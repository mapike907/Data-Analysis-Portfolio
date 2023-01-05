/***********************************************************************/
/******************* COVID-19 Data Dashboard ***************************/
/***********************************************************************/
/***********************************************************************/
/******** LAST UPDATE 01/04/2023 ***************************************/

/***********************************************************************/
/********************* STEP 1: DATASETS ********************************/
/***********************************************************************/

/* TABLE OF CONTENTS*/;

/* OWID, Line 35
/* HHS_Population, Line 180
/* HHS Data, Line 193
/* CDC Data, Line 454
/* NYC Data, Line 532
/* London Data, Line 594
/* UK Data, Line 686
/* Export, Line 1214


/*************************************************************************/
/************* STEP 2: IMPORT DATA AND MANIPULATE ************************/
/*************************************************************************/

/*** OUR WORLD IN DATA ***/;

/***Pull data from CSV off OWID***/

filename owid temp;
proc http
url="https://covid.ourworldindata.org/data/owid-covid-data.csv"
method="GET"
out=owid;
run;

proc import file=owid
out=owiddata
dbms=csv
replace;
run;

DATA owiddata1;
	set owiddata;
	format source $15. location_type $25.; 
	Location_type = 'country';
	Source = 'OWID';
RUN;

/* CLEAN DATA SET: Pull cases, hospitalizations, deaths */;

PROC SQL;
   CREATE TABLE Country_OWID_1 AS 
   SELECT location, 
   		  location_type,
		  source,
          date,
          icu_patients,
		  hosp_patients,
		  new_cases,
		  weekly_hosp_admissions,
		  weekly_icu_admissions,
          new_cases_smoothed as owid_new_cases_7day,
          population as pop_denom
      FROM WORK.OWIDDATA1
      WHERE date >= '1Dec2021'd and location = 'Australia' or location = 'Austria' or location = 'Denmark' 
		or location = 'Italy' or location = 'Netherlands' or location = 'South Africa' or location= 'France' or location= 'Germany'
		or location = 'Israel' or location = 'Singapore' or location = 'Italy' or location = 'South Korea'
		or location = 'United King' or location = 'United Stat' ;
QUIT;

/*create weeks for OWID to match CDC data with weeks starting on Thursday */;

DATA country_OWID_2;
	set country_OWID_1;

	Day_of_week = weekday(date);
	put day_of_week =;
RUN;

DATA country_OWID_3;
	set country_OWID_2;

	format owid_date_wk yymmdd10. section $30.;
	section = 'International';

	length day_of_week2 8 owid_date_wk 8;
		if day_of_week ne 5 then day_of_week2 = .;
	 	else day_of_week2 = day_of_week;

	if day_of_week2 = 5 then owid_date_wk = date;

	if owid_date_wk = . then cases_7day = .;
		else cases_7day = owid_new_cases_7day;

	wkly_hosp_admissions = input(weekly_hosp_admissions, comma9.);

	drop Day_of_week day_of_week2 owid_new_cases_7day weekly_hosp_admissions;
RUN;

proc freq data=Country_OWID_3; tables wkly_hosp_admissions; run;

DATA country_OWID;
	set country_OWID_3;
	format week_date yymmdd10.;
	week_date = owid_date_wk;
	rename cases_7day=owid_new_cases_7day wkly_hosp_admissions = weekly_hosp_admissions;

RUN; 

DATA OWID_Rate;
	set Country_OWID;
		format section $25. category $35.; 

	total_cases_hosp = sum(icu_patients + hosp_patients); /*mid-level missing, lowest, highest*/
	Hosp_admit = sum(weekly_icu_admissions + weekly_hosp_admissions);/*7700, 7691, 4101*/
	
	if location =  'United King' then location = 'UK';
		else if location = 'United Stat' then location = 'USA';	

	daily_hosp_per100k = (total_cases_hosp/pop_denom)*100000; 
	daily_hospadmit_per100k = (hosp_admit/pop_denom)*100000;
    cases_per_100K_7day = (owid_new_cases_7day/pop_denom)*100000; 
	cases_per100k = (new_cases/pop_denom)*100000;
    Hosp_admit_avgper100K = (((Hosp_admit/7)/pop_denom)*100000); 

	section= 'Cases and Hospitalizations';
	category= 'Rates';

