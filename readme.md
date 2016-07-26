#SymbiotaToSpecifySQL
### Primary Author Vaughn M. Shirey, contributions by Vincent O'Leary

These files are being developed to assist importing records from Darwin Core standards into the DBMS Specify for natural history collections. As the process is completed and generalized, we will update this README with instructions for use.

Under the import forlder are sql scripts to import an authority file for taxonomy into a Specify Taxon table. This works by importing into a temporary table similar to Specify and then moving into the correct fields in Specify. Run them in order to complete import of taxonomy in Specify from an authority file.

Under the legacy folder are previous versions of importing scripts that are no longer being used or maintained.

In the home folder are a series of scripts to import data from filemaker or symbiota tables into a Darwin Core view and then into Specify tables. Please execute these files in the following order:

1. symbiota_view and/or filemaker_view depending on your data
 - Creates a Darwin Core (DwC) view and associated temporary tables to move data, moves and parses serialized collector names into the Agents table

2. specify_import
 - Handles all other table data and establishes keys to each based on occurrenceIDs
 
### General Instructions

In order to successfully migrate data from a FileMaker or Symbiota instance to Specify, following these instructions is crucial as there are several steps required to migrate data. 

1. Depending on what type of instance you are drawing data from, run the filemaker_view or symbiota_view scripts to generate a DwC view in the database that currently contains your occurrence data. 

2. Next, run the specify_import script to generate temporary tables from the DwC view generated in step one.

3. You will need to execute a mysqldump to move your temporary tables to a new database. The temporary table names are:
 - tempCollector, tempColObject, tempColEvent, tempAgent, tempLocality, tempDetermination.

4. Finally, executing specify_integrate one you have executed your mysqldump results using your Specify database should yield integrate from Filemaker/Symbiota into Specify. 

### Additional Information

This project is updated on a casual basis and may not fit all collection datasets. We strive to make this as general as possible to encompass most datasets, but realize that this is not always an option. If you run into serious issues with this code, please to not hesitate to open and issue or contact me directly.
