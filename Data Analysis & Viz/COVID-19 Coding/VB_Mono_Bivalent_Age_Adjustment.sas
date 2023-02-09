/*************************************************************************************************/
/* MN, CO, TN VB Variant Analysis 															     */
/* SAS CODE written 8 FEB 2023        															 */
/* Creates categories based upon vaccination status 											 */
/* Output table of eventids, vb_status, dob, firstname, lastname for matching to sequencing data */
/*************************************************************************************************/

libname cedrs 	odbc dsn='CEDRS_3_read' 	schema=CEDRS 	READ_LOCK_TYPE=NOLOCK; /*66 - CEDRS */;
libname covid19  odbc dsn='COVID19' 		schema=ciis 	READ_LOCK_TYPE=NOLOCK; /* 144 - CIIS */;
libname covid	 odbc dsn='COVID19' 	    schema=dbo		READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname covcase	 odbc dsn='COVID19' 	    schema=cases	READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname archive 'O:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive';
libname archive2 'O:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive2';


/* Pull Immunization data */;

proc sql;
create table vaccines
as select distinct v.EventID, input(v.vaccination_date, anydtdtm.) as Vax_Date format=dtdate9., v.Vaccination_Code, v.vaccination_code_id, v.source

	from covid19.case_iz v

	order by v.EventID, vax_date
;
quit;
/*n = 2,673,826
proc freq data = vaccines; table vaccination_code * vaccination_code_id/ norow nocol nopercent; run;
proc freq data = vaccines; table vaccination_code_id/ norow nocol nopercent; run;


/*Output records with unknown or non-FDA approved vaccinations to check numbers and vaccine combinations.*/
data non_FDA_doses;
set vaccines;
if vaccination_code_id in (.,213,225,226,227,506,509,510,511,516,520) then output;  *-----> Can add/remove codes if needed based on CDC guidelines;
run;
/* n = 24,803*/

/*Remove records with unknown or non-FDA approved vaccinations from CIIS data*/
data vaccines2;
	set vaccines;
if vaccination_code_id in (225,226,227,506,509,510,511,516,520) then delete;
run;
/*n= 2,649,048  - 24,778 records removed*/

data vaccines3;
	set vaccines2;
dose + 1;
	by eventid;
	if first.eventID then dose = 1;
run;

proc transpose data=vaccines3 out=wide1 prefix=vax_date_;
	by eventid;
	id dose;
	var vax_date;
 run;

 proc transpose data=vaccines3 out=wide2 prefix=manufacturer_code_;
	by eventid;
	id dose;
	var vaccination_code;
 run;

 proc transpose data=vaccines3 out=wide3 prefix=vaccination_code_id;
	by eventid;
	id dose;
	var vaccination_code_id;
 run;

 proc transpose data=vaccines3 out=wide4 prefix=source;
	by eventid;
	id dose;
	var source;
 run;

/* This has all vaccination dates, and all vaccine manufacturers*/;

data ciis_vax_all;
	merge wide1 wide2 wide3 wide4;						
	by eventID;
	drop _name_ _label_;
run;

proc sort data = ciis_vax_all; by descending vaccination_code_id11; run;  /*ONE record has 11 vaccinations and the last one is a Bivalent*/

PROC SQL;
   CREATE TABLE WORK.CIIS_VAX AS 
   SELECT t1.eventid, 
   		  t1.source1,
		  t1.source2,
		  t1.source3,
          t1.vax_date_1,
		  t1.vax_date_2,
		  t1.vax_date_3,
		  t1.vax_date_4,
		  t1.vax_date_5,
		  t1.vax_date_6,
		  t1.vax_date_7,
		  t1.vax_date_8,
		  t1.vax_date_9,
		  t1.vax_date_10,
		  t1.vax_date_11,
		  t1.vaccination_code_id1 as CVX_1,
		  t1.vaccination_code_id2 as CVX_2,
		  t1.vaccination_code_id3 as CVX_3,
		  t1.vaccination_code_id4 as CVX_4,
		  t1.vaccination_code_id5 as CVX_5,
		  t1.vaccination_code_id6 as CVX_6,
		  t1.vaccination_code_id7 as CVX_7,
		  t1.vaccination_code_id8 as CVX_8,
		  t1.vaccination_code_id9 as CVX_9,
		  t1.vaccination_code_id10 as CVX_10,
		  t1.vaccination_code_id11 as CVX_11

      FROM work.ciis_vax_all t1
	  ;
