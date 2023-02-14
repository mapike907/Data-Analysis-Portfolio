# COVID-19 Coding

These are associated codes that were used to analyze vaccine breakthrough among various vaccination statuses and creating data visualizations for cases, hospitalizations, and deaths, incluing rates and age adjusted rates.

| File Name | Program Language | Description |
| ------------- | ------------- | ------------- |
| Unvax_Partial_Aggregate_Counts.sas | SAS | This creates a count by CDC MMWR Week for Unvaccinated and Partially Vaccinated COVID-19 cases |
| VB Bivalent Categories_R Code.R | R | This creates a CSV with EventID, First_Name, Last_Name, DOB, CollectionDate, and Vaccination_status depending on what vaccination you have received: Unvax, Vaccinated without a bivalent booster, Vaccinated with a bivalent booster. This code does not contain any PII and requires access to databases to pull PII. |
| VB_Mono_Bivalent_Age_Adjustment.sas | SAS | Creates a CSV with cases, hospitalzations, and deaths, by age group; age adjusted using population data. |
