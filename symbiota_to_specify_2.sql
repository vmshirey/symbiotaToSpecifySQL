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

INSERT INTO collectionobject (TimestampCreated, Version, CollectionMemberID, CollectingEventID, CollectionID, CatalogNumber, AltCatalogNumber)
SELECT now(), 0 as Version, 4 as CollectionMemberID, CollectionEventID + 2017, 4 as CollectionID, CatalogNumber, AltCatalogNumber FROM tempColObject;

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

UPDATE taxon LEFT JOIN (SELECT TaxonID, PreviousTaxonID FROM taxon WHERE CollectionCode = "PH") AS parents ON parents.PreviousTaxonID = taxon.PreviousParentID
SET taxon.ParentID = parents.TaxonID WHERE CollectionCode = "PH";