version 16.1
clear
set scheme s2color
*global vintage_string 2021_09_01


use "${data_main}/revenue_yearly_stats_${vintage_string}.dta", replace
drop mean_revenue

merge 1:1 shortname year using "${data_main}/mean_revenue_yearly_stats_${vintage_string}.dta"
assert _merge==3



foreach var of varlist mean_revenue sdrev median_rev p25_rev p75_rev p5_rev p95_rev{
	replace `var'=`var'/1000000
}

local labelopts legend(order(1 "Mean Revenue") rows(1)) ylabel(5(5)30)  tlabel(2021(2)2033)
local axisopts ytitle("Revenue (M nominal)") xtitle("Year")  
local addlines tline(2022, lcolor(black) lpattern(dash)) tmtick(##2) text(30 2022 "Rebuilding F starts", placement(e)) 
 levelsof shortname, local(mys)

local i=1
foreach scenario of local mys{
	tsline mean_revenue  if shortname=="`scenario'",  `labelopts' `axisopts' `addlines' title("`scenario'") name(gr_`i', replace)
	graph export  "${my_images}/timeseries_revenue_`i'.png", as(png) replace
	local ++i
}


pause

use "${data_main}/mean_revenue_trajectory_${vintage_string}.dta", replace

gen alt=.
replace alt=3 if strmatch(shortname,"Constant F*")
replace alt=2 if strmatch(shortname,"ABC CR*")

keep if alt~=.
gen sort_order=0
replace sort_order=1 if shortname=="ABC CR"
replace sort_order=2 if shortname== "Constant F"
replace sort_order=3 if shortname=="ABC CR AR"
replace sort_order=4 if shortname=="Constant F AR"
replace sort_order=5 if shortname=="ABC CR AR in AVG"
replace sort_order=6 if shortname=="Constant F AR in AVG"
replace sort_order=7 if shortname=="ABC CR AVG in AR"
replace sort_order=8 if shortname=="Constant F AVG in AR"



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












