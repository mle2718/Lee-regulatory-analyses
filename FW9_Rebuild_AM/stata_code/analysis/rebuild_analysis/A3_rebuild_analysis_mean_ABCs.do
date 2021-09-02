/* use the mean ABC's from the FW9 doc to deal with the variation caused in the "specify a fishing mortality rate (F) that "on average" among stochastic realizations will produce the desired ABC" process*/


version 16.1
clear
set scheme s2color
*global vintage_string 2021_08_26
local data_in "${data_raw}/herring_mean_ABCs.csv"


/* get the equation for the linear fit 
> reg pricemt_realGDP landings ;

      Source |       SS           df       MS      Number of obs   =        18
-------------+----------------------------------   F(1, 16)        =    114.90
       Model |  376930.924         1  376930.924   Prob > F        =    0.0000
    Residual |  52488.3832        16  3280.52395   R-squared       =    0.8778
-------------+----------------------------------   Adj R-squared   =    0.8701
       Total |  429419.307        17  25259.9593   Root MSE        =    57.276

------------------------------------------------------------------------------
pricemt_re~P |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
    landings |  -5.356439   .4997087   -10.72   0.000    -6.415774   -4.297104
       _cons |   774.5517   38.78819    19.97   0.000     692.3244     856.779
------------------------------------------------------------------------------





. ivregress 2sls pricemt_realGDP (landings=l1.landings), first;


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

global cons 815.0201
global beta_land -5.893482
keep if year>=2021
gen running_yr=year-2021

drop rebuild_year
destring abc ofl, replace

rename abc ABC



pause


gen mABC=ABC
replace mABC=124100 if mABC>=124100
gen price=$cons + mABC/1000*$beta_land
gen revenue=mABC*price
/* Previously showing all, now we'll show starting at 2021, for consistency with the rest of the doc
gen running_yr=year-2020
*/




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










