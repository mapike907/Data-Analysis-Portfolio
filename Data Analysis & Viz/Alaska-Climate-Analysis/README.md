# Anchorage: First Signficant Snowfall Raffle

**BACKGROUND:** The Nordic Skiing Association of Anchorage (NSAA) is holding a raffle, Anchorage Nordic Snow Classic. The raffle raises money NSAA and provides the association with funding needed to maintain trails for this upcoming season. For the entry, you have to guess when Anchorage will receive it's first significant snowfall of at least 3 inches for the 2022-2023 season. The snowfall is measured at the NOAA headquarters on Sand Lake Rd, Anchorage. Winner will recieve two roundtrip coach airline tickets on AlaskaAir, with a second prize at $1,000 cash, and third prize is a one-hour Pistonbully ride. 
https://anchoragenordicski.com/events/anchorage-nordic-snow-classic/

**Question:** Based upon the past decade of precipitation data, what are the best days or weeks to choose for entering this raffle?

**Methods & Datasets:**
Precipatation and temperature from 8/1/2011 to 12/31/2021, Anchorage, AK. Dataset downloaded from from Alaska Climate Research Center (ACRC) Data Portal on 10/11/2022. 
Variables pulled for analysis: maximum temperature, mean temperature, minimum temperature, snowfall, snow depth, precipitation.
link: https://akclimate.org/data/data-portal/

Datafile in GitHub folder: weather_anc_2011_2021.csv
SAS program produces sas file 'weather' for use in Tableau. 

**DISCUSSION:** Based on histoical data, Anchorage oftens sees it's first snowfall during the second or third week of October. La Niña and El Niño's also impact snowfalls. In September 2022, Climate.gov stated the odds of a La Niña this winter are more than 90 percent [1]. When there is an La Niña, that typically means above-average snowfall. 

<img src="[https://camo.githubusercontent.com/...](https://github.com/mapike907/Images/blob/main/Snowfall2.PNG)" data-canonical-src="[https://gyazo.com/eb5c5741b6a9a16c692170a41a49c858.png](https://github.com/mapike907/Images/blob/main/Snowfall2.PNG)" width="200" height="400" />



**REFERENCES:**
[1] NOAA Climate.gov. "September 2022 La Niña update: it's Q & A time." 8 September 2022. accessed on 11 Oct 2022 at: https://www.climate.gov/news-features/blogs/september-2022-la-ni%C3%B1a-update-it%E2%80%99s-q-time
