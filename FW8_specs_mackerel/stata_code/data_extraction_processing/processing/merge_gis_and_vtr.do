pause on
global codedir "/home/mlee/Documents/Herring_PDT_work/fw6/code"
global datadir "/home/mlee/Documents/Herring_PDT_work/fw6/data"
global outputdir "/home/mlee/Documents/Herring_PDT_work/fw6/outputs"

cd "$outputdir"
use "$outputdir/herring_from_vtr2.dta", clear

gen herring=0
replace herring=1 if nespp3==168
drop discard
collapse (sum) revenue kept , by(herring my_id tripid gearcode permit portlnd1  state1 cat year)
reshape wide revenue kept, i(my_id) j(herring)
foreach var of varlist revenue* kept* {
replace `var'=0 if `var'==.
}
gen revenue_all=revenue0+revenue1
gen kept_all=kept0+kept1

rename revenue1 revenue_herring
rename kept1 kept_herring
drop revenue0 kept0
pause
replace gearcode="PTM" if gearcode=="PTW" & kept_herring>=20000
merge 1:1 my_id using "$datadir/gis/herring_spatial_join4.dta"


keep if year>=2016 & year<=2018
drop _merge

/* */
save "$outputdir/herring_vtr_and_areajoin.dta", replace
export delimited using "/home/mlee/Documents/Herring_PDT_work/fw6/outputs/herring_vtr_and_areajoin.csv", replace
