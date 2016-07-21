These files are used to create temporary tables that mimic the tables found in Specify as a part of a normalization routineto move data from the omoccurrences table in Symbiota to a Specify instance.

Please execute these files in the following order:

(1) symbiota_import and/or dwc_import depending on your data
-- Creates Darwin Core (DwC) view and associated temporary tables to move data, moves and parses serialized collector names into the Agents table --

(2) specify_import
-- Handles all other table data and establishes keys to each based on occurrenceIDs --

-- Primary Author Vaughn M. Shirey -- 
-- Contributions by Vincent O'Leary --
