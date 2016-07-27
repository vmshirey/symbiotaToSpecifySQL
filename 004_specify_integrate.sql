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
DELETE * FROM specifyIDReference;
INSERT INTO specifyIDReference(placeholderKey, previousLocalityMax, previousColEventMax, previousColObjectMax)
SELECT 1 as placeholderKey, MAX(LocalityID), MAX(CollectionEventID), MAX(CollectionObjectID) FROM locality, collectionEvent, collectionObject;

-- Create a reference table for taxonomy rankID definitions --
DROP TABLE IF EXISTS rankIDDef;
CREATE TABLE rankIDDef(
	TaxonTreeDefItemID int(10) NOT NULL PRIMARY KEY,
	rankID int(10)
);
INSERT INTO rankIDDef(TaxonTreeDefItemID, rankID)
VALUES (1, 0), (2, 10), (3, 30), (9, 40), (4, 60), (5, 100), (6, 140), (7, 180), (10, 190), (8, 220), (11, 230), (12, 240), (13, 260), (14, 50);

-- Insert values that do not rely on updating numbers based on the previous maximum number for each table --
INSERT INTO agent (AgentID, TimestampCreated, Version, AgentType, FirstName, LastName, DivisionID)
SELECT AgentID, now(), 0 as Version, 1 as AgentType, FirstName, LastName, 2 as DivisionID FROM tempAgent;

INSERT INTO locality (TimestampCreated, Version, Latitude1, Longitude1, MaxElevation, Remarks, VerbatimLatitude, VerbatimLongitude, DisciplineID, Country, `State`, County)
SELECT  now(), 0 as Version, Latitude1, Longitude1, MaxElevation, Long1Text, VerbatimLatitude, VerbatimLongitude, 3 as DisciplineID, Country, `State`, County  FROM tempLocality;

-- Insert values that do rely on updating numbers --
INSERT INTO collectingevent (TimestampCreated, Version, StartDate, LocalityID, DisciplineID)
SELECT  now(), 0 as Version, StartDate, SUM(LocalityID, specifyIDReference.previousLocalityMax), 3 as DisciplineID 
FROM tempColEvent, specifyIDReference WHERE specifyIDReference.placeholderKey = 1;

INSERT INTO collector (TimestampCreated, Version, IsPrimary, DivisionID, CollectingEventID, AgentID)
SELECT now(), 0 as Version, IsPrimary, 2 as DivisionID, SUM(CollectingEventID, specifyIDReference.previousColEventMax), AgentID 
FROM tempCollector, specifyIDReference WHERE specifyIDReference.placeholderKey = 1;

INSERT INTO collectionobject (TimestampCreated, Version, CollectionMemberID, CollectingEventID, CollectionID, CatalogNumber, AltCatalogNumber, previousOccid)
SELECT now(), 0 as Version, 4 as CollectionMemberID, SUM(CollectingEventID, specifyIDReference.previousColEventMax), 4 as CollectionID, CatalogNumber, AltCatalogNumber, occid 
FROM tempColObject, specifyIDReference WHERE specifyIDReference.placeholderKey = 1;

-- Insert taxonomy --
INSERT INTO taxon (TimestampCreated, IsAccepted, IsHybrid, Version, FullName, `Name`, RankID, TaxonTreeDefID, TaxonTreeDefItemID, PreviousParentID, ParentName, PreviousTaxonID, CollectionCode)
SELECT now(), 1 as IsAccepted, 0 as IsHybrid, Version, FullName, SUBSTRING_INDEX(`FullName`, ' ', -1) as `Name`, RankID, TaxonTreeDefID, 1 as TaxonTreeDefItemID, PreviousPID, ParentName, PreviousTID, 'VP' as CollectionCode FROM taxon_reclamation;

UPDATE taxon (SELECT taxon.RankID, rankIDDef.TaxonTreeDefItemID FROM taxon INNER JOIN rankIDDef) AS taxrank ON taxrank.RankID = rankIDDef.rankID
SET taxon.TaxonTreeDefItemID = taxrank.TaxonTreeDefItemID WHERE CollectionCode = '';

UPDATE taxon INNER JOIN (SELECT TaxonID, PreviousTaxonID FROM taxon WHERE CollectionCode = '') AS parents ON parents.PreviousTaxonID = taxon.PreviousParentID
SET taxon.ParentID = parents.TaxonID WHERE CollectionCode = '';

UPDATE taxon INNER JOIN (SELECT TaxonID, PreviousTaxonID, Name FROM taxon WHERE CollectionCode = '') AS parents ON parents.PreviousTaxonID = taxon.PreviousParentID
SET taxon.ParentName = parents.Name WHERE CollectionCode = '';

-- Insert determinations for reassociation with Specify taxonomy --
INSERT INTO determination (TimestampCreated, Version, CollectionMemberID, oldTaxonID, CollectionObjectID, DeterminerID)
SELECT collectionobject.TimestampCreated, 1 as Version, 4 as CollectionMemberID, TaxonID, collectionobject.CollectionObjectID, AgentID
FROM tempDetermination, collectionobject;

-- Update determinations to corresponse with new taxonomy tree --
UPDATE determination INNER JOIN (SELECT TaxonID FROM taxon WHERE CollectionCode = "") as taxa ON determination.oldTaxonID = taxa.TaxonID
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