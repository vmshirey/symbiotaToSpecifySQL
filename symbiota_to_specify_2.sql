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