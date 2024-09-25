#################################################################################
#################################################################################
### HERE IS THE TABLE OF CONTENTS 
# SECTION 1 -- Set up directories 
# SECTION 2  - LOAD PACKAGES 
# SECTION 3 - SPECIFY MAPPING OPTIONS
# SECTION 4 - LOAD EXISTING GIS DATA
# SECTION 5 - MAKE MAPS

###### This script will sum together various geotiffs

todaysdate = as.Date(Sys.time())

#################################################################################
# Section 1 -- Set up directories 
#################################################################################
#################################################################################
#################################################################################

# #THIS SECTION CONTAINS PLACES TO LOOK FOR DATA
ML.NETWORK.LOCAL=file.path("/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee") #THIS Is what you need to run local
ML.NETWORK.SERVER=file.path("/net/home2/mlee") #This Is what you need to run from the network.
PROJECT.NAME="FW7_initial"

ML.NETWORK.PATH=file.path(ML.NETWORK.SERVER) # Tell R which to use (local or server)

ML.PROJECT.PATH=file.path(ML.NETWORK.PATH,"RasterRequests")

ML.CODE.PATH=file.path(ML.PROJECT.PATH,"code","herring_scripts","herring_FW7")

ML.OUTPUT.IMAGE.PATH=file.path(ML.PROJECT.PATH,"outputs","images",PROJECT.NAME)
ML.OUTPUT.GEOTIFF.PATH=file.path(ML.PROJECT.PATH,"outputs","geotiff",PROJECT.NAME,paste0(PROJECT.NAME,"_AGGREGATED_2019-12-10"))

export.geotiff.path = ML.OUTPUT.GEOTIFF.PATH
export.image.path = file.path(ML.OUTPUT.IMAGE.PATH,paste0(PROJECT.NAME,"_","2019-12-10"))
dir.create(export.image.path, recursive=T)

#where is the manifest of individual rasters?
individual.raster.file="individual_payload2019-12-05.Rds"
ML.DATA.PATH=file.path(ML.PROJECT.PATH,"data")

payloadRDS=file.path(ML.DATA.PATH,individual.raster.file)



ML.GIS.PATH= file.path(ML.NETWORK.PATH, "spatial data") #Min-Yang stores some of his spatial data in this folder

################################
#SSB DRIVE
#THIS MAY CHANGE IF YOU ARE NOT MINYANG.
################################
SSB.LOCAL = file.path("/run/user/1877/gvfs/smb-share:server=net,share=socialsci") #This is what you need to run local
SSB.NETWORK=file.path("/net/work5/socialsci") #This is what you need to run networked
SSB.DRIVE = file.path(SSB.NETWORK)

################################
#THESE LINES SHOULD NOT CHANGE.
GD.RASTERS = file.path(SSB.DRIVE, "Geret_Rasters")
GD.INVIDVIDUALRASTERS = file.path(GD.RASTERS, "Data", "individualrasters") 
GD.GIS.PATH = file.path(GD.RASTERS, "Data")
source(file.path(GD.RASTERS,"FINAL_Raster_Functions.R"))

#GENERIC GIS FOLDER (These are maintained by Sharon Benjamin) 
GENERIC.GIS.PATH= file.path(SSB.DRIVE, "GIS")
FREQUENT.USE.SSB= file.path(GENERIC.GIS.PATH, "FrequentUseSSB")
################################




#####################################################
## OUTPUT LOCATIONS
#####################################################
exportfolder = file.path(export.geotiff.path)
dir.create(exportfolder, recursive=T)

YOUR.STORAGE.PATH=file.path(exportfolder)  #To recap, we are storing things in the folder "output" which is in the directory defined by ML.OUTPUT.GEOTIFF.PATH
#################################################################################
# END OF SECTION 1  
#################################################################################





#################################################################################
# SECTION 2  - LOAD PACKAGES 
#################################################################################

#Load/Install necessary libraries
#not all of these are required, but I'm too lazy to pull out the ones that are not.
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

substrRight <- function(b, n){
  substr(b, nchar(b)-n+1, nchar(b))
}



#################################################
# STEP 3 -- Set your mapping options
#################################################
#### WHAT ARE YOU TRYING TO MAP?
#sp1<-"hrgmack_REVENUE"
sp1<-"herringnoPUR_QTYKEPT"
z<-paste0("*",sp1,"*.tif")
mypat1<-glob2rx(z)

outfilestub<-"herring_pounds_noPUR_avg_"

############################
#3C. This code contains  options to pass to levelplot.  ?levelplot, ?lattice, and ?xyplot may be helpful.
############################
##These are options that you can pass to levelplot.  It can help ensure that you have identical windows
# xlim= and ylim= options can used to set the window
# scale= options can be use to scale things (or turn off axes)
# par.setting= is used to set the color theme
# at= is used for custom binning

my.ylimit=c(-200000,900000)
my.xlimit=c(1700000,2600000)
#my.at <- seq(10, 2500, 500) #this defines equal intervals from 10 to 2500 by 500 units.
myscaleopts <- list(draw=FALSE) #Don't draw axes
# myscaleopts <- list(draw=TRUE) #draw axes

#mycoloropts <- myBLUETHEME #Use the theme "myBLUETHEME" defined above
#mycoloropts <- mydichrome  #Use the theme "mydichrome" defined above