RUN;


DATA OWID_Omi;
	set OWID_Rate;

	format omi_wave_dt yymmdd10.;

	/* create Omi_Wave_dt which is the date of the start of the Omicron
		Variant. Dates are those selected by Parker for his Domo Viz */;

	/* In this output, not all states will have a omi_wave_dt */;

	if location = 'London' then Omi_Wave_dt = '01Mar2022'd; 
		else if location = 'UK' then  Omi_Wave_dt = '01Mar2022'd; 
		else if location = 'Denmark' then Omi_Wave_dt ='29Nov2021'd; 
		else if location = 'Netherlands' then Omi_Wave_dt = '03Jan2022'd;
		else if location = 'Germany' then Omi_Wave_dt = '05Jan2022'd;
		else if location = 'Italy' then Omi_Wave_dt = '29Dec2021'd;
		else if location = 'South Korea' then Omi_Wave_dt = '01Feb2022'd;
		else if location = 'France' then Omi_Wave_dt = '19DEC2021'd;

	if total_cases_hosp = . then total_cases_hosp = 0;

RUN;

DATA OWID_Clean; retain location source location_type section category date new_cases new_deaths pop_denom
		week_date daily_hospadmit_per100k daily_hosp_per100k cases_per_100K_7day cases_per100k Hosp_admit_avgper100k
		deaths_per100k omi_daydiff;
	set OWID_Omi; 
	format section $25. category $30.;

	Omi_daydiff = Date - Omi_wave_dt;

	section = 'Cases & Hospitalization';
	category= 'Omicron';
	drop icu_patients hosp_patients omi_wave_dt Hosp_admit owid_date_wk total_cases_hosp weekly_hosp_admissions
	 weekly_icu_admissions;
RUN;

PROC CONTENTS data= OWID_clean; RUN; /* IN FINAL EXPORT FILE */



/***Pull Population Data: From Personal Drive***/

PROC IMPORT datafile="C:\Users\Mapike\Documents\GitHub\Data-Analysis-Portfolio\Dashboards\COVID Dashboard\Pop_Denom.csv"
        out=work.HHS_Populations
        dbms=csv
        replace;
   
     getnames=yes;
	 guessingrows=32767; /*this is needed to pull full lengths of city names */;
RUN;



/******** HHS DATA ********/;

/***HHS TEST DATA***/

filename hhstest temp;
proc http
url="https://healthdata.gov/api/views/j8mb-icvb/rows.csv?accessType=DOWNLOAD"
method= "GET"
out=hhstest;

run;
proc import file=hhstest
out=hhstestdata
dbms=csv
replace;
guessingrows=32767;
run;

DATA hhstestdata2;
	set hhstestdata;
	format source $15. location_type $25. section $35.; 
	Location_type = 'state';
	Source = 'HHS';
	Section = 'Tests';
	if date >= '1Dec2021'd then output;
RUN;

PROC SQL;
create table HHS_case_pop
as select v.*, e.*

	from work.hhstestdata2 v 
	left join HHS_Populations e on v.state_name = e.state_name
	
	order by e.state_name
;
QUIT;

DATA HHS_Case;
	set HHS_case_pop;

	if state in ('AS', 'VI', 'MH', 'FS', 'GU', 'MP', 'PW', 'RM') then delete;
	if overall_outcome = 'Positive' then output; /*There are inconclusive and negative results. Looking for positive cases, so we keep 'Positive'*/;

RUN;

