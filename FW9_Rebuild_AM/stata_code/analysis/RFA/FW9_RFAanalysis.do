use $RFA_dataset, clear
/* first, lets get total fishery value by year */

 collapse (sum) value168 value212, by(year)

 list




use $RFA_dataset, clear


/* For FW9, we will only be affecting HRG ABCDE vessels. 
we want to flag all the firms that had at least 1 of these in the most recent year*/

/* STEP 1: Keep affiliate_id's that have at least one of the categorical variables in the keeplist ==1 in the most recent year*/


/* ALL permitted */
local keeplist HRG_A HRG_B HRG_C HRG_D HRG_E 


drop person*

/*Add up the number of herring permits help by a vp_num */
egen keep_flag=rowtotal(`keeplist')

/* zero out everything that is not the last year */
qui summ year
local maxy=`r(max)'
replace keep_flag=0 if year~=`maxy'

/* drop if the the affiliate did not have at least one of the permits */
bysort affiliate_id : egen kf2=total(keep_flag)
keep if kf2>=1
drop kf2

qui compress



/* how many firms */
/* generate an indicator for each firm-year */
egen ty=tag(affiliate_id year)
tab year if ty==1

/* how many small firms and large */
tab year small_business if ty==1

/* setup revenue for small and large firms */
/* in the last year, the large firms had 24.4M in revenue and the small had 1.49M */
bysort affiliate_id year: egen herring=total(value168)
bysort affiliate_id year: egen mackerel=total(value212)
gen squids=value801+value802
bysort affiliate_id year: egen squid=total(squids)
cap drop squids
bysort affiliate_id year: egen menhaden=total(value221)
gen other=affiliate_total-herring-mackerel-squid-menhaden

gen herring_frac=herring/affiliate_total
gen mackerel_frac=mackerel/affiliate_total


gen hm=herring+mackerel
gen hm_frac=hm/affiliate_total
replace affiliate_total=affiliate_total/1000000

bysort year: centile affiliate_total herring mackerel if ty==1 & small==1, centile(25 50 75)
bysort small year : summ affiliate_total herring mackerel if ty==1 

gen active=herring+mackerel
replace active=active>=1

/* histograms of dependence */
hist herring_frac if ty==1 & year==2017 & small==1, width(.05)
hist herring_frac if ty==1 & year==2018 & small==1, width(.05)
hist herring_frac if ty==1 & year==2019 & small==1, width(.05)

summ herring_frac mackerel_frac if ty==1 & year==2019 & small==1


centile herring_frac mackerel_frac if ty==1 & year==2019 & small==1 & active==1, centile(25 50 75) 




/* how much of the fishery is in the small firms */
preserve
gen permits=1
foreach var of varlist herring mackerel squid menhaden  other hm affiliate_total{
replace `var'=0 if ty==0
}

collapse (sum) herring mackerel squid menhaden  other hm affiliate_total ty permits, by(small active year)
format herring mackerel squid menhaden  other hm %12.0gc
list if active==1
restore

tempfile savepoint
save `savepoint', replace
/* revenue changes, in percentage terms relative 2019 and baseline*/
keep if ty==1
keep affiliate_id active year herring mackerel squid menhaden other affiliate_total small count_permits
gen baseline_herring=herring*(11571/13066)
gen adj_herring=baseline_herring*(1-.625)

gen baseline_affiliate_total=(affiliate_total*1000000)-herring+baseline_herring
replace baseline_affiliate_total=baseline_affiliate_total/1000000

gen adj_affiliate_total=(affiliate_total*1000000)-herring+adj_herring
replace adj_affiliate_total=adj_affiliate_total/1000000

gen pct_change=(baseline_affiliate_total-adj_affiliate_total)/baseline_affiliate_total
gen pct_change2019=(affiliate_total-adj_affiliate_total)/affiliate_total


order small affiliate_total adj_affiliate pct_change
sort small pct_change


export delimited small affiliate_total adj_affiliate_total pct_change pct_change2019 if active==1 & year==2019 using ${my_results}/RFApct_change.csv, replace











use `savepoint', replace


drop active
gen active=herring>=1


/* revenue changes, in percentage terms */
keep if ty==1
keep affiliate_id active year herring mackerel squid menhaden other affiliate_total small count_permits
gen baseline_herring=herring*(11571/13066)
gen adj_herring=baseline_herring*(1-.625)

gen baseline_affiliate_total=(affiliate_total*1000000)-herring+baseline_herring
replace baseline_affiliate_total=baseline_affiliate_total/1000000

gen adj_affiliate_total=(affiliate_total*1000000)-herring+adj_herring
replace adj_affiliate_total=adj_affiliate_total/1000000

gen pct_change=(baseline_affiliate_total-adj_affiliate_total)/baseline_affiliate_total
gen pct_change2019=(affiliate_total-adj_affiliate_total)/affiliate_total

order small affiliate_total adj_affiliate pct_change
sort small pct_change




export delimited small affiliate_total adj_affiliate_total pct_change pct_change2019 if active==1 & year==2019 using ${my_results}/RFA_hrg_only_pct_change.csv, replace






gen a2=herring+mackerel
/* large firms */
count  if year>=2019 & a2>=1 & small==0 & pct_change<=.02
count  if year>=2019 & a2>=1 & small==0 & pct_change>.02 & pct_change<=.10 

/* small firms */

count  if year>=2019 & a2>=1 & small==1 & pct_change<=.02

count  if year>=2019 & a2>=1 & small==1 & pct_change>.02 & pct_change<=.10 
count  if year>=2019 & a2>=1 & small==1 & pct_change>.10 & pct_change<=.25 
count  if year>=2019 & a2>=1 & small==1 & pct_change>.25 & pct_change<=.63 


count  if year>=2019 & a2>=1 & small==1 & pct_change2019<=.02

count  if year>=2019 & a2>=1 & small==1 & pct_change2019>.02 & pct_change2019<=.10 
count  if year>=2019 & a2>=1 & small==1 & pct_change2019>.10 & pct_change2019<=.25 
count  if year>=2019 & a2>=1 & small==1 & pct_change2019>.25 & pct_change2019<=.67 



