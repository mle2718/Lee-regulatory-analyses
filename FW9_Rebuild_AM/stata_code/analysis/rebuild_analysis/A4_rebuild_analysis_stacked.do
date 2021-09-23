/*****************************************************/
/*
This is a piece of code that joins in the values "at mean ABC" with the raw projection prediction

Ultimately, much of this is not used for the FW9 Analysis.


*/
/*****************************************************/







version 16.1
clear
set scheme s2mono
*global vintage_string 2021_09_01


use "${data_main}/revenue_yearly_stats_${vintage_string}.dta", replace
drop mean_revenue

merge 1:1 shortname year using "${data_main}/mean_revenue_yearly_stats_${vintage_string}.dta"
assert _merge==3 | _merge==2 & strmatch(shortname,"Alt 3A*")


gen sort_order=0
replace sort_order=1 if shortname=="ABC CR AVG"
replace sort_order=2 if shortname== "Constant F AVG"
replace sort_order=3 if shortname=="ABC CR AR"
replace sort_order=4 if shortname=="Constant F AR"
replace sort_order=5 if shortname=="ABC CR AR in AVG"
replace sort_order=6 if shortname=="Constant F AR in AVG"
replace sort_order=7 if shortname=="ABC CR AVG in AR"
replace sort_order=8 if shortname=="Constant F AVG in AR"


replace sort_order=9 if shortname=="Alt 3A lower F AVG"
replace sort_order=10 if shortname=="Alt 3A lower F AVG in AR"


foreach var of varlist mean_revenue sdrev median_rev p25_rev p75_rev p5_rev p95_rev{
	replace `var'=`var'/1000000
}
local rebuild_start 2023

local labelopts legend(order(1 "Mean Revenue") rows(1)) ylabel(5(5)30)  tlabel(2021(2)2033)
local axisopts ytitle("Revenue (M nominal)") xtitle("Year")  
local addlines tline(`rebuild_start', lcolor(black) lpattern(dash)) tmtick(##2) text(30 `rebuild_start' "Rebuilding F starts", placement(e)) 

levelsof sort_order, local(mys)

foreach scenario of local mys{
    preserve
	keep if sort_order==`scenario'
	local scenario_name=shortname[1]
	tsline mean_revenue ,  `labelopts' `axisopts' `addlines' title("`scenario_name'") name(gr_`scenario', replace)
	graph export  "${my_images}/timeseries_revenue_`scenario'.png", as(png) replace

	restore
}


pause

use "${data_main}/mean_revenue_trajectory_${vintage_string}.dta", replace

gen alt=.
replace alt=3 if strmatch(shortname,"Constant F*")
replace alt=2 if strmatch(shortname,"ABC CR*")
replace alt=4 if strmatch(shortname,"Alt 3A*")

keep if alt~=.
gen sort_order=0
replace sort_order=1 if shortname=="ABC CR AVG"
replace sort_order=2 if shortname== "Constant F AVG"
replace sort_order=3 if shortname=="ABC CR AR"
replace sort_order=4 if shortname=="Constant F AR"
replace sort_order=5 if shortname=="ABC CR AR in AVG"
replace sort_order=6 if shortname=="Constant F AR in AVG"
replace sort_order=7 if shortname=="ABC CR AVG in AR"
replace sort_order=8 if shortname=="Constant F AVG in AR"


replace sort_order=9 if shortname=="Alt 3A lower F AVG"
replace sort_order=10 if shortname=="Alt 3A lower F AVG in AR"

replace d3_rev=d3_rev/1000000
replace d7_rev=d7_rev/1000000


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

/* Total Revenues */

collapse (sum) d3_rev d7_rev, by (alt shortname sort_order)
label var d3_rev "Discounted Revenue (3\%)"
label var d7_rev "Discounted Revenue (7\%)"


save "${data_main}/discounted_revenues_${vintage_string}.dta", replace






local stats d3_rev d7_rev 



local  estpost_opts_by "statistics(mean) columns(statistics) nototal "

local estab_opts_by_small "main(mean %03.2f )nostar noobs nonote label replace  unstack nomtitles nodepvars nonumbers compress nogaps"
estpost tabstat `stats'  if inlist(sort_order,1,3,5,7), by(sort_order) `estpost_opts_by'
esttab . ,  `estab_opts_by_small'

esttab . using ${my_tables}/summary_stats_A2.tex, `estab_opts_by_small'


estpost tabstat `stats' if inlist(sort_order,2,4,6,8), by(sort_order) `estpost_opts_by'
esttab . using ${my_tables}/summary_stats_A3.tex, `estab_opts_by_small'




estpost tabstat `stats' if inlist(sort_order,9,10), by(sort_order) `estpost_opts_by'
esttab . using ${my_tables}/summary_stats_Alt3A.tex, `estab_opts_by_small'








