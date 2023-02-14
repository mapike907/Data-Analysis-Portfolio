# COVID-19 DASHBOARD
Dashboard of COVID-19 Cases, Hospitalizations and Deaths. 

This was part of a project to create data visualiazation with my team at Colorado DPHE. This code has been condensed and only uses aggregate data that is provided by state and/or federal/national data that was used to evaluate COVID-19 trends. 
Other co-authors of this project include: Alexis Bell and Ivy Oyegun. This project created 25 different data visualizations and was created in less than 6-weeks from start to finish. Finalization of the dashboard was done by all team members, with additional help from Nick Stark. Thanks, team! This was such a fun and challening project. 

The end product was an internal dashboard, and this is a snippet of the final larger dashboard. These data visualizations are snapshots of what was created and are NOT CURRENT or updated. 

Here are a select few of the many visualizations that I made for this project.  

<img src="https://github.com/mapike907/Images/blob/main/Dashboard_1.JPG" width="650" height="500" />

<img src="https://github.com/mapike907/Images/blob/main/Dashboard_2.JPG" width="650" height="500" />

<img src="https://github.com/mapike907/Images/blob/main/Dashboard_3.JPG" width="650" height="500" />

<img src="https://github.com/mapike907/Images/blob/main/Dashboard_4.JPG" width="650" height="500" />

These images were created as a team effort, as they required more manipulation in Tableau. 

<img src="https://github.com/mapike907/Images/blob/main/Dashboard_5.JPG" width="650" height="500" />

<img src="https://github.com/mapike907/Images/blob/main/Dashboard_6.JPG" width="750" height="500" />

# Data Sources:

Our World In Data: https://github.com/owid/covid-19-data/tree/master/public/data

CDC: https://data.cdc.gov/Case-Surveillance/Weekly-United-States-COVID-19-Cases-and-Deaths-by-/pwn4-m3yp

## Data Dictionary for dashboard.csv output from this code:

