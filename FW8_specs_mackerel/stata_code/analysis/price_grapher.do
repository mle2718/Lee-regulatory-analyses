#delimit ;
global lbs_to_mt 2204.62;

local data_in "${data_intermediate}/monthly_util_herring.dta";
use `data_in', replace;
collapse (sum) landings value, by(year month mymonth nespp3);
tsset nespp3 mymonth;
bysort nespp3 year: egen vs=total(value);
bysort nespp3 year: egen ls=total(landings);

gen pricemt=value/landings;
gen pricemt_yr=vs/ls;
label var ls "annual landings";
label var pricemt "monthly average price";
label var pricemt_yr "annual average price";
set scheme s2mono;
*drop if pricemt>=500;
drop if year>=2020;
tsfill;


*keep if  mymonth<=monthly("2020m7","YM") & mymonth>=monthly("2015m1", "YM");
local species_pick nespp3==168 ;
local graph_subset mymonth<=monthly("2020m07","YM") & mymonth>=monthly("2015m1", "YM");
local graph_subset mymonth<=monthly("2019m12","YM") & mymonth>=monthly("2015m1", "YM");
local graphopts tmtick(##6);


replace landings=landings/1000;
label var landings "(000 mt)";

gen price=pricemt/$lbs_to_mt;
gen price_yr=pricemt_yr/$lbs_to_mt;

twoway (tsline pricemt  if `species_pick' & `graph_subset', `graphopts' cmissing(n))  (tsline pricemt_yr if `species_pick' & `graph_subset', `graphopts'), ytitle("Nominal Price per metric ton") tlabel(, format(%tmCCYY)) name(herringprice, replace) legend(off)  ttitle("");
twoway bar landings mymonth  if `species_pick' & `graph_subset', xmtick(##5) xlabel(, format(%tmCCYY)) xtitle("") name(herringlandings, replace) fysize(25);

graph combine herringprice herringlandings, cols(1) imargin(b=0 t=0);

graph export ${my_images}/herring_price_quantity.tif, replace as(tif);
graph export ${my_images}/herring_price_quantity.png, replace as(png);





local species_pick nespp3==221 ;
twoway (tsline pricemt  if `species_pick' & `graph_subset', `graphopts' cmissing(n))  (tsline pricemt_yr if `species_pick' & `graph_subset', `graphopts'), ytitle("Nominal Price per metric ton") tlabel(, format(%tmCCYY)) name(menhadenprices, replace) legend(off)  ttitle("");
twoway bar landings mymonth if `species_pick' & `graph_subset', xmtick(##5) xlabel(, format(%tmCCYY)) xtitle("") name(menhadenlandings, replace) fysize(25);

/*graph export ${my_images}/price.tif, replace as(tif);
graph export ${my_images}/price.png, replace as(png);

*/

graph combine menhadenprices menhadenlandings, cols(1) imargin(b=0 t=0);

graph export ${my_images}/menhaden_price_quantity.tif, replace as(tif);
graph export ${my_images}/menhaden_price_quantity.png, replace as(png);














/*
scatter pricemt landings;

graph box landings, over(month);

graph box pricemt, over(month);
*/
local species_pick nespp3==727;

twoway (tsline price  if `species_pick' & `graph_subset', `graphopts' cmissing(n))  (tsline price_yr if `species_pick' & `graph_subset', `graphopts'), ytitle("Nominal Price per pound") tlabel(, format(%tmCCYY)) name(lobsterp, replace) legend(off)  ttitle("");
twoway bar landings mymonth if `species_pick' & `graph_subset', xmtick(##5) xlabel(, format(%tmCCYY)) xtitle("") name(lobsterq, replace) fysize(25);

graph combine lobsterp lobsterq, cols(1) imargin(b=0 t=0);

graph export ${my_images}/lobster_price_quantity.tif, replace as(tif);
graph export ${my_images}/lobster_price_quantity.png, replace as(png);

