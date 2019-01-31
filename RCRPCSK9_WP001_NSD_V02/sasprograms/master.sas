
*********************************************************************************************************************;
*	PCSK9i RCR
*   Query identifies four mutually exclusive groups (CHD/CAD, FH, LDL>=130 (LDL), and dyslipidemia) from 
*	1/1/2015-3/31/2017 with DX and lab data. Descriptive analysis will be done on demographics, diagnosis, 
*	procedures, vital, lab_result_cm, and prescribing/dispensing data. Aggregate output at the DataMart- level produced. 
*  
*	
*	Affiliation: Institute of Child Health Policy (ICHP), Univ. Florida
*	Date: Oct 19th 2017
*********************************************************************************************************************;


/*System Options*/
options mprint linesize=150 pagesize=50 compress=yes reuse=no symbolgen ERRORS=0 noquotelenmax validvarname=v7 LRECL=32767;

libname indata 'C:\Case\PCORNET\PCSK9RCR\indata\';

%let infolder= C:\Case\PCORNET\PCSK9RCR\infolder\;
libname infolder "&infolder.";

%let dmlocal= C:\Case\PCORNET\PCSK9RCR\dmlocal\;
libname dmlocal "&dmlocal.";

%let drnoc=C:\Case\PCORNET\PCSK9RCR\drnoc\;
libname drnoc "&drnoc.";

*supplemental_table -Rx_providerid to taxonomy code;
libname tax 'C:\Case\taxonomy';

*Indicate if table is available Y/N;
%let dispensing=Y;
%let prescribing=Y;
%let vital=Y;
%let lab_result_cm=Y;

*Values below the THRESHOLD parameter will be considered as low cell count.;
%let threshold=11;

*datamart id;
%LET DMID=;
%LET SITEID=;

/*****************************************************************************************************/
/**************************** PLEASE DO NOT EDIT CODE BELOW THIS LINE ********************************/
/*****************************************************************************************************/

%let start='01JAN2015'D;
%let end='31MAR2017'D;

%let anchor='31MAR2017'D;

%let requestid=RCRPCSK9WP001;
%let runid= r2;

%include "&infolder.PCSK9i_RCR_v4.sas";
%include "&infolder.PCSK9i_RCR_medication.sas";
%include "&infolder.PCSK9i_RCR_lab.sas";
%include "&infolder.PCSK9i_RCR_case.sas";
%include "&infolder.PCSK9i_RCR_vital.sas";
%include "&infolder.PCSK9i_RCR_ascvd.sas";
%include "&infolder.PCSK9i_RCR_analysis.sas";