| Variable Name  | Data Type | Description | Origin | Tableau Data Viz Section |
| -- | -- | -- | -- | -- |
| cases_per100k | numerical | This is a daily rate. ; HHS: (new_results_reported/pop_denom)x100000; NYCDATA: (case_count/pop_denom)x100000; OWID: (new_cases/pop_denom)X100000; LONDON: (newCasesBySpecimenDate/pop_denom)x100000 | HHS, NYC; London; OWID | Cases & Hospitalization; Case Rates; Omicron |
| cases_per_100K_7day | numerical | Average cases over 7-days; Calculated by (owid_new_cases_7day/pop_denom) x100000; (case_count_7day_avg/pop_denom)x100000; | Created; OWID; NYC Data | Cases & Hospitalization; Case Rates |
| category | character  | what type of data it will be used for: Omicron, Rates, | Created | |
| cdc_date_wk | date | CDC, date of the week, for weekly case and death rates, state   | CDC | Cases & Hospitalization; Case Rates  |
| daily_hospadmit_per100k | numerical | (hosp_admit/pop_denom)x100000; Daily Hosp Admission Rate | Created, OWID, London, NYC | Cases & Hospitalization; Cases - Omicron (wave) |
| daily_hosp_per100k | numerical | =(total_cases_hosp/pop_denom)x100000 ; Daily hosp rate. | Created; CO CDPHE, HHS, NYC, London, OWID, UK data | Cases & Hospitalization; Hosp Rates (daily) |
| hosp_admit_avgper100k | numerical | Average 7-day Hosp per 100K; Hosp_admit = sum(weekly_icu_admisions + weekly_hosp_admissions); Hosp_admit_avgper100K = (((Hosp_admit/7)/pop_denom)x100000); | Created; OWID | Hospitalizations |
| Date | date  | Date of reported cases; date of hospitalization; date of death  | All Imports | |
| Location | character  | The name of the city, state, or country.  | Created | |
| Location_type | character  | City, State, State/County, Region, or Country.  | Created | |
| new_cases | numerical  | Number of new cases (7-day sum) | CDC | |
| new_deaths | numerical  | Number of new deaths (7-day sum) | CDC | |
| new_historic_cases | numerical  | Number of new historic cases (7-day sum) | CDC | |
| new_historic_deaths | numerical  | Number of new historic deaths (7-day sum) | CDC | |
| omi_daydiff | numerical  | omi_daydiff = date - Omi_Wave_dt . These numbers will be positive and negative around the Omicron start date set up for each location.  | Created | Cases & Hospitalization; Cases - Omicron (wave)  |
| omi_Wave_dt | date | Dates acquired from Vanadata's Viz chosen by date of the bottom of the Omicron start wave  | Created | Cases & Hospitalization; Cases - Omicron (wave) |
| owid_daily_case_rate | numerical | (new_cases/pop_denom)x100000 | OWID | Cases & Hospitalization |
| owid_new_cases_7day | numerical  | variable rename; originally new_cases_smoothed. New confirmed cases of COVID-19 (7-day smoothed). Counts can include probable cases, where reported. | OWID | Cases & Hospitalization; Case Rates |
| pctdiff_14day_hosp  | numerical | 14-day percent difference in total cases hospitalized. Created by creating a lag14_hosp = lag14(total_cases_hosp); diff = total_cases_hosp - lag14_hosp; pctdiff_14day_hosp = (diff/lag14_hosp)x100.  | Created, HHS | Cases & Hosptializations; Rates|
| percent_change | numerical  | used for case and state positivity analysis;  percent_change = ((positivity - lag(positivity))/lag(positivity))*100 | Created, CDPHE, HHS | Tests / Positivity|
| positivity | numerical | From CDPHE 144. count(case when (covid19negative = "N") then 1 end)/count(asterisk))x100 as positivity  | created, CDPHE 144, HHS | Tests / Positivity |
| pop_denom | numerical  | denominator population (city, state, country, Colorado county)  | Imported from HHS_Populations.csv | |
| section | character  | where the data will go in the data viz final product: Cases & Hospitlization, Tests   | Created | |
| source | character  | Where the data originated from. Examples: CDC, CDPHE, Our World in Data (OWID), HHS, etc.  | Created | |
| state_case_rt_wk | numerical  | Weekly case rate rate, state. (tot_cases/pop_denom)x100000  | Created, CDC | Cases & Hospitalizations, Rates |
| state_death_rt_wk | numerical  | Weekly death rate rate, state. (tot_deaths/pop_denom)x100000  | Created, CDC | Cases & Hospitalizations, Rates |
| total_cases_hosp | numerical  | HHS: Total_cases_hosp = sum(AdultConSusHosp+PedsTotalHospConSus); From OWID: total_cases_hosp = sum(icu_patients + hosp_patients); From CDPHE: total_cases_hosp = sum(hospitalized_cophs); NYC Data: hospitalized_count; UK & London Data: hospitalCases | HHS, OWID, CDPHE, NYC, London | |
| total_previous_cases_admit | numerical | = sum(PrevDayAdultCo+PrevDayAdultSus+ PrevDayPedsCo+PrevDayPedSus) | HHS | |
| total_tests| numerical | From OWID: total_cases_hosp = sum(icu_patients + hosp_patients); From CDPHE: total_cases_hosp = sum(hospitalized_cophs)| HHS, OWID, CDPHE, NYC, London, | Tests / Positivity |
| week_date | date | starting day of week. Required for Hosp_admit_avgper100k. | HHS; OWID; Created from CollectionDate from CDPHE; Created from date from HHS | Cases & Hosptializations; Rates; Tests / Positivity |
| weekly_hosp_admissions | number | Number of COVID-19 patients newly admitted to hospitals in a given week (reporting date and the preceeding 6 days) | OWID | |


Variables located in each Data Source:
| Data Source  | Location Type | Variables | Tableau Section/Category |  Notes | 
| -- | -- | -- | -- | -- |
| CDC | state | cdc_date_wk, new_cases, new_deaths, new_historic_cases, new_historic_deaths, source, location_type, section, location, pop_denom, category, state_case_rt_wk, state_death_rt_wk | Cases / Rates (weekly) | cdc_date_wk is a weekly variable | 
| HHS | state | source, location_type, section, location, pop_denom, date, total_cases_hosp, pctdiff_14day_hosp, positivity, percent change, daily_hosp_per100K, omi_wave_dt, omi_daydiff, total_previous_cases_admit |  Hospitalization (Rates (daily)) /  Omicron |  dates are daily; Omicron Wave Viz | 
| OWID | country | source, location_type, section, location, pop_denom, date, total_cases_hosp, weekly_hosp_admissions, owid_date_wk, owid_new_cases_7day, owid_daily_case_rates | Cases / Hospitalization /  Omicron |  International; dates are weekly; Omicron Wave Viz | 
omi_daydiff |  Hospitalization (Rates (daily)) /  Omicron Data Viz | daily hosp rates / Omicron Wave Viz | 
| UK NHS | Country, UK | source, location_type, section, location, category, date, total_cases_hosp, daily_hosp_per100k |  |locations include England, Wales, N Ireland and Scotland |
| HHS | state | source, location_type, section, location, week_date, positivity, percent_change| Tests / Positivity |  dates are weekly; State Positivity |
 
