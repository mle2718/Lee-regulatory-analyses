#Creating count of trip id and percent of trip calculated to fall within a certain shapefile
#Geret DePiper Modified by Min-Yang Lee
#August 2017


if(!require(plyr)) {  
  install.packages("plyr")
  require(plyr)}
if(!require(foreign)) {  
  install.packages("foreign")
  require(foreign)}

if(!require(raster)) {  
  install.packages("raster")
  require(raster)}
if(!require(rgdal)) {  
  install.packages("rgdal")
  require(rgdal)}
if(!require(rgeos)) {  
  install.packages("rgeos")
  require(rgeos)}
if(!require(scales)) {  
  install.packages("scales")
  require(scales)}
if(!require(R2HTML)) {  
  install.packages("R2HTML")
  require(R2HTML)}
if(!require(RColorBrewer)) {  
  install.packages("RColorBrewer")
  require(RColorBrewer)}
if(!require(stringr)) {  
  install.packages("stringr")
  require(stringr)}
if(!require(maps)) {  
  install.packages("maps")
  require(maps)}


START.YEAR = 2004   #Min = 1996
END.YEAR = 2015     #Max = 2014
SSB.NETWORK=file.path("/net/work5/socialsci") # This is what you need to run networked

YOUR.DATA.PATH= file.path("/net/work5/socialsci/Geret_Rasters/FINAL MAPS") 
YOUR.CODE.PATH= file.path("/net/home2/mlee/RasterRequests/herring_scripts/") 

ML.GIS.PATH <- file.path("/net/home2/mlee/spatial data")


SSB.DRIVE = SSB.NETWORK
GD.RASTERS = file.path(SSB.DRIVE, "Geret_Rasters")
GD.GIS.PATH = file.path(GD.RASTERS, "Data")


ML.NETWORK.SERVER=file.path("/net/home2/mlee") #This Is what you need to run from the network.


PROJ.USE = CRS('+proj=aea +lat_1=28 +lat_2=42 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0 ') 

# STATISTICAL AREAS
my_basemap1 = readOGR(dsn=file.path(ML.GIS.PATH,"nmfs spatial data","corrected_stat_areas"), layer="Statistical_Areas", verbose=F)
my_basemap1 = spTransform(my_basemap1, CRS=PROJ.USE)# Don't project if you're plotting in a lat/lon, not-projected CRS

# Establish "the other"lat lon" projection info
PROJ.LATLON = crs(my_basemap1)

#THIRTY MINUTE SQUARES
my_basemap = readOGR(dsn=file.path(ML.GIS.PATH,"nmfs spatial data", "Thirty_Minute_Squares"), layer="Thirty_Minute_Squares", verbose=F)
my_basemap = spTransform(my_basemap, CRS=PROJ.USE) # Don't project if you're plotting in a lat/lon, not-projected CRS

# EastCoast_states
my_basemap2 = readOGR(dsn=file.path(ML.GIS.PATH,"basic spatial data","more_states"), layer="EastCoast_states", verbose=F)
my_basemap2 = spTransform(my_basemap2, CRS=PROJ.USE) # Don't project if you're plotting in a lat/lon, not-projected CRS

# EEZ Shapefiles
my_basemap3 = readOGR(dsn=file.path(ML.GIS.PATH,"nmfs spatial data", "corrected_stat_areas"), layer="EEZ", verbose=F)
my_basemap3 = spTransform(my_basemap3, CRS=PROJ.USE) # Don't project if you're plotting in a lat/lon, not-projected CRS




load(file.path(GD.RASTERS,"Data","RasterDate.Rdata"))
fla<-FILE_INFO[c(1:4)]
fla$YEAR<- as.numeric(fla$YEAR)
rm(list="FILE_INFO")






load(file.path(ML.NETWORK.SERVER, "spatial data","permit_tripid.Rdata"))
load(file.path(ML.NETWORK.SERVER, "spatial data","VTRgear.rdata"))



#Geret has built the amount of a trip inside a polygon.  It is stored in a Rdata file (by year) in the trip_level_data folder.

AREA.PATH = file.path(SSB.DRIVE, "Geret_Rasters","Data","NEFMC_Coral","Trip_level_data")




