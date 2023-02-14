# Anchorage: First Signficant Snowfall Raffle

**BACKGROUND:** The Nordic Skiing Association of Anchorage (NSAA) is holding a raffle, Anchorage Nordic Snow Classic. The raffle raises money NSAA and provides the association with funding needed to maintain trails for this upcoming season. For the entry, you have to guess when Anchorage will receive it's first significant snowfall of at least 3 inches for the 2022-2023 season. The snowfall is measured at the NOAA headquarters on Sand Lake Rd, Anchorage. Winner will recieve two roundtrip coach airline tickets on AlaskaAir, with a second prize at $1,000 cash, and third prize is a one-hour Pistonbully ride. 
https://anchoragenordicski.com/events/anchorage-nordic-snow-classic/

**Question:** Based upon the past decade of precipitation data, what are the best days or weeks to choose for entering this raffle?

**Methods & Datasets:**
Precipitation and temperature from 8/1/2011 to 12/31/2021, Anchorage, AK. Dataset downloaded from from Alaska Climate Research Center (ACRC) Data Portal on 10/11/2022. 
Variables pulled for analysis: maximum temperature, mean temperature, minimum temperature, snowfall, snow depth, precipitation.
link: https://akclimate.org/data/data-portal/

Datafile in GitHub folder: weather_anc_2011_2021.csv
SAS program produces sas file 'weather' for use in Tableau. 

**DISCUSSION:** Based on histoical data, Anchorage oftens sees it's first snowfall during the second or third week of October.
Between October 2011 and October 2021, eight out of eleven years saw a first snow between October 14 to October 30, which are roughly the third and fourth weeks of the month. This is roughly a week later than the hisorical data. None of the first snowfalls were also significant (greater than 3 inches).  Significant snowfalls of greater than 3 inches occurred in November six out of 11 years, in December and October at three and two out of last 11 years, respectively.

<img src="https://github.com/mapike907/Images/blob/main/Snowfall2.PNG" width="800" height="400" />

Putting the months & days into order gives us a different view without evaluating year:

<img src="https://github.com/mapike907/Images/blob/main/snow1.PNG" width="500" height="400" />

Based on this limited set of data, if you were making a prediction for this raffle, you would probably want to choose somewhere between late October and into the first week of November. Given that today is October 11, and, as of today, we have a forecast to October 18th that has no snow, with highs and lows above freezing, one would probably want to guess a later date than October 20th. Additional analysis could increase the sample size and evaulate more than 10 years of data in order to make a more informed raffle entry.

Data analyst will update this post with the snowfall date, once it occurs.

UPDATE 10/27/2022: THERE IS A WINNER!

<img src="https://github.com/mapike907/Images/blob/main/Capture.JPG?raw=true" width="375" height="650" />

**WHAT WAS LEARNED:** 
The first snow was recorded after October 20, as predicted above. Data analysis should have examined first snowfall by decade, providing more data points and potentially providing a more informed model/prediction. Overall, this was a fun project to learn more skills in R and further develop analytical skills. 

