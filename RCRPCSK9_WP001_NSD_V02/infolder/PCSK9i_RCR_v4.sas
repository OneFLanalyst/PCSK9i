

proc printto log="&DRNOC.&REQUESTID.&RUNID..log" new;
run;

/*Empty work*/   
proc datasets NOLIST NOWARN library=WORK;
   delete _:;
quit;

* Format age groups;
PROC FORMAT;
VALUE agefmt
	18-24='18-24 Years'
	25-34='25-34 Years'
	35-44='35-44 Years'
	45-54='45-54 Years'
	55-64='55-64 Years'
	65-74='65-74 Years'
	75-84='75-84 Years'
	85-high='85+ Years';
RUN;

*Get count all patid in demogs;
data _demogs;
  set indata.demographic (keep=patid birth_date sex hispanic race);

  if missing(Patid)=0 and missing(Birth_date)=0 then both=1;
  if missing(Birth_date)=0 then do;
        minagedate=intnx("year",Birth_date,18,"SAMEDAY");
        if month(Birth_date) = 2 and day(Birth_date)=29 then minagedate=minagedate+1;

		maxagedate=intnx("year",Birth_date,110,"SAMEDAY");
        if month(Birth_date) = 2 and day(Birth_date)=29 then maxagedate=maxagedate+1;
    end;

	age=intck('YEAR',BIRTH_DATE,&anchor.,'C'); 

	if 18 le age le 110 then output;

format minagedate maxagedate date9.;
run;


proc means data=_demogs noprint missing;
 var both;
 output out=_DemogsAlllist sum=;
run;

proc sort data =_demogs out =_DemogsList nodupkey;
 by patid;
 where both=1;
run;

*Select patients with an encounter and diagnosis in study period;
PROC SQL;
  CREATE TABLE enc AS
  SELECT a.patid, 
		 a.encounterid, 
	     a.enc_type, 
	     a.admit_date, 
		 birth_date, 
		 sex, 
		 hispanic, 
		 race, 
		 age
  FROM indata.encounter as a,
  		_DemogsList as b
  WHERE 
	   &start. le admit_date le &end.
	   and a.patid=b.patid;
QUIT;

PROC SQL;
  CREATE TABLE _dx AS
  SELECT a.diagnosisid, 
		 a.patid, 
         a.encounterid, 
	     a.dx, 
 		 a.dx_type,
		 a.enc_type,
         a.admit_date,
	     a.pdx
  FROM 
       indata.diagnosis as a,
		_DemogsList as b
  WHERE 
	   &start. le admit_date le &end.
		 and a.patid=b.patid;
QUIT;

proc sort data=enc nodupkey out=_enc1;
 by patid;
run;

proc sort data=_dx nodupkey out=_dx1;
 by patid;
run;

PROC SQL;
  CREATE TABLE _visit AS
  SELECT distinct a.patid,
 		 birth_date, 
		 sex, 
		 hispanic, 
		 race, 
		 age
  FROM _enc1 AS a, 
       _dx1 as b
  WHERE a.patid =b.patid 
  ORDER patid ;
QUIT;

data visit;
set _visit;

agegrp=put(age,agefmt.);
  if sex not in ('M' 'F') then sex ='XX';
  if race not in ('01' '02' '03' '04' '05') then race='XX';
  if hispanic not in ('Y' 'N') then hispanic='XX';
run;

data _diag;
set infolder.code_list_dx;
  original_code=dx;
  code = compress(dx,'. ');
  length=length(dx);
  CodeType=upcase(dx_type);

if CodeType in:('DX') then do; codetype=compress(codetype,'DX'); output _diag; end;
run;

data _diag;
set _diag ;
 OrigCode=code; 
 exact=index(code,'*')=0;
		if exact=1 then do;
			code=compress(code,'*');
		end;
		else do;
			WildcardIndex=index(code,'*');
			if code='*' then do;   	                    /*Extract all codes*/
				exact=-2;	
			end;
			else if WildcardIndex=length(code) then do;   	/*the star is at the end*/
				code=compress(code,'*'); 
			end;
			else do;                            		/*the star is in a middle position*/
				exact=-1;		
				LengthCodeEnd=length(code)-WildcardIndex;
				CodeEnd=substr(code,WildcardIndex+1,LengthCodeEnd);		
				code=substr(code,1,WildcardIndex-1);
			end;
		end;
		length=length(Code); 
run;		


/*Select diagnosis records*/
proc sql;
create table dmlocal.&REQUESTID.&RUNID._condition_dx as
    select diagtb.diagnosisid, 
		   diagtb.patid, 
           diagtb.encounterid, 
	       diagtb.dx, 
 		   diagtb.dx_type,
		   diagtb.enc_type,
           diagtb.admit_date,
	       diagtb.pdx,
		   diaglist.Description,
		   diaglist.condition format= $15.,
	      diaglist.stroke_type format= $15.
    from _dx as diagtb,
		 _diag as diaglist,
   		 visit as diagpop
    where (
		  &start. le diagtb.admit_date le &end.
		and
		 (
		 (diaglist.exact=-2) or
         (diagtb.DX_type = diaglist.codetype and diaglist.exact=-1 and substr(compress(diagtb.DX,'.'),1,diaglist.length) = diaglist.code and 
		 substr(compress(diagtb.DX,'.'),diaglist.WildcardIndex+1,diaglist.LengthCodeEnd) = diaglist.CodeEnd) or
	     (diagtb.DX_type = diaglist.codetype and diaglist.exact=0  and substr(compress(diagtb.DX,'.'),1,diaglist.length) = diaglist.Code) or
         (diagtb.DX_type = diaglist.codetype and diaglist.exact=1  and compress(diagtb.DX,'.')=diaglist.code)
         )
		and diagpop.patid=diagtb.patid );
quit;


data _FH _CHD_CAD _dyslip comorbidities;
set dmlocal.&REQUESTID.&RUNID._condition_dx;

	if description in: ('(CAD' '(CHF') then output _CHD_CAD;
	else if description =: '(Dyslipidemia' then output _dyslip;
	else if description in: ('(FH)' 'tendon' 'corneal') then output _FH;
	if condition ne ' ' then output comorbidities;
run;

proc sort data=_FH nodupkey out= fh1;
by patid;
run;

proc sort data=_CHD_CAD nodupkey out= CHD_CAD1;
by patid;
run;

proc sort data=_dyslip nodupkey out= dyslip1;
by patid;
run;

proc datasets NOLIST NOWARN library=WORK;
   delete _:;
quit;










