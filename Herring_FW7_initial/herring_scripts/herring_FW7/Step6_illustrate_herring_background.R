#################################################################################
#################################################################################
### HERE IS THE TABLE OF CONTENTS 
# SECTION 1 -- Set up directories 
# SECTION 2  - LOAD PACKAGES 
# SECTION 3 - SPECIFY MAPPING OPTIONS
# SECTION 4 - LOAD EXISTING GIS DATA
# SECTION 5 - MAKE MAPS

###### This script is for exploratory mapping of rasters. It will look into a folder.  It will parse the contents of that folder. 
## TIFs that are in a sub-folder will be mapped using the same binning/scaling.
## TIFS that are in different sub-folders will be mapped using different binning.

rm(list=ls())
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
PROJECT.NAME="FW7_initial"

ML.NETWORK.PATH=file.path(ML.NETWORK.SERVER) # Tell R which to use (local or server)

ML.PROJECT.PATH=file.path(ML.NETWORK.PATH,"RasterRequests")

ML.CODE.PATH=file.path(ML.PROJECT.PATH,"code","herring_scripts","herring_FW7")

ML.OUTPUT.IMAGE.PATH=file.path(ML.PROJECT.PATH,"outputs","images",PROJECT.NAME)
ML.OUTPUT.GEOTIFF.PATH=file.path(ML.PROJECT.PATH,"outputs","geotiff",PROJECT.NAME,paste0(PROJECT.NAME,"_AGGREGATED_2019-12-10"))

export.image.path = file.path(ML.OUTPUT.IMAGE.PATH,paste0(PROJECT.NAME,"_AGGREGATED_2019-12-10"))


#where is the manifest of individual rasters?
individual.raster.file="individual_payload2019-12-05.Rds"
ML.DATA.PATH=file.path(ML.PROJECT.PATH,"data")

payloadRDS=file.path(ML.DATA.PATH,individual.raster.file)



ML.GIS.PATH= file.path(ML.NETWORK.PATH, "spatial data") #Min-Yang stores some of his spatial data in this folder
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
exportfolder = file.path(export.image.path)
dir.create(exportfolder, recursive=T)

YOUR.STORAGE.PATH=file.path(exportfolder)  #To recap, we are storing things in the folder "output" which is in the directory defined by ML.OUTPUT.GEOTIFF.PATH
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
if(!require(data.table)) {  
  install.packages("data.table")
  require(data.table)}

substrRight <- function(b, n){
  substr(b, nchar(b)-n+1, nchar(b))
}



#################################################
# STEP 3 -- Set your mapping options
#################################################
#### WHAT ARE YOU TRYING TO MAP?
# I WANT TO Separately MAP ALL THE GEOTIFS THAT MATCH a particular pattern 
#sp1<-"hrgmack_revenue"
# sp1<-"herring_pounds"
# z<-paste0("*",sp1,"*.tif")
# mypat1<-glob2rx(z)

mypat1<-glob2rx("*.tif")
#outfilestub<-"herring_pounds_avg_"

#3a. rasterViz options
#THIS CODE MAKES 3 "rasterTheme" to pass to rasterViz.
#  ?rasterViz and ?RColorBrewer may be helpful
#  Blue, Green, and Dichromatic.
#  There is a maximum of 9 classes, one of which is transparent and useful for forcing the zeros to have no color.  

numclasses<-5


brewer.friendly.ygb <- c("#ffffff", brewer.pal(numclasses, "YlGnBu"))
my.friendly.YGB=rasterTheme(region=brewer.friendly.ygb)
mycoloropts <- c(my.friendly.YGB)


#if you want, you can set the number of breaks less than (numclasses+1).  Which I have done.
nbreaks=5

#you could also color the bottom 3 colors as white, to focus on the hottest spots

ygb_sub=c(rep("#ffffff",3),brewer.friendly.ygb[4:6])
my.friendly.YGB_sub=rasterTheme(region=ygb_sub)
mycoloropts2 <- c(my.friendly.YGB_sub)


# How large do you want the subsample for Jenks Natural breaks classifications? 
# 10,000 runs reasonably quickly. don't pick too many
# If you ask for a subsample, it's a good idea to set a seed.
num_jenks_subs=2000
set.seed(8675309)
# You might want to exclude zeros or anythign that is below a threshold. I'm going to exclude all cells <=1.
jenks.lowerbound=1

