# Data for VB Variant Project ----
# Variants and VB status
# Inputs: CIIS vaccinations; CEDRS cases; zDSI_Profiles
# Output: CSV with EventID, FirstName, LastName, DOB, 
#         Collectiondate, and VB status
# written 2/13/2023 by M.Pike

#Connect to packages 
library(DBI)
library(odbc)
library(dbplyr)
library(dplyr)
library(stringr)
library(magrittr)
library(lubridate)

# connect to server 144
DPHE144 <- dbConnect(odbc::odbc(), "COVID19", timeout = 10)


# create immunization table, selecting only those with CIIS data 
# this is what you see in the underlying code of 144 
iz <- tbl(DPHE144, in_schema('ciis','case_iz')) %>% # from
  filter(source == 'CIIS') %>% # where
  select(profileid,eventid,vaccination_date,vaccination_code_id) %>% 
  distinct() %>% 
  collect()

for_breakthrough_fn <- iz %>% 
  select(-profileid)

# codes <- for_breakthrough_fn %>% 
#   select(vaccination_code) %>% 
#   distinct()

pfizer <- # codes %>% filter(str_detect(vaccination_code, "PFR") & str_detect(vaccination_code, "MONO")) %>% pull() # 208, 217, 218, 219
  c(208,217,218,219)
moderna <- # codes %>% filter(str_detect(vaccination_code, "MOD") & str_detect(vaccination_code, "MONO")) %>% pull() # 207, 221, 228
  c(207,221,228)
janssen <- # codes %>% filter(str_detect(vaccination_code, "JSN")) %>% pull() # 212
  c(212)
novavax <- # codes %>% filter(str_detect(vaccination_code, "NVX") & str_detect(vaccination_code, "MONO")) %>% pull() # 211
  c(211)
# astrazeneca <- codes %>% filter(str_detect(vaccination_code, "ASZ")) %>% pull() # 210
# cansino <- codes %>% filter(str_detect(vaccination_code, "CanSino")) %>% pull() # 506


#### GAME PLAN ####


# First we need to recreate the variables that Severson has built into covid19_cedrs_dashboard_constrained;
# starting with the dates we'll eventually use to compare their dose to their collection date
# we should end up with firstdose, fullyvaxxed_date, monovalent_booster, and let's  make a new one called bivalent_booster
# 1. Create dates for firstdose, utd (up to date), booster, and bivalentbooster
# 2. Create time intervals between ^ and collectiondate
# 3. Use case_when logic to determine categorization of:
#     a. Case Def in Slide 10 [would have total CO case count]
#       i. Case vaccinated with primary series only
#      ii. Case vaccinated with primary series and one or more additional doses
#           iia. Case vaccinated with monovalent booster
#           iib. Case vaccinated with bivalent booster
#     iii. Partially vaccinated case
#      iv. Unvaccinated
# When the cdc analysis is due - the above table would be pulled and subset for 
# the categories they desire

# create a first dose table 
firstdose <- for_breakthrough_fn %>% 
  arrange(eventid, vaccination_date) %>% 
  distinct(eventid, .keep_all = T) %>% 
  rename(first_date = vaccination_date, 
         first_code = vaccination_code_id) 

# split first dose table into separate manufacturers based upon JnJ (1 dose)
# and mRNA (2 dose)

jandj <- firstdose %>% 
  filter(first_code %in% janssen)

mrna_firstdose <- firstdose %>% 
  filter(!eventid %in% jandj$eventid, 
         first_code %in% c('213', moderna, pfizer, novavax)) 

mrna_seconddose <- mrna_firstdose %>% 
  left_join(for_breakthrough_fn) %>% 
  filter(vaccination_date > first_date) %>% 
  arrange(eventid, vaccination_date) %>% 
  distinct(eventid, .keep_all = T) %>% 
  rename(second_date = vaccination_date) %>% 
  select(eventid, second_date)

mrna <- mrna_firstdose %>% 
  mutate(vaccine_received = case_when(
    first_code %in% pfizer ~ "Pfizer", 
    first_code %in% moderna ~ "Moderna", 
    first_code == novavax ~ "Novavax", 
    first_code == "213" ~ "Unspecified"
  )) %>% 
  left_join(mrna_seconddose) %>% 
  select(eventid, vaccine_received, first_date, second_date) %>% 
  rename(partial = first_date, 
         utd = second_date)

