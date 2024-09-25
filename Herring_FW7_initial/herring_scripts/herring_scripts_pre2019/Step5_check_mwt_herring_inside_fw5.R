

###### This script is for exploratory mapping of rasters

todaysdate = as.Date(Sys.time())

#################################################################################
# Section 1 -- Set up directories 
#################################################################################
#################################################################################
#################################################################################

# #THIS SECTION CONTAINS PLACES TO LOOK FOR DATA
# We need to tell R where to look for things.  
#    Your network drive (YOUR.NETWORK.PATH)
#    A few places where we store GIS data on the network (Min-Yang's spot and Sharon's spot)
#    The place where the rasters are stored (YOUR.DATA.PATH)
#    THE SSB DRIVE ITSELF (In case you need to look into the individual raster folder)

# MINYANG's locations
# ML.NETWORK.LOCAL and .SERVER : This is how Min-Yang Mounts his network drive.  You will want to change this.
# PROJECT PATH IS A FOLDER IN MY SHARED DRIVE
# DATA.PATH is a FOLDER INSIDE MY PROJECT PATH
# The TIF data is stored in a subfolder of DATA.PATH. 
##########   This is because the code to get a list of files throws up if there are no subfolders.
##########   The code to get a list of files throws up because Min-Yang lifted it from Geret and never bothered to figure out how it works
# ML.GIS.PATH is the location of some shapefiles. 


##YOU NEED TO CHANGE THESE THREE LINES of CODE TO POINT TO YOUR NETWORK SHARE
ML.NETWORK.LOCAL=file.path("/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee") #THIS Is what you need to run local
ML.NETWORK.SERVER=file.path("/net/home2/mlee") #This Is what you need to run from the network.


YOUR.NETWORK.PATH=file.path(ML.NETWORK.SERVER) # Tell R which to use (local or server)

YOUR.PROJECT.PATH=file.path(YOUR.NETWORK.PATH,"RasterRequests")
YOUR.DATA.PATH=file.path(YOUR.PROJECT.PATH,"HERRING_A8_09162016") 

ML.GIS.PATH= file.path(YOUR.NETWORK.PATH, "spatial data") #Min-Yang stores some of his spatial data in this folder


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

#GENERIC GIS FOLDER (These are maintained by Sharon Benjamin) 
GENERIC.GIS.PATH= file.path(SSB.DRIVE, "GIS")
FREQUENT.USE.SSB= file.path(GENERIC.GIS.PATH, "FrequentUseSSB")
################################




#####################################################
## OUTPUT LOCATIONS
#####################################################
exportfolder = file.path(YOUR.PROJECT.PATH,"FW5_analysis")
dir.create(exportfolder, recursive=T)

YOUR.STORAGE.PATH=file.path(exportfolder)  #To recap, we are storing things in the folder "output" which is in the directory defined by YOUR.DATA.PATH
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



source(file.path(GD.RASTERS,"FINAL_Raster_Functions.R"))


#################################################
# STEP 3 -- Set your mapping options
#################################################
#### WHAT ARE YOU TRYING TO MAP?
# I WANT TO Separately MAP ALL THE GEOTIFS THAT MATCH a particular pattern 
mypat1<-glob2rx("*QTYKEPT*.tif")


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
my_basemap1 = readOGR(dsn=file.path(ML.GIS.PATH,"nmfs spatial data","corrected_stat_areas"), layer="Statistical_Areas", verbose=F)
my_basemap1 = spTransform(my_basemap1, CRS=PROJ.USE)

#THIRTY MINUTE SQUARES
my_basemap = readOGR(dsn=file.path(ML.GIS.PATH,"nmfs spatial data", "Thirty_Minute_Squares"), layer="Thirty_Minute_Squares", verbose=F)
my_basemap = spTransform(my_basemap, CRS=PROJ.USE)

# EastCoast_states
my_basemap2 = readOGR(dsn=file.path(ML.GIS.PATH,"basic spatial data","more_states"), layer="EastCoast_states", verbose=F)
my_basemap2 = spTransform(my_basemap2, CRS=PROJ.USE)



# caplus
caplus = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","herringa8"), layer="caplus_masp", verbose=F)
caplus = spTransform(caplus, CRS=PROJ.USE)

#Pulling groundfish closures into memory
CAI_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_ca1", verbose=F)
CAI_grnd = spTransform(CAI_grnd, CRS=PROJ.USE)

CAII_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_ca2", verbose=F)
CAII_grnd = spTransform(CAII_grnd, CRS=PROJ.USE)
#done to here
Cashes_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"),  layer="mults_cashes", verbose=F)
Cashes_grnd = spTransform(Cashes_grnd, CRS=PROJ.USE)

NLS_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_nls", verbose=F)
NLS_grnd = spTransform(NLS_grnd, CRS=PROJ.USE)

