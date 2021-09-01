version 16.1
clear
/* code to copy over the ABC's from derobas folder.

You've mapped his /work2/jderoba to X */

global subfolder "Herring/2021 Rebuild Projections"
global deroba_full "X://$subfolder"

/* look up the directories in his folder */
local mm: dir "$deroba_full" dirs "*", respectcase
local foldercount: word count `mm'
clear
set obs `foldercount'
gen str60 folder=""
gen str60 filename12 =""
gen str60 filename13 =""

/* Look through for the *12.xx6 files and copy them down to your computer*/
local stepno=1
foreach folder of local mm{
	di "Working on Folder `folder'.  This is folder number `stepno'."
	local getme 
	local getmeA : dir "$deroba_full/`folder'" files "*12.xx6", respectcase
	local getme2BMY : dir "$deroba_full/`folder'" files "*12BMY.xx6", respectcase
    local getme `getme' `getmeA' `getme2BMY'

	local getme :subinstr local getme `"""' "", all

	/*some folders have no 12.xx6 files */
	if "`getme'"==""{
		di "no matching 12.xx6 file in ${deroba_full}/`folder'"
	}
	else{	
		/* some folders have multiple 12.xx6 files */
		local getmelength:  word count `getme'
		forvalues i=1/`getmelength'{
		
			local getme12: word `i' of `getme'
			local f12  $deroba_full/`folder'/`getme12'
			
			di "getting `f12'"
			! cp "`f12'" "$data_raw"
		}
	}
/* Look through for the *13.xx6 files and copy them down to your computer*/

	local getme2 
	local getme2A : dir "$deroba_full/`folder'" files "*13.xx6", respectcase
	local getme2BMY : dir "$deroba_full/`folder'" files "*13BMY.xx6", respectcase
    local getme2 `getme2' `getme2A' `getme2BMY'
	
	local getme2 :subinstr local getme2 `"""' "", all

	di "This is what we're working on `getme2'"
	
		/*some folders have no 13.xx6 files */
	if "`getme2'"==""{
		di "no matching 13.xx6 file in ${deroba_full}/`folder'"
	}
	else{
		/* some folders have multiple 13.xx6 files */
	local getmelength2:  word count `getme2'
	forvalues j=1/`getmelength2'{
		local getme13: word `j' of `getme2'
		local f13  $deroba_full/`folder'/`getme13'
		
		di "getting `f13'"
		! cp "`f13'" "$data_raw"

		}
	}


	replace folder="`folder'" in `stepno'
	replace filename12="`getme'" in `stepno'
	replace filename13="`getme2'" in `stepno'

	di "Done with Folder `folder'. This was folder number `stepno'. "
	local ++stepno

}
compress


/* there's multiple files in some of the folder, so you'll have to parse this as well. split on the space */

split filename12, gen(filename12_) parse(" ")
split filename13, gen(filename13_) parse(" ")
drop filename12 filename13
reshape long filename12_ filename13_, i(folder) j(rep)
drop if filename12_=="" & filename13_==""
rename filename12_ filename12
rename filename13_ filename13

sort folder filename12 filename13


/* decoder key */
gen str30 alternative=""
replace alternative="Constant Seven Year" if strmatch(folder,"F_CONSTANT_SEVENYR*")
replace alternative="F40 ABC CR" if strmatch(folder,"F40_ABC_CR*")
replace alternative="F Zero" if strmatch(folder,"F_ZERO_10YR*")



gen str30 recruitment_type=""
replace recruitment_type="AVG" if strmatch(filename13,"*_AR_IN_AVG*")
replace recruitment_type="AR" if strmatch(filename13,"*_AVG_IN_AR*")
replace recruitment_type="AR" if strmatch(folder,"F_ZERO_10YRFIXED_REBUILD_AR_STAGE")

replace recruitment_type="AR" if strmatch(filename12,"*AR12.xx6*") & recruitment_type==""
replace recruitment_type="AR" if strmatch(filename12,"*_AR**") & recruitment_type==""
replace recruitment_type="AVG" if recruitment_type==""




