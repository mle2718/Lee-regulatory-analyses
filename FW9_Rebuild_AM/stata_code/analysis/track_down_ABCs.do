/* track down ABCs and projections */

use "C:\Users\Min-Yang.Lee\Documents\READ-SSB-Lee-herring-analyses\FW9_Rebuild_AM\data_folder\main\revenue_trajectory_2021_09_01.dta", clear
local data_in "${data_main}/ABCs_${vintage_string}.dta"

/* look at the ABC CR with AVG*/

browse if year==2021 & full_filename=="RUN_F40_ABC_CR_MULTI_10YRFIXED_REB212.xx6"


/* look at the ABC CR with AR*/
browse if year==2021 & full_filename=="RUN_F40_ABC_CR_MULTI_10YRFIXED_AR_3BRG12.xx6"
pause


replace rev=rev/1000000
label var revenue "Revenue M"
rename ABC ABC



local stats revenue ABC



local estpost_opts_grand "statistics(mean sd) columns(statistics) quietly"
local estab_opts_grand "cells("mean(fmt(%8.0fc)) sd(fmt(%8.0fc))") label replace nogaps"

local  estpost_opts_by "statistics(mean) columns(statistics) nototal "

local estab_opts_by "main(mean %8.0gc median %8.0gc) nostar noobs nonote label replace nogaps unstack"

local estab_opts_by_small "main(mean %03.2f )nostar noobs nonote label replace nogaps unstack nomtitles nodepvars nonumbers "


levelsof full_filename, local(files)

foreach working_file of local files{
	estpost tabstat `stats' if full_filename=="`working_file'", by(year)  `estpost_opts_by'
	esttab . using ${my_tables}/ABC_`working_file'.csv, `estab_opts_by_small'
}


collapse (mean) revenue, by(full_filename shortname year)

reshape wide revenue, i(shortname) j(year) 


forvalues yr=2021(1)2032{
    label var revenue`yr' `yr'
}

estpost tabstat revenue* , by(shortname) `estpost_opts_by'
esttab . , `estab_opts_by_small'



/*


local data_in "${data_main}/ABCs_${vintage_string}.dta"

collapse (mean) ABC , by( full_filename shortname year)
rename ABC ABC_
reshape wide ABC_, i(full_filename) j(year)



*/

local data_in "${data_main}/ABCs_${vintage_string}.dta"

use `data_in', clear
collapse (mean) ABC , by( full_filename year)
rename ABC_ ABC
export excel using "C:\Users\Min-Yang.Lee\Desktop\ABC_check.xlsx", replace





