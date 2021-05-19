#delimit ;
global lbs_to_mt 2204.62;
set scheme s2mono;
local data_in "${data_intermediate}/monthly_util_herring.dta";
use `data_in', replace;
keep if nespp3==168;
collapse (sum) landings value, by(year  nespp3);
keep if year<=2020;
tsset nespp3 year;

/* pull in deflators */

merge m:1 year using ${data_external}\deflatorsY.dta, keep(1 3);
assert _merge==3;
drop _merge;


gen value_realGDP=value/fGDPDEF_2019;

gen pricemt=value/landings;
gen pricemt_realGDP=value_realGDP/landings;

replace landings=landings/1000;
label var landings "(000 mt)";


gen price=pricemt/$lbs_to_mt;
gen price_real=pricemt_realGDP/$lbs_to_mt;

local species_pick nespp3==168 ;
local graph_subset year<=2019;

tsline pricemt  pricemt_realGDP if `species_pick' & `graph_subset', `graphopts' cmissing(n)  tlabel(2003(2)2019) tmtick(##2) ymtick(##4) ytitle("Annual Average Price per metric ton") legend(order(1 "Nominal" 2 "Real 2019 dollars")) ;
graph export ${my_images}/herring_prices_real.tif, replace as(tif);

replace value=value/1000000;
replace value_realGDP=value_realGDP/1000000;

label var value "Nominal Value $M";
label var value_realGDP "Real Value 2019$M";

tsline value  value_realGDP if `species_pick' & `graph_subset', `graphopts' cmissing(n) tlabel(2003(2)2019) tmtick(##2) ytitle("Millions of USD") legend(order(1 "Nominal value" 2 "Real Value 2019 dollars")) ;
graph export ${my_images}/herring_value_real.tif, replace as(tif);

/*
local graph_subset mymonth<=monthly("2020m07","YM") & mymonth>=monthly("2015m1", "YM");
local graph_subset mymonth<=monthly("2019m12","YM") & mymonth>=monthly("2015m1", "YM");
local graphopts tmtick(##6);




twoway (tsline pricemt  if `species_pick' & `graph_subset', `graphopts' cmissing(n))  (tsline pricemt_yr if `species_pick' & `graph_subset', `graphopts'), ytitle("Nominal Price per metric ton") tlabel(, format(%tmCCYY)) name(herringprice, replace) legend(off)  ttitle("");
twoway bar landings mymonth  if `species_pick' & `graph_subset', xmtick(##5) xlabel(, format(%tmCCYY)) xtitle("") name(herringlandings, replace) fysize(25);

graph combine herringprice herringlandings, cols(1) imargin(b=0 t=0);

graph export ${my_images}/herring_price_quantity.tif, replace as(tif);
graph export ${my_images}/herring_price_quantity.png, replace as(png);

*/
