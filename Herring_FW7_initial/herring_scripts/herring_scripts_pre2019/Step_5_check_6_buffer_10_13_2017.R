#Creating count of trip id and percent of trip calculated to fall within a certain shapefile
#Geret DePiper
#August 2015
#Check the buffers for "MWT only" for herring and mackerel revenue


todaysdate = as.Date(Sys.time())
print(Sys.time())

max.nodes=24
START.YEAR = 2000   #Min = 1996
END.YEAR = 2015     #Max = 2013

#Setting directories (currently for server run)
##YOU NEED TO CHANGE THESE THREE LINES of CODE TO POINT TO YOUR NETWORK SHARE
ML.NETWORK.LOCAL=file.path("/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee") #THIS Is what you need to run local
ML.NETWORK.SERVER=file.path("/net/home2/mlee") #This Is what you need to run from the network.


YOUR.NETWORK.PATH=file.path(ML.NETWORK.SERVER) # Tell R which to use (local or server)

YOUR.PROJECT.PATH=file.path(YOUR.NETWORK.PATH,"RasterRequests")


ML.GIS.PATH= file.path(YOUR.NETWORK.PATH, "spatial data") #Min-Yang stores some of his spatial data in this folder

SSB.LOCAL = file.path("/run/user/1877/gvfs/smb-share:server=net,share=socialsci") #This is what you need to run local
SSB.NETWORK=file.path("/net/work5/socialsci") #This is what you need to run networked


exportfolder = file.path(YOUR.PROJECT.PATH,paste0("confid_check_",todaysdate))
dir.create(exportfolder, recursive=T)

YOUR.STORAGE.PATH=file.path(exportfolder)  


SSBdrive = file.path(SSB.NETWORK)
rasterfolder = file.path(SSBdrive, "Data", "individualrasters") 

#GENERIC GIS FOLDER (These are maintained by Sharon Benjamin) 
GENERIC.GIS.PATH= file.path(SSBdrive, "GIS")
FREQUENT.USE.SSB= file.path(GENERIC.GIS.PATH, "FrequentUseSSB")
################################
AREA.PATH= exportfolder

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
# East_Cst_cropped  = LOAD.AND.PREP.GIS(SHPNAME="East_Cst_cropped", PROJECT.PATH = GIS.PATH, PROJ.USE = PROJ.USE)





#LOAD IN THE INVENTORY OF RASTERS
load(file.path(SSBdrive,"Geret_Rasters","Data","RasterDate.Rdata"))
fla<-FILE_INFO[c(1:4)]
fla$YEAR<- as.numeric(fla$YEAR)
rm(list="FILE_INFO")

#LOAD AND SUBSET MY DATA
FINAL2=data.frame()

for (yr in START.YEAR:END.YEAR)  {
FINAL <- read.dbf(file = paste0(SSBdrive,"/Geret_Rasters/Data/ExportAll",yr,".dbf"))
# FINAL = subset(FINAL, select=-c(distance25, distance50, distance75, distance90, distance95))
# FINAL = FINAL[which(!is.na(FINAL[[FIELD]])),]
# FINAL = FINAL[which(FINAL[[FIELD]]!=0),]

FINAL=FINAL[which(FINAL$NESPP3 %in% c("168","212")),]
FINAL=FINAL[which(FINAL$GEARCODE %in% c("OTM","PTM")),] # <-MWT and PUR
FINAL = FINAL[which(FINAL$REVENUE>0),]

FINAL2=rbind(FINAL,FINAL2)
}

#This is the set of IDNUMS that I'll need to check
fl=fla[which(fla$IDNUM%in%FINAL2$IDNUM),]
#A bit of a hack: this is <duplicates, drop>
fl=unique(fl)

# 
# fl = do.call(rbind, lapply(U.IDNUM, function(xx) {
#   xx = as.data.frame(xx, stringsAsFactors=F)
#   names(xx) = "IDNUM" 
#   return(xx) }) )                                         




LOAD.AND.PREP.GIS <- function(SHPNAME, PROJECT.PATH = PROJECT.PATH, PROJ.USE = PROJ.USE) {
  SHP = readOGR(dsn=file.path(PROJECT.PATH), layer=SHPNAME, verbose=T)
  SHP = spTransform(SHP, CRS=PROJ.USE)
  if(NROW(SHP)>1) {
    SHP = gBuffer(SHP, width=1, byid=T) 
    }
  stopifnot(gIsValid(SHP))
  return(SHP)
}

