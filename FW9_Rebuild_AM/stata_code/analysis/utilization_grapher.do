#delimit ;
set scheme s2color;
pause on;
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

label define utils 0 "food/unknown" 234589 "feed, industrial,other" 7 "bait";
replace utilcd=234589 if inlist(utilcd,0,2,3,4,5,8,9,.);

collapse (sum) landings value, by(year nespp3 utilcd);
label var landings "landings (mt)";

label values utilcd utils;
replace landings=landings/1000;
reshape wide landings value, i(year nespp3) j(utilcd);
foreach var of varlist landings* value*{;
replace `var'=0 if `var'==.;
};


rename landings7 bait;
rename landings234589 other;

rename value7 bait_value;
rename value234589 other_value;


local graph_subset nespp3==168 & year<=2020;

graph bar bait other if `graph_subset',over(year, label(angle(45))) stack ytitle("herring landings(000mt)") legend(order(1 "bait" 2 "other") rows(1)) ylabel(0(50)250) ymtick(##4);
graph export ${my_images}/herring_utilization.tif, replace as(tif);
graph export ${my_images}/herring_utilization.png, replace as(png);
/*
*keep if  mymonth<=monthly("2020m7","YM") & mymonth>=monthly("2015m1", "YM");

local time_subset mymonth<=monthly("2020m7","YM") & mymonth>=monthly("2015m1", "YM");
local graphopts tmtick(##6);


replace landings=landings/1000;
label var landings "(000 mt)";
*/
local graph_subset nespp3==221 & year<=2020;


graph bar bait other if `graph_subset',over(year, label(angle(45))) stack ytitle("menhaden landings(000mt)") legend(order(1 "bait" 2 "other") rows(1))  ylabel(0(50)250)  ymtick(##4);
graph export ${my_images}/menhaden_utilization.tif, replace as(tif);
graph export ${my_images}/menhaden_utilization.png, replace as(png);



gen total=bait+other;
gen bait_frac=bait/total;
sort nespp3 year;
browse if nespp3==168;

pause;

keep if year>=2015 & year<=2020;
collapse (sum) bait total, by(nespp3);
gen bf=bait/total;
browse;
pause;
