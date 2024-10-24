
# This is a code to:
# Estimate the number of trips that targeted a particular species.
# I have previously read in all the sas7bdat files and converted them to Rds. This takes a little while.
# This has been verified by replicating the trips that Target Striped bass on the MRIP website

# Directed Trip query for trips by wave that have Primary Target=STRIPED BASS or Secondary Target=STRIPED BASS
# for 2023.

library("here")
library("tidyverse")
library("haven")
library("survey")
library("srvyr")
library("data.table")
here::i_am("R_code/data_extraction_processing/processing/01_MRIP_Targeting.R")
options(scipen=999)
################################################################################
########################################SET UPS ################################
################################################################################

#Handle single PSUs
options(survey.lonely.psu = "certainty")


# running local 
local_BLAST_folder<-file.path("V:","READ-SSB-Lee-MRIP-BLAST")
network_BLAST_folder<-file.path("blast","READ-SSB-Lee-MRIP-BLAST")


raw_mrip_folder<-file.path(local_BLAST_folder,"data_folder","raw")


species1<-"stripedbass"
################################################################################
################################################################################
########################################SET UPS ################################
################################################################################
################################################################################
size_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("size_2*.Rds"))
sizeb2_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("size_b2_2*.Rds"))
catch_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("catch_*.Rds"))
trip_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("trip_*.Rds"))

year<-as.character(2021:2023)
year<-as.data.frame(year)
waves<-as.character(1:6)
waves<-as.data.frame(waves)

yearly<-merge(year,waves, all=TRUE)
readins<-paste0(yearly$year, yearly$waves)

readins<-as.list(readins)  






ma_allocation<-haven::read_dta(file.path(raw_mrip_folder,"ma_site_allocation.dta"))






#Functions to read in Trips, Size, SizeB2, and catch Rds files

readin_trips <- function(waves) {
  in_dataset<-file.path(raw_mrip_folder,paste0("trip_",waves,".Rds"))
  
  if(file.exists(in_dataset)==TRUE){
    output<-readRDS(in_dataset)
    return(output)
  }
}


readin_size <- function(waves) {
  in_dataset<-file.path(raw_mrip_folder,paste0("size_",waves,".Rds"))
  
  if(file.exists(in_dataset)==TRUE){
    output<-readRDS(in_dataset)
    return(output)
  }
}


readin_catch <- function(waves) {
  in_dataset<-file.path(raw_mrip_folder,paste0("catch_",waves,".Rds"))
  
  if(file.exists(in_dataset)==TRUE){
    output<-readRDS(in_dataset)
    return(output)
  }
}

readin_size_b2 <- function(waves) {
  in_dataset<-file.path(raw_mrip_folder,paste0("size_b2_",waves,".Rds"))
  
  if(file.exists(in_dataset)==TRUE){
    output<-readRDS(in_dataset)
    return(output)
  }
}


















################################################################################
################################################################################
######READ in Trip Dataset####################

################################################################################
# Trips
################################################################################


# Process Trip 

# Add a directedtrip (dtrip)= 1 column and make all the column names lowercase
# convert contents of prim1_common and prim2_common to lower case and remove white space
# Pad out st and cnty.  create stco.


trip_dataset<-lapply(readins,readin_trips)
trip_dataset<-rbindlist(trip_dataset, fill=TRUE)











trip_dataset<-trip_dataset %>%
  mutate(dtrip=1) %>%
  rename_all(tolower)%>%
  mutate(prim1_common=str_to_lower(prim1_common),
         prim2_common=str_to_lower(prim2_common)
         )%>%
  mutate(prim1_common=str_replace_all(prim1_common, pattern=" ", ""),
         prim2_common=str_replace_all(prim2_common, pattern=" ", "")
         ) %>%
  mutate(st=str_pad(st,2,pad="0"),
         cnty=str_pad(cnty,3,pad="0"),
         stco=paste0(st,cnty))


trip_dataset<-trip_dataset %>%
  left_join(ma_allocation, by=join_by(intsite==site_id))



######READ in Trip Dataset####################
catch_dataset<-lapply(readins,readin_catch)
catch_dataset<-rbindlist(catch_dataset, fill=TRUE)

# column names to lower case, fill na., 
# convert contents of common to lower case and remove all white space 
catch_dataset<-catch_dataset %>%
  rename_all(tolower) %>%
  mutate(var_id=ifelse(var_id=="",strat_id,var_id),
         wp_catch=ifelse(is.na(wp_catch),wp_int, wp_catch),
         claim=ifelse(is.na(claim),0,claim),
         wp_int=ifelse(wp_int<0,0,wp_int)) %>%
  mutate(common=str_to_lower(common))%>%
  mutate(common=str_replace_all(common, pattern=" ", ""))

