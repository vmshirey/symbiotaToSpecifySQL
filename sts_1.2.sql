ALTER TABLE tempCollector
ADD FOREIGN KEY (AgentID) REFERENCES tempAgent.AgentID;

ALTER TABLE tempDetermination
ADD FOREIGN KEY (AgentID) REFERENCES tempAgent.AgentID;

INSERT INTO tempCollector(OccID, AgentID)
SELECT OccID, AgentID FROM tempAgent WHERE tempAgent.AgentType IS NULL;

-- set primary collectors --
UPDATE tempCollector JOIN (SELECT OccID, MIN(TempCollectorID) as minValue FROM tempCollector GROUP BY OccID) tMin ON tempCollector.OccID = tMin.OccID AND tempCollector.TempCollectorID = tMin.minValue
SET isPrimary = 1;

UPDATE tempDetermination
SET AgentID = (SELECT AgentID FROM tempAgent WHERE tempDetermination.OccID = tempAgent.OccID AND tempAgent.AgentType = 2);