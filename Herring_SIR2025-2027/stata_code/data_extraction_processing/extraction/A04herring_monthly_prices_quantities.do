#delimit ;
global lbs_to_mt 2204.62;

/* ORACLE SQL IN UBUNTU using Stata's connectstring feature.*/


global commercial_grab_start 2003;
global commercial_grab_end 2024;

clear;
odbc load,  exec("select sum(nvl(lndlb,0)) as landings,  sum(livlb) as livelnd, sum(nvl(value,0)) as value, year, month, itis_tsn, area_herr, dlr_utilcd from cams_land cl where 
		cl.year between $commercial_grab_start and $commercial_grab_end and
		itis_tsn in ('161722')
		group by year, month, itis_tsn, area_herr,dlr_utilcd;") $myNEFSC_USERS_conn ;	

gen source="cams_land";

tempfile t1;
save `t1',replace;


clear;

odbc load,  exec("select sum(nvl(lndlb,0)) as landings,  sum(livlb) as livelnd, sum(nvl(value,0)) as value, year, month, itis_tsn, area_herr,dlr_utilcd from cams_vtr_orphans co where 
		co.year between $commercial_grab_start and $commercial_grab_end and
		itis_tsn in ('161722')
		group by year, month, itis_tsn, area_herr,dlr_utilcd;") $myNEFSC_USERS_conn ;	

gen source="cams_vtr_orphans";
append using `t1';

replace value=. if value==0;
gen imputedPrice=value==.;

gen mymonth=ym(year, month);
format mymonth %tm;
gen landings_mt=landings/$lbs_to_mt;
label var landings "landings (mt)";
label var mymonth "month";

gen price_mt=value/landings_mt;

/* create a monthly fraction bait */
bysort source year month: egen tl=total(landings);
bysort source year month dlr_utilcd: egen tb=total(landings);
replace tb=. if dlr_utilcd~="7";
gen frac_bait=tb/tl;

bysort year month (frac_bait): replace frac_bait=frac_bait[1] if frac_bait==.;

destring dlr_utilcd, replace;
bysort mymonth: egen anyb=max(dlr_utilcd);
replace frac_bait=0 if anyb==0;

assert missing(frac_bait)==0;


drop  tb anyb;





/* fill in a monthly price for the VTR Orphans */
bysort year month: egen tv=total(value);
gen fill_price=tv/tl;
replace price_mt=fill_price if price_mt==.;
drop fill_price tv tl;
replace value=landings_mt*price_mt if value==.;

save "${data_intermediate}/monthly_util_herring.dta", replace;



/*



twoway (tsline landings if mymonth<=monthly("2011m10","YM")), ytitle("Landings (mt)");


graph save price.gph, replace;
graph export price.tif, replace as(tif);
graph export price.png, replace as(png);


*/



