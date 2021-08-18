/* Code to describe impacts on small and large for FW9 */


version 16.1
clear
set scheme s2color
global vintage_string 2021_08_16

use $RFA_dataset, clear

/* For FW9, we will affecting HRG ABCDE vessels. 
we want to flag all the firms that had at least 1 of these in the most recent year

You might want to use 

	local keeplist HRG_A HRG_B HRG_C HRG_E 

perhaps combined with the filter in STEP 2. 

Do we want to filter on just "active" in 2020 to match the entities description? Or just leave it the way it is?

*/









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
drop kf2 keep_flag

qui compress


	
/*Screen for just firms active in herring in the last year
 STEP 2: Keep affiliate_id's that have at least $1 of herring revenue in the most recent year 
gen h_temp=0
replace h_temp=value168 if year==`maxy'
bysort affiliate_id : egen kf2=total(h_temp)
keep if kf2>=1
drop kf2 h_temp
*/



/*Screen for just firms active in herring in any of the last three years
 STEP 2: Keep affiliate_id's that have any herring revenue in the last three years
gen h_temp=0
replace h_temp=value168
bysort affiliate_id : egen kf2=total(h_temp)
keep if kf2>=1
drop kf2 h_temp
*/




/* how many firms */
/* generate an indicator for each firm-year */
egen ty=tag(affiliate_id year)
tab year if ty==1

/* how many small firms and large */
tab year small_business if ty==1

/* setup revenue for small and large firms */
bysort affiliate_id year: egen herring=total(value168)
bysort affiliate_id year: egen mackerel=total(value212)
gen squids=value801+value802
bysort affiliate_id year: egen squid=total(squids)
cap drop squids
bysort affiliate_id year: egen menhaden=total(value221)
gen other=affiliate_total-herring-mackerel-squid-menhaden


/* I think here-ish is what i need to do 
1. Compute each firms's fraction of the herring fishery. I will do this based on the 2018-2020 average. Just summ up the total fishery revenue and then sum up each affiliate_id's herring revenue.
2.  Apply this fraction to the trajectory of landings.
	Kind of complicated, can I make do with the average, or do I need to do each replicates? I think each replicate.

3.  Compute the "adjusted" herring revenues.
4.  Compute adjusted total revenues.
5.  Need to characterize the 'distributions' or movements, particularly for the small firms.
*/
/* STEP 1  - compute each firms fraction of the herring fishery.  Also retain total revenue and herring revenue */
keep if ty==1

/* compute the fraction of the total fishery for each affiliate, averaged of the trailing three years */
keep affiliate_id year herring mackerel squid menhaden other affiliate_total small count_permits

egen th=total(herring)
bysort affiliate_id: egen affiliate_herring=total(herring)
gen affiliate_fraction_herring=affiliate_herring/th

bysort affiliate_id: egen affiliate_rev=mean(affiliate_total)

gen non_herring=affiliate_total-herring

bysort affiliate_id: egen affiliate_nonherring=mean(non_herring)

notes affiliate_herring: Herring revenue for the firm, averaged over the trailing three years
notes affiliate_nonherring: Non-herring revenue for the firm, averaged over the trailing three years
notes affiliate_rev: Revenue for the firm, averaged over the trailing three years

notes small_business: Indicator for small (=1) or large(=0) firm as defined by SBA.

notes count_permits: Number of vessels owned by the firm.
notes affiliate_id: Identifier for a firm.
notes affiliate_fraction: Firm's fraction of aggregate herring landings 

/* keep just 1 obs per firm */
keep if year==2020
bysort affiliate_id: assert _N==1
gsort - affiliate_fraction_herring
egen cdf=sum( affiliate_fraction_herring)



keep year affiliate_id count_permits small_business affiliate_herring affiliate_nonherring affiliate_rev  affiliate_fraction_herring

/* 1222 firms: 9 large and 1213 small*/
expand 13
sort affiliate_id year

by affiliate_id: egen myy=seq(), from(2020) to(2032)
drop year
rename myy year











/* Can't just merge all 8 scenarios, 100000 replicates, 13 years : 104M observations per firm. That's ~12B obs. */
/* maybe just get the yearly averages, p25 and p75 and use those? */

joinby year using "${data_main}/revenue_yearly_stats_${vintage_string}.dta"

/* verify 1 row per firm, year, and scenario */
bysort affiliate_id year full_filename: assert _N==1


sort shortname full_filename affiliate_id year

/* compute adjusted herring revenues and adjusted total revenues */
gen adjusted_herring=affiliate_fraction_herring*mean_revenue
gen adjusted_revenue=adjusted_herring + affiliate_nonherring

gen difference=affiliate_rev - adjusted_revenue
sort year difference
browse if difference~=0

/* note, some firms have no revenue */
gen pct_diff=difference/affiliate_rev

order affiliate_rev adjusted_revenue pct_diff

browse if pct==.








/*
gen baseline_herring=herring*(11571/13066)
gen adj_herring=baseline_herring*(1-.625)

gen baseline_affiliate_total=(affiliate_total*1000000)-herring+baseline_herring
replace baseline_affiliate_total=baseline_affiliate_total/1000000

gen adj_affiliate_total=(affiliate_total*1000000)-herring+adj_herring
replace adj_affiliate_total=adj_affiliate_total/1000000

gen pct_change=(baseline_affiliate_total-adj_affiliate_total)/baseline_affiliate_total
gen pct_change`maxy'=(affiliate_total-adj_affiliate_total)/affiliate_total


order small affiliate_total adj_affiliate pct_change
sort small pct_change

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
gen pct_change`maxy'=(affiliate_total-adj_affiliate_total)/affiliate_total

order small affiliate_total adj_affiliate pct_change
sort small pct_change




export delimited small affiliate_total adj_affiliate_total pct_change pct_change`maxy' if active==1 & year==`maxy' using ${my_results}/RFA_hrg_only_pct_change.csv, replace






gen a2=herring+mackerel
/* large firms */
count  if year>=`maxy' & a2>=1 & small==0 & pct_change<=.02
count  if year>=`maxy' & a2>=1 & small==0 & pct_change>.02 & pct_change<=.10 

/* small firms */

count  if year>=`maxy' & a2>=1 & small==1 & pct_change<=.02

count  if year>=`maxy' & a2>=1 & small==1 & pct_change>.02 & pct_change<=.10 
count  if year>=`maxy' & a2>=1 & small==1 & pct_change>.10 & pct_change<=.25 
count  if year>=`maxy' & a2>=1 & small==1 & pct_change>.25 & pct_change<=.63 


count  if year>=`maxy' & a2>=1 & small==1 & pct_change`maxy'<=.02

count  if year>=`maxy' & a2>=1 & small==1 & pct_change`maxy'>.02 & pct_change`maxy'<=.10 
count  if year>=`maxy' & a2>=1 & small==1 & pct_change`maxy'>.10 & pct_change`maxy'<=.25 
count  if year>=`maxy' & a2>=1 & small==1 & pct_change`maxy'>.25 & pct_change`maxy'<=.67 


*/
