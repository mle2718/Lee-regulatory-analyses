####
# Code to plot anonymized maps.
rm(list=ls())
######################
## Outline of the Script Process: 
# 1) Set up info, packages, etc. 
# 2) List all the rasters that are going to be processed
# 3) Put them into "parsed_groups" dataframe, to break the name up and allow us to categorize by group (FMP, species, gear), unit (revenue vs. quantity), and year.
# 4) When the code runs, you choose a group (such as a particular FMP) and creates temporary subgroups (FMP_REVENUE & FMP_QTYKEPT)
# 5) The code determines the maximum extent of data in the rasters for the whole group (for rasters of both units types)
# 6) The code then begins to run first the QTYKEPT raster, determines the value-range and breaks the values into classification bins. 
# 7) Then Min-Yang's confidentiality checker converts each raster to a polygon, and checks that at least 3 trips are in a discrete area.
#       This process re-names the value bins for 1-6, and when finished re-assigns the correct bin-values for the plotted map
#       The code plots both the original ("raw") and the reclassified map as a plotted png, also saving the CSV of value-cuts for the binning. 
# 8) The process of value-range check, confidentiality check, and plotting of pngs begins again with the REVENUE rasters. 
# 9) Next, separate codeconverts the plotted pngs to PNGs for the purpose of easier plotting on the website.
# 10) Finally, separate code also strings together PNGs by Group and Unit to create GIFs. 
######################

#### (1) - Set your info
todaysdate = as.Date(Sys.time())
max.nodes = 4 #processor nodes

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




###
#GIVE YOUR PROJECT A NAME
PROJECT.NAME="FW7_initial"

##YOU NEED TO CHANGE THESE THREE LINES of CODE TO POINT TO YOUR NETWORK SHARE
ML.NETWORK.LOCAL=file.path("/run/user/1877/gvfs/smb-share:server=net,share=home2/mlee") #THIS Is what you need to run local
ML.NETWORK.SERVER=file.path("/net/home2/mlee") #This Is what you need to run from the network.

ML.NETWORK.PATH=file.path(ML.NETWORK.SERVER) # Tell R which to use (local or server)
SSB.LOCAL = file.path("/run/user/1877/gvfs/smb-share:server=net,share=socialsci") #This is what you need to run local
SSB.NETWORK=file.path("/net/work5/socialsci") #This is what you need to run networked

SSB.DRIVE = file.path(SSB.NETWORK)
ML.PROJECT.PATH=file.path(ML.NETWORK.PATH,"RasterRequests")
ML.OUTPUT.GEOTIFF.PATH=file.path(ML.PROJECT.PATH,"outputs","geotiff",PROJECT.NAME,paste0(PROJECT.NAME,"_AGGREGATED_2019-12-10"))
export.geotiff.path =file.path(ML.PROJECT.PATH,"outputs","geotiff",PROJECT.NAME,paste0(PROJECT.NAME,"_reclass_2020-05-07"))

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
ML.CODE.PATH=file.path(ML.PROJECT.PATH,"code","herring_scripts","herring_FW7")
ML.OUTPUT.IMAGE.PATH=file.path(ML.PROJECT.PATH,"outputs","images",PROJECT.NAME)
export.image.path = file.path(ML.OUTPUT.IMAGE.PATH,paste0(PROJECT.NAME,"_AGGREGATED_2020-05-07"))


#where is the manifest of individual rasters?
individual.raster.file="individual_payload2019-12-05.Rds"
ML.DATA.PATH=file.path(ML.PROJECT.PATH,"data")

payloadRDS=file.path(ML.DATA.PATH,individual.raster.file)

# dir create this
dir.create(export.geotiff.path, recursive=T)
dir.create(export.image.path, recursive=T)


#Where are the inputs for this project


ML.GIS.PATH= file.path(ML.NETWORK.PATH, "spatial data") #Min-Yang stores some of his spatial data in this folder
################################
#SSB DRIVE
#THIS MAY CHANGE IF YOU ARE NOT MINYANG.
################################