WGOM_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_wgom", verbose=F)
WGOM_grnd = spTransform(WGOM_grnd, CRS=PROJ.USE)

#Loading EFH closures
EFH_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults_efh"), layer="mults_efh", verbose=F)
EFH_grnd = spTransform(EFH_grnd, CRS=PROJ.USE)

#REad in groundfish closed areas

Closedgf_04_15 = gUnion(CAI_grnd[CAI_grnd$id==2,],CAII_grnd)
Closedgf_04_15 = gUnion(Closedgf_04_15,Cashes_grnd)
Closedgf_04_15 = gUnion(Closedgf_04_15,WGOM_grnd)








#Split the CAPLUS and CAI shapefiles to retain just the IDs that I care about.
CAI_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_ca1", verbose=F)
CAI_grnd = spTransform(CAI_grnd, CRS=PROJ.USE)

CAII_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_ca2", verbose=F)
CAII_grnd = spTransform(CAII_grnd, CRS=PROJ.USE)




caplus = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","herringa8"), layer="caplus_masp", verbose=F)
caplus = spTransform(caplus, CRS=PROJ.USE)


CA1plus=caplus[caplus$ET_ID=="CA1",]
CA2plus=caplus[caplus$ET_ID=="CA2",]

CAI_grnd = CAI_grnd[CAI_grnd$id==2,]




#################################################
## END SECTION 4 
#################################################

list1<- lapply(as.list(list.dirs(path=YOUR.DATA.PATH, recursive=T)), list.files, recursive=F, full.names=T, pattern=mypat1)
parsed_list1 = do.call(rbind, lapply(list1, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILEPATH" 
  return(xx) }) )                                         
parsed_list1$first_part =  sapply(parsed_list1$FILEPATH, USE.NAMES=F, function(zz) {
  strsplit(x = as.character(zz), split = ".tif")[[1]]
})
parsed_list1$NAME = sapply(parsed_list1$first_part, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })

parsed_list1$YEAR = str_sub(parsed_list1$NAME,-4)

#get the 1st and 2nd characters from NAME. Discard the Q for the single digit months
parsed_list1$MONTH = sub('_',' ',str_sub(parsed_list1$NAME,1,2))





#These are the 4 spatial areas that I need to examine.
# 
# 
# CA1plus=caplus[caplus$ET_ID=="CA1",]
# CA2plus=caplus[caplus$ET_ID=="CA2",]
# 
# CAI_grnd = CAI_grnd[CAI_grnd$id==2,]
# CAI_grnd 
# 




#parsed_list1$closed<-0
#parsed_list1$closed[parsed_list1$MONTH>=5 & parsed_list1$MONTH<=8] <-1 



#Initialize a matrix to store the data
# Month, Year, quantity_grand_sum, ca1, ca1plus, ca2, ca2plus
results=matrix(0,nrow=nrow(parsed_list1), ncol=8)
print(Sys.time())

pb <- txtProgressBar(min = 0, max = nrow(parsed_list1), style = 3)



#NOT IN 1A
  
for (myr in 1:nrow(parsed_list1)){
  #REad in raster -- get the total
  myras<-raster(file.path(parsed_list1$FILEPATH[myr]))
  quantity_grand_sum<-cellStats(myras,'sum')
  
#CA1 plus
  sub_ca1plus<-mask(myras,CA1plus)
  qca1_plus<-cellStats(sub_ca1plus,'sum')
  
  #CA1
  sub_ca1<-mask(sub_ca1plus,CAI_grnd)
  qca1<-cellStats(sub_ca1,'sum')
  
  #CA2 plus
  sub_ca2plus<-mask(myras,CA2plus)
  qca2_plus<-cellStats(sub_ca2plus,'sum')
  
  #CA2 
    sub_ca2plus<-mask(sub_ca2plus,CAII_grnd)
  qca2<-cellStats(sub_ca2plus,'sum')
  
  results[myr,1]<-parsed_list1$MONTH[myr]
  results[myr,2]<-parsed_list1$YEAR[myr]
  
  results[myr,3]<-quantity_grand_sum
  results[myr,4]<-qca1_plus
  results[myr,5]<-qca1
  results[myr,6]<-qca2_plus
  results[myr,7]<-qca2
  results[myr,8]<-parsed_list1$NAME[myr]
  setTxtProgressBar(pb, myr)
}
close(pb)









# 
# 
# 
 table_name<-"herring_mwt_areas_fw5"
 write.table(results,(file.path(YOUR.STORAGE.PATH, paste0(table_name,".csv"))) , sep=",", row.names=FALSE, col.names=c("month", "year","grand total mt","ca1plus", "ca1", "ca2plus", "ca2", "name"))  
 





















