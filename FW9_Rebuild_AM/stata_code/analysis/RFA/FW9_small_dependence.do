use $RFA_dataset, clear
/* first, lets get total fishery value by year */
collapse (sum) value168 value212, by(year)
list


use $RFA_dataset, clear



/* For FW9, we will only be affecting HRG ABCDE vessels. 
we want to flag all the firms that had at least 1 of these in the most recent year*/

/* ALL permitted */
local keeplist HRG_A HRG_B HRG_C HRG_D HRG_E 



drop person*
egen keep_flag=rowtotal(`keeplist')
qui summ year
local maxy=`r(max)'
replace keep_flag=0 if year~=`maxy'

bysort affiliate_id : egen kf2=total(keep_flag)
keep if kf2>=1
drop kf2

qui compress

preserve

/* Table 25 - Revenue (in thousands $) for VESSELS that land Atlantic herring or mackerel, 2017-2019*/
keep if value168>=1 | value212>=1
gen squid=value801+value802
collapse (sum) value168 value212 value221 squid value_permit (count) permit, by(year)
rename value168 herring
rename value212 mackerel
rename value221 menhaden 

gen other=value_permit-squid-herring-mackerel-menhaden
 rename value_permit total_value
order permit, after(year)
order total_value, last
rename permit vessels

format herring mackerel menhaden squid other total_value %15.0gc
/* thousands */
foreach var of varlist herring mackerel menhaden squid other total_value{
	replace `var'=`var'/1000
}

export delimited year vessels herring mackerel squid menhaden other using ${my_results}/RFAspecies_comp_vessels.csv, replace


restore


/* Table 25A - Revenue (in thousands $) for firms that own a vessel that landed Atlantic herring or mackerel, 2017-2019*/



*preserve

/* how many firms */
/* generate an indicator for each firm-year */
egen ty=tag(affiliate_id year)

gen squid=value801+value802

/* flag the active vessels in H or M */
gen aa=value168>=1
replace aa=1 if value212>=1
/* flag the active firms */
bysort affiliate_id year: egen active=total(aa)
replace active=active>=1
drop aa

gen permits=1
collapse (sum) value168 value212 value221 squid value_permit ty permits, by(active small year)
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
list if active==1
rename permit vessels
rename small size
label define smallsize 0 "Large" 1 "Small"
label values size smallsize
rename total_value total

export delimited year size firms vessels total herring mackerel squid menhaden other using ${my_results}/RFAspecies_comp_firms.csv if active==1, replace

*restore