#These are the names of the .Rdata files that contain an IDNUM, Area, year, and Inside. MGAREA is the list of "Area"'s
MGAREA = c('300m_polygon','400m_polygon','500m_polygon','600m_polygon','900m_polygon','Alvin',
           'Bear','Atlantis','Chebacco',
           'Clipper','Dogbody','Filebottom','Gilbert','Heel_Tapper','Heezen','Hydrographer',
           'Lindenkohl_Knoll','Lydonia','Munson',
           'Mytilus','Nantucket','Nygren','Oceanographer','Outer_Schoodic_Ridge','Physalia','Powell',
           "Retriever",'Sharpshooter','Unnamed_Nygren_Heezen','Veatch','Welker',
           'Veatch_Tilefish_GRA','Lydonia_combined','Oceanographer_combined','Monument_seamounts','Monument_canyons',
           'Canyon_area_combined','600m_min_new','MDR_II',"JordanBasin","Lindenkohl","Compromise_broad_zone_alternative_052617",
           'WJB_96','WJB_114','WJB_118','Central_Jordan_Basin_2','Mount_Desert_Rock')



# You put the 30 minute square data in /home2/mlee/spatial data/check_thirty_min_sq
# With the 








FIN<-null
for(yr in START.YEAR:END.YEAR) {
  print(yr)
  YEAR.RESULT <- read.dbf(file = paste0(SSBdrive,"/Data/ExportAll",yr,".dbf"),as.is=TRUE)

    FIN = rbind(FIN,YEAR.RESULT)
  # Print the results summary:
  print(paste("For year ",yr,", ",(NROW(YEAR.RESULT))," records were added.",sep=""))
  print(paste0("After adding year ",yr,", total records imported = ",NROW(FIN),"."))
}


test=1
for (YEAR in START.YEAR:END.YEAR) {
  for (AREA in MGAREA){
    load(paste(AREA.PATH, "/",AREA,YEAR,".RData", sep = ''))
    if (test == 1) {
      FULLFILE <- subset(ACTIVITY,select=c(IDNUM,Area,Year,Inside))
      FULLFILE$Inside <- as.numeric(as.character(FULLFILE$Inside))
      FULLFILE <- FULLFILE[which(FULLFILE$Inside!=0),]
      FULLFILE$Inside <- as.numeric(as.character(FULLFILE$Inside))
      rm(ACTIVITY)
      test = 2
    }
    else {
      YEAR.AREA <-   subset(ACTIVITY,select=c(IDNUM,Area,Year,Inside))
      YEAR.AREA <- YEAR.AREA[which(YEAR.AREA$Inside!=0),]
      YEAR.AREA$Inside <- as.numeric(as.character(YEAR.AREA$Inside))
      FULLFILE <- rbind(FULLFILE, YEAR.AREA)
      rm(ACTIVITY,YEAR.AREA)
    }
  }
}

source('C:/Users/gdepiper/Documents/Rasters/FINAL_ODBC_rasters.r')
E_Y <- END.YEAR+1
RESULT.COMPILED<-null

for(i in START.YEAR:E_Y) {
  print(i)
  CURRENT.QUERY = paste("SELECT  unique PERMIT,
                        TRIPID FROM VTR.veslog",i,"t ;"
                        ,sep="")
  
  YEAR.RESULT = sqlQuery(ODBC.CONNECTION, CURRENT.QUERY)  ### seems to be a problem with having a "paste" on both sides...
  
  # Now, the loop compiles the results; the first year must be treated slightly differently###
    RESULT.COMPILED = rbind(RESULT.COMPILED,YEAR.RESULT) }
  
  # Print the results summary:
  print(paste("For year ",i,", ",(NROW(YEAR.RESULT))," records were added.",sep=""))
  print(paste0("After adding year ",i,", total records imported = ",NROW(RESULT.COMPILED),"."))
}    # End Main Loop

save(FIN,file=paste(AREA.PATH,"/DeepSeaCoralData_RAWJune7_2017.Rdata",sep=""))

load(file=paste(AREA.PATH,"/DeepSeaCoralData_RAWJune7_2017.Rdata",sep=""))

