-- Imports Darwincore archive, order of fields matches the output expected from our FileMaker instance --

USE `darwincorevp`;
DROP TABLE `dwcarchive`;
CREATE TABLE `dwcarchive` 
(`otherCatalogNumbers` VARCHAR(16),
`institutioncode` VARCHAR(4),
`collectioncode` VARCHAR(32),
`catalognumber` VARCHAR(8),
`typestatus` VARCHAR(256),
`individualcount` VARCHAR(32),
`higherclassification` VARCHAR(256),
`order` VARCHAR(64),
`family` VARCHAR(64),
`genus` VARCHAR(64),
`specificEpithet` VARCHAR(64),
`scientificname` VARCHAR(256),
`identificationqualifier` VARCHAR(256),
`identifiedby` VARCHAR(64),
`dateidentified` VARCHAR(16),
`taxonremarks` VARCHAR(256),
`identificationremarks` VARCHAR(256),
`preparations` VARCHAR(256),
`recordedby` VARCHAR(64),
`verbatimcoordinates` VARCHAR(256),
`decimallatitude` VARCHAR(16),
`decimallongitude` VARCHAR(16),
`geodeticdatum` VARCHAR(16),
`georeferencedby` VARCHAR(64),
`georeferenceddate` VARCHAR(16),
`georeferencedremarks` VARCHAR(256),
`fieldnumber` VARCHAR(64), 
`verbatimeventdate` VARCHAR(64),
`month` VARCHAR(8),
`day` VARCHAR(8),
`year` VARCHAR(8), 
`continent` VARCHAR(16),
`country` VARCHAR(64),
`stateprovince` VARCHAR(64),
`county` VARCHAR(64),
`verbatimlocality` VARCHAR(256),
`locationremarks` VARCHAR(256),
`eventremarks` VARCHAR(256),
`occurrenceremarks` VARCHAR(256),
`fieldnotes` VARCHAR(256),
`earliestageorlowestage` VARCHAR(64),
`lithostratigraphicterms` VARCHAR(256),
`type` VARCHAR(16),
`basisofrecord` VARCHAR(16),
`datasetname` VARCHAR(64),
`disposition` VARCHAR(256),
`modified` VARCHAR(16),
`bibliographiccitation` VARCHAR(256),
`associatedmedia` VARCHAR(256),
`associatedreferences` VARCHAR(256));
TRUNCATE TABLE `dwcarchive`;

-- Update file name for import--

LOAD DATA LOCAL INFILE 'D:\dwc_tab' INTO TABLE `dwcarchive`;

ALTER TABLE dwcarchive ADD occurrenceID INT(10) auto_increment PRIMARY KEY -- Need integer value for Specify --