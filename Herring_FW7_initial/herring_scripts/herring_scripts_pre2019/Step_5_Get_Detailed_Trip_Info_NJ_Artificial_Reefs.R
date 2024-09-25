#Creating count of trip id and percent of trip calculated to fall within a certain shapefile
#Geret DePiper
#August 2015

COMPUTERRATE = 86  #Approx # donuts per minute that computer can draw. Updates with rolling average. (For estimating time to run) 
COMPUTERNAME = "Geret"

max.nodes = 30 # Set to 12 when working on Server?
todaysdate = as.Date(Sys.time())
print(Sys.time())

START.YEAR = 2010   #Min = 1996
END.YEAR = 2014     #Max = 2013

#Setting directories (currently for server run)

SSBdrive = file.path("/net/work5/socialsci/Geret_Rasters") #when running R script off Linux server
#SSBdrive = file.path('Z:/Geret_Rasters') 
rasterfolder = file.path(SSBdrive, "Data", "individualrasters") 
GIS.PATH = file.path(SSBdrive, "Data")
AREA.PATH = file.path(SSBdrive, "Data","Artificial_Reefs")

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

source(file.path(SSBdrive,"FINAL_Raster_Functions.R"))

PROJ.USE = CRS('+proj=aea +lat_1=28 +lat_2=42 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0 ') 
# Albers Equal Area conic (in meters)
BASE.RASTER = raster(file.path(GIS.PATH,"BASERASTER_AEA_2"))
East_Cst_cropped  = LOAD.AND.PREP.GIS(SHPNAME="East_Cst_cropped", PROJECT.PATH = GIS.PATH, PROJ.USE = PROJ.USE)

#test <- raster(paste(sd,"individualrasters","MA","2013","70766.grd",sep="/"))

filelist = lapply(as.list(list.dirs(path=rasterfolder, recursive=F)), list.files, recursive=T, full.names=T, pattern="*.gri")
#MGAREA = c('AprilJuneSpawn','ClamExemption1','CoxLedge','GBEFHexpanded2','GBEFHexpandedt','GBEFHSouth',
  #         'GBmortalityclosure','GBWesternArea','GeorgesShoal1MBTG','GeorgesShoal2MBGT','GeorgesShoalGMA',
   #        'GreatSouthChannel','GreatSouthChannelEast','GreatSouthChannelGMA','JuneSpawn','LargeBigelow',
     #      'LargeEMaine','Machias','MassBaySpawn','MayJuneSpawn','MaySpawn','NantucketShoals','NantucketShoalsWest',
      #     'NorthernEdge','NorthernEdgeReducedImpact','NorthernGeorgesGMA','NovJanSpawn','OctSpawn','Platts','SmallBigelow',
       #    'SmallEMaine','SNEMBTGclosure','Toothaker','WGOMaltrollinggear','WGOMinshorerollgear')


LOAD.AND.PREP.GIS <- function(SHPNAME, PROJECT.PATH = PROJECT.PATH, PROJ.USE = PROJ.USE) {
  SHP = readOGR(dsn=file.path(PROJECT.PATH), layer=SHPNAME, verbose=T)
  SHP = spTransform(SHP, CRS=PROJ.USE)
  if(NROW(SHP)>1) {
    SHP = gBuffer(SHP, width=1, byid=T) 
    }
  stopifnot(gIsValid(SHP))
  return(SHP)
}
AREA_SHP= LOAD.AND.PREP.GIS(SHPNAME="NJ_Reef_Sites_May2016", PROJECT.PATH = AREA.PATH, PROJ.USE = PROJ.USE)
MGAREA = AREA_SHP$AREANAME

#AREA = LOAD.AND.PREP.GIS(SHPNAME="NantucketShoalsWest", PROJECT.PATH = AREA.PATH, PROJ.USE = PROJ.USE)
#tt = fl$FILEPATH
#tt = try(raster(file.path(tt)))

# Create one single-column dataframe with all elements in form of the filepath, but R recgonizes it only as text
# Dataframe with ~1.8 million records (comercial only) 

#The following create new dataframe fields for IDnum and year..
fl = do.call(rbind, lapply(filelist, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILEPATH" 
  return(xx) }) )         

#fl = paste(sd,"individualrasters","MA","2013","70766.grd",sep="/")
#fl = as.data.frame(fl)
names(fl) <- "FILEPATH"

fl$STRIPGRID =  sapply(fl$FILEPATH, USE.NAMES=F, function(zz) {
  strsplit(x = as.character(zz), split = ".gri")[[1]]
})
fl$IDNUM = sapply(fl$STRIPGRID, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })

fl$YEAR = sapply(fl$STRIPGRID, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[(NCOL(temp)-1)]) })

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
            tt = mask(tt, AREA_SHP[AREA_SHP$AREANAME==AREA,], byid=c(T,F), id=row.names(tt))
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
  