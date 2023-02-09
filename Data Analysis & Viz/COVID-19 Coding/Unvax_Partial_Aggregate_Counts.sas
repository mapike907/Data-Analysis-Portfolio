
/*****************************************************************************************************/
/** 	CDC Vaccine Breakthrough Surveillance, Sent Monthly to CDC, Aggregate Data Submission		**/
/**															  				   						**/
/** 	Vaccine Breakthrough: Colorado VB data, Unvax & Partial, Cases & Deaths						**/
/**		This is part 1 of 2. Unvax and Partial vax cases and deaths									**/
/**																									**/															   
/** 																								**/
/**		Written by: M. Pike, May 23, 2022															**/
/**		Updated 6/28/22 to include first and second booster dose data								**/
/**		Updated 8/31/22 to remove individuals under 6 mo of age										**/
/**		Updated 10/19/22 to update CDC new deliverable format										**/
/*****************************************************************************************************/

libname newcedrs odbc dsn='CEDRS_3_read' 	schema=CEDRS 	READ_LOCK_TYPE=NOLOCK; /*66 - CEDRS */;
libname covidvax odbc dsn='covid_vaccine' 	schema=tab 		READ_LOCK_TYPE=NOLOCK; /* CDPHESQD03 */;
libname covcase	 odbc dsn='COVID19' 	    schema=cases	READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname covid	 odbc dsn='COVID19' 	    schema=dbo		READ_LOCK_TYPE=NOLOCK; /* 144 - DBO */;
libname covid19	 odbc dsn='COVID19' 		schema=ciis 	READ_LOCK_TYPE=NOLOCK; /* 144 - CIIS */;
libname archive 'O:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive';


/* PART 1: Pull all cases from Cedrs_III_Wearhouse (cedrs_view) */;

PROC SQL;
   CREATE TABLE cases_Cedrs3WH AS 
   SELECT DISTINCT 	eventid, 
       				profileid, 
					age_at_reported,
          			breakthrough,
					breakthrough_booster, 
					vaccine_received,
          			partialonly, 
          			outcome, 
					cophs_admissiondate,
					datevsdeceased,
					deathdueto_vs_u071,
          			deathdate, 
          			earliest_collectiondate,
					vax_booster,
          			vax_utd
      FROM COVID.cedrs_view;
QUIT;
/* N = 1,736,501  */;


DATA cedrs_cleaned;
	set cases_cedrs3WH;

	format test_dt mmddyy10. age_group $15. mmwr_case mmwr_dead 6. ;

	test_dt = input(earliest_collectiondate, yymmdd10.);

	death_date = input(deathdate, yymmdd10.);

	death_year = put(year(death_date), z4.);
	case_year = put(year(test_dt), z4.);

	death_week = put(week(death_date, 'u'), z2.);
	case_week = put(week(test_dt, 'u'), z2.);

	mmwr_case = CATS(case_year,case_week); /*puts it into YYYYWW as per MMWR week CDC format */;
	mmwr_dead = CATS(death_year,death_week);
	
	if age_at_reported >= 0 and age_at_reported <= 4 then age_group = 'Group 1 (0.5-4)';
		else if age_at_reported >= 5 and age_at_reported <= 11 then age_group = 'Group 2 (5-11)';
		else if age_at_reported >=12 and age_at_reported <= 17 then age_group = 'Group 3 (12-17)';
		else if age_at_reported >=18 and age_at_reported <= 29 then age_group = 'Group 4 (18-29)';
		else if age_at_reported >=30 and age_at_reported <= 49 then age_group = 'Group 5 (30-49)';
		else if age_at_reported >=50 and age_at_reported <= 64 then age_group = 'Group 6 (50-64)';
		else if age_at_reported >=65 and age_at_reported <= 79 then age_group = 'Group 7 (65-79)';
		else if age_at_reported >=80 then age_group = 'Group 8 (80+)';

	if earliest_collectiondate = '' then delete;

	if test_dt >= '03OCT2021'd then output; /*as per Concept Notes, Aggregate Data, 10/14/22*/; 

drop death_week case_week death_year case_year;

RUN;
/* N = 1,027,865 */;


/* Pull out kids who are <6 mo old */;
DATA adults;
	set cedrs_cleaned;

	if age_at_reported = 0 then delete;
RUN;
/* N = 1,015,658 */;

DATA kids_1;
	set cedrs_cleaned;

	if age_at_reported = 0 then output;
RUN;
/* N = 12,207 */;

/* Pull Birthdates */;

PROC SQL;
   CREATE TABLE WORK.QUERY_FOR_ZDSI_PROFILES AS 
   SELECT t1.ProfileID, 
          t1.BirthDate
      FROM NEWCEDRS.zDSI_Profiles t1;
QUIT;

/*Combine bithdates to cases */;

