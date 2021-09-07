/*****************************************************/
/*
This is a piece of code that matches graphs and compares some of the results from the projections with results from using just the mean ABC.

*/
/*****************************************************/






version 16.1
clear
set scheme s2color
*global vintage_string 2021_09_01


use "${data_main}/revenue_yearly_stats_${vintage_string}.dta", replace
rename mean_revenue mean_rev1

merge 1:1 shortname year using "${data_main}/mean_revenue_yearly_stats_${vintage_string}.dta"
assert _merge==3

rename mean_revenue rev_at_mean

foreach var of varlist mean_rev1 rev_at_mean sdrev median_rev p25_rev p75_rev p5_rev p95_rev{
	replace `var'=`var'/1000000
}

gen sort_order=0
replace sort_order=1 if shortname=="ABC CR AVG"
replace sort_order=2 if shortname== "Constant F AVG"
replace sort_order=3 if shortname=="ABC CR AR"
replace sort_order=4 if shortname=="Constant F AR"
replace sort_order=5 if shortname=="ABC CR AR in AVG"
replace sort_order=6 if shortname=="Constant F AR in AVG"
replace sort_order=7 if shortname=="ABC CR AVG in AR"
replace sort_order=8 if shortname=="Constant F AVG in AR"




local rebuild_start 2023

local labelopts legend(order(1 "Mean Revenue" 2 "25th percentile" 3 "75th percentile" 4 "Rev of mean" 5 "5th percentile" 6 "95th percentile") rows(2)) ylabel(5(5)30)  tlabel(2021(2)2033)  lpattern(solid solid solid dot dash dash) lwidth(medthick medium medium medthick medthick medthick)
local axisopts ytitle("Revenue (M nominal)") xtitle("Year")  
local addlines tline(`rebuild_start', lcolor(black) lpattern(dash)) tmtick(##2) text(30 `rebuild_start' "Rebuilding F starts", placement(e)) 
 levelsof shortname, local(mys)

levelsof sort_order, local(mys)

foreach scenario of local mys{
    preserve
	keep if sort_order==`scenario'
	local scenario_name=shortname[1]
	tsline mean_rev1 p25_rev p75_rev rev_at_mean p5_rev p95_rev,  `labelopts' `axisopts' `addlines' title("`scenario_name'") name(gr_`scenario', replace)
	graph export  "${my_images}/timeseries_outlier_revenue_`scenario'.png", as(png) replace

	restore
}






local labelopts legend(order(1 "Mean Revenue" 2 "25th percentile" 3 "75th percentile" 4 "Rev of mean" ) rows(2)) ylabel(5(5)30)  tlabel(2021(2)2033)  lpattern(solid solid solid dot dash dash) lwidth(medthick medium medium medthick medthick medthick)
local axisopts ytitle("Revenue (M nominal)") xtitle("Year")  
local addlines tline(`rebuild_start', lcolor(black) lpattern(dash)) tmtick(##2) text(30 `rebuild_start' "Rebuilding F starts", placement(e)) 




foreach scenario of local mys{
    preserve
	keep if sort_order==`scenario'
	local scenario_name=shortname[1]
	tsline mean_rev1 p25_rev p75_rev rev_at_mean,  `labelopts' `axisopts' `addlines' title("`scenario_name'") name(gr_`scenario', replace)

	graph export  "${my_images}/timeseries_A_revenue_`scenario'.png", as(png) replace

	restore
}