############################
#3C. This code contains  options to pass to levelplot.  ?levelplot, ?lattice, and ?xyplot may be helpful.
############################
##These are options that you can pass to levelplot.  It can help ensure that you have identical windows
# xlim= and ylim= options can used to set the window
# scale= options can be use to scale things (or turn off axes)
# par.setting= is used to set the color theme
# at= is used for custom binning


#xlim and ylim options (set the window)

my.ylimit=c(250000,850000)
my.xlimit=c(1900000,2450000)


#cut point options 
#my.at <- seq(10, 2500, 500) #this defines equal intervals from 10 to 2500 by 500 units.

#turn things on or or off 
myscaleopts <- list(draw=FALSE) #Don't draw axes
#myscaleopts <- list(draw=TRUE)



#color options (par.setting)
mycoloropts <- c(my.friendly.YGB)

our.max.pixels=8e8
#colorkey  -- set the size of the labels
myckey <- list(labels=list(cex=2)) #This makes the scale of the labels "big"

##HERE ARE SOME OPTIONS TO PASS TO PNG
png.height<-1000
png.width<-1000

## land color 
mylandfill<- "#d1d1e0"
############################











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


# Herring Management areas
my_HMAs = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures", "garfo gis", "Herring_Management_Areas"), layer="Herring_Management_Areas", verbose=F)
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

A8LD = readOGR(dsn=file.path(ML.GIS.PATH,"herring_A8","Final_A8_Localized_Depletion_Closure"), layer="Final_A8_Localized_Depletion_Closure", verbose=F)
A8LD = spTransform(A8LD, CRS=PROJ.USE)

#WGOM_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults closed areas"), layer="mults_wgom", verbose=F)
#WGOM_grnd = spTransform(WGOM_grnd, CRS=PROJ.USE)

#Loading EFH closures
#EFH_grnd = readOGR(dsn=file.path(ML.GIS.PATH,"spatial management measures","mults_efh"), layer="mults_efh", verbose=F)
#EFH_grnd = spTransform(EFH_grnd, CRS=PROJ.USE)

#REad in groundfish closed areas

Closedgf_04_15 = gUnion(CAI_grnd[CAI_grnd$id==2,],CAII_grnd)
#Closedgf_04_15 = gUnion(Closedgf_04_15,NLS_grnd)
#Closedgf_04_15 = gUnion(Closedgf_04_15,Cashes_grnd)
#Closedgf_04_15 = gUnion(Closedgf_04_15,WGOM_grnd)

#################################################
## END SECTION 4 
#################################################











##############################################
## SECTION 5 - DO STUFF! 
#IF MIN-YANG HAD CODED THINGS PROPERLY, YOU SHOULD NOT NEED TO CHANGE ANYTHING BELOW HERE
#################################################





#################################################
#GET A LIST OF FILES. PUT IT INTO A DATASET
#################################################

list1<- lapply(as.list(list.dirs(path=ML.OUTPUT.GEOTIFF.PATH, recursive=T)), list.files, recursive=F, full.names=T, pattern=mypat1)

parsed_list1a = do.call(rbind, lapply(list1, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILEPATH" 
  return(xx) }) )                                         

parsed_list1a$NAME = sapply(parsed_list1a$FILEPATH, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })

parsed_list1a$NAME <-gsub(".tif","",parsed_list1a$NAME)

parsed_list1a$REGIME = sapply(parsed_list1a$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[NCOL(temp)]) })
parsed_list1a$REGIME<-as.numeric(parsed_list1a$REGIME)


parsed_list1a$MONTH = sapply(parsed_list1a$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[NCOL(temp)-2]) })
parsed_list1a$MONTH<-as.numeric(parsed_list1a$MONTH)
  
