-- Create temporary MySQL table for taxonoy that can be easily inserted into Specify --

-- 1. Create table

DROP TABLE IF EXISTS tempTaxonomy;
CREATE TABLE IF NOT EXISTS tempTaxonomy(
`TID` INT(11) auto_increment PRIMARY KEY,
`PID` INT(11),
`TimestampCreated` datetime,
`Name` VARCHAR(128),
`TaxonRank` VARCHAR(16),
`RankID` VARCHAR(10),
`TaxonTreeDefID` VARCHAR(10),
`TaxonTreeDefItemID` VARCHAR(10),
`PreviousTID` VARCHAR(10),
`PreviousPID` VARCHAR(10),
`ParentName` VARCHAR(128),
`CollectionCode` VARCHAR(3)
); 

-- 2. Insert table with authority records for taxonomy --
INSERT INTO tempTaxonomy (TimestampCreated, `Name`, TaxonRank, TaxonTreeDefID, TaxonTreeDefItemID, PreviousTID, PreviousPID, ParentName, CollectionCode)
SELECT now(), `Name`, TaxonRank, 1 as TaxonTreeDefID, 1 as TaxonTreeDefItemID, TaxonID, ParentID, ParentName, "VP" as CollectionCode FROM auth_view;

UPDATE tempTaxonomy INNER JOIN (SELECT TID, PreviousTID FROM tempTaxonomy) AS parents ON parents.PreviousTID = tempTaxonomy.PreviousPID
SET tempTaxonomy.PID = parents.TID;

UPDATE tempTaxonomy INNER JOIN (SELECT TID, PreviousTID, `Name` FROM tempTaxonomy) AS parents ON parents.PreviousTID = tempTaxonomy.PreviousPID
SET tempTaxonomy.ParentName = parents.Name;

-- Update RankID and TaxonDef for Specify --

UPDATE tempTaxonomy
SET RankID = 0 WHERE TaxonRank = 'Life';
UPDATE tempTaxonomy
SET RankID = 10 WHERE TaxonRank = 'Kingdom';
UPDATE tempTaxonomy
SET RankID = 30 WHERE TaxonRank = 'Phylum';
UPDATE tempTaxonomy
SET RankID = 40 WHERE TaxonRank = 'Subphylum';
UPDATE tempTaxonomy
SET RankID = 40 WHERE TaxonRank = 'Division';
UPDATE tempTaxonomy
SET RankID = 50 WHERE TaxonRank = 'Unranked Clade';
UPDATE tempTaxonomy
SET RankID = 60 WHERE TaxonRank = 'Class';
UPDATE tempTaxonomy
SET RankID = 100 WHERE TaxonRank = 'Order';
UPDATE tempTaxonomy
SET RankID = 140 WHERE TaxonRank = 'Family';
UPDATE tempTaxonomy
SET RankID = 180 WHERE TaxonRank = 'Genus';
UPDATE tempTaxonomy
SET RankID = 190 WHERE TaxonRank = 'Subgenus';
UPDATE tempTaxonomy
SET RankID = 220 WHERE TaxonRank = 'Species';
UPDATE tempTaxonomy
SET RankID = 230 WHERE TaxonRank = 'Subspecies';
UPDATE tempTaxonomy
SET RankID = 240 WHERE TaxonRank = 'Varieties';
UPDATE tempTaxonomy
SET RankID = 260 WHERE TaxonRank = 'Form';

UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 1 WHERE RankID = 0; -- Life
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 2 WHERE RankID = 10; -- Kingdom
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 3 WHERE RankID = 30; -- Phylum
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 4 WHERE RankID = 60; -- Class
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 5 WHERE RankID = 100; -- Order
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 6 WHERE RankID = 140; -- Family
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 7 WHERE RankID = 180; -- Genus
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 8 WHERE RankID = 220; -- Species
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 9 WHERE RankID = 40; -- (Subphylum) Division
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 10 WHERE RankID = 190; -- Subgenus
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 11 WHERE RankID = 230; -- Subspecies
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 12 WHERE RankID = 240; -- Varieties
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 13 WHERE RankID = 260; -- Form
UPDATE tempTaxonomy
SET TaxonTreeDefItemID = 14 WHERE RankID = 50; -- Unranked Clade
