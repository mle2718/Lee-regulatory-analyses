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
YOUR.DATA.PATH=file.path(YOUR.PROJECT.PATH,"2016-03-10_rasterexport") 

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
exportfolder = file.path(YOUR.DATA.PATH,"pretty_pics")
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





#################################################
# STEP 3 -- Set your mapping options
#################################################
#### WHAT ARE YOU TRYING TO MAP?
# I WANT TO Separately MAP ALL THE GEOTIFS THAT MATCH "PURSE...tif" and "Midwater.....tif" 
mypat1<-glob2rx("81*9999.tif")
mypat2<-glob2rx("269*9999.tif")
mypat3<-glob2rx("352*9999.tif")
mypat4<-glob2rx("121*9999.tif")

#3a. rasterViz options
#THIS CODE MAKES 3 "rasterTheme" to pass to rasterViz.
#  ?rasterViz and ?RColorBrewer may be helpful
#  Blue, Green, and Dichromatic.
#  There is a maximum of 9 classes, one of which is transparent and useful for forcing the zeros to have no color.  

numclasses<-8

#THESE TWO ARE UN-MODIFIED COLOR BREWER in BLUE and GREEN
brewer.blues=brewer.pal(numclasses, "Blues")
brewer.greens=brewer.pal(numclasses, "Greens")

#THESE TWO MANUALL ADD A TRANSPARENT FIRST BIN
brewer.blues=c("#ffffff",brewer.pal(numclasses, "Blues"))
brewer.greens=c("#ffffff",brewer.pal(numclasses, "Greens"))

myBLUETHEME=rasterTheme(region=brewer.blues)
myGREENTHEME=rasterTheme(region=brewer.blues)

#THIS SETS UP A RASTER THEME THAT IS FOR COLOR BLIND PEOPLE
temp_dichrome<-c(dichromat(terrain.colors(numclasses)),"#ffffff")
mydichrome <- rasterTheme(region=rev(temp_dichrome))

#3B. classInt options
#if you want, you can set the number of breaks less than (numclasses+1).  Which I have done.
nbreaks=6
# How large do you want the subsample for Jenks Natural breaks classifications? 
# 10,000 runs reasonably quickly. don't pick too many
# If you ask for a subsample, it's a good idea to set a seed.
num_jenks_subs=10000
set.seed(8675309)
# You might want to exclude zeros or anythign that is below a threshold. I'm going to exclude all cells <=1.
jenks.lowerbound=0
jenks.lowerbound=1


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
myscaleopts <- list(draw=TRUE)

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

#GET ANOTHER LIST OF FILES. PUT IT INTO A DATASET
list2<- lapply(as.list(list.dirs(path=YOUR.DATA.PATH, recursive=T)), list.files, recursive=F, full.names=T, pattern=mypat2)
parsed_list2 = do.call(rbind, lapply(list2, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILEPATH" 
  return(xx) }) )                                         
parsed_list2$first_part =  sapply(parsed_list2$FILEPATH, USE.NAMES=F, function(zz) {
  strsplit(x = as.character(zz), split = ".tif")[[1]]
})
parsed_list2$NAME = sapply(parsed_list2$first_part, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })
parsed_list2$YEAR = str_sub(parsed_list2$NAME,-4)


#GET ANOTHER LIST OF FILES. PUT IT INTO A DATASET
list3<- lapply(as.list(list.dirs(path=YOUR.DATA.PATH, recursive=T)), list.files, recursive=F, full.names=T, pattern=mypat3)
parsed_list3 = do.call(rbind, lapply(list3, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILEPATH" 
  return(xx) }) )                                         
parsed_list3$first_part =  sapply(parsed_list3$FILEPATH, USE.NAMES=F, function(zz) {
  strsplit(x = as.character(zz), split = ".tif")[[1]]
})
parsed_list3$NAME = sapply(parsed_list3$first_part, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })
parsed_list3$YEAR = str_sub(parsed_list3$NAME,-4)