/* fill in what the manager things the recruitment is */
gen str30 recruitment_belief=recruitment_type
/* and mix them up*/
replace recruitment_belief="AR" if strmatch(filename13,"*_AR_IN_AVG*")
replace recruitment_belief="AVG" if strmatch(filename13,"*_AVG_IN_AR*")



gen sensitivity_shorthand=""
replace sensitivity_shorthand = "BASE" if  recruitment_belief=="AVG" & recruitment_type=="AVG" 
replace sensitivity_shorthand = "AVG in AR" if recruitment_belief=="AVG" & recruitment_type=="AR" 
replace sensitivity_shorthand = "AR in AVG" if recruitment_belief=="AR" & recruitment_type=="AVG" 
replace sensitivity_shorthand = "AR" if recruitment_belief=="AR" & recruitment_type=="AR" 


gen obsolete=0
replace obsolete=1 if strmatch(alternative,"F Zero")
replace obsolete=1 if inlist(filename13,"RUN_F40_ABC_CR_AR_IN_AVG13.xx6","RUN_F40_ABC_CR_AVG_IN_AR13.xx6", "FCONSTANT_7YRREB_AR_IN_AVG_3BRG13.xx6","FCONSTANT_7YRREB_AVG_IN_AR_3BRG13.xx6","RUN_FCONSTANT_7YRREB_10YRFIXED_REB_STG12","RUN_FCONSTANT_7YRREB_10YRFIXED_REB_ARSTG12")
/*
...F_CONSTANT_SEVENYR_REBUILD_3BRG / FCONSTANT_7YRREB_3STG12BMY.xx6
...F_CONSTANT_SEVENYR_REBUILD_3BRG_AR / FCONSTANT_7YRREB_3STG_AR12BMY.xx6

F40_ABC_CR_10YRFIXED_REBUILD_2BRG \\ RUN_F40_ABC_CR_MULTI_10YRFIXED_REB212.xx6
F40_ABC_CR_10YRFIXED_REBUILD_AR_3BRG \\ RUN_F40_ABC_CR_MULTI_10YRFIXED_AR_3BRG12.xx6
*/

rename filename12 filename
replace filename=filename13 if filename==""
drop filename13



/* pretty up the scenario */
gen strl=strlen(filename)
gen sub=substr(filename,1,strl-4)
drop strl


gen markin=0
/* 7 year rebuild with constant F*/
replace markin=1 if strmatch(filename,"FCONSTANT_7YRREB_3STG12BMY.xx6")

/* ABCCR */
replace markin=1 if strmatch(filename,"RUN_F40_ABC_CR_MULTI_10YRFIXED_REB212.xx6")

/*Sensitivity - 7 year rebuild under autocorrelated something */
replace markin=1 if strmatch(filename,"FCONSTANT_7YRREB_3STG_AR12BMY.xx6")
/*Sensitivity - ABC CR rebuild under autocorrelated something */
replace markin=1 if strmatch(filename,"RUN_F40_ABC_CR_MULTI_10YRFIXED_AR_3BRG12.xx6")

/*Sensitivity - 7 year where we think it's AR when it's really AVG and vice versa */

replace markin=1 if strmatch(filename,"FCONSTANT_7YRREB_AR_IN_AVG_3BRG13BMY.xx6")
replace markin=1 if strmatch(filename,"FCONSTANT_7YRREB_AVG_IN_AR_3BRG13BMY.xx6")

/*Sensitivity - ABC CR year where we think it's AR when it's really AVG and vice versa */

replace markin=1 if strmatch(filename,"RUN_F40_ABC_CR_AR_IN_AVG13BMY.xx6")
replace markin=1 if strmatch(filename,"RUN_F40_ABC_CR_AVG_IN_AR13BMY.xx6")

gsort - markin alternative

drop rep obsolete sub



bysort filename: assert _N==1

gsort - markin - alternative - sensitivity_shorthand folder
order alternative sensitivity_shorthand folder filename markin 

save "${data_raw}\scenario_key.dta", replace

export delimited using "${data_raw}\scenario_key.csv", delimiter(",") replace


filelist, directory("$data_raw") pattern("*.xx6") save ("${data_raw}/simfileslist_${vintage_string}.dta") replace

