---------------------------------------------------------
-- STS 1b                                              --
-- Vaughn Shirey 2016                                  --
-- Creates temporary tables to emulate those in        --    
-- Specify for agents, localities, collectors,         --
-- collecting events, collection objects and           --
-- determinations									   --
---------------------------------------------------------

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
	
	Long1Text varchar(50),
	Country varchar(100),
	`State` varchar(100),
	County varchar(100)
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

DELETE FROM tempAgent; 

INSERT INTO tempAgent(verbatimName, FirstName, LastName, occid, AgentType, TimestampCreated)
	SELECT identifiedBy, SUBSTRING_INDEX(dwc_view.identifiedBy, ' ', 1) AS FirstName, SUBSTRING_INDEX(dwc_view.identifiedBy, ' ', -1) AS LastName, dwc_view.occid, 2, now() FROM dwc_view WHERE identifiedBy NOT LIKE '%.%';
	
INSERT INTO tempAgent(verbatimName, FirstName, LastName, occid, AgentType, TimestampCreated)
	SELECT identifiedBy, SUBSTRING_INDEX(dwc_view.identifiedBy, '.', 1) AS FirstName, SUBSTRING_INDEX(dwc_view.identifiedBy, '.', -1) AS LastName, dwc_view.occid, 2, now() FROM dwc_view WHERE identifiedBy LIKE '%.%';

DELETE FROM tempLocality;
INSERT INTO tempLocality(OccID, Latitude1, Longitude1, MaxElevation, MinElevation, VerbatimElevation, Long1Text, VerbatimLatitude, VerbatimLongitude, Country, `State`, County)
	SELECT occid, decimalLatitude, decimalLongitude, maximumElevationInMeters, minimumElevationInMeters, verbatimElevation, locality, SUBSTRING_INDEX(vCoord, ' ', 1) AS VerbatimLatitude, 
	SUBSTRING_INDEX(vCoord, ' ', -1) AS VerbatimLongitude, Country, `State`, County 
	FROM (SELECT Country, `State`, County, occid, decimalLatitude, decimalLongitude, maximumElevationInMeters, minimumElevationInMeters, verbatimElevation, locality, verbatimCoordinates AS vCoord FROM dwc_view) AS localityTable ORDER BY locality;
	
-- BEGIN INSERT WITH TEMPORARY COLLECTION EVENTS --
DELETE FROM tempColEvent;
INSERT INTO tempColEvent(OccID, StartDate, VerbatimDate)
	SELECT occid, eventDate, verbatimEventDate
	FROM dwc_view;
	
-- BEGIN INSERT INTO TEMPORARY COLLECTION OBJECT --
DELETE FROM tempColObject;
INSERT INTO tempColObject(OccID, AltCatalogNumber, CatalogNumber)
	SELECT occid, otherCatalogNumbers, catalogNumber
	FROM dwc_view;

-- BEGIN INSERT INTO TEMPORARY DETERMINATIONS --
DELETE FROM tempDetermination;
INSERT INTO tempDetermination(OccID, TaxonID, CollectionObjectID)
	SELECT dwc.occid, dwc.taxonID, tempColObj.CollectionObjectID 
	FROM dwc_view AS dwc, tempColObject AS tempColObj WHERE dwc.occid = tempColObj.occid;

ALTER TABLE tempAgent
ADD FOREIGN KEY (OccID) REFERENCES tempLocality.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColEvent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColObject.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempDetermination.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempCollector.OccID; 

ALTER TABLE tempLocality
ADD FOREIGN KEY (OccID) REFERENCES tempAgent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColEvent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColObject.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempDetermination.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempCollector.OccID; 

ALTER TABLE tempColEvent
ADD FOREIGN KEY (OccID) REFERENCES tempAgent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempLocality.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColObject.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempDetermination.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempCollector.OccID;

ALTER TABLE tempColObject
ADD FOREIGN KEY (OccID) REFERENCES tempAgent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempLocality.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColEvent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempDetermination.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempCollector.OccID;
	
ALTER TABLE tempDetermination
ADD FOREIGN KEY (OccID) REFERENCES tempAgent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempLocality.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColEvent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColObject.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempCollector.OccID;

