#SymbiotaToSpecifySQL
------
These files are being developed to assist importing records from Darwin Core standards into the DBMS Specify for natural history collections. As the process is completed and generalized, we will update this README with instructions for use.

Under the import forlder are sql scripts to import an authority file for taxonomy into a Specify Taxon table. This works by importing into a temporary table similar to Specify and then moving into the correct fields in Specify. Run them in order to complete import of taxonomy in Specify from an authority file.

Under the legacy folder are previous versions of importing scripts that are no longer being used or maintained.

In the home folder are a series of scripts to import data from filemaker or symbiota tables into a Darwin Core view and then into Specify tables. Please execute these files in the following order:

1. symbiota_view and/or filemaker_view depending on your data
 - Creates a Darwin Core (DwC) view and associated temporary tables to move data, moves and parses serialized collector names into the Agents table

2. specify_import
 - Handles all other table data and establishes keys to each based on occurrenceIDs
 
### Primary Author Vaughn M. Shirey, contributions by Vincent O'Leary
 
