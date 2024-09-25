###### This script pulls all queries rasters and sums them
###### creating a heat-map for any subset of VTR data.



todaysdate = as.Date(Sys.time())

#### (1) - Set your info
yourname = "Min-Yang"
youremail = "Min-Yang.Lee@noaa.gov"
max.nodes = 30 #processor nodes

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
if(!require(mail)) {  
  install.packages("mail")
  require(mail)}
if(!require(foreign)) {  
  install.packages("foreign")
  require(foreign)}
if(!require(scales)) {  
  install.packages("scales")
  require(scales)}
if(!require(R2HTML)) {  
  install.packages("R2HTML")
  require(R2HTML)}

#GIVE YOUR PROJECT A NAME
PROJECT.NAME="FW7_initial"


#### Set directories
SSB.NETWORK=file.path("/net/work5/socialsci") #This is what you need to run networked
SSBdrive = file.path(SSB.NETWORK, "Geret_Rasters") #when running R script off Linux server
rasterfolder = file.path(SSBdrive, "Data", "individualrasters") 

ML.NETWORK.PATH=file.path("/net/home2/mlee")
ML.PROJECT.PATH=file.path(ML.NETWORK.PATH,"RasterRequests")


#Where are the inputs for this project
ML.DATA.PATH=file.path(ML.PROJECT.PATH,"data")
GIS.PATH = file.path(SSBdrive, "Data")
source(file.path(SSBdrive,"FINAL_Raster_Functions.R"))


#where you putting the output?
ML.CODE.PATH=file.path(ML.PROJECT.PATH,"code","herring_scripts","herring_FW7")
ML.OUTPUT.IMAGE.PATH=file.path(ML.PROJECT.PATH,"outputs","images",PROJECT.NAME)
ML.OUTPUT.GEOTIFF.PATH=file.path(ML.PROJECT.PATH,"outputs","geotiff",PROJECT.NAME)


# You may want to make export_folders for ALL things - data, output images, output geotiffs 
#export.image.path = file.path(ML.OUTPUT.IMAGE.PATH,paste0(PROJECT.NAME,"_",todaysdate))
#dir.create(export.image.path, recursive=T)

export.geotiff.path = file.path(ML.OUTPUT.GEOTIFF.PATH,paste0(PROJECT.NAME,"_",todaysdate))
dir.create(export.geotiff.path, recursive=T)

#where is the manifest of individual rasters?
individual.raster.file="individual_payload2019-12-05.Rds"
payloadRDS=file.path(ML.DATA.PATH,individual.raster.file)


#exportfolder = file.path(ML.PROJECT.PATH,"MACKEREL_ALL_GEARS_11172016")
#dir.create(exportfolder, recursive=T)
#SET field you are trying to sum over
FIELD = "REVENUE" #Like "REVENUE","QTYKEPT", "QTYDISC", or "CATCH"
#SET margin to sum over
MARGIN = c("MY_MARGIN") #Like "SPPNM","NESPP3","GEARCAT","FMP","STATE1" Comment out if want to sum over all margins in a year

logical_subset<-quote(which(FINAL$NESPP3 %in% c(212)))
readable_name ="mackerel"
my_margin_name<-quote(paste(FINAL$MONTH,readable_name, sep="_"))



#Define years to create rasters for here
START.YEAR = 1996   #Min = 1996
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
### GIS layers are ONLY used for mapping, they do not get used to cut donuts.



source(file.path(ML.CODE.PATH, "Step_4_generic_raster_aggregator.R"))