DATA hhstestdata1; 
	set HHS_case;
	format location $25. location_type $25. omi_wave_dt yymmdd10. ;

	cases_per100k = (new_results_reported/pop_denom)*10000;
	location = state_name;

	/* create Omi_Wave_dt which is the date of the start of the Omicron
		Variant. Dates are those selected by Parker for his Domo Viz */;

	/* In this output, not all states will have a omi_wave_dt */;

	if location = 'New Jersey' then Omi_wave_dt = '03Mar2022'd;
		else if location = 'New York' then Omi_wave_dt = '15Mar2022'd;
		else if location = 'Colorado' then Omi_wave_dt = '27Mar2022'd;
		else if location = 'Massachusetts' then Omi_wave_dt = '14Mar2022'd;
		else if location = 'Rhode Island' then Omi_wave_dt = '13Mar2022'd;
		else if location = 'Pennsylvania' then Omi_wave_dt = '18Mar2022'd;
		else if location = 'Connecticut' then Omi_wave_dt = '13Mar2022'd;
		else if location = 'Maine' then Omi_wave_dt = '15Mar2022'd;
		else if location = 'Florida' then Omi_wave_dt = '25Mar2022'd;
		else if location = 'Michigan' then Omi_wave_dt = '14Apr2022'd;
		else if location = 'Illinois' then Omi_wave_dt = '28Mar2022'd;
		else if location = 'Ohio' then Omi_wave_dt = '4Apr2022'd;
		else if location = 'Washington' then Omi_wave_dt = '5Apr2022'd;
		else if location = 'Hawaii' then Omi_wave_dt = '30Mar2022'd;
		else if location = 'Puerto Rico' then Omi_wave_dt = '30Mar2022'd;

	Omi_daydiff = Date - Omi_wave_dt;

	drop state_fips fema_region geocoded_state state overall_outcome state_name city;
RUN;

PROC SORT data=hhs_case; by state date; RUN;

PROC CONTENTS data=hhstestdata1; RUN;


/*** HHS HOSPITAL DATA ***/
filename hhs temp;
proc http
url="https://healthdata.gov/api/views/g62h-syeh/rows.csv?accessType=DOWNLOAD"
method= "GET"
out=hhs;

run;

proc import file=hhs
out=hhsdata
dbms=csv
replace;
guessingrows=32767;
run;

PROC SQL;
   CREATE TABLE hhsdatarename AS 
   SELECT state,
   		  date,
		  previous_day_admission_adult_cov as PrevDayAdultCo,
		  VAR19 as PrevDayAdultSus,
		  previous_day_admission_pediatric as PrevDayPedsCo,
		  VAR23 as PrevDayPedSus,
		  total_adult_patients_hospitalize as AdultConSusHosp,
		  VAR33 as AdultTotalHospCon,
		  total_pediatric_patients_hospita as PedsTotalHospConSus,
		  VAR37 as PedsTotalHospCon
      FROM WORK.hhsdata
      WHERE date >= '1Dec2021'd;
QUIT;

DATA hhsdatahosp1; 
	set hhsdatarename;
	format source $15. location_type $25. section $35.; 
	Location_type = 'state';
	Source = 'HHS';
	Section = 'Cases & Hospitalizations';
	Total_cases_hosp = sum(AdultConSusHosp+PedsTotalHospConSus);
	Total_previous_cases_admit = sum(PrevDayAdultCo+PrevDayAdultSus+PrevDayPedsCo+PrevDayPedSus);
RUN;

PROC SQL;
create table HHS_hosp_pop
as select v.*, e.*

	from work.hhsdatahosp1 v 
	left join HHS_Populations e on v.state = e.state
	
	order by e.state
;
QUIT;

DATA HHS_Hosp_pop2;
	set HHS_Hosp_pop;
	if state in ('AS', 'VI', 'FS', 'GU', 'MP', 'PW', 'RM') then delete;
	drop city;
RUN;