# primary series 
series <- jandj %>% 
  rename(partial = first_date) %>% 
  mutate(utd = partial, 
         vaccine_received = "Janssen") %>% 
  select(eventid, vaccine_received, partial, utd) %>% 
  bind_rows(mrna)

booster <- series %>% 
  filter(!is.na(utd)) %>% 
  left_join(for_breakthrough_fn %>% 
              filter(vaccination_date >= ymd("2021-08-13"))) %>% 
  filter(vaccination_date > utd) %>% 
  arrange(eventid, vaccination_date) %>% 
  distinct(eventid, .keep_all = T) %>% 
  select(eventid, vaccination_date) %>% 
  rename(booster = vaccination_date)

# bivalent
# 229, 230, 300, 301 or 302 on or after Sept 1, 2022
bivalent <- 
  c(229,230,300,301,302)

bivalent <- for_breakthrough_fn %>% 
  filter(vaccination_code_id %in% bivalent & vaccination_date >= ymd("2022-09-01")) %>% 
  arrange(eventid,vaccination_date) %>% 
  distinct(eventid,.keep_all = T) %>% 
  select(eventid,vaccination_date) %>% 
  rename(bivalent = vaccination_date)

# pull everyone with primary series, one booster, or bivalent
for_breakthrough_fn2 <- for_breakthrough_fn %>% 
  select(eventid) %>% 
  distinct() %>% 
  left_join(series) %>% 
  left_join(booster) %>% 
  left_join(bivalent)

# load in case data
cases <- tbl(DPHE144, in_schema('dbo','cedrs_view')) %>% 
  select(profileid,eventid,reporteddate,collectiondate) %>% 
  collect()

# part of covid_update/R/update/02-covid19_cedrs_dashboard_constrained.R
c2 <- cases %>% 
  left_join(for_breakthrough_fn2) %>% 
  mutate(days_full = interval(utd, collectiondate) / days(1), 
         days_after1st = interval(partial, collectiondate) / days(1),
         days_afterbooster = interval(booster, collectiondate) / days(1), 
         days_final_to_booster = interval(utd, booster) / days(1),
         days_to_bivalent = interval(bivalent,collectiondate) / days(1)) %>% 
  mutate(
  breakthrough = days_full >= 14,
  vax = case_when(
    !is.na(days_to_bivalent) & days_to_bivalent >=14 ~ "bivalent",
    !is.na(days_afterbooster) & days_afterbooster >=14 ~ "monovalent",
    !is.na(days_full) & days_full >= 14 ~ "primary_series",
    !is.na(days_full) & !is.na(days_after1st) & days_full < 14 & days_after1st >= 0 ~ "partial", 
    is.na(days_full) & !is.na(days_after1st) & days_after1st >= 0 ~ "partial", 
    is.na(days_after1st) ~ "unvax", 
    is.na(days_full) & !is.na(days_after1st) & days_after1st < 0 ~ "unvax", # tested positive b4 first dose 
    !is.na(days_full) & days_full < 0 & !is.na(days_after1st) & days_after1st < 0 ~ "unvax" # tested positive b4 first  & Second dose
  )
)  %>% 
  select(profileid,eventid,vaccine_received,partial,utd,booster,bivalent,vax) %>%
  distinct()

# get names and birth dates
profiles1 <- tbl(DPHE144, in_schema('cases','covid19_cedrs')) %>% 
  select(eventid,firstname,lastname,birthdate,collectiondate) %>% 
  collect()

#pull only the variables you need from c2
c3 <- c2 %>%
  select(eventid, vax)

#left join to table c2 on eventid
Dataset <- left_join (c3,profiles1, by = "eventid")
Dataset <- Dataset %>% distinct(eventid, .keep_all = T)


Dataset <- Dataset %>% 
  filter(!is.na(collectiondate)) %>% 
  mutate(breakthrough_booster = case_when(
    vax == 'unvax' ~ 'Unvaccinated',
    vax == 'partial' ~ 'Partially Vaccinated',
    vax == 'primary_series'  ~ 'Vaccinated with primary series, no booster',
    vax == 'monovalent' ~ 'Vaccinated with monovalent booster',
    vax == 'bivalent' ~ 'Vaccinated with bivalent booster'
  )) %>% 
  filter(breakthrough_booster != 'Partially Vaccinated')   # exclude partially vaccinated

 
write.csv(Dataset, "C:\\Users\\Mapike\\Documents\\Dataset.csv", row.names=TRUE)

# END OF CODE #