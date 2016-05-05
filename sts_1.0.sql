-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- AUTHOR: VAUGHN SHIREY
-- Description: Moves core occurrence data through a Darwin Core view into tables that align with Specify.
-- CREATE DWC VIEW FROM SYMBIOTA -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

/*(1)*/
DROP VIEW IF EXISTS dwc_view; 
CREATE VIEW dwc_view AS
SELECT occid, catalogNumber, otherCatalogNumbers, tidinterpreted AS taxonID, eventDate, verbatimEventDate, decimalLatitude, decimalLongitude, 
verbatimCoordinates, minimumElevationInMeters, maximumElevationInMeters, verbatimElevation, locality, identifiedBy, recordedBy
FROM omoccurrences;

-- CREATE TABLE STATMENTS -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- TEMPORARY AGENTS --
/*(2)*/
DROP TABLE IF EXISTS tempAgent;
CREATE TABLE IF NOT EXISTS tempAgent (

	OccID int(10),
	TempAgentID int(11) NOT NULL auto_increment PRIMARY KEY,
	AgentID int(11),
	TimestampCreated datetime,
	AgentType tinyint(4),

	VerbatimName varchar(170),
	FirstName varchar(50),
	LastName varchar(120)
);
DELETE FROM tempAgent;

-- TEMPORARY COLLECTORS --
DROP TABLE IF EXISTS tempCollector;
CREATE TABLE IF NOT EXISTS tempCollector (

	OccID int(10),
	TempCollectorID int(11) NOT NULL auto_increment PRIMARY KEY,
	CollectorID int(11),
	TimestampCreated datetime,
	
	IsPrimary bit(1),
	OrderNumber int(11),
	AgentID int(11),
	CollectingEventID int(11)
);
DELETE FROM tempCollector;

 -- TEMPORARY LOCALITIES --
DROP TABLE IF EXISTS tempLocality;
CREATE TABLE IF NOT EXISTS tempLocality (

	OccID int(10),
	TempLocalityID int(11) NOT NULL auto_increment PRIMARY KEY,
	LocalityID int(11),
	
	Latitude1 decimal(12,10),
	Longitude1 decimal(12,10),
	
	MaxElevation double,
	MinElevation double,
	
	VerbatimElevation varchar(50),
	VerbatimLatitude varchar(50),
	VerbatimLongitude varchar(50),
	
	Long1Text varchar(50)
);

 -- TEMPORARY COLLECTION EVENTS --
DROP TABLE IF EXISTS tempColEvent;
CREATE TABLE IF NOT EXISTS tempColEvent (
	
	OccID int(10),
	TempColEventID int(11) NOT NULL auto_increment PRIMARY KEY,
	CollectionEventID int(11),
	TimestampCreate datetime,
	DisciplineID int(11),
	CollectorID int(11),
	
	StartDate date,
	VerbatimDate varchar(50),
	
	LocalityID int(11)
);

-- TEMPORARY COLLECTION OBJECT --
DROP TABLE IF EXISTS tempColObject;
CREATE TABLE IF NOT EXISTS tempColObject (

	OccID int(10),
	TempColObjectID int(11) auto_increment PRIMARY KEY,
	CollectionObjectID int(11),
	CollectionMemberID int(11),
	CollectionEventID int(11),
	
	AltCatalogNumber varchar(32),
	CatalogNumber varchar(32)
);

-- TEMPORARY DETERMINATION --
DROP TABLE IF EXISTS tempDetermination;
CREATE TABLE IF NOT EXISTS tempDetermination (

	OccID int(10),
	TempDeterminationID int(11) NOT NULL auto_increment PRIMARY KEY,
	DeterminationID int(11),
	TimestampCreated datetime,
	CollectionMemberID int(11),
	
	IsCurrent bit(1) NOT NULL,
	TaxonID int(11),
	
	CollectionObjectID int(11),
	AgentID int(11)
);

-- TABLE FOR HANDLING AGENT ASSIGNMENTS -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

