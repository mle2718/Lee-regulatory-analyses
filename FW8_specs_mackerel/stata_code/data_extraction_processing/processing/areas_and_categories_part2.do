pause on
global codedir "/home/mlee/Documents/Herring_PDT_work/fw6/code"
global datadir "/home/mlee/Documents/Herring_PDT_work/fw6/data"
global outputdir "/home/mlee/Documents/Herring_PDT_work/fw6/outputs"


use "$outputdir/herring_vtr_and_areajoin.dta", replace


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

Aggregate the C's into the A in 1B, 3
don't report the D's in Area 3

*/

gen newcat=category
replace newcat="A" if category=="C" & inlist(hma_comm,"Herring Area 3","Herring Area 1B")
replace newcat="D" if category=="DE"


drop pca ca ar tperms



egen pca=tag(permit newcat hma_comm)
egen ca=tag(newcat hma_comm)
egen ar=tag(hma_comm)

bysort newcat hma_comm: egen tperms=total(pca)
order pca ca ar tperms
list tperms hma_comm category if ca==1
pause


collapse (sum) revenue_herring revenue_all, by(newcat hma_comm)























