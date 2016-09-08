#SymbiotaToSpecifySQL
### Authors: Vaughn M. Shirey and Vincent O'Leary

These files are being developed to assist importing records from Darwin Core standards into the DBMS Specify for natural history collections. As the process is completed and generalized, we will update this README with instructions for use. Specify is being used as a database across collections at the Academy, which requires many data preparation steps to move each collection from their various systems into a form we can import to Specify. So far, this repository has scripts used for:

- entomology
- vertebrate paleontology

Each folder contains scripts to prepare individual specimen collections for Specify. These folders contain steps for Symbiota and FileMaker datasets, and import the data into a standardized mysql view based on DarwinCore. Once the data has been prepared in these steps it can be used by the scripts below. 

The legacy folder includes previous versions of importing scripts that are no longer being used or maintained.
 
### General Instructions

In order to successfully migrate data from a FileMaker or Symbiota instance to Specify, following these instructions is crucial as there are several steps required to migrate data. 

1. In the main repository, the temp_tables script will generate temporary tables from the DarwinCore view generated before

2. After the temporary tables are generated, use mysqldump to make a backup and move your temporary tables to a new database. The tables include:
 - tempAgent, tempLocality, tempTaxonomy, tempColObject, tempColEvent, tempCollector, and tempDetermination

3. Finally, executing the script specify_import with the mysqldump will integrate your collections data from mysql into the Specify system

### Additional Information

This project is updated on a casual basis and may not fit all collection datasets. We strive to make this as general as possible to encompass most datasets, but realize that this is not always an option. If you run into serious issues with this code, please do not hesitate to open and issue or contact me directly.
