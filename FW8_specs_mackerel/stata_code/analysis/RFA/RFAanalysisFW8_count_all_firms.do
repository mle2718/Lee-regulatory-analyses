use $RFA_dataset, clear
/* first, lets get total fishery value by year */

 collapse (sum) value168 value212, by(year)

 list




use $RFA_dataset, clear


/* For FW8, it's reasonable to assume HRG A,B,C, and E vessels OR SMB T1, T2, T3, 4
we want to flag all the firms that had at least 1 of these 4 categories in the most recent year*/

/* ALL permitted */
local keeplist HRG_A HRG_B HRG_C HRG_D HRG_E SMB_T1 SMB_T2 SMB_T3 SMB_4

/* Without HRG D permitted

local keeplist HRG_A HRG_B HRG_C HRG_E SMB_T1 SMB_T2 SMB_T3 SMB_4
 */
drop person*
egen keep_flag=rowtotal(`keeplist')
qui summ year
local maxy=`r(max)'
replace keep_flag=0 if year~=`maxy'

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
gen squid=value801+value802



gen permits=1
collapse (sum) value168 value212 value221 squid value_permit ty permits, by(small year)

collapse (mean) value168 value212 value221 squid value_permit ty permits, by(small)


rename value168 herring
rename value212 mackerel
rename value221 menhaden 

 rename value_permit total_value

gen other=total_value-squid-herring-mackerel-menhaden

rename ty firms
format herring mackerel menhaden squid other total_value %15.0gc
/* thousands */
foreach var of varlist herring mackerel menhaden squid other total_value{
	replace `var'=`var'/1000
}
list 
rename permit vessels
rename small size
label define smallsize 0 "Large" 1 "Small"
label values size smallsize
rename total_value total

export delimited size firms vessels total herring mackerel squid menhaden other using ${my_results}/RFAspecies_comp_firms_all.csv , replace

