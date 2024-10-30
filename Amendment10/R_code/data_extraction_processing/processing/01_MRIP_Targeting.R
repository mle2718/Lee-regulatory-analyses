
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


local_BLAST_folder<-file.path("V:","READ-SSB-Lee-MRIP-BLAST")
network_BLAST_folder<-file.path("//nefscfile","BLAST" ,"READ-SSB-Lee-MRIP-BLAST")

# run local
raw_mrip_folder<-file.path(local_BLAST_folder,"data_folder","raw")
# run network
raw_mrip_folder<-file.path(network_BLAST_folder,"data_folder","raw")

specieslist<-c("stripedbass","blackseabass")
################################################################################
################################################################################
########################################SET UPS ################################
################################################################################
################################################################################
size_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("size_2*.Rds"))
sizeb2_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("size_b2_2*.Rds"))
catch_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("catch_*.Rds"))
trip_list<-list.files(path=raw_mrip_folder, pattern=glob2rx("trip_*.Rds"))

year<-as.character(2020:2024)
year<-as.data.frame(year)
waves<-as.character(1:6)
waves<-as.data.frame(waves)

yearly<-merge(year,waves, all=TRUE)
readins<-paste0(yearly$year, yearly$waves)

readins<-as.list(readins)  






ma_site_allocation<-haven::read_dta(file.path(raw_mrip_folder,"ma_site_allocation.dta"))

names(ma_site_allocation) <- tolower(names(ma_site_allocation))





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
  left_join(ma_site_allocation, by=join_by(intsite==site_id))
rows_of_trip<-nrow(trip_dataset)

trip_dataset<-trip_dataset %>%
  mutate(mode=ifelse(mode_fx==4,"FH",ifelse(mode_fx==5,"FH","PR"))
)



# Classify rows in "trip" that are in my domain. At the end of this code, I need the same number of rows as the original trip dataset

# rows_of_trip<-nrow(trip_dataset)) 
#   group_by(year, wave, strat_id, psu_id, id_code)%>%

#create a categorical for whether the row caught or targeted species in specieslist

trip_dataset<-trip_dataset %>%
  mutate(targeted=case_when(prim1_common %in% specieslist ~1, .default=0)
  ) %>%
  mutate(targeted=case_when(prim2_common %in% specieslist ~1, .default=targeted)
)


# sum those variables, so they are constant within each year, wave, strat_id, psu_id, id_code. Pick of the first row.
trip_dataset<-trip_dataset %>%
  group_by(year, wave, strat_id, psu_id, id_code)%>%
  mutate(targeted=sum(targeted)) %>%
  slice_head(n=1) %>%
  ungroup()

# Classify as in my domain if caught or targeted
trip_dataset<-trip_dataset %>%
 mutate(dom_id=case_when(targeted>=1 ~ 1, .default=0) 
         )

# # You might want to adjust this by filtering: just new England or just ME, MA, NH.
# Be careful where you put this piece of code
# trip_dataset$dom_id[!trip_dataset$sub_reg %in% c(4)]<-2
# trip_dataset$dom_id[!trip_dataset$st %in% c(23,33,25)]<-2
# # Use the ma_site_allocation to classify intercept sites into GOM and not?
# trip_dataset$dom_id[!trip_dataset$stock_region_calc %in% c("NORTH")]<-2





# Drop protest st_res fips codes
# trip_dataset<-trip_dataset %>%
#   dplyr::filter(st_res<99)
 
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
 target_totals_stco<-tidy_trips_in %>%
   dplyr::filter(dom_id==1) %>%
   group_by(year, wave,stco ) %>%
   summarise(dtrip=round(survey_total(dtrip))
)

 target_totals_stco$target<-paste(specieslist, collapse = "_")
 
 
target_totals_zip<-tidy_trips_in %>%
  dplyr::filter(dom_id==1) %>%
  group_by(st_res, zip ) %>%
  summarise(dtrip=round(survey_total(dtrip))
  )

target_totals_zip$target<-paste(specieslist, collapse = "_")



saveRDS(target_totals_stco,file=here("data_folder", "main", paste0("targeted_stco_",vintage_string,".Rds")))


saveRDS(target_totals_zip,file=here("data_folder", "main", paste0("targeted_zip_",vintage_string,".Rds")))


