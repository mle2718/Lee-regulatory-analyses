#delimit ;
global lbs_to_mt 2204.62;

local data_in "${data_intermediate}/monthly_util_herring.dta";
use `data_in', replace;
keep if nespp3==168;
keep if year>=2017 & year<=2019;

collapse (sum) landings value, by(year  nespp3);
tsset nespp3 year;

/* pull in deflators */

merge m:1 year using ${data_external}\deflatorsY.dta, keep(1 3);
gen value_realGDP=value/fGDPDEF_2019;

gen pricemt_realGDP=value_realGDP/landings;
keep if year==2019;
collapse (sum) landings value value_realGDP, by(nespp3);


gen pricemt=value/landings;
gen pricemt_realGDP=value_realGDP/landings;

replace landings=landings/1000;
label var landings "(000 mt)";


gen price=pricemt/$lbs_to_mt;
gen price_real=pricemt_realGDP/$lbs_to_mt;

/* yearly averages */
replace value=value/1000000;
replace value=value/3;
label var value "Average Annual Value (M) nominal";

replace value_realGDP=value_realGDP/1000000;
replace value_realGDP=value_realGDP/3;

label var value_realGDP "Average Annual Value (2019M)";

label var pricemt "Average Annual Price per mt (nominal)";
label var pricemt_realGDP "Average Annual Price per mt (2019)";
label var price "Average Annual Price per pound(nominal)";
label var price_real "Average Annual Price per pound (2019)";

/* predicted prices are
.646 L.price -1.194 Quantity  +217.8 
lnp=.666 L.lnp - .395 lnQ + 6.423*/


global quant2020 16.131;
global quant2021 4.923;
global quant2022 4.207;

gen price2020=.646*pricemt_real +217.8 - 1.194*$quant2020;

gen price2021=.646*price2020 +217.8 - 1.194*$quant2021;
gen price2022=.646*price2021 +217.8 - 1.194*$quant2022;




