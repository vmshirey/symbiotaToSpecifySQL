-- Insert temporary table into Specify and update parentIDs --

-- 1. Insert into Specify --
SET FOREIGN_KEY_CHECKS=0;
DELETE from taxon WHERE CollectionCode = "VP";
INSERT INTO taxon (TimestampCreated, IsAccepted, IsHybrid, Version, FullName, `Name`, RankID, TaxonTreeDefID, TaxonTreeDefItemID, PreviousParentID, ParentName, PreviousTaxonID, CollectionCode)
SELECT now(), 1 as IsAccepted, 0 as IsHybrid, Version, FullName, SUBSTRING_INDEX(`FullName`, ' ', -1) as `Name`, RankID, TaxonTreeDefID, 1, PreviousPID, ParentName, PreviousTID, CollectionCode FROM temptaxonomy;

DROP TABLE temptaxonomy;
DROP TABLE auth_taxa;
DROP VIEW auth_view;

-- after in Specify update parent IDs from new taxon id and add names --

UPDATE taxon INNER JOIN (SELECT TaxonID, PreviousTaxonID FROM taxon WHERE CollectionCode = "VP") AS parents ON parents.PreviousTaxonID = taxon.PreviousParentID
SET taxon.ParentID = parents.TaxonID WHERE CollectionCode = "VP";

UPDATE taxon INNER JOIN (SELECT TaxonID, PreviousTaxonID, Name FROM taxon WHERE CollectionCode = "VP") AS parents ON parents.PreviousTaxonID = taxon.PreviousParentID
SET taxon.ParentName = parents.Name WHERE CollectionCode = "VP";

UPDATE taxon SET taxon.ParentID = "2" WHERE FullName = "Vertebrata";
UPDATE taxon SET taxon.ParentName = "Animalia" WHERE FullName = "Vertebrata";

SET FOREIGN_KEY_CHECKS=1;