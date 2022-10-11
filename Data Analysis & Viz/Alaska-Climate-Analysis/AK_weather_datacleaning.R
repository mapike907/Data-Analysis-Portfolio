##############################################
# Anchorage, Precipitation, Data Cleaning    #
#                                            #
# Written by Melissa Pike, 10/11/22          #
##############################################


# Import data
library(readr)
weather_anc_2011_2021 <- read_csv("weather_anc_2011_2021.csv")
View(weather_anc_2011_2021)

# packages
library(lubridate)
library(tidyverse)


# clean dataset: select only dates with with snowfall. 
snowfall <- 