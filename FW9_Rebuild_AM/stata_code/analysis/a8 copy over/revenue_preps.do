clear
macro drop _all
scalar drop _all
pause off
#delimit ;

cd "/home/mlee/Documents/Herring_PDT_work/Amendment8/round4";
quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do";

/*Screen the ABC vessels only */

clear;
	odbc load,  exec("select vp_num, plan, ap_year from permit.vps_fishery_ner  
	where plan='HRG' and cat in ('A','B','C','E') and ap_year>=2009 ;") conn("$mysole_conn") lower;

dups vp_num ap_year, drop terse;
drop _expand;
tempfile t1;
rename vp_num permit;
rename ap_year year;
keep permit year;
save `t1', replace;


/*assign a gear */
use extra.dta, clear;
tempfile t2;
bysort tripid (qtykept): keep if _n==_N;
keep tripid gearcode ;
save `t2', replace;









use "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_10192017/veslog_species_huge_10192017.dta" if dbyear>=2010 & tripid~=.;
drop year dbyear;
gen year=yofd(date);
merge m:1 permit year using `t1', keep(3) nogenerate;
merge m:1 tripid using `t2', keep(1 3);
drop LADAS-Nopermit_scal;
drop if _merge==1;

save "master_herring_dataset.dta", replace;

#delimit;
use "master_herring_dataset.dta", clear;

/* */
gen lumped_gear=gearcode;
replace lumped_gear="BT" if inlist(gearcode, "OTF", "OTO", "OTR", "OTS", "PTB", "OHS", "OTT");
replace lumped_gear="OTM" if inlist(gearcode, "OTM", "PTM");
replace lumped_gear="PUR" if inlist(gearcode, "PUR");
replace lumped_gear="OTHER" if inlist(lumped_gear, "BT", "OTM", "PUR", "OTHER")==0;

replace myspp=999 if inlist(myspp, 168, 221,212,801, 802 )==0;
replace myspp=801 if myspp==802;


egen tag_permit=tag(permit lumped_gear year myspp);
replace qtykept=qtykept/2204;
replace raw=raw/1000;
collapse (sum) qtykept raw_revenue tag_permit, by(lumped_gear year myspp);

reshape wide qtykept raw tag_permit, i(lumped year) j(myspp);
foreach var of varlist qtykept* raw*{;
	replace `var'=0 if `var'==.;
};

sort year lumped;
rename lumped gear;
/*
*/

foreach var of varlist qtykept* raw_revenue*{;
replace `var'=floor(`var');
};
tostring qtykept168 qtykept212 qtykept221 qtykept801 qtykept999, gen(qtykept168s qtykept212s qtykept221s  qtykept801s qtykept999s) format(%8.0gc) force;
tostring raw_revenue168 raw_revenue212 raw_revenue221 raw_revenue801 raw_revenue999, gen(raw_revenue168s raw_revenue212s raw_revenue221s raw_revenue801s raw_revenue999s) format(%8.0gc) force;

foreach myv of numlist 168 212 221 801 999{;
replace qtykept`myv's="(C)" if tag_permit`myv'<=2;
replace raw_revenue`myv's="(C)" if tag_permit`myv'<=2;
replace qtykept`myv's=" " if qtykept`myv'<=5;
replace raw_revenue`myv's=" " if raw_revenue`myv'<=5;
};

label var qtykept168s "herring (mt)";
label var raw_revenue168s "herring value (000s)";

label var qtykept212s "mackerel(mt)";
label var raw_revenue212s "mackerel value (000s)";

label var qtykept221s "menhaden (mt)";
label var raw_revenue221s "menhaden value (000s)";

label var qtykept801s "squid (mt)";
label var raw_revenue801s "squid value (000s)";

label var qtykept999s "other (mt)";
label var raw_revenue999s "other value (000s)";

sort year gear;
local replacer replace;

gen sortorder=0;
replace sortorder=1 if inlist(gear,"OTM");
replace sortorder=2 if inlist(gear,"PUR");
replace sortorder=3 if inlist(gear,"BT");
replace sortorder=4 if inlist(gear,"OTHER");

sort year sortorder;
order year gear *168* *212* *221* *801* *999*;
export excel year gear *s using "herring_A8_background.xlsx" if year<=2016, sheet("rev_and_qty") `replacer' firstrow(varlabels);
local replacer ;


/* vessel level dependences, by gear*/
#delimit;
use "master_herring_dataset.dta", clear;

gen lumped_gear=gearcode;
replace lumped_gear="BT" if inlist(gearcode, "OTF", "OTO", "OTR", "OTS", "PTB", "OHS", "OTT");
replace lumped_gear="OTM" if inlist(gearcode, "OTM", "PTM");
replace lumped_gear="PUR" if inlist(gearcode, "PUR");
replace lumped_gear="OTHER" if inlist(lumped_gear, "BT", "OTM", "PUR", "OTHER")==0;

replace myspp=999 if inlist(myspp, 168, 221,212,801, 802 )==0;
replace myspp=801 if myspp==802;



/*permit-gear-species revenue */
collapse (sum) raw_revenue, by(permit lumped_gear year myspp);
egen grouper=group(myspp year lumped);
egen tp=tag(permit lumped_gear year myspp);
/*
preserve;
keep grouper myspp year lumped_gear;
dups, drop terse;
drop _expand;
tempfile mykey;
save `mykey';
restore;
tsset permit grouper;
tsfill;
merge m:1 grouper using `mykey', update;
assert _merge>=3;
replace raw=0 if _merge~=3;
*/

collapse (sum) raw_revenue tp,  by(lumped_gear year myspp);

bysort lumped_gear year: egen tr=total(raw);
gen percentage=raw/tr;
drop tr raw;
reshape wide percentage tp, i(lumped_gear myspp) j(year);

foreach myv of numlist 2010 2011 2012 2013 2014 2015 2016 2017{;
replace percentage`myv'=0 if percentage`myv'==.;
replace percentage`myv'=floor(percentage`myv'*100);

tostring percentage`myv', gen(percentage`myv's) format(%3.0f) force;
*	replace percentage`myv's="<1" if percentage`myv'<=1;
*	replace percentage`myv's=">99" if percentage`myv'>=99;
	replace percentage`myv's="(C)" if tp`myv'<=2;
	replace percentage`myv's=" " if percentage`myv'<=1;

};
label define myspplab 168 "Herring" 212 "Mackerel" 221 "Menhaden" 801 "Squid" 999 "Other";

