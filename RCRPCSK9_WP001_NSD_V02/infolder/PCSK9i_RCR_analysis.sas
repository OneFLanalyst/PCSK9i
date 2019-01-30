*PCSK9i RCR lab, medication, comorbitities frerquencies;

%macro lab_analysis;
%if ("&lab_result_cm" EQ "Y") %then %do;
data _lab_demo;
merge lab2 dmlocal.&REQUESTID.&RUNID._population (in=a) ;
 by patid;
 if a;
run;

data _lab_demo_class;
set _lab_demo;
length classify $25.;
	if lab_test='LDL' then do;
		if result_num <100 then classify='Optimal';
		else if 100 le result_num <130 then classify='Near Optimal';
		else if 130 le result_num<160 then classify='Borderline high';
		else if 160 le result_num <190 then classify ='High';
		else if result_num ge 190 then classify='Very High';
	end;
	if lab_test='HDL' then do;
		if result_num <40 then classify='Poor';
		else if 40 le result_num <60 then classify ='Better';
		else if result_num ge 60 then classify='Best';
	end;
	if lab_test='Total Cholesterol' then do;
		if result_num <200 then classify='Desirable';
		else if 200 le result_num <240 then classify='Borderline high';
		else if result_num ge 240 then classify='High';
	end;
	if lab_test='Triglyceride' then do;
		if result_num <150 then classify='Desirable';
		else if 150 le result_num <200 then classify='Borderline high';
		else if 200 le result_num <500 then classify='High';
		else if result_num ge 500 then classify='Very High';
	end;
run;

proc sql;
create table _lab_result as
 select group, lab_test, classify, count(distinct patid) as count
 from _lab_demo_class
 group by group, lab_test, classify;
quit;

proc sql;
create table _lab_result_total as
 select 'Total' as group, lab_test, classify, count(distinct patid) as count
 from _lab_demo_class
 group by lab_test, classify;
quit;

data _lab_results;
retain DMID SITEID;
set _lab_result _lab_result_total;
 where group ne ' ' and lab_test ne' ';

 DMID="&DMID.";
 SITEID="&SITEID.";

 if 0<count<&THRESHOLD. then count=.t;
run;

proc sort data=_lab_results out =drnoc.&REQUESTID.&RUNID._lab_results;
by lab_test group ;
run;

proc summary data=_lab_demo mean std median qrange q1 q3;
class group lab_test;
var result_num;
output out=_lab_mean N=N mean=mean std=std min=min max=max median=median qrange=qrange ;
run;

proc summary data=_lab_demo mean std median qrange q1 q3;
class lab_test;
var result_num;
output out=_lab_mean_total N=N mean=mean std=std min=min max=max median=median qrange=qrange ;
run;


data _lab_mean;
retain DMID SITEID group summary ;
length summary $40.;
set _lab_mean (where=(group ne' ' and summary ne ' ')rename =(lab_test=summary))
	_lab_mean_total (where=(summary ne ' ') rename =(lab_test=summary))
	;
	
	*outlier_high=q3+1.5*qrange;
	*outlier_low=q3-1.5*qrange;


if group=' ' then group ='Total';

DMID="&DMID.";
SITEID="&SITEID.";

if 0<N<&THRESHOLD. then N=.t;
	if N=.t then do;
	min=.t;
	max=.t;
	mean=.t;
	std=.t;
	median=.t;
	qrange=.t;
	end;
drop _type_;
run;

proc sort data=_lab_mean out=drnoc.&REQUESTID.&RUNID._lab_mean (drop=_freq_);
by summary group ;
run;

%end;
%mend lab_analysis;
%lab_analysis;


************;
*Medication;
************;
%macro drug(type,class);
proc sort data =&type. out=&type.;
 by patid &class. descending drug_date;
run;

data drug_demo_&type.;
merge &type. dmlocal.&REQUESTID.&RUNID._population (in=a) ;
 by patid;
 if a;
run;

proc sort data =drug_demo_&type. nodupkey out=&type._total;
 by patid &class. ;
run;

proc sort data =drug_demo_&type. nodupkey out=&type._sixmon;
 by patid &class. six_month;
run;

*Without group;
proc sql;
  create table _&type._counts as
  select 'Total, drug code' as analysis, &class., drug_code, count(distinct patid) as count 
  from &type._total 
  group by &class.,drug_code;
quit;

proc sql;
  create table _&type._counts_name as
  select 'Total' as analysis, &class., count(distinct patid) as count 
  from &type._total 
  group by &class.;
quit;

proc sql;
  create table _&type._counts_six as
  select 'Six month, drug code' as analysis, six_month,&class., drug_code, count(distinct patid) as count 
  from &type._sixmon 
  group by six_month,&class., drug_code;
quit;

