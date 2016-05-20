-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
-- AUTHOR: VAUGHN SHIREY
-- Description: Moves core occurrence data through a Darwin Core view into tables that align with Specify.
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

-- Remove previous tables used in handling specimen data --

-- Begin inserting into the official Specify tables --

INSERT INTO agent (AgentID, TimestampCreated, Version, AgentType, FirstName, LastName, DivisionID)
SELECT AgentID, now(), 0 as Version, 1 as AgentType, FirstName, LastName FROM tempAgent;

INSERT INTO locality (LocalityID, TimestampCreated, Version, Latitude1, Longitude1, MaxElevation, Remarks, VerbatimLatitude, VerbatimLongitude, DisciplineID)
SELECT LocalityID + 2011, now(), 0 as Version, Latitude1, Longitude1, MaxElevation, Long1Text, VerbatimLatitude, VerbatimLongitude, 3 as DisciplineID FROM tempLocality;

INSERT INTO collectingevent (CollectingEventID, TimestampCreated, Version, StartDate, LocalityID, DisciplineID)
SELECT CollectionEventID + 2017, now(), 0 as Version, StartDate, LocalityID + 2011, 3 as DisciplineID FROM tempColEvent;

INSERT INTO collector (CollectorID, TimestampCreated, Version, IsPrimary, DivisionID, CollectingEventID, AgentID)
SELECT tempCollectorID + 2793, now(), 0 as Version, IsPrimary, 2 as DivisionID, CollectingEventID + 2017, AgentID FROM tempCollector;

INSERT INTO collectionobject (CollectionObjectID, TimestampCreated, Version, CollectionMemberID, CollectingEventID, CollectionID, CatalogNumber, AltCatalogNumber)
SELECT TempColObjectID + 2017, now(), 0 as Version, 4 as CollectionMemberID, CollectionEventID + 2017, 4 as CollectionID, CatalogNumber, AltCatalogNumber FROM tempColObject;

-- Handle taxonomy prior to linking determinations --
