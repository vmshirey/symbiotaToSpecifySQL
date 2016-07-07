---------------------------------------------------------
-- STS 1a                                              --
-- Vaughn Shirey 2016                                  --
-- Creates a DwC View of Data from a Symbiota Instance --
---------------------------------------------------------

DROP VIEW IF EXISTS dwc_view; 
CREATE VIEW dwc_view AS
SELECT occid AS occurrenceID, 
catalogNumber, 
otherCatalogNumbers, 
tidinterpreted AS taxonID, 
eventDate, 
verbatimEventDate, 
decimalLatitude, 
decimalLongitude, 
verbatimCoordinates, 
minimumElevationInMeters, 
maximumElevationInMeters, 
verbatimElevation, 
locality, 
identifiedBy, 
recordedBy, 
country,
stateProvince, 
county, 
family, 
scientificName,
genus,
basisofrecord
FROM omoccurrences;

---------------------------------------------------------
-- END                                        		   --
---------------------------------------------------------