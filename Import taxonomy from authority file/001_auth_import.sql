-- Create MySQL table for a taxon authority file --

-- 1. Import auhority file for taxonomy, this workflow is using a tab separated file from paleobiodb.org and will need updated for other files --
DROP TABLE IF EXISTS`auth_taxa`;
CREATE TABLE IF NOT EXISTS `auth_taxa` 
(`orig_no` VARCHAR(10),
`taxon_no` VARCHAR(10),
`record_type` VARCHAR(10),
`flags` VARCHAR(10),
`taxon_rank` VARCHAR(16),
`taxon_name` VARCHAR(128),
`parent_no` VARCHAR(10),
`reference_no` VARCHAR(10),
`is_extant` VARCHAR(10),
`n_occs` VARCHAR(10));
TRUNCATE TABLE `auth_taxa`;

-- Update file name for import --

LOAD DATA LOCAL INFILE 'D:\\taxa.tsv' INTO TABLE `auth_taxa`;

-- 2. Create view for Specify table --

CREATE OR REPLACE VIEW auth_view AS
SELECT orig_no AS TaxonID,
taxon_rank AS TaxonRank,
taxon_name AS FullName,
parent_no AS ParentID
FROM darwincorevp.auth_taxa

-- Update these fields as necessary for the authority file --

WHERE taxon_rank <> 'subclass' AND taxon_rank <> 'superclass' AND taxon_rank <> 'infraclass' AND taxon_rank <> 'superorder' AND taxon_rank <> 'suborder' AND taxon_rank <> 'infraorder' AND taxon_rank <> 'subfamily' AND taxon_rank <> 'superfamily' AND taxon_rank <> 'informal' AND taxon_rank <> 'tribe' AND taxon_rank <> 'subtribe';