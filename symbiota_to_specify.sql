-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- AUTHOR: VAUGHN SHIREY
-- Description: Moves core occurrence data through a Darwin Core view into tables that align with Specify.
-- CREATE DWC VIEW FROM SYMBIOTA -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

/*(1)*/
DROP VIEW IF EXISTS dwc_view; 
CREATE VIEW dwc_view AS
SELECT occid, catalogNumber, otherCatalogNumbers, tidinterpreted AS taxonID, eventDate, verbatimEventDate, decimalLatitude, decimalLongitude, 
verbatimCoordinates, minimumElevationInMeters, maximumElevationInMeters, verbatimElevation, locality, identifiedBy, recordedBy
FROM omoccurrences
;

-- CREATE TABLE STATMENTS -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- TEMPORARY AGENTS --
/*(2)*/
DROP TABLE IF EXISTS tempAgent();
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

-- TEMPORARY COLLECTORS --
DROP TABLE IF EXISTS tempCollector();
CREATE TABLE IF NOT EXISTS tempCollector (

	OccID int(10),
	TempCollectorID int(11) NOT NULL auto_increment PRIMARY KEY,
	CollectorID int(11),
	TimestampCreated datetime,
	CollectingEventID int(11),
	
	IsPrimary bit(1),
	OrderNumber int(11),
	AgentID int(11),
	CollectingEventID int(11)
);

 -- TEMPORARY LOCALITIES --
DROP TABLE IF EXISTS tempLocality();
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
DROP TABLE IF EXISTS tempColEvent();
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
DROP TABLE IF EXISTS tempColObject();
CREATE TABLE IF NOT EXISTS tempColObject (

	OccID int(10),
	TempColObjectID int(11) auto_increment PRIMARY KEY,
	CollectionObject int(11),
	CollectionMemberID int(11),
	CollectionEventID,
	
	AltCatalogNumber varchar(32),
	CatalogNumber varchar(32)
);

-- TEMPORARY DETERMINATION --
DROP TABLE IF EXISTS tempDetermination();
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
DROP TABLE IF EXISTS agentReclamation();
CREATE TABLE IF NOT EXISTS agentReclamation (tempAgentNameID int(11) NOT NULL auto_increment PRIMARY KEY, tempAgentName varchar(170), finalID int(11));

-- BEGIN INSERTING VALUES INTO APPROPRIATE FIELDS -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- BEGIN INSERT WITH TEMPORARY AGENTS --
-- INSERT INTO tempAgent(OccID, VerbatimName, FirstName, LastName) -- update to obtain agents for each member of a collection team --
	-- SELECT occid, name, SUBSTRING_INDEX(name, '.', 1) AS FirstName, SUBSTRING_INDEX(name, '.', -1)  AS LastName  -- alternatively could just use last names --
	-- FROM (SELECT occid, SUBSTRING_INDEX(recordedBy, ',', 1) as name FROM dwc_view) AS nameTable WHERE name IS NOT NULL AND name LIKE '%.%' AND name NOT LIKE '%#%' ORDER BY name;
	
-- GET NAMES THAT ARE SINGLE COLLECTORS PER RECORD PROCEDURE? --
SELECT occid, name, SUBSTRING_INDEX(name, ' ',1) AS FirstName, SUBSTRING_INDEX(name, ' ',-1) AS LastName
FROM (SELECT occid, recordedBy as name FROM omoccurrences) AS names WHERE name NOT REGEXP '[,]' AND name NOT REGEXP '[&]'

SELECT occid, name, SUBSTRING_INDEX(name, ',',2) AS FirstName, SUBSTRING_INDEX(name, ',',1) AS LastName
FROM (SELECT occid, recordedBy as name FROM omoccurrences) AS names WHERE name NOT REGEXP '[&]' AND name NOT REGEXP '[a-z]* [a-z]+$'

----------------------------------------------------------------

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
DECLARE cur CURSOR FOR SELECT VerbatimName FROM tempAgent WHERE VerbatimName LIKE '%,%';
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done := TRUE;

OPEN cur;

testLoop: LOOP
	FETCH cur INTO verbatimNameHandler;
	IF done THEN 
		LEAVE testLoop;
	END IF;
	CALL agent_reclamation(verbatimNameHandler);
END LOOP testLoop;

CLOSE cur;
END //

