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



/* fraction of all herring, by firm */
/* first, collapse to the firm level */
gen permits=1

collapse (sum) value168 value212 value221 squid value_permit ty permits, by(small affiliate_id year)

bysort year: egen total_herring=total(value168)
gen fraction_herring=value168/total_herring


/* additional herring revenue from Action 2 */
gen adj_fleet_herring=total_herring+160000
gen adj_herring=fraction_herring*adj_fleet_herring



rename value168 herring
rename value212 mackerel
rename value221 menhaden 
rename value_permit total_value


gen delta_herring=adj_herring-herring

gen other=total_value-squid-herring-mackerel-menhaden
gen adj_total_value=other+squid+mackerel+menhaden+adj_herring
pause
/* tag the affiliate-year */
cap drop ty
gen ty=1




/* here is a good place to construct a histogram of percent of total receipts changed */

preserve

collapse (mean) adj_herring herring delta_herring mackerel menhaden squid total_value adj_fleet_herring adj_total_value other, by(affiliate_id small)

/* round these to the nearest dollar */

foreach var of varlist adj_herring herring delta_herring mackerel menhaden squid total_value adj_fleet_herring adj_total_value other{
	replace `var'=round(`var')
}

gen delta_rev=adj_total_value-total_value

gen pct_delta_rev=(delta_rev/total_value)*100
label variable delta_rev "Change in Gross Receipts"

label variable pct_delta_rev "Change in Gross Receipts"

hist pct_delta_rev if pct_delta_rev>0 & small==1, frequency ytitle("Number of Small Firms")

graph export ${my_images}/RFA_active_pct_change_in_gross_receipts.png, replace as(png)


hist delta_rev if delta_rev>0 & small==1, frequency ytitle("Number of Small Firms")

graph export ${my_images}/RFA_active_change_in_gross_receipts.png, replace as(png)


restore




/* Aggregate revenue for each size class and year, plus number of firms and vessels */
collapse (sum) adj_herring herring delta_herring mackerel menhaden squid total_value ty adj_total_value permits other, by(small year)


/* give these better names */



format adj_herring herring delta_herring mackerel menhaden squid total_value ty  adj_total_value other %15.0gc




/* millions */
foreach var of varlist adj_herring herring mackerel menhaden squid total_value  adj_total_value other delta_herring{
	replace `var'=`var'/1000000
}
list 

rename ty firms

rename permit vessels
rename small size
label define smallsize 0 "Large" 1 "Small"
label values size smallsize
rename total_value total


order size firms vessels total herring mackerel menhaden squid other
label variable firms "Firms"

label variable herring "Baseline Herring Receipts"
label variable mackerel "Mackerel Receipts"
label variable menhaden "Menhaden Receipts"
label variable squid "Squid Receipts"
label variable other "Other Receipts"
label variable vessels "Total Vessels"
label variable total "Baseline Gross Receipts"

label variable adj_total_value "Gross Receipts (Preferred Alt)"
label variable adj_herring "Herring Receipts  (Preferred Alt)"

label variable delta_herring "Change in Herring Receipts"







pause
















/* take the averages (over 3 years) for the small and large firms */
local stats firms total adj_total_value herring adj_herring delta_herring

local  estpost_opts_by "statistics(mean sd) columns(statistics) nototal "

local estab_opts_by_small "main(mean %8.3fc) unstack nogaps label nomtitles nonumbers noobs nostar nonote compress"




*local  estpost_opts_by "statistics(mean) columns(statistics) nototal "

*local estab_opts_by_small "main(mean %6.2fc) unstack nogaps label nomtitles nonumbers noobs nostar nonote compress"
estpost tabstat `stats', by(size)  `estpost_opts_by'

esttab ., `estab_opts_by_small'


esttab .  using ${my_tables}/RFA_active_revenue_changes_all.tex, `estab_opts_by_small' replace




preserve


/* also save it as a csv */
collapse (mean) adj_total_value adj_herring mackerel menhaden squid other firms vessels, by(size)







export delimited size adj_total_value adj_herring mackerel menhaden squid other firms vessels using ${my_results}/RFAspecies_active_revenue_changes.csv , replace

restore