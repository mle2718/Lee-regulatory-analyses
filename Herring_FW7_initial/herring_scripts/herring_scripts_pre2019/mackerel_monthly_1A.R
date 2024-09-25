#################################################################################
#################################################################################
### HERE IS THE TABLE OF CONTENTS 
# SECTION 1 -- Set up directories 
# SECTION 2  - LOAD PACKAGES 
# SECTION 3 - SPECIFY MAPPING OPTIONS
# SECTION 4 - LOAD EXISTING GIS DATA
# SECTION 5 - MAKE MAPS

###### This script is for exploratory mapping of rasters

todaysdate = as.Date(Sys.time())

#################################################################################
# Section 1 -- Set up directories 
#################################################################################
#################################################################################
#################################################################################

# #THIS SECTION CONTAINS PLACES TO LOOK FOR DATA
# MINYANG's locations
# ML.NETWORK.PATH this is how Min-Yang Mounts his network drive.  You will want to change this.
# PROJECT PATH IS A FOLDER IN MY SHARED DRIVE
# DATA.PATH is a FOLDER INSIDE MY PROJECT PATH
# The TIF data is stored in a subfolder of DATA.PATH. 
##########   This is because the code to get a list of files throws up if there are no subfolders.
##########   The code to get a list of files throws up because I, Min-Yang, stole it from Geret.
# ML.GIS.PATH is the location of some shapefiles. 


##YOU NEED TO CHANGE THESE THREE LINES of CODE TO POINT TO YOUR NETWORK SHARE
ML.NETWORK.LOCAL=file.path("/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee") #THIS Is what you need to run local
ML.NETWORK.SERVER=file.path("/net/home2/mlee") #This Is what you need to run from the network.


YOUR.NETWORK.PATH=file.path(ML.NETWORK.SERVER) # Tell R which to use (local or server)

YOUR.PROJECT.PATH=file.path(YOUR.NETWORK.PATH,"RasterRequests")
# YOUR.DATA.PATH=file.path(YOUR.PROJECT.PATH,"2016-03-15_rasterexport") #Annual Kepts for 2006-2014, all herring
# YOUR.DATA.PATH=file.path(YOUR.PROJECT.PATH,"2016-03-07_rasterexport") #This has MWT and PUR yearly in it
YOUR.DATA.PATH=file.path(YOUR.PROJECT.PATH,"MACKEREL_MWT_10252017") #This has monthly MWT and PUR yearly in it

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
source(file.path(GD.RASTERS,"FINAL_Raster_Functions.R"))

#GENERIC GIS FOLDER (These are maintained by Sharon Benjamin) 
GENERIC.GIS.PATH= file.path(SSB.DRIVE, "GIS")
FREQUENT.USE.SSB= file.path(GENERIC.GIS.PATH, "FrequentUseSSB")
################################




#####################################################
## OUTPUT LOCATIONS
#####################################################
exportfolder = file.path(YOUR.PROJECT.PATH,paste0("thirty_minute_extractions_",todaysdate))
dir.create(exportfolder, recursive=T)

YOUR.STORAGE.PATH=file.path(exportfolder)  #To recap, we are storing things in the folder "exportfolder" which is in the directory defined by YOUR.DATA.PATH
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





#################################################
# STEP 3 -- Set your mapping options
#################################################
#### WHAT ARE YOU TRYING TO MAP?
sp1<-"*mackerel_MWT*"
z<-paste0(sp1,".tif")
mypat1<-glob2rx(z)










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


#Load in the buffer files

my_HMAs = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures", "garfo gis", "Herring_Management_Areas"), layer="Herring_Management_Areas", verbose=F)

my_HMAs = spTransform(my_HMAs, CRS=PROJ.USE)
my_6nm<-my_HMAs[my_HMAs@data$GARFO_ID == c("G000167"), ]



#################################################
## END SECTION 4 
#################################################

list1<- lapply(as.list(list.dirs(path=YOUR.DATA.PATH, recursive=T)), list.files, recursive=F, full.names=T, pattern=mypat1)

parsed_list1a = do.call(rbind, lapply(list1, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILEPATH" 
  return(xx) }) )                                         
parsed_list1a$first_part =  sapply(parsed_list1a$FILEPATH, USE.NAMES=F, function(zz) {
  strsplit(x = as.character(zz), split = ".tif")[[1]]
})
parsed_list1a$NAME = sapply(parsed_list1a$first_part, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })
#parsed_list1a$YEAR = str_sub(parsed_list1a$NAME,-4)


parsed_list1a$GROUP = sapply(parsed_list1a$first_part, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)-1]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name


parsed_list1a$REGIME = sapply(parsed_list1a$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[NCOL(temp)]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name


parsed_list1a$GEAR = sapply(parsed_list1a$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[3]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name

parsed_list1a$MONTH = sapply(parsed_list1a$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[5]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name

parsed_list1a$TYPE = sapply(parsed_list1a$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(NCOL(temp)) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name

#overwite MONTH=0 if TYPE=5
parsed_list1a$MONTH[which(parsed_list1a$TYPE==5)]<-0




my_name1=list()

my_month1=list()
my_annual_qty1=list() #A place to hold things

my_block_qty6=list()



for (i in 1:nrow(parsed_list1a)) {
  myras<-raster(parsed_list1a$FILEPATH[i])
  mya<-cellStats(myras,'sum')
  
  
    #subset the 30 minute square
    #Loop over the items of icare, subset the basemap to pull out the squares.
    #extract the rasters inside those squares
    #sum them up 
    #stick them in the list
    
    rvals6<-extract(myras,my_6nm) #Subset raster data within 6nm
    r6<-unlist(lapply(rvals6, function(x) if (!is.null(x)) sum(x, na.rm=TRUE) else NA ))
    

    
    my_block_qty6[[length(my_block_qty6)+1]] = r6

    
    
    
    my_annual_qty1[[length(my_annual_qty1)+1]] = mya
    my_month1[[length(my_month1)+1]] = parsed_list1a$MONTH[i]
    my_name1[[length(my_name1)+1]] = parsed_list1a$NAME[i]
    print(paste0("this is iteration ",i))
      }






#THIS IS HORRIDLY INEFFICIENT
y1<-do.call(rbind, lapply(my_month1, data.frame, stringsAsFactors=FALSE))

name<-do.call(rbind, lapply(my_name1, data.frame, stringsAsFactors=FALSE))

inside6<-do.call(rbind, lapply(my_block_qty6, data.frame, stringsAsFactors=FALSE))

annual<-do.call(rbind, lapply(my_annual_qty1, data.frame, stringsAsFactors=FALSE))

my_output1<-data.frame(y1,name,inside6,annual)

write.table(my_output1,(file.path(YOUR.STORAGE.PATH, "hma1A_mackerel_landings.csv")), sep=",", row.names=FALSE, col.names=c("month", "name", "in1A","annual"))  

                # This is where you should add new column names - check that you put them in the correct order!












