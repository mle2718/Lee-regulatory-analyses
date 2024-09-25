#Creating count of trip id and percent of trip calculated to fall within a certain shapefile
#Geret DePiper
#August 2015


max.nodes = 30 # Set to 12 when working on Server?
todaysdate = as.Date(Sys.time())
print(Sys.time())

START.YEAR = 1996   #Min = 1996
END.YEAR = 2015     #Max = 2013

#Setting directories (currently for server run)
##YOU NEED TO CHANGE THESE THREE LINES of CODE TO POINT TO YOUR NETWORK SHARE
ML.NETWORK.LOCAL=file.path("/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee") #THIS Is what you need to run local
ML.NETWORK.SERVER=file.path("/net/home2/mlee") #This Is what you need to run from the network.


YOUR.NETWORK.PATH=file.path(ML.NETWORK.SERVER) # Tell R which to use (local or server)

YOUR.PROJECT.PATH=file.path(YOUR.NETWORK.PATH,"RasterRequests")
YOUR.DATA.PATH=file.path(YOUR.PROJECT.PATH,"2016-07-21_task12_rasterexport") #This has monthly MWT and PUR yearly in it

ML.GIS.PATH= file.path(YOUR.NETWORK.PATH, "spatial data") #Min-Yang stores some of his spatial data in this folder

SSB.LOCAL = file.path("/run/user/1877/gvfs/smb-share:server=net,share=socialsci") #This is what you need to run local
SSB.NETWORK=file.path("/net/work5/socialsci") #This is what you need to run networked




SSBdrive = file.path(SSB.NETWORK)
rasterfolder = file.path(SSBdrive, "Data", "individualrasters") 

#GENERIC GIS FOLDER (These are maintained by Sharon Benjamin) 
GENERIC.GIS.PATH= file.path(SSBdrive, "GIS")
FREQUENT.USE.SSB= file.path(GENERIC.GIS.PATH, "FrequentUseSSB")
################################
AREA.PATH= file.path(YOUR.NETWORK.PATH, "spatial data") #Min-Yang stores some of his spatial data in this folder

GIS.PATH = file.path(SSBdrive, "Geret_Rasters","Data")

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

source(file.path(SSBdrive,"Geret_Rasters","FINAL_Raster_Functions.R"))

PROJ.USE = CRS('+proj=aea +lat_1=28 +lat_2=42 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0 ') 
# Albers Equal Area conic (in meters)
BASE.RASTER = raster(file.path(GIS.PATH,"BASERASTER_AEA_2"))
#East_Cst_cropped  = LOAD.AND.PREP.GIS(SHPNAME="East_Cst_cropped", PROJECT.PATH = GIS.PATH, PROJ.USE = PROJ.USE)



# 
# 
# #THIRTY MINUTE SQUARES
# my_basemap = readOGR(dsn=file.path(ML.GIS.PATH,"nmfs spatial data", "Thirty_Minute_Squares"), layer="Thirty_Minute_Squares", verbose=T)
# my_basemap = spTransform(my_basemap, CRS=PROJ.USE)
# 
# 
# 
# LOAD.AND.PREP.GIS <- function(SHPNAME, PROJECT.PATH = PROJECT.PATH, PROJ.USE = PROJ.USE) {
#   SHP = readOGR(dsn=file.path(PROJECT.PATH), layer=SHPNAME, verbose=T)
#   SHP = spTransform(SHP, CRS=PROJ.USE)
#   if(NROW(SHP)>1) {
#     SHP = gBuffer(SHP, width=1, byid=T) 
#     }
#   stopifnot(gIsValid(SHP))
#   return(SHP)
# }
# AREA_SHP= LOAD.AND.PREP.GIS(SHPNAME="Thirty_Minute_Squares", PROJECT.PATH = file.path(ML.GIS.PATH,"nmfs spatial data", "Thirty_Minute_Squares"), PROJ.USE = PROJ.USE)
# 
# AREA_SHP<-AREA_SHP[which(AREA_SHP$NERO_ID %in% c(99,100,114,115,123)),]
# 
# MGAREA = AREA_SHP$NERO_ID


load(file.path(AREA.PATH,"check_thirty_min_sq","1141998.RData"))