#Load in the buffer files
my_6nm<-LOAD.AND.PREP.GIS("USCoastline_clipped_6nm",PROJECT.PATH=file.path(ML.GIS.PATH,"basic spatial data", "USCoastline"),  PROJ.USE=PROJ.USE)
my_12nm<-LOAD.AND.PREP.GIS("USCoastline_clipped_12nm",PROJECT.PATH=file.path(ML.GIS.PATH,"basic spatial data", "USCoastline"),  PROJ.USE=PROJ.USE)
my_25nm<-LOAD.AND.PREP.GIS("USCoastline_clipped_25nm",PROJECT.PATH=file.path(ML.GIS.PATH,"basic spatial data", "USCoastline"),  PROJ.USE=PROJ.USE)
my_50nm<-LOAD.AND.PREP.GIS("USCoastline_clipped_50nm",PROJECT.PATH=file.path(ML.GIS.PATH,"basic spatial data", "USCoastline"),  PROJ.USE=PROJ.USE)
my_35nm<-LOAD.AND.PREP.GIS("USCoastline_clipped_35nm",PROJECT.PATH=file.path(ML.GIS.PATH,"basic spatial data", "USCoastline"),  PROJ.USE=PROJ.USE)

#Load in the HMA, remove the 1A, and make a single object
my_HMAs = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures", "garfo gis", "Herring_Management_Areas"), layer="Herring_Management_Areas_mod", verbose=F)
my_HMAs = spTransform(my_HMAs, CRS=PROJ.USE)
sub<-my_HMAs[my_HMAs@data$GARFO_ID != c("G000167") , ]
sub_1B23<-gBuffer(sub,width=.1, byid=F)


#Load in the HMA
# AREA_SHP= LOAD.AND.PREP.GIS(SHPNAME="Thirty_Minute_Squares", PROJECT.PATH = file.path(ML.GIS.PATH,"nmfs spatial data", "Thirty_Minute_Squares"), PROJ.USE = PROJ.USE)
# AREA_SHP<-AREA_SHP[which(AREA_SHP$NERO_ID %in% c(114)),]

# foreach buffer file:  Intersect the buffer with the HMA. Store this somewhere  Save this as AREA_SHP.
AREA_SHP50<-gIntersection(sub_1B23,my_50nm)
 AREA_SHP35<-gIntersection(AREA_SHP50,my_35nm)
 AREA_SHP25<-gIntersection(AREA_SHP35,my_25nm)
 AREA_SHP12<-gIntersection(AREA_SHP25,my_12nm)
 AREA_SHP6<-gIntersection(AREA_SHP12,my_6nm)
 mybuffers<-c(50,35,25,12,6)
# Create one single-column dataframe with all elements in form of the filepath, but R recgonizes it only as text
# Dataframe with ~1.8 million records (comercial only) 


#setup the results matrix -- IDNUM, 6,12,25, 35, and 50 percentages

 
 MGAREA = c('buffer')
 
 sfInit(parallel=T, cpus=max.nodes)
 sfLibrary(raster, verbose=F)
 sfLibrary(sp, verbose=F)
 sfLibrary(rgeos, verbose=F)
 sfLibrary(rgdal, verbose=F)
 sfLibrary(R2HTML, verbose=F)
 for (yr in START.YEAR:END.YEAR)  {
   fileswanted <- fl[which(fl$YEAR == yr),]
   fileswanted$RAND = as.factor(sample.int(max.nodes, size=NROW(fileswanted), replace=T) )
   fileswanted = split(fileswanted$FILEPATH, f=fileswanted$RAND)
   fileswanted = lapply(fileswanted, as.list)
   row.names(fileswanted) = fileswanted$IDNUM   
   YEAR = yr
   
   sfExport("fileswanted","BASE.RASTER","YEAR")
   for (ar in MGAREA){
     ptm.TOT = Sys.time()
     AREA = ar

          sfExport("AREA","AREA_SHP50","AREA_SHP35","AREA_SHP25","AREA_SHP12","AREA_SHP6")
     
     ACTIVITY = sfLapply(fileswanted,function(x,...) {     #usually run in sfLapply
       ERRS = as.character(0) # create empty character vector 
       
       NR = as.numeric(NROW(x)) #NR = number of rows in fileswanted
       id.list <- matrix(nrow = NR,ncol = 8)
       colnames(id.list) <- c("IDNUM","Area","Year","Inside50", "Inside35","Inside25","Inside12","Inside6")
       BR = seq(1,NR,by=25) #BR is a sequence 
       if(!NR%in%BR) BR=c(BR, NR) # takes bricks of 25 
       for (i in 1:(NROW(BR)-1)){ #use row # of what's in that "brick" 
         t.index = (BR[i]):(BR[i+1]-1)
         if(i==(NROW(BR)-1)) (t.index = (BR[i]):(BR[i+1])) 
         for (j in t.index) {   
           tt = raster(x[[j]])
           tt = mask(tt, AREA_SHP50, byid=c(T,F), id=row.names(tt))
           tts <- unlist(as.numeric(cellStats(tt,stat='sum')))
           ID =  unlist(strsplit(x[[j]], split = ".gri"))
           ID = do.call(rbind,strsplit(as.character(ID), split = "/"))
           ID = as.character(ID[NCOL(ID)])
           #if(tt!=0) {
           id.list[j,1] <- ID
           id.list[j,2] <- AREA
           id.list[j,3] <- YEAR
           id.list[j,4] <- as.numeric(tts)                      
           # }
           tt = mask(tt, AREA_SHP35, byid=c(T,F), id=row.names(tt))
           tts <- unlist(as.numeric(cellStats(tt,stat='sum')))
           id.list[j,5] <- as.numeric(tts)                      
           tt = mask(tt, AREA_SHP25, byid=c(T,F), id=row.names(tt))
           tts <- unlist(as.numeric(cellStats(tt,stat='sum')))
           id.list[j,6] <- as.numeric(tts)                      
           tt = mask(tt, AREA_SHP12, byid=c(T,F), id=row.names(tt))
           tts <- unlist(as.numeric(cellStats(tt,stat='sum')))
           id.list[j,7] <- as.numeric(tts)                      
           tt = mask(tt, AREA_SHP6, byid=c(T,F), id=row.names(tt))
           tts <- unlist(as.numeric(cellStats(tt,stat='sum')))
           id.list[j,8] <- as.numeric(tts)                      
        }
       }
       return(list(id.list, ERRS))})
     ACTIVITY <- do.call(rbind,lapply(ACTIVITY,data.frame,stringsAsFactors=FALSE) )
     #ACTIVITY$Inside <- as.numeric(as.character(ACTIVITY$Inside))
     #ACTIVITY <- ACTIVITY[which(ACTIVITY$Inside!=0),]
     save(ACTIVITY, file = paste(AREA.PATH, "/",AREA,"_",YEAR,".RData", sep = ''))
   }
   print(paste0("Total run time ",round(difftime(Sys.time(), ptm.TOT, units='min'), 2), " mins for",AREA,YEAR))
   
 }
 sfStop() 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
#  
#  
#  
#  
#  
#  
#  
#  
# results=matrix(0,nrow=nrow(fl), ncol=6)
# print(Sys.time())
# 
# 
# pb <- txtProgressBar(min = 0, max = nrow(fl), style = 3)
# 
# 
# for (i in 1:nrow(fl)){
#   tt = raster(fl$FILEPATH[i])
#   tt = mask(tt, AREA_SHP50, byid=c(T,F), id=row.names(tt)) #HERE
#   r50 <- as.numeric(cellStats(tt,stat='sum'))
#   
#   tt = mask(tt, AREA_SHP35, byid=c(T,F), id=row.names(tt)) #HERE
#   r35 <- as.numeric(cellStats(tt,stat='sum'))
#   
#   tt = mask(tt, AREA_SHP25, byid=c(T,F), id=row.names(tt)) #HERE
#   r25 <- as.numeric(cellStats(tt,stat='sum'))
#   
#   tt = mask(tt, AREA_SHP12, byid=c(T,F), id=row.names(tt)) #HERE
#   r12 <- as.numeric(cellStats(tt,stat='sum'))
#   
#   tt = mask(tt, AREA_SHP6, byid=c(T,F), id=row.names(tt)) #HERE
#   r6 <- as.numeric(cellStats(tt,stat='sum'))
# 
#   results[i,1]<-fl$IDNUM[i]
#   results[i,2]<-r6
#   results[i,3]<-r12
#   results[i,4]<-r25
#   results[i,5]<-r35
#   results[i,6]<-r50
#   setTxtProgressBar(pb, i)
#  }
# close(pb)
# 
# table_name<-"buffer_check"
# write.table(results,(file.path(YOUR.STORAGE.PATH, paste0(table_name,".csv"))) , sep=",", row.names=FALSE, col.names=c("GEARID", "in6", "in12", "in25", "in35", "in50"))  
# print(Sys.time())

