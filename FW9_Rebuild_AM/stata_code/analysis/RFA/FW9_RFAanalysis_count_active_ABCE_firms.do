use $RFA_dataset, clear
/* first, lets get total fishery value by year */

 collapse (sum) value168 value212, by(year)

 list




use $RFA_dataset, clear

drop person*

/* For FW9, we will only be affecting HRG ABCDE vessels. 
we want to flag all the firms that had at least 1 of these in the most recent year*/

/* STEP 1: Keep affiliate_id's that have at least one of the categorical variables in the keeplist ==1 in the most recent year*/


/* ABCE permitted */
local keeplist HRG_A HRG_B HRG_C HRG_E 



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

/* STEP 2: Keep affiliate_id's that have at least $1 of herring revenue in the most recent year */
gen h_temp=0
replace h_temp=value168 if year==`maxy'
bysort affiliate_id : egen kf2=total(h_temp)
keep if kf2>=1
drop kf2 h_temp



/* how many firms */
/* generate an indicator for each firm-year */
egen ty=tag(affiliate_id year)
tab year if ty==1

/* how many small firms and large */
tab year small_business if ty==1





/* setup revenue for small and large firms */
gen squid=value801+value802



gen permits=1

/* Aggregate revenue for each size class and year, plus number of firms and vessels */
collapse (sum) value168 value212 value221 squid value_permit ty permits, by(small year)


/* give these better names */
rename value168 herring
rename value212 mackerel
rename value221 menhaden 
rename value_permit total_value
gen other=total_value-squid-herring-mackerel-menhaden



rename ty firms
format herring mackerel menhaden squid other total_value %15.0gc
/* millions */
foreach var of varlist herring mackerel menhaden squid other total_value{
	replace `var'=`var'/1000000
}
list 
rename permit vessels
rename small size
label define smallsize 0 "Large" 1 "Small"
label values size smallsize
rename total_value total


order size firms vessels total herring mackerel menhaden squid other


label variable firms "Firms"

label variable herring "Herring Receipts"
label variable mackerel "Mackerel Receipts"
label variable menhaden "Menhaden Receipts"
label variable squid "Squid Receipts"
label variable other "Other Receipts"
label variable vessels "Total Vessels"
label variable total "Total Receipts"



/* take the averages (over 3 years) for the small and large firms */
local stats firms vessels total herring mackerel menhaden squid other





local  estpost_opts_by "statistics(mean sd) columns(statistics) nototal "

local estab_opts_by_small "main(mean %6.2fc) unstack nogaps label nomtitles nonumbers noobs nostar nonote compress"




*local  estpost_opts_by "statistics(mean) columns(statistics) nototal "

*local estab_opts_by_small "main(mean %6.2fc) unstack nogaps label nomtitles nonumbers noobs nostar nonote compress"





estpost tabstat `stats', by(size)  `estpost_opts_by'

esttab ., `estab_opts_by_small'

/*
esttab .  using ${my_tables}/RFA_ABCDE.tex, `estab_opts_by_small' replace
*/


/* turns out there are only 2 large firms, so we can only report the small ones*/



estpost tabstat `stats' if size==1, by(size)  `estpost_opts_by'

esttab ., `estab_opts_by_small'


esttab .  using ${my_tables}/RFA_active_ABCDE.tex, `estab_opts_by_small' replace



/*averaged across the years */
collapse (mean) herring mackerel menhaden squid other total firms vessels, by(size)







export delimited size firms vessels total herring mackerel squid menhaden other using ${my_results}/RFA_active_ABCDE.csv , replace

