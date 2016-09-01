-- Update taxonID after importing DwC archive to corresponse with new authority file --

UPDATE temptaxonomy SET temptaxonomy.PID = "2" WHERE FullName = "Vertebrata";
UPDATE temptaxonomy SET temptaxonomy.ParentName = "Animalia" WHERE FullName = "Vertebrata";

-- Run this step if TaxonID already exists --
ALTER TABLE dwc_archive
DROP COLUMN TaxonID;

ALTER TABLE dwc_archive
ADD COLUMN TaxonID VARCHAR(20);

-- First set all records to Vertebrate update to search for ID

UPDATE dwc_archive
SET dwc_archive.TaxonID = "";

-- Then update for more specific names

UPDATE dwc_archive INNER JOIN (SELECT FullName, TID FROM temptaxonomy) as taxa ON dwc_archive.order = taxa.FullName
SET dwc_archive.TaxonID = taxa.TID;

UPDATE dwc_archive INNER JOIN (SELECT FullName, TID FROM temptaxonomy) as taxa ON dwc_archive.family = taxa.FullName
SET dwc_archive.TaxonID = taxa.TID;

UPDATE dwc_archive INNER JOIN (SELECT FullName, TID FROM temptaxonomy) as taxa ON dwc_archive.genus = taxa.FullName
SET dwc_archive.TaxonID = taxa.TID;

UPDATE dwc_archive INNER JOIN (SELECT FullName, TID FROM temptaxonomy) as taxa ON dwc_archive.specificEpithet = taxa.FullName
SET dwc_archive.TaxonID = taxa.TID;

-- Some valid names may not match because they were not in the authority file to begin with