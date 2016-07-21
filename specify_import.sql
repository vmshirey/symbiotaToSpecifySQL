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

	occurrenceID int(10) NOT NULL,
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

	occurrenceID int(10) NOT NULL,
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

	occurrenceID int(10) NOT NULL,
	TempLocalityID int(11) NOT NULL auto_increment PRIMARY KEY,
	LocalityID int(11),
	
	Latitude1 decimal(12,10),
	Longitude1 decimal(12,10),
	
	MaxElevation double,
	MinElevation double,
	
	VerbatimElevation varchar(50),
	VerbatimLatitude varchar(50),
	VerbatimLongitude varchar(50),
	
	Remarks text,
	Country varchar(100),
	`State` varchar(100),
	County varchar(100)
);

 -- TEMPORARY COLLECTION EVENTS --
DROP TABLE IF EXISTS tempColEvent;
CREATE TABLE IF NOT EXISTS tempColEvent (
	
	occurrenceID int(10) NOT NULL,
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

	occurrenceID int(10) NOT NULL,
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

	occurrenceID int(10) NOT NULL,
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
CREATE TABLE IF NOT EXISTS agentReclamation (

	occurrenceID int(10) NOT NULL,
	tempAgentNameID int(11) NOT NULL auto_increment PRIMARY KEY,
    tempAgentName varchar(170),
    finalID int(11)
);

-- BEGIN INSERTING VALUES INTO APPROPRIATE FIELDS -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

/*(4)*/
INSERT INTO tempAgent(verbatimName, occurrenceID)
	SELECT recordedBy, occurrenceID FROM dwc_view;

DROP PROCEDURE IF EXISTS agent_reclamation;
DROP PROCEDURE IF EXISTS procIteration;
DELIMITER //

CREATE PROCEDURE procIteration ()
BEGIN
DECLARE done BOOLEAN DEFAULT FALSE;
DECLARE verbatimNameHandler varchar(170);
DECLARE occurrenceHandler int(11);
DECLARE cur CURSOR FOR SELECT VerbatimName, occurrenceID FROM tempAgent; -- WHERE VerbatimName LIKE '%,%';
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

CREATE PROCEDURE agent_reclamation (IN VerbatimName VARCHAR(170), IN occurrenceIDMover int(11)) 
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
		INSERT INTO agentReclamation(tempAgentName, occurrenceID) VALUES (tempAgentName, occurrenceIDMover);  -- insert the new names into the agentReclamation table
		SET verbatimNameHandler = REPLACE(verbatimNameHandler, CONCAT(tempAgentName, ','), ''); -- won't accept procedure without update --
	END WHILE;
END //

DELIMITER ;

CALL procIteration();

DELETE FROM tempAgent; 

INSERT INTO tempAgent(verbatimName, FirstName, LastName, occurrenceID, AgentType, TimestampCreated)
	SELECT identifiedBy, SUBSTRING_INDEX(dwc_view.identifiedBy, ' ', 1) AS FirstName, SUBSTRING_INDEX(dwc_view.identifiedBy, ' ', -1) AS LastName, dwc_view.occurrenceID, 2, now() FROM dwc_view WHERE identifiedBy NOT LIKE '%.%';
	
INSERT INTO tempAgent(verbatimName, FirstName, LastName, occurrenceID, AgentType, TimestampCreated)
	SELECT identifiedBy, SUBSTRING_INDEX(dwc_view.identifiedBy, '.', 1) AS FirstName, SUBSTRING_INDEX(dwc_view.identifiedBy, '.', -1) AS LastName, dwc_view.occurrenceID, 2, now() FROM dwc_view WHERE identifiedBy LIKE '%.%';

DELETE FROM tempLocality;
INSERT INTO tempLocality(occurrenceID, Latitude1, Longitude1, MaxElevation, MinElevation, VerbatimElevation, Remarks, VerbatimLatitude, VerbatimLongitude, Country, `State`, County)
	SELECT occurrenceID, decimalLatitude, decimalLongitude, maximumElevationInMeters, minimumElevationInMeters, verbatimElevation, locality, SUBSTRING_INDEX(vCoord, ' ', 1) AS VerbatimLatitude, 
	SUBSTRING_INDEX(vCoord, ' ', -1) AS VerbatimLongitude, Country, stateProvince, County 
	FROM (SELECT Country, stateProvince, County, occurrenceID, decimalLatitude, decimalLongitude, maximumElevationInMeters, minimumElevationInMeters, verbatimElevation, locality, verbatimCoordinates AS vCoord FROM dwc_view) AS localityTable ORDER BY locality;
	
-- BEGIN INSERT WITH TEMPORARY COLLECTION EVENTS --
DELETE FROM tempColEvent;
INSERT INTO tempColEvent(occurrenceID, StartDate, VerbatimDate)
	SELECT occurrenceID, eventDate, verbatimEventDate
	FROM dwc_view;
	
-- BEGIN INSERT INTO TEMPORARY COLLECTORS --	
DELETE FROM tempCollector;
INSERT INTO tempCollector(occurrenceID, AgentID)
 	SELECT dwc.occurrenceID, tAgent.tempAgentID 
 	FROM dwc_view AS dwc, tempAgent AS tAgent WHERE dwc.occurrenceID = tAgent.occurrenceID;
	
-- BEGIN INSERT INTO TEMPORARY COLLECTION OBJECT --
DELETE FROM tempColObject;
INSERT INTO tempColObject(occurrenceID, AltCatalogNumber, CatalogNumber)
	SELECT occurrenceID, otherCatalogNumbers, catalogNumber
	FROM dwc_view;

-- BEGIN INSERT INTO TEMPORARY DETERMINATIONS --
DELETE FROM tempDetermination;
INSERT INTO tempDetermination(occurrenceID, TaxonID, CollectionObjectID, IsCurrent)
	SELECT dwc.occurrenceID, dwc.taxonID, tempColObj.CollectionObjectID, 1 AS IsCurrent 
	FROM dwc_view AS dwc, tempColObject AS tempColObj WHERE dwc.occurrenceID = tempColObj.occurrenceID;

ALTER TABLE tempAgent
ADD FOREIGN KEY (occurrenceID) REFERENCES tempLocality.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempColEvent.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempColObject.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempDetermination.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempCollector.occurrenceID; 

ALTER TABLE tempLocality
ADD FOREIGN KEY (occurrenceID) REFERENCES tempAgent.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempColEvent.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempColObject.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempDetermination.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempCollector.occurrenceID; 

ALTER TABLE tempColEvent
ADD FOREIGN KEY (occurrenceID) REFERENCES tempAgent.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempLocality.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempColObject.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempDetermination.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempCollector.occurrenceID;

ALTER TABLE tempCollector
ADD FOREIGN KEY (occurrenceID) REFERENCES tempAgent.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempLocality.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempColEvent.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempColObject.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempCollector.occurrenceID;

ALTER TABLE tempColObject
ADD FOREIGN KEY (occurrenceID) REFERENCES tempAgent.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempLocality.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempColEvent.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempDetermination.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempCollector.occurrenceID;
	
ALTER TABLE tempDetermination
ADD FOREIGN KEY (occurrenceID) REFERENCES tempAgent.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempLocality.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempColEvent.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempColObject.occurrenceID, 
ADD FOREIGN KEY (occurrenceID) REFERENCES tempCollector.occurrenceID;

ALTER TABLE tempCollector
ADD FOREIGN KEY (AgentID) REFERENCES tempAgent.AgentID;

ALTER TABLE tempDetermination
ADD FOREIGN KEY (AgentID) REFERENCES tempAgent.AgentID;

ALTER TABLE tempDetermination
ADD FOREIGN KEY (CollectionObjectID) REFERENCES tempColObject.TempColObjectID;

ALTER TABLE tempColEvent
ADD FOREIGN KEY (LocalityID) REFERENCES tempLocality.LocalityID;

INSERT INTO tempCollector(occurrenceID, AgentID)
SELECT occurrenceID, AgentID FROM tempAgent; 


UPDATE tempCollector JOIN (SELECT occurrenceID, MIN(TempCollectorID) as minValue FROM tempCollector GROUP BY occurrenceID) tMin ON tempCollector.occurrenceID = tMin.occurrenceID AND tempCollector.TempCollectorID = tMin.minValue
SET isPrimary = 1;

UPDATE tempCollector JOIN (SELECT occurrenceID, AgentID, MIN(TempCollectorID) as minValue FROM tempCollector GROUP BY AgentID) tMin ON tempCollector.AgentID = tMin.AgentID
SET CollectorID = tMin.minValue;

UPDATE tempDetermination
SET AgentID = (SELECT AgentID FROM tempAgent WHERE tempDetermination.occurrenceID = tempAgent.occurrenceID);

UPDATE tempDetermination
SET CollectionObjectID = (SELECT TempColObjectID FROM tempColObject WHERE tempDetermination.occurrenceID = tempColObject.occurrenceID);

-- handle localities --

UPDATE tempLocality JOIN (SELECT Remarks, Latitude1, Longitude1, MIN(TempLocalityID) as minValue FROM tempLocality GROUP BY Remarks) tMin ON tempLocality.Remarks = tMin.Remarks AND tempLocality.Latitude1 = tMin.Latitude1 AND tempLocality.Longitude1 = tMin.Longitude1 
SET LocalityID = tMin.minValue;

UPDATE tempLocality
SET LocalityID = TempLocalityID WHERE LocalityID IS NULL;

-- link locality/collector to CollectingEvent --

UPDATE tempColEvent
SET LocalityID = (SELECT LocalityID FROM tempLocality WHERE tempColEvent.occurrenceID = tempLocality.occurrenceID); 

UPDATE tempColEvent
SET CollectorID = (SELECT CollectorID FROM tempCollector WHERE tempColEvent.occurrenceID = tempCollector.occurrenceID AND tempCollector.IsPrimary IS NOT NULL);

-- handle ColEvent --

UPDATE tempColEvent JOIN (SELECT StartDate, LocalityID, CollectorID, MIN(TempColEventID) as minValue FROM tempColEvent GROUP BY StartDate) tMin ON tempColEvent.StartDate = tMin.StartDate AND tempColEvent.LocalityID = tMin.LocalityID AND tempColEvent.CollectorID = tMin.CollectorID
SET CollectionEventID = tMin.minValue;

UPDATE tempColEvent
SET CollectionEventID = TempColEventID WHERE CollectionEventID IS NULL;

-- link colevent to colobj/collector --

UPDATE tempColObject 
SET CollectionEventID = (SELECT CollectionEventID FROM tempColEvent WHERE tempColEvent.occurrenceID = tempColObject.occurrenceID);

UPDATE tempCollector
SET CollectingEventID = (SELECT CollectionEventID FROM tempColEvent WHERE tempColEvent.occurrenceID = tempCollector.occurrenceID);

ALTER TABLE tempAgent
DROP FOREIGN KEY occurrenceID;  

ALTER TABLE tempLocality
DROP FOREIGN KEY occurrenceID;

ALTER TABLE tempColEvent
DROP FOREIGN KEY occurrenceID;

ALTER TABLE tempColObject
DROP FOREIGN KEY occurrenceID;
	
ALTER TABLE tempDetermination
DROP FOREIGN KEY occurrenceID;

DELETE FROM tempAgent WHERE tempAgent.AgentID != tempAgent.TempAgentID;

DELETE FROM tempColEvent WHERE tempColEvent.CollectionEventID != tempColEvent.TempColEventID;

DELETE FROM tempLocality WHERE tempLocality.LocalityID != tempLocality.tempLocalityID;