#GET ANOTHER LIST OF FILES. PUT IT INTO A DATASET
list4<- lapply(as.list(list.dirs(path=YOUR.DATA.PATH, recursive=T)), list.files, recursive=F, full.names=T, pattern=mypat4)
parsed_list4 = do.call(rbind, lapply(list4, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILEPATH" 
  return(xx) }) )                                         
parsed_list4$first_part =  sapply(parsed_list4$FILEPATH, USE.NAMES=F, function(zz) {
  strsplit(x = as.character(zz), split = ".tif")[[1]]
})
parsed_list4$NAME = sapply(parsed_list4$first_part, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })
parsed_list4$YEAR = str_sub(parsed_list4$NAME,-4)














#################################################
#################################################




###############################################################################
#LOOP OVER ALL ROWS IN parsed_list1 and build a single jenks category
  #THIS reads in all the Raster data and drops all the zeros.
  #THen stacks them all together into a big list, subsamples, and runs a Jenks NB classifcation.
  #Then it remaps the final cutpoint to the global maximum
###############################################################################



#IF YOU DON'T WANT JENKS BREAKS, COMMENT THIS OUT.
mylist = list()
for (i in 1:nrow(parsed_list1)) {
  
  # myras<-raster(parsed_list1$FILEPATH[i])
  
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
#   #End JENKS BREAKS code




#LOOPY MAPPING

# DO THE MAPPING
for (i in 1:nrow(parsed_list1)) {

  myras<-raster(parsed_list1$FILEPATH[i])
  
  #JB is has a hard upper bound. This means that any value above this upper bound will have no colors.
  #To fix this, we will set all raster values greater than the upper bound to be slightly less than this upper bound
  
  ub=mybreaks_class1[length(mybreaks_class1)]
  myras[myras>=ub]<-floor(ub)
  



  
  pfilename=paste(parsed_list1$NAME[i],"crude", sep="_")
  pfilename=paste(pfilename,"png",sep=".")



  
  jconsfilename=paste(parsed_list1$NAME[i],"crude", "jcons",sep="_")
  jconsfilename=paste(jconsfilename,"png",sep=".")
  title_opts1<-list(parsed_list1$NAME[i],cex=2)
  
  
  p<-levelplot(myras, margin=FALSE, main=title_opts1, par.setting=mycoloropts,scales=myscaleopts)

  jcons<-levelplot(myras, margin=FALSE, main=title_opts1, 
                   par.setting=mycoloropts,scales=myscaleopts, at=mybreaks_class1, 
                   xlim=my.xlimit, ylim=my.ylimit, colorkey=myckey)
  
  
  
  png(filename=file.path(YOUR.STORAGE.PATH,pfilename), 
      height=png.height,
      width=png.width,
      units="px"
  )
  
  print(p+ layer(sp.lines(my_basemap)) + layer(sp.polygons(my_basemap2, fill=mylandfill)))
  dev.off()
  
  
  png(filename=file.path(YOUR.STORAGE.PATH,jconsfilename), 
      height=png.width,
      width=png.width,
      units="px"
  )
  
  print(jcons+ layer(sp.lines(my_basemap)) + layer(sp.polygons(my_basemap2, fill=mylandfill)))
  dev.off()
  
  
}


###############################################################################
###############################################################################
#LOOP OVER ALL ROWS IN parsed_list2 and do some stuff
###############################################################################
###############################################################################



#IF YOU DON' WANT JENKS BREAKS, COMMENT THIS OUT.
mylist2 = list()
for (i in 1:nrow(parsed_list2)) {
  

  #This bit of code does Jenks breaks
  subsamp<-values(raster(parsed_list2$FILEPATH[i]))
  subsamp<-subsamp[subsamp>jenks.lowerbound]
  mylist2[[length(mylist2)+1]] = subsamp
}


myvals<-unlist(mylist2)
mysubs<-sample(myvals,num_jenks_subs)



myclass <- classIntervals(mysubs, n=nbreaks,style="jenks")
myclass$brks[nbreaks]<-glob_max
mybreaks_class2<-c(0,myclass$brks)
#   #End JENKS BREAKS code




# DO THE MAPPING
for (i in 1:nrow(parsed_list2)) {
  
  myras<-raster(parsed_list2$FILEPATH[i])
    
  #JB is has a hard upper bound. This means that any value above this upper bound will have no colors.
  #To fix this, we will set all raster values greater than the upper bound to be slightly less than this upper bound
  
  ub=mybreaks_class1[length(mybreaks_class1)]
  myras[myras>=ub]<-floor(ub)
  

  pfilename=paste(parsed_list2$NAME[i],"crude", sep="_")
  pfilename=paste(pfilename,"png",sep=".")
  
  jconsfilename=paste(parsed_list2$NAME[i],"crude", "jcons",sep="_")
  jconsfilename=paste(jconsfilename,"png",sep=".")
  title_opts2<-list(parsed_list2$NAME[i],cex=2)
  
  
  p<-levelplot(myras, margin=FALSE, main=title_opts2, par.setting=mycoloropts,scales=myscaleopts)
  
  jcons<-levelplot(myras, margin=FALSE, main=title_opts2, 
                   par.setting=mycoloropts,scales=myscaleopts, at=mybreaks_class2, 
                   xlim=my.xlimit, ylim=my.ylimit, colorkey=myckey)
  
  
  
  png(filename=file.path(YOUR.STORAGE.PATH,pfilename), 
      height=png.height,
      width=png.width,
      units="px"
  )
  
  print(p+ layer(sp.lines(my_basemap)) + layer(sp.polygons(my_basemap2, fill=mylandfill)))
  dev.off()
  
  
  png(filename=file.path(YOUR.STORAGE.PATH,jconsfilename), 
      height=png.width,
      width=png.width,
      units="px"
  )
  print(jcons+ layer(sp.lines(my_basemap)) + layer(sp.polygons(my_basemap2, fill=mylandfill)))
  dev.off()
  
  
}




###############################################################################
###############################################################################
#LOOP OVER ALL ROWS IN parsed_list3 and do some stuff
###############################################################################
###############################################################################



#IF YOU DON' WANT JENKS BREAKS, COMMENT THIS OUT.
mylist2 = list()
for (i in 1:nrow(parsed_list3)) {
  
  
  #This bit of code does Jenks breaks
  subsamp<-values(raster(parsed_list3$FILEPATH[i]))
  subsamp<-subsamp[subsamp>jenks.lowerbound]
  mylist2[[length(mylist2)+1]] = subsamp
}


myvals<-unlist(mylist2)
glob_max<-max(myvals)
mysubs<-sample(myvals,num_jenks_subs)



myclass <- classIntervals(mysubs, n=nbreaks,style="jenks")
myclass$brks[nbreaks]<-glob_max
mybreaks_class2<-c(0,myclass$brks)
#   #End JENKS BREAKS code




# DO THE MAPPING
for (i in 1:nrow(parsed_list3)) {
  
  myras<-raster(parsed_list3$FILEPATH[i])
  
  pfilename=paste(parsed_list3$NAME[i],"crude", sep="_")
  pfilename=paste(pfilename,"png",sep=".")
  
  jconsfilename=paste(parsed_list3$NAME[i],"crude", "jcons",sep="_")
  jconsfilename=paste(jconsfilename,"png",sep=".")
  title_opts<-list(parsed_list3$NAME[i],cex=2)
  
  
  p<-levelplot(myras, margin=FALSE, main=title_opts, par.setting=mycoloropts,scales=myscaleopts)
  
  jcons<-levelplot(myras, margin=FALSE, main=title_opts, 
                   par.setting=mycoloropts,scales=myscaleopts, at=mybreaks_class2, 
                   xlim=my.xlimit, ylim=my.ylimit, colorkey=myckey)
  
  
  
  png(filename=file.path(YOUR.STORAGE.PATH,pfilename), 
      height=png.height,
      width=png.width,
      units="px"
  )
  
  print(p+ layer(sp.lines(my_basemap)) + layer(sp.polygons(my_basemap2, fill=mylandfill)))
  dev.off()
  
  
  png(filename=file.path(YOUR.STORAGE.PATH,jconsfilename), 
      height=png.width,
      width=png.width,
      units="px"
  )
  print(jcons+ layer(sp.lines(my_basemap)) + layer(sp.polygons(my_basemap2, fill=mylandfill)))
  dev.off()
  
  
}









###############################################################################
###############################################################################
#LOOP OVER ALL ROWS IN parsed_list4 and do some stuff
###############################################################################
###############################################################################



#IF YOU DON' WANT JENKS BREAKS, COMMENT THIS OUT.
mylist2 = list()
for (i in 1:nrow(parsed_list4)) {
  
  
  #This bit of code does Jenks breaks
  subsamp<-values(raster(parsed_list4$FILEPATH[i]))
  subsamp<-subsamp[subsamp>jenks.lowerbound]
  mylist2[[length(mylist2)+1]] = subsamp
}


myvals<-unlist(mylist2)
glob_max<-max(myvals)
mysubs<-sample(myvals,num_jenks_subs)



myclass <- classIntervals(mysubs, n=nbreaks,style="jenks")
myclass$brks[nbreaks]<-glob_max
mybreaks_class2<-c(0,myclass$brks)
#   #End JENKS BREAKS code




# DO THE MAPPING
for (i in 1:nrow(parsed_list4)) {
  
  myras<-raster(parsed_list4$FILEPATH[i])
  
  pfilename=paste(parsed_list4$NAME[i],"crude", sep="_")
  pfilename=paste(pfilename,"png",sep=".")
  
  jconsfilename=paste(parsed_list4$NAME[i],"crude", "jcons",sep="_")
  jconsfilename=paste(jconsfilename,"png",sep=".")
  title_opts<-list(parsed_list4$NAME[i],cex=2)
  
  
  p<-levelplot(myras, margin=FALSE, main=title_opts, par.setting=mycoloropts,scales=myscaleopts)
  
  jcons<-levelplot(myras, margin=FALSE, main=title_opts, 
                   par.setting=mycoloropts,scales=myscaleopts, at=mybreaks_class2, 
                   xlim=my.xlimit, ylim=my.ylimit, colorkey=myckey)
  
  
  
  png(filename=file.path(YOUR.STORAGE.PATH,pfilename), 
      height=png.height,
      width=png.width,
      units="px"
  )
  
  print(p+ layer(sp.lines(my_basemap)) + layer(sp.polygons(my_basemap2, fill=mylandfill)))
  dev.off()
  
  
  png(filename=file.path(YOUR.STORAGE.PATH,jconsfilename), 
      height=png.width,
      width=png.width,
      units="px"
  )
  print(jcons+ layer(sp.lines(my_basemap)) + layer(sp.polygons(my_basemap2, fill=mylandfill)))
  dev.off()
  
  
}




























#THIS IS THE UNLOOPED VERSION JUST TO SEE WHAT IS GOING ON.
#    
# my.ylimit=c(-200000,900000)
# my.xlimit=c(1700000,2600000)
# #my.at <- seq(10, 2500, 500)
# mycoloropts <- myBLUETHEME
# mycoloropts <- mydichrome
# myckey <- list(labels=list(cex=2))
# 
# i=1
#   myras<-raster(parsed_list2$FILEPATH[i])
#   
#   tfilename=paste(parsed_list2$NAME[i],"crude", sep="_")
#   tfilename=paste(tfilename,"png",sep=".")
#   p<-levelplot(myras, margin=FALSE, main=parsed_list2$NAME[i], par.setting=mydichrome,scales=list(draw=FALSE))
#   png(filename=file.path(YOUR.STORAGE.PATH,tfilename), 
#       height=500,
#       width=500,
#       units="px"
#   )
#   
#   print(p+layer(sp.lines(my_basemap)) + layer(sp.polygons(my_basemap2, fill=mylandfill)))
# 



