####
# May 2, 2017
####

# This copy of the "MULTIGRPX_PDFs.R" set of scripts is an ANNOTATED base copy. 
# The set of scripts were run in "faux-multicore" during April and May 2017, 
# to produce maps and rasters in a standardized-style for the SSB website. 

# The line-numbers WILL NOT MATCH the other scripts; this one has been cleaned 
# up and has extra notation, and excess/commented out material is removed for ease of reading. 
# Hopefully this is actually helpful to the reader. 

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
#       The code plots both the original ("raw") and the reclassified map as a plotted PDF, also saving the CSV of value-cuts for the binning. 
# 8) The process of value-range check, confidentiality check, and plotting of PDFs begins again with the REVENUE rasters. 
# 9) Next, separate codeconverts the plotted PDFs to PNGs for the purpose of easier plotting on the website.
# 10) Finally, separate code also strings together PNGs by Group and Unit to create GIFs. 
######################

#### (1) - Set your info
todaysdate = as.Date(Sys.time())
yourname = "Sharon"
youremail = "Sharon.Benjamin@noaa.gov"
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
YOUR.DATA.PATH= file.path("/net/work5/socialsci/Geret_Rasters/FINAL MAPS") 
YOUR.CODE.PATH= file.path("/net/home2/mlee/RasterRequests/herring_scripts/") 

# Where output files are saved
#YOUR.STORAGE.PATH = file.path(paste0("/net/home4/sbenjamin/spatial_data_scratch/", todaysdate, "output"))
YOUR.STORAGE.PATH = file.path(paste0("/net/home2/mlee/","RasterRequests/A8_background_2017-06-13"))
dir.create(YOUR.STORAGE.PATH, recursive=T)# outputfolder = file.path(workplace, "outputs"



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

 START.YEAR <- 2000  # This means the code will run for any year between START.YEAR and END.YEAR
 END.YEAR <- 2007

# Read in the Confidentiality-check portion of code

source(file.path(YOUR.CODE.PATH,"confidential_readin_preprocess.R"))

##################################

### Setting up BINNING options: 

# Number of breaks  -  for classifiying raster values into bins
nbreaks=5

# Subsample for Jenks Natural breaks classifications?  Set sampling-seed later
num_jenks_subs=3000 # Maybe this should be higher; set to 1000 for the map production process. But, the higher the sample the longer it takes to run.

# Here we exclude all cells <=1. (Later we deal with rasters with so few cells above the lower bound value,
    # that we change the sample size to match the number of cells with those values.)
jenks.lowerbound=1

# Min and Max x and y values set to standardize plot extent # the plot extent is set, but then adjusted based on the location of points in the plotted region
my.ylimit=c(-300000,900000)
my.xlimit=c(1700000,2600000)

# Lat/lon borders
myscaleopts <- list(draw=FALSE) # Don't draw axes!
#myscaleopts <- list(draw=TRUE, cex=1.2) # Draw axes

# Number of color value "bins", plus 0-value will be added too.
numclasses <- 5

# Set Color Ramp Values 
brewer.friendly.bupu <- c("#ffffff", brewer.pal(numclasses, "BuPu")) # Blue to purple  (low to high) 
my.friendly.BUPU <- rasterTheme(region=brewer.friendly.bupu)
 
# Set options (par.setting) for Colors
mycoloropts <-  c(my.friendly.BUPU) 

# Other Plotting Settings 
myckey <- list(labels=list(cex=2)) # Set the size of color ramp labels (?)

# PNG Image Size in pixel units (?) 
png.height<-1800
png.width<-1400

# Land color 
mylandfill <- "#d1d1e0" # It's gray.


############################

#### (3) Set up to work from the FINAL MAPS folder:

# Setup to loop through unique file paths: 
# List all the rasters in "FINAL MAPS" (below) .... and parse their filenames out into FILEPATH, NAME, and UNIT (further down)
tif_pat<-glob2rx("*.tif")

