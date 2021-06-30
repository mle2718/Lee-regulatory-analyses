version 16.1
clear
global vintage_string 2021_05_27


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

*/

global cons 774.5517
global beta_land -5.356439

use `data_in', replace

/* pretty up the scenario */
gen strl=strlen(full_filename)
gen sub=substr(full_filename,1,strl-6)
replace sub=substr(sub,5,.)


gen str30 shortname=""
replace shortname="Constant F" if strmatch(sub,"FCONSTANT_7YRREB_10YRFIXED_REB_STG")
replace shortname="Constant F AR" if strmatch(sub,"FCONSTANT_7YRREB_10YRFIXED_REB_ARSTG")
replace shortname="Constant F AR in AVG" if strmatch(sub,"FCONSTANT_7YRREB_AR_IN_AVG")
replace shortname="Constant F AVG in AR" if strmatch(sub,"FCONSTANT_7YRREB_AVG_IN_AR")


replace shortname="ABC CR" if strmatch(sub,"F40_ABC_CR_MULTI_10YRFIXED_REB2")
replace shortname="ABC CR AR" if strmatch(sub,"F40_ABC_CR_MULTI_10YRFIXED_REB_AR2")
replace shortname="ABC CR AVG in AR" if strmatch(sub,"F40_ABC_CR_AVG_IN_AR")
replace shortname="ABC CR AR in AVG" if strmatch(sub,"F40_ABC_CR_AR_IN_AVG")
drop strl sub


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









collapse (sum) d3_rev d7_rev, by(full_filename replicate_number shortname)
replace d3_rev=d3_rev/1000000
replace d7_rev=d7_rev/1000000

label var d3_rev "Revenue discounted at 3% (M USD)"
label var d7_rev "Revenue discounted at 7% (M USD)"


gen alt=.
replace alt=1 if strmatch(shortname,"Constant F*")
replace alt=2 if strmatch(shortname,"ABC CR*")

keep if alt~=.



gen keep=0
replace keep=1 if  shortname=="Constant F" | shortname=="Constant F AR" 
replace keep=1 if  shortname=="ABC CR" | shortname=="ABC CR AR" 

graph box d3_rev d7_rev if keep==1, over(shortname)  legend(rows(2))
graph export "${my_images}/boxplot_discounted_rev.png", as(png) replace


/*
graph box d3_rev if alt==1, over(shortname) nooutsides





/* summary stats */




local stats d3_rev d7_rev

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



estpost tabstat `stats2', `estpost_opts_grand'
esttab .,   `estab_opts_grand_small'
esttab . using ${my_tables}/first_stage_averages_pr_inter.tex, `estab_opts_grand_small'




local  estpost_opts_by "statistics(mean sd) columns(statistics) listwise nototal quietly"

local estab_opts_by "main(mean %8.2gc ) aux(sd %8.2gc) nostar noobs nonote label replace nogaps unstack"

local estab_opts_by_small "main(mean %03.2f) aux(sd %03.2f) nostar noobs nonote label replace nogaps unstack"



estpost tabstat `stats' transactions, by(fy)  `estpost_opts_by'








*/




/*
The only two alternatives at this point are
 "7yrFconstant" with assumed average recruitment "F_CONSTANT_SEVENYR_REBUILD_STAGE"
 "ABC CR" with assumed average recruitment, "F40_ABC_CR_10YRFIXED_REBUILD_2BRG"
 
 
  "7yrFconstant" with AR recruitment instead of average "F_CONSTANT_SEVENYR_REBUILD_AR_STAGE"
 "ABC CR" with AR recruitment instead of average, "F40_ABC_CR_10YRFIXED_REBUILD_AR_2BRG"

  Any folder name ending in "...AVG_IN_AR" uses the projected catches based on assuming average recruitment in a projection where AR recruitment actually occurs;
  and visa versa for "...AR_IN_AVG".

Except for the "AVG_IN_AR" or "AR_IN_AVG" folders, the file you need ends with "...12.xx6". 

for the "AVG_IN_AR" or "AR_IN_AVG" folders, the file you need ends with "...13.xx6". 


Number of columns = number of years, with the first column being 2020.  We only need up to 2032. So drop ABC_2033.

The number of rows = the number of stochastic realizations. There are 100,000

The values equal the ABCs in metric tons

*/



save "${data_main}/discounted_revenues_${vintage_string}.dta", replace