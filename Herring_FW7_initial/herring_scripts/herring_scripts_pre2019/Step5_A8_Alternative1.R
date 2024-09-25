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
YOUR.DATA.PATH=file.path(YOUR.PROJECT.PATH,"2016-07-21_task12_rasterexport") #This has monthly MWT and PUR yearly in it

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
exportfolder = file.path(YOUR.PROJECT.PATH,"A8_Alternative1")
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
if(!require(data.table)) {  
  install.packages("data.table")
  require(data.table)}




#################################################
# STEP 3 -- Set your mapping options
#################################################
#### WHAT ARE YOU TRYING TO MAP?
sp1<-"QTYKEPT"
z<-paste0("*",sp1,"9999.tif")
mypat1<-glob2rx(z)



############################
#3C. This code contains  options to pass to levelplot.  ?levelplot, ?lattice, and ?xyplot may be helpful.
############################
##These are options that you can pass to levelplot.  It can help ensure that you have identical windows
# xlim= and ylim= options can used to set the window
# scale= options can be use to scale things (or turn off axes)
# par.setting= is used to set the color theme
# at= is used for custom binning

my.ylimit=c(-200000,900000)
my.xlimit=c(1700000,2600000)
#my.at <- seq(10, 2500, 500) #this defines equal intervals from 10 to 2500 by 500 units.
myscaleopts <- list(draw=FALSE) #Don't draw axes
# myscaleopts <- list(draw=TRUE) #draw axes

mycoloropts <- myBLUETHEME #Use the theme "myBLUETHEME" defined above
mycoloropts <- mydichrome  #Use the theme "mydichrome" defined above

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



#6nm buffer
my_6nm<-LOAD.AND.PREP.GIS("USCoastline_clipped_6nm",PROJECT.PATH=file.path(ML.GIS.PATH,"basic spatial data", "USCoastline"),  PROJ.USE=PROJ.USE)


#12nm buffer
my_12nm<-LOAD.AND.PREP.GIS("USCoastline_clipped_12nm",PROJECT.PATH=file.path(ML.GIS.PATH,"basic spatial data", "USCoastline"),  PROJ.USE=PROJ.USE)


#35nm buffer
my_35nm<-LOAD.AND.PREP.GIS("USCoastline_clipped_35nm",PROJECT.PATH=file.path(ML.GIS.PATH,"basic spatial data", "USCoastline"),  PROJ.USE=PROJ.USE)


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

#get the 13th and 14th characters from NAME. Discard the Q for the single digit months
parsed_list1$MONTH = sub('Q$',' ',str_sub(parsed_list1$NAME,1,2))


parsed_list1$closed<-0
parsed_list1$closed[parsed_list1$MONTH>=5 & parsed_list1$MONTH<=8] <-1 



#READ IN ALL RASTERS, put them on the right extent, and add them together, saving the outputs

for (myc in 0:1)  {
  
  fl1 <- parsed_list1[which(parsed_list1$closed== myc),]
  
  f<-extent(raster(file.path(fl1$FILEPATH[1])))
  new_xmin<-xmin(f)
  new_ymin<-ymin(f)
  new_xmax<-xmax(f)
  new_ymax<-ymax(f)
  
  
  for (pp in 2:nrow(fl1)){
    f2<-extent(raster(file.path(fl1$FILEPATH[pp])))
    new_xmin<-min(new_xmin,xmin(f2))
    new_ymin<-min(new_ymin,ymin(f2))
    new_xmax<-max(new_xmax,xmax(f2))
    new_ymax<-max(new_ymax, ymax(f2))
  }
  
  ## THIS SETS THE NEW EXTENT that constant for each year.
  f3<-extent(new_xmin,new_xmax, new_ymin, new_ymax)
  
  #set up a zero raster
  aggregate<-raster(f3, res=500, vals=0)
  
  
  for (myr in 1:nrow(fl1)){
    #REad in raster
    temp<-extend(raster(file.path(fl1$FILEPATH[myr])), f3, value=0)
    aggregate<-temp+aggregate
  }

  assign(paste("aggregate",myc, sep=""), aggregate)
  
}
#after this, you will have two rasters in memory, aggregate0 and aggregate1.  



  myras<-aggregate0
  mya0<-cellStats(myras,'sum')
  
  
square<-114
  
    #subset the 30 minute square
    #Loop over the items of icare, subset the basemap to pull out the squares.
    #extract the rasters inside those squares
    #sum them up 
    #stick them in the list
    
    sub<-my_basemap[my_basemap@data$NERO_ID == square & !is.na(my_basemap@data$NERO_ID) , ]
    #Mask the values OUTSIDE the square of interest to NA
    raster_subset<-mask(myras,sub)
    #Mask the values OUTSIDE the 6nm buffer to NA
    
    raster_subset<-mask(raster_subset,my_6nm)
    myb0<-cellStats(raster_subset,'sum')
    

    
    
    
    
    
    
    
    myras<-aggregate1
    mya1<-cellStats(myras,'sum')
    
    
    #subset the 30 minute square
    #Loop over the items of icare, subset the basemap to pull out the squares.
    #extract the rasters inside those squares
    #sum them up 
    #stick them in the list
    
    sub<-my_basemap[my_basemap@data$NERO_ID == square & !is.na(my_basemap@data$NERO_ID) , ]
    #Mask the values OUTSIDE the square of interest to NA
    raster_subset<-mask(myras,sub)
    #Mask the values OUTSIDE the 6nm buffer to NA
    
    raster_subset<-mask(raster_subset,my_6nm)
    myb1<-cellStats(raster_subset,'sum')
    

    results<-rbind(cbind(0,mya0, myb0), cbind(1,mya1, myb1))
    
    write.table(results,(file.path(YOUR.STORAGE.PATH, "alt1_results.csv")), sep=",", row.names=FALSE, col.names=c("TYPE", "All", "Inside"))  
    
    #TYPE=1 means  the months we care about (June-August) TYPE=0 means ELSE
    #ALL is all qtykept
    #Inside means inside the area I care about.
    
    
    
    
    
    