QUIT;
/* n = 967,683 */;
/***********************************************************/;
/* We have cases that are manually entried that are in the CIIS_Vax dataset and we need to remove those from this dataset */;

DATA CIIS_VAX_1;
	set CIIS_VAX; 
	if source1 = 'CIIS' or source2 = 'CIIS' then output;
RUN;


/***********************************************************/;

/**  Pull all VB cases from 144, Cedrs_view */

PROC SQL;
   CREATE TABLE WORK.VB_CASES AS 
   SELECT t1.profileid, 
          t1.eventid, 
          t1.gender, 
          t1.countyassigned, 
		  t1.age_at_reported,
		  t1.collectiondate,
		  t1.countyassigned, 
          t1.address_state, 
		  t1.partialonly,
          t1.reinfection, 
          t1.hospitalized_cophs,
		  t1.deathdueto_vs_u071, 
          t1.cophs_admissiondate, 
          t1.hospitalized, 
          t1.casestatus,
		  t1.breakthrough
      FROM covid.cedrs_view t1
	  where breakthrough = 1 and age_at_reported >= 5 and address_state in ('CO','') 
	  		and partialonly = 0 and countyassigned ne 'INTERNATIONAL';
QUIT;


/* left join the ciis and cedrs data  */;
PROC SQL;
	create table Combined
		
	as select distinct *
	from work.VB_cases as p
	left join work.ciis_vax_1 v on p.EventID = v.EventID
;
QUIT;


/***********************************************************/;

/*Clean the work.combine; age groups */;

DATA dates_clean;
	set combined;

	FORMAT  age_group $25. covtestdt vax_date_1 vax_date_2 vax_date_3  vax_date_4 
			 vax_date_5  vax_date_6  vax_date_7  vax_date_8 vax_date_9 vax_date_10 vax_date_11 MMDDYY10.;

	/*Format dates*/
	covtestdt = input(CollectionDate, yymmdd10.);
	vax_date_1 = datepart(vax_date_1);
	vax_date_2 = datepart(vax_date_2);
	vax_date_3 = datepart(vax_date_3);
	vax_date_4 = datepart(vax_date_4);
	vax_date_5 = datepart(vax_date_5); 
	vax_date_6 = datepart(vax_date_6);
	vax_date_7 = datepart(vax_date_7);
	vax_date_8 = datepart(vax_date_8);
	vax_date_9 = datepart(vax_date_9);
	vax_date_10 = datepart(vax_date_10);
	vax_date_11= datepart(vax_date_11);


	/* Create age groups to match those in the Population_fix file for rate calculations */;

	if age_at_reported >= 0 and age_at_reported  <= 4 then age_Group = '<5'; 
		else if age_at_reported  >= 5 and age_at_reported  <= 11 then age_Group = '5-11'; 
		else if age_at_reported  >= 12 and age_at_reported  <= 19 then age_Group = '12-19'; 
		else if age_at_reported  >= 20 and age_at_reported  <= 29 then age_Group = '20-29';
		else if age_at_reported  >= 30 and age_at_reported  <= 39 then age_Group = '30-39';
		else if age_at_reported  >= 40 and age_at_reported  <= 49 then age_Group = '40-49';
		else if age_at_reported  >= 50 and age_at_reported  <= 59 then age_Group = '50-59';
		else if age_at_reported  >= 60 and age_at_reported  <= 69 then age_Group = '60-69';
		else if age_at_reported  >= 70 and age_at_reported  <= 79 then age_Group = '70-79';
		else if age_at_reported  >= 80 then age_Group = '80+';

	if covtestdt >= '01Jan2022'd then output;
 
