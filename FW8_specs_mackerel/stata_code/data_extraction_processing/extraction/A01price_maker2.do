pause on

#delimit ;

local prefix all_prices ;

tempfile gear_info;
local first 2006;
local last 2020;
/* S characteristics */
forvalues myy=`first'/`last'{;
	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
	clear;
	odbc load,  exec("select sum(spplndlb) as landings, sum(sppvalue) as value, nespp3, port, month, state, county, day, year from cfdbs.cfders`myy' 
		where spplndlb is not null   
		group by nespp3, port, month, state, county, day, year;") $oracle_cxn clear;
	gen dbyear= `myy';
	quietly save `new';
};
clear;

append using `NEWfiles';
	renvarlab, lower;
destring, replace;

	
gen date=mdy(month,day, year);
tempfile base;
save `base';

/* this is port level pricing */
collapse (sum) value landings, by(port date nespp3);
drop if date==. ;
gen price1=value/landings;
drop if landings<500;
drop if price1 ==0;
drop if price1>=25;
drop landings value;
label var price1 "port-day price";
compress;

save "${data_raw}/`prefix'1.dta", replace;

use `base', clear;
/* Create the county price dataset*/
collapse (sum) landings value, by(date state county nespp3);
drop if date==. ;
gen price2=value/landings;
drop if landings<500;
drop if price2 ==0;
drop if price2>=25;

drop landings value;
label var price2 "county-day price";
save "${data_raw}/`prefix'2.dta", replace;



/* Create state level prices */
use `base', clear;
collapse (sum) landings value, by(date state nespp3);
drop if date==. ;
gen price3=value/landings;
drop if landings<500;
drop if price3 ==0;
drop if price3>=25;

drop landings value;

label var price3 "state-day price";
save "${data_raw}/`prefix'3.dta", replace;




/* Create region level prices */
use `base', clear;
collapse (sum) landings value, by(date nespp3);
drop if date==. ;
gen price4=value/landings;
drop if landings<500;
drop if price4 ==0;
drop if price4>=25;

drop landings value;
save "${data_raw}/`prefix'4.dta", replace;

/* Create port-month prices */
use `base', clear;
collapse (sum) landings value, by(month year port nespp3);
gen price5=value/landings;
drop if landings<500;
drop if price5 ==0;
drop if price5>=25;

drop landings value;

label var price5 "port-month prices";
save "${data_raw}/`prefix'5.dta", replace;


/* Create county-month prices */

use `base', clear;
collapse (sum) landings value, by(month year state county nespp3);
gen price6=value/landings;
drop if landings<500;
drop if price6 ==0;
drop if price6>=25;

drop landings value;

label var price6 "monthly county price";
label data "Monthly County Level Prices";
save "${data_raw}/`prefix'6.dta", replace;



/* Create state-month prices */
use `base', clear;
collapse (sum) landings value, by(month year state nespp3);
gen price7=value/landings;
drop if landings<500;
drop landings value;
drop if price7 ==0;
drop if price7>=25;

label var price7 "monthly state price";
label data "Monthly State Level Prices";
save "${data_raw}/`prefix'7.dta", replace;



/* Create region-month prices */
use `base', clear;
collapse (sum) landings value, by(month year nespp3);
gen price8=value/landings;
drop if landings<500;
drop if price8 ==0;
drop if price8>=25;

drop landings value;

label var price8 "monthly region price";
label data "Monthly Region-wide prices";
save "${data_raw}/`prefix'8.dta", replace;

/* Create year-nespp3 prices */
use `base', clear;

collapse (sum) landings value, by(year nespp3);
gen price9=value/landings;
drop if landings<500;
drop if price9 ==0;
drop if price9>=25;

drop landings value;

label var price9 "yearly region price by species";

label data "yearly region price";
save "${data_raw}/`prefix'9.dta", replace;

/* Create year prices --hopefully everything matches at the MERGE9 level*/
use `base', clear;
collapse (sum) landings value, by(year);
gen price10=value/landings;
drop if landings<500;
drop if price10>=25;

drop landings value;

label var price10 "yearly region price";

label data "yearly region price all species";
save "${data_raw}/`prefix'10.dta", replace;

