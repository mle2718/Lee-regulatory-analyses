
#########################
# You used this file to construct the scallop revenue tifs at the year-permit category year.
# The rasterfolder is pointing to the location of the GGGGGGGGGG_CrevenueYYYY.tif files that are created by Step4_v2_Sum_scallop_rasters_ml.R
#  (Step4_v2_Sum_scallop_rasters_ml.R builds yearly GEOID_Cat revenue geotifs.
#############
#### (1) - Set your info

todaysdate = as.Date(Sys.time())


#I Set this up to run at the end of the STEP4...JULY2016.R
#Which means that I've passed "todaysdate" from that file to this. 

yourname = "Min-Yang"
youremail = "Min/-Yang.Lee@noaa.gov"
max.nodes = 4 #processor nodes

#### Set directories
SSB.NETWORK=file.path("/net/work5/socialsci") #This is what you need to run networked


SSBdrive = file.path(SSB.NETWORK, "Geret_Rasters") #when running R script off Linux server
ML.NETWORK.LOCAL=file.path("/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee") #THIS Is what you need to run local
ML.NETWORK.SERVER=file.path("/net/home2/mlee") #This Is what you need to run from the network.


GIS.PATH = file.path(SSBdrive, "Data")
source(file.path(SSBdrive,"FINAL_Raster_Functions.R"))



##YOU MIGHT HAVE TO CHANGE THESE LINES 
YOUR.NETWORK.PATH=file.path(ML.NETWORK.SERVER) # Tell R which to use (local or server)
ML.GIS.PATH= file.path(YOUR.NETWORK.PATH, "spatial data") #Min-Yang stores some of his spatial data in this folder


#where you putting the output?
ML.PROJECT.PATH=file.path(YOUR.NETWORK.PATH,"RasterRequests")
exportfolder = file.path(ML.PROJECT.PATH,"GARFO")


#Where is the folder that contains the rasters that you are aggregating?
rasterfolder = file.path(ML.PROJECT.PATH,"2016-03-07_rasterexport")


dir.create(exportfolder, recursive=T)# outputfolder = file.path(workplace, "outputs")




#### Set directories

#Define years to create rasters for here
START.YEAR = 2000   #Min = 1996
END.YEAR = 2014     #Max = 2013

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

if(!require(stringr)) {  
  install.packages("stringr")
  require(stringr)}





## Load GIS maps
PROJ.USE = CRS('+proj=aea +lat_1=28 +lat_2=42 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0 ') 
# Albers Equal Area conic (in meters)
#BASE.RASTER = raster(file.path(SSBdrive,"Data","BASERASTER_AEA_2"))

#This is a big modification from Geret's original code. Since everything is in a single folder, 
# A.  I can just pass <rasterfolder>.
# B. I can set full.names=F

# Helpful function for extracting strings later 
substrRight <- function(b, n){
  substr(b, nchar(b)-n+1, nchar(b))
}

filelist=lapply(as.list(rasterfolder), list.files, recursive=T, full.names=F, pattern=glob2rx("MWT_168*.tif"))

#The following create new dataframe fields for IDnum and year..
fl = do.call(rbind, lapply(filelist, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILENAME" 
  return(xx) }) )                 

fl$GEOID = sapply(fl$FILENAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[1]) })

fl$CAT = sapply(fl$FILENAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[NCOL(temp)]) })


#I'm using this, because I'm not sure if the leading zeros were maintained.
fl$YEAR <-   substr(substrRight(fl$FILENAME,8),1,4)


## You have a dataframe (fl) that indexes the things that you care about. 

#The next step is to sum up the things you care about

#strategy
#loop over years 
#loop over cats


  yearfileswanted <- fl
  f<-extent(raster(file.path(rasterfolder,yearfileswanted$FILENAME[1])))
  new_xmin<-xmin(f)
  new_ymin<-ymin(f)
  new_xmax<-xmax(f)
  new_ymax<-ymax(f)
  
  
  for (pp in 2:nrow(yearfileswanted)){
    f<-extent(raster(file.path(rasterfolder,yearfileswanted$FILENAME[pp])))
    new_xmin<-min(new_xmin,xmin(f))
    new_ymin<-min(new_ymin,ymin(f))
    new_xmax<-max(new_xmax,xmax(f))
    new_ymax<-max(new_ymax, ymax(f))
  }
  
  ## THIS SETS THE NEW EXTENT
  f3<-extent(new_xmin,new_xmax, new_ymin, new_ymax)
  
  
  outfilename<-paste0(substr(fl$FILENAME[1],1,7),".tif")
  
    
    
  fileswanted <- yearfileswanted
  
    holding_summer<-extend(raster(file.path(rasterfolder,fileswanted$FILENAME[1])), f3, value=0)

      for (ppp in 2:nrow(fileswanted)){
        temp<-extend(raster(file.path(rasterfolder,fileswanted$FILENAME[ppp])), f3, value=0)
        holding_summer<-temp+holding_summer
      }
      writeRaster(holding_summer, filename=file.path(exportfolder,outfilename), overwrite=TRUE)
     








     

  
  #This took about 20 minutes to crank through the 1996-2014 GEOID_CrevenueYYYY.tif files.
  