/*(3)*/
DROP TABLE IF EXISTS agentReclamation;
CREATE TABLE IF NOT EXISTS agentReclamation (tempAgentNameID int(11) NOT NULL auto_increment PRIMARY KEY, tempAgentName varchar(170), finalID int(11), OccID int(11));

-- BEGIN INSERTING VALUES INTO APPROPRIATE FIELDS -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- BEGIN INSERT WITH TEMPORARY AGENTS --
-- INSERT INTO tempAgent(OccID, VerbatimName, FirstName, LastName) -- update to obtain agents for each member of a collection team --
	-- SELECT occid, name, SUBSTRING_INDEX(name, '.', 1) AS FirstName, SUBSTRING_INDEX(name, '.', -1)  AS LastName  -- alternatively could just use last names --
	-- FROM (SELECT occid, SUBSTRING_INDEX(recordedBy, ',', 1) as name FROM dwc_view) AS nameTable WHERE name IS NOT NULL AND name LIKE '%.%' AND name NOT LIKE '%#%' ORDER BY name;
	
-- GET NAMES THAT ARE SINGLE COLLECTORS PER RECORD PROCEDURE? --
-- SELECT occid, name, SUBSTRING_INDEX(name, ' ',1) AS FirstName, SUBSTRING_INDEX(name, ' ',-1) AS LastName
-- FROM (SELECT occid, recordedBy as name FROM omoccurrences) AS names WHERE name NOT REGEXP '[,]' AND name NOT REGEXP '[&]'

-- SELECT occid, name, SUBSTRING_INDEX(name, ',',2) AS FirstName, SUBSTRING_INDEX(name, ',',1) AS LastName
-- FROM (SELECT occid, recordedBy as name FROM omoccurrences) AS names WHERE name NOT REGEXP '[&]' AND name NOT REGEXP '[a-z]* [a-z]+$'


-- PROCEDURE FOR PARSING ALL COLLECTOR NAMES INTO INDIVIDUAL AGENTS -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
/*(4)*/
INSERT INTO tempAgent(verbatimName, occid)
	SELECT recordedBy, occid FROM dwc_view;

DROP PROCEDURE IF EXISTS agent_reclamation;
DROP PROCEDURE IF EXISTS procIteration;
DELIMITER //

CREATE PROCEDURE procIteration ()
BEGIN
DECLARE done BOOLEAN DEFAULT FALSE;
DECLARE verbatimNameHandler varchar(170);
DECLARE occurrenceHandler int(11);
DECLARE cur CURSOR FOR SELECT VerbatimName, OccID FROM tempAgent; -- WHERE VerbatimName LIKE '%,%';
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done := TRUE;

OPEN cur;

testLoop: LOOP
	FETCH cur INTO verbatimNameHandler, occurrenceHandler;
	IF done THEN 
		LEAVE testLoop;
	END IF;
	CALL agent_reclamation(verbatimNameHandler, occurrenceHandler);
END LOOP testLoop;

CLOSE cur;
END //

CREATE PROCEDURE agent_reclamation (IN VerbatimName VARCHAR(170), IN OccIDMover int(11)) 
BEGIN
DECLARE verbatimNameHandler varchar(170);
DECLARE tempAgentName varchar(170); 
SET verbatimNameHandler = VerbatimName;
	WHILE LENGTH(verbatimNameHandler) > 0 DO -- while there's more stuff left
		IF LOCATE(',', verbatimNameHandler) > 0 THEN -- and theres a comma to be found
			SET tempAgentName = SUBSTRING(verbatimNameHandler,1,LOCATE(',',verbatimNameHandler) - 1); -- set the temp variable to everything from the first character to the first comma
		ELSE
			SET tempAgentName = verbatimNameHandler;-- set the name if there are no commas
			SET verbatimNameHandler = ''; -- won't accept procedure without update --
		END IF;
		-- INSERT INTO agentReclamation SET tempAgentName = tempAgentName;
		INSERT INTO agentReclamation(tempAgentName, OccID) VALUES (tempAgentName, OccIDMover);  -- insert the new names into the agentReclamation table
		SET verbatimNameHandler = REPLACE(verbatimNameHandler, CONCAT(tempAgentName, ','), ''); -- won't accept procedure without update --
	END WHILE;
