# Remap FW7 - 
# Herring and mackerel disaggregated pounds
# plotted on the same map window
# 2008-2013 and then 2014-2018.
# Monthly
# You've already run step4 to make month-by-month TIFs for herring pounds and mackerel pounds
# STEP5_modified you need to aggregate them together into 24 geotiffs per species (12 months)
# Step7_check_confidentiality


rm(list=ls())
# SETUP directories
todaysdate = as.Date(Sys.time())


#Load/Install necessary libraries
if(!require(raster)) {  
  install.packages("raster")
  require(raster)}
if(!require(snow)) {  
  install.packages("snow")
  require(snow)}
if(!require(snowfall)) {
  install.packages("snowfall")
  require(snowfall)}
if(!require(rgdal)) {  
  install.packages("rgdal")
  require(rgdal)}
if(!require(rgeos)) {  
  install.packages("rgeos")
  require(rgeos)}
if(!require(foreign)) {  
  install.packages("foreign")
  require(foreign)}
if(!require(scales)) {  
  install.packages("scales")
  require(scales)}
if(!require(R2HTML)) {  
  install.packages("R2HTML")
  require(R2HTML)}

if(!require(RColorBrewer)) {  
  install.packages("RColorBrewer")
  require(RColorBrewer)}

if(!require(rasterVis)) {  
  install.packages("rasterVis")
  require(rasterVis)}
if(!require(dichromat)) {  
  install.packages("dichromat")
  require(dichromat)}
if(!require(stringr)) {  
  install.packages("stringr")
  require(stringr)}
if(!require(classInt)) {  
  install.packages("classInt")
  require(classInt)}
if(!require(data.table)) {  
  install.packages("data.table")
  require(data.table)}
if(!require(ROracle)) {  
  install.packages("ROracle")
  require(ROracle)}
if(!require(maps)) {  
  install.packages("maps")
  require(maps)}
if(!require(grid)) {  
  install.packages("grid")
  require(grid)}
#GIVE YOUR PROJECT A NAME
PROJECT.NAME="FW7_initial"


#### Set directories
SSB.NETWORK=file.path("/net/work5/socialsci") #This is what you need to run networked
SSBdrive = file.path(SSB.NETWORK, "Geret_Rasters") #when running R script off Linux server

GD.GIS.PATH = file.path(SSBdrive, "Data")


rasterfolder = file.path(SSBdrive, "Data", "individualrasters") 

ML.NETWORK.PATH=file.path("/net/home2/mlee")
ML.PROJECT.PATH=file.path(ML.NETWORK.PATH,"RasterRequests")
ML.GIS.PATH= file.path(ML.NETWORK.PATH, "spatial data") #Min-Yang stores some of his spatial data in this folder

#Where are the inputs for this project
ML.DATA.PATH=file.path(ML.PROJECT.PATH,"data")
GIS.PATH = file.path(SSBdrive, "Data")
source(file.path(SSBdrive,"FINAL_Raster_Functions.R"))

#GENERIC GIS FOLDER (These are maintained by Sharon Benjamin) 
GENERIC.GIS.PATH= file.path(SSB.NETWORK, "GIS")
FREQUENT.USE.SSB= file.path(GENERIC.GIS.PATH, "FrequentUseSSB")
################################


#where you putting the output?
ML.CODE.PATH=file.path(ML.PROJECT.PATH,"code","herring_scripts","herring_FW7")
ML.OUTPUT.IMAGE.PATH=file.path(ML.PROJECT.PATH,"outputs","images",PROJECT.NAME)
ML.OUTPUT.GEOTIFF.PATH=file.path(ML.PROJECT.PATH,"outputs","geotiff",PROJECT.NAME)

#this is the location of the first set of aggregated geotiffs
export.geotiff.path = file.path(ML.OUTPUT.GEOTIFF.PATH,paste0(PROJECT.NAME,"_",todaysdate))
dir.create(export.geotiff.path, recursive=T)

regime.geotiff.path = file.path(ML.PROJECT.PATH,"outputs","geotiff",PROJECT.NAME,paste0(PROJECT.NAME,"_AGGREGATED_",todaysdate))
dir.create(regime.geotiff.path, recursive=T)

# we'll need a folder for the confidentialized rasters.
confid.regime.geotiff.path =file.path(ML.PROJECT.PATH,"outputs","geotiff",PROJECT.NAME,paste0(PROJECT.NAME,"_reclass_",todaysdate))
confid.regime.image.path = file.path(ML.OUTPUT.IMAGE.PATH,paste0(PROJECT.NAME,"_reclass_", todaysdate))


dir.create(confid.regime.geotiff.path, recursive=T)
dir.create(confid.regime.image.path, recursive=T)


#where is the manifest of individual rasters?
individual.raster.file="individual_payload2019-12-05.Rds"
payloadRDS=file.path(ML.DATA.PATH,individual.raster.file)



#Define years to create rasters for here
START.YEAR = 2008   #Min = 1996
END.YEAR = 2018     #Max = 2013


#Read in the list of rasters
fl<-readRDS(payloadRDS)


## Load GIS maps
PROJ.USE = CRS('+proj=aea +lat_1=28 +lat_2=42 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0 ') 
# Albers Equal Area conic (in meters)
BASE.RASTER = raster(file.path(SSBdrive,"Data","BASERASTER_AEA_2"))

HABareas = LOAD.AND.PREP.GIS(SHPNAME="mults_efh", PROJECT.PATH = GIS.PATH, PROJ.USE = PROJ.USE)
East_Cst_cropped  = LOAD.AND.PREP.GIS(SHPNAME="East_Cst_cropped", PROJECT.PATH = GIS.PATH, PROJ.USE = PROJ.USE)
HABareas = gUnion(East_Cst_cropped,HABareas)


source(file.path(ML.CODE.PATH, "Step4_mackerel_and_herring_individually.R"))


### GIS layers are ONLY used for mapping, they do not get used to cut donuts.
# Code up the appropriate version of step 5


# Source step 5


#################################################
# STEP 3 -- Set your mapping options
#################################################

#### WHAT ARE YOU TRYING TO MAP?
sp1<-"herring_QTYKEPT"
z<-paste0("*",sp1,"*.tif")
mypat1<-glob2rx(z)

outfilestub<-"herring_pounds_avg"

# Source the generic step 5 here
source(file.path(ML.CODE.PATH, "Step5_aggregate_regimes.R"))


#### WHAT ARE YOU TRYING TO MAP?
sp1<-"mackerel_QTYKEPT"
z<-paste0("*",sp1,"*.tif")
mypat1<-glob2rx(z)

outfilestub<-"mackerel_pounds_avg"

# Source the generic step 5 here

source(file.path(ML.CODE.PATH, "Step5_aggregate_regimes.R"))


# Source the new version of step 7


source(file.path(ML.CODE.PATH, "Step7_check_confidentiality_general.R"))
