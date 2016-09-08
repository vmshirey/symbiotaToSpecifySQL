-- Update taxonID after importing DwC archive to corresponse with new authority file --

UPDATE tempTaxonomy SET tempTaxonomy.PID = "1" WHERE `Name` = "Vertebrata";
UPDATE tempTaxonomy SET tempTaxonomy.ParentName = "Animalia" WHERE `Name` = "Vertebrata";

-- Run this step if TaxonID and UnrankedClade already exist --

-- ALTER TABLE dwc_archive
-- DROP COLUMN TaxonID;

-- ALTER TABLE dwc_archive
-- DROP COLUMN UnrankedClade;

-- Add remaining fields needed for determination and taxon ID --

ALTER TABLE dwc_archive
ADD COLUMN TaxonID VARCHAR(20);

ALTER TABLE dwc_archive
ADD COLUMN UnrankedClade VARCHAR(64);

UPDATE dwc_archive
SET dwc_archive.unrankedclade = SUBSTRING_INDEX(higherclassification, ' ', -1);

-- Then update for more specific names
UPDATE dwc_archive INNER JOIN (SELECT `Name`, TID FROM tempTaxonomy) as taxa ON dwc_archive.unrankedclade = taxa.Name
SET dwc_archive.TaxonID = taxa.TID;

UPDATE dwc_archive INNER JOIN (SELECT `Name`, TID FROM tempTaxonomy) as taxa ON dwc_archive.order = taxa.Name
SET dwc_archive.TaxonID = taxa.TID;

UPDATE dwc_archive INNER JOIN (SELECT `Name`, TID FROM tempTaxonomy) as taxa ON dwc_archive.family = taxa.Name
SET dwc_archive.TaxonID = taxa.TID;

UPDATE dwc_archive INNER JOIN (SELECT `Name`, TID FROM tempTaxonomy) as taxa ON dwc_archive.genus = taxa.Name
SET dwc_archive.TaxonID = taxa.TID;

UPDATE dwc_archive INNER JOIN (SELECT `Name`, TID FROM tempTaxonomy) as taxa ON dwc_archive.specificEpithet = taxa.Name
SET dwc_archive.TaxonID = taxa.TID;

-- Some valid names may not match because they were not in the authority file to begin with, check for errors using the script below --

-- SELECT * FROM specify_sandbox.dwc_archive WHERE TaxonID IS NULL;