END //

DELIMITER ;

CALL procIteration();

DELETE FROM tempAgent WHERE FirstName IS NULL; 

INSERT INTO tempAgent(verbatimName, FirstName, LastName, occid, AgentType)
	SELECT identifiedBy, SUBSTRING_INDEX(dwc_view.identifiedBy, ' ', 2) AS FirstName, SUBSTRING_INDEX(dwc_view.identifiedBy, ' ', -1) AS LastName, dwc_view.occid, 2 FROM dwc_view WHERE identifiedBy NOT LIKE '%.%';
	
INSERT INTO tempAgent(verbatimName, FirstName, LastName, occid, AgentType)
	SELECT identifiedBy, SUBSTRING_INDEX(dwc_view.identifiedBy, '.', 1) AS FirstName, SUBSTRING_INDEX(dwc_view.identifiedBy, '.', -1) AS LastName, dwc_view.occid, 2 FROM dwc_view WHERE identifiedBy LIKE '%.%';

UPDATE tempAgent JOIN (SELECT VerbatimName, MIN(TempAgentID) as minValue FROM tempAgent GROUP BY VerbatimName) tMin ON tempAgent.VerbatimName = tMin.VerbatimName
SET AgentID = tMin.minValue;

-- COMPACT AGENTS HERE!!!!!!!!!!!!!!!!!!!!!!!!!! -- -- -- -- -- -- -- -- -- -- -- --!!!!!!!

-- SELECT agentReclamation.tempAgentNameID, agentReclamation.tempAgentName, agentKey.newKey
-- FROM agentReclamation LEFT JOIN (
-- SELECT tempAgentName, MIN(tempAgentNameID) AS newKey FROM agentReclamation GROUP BY tempAgentName) AS agentKey ON agentReclamation.tempAgentName = agentKey.tempAgentName ORDER BY agentReclamation.tempAgentName 

-- UPDATE agentReclamation
-- SET finalID = SELECT newKey FROM agentReclamation LEFT JOIN (
-- SELECT tempAgentName, MIN(tempAgentNameID) AS newKey FROM agentReclamation GROUP BY tempAgentName) AS agentKeys ON agentReclamation.tempAgentName = agentKeys.tempAgentName;

	
/*(7) */ -- INSERT NAMES TO tempAgent --
INSERT INTO tempAgent(FirstName, LastName, AgentID, verbatimName, OccID)
	SELECT SUBSTRING_INDEX(agentReclamation.tempAgentName, ' ', 2) AS FirstName, SUBSTRING_INDEX(agentReclamation.tempAgentName, ' ', -1) AS LastName, targetKeys.newKey, agentReclamation.tempAgentName, OccID FROM agentReclamation JOIN (SELECT tempAgentName, MIN(tempAgentNameID) AS newKey FROM agentReclamation GROUP BY tempAgentName) AS targetKeys ON targetKeys.tempAgentName = agentReclamation.tempAgentName WHERE agentReclamation.tempAgentName NOT LIKE '%.%' AND agentReclamation.tempAgentName NOT LIKE '%&%';

INSERT INTO tempAgent(FirstName, LastName, AgentID, verbatimName, OccID)
	SELECT SUBSTRING_INDEX(agentReclamation.tempAgentName, '.', 1) AS FirstName, SUBSTRING_INDEX(agentReclamation.tempAgentName, '.', -1) AS LastName, targetKeys.newKey, agentReclamation.tempAgentName, OccID FROM agentReclamation JOIN(SELECT tempAgentName, MIN(tempAgentNameID) AS newKey FROM agentReclamation GROUP BY tempAgentName) AS targetKeys ON targetKeys.tempAgentName = agentReclamation.tempAgentName WHERE agentReclamation.tempAgentName LIKE '%.%';