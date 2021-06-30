


#delimit ;

tempfile gear_info;
local first 2015;
local last 2020;

clear;
/* make a table of nespp3 */
tempfile nespp34;
odbc load, exec("select distinct nespp3, sppcode from vlsppsyn;") $oracle_cxn;   
destring, replace ;
renvarlab, lower ;
duplicates drop (sppcode), force  ;
save `nespp34', replace ;
clear; 



/* G characteristics 
I get the gear characteristics corresponding to the distinct GEARID's that caught herring*/
forvalues myy=`first'/`last'{;
	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
	clear;
	odbc load,  exec("select to_char(g.tripid) as tripid, g.carea, g.gearid, g.gearcode, g.clatdeg, g.clatmin, g.clatsec, g.clondeg, g.clonmin, g.clonsec from vtr.veslog`myy'g g
    where g.gearid in 
      (select distinct s.gearid from vtr.veslog`myy's s where s.sppcode='HERR' and s.qtykept>=1);") $oracle_cxn clear;
	gen dbyear= `myy';
	quietly save `new';
};
clear;
append using `NEWfiles';
	renvarlab, lower;
destring, replace;

foreach var of varlist clatdeg-clonsec{;
replace `var'=0 if `var'==.;
};

gen lat=clatdeg+clatmin/60+clatsec/3600;
gen lon=-1*(clondeg+clonmin/60+clonsec/3600);

drop clatdeg-clonsec;
save `gear_info', replace;

/* S characteristics 
I get the total catch (kept + discard) of herring, grouped by GEARID */

forvalues myy=`first'/`last'{;
	tempfile new2;
	local NEWfiles2 `"`NEWfiles2'"`new2'" "'  ;
	clear;
	odbc load,  exec("select to_char(s.tripid) as tripid, s.gearid, s.dealnum, s.sppcode, sum(nvl(s.qtykept,0)) as kept, sum(nvl(s.qtydisc,0)) as discard from vtr.veslog`myy's s
		where s.gearid in 
      (select distinct s.gearid from vtr.veslog`myy's s where s.sppcode='HERR'and s.qtykept>=1) group by to_char(s.tripid), s.dealnum,s.gearid, s.sppcode;") $oracle_cxn clear;
	gen dbyear= `myy';
	quietly save `new2';
};
clear;
append using `NEWfiles2';
	renvarlab, lower;
destring, replace;
merge m:1 tripid gearid dbyear using `gear_info';
assert _merge==3;
drop _merge;
save `gear_info', replace;


/* T characteristics */
forvalues myy=`first'/`last'{;
	tempfile newt;
	local NEWfilest `"`NEWfilest'"`newt'" "'  ;
	clear;
	odbc load,  exec("select distinct to_char(t.tripid) as tripid, t.permit, t.portlnd1, t.state1, t.port, t.datelnd1 from vtr.veslog`myy't t 
		where t.tripid in (
		select distinct s.tripid from vtr.veslog`myy's s where s.sppcode='HERR' and s.qtykept>=1);") $oracle_cxn clear;
	gen dbyear= `myy';
	quietly save `newt';
};
clear;
append using `NEWfilest';
	renvarlab, lower;
destring, replace;

merge 1:m tripid dbyear using `gear_info';
assert _merge==3;
drop _merge;

notes: Need to resolve which VTR gears.  Need to resolve zero landings and zero discards.;
notes: Need to resolve Carrier gear (CAR).;
gen date=dofc(datelnd1);
format date %td;

gen state=floor(port/10000);
gen county=mod(port,100);
gen year=year(date);
gen month=month(date);

drop if kept==0 & discard==0;
drop if gearcode=="CAR";
save "${data_raw}/herring_from_vtr3.dta", replace;

merge m:1 sppcode using `nespp34', keep(1 3) ;
drop if sppcode=="WHKNS";
assert _merge==3;
drop _merge;

/* merge prices in here */
local prefix all_prices ;
merge m:1 port date nespp3 using "${data_raw}/`prefix'1.dta", keep (1 3) nogenerate ;

merge m:1 date state county nespp3 using "${data_raw}/`prefix'2.dta", keep (1 3) nogenerate ;
replace price1=price2 if price1==.;

merge m:1 date state nespp3 using "${data_raw}/`prefix'3.dta", keep (1 3) nogenerate ;
replace price1=price3 if price1==.;

merge m:1 date nespp3 using "${data_raw}/`prefix'4.dta", keep (1 3) nogenerate ;
replace price1=price4 if price1==.;

merge m:1 month year port nespp3 using "${data_raw}/`prefix'5.dta", keep (1 3) nogenerate ;
replace price1=price5 if price1==.;

merge m:1 month year state county nespp3 using "${data_raw}/`prefix'6.dta", keep (1 3) nogenerate ;
replace price1=price6 if price1==.;

merge m:1 month year state nespp3 using "${data_raw}/`prefix'7.dta", keep (1 3) nogenerate ;
replace price1=price7 if price1==.;

merge m:1 month year nespp3 using  "${data_raw}/`prefix'8.dta", keep (1 3) nogenerate ;
replace price1=price8 if price1==.;

merge m:1 year nespp3 using  "${data_raw}/`prefix'9.dta", keep (1 3) nogenerate ;
replace price1=price9 if price1==.;

merge m:1 year using  "${data_raw}/`prefix'10.dta", keep (1 3) nogenerate ;
replace price1=price10 if price1==.;


drop price2-price10;
gen revenue=price1*kept;
drop state county month year dbyear;

gen year=year(dofc(datelnd1));


*notes: This file created by "extracting_loop_herring_vtr2.do";
*save "$outputdir/herring_from_vtr3.dta", replace;

merge m:1 permit year using "${data_raw}/hrg_permits.dta";
drop if _merge==2;
drop if year<`first';
drop if year>`last';

drop if kept==0;
drop if cat=="";


drop _merge;
sort tripid gearid permit year lat lon, stable;

egen my_id=group(tripid gearid permit year lat lon);
order my_id;
compress;
rename cat category;

save "${data_raw}/herring_from_vtr2.dta", replace;

keep my_id lat lon;
duplicates drop my_id, force;

export delimited my_id lat lon using "${data_intermediate}/export_herring_lat_lon2.csv" if lat~=0 & lon~=0, delimit(",") replace;



/* use ARC to spatial join */






/* Count up the active vessels in each category 
collapse (sum) kept, by(permit year HRG_A-HRG_E);
tab year if HRG_A==1;
tab year if HRG_B==1 & HRG_C==1;
tab year if HRG_B==0 & HRG_C==1;
tab year if HRG_B==1 | HRG_C==1;

tab year if HRG_D;*/
