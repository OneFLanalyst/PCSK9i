*ASCVD Risk Score;


%macro ASCVD_data;
%if ("&lab_result_cm" EQ "Y") %then %do;
*HDL and total cholesterol flag for ASCVD risk score;
proc sql noprint;
select count(distinct patid) into:HDL_LAB
 from lab2
 where (lab_test='HDL');

select count(distinct patid) into:TOTAL_CHOL_LAB
 from lab2
 where (lab_test='Total Cholesterol');
quit;
%put &HDL_LAB. &TOTAL_CHOL_LAB.;

%if %eval (&HDL_LAB. GT 0) %then %do;
	%if %eval (&TOTAL_CHOL_LAB. GT 0) %then %do;
		%if("&vital" EQ "Y") %then %do;

data _t2dm (keep=patid diabetes);
set comorbidities ;
 where condition='Diabetes';
 diabetes=1;
run;

proc sort data=_t2dm nodupkey out=_t2dm1;
by patid;
run;

proc sort data =antihypertensives nodupkey out=_antihypertensives1 (keep=patid class);
by patid;
run;

data _ascvd1;
merge  _antihypertensives1 
	   vittable_smk (keep=patid smoker) 
       lab2 (where=(lab_test='Total Cholesterol')rename=(result_num=tc_result)keep=patid result_num lab_test)
	   lab2 (where=(lab_test='HDL')rename=(result_num=hdl_result) keep=patid result_num lab_test)
	   recent_bp (keep=patid systolic diastolic) 
	   _t2dm1  
	   dmlocal.&REQUESTID.&RUNID._population (in=a keep=patid sex race age hispanic group);
 by patid;
 if a;
 if diabetes ne 1 then diabetes=0;
 drop lab_test ;
run;


data _ascvd2;
set _ascvd1;

*AA women;
if sex='F' and race='03' and smoker ne . and tc_result ne . and hdl_result ne . and systolic ne . then do;
 *not-treated;
	if class=' ' then individual_score=17.114*log(age)+.94*log(tc_result)-18.92*log(hdl_result)+4.475*log(age)*log(hdl_result)+27.82*
		log(systolic)-6.087*log(age)*log(systolic)+(.691)*smoker+(0.874)*diabetes;
 *treated;
	else if class ne ' '  then individual_score=17.114*log(age)+.94*log(tc_result)-18.92*log(hdl_result)+4.475*log(age)*log(hdl_result)
		+29.291*log(systolic)-6.432*log(age)*log(systolic)+(.691)*smoker+(0.874)*diabetes;

	_10_yr=1-.9533**exp(individual_score-86.61);
end;

*WH women;
if sex='F' and race='05' and smoker ne . and tc_result ne . and hdl_result ne . and systolic ne . then do;
 *not-treated;
	if class=' ' then individual_score=-29.799*log(age)+4.884*(log(age)**2)+13.54*log(tc_result)-3.114*log(age)*log(tc_result)-13.578*
		log(hdl_result)+3.149*log(age)*log(hdl_result)+1.957*log(systolic)+(7.574-1.665*log(age))*smoker+(0.661)*diabetes;
 *treated;
	else if class ne ' '  then individual_score=-29.799*log(age)+4.884*(log(age)**2)+13.54*log(tc_result)-3.114*log(age)*log(tc_result)-13.578*
		log(hdl_result)+3.149*log(age)*log(hdl_result)+2.019*log(systolic)+(7.574-1.665*log(age))*smoker+(0.661)*diabetes;

	_10_yr=1-.9665**exp(individual_score-(-29.18));
end;

*Hispanic women-not AA or White;
if sex='F' and hispanic='Y' and race not in ('05' '03') and smoker ne . and tc_result ne . and hdl_result ne . and systolic ne . then do;
 *not-treated;
	if class=' ' then individual_score=-29.799*log(age)+4.884*(log(age)**2)+13.54*log(tc_result)-3.114*log(age)*log(tc_result)-13.578*
		log(hdl_result)+3.149*log(age)*log(hdl_result)+1.957*log(systolic)+(7.574-1.665*log(age))*smoker+(0.661)*diabetes;
 *treated;
	else if class ne ' '  then individual_score=-29.799*log(age)+4.884*(log(age)**2)+13.54*log(tc_result)-3.114*log(age)*log(tc_result)-13.578*
		log(hdl_result)+3.149*log(age)*log(hdl_result)+2.019*log(systolic)+(7.574-1.665*log(age))*smoker+(0.661)*diabetes;

	_10_yr=1-.9665**exp(individual_score-(-29.18));
