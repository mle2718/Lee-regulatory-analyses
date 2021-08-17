version 16.1
clear
set scheme s2color
global vintage_string 2021_08_16
local data_in "${data_main}/ABCs_${vintage_string}.dta"



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

global cons 815.0201
global beta_land -5.893482

use `data_in', replace

/* pretty up the scenario */
gen sub=subinstr(full_filename,"RUN_","",.)
replace sub=subinstr(sub,".xx6","",.)
compress

gen str30 shortname=""
replace shortname="Constant F" if strmatch(sub,"FCONSTANT_7YRREB_10YRFIXED_REB_STG12")
replace shortname="Constant F AR" if strmatch(sub,"FCONSTANT_7YRREB_10YRFIXED_REB_ARSTG12")



replace shortname="Constant F AR in AVG" if strmatch(sub,"FCONSTANT_7YRREB_AR_IN_AVG_3BRG13BMY")
replace shortname="Constant F AVG in AR" if strmatch(sub,"FCONSTANT_7YRREB_AVG_IN_AR_3BRG13BMY")


replace shortname="ABC CR" if strmatch(sub,"F40_ABC_CR_MULTI_10YRFIXED_REB212")
replace shortname="ABC CR AR" if strmatch(sub,"F40_ABC_CR_MULTI_10YRFIXED_REB_AR212")
replace shortname="ABC CR AVG in AR" if strmatch(sub,"F40_ABC_CR_AR_IN_AVG13BMY")
replace shortname="ABC CR AR in AVG" if strmatch(sub,"F40_ABC_CR_AVG_IN_AR13BMY")




















gen mABC=ABC_
replace mABC=124100 if mABC>=124100
gen price=$cons + mABC/1000*$beta_land
gen revenue=mABC*price
gen running_yr=year-2020

gen discount_factor3=1/((1+.03)^running_yr)
gen discount_factor7=1/((1+.07)^running_yr)



gen d3_rev=discount_factor3*revenue
gen d7_rev=discount_factor7*revenue


save "${data_main}/revenue_trajectory_${vintage_string}.dta", replace
/* you might want to plot mean revenue for each shortname over time.*/

replace revenue=revenue/1000000
drop if shortname==""
collapse (mean) revenue (sd) sdrev=revenue (p50) median_rev=revenue (p25) p25_rev=revenue (p75) p75_rev=revenue  (p5) p5_rev=revenue (p95) p95_rev=revenue , by(year shortname)
encode shortname, gen(mys)
tsset mys year
save "${data_main}/revenue_yearly_stats_${vintage_string}.dta", replace


levelsof shortname, local(mys)

local graphopts legend(order(1 "Mean" 2 "25th percentile" 3 "75th percentile ")  rows(1)) ytitle("Revenue (M nominal)") xtitle("Year") 
local i=1
foreach scenario of local mys{
	tsline revenue p25 p75 if shortname=="`scenario'",  `graphopts' title("`scenario'") name(gr_`i', replace)
	graph export  "${my_images}/timeseries_revenue_`i'.png", as(png) replace
	local ++i
}









use "${data_main}/revenue_trajectory_${vintage_string}.dta", replace

collapse (sum) d3_rev d7_rev, by(full_filename replicate_number shortname)
replace d3_rev=d3_rev/1000000
replace d7_rev=d7_rev/1000000

label var d3_rev "Revenue discounted at 3% (M USD)"
label var d7_rev "Revenue discounted at 7% (M USD)"


gen alt=.
replace alt=3 if strmatch(shortname,"Constant F*")
replace alt=2 if strmatch(shortname,"ABC CR*")

keep if alt~=.



gen keep=0
replace keep=1 if  shortname=="Constant F" | shortname=="Constant F AR" 
replace keep=1 if  shortname=="ABC CR" | shortname=="ABC CR AR" 

gen sort_order=0
replace sort_order=1 if shortname=="ABC CR"
replace sort_order=2 if shortname== "Constant F"
replace sort_order=3 if shortname=="ABC CR AR"
replace sort_order=4 if shortname=="Constant F AR"
replace sort_order=5 if shortname=="ABC CR AR in AVG"
replace sort_order=6 if shortname=="Constant F AR in AVG"
replace sort_order=7 if shortname=="ABC CR AVG in AR"
replace sort_order=8 if shortname=="Constant F AVG in AR"

graph box d3_rev, over(shortname, label(angle(45)) sort(sort_order))

graph export "${my_images}/boxplot_discounted_rev3.png", as(png) replace

graph box d7_rev, over(shortname, label(angle(45)) sort(sort_order))

graph export "${my_images}/boxplot_discounted_rev7.png", as(png) replace


/*
graph box d3_rev if alt==1, over(shortname) nooutsides

*/



/* summary stats */




local stats d3_rev d7_rev
label var d3_rev "Discounted Revenue (3\%)"
label var d7_rev "Discounted Revenue (7\%)"
labmask sort_order, values(shortname)
/*******************************************/
/*******************************************/
/*options for making tables */
/*******************************************/
/*******************************************/
local estpost_opts_grand "statistics(mean sd) columns(statistics) quietly"
local estab_opts_grand "cells("mean(fmt(%8.0fc)) sd(fmt(%8.0fc))") label replace nogaps"

estpost tabstat `stats', `estpost_opts_grand'
esttab .,   `estab_opts_grand'

*esttab . using ${my_tables}/first_stage_averages.tex, `estab_opts_grand'



local  estpost_opts_by "statistics(mean sd) columns(statistics) nototal "

local estab_opts_by "main(mean %8.2gc ) aux(sd %8.2gc) nostar noobs nonote label replace nogaps unstack"

local estab_opts_by_small "main(mean %03.2f) aux(sd %03.2f) nostar noobs nonote label replace nogaps unstack nomtitles nodepvars nonumbers "



estpost tabstat `stats' if alt==2, by(sort_order)  `estpost_opts_by'


esttab .,   `estab_opts_by_small'


esttab . using ${my_tables}/summary_stats_A2.tex, `estab_opts_by_small'



estpost tabstat `stats' if alt==3, by(sort_order)  `estpost_opts_by'


esttab .,   `estab_opts_by_small'


esttab . using ${my_tables}/summary_stats_A3.tex, `estab_opts_by_small'










save "${data_main}/discounted_revenues_${vintage_string}.dta", replace