RUN;


DATA VB_Case;
	set dates_clean;
	format first_vax_dt fully_vax_dt first_booster_dt second_booster_dt 
			third_booster_dt fourth_booster_dt fifth_booster_dt BiBoost_Auth_dt Mono_Boost_Auth_dt mmddyy10.;

	/* create dates for when fully vaccinated, when fully vaxed with booster dates */;
	if CVX_1 = 212 THEN DO; 
		first_vax_dt = vax_date_1;
		fully_vax_dt = vax_date_1 + 14;
		first_booster_dt = vax_date_2 + 14;
		second_booster_dt = vax_date_3 + 14;
		third_booster_dt = vax_date_4 + 14;
		fourth_booster_dt = vax_date_5 + 14;
		fifth_booster_dt = vax_date_6 + 14;
		sixth_booster_dt = vax_date_7 + 14;
		seventh_booster_dt = vax_date_8 + 14;
		eighth_booster_dt = vax_date_9 + 14; 
		ninth_booster_dt = vax_date_10 + 14;
		tenth_booster_dt = vax_date_11 + 14; 
		END;

	if CVX_1 = 207 or CVX_1 = 208 or CVX_1 = 210 or CVX_1 =211 or CVX_1 =217
		or CVX_1 = 218 or CVX_1 = 219 or CVX_1 = 221 or CVX_1 = 228 or CVX_1 = 229
		or CVX_1 = 300 or CVX_1 = 301 THEN DO;
		first_vax_dt = vax_date_1;
		fully_vax_dt = vax_date_2 + 14;
		first_booster_dt = vax_date_3 + 14;
		second_booster_dt = vax_date_4 + 14;
		third_booster_dt = vax_date_5 + 14;
		fourth_booster_dt = vax_date_6 + 14;
		fifth_booster_dt = vax_date_7 + 14;
		sixth_booster_dt = vax_date_8 + 14;
		seventh_booster_dt = vax_date_9 + 14;
		eighth_booster_dt = vax_date_10 + 14; 
		ninth_booster_dt = vax_date_11 + 14;
		END;

	BiBoost_Auth_dt = '01Sep2022'd;
	Mono_Boost_Auth_dt = '13Aug2021'd;

	/*removing any records where vax_date_1 is missing and where partially vaccinated, or non-FDA approved in primary series*/;
	if Vax_date_1 = . then delete;
	if CVX_1 in (213,208,217,225,226,227,506,509,510,511,516,520) and CVX_2 = . then delete;

RUN;


PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_VB_CASE AS 
   SELECT t1.profileid, 
          t1.eventid, 
          t1.gender, 
		  t1.age_at_reported,
		  t1.partialonly,
          t1.reinfection, 
          t1.covtestdt, 
          t1.hospitalized_cophs,
		  t1.deathdueto_vs_u071, 
          t1.cophs_admissiondate, 
          t1.hospitalized, 
          t1.casestatus,
		  t1.breakthrough,
          t1.vax_date_1, 
          t1.vax_date_2, 
          t1.vax_date_3, 
          t1.vax_date_4, 
          t1.vax_date_5, 
          t1.vax_date_6, 
          t1.vax_date_7, 
          t1.vax_date_8, 
          t1.vax_date_9, 
          t1.vax_date_10, 
          t1.vax_date_11, 
          t1.CVX_1, 
          t1.CVX_2, 
          t1.CVX_3, 
          t1.CVX_4, 
          t1.CVX_5, 
          t1.CVX_6, 
          t1.CVX_7, 
          t1.CVX_8, 
          t1.CVX_9, 
          t1.CVX_10, 
          t1.CVX_11, 
          t1.covtestdt, 
          t1.fully_vax_dt,  
		  t1.first_vax_dt,  
          t1.first_booster_dt, 
          t1.second_booster_dt, 
          t1.third_booster_dt, 
          t1.fourth_booster_dt, 
          t1.fifth_booster_dt, 
          t1.sixth_booster_dt, 
          t1.seventh_booster_dt, 
          t1.eighth_booster_dt, 
          t1.ninth_booster_dt, 
          t1.tenth_booster_dt, 
          t1.BiBoost_Auth_dt, 
          t1.Mono_Boost_Auth_dt
      FROM WORK.VB_CASE t1;
