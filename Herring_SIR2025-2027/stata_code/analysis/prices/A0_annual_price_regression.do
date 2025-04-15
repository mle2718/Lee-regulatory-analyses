#delimit ;
global lbs_to_mt 2204.62;
set scheme s2mono;

local data_in "${data_intermediate}/monthly_util_herring.dta";
use `data_in', replace;
collapse (sum) landings_mt value, by(year);
keep if year<=2023;
tsset year;

/* pull in deflators */

merge m:1 year using ${data_external}\deflatorsY.dta, keep(1 3);
assert _merge==3;
drop _merge;


gen value_realGDP=value/fGDPDEF_2023;

gen pricemt=value/landings_mt;
gen pricemt_realGDP=value_realGDP/landings_mt;
label var pricemt_realGDP "annual average Real (2023) price";

replace landings=landings/1000;
label var landings "(000 mt)";

gen price=pricemt/$lbs_to_mt;
gen price_real=pricemt_realGDP/$lbs_to_mt;

local graph_subset year<=2024;

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

twoway (scatter pricemt_realGDP yhat_log_iv, mlabel(year)) (function y=x, range(200 1000)), legend(off) ytitle("Price") xtitle("Predicted Price") title("Log-Log IV");


local saving_opts style(tex) replace;
local header_opts mlabels("IV" "OLS" "Log-Log IV" "Log-Log") collabels(none) nonumbers ;

esttab linear_2sls linear_ols log_2sls  log_log using ${my_tables}/Yregression_results2023.tex,  b se compress  r2 label `header_opts' `saving_opts' ;