ALTER TABLE tempCollector
ADD FOREIGN KEY (AgentID) REFERENCES tempAgent.AgentID;

ALTER TABLE tempDetermination
ADD FOREIGN KEY (AgentID) REFERENCES tempAgent.AgentID;

ALTER TABLE tempDetermination
ADD FOREIGN KEY (CollectionObjectID) REFERENCES tempColObject.TempColObjectID;

ALTER TABLE tempColEvent
ADD FOREIGN KEY (LocalityID) REFERENCES tempLocality.LocalityID;

INSERT INTO tempCollector(OccID, AgentID)
SELECT OccID, AgentID FROM tempAgent; 


UPDATE tempCollector JOIN (SELECT OccID, MIN(TempCollectorID) as minValue FROM tempCollector GROUP BY OccID) tMin ON tempCollector.OccID = tMin.OccID AND tempCollector.TempCollectorID = tMin.minValue
SET isPrimary = 1;

UPDATE tempCollector JOIN (SELECT OccID, AgentID, MIN(TempCollectorID) as minValue FROM tempCollector GROUP BY AgentID) tMin ON tempCollector.AgentID = tMin.AgentID
SET CollectorID = tMin.minValue;

UPDATE tempDetermination
SET AgentID = (SELECT AgentID FROM tempAgent WHERE tempDetermination.OccID = tempAgent.OccID);

UPDATE tempDetermination
SET CollectionObjectID = (SELECT TempColObjectID FROM tempColObject WHERE tempDetermination.OccID = tempColObject.OccID);

-- handle localities --

UPDATE tempLocality JOIN (SELECT Long1Text, Latitude1, Longitude1, MIN(TempLocalityID) as minValue FROM tempLocality GROUP BY Long1Text) tMin ON tempLocality.Long1Text = tMin.Long1Text AND tempLocality.Latitude1 = tMin.Latitude1 AND tempLocality.Longitude1 = tMin.Longitude1 
SET LocalityID = tMin.minValue;

UPDATE tempLocality
SET LocalityID = TempLocalityID WHERE LocalityID IS NULL;

-- link locality/collector to CollectingEvent --

UPDATE tempColEvent
SET LocalityID = (SELECT LocalityID FROM tempLocality WHERE tempColEvent.OccID = tempLocality.OccID); 

UPDATE tempColEvent
SET CollectorID = (SELECT CollectorID FROM tempCollector WHERE tempColEvent.OccID = tempCollector.OccID AND tempCollector.IsPrimary IS NOT NULL);

-- handle ColEvent --

UPDATE tempColEvent JOIN (SELECT StartDate, LocalityID, CollectorID, MIN(TempColEventID) as minValue FROM tempColEvent GROUP BY StartDate) tMin ON tempColEvent.StartDate = tMin.StartDate AND tempColEvent.LocalityID = tMin.LocalityID AND tempColEvent.CollectorID = tMin.CollectorID
SET CollectionEventID = tMin.minValue;

UPDATE tempColEvent
SET CollectionEventID = TempColEventID WHERE CollectionEventID IS NULL;

-- link colevent to colobj/collector --

UPDATE tempColObject 
SET CollectionEventID = (SELECT CollectionEventID FROM tempColEvent WHERE tempColEvent.OccID = tempColObject.OccID);

UPDATE tempCollector
SET CollectingEventID = (SELECT CollectionEventID FROM tempColEvent WHERE tempColEvent.OccID = tempCollector.OccID);

ALTER TABLE tempAgent
DROP FOREIGN KEY OccID;  

ALTER TABLE tempLocality
DROP FOREIGN KEY OccID;

ALTER TABLE tempColEvent
DROP FOREIGN KEY OccID;

ALTER TABLE tempColObject
DROP FOREIGN KEY OccID;
	
ALTER TABLE tempDetermination
DROP FOREIGN KEY OccID;

DELETE FROM tempAgent WHERE tempAgent.AgentID != tempAgent.TempAgentID;

DELETE FROM tempColEvent WHERE tempColEvent.CollectionEventID != tempColEvent.TempColEventID;

DELETE FROM tempLocality WHERE tempLocality.LocalityID != tempLocality.tempLocalityID;