parsed_list1a$species = sapply(parsed_list1a$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[1]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name

parsed_list1a$metric = sapply(parsed_list1a$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[2]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name

parsed_list1a$gears = sapply(parsed_list1a$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[3]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name


parsed_list1a$GROUP<-paste0(parsed_list1a$species,"_",parsed_list1a$metric,"_",parsed_list1a$gears)




#LOOP OVER the GROUPS
distinct_groups<-unique(parsed_list1a$GROUP)
for (mygroup in distinct_groups)  {
  
  #SETUP subdirectories for holding images
  
  STORE.SUBDIR<-paste0(mygroup,"_trimmed_rescale")
  dir.create(file.path(exportfolder,STORE.SUBDIR), recursive=T)

  parsed_list1 <- parsed_list1a[which(parsed_list1a$GROUP==mygroup),]
  



###############################################################################
#LOOP OVER ALL ROWS IN parsed_list1 and build a single jenks category
  #THIS reads in all the Raster data and drops all the zeros.
  #THen stacks them all together into a big list, subsamples, and runs a Jenks NB classifcation.
  #Then it remaps the final cutpoint to the global maximum
###############################################################################



# IF YOU DON'T WANT JENKS BREAKS, COMMENT THIS OUT.
# This bit of code will look at the data in a raster. It will first include only the values that
# are greater than your "jenks.lowerbound" value defined above and do the Jenks classification.
# because the way the loop is written, it will do a single classification for ALL of the rasters that are
# in parsed_list1













mylist = list()
for (i in 1:nrow(parsed_list1)) {


 #This bit of code does Jenks breaks
  subsamp<-values(raster(parsed_list1$FILEPATH[i]))
  subsamp<-subsamp[subsamp>jenks.lowerbound]
  mylist[[length(mylist)+1]] = subsamp
}


myvals<-unlist(mylist)
glob_max<-max(myvals)
mysubs<-sample(myvals,num_jenks_subs)


myclass <- classIntervals(mysubs, n=nbreaks,style="jenks")
mybreaks_class1<-c(0,myclass$brks)
#I add a zero manually. Therefore, the first bin is defined as [0,jenks.lowerbound).
#   #End JENKS BREAKS code




#LOOPY MAPPING

# DO THE MAPPING
for (i in 1:nrow(parsed_list1)) {

  myras<-raster(parsed_list1$FILEPATH[i])
  
  #JB is has a hard upper bound. This means that any value above this upper bound will have no colors.
  #To fix this, we will set all raster values greater than the upper bound to be slightly less than this upper bound
  
  ub=mybreaks_class1[length(mybreaks_class1)]
  myras[myras>=ub]<-floor(ub)
  

 #Set up 2 file names pfilename to store the maps.  
 
  
  #pfilename=paste(parsed_list1$outname[i],"crude", sep="_")
  #pfilename=paste(pfilename,"png",sep=".")


  savefilename=paste0(parsed_list1$NAME[i],".png")
  
  #title_opts1<-list(parsed_list1$NAME[i],cex=2)
  
  #make the object 'p' that is a levelplot.  Pass some options through.
  #make the object 'jcons' that is a levelplot.  Pass some options through.  Most importantly, these are the options from the jenks breaks
  

  jcons<-levelplot(myras, margin=FALSE, maxpixels=our.max.pixels,
                   par.setting=mycoloropts2,scales=myscaleopts, at=mybreaks_class1, 
                   xlim=my.xlimit, ylim=my.ylimit, colorkey=myckey)
  
  
  #Build a small legend for the maps
  
  
  my.regime<-parsed_list1$REGIME[i]
  
  my.regime[which(my.regime==1)]<-"2008-2015"
  my.regime[which(my.regime==2)]<-"2016-2018"
  
  my.month<-parsed_list1$MONTH[i]
  my.month[which(my.month==0)]<-"N/A"
  my.month<-paste0("Month=",my.month)

  my.gear<-parsed_list1$gears[i]

  my.gear[which(my.gear=="allgears")]<-"gear=All"
  my.gear[which(my.gear=="noPUR")]<-"gear=excludes PUR"
  my.gear[which(my.gear=="avgmonth")]<-"gear=All"
  
  
    png(filename=file.path(export.image.path,savefilename), 
      height=png.width,
      width=png.width,
      units="px"
  )
  
  print(jcons+  layer(sp.lines(CAI_grnd)) + layer(sp.lines(CAII_grnd)) + layer(sp.lines(A8LD))
        + layer(sp.lines(NLS_grnd))+ layer(sp.polygons(my_basemap2, fill=mylandfill)) + layer(sp.lines(my_HMAs))
        + layer(grid.text(my.regime,draw=TRUE,x=unit(0.82, "npc"),y=unit(0.10, "npc"), just="left",gp=gpar(cex=2)))
        + layer(grid.text(my.month,draw=TRUE,x=unit(0.82, "npc"),y=unit(0.05, "npc"), just="left",gp=gpar(cex=2)))
        + layer(grid.text(my.gear,draw=TRUE,x=unit(0.82, "npc"),y=unit(0.075, "npc"), just="left",gp=gpar(cex=2)))
  
        )
  dev.off()
  
  
}

}
###############################################################################
###############################################################################
#LOOP OVER ALL ROWS IN parsed_list2 and do some stuff
###############################################################################
###############################################################################
# 
# 
# png(filename=file.path(export.geotiff.path,STORE.SUBDIR,"tempA.png"), 
#     height=10000,
#     width=10000,
#     units="px"
# )
# plot(myras)
# dev.off()