CREATE PROCEDURE agent_reclamation (IN VerbatimName VARCHAR(170)) 
BEGIN
DECLARE verbatimNameHandler varchar(170);
DECLARE tempAgentName varchar(170); 
SET verbatimNameHandler = VerbatimName;
	WHILE LENGTH(verbatimNameHandler) > 0 DO -- while there's more stuff left
		IF LOCATE(',', verbatimNameHandler) > 0 THEN -- and theres a comma to be found
			SET tempAgentName = SUBSTRING(verbatimNameHandler,1,LOCATE(',',verbatimNameHandler) - 1); -- set the temp variable to everything from the first character to the first comma
		ELSE
			SET tempAgentName = verbatimNameHandler; -- set the name if there are no commas
			SET verbatimNameHandler = ''; -- won't accept procedure without update --
		END IF;
		-- INSERT INTO agentReclamation SET tempAgentName = tempAgentName;
		INSERT INTO agentReclamation(tempAgentName) VALUES (tempAgentName);  -- insert the new names into the agentReclamation table
		SET verbatimNameHandler = REPLACE(verbatimNameHandler, CONCAT(tempAgentName, ','), ''); -- won't accept procedure without update --
	END WHILE;
END //

DELIMITER ;

CALL procIteration();

INSERT INTO tempAgent(verbatimName, occid)
	SELECT identifiedBy, occid FROM dwc_view;
	
-- COMPACT AGENTS HERE!!!!!!!!!!!!!!!!!!!!!!!!!! -- -- -- -- -- -- -- -- -- -- -- --!!!!!!!

SELECT agentReclamation.tempAgentNameID, agentReclamation.tempAgentName, agentKey.newKey
FROM agentReclamation LEFT JOIN (
SELECT tempAgentName, MIN(tempAgentNameID) AS newKey FROM agentReclamation GROUP BY tempAgentName) AS agentKey ON agentReclamation.tempAgentName = agentKey.tempAgentName ORDER BY agentReclamation.tempAgentName 

UPDATE agentReclamation
SET finalID = SELECT newKey FROM agentReclamation LEFT JOIN (
SELECT tempAgentName, MIN(tempAgentNameID) AS newKey FROM agentReclamation GROUP BY tempAgentName) AS agentKeys ON agentReclamation.tempAgentName = agentKeys.tempAgentName;
	
/*(7) */
INSERT INTO tempAgent(FirstName, LastName, tempAgentID)
	SELECT SUBSTRING_INDEX(tempAgentName, ' ', 1) AS FirstName, SUBSTRING_INDEX(tempAgentName, ' ', -1) AS LastName, tempAgentNameID FROM agentReclamation WHERE tempAgentName NOT LIKE '%.%';

INSERT INTO tempAgent(FirstName, LastName, tempAgentID)	
	SELECT SUBSTRING_INDEX(tempAgentName, '.', 1) AS FirstName, SUBSTRING_INDEX(tempAgentName, '.', -1) AS LastName, tempAgentNameID FROM agentReclamation WHERE tempAgentName LIKE '%.%';
	
/*(5)*/
-- BEGIN INSERT WITH TEMPORARY LOCALITIES --
INSERT INTO tempLocality(OccID, Latitude1, Longitude1, MaxElevation, MinElevation, VerbatimElevation, Long1Text, VerbatimLatitude, VerbatimLongitude)
	SELECT occid, decimalLatitude, decimalLongitude, maximumElevationInMeters, minimumElevationInMeters, verbatimElevation, locality, SUBSTRING_INDEX(vCoord, ' ', 1) AS VerbatimLatitude, 
	SUBSTRING_INDEX(vCoord, ' ', -1) AS VerbatimLongitude 
	FROM (SELECT occid, decimalLatitude, decimalLongitude, maximumElevationInMeters, minimumElevationInMeters, verbatimElevation, locality, verbatimCoordinates AS vCoord FROM dwc_view) AS localityTable ORDER BY locality;
	
-- BEGIN INSERT WITH TEMPORARY COLLECTION EVENTS --
INSERT INTO tempColEvent(OccID, StartDate, VerbatimDate)
	SELECT occid, eventDate, verbatimEventDate
	FROM dwc_view;
	
-- BEGIN INSERT INTO TEMPORARY COLLECTORS --	
INSERT INTO tempCollector(OccID, AgentID)
	SELECT dwc.occid, tAgent.tempAgentID 
	FROM dwc_view AS dwc, tempAgent AS tAgent WHERE dwc.occid = tAgent.occid;
	
-- BEGIN INSERT INTO TEMPORARY COLLECTION OBJECT --
INSERT INTO tempColObject(OccID, AltCatalogNumber, CatalogNumber)
	SELECT occid, otherCatalogNumbers, catalogNumber
	FROM dwc_view;

