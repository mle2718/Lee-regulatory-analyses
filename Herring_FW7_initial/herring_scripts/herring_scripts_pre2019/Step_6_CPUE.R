

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

exportfolder = file.path(ML.PROJECT.PATH,paste0(todaysdate, "_CPUE_rasterexport"))


#UPDATE WITH NEW CATCH FOLDERS

effortfolder = file.path(ML.PROJECT.PATH,"2016-07-26_rasterexport")


dir.create(exportfolder, recursive=T)
GIS.PATH = file.path(SSBdrive, "Data")
source(file.path(SSBdrive,"FINAL_Raster_Functions.R"))


#Define years to create rasters for here
START.YEAR = 2010   #Min = 1996
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
BASE.RASTER = raster(file.path(SSBdrive,"Data","BASERASTER_AEA_2"))

#HABareas = LOAD.AND.PREP.GIS(SHPNAME="mults_efh", PROJECT.PATH = GIS.PATH, PROJ.USE = PROJ.USE)
#East_Cst_cropped  = LOAD.AND.PREP.GIS(SHPNAME="East_Cst_cropped", PROJECT.PATH = GIS.PATH, PROJ.USE = PROJ.USE)
#HABareas = gUnion(East_Cst_cropped,HABareas)
### GIS layers are ONLY used for mapping, they do not get used to cut donuts.


#catch has all 
#catch2 has 
catch_filelist = lapply(as.list(list.dirs(path=effortfolder, recursive=T)), list.files, recursive=T, full.names=T, pattern=glob2rx("*QTYKEPT*.tif"))

#effort has MWT and all
effort_filelist = lapply(as.list(list.dirs(path=effortfolder, recursive=T)), list.files, recursive=T, full.names=T, pattern=glob2rx("*fishing_hours*.tif"))

 fl = do.call(rbind, lapply(catch_filelist, function(xx) {
   xx = as.data.frame(xx, stringsAsFactors=F)
   names(xx) = "FILEPATH" 
   return(xx) }) )                                         
 fl$STRIPGRID =  sapply(fl$FILEPATH, USE.NAMES=F, function(zz) {
   strsplit(x = as.character(zz), split = ".tif")[[1]]
 })
 
 fl$NAME = sapply(fl$STRIPGRID, USE.NAMES=F, function(zz) {
   temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
   return(temp[NCOL(temp)]) })
 
 fl$FLEET="ALL"
 fl$FLEET[grep('MWT', fl$NAME)]<-"MWT" 
 
 
 fl$MONTH = sub('Q$',' ',str_sub(fl$NAME,1,2)) 

 fl$MONTHa<-sub('Q$',' ',str_sub(fl$NAME,5,6)) 
 v<-fl$FLEET == "MWT"
 
 fl[v,"MONTH"]<-fl[v,"MONTHa"]
 
 fl = subset(fl, select=-c(MONTHa))
 


fle = do.call(rbind, lapply(effort_filelist, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILEPATH_eff" 
  return(xx) }) )                                         
fle$STRIPGRID_eff =  sapply(fle$FILEPATH_eff, USE.NAMES=F, function(zz) {
  strsplit(x = as.character(zz), split = ".tif")[[1]]
})
fle$NAME_eff = sapply(fle$STRIPGRID_eff, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })



fle$FLEET_eff="ALL"
fle$FLEET_eff[grep('MWT', fle$NAME_eff)]<-"MWT" 



fle$MONTH_eff = sub('f$',' ',str_sub(fle$NAME_eff,1,2)) 
fle$MONTHa = sub('f$',' ',str_sub(fle$NAME_eff,5,6)) 
v<-fle$FLEET_eff == "MWT"
fle[v,"MONTH_eff"]<-fle[v,"MONTHa"]

fle = subset(fle, select=-c(MONTHa))

rm(v)

#Merge catch and effort files, based on month and fleet

FINAL<-merge(fl, y=fle, all.x=TRUE, all.y=FALSE, by.x=c('FLEET','MONTH'), by.y=c('FLEET_eff','MONTH_eff') )


for (pp in 1:nrow(FINAL)){
  
  outfilename<-paste0("FLEET_", FINAL$FLEET[pp], "_MONTH_",FINAL$MONTH[pp],".tif")
  outfilename<- str_replace_all(string=outfilename, pattern=" ", repl="")
  
  #READ in  the catch raster
  catch<-raster(file.path(FINAL$FILEPATH[pp]))
  cextent<-extent(catch)
  new_xmin<-xmin(cextent)
  new_ymin<-ymin(cextent)
  new_xmax<-xmax(cextent)
  new_ymax<-ymax(cextent)
  
  #READ IN THE extent of the effort rasters
  
  effort<-raster(file.path(FINAL$FILEPATH_eff[pp]))
  eff_extent<-extent(effort)
  new_xmin<-min(new_xmin,xmin(eff_extent))
  new_ymin<-min(new_ymin,ymin(eff_extent))
  new_xmax<-max(new_xmax,xmax(eff_extent))
  new_ymax<-max(new_ymax, ymax(eff_extent))
  
  
  f3<-extent(new_xmin,new_xmax, new_ymin, new_ymax)
  
  catch<-extend(catch,f3, value=0)
  effort<-extend(effort,f3, value=0)
  
  
  
  cpue<-catch/effort
  
  
  
  

  
  
  writeRaster(cpue, filename=file.path(exportfolder,outfilename), overwrite=TRUE)
  
}
#Loop over rows

#read in both catch and effort rasters
#compute CPUE
#MAP CPUE
#SAVE the tif files.

