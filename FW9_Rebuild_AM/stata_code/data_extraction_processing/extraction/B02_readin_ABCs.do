version 16.1
clear

use "${data_raw}/simfileslist_${vintage_string}.dta", clear
local obs=_N


di "There are `obs' files in total"

quietly forvalues i=1/`obs' {
        use "${data_raw}/simfileslist_${vintage_string}.dta" in `i', clear
		local myfilename =filename[1]
		local f = "${data_raw}/" + filename

		
		import delimited using "`f'", clear delimit(" ", collapse)
		gen str100 full_filename="`myfilename'"
		gen replicate_number=_n
		tempfile savefile_`i'
	      
	    compress
		save "`savefile_`i''"

	}
clear


forvalues i=1/`obs' {
           append using "`savefile_`i''"
}





/*prepare to reshape */


drop v15
local yr 2020

foreach i of numlist 1/14{

rename v`i' ABC_`yr'
label var ABC_`yr' "ABC in year `yr' (mt)"

local ++yr	
	
}
cap drop ABC_2033

order full_filename replicate
compress



save "${data_raw}\ABC_full_${vintage_string}.dta", replace



reshape long ABC_, i(full_filename replicate_number) j(year)
gen markin=0

/* 7 year rebuild with constant F*/
replace markin=1 if strmatch(full_filename,"FCONSTANT_7YRREB_3STG12BMY.xx6")

/* ABCCR */
replace markin=1 if strmatch(full_filename,"RUN_F40_ABC_CR_MULTI_10YRFIXED_REB212.xx6")


/*Sensitivity - 7 year rebuild under autocorrelated something */
replace markin=1 if strmatch(full_filename,"FCONSTANT_7YRREB_3STG_AR12BMY.xx6")

/*Sensitivity - ABC CR rebuild under autocorrelated something */
replace markin=1 if strmatch(full_filename,"RUN_F40_ABC_CR_MULTI_10YRFIXED_AR_3BRG12.xx6")

/*Sensitivity - 7 year where we think it's AR when it's really AVG and vice versa */

replace markin=1 if strmatch(full_filename,"FCONSTANT_7YRREB_AR_IN_AVG_3BRG13BMY.xx6")
replace markin=1 if strmatch(full_filename,"FCONSTANT_7YRREB_AVG_IN_AR_3BRG13BMY.xx6")

/*Sensitivity - ABC CR year where we think it's AR when it's really AVG and vice versa */


replace markin=1 if strmatch(full_filename,"RUN_F40_ABC_CR_AR_IN_AVG13BMY.xx6")
replace markin=1 if strmatch(full_filename,"RUN_F40_ABC_CR_AVG_IN_AR13BMY.xx6")

keep if markin==1




save "${data_main}\ABCs_${vintage_string}.dta", replace

/* mark in the ones I need */

/*
The only two alternatives at this point are
 "7yrFconstant" with assumed average recruitment "FCONSTANT_7YRREB_3STG12BMY"
 "ABC CR" with assumed average recruitment, "FCONSTANT_7YRREB_3STG_AR12BMY"
 
  "7yrFconstant" with AR recruitment instead of average "FCONSTANT_7YRREB_3STG_AR12BMY"
 "ABC CR" with AR recruitment instead of average, "F40_ABC_CR_10YRFIXED_REBUILD_AR_2BRG"

  Any folder name ending in "...AVG_IN_AR" uses the projected catches based on assuming average recruitment in a projection where AR recruitment actually occurs;
  and visa versa for "...AR_IN_AVG".

Except for the "AVG_IN_AR" or "AR_IN_AVG" folders, the file you need ends with "...12.xx6". 

for the "AVG_IN_AR" or "AR_IN_AVG" folders, the file you need ends with "...13.xx6". 


Number of columns = number of years, with the first column being 2020.  We only need up to 2032. So drop ABC_2033.

The number of rows = the number of stochastic realizations. There are 100,000

The values equal the ABCs in metric tons

*/



