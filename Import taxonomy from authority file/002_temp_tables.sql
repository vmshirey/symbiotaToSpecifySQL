-- Create temporary MySQL table for taxonoy that can be easily inserted into Specify --

-- 1. Create table

DROP TABLE IF EXISTS temptaxonomy;
CREATE TABLE IF NOT EXISTS temptaxonomy(
`TID` INT(11) auto_increment PRIMARY KEY,
`PID` INT(11),
`TimestampCreated` datetime,
`FullName` VARCHAR(128),
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
INSERT INTO temptaxonomy (TimestampCreated, FullName, TaxonRank, TaxonTreeDefID, TaxonTreeDefItemID, PreviousTID, PreviousPID, CollectionCode)
SELECT now(), FullName, TaxonRank, 1 as TaxonTreeDefID, 1 as TaxonTreeDefItemID, TaxonID, ParentID, "VP" as CollectionCode FROM auth_view;

UPDATE temptaxonomy INNER JOIN (SELECT TID, PreviousTID FROM temptaxonomy) AS parents ON parents.PreviousTID = temptaxonomy.PreviousPID
SET temptaxonomy.PID = parents.TID;

UPDATE temptaxonomy INNER JOIN (SELECT TID, PreviousTID, FullName FROM temptaxonomy) AS parents ON parents.PreviousTID = temptaxonomy.PreviousPID
SET temptaxonomy.ParentName = parents.FullName;

-- Update RankID and TaxonDef for Specify --

UPDATE temptaxonomy
SET RankID = 0 WHERE TaxonRank = 'Life';
UPDATE temptaxonomy
SET RankID = 10 WHERE TaxonRank = 'Kingdom';
UPDATE temptaxonomy
SET RankID = 30 WHERE TaxonRank = 'Phylum';
UPDATE temptaxonomy
SET RankID = 40 WHERE TaxonRank = 'Subphylum';
UPDATE temptaxonomy
SET RankID = 40 WHERE TaxonRank = 'Division';
UPDATE temptaxonomy
SET RankID = 50 WHERE TaxonRank = 'Unranked Clade';
UPDATE temptaxonomy
SET RankID = 60 WHERE TaxonRank = 'Class';
UPDATE temptaxonomy
SET RankID = 100 WHERE TaxonRank = 'Order';
UPDATE temptaxonomy
SET RankID = 140 WHERE TaxonRank = 'Family';
UPDATE temptaxonomy
SET RankID = 180 WHERE TaxonRank = 'Genus';
UPDATE temptaxonomy
SET RankID = 190 WHERE TaxonRank = 'Subgenus';
UPDATE temptaxonomy
SET RankID = 220 WHERE TaxonRank = 'Species';
UPDATE temptaxonomy
SET RankID = 230 WHERE TaxonRank = 'Subspecies';
UPDATE temptaxonomy
SET RankID = 240 WHERE TaxonRank = 'Varieties';
UPDATE temptaxonomy
SET RankID = 260 WHERE TaxonRank = 'Form';

UPDATE temptaxonomy
SET TaxonTreeDefItemID = 1 WHERE RankID = 0; -- Life
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 2 WHERE RankID = 10; -- Kingdom
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 3 WHERE RankID = 30; -- Phylum
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 4 WHERE RankID = 60; -- Class
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 5 WHERE RankID = 100; -- Order
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 6 WHERE RankID = 140; -- Family
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 7 WHERE RankID = 180; -- Genus
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 8 WHERE RankID = 220; -- Species
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 9 WHERE RankID = 40; -- (Subphylum) Division
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 10 WHERE RankID = 190; -- Subgenus
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 11 WHERE RankID = 230; -- Subspecies
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 12 WHERE RankID = 240; -- Varieties
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 13 WHERE RankID = 260; -- Form
UPDATE temptaxonomy
SET TaxonTreeDefItemID = 14 WHERE RankID = 50; -- Unranked Clade
