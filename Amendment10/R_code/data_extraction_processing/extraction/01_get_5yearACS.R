library("tidyverse")
#library("tidycensus")
library("censusapi")
library("tigris")
options(tigris_use_cache = TRUE)
library("mapview")


options(scipen=999)



# Get the zcta data
# This is a really massive dataset, so don't look at them all. 
zcta<-zctas(cb=FALSE, year=2022)

# Subset the zctas that start with 01 and 02, which is mostly MA and RI
MARI<-zcta %>%
  dplyr::filter(str_detect(ZCTA5CE20,"^01")| str_detect(ZCTA5CE20,"^02"))
)
mapview(MARI)

ggplot(MARI) +
  +   geom_sf(fill = "white", color = "black", linewidth = 0.3) +
  +   theme_void()

# Read in the state-zcta correspondence file.
zcta_state<-read_delim("https://www2.census.gov/geo/docs/maps-data/data/rel2020/zcta520/tab20_zcta520_county20_natl.txt", delim="|", guess_max=2000)

# Contract down to the fraction in each area.
zcta_state <- zcta_state %>%
  dplyr::filter(is.na(OID_ZCTA5_20)==FALSE) %>%
  group_by(OID_ZCTA5_20) %>%
  mutate(total_area=sum(AREALAND_PART)) %>%
  mutate(fraction=AREALAND_PART/total_area) %>%
  select(c(GEOID_ZCTA5_20, OID_ZCTA5_20,OID_COUNTY_20, GEOID_COUNTY_20, fraction))

#Code to investigate census data
acs5ST <- listCensusMetadata(
  vintage="2022",
  name = "acs/acs5/subject",
  type = "variables")

acs5ST <-acs5ST %>%
  arrange(group, concept, name) %>%
  dplyr::filter(str_detect(label,"Estimate"))

finance<-acs5ST %>%
  dplyr::filter(group=="S2503")

inc<-acs5ST %>%
  dplyr::filter(group=="S1901")


as<-acs5ST %>%
  dplyr::filter(group=="S0101")


demog<-acs5ST %>%
  dplyr::filter(group=="S0501")


# 
# concepts<-acs5ST %>% 
#   select(group, concept) %>%
#   distinct()

#acs5ST <- listCensusMetadata(
#  vintage="2022",
#  name = "acs/acs5/subject", 
#  type = "geographies")


# income <- getCensus(
#   name = "acs/acs5/subject",
#   vintage = 2022,
#   vars = "group(S1901)",
#   region = "state:*", 
#   show_call=TRUE)
# 
# 


# Pull in and tidy up some Census data on household income at the state level
county_income <- getCensus(
  name = "acs/acs5/subject",
  vintage = 2022,
  vars = c("S1901_C01_012E","S1901_C01_013E"),
  region = "county:*", 
  show_call=TRUE)

county_income<-county_income %>%
  rename (county_household_median_inc=S1901_C01_012E, 
           county_household_mean_inc=S1901_C01_013E
  ) %>%
  mutate(st_co=paste0(state,county))


# use county income to create an in imputed income based on county income

income_fill<-zcta_state %>%
  left_join(county_income, by=join_by(GEOID_COUNTY_20==st_co), relationship="many-to-one") %>%
  mutate(wmedian=fraction*county_household_median_inc,
         wmean=fraction*county_household_mean_inc) %>%
  group_by(GEOID_ZCTA5_20, OID_ZCTA5_20) %>%
  summarise(imputed_household_median_income=sum(wmedian),
           imputed_household_mean_income=sum(wmean)) %>%
  ungroup()





# Pull in and tidy up some Census data on household income
income <- getCensus(
  name = "acs/acs5/subject",
  vintage = 2022,
  vars = c("S1901_C01_001E",  "S1901_C01_010E","S1901_C01_011E","S1901_C01_012E","S1901_C01_013E","S0101_C01_001E", "S0101_C02_028E"),
  region = "zip code tabulation area:*", 
  show_call=TRUE)

income<-income %>%
  rename ( households=S1901_C01_001E,
           household_inc_150_200pct =S1901_C01_010E,
           household_inc_200pct=S1901_C01_011E,
           household_median_inc=S1901_C01_012E, 
           household_mean_inc=S1901_C01_013E,
           total_population=S0101_C01_001E,
           population_pct_over60=S0101_C02_028E
           )

income<-income %>%
  left_join(income_fill, by=join_by(zip_code_tabulation_area==GEOID_ZCTA5_20), relationship="one-to-one")%>%
  mutate(household_median_inc=case_when(household_median_inc<0 ~ imputed_household_median_income, .default=household_median_inc),
         household_mean_inc=case_when(household_mean_inc<0 ~ imputed_household_mean_income, .default=household_mean_inc)
  )



# There are some suppressed data particularly for the median and mean income.
# An example is zcta 01063. 
# I could ignore it (null out things with HHI < 0 ), reconstruct it from the distribution, or substitute in county or state level means.
#    Substituing in state or county is actually tricky, because zcta's dont nest inside  


# Total_population S0501_C01_001E
 # S0601_C01_001E
# White alone not Hispanic or Latino as a percentage of the total population). S0501_C01_023E
#This isnt working, everything is NA or NULL

demog <- getCensus(
  name = "acs/acs5/subject",
  vintage = 2022,
  vars = c("S0601_C01_001E","S0601_C01_022E"),
  region = "zip code tabulation area:*", 
  show_call=TRUE)


demog<-demog %>%
  rename ( total_population=S0601_C01_001E,
           pct_white_alone =S0601_C01_022E
  )

income<-income %>%
  left_join(demog, by=join_by(zip_code_tabulation_area))

income<-income %>%
  left_join(zcta_statekey, by=join_by(zip_code_tabulation_area==ZCTA5CE10))

income<-income %>%
  left_join(state_income, by=join_by(STATEFP10==state))

mapview(zctaMA)
