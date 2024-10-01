
clear
global RFA_filepath "Z:\Ownership Data/current data and metadata/affiliates_2024_06_01.dta"

/*
```{r Directly_Regulated_Entities, eval=TRUE}
load(RFA_filepath)
affiliates<-affiliates_2024_06_01
finalyr<-max(affiliates$year)

rm(affiliates_2024_06_01)
affiliates$permit_count<-1

nyears<-length(unique(affiliates$year))
*/

use "$RFA_filepath"
tab year
local nyears=r(r)
qui summ year
local finalyr=r(max)
gen permit_count=1

/*
# Recode small_business to a print friendly string (Large, Small). Recode entity_type to nice casing

affiliates<-affiliates %>%
  mutate(entity_type_2023=replace(entity_type_2023, entity_type_2023=="FISHING","Fishing"),
         entity_type_2023=replace(entity_type_2023, entity_type_2023=="FORHIRE","For-Hire"),
         SB_string=case_when(
           small_business==1 ~ "Small",
           small_business==0 ~ "Large"),
  regulated_rev=value_169182 + value_172735 + value_167687 + value_168559
         ) %>%
    relocate(SB_string, .after=small_business) 
*/

replace entity_type_2023="Fishing" if strmatch(entity_type_2023,"FISHING")
replace entity_type_2023="For-Hire" if strmatch(entity_type_2023,"FORHIRE")
replace entity_type_2023="No Rev" if strmatch(entity_type_2023,"NO_REV")
gen SB_string="Small" if small_business==1
replace SB_string="Large" if small_business==0
gen regulated_rev=value_169182 + value_172735 + value_167687 + value_168559
tempfile affiliates
save `affiliates', replace


/* BSB2023<-affiliates %>%
 dplyr::filter(year==finalyr) %>%
  group_by(affiliate_id) %>%
  summarise(Type=first(entity_type_2023), 
            Size=first(SB_string),
            vessels=sum(permit_count),
            FLS=sum(c_across(starts_with("FLS_"))),
            SCP=sum(c_across(starts_with("SCP_"))),
            BLU=sum(c_across(starts_with("BLU_"))),
            BSB=sum(c_across(starts_with("BSB_"))),
            reg=sum(BSB)+sum(FLS)+sum(SCP)+sum(BLU)
            ) %>%
  filter(reg>=1)
*/

keep if year==`finalyr'
collapse (first) entity_type_2023 SB_string (sum) permit_count FLS* BSB* SCP* BLU* , by(affiliate_id)
egen reg=rowtotal(FLS* BSB* SCP* BLU*)
keep if reg>=1


tempfile BSB2023
save `BSB2023', replace

/* 

# Compute yearly average revenues, including average revenues by species. Rename the value_permit to value_firm to reflect the change in the column when we do the final summarise
yearly_affiliates<-affiliates %>%
  group_by(affiliate_id,year) %>%
  summarise(across(value_permit:value_914179, sum)) %>%  # Creates a firm-year dataset of values 
  mutate(regulated_rev=value_169182 + value_172735 + value_167687 + value_168559) %>%
      ungroup()
  */

use `affiliates', replace
collapse (sum) value* regulated_rev (first) affiliate_total affiliate_fish affiliate_forhire, by(affiliate_id year)
/* by summing the value_permit by affiliate_id and year value_permit should now be equal to affiliate_total */
assert abs(value_permit-affiliate_total)<=2
tempfile yearly_affiliates
save `yearly_affiliates', replace

/* summary_affiliates<-yearly_affiliates %>%
  group_by(affiliate_id) %>%
  summarise(across(value_permit:value_914179, mean)) %>% # Takes the mean of the firm-level dataset of values
    rename(value_firm=value_permit, value_firm_forhire=value_permit_forhire) %>%
    mutate(regulated_rev=value_169182 + value_172735 + value_167687 + value_168559)
 */


collapse (mean) value* regulated_rev affiliate_total affiliate_fish affiliate_forhire, by(affiliate_id)
/* by summing the value_permit by affiliate_id and year value_permit should now be equal to affiliate_total */
assert abs(value_permit-affiliate_total)<=2

rename value_permit value_firm
rename value_permit_forhire value_firm_forhire

tempfile summary_affiliates
save `summary_affiliates', replace


/* 
#merge together they keyfile and the average revenue, keeping just the affiliate_ids that show up in BSB2023
Directly_Regulated_Entities<-left_join(BSB2023,summary_affiliates,by='affiliate_id')

Directly_Regulated_Entities <-Directly_Regulated_Entities %>%
    mutate(Revenue_Bin = cut(value_firm, breaks=c(-0.1, 250000, 1000000, 2000000, 5000000, 11000000, 1e15)) ,
           Regulated_fraction=regulated_rev/value_firm) */

