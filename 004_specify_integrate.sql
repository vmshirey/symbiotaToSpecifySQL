-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- AUTHOR: VAUGHN SHIREY
-- Description: Moves core occurrence data through a Darwin Core view into tables that align with Specify.
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Create a reference table for maintaining the previous maximum IDs for various Specify tables --
DROP TABLE IF EXISTS specifyIDReference;
CREATE TABLE specifyIDReference (
	placeholderKey int(10) NOT NULL PRIMARY KEY,
	previousLocalityMax int(10),
	previousColEventMax int(10),
	previousColObjectMax int(10)
);
INSERT INTO specifyIDReference(placeholderKey, previousLocalityMax, previousColEventMax, previousColObjectMax)
SELECT 1 as placeholderKey, MAX(LocalityID), MAX(CollectionEventID), MAX(CollectionObjectID) FROM locality, collectionEvent, collectionObject;

-- Create a reference table for taxonomy rankID definitions --
DROP TABLE IF EXISTS rankIDDef;
CREATE TABLE rankIDDef(
	TaxonTreeDefItemID int(10) NOT NULL PRIMARY KEY,
	rankID int(10)
);
INSERT INTO rankIDDef(TaxonTreeDefItemID, rankID)
VALUES (1, 0), (2, 10), (3, 30), (9, 40), (4, 60), (5, 100), (6, 140), (7, 180), (10, 190), (8, 220), (11, 230), (12, 240), (13, 260);

-- Insert values that do not rely on updating numbers based on the previous maximum number for each table --
INSERT INTO agent (AgentID, TimestampCreated, Version, AgentType, FirstName, LastName, DivisionID)
SELECT AgentID, now(), 0 as Version, 1 as AgentType, FirstName, LastName, 2 as DivisionID FROM tempAgent;

INSERT INTO locality (TimestampCreated, Version, Latitude1, Longitude1, MaxElevation, Remarks, VerbatimLatitude, VerbatimLongitude, DisciplineID, Country, `State`, County )
SELECT  now(), 0 as Version, Latitude1, Longitude1, MaxElevation, Long1Text, VerbatimLatitude, VerbatimLongitude, 3 as DisciplineID, Country, `State`, County  FROM tempLocality;

-- Insert values that do rely on updating numbers --
INSERT INTO collectingevent (TimestampCreated, Version, StartDate, LocalityID, DisciplineID)
SELECT  now(), 0 as Version, StartDate, SUM(LocalityID + specifyIDReference.previousColEventMax), 3 as DisciplineID FROM tempColEvent, specifyIDReference WHERE specifyIDReference.placeholderKey = 1;