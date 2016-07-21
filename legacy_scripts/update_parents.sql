UPDATE taxon t1 LEFT JOIN taxon t2 ON t1.PreviousParentID = t2.PreviousTaxonID
SET t1.ParentID = t2.TaxonID WHERE t1.RankID = 220;