end;

*AA men;
if sex='M' and race='03' and smoker ne . and tc_result ne . and hdl_result ne . and systolic ne . then do;
*not-treated;
	if class=' '   then individual_score=2.469*log(age)+.302*log(tc_result)-.307*log(hdl_result)+1.809*
		log(systolic)+(.549)*smoker+0.645*diabetes;
*treated;
	else if class ne ' '  then individual_score=2.469*log(age)+.302*log(tc_result)-.307*log(hdl_result)+1.916*
		log(systolic)+(.549)*smoker+0.645*diabetes;

	_10_yr=1-.8954**exp(individual_score-19.54);
end;

*WH men;
if sex='M' and race='05' and smoker ne . and tc_result ne . and hdl_result ne . and systolic ne . then do;
*not-treated;
	if class=' '  then individual_score=12.344*log(age)+11.853*log(tc_result)-2.664*log(age)*log(tc_result)-7.99*log(hdl_result)+1.769*
		log(age)*log(hdl_result)+1.764*log(systolic)+(7.837-1.795*log(age))*smoker+0.658*diabetes;
	
*treated;
	else if (class ne ' ' and smoker =1 and diabetes=1) then individual_score=12.344*log(age)+11.853*log(tc_result)-2.664*log(age)*log(tc_result)-7.99*log(hdl_result)+1.769*
		log(age)*log(hdl_result)+1.797*log(systolic)+(7.837-1.795*log(age))*smoker+0.658*diabetes;	

	_10_yr=1-.9144**exp(individual_score-61.18);
end;

*Hispanic men-not AA or White;
if sex='M' and hispanic='Y' and race not in ('05' '03') and smoker ne . and tc_result ne . and hdl_result ne . and systolic ne . then do;
*not-treated;
	if class=' '  then individual_score=12.344*log(age)+11.853*log(tc_result)-2.664*log(age)*log(tc_result)-7.99*log(hdl_result)+1.769*
		log(age)*log(hdl_result)+1.764*log(systolic)+(7.837-1.795*log(age))*smoker+0.658*diabetes;
	
*treated;
	else if (class ne ' ' and smoker =1 and diabetes=1) then individual_score=12.344*log(age)+11.853*log(tc_result)-2.664*log(age)*log(tc_result)-7.99*log(hdl_result)+1.769*
		log(age)*log(hdl_result)+1.797*log(systolic)+(7.837-1.795*log(age))*smoker+0.658*diabetes;	

	_10_yr=1-.9144**exp(individual_score-61.18);
end;

run;

data _ascvd_demo;
merge _ascvd2  ;
 by patid;
 length _10y_ASCVD $10.;
 if _10_yr ne . and 20 le age le 79 and 20 le hdl_result le 100 and 130 le tc_result le 320 and 90 le systolic le 200 ;

_10_yr_percent=_10_yr*100;

  if _10_yr_percent <5then _10y_ASCVD=' <5%';
  else if 5 le _10_yr_percent <7.5 then _10y_ASCVD='5%-7.5%';
  else if 7.5 le _10_yr_percent <10 then _10y_ASCVD='7.5%-10%';
  else if  10 le _10_yr_percent < 20 then _10y_ASCVD='10-20%';
  else if  _10_yr_percent ge 20 then _10y_ASCVD='>=20%';

  agegrp=put(age,agefmt.);
  if sex not in ('M' 'F') then sex ='XX';
  if race not in ('01' '02' '03' '04' '05') then race='XX';
  if hispanic not in ('Y' 'N') then hispanic='XX';
 
run;


%macro ascvd_sum (grp,congrp);
proc sql;
  create table _ascvd_&grp._groups as
  select group, "&congrp." as demog format= $15.,  &grp. as demogval format= $15., count(distinct patid) as count
  from _ascvd_demo
  where group ne ' '
  group by group, &grp.
  order by group, &grp.;
quit;

proc sql;
  create table _ascvd_&grp._total as
  select 'Total' as group, "&congrp." as demog format= $15.,  &grp. as demogval format= $15., count(distinct patid) as count
  from _ascvd_demo
   group by  &grp.
  order by &grp.;