#TEMP.CODE.PATH<-file.path(ML.PROJECT.PATH,"code","code_fragments","confidentiality")

#ML.CODE.PATH<-TEMP.CODE.PATH
#libraries


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
if(!require(maps)) {  
  install.packages("maps")
  require(maps)}
if(!require(grid)) {  
  install.packages("grid")
  require(grid)}
if(!require(ROracle)) {  
  install.packages("ROracle")
  require(ROracle)}
if(!require(data.table)) {  
  install.packages("data.table")
  require(data.table)}


substrRight <- function(b, n){
  substr(b, nchar(b)-n+1, nchar(b))
}

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

# Herring Management areas
my_HMAs = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures", "garfo gis", "Herring_Management_Areas"), layer="Herring_Management_Areas_mod", verbose=F)
my_HMAs = spTransform(my_HMAs, CRS=PROJ.USE)



#Pulling groundfish closures into memory
CAI_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_ca1", verbose=F)
CAI_grnd = spTransform(CAI_grnd, CRS=PROJ.USE)
CAI_grnd = CAI_grnd[CAI_grnd$id==2,]

CAII_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_ca2", verbose=F)
CAII_grnd = spTransform(CAII_grnd, CRS=PROJ.USE)

#done to here
#Cashes_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"),  layer="mults_cashes", verbose=F)
#Cashes_grnd = spTransform(Cashes_grnd, CRS=PROJ.USE)

NLS_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_nls", verbose=F)
NLS_grnd = spTransform(NLS_grnd, CRS=PROJ.USE)

#WGOM_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_wgom", verbose=F)
#WGOM_grnd = spTransform(WGOM_grnd, CRS=PROJ.USE)

#Loading EFH closures
#EFH_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults_efh"), layer="mults_efh", verbose=F)
#EFH_grnd = spTransform(EFH_grnd, CRS=PROJ.USE)

#REad in groundfish closed areas

Closedgf_04_15 = gUnion(CAI_grnd[CAI_grnd$id==2,],CAII_grnd)
Closedgf_04_15 = gUnion(Closedgf_04_15,NLS_grnd)
#Closedgf_04_15 = gUnion(Closedgf_04_15,Cashes_grnd)
#Closedgf_04_15 = gUnion(Closedgf_04_15,WGOM_grnd)
#######################################################################

### Set Up for Confidentiality Check  

 #where is the manifest of individual rasters?
 individual.raster.file="individual_payload2019-12-05.Rds"
 payloadRDS=file.path(ML.DATA.PATH,individual.raster.file)
 
 #Define years to create rasters for here
 START.YEAR = 2008   #Min = 1996
 END.YEAR = 2018     #Max = 2013
 
 #The first step below is to pull in the two data files from R that we need
 ############################################################################################
 #First, set up Oracle Connection
 ############################################################################################
 drv<-dbDriver("Oracle")
 host <- "sole.nefsc.noaa.gov"
 port <- 1526
 sid <- "sole"
 uid<-"mlee"
 mypass<- "ZXCasdQWE_123"
 connect.string<-paste(
   "(DESCRIPTION=",
   "(ADDRESS=(PROTOCOL=tcp)(HOST=", host, ")(PORT=", port, "))",
   "(CONNECT_DATA=(SID=", sid, ")))", sep="")
 con<-dbConnect(drv, username=uid, password=mypass, dbname=connect.string)
 ###########################################################################################
 
 # load in various preliminaries (FINAL with permits appended; list of file names)
 

 source(file.path(ML.CODE.PATH,"Step7A_confidentiality_setup.R"))
 
 
 
##################################

### Setting up BINNING options: 

# Number of breaks  -  for classifiying raster values into bins
nbreaks=5

