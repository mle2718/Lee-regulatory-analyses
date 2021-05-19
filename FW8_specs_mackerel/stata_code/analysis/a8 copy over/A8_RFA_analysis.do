/* I'll need to do the RFA analysis the usual way, but I'll need to link with gearcodes as well */


cd "/home/mlee/Documents/Herring_PDT_work/Amendment8/round4"

/*"herring_geartype_classifed.dta" contains a gear classification based on revenue in herring for each permit-year from 2010-2017partial. I only have the ABCE (NO D) vessels.*/

use herring_geartype_classifed.dta if year==2016
tempfile pclass
drop year
save `pclass', replace

/*affiliate data */
use "/home/mlee/Documents/Workspace/ownership/new_affiliates_2016.dta" 
merge m:1  permit using `pclass'

/* go look at your code to see how you make the small/large determination and get the average revenues */
