-- Update taxonID after importing DwC archive to corresponse with new authority file --

-- Run this step if TaxonID already exists --
-- ALTER TABLE dwc_archive
-- DROP COLUMN TaxonID;

ALTER TABLE dwc_archive
ADD COLUMN TaxonID VARCHAR(20);

-- First set all records to Vertebrate update to search for ID

UPDATE dwc_archive
SET dwc_archive.TaxonID = 1833967;

-- Then update for more specific names

UPDATE dwc_archive INNER JOIN (SELECT Name, TaxonID FROM taxon WHERE CollectionCode = "VP") as taxa ON dwc_archive.order = taxa.Name
SET dwc_archive.TaxonID = taxa.TaxonID;

UPDATE dwc_archive INNER JOIN (SELECT Name, TaxonID FROM taxon WHERE CollectionCode = "VP") as taxa ON dwc_archive.family = taxa.Name
SET dwc_archive.TaxonID = taxa.TaxonID;

UPDATE dwc_archive INNER JOIN (SELECT Name, TaxonID FROM taxon WHERE CollectionCode = "VP") as taxa ON dwc_archive.genus = taxa.Name
SET dwc_archive.TaxonID = taxa.TaxonID;

UPDATE dwc_archive INNER JOIN (SELECT Name, TaxonID FROM taxon WHERE CollectionCode = "VP") as taxa ON dwc_archive.specificEpithet = taxa.Name
SET dwc_archive.TaxonID = taxa.TaxonID;

-- Some valid names may not match because they were not in the authority file to begin with