#delimit ;
global lbs_to_mt 2204.62;

/* ORACLE SQL IN UBUNTU using Stata's connectstring feature.*/

/* LOOPS OVER A QUERY from SOLE */

local first 2003;
local last 2020;

forvalues myy=`first'/`last'{;
	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
	clear;
	odbc load,  exec("SELECT year, month, nespp3, sum(sppvalue) as value, sum(spplndlb) as landings, utilcd FROM cfdbs.cfders`myy' 
		WHERE nespp3 in('168','221','727') AND spplndlb>0 group BY nespp3, year, month, utilcd;")  $oracle_cxn clear;
	gen dbyear= `myy';
	quietly save `new';
};
clear;
append using `NEWfiles';
	renvarlab, lower;
destring, replace;



gen mymonth=ym(year, month);
format mymonth %tm;
replace landings=landings/$lbs_to_mt;
label var landings "landings (mt)";
label var mymonth "month";



save "${data_intermediate}/monthly_util_herring.dta", replace;



/*





graph save price.gph, replace;
graph export price.tif, replace as(tif);
graph export price.png, replace as(png);

twoway (tsline landings if mymonth<=monthly("2011m10","YM")), ytitle("Landings (mt)");

*/



