#delimit ;
global lbs_to_mt 2204.62;
set scheme s2mono;
local data_in "${data_intermediate}/monthly_util_herring.dta";
use `data_in', replace;
collapse (sum) landings_mt value, by(year );
keep if year<=2023;
tsset year;
replace value=. if value==0;

/* pull in deflators */

merge m:1 year using ${data_external}\deflatorsY.dta, keep(1 3);
assert _merge==3;
drop _merge;


gen value_realGDP=value/fGDPDEF_2023;

gen pricemt=value/landings_mt;
gen pricemt_realGDP=value_realGDP/landings_mt;


replace landings_mt=landings_mt/1000;
label var landings_mt "landings 000s of mt";


local graph_subset year<=2023;

replace value=value/1000000;
replace value_realGDP=value_realGDP/1000000;

label var value_realGDP "Average Annual Value (2023M)";

label var pricemt "Average Annual Price per mt (nominal)";
label var pricemt_realGDP "Average Annual Price per mt (2023)";
label var pricemt_realGDP "Average Annual Price per pound (2023)";


local graphopts tmtick(##6);
local graph_subset year<=2024 & year>=2009;


tsline pricemt  pricemt_realGDP if `graph_subset', `graphopts' cmissing(n)  tlabel(2009(2)2024) tmtick(##2) ymtick(##4) ytitle("Annual Average Price per metric ton") legend(order(1 "Nominal" 2 "Real 2023 dollars")) ;
graph export ${my_images}/herring_prices_real.tif, replace as(tif);


label var value "Nominal Value $M";
label var value_realGDP "Real Value 2023$M";

tsline value  value_realGDP if `graph_subset', `graphopts' cmissing(n) tlabel(2009(2)2024) tmtick(##2) ytitle("Millions of USD") legend(order(1 "Nominal value" 2 "Real Value 2023 dollars")) ;
graph export ${my_images}/herring_value_real.tif, replace as(tif);


sort year;

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
 
 

local scatter_opts  ylabel(0(200)1000) ymtick(##4)  xlabel(0(40)120) xmtick(##4)  ytitle("Price per Metric Ton (Real 2023)") xtitle("Herring Landings ('000s of mt)") legend(off);


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


 

local scatter_opts  ylabel(0(200)1000) ymtick(##4)  xlabel(0(40)120) xmtick(##4)   ytitle("Price per Metric Ton (Real 2023)") xtitle("Herring Landings ('000s of mt)");


twoway (function y=exp(_b[_cons] + _b[lnlandings]*ln(x) + (`rmse'^2)/2), range(5 120)) (scatter pricemt_realGDP landings if year<=2016, mlabel(year)) (scatter pricemt_realGDP landings if year>=2017, mlabel(year)), `scatter_opts' note("`eq3'") legend(off);

graph export ${my_images}/herring_price_quantity_lniv_scatter.png, replace as(png);




twoway (function y=exp(_b[_cons] + _b[lnlandings]*ln(x) + (`rmse'^2)/2), range(5 120)) (function y=`liv_cons' + `liv_beta'*x, range(5 120)) (scatter pricemt_realGDP landings if year<=2016, mlabel(year)) (scatter pricemt_realGDP landings if year>=2017, mlabel(year)), `scatter_opts' note("`eq3'" "`eq2'") legend(order(1 "log fit" 2 "linear fit"));

graph export ${my_images}/herring_price_quantity_iv_both_scatter.png, replace as(png);





*/