# Subsample for Jenks Natural breaks classifications?  Set sampling-seed later
num_jenks_subs=5000 # Maybe this should be higher; set to 1000 for the map production process. But, the higher the sample the longer it takes to run.

# Here we exclude all cells <=1. (Later we deal with rasters with so few cells above the lower bound value,
    # that we change the sample size to match the number of cells with those values.)
jenks.lowerbound=1

# Min and Max x and y values set to standardize plot extent # the plot extent is set, but then adjusted based on the location of points in the plotted region
my.ylimit=c(250000,850000)
my.xlimit=c(1900000,2450000)


#cut point options 
#my.at <- seq(10, 2500, 500) #this defines equal intervals from 10 to 2500 by 500 units.

#turn things on or or off 
myscaleopts <- list(draw=FALSE) #Don't draw axes
#myscaleopts <- list(draw=TRUE)


brewer.friendly.ygb <- c("#ffffff", brewer.pal(nbreaks, "YlGnBu"))
my.friendly.YGB=rasterTheme(region=brewer.friendly.ygb)

#color options (par.setting)
mycoloropts <- c(my.friendly.YGB)
our.max.pixels=8e8

# PNG Image Size in pixel units (?) 
png.height<-1800
png.width<-1400

## land color 
mylandfill<- "#d1d1e0"
############################


# Number of color value "bins", plus 0-value will be added too.
numclasses <- 5

# Set Color Ramp Values 
brewer.friendly.bupu <- c("#ffffff", brewer.pal(numclasses, "BuPu")) # Blue to purple  (low to high) 
my.friendly.BUPU <- rasterTheme(region=brewer.friendly.bupu)
 
mycoloropts <-  c(my.friendly.BUPU) 

# Other Plotting Settings 
myckey <- list(labels=list(cex=2)) # Set the size of color ramp labels (?)




############################

#### (3) Set up to work from the FINAL MAPS folder:

# Setup to loop through unique file paths: 
# List all the rasters in "FINAL MAPS" (below) .... and parse their filenames out into FILEPATH, NAME, and UNIT (further down)
tif_pat<-glob2rx("*.tif")

#
#
######!!! FOR USE WHEN WE ADD NEW RASTERS (for example, next year's latest data)  ############

# When re-running the code with newly available rasters, start here:  #####  This is where you build and refine the list of rasters you want to use in maps!
rasterlist<- lapply(as.list(list.dirs(path=ML.OUTPUT.GEOTIFF.PATH, recursive=T)), list.files, recursive=F, full.names=T, pattern=tif_pat)

##############################

# Parse out the names of each raster's file path into chunks
    parsed_groups = do.call(rbind, lapply(rasterlist, function(xx) { # Takes the list creates dataframe where first column is filepath
      xx = as.data.frame(xx, stringsAsFactors=F)
      names(xx) = "FILEPATH" 
      return(xx) }) ) 

#patterns <- c("/Archive/", "/5_YEAR_AVG", "Calendar Year Species","Fishing_Year_Species","FMP_2016_2017","REVENUE.tif")
#parsed_groups$markout<-grepl(paste(patterns,collapse="|"),parsed_groups$FILEPATH)
#parsed_groups<-parsed_groups[(which(parsed_groups$markout==FALSE)),]

parsed_groups$NAME = sapply(parsed_groups$FILEPATH, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })

parsed_groups$NAME <-gsub(".tif","",parsed_groups$NAME)

