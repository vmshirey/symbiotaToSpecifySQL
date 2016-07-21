UPDATE tempDetermination LEFT JOIN taxon on taxon.PreviousTaxonID = tempDetermination.TaxonID
SET newTaxonID = taxon.TaxonID;