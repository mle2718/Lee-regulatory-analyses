####
# June 5, 2017
####


# YOU need to figure out how to 
#1.  Aggregate the summer months together
#2.  Aggregate the non-summer months together
#3.  Come up with a good scaling.  We'll probably have to do 2 scalings -- one for  summer and not-summmer. and one for both combined.
#4 confidential_readin_preprocess_with_regimes.R and confid_match_and_subset_regimes.R will need to get re-coded to account for these aggregations. 
    #the basic code assumed we were feeding a "metier" plus a YEAR. We're still feeding it a metier, but we are now aggregating across years (and some months) using regime and a month_block columns
      #  I can merge parsed_groups to FINAL using parsed_groups$metier <-> FINAL$MY_GEAR and parsed_groups$MONTH_block<->FINAL$MONTH_block
      #  I don't think I need to merge, I just need to subset
      
#5. you're going to hold off on doing anything else if it's not needed.

######################
## Outline of the Script Process: 
# 1) Set up info, packages, etc. 
# 2) List all the rasters that are going to be processed
# 3) Put them into "parsed_groups" dataframe, to break the name up and allow us to categorize by group (FMP, species, gear), unit (revenue vs. quantity), and year.




# 7) Then Min-Yang's confidentiality checker converts each raster to a polygon, and checks that at least 3 trips are in a discrete area.
#       This process re-names the value bins for 1-6, and when finished re-assigns the correct bin-values for the plotted map
#       The code plots both the original ("raw") and the reclassified map as a plotted PDF, also saving the CSV of value-cuts for the binning. 
# 8) The process of value-range check, confidentiality check, and plotting of PDFs begins again with the REVENUE rasters. 
# 9) Next, separate codeconverts the plotted PDFs to PNGs for the purpose of easier plotting on the website.
# 10) Finally, separate code also strings together PNGs by Group and Unit to create GIFs. 
######################

#### (1) - Set your info
todaysdate = as.Date(Sys.time())
max.nodes = 4 #processor nodes

####################
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


######################
### Set up your file paths and directories, etc

# Set working directory:

# For testing purposes only
#YOUR.DATA.PATH= file.path("/net/work5/socialsci/Geret_Rasters/TEST_MAPS")
# For the real deal! 
YOUR.DATA.PATH= file.path("/net/home2/mlee/RasterRequests/A8_background_2017-03-16/") 
YOUR.CODE.PATH= file.path("/net/home2/mlee/RasterRequests/herring_scripts/") 

# Where output files are saved
YOUR.STORAGE.PATH = file.path(paste0("/net/home2/mlee/RasterRequests/A8_Regimes",todaysdate))
dir.create(YOUR.STORAGE.PATH, recursive=T)
dir.create(file.path(YOUR.STORAGE.PATH,"csv_keys"), recursive=T)


# For testing: 
ML.GIS.PATH <- file.path("/net/home2/mlee/spatial data")
#SB.GIS.PATH <- file.path("/net/home4/sbenjamin/spatial_data_scratch")

# Additional Directory Setup
SSB.NETWORK=file.path("/net/work5/socialsci") # This is what you need to run networked

SSB.DRIVE = file.path(SSB.NETWORK)
GD.RASTERS = file.path(SSB.DRIVE, "Geret_Rasters")
GD.GIS.PATH = file.path(GD.RASTERS, "Data")
ML.NETWORK.SERVER=file.path("/net/home2/mlee") #This Is what you need to run from the network.

##########################
### (2) Setup spatial data stuff for mapping later:

# DEFINE OUR PROJECTION - Albers Equal Area conic (in meters)
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

#######################################################################

### Set Up for Confidentiality Check  

 START.YEAR <- 1996  # This means the code will run for any year between START.YEAR and END.YEAR
 END.YEAR <- 2015

# Setup to loop through unique file paths: 
# List all the rasters in "FINAL MAPS" (below) .... and parse their filenames out into FILEPATH, NAME, and UNIT (further down)
tif_pat<-glob2rx("*month*.tif")