QUIT;


/* CVX_1 = 212 JANSSEN */;

PROC SQL; 
	create table Janssen as
	select * from WORK.QUERY_FOR_VB_CASE
	where CVX_1 IN (212);
QUIT; 
/* n = 26,733 */;

DATA Janssen_primary Janssen_booster;
	set Janssen;
	format vb_status $35.;

	if CVX_1 = 212 and CVX_2 = . and covtestdt >= fully_vax_dt then vb_status = 'Monovalent Vaccinated'; 

	If CVX_1 = 212 and CVX_2 = . then output Janssen_primary;
		else output Janssen_booster;
RUN;

DATA Janssen_booster_1 Janssen_vb;
	set Janssen_booster;
	format vb_status $35.;

	if CVX_1 = 212 and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,212,211) and CVX_3 = . and first_booster_dt < covtestdt >= fully_vax_dt 
		and vax_date_2 >= Mono_Boost_Auth_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,212) and CVX_3 = . and covtestdt >= first_booster_dt 
		and vax_date_2 >= Mono_Boost_Auth_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,212) and CVX_3 = . and covtestdt >= fully_vax_dt  then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (207,208,210,211,213,217,218,219,221,212,228) and CVX_3 IN (207,208,210,211,213,217,218,219,221,228,212) and CVX_4 = .
		and covtestdt >= fully_vax_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (207,208,210,211,213,217,218,219,221,212,228) and CVX_3 IN (207,208,210,211,213,217,218,219,221,228,212) 
		and CVX_4 IN (207,208,210,211,213,217,218,219,221,228,212) and covtestdt >= fully_vax_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (229,300,301) and covtestdt >= first_booster_dt and 
		vax_date_2 >= BiBoost_Auth_dt then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (229,300,301) and vax_date_3 = . and covtestdt >= fully_vax_dt and 
		vax_date_2 < BiBoost_Auth_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_3 IN (229,300,301) and third_booster_dt < covtestdt >= second_booster_dt and 
		vax_date_3 < BiBoost_Auth_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (229,300,301) and covtestdt < first_booster_dt and 
		vax_date_2 >= BiBoost_Auth_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if vb_status = '' then output Janssen_vb;
		else output Janssen_booster_1;
RUN;

DATA Janssen_Bivalent Janssen_vb_1;
	set Janssen_vb;
	format vb_status $35.;

	if CVX_1 = 212 and CVX_2 IN (229,300,301) and covtestdt >= first_booster_dt and 
		vax_date_2 >= BiBoost_Auth_dt then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_3 IN (229,300,301) and covtestdt >= third_booster_dt and 
		vax_date_3 >= BiBoost_Auth_dt then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_4 IN (229,300,301) and covtestdt >= fourth_booster_dt and 
		vax_date_4 >= BiBoost_Auth_dt then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_5 IN (229,300,301) and covtestdt >= fifth_booster_dt and 
		vax_date_5 >= BiBoost_Auth_dt then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_6 IN (229,300,301) and covtestdt >= sixth_booster_dt and 
		vax_date_6 >= BiBoost_Auth_dt then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_7 IN (229,300,301) and covtestdt >= seventh_booster_dt and 
		vax_date_7 >= BiBoost_Auth_dt then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_8 IN (229,300,301) and covtestdt >= eighth_booster_dt and 
		vax_date_8 >= BiBoost_Auth_dt then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if vb_status = '' then output Janssen_vb_1;
		else output Janssen_Bivalent;

RUN;

