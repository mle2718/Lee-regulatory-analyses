#delimit ;
global lbs_to_mt 2204.62;

local data_in "${data_intermediate}/monthly_util_herring.dta";
use `data_in', replace;
collapse (sum) landings value, by(year  nespp3);
tsset nespp3 year;

gen pricemt=value/landings;
label var landings "annual landings";
label var pricemt "monthly average price";
label var pricemt_yr "annual average price";
set scheme s2mono;
*drop if pricemt>=500;
drop if year>=2021;
tsfill;


*keep if  mymonth<=monthly("2020m7","YM") & mymonth>=monthly("2015m1", "YM");
local species_pick nespp3==168 ;
local graph_subset mymonth<=monthly("2020m12","YM") & mymonth>=monthly("2015m1", "YM");
local graph_subset mymonth<=monthly("2020m12","YM") & mymonth>=monthly("2015m1", "YM");
local graphopts tmtick(##6);


replace landings=landings/1000;
label var landings "(000 mt)";



gen price=pricemt/$lbs_to_mt;
gen price_yr=pricemt_yr/$lbs_to_mt;





*twoway (tsline pricemt  if `species_pick' & `graph_subset', `graphopts' cmissing(n))  (tsline pricemt_yr if `species_pick' & `graph_subset', `graphopts'), ytitle("Nominal Price per metric ton") tlabel(, format(%tmCCYY)) name(herringprice, replace) legend(off)  ttitle("");
*twoway bar landings mymonth  if `species_pick' & `graph_subset', xmtick(##5) xlabel(, format(%tmCCYY)) xtitle("") name(herringlandings, replace) fysize(25);

*graph combine herringprice herringlandings, cols(1) imargin(b=0 t=0);

*graph export ${my_images}/herring_price_quantity.tif, replace as(tif);
*graph export ${my_images}/herring_price_quantity.png, replace as(png);