DATA hhsdatahosp2; 
	set HHS_Hosp_pop2; 

	format omi_wave_dt yymmdd10.;

	location = state_name;

	/* create Omi_Wave_dt which is the date of the start of the Omicron
		Variant based upon visual inspection with state trends */;

	/* In this output, not all states will have a omi_wave_dt */;

	if location = 'New Jersey' then Omi_wave_dt = '03Mar2022'd;
		else if location = 'New York' then Omi_wave_dt = '15Mar2022'd;
		else if location = 'Colorado' then Omi_wave_dt = '27Mar2022'd;
		else if location = 'Massachusetts' then Omi_wave_dt = '14Mar2022'd;
		else if location = 'Rhode Island' then Omi_wave_dt = '13Mar2022'd;
		else if location = 'Pennsylvania' then Omi_wave_dt = '18Mar2022'd;
		else if location = 'Connecticut' then Omi_wave_dt = '13Mar2022'd;
		else if location = 'Maine' then Omi_wave_dt = '15Mar2022'd;
		else if location = 'Florida' then Omi_wave_dt = '25Mar2022'd;
		else if location = 'Michigan' then Omi_wave_dt = '14Apr2022'd;
		else if location = 'Illinois' then Omi_wave_dt = '28Mar2022'd;
		else if location = 'Ohio' then Omi_wave_dt = '4Apr2022'd;
		else if location = 'Washington' then Omi_wave_dt = '5Apr2022'd;
		else if location = 'Hawaii' then Omi_wave_dt = '30Mar2022'd;
		else if location = 'Puerto Rico' then Omi_wave_dt = '30Mar2022'd;

	if total_cases_hosp = . then total_cases_hosp = 0;
	drop state_name state; 
RUN;

DATA HHS_Hosp_Rate;  
	set hhsdatahosp2;
	format location $25.;

	daily_hosp_per100k = (total_cases_hosp/pop_denom)*100000; 
	daily_hospadmit_per100k = (total_previous_cases_admit/pop_denom)*100000;
	Omi_daydiff = Date - Omi_wave_dt;
	
	if date >= '1Dec2021'd then output;
	drop  city state PrevDayAdultCo PrevDayAdultSus PrevDayPedsCo
		  PrevDayPedSus AdultConSusHosp AdultTotalHospCon PedsTotalHospCon
		   PedsTotalHospConSus; 
RUN;

PROC SORT data=HHS_Hosp_Rate;
	by location date;
RUN;

/*Using Proc Expand to create a 7-day moving average for Hosp Admissions */;

PROC EXPAND data=HHS_Hosp_rate out=HHS_Hosp_7day method=none;
	id date;
	by location;
	convert Total_previous_cases_admit = HHS_HospAdmit_7day_trailing / transout=(movave 7);
RUN

/* Put into the order needed to merge later, drop first 6 days in 7day_trailing */;
DATA HHS_Hosp_clean_1;
	set HHS_Hosp_7day; 

	if date = '1Dec2021'd then HHS_HospAdmit_7day_trailing = .;
		else if date = '2Dec2021'd then HHS_HospAdmit_7day_trailing = .;
		else if date = '3Dec2021'd then HHS_HospAdmit_7day_trailing = .;
		else if date = '4Dec2021'd then HHS_HospAdmit_7day_trailing = .;
		else if date = '5Dec2021'd then HHS_HospAdmit_7day_trailing = .;
		else if date = '6Dec2021'd then HHS_HospAdmit_7day_trailing = .;

RUN; 

PROC SORT data=HHS_Hosp_clean_1;
	by location date;
RUN;

/*percent change hosptializations by 14 days */;

data HHS_Hosp_clean;  retain location date source location_type section 
			total_cases_hosp  total_previous_cases_admit pop_denom daily_hosp_per100k daily_hospadmit_per100k
		    pctdiff_14day_hosp omi_daydiff;
	set HHS_Hosp_clean_1;

 	lag14_hosp = lag14(total_cases_hosp);
	diff = total_cases_hosp - lag14_hosp ;
	pctdiff_14day_hosp = (diff/lag14_hosp)*100;
	drop diff omi_wave_dt lag14_hosp; 
RUN;

PROC SORT data=HHS_Hosp_clean; by location date ; RUN; 

