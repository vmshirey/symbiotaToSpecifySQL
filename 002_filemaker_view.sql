-- ------------------------------------------------------
-- Creates a view of data from a Darwin Core archive   --
-- ------------------------------------------------------

DROP VIEW IF EXISTS dwc_view; 
CREATE VIEW dwc_view AS
SELECT occurrenceID, 
catalogNumber, 
otherCatalogNumbers, 
taxonID,
null as eventDate,
verbatimEventDate, 
null as decimalLatitude, 
null as decimalLongitude, 
verbatimCoordinates, 
null as minimumElevationInMeters,
null as maximumElevationInMeters,
null as verbatimElevation,
verbatimLocality AS locality, 
identifiedBy, 
recordedBy, 
country,
stateProvince, 
county,
'order',
family, 
genus,
specificEpithet,
scientificName,
basisofrecord
FROM dwc_archive;

-- ------------------------------------------------------
-- END                                        		   --
-- ------------------------------------------------------