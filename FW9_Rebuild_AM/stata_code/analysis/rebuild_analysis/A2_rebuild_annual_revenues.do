/*****************************************************/
/*****************************************************/
/*
Use the mean ABCs, taken directly from the FW9 document to compute revenue at the mean ABC.

*/
/*****************************************************/
/*****************************************************/

use "${data_main}/mean_revenue_trajectory_${vintage_string}.dta", replace

replace rev=rev/1000000
label var revenue "Revenue M"
rename ABC ABC


collapse (mean) revenue , by( shortname year)


reshape wide revenue, i(shortname) j(year) 

forvalues yr=2021(1)2032{
    label var revenue`yr' `yr'
}



/*******************************************/
/* construct a variable that will put the box plots in a reasonable order*/
/*******************************************/

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

labmask sort_order, values(shortname)




/*******************************************/
/*******************************************/
/* Make some tables */
/*******************************************/
/*******************************************/



/*******************************************/
/*options for making tables */
/*******************************************/

local stats revenue 
local  estpost_opts_by "statistics(mean) columns(statistics) nototal "
local estab_opts_by_small "main(mean %03.2f )nostar noobs nonote label replace  unstack nomtitles nodepvars nonumbers compress nogaps"




estpost tabstat revenue* if inlist(sort_order,1, 3 ,5 ,7), by(sort_order) `estpost_opts_by'
esttab . using ${my_tables}/yearly_revenue_trajectoryA2.tex, `estab_opts_by_small'


estpost tabstat revenue* if inlist(sort_order,2,4,6,8), by(sort_order) `estpost_opts_by'
esttab . using ${my_tables}/yearly_revenue_trajectoryA3.tex, `estab_opts_by_small'




estpost tabstat revenue* if inlist(sort_order,9,10), by(sort_order) `estpost_opts_by'
esttab . using ${my_tables}/yearly_revenue_trajectoryAlt_3A.tex, `estab_opts_by_small'


