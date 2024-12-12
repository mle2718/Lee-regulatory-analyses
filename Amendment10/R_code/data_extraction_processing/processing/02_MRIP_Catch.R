
# This is a code to:
# 1.  Estimate the number of trips that targeted or caught a particular species.
# 2.  Estimate catch, claim, harvest, and release of that species.
# I have previously readin all the sas7bdat files and converted them to Rds. This takes a little while.
# This matches the MRIP 2023 Catch Time Series for Striped Bass (Total Catch A+B1+B2)

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


specieslist<-c("stripedbass")
################################################################################
################################################################################
########################################SET UPS ################################
################################################################################
################################################################################
size_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("size_2*.Rds"))
sizeb2_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("size_b2_2*.Rds"))
catch_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("catch_*.Rds"))
trip_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("trip_*.Rds"))

len_dataset<-list()

year<-as.character(2023:2023)
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


trip_datasetA<-lapply(readins,readin_trips)
trip_datasetA<-rbindlist(trip_datasetA, fill=TRUE)



trip_dataset<-trip_datasetA %>%
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



######READ in Catch Dataset####################
catch_datasetA<-lapply(readins,readin_catch)
catch_datasetA<-rbindlist(catch_datasetA, fill=TRUE)

# column names to lower case, fill na., 
# convert contents of common to lower case and remove all white space 
catch_dataset<-catch_datasetA %>%
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
 trip_dataset$dom_id[trip_dataset$common ==species1 ]<-1


#srvyr data prep
tidy_catch_in<-trip_dataset %>%
  as_survey_design(id=psu_id, weights=wp_int, strata=var_id, nest=TRUE, fpc=NULL)


catch_totals_filtered<-tidy_catch_in %>%
  group_by(year, wave,dom_id,common ) %>%
  summarise(tot_cat=round(survey_total(tot_cat)),
            claim=round(survey_total(claim)),
            harvest=round(survey_total(harvest)),
            release=round(survey_total(release))
  )


