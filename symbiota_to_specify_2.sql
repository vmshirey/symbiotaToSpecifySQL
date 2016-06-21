-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- AUTHOR: VAUGHN SHIREY
-- Description: Moves core occurrence data through a Darwin Core view into tables that align with Specify.
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Remove previous tables used in handling specimen data --

-- Begin inserting into the official Specify tables --

INSERT INTO agent (AgentID, TimestampCreated, Version, AgentType, FirstName, LastName, DivisionID)
SELECT AgentID, now(), 0 as Version, 1 as AgentType, FirstName, LastName FROM tempAgent;

-- add geographyID to this! --
INSERT INTO locality (TimestampCreated, Version, Latitude1, Longitude1, MaxElevation, Remarks, VerbatimLatitude, VerbatimLongitude, DisciplineID)
SELECT  now(), 0 as Version, Latitude1, Longitude1, MaxElevation, Long1Text, VerbatimLatitude, VerbatimLongitude, 3 as DisciplineID FROM tempLocality;

INSERT INTO collectingevent (TimestampCreated, Version, StartDate, LocalityID, DisciplineID)
SELECT  now(), 0 as Version, StartDate, LocalityID + 2011, 3 as DisciplineID FROM tempColEvent;

INSERT INTO collector (TimestampCreated, Version, IsPrimary, DivisionID, CollectingEventID, AgentID)
SELECT now(), 0 as Version, IsPrimary, 2 as DivisionID, CollectingEventID + 2017, AgentID FROM tempCollector;

INSERT INTO collectionobject (TimestampCreated, Version, CollectionMemberID, CollectingEventID, CollectionID, CatalogNumber, AltCatalogNumber, previousOccid)
SELECT now(), 0 as Version, 4 as CollectionMemberID, CollectionEventID + 2017, 4 as CollectionID, CatalogNumber, AltCatalogNumber, occid FROM tempColObject;

-- Handle taxonomy prior to linking determinations --

-- Change collection code to be appropriate --
INSERT INTO taxon (TimestampCreated, Version, FullName, Name, RankID, TaxonTreeDefID, TaxonTreeDefItemID, PreviousParentID, ParentName, PreviousTaxonID, CollectionCode)
SELECT now(), 0 as Version, FullName, Name, RankID, TaxonTreeDefID, 1, ParentID, ParentName, TaxonID, "PH" as CollectionCode FROM taxon_reclamation;

UPDATE taxon
SET TaxonTreeDefItemID = 1 WHERE RankID = 0;
UPDATE taxon
SET TaxonTreeDefItemID = 2 WHERE RankID = 10;
UPDATE taxon
SET TaxonTreeDefItemID = 3 WHERE RankID = 30;
UPDATE taxon
SET TaxonTreeDefItemID = 9 WHERE RankID = 40;
UPDATE taxon
SET TaxonTreeDefItemID = 4 WHERE RankID = 60;
UPDATE taxon
SET TaxonTreeDefItemID = 5 WHERE RankID = 100;
UPDATE taxon
SET TaxonTreeDefItemID = 6 WHERE RankID = 140;
UPDATE taxon
SET TaxonTreeDefItemID = 7 WHERE RankID = 180;
UPDATE taxon
SET TaxonTreeDefItemID = 10 WHERE RankID = 190;
UPDATE taxon
SET TaxonTreeDefItemID = 8 WHERE RankID = 220;
UPDATE taxon
SET TaxonTreeDefItemID = 11 WHERE RankID = 230;
UPDATE taxon
SET TaxonTreeDefItemID = 12 WHERE RankID = 240;
UPDATE taxon
SET TaxonTreeDefItemID = 13 WHERE RankID = 260;

UPDATE taxon INNER JOIN (SELECT TaxonID, PreviousTaxonID FROM taxon WHERE CollectionCode = "PH") AS parents ON parents.PreviousTaxonID = taxon.PreviousParentID
SET taxon.ParentID = parents.TaxonID WHERE CollectionCode = "PH";

INSERT INTO determination (TimestampCreated, Version, CollectionMemberID, oldTaxonID, CollectionObjectID, DeterminerID)
SELECT collectionobject.TimestampCreated, 1 AS version, 4 as CollectionMemberID, TaxonID, collectionobject.CollectionObjectID, AgentID
FROM tempDetermination, collectionobject
WHERE collectionobject.TimestampCreated = '2016-05-18 10:27:15'
AND tempDetermination.CollectionObjectID = collectionobject.CollectionObjectID + 2017;

UPDATE determination INNER JOIN (SELECT TaxonID FROM taxon WHERE CollectionCode = "PH") AS taxa ON  determination.oldTaxonID = taxa.TaxonID
SET determination.TaxonID = taxa.TaxonID, PreferredTaxonID = taxa.TaxonID, IsCurrent = 1;

SELECT LocalityID, Country, `State`, County FROM tempLocality JOIN geography_view ON geography_view.OccID = tempLocality.OccID; -- 104650 v. 102639 = 2011 --

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
WHERE locality.TimestampCreated = "2016-05-18 10:11:17"
AND locality.GeographyID IS NULL;