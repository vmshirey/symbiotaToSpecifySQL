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
	previousColObjectMax int(10),
	previousAgentMax int(10)
);
TRUNCATE TABLE specifyIDReference;
INSERT INTO specifyIDReference(placeholderKey, previousLocalityMax, previousColEventMax, previousColObjectMax, previousAgentMax)
SELECT 1 as placeholderKey, MAX(locality.LocalityID), MAX(collectingevent.CollectingEventID), MAX(collectionobject.CollectionObjectID), MAX(agent.AgentID) FROM locality, collectingevent, collectionobject, agent

-- Create a reference table for taxonomy rankID definitions --
DROP TABLE IF EXISTS rankIDDef;
CREATE TABLE rankIDDef(
	TaxonTreeDefItemID int(10) NOT NULL PRIMARY KEY,
	rankID int(10)
);
INSERT INTO rankIDDef(TaxonTreeDefItemID, rankID)
VALUES (1, 0), (2, 10), (3, 30), (9, 40), (4, 60), (5, 100), (6, 140), (7, 180), (10, 190), (8, 220), (11, 230), (12, 240), (13, 260), (14, 50);

-- Insert values that do not rely on updating numbers based on the previous maximum number for each table --
INSERT INTO agent (TimestampCreated, Version, AgentType, FirstName, LastName, DivisionID)
SELECT now(), 0 as Version, 1 as AgentType, FirstName, LastName, 2 as DivisionID FROM tempAgent, specifyIDReference WHERE specifyIDReference.placeholderKey = 1;

INSERT INTO locality (TimestampCreated, Version, Latitude1, Longitude1, MaxElevation, Remarks, VerbatimLatitude, VerbatimLongitude, DisciplineID, Country, `State`, County)
SELECT  now(), 0 as Version, Latitude1, Longitude1, MaxElevation, Remarks, VerbatimLatitude, VerbatimLongitude, 3 as DisciplineID, Country, `State`, County  FROM tempLocality;

-- Insert values that do rely on updating numbers --
INSERT INTO collectingevent (TimestampCreated, Version, StartDate, LocalityID, DisciplineID)
SELECT  now(), 0 as Version, StartDate, LocalityID + previousLocalityMax, 3 as DisciplineID 
FROM tempColEvent, specifyIDReference WHERE specifyIDReference.placeholderKey = 1;

INSERT INTO collector (TimestampCreated, Version, IsPrimary, DivisionID, CollectingEventID, AgentID)
SELECT now(), 0 as Version, IsPrimary, 2 as DivisionID, CollectingEventID + previousColEventMax, AgentID+previousAgentMax 
FROM tempCollector, specifyIDReference WHERE specifyIDReference.placeholderKey = 1;

INSERT INTO collectionobject (TimestampCreated, Version, CollectionMemberID, CollectingEventID, CollectionID, CatalogNumber, AltCatalogNumber, previousOccid)
SELECT now(), 0 as Version, 4 as CollectionMemberID, CollectionEventID + previousColEventMax, 4 as CollectionID, CatalogNumber, AltCatalogNumber, occurrenceID 
FROM tempColObject, specifyIDReference WHERE specifyIDReference.placeholderKey = 1;

-- Insert taxonomy (USE APPROPRIATE COLLECTION CODE)--
INSERT INTO taxon (TimestampCreated, IsAccepted, IsHybrid, Version, FullName, `Name`, RankID, TaxonTreeDefID, TaxonTreeDefItemID, PreviousParentID, ParentName, PreviousTaxonID, CollectionCode)
SELECT now(), 1 as IsAccepted, 0 as IsHybrid, Version, FullName, SUBSTRING_INDEX(`FullName`, ' ', -1) as `Name`, RankID, TaxonTreeDefID, 1 as TaxonTreeDefItemID, PreviousPID, ParentName, PreviousTID, 'VP' as CollectionCode FROM tempTaxonomy;

UPDATE taxon (SELECT taxon.RankID, rankIDDef.TaxonTreeDefItemID FROM taxon INNER JOIN rankIDDef) AS taxrank ON taxrank.RankID = rankIDDef.rankID
SET taxon.TaxonTreeDefItemID = taxrank.TaxonTreeDefItemID WHERE CollectionCode = 'VP'; -- Collection code needs to be changed depending on import

UPDATE taxon INNER JOIN (SELECT TaxonID, PreviousTaxonID FROM taxon WHERE CollectionCode = 'VP') AS parents ON parents.PreviousTaxonID = taxon.PreviousParentID
SET taxon.ParentID = parents.TaxonID WHERE CollectionCode = 'VP'; -- Collection code needs to be changed depending on import

UPDATE taxon INNER JOIN (SELECT TaxonID, PreviousTaxonID, Name FROM taxon WHERE CollectionCode = 'VP') AS parents ON parents.PreviousTaxonID = taxon.PreviousParentID
SET taxon.ParentName = parents.Name WHERE CollectionCode = 'VP'; -- Collection code needs to be changed depending on import

-- Insert determinations for reassociation with Specify taxonomy --
INSERT INTO determination (TimestampCreated, Version, CollectionMemberID, oldTaxonID, CollectionObjectID, DeterminerID)
SELECT now() as TimestampCreated, 1 as Version, 4 as CollectionMemberID, TaxonID, tempDetermination.CollectionObjectID+previousColObjectMax, AgentID+previousAgentMax
FROM tempDetermination, collectionobject, specifyIDReference WHERE placeholderKey = 1;

-- Update determinations to corresponse with new taxonomy tree --
UPDATE determination INNER JOIN (SELECT TaxonID FROM taxon WHERE CollectionCode = "") as taxa ON determination.oldTaxonID = taxa.TaxonID -- Collection code needs to be changed depending on import
SET determination.TaxonID = taxa.TaxonID, PreferredTaxonID = taxa.TaxonID, IsCurrent = 1;

-- Update Localities --
UPDATE locality  
SET GeographyID = (SELECT geographyID FROM 
(SELECT geography.geographyID, `state`, county, ParentID
FROM locality, geography 
LEFT JOIN (SELECT g.name AS stateName, g.geographyID
	FROM geography AS g) AS parents ON geography.ParentID = parents.geographyID  
	WHERE geography.name = locality.county
	AND locality.`state` = parents.stateName) AS finalID);
	
UPDATE locality JOIN (SELECT * FROM geography JOIN (SELECT GeographyID as geoID, Name AS ParentName FROM geography) AS parent ON parent.geoID = geography.ParentID) AS geo 
ON geo.FullName LIKE CONCAT('%', geo.ParentName, '%', geo.Name, '%')
SET locality.GeographyID = geo.GeographyID
WHERE GETDATE(locality.TimestampCreated) = CURDATE() 
AND locality.GeographyID IS NULL;

UPDATE locality JOIN geography ON geography.Name LIKE locality.country
SET locality.GeographyID = geography.GeographyID
WHERE GETDATE(locality.TimestampCreated) = CURDATE() 
AND locality.GeographyID IS NULL;