Data Janssen_Bivalent_2;
	set Janssen_vb_1;
	format vb_status $35.;

	if CVX_1 = 212 and CVX_2 IN (213) and CVX_3 IN (212,500,208,207,213) 
		and covtestdt >= fully_vax_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (213,500)
		and covtestdt >= fully_vax_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,212,500) and CVX_3 IN (207,208,210,211,213,217,218,219,221,228,212,500) 
		and covtestdt >= third_booster_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,212,500) and CVX_3 IN (229,300,301) 
		and covtestdt =< third_booster_dt and vax_date_3 >= BiBoost_Auth_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,212,500) and CVX_4 IN (229,300,301) and covtestdt =< fourth_booster_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

	if CVX_1 = 212 and CVX_5 IN (229,300,301) and covtestdt =< fourth_booster_dt then do;
		vb_status = 'Monovalent Vaccinated'; end;

RUN;

DATA Combine_Janssen;
	set Janssen_primary
		Janssen_booster_1
		Janssen_Bivalent
		Janssen_Bivalent_2;
RUN;
/* n = 26709  */;

PROC FREQ data=Combine_Janssen; tables vb_status; RUN;


PROC SORT data=Janssen; by eventid; RUN;
PROC SORT data=combine_Janssen; by eventid; RUN;

data match_JnJ nomatch_JnJ ;
	merge Janssen (in=old) Combine_Janssen (in=new) ;
	by EVENTID ;
	if old and new then output match_JnJ ; else output nomatch_JnJ ;
run ;
/* nomatch = 0; match = 267,33 & matches the original Janssen table */;

/* mRNA */;

PROC SQL; 
	create table mRNA as
	select * from WORK.QUERY_FOR_VB_CASE
	where CVX_1 IN (207,208,210,211,213,217,218,219,221,228) or CVX_2 IN (207,208,210,211,213,217,218,219,221,228);
QUIT; 
/* N = 388,110 */;

DATA mRNA_primary mRNA_booster;
	set mRNA; 
	format vb_status $35.;

	if CVX_1 IN (207,208,210,211,213,217,218,219,221,228) and CVX_2 IN (207,208,210,211,213,217,218,219,221,228)
	 and vax_date_3 = . then vb_status = 'Monovalent Vaccinated'; 

	if vb_status = '' then output mRNA_booster;
		else output mRNA_primary;

RUN;

DATA mRNA_Booster_1 mRNA_Booster_2;
	set mRNA_Booster;
	format vb_status $35.;

	if CVX_1 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_3 IN (299,300,301) 
		and covtestdt >= first_booster_dt and vax_date_3 >= BiBoost_Auth_dt  then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_4 IN (299,300,301) 
		and covtestdt >= second_booster_dt and vax_date_4 >= BiBoost_Auth_dt  then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_5 IN (299,300,301) 
		and covtestdt >= third_booster_dt and vax_date_5 >= BiBoost_Auth_dt  then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_6 IN (299,300,301) 
		and covtestdt >= fourth_booster_dt and vax_date_6 >= BiBoost_Auth_dt  then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_7 IN (299,300,301) 
		and covtestdt >= fifth_booster_dt and vax_date_7 >= BiBoost_Auth_dt  then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_8 IN (299,300,301) 
		and covtestdt >= sixth_booster_dt and vax_date_8 >= BiBoost_Auth_dt  then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_9 IN (299,300,301) 
		and covtestdt >= seventh_booster_dt and vax_date_9 >= BiBoost_Auth_dt  then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_10 IN (299,300,301) 
		and covtestdt >= eighth_booster_dt and vax_date_10 >= BiBoost_Auth_dt  then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if CVX_1 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_2 IN (207,208,210,211,213,217,218,219,221,228,230) and CVX_11 IN (299,300,301) 
		and covtestdt >= ninth_booster_dt and vax_date_11 >= BiBoost_Auth_dt  then do;
		vb_status = 'Bivalent Vaccinated'; end;

	if vb_status = '' then output mRNA_booster_2;
		else output mRNA_booster_1;

RUN;

