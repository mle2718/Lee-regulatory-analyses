#delimit ;
global lbs_to_mt 2204.62;



local data_in "${data_intermediate}/monthly_util_herring.dta";
use `data_in', replace;
keep if year<=2023;

collapse (sum) landings_mt value (first) frac_bait, by(year month mymonth);
/* pull in deflators */

merge m:1 year using ${data_external}\deflatorsY.dta, keep(1 3);
assert _merge==3;
drop _merge;


gen value_realGDP=value/fGDPDEF_2023;


tsset mymonth;
bysort year: egen vs=total(value);
bysort year: egen ls=total(landings_mt);

bysort year: egen vsR=total(value_realGDP);




gen pricemt=value/landings_mt;
gen pricemt_yr=vs/ls;

gen pricemt2023=value_realGDP/landings_mt;
gen pricemt_yr2023=vsR/ls;




label var ls "annual landings";
label var pricemt "monthly average nominal price";
label var pricemt_yr "annual average nominal price";

label var pricemt2023 "monthly average Real (2023) price";
label var pricemt_yr2023 "annual average Real (2023) price";


replace landings=landings/1000;
label var landings "(000 mt)";

gen price=pricemt/$lbs_to_mt;
gen price_yr=pricemt_yr/$lbs_to_mt;

sort mymonth;
/* some regressions */


regress pricemt2023 landings_mt i.month;
est store monthly_ols;

ivregress 2sls pricemt2023 (landings_mt=l12.landings_mt) i.month;

est store monthly_iv;



local saving_opts style(tex) replace;
local header_opts mlabels("OLS" "IV") collabels(none) nonumbers ;

esttab monthly_ols monthly_iv using ${my_tables}/Mregression_results2023.tex,  b se compress  r2 label `header_opts' `saving_opts' ;