FIN$GEARCAT <- ""
FIN$GEARCAT[FIN$GEARNM=="POT, LOBSTER"] <- "Lobster Pot"
FIN$GEARCAT[FIN$GEARNM %in% c("OTTER TRAWL, BOTTOM,FISH","OTTER TRAWL, BEAM","OTTER TRAWL, BOTTOM,OTHER", "OTTER TRAWL,BOTTOM,TWIN", 
                                  "SEINE, DANISH","SEINE, SCOTTISH","PAIR TRAWL, BOTTOM") ] <- "Bottom Trawl"
FIN$GEARCAT[FIN$GEARNM=="GILL NET, SINK"] <- "Sink Gillnet"
FIN$GEARCAT[FIN$GEARNM %in% c("DREDGE, SCALLOP,SEA","DREDGE, SCALLOP-CHAIN MAT","DREDGE,SCALLOP,TURTLE DEFLECT",
                                  "DREDGE, SCALLOP,CHAIN MAT,MOD","DREDGE, OCEAN QUAHOG/SURF CLAM","OTTER TRAWL, BOTTOM,SCALLOP")] <- "Scallop Gear & Clam Dredge"
#FIN$GEARCAT[FIN$GEARNM=="DREDGE, OCEAN QUAHOG/SURF CLAM"] <- "Clam Dredge"
FIN$GEARCAT[FIN$GEARNM=="OTTER TRAWL, BOTTOM,SHRIMP"] <- "Shrimp Trawl"
FIN$GEARCAT[FIN$GEARNM %in% c("DREDGE, URCHIN","DREDGE, OTHER","DREDGE, OTHER")] <- "Other Dredge"
FIN$GEARCAT[FIN$GEARNM %in% c("HAND LINE/ROD & REEL","HARPOON")] <- "Hand Gear"
FIN$GEARCAT[FIN$GEARNM=="LONGLINE, BOTTOM"] <- "Bottom Longline"
FIN$GEARCAT[FIN$GEARNM %in% c("POT, HAG","POT, CRAB","POT, FISH", "POT, CONCH/WHELK", "POT, SHRIMP","POT, OTHER",
                                  "TRAP","POT, EEL","POTS, MIXED")] <- "Other Pot"
FIN$GEARCAT[FIN$GEARNM %in% c("OTTER TRAWL, MIDWATER","PAIR TRAWL, MIDWATER")] <- "Midwater Trawl"
FIN$GEARCAT[FIN$GEARNM %in% c("OTTER TRAWL, HADDOCK SEPARATOR","OTTER TRAWL, RUHLE")] <- "Separator & Ruhle Trawl"
#FIN$GEARCAT[FIN$GEARNM=="OTTER TRAWL, BOTTOM,SCALLOP"] <- "Scallop Trawl"
FIN$GEARCAT[FIN$GEARNM %in% c("GILL NET, DRIFT,LARGE MESH","GILL NET, DRIFT,SMALL MESH")] <- "Drift Gillnet"
FIN$GEARCAT[FIN$GEARNM %in% c("FYKE NET","OTHER GEAR", "HAND RAKE", "DIVING GEAR","SEINE, STOP","WEIR","CARRIER VESSEL",
                                  "MIXED GEAR","CASTNET","SEINE,HAUL")] <- "Other Gear"
FIN$GEARCAT[FIN$GEARNM=="LONGLINE, PELAGIC"] <- "Pelagic Longline"
FIN$GEARCAT[FIN$GEARNM=="SEINE, PURSE"] <- "Purse Seine"
FIN$GEARCAT[FIN$GEARNM %in% c("GILL NET, OTHER","GILL NET, RUNAROUND")] <- "Other Gillnet"
FIN$GEARCAT[FIN$GEARCAT==""] <- "Other Gear"
FIN$GEARCAT[which(is.na(FIN$GEARCAT))] <- "Other Gear"

RESULT.COMPILED <- unique(RESULT.COMPILED)
TEST_1 <- NROW(FIN)
FIN <- merge(FIN,RESULT.COMPILED, by='TRIPID',all.x=TRUE, all.y=FALSE)
if (NROW(FIN) != TEST_1) stop("Merging Permits increased number of rows, which shouldn't happen") 

