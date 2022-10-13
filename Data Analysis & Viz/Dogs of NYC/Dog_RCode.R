#################################
#  Dogs in NYC                  #
#                               #
#  Inputs: Dogs of NYC          #
#                               #
#  Output: Demographic Analysis #
#                               #
#  Written by: M Pike 10/12/22  #
#################################

# Questions? What the most popular dog breed and dog names among NYC residents 
# who purchased a dog license during the pandemic, March 2020 to March 2021?
# What was the average age of dogs registered?

# create libraries
library(dplyr)
library(readr)
library(lubridate)
library(tidyverse)
library(arsenal)
library(ggplot2)

# import the dataset
dogs <- read_csv("NYC_Dog_Licensing_Dataset.csv")

# select variables & timeframe needed
keeps <- c("AnimalName","AnimalGender", "BreedName", "AnimalBirthYear",
           "LicenseIssuedDate")
df = dogs[keeps]

# transform LicenseIssuedDate from char to date
df <- df %>% mutate(LicenseIssuedDate = as.Date(LicenseIssuedDate, 
                                                format = "%d/%m/%Y")) 

# select date range
df %>% filter(between(LicenseIssuedDate, as.Date('2020-03-01'), 
                      as.Date('2021-03-01')))

# select variables to retain; drop LicenseIssuedDate
keeps2 <- c("AnimalName","AnimalGender", "BreedName", "AnimalBirthYear")
df2 = df[keeps2]

# calculate age in years of animal
# create variable year, which is the endpoint (2021)
year = c(2021)

# create new data table with variables from df2 and new variable, year.
df3 <- data.frame(df2, year)

# create variable ageyears to find out age of dog in 2021
df3$ageyears <- df3$year - df3$AnimalBirthYear 

#Q: what are the ages of the dogs in the dataset?
min(df3$ageyears) 
max(df3$ageyears)

# This dataset shows that the min = 0 and the max = 29. The average age for 
# dogs is 10-13 years, so AnimalBirthYear is likely an incorrect data entry for 
# any dog older than 22 years.

# Create a barchart of the distribution of ages to visually check dataset. 
barplot(table(df3$ageyears)) 

# For this analysis, we will exclude all dogs where ageyears > 22 through filtering.
df4 <- df3  %>%
  filter(!(ageyears>22))

barplot(table(df4$ageyears)) 

mean(df4$ageyears)
# The mean age for dogs registered with NYC was 7.8 years. 


# Q: What are the 10 most popular names for dog licenses in NYC between March 2020 
# and March 2021?
df_names <- df4 %>% group_by(AnimalName) %>% dplyr::summarise(count = n())

# remove "unknown' and 'name not provided' from AnimalName. We only want those
# with names for this analysis. 
df_names %>% 
  group_by(AnimalName) %>% count()

df_names <- df_names %>% dplyr::filter(AnimalName !='UNKNOWN' & AnimalName !='NAME NOT PROVIDED')

# order in descending counts
df_names %>%
  arrange(desc(count)) %>%
  head(10) %>%
  ggplot(aes(x=reorder(AnimalName,desc(count)), y=count)) + geom_col() + labs(x = 'Name')


barplot(counts, main="Animal Names",
        xlab="Names")


df_names_sort3 <- df_names %>%                 # Order table with dplyr
  as.data.frame() %>% 
  arrange(desc(AnimalName))
df_names_sort3                               # Print ordered table as data frame


names(which.max(table(df2$AnimalName)))

# look at summary, utilizing package gmodels
counts <- table(df2$BreedName)
barplot(counts, main="BreedName",
        xlab="Breeds")


summary(dogs.ex, title = "Summary of ")
df %>%
  mutate(x = c("", "NewVariable"[(date >= "2020-03-01" & 
                                    as.character(infection) == "infectionvariableyouwant"] )
                                 
                                 
                                 
                                 
dat$rate <- ((viz$count.y/viz$count.x)*100)