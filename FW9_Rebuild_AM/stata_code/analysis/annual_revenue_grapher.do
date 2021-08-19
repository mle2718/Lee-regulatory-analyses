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
local graph_subset year<=2020;

tsline pricemt  pricemt_realGDP if `species_pick' & `graph_subset', `graphopts' cmissing(n)  tlabel(2004(2)2020) tmtick(##2) ymtick(##4) ytitle("Annual Average Price per metric ton") legend(order(1 "Nominal" 2 "Real 2019 dollars")) ;
graph export ${my_images}/herring_prices_real.tif, replace as(tif);

replace value=value/1000000;
replace value_realGDP=value_realGDP/1000000;

label var value "Nominal Value $M";
label var value_realGDP "Real Value 2019$M";

tsline value  value_realGDP if `species_pick' & `graph_subset', `graphopts' cmissing(n) tlabel(2004(2)2020) tmtick(##2) ytitle("Millions of USD") legend(order(1 "Nominal value" 2 "Real Value 2019 dollars")) ;
graph export ${my_images}/herring_value_real.tif, replace as(tif);




/* get the equation for the linear fit */
reg pricemt_realGDP landings ;
// find the dependt variable
 local eq `"`e(depvar)' ="';
 
 // choose a nice display format for the constant
 local eq "`eq' `: di  %7.2f _b[_cons]'";
 
 // should we add or subtract
 local eq `"`eq' `=cond(_b[landings]>0, "+", "-")'"';
 
 // we already chose the plus or minus sign
 // so we need to strip a minus sign when it is there
 local eq `"`eq' `:di %6.2f abs(_b[landings])' landings"';
 
 // add the error term
 local eq `"`eq' + {&epsilon}"';

 
 tsset;
ivregress 2sls pricemt_realGDP (landings=l1.landings);

// find the dependt variable
 local eq2 `"`e(depvar)' ="';
 
 // choose a nice display format for the constant
 local eq2 "`eq2' `: di  %7.2f _b[_cons]'";
 
 // should we add or subtract
 local eq2 `"`eq2' `=cond(_b[landings]>0, "+", "-")'"';
 
 // we already chose the plus or minus sign
 // so we need to strip a minus sign when it is there
 local eq2 `"`eq2' `:di %6.2f abs(_b[landings])' landings"';
 
 // add the error term
 local eq2 `"`eq2' + {&epsilon}"';

 di "`eq2'";


 
 local liv_cons=_b[_cons];
 
 local liv_beta=_b[landings];
 
 

local scatter_opts  ylabel(0(200)1000) ymtick(##4)  xlabel(0(40)120) xmtick(##4)  ytitle("Price per Metric Ton (Real 2019)") xtitle("Herring Landings ('000s of mt)") legend(off);


twoway (function y=_b[_cons] + _b[landings]*x, range(0 120)) (scatter pricemt_realGDP landings if year<=2016, mlabel(year)) (scatter pricemt_realGDP landings if year>=2017, mlabel(year)), `scatter_opts' note("`eq2'");

graph export ${my_images}/herring_price_quantity_iv_scatter.png, replace as(png);

twoway ( lfit pricemt_realGDP landings,range(0 120)) (scatter pricemt_realGDP landings if year<=2016, mlabel(year)) (scatter pricemt_realGDP landings if year>=2017, mlabel(year)), `scatter_opts' note("`eq'");

graph export ${my_images}/herring_price_quantity_scatter.png, replace as(png);













/* plot the iv- regression fit */ 
 
gen lnpricemt_realGDP=ln(pricemt_realGDP);
gen lnlandings=ln(landings);


ivregress 2sls lnpricemt_realGDP (lnlandings=l1.lnlandings);





// find the dependt variable
 local eq3 `"`e(depvar)' ="';
 
 // choose a nice display format for the constant
 local eq3 "`eq3' `: di  %7.2f _b[_cons]'";
 
 // should we add or subtract
 local eq3 `"`eq3' `=cond(_b[lnlandings]>0, "+", "-")'"';
 
 // we already chose the plus or minus sign
 // so we need to strip a minus sign when it is there
 local eq3 `"`eq3' `:di %6.2f abs(_b[lnlandings])' lnlandings"';
 
 // add the error term
 local eq3 `"`eq3' + {&epsilon}"';

 
 local rmse=e(rmse);
 di "`eq3'";


 

local scatter_opts  ylabel(0(200)1000) ymtick(##4)  xlabel(0(40)120) xmtick(##4)   ytitle("Price per Metric Ton (Real 2019)") xtitle("Herring Landings ('000s of mt)");


twoway (function y=exp(_b[_cons] + _b[lnlandings]*ln(x) + (`rmse'^2)/2), range(5 120)) (scatter pricemt_realGDP landings if year<=2016, mlabel(year)) (scatter pricemt_realGDP landings if year>=2017, mlabel(year)), `scatter_opts' note("`eq3'") legend(off);

graph export ${my_images}/herring_price_quantity_lniv_scatter.png, replace as(png);




twoway (function y=exp(_b[_cons] + _b[lnlandings]*ln(x) + (`rmse'^2)/2), range(5 120)) (function y=`liv_cons' + `liv_beta'*x, range(5 120)) (scatter pricemt_realGDP landings if year<=2016, mlabel(year)) (scatter pricemt_realGDP landings if year>=2017, mlabel(year)), `scatter_opts' note("`eq3'" "`eq2'") legend(order(1 "log fit" 2 "linear fit"));

graph export ${my_images}/herring_price_quantity_iv_both_scatter.png, replace as(png);







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