DATA mRNA_booster_2; 
	set mRNA_booster_2;
	format vb_status $35.;

	vb_status = 'Monovalent Vaccinated'; 

RUN;

DATA Combine_mRNA;
	set  mRNA_primary
		 mRNA_Booster_1
		mRNA_booster_2; 
RUN;
/* N = 388,110 */;

PROC FREQ data=Combine_mRNA; tables vb_status; RUN;


PROC SORT data=mRNA; by eventid; RUN;
PROC SORT data=combine_mRNA; by eventid; RUN;

data match_mRNA nomatch_mRNA ;
	merge mRNA (in=old) Combine_mRNA(in=new) ;
	by EVENTID ;
	if old and new then output match_mRNA ; else output nomatch_mRNA ;
run ;
/* nomatch = 0; match = 388,110; same as Combine_mRNA */;

/* Combine all */;

DATA VB_Combined;
	set combine_Janssen
		combine_mRNA;
	case = 1; 
RUN;
/* N = 414,843 */;

/* Remove Duplicates */;

PROC SORT data=VB_Combined nodup dupout=dups; by eventid; RUN;
/* N = 407,828; dups = 7015 */;

PROC FREQ data=VB_Combined; tables vb_status; RUN;
/* Bivalent = 12,374 
/* Monovalent = 395,454 



/* UNVACCINATED */;

/* Pull in Unvaxed Cases, we are excluding anyone with a partial vax for this analysis */;

PROC SQL;
   CREATE TABLE WORK.Unvax AS 
   SELECT t1.profileid, 
          t1.eventid, 
          t1.gender, 
          t1.countyassigned, 
		  t1.age_at_reported,
		  t1.collectiondate,
		  t1.countyassigned, 
          t1.address_state, 
		  t1.partialonly,
          t1.reinfection, 
          t1.hospitalized_cophs,
		  t1.deathdueto_vs_u071, 
          t1.cophs_admissiondate, 
          t1.hospitalized, 
          t1.casestatus,
		  t1.breakthrough
      FROM covid.cedrs_view t1
	  where breakthrough = 0 and age_at_reported >= 5 and address_state in ('CO','') 
	  		and partialonly = 0 and countyassigned ne 'INTERNATIONAL';
QUIT;

DATA UNVAX_all;
	set work.unvax;
	format vb_status $35.;

	vb_status = 'Unvaccinated';
RUN; 
/* N = 1,066,025 */;

DATA ALL_CASES;
	set VB_combined
		Unvax_all;

	format age_Group $25.;
	cases = 1;

	if age_at_reported >= 0 and age_at_reported  <= 4 then age_Group = '<5'; 
		else if age_at_reported  >= 5 and age_at_reported  <= 11 then age_Group = '5-11'; 
		else if age_at_reported  >= 12 and age_at_reported  <= 19 then age_Group = '12-19'; 
		else if age_at_reported  >= 20 and age_at_reported  <= 29 then age_Group = '20-29';
		else if age_at_reported  >= 30 and age_at_reported  <= 39 then age_Group = '30-39';
		else if age_at_reported  >= 40 and age_at_reported  <= 49 then age_Group = '40-49';
		else if age_at_reported  >= 50 and age_at_reported  <= 59 then age_Group = '50-59';
		else if age_at_reported  >= 60 and age_at_reported  <= 69 then age_Group = '60-69';
		else if age_at_reported  >= 70 and age_at_reported  <= 79 then age_Group = '70-79';
		else if age_at_reported  >= 80 then age_Group = '80+';

	drop partialonly;

RUN;

PROC SORT Data=ALL_CASES nodup dupout=dup_all; by eventid; RUN;
/* zero duplicates in dup_all */;
/* N = 1,473,853 */;



/****************************************************************/;
/****************************************************************/;
/*  Next we pull Population data & create population tables with weights for rate calculations */;

/* DENOMINATOR DATA */;

