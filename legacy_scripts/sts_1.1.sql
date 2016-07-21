DELETE FROM tempLocality;
INSERT INTO tempLocality(OccID, Latitude1, Longitude1, MaxElevation, MinElevation, VerbatimElevation, Long1Text, VerbatimLatitude, VerbatimLongitude)
	SELECT occid, decimalLatitude, decimalLongitude, maximumElevationInMeters, minimumElevationInMeters, verbatimElevation, locality, SUBSTRING_INDEX(vCoord, ' ', 1) AS VerbatimLatitude, 
	SUBSTRING_INDEX(vCoord, ' ', -1) AS VerbatimLongitude 
	FROM (SELECT occid, decimalLatitude, decimalLongitude, maximumElevationInMeters, minimumElevationInMeters, verbatimElevation, locality, verbatimCoordinates AS vCoord FROM dwc_view) AS localityTable ORDER BY locality;
	
-- BEGIN INSERT WITH TEMPORARY COLLECTION EVENTS --
DELETE FROM tempColEvent;
INSERT INTO tempColEvent(OccID, StartDate, VerbatimDate)
	SELECT occid, eventDate, verbatimEventDate
	FROM dwc_view;
	
-- BEGIN INSERT INTO TEMPORARY COLLECTORS --	
-- INSERT INTO tempCollector(OccID, AgentID)
-- 	SELECT dwc.occid, tAgent.tempAgentID 
-- 	FROM dwc_view AS dwc, tempAgent AS tAgent WHERE dwc.occid = tAgent.occid;
	
-- BEGIN INSERT INTO TEMPORARY COLLECTION OBJECT --
DELETE FROM tempColObject;
INSERT INTO tempColObject(OccID, AltCatalogNumber, CatalogNumber)
	SELECT occid, otherCatalogNumbers, catalogNumber
	FROM dwc_view;

-- BEGIN INSERT INTO TEMPORARY DETERMINATIONS --
DELETE FROM tempDetermination;
INSERT INTO tempDetermination(OccID, TaxonID, CollectionObjectID)
	SELECT dwc.occid, dwc.taxonID, tempColObj.CollectionObjectID 
	FROM dwc_view AS dwc, tempColObject AS tempColObj WHERE dwc.occid = tempColObj.occid;

ALTER TABLE tempAgent
ADD FOREIGN KEY (OccID) REFERENCES tempLocality.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColEvent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColObject.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempDetermination.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempCollector.OccID; 

ALTER TABLE tempLocality
ADD FOREIGN KEY (OccID) REFERENCES tempAgent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColEvent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColObject.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempDetermination.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempCollector.OccID; 

ALTER TABLE tempColEvent
ADD FOREIGN KEY (OccID) REFERENCES tempAgent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempLocality.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColObject.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempDetermination.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempCollector.OccID;

ALTER TABLE tempColObject
ADD FOREIGN KEY (OccID) REFERENCES tempAgent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempLocality.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColEvent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempDetermination.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempCollector.OccID;
	
ALTER TABLE tempDetermination
ADD FOREIGN KEY (OccID) REFERENCES tempAgent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempLocality.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColEvent.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempColObject.OccID, 
ADD FOREIGN KEY (OccID) REFERENCES tempCollector.OccID;