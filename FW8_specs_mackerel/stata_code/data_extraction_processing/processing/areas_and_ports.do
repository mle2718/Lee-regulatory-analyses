

cd "/home/mlee/Documents/Herring_PDT_work/specs2016"
use "herring_spatial_classified.dta", replace


keep if year>=2012 & year<=2014

/* check confids - tag the distinct permits in each portlnd1, state1 and area
tag distinct hma portlnd1 state1
tag the distinct portlnd1 state1 */
egen port_hma=tag(permit hma_comm portlnd1 state1)
egen ga=tag(portlnd1 state1 hma_comm)
egen ar=tag(portlnd1 state1)

bysort portlnd1 state1 hma_comm: egen tperms=total(port_hma)

order port_hma ga ar tperms

/* This will display the distinct permit-gear in each HMA */
list tperms hma_comm portlnd1 state1 if ga==1

pause
preserve
/* POtential problems are "BT in 1B, OTher in 1B, Other in 3, PUR in 1B, 2 
a. group PUR 1B and 2 (3 distinct permits)
b. group BT 1B with 1A
c. Group 
*/


replace hma_comm="Herring Area 1B" if hma_comm=="Herring Area 2" & gear2=="PUR"
replace hma_comm="Herring Area 1A" if hma_comm=="Herring Area 1B" & gear2=="BT"

drop pga ga ar tperms
egen pga=tag(permit gear2 hma_comm)
egen ga=tag(gear2 hma_comm)
egen ar=tag(hma_comm)

bysort gear2 hma_comm: egen tperms=total(pga)

collapse (sum) kept revenue port_hma, by(gear2 hma_comm)
replace kept=kept/2204
restore


collapse (sum) kept revenue port_hma, by(hma_comm, portlnd1 state1)
