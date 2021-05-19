
global codedir "/home/mlee/Documents/Herring_PDT_work/fw6/code"
global datadir "/home/mlee/Documents/Herring_PDT_work/fw6/data"
global outputdir "/home/mlee/Documents/Herring_PDT_work/fw6/outputs"

use "$outputdir/herring_vtr_and_areajoin.dta", replace


keep if year>=2016 & year<=2018

/* Bin into  Midwater, Bottom, Purse, and Other*/
gen str5 gear2="PTM" if inlist(gearcode,"PTM")
replace  gear2="OTM" if inlist(gearcode,"OTM")

replace gear2="BT" if inlist(gearcode,"OTB","OTF", "OTO", "OTR", "OTS") 
replace gear2="PUR" if inlist(gearcode,"PUR")
replace gear2="OTHER" if strmatch(gear2,"")

/* revenue by gear and area */

/* check confids - tag the distinct permits in each gear and area
tag distinct gear area
tag the distinct areas */
egen pga=tag(permit gear2 hma_comm)
egen ga=tag(gear2 hma_comm)
egen ar=tag(hma_comm)

bysort gear2 hma_comm: egen tperms=total(pga)

order pga ga ar tperms

/* This will display the distinct permit-gear in each HMA */
list tperms hma_comm gear2 if ga==1
pause
/* POtential problems are "BT in 1B, OTher in 1B, Other in 3, PUR in 1B, 2 
a. group PUR 1B and 2 (3 distinct permits)
b. group BT 1B with 1A
c. Group 
*/


replace hma_comm="Herring Area 1A" if gear2=="OTHER"
replace gear2="OTM" if gear2=="PTM"

drop pga ga ar tperms
egen pga=tag(permit gear2 hma_comm)
egen ga=tag(gear2 hma_comm)
egen ar=tag(hma_comm)

bysort gear2 hma_comm: egen tperms=total(pga)

collapse (sum) kept_herring revenue_herring pga, by(gear2 hma_comm)
replace kept=kept/2204
rename kept kept_mt