parsed_groups$REGIME =  sapply(parsed_groups$NAME, USE.NAMES=F, function(zz) { # We are referring to "REVENUE" versus "QTYKEPT here
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(temp[NCOL(temp)]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
 
parsed_groups$REGIME<-as.numeric(parsed_groups$REGIME)  

    parsed_groups$MONTH =  sapply(parsed_groups$NAME, USE.NAMES=F, function(zz) { # Refers to the raster-group, such as the FMP or species or geartype
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(paste0(temp[NCOL(temp)-2])) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    parsed_groups$MONTH<-as.numeric(parsed_groups$MONTH)  
    
    parsed_groups$TYPE =  sapply(parsed_groups$NAME, USE.NAMES=F, function(zz) { # GROUP-UNIT combo, as in "BLUEFISHFMP-REVENUE" vs. "BLUEFISHFMP-QTYKEPT"
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(temp[1]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    
    parsed_groups$METRIC =  sapply(parsed_groups$NAME, USE.NAMES=F, function(zz) {
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(temp[2]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    
    parsed_groups$EXTRA =  sapply(parsed_groups$NAME, USE.NAMES=F, function(zz) {
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(temp[3]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    
    parsed_groups$Type_Metric_Extra =  sapply(parsed_groups$NAME, USE.NAMES=F, function(zz) {
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(file.path(paste0(temp[1],"_",temp[2],"_",temp[3]))) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    parsed_groups$Type_Metric_Extra <-paste0(parsed_groups$Type_Metric_Extra,"_regime_",parsed_groups$REGIME)
      
# Drop rows of rasters to ignore - groups of species/year, etc to NOT plot
    parsed_groups <-parsed_groups[(parsed_groups$TYPE %in% c("hrgmack")),] 
#    parsed_groups <-parsed_groups[(parsed_groups$MONTH %in% c("4","6")),] 
    
##########################################

#
### (4) Loop through the unique filepaths! - List of unique GROUPINPATH names
list_groupinpath <- sort(unique(parsed_groups$Type_Metric_Extra)) # List of unique GROUPPATHs; will break out into UNIT subgroups inside the loop

    
    
# Set file name to store the maps; check if dir exists, and if not, create folder for storing the plotted map PNGs

start.time.total <- Sys.time()

# You might want to set some things to be the same across all groups of images. If so, do that here. 
# For example, this bit of code will set the image window to be the same:
# This is also a good place to collect summary values from each raster.


############## BEGIN SET IMAGE WINDOW ###################
xxyy=data.frame() # Start with creating a new list for dimension info

  for (b in (1:nrow(parsed_groups))) {
    # For plotting rasters in a projected coordinate system
    
    extremes <- raster(parsed_groups$FILEPATH[b]) 
    parsed_groups$total_value[b]<-cellStats(extremes,'sum', na.rm="TRUE")
    extremes <- rasterToPoints(extremes, fun=function(x){x>1}) 
    
    #  (For un-projecting rasters into a Lat/Lon coordinate system...)
    #   extremes <- rasterToPoints(projectRaster(raster(temp_rgrouplist$FILEPATH[b]), crs=PROJ.LATLON), fun=function(x){x>1}) 
    
    
    extremes.df <- as.data.frame(extremes)
    
    max.x <- max(extremes.df$x)
    min.x <- min(extremes.df$x)
    max.y <- max(extremes.df$y)
    min.y <- min(extremes.df$y)
    xxyy= rbind(xxyy, c(max.x,min.x,max.y,min.y))
    
  } # end loop setting up max extent info 
  
  # Add column names for ease of comprehension
  colnames(xxyy)=c("MaxX", "MinX", "MaxY", "MinY")
  
  # These are min and max x and y values set for standardizing plot extents
  extreme.ylimit = c(min(xxyy[,"MinY"]), max(xxyy[,"MaxY"]))
  extreme.xlimit = c(min(xxyy[,"MinX"]), max(xxyy[,"MaxX"]))
  
  
  ############## END SET IMAGE WINDOW ###################
  



# Begin loop through each raster GROUPUNITPATH (as in, each subset of rasters) 
#  for (i in (5:length(list_groupinpath))){
# for (i in (1:1 )) {

i<-1
  
for (i in (1:length(list_groupinpath))){

# Create a list of rasters that are in that GROUPUNITPATH 
  temp_rgrouplist <- parsed_groups[parsed_groups$Type_Metric_Extra == list_groupinpath[i],] # All rasters in a GroupPath (As in, in "MONKFISH FMP" - not broken by unit yet)
  
  temp_R_list <- temp_rgrouplist
  temp_R_list$textUnit <- temp_rgrouplist$METRIC
  
  #rescale to "total dollars per square km"
  rescale_factor<-4
  

# Determine max. extent for all rasters in the metier (both REVENUE and QUANTITY) 
# #
#   xxyy=data.frame() # Start with creating a new list for dimension info
#   
#   for (b in (1:nrow(temp_rgrouplist))) {
#   # For plotting rasters in a projected coordinate system
#       extremes <- rasterToPoints(raster(temp_rgrouplist$FILEPATH[b]), fun=function(x){x>1}) 
#     
#   #  (For un-projecting rasters into a Lat/Lon coordinate system...)
#   #   extremes <- rasterToPoints(projectRaster(raster(temp_rgrouplist$FILEPATH[b]), crs=PROJ.LATLON), fun=function(x){x>1}) 
#   
#       
#   extremes.df <- as.data.frame(extremes)
#         
#         max.x <- max(extremes.df$x)
#         min.x <- min(extremes.df$x)
#         max.y <- max(extremes.df$y)
#         min.y <- min(extremes.df$y)
#         xxyy= rbind(xxyy, c(max.x,min.x,max.y,min.y))
#   
#       } # end loop setting up max extent info 
#   
# # Add column names for ease of comprehension
#   colnames(xxyy)=c("MaxX", "MinX", "MaxY", "MinY")
#     
# # These are min and max x and y values set for standardizing plot extents
#   extreme.ylimit = c(min(xxyy[,"MinY"]), max(xxyy[,"MaxY"]))
#   extreme.xlimit = c(min(xxyy[,"MinX"]), max(xxyy[,"MaxX"]))
#  
  
  
  
  
### FIND BINNING & PLOT THE RASTERS in the GROUP    
if(nrow(temp_R_list) > 1){ # error catch when there was accidentally no Q or R folders for a metier....
#
  R.start.time <- Sys.time()
# You MUST make a new "mylist" object or the sampling will not work correctly. 
  mylist=list() # for new Jenks binning
  
#### Additional code for confidentiality check
working_group<-temp_R_list

TME<-working_group$Type_Metric_Extra[1]
source(file.path(ML.CODE.PATH, "confid_match_and_subset_mod.R")) #Might need to add a file.path(working directory,”confid_match_and_subset.R”)
####
  
  for (s in (1:nrow(temp_R_list))){ # Do jenks binning on GROUP-UNIT subset, and plot those rasters
      start.time <- Sys.time()
      subsamp<-values(raster(temp_R_list$FILEPATH[s]))
      subsamp<-subsamp[subsamp>jenks.lowerbound]
      mylist[[length(mylist)+1]] = subsamp
    }
# Using list of raster cell values, create the jenks breaks
    myvals<-unlist(mylist) 
    myvals<-myvals/rescale_factor
    glob_max<-floor(max(myvals)) 
    
    set.seed(24601)
  
    mysubs<-sample(myvals,num_jenks_subs) # sampling occurs here, refers back to the "set.seed"
    myclass <- classIntervals(mysubs, n=nbreaks,style="jenks", warnLargeN=FALSE, largeN=6000)
    mybreaks_class1<-c(0,myclass$brks) # Here we add a "zero" bin, manually. 
    
# Now we set up ANOTHER loop to plot the rasters in temp_rasterlist
for (t in (1:nrow(temp_R_list))){
  
      #To fix this, we will set all raster values greater than the upper bound to be slightly less than this upper bound
      myras<-raster(temp_R_list$FILEPATH[t])
      myras<-myras/rescale_factor
         # myras_proj <- projectRaster(myras, crs=PROJ.LATLON)
      
      mygroup <- as.character(temp_R_list$Type_Metric_Extra[t])
      ub=mybreaks_class1[length(mybreaks_class1)]
      myras[myras>=ub]<-floor(ub)
      
#########
# Min-Yang's code changes for reclassification to 1-6 from value bins
  blength <-length(mybreaks_class1)-1
  myclass_matrix <- cbind(mybreaks_class1[1:blength],c(mybreaks_class1[2:blength],glob_max), 1:blength)                      
  
  myr2<-reclassify(myras,myclass_matrix, include.lowest=TRUE, right=TRUE)
  
  colnames(myclass_matrix)<-c("LB","UB","CATEGORY")
  cutnames<-working_group$NAME[1]
  cutnames<-gsub(" ", "_", cutnames)
  cutnames<-gsub("/", "_", cutnames)
  cutnames<-paste0(cutnames,".csv")
  
  write.csv(myclass_matrix, file=file.path(export.geotiff.path,cutnames),  row.names=FALSE)
  working_year<-temp_R_list$YEAR[p]
  
  source(file.path(ML.CODE.PATH, "production_confidential_checker.R"))  # Might need to add a file.path

#########

# Now set up to plot this GROUP of rasters, with the above-determined binning scheme

  # Filename for 'RAW' plotted png
  png_filename=paste0("raw_", temp_R_list$NAME[t], ".png")
  rawPNG.file <- file.path(export.image.path, png_filename)
  
  
  my.regime<-temp_R_list$REGIME[t]
  
  my.regime[which(my.regime==1)]<-"2008-2015"
  my.regime[which(my.regime==2)]<-"2016-2018"
  
  my.month<-temp_R_list$MONTH[t]
  my.month[which(my.month==0)]<-"N/A"
  my.month<-paste0("Month=",my.month)
  
  #my.gear<-paste0("Gear=",temp_R_list$GEAR[t])
  
  
  
  
  # Filename for RECLASSIFIED plotted map png
      reclass_filename=paste0("reclass_", temp_R_list$NAME[t], ".png")
      reclassPNG.file <- file.path(export.image.path, reclass_filename)
      
      # Create a graphical object of text

      our.max.pixels = 8e8 # This is slightly larger than the number of cells in the baseraster (the max number of cells possible)
      
      jcons<-levelplot(myras, 
                       raster=TRUE,
                       #aspect="xy",
                       maxpixels=our.max.pixels,
                       margin=FALSE, 
                       #main=title_opts1,                  
                       par.setting=mycoloropts, scales=myscaleopts, at=mybreaks_class1, 
                       xlim=extreme.xlimit,ylim=extreme.ylimit, 
                       colorkey=myckey 
                      )
# OUTPUT  for the RAW raster 
      png(file=rawPNG.file, width=png.width, height=png.height, units="px"
          , bg="white")
      
      
      
      print(jcons+ layer(sp.lines(CAI_grnd)) + layer(sp.lines(CAII_grnd))
            + layer(sp.lines(NLS_grnd))+ layer(sp.polygons(my_basemap2, fill=mylandfill))
            + layer(grid.text(my.regime,draw=TRUE,x=unit(0.80, "npc"),y=unit(0.10, "npc"), just="left",gp=gpar(fontsize=12, cex=1.5)))
            #+ layer(grid.text(my.gear,draw=TRUE,x=unit(0.82, "npc"),y=unit(0.075, "npc"), just="left",gp=gpar(cex=1.5)))
            + layer(grid.text(my.month,draw=TRUE,x=unit(0.80, "npc"),y=unit(0.05, "npc"), just="left",gp=gpar(fontsize=12, cex=1.5)))
            
      )
      
      # print(jcons 
      #       + layer(sp.polygons(my_basemap2,fill=mylandfill))
      #       + layer(sp.polygons(my_basemap3,lwd=2,col='gray'))
            #+ layer(grid.text(tempyear,draw=TRUE,x=unit(0.80, "npc"),y=unit(0.1, "npc"), gp=gpar(cex=2.5)))
            #+ layer(grid.text(tempyear,draw=TRUE,x=unit(0.80, "npc"),y=unit(0.1, "npc"), gp=gpar(cex=1.5)))
            #+ layer(grid.draw(gr.text))
     # )
      dev.off()
##################################      
      end.time <- Sys.time()
      print(paste0("REVENUE rasters were built in ", round((end.time - start.time), digits=2), " minutes."))
      
##### 
      #reclass_gtiff_name<-gsub(".png", ".tif", reclass_filename) 
      reclass_gtiff_name<-gsub(".png", ".tif", reclass_filename) 
      #store the reclassified raster.
      writeRaster(myr2, file.path(export.geotiff.path,reclass_gtiff_name), format="GTiff", overwrite=T)
      
      our.max.pixels = 550000 #8e6 # This is slightly larger than the number of cells in the baseraster (the max number of cells possible)
      
      mylegend<-floor(mybreaks_class1)
      #sub in the true largest value 
      mylegend[length(mylegend)]<-glob_max
      myckey2<-list(at=seq(0, length(mylegend)-1, 1), labels=list(at=seq(0,length(mylegend)-1,1),labels=mylegend, cex=2))
      
      rclassed<-levelplot(myr2,  
                            #raster=TRUE,
                            #aspect="xy",
                            maxpixels=our.max.pixels,
                            margin=FALSE,
                            col.regions=brewer.friendly.bupu,scales=myscaleopts,
                            at=seq(0, length(mylegend)-1, 1),
                            xlim=extreme.xlimit,ylim=extreme.ylimit,
                            colorkey=myckey2
                            )
      reclassPNG.file
      png(file=reclassPNG.file, width=png.width, height=png.height, units="px"
          , bg="white")
      
      print(rclassed+ layer(sp.lines(CAI_grnd)) + layer(sp.lines(CAII_grnd))
            + layer(sp.lines(NLS_grnd))+ layer(sp.polygons(my_basemap2, fill=mylandfill))
            + layer(grid.text(my.regime,draw=TRUE,x=unit(0.80, "npc"),y=unit(0.10, "npc"), just="left",gp=gpar(fontsize=12, cex=1.5)))
            #+ layer(grid.text(my.gear,draw=TRUE,x=unit(0.82, "npc"),y=unit(0.075, "npc"), just="left",gp=gpar(cex=1.5)))
            + layer(grid.text(my.month,draw=TRUE,x=unit(0.80, "npc"),y=unit(0.05, "npc"), just="left",gp=gpar(fontsize=12, cex=1.5)))
            
      )
      #print(rclassed
       #     + layer(sp.polygons(my_basemap2,fill=mylandfill))
        #    + layer(sp.polygons(my_basemap3,lwd=2,col='gray'))
            #+ layer(grid.text(tempyear,draw=TRUE,x=unit(0.80, "npc"),y=unit(0.1, "npc"), gp=gpar(cex=2.5)))
            #+ layer(grid.text(tempyear,draw=TRUE,x=unit(0.80, "npc"),y=unit(0.1, "npc"), gp=gpar(cex=1.5)))
            #+ layer(grid.draw(gr.text))
      #)
      dev.off()
      
###     
      print(paste0("You just made the ",reclass_gtiff_name, " image" ))
      
    }  
    # END loop plotting REVENUE rasters
##############
    R.end.time <- Sys.time()
} # End error-catch for R list < 5 rows

    print(paste0("Started at ", (R.start.time)," and ended at ", R.end.time, ". Total time: ", (R.end.time - R.start.time)))
    print("------------------")
################################
### Ends where the rasters are individually plotted
  } 

# Ends whole loop!
end.time.total <- Sys.time()
end.time.total-start.time.total

############################
####
csv_out<-file.path(export.image.path,"parsed_groups.csv")
write.csv(parsed_groups, csv_out)

  