myckey <- list(labels=list(cex=2)) #This makes the scale of the labels "big"

##HERE ARE SOME OPTIONS TO PASS TO PNG
png.height<-1000
png.width<-1000

## land color 
mylandfill<- "#d1d1e0"
############################











##############################################
## SECTION 4 - LOAD EXISTING GIS DATA
#################################################
#DEFINE OUR PROJECTION
PROJ.USE = CRS('+proj=aea +lat_1=28 +lat_2=42 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0 ') 
# Albers Equal Area conic (in meters)
#coastline  = LOAD.AND.PREP.GIS(SHPNAME="Coastline_Eastern_US", PROJECT.PATH = GENERIC.GIS.PATH, PROJ.USE = PROJ.USE)


## <--- LOAD AND PREP DISSOLVES. 
#We don't want to do that, so we'll just load and transform to the appropriate
# You might want to load a different "basemap" the stat areas are nice because they also include the coast.
# STATISTICAL AREAS
# my_basemap1 = readOGR(dsn=file.path(ML.GIS.PATH,"nmfs spatial data","corrected_stat_areas"), layer="Statistical_Areas", verbose=F)
# my_basemap1 = spTransform(my_basemap1, CRS=PROJ.USE)
# 
# #THIRTY MINUTE SQUARES
# my_basemap = readOGR(dsn=file.path(ML.GIS.PATH,"nmfs spatial data", "Thirty_Minute_Squares"), layer="Thirty_Minute_Squares", verbose=F)
# my_basemap = spTransform(my_basemap, CRS=PROJ.USE)
# 
# # Herring Management areas
# my_HMAs = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures", "garfo gis", "Herring_Management_Areas"), layer="Herring_Management_Areas_mod", verbose=F)
# my_HMAs = spTransform(my_HMAs, CRS=PROJ.USE)


#################################################
## END SECTION 4 
#################################################

list1<- lapply(as.list(list.dirs(path=ML.OUTPUT.GEOTIFF.PATH, recursive=T)), list.files, recursive=F, full.names=T, pattern=mypat1)
parsed_list1 = do.call(rbind, lapply(list1, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILENAME" 
  return(xx) }) )      


parsed_list1$NAME = sapply(parsed_list1$FILENAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })

parsed_list1$NAME <-gsub(".tif","",parsed_list1$NAME)

parsed_list1$MONTH = as.numeric(sapply(parsed_list1$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[1]) }))

parsed_list1$type = as.character(sapply(parsed_list1$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[2]) }))


parsed_list1$metric = as.character(sapply(parsed_list1$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[3]) }))


parsed_list1$YEAR = as.numeric(sapply(parsed_list1$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[4]) }))

parsed_list1$REGIME<-0
parsed_list1$REGIME[which(parsed_list1$YEAR>=2008 & parsed_list1$YEAR<=2015)]<-1
parsed_list1$REGIME[which(parsed_list1$YEAR>=2016 & parsed_list1$YEAR<=2018)]<-2



# Classify into old, medium, new
# Drop 2000
# What you want to do is generate a new variable 0,1,2 based on YEAR. THen loop over 0,1,2.
# and 



# yearfileswanted <- parsed_list1[which(parsed_list1$YEAR>=2001 & parsed_list1$YEAR<=2005),]
# yearfileswanted <- yearfileswanted[which(yearfileswanted$YEAR<=2005),]


for (mymonth in 1:12) {
for (myr in 1:2)  {
   yearfileswanted <- parsed_list1[which(parsed_list1$REGIME==myr & parsed_list1$MONTH==mymonth),]
if (nrow(yearfileswanted)==0){
#If there are no matching files, do nothing
  }
else{   
# If there is at least 1 matching file, build the name
outfilename<-paste0(outfilestub,"month_",mymonth,"_regime_",myr,".tif")
  
f<-extent(raster(file.path(yearfileswanted$FILENAME[1])))
new_xmin<-xmin(f)
new_ymin<-ymin(f)
new_xmax<-xmax(f)
new_ymax<-ymax(f)


if (nrow(yearfileswanted)==1){
#There's nothing really to do except save the raster as outfilename  
  holding_summer<-raster(file.path(yearfileswanted$FILENAME[1]))
  writeRaster(holding_summer, filename=file.path(exportfolder,outfilename), overwrite=TRUE)
}
else{
for (pp in 2:nrow(yearfileswanted)){
  f<-extent(raster(file.path(yearfileswanted$FILENAME[pp])))
  new_xmin<-min(new_xmin,xmin(f))
  new_ymin<-min(new_ymin,ymin(f))
  new_xmax<-max(new_xmax,xmax(f))
  new_ymax<-max(new_ymax, ymax(f))
}

## THIS SETS THE NEW EXTENT
f3<-extent(new_xmin,new_xmax, new_ymin, new_ymax)





holding_summer<-extend(raster(file.path(yearfileswanted$FILENAME[1])), f3, value=0)

for (ppp in 2:nrow(yearfileswanted)){
  temp<-extend(raster(file.path(yearfileswanted$FILENAME[ppp])), f3, value=0)
  holding_summer<-temp+holding_summer
  }
}

#divide by the number of years
nyears<-length(unique(yearfileswanted$YEAR))
holding_summer<-holding_summer/nyears
writeRaster(holding_summer, filename=file.path(exportfolder,outfilename), overwrite=TRUE)
}

}
}