quit;
%mend;
%ascvd_sum (sex, sex)
%ascvd_sum (hispanic, hispanic)
%ascvd_sum (race, race)
%ascvd_sum (agegrp,age_group)
%ascvd_sum (_10y_ASCVD, _10y_ASCVD);

%macro ascvd_cross (grp,grp1,congrp,cross);
proc sql;
  create table _ascvd_&cross._groups as
  select group, "&congrp." as demog format= $15.,  &grp. as demogval format= $15., &grp1., count(distinct patid) as count
  from _ascvd_demo
  where group ne ' '
  group by group, &grp.,&grp1.
  order by group, &grp.,&grp1.;
quit;

proc sql;
  create table _ascvd_&cross._total as
  select 'Total' as group, "&congrp." as demog format= $15.,  &grp. as demogval format= $15., &grp1., count(distinct patid) as count
  from _ascvd_demo
  group by &grp.,&grp1.
  order by &grp.,&grp1.;
quit;
%mend;
%ascvd_cross (_10y_ASCVD, race, _10y_ASCVD, sc_rc);
%ascvd_cross (_10y_ASCVD, hispanic, _10y_ASCVD, sc_eth);
%ascvd_cross (_10y_ASCVD, sex, _10y_ASCVD, sc_sex);
%ascvd_cross (race, hispanic,race, rc_eth);

data drnoc.&REQUESTID.&RUNID._demo_ascvd;
retain DMID SITEID group demog demogval sex race hispanic;
length demog demogval $15;
set _ascvd_sex_groups 
	_ascvd_hispanic_groups 
	_ascvd_race_groups 
	_ascvd_agegrp_groups 
	_ascvd__10y_ASCVD_groups 
	_ascvd_sc_rc_groups
	_ascvd_sc_eth_groups
	_ascvd_rc_eth_groups
	_ascvd_sc_sex_groups
	_ascvd_sex_total 
	_ascvd_hispanic_total 
	_ascvd_race_total 
	_ascvd_agegrp_total
	_ascvd__10y_ASCVD_total 
	_ascvd_sc_rc_total
	_ascvd_sc_eth_total
	_ascvd_rc_eth_total
	_ascvd_sc_sex_total;
	by group;

	DMID="&DMID.";
	SITEID="&SITEID.";

	if 0<count<&THRESHOLD. then count=.t;
run;

proc summary data=_ascvd_demo mean std median qrange;
 class group ;
 var _10_yr;
 output out=_ascvd2_mean  N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;

proc summary data=_ascvd_demo mean std median qrange;
 var _10_yr;
 output out=_ascvd2_mean_total  N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;

%macro ascvd (set);
proc summary data=_ascvd_demo mean std median qrange;
 class group &set.  ;
 var _10_yr;
 output out=_ascvd2_&set._mean  N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;

proc summary data=_ascvd_demo mean std median qrange;
 class &set.;
 var _10_yr;
 output out=_ascvd2_&set._mean_total  N=N mean=mean std=std min=min max=max median=median qrange=qrange;
run;
%mend;
%ascvd (sex)
%ascvd (race);
%ascvd (hispanic);

data _ascvd_mean ;
retain DMID SITEID summary group sex race hispanic;
set _ascvd2_sex_mean(where=(group ne' ' and sex ne' '))  
	_ascvd2_sex_mean_total(where=(sex ne' ')) 
	_ascvd2_race_mean(where=(group ne' ' and race ne' '))
	_ascvd2_race_mean_total(where=(race ne' '))  
	_ascvd2_hispanic_mean(where=(group ne' ' and hispanic ne' '))
	_ascvd2_hispanic_mean_total(where=(hispanic ne' '))  
	_ascvd2_mean(where=(group ne' ')) 
	_ascvd2_mean_total;

if group=' ' then group='Total';
summary ='ASCVD';

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
proc sort data=_ascvd_mean out=drnoc.&REQUESTID.&RUNID._ascvd_mean (drop=_freq_);
by  summary group;
run;

/*proc datasets NOLIST NOWARN library=WORK;
   delete _:;
quit;*/
%end;%end;%end;%end;
%mend ascvd_data;
%ascvd_data;