#
#
######!!! FOR USE WHEN WE ADD NEW RASTERS (for example, next year's latest data)  ############

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
  
    parsed_groups$UNIT =  sapply(parsed_groups$FILEPATH, USE.NAMES=F, function(zz) { # We are referring to "REVENUE" versus "QTYKEPT here
      temp <- do.call(rbind,strsplit(as.character(zz), split = "/")) 
      return(temp[NCOL(temp)-1]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    
    parsed_groups$YEAR = str_sub(parsed_groups$first_part,-4) # Just extracting the YEAR from the filename
 
    parsed_groups$GROUP =  sapply(parsed_groups$FILEPATH, USE.NAMES=F, function(zz) { # Refers to the raster-group, such as the FMP or species or geartype
      temp <- do.call(rbind,strsplit(as.character(zz), split = "/")) 
      return(paste0(temp[NCOL(temp)-2])) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    
    parsed_groups$GROUPUNIT =  sapply(parsed_groups$FILEPATH, USE.NAMES=F, function(zz) { # GROUP-UNIT combo, as in "BLUEFISHFMP-REVENUE" vs. "BLUEFISHFMP-QTYKEPT"
      temp <- do.call(rbind,strsplit(as.character(zz), split = "/")) 
      return(paste0(temp[NCOL(temp)-2], "/", temp[NCOL(temp)-1])) })# Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    
    parsed_groups$GROUPPATH =  sapply(parsed_groups$FILEPATH, USE.NAMES=F, function(zz) {
      temp <- do.call(rbind,strsplit(as.character(zz), split = "/")) 
      return(file.path(paste0(temp[1],"/",temp[2],"/",temp[3],"/",temp[4],"/",temp[5],"/",temp[6],"/",temp[7]))) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
       
    parsed_groups$GROUPUNITPATH =  sapply(parsed_groups$FILEPATH, USE.NAMES=F, function(zz) {
      temp <- do.call(rbind,strsplit(as.character(zz), split = "/")) 
      return(file.path(paste0(temp[1],"/",temp[2],"/",temp[3],"/",temp[4],"/",temp[5],"/",temp[6],"/",temp[7],"/",temp[8]))) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    
# Drop rows of rasters to ignore - groups of species/year, etc to NOT plot
    parsed_groups <-parsed_groups[!(parsed_groups$UNIT %in% c("Calendar Year Species", "Fishing_Year_Species")),]  # We are removing things that mess up the system or don't meet privacy standards we need
    parsed_groups <-parsed_groups[!((parsed_groups$YEAR %in% 1996:2002) & (parsed_groups$GROUP == "CLAM FMP")),]  

    parsed_groups <-parsed_groups[((parsed_groups$YEAR >=START.YEAR) & (parsed_groups$YEAR <=END.YEAR)),]  
    MULTI.GRP11c <- c("SPP_352","SPP_81","SPP_269")
    
    
    ######
######
## --- WHICH MULTICORE **GROUP** ARE YOU RUNNING? CHANGE to 1-7 HERE --- ##
    parsed_groups <- parsed_groups[(parsed_groups$GROUP %in% MULTI.GRP11c),]
    
##########################################

#
### (4) Loop through the unique filepaths! - List of unique GROUPINPATH names
list_groupinpath <- sort(unique(parsed_groups$GROUPPATH)) # List of unique GROUPPATHs; will break out into UNIT subgroups inside the loop

# Set file name to store the maps; check if dir exists, and if not, create folder for storing the plotted map PNGs

start.time.total <- Sys.time()
# Begin loop through each raster GROUPUNITPATH (as in, each subset of rasters) 

for (i in (1:length(list_groupinpath))){

# Create a list of rasters that are in that GROUPUNITPATH 
  temp_rgrouplist <- parsed_groups[parsed_groups$GROUPPATH == list_groupinpath[i],] # All rasters in a GroupPath (As in, in "MONKFISH FMP" - not broken by unit yet)
  
  temp_rgrouplist$FMP_txt <- ifelse(grepl("FMP", temp_rgrouplist$GROUP), "Fishery Management Plan", "")
  temp_rgrouplist$GRP_txt <- ifelse(grepl("FMP", temp_rgrouplist$GROUP), gsub(" FMP", "", as.character(temp_rgrouplist$GROUP)), temp_rgrouplist$GROUP)
  
  temp_R_list <- temp_rgrouplist[temp_rgrouplist$UNIT == "REVENUE",]  # Subset list of REVENUE rasters for the fish species/FMP/geartype
  temp_R_list$textUnit <- "Revenue"


  temp_Q_list <- temp_rgrouplist[temp_rgrouplist$UNIT == "QTYKEPT",] # Subset list of QUANTITY rasters for the fish species/FMP/geartype
  temp_Q_list$textUnit <- "Pounds Landed"
# 
# Determine max. extent for all rasters in the metier (both REVENUE and QUANTITY) 
#
  xxyy=data.frame() # Start with creating a new list for dimension info
  
  for (b in (1:nrow(temp_rgrouplist))) {
  # For plotting rasters in a projected coordinate system
      extremes <- rasterToPoints(raster(temp_rgrouplist$FILEPATH[b]), fun=function(x){x>1}) 
    
  #  (For un-projecting rasters into a Lat/Lon coordinate system...)
  #   extremes <- rasterToPoints(projectRaster(raster(temp_rgrouplist$FILEPATH[b]), crs=PROJ.LATLON), fun=function(x){x>1}) 
  
      
  extremes.df <- as.data.frame(extremes)
        
        max.x <- max(extremes.df$x)
        min.x <- min(extremes.df$x)
        max.y <- max(extremes.df$y)
        min.y <- min(extremes.df$y)
        xxyy= rbind(xxyy, c(max.x,min.x,max.y,min.y))
  }
       # end loop setting up max extent info 
  
# Add column names for ease of comprehension
  colnames(xxyy)=c("MaxX", "MinX", "MaxY", "MinY")
    
# These are min and max x and y values set for standardizing plot extents
  extreme.ylimit = c(min(xxyy[,"MinY"]), max(xxyy[,"MaxY"]))
  extreme.xlimit = c(min(xxyy[,"MinX"]), max(xxyy[,"MaxX"]))

################### 
  
### FIND BINNING & PLOT THE *QTYKEPT* RASTERS in the GROUP 
#
if(nrow(temp_Q_list) > 0){ # error catch when there was accidentally no Q or R folders for a metier....
#
mylist <- list ()  # IMPORTANT to create new list, or random selection will not work correctly
Q.start.time <- Sys.time()   # Starting Time 

#### Additional code added for a confidentiality check
working_group<-temp_Q_list

  matcher<-working_group$NAME[1]
  matcher<-substr(matcher,1, nchar(matcher)-8)
  matcher<-gsub("REVENUE","",matcher)
  matcher<-gsub("QTYKEPT","",matcher)
  FINAL_w=FINAL[which(FINAL$NESPP3 %in% matcher),]
  counter<-NROW(FINAL_w)
  

####

# Do jenks binning on this GROUP-UNIT subset, and plot those rasters


          new_xmin<-NULL
          new_xmax<-NULL
          new_ymin<-NULL
          new_ymax<-NULL

          
          #loop over the rasters that you want and update with the new min and maxes
          
          for (pp in 1:nrow(temp_Q_list)){
            f2<-extent(raster(file.path(temp_Q_list$FILEPATH[pp])))
            new_xmin<-min(new_xmin,xmin(f2))
            new_ymin<-min(new_ymin,ymin(f2))
            new_xmax<-max(new_xmax,xmax(f2))
            new_ymax<-max(new_ymax, ymax(f2))
          }
          
          ## THIS SETS THE NEW EXTENT that constant for each year.
          f3<-extent(new_xmin,new_xmax, new_ymin, new_ymax)
          extreme.ylimit=c(new_ymin, new_ymax)
          extreme.xlimit=c(new_xmin, new_xmax)
  
          myras<-extend(raster(file.path(temp_Q_list$FILEPATH[1])), f3, value=0)
	#SUM THEM TOGETHER
          for (pp in 2:nrow(temp_Q_list)){
            myras<-myras+extend(raster(file.path(temp_Q_list$FILEPATH[pp])), f3, value=0)
          }
	#normalize to catch per year
	myras<-myras/nrow(temp_Q_list)
	



      myvals<-values(myras)  # Create "subsamp" object of a raster's cell values
      myvals<-myvals[myvals>jenks.lowerbound]        # Subset that object to those greater than 1

  glob_max<-max(myvals) 
  
# Take mostly-'random' sample of myvals (values of all cells of all rasters in this metier)
  set.seed(24601)                                             # Set seed immediately before sampling.
  mysubs<-sample(myvals,num_jenks_subs) #num_jenks_subs=5747
  myclass <- classIntervals(mysubs, n=nbreaks,style="jenks")  # Create object of class intervals
  
  mybreaks_class1<-c(0,myclass$brks) # Here we add a "zero" bin, manually.  # Create Breaks object of value classes


      mygroup <- as.character(temp_Q_list$GROUPUNITPATH[1])
      ub=mybreaks_class1[length(mybreaks_class1)]
      myras[myras>=ub]<-floor(ub)

# Min-Yang's code changes for reclassification to 1-6 from value bins
  blength <-length(mybreaks_class1)-1
  myclass_matrix <- cbind(mybreaks_class1[1:blength],c(mybreaks_class1[2:blength],ub), 1:blength)                      
      
  myr2<-reclassify(myras,myclass_matrix, include.lowest=TRUE, right=TRUE)
  
  colnames(myclass_matrix)<-c("LB","UB","CATEGORY")
  cutnames<-temp_rgrouplist$GRP_txt[1]
  cutnames<-gsub(" ", "_", cutnames)
  cutnames<-gsub("/", "_", cutnames)
  cutnames<-paste0(cutnames,".csv")
# FIRST OUTPUT - WRITE THE CSV OF THE CUT POINT VALUES
  write.csv(myclass_matrix, file=file.path(YOUR.STORAGE.PATH,cutnames),  row.names=FALSE)


#HERE YOU NEED TO SUBSET FINALw into the appropriate set FINALw<-
	   FINAL_wy=FINAL_w[which((FINAL$YEAR>=START.YEAR) & (FINAL$YEAR<=END.YEAR)) ,]

#RUN TO HERE. CHECK filenames and others. verify loop works.


  source(file.path(YOUR.CODE.PATH,"lumped_confidential_checker.R"))
  
####  

# Now set up to plot this GROUP of rasters, with the above-determined binning scheme
  
# Name for 'RAW' rasters - the original file
    pdf_filename=paste0(temp_rgrouplist$GRP_txt[1],".pdf")
  
# Name for RECLASSIFIED rasters - checked for confidentiality
    reclass_filename=paste0("reclass_",pdf_filename)
#
#
#
# Create the plot title, in two lines: 
    tempyear <-paste0(START.YEAR," to ",END.YEAR) 
    unit <- as.character(temp_Q_list$textUnit[1])
    
# Create a graphical object of text
    gr.text <- textGrob(label=unit, x=unit(0.80, "npc"), y=unit(0.04, "npc"), gp=gpar(cex=1.0))
    
    our.max.pixels = 550000#8e6 # This is slightly larger than the number of cells in the baseraster (the max number of cells possible)
    
  reclass_gtiff_name<-gsub(".pdf", ".tif", reclass_filename)
  
# Store the reclassified raster.
  writeRaster(myr2, file.path(YOUR.STORAGE.PATH,reclass_gtiff_name), format="GTiff", overwrite=T)
        
#####        
# Make another (reclassed) plot and save as PNG
        mylegend<-floor(mybreaks_class1)
        myckey2<-list(at=seq(0, length(mylegend)-1, 1), labels=list(at=seq(0,length(mylegend)-1,1),labels=mylegend, cex=2))
        
        rclassed<-levelplot(myr2,  
                            raster=TRUE,
                            #aspect="xy",
                            maxpixels=our.max.pixels,
                            margin=FALSE, 
                            col.regions=brewer.friendly.bupu,scales=myscaleopts, 
                            at=seq(0, length(mylegend)-1, 1), 
                            xlim=extreme.xlimit,ylim=extreme.ylimit, 
                            colorkey=myckey2 
        ) 
# THIRD OUPUT - PLOT THE PDF OF THE RECLASSIFIED RASTER           
        PDF.file <- paste0(YOUR.STORAGE.PATH, "/", reclass_filename)
        pdf(file=PDF.file, width=7, height=9, useDingbats = TRUE, bg="white", compress=T )
        
        print(rclassed 
              + layer(sp.polygons(my_basemap2,fill=mylandfill))
              + layer(sp.polygons(my_basemap3,lwd=2,col='gray'))
              #+ layer(grid.text(tempyear,draw=TRUE,x=unit(0.80, "npc"),y=unit(0.1, "npc"), gp=gpar(cex=2.5)))
              + layer(grid.text(tempyear,draw=TRUE,x=unit(0.80, "npc"),y=unit(0.1, "npc"), gp=gpar(cex=1.5)))
              + layer(grid.draw(gr.text))
        )
        
        dev.off()
        
###
        
    }  # END loop plotting QTYKEPT rasters
  Q.end.time <- Sys.time()  

  } # Close of error catch of Q list < 5 rows


#YOU NEED TO CHECK Parentheses
  
  
