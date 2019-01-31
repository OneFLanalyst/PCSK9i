*PCSK9 medication;


data _taxonomy;
set tax.supplemental_table;
where rx_providerid ne ' ';
run;

%macro disp;
%if ("&dispensing" EQ "Y" and "&prescribing"="N") %then %do;
proc sql;
create table _dispense as 
select diagpop.patid, 
	   dispense_date as drug_date,
	   year(dispense_date) as year,
	   qtr(dispense_date) as qtr,
	   a.ndc as drug_code,
	   prescribingid,
	   b.class, 
       b.drug
from indata.dispensing as a,
	infolder.code_list_disp as b,
	 visit as diagpop
where b.ndc=a.ndc
	and &start. LE dispense_date LE &end.
	and a.patid=diagpop.patid
order by patid;
quit;

proc sql;
create table _dispense1 as 
select a.*,
	   b.rx_providerid
from dispense as a
	 left join
	 indata.prescribing as b
  on a.prescribingid=b.prescribingid;
quit;

proc sql;
create table dmlocal.&REQUESTID.&RUNID._dispense as 
select a.*,
	   b.taxo
from _dispense1 as a
	 left join
	 _taxonomy as b
  on a.rx_providerid=b.rx_providerid;
quit;

data antihypertensives lipid_lowering other_meds;
set dmlocal.&REQUESTID.&RUNID._dispense;
yrq=cat(year,qtr);
if qtr in (1 2) then interval=1;
if qtr in (3 4) then interval=2;
six_month=cat(year,interval);
 if  class ne ' ' and class ne 'Aspirin' then output antihypertensives;
 if  class ne ' ' then output other_meds;
 if drug ne ' ' then  output lipid_lowering;
run;

*Total population with medication;
proc sql;
create table drnoc.&REQUESTID.&RUNID._total_medication as
select "&DMID." as DMID, "&SITEID." as SITEID, count(distinct a.patid) as total_medication
	from indata.prescribing as a,
		 visit as diagpop
	where  (&start. LE rx_order_date LE &end.) 
	    and (a.patid=diagpop.patid) 
	having total_medication ge &threshold.;
quit;
%end;
%mend disp;
%disp;

%macro pres;
%if ("&dispensing" EQ "N" and "&prescribing"="Y") %then %do;
proc sql;
create table _pres as 
select diagpop.patid,
	   encounterid,
	   prescribingid,
	   rxnorm_cui as drug_code,
	   rx_order_date as drug_date,
	   rx_order_time,
	   year(rx_order_date) as year,
	   qtr(rx_order_date) as qtr,
	   rx_start_date,
	   rx_end_date,
 	   rx_providerid,
	   raw_rx_med_name,
	   b.class, 
	   b.term_type, 
	   b.drug
from indata.prescribing as a,
	infolder.code_list_pres as b,
	 visit as diagpop
where b.rx_normcui=a.rxnorm_cui
	and coalesce (rx_start_date,rx_order_date) between &start. and &end.
	and a.patid=diagpop.patid
order by patid;
quit;

proc sql;
create table dmlocal.&REQUESTID.&RUNID._pres as 
select a.*,
	   b.taxo
from _pres as a
	 left join
	 _taxonomy as b
  on a.rx_providerid=b.rx_providerid;
quit;

data antihypertensives lipid_lowering other_meds;
set dmlocal.&REQUESTID.&RUNID._pres;
yrq=cat(year,qtr);
if qtr in (1 2) then interval=1;
if qtr in (3 4) then interval=2;
six_month=cat(year,interval);
 if  class ne ' ' and class ne 'Aspirin' then output antihypertensives;
 if  class ne ' ' then output other_meds;
 if drug ne ' ' then  output lipid_lowering;
run;