PROC CONTENTS data=HHS_Hosp_clean; RUN; 


PROC SQL;
create table HHS_combo
as select v.*, e.date, e.location, e.case_per100k

	from work.HHS_Hosp_clean v 
	left join hhstestdata1 e on v.location = e.location and v.date=e.date
	
	order by e.location
;
QUIT;

PROC SORT data=HHS_combo; by location date ; RUN; 


/*Combine all HHS data into one file*/

DATA HHS_Cases_Hosp_clean; /* IN FINAL EXPORT FILE */
	set hhstestdata1
		HHS_Hosp_clean; 
RUN;
PROC FREQ data=hhs_cases_hosp_clean; tables location; RUN;



/****** CDC DATA ******/

/***Pull data using CSV from CDC***/

filename cdc temp;
proc http
url="https://data.cdc.gov/api/views/pwn4-m3yp/rows.csv?accessType=DOWNLOAD"
method= "GET"
out=cdc;
run;
proc import file=cdc
out=cdcdata
dbms=csv
replace;
run;

DATA cdcdata1;
	set cdcdata;
	format source $15. location_type $25. section $30.; 
	Location_type = 'state';
	Source = 'CDC';
	Section = 'CDC Cases and Deaths';
RUN;

DATA cdcdata2;
	set cdcdata1;
	rename start_date = cdc_date_wk;
	drop date_updated end_date;	
RUN;

DATA cdcdata3; 
	set cdcdata2;
	if cdc_date_wk >= '1Dec2021'd then output;
	/*CDC is providing weekly data starting on Thursdays */;
RUN;


PROC SQL;
create table cdc_Pop
as select cd.*, hh.*

	from work.cdcdata3 cd 
	left join HHS_Populations hh on cd.state = hh.state
	
	order by cd.state
;
QUIT;

DATA cdc_pop2;
	set cdc_pop;
	if state in ('AS', 'VI', 'FS', 'GU', 'MP', 'PW', 'RM') then delete;
RUN;

/**CDC CASES/DEATH PER 100K***/
Data CDC_Cases_Death_Clean; /* IN FINAL EXPORT FILE */
set cdc_pop2;
format section $36. category $36. location $25.;
	rename state_name = location;
 
	state_case_rt_wk = (new_cases/pop_denom)*100000;
	state_death_rt_wk = (new_deaths/pop_denom)*100000; 

	section= 'cases';
	category= 'rates';

	
	if cdc_date_wk >= 2021-12-01 then output; 
	drop state tot_cases tot_deaths city end_date date_updated ; /*city is blank, country not present*/ 
RUN;

proc sort data=work.CDC_Cases_Death_Clean;
	by cdc_date_wk;
	run;

PROC FREQ data=CDC_Cases_Death_clean; tables location; RUN;


/***** STATE POSITIVITY BY WEEK USING DATA FROM HHS **********************/
/*************************************************************************/; 

proc sql ;
create table hhs_tests1 as
select
	state_name as location,
	intnx('week',DATE,0,'b') as week_start format=mmddyy10.,
	sum( case when (overall_outcome = 'Positive') then new_results_reported end) as positive_tests,
	sum(new_results_reported) as total_tests,
	source,
	location_type,
	section 

from HHS_Case_pop
group by location, week_start, source, location_type, section;
quit;

data  hhs_tests_positivity;
set hhs_tests1;
	format location $25.;
	state_positivity = ((positive_tests/total_tests)*100);
run;

data hhs_tests_positivity ; /* IN FINAL EXPORT FILE */
	set hhs_tests_positivity ;
	by location ;
	percent_change = state_positivity - lag(state_positivity) ;
		if first.state_name then call missing(percent_change) ;
	if location = 'Northern Mariana Isl' then delete;
RUN;

PROC FREQ data=HHS_tests_positivity; tables location; RUN;


/*************************************************************************/
/********************* COMBINE ALL FILES *********************************/
/*************************************************************************/