PROC SQL;
	create table cases_kids_bday
		
	as select distinct *
	from work.kids_1 as p
	left join WORK.QUERY_FOR_ZDSI_PROFILES q on p.ProfileID = q.ProfileID
;
QUIT; 
/* N = 12,207 */;

DATA kids_cleaned_1;
	set cases_kids_bday;

	format dob mmddyy10. test_dt mmddyy10.;

	dob = input(birthdate, yymmdd10.); 
	test_dt = input(earliest_collectiondate, yymmdd10.);

	days = intck('day',dob,test_dt);
	if days >= 180 then output;

	drop dob days;

RUN;
/* N = 6,280 */;


/* How many children are in the dataset that were under 6-months of age that need to be removed per CDC concept notes? */;
DATA children;
	set cases_kids_bday; 

	format dob mmddyy10. test_dt mmddyy10.;

	dob = input(birthdate, yymmdd10.); 
	test_dt = input(earliest_collectiondate, yymmdd10.);

	days = intck('day',dob,test_dt);

	if days < 180 then under6mo = 'yes';
		else if days >= 180 then under6mo = 'no';

RUN; 

PROC FREQ data=children; table under6mo / nocol nocum nopercent norow; RUN;
PROC FREQ data=children; table breakthrough*under6mo / nocol nocum nopercent norow; RUN;
PROC FREQ data=children; table partialonly*under6mo / nocol nocum nopercent norow; RUN;
PROC FREQ data=children; table breakthrough*partialonly*under6mo / nocol nocum nopercent norow; RUN;
/* Answer: 5,919 children are removed from this dataset for January 2023 due to age <180 days/6 months */;


/* Put Adults and kids back together */;

DATA cases_cleaned; 
	set adults 
		kids_cleaned_1;
RUN;
/* N = 1,034,544*/;

PROC FREQ data=cases_cleaned; tables age_group; RUN;

Data test; set cases_cleaned; if age_group = '' then output; RUN;


/*************************************************/;

/* PART 2: TABLES FOR UNVAX / PARTIAL VAX, create unvaccinated and partially vaccinated persons table from Cases_cedrs3W */;

DATA unvax_partvax;
	set cases_cleaned;
	if breakthrough = 0 then output;
RUN;
/* Unvax_partvax, N =  502,833  */;

PROC FREQ data=unvax_partvax;
	tables partialonly; 
RUN; 
/* Unvaccinated: 464,481 */
/* Partial: 38,352 */;


/**** PARTIALLY VACCINATED ****/;

/*creates a dataset of partially vaccinated persons*/;

DATA Partial;
	set unvax_partvax;
	case = 1;
	if partialonly = 1 then output;
RUN;

/*creates a dataset of partially vaccinated persons from week 52 (202152) and week 0 (1/1/22) for MMWR Week 202152 per CDC guidance*/;
/* Note: mmwr_case = 20220 (cases from 1/1/22 - Saturday) get counted into case_year = 2021 and mmwr_case = 52 as per CDC guidance */;

DATA partial_52_0; 
	set  partial;
	case = 1;
	if mmwr_case = 202152 or mmwr_case = 202200 then output;
RUN;


DATA partial_52; 
	set partial_52_0; 

	mmwr_case = 202152;
	 
RUN;



PROC FREQ data=partial_52_0; table mmwr_case; RUN; 
PROC FREQ data=partial_52; table mmwr_case; RUN; 


DATA Partial_2;
	set partial;

	if mmwr_case = 202200 or mmwr_case = 202152 then delete;
RUN;

PROC FREQ data=partial_2; table mmwr_case; RUN; 

DATA partial_all;
	set partial_2
		partial_52;
	if age_at_reported = . then delete;
RUN;
PROC FREQ data=partial_all; table mmwr_case; RUN;


PROC SORT data=partial_all; by mmwr_case age_group; RUN;


/*CASES: partial vaccinated output tables */;

ods excel file = "O:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive\feb_partial_cases.xlsx";
ods graphics on; 
title 'Partial Vax Cases, MMWR';
proc means data = work.partial_all n nonobs completetypes;
  class mmwr_case / ascending;
  class age_group;
  var case; 
  output out=partial_all2;
run;
ods excel close;


/* DEATHS: partial deaths output tables */;

proc sql ;
create table table_mmwr as 
	select distinct mmwr_case
	from partial_all ; 
quit ;

proc sql ;
create table table_agegroups as 
	select distinct age_group
	from partial_all; 
quit ;

proc sql ;
create table table_deaths as 
	select distinct deathdueto_vs_u071
	from partial_all ; 
quit ;


proc sql ; 
create table combined_rows as 
	select
		 m.*
		,a.*
		,v.*
	from table_mmwr m, table_agegroups a, table_deaths v
	order by mmwr_case, deathdueto_vs_u071, age_group  ; 