FIN <- subset(FIN,select=c('PORTLANDED','YEAR','VESID','NESPP3','MONTH','GEARCODE','GEARCAT','SERIAL_NUM','IDNUM','LIVE','QTYKEPT','QTYDISC','DAS','SPPNM','REVENUE',
                           'FMP','LEN','FY','TRIPID','PERMIT'))

REVENUEFILE <- merge(FULLFILE,y=FIN,all.x=TRUE,all.y=TRUE,by.x=c('IDNUM','Year'),by.y=c('IDNUM','YEAR'))
REVENUEFILE <- REVENUEFILE[!is.na(REVENUEFILE$IDNUM),]
REVENUEFILE$PERMIT[which(REVENUEFILE$GEARCODE=='DRC'& is.na(REVENUEFILE$PERMIT) & !is.na(REVENUEFILE$VESID))] <- 
    REVENUEFILE$VESID[which(REVENUEFILE$GEARCODE=='DRC'& is.na(REVENUEFILE$PERMIT) & !is.na(REVENUEFILE$VESID))]
#There are a few trips which are left over from the earlier raster processing (not in the most recent data for whatever reason)
#528 observations, but less trips total.
REVENUEFILE <- REVENUEFILE[!is.na(REVENUEFILE$PERMIT),]
#Dropping observations with pelagic gear

REVENUEFILE$DROP <- 0
#REVENUEFILE$DROP[REVENUEFILE$GEARCAT%in%c("Purse Seine","Pelagic Longline","Drift Gillnet","Hand Gear","Midwater Trawl")] <- 1
REVENUEFILE <- REVENUEFILE[REVENUEFILE$DROP!=1,]
REVENUEFILE$DROP <- NULL

REVENUEFILE$Inside[which(is.na(REVENUEFILE$Inside))] <- 0
REVENUEFILE$InsideREV <- REVENUEFILE$Inside*REVENUEFILE$REVENUE
REVENUEFILE$InsideDAS <- REVENUEFILE$Inside*REVENUEFILE$DAS
REVENUEFILE$QTYKEPT[which(is.na(REVENUEFILE$QTYKEPT))] <- 0
REVENUEFILE$QTYDISC[which(is.na(REVENUEFILE$QTYDISC))] <- 0
REVENUEFILE$LIVE[which(is.na(REVENUEFILE$LIVE))] <- 0
REVENUEFILE$TOTCATCH <- REVENUEFILE$LIVE+REVENUEFILE$QTYDISC
REVENUEFILE$InsideCATCH <- REVENUEFILE$Inside*REVENUEFILE$TOTCATCH
REVENUEFILE$InsideLANDED <- REVENUEFILE$Inside*REVENUEFILE$QTYKEPT
REVENUEFILE$Area[which(is.na(REVENUEFILE$Area))] <- 'Other'

#REVENUEFILE$vesselcat = "U"
#REVENUEFILE$vesselcat[which(REVENUEFILE$LEN <50)] <- "S"
#REVENUEFILE$vesselcat[which(REVENUEFILE$LEN >=50 & REVENUEFILE$LEN < 70)] <- "M"
#REVENUEFILE$vesselcat[which(REVENUEFILE$LEN >=70)] <- "L"

REVENUEFILE$BROADZONE <- "Other Offshore Discrete Canyons"
REVENUEFILE$BROADZONE[REVENUEFILE$Area%in%c("WJB_96","WJB_114","WJB_118",
                                            "Central_Jordan_Basin_2")] <- "Jordan Basin Option 1"