DATA Population;
	set covid19.vaxunvax_age_bivalent;
	format date2 mmddyy10. age_group $25.;
	if age >= 0 and age <= 4 then age_Group = '<5'; 
		else if age >=5 and age <= 11 then age_Group = '5-11'; 
		else if age >= 12 and age <= 19 then age_Group = '12-19'; 
		else if age >= 20 and age <= 29 then age_Group = '20-29';
		else if age >= 30 and age <= 39 then age_Group = '30-39';
		else if age >= 40 and age <= 49 then age_Group = '40-49';
		else if age >= 50 and age <= 59 then age_Group = '50-59';
		else if age >= 60 and age <= 69 then age_Group = '60-69';
		else if age >= 70 and age <= 79 then age_Group = '70-79';
		else if age >= 80 then age_Group = '80+';
	date2 = input(date,yymmdd10.);
	if date2 >= '01jan2021'd then output;
RUN;

PROC SORT data=population; by date2 age_Group; RUN;

PROC SQL; 
	create table sum_population as
 	select 	date2,
			total_unvax,
			total_primary_series,
			total_monovalent,
			total_bivalent,
			age_group, 
	sum(total_primary_series,total_monovalent) as sum_total_NoBooster,
	sum(total_unvax) as sum_total_unvax,
	sum(total_bivalent) as sum_total_bivalent

	FROM work.population
	GROUP BY date2, age_group;
QUIT; 

DATA Population_2; 
	set sum_population;
	by date2 age_group;

	if first.age_group then output; 

RUN; 

DATA Population_fix_1;
	set population_2;

	keep date2 age_group sum_total_unvax  sum_total_NoBooster sum_total_bivalent;

RUN; 

/* (8B) POPULATION WEIGHTS */;

DATA weights;
	set covid.populations_allcounties_allages;
	format age_group $25.;
	if age >= 0 and age <= 4 then age_Group = '<5'; 
		else if age >=5 and age <= 11 then age_Group = '5-11'; 
		else if age >= 12 and age <= 19 then age_Group = '12-19'; 
		else if age >= 20 and age <= 29 then age_Group = '20-29';
		else if age >= 30 and age <= 39 then age_Group = '30-39';
		else if age >= 40 and age <= 49 then age_Group = '40-49';
		else if age >= 50 and age <= 59 then age_Group = '50-59';
		else if age >= 60 and age <= 69 then age_Group = '60-69';
		else if age >= 70 and age <= 79 then age_Group = '70-79';
		else if age >= 80 then age_Group = '80+';
RUN; 

PROC SQL; 
	create table sum_population_weights as
 	select 	county,
			total,
			age_group, 

	sum(total) as total_age_group

	FROM work.weights
	GROUP BY age_group;
QUIT; 

DATA Pop_weights;
	set sum_population_weights;
	by age_group;

	if first.age_group then output; 
	drop county total;
RUN; 

PROC SQL; 
	create table sum_population_weights as
 	select 	age_group,
			total_age_group,

	sum(total_age_group) as total_pop

	FROM work.pop_weights;
	
QUIT; 

DATA Weights_calc;
	set sum_population_weights; 

	weight = total_age_group/total_pop;
RUN; 

/* LEFT JOIN Population with Weight Calculation for a final Denominator Table */;

PROC SQL;
	create table population_fix
as select *

	from work.population_fix_1 v

	left join work.weights_calc x on v.age_group=x.age_group

;
QUIT;

PROC SORT data=population_fix; by date2; RUN;
/* This is the table we will use when doing calcuations. */;



/****************************************************************/;
/****************************************************************/;

/* CALCULATIONS */;
/*Need to count those cases, hosptializations, and death
SUM BY LABEL, AGE GROUP and COV TEST DATE for AGE ADJUSTMENT CALCULATION*/;

PROC SQL; 
	create table VB_Dashboard_Sum as
 	select 	vb_status,
			covtestdt, 
			age_group, 
			cases,
			hospitalized,
			deathdueto_vs_u071,

	sum(cases) as Sum_cases,
	sum(hospitalized) as sum_hosp,
	sum(deathdueto_vs_u071) as sum_death

	FROM work.ALL_CASES
	GROUP BY vb_status, age_group, covtestdt;