quit ;


proc sql ; 
create table final_counts as 
	select
		 r.*
		,case when n is not null then n else 0 end as count
	from combined_rows r
	left join 
		( 	select mmwr_case, age_group, deathdueto_vs_u071, sum(deathdueto_vs_u071) as n /* switch vax_with_booster w/any variable you want to count */
			from partial_all b 
			group by mmwr_case, age_group, deathdueto_vs_u071 
		 ) b
		on  r.mmwr_case = b.mmwr_case
		and r.age_group = b.age_group 
		and r.deathdueto_vs_u071 = b.deathdueto_vs_u071
	order by r.mmwr_case, r.deathdueto_vs_u071, r.age_group  ; 
quit ;


DATA partial_death_output;
	set final_counts;

	if deathdueto_vs_u071 = 1 then output;

	drop deathdueto_vs_u071;
RUN;

ods excel file = "O:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive\feb_partial_death_output.xlsx";
ods graphics on; 
title 'Partial Vax Deaths, MMWR';
PROC PRINT data=partial_death_output; 
RUN;
ods excel close;


/*************************************************/;
/*************************************************/;
/*************************************************/;
/*************************************************/;


/**** UNVACCINATED ****/;

DATA Unvaccinated;
	set unvax_partvax;
	case = 1;
	if partialonly = 0 then output;
RUN; 
 

/*creates a dataset of Unvaccinated persons from week 52 (2021) and week 0 (1/1/22) for MMWR Week 202152 per CDC guidance*/;
/* Note: case_year = 2022 and case_week = 0 (cases from 1/1/22 - Saturday) get counted into case_year = 2021 and 
case_week = 52 as per CDC guidance */;

DATA Unvax_52_0; 
	set Unvaccinated;
	case = 1;
	if mmwr_case = 202152 or mmwr_case = 202200 then output;
RUN;

PROC FREQ data=unvax_52_0; table mmwr_case; RUN; 

DATA unvax_52; 
	set unvax_52_0; 

	mmwr_case = 202152;
	 
RUN;

PROC FREQ data=unvax_52; table mmwr_case; RUN; 

DATA Unvax_2;
	set Unvaccinated;

	if mmwr_case = 202200 or mmwr_case = 202152 then delete;

RUN;

PROC FREQ data=Unvax_2; table mmwr_case; RUN; 


DATA Unvax_all;
	set Unvax_2
		Unvax_52;
	if age_at_reported = . then delete;
RUN;

PROC FREQ data=unvax_all; table mmwr_case; RUN;

PROC SORT data=unvax_all; by mmwr_case age_group; RUN;


/*CASES: Unvaccinated output tables */;

ods excel file = "O:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive\feb_unvax_cases.xlsx";
ods graphics on; 
title 'UnVax Cases, MMWR';
proc means data = work.unvax_all n nonobs completetypes;
  class mmwr_case / ascending;
  class age_group;
  var case;
run;
ods excel close;


/* DEATHS: Unvax deaths output */;

proc sql ;
create table table_mmwr as 
	select distinct mmwr_case
	from unvax_all ; 
quit ;

proc sql ;
create table table_agegroups as 
	select distinct age_group
	from unvax_all; 
quit ;

proc sql ;
create table table_deaths as 
	select distinct deathdueto_vs_u071
	from unvax_all; 
quit ;


proc sql ; 
create table combined_rows as 
	select
		 m.*
		,a.*
		,v.*
	from table_mmwr m, table_agegroups a, table_deaths v
	order by mmwr_case, deathdueto_vs_u071, age_group  ; 
quit ;


proc sql ; 
create table final_counts as 
	select
		 r.*
		,case when n is not null then n else 0 end as count
	from combined_rows r
	left join 
		( 	select mmwr_case, age_group, deathdueto_vs_u071, sum(deathdueto_vs_u071) as n /* switch vax_with_booster w/any variable you want to count */
			from unvax_all b 
			group by mmwr_case, age_group, deathdueto_vs_u071 
		 ) b
		on  r.mmwr_case = b.mmwr_case
		and r.age_group = b.age_group 
		and r.deathdueto_vs_u071 = b.deathdueto_vs_u071
	order by r.mmwr_case, r.deathdueto_vs_u071, r.age_group  ; 
quit ;


DATA unvax_death_output;
	set final_counts;

	if deathdueto_vs_u071 = 1 then output;

	drop deathdueto_vs_u071;
RUN;

ods excel file = "O:\Programs\Other Pathogens or Responses\2019-nCoV\Vaccine Breakthrough\07_Data\archive\feb_unvax_death_output.xlsx";
ods graphics on; 
title 'UnVax Deaths, MMWR';
PROC PRINT data=unvax_death_output; 
RUN;
ods excel close;


/* END OF CODE */;