label values  myspp myspplab;


gen sortorder=0;
replace sortorder=1 if inlist(lumped_gear,"OTM");
replace sortorder=2 if inlist(lumped_gear,"PUR");
replace sortorder=3 if inlist(lumped_gear,"BT");
replace sortorder=4 if inlist(lumped_gear,"OTHER");


gen sort2=0;
replace sort2=1 if myspp==168;
replace sort2=2 if myspp==221;
replace sort2=3 if myspp==212;
replace sort2=4 if myspp==801;
replace sort2=5 if myspp==999;

sort sortorder sort2;
rename lumped gear;
order gear myspp;
rename myspp species;
drop *2017s;


export excel gear *s using "herring_A8_background.xlsx", sheet("dependence") `replacer' firstrow(varlabels);

/* classify permits into a gearcode, based on majority of herring revenues */
use "master_herring_dataset.dta", clear;

gen lumped_gear=gearcode;
replace lumped_gear="BT" if inlist(gearcode, "OTF", "OTO", "OTR", "OTS", "PTB", "OHS", "OTT");
replace lumped_gear="OTM" if inlist(gearcode, "OTM", "PTM");
replace lumped_gear="PUR" if inlist(gearcode, "PUR");
replace lumped_gear="OTHER" if inlist(lumped_gear, "BT", "OTM", "PUR", "OTHER")==0;

keep if myspp==168;



collapse (sum) raw, by(permit year lumped);
sort permit year raw;
bysort permit year  (raw): keep if _n==_N;
drop raw;
notes: I classified each permit-year into one of the four geartypes based on herring revenues;
save "herring_geartype_classifed.dta", replace;

#delimit;

clear;

tempfile nespp34;
odbc load, exec("select distinct sppnm, nespp3 from cfspp;") conn("$mysole_conn") lower;
destring, replace ;
renvarlab, lower ;
dups nespp3, drop  terse  ;
save `nespp34', replace ;
clear; 



#delimit;


/* top ten species*/
use "master_herring_dataset.dta", clear;

gen lumped_gear=gearcode;
replace lumped_gear="BT" if inlist(gearcode, "OTF", "OTO", "OTR", "OTS", "PTB", "OHS", "OTT");
replace lumped_gear="OTM" if inlist(gearcode, "OTM", "PTM");
replace lumped_gear="PUR" if inlist(gearcode, "PUR");
replace lumped_gear="OTHER" if inlist(lumped_gear, "BT", "OTM", "PUR", "OTHER")==0;


keep if year>=2012 & year<=2016;
egen tp=tag(permit lumped_gear myspp);



collapse (sum) qtykept raw tp, by(lumped myspp);
rename myspp nespp3;
merge m:1 nespp3 using `nespp34';

sort lumped qty;
bysort  lumped (qty): gen rank=_N-_n+1;

drop if _merge==2;
replace nespp3=999 if rank>=10;
replace sppnm="OTHER" if rank>=10;
collapse (sum) qty raw tp, by(nespp3 lumped sppnm);
bysort lumped (qty): gen rank=_N-_n+1;
sort lumped rank;

drop raw;
replace qty=floor(qty/(2204*5));

tostring qtykept, gen(qtykepts) format(%6.0fc) force;
	replace qtykepts="(C)" if tp<=2;
rename lumped gear;
label var qtykepts "average landings (mt)";
drop if qtykept<=1;

export excel gear sppnm qtykepts using "herring_A8_background.xlsx" if strmatch(gear,"BT"), sheet("BT_lands") `replacer' firstrow(varlabels);

export excel gear sppnm qtykepts using "herring_A8_background.xlsx" if strmatch(gear,"PUR"), sheet("PUR_lands") `replacer' firstrow(varlabels);

export excel gear sppnm qtykepts using "herring_A8_background.xlsx" if strmatch(gear,"OTM"), sheet("OTM_lands") `replacer' firstrow(varlabels);

export excel gear sppnm qtykepts using "herring_A8_background.xlsx" if strmatch(gear,"OTHER"), sheet("other_lands") `replacer' firstrow(varlabels);

putexcel set "herring_A8_background.xlsx", sheet("BT_lands") modify;
putexcel A12 = "Average Landings (mt) from 2012-2016 for the top 10 species. Herring A,B, C, and E permits fishing bottomtrawl gear";


putexcel set "herring_A8_background.xlsx", sheet("PUR_lands") modify;
putexcel A12 = "Average Landings (mt) from 2012-2016 for the top species. Herring A,B, C, and E permits fishing purse seine gear";



putexcel set "herring_A8_background.xlsx", sheet("OTM_lands") modify;
putexcel A12 = "Average Landings (mt) from 2012-2016 for the top 10 species. Herring A,B, C, and E permits fishing midwater trawl gear";


putexcel set "herring_A8_background.xlsx", sheet("other_lands") modify;
putexcel A12 = "Average Landings (mt) from 2012-2016 for the top species. Herring A,B, C, and E permits fishing other gear";

putexcel close;

