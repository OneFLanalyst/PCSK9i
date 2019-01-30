*PCSK9 lab_result_cm SAS code;
%macro vital_data;
%if ("&vital" EQ "Y") %then %do;

*Select vital data;
proc sql;
create table dmlocal.&REQUESTID.&RUNID._vittable as
  select a.*
  from indata.vital as a, 
      dmlocal.&REQUESTID.&RUNID._population as diagpop
  where a.patid=diagpop.patid
  	and &start. LE MEASURE_DATE LE &end.;
quit;

data _vittable_bp _vittable_smk _vittable_bmi;
  set dmlocal.&REQUESTID.&RUNID._vittable;
	
   if DIASTOLIC ne . or SYSTOLIC ne . then output _vittable_bp; 

 	if ht ne . or wt ne . or original_bmi ne . then output _vittable_bmi;

	if smoking not in (' ' 'NI') or tobacco not in (' ' 'NI') or tobacco_type not in (' ' 'NI') then output _vittable_smk;

run;

*BP;
PROC SQL;
  CREATE TABLE _enc_av AS
  SELECT patid, encounterid, admit_date, enc_type 
  FROM enc
  		
  WHERE 
	   &start. le admit_date le &end.
	   and enc_type='AV';
QUIT;

PROC SQL;
	CREATE TABLE BP_ENC  AS
	SELECT  b.encounterid,
			b.admit_date,
			b.enc_type,
			a.patid, 
		    a.measure_date, 
	        a.measure_time, 
		    a.vital_source, 
		    a.diastolic, 
		    a.systolic
	FROM   _vittable_bp as a, 
		   _enc_av as b
	WHERE (
			a.patid=b.patid
		and ((b.encounterid=a.encounterid or b.admit_date=a.measure_date)
		))
	ORDER BY  PATID, MEASURE_DATE;
QUIT;

data _vittable_bp1;
set BP_ENC;
 where VITAL_SOURCE NOT IN ('PR' 'PD') ;
  if DIASTOLIC ne . and not(50 le DIASTOLIC le 150) then DIASTOLIC=.;
  if SYSTOLIC ne . and not (70 le SYSTOLIC le 250) then SYSTOLIC=.;
  if DIASTOLIC=. and SYSTOLIC=. then delete;
run;

DATA _DIA (DROP=SYSTOLIC) _SYS(DROP=DIASTOLIC);
SET _vittable_bp1 ;
*BY PATID;
	IF 50 LE DIASTOLIC LE 150 THEN OUTPUT _DIA; 
	IF 70 LE SYSTOLIC LE 250 THEN OUTPUT _SYS;
RUN;

*Measure criterea, take lowest DIASTOLIC/SYSTOLIC per date of service;
PROC SORT DATA =_DIA ;
	BY PATID MEASURE_DATE  DIASTOLIC;
RUN;

PROC SORT DATA =_SYS ;
	BY PATID MEASURE_DATE  SYSTOLIC;
RUN;

PROC SORT DATA =_DIA NODUPKEY OUT=_DIA_1;
	BY PATID MEASURE_DATE  ;
RUN;

PROC SORT DATA =_SYS NODUPKEY OUT=_SYS_1;
	BY PATID MEASURE_DATE ;
RUN;

DATA _BP_1;
MERGE _DIA_1 _SYS_1;
BY PATID MEASURE_DATE ;
	IF DIASTOLIC GE 90 THEN DIA=1; 
	IF SYSTOLIC GE 140 THEN SYS=1;

	if SYSTOLIC = . THEN delete; *Jianing 8/30/17-remove records with missing systolic;
RUN;

data recent_bp;
set _bp_1;
by patid;
	if last.patid;
run;

data _bp_demo;
merge recent_bp dmlocal.&REQUESTID.&RUNID._population (in=a) ;
 by patid;
 if a;
run;

%macro bp_sum(vt);
proc summary data=_bp_demo mean std;
class group;
var &vt.;
output out=_&vt._mean N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;

proc summary data=_bp_demo mean std;
var &vt.;
output out=_&vt._mean_total N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;
%mend;
%bp_sum(systolic)
%bp_sum(diastolic);


