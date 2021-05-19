cd "/home/mlee/Documents/Herring_PDT_work/specs2016"
use herring_spatial_classified, clear



keep if year>=2012 & year<=2014

gen str1 category=" "
replace category="A" if HRG_A==1
replace category="C" if HRG_C==1
replace category="D" if HRG_D==1



/* revenue by gear and area */

/* check confids - tag the distinct permits in each gear and area
tag distinct gear area
tag the distinct areas */
egen pca=tag(permit category hma_comm)
egen ca=tag(category hma_comm)
egen ar=tag(hma_comm)

bysort category hma_comm: egen tperms=total(pca)

order pca ca ar tperms

/* This will display the distinct permit-gear in each HMA */
list tperms hma_comm category if ca==1
pause
/* POtential problems are:

Cat C -- 1B, 3.    No good fix.
*/


collapse (sum) kept revenue pca, by(category hma_comm)
replace kept=kept/2204