proc sql;
  create table _&type._counts_six_name as
  select 'Six month' as analysis, six_month, &class., count(distinct patid) as count 
  from &type._sixmon 
  group by six_month, &class.;
quit;

*With group;
proc sql;
  create table _&type._counts_g as
  select 'Total, drug code, group' as analysis, group, &class., drug_code, count(distinct patid) as count 
  from &type._total 
  group by group, &class.,drug_code;
quit;

proc sql;
  create table _&type._counts_name_g as
  select 'Total, group' as analysis, group, &class., count(distinct patid) as count 
  from &type._total 
  group by group, &class.;
quit;

proc sql;
  create table _&type._counts_six_g as
  select 'Six month, drug code, group' as analysis, group, six_month,&class., drug_code, count(distinct patid) as count 
  from &type._sixmon 
  group by group, six_month,&class., drug_code;
quit;

proc sql;
  create table _&type._cnts_six_name_g as
  select 'Six month, group' as analysis, group, six_month,&class., count(distinct patid) as count 
  from &type._sixmon 
  group by group, six_month,&class.;
quit;
%mend;
%drug(lipid_lowering,drug)
%drug(other_meds,class)

data drnoc.&REQUESTID.&RUNID._oth_med_cnt;
retain DMID SITEID group six_month class drug_code count;
set _other_meds_counts_six_g 
	_other_meds_counts_g  
	_other_meds_cnts_six_name_g  
	_other_meds_counts_name_g 
    _other_meds_counts_six  
	_other_meds_counts  
	_other_meds_counts_six_name 
	_other_meds_counts_name ;

	DMID="&DMID.";
	SITEID="&SITEID.";

 if 0<count<&THRESHOLD. then count=.t;
run;

data drnoc.&REQUESTID.&RUNID._lipid_low_cnt;
retain DMID SITEID group six_month drug drug_code count;
set _lipid_lowering_counts_six_g  
	_lipid_lowering_counts_g  
	_lipid_lowering_cnts_six_name_g 
	_lipid_lowering_counts_name_g 
    _lipid_lowering_counts_six  
	_lipid_lowering_counts  
	_lipid_lowering_counts_six_name 
	_lipid_lowering_counts_name ;

	DMID="&DMID.";
	SITEID="&SITEID.";

 if 0<count<&THRESHOLD. then count=.t;
run;

**************;
*Provider_type;
**************;
*Without group;
proc sql;
  create table _ll_taxo_counts as
  select 'Total' as analysis length 20, taxo, count(distinct patid) as count 
  from lipid_lowering_total 
  group by  taxo;
quit;

proc sql;
  create table _ll_taxo_counts_six as
  select 'Six Month' as analysis length 20, six_month,taxo, count(distinct patid) as count 
  from lipid_lowering_sixmon 
  group by taxo, six_month;
quit;

proc sql;
  create table _ll_taxo_cnt_drug as
  select 'Total, drug' as analysis length 20, drug, taxo, count(distinct patid) as count 
  from lipid_lowering_total 
  group by  drug, taxo;
quit;

*With group;
proc sql;
  create table _ll_taxo_counts_g as
  select 'Total, group' as analysis length 20, group,taxo, count(distinct patid) as count 
  from lipid_lowering_total 
  group by  group,taxo;
quit;

proc sql;
  create table _ll_taxo_counts_six_g as
  select 'Six Month, group' as analysis length 20, group,six_month,taxo, count(distinct patid) as count 
  from lipid_lowering_sixmon 
  group by group,taxo, six_month;
quit;

proc sql;
  create table _ll_taxo_cnt_g_drug as
  select 'Total, drug, group' as analysis length 20, group, drug, taxo, count(distinct patid) as count 
  from lipid_lowering_total 
  group by  group, drug, taxo;
quit;

data drnoc.&REQUESTID.&RUNID._lipid_low_taxo;
retain DMID SITEID group six_month taxo;
length analysis $20.;
set _ll_taxo_counts_six_g  
	_ll_taxo_counts_g 
    _ll_taxo_counts_six  
	_ll_taxo_counts 
	_ll_taxo_cnt_drug
	_ll_taxo_cnt_g_drug	;

	 DMID="&DMID.";
	SITEID="&SITEID.";
 if 0<count<&THRESHOLD. then count=.t;
run;



**************;
*comorbidities;
**************;
proc sort data =comorbidities out =_comorbidities1 (keep=patid dx condition stroke_type) nodupkey;
 by patid condition stroke_type;
 where condition ='Stroke';
run;

proc sort data =comorbidities out =_comorbidities2 (keep=patid condition) nodupkey;
 by patid condition ;
run;

proc transpose data=_comorbidities2 out=_comorbidities4;
 by patid;
 id condition;
 var condition;
run;

proc transpose data=_comorbidities1 out=_comorbidities_stroke;
 by patid;
 id stroke_type;
 var stroke_type;
