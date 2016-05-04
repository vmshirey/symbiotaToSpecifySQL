These files are used to create temporary tables that mimic the tables found in Specify as a part of a normalization routineto move data from the omoccurrences table in Symbiota to a Specify instance. In order to successfully run these files, please run them in sequential order from sts_1.0 through sts_1.x where x is the highest number in the series of files. 

Please execute these files in the following order:

(1) sts_1.0
-- Creates Darwin Core (DwC) view and associated temporary tables to move data, moves and parses serialized collector names into the Agents table --

(2) sts_1.1
-- Handles all other table data and establishes keys to each based on occurrenceIDs --

(3) sts_1.2
-- Handles additional data, estblishes linkages between tables on keys other than occurrenceIDs --

-- Author Vaughn M. Shirey -- 
