ALTER TABLE tempCollector
ADD FOREIGN KEY (AgentID) REFERENCES tempAgent.AgentID;

INSERT INTO tempCollector(OccID, AgentID)
SELECT OccID, AgentID FROM tempAgent;

UPDATE tempCollector
SET IsPrimary = CASE 
WHEN AgentID = (SELECT MIN(AgentID)FROM tempAgent AS t WHERE t.OccID = tempCollector.OccID)  THEN '1'
ELSE NULL
END