run;

data _pop ;
merge dmlocal.&REQUESTID.&RUNID._population (in=a drop=condition stroke_type)  _comorbidities4 (drop =_name_) _comorbidities_stroke(drop =_name_) ;
by patid;
 if a;
run;

%macro calc (grp, congrp);
proc sql;
  create table _&grp._groups as
  select group, "&congrp." as demog format= $15.,  &grp. as demogval format= $15., count(distinct patid) as count
  from _pop
  where group ne ' '
  group by group, &grp.
  order by group, &grp.;
quit;

proc sql;
  create table _&grp._total as
  select 'Total' as group, "&congrp." as demog format= $15.,  &grp. as demogval format= $15., count(distinct patid) as count
  from _pop
   group by  &grp.
  order by &grp.;
quit;
%mend;
%calc (sex, sex)
%calc (hispanic, hispanic)
%calc (race, race)
%calc (agegrp,age_group)
%calc (diabetes,Diabetes)
%calc (CAD,CAD)
%calc (CKD,CKD)
%calc (MI,MI)
%calc (stroke,stroke)
%calc (ischemic,ischemic)
%calc (non_ischemic,non_ischemic)
%calc (TIA,TIA)
%calc (PAD,PAD)
%calc (HTN,HTN)
%calc (obesity,Obesity);


%macro calc (grp, grp1, congrp, name);
proc sql;
  create table _&name._groups as
  select group, "&congrp." as demog format= $15.,  &grp. as demogval format= $15., &grp1., count(distinct patid) as count
  from _pop
  where group ne ' '
  group by group, &grp.,&grp1.
  order by group, &grp.,&grp1.;
quit;

proc sql;
  create table _&name._total as
  select 'Total' as group, "&congrp." as demog format= $15.,  &grp. as demogval format= $15., &grp1., count(distinct patid) as count
  from _pop
   group by  &grp.,&grp1.
  order by &grp.,&grp1.;
quit;
%mend;
%calc (agegrp, sex, agegrp, ag_sex)
%calc (agegrp, hispanic, agegrp, ag_his)
%calc (agegrp, race, agegrp, ag_race)
%calc (sex,hispanic, sex, sex_his);
%calc (sex,race, sex, sex_race);
%calc (race,hispanic, race, race_his);

proc summary data=_pop mean std median qrange;
 class group;
 var age;
 output out=_age_mean N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;

proc summary data=_pop mean std median qrange ;
 var age;
 output out=_age_mean_total N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;

*Total population with demographics;
proc sql;
create table denominator_demo as
select group, count(distinct patid) as denominator 
	from _pop 
	where group ne ' '
group by group
order by group; 
	insert into denominator_demo (group, denominator)
	select 'Total' as group, count(distinct patid) as denominator 
	from _pop;
quit;

data drnoc.&REQUESTID.&RUNID._denom_grp;
retain DMID SITEID ;
set denominator_demo;

	DMID="&DMID.";
	SITEID="&SITEID.";

 if 0<denominator<&THRESHOLD. then denominator=.t;
run;

data drnoc.&REQUESTID.&RUNID._demo_freq;
retain DMID SITEID group demog demogval sex race hispanic count;
length demog demogval $15;
set _sex_groups 
	_hispanic_groups 
	_race_groups 
	_agegrp_groups 
	_diabetes_groups (where=(demogval ne' '))
	_cad_groups (where=(demogval ne' '))
	_ckd_groups (where=(demogval ne' '))
	_mi_groups (where=(demogval ne' '))
	_stroke_groups (where=(demogval ne' '))
	_ischemic_groups (where=(demogval ne' '))
	_non_ischemic_groups (where=(demogval ne' '))
	_tia_groups (where=(demogval ne' '))
	_pad_groups (where=(demogval ne' '))
	_htn_groups (where=(demogval ne' '))
	_obesity_groups (where=(demogval ne' '))
	_sex_total 
	_hispanic_total 
	_race_total 
	_agegrp_total
	_diabetes_total (where=(demogval ne' '))
	_cad_total (where=(demogval ne' '))
	_ckd_total (where=(demogval ne' '))
	_mi_total(where=(demogval ne' '))
	_stroke_total (where=(demogval ne' '))
	_ischemic_total (where=(demogval ne' '))
	_non_ischemic_total (where=(demogval ne' '))
	_tia_total (where=(demogval ne' '))
	_pad_total (where=(demogval ne' '))
	_htn_total (where=(demogval ne' '))
	_obesity_total (where=(demogval ne' '))
	_ag_sex_groups
	_ag_his_groups
	_ag_race_groups
	_sex_his_groups
	_sex_race_groups
	_race_his_groups
	_ag_sex_total
	_ag_his_total
	_ag_race_total
	_sex_his_total
	_sex_race_total
	_race_his_total;
	by group;

	DMID="&DMID.";
	SITEID="&SITEID.";

	if 0<count<&THRESHOLD. then count=.t;