Data dashboard_1;
	format location $25. daily_hosp_per100k 10.3 omi_daydiff 10.
		   owid_new_cases_7day 10.3 pctdiff_14day_hosp 10.3 week_end mmddyy10.
		   percent_change 10.3 positive_tests 10. owid_daily_case_rate 10.3
		   positivity 10.3 state_case_rt_wk 10.3 state_death_rt_wk 10.3
		   state_positivity 10.3 total_previous_cases_admit 10.3
		   total_tests 10. weekly_hosp_admissions 10.3 Hosp_admit_avgper100K 10.3
		   cases_per_100K_7day 10.3 cases_per100k 10.3 newCasesBySpecimenDate 10.
		   HHS_HospAdmit_7day_trailing 10.3 daily_hospadmit_per100k 10.3 week_date yymmdd10.;

	informat location $25. daily_hosp_per100k 10.3 omi_daydiff 10.
		   owid_new_cases_7day 10.3 pctdiff_14day_hosp 10.3 week_end mmddyy10.
		   percent_change 10.3 positive_tests 10. owid_daily_case_rate 10.3
		   positivity 10.3 state_case_rt_wk 10.3 state_death_rt_wk 10.3
		   state_positivity 10.3 total_previous_cases_admit 10.3
		   total_tests 10. weekly_hosp_admissions 10.3 Hosp_admit_avgper100K 10.3
		   cases_per_100K_7day 10.3 cases_per100k 10.3 newCasesBySpecimenDate 10.
		   HHS_HospAdmit_7day_trailing 10.3 daily_hospadmit_per100k 10.3 week_date yymmdd10.;
	length location $25.;

	set work.OWID_CLEAN /*OWID data */
		work.HHS_CASES_HOSP_CLEAN /*all HHS DATA*/
		work.CDC_CASES_DEATH_CLEAN /*all CDC DATA*/
		work.hhs_tests_positivity /*positivity data */;

	if section = 'Cases &' then section = 'Cases & Hospitalizations';
	if section = 'Cases & Hospitalization' then section = 'Cases & Hospitalizations';
RUN; 


PROC FREQ data= work.dashboard_1; tables section; RUN;

PROC SQL;
   CREATE TABLE WORK.DASHBOARD AS 
   SELECT t1.source, 
          t1.section, 
          t1.category, 
          t1.location, 
          t1.location_type, 
          t1.cdc_date_wk,
		  t1.week_date, 
		  t1.date, 
          t1.pop_denom,
          t1.new_cases, 
		  t1.owid_daily_case_rate,
		  t1.cases_per100k,
          t1.new_deaths, 
          t1.new_historic_cases, 
          t1.new_historic_deaths, 
          t1.state_case_rt_wk, 
          t1.state_death_rt_wk, 
          t1.total_cases_hosp, 
          t1.daily_hosp_per100k,
		  t1.daily_hospadmit_per100k,
		  t1.hosp_admit_avgper100k,
		  t1.pctdiff_14day_hosp, 
          t1.omi_wave_dt, 
          t1.omi_daydiff, 
          t1.total_previous_cases_admit, 
		  t1.HHS_HospAdmit_7day_trailing,
          t1.weekly_hosp_admissions, 
          t1.owid_new_cases_7day,
		  t1.cases_per_100K_7day, 
          t1.week_start, 
          t1.week_end, 
          t1.positivity, 
          t1.percent_change, 
          t1.positive_tests, 
          t1.total_tests, 
          t1.state_positivity
      FROM WORK.DASHBOARD_1 t1;
QUIT;

PROC FREQ data=dashboard; tables section; RUN;

PROC CONTENTS data=dashboard; RUN;

/* Export: These are what's needed for Tableau */;
ODS CSV file="C:\Users\Mapike\Documents\GitHub\Data-Analysis-Portfolio\Dashboards\COVID Dashboard\dashboard.csv";
proc print data= dashboard;
run;
ODS CSV close;

/*******************END CODE****************************************************************************************/
