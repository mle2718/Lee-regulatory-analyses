
#delimit ;

clear;
/* Loop over the years */
local first 2006;
local last 2020;
forvalues myy=`first'/`last'{;
	clear;
	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
odbc load,  exec("select vp_num, max(ap_num) as ap_num, plan, cat from permit.vps_fishery_ner 
		where plan='HRG' and trunc(start_date,'DD')>= to_date('01-01-`myy'','MM-DD-YYYY') 
		and trunc(start_date,'DD') <=trunc(end_date,'DD') and trunc(start_date,'DD')<= to_date('12-31-`myy'','MM-DD-YYYY')
	group by vp_num, plan, cat;") $oracle_cxn;
	gen year=`myy';
	quietly save `new';
};

clear;
append using `NEWfiles';
	renvarlab, lower;
destring, replace;
drop ap_num;

gen str6 plancat=plan+"_"+cat;
drop plan cat;
gen ppp=1;
reshape wide ppp, i(vp year) j(plancat) string;
rename vp_num permit;

quietly foreach var of varlist ppp*{;
	replace `var'=0 if `var'==.;
	label var `var' ;
};
renvars ppp*, predrop(3);

/*notes: This file created by $codedir/permits.do";*/


/* Count up active permits by category and year */
tab year if HRG_A==1;
tab year if HRG_B==1 & HRG_C==1;
tab year if HRG_B==1 | HRG_C==1;

tab year if HRG_B==0 & HRG_C==1;
tab year if HRG_D;

gen cat="A" if HRG_A==1;
replace cat="B" if HRG_B==1;
replace cat="C" if HRG_C==1;
replace cat="D" if HRG_D==1;
replace cat="E" if HRG_E==1;


replace cat="AB" if HRG_A==1 & HRG_B==1;
replace cat="AC" if HRG_A==1 & HRG_C==1;
replace cat="AD" if HRG_A==1 & HRG_D==1;
replace cat="AE" if HRG_A==1 & HRG_E==1;

replace cat="BC" if HRG_B==1 & HRG_C==1;
replace cat="BD" if HRG_B==1 & HRG_D==1;
replace cat="BE" if HRG_B==1 & HRG_E==1;

replace cat="CD" if HRG_C==1 & HRG_D==1;
replace cat="CE" if HRG_C==1 & HRG_E==1;
replace cat="DE" if HRG_D==1 & HRG_E==1;


replace cat="ABC" if HRG_A==1 & HRG_B==1 & HRG_C==1;
replace cat="ABD" if HRG_A==1 & HRG_B==1 & HRG_D==1;
replace cat="ABE" if HRG_A==1 & HRG_B==1 & HRG_E==1;

replace cat="ACD" if HRG_A==1 & HRG_C==1 & HRG_D==1;
replace cat="ACE" if HRG_A==1 & HRG_C==1 & HRG_E==1;
replace cat="ADE" if HRG_A==1 & HRG_D==1 & HRG_E==1;


replace cat="BCD" if HRG_B==1 & HRG_C==1 & HRG_D==1;
replace cat="BCE" if HRG_B==1 & HRG_C==1 & HRG_E==1;
replace cat="BDE" if HRG_B==1 & HRG_D==1 & HRG_E==1;

replace cat="CDE" if HRG_C==1 & HRG_D==1 & HRG_E==1;


drop HRG_A-HRG_E;
sort permit year;
order permit year cat;
bysort permit year: assert _N==1;
save "${data_raw}/hrg_permits.dta", replace; 



use "${data_raw}/hrg_permits.dta", replace; 