*Smoking;
data _vittable_smk1 ;
set _vittable_smk;
if ((smoking  in ('01' '02' '07' '08') 
		or (tobacco_type in ('01' '03' '05') and tobacco ='01'))) then smoker=1;
if ((smoking  in ('03' '04') 
		or (tobacco in ('02' '03')))) then smoker=0;
if smoker ne . then output;
drop diastolic systolic bp_position raw_bp_position raw_systolic raw_diastolic ht wt original_bmi;
run;

proc sort data =_vittable_smk1 ;
 by patid descending measure_date;
run;

proc sort data =_vittable_smk1 nodupkey out=vittable_smk;
 by patid ;
run;

*BMI, WT, HT;
DATA _VITAL_HT (DROP=WT original_bmi) _VITAL_WT (DROP=HT original_bmi) _bmi (drop=HT WT);
SET _VITtable_bmi;
  IF 48 le HT le 96 THEN OUTPUT _VITAL_HT;
  IF 50 le WT le 1000  THEN OUTPUT _VITAL_WT;
  if 5 le original_bmi le 90 then output _bmi;
drop diastolic systolic bp_position smoking tobacco tobacco_type raw_bp_position raw_systolic raw_diastolic raw_smoking raw_tobacco;
RUN;

proc sort data =_VITAL_HT nodupkey out=_VITAL_HT1;
  by PATID MEASURE_DATE measure_time;
run;

proc sort data =_VITAL_WT nodupkey out=_VITAL_WT1;
  by PATID MEASURE_DATE measure_time;
run;

proc sort data =_bmi nodupkey out=_VITAL_bmi1;
  by PATID MEASURE_DATE measure_time;
run;

data _VITAL_HT_WT;
merge _VITAL_HT1  _VITAL_WT1  _VITAL_bmi1;
by patid MEASURE_DATE measure_time;
run;

DATA _vital_1;
SET  _VITAL_HT_WT;

IF ORIGINAL_BMI ne . AND ORIGINAL_BMI GE 5 AND ORIGINAL_BMI LE 90 THEN BMI=ORIGINAL_BMI;
	ELSE IF (48 LE HT LE 96 AND 50 LE WT LE 1000) THEN DO;
		BMI=WT/(HT*HT)*703;
		IF not(5 le BMI le 90) THEN BMI=.;
	END;
IF BMI ne .;
RUN;

PROC SORT DATA =_vital_1;
BY PATID MEASURE_DATE;
RUN;

*Apply CDC reference for groupings;
DATA BMI_V;
SET _vital_1;
LENGTH condition $15;
BY PATID;
IF last.PATID;
IF BMI<25 THEN condition=' BMI<25';
	ELSE IF 25<=BMI<30 THEN condition='BMI 25-29';
	ELSE IF BMI>=30 THEN condition='BMI>=30';
run;

%macro ht_wt (vt);
proc sort data =_VITAL_&vt.;
  by PATID descending MEASURE_DATE ;
run;

proc sort data =_VITAL_&vt. nodupkey out=&vt._V;
  by PATID  ;
run;
%mend;
%ht_wt (ht)
%ht_wt (wt);

%macro sum_htwt (vt);
data _&vt._demo;
merge &vt._V dmlocal.&REQUESTID.&RUNID._population(in=a) ;
 by patid;
 if a;
run;

proc summary data=_&vt._demo mean std median qrange;
class group;
var &vt.;
output out=_&vt._mean N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;

proc summary data=_&vt._demo mean std median qrange;
var &vt.;
output out=_&vt._mean_total N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;
%mend;
%sum_htwt (ht)
%sum_htwt (wt)
%sum_htwt (bmi);


%macro cross_htwt (vt, demo);
proc summary data=_&vt._demo mean std median qrange;
class group &demo.;
var &vt.;
output out=_&vt._mean_&demo. N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;

