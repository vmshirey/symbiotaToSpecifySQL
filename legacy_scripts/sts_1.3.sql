ALTER TABLE tempAgent
DROP FOREIGN KEY OccID;  

ALTER TABLE tempLocality
DROP FOREIGN KEY OccID;

ALTER TABLE tempColEvent
DROP FOREIGN KEY OccID;

ALTER TABLE tempColObject
DROP FOREIGN KEY OccID;
	
ALTER TABLE tempDetermination
DROP FOREIGN KEY OccID;

DELETE FROM tempAgent WHERE tempAgent.AgentID != tempAgent.TempAgentID;

DELETE FROM tempColEvent WHERE tempColEvent.CollectionEventID != tempColEvent.TempColEventID;

DELETE FROM tempLocality WHERE tempLocality.LocalityID != tempLocality.tempLocalityID;