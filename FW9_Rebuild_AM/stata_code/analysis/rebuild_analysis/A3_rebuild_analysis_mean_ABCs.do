/*****************************************************/
/*
This is a piece of code that matches predicted prices 

 the mean ABC's from the FW9 doc to deal with the variation caused in the "specify a fishing mortality rate (F) that "on average" among stochastic realizations will produce the desired ABC" process

 An equation from prices comes from 

/$analysis_code/annual_price_regression.do

and is copied in below

Ultimately, much of this is not used for the FW9 Analysis.


*/
/*****************************************************/



/**/


version 16.1
clear
set scheme s2mono
*global vintage_string 2021_08_26
local data_in "${data_raw}/herring_mean_ABCs.csv"


/* get the equation for the linear fit 

ivregress 2sls pricemt_realGDP (landings=l1.landings), first;


-----------------------

                                                Number of obs     =         17
                                                F(   1,     15)   =      29.57
                                                Prob > F          =     0.0001
                                                R-squared         =     0.6635
                                                Adj R-squared     =     0.6410
                                                Root MSE          =    16.7516

------------------------------------------------------------------------------
    landings |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
    landings |
         L1. |   .9654579   .1775325     5.44   0.000     .5870563     1.34386
             |
       _cons |  -2.511697   14.17393    -0.18   0.862    -32.72271    27.69932
------------------------------------------------------------------------------


Instrumental variables (2SLS) regression          Number of obs   =         17
                                                  Wald chi2(1)    =      88.00
                                                  Prob > chi2     =     0.0000
                                                  R-squared       =     0.8607
                                                  Root MSE        =     57.234

------------------------------------------------------------------------------
pricemt_re~P |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
    landings |  -5.893482    .628265    -9.38   0.000    -7.124858   -4.662105
       _cons |   815.0201    46.9175    17.37   0.000     723.0635    906.9767
------------------------------------------------------------------------------



*/
import delimited `data_in' 
/*drop 2020 rows, which have some funky non-numerics.*/
keep if year>=2021

global cons 815.0201
global beta_land -5.893482

drop rebuild_year
destring abc ofl, replace

rename abc ABC

replace shortname="ABC CR AVG" if strmatch(shortname, "ABC CR")
replace shortname="Constant F AVG" if strmatch(shortname, "Constant F")

pause



/*****************************************************/
/* construct the modified ABC (landings).  Cap landings at 124,100mt, which is the maximum historical */
/*****************************************************/
gen mABC=ABC
replace mABC=124100 if mABC>=124100
gen price=$cons + mABC/1000*$beta_land
gen revenue=mABC*price


/*construct a yearly variable that denotes years since 2021*/
gen running_yr=year-2021



/* discount at 3% and 7% */
gen discount_factor3=1/((1+.03)^running_yr)
gen discount_factor7=1/((1+.07)^running_yr)



gen d3_rev=discount_factor3*revenue
gen d7_rev=discount_factor7*revenue


save "${data_main}/mean_revenue_trajectory_${vintage_string}.dta", replace
/* you might want to plot mean revenue for each shortname over time.*/

drop if shortname==""

collapse (mean) mean_revenue =revenue mean_ABC=ABC mean_mABC=mABC , by(year shortname)
encode shortname, gen(mys)
tsset mys year
save "${data_main}/mean_revenue_yearly_stats_${vintage_string}.dta", replace










