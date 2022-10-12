/*******************************************/
/* Snowfall in Anchorage		    	   */
/* 										   */
/* Written by M.Pike, 10/11/22			   */
/* 									       */
/* Outputs: weather.sasbdat7 for Tableau   */
/*******************************************/


/* Import data */;

DATA WORK.weather_anc;
    LENGTH
        Date               8
        'Maximum Temperature (degF)'n   8
        'Precipitation (in)'n   8
        'Mean Temperature (degF)'n   8
        'Minimum Temperature (degF)'n   8
        'Snowfall (in)'n   8
        'Snow Depth (in)'n   8 ;
    FORMAT
        Date             MMDDYY10.
        'Maximum Temperature (degF)'n BEST2.
        'Precipitation (in)'n BEST4.
        'Mean Temperature (degF)'n BEST4.
        'Minimum Temperature (degF)'n BEST3.
        'Snowfall (in)'n BEST4.
        'Snow Depth (in)'n BEST2. ;
    INFORMAT
        Date             MMDDYY10.
        'Maximum Temperature (degF)'n BEST2.
        'Precipitation (in)'n BEST4.
        'Mean Temperature (degF)'n BEST4.
        'Minimum Temperature (degF)'n BEST3.
        'Snowfall (in)'n BEST4.
        'Snow Depth (in)'n BEST2. ;
    INFILE 'C:\Users\Mapike\AppData\Roaming\SAS\EnterpriseGuide\EGTEMP\SEG-5716-1bbd8a92\contents\weather_anc_2011_2021-410f78f6d5ab456d95b39f90d02f1d5d.txt'
        LRECL=33
        ENCODING="WLATIN1"
        TERMSTR=CRLF
        DLM='7F'x
        MISSOVER
        DSD ;
    INPUT
        Date             : ?? MMDDYY10.
        'Maximum Temperature (degF)'n : ?? BEST2.
        'Precipitation (in)'n : ?? COMMA4.
        'Mean Temperature (degF)'n : ?? COMMA4.
        'Minimum Temperature (degF)'n : ?? BEST3.
        'Snowfall (in)'n : ?? COMMA4.
        'Snow Depth (in)'n : ?? BEST2. ;
RUN;

/* Select for days with snowfall > 0 */;

DATA snow;
	set work.weather_anc; 

	if 'Snowfall (in)'n > 0 then output;
RUN;

DATA first_snow;
	set snow;

	if date = '30Oct2011'd or date = '29Sep2012'd or date = '09Nov2013'd or date = '19Oct2014'd or
		date = '29Sep2015'd or date = '20Oct2016'd or date = '21Oct2017'd or date = '29Oct2018'd or
		date = '16Oct2019'd or date ='18Oct2020'd or date = '14Oct2021'd then first_snow = 1;
	else first_snow = 0; 

RUN; 


DATA three_in;
	set work.weather_anc;

	if 'Snowfall (in)'n >= 3 then output;

RUN;

DATA first_sig;
	set three_in;

	if date = '06Nov2011'd or date = '08Dec2012'd or date = '10Nov2013'd or date = '20Oct2014'd or 
		date = '30Oct2015'd or date = '01Dec2016'd or date = '05Nov2017'd or date = '12Dec2018'd or 
		date = '16Nov2019'd or date = '08Nov2020'd or date = '11Nov2021'd then first3inches = 1;
	else first3inches = 0; 
RUN;

PROC SQL;
	create table weather_combo
		
	as select distinct *
	from work.first_snow as p
	left join work.first_sig q on p.date = q.date
;
QUIT; 


DATA weather;
	set weather_combo;
	if first3inches = . then first3inches = 0;
RUN;


/** END OF CODE **/;