proc summary data=_&vt._demo mean std median qrange;
class &demo.;
var &vt.;
output out=_&vt._mean_&demo._total N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;
%mend;
%cross_htwt (ht, sex)
%cross_htwt (ht, race)
%cross_htwt (ht, hispanic)
%cross_htwt (wt, sex)
%cross_htwt (wt, race)
%cross_htwt (wt, hispanic)
%cross_htwt (bmi, sex)
%cross_htwt (bmi, race)
%cross_htwt (bmi, hispanic)


data _vital_mean;
retain DMID SITEID group summary sex race hispanic;
length summary $40.;
set _ht_mean (where=(group ne' ')in=f)
	_ht_mean_sex (where=(group ne' ')in=f)
	_ht_mean_race (where=(group ne' ')in=f)
	_ht_mean_hispanic (where=(group ne' ')in=f)
	_ht_mean_total(in=f)
	_ht_mean_sex_total(in=f)
	_ht_mean_race_total(in=f)
	_ht_mean_hispanic_total(in=f)
	_wt_mean (where=(group ne' ')in=g) 
	_wt_mean_sex (where=(group ne' ')in=g) 
	_wt_mean_race (where=(group ne' ')in=g) 
	_wt_mean_hispanic (where=(group ne' ')in=g)  
	_wt_mean_total(in=g)
	_wt_mean_sex_total(in=g)
	_wt_mean_race_total(in=g)
	_wt_mean_hispanic_total(in=g)
	_bmi_mean (where=(group ne' ')in=h)  
	_bmi_mean_sex (where=(group ne' ')in=h)
	_bmi_mean_race (where=(group ne' ')in=h)
	_bmi_mean_hispanic (where=(group ne' ')in=h)
	_bmi_mean_total(in=h)
	_bmi_mean_sex_total(in=h)
	_bmi_mean_race_total (in=h)
	_bmi_mean_hispanic_total(in=h)
	_systolic_mean(where=(group ne' ')in=i)  
	_systolic_mean_total(in=i)
	_diastolic_mean(where=(group ne' ')in=j)  
	_diastolic_mean_total(in=j)
	;
	
	if f then summary='HT';
	if g then summary='WT';
	if h then summary='BMI';
	if i then summary='SBP';
	if j then summary='DBP';
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

proc sort data=_vital_mean;
by  _all_;
run;

proc sort data=_vital_mean out=drnoc.&REQUESTID.&RUNID.vital_mean (drop=_freq_);
by  summary group;
run;

data _pop_vt (rename= (smoker1=smoker));
merge dmlocal.&REQUESTID.&RUNID._population (in=a drop=condition stroke_type)  BMI_V(keep=patid condition) vittable_smk (keep=patid smoker);
length smoker1 $15.;
by patid;
 if a;
 
 if condition=' ' then condition='NR';
 if smoker =1 then smoker1='Y';
 	else if smoker=0 then smoker1='N';
	else if smoker=. then smoker1='NR';
 
  drop smoker;
  
run;

%macro calc (grp, congrp);
proc sql;
  create table _&grp._groups as
  select group, "&congrp." as demog format= $15.,  &grp. as demogval format= $15., count(distinct patid) as count
  from _pop_vt
  where group ne ' '
  group by group, &grp.
  order by group, &grp.;
quit;

proc sql;
  create table _&grp._total as
  select 'Total' as group, "&congrp." as demog format= $15.,  &grp. as demogval format= $15., count(distinct patid) as count
  from _pop_vt
   group by  &grp.
  order by &grp.;
quit;
%mend;
%calc (condition,BMI);
%calc (smoker,smoker);


data drnoc.&REQUESTID.&RUNID._vital_freq;
retain DMID SITEID group demog demogval count;
length demog demogval $15;
set _condition_groups (where=(demogval ne' '))
	_smoker_groups (where=(demogval ne' '))
	_condition_total (where=(demogval ne' '))
	_smoker_total (where=(demogval ne' '));
	by group;

	DMID="&DMID.";
	SITEID="&SITEID.";

	if 0<count<&THRESHOLD. then count=.t;
run;

/*proc datasets NOLIST NOWARN library=WORK;
   delete _:;
quit;*/
%end;
%mend vital_data;
%vital_data;