# When re-running the code with newly available rasters, start here:  #####  This is where you build and refine the list of rasters you want to use in maps!
rasterlist<- lapply(as.list(list.dirs(path=YOUR.DATA.PATH, recursive=T)), list.files, recursive=F, full.names=T, pattern=tif_pat)

##############################

# Parse out the names of each raster's file path into chunks
    parsed_groups = do.call(rbind, lapply(rasterlist, function(xx) { # Takes the list creates dataframe where first column is filepath
      xx = as.data.frame(xx, stringsAsFactors=F)
      names(xx) = "FILEPATH" 
      return(xx) }) ) 
    parsed_groups$first_part =  sapply(parsed_groups$FILEPATH, USE.NAMES=F, function(zz) { # Next is most of the filepath
      strsplit(x = as.character(zz), split = ".tif")[[1]] })
    parsed_groups$NAME =  sapply(parsed_groups$FILEPATH, USE.NAMES=F, function(zz) {
      temp <- do.call(rbind,strsplit(as.character(zz), split = "/")) 
      return(temp[NCOL(temp)]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
  
    parsed_groups$REGIME =  sapply(parsed_groups$first_part, USE.NAMES=F, function(zz) { # We are referring to "REVENUE" versus "QTYKEPT here
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(temp[NCOL(temp)]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    
    
    parsed_groups$metier =  sapply(parsed_groups$NAME, USE.NAMES=F, function(zz) { # We are referring to "REVENUE" versus "QTYKEPT here
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(temp[3]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    
    parsed_groups$MONTH =  sapply(parsed_groups$NAME, USE.NAMES=F, function(zz) { # We are referring to "REVENUE" versus "QTYKEPT here
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(temp[NCOL(temp)-2]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    parsed_groups$MONTH<-as.numeric(parsed_groups$MONTH)
    
    parsed_groups$summer_months <- 0
    parsed_groups$summer_months[parsed_groups$MONTH>=6 &parsed_groups$MONTH<=9 ] <- 1
    
#
    for (working_gear in c("allgears","BOT","MWT",'PUR')){
      for (working_regime in c(1,2)){
          print(paste("The metier is", working_gear, "and the regime is ",working_regime ))
        
          temp_Q_list<-parsed_groups[parsed_groups$metier ==working_gear,] 
          temp_Q_list<-temp_Q_list[temp_Q_list$REGIME ==working_regime,] 
          
          #source(file.path(YOUR.CODE.PATH, "confid_match_and_subset_regimes.R")) 
          
          #get the extent
          f<-extent(raster(file.path(temp_Q_list$FILEPATH[1])))
          new_xmin<-xmin(f)
          new_ymin<-ymin(f)
          new_xmax<-xmax(f)
          new_ymax<-ymax(f)
          
          #loop over the rasters that you want and update with the new min and maxes
          
          for (pp in 2:nrow(temp_Q_list)){
            f2<-extent(raster(file.path(temp_Q_list$FILEPATH[pp])))
            new_xmin<-min(new_xmin,xmin(f2))
            new_ymin<-min(new_ymin,ymin(f2))
            new_xmax<-max(new_xmax,xmax(f2))
            new_ymax<-max(new_ymax, ymax(f2))
          }
          
          ## THIS SETS THE NEW EXTENT that constant for each year.
          f3<-extent(new_xmin,new_xmax, new_ymin, new_ymax)
          
          
          #Read in the rasters and add them together.
          myras<-extend(raster(file.path(temp_Q_list$FILEPATH[1])), f3, value=0)
          
          for (pp in 2:nrow(temp_Q_list)){
            working_raster2<-extend(raster(file.path(temp_Q_list$FILEPATH[pp])), f3, value=0)
            myras<-myras+working_raster2
          }
          if (working_regime==1){
            myras<-myras/(7+5/12)
            #myras<-myras/(7)
            
                  } 
          else{
            myras<-myras/(8+7/12)
            #myras<-myras/(8)
            
        }  
          
          gtiff_name<-paste0(working_gear,"_full_year_regime_", working_regime, ".csv")
          
          writeRaster(myras, file.path(YOUR.STORAGE.PATH,gtiff_name), format="GTiff", overwrite=T)
          
          #save the raster here.
          
        
      }
    }
        
        
        
        