REVENUEFILE$BROADZONE[REVENUEFILE$Area%in%c("JordanBasin")] <- "Jordan Basin Option 2"
REVENUEFILE$BROADZONE[REVENUEFILE$Area%in%c("Lindenkohl")] <- "Lindenkohl Knoll Option 2"
REVENUEFILE$BROADZONE[REVENUEFILE$Area%in%c('Oceanographer','Filebottom','Chebacco','Gilbert','Lydonia')] <- "Offshore Monument Discrete Canyons"
REVENUEFILE$BROADZONE[REVENUEFILE$Area%in%c('Bear','Mytilus','Physalia',"Retriever")] <- "Offshore Seamounts"
REVENUEFILE$BROADZONE[REVENUEFILE$Area%in%c("Lindenkohl_Knoll")] <- "Lindenkohl Knoll Option 1"
REVENUEFILE$BROADZONE[REVENUEFILE$Area%in%c("Mount_Desert_Rock")] <- "Mt Desert Rock Option 1"
REVENUEFILE$BROADZONE[REVENUEFILE$Area%in%c("MDR_II")] <- "Mt Desert Rock Option 2"
REVENUEFILE$BROADZONE[REVENUEFILE$Area%in%c("Outer_Schoodic_Ridge")] <- "Outer Schoodic Ridge"
REVENUEFILE$BROADZONE[REVENUEFILE$Area=="300m_polygon"] <- "300 m"
REVENUEFILE$BROADZONE[REVENUEFILE$Area=="400m_polygon"] <- "400 m"
REVENUEFILE$BROADZONE[REVENUEFILE$Area=="500m_polygon"] <- "500 m"
REVENUEFILE$BROADZONE[REVENUEFILE$Area=='600m_polygon'] <- "600 m"
REVENUEFILE$BROADZONE[REVENUEFILE$Area=="900m_polygon"] <- "900 m"
REVENUEFILE$BROADZONE[REVENUEFILE$Area=='600m_min_new'] <- "600 m Min"
REVENUEFILE$BROADZONE[REVENUEFILE$Area%in%c('Veatch_Tilefish_GRA','Lydonia_combined','Oceanographer_combined')] <- "No Action Monkfish Tilefish Areas"
REVENUEFILE$BROADZONE[REVENUEFILE$Area=='Monument_seamounts'] <- 'National Monument'
REVENUEFILE$BROADZONE[REVENUEFILE$Area=='Monument_canyons'] <- 'National Monument'
REVENUEFILE$BROADZONE[REVENUEFILE$Area=='Canyon_area_combined'] <- 'No Action Combined Canyons'
REVENUEFILE$BROADZONE[REVENUEFILE$Area=="Compromise_broad_zone_alternative_052617"] <-"ENGO Alternative"

#REVENUEFILE$SPPNM[REVENUEFILE$NESPP3==710] <- "CRAB, JONAH & RED"
#REVENUEFILE$SPPNM[REVENUEFILE$NESPP3==711] <- "CRAB, JONAH & RED"
REVENUEFILE$SPPNM[REVENUEFILE$NESPP3==168] <- "Atlantic Herring"
REVENUEFILE$SPPNM[REVENUEFILE$NESPP3%in%c(11,12)] <- "MONKFISH"

#FIN <- REVENUEFILE

#write.dbf(REVENUEFILE[which(REVENUEFILE$BROADZONE =="900 m"),],file=paste(AREA.PATH,"/DeepSeaCoral900mData_Mar2017.dbf",sep=""))
if (is.na(NROW(REVENUEFILE[which(is.na(REVENUEFILE$TOTCATCH)),]))) stop("Some Total Catch is zero")
save(REVENUEFILE,file=paste(AREA.PATH,"/DeepSeaCoralData_June7_2017.Rdata",sep=""))

load(file=paste(AREA.PATH,"/DeepSeaCoralData_June7_2017.Rdata",sep=""))

#Data for Rachel Feeney
REVENUEFILE_R <- REVENUEFILE
REVENUEFILE_R$InsideREV[REVENUEFILE_R$NESPP3==727 & REVENUEFILE_R$GEARCAT=="Lobster Pot" & !REVENUEFILE_R$BROADZONE%in%c("Mt Desert Rock Option 1","Mt Desert Rock Option 2","Outer Schoodic Ridge")] <-
  REVENUEFILE_R$InsideREV[REVENUEFILE_R$NESPP3==727 & REVENUEFILE_R$GEARCAT=="Lobster Pot" & !REVENUEFILE_R$BROADZONE%in%c("Mt Desert Rock Option 1","Mt Desert Rock Option 2","Outer Schoodic Ridge")]*1.2420




REVENUEFILE_R <- aggregate(InsideREV~PERMIT+TRIPID+Year+MONTH+PORTLANDED, data=REVENUEFILE_R[REVENUEFILE$Area!='Other',], FUN=sum)
write.csv(REVENUEFILE_R, file=paste(AREA.PATH,"/DeepSeaCoralRachelData_June7_2017.csv",sep=""))
rm(REVENUEFILE_R)




  