*Total population with medication;
proc sql;
create table drnoc.total_medication as
select "&DMID." as DMID, "&SITEID." as SITEID, count(distinct a.patid) as total_medication
	from indata.prescribing as a,
		 visit as diagpop
	where  (coalesce (rx_start_date,rx_order_date) between &start. and &end.) 
	    and (a.patid=diagpop.patid) 
	having total_medication ge &threshold.;
quit;

%end;
%mend pres;
%pres;

%macro pres_dis;
%if ("&dispensing" EQ "Y" and "&prescribing" EQ "Y") %then %do;

proc sql;
create table dispense as 
select diagpop.patid, 
	   dispense_date as drug_date,
	   year(dispense_date) as year,
	   qtr(dispense_date) as qtr,
	   a.ndc, 
	   b.rxcui as drug_code,
	   prescribingid,
	   b.class, 
       b.drug
from indata.dispensing as a,
	infolder.code_list_disp as b,
	 visit as diagpop
where b.ndc=a.ndc
	and &start. LE dispense_date LE &end.
	and a.patid=diagpop.patid
order by patid;
quit;

proc sql;
create table _dispense1 as 
select a.*,
	   b.rx_providerid
from dispense as a
	 left join
	 indata.prescribing as b
  on a.prescribingid=b.prescribingid;
quit;

proc sql;
create table dmlocal.&REQUESTID.&RUNID._dispense as 
select a.*,
	   b.taxo
from _dispense1 as a
	 left join
	 _taxonomy as b
  on a.rx_providerid=b.rx_providerid;
quit;

proc sql;
create table _pres as 
select diagpop.patid,
	   encounterid,
	   prescribingid,
	   rxnorm_cui as drug_code,
	   rx_order_date as drug_date,
	   rx_order_time,
	   year(rx_order_date) as year,
	   qtr(rx_order_date) as qtr,
	   rx_start_date,
	   rx_end_date,
 	   rx_providerid,
	   raw_rx_med_name,
	   b.class, 
	   b.term_type, 
	   b.drug
from indata.prescribing as a,
	infolder.code_list_pres as b,
	 visit as diagpop
where b.rx_normcui=a.rxnorm_cui
	and coalesce (rx_start_date,rx_order_date) between &start. and &end.
	and a.patid=diagpop.patid
order by patid;
quit;

proc sql;
create table dmlocal.&REQUESTID.&RUNID._pres as 
select a.*,
	   b.taxo
from _pres as a
	 left join
	 _taxonomy as b
  on a.rx_providerid=b.rx_providerid;
quit;

data antihypertensives lipid_lowering other_meds;
set dmlocal.&REQUESTID.&RUNID._dispense dmlocal.&REQUESTID.&RUNID._pres;
yrq=cat(year,qtr);
if qtr in (1 2) then interval=1;
if qtr in (3 4) then interval=2;
six_month=cat(year,interval);
 if  class ne ' ' and class ne 'Aspirin' then output antihypertensives;
 if  class ne ' ' then output other_meds;
 if drug ne ' ' then  output lipid_lowering;
run;

*Total population with medication;
proc sql;
create table _pres_pop as
select distinct a.patid
from indata.prescribing as a,
	visit as diagpop
where  (coalesce (rx_start_date,rx_order_date) between &start. and &end.) 
	    and (a.patid=diagpop.patid) ;
create table _disp_pop as
select distinct a.patid
from indata.dispensing as a,
	visit as diagpop
where  (&start. LE Dispense_date LE &end.) 
	    and (a.patid=diagpop.patid) ;
quit;

proc sql;
create table _med_pop as
select coalesce (a.patid, b.patid) as id
	from _pres_pop as a 
	full join _disp_pop as b
	on a.patid=b.patid;
quit;

proc sql;
create table drnoc.&REQUESTID.&RUNID._total_medication as
select "&DMID." as DMID, "&SITEID." as SITEID, count(distinct id) as total_medication
	from _med_pop
	having total_medication ge &threshold. ;
quit;

proc datasets NOLIST NOWARN library=WORK;
   delete _:;
quit;
%end;
%mend pres_dis;
%pres_dis;
