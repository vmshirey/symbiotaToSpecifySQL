ALTER TABLE tempCollector
ADD FOREIGN KEY (AgentID) REFERENCES tempAgent.AgentID;

ALTER TABLE tempDetermination
ADD FOREIGN KEY (AgentID) REFERENCES tempAgent.AgentID;

ALTER TABLE tempDetermination
ADD FOREIGN KEY (CollectionObjectID) REFERENCES tempColObject.TempColObjectID;

ALTER TABLE tempColEvent
ADD FOREIGN KEY (LocalityID) REFERENCES tempLocality.LocalityID;

INSERT INTO tempCollector(OccID, AgentID)
SELECT OccID, AgentID FROM tempAgent WHERE tempAgent.AgentType IS NULL;

-- set primary collectors --
UPDATE tempCollector JOIN (SELECT OccID, MIN(TempCollectorID) as minValue FROM tempCollector GROUP BY OccID) tMin ON tempCollector.OccID = tMin.OccID AND tempCollector.TempCollectorID = tMin.minValue
SET isPrimary = 1;

UPDATE tempCollector JOIN (SELECT OccID, AgentID, MIN(TempCollectorID) as minValue FROM tempCollector GROUP BY AgentID) tMin ON tempCollector.AgentID = tMin.AgentID
SET CollectorID = tMin.minValue;

UPDATE tempDetermination
SET AgentID = (SELECT AgentID FROM tempAgent WHERE tempDetermination.OccID = tempAgent.OccID AND tempAgent.AgentType = 2);

UPDATE tempDetermination
SET CollectionObjectID = (SELECT TempColObjectID FROM tempColObject WHERE tempDetermination.OccID = tempColObject.OccID);

-- handle localities --

UPDATE tempLocality JOIN (SELECT Long1Text, Latitude1, Longitude1, MIN(TempLocalityID) as minValue FROM tempLocality GROUP BY Long1Text) tMin ON tempLocality.Long1Text = tMin.Long1Text OR tempLocality.Latitude1 = tMin.Latitude1 AND tempLocality.Longitude1 = tMin.Longitude1 
SET LocalityID = tMin.minValue;

UPDATE tempLocality
SET LocalityID = TempLocalityID WHERE LocalityID IS NULL;

-- link locality/collector to CollectingEvent --

UPDATE tempColEvent
SET LocalityID = (SELECT LocalityID FROM tempLocality WHERE tempColEvent.OccID = tempLocality.OccID); 

UPDATE tempColEvent
SET CollectorID = (SELECT MIN(CollectorID) FROM tempCollector WHERE tempColEvent.OccID = tempCollector.OccID);

-- handle ColEvent --

UPDATE tempColEvent JOIN (SELECT StartDate, LocalityID, CollectorID, MIN(TempColEventID) as minValue FROM tempColEvent GROUP BY StartDate) tMin ON tempColEvent.StartDate = tMin.StartDate AND tempColEvent.LocalityID = tMin.LocalityID AND tempColEvent.CollectorID = tMin.CollectorID
SET CollectionEventID = tMin.minValue;

UPDATE tempColEvent
SET CollectionEventID = TempColEventID WHERE CollectionEventID IS NULL;

-- link colevent to colobj --

UPDATE tempColObject 
SET CollectionEventID = (SELECT CollectionEventID FROM tempColEvent WHERE tempColEvent.OccID = tempColObject.OccID);




