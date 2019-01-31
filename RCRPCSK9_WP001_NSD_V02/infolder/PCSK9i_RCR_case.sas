
* assign groups;
%macro lab_case;
%if ("&lab_result_cm" EQ "Y") %then %do;
data  dmlocal.&REQUESTID.&RUNID._population;
merge visit (in=e) fh1 (in=a) CHD_CAD1 (in=b) dyslip1 (in=c) ldl_drug_verify(in=d) ;
length group $20.;
  by patid;
	if e;
	if b then group='CHD/CAD';
  	else if a then group ='FH';
	else if d then group='LDL';
    else if c then group='Dyslipemia';
run;

proc sort data =dmlocal.&REQUESTID.&RUNID._population nodupkey;
by patid;
run;
%end;
%mend lab_case;
%lab_case;

%macro no_lab;
%if ("&lab_result_cm" EQ "N") %then %do;
data  dmlocal.&REQUESTID.&RUNID._population;
merge visit (in=d) fh1 (in=a) CHD_CAD1 (in=b) dyslip1 (in=c) ;
length group $20.;
  by patid;
  if d;
	if b then group='CHD/CAD';
  	else if a then group ='FH';
    else if c then group='Dyslipemia';
keep patid birth_date sex hispanic race age agegrp group condition stroke_type;
run;

proc sort data =dmlocal.&REQUESTID.&RUNID._population nodupkey;
by patid;
run;
%end;
%mend no_lab;
%no_lab;


