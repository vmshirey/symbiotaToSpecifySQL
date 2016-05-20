INSERT INTO determination (TaxonID, CollectionObjectID, CollectionMemberID, DeterminerID)
SELECT newTaxonID, CollectionObjectID, 4, AgentID FROM tempDetermination WHERE newTaxonID > 0;