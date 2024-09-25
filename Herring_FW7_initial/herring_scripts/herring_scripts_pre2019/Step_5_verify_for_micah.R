###### This script is one of two that are used to get haddock CPUE for micah
# Time span: Jan, 2010 to Dec, 2015
# Time Step: monthly
# Species : haddock
# field: qtykept
# MARGIN: MONTH (YEAR is automagically a margin)
#####



todaysdate = as.Date(Sys.time())

#### (1) - Set your info
yourname = "Min-Yang"
youremail = "minyang@gmail.com"
max.nodes = 30 #processor nodes
#### Set directories
SSBdrive = file.path("/net/work5/socialsci/Geret_Rasters") #when running R script off Linux server
rasterfolder = file.path(SSBdrive, "Data", "individualrasters") 
bonusfolder=file.path(SSBdrive,"ECON_GEO","bonus_rasters")

ML.NETWORK.PATH=file.path("/net/home2/mlee")
ML.PROJECT.PATH=file.path(ML.NETWORK.PATH,"RasterRequests")


exportfolder = file.path(ML.PROJECT.PATH,paste0("micah_dean",todaysdate, "_rasterexport"))


dir.create(exportfolder, recursive=T)
GIS.PATH = file.path(SSBdrive, "Data")
source(file.path(SSBdrive,"FINAL_Raster_Functions.R"))
#SET field you are trying to sum over
FIELD = c("QTYKEPT") #Like "REVENUE","QTYKEPT", "QTYDISC", or "CATCH"
#SET margin to sum over
MARGIN = c("MONTH") #Like "SPPNM","NESPP3","GEARCAT","FMP","STATE1" Comment out if want to sum over all margins in a year



#Define years to create rasters for here
START.YEAR = 2010   #Min = 1996
END.YEAR = 2010     #Max = 2013

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

if(!require(rasterVis)) {  
  install.packages("rasterVis")
  require(rasterVis)}


## Load GIS maps
PROJ.USE = CRS('+proj=aea +lat_1=28 +lat_2=42 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0 ') 
# Albers Equal Area conic (in meters)
BASE.RASTER = raster(file.path(SSBdrive,"Data","BASERASTER_AEA_2"))
### GIS layers are ONLY used for mapping, they do not get used to cut donuts.

#LOAD IN THE INVENTORY OF RASTERS
load(file.path(SSBdrive,"Data","RasterDate.Rdata"))
fl<-FILE_INFO[c(1:4)]
rm(list="FILE_INFO")
# If pulling permits based on conditions, set them here: 

#FINAL$GEARCAT <- as.factor(FINAL$GEARCAT)

#####################################################

##########################################################
#Need to account for fact that a very small # of points are completely on land and can't be spatially allocated 










#Load in extra data
extra_data<-read.csv(file=file.path(ML.NETWORK.PATH,"spatial data","herring_A8","fishing_time.csv"))
FINAL=data.frame()

for (yr in START.YEAR:END.YEAR)  {
  
  FINALa <- read.dbf(file = paste0(SSBdrive,"/Data/ExportAll",yr,".dbf"))
 # FINALa = subset(FINALa, select=-c(distance25, distance50, distance75, distance90, distance95))
  
  FINALa=FINALa[which(FINALa$NESPP3 %in% c("147")),]
  FINALa=FINALa[which(FINALa$GEARCODE %in% c("OTF")),] 
  FINAL=rbind(FINAL, FINALa)
  
}
FINAL<-merge(FINAL, y=extra_data, all.x=TRUE, all.y=FALSE, by.x=c('IDNUM'), by.y=c('gearid'))

#Drop obs with missing or zero fishing hours. Drop obs with missing or zero FIELD
FINAL = FINAL[which(!is.na(FINAL[["fishing_hours"]])),]
FINAL = FINAL[which(FINAL[["fishing_hours"]]!=0),]

FINAL = FINAL[which(!is.na(FINAL[[FIELD]])),]
FINAL = FINAL[which(FINAL[[FIELD]]!=0),]



###############
#SET field you are trying to sum over
FIELD = c("QTYKEPT") #Like "REVENUE","QTYKEPT", "QTYDISC", or "CATCH"
#SET margin to sum over
MARGIN = c("MONTH") #Like "SPPNM","NESPP3","GEARCAT","FMP","STATE1" Comment out if want to sum over all margins in a year

############

#Define years to create rasters for here
yr=START.YEAR
MARG=MARGIN

  #THIS IS THE NAME OF MY MARGIN VARIABLE
  
  RASTER_FILE = FINAL[which(FINAL$YEAR==yr),] 
  
  RASTER_FILE = RASTER_FILE[which(RASTER_FILE$IDNUM%in%fl$IDNUM),] 
  RASTER_FILE = aggregate(get(FIELD) ~ get(MARG) + IDNUM, data=RASTER_FILE, FUN = "sum")
  names(RASTER_FILE) <- c(paste0(MARG),"IDNUM",paste0(FIELD))
  MARGINS <- as.character(unique(RASTER_FILE[[paste0(MARG)]]))

#cond.ONE = paste0('FINAL$GEARNM ==',gear, collapse="")
#cond.ONE = FINAL$GEARCAT == "Clam Dredge"

####
#rastername = paste0(gear,yr)


#U.IDNUM = FINAL$IDNUM[cond.ONE & cond.TWO & cond.THREE & cond.FOUR & cond.FIVE]
U.IDNUM = unique(RASTER_FILE$IDNUM)

fileswanted <- fl[which(fl$IDNUM %in% U.IDNUM),]
fileswanted <- merge(fileswanted,y=subset(RASTER_FILE,select=c("IDNUM",paste0(MARG))))
fileswanted[[paste0(MARG)]] <- as.character(fileswanted[[paste0(MARG)]])
fileswanted$FILEPATH <- paste(fileswanted[['FILEPATH']],fileswanted[[paste0(MARG)]],sep="@")
fileswanted$FILEPATH <- paste0(fileswanted[['FILEPATH']],'@')
fileswanted = split(fileswanted$FILEPATH, f=fileswanted[[paste0(MARG)]])
fileswanted = lapply(fileswanted, as.list)
#fileswanted <- as.character(fileswanted)

# Number records
length(U.IDNUM)

#subset just january from the dbfs
jan<-FINAL[which(FINAL$MONTH==1),] 


#find the rasters
fl <- fl[which(fl$YEAR==2010),]
fl$MARK=1



#FINAL<-merge(FINAL, y=extra_data, all.x=TRUE, all.y=FALSE, by.x=c('IDNUM'), by.y=c('gearid'))