use `BSB2023', replace
merge 1:1 affiliate_id using `summary_affiliates', keep(1 3)
assert _merge==3

gen Revenue_Bin=irecode(value_firm, -.1, 250000, 1000000, 2000000, 5000000, 11000000)
gen Regulated_fraction=regulated_rev/value_firm

tab Revenue_Bin
rename permit_count vessels
rename entity Type
rename SB Size


tempfile Directly_Regulated_Entities
save `Directly_Regulated_Entities', replace

/* # Summary of DRE large and small firms in the fishing and for-hire industries. Exclude the inactive (NO_REV).
Directly_Regulated_Entities_table <- Directly_Regulated_Entities %>%
  filter(Type !="NO_REV") %>%
  group_by(Size, Type) %>%
  summarise(Firms=n(),
            Vessels=sum(vessels),
            "Avg Gross Receipts"=round(mean(value_firm),0),
            "Avg Regulated Receipts"=round(mean(regulated_rev),0),
            "25th pct Gross Receipts" = round(quantile(value_firm, probs=.25),0),
            "75th pct Gross Receipts"=round(quantile(value_firm, probs=.75),0)
           ) %>%
  mutate(across(c(`Firms`,`Vessels`), ~ number(.x, big.mark=","))) %>%
  mutate(across(c(`Avg Gross Receipts`,`Avg Regulated Receipts`, `25th pct Gross Receipts`, `75th pct Gross Receipts` ), ~ number(.x, accuracy=1000,prefix="$", big.mark=",")))

small_fishing_firms<-Directly_Regulated_Entities_table$Firms[Directly_Regulated_Entities_table$Size=="Small"& Directly_Regulated_Entities_table$Type=="Fishing"]
large_fishing_firms<-Directly_Regulated_Entities_table$Firms[Directly_Regulated_Entities_table$Size=="Large"& Directly_Regulated_Entities_table$Type=="Fishing"]
small_forhire_firms<-Directly_Regulated_Entities_table$Firms[Directly_Regulated_Entities_table$Size=="Small"& Directly_Regulated_Entities_table$Type=="For-Hire"]
```


```{r make_DRE_table} 
kbl(Directly_Regulated_Entities_table, digits=0,booktabs=T, align=c("l",rep('r',times=7)), caption =  "Number and characterization of the directly regulated entities and average trailing five years of revenue") %>%
    #column_spec(5:8, width = "2cm")
    kable_styling(full_width = T,latex_options = "hold_position") %>% 
      row_spec(0,bold=FALSE) 
```
 */


tab Size Type
collapse (sum) vessels (mean) value_firm regulated_rev Regulated_fraction, by(Size Type)
list if Type~="No Rev"

/*
          
```



```{r Rev_by_firm_size}
# Make a keyfile based on BSB2023 that just has firms that landed any herring at any time during the 2019-2023 period.

Summary_table<-Directly_Regulated_Entities %>%
  group_by(Revenue_Bin) %>%
  summarise(firms=n(),
            Total_Revenue= round(mean(value_firm),0),
            Avg_Regulated_Receipts=round(mean(regulated_rev),0)) %>%
  mutate(Fraction =round(Avg_Regulated_Receipts/ Total_Revenue,3))
  
kbl(Summary_table,booktabs=T, align=c("l",rep('r',times=7)), caption =  "Average annual total revenues during 2018-2023 for the small businesses/affiliates potentially impacted by the proposed action, as well as average annual revenues from commercial landings of summer flounder, scup, and/or black sea bass") %>%
    #column_spec(1:4, width = "1cm") %>%
    kable_styling(full_width = T) %>% 
      row_spec(0,bold=FALSE) 


	  */
	  
	  
	  
use `Directly_Regulated_Entities', replace
collapse (count) firms=affiliate_id (mean) value_firm  regulated_rev Regulated_fraction, by(Revenue_Bin)
list

use `Directly_Regulated_Entities', replace

replace regulated_rev=regulated_rev/1000
graph box regulated_rev, over(Revenue_Bin)


/*	   




```{r boxplotsR, fig.cap="\\label{figure_boxR}Projected Firm Level Revenue under the draft action, small firms only"}

Directly_Regulated_Entities2<-Directly_Regulated_Entities %>%
  mutate(fraction_reg=regulated_rev/value_firm)

p<-ggplot(Directly_Regulated_Entities2, aes(Revenue_Bin, regulated_rev/1000))
p+geom_boxplot(outlier.shape = NA) +
  labs(x="Year", y="Revenue from Regulated Species ('000s of USD)")


p<-ggplot(Directly_Regulated_Entities2, aes(Revenue_Bin, fraction_reg))
p+geom_boxplot(outlier.shape = NA) +
  labs(x="Year", y="Fraction Revenue from Regulated Species")


```
*/