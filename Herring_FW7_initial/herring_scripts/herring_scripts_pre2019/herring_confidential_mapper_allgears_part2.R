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
YOUR.DATA.PATH= file.path("/net/home2/mlee/RasterRequests/A8_background_2017-06-12/") 
YOUR.CODE.PATH= file.path("/net/home2/mlee/RasterRequests/herring_scripts/") 

# Where output files are saved
YOUR.STORAGE.PATH = file.path("/net/home2/mlee/RasterRequests/A8_background_2017-06-12")
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

# Read in the Confidentiality-check portion of code
source(file.path(YOUR.CODE.PATH,"confidential_readin_preprocess_with_regimes.R"))

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
tif_pat<-glob2rx("allgears*.tif")

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
  
    parsed_groups$REGIME =  sapply(parsed_groups$first_part, USE.NAMES=F, function(zz) { # We are referring to "REVENUE" versus "QTYKEPT here
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(temp[NCOL(temp)]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    parsed_groups$metier =  sapply(parsed_groups$NAME, USE.NAMES=F, function(zz) { # We are referring to "REVENUE" versus "QTYKEPT here
      temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
      return(temp[NCOL(1)]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
    
    #Done to here  read in both rasters. stack data into the same list and do classint. change the names of the output pdfs.
    
      
    for (working_gear in c("allgears")){
          print(paste("The metier is", working_gear, "and the regime is ",working_regime ))
        
          temp_Q_list<-parsed_groups[parsed_groups$metier ==working_gear,] 
          #temp_Q_list<-temp_Q_list[temp_Q_list$summer_months ==working_time,] 

          
          FINAL_w<-NULL
          
          if(working_gear=="allgears"){
            FINAL_w=FINAL
          } else {
            
            FINAL_w=FINAL[which(FINAL$MY_GEAR %in% working_gear),]
          }
          
          #get the extent
          f<-extent(raster(file.path(temp_Q_list$FILEPATH[1])))
          new_xmin<-xmin(f)
          new_ymin<-ymin(f)
          new_xmax<-xmax(f)
          new_ymax<-ymax(f)
          
          #loop over the rasters that you want and update with the new min and maxes
          
          
          mylist <- list ()  # IMPORTANT to create new list, or random selection will not work correctly  
          
          for (pp in 2:nrow(temp_Q_list)){
            f2<-extent(raster(file.path(temp_Q_list$FILEPATH[pp])))
            new_xmin<-min(new_xmin,xmin(f2))
            new_ymin<-min(new_ymin,ymin(f2))
            new_xmax<-max(new_xmax,xmax(f2))
            new_ymax<-max(new_ymax, ymax(f2))
        
          #read in all the values of the raster into a list  
          subsamp<-values(myras)  # Create "subsamp" object of a raster's cell values
          subsamp<-subsamp[subsamp>jenks.lowerbound]        # Subset that object to those greater than 1
          mylist[[length(mylist)+1]] = subsamp              # Make it into a list (?) 
            
            
              }
          
          ## THIS SETS THE NEW EXTENT that constant for each year.
          f3<-extent(new_xmin,new_xmax, new_ymin, new_ymax)
          extreme.ylimit = c(new_ymin,new_ymax)
          extreme.xlimit = c(new_xmin,new_xmax)
          
          #Read in the rasters and add them together.
          

          #unlist the values of the list and subsample to make 1 classification.
          myvals<-unlist(mylist)  
          glob_max<-max(myvals) 
          
          set.seed(24601)                                             # Set seed immediately before sampling.
          mysubs<-sample(myvals,num_jenks_subs) #num_jenks_subs=5747
          myclass <- classIntervals(mysubs, n=nbreaks,style="jenks")  # Create object of class intervals
          
          mybreaks_class1<-c(0,myclass$brks) # Here we add a "zero" bin, manually.  # Create Breaks object of value classes
          
          ub=mybreaks_class1[length(mybreaks_class1)]
          myras[myras>=ub]<-floor(ub)

          
          blength <-length(mybreaks_class1)-1
          myclass_matrix <- cbind(mybreaks_class1[1:blength],c(mybreaks_class1[2:blength],Inf), 1:blength)                      
          
          
          for (working_regime in c(1,2)){
            tql<-temp_Q_list[temp_Q_list$REGIME==working_regime,]
            myras<-extend(raster(file.path(tql$FILEPATH[1])), f3, value=0)
            myras[myras>=ub]<-floor(ub)
            
          
          myr2<-reclassify(myras,myclass_matrix, include.lowest=TRUE, right=TRUE)
                    myclass_matrix <- cbind(mybreaks_class1[1:blength],c(mybreaks_class1[2:blength],ub), 1:blength)                      
          colnames(myclass_matrix)<-c("LB","UB","CATEGORY")
          cutnames<-paste0(working_gear, "_regime_", working_regime, "onescale.csv")
          # FIRST OUTPUT - WRITE THE CSV OF THE CUT POINT VALUES
          write.csv(myclass_matrix, file=file.path(YOUR.STORAGE.PATH,"csv_keys",cutnames),  row.names=FALSE)

          
          source(file.path(YOUR.CODE.PATH,"herring_confidential_checker.R"))
          
          
          
          
          pdf_filename<-gsub(".csv", ".pdf", cutnames)
          

# Name for RECLASSIFIED rasters - checked for confidentiality
    reclass_filename=paste0("reclass_",pdf_filename)
#

    our.max.pixels = 550000#8e6 # This is slightly larger than the number of cells in the baseraster (the max number of cells possible)

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
    PDF.file <- file.path(YOUR.STORAGE.PATH, pdf_filename)
# SECOND OUPUT - PLOT THE PDF OF THE 'RAW' RASTER   
    pdf(file=PDF.file, width=7, height=9, 
        useDingbats = TRUE, bg="white", 
        compress=T )
    
         print(jcons 
             + layer(sp.polygons(my_basemap2,fill=mylandfill))
             + layer(sp.polygons(my_basemap3,lwd=2,col='gray'))
         )
           dev.off()
          
          # End time stamp for this loop here
        end.time <- Sys.time()
        #Print time elapsed for this process

#####     
  reclass_gtiff_name<-gsub(".png", ".tif", reclass_filename)
  gtiff_name<-gsub(".csv", ".tif", cutnames)
  
# Store the reclassified raster.
  writeRaster(myr2, file.path(YOUR.STORAGE.PATH,reclass_gtiff_name), format="GTiff", overwrite=T)
  writeRaster(myras, file.path(YOUR.STORAGE.PATH,gtiff_name), format="GTiff", overwrite=T)
  
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
        PDF.file <- file.path(YOUR.STORAGE.PATH, reclass_filename)
        pdf(file=PDF.file, width=7, height=9, useDingbats = TRUE, bg="white", compress=T )
        
        print(rclassed 
              + layer(sp.polygons(my_basemap2,fill=mylandfill))
              + layer(sp.polygons(my_basemap3,lwd=2,col='gray'))
        )
        
        dev.off()
        
###
        
    }  # END loop plotting QTYKEPT rasters
      
    
}
