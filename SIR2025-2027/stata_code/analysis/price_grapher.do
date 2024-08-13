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


set scheme s2mono;
*drop if pricemt>=500;
drop if year>=2024;
tsfill;



local graph_subset mymonth<=monthly("2023m12","YM") & mymonth>=monthly("2016m1", "YM");
local graph_subset mymonth<=monthly("2023m12","YM") & mymonth>=monthly("2016m1", "YM");
local graphopts tmtick(##6);


replace landings=landings/1000;
label var landings "(000 mt)";

gen price=pricemt/$lbs_to_mt;
gen price_yr=pricemt_yr/$lbs_to_mt;

twoway (tsline pricemt if `graph_subset', `graphopts' cmissing(n))  (tsline pricemt_yr if  `graph_subset', `graphopts'), ytitle("Price per metric ton") tlabel(, format(%tmCCYY)) name(herringprice, replace) legend(off)  ttitle("");
twoway bar landings mymonth  if  `graph_subset', xmtick(##5) xlabel(, format(%tmCCYY)) xtitle("") name(herringlandings, replace) fysize(25);

graph combine herringprice herringlandings, cols(1) imargin(b=0 t=0);

graph export ${my_images}/herring_price_quantity.tif, replace as(tif);
graph export ${my_images}/herring_price_quantity.png, replace as(png);






twoway (tsline pricemt2023  if `graph_subset', `graphopts' cmissing(n))  (tsline pricemt_yr2023 if  `graph_subset', `graphopts'), ytitle("Real (2023) Price per metric ton") tlabel(, format(%tmCCYY)) name(herringpriceR, replace) legend(off)  ttitle("");

graph combine herringpriceR herringlandings, cols(1) imargin(b=0 t=0);

graph export ${my_images}/herring_price_quantity.tif, replace as(tif);
graph export ${my_images}/herring_price_quantity.png, replace as(png);



tsset year month;



xtline frac_bait;

graph export ${my_images}/herring_fraction_bait.png, replace as(png);



