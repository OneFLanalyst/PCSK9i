

%macro lab_data;
%if ("&lab_result_cm" EQ "Y") %then %do;

*select lab records;
proc sql;
create table dmlocal.&REQUESTID.&RUNID._lab_data as
  select labtb.patid, 
  		 labtb.encounterid,
		 labtb.lab_name,
  		 labtb.lab_loinc,
		 labtb.lab_order_date,
		 labtb.specimen_date,
		 labtb.specimen_time,
		 labtb.result_date,
		 labtb.result_time,
		 labtb.result_qual,
		 labtb.result_num,
		 labtb.result_modifier,
		 labtb.result_unit,
		 labtb.norm_range_low,
		 labtb.norm_modifier_low,
		 labtb.norm_range_high,
		 labtb.norm_modifier_high,
		 labtb.raw_lab_name,
		 labtb.raw_result,
		 labtb.raw_unit,
		 lablist.lab_test length=40
  from indata.lab_result_cm as labtb,
	 infolder.code_list_lab as lablist,
   		 visit as diagpop
  where coalesce (labtb.lab_order_date, labtb.result_date) between &start. and &end.
	   and lablist.loinc=labtb.lab_loinc
	   and labtb.patid=diagpop.patid;
quit;

*Total population with lab;
proc sql;
create table drnoc.&REQUESTID.&RUNID._total_lab as
select "&DMID." as DMID, "&SITEID." as SITEID, count(distinct a.patid) as total_lab
	from indata.lab_result_cm as a,
		 visit as diagpop
	where  (coalesce (a.lab_order_date, a.result_date) between &start. and &end.) 
	    and (a.patid=diagpop.patid) 
	having total_lab ge &threshold. ;
quit;


data _lab;
set dmlocal.&REQUESTID.&RUNID._lab_data;
where result_num ne .;
 if (lab_test='LDL' and 0 < result_num le 300 and result_unit ne 'RATIO U') or  
 (lab_test='HDL' and result_num le 150) or 
 (lab_test='Total Cholesterol' and 62 le result_num le 300) or
 (lab_test='Triglyceride' and 25 le result_num le 2000) or 
 (lab_test='Lipoprotein (little a)' ); 
run;

proc sort data =_lab out=_lab1 ;
 by patid lab_test descending lab_order_date;
 where result_modifier not in ('GT' 'LT');
run;

proc sort data =_lab1 nodupkey out=lab2;
 by patid lab_test;
run;

*create LDL case group;
data ldl_case1;
set lab2;
where lab_test='LDL' and (130 le result_num le 300);
run;

proc sort data =lipid_lowering nodupkey out=_lipid_lowering;
 by patid;
run;

data ldl_drug;
merge ldl_case1 (in=a) _lipid_lowering (in=b keep=patid);
 by patid;
 if a and not b;
run;

*verify ldl cases have at least one prescription in time frame;
%macro disp_verify;
%if ("&dispensing" EQ "Y" and "&prescribing"="N") %then %do;
proc sql;
create table ldl_drug_verify as 
select distinct b.patid 
from indata.dispensing as a,
	 ldl_drug as b
where &start. LE a.dispense_date LE &end.
	and a.patid=b.patid
order by b.patid;
quit;
%end;
%mend disp_verify;
%disp_verify;

%macro pres_verify;
%if ("&dispensing" EQ "N" and "&prescribing"="Y") %then %do;
proc sql;
create table ldl_drug_verify as 
select distinct b.patid 
from indata.prescribing as a,
	 ldl_drug as b
where &start. LE a.rx_order_date LE &end.
	and a.patid=b.patid
order by b.patid;
quit;
%end;
%mend pres_verify;
%pres_verify;

%macro presdis_verify;
%if ("&dispensing" EQ "Y" and "&prescribing"="Y") %then %do;
proc sql;
create table _ldl_drug_verify_disp as 
select distinct c.patid 
from indata.dispensing as b,
	 ldl_drug as c
where (&start. LE b.dispense_date LE &end.)
	and (b.patid=c.patid)
order by c.patid;
quit;

proc sql;
create table _ldl_drug_verify_pres as 
select distinct c.patid 
from indata.prescribing as a,
     ldl_drug as c
where (&start. LE a.rx_order_date LE &end.)
	 and (a.patid=c.patid)
order by c.patid;
quit;

data ldl_drug_verify;
set _ldl_drug_verify_disp _ldl_drug_verify_pres;
run;

proc sort data =ldl_drug_verify nodupkey;
by patid;
run;
%end;
%mend presdis_verify;
%presdis_verify;
%end;
%mend lab_data;
%lab_data;





