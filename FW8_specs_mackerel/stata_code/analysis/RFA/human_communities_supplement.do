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

preserve

/* Table 25 - Revenue (in thousands $) for VESSELS that land Atlantic herring, 2017-2019*/
keep if value168>0
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
rename total total
export delimited year vessels total herring mackerel squid menhaden other using ${my_results}/species_comp_vessels.csv, replace
export excel year vessels total herring mackerel squid menhaden other using ${my_results}/species_comp_vessels.xlsx, replace firstrow(variables)


restore


/* Table 25A - Revenue (in thousands $) for firms that own a vessel that landed Atlantic herring, 2017-2019*/



*preserve

/* how many firms */
/* generate an indicator for each firm-year */
egen ty=tag(affiliate_id year)

gen squid=value801+value802

/* flag the active vessels */
gen aa=value168>=1

/* flag the active firms */
bysort affiliate_id year: egen active=total(aa)
replace active=active>=1
drop aa

gen permits=1
collapse (sum) value168 value212 value221 squid value_permit ty permits, by(active year)
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
rename total total
export delimited year firms vessels total herring mackerel squid menhaden other using ${my_results}/species_comp_firms.csv if active==1, replace
export excel year firms vessels total herring mackerel squid menhaden other using ${my_results}/species_comp_firms.xlsx if active==1, replace  firstrow(variables)

*restore
