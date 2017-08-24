# VIVO-DW-Tools

This repository contains fucntions and lookup tables used to clean data (HR and otherwise) from McMaster's Mosaic Data Warehouse (DW), and prepare it for ingest into VIVO and Symplectic Elements. 

## Contents:
**vivo_clean_dw.m** --> DW HR data cleaning function  
**vivo_prepare_elementsHR.m** --> function to format cleaned DW HR data for ingestion into Symplectic Elements.  
**vivo_HR_diff.m** --> function that allows a comparison of two DW HR file versions; creates separate lists of additions and deletions  
**vivo_update_and_process.m** --> function to move files out of DW share into MacDrive locations, and then run vivo_clean_dw and vivo_prepare_elementsHR functions.  
**sendolmail.m** --> pre-made function that enables report emailing from the vivo_update_and_process.m function.  

**/lookup_tables** --> various lookup tables used in processing operations  

*all other files can be considered working/scratch files*

## Additional Documentation
Full workflow documentation may be found in [this Google Doc](https://goo.gl/k6gqgx)

## Requirements: 
* Octave/Matlab -- note that Octave is currently not an option, as it hits an error processing csvs with quotes.
* Mosaic DW data downloaded as a comma-separated file (.csv)