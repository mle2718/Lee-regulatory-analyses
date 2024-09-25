#Creating count of trip id and percent of trip calculated to fall within a certain shapefile
#Geret DePiper
#August 2015

COMPUTERRATE = 86  #Approx # donuts per minute that computer can draw. Updates with rolling average. (For estimating time to run) 
COMPUTERNAME = "Geret"

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
# YOUR.DATA.PATH=file.path(YOUR.PROJECT.PATH,"2016-03-15_rasterexport") #Annual Kepts for 2006-2014, all herring
# YOUR.DATA.PATH=file.path(YOUR.PROJECT.PATH,"2016-03-07_rasterexport") #This has MWT and PUR yearly in it
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
East_Cst_cropped  = LOAD.AND.PREP.GIS(SHPNAME="East_Cst_cropped", PROJECT.PATH = GIS.PATH, PROJ.USE = PROJ.USE)





#LOAD IN THE INVENTORY OF RASTERS
load(file.path(SSBdrive,"Geret_Rasters","Data","RasterDate.Rdata"))
fl<-FILE_INFO[c(1:4)]
fl$YEAR<- as.numeric(fl$YEAR)
rm(list="FILE_INFO")






#test <- raster(paste(sd,"individualrasters","MA","2013","70766.grd",sep="/"))

#MGAREA = c('AprilJuneSpawn','ClamExemption1','CoxLedge','GBEFHexpanded2','GBEFHexpandedt','GBEFHSouth',
  #         'GBmortalityclosure','GBWesternArea','GeorgesShoal1MBTG','GeorgesShoal2MBGT','GeorgesShoalGMA',
   #        'GreatSouthChannel','GreatSouthChannelEast','GreatSouthChannelGMA','JuneSpawn','LargeBigelow',
     #      'LargeEMaine','Machias','MassBaySpawn','MayJuneSpawn','MaySpawn','NantucketShoals','NantucketShoalsWest',
      #     'NorthernEdge','NorthernEdgeReducedImpact','NorthernGeorgesGMA','NovJanSpawn','OctSpawn','Platts','SmallBigelow',
       #    'SmallEMaine','SNEMBTGclosure','Toothaker','WGOMaltrollinggear','WGOMinshorerollgear')


#THIRTY MINUTE SQUARES
my_basemap = readOGR(dsn=file.path(ML.GIS.PATH,"nmfs spatial data", "Thirty_Minute_Squares"), layer="Thirty_Minute_Squares", verbose=T)
my_basemap = spTransform(my_basemap, CRS=PROJ.USE)



LOAD.AND.PREP.GIS <- function(SHPNAME, PROJECT.PATH = PROJECT.PATH, PROJ.USE = PROJ.USE) {
  SHP = readOGR(dsn=file.path(PROJECT.PATH), layer=SHPNAME, verbose=T)
  SHP = spTransform(SHP, CRS=PROJ.USE)
  if(NROW(SHP)>1) {
    SHP = gBuffer(SHP, width=1, byid=T) 
    }
  stopifnot(gIsValid(SHP))
  return(SHP)
}
AREA_SHP= LOAD.AND.PREP.GIS(SHPNAME="Thirty_Minute_Squares", PROJECT.PATH = file.path(ML.GIS.PATH,"nmfs spatial data", "Thirty_Minute_Squares"), PROJ.USE = PROJ.USE)

AREA_SHP<-AREA_SHP[which(AREA_SHP$NERO_ID %in% c(99,100,114,115,123)),]

MGAREA = AREA_SHP$NERO_ID


# Create one single-column dataframe with all elements in form of the filepath, but R recgonizes it only as text
# Dataframe with ~1.8 million records (comercial only) 


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
    sfExport("AREA","AREA_SHP")
  
    ACTIVITY = sfLapply(fileswanted,function(x,...) {     #usually run in sfLapply
      ERRS = as.character(0) # create empty character vector 
      
      NR = as.numeric(NROW(x)) #NR = number of rows in fileswanted
      id.list <- matrix(nrow = NR,ncol = 4)
      colnames(id.list) <- c("IDNUM","Area","Year","Inside")
        BR = seq(1,NR,by=25) #BR is a sequence 
        if(!NR%in%BR) BR=c(BR, NR) # takes bricks of 25 
        for (i in 1:(NROW(BR)-1)){ #use row # of what's in that "brick" 
          t.index = (BR[i]):(BR[i+1]-1)
          if(i==(NROW(BR)-1)) (t.index = (BR[i]):(BR[i+1])) 
          for (j in t.index) {   
            tt = raster(x[[j]])
            tt = mask(tt, AREA_SHP[AREA_SHP$NERO_ID==AREA,], byid=c(T,F), id=row.names(tt))
            tt <- unlist(as.numeric(cellStats(tt,stat='sum')))
            ID =  unlist(strsplit(x[[j]], split = ".gri"))
            ID = do.call(rbind,strsplit(as.character(ID), split = "/"))
            ID = as.character(ID[NCOL(ID)])
            #if(tt!=0) {
              id.list[j,1] <- ID
              id.list[j,2] <- AREA
              id.list[j,3] <- YEAR
              id.list[j,4] <- as.numeric(tt)                      
           # }     
        }
      }
    return(list(id.list, ERRS))})
    ACTIVITY <- do.call(rbind,lapply(ACTIVITY,data.frame,stringsAsFactors=FALSE) )
    ACTIVITY$Inside <- as.numeric(as.character(ACTIVITY$Inside))
    ACTIVITY <- ACTIVITY[which(ACTIVITY$Inside!=0),]
    save(ACTIVITY, file = paste(AREA.PATH, "/",AREA,YEAR,".RData", sep = ''))
  }
  print(paste0("Total run time ",round(difftime(Sys.time(), ptm.TOT, units='min'), 2), " mins for",AREA,YEAR))
  
}
sfStop() 
  