run;


data drnoc.&REQUESTID.&RUNID._demo_mean;
retain DMID SITEID summary group  ;
set _age_mean (where=(group ne' ')) _age_mean_total;
 if group=' ' then group ='Total';
 summary ='Age';

 DMID="&DMID.";
 SITEID="&SITEID.";

 if 0<N<&THRESHOLD. then N=.t;
	if N=.t then do;
	min=.t;
	max=.t;
	mean=.t;
	std=.t;
	median=.t;
	qrange=.t;
	end;
drop _type_ _freq_;
run;

proc printto log=log;* print=print;
run;
/*---------------------------------------------------------------------------------------------------*/
/*Rewrite log to mask low cell count                                                                        */
/*---------------------------------------------------------------------------------------------------*/

*Determine threshold category;
%let THRESHOLDCAT=?;
%macro createThreshOldCat();
	%if %eval(&THRESHOLD.=0) %then %do;
		%let THRESHOLDCAT=0;
	%end;
	%if %eval(0<&THRESHOLD. & &THRESHOLD.<11) %then %do;
		%let THRESHOLDCAT=1-10;
	%end;
	%if %eval(10<&THRESHOLD. & &THRESHOLD.<21) %then %do;
		%let THRESHOLDCAT=11-20;
	%end;
	%if %eval(21<&THRESHOLD. & &THRESHOLD.<50) %then %do;
		%let THRESHOLDCAT=21-50;
	%end;
	%if %eval(51<&THRESHOLD. & &THRESHOLD.<100) %then %do;
		%let THRESHOLDCAT=51-100;
	%end;
	%if %eval(&THRESHOLD.>100) %then %do;
		%let THRESHOLDCAT=100+;
	%end;
%mend createThreshOldCat;
%createThreshOldCat();

%put &THRESHOLDCAT.;

*Load log file into dataset;
data _log;
infile "&DRNOC.&REQUESTID.&RUNID..log" truncover;
input var1 $1000.;
run;

*copy log to dmlocal;
data _null_ ;          							*No SAS data set is created; 
    set _log; 
    FILE  "&DMLOCAL.&REQUESTID.&RUNID..log" ;     *Output Text File; 
    PUT var1; 
run ;

*Add a header to the log;
data _header;
format var1 $1000.;
var1="Note: This SAS log has all numbers less than the low cell count threshold entered in the ‘master.sas’ file masked.";
output;
var1="";
output; 
run;

*Find OBSERVATIONS keyword to replace low cell counts;
data _log;
set _header _log;
format num $10. num2 $250. var2 $1030.;
pos=indexw(var1,"observations");
pos1=indexw(var1,"rows");
pos2=indexw(var1,"THRESHOLD resolves to");
pos3=indexw(var1,"< CritCnt <");
pos4=indexw(var1,"< Excluded <");
pos5=indexw(var1,"INFOLDER resolves to");
var2=var1;
if pos>0 then do;
	num=scan(var1,countw(substr(var1,1,pos-1)));
	if strip(upcase(num) ne "NO") then do;
		if 0 < input(num,best.) < &threshold. then do;
			var2=TRANWRD(var1,compress(num),"[number is masked (&thresholdcat.)]");
		end;
	end;
end;
if pos1>0 then do;	
	num=scan(var1,countw(substr(var1,1,pos1-1)));
	if strip(upcase(num) ne "NO") then do;
		if 0 < input(num,best.) < &threshold. then do;
			var2=TRANWRD(var1,compress(num),"[number is masked (&thresholdcat.)]");
		end;
	end;
end;
if pos2>0 then do;
	num=scan(var1,countw(substr(var1,1,pos2+22)));	
	var2=TRANWRD(var1,compress(num),"[number is masked (&thresholdcat.)]");
end;
if pos3>0 then do;
	num=scan(var1,countw(substr(var1,1,pos3+12)));	
	var2=TRANWRD(var1,compress(num),"[number is masked (&thresholdcat.)]");
end;
if pos4>0 then do;
	num=scan(var1,countw(substr(var1,1,pos4+13)));	
	var2=TRANWRD(var1,compress(num),"[number is masked (&thresholdcat.)]");
end;
if pos5>0 then do;
	num2=(substr(var1,1,pos5+20));
	var2=catx(' ',num2,"[location is masked]");
end;
run;

*Output altered log;
data _null_ ;          							*No SAS data set is created; 
    set _log; 
    FILE  "&DRNOC.&REQUESTID.&RUNID..log" ;     *Output Text File; 
    PUT var2; 
run ;

PROC DATASETS LIBRARY=WORK NOLIST KILL;
QUIT;
**************************************************************************;
*                           END OF CODE                                   ;
**************************************************************************;