QUIT; 

PROC SORT data=VB_dashboard_SUM; by covtestdt vb_status age_group; RUN;

DATA sum_VB_Dashboard_1;
	set VB_dashboard_sum;
	by covtestdt vb_status age_group;

	if first.age_group then output; 

RUN; 


PROC SQL;
	create table calcs
as select *

	from sum_VB_Dashboard_1 v

	left join population_fix x on v.covtestdt=x.date2 and v.age_group=x.age_group

;
quit;



/* Calculations  */;

Data VB_Mono_Bivalent;
	set calcs;
	format label $35.;

	if vb_status = 'Unvaccinated' then  cases_per100k = ((Sum_cases/sum_total_unvax)*100000);
		else if vb_status = 'Monovalent Vaccinated' then cases_per100k = ((Sum_cases/sum_total_NoBooster)*100000);
		else if vb_status = 'Bivalent Vaccinated' then cases_per100k = ((Sum_cases/sum_total_Bivalent)*100000);

	if vb_status = 'Unvaccinated' then  hosp_per100k = ((Sum_hosp/sum_total_unvax)*100000);
		else if vb_status = 'Monovalent Vaccinated' then hosp_per100k = ((Sum_hosp/sum_total_NoBooster)*100000);
		else if vb_status = 'Bivalent Vaccinated' then hosp_per100k = ((Sum_hosp/sum_total_Bivalent)*100000);

	if vb_status = 'Unvaccinated' then  death_per1M = ((Sum_death/sum_total_unvax)*1000000);
		else if vb_status = 'Monovalent Vaccinated' then death_per1M = ((Sum_death/sum_total_NoBooster)*1000000);
		else if vb_status = 'Bivalent Vaccinated' then death_per1M = ((Sum_death/sum_total_Bivalent)*1000000);
	
	cases_wt = cases_per100k*weight;
	hosp_wt = hosp_per100k*weight;
	death_wt = death_per1M*weight;

	label = vb_status;

	drop date2 total_bivalent total_age_group cases hospitalized deathdueto_vs_u071
		 total_pop total_partially_vax total_unvax total_NoBooster weight ;
	if covtestdt >= '01May2022'd then output;

	drop vb_status hospitalized deathdueto_vs_u071 cases;

RUN;


/* Output VB_MONO_BIVALENT.csv has the following variables:

covtestdt = collection date of sample
age_group = age group 
sum_cases = all the cases summed by label, age_group and covtestdt
sum_hosp =  all the hospitalized cases with associated collection date, summed by label, age_group and covtestdt
sum_death = all the deaths due to COVID-19 with associated collection date, summed by label, age_group, and covtestdt
sum_total_NoBooster = state population of those who received a monovalent dose, summed by label, age_group, and covtestdt
sum_total_unvax = population of those who received no immunizations, summed by label, age_group, and covtestdt
sum_total_bivalent = population of those who received a monovalent dose, summed by label, age_group, and covtestdt
label = vaccination status: unvax, monovalent, bivalent
cases_per_100k = cases/population x 100k, calculated by label, age_group, and covtestdt, cases = 1
hosp_per_100k = hosptializations/population x 100k, calculated by label, age_group, and covtestdt, hosptialization = 1
deaths_per_1M = death/population x 1 million, calculated by label, age_group, and covtestdt, death data vital statistics = 1
cases_wt = age adjusted weight for cases, calculated by case per 100k*weights, label, age_group, and covtestdt
hosp_wt = age adjusted weight for hospitalizations, calculated by hosp per 100K*weights, label, age_group, and covtestdt
death_wt = age adjusted weight for hospitalizations, calculated by death per 1M*weights, label, age_group, and covtestdt

/*  OUTPUT PLACED INTO TABLEAU FOR DATA VISUALIZATION */;


/* END OF CODE */;