# Merge trip to catch. For columns in both dataset, column from the "trip" dataset          
trip_dataset<-trip_dataset %>%
  dplyr::full_join(catch_dataset, by=join_by(year, strat_id, psu_id, id_code), relationship="one-to-many", suffix=c("",".y")) %>%
  select(-ends_with(".y"))


trip_dataset<-trip_dataset %>%
  mutate(mode=ifelse(mode_fx==4,"FH",ifelse(mode_fx==5,"FH","PR"))
)

trip_dataset$dom_id<-2

# This is trips that caught species1
# trip_dataset$dom_id[trip_dataset$common ==species1 ]<-1


# This is trips that targeted species1
trip_dataset$dom_id[trip_dataset$prim1_common ==species1 ]<-1
trip_dataset$dom_id[trip_dataset$prim2_common ==species1 ]<-1



# Deal with Group Catch 
# For group catch, we want to keep only the largest value of claim from the leader.  
# I am not sure if this matters for targeting.  

# -- this bit of code generates a flag for each year-strat_id psu_id leader. (equal to the lowest of the dom_id)

# 
# 
# Flag the year-wave-strat_id, psu_id, leader. Pull in the dom_id.
trip_dataset<-trip_dataset %>%
  group_by(year, wave, strat_id, psu_id, leader)%>%
  arrange(year, wave, strat_id, psu_id, dom_id)%>%
  mutate(gc_flag=dplyr::first(dom_id))


# Generates a flag for claim equal to the largest claim.
# [This is probably wrong. it's pulling forward the largest value of claim, regardless of species
trip_dataset<-trip_dataset %>%
  group_by(year, wave, strat_id, psu_id, leader)%>%
  arrange(year, wave,strat_id, psu_id, claim)%>%
  mutate(claim_flag=dplyr::last(claim))

# Re-classifies the trip into dom_id=1 if that trip had catch of species in dom_id1
trip_dataset$dom_id[(trip_dataset$dom_id ==2) &
  (trip_dataset$claim_flag >0) & is.na(trip_dataset$claim_flag)==FALSE  &
   trip_dataset$gc_flag==1]<-1



# keep 1 observation per year-strat-psu-id_code. This will have dom_id=1 if it
# targeted or caught my_common1 or my_common2. Else it will be dom_id=2*/
# bysort year wave strat_id psu_id id_code (dom_id): gen count_obs1=_n
# 
# keep if count_obs1==1

  

# # You might want to adjust this by filtering: just new England or just ME, MA, NH.  
# trip_dataset$dom_id[!trip_dataset$sub_reg %in% c(4)]<-2
# trip_dataset$dom_id[!trip_dataset$st %in% c(23,33,25)]<-2
# # Use the ma_site_allocation to classify intercept sites into GOM and not?
# trip_dataset$dom_id[!trip_dataset$stock_region_calc %in% c("NORTH")]<-2




 trip_dataset<-trip_dataset %>%
   group_by(year, wave, strat_id, psu_id, id_code)%>%
   arrange(year, wave, strat_id, psu_id, id_code, dom_id)%>%
   slice_head(n=1) %>%
   dplyr::filter(dom_id==1)

 # Drop protest st_res fips codes
trip_dataset<-trip_dataset %>%
  dplyr::filter(st_res<99)
 
# Targeting 
# srvyr data prep

 
tidy_trips_in<-trip_dataset %>%
  as_survey_design(id=psu_id, weights=wp_int, strata=strat_id, nest=TRUE, fpc=NULL)

# 
# target_totals_by_mode<-tidy_trips_in %>%
#   dplyr::filter(dom_id==1) %>%
#   group_by(year, wave,mode ) %>%
#   summarise(dtrip=round(survey_total(dtrip))
#   )
# 
# target_totals<-tidy_trips_in %>%
#   dplyr::filter(dom_id==1) %>%
#   group_by(year, wave ) %>%
#   summarise(dtrip=round(survey_total(dtrip))
#   )
# 
# 
# target_totals_stco<-tidy_trips_in %>%
#   dplyr::filter(dom_id==1) %>%
#   group_by(year, wave,stco ) %>%
#   summarise(dtrip=round(survey_total(dtrip))
#)

target_totals_zip<-tidy_trips_in %>%
  dplyr::filter(dom_id==1) %>%
  group_by(st_res, zip ) %>%
  summarise(dtrip=round(survey_total(dtrip))
  )


