-- ------------------------------------------------------
-- Creates a view of data from a Darwin Core archive   --
-- ------------------------------------------------------

USE darwincore;
DROP VIEW IF EXISTS dwc_view; 
CREATE VIEW dwc_view AS
SELECT occurrenceID, 
catalogNumber, 
otherCatalogNumbers, 
null as taxonID,
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
family, 
scientificName,
genus,
basisofrecord
FROM dwc_archive;

-- ------------------------------------------------------
-- END                                        		   --
-- ------------------------------------------------------