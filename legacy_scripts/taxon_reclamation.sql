-- DELETE FROM taxon WHERE rankID = 180;
DROP PROCEDURE IF EXISTS procIteration;
DROP PROCEDURE IF EXISTS taxon_reclamation;

DROP TABLE IF EXISTS taxon_reclamation;
CREATE TABLE IF NOT EXISTS taxon_reclamation (
TaxonID varchar(170) PRIMARY KEY NOT NULL,
FullName varchar(170),
`Name` varchar(170),
RankID varchar(170),
ParentID varchar(170),
TaxonTreeDefID varchar(170),
TaxonTreeDefItemID varchar(170),
ParentName varchar(170)

); 

DELIMITER //

CREATE PROCEDURE procIteration ()
BEGIN
DECLARE done BOOLEAN DEFAULT FALSE;
DECLARE My_TaxonName varchar(170);
DECLARE My_RankID varchar(170);
DECLARE My_ParentID varchar(170);
DECLARE My_TaxonID varchar(170);
DECLARE cur CURSOR FOR SELECT DISTINCT SciName, rankID, MAX(parenttid) as parentID, taxaRelation_temp.tid FROM taxaRelation_temp, taxa WHERE taxa.tid = taxaRelation_temp.tid GROUP BY taxaRelation_temp.tid; 
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done := TRUE;

-- SELECT child.SciName, RankID, parent.parentID, child.tid FROM taxa child LEFT JOIN (SELECT MAX(parenttid) as parentID, SciName, taxaRelation_temp.tid FROM taxaRelation_temp, taxa WHERE taxa.tid = taxaRelation_temp.tid GROUP BY taxaRelation_temp.tid) AS parent ON parent.tid = child.tid WHERE rankID = 10;

OPEN cur;

testLoop: LOOP
	FETCH cur INTO My_TaxonName, My_RankID, My_ParentID, My_TaxonID;
	IF done THEN 
		LEAVE testLoop;
	END IF;
	-- SELECT TaxonName, RankId, ParentID, TaxonID FROM cur;
	CALL taxon_reclamation(My_TaxonName, My_RankID, My_ParentID, My_TaxonID);
END LOOP testLoop;

CLOSE cur;
END //

CREATE PROCEDURE taxon_reclamation(IN TaxonNameIn VARCHAR(170), IN RankIDIn VARCHAR(170), IN ParentIDIn VARCHAR(11), IN TaxonIDIn VARCHAR(170)) 
BEGIN
DECLARE TaxonNameInput varchar(170);
DECLARE RankIDInput varchar(170);
DECLARE ParentIDInput varchar(170); 
DECLARE TaxonIDInput varchar(170);
DECLARE ParentName varchar(170);
SET TaxonNameInput = TaxonNameIn;
SET RankIDInput = RankIDIn;
SET TaxonIDInput = TaxonIDIn;
SET ParentIDInput = ParentIDIn;
SET ParentName = (SELECT taxa.SciName FROM taxa, taxaRelation_temp WHERE taxa.tid = taxaRelation_temp.parenttid AND taxaRelation_temp.parenttid = ParentIDIn AND taxaRelation_temp.tid = TaxonIDIn);

INSERT INTO taxon_reclamation(TaxonID, FullName, `Name`, RankID, ParentID, TaxonTreeDefID, TaxonTreeDefItemID, ParentName)
VALUES (TaxonIDInput, TaxonNameInput, TaxonNameInput, RankIDInput, ParentIDInput, 1, 1, ParentName);
END //

DELIMITER ;

CALL procIteration();

