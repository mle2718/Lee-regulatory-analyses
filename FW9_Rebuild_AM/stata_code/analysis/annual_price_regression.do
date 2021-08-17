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

replace value=value/1000000;
replace value_realGDP=value_realGDP/1000000;

label var value "Nominal Value $M";
label var value_realGDP "Real Value 2019$M";

tsset;


gen lnpricemt_realGDP=ln(pricemt_realGDP);
gen lnlandings=ln(landings);

label var lnlandings "log landings";
label var landings "landings (000 mt)";

/* Linear*/
reg pricemt_realGDP landings ;
est store linear_ols;
predict yhat, xb;

ivregress 2sls pricemt_realGDP (landings=l1.landings), first;
est store linear_2sls;
predict yhat_iv, xb;



/* Log-log */
reg lnpricemt_realGDP lnlandings ;
est store log_log;

predict yhat_log, xb;
replace yhat_log=exp(yhat_log)*exp(e(rmse)^2/2);

ivregress 2sls lnpricemt_realGDP (lnlandings=l1.lnlandings), first;
est store log_2sls;

predict yhat_log_iv, xb;
replace yhat_log_iv=exp(yhat_log_iv)*exp(e(rmse)^2/2);

twoway (scatter pricemt_realGDP yhat_log_iv, mlabel(year)) (function y=x, range(200 800)), legend(off) ytitle("Price") xtitle("Predicted Price") title("Log-Log IV");


local saving_opts replace style(tex) ;
local header_opts mlabels("IV" "OLS" "Log-Log IV" "Log-Log") collabels(none) nonumbers ;

esttab linear_2sls linear_ols log_2sls  log_log using ${my_tables}/regression_results.tex,  b se compress  r2 label `header_opts' `saving_opts' ;



/* collect the estimation results into a table ;
local cell_opts cells(b(star fmt(3)) se(par fmt(2))) label varlabels(_cons Constant);
local add_stats  stats(r2 N,fmt(%9.3f %9.0g));
local header_opts mlabels("IV" "OLS" "Log-Log IV" "Log-Log"")  collabels(none);
estout linear_ols linear_2sls log_log log_2sls,  `cell_opts' `add_stats'   `header_opts' legend;

estout linear_2sls linear_ols  log_log log_2sls  ,  `cell_opts' `add_stats'   `header_opts' legend replace style(tex);
*/
