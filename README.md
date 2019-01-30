# PCSK9i
PCORnet-PCSK9i
Description:Query identifies four mutually exclusive groups (CHD/CAD, FH, LDL>=130 (LDL), and dyslipidemia) from 1/1/2015-3/31/2017 with 
DX and lab data. Descriptive analysis will be done on demographics, diagnosis, procedures, vital, lab_result_cm, and prescribing/dispensing data. Aggregate output at the DataMart- level produced.

Query Request:
PCORnet CDM V3.1 format

Running the SAS Program:
Open the sasprograms folder and open the SAS file ‘master.sas’ using SAS 9.3+

1. In step 1, edit the various locations as follows:

  i. Edit the indata libname to contain the filepath location where the static SAS datasets are stored.
  ii. Edit the infolder %LET statement to contain the filepath for the infolder folder that was included in the zip file.
	
  iii. Edit the dmlocal %LET statement to contain the filepath for the dmlocal folder that was included in the zip file.
	
  iv. Edit the drnoc %LET statement to contain the filepath for the drnoc folder that was included in the zip file.
	
  v. Edit the tax, supplemental_table, location.
	
  vi. Indicate if tables are available:
	
    • Dispensing %LET statement Y/N
		
    • Prescribing %LET statement Y/N
		
    • Vital %LET statement Y/N
		
    • Lab_result_cm %LET statement Y/N
		
  vii. NOTE: the default value for low cell count masking is 11
	
  viii. Edit the DMID %LET statement and the SITEID %LET statement to contain your designated DataMart ID and Site ID.
