
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


load(file.path(GD.RASTERS,"Data","RasterDate.Rdata"))
fla<-FILE_INFO[c(1:4)]
fla$YEAR<- as.numeric(fla$YEAR)
rm(list="FILE_INFO")


load(file.path(ML.NETWORK.SERVER, "spatial data","permit_tripid.Rdata"))
load(file.path(ML.NETWORK.SERVER, "spatial data","VTRgear.rdata"))

PROJ.USE = CRS('+proj=aea +lat_1=28 +lat_2=42 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0 ') 
# Albers Equal Area conic (in meters)
BASE.RASTER = raster(file.path(GD.GIS.PATH,"BASERASTER_AEA_2"))


# you built this with "mlee/RasterRequests/code_fragments/get_permit_nums.do" 
# because you can't figure out how to do it within R

FINAL=data.frame()
for (yr in START.YEAR:END.YEAR)  {
  FINAL2 <- read.dbf(file = paste0(GD.RASTERS,"/Data/ExportAll",yr,".dbf"), as.is=TRUE)
  FINAL=rbind(FINAL,FINAL2)
  rm(FINAL2)
}

      
# AND CONSTRUCTS THE GEARCAT AND Gearname variables
FINAL$GEARCAT <- ""
FINAL$GEARCAT[FINAL$GEARNM=="POT, LOBSTER"] <- "Lobster Pot"
FINAL$GEARCAT[FINAL$GEARNM %in% c("OTTER TRAWL, BOTTOM,FISH","OTTER TRAWL, BEAM","OTTER TRAWL, BOTTOM,OTHER", "OTTER TRAWL,BOTTOM,TWIN", 
                                  "SEINE, DANISH","SEINE, SCOTTISH","PAIR TRAWL, BOTTOM") ] <- "Bottom Trawl"
FINAL$GEARCAT[FINAL$GEARNM=="GILL NET, SINK"] <- "Sink Gillnet"
FINAL$GEARCAT[FINAL$GEARNM %in% c("DREDGE, SCALLOP,SEA","DREDGE, SCALLOP-CHAIN MAT","DREDGE,SCALLOP,TURTLE DEFLECT",
                                  "DREDGE, SCALLOP,CHAIN MAT,MOD")] <- "Scallop Dredge"
FINAL$GEARCAT[FINAL$GEARNM=="DREDGE, OCEAN QUAHOG/SURF CLAM"] <- "Clam Dredge"
FINAL$GEARCAT[FINAL$GEARNM=="OTTER TRAWL, BOTTOM,SHRIMP"] <- "Shrimp Trawl"
FINAL$GEARCAT[FINAL$GEARNM %in% c("DREDGE, URCHIN","DREDGE, OTHER","DREDGE, OTHER")] <- "Other Dredge"
FINAL$GEARCAT[FINAL$GEARNM %in% c("HAND LINE/ROD & REEL","HARPOON")] <- "Hand Gear"
FINAL$GEARCAT[FINAL$GEARNM=="LONGLINE, BOTTOM"] <- "Bottom Longline"
FINAL$GEARCAT[FINAL$GEARNM %in% c("POT, HAG","POT, CRAB","POT, FISH", "POT, CONCH/WHELK", "POT, SHRIMP","POT, OTHER",
                                  "TRAP","POT, EEL","POTS, MIXED")] <- "Other Pot"
FINAL$GEARCAT[FINAL$GEARNM %in% c("OTTER TRAWL, MIDWATER","PAIR TRAWL, MIDWATER")] <- "Midwater Trawl"
FINAL$GEARCAT[FINAL$GEARNM %in% c("OTTER TRAWL, HADDOCK SEPARATOR","OTTER TRAWL, RUHLE")] <- "SAP Trawl"
FINAL$GEARCAT[FINAL$GEARNM=="OTTER TRAWL, BOTTOM,SCALLOP"] <- "Scallop Trawl"
FINAL$GEARCAT[FINAL$GEARNM %in% c("GILL NET, DRIFT,LARGE MESH","GILL NET, DRIFT,SMALL MESH")] <- "Drift Gillnet"
FINAL$GEARCAT[FINAL$GEARNM %in% c("FYKE NET","OTHER GEAR", "HAND RAKE", "DIVING GEAR","SEINE, STOP","WEIR","CARRIER VESSEL",
                                  "MIXED GEAR","CASTNET","SEINE,HAUL")] <- "Other Gear"
FINAL$GEARCAT[FINAL$GEARNM=="LONGLINE, PELAGIC"] <- "Pelagic Longline"
FINAL$GEARCAT[FINAL$GEARNM=="SEINE, PURSE"] <- "Purse Seine"
FINAL$GEARCAT[FINAL$GEARNM %in% c("GILL NET, OTHER","GILL NET, RUNAROUND")] <- "Other Gillnet"
FINAL$GEARCAT[FINAL$GEARCAT==""] <- "Other Gear"

FINAL$GEARNAME <= ""



FINAL <- merge(FINAL,VTRgear, all.x=TRUE,all.y=FALSE, by.x = 'GEARCODE', by.y='gearcode')

BT <- c('050','051','052','053','056','059','350','360','160')
SAP <- c('054','057')
LL <- c('010','020','021','040')
SG <- c('100','105','117','250','260','320','330','340')
DG <- c('110','115','116','500')
PS <- c('120','121','070','240')
SD <- c('132')
MT <- c('170','370')
P <- c('181','183','186','200','300','080','180','190')
CD <- c('381','386','400','385','387')
UK <- c('999')
H <- c('030','031')
R <- c('070','240','250','260','320','330','340')
ST <- c('058')


