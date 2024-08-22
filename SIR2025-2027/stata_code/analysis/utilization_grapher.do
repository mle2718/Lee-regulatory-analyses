#delimit ;
set scheme s2color;
local data_in "${data_intermediate}/monthly_util_herring.dta";
use `data_in', replace;
/*
The utilization code:
 0=food fish or unknown;
 2=aquaculture; 
 3=canned pet food (1984+); 
 4=Biomedical (2002+); 
 5=animal food (1984+); 
 7=bait;
 8=industrial, other (2002+); 
 9=industrial, reduction.*/

 rename dlr_utilcd utilcd ;
label define utils 0 "food/unknown" 234589 "feed, industrial,other" 7 "bait";
replace utilcd=234589 if inlist(utilcd,0,2,3,4,5,8,9,.);

collapse (sum) landings_mt value, by(year itis_tsn utilcd);
label var landings_mt "landings (mt)";

label values utilcd utils;
replace landings=landings/1000;
reshape wide landings_mt value, i(year itis_tsn) j(utilcd);
foreach var of varlist landings* value*{;
replace `var'=0 if `var'==.;
};


rename landings_mt7 bait;
rename landings_mt234589 other;

rename value7 bait_value;
rename value234589 other_value;


local graph_subset year<=2023;

graph bar bait other if `graph_subset',over(year, label(angle(45))) stack ytitle("herring landings(000mt)") legend(order(1 "bait" 2 "other") rows(1)) ymtick(##4);
graph export ${my_images}/herring_utilization.tif, replace as(tif);
graph export ${my_images}/herring_utilization.png, replace as(png);


gen total=bait+other;
gen bait_frac=bait/total;
sort itis_tsn year;

pause;

keep if year>=2015 & year<=2023;
collapse (sum) bait total, by(itis_tsn);
gen bf=bait/total;
browse;
pause;
