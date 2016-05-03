ALTER TABLE tempCollector
ADD FOREIGN KEY (AgentID) REFERENCES tempAgent.AgentID;

INSERT INTO tempCollector(OccID, AgentID)
SELECT OccID, AgentID FROM tempAgent;

UPDATE tempCollector JOIN (SELECT OccID, MIN(TempCollectorID) as minValue FROM tempCollector GROUP BY OccID) tMin ON tempCollector.OccID = tMin.OccID AND tempCollector.TempCollectorID = tMin.minValue
SET isPrimary = 1;