FINAL$Gearname <- ""
FINAL$Gearname[which(FINAL$negear %in% BT)] <- "Bottom Trawl"
FINAL$Gearname[which(FINAL$negear %in% SAP)] <- "SAP Trawl"
FINAL$Gearname[which(FINAL$negear %in% LL)] <- "Longline"
FINAL$Gearname[which(FINAL$negear %in% SG)] <- "Sink Gillnet"
FINAL$Gearname[which(FINAL$negear %in% DG)] <- "Drift Gillnet"
FINAL$Gearname[which(FINAL$negear %in% PS)] <- "Purse Seine"
FINAL$Gearname[which(FINAL$negear %in% SD)] <- "Scallop Dredge"
FINAL$Gearname[which(FINAL$negear %in% MT)] <- "Midwater Trawl"
FINAL$Gearname[which(FINAL$negear %in% P)] <- "Pot"
FINAL$Gearname[which(FINAL$negear %in% CD)] <- "Clam Dredge"
FINAL$Gearname[which(FINAL$negear %in% UK)] <- "Unknown"
FINAL$Gearname[which(FINAL$negear %in% H)] <- "HARPOON"
FINAL$Gearname[which(FINAL$negear %in% ST)] <- "Shrimp Trawl"
FINAL$Gearname[which(FINAL$negear %in% R)] <- "Other"





FINAL <- subset(FINAL, select=-c(DAY, AREA, DAS, SERIAL_NUM, PORTLANDED, PORTGROUP, PORTAREAKE, PORTLND1, STATE1, VHP, LEN, PORT_LON, PORT_LAT,distance25, distance50, distance75, distance90, distance95))
FINAL <- merge(FINAL,permit_tripid, all.x=TRUE,all.y=FALSE, by.x = 'TRIPID', by.y='tripid')

#VAST majority of no permits are from SCOQ fishery, but we'll just copy over VESID into permit for these anywa
#table(FINAL[which(is.na(FINAL$permit)),]$FMP) 
FINAL$permit[FINAL$FMP == "SURF CLAM OCEAN QUAHOG MIDATLANTIC *"] <-FINAL$VESID[FINAL$FMP == "SURF CLAM OCEAN QUAHOG MIDATLANTIC *"]


################################################################################
################################################################################
################################################################################
#WARNING: Matching from a derivative of parsed_groups$GROUP_UNIT to tFMP SHOULD work. 
# These needed to be cleaned up just a little bit.
################################################################################
FINAL$tFMP<-tolower(FINAL$FMP)
FINAL$tFMP<-gsub("[/*]", "", FINAL$tFMP)

FINAL$tFMP<-gsub("midatlantic", "", FINAL$tFMP)
FINAL$tFMP<-gsub(" ne", "", FINAL$tFMP)  #Be careful here, since there are NEs at the beginning and end of strings. 
FINAL$tFMP<-gsub(" joint", "", FINAL$tFMP)  
FINAL$tFMP<-gsub(" ", "",FINAL$tFMP)

mygears<-unique(FINAL$GEARCAT)
mygears<-gsub(" ","",mygears)

mygears<-tolower(mygears)


## This is where you'll want to do some subsetting. You only need (A) herring (B) PUR, OTF, OTM, PTM gears.  
# you'll find it handly to construct a regime variable and a month_group variable as well.

FINAL$summer_months <- 0
FINAL$summer_months[FINAL$MONTH>=6 &FINAL$MONTH<=9 ] <- 1

FINAL$REGIME<-0
FINAL$REGIME[which(FINAL$YEAR>=2001 & FINAL$YEAR<=2007)]<-1
FINAL$REGIME[which(FINAL$YEAR>=2008 & FINAL$YEAR<=2015)]<-2
FINAL$REGIME[which(FINAL$REGIME==1 & FINAL$YEAR>=2007 & FINAL$MONTH>=6)]<-2
FINAL$MY_GEAR<-FINAL$GEARCODE  

FINAL$MY_GEAR[FINAL$GEARCODE=="PUR"]<-"PUR"
FINAL$MY_GEAR[FINAL$GEARCODE=="OTM"]<-"MWT"
FINAL$MY_GEAR[FINAL$GEARCODE=="PTM"]<-"MWT"  
FINAL$MY_GEAR[FINAL$GEARCODE=="OTF"]<-"BOT"  
FINAL$MY_GEAR[FINAL$GEARCODE=="OHS"]<-"BOT"  
FINAL$MY_GEAR[FINAL$GEARCODE=="OTR"]<-"BOT"  
FINAL$MY_GEAR[FINAL$GEARCODE=="OTT"]<-"BOT"  
FINAL$MY_GEAR[FINAL$GEARCODE=="OTS"]<-"BOT"  
FINAL$MY_GEAR[FINAL$GEARCODE=="OTC"]<-"BOT"  

FINAL=FINAL[which(FINAL$MY_GEAR %in% c("PUR","BOT","MWT")),] # <-BOT, OTM, PUR
FINAL=FINAL[which(FINAL$NESPP3 %in% c("168")),]

FINAL=FINAL[which(FINAL$REGIME>=1),]