-- BEGIN INSERT INTO TEMPORARY DETERMINATIONS --
INSERT INTO tempDetermination(OccID, TaxonID, CollectionObjectID)
	SELECT dwc.occid, dwc.tidinterpreted, tempColObj.CollectionObjectID 
	FROM dwc_view AS dwc, tempColObject AS tempColObj WHERE dwc.occid = tempColObj.occid;
	
-- ALTER TABLE WITH FOREIGN KEYS -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 

ALTER TABLE tempAgent
ADD FOREIGN KEY OccID REFERENCES tempLocality.OccID, tempColEvent.OccID, tempColObject.OccID, tempDetermination.OccID, tempCollector.OccID

ALTER TABLE tempLocality
ADD FOREIGN KEY OccID REFERENCES tempAgent.OccID, tempColEvent.OccID, tempColObject.OccID, tempDetermination.OccID, tempCollector.OccID

ALTER TABLE tempColEvent
ADD FOREIGN KEY OccID REFERENCES tempAgent.OccID, tempLocality.OccID, tempColObject.OccID, tempDetermination.OccID, tempCollector.OccID

ALTER TABLE tempColObject
ADD FOREIGN KEY OccID REFERENCES tempAgent.OccID, tempLocality.OccID, tempColEvent.OccID, tempDetermination.OccID, tempCollector.OccID
	
ALTER TABLE tempDetermination
ADD FOREIGN KEY OccID REFERENCES tempAgent.OccID, tempLocality.OccID, tempColEvent.OccID, tempColObject.OccID, tempCollector.OccID

-- CREATE GROUPINGS  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- GET DISTINCT LOCALITY KEYS --
SELECT omoccurrences.locality, localityKeys.newKey 
FROM omoccurrences LEFT JOIN (
SELECT locality, MIN(occid) AS newKey FROM omoccurrences GROUP BY locality) AS localityKeys ON omoccurrences.locality = localityKeys.locality ORDER BY newKey

-- GET DISTINCT COLLECTOR/AGENT KEYS --
SELECT omoccurrences.recordedBy, collectorKeys.newKey, omoccurrences.occid
FROM omoccurrences LEFT JOIN (
SELECT recordedBy, MIN(occid) AS newKey FROM omoccurrences GROUP BY recordedBy) AS collectorKeys ON omoccurrences.recordedBy = collectorKeys.recordedBy WHERE omoccurrences.recordedBy IS NOT NULL ORDER BY newKey 

-- UPDATES -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

/*(5)*/
UPDATE tempCollector
SET CollectorID = SELECT newKey FROM dwc_view LEFT JOIN (
SELECT recordedBy, MIN(tempCollectorID) AS newKey FROM dwc_view GROUP BY recordedBy) AS collectorKeys ON dwc_view.recordedBy = collectorKeys.recordedBy

UPDATE tempLocality
SET LocalityID = SELECT newKey FROM dwc_view LEFT JOIN (
SELECT locality, MIN(tempLocalityID) AS newKey FROM dwc_view GROUP BY locality) AS localityKeys ON dwc_view.locality = localityKeys.locality

UPDATE tempColEvent
SET CollectingEventID = SELECT newKey FROM dwc_view LEFT JOIN (
SELECT eventDate, locality, recordedBy, occid, MIN(tempColEventID) AS newKey FROM dwc_view GROUP BY eventDate, locality, recordedBy) AS eventKeys ON dwc_view.occid = eventKeys.occid


-- BEGIN LINKAGES -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

/*(6)*/
UPDATE tempColEvent
SET localityID = SELECT localityID FROM tempLocality, tempColEvent WHERE tempLocality.OccID = tempColEvent.OccID

UPDATE tempCollector -- update this to obtain distinct collection events above --
SET CollectionEventID = SELECT CollectionEventID FROM tempColEvent, tempCollector WHERE tempColEvent.OccID = tempCollector.OccID

UPDATE tempDetermination
SET AgentID = SELECT tempAgentID FROM tempAgent, tempDetermination WHERE tempDetermination.Occid = tempAgent.OccID

UPDATE tempColObj 
SET CollectionEventID = SELECT CollectionEventID FROM tempColEVent, tempColObj WHERE tempColEvent.OccID = tempColObj.OccID

-- REMOVE DUPLICATES -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

DELETE FROM tempCollector
WHERE tempCollectorID != CollectorID;

DELETE FROM tempLocality
WHERE tempLocalityID != LocalityID;

-- DROP OCCID COLUMN -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

ALTER TABLE tempCollector
DROP COLUMN OccID;

ALTER TABLE tempLocality
DROP COLUMN OccID;



