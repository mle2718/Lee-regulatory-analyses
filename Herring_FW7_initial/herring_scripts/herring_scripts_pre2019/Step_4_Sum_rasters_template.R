###### This script pulls all queries rasters and sums them
###### creating a heat-map for any subset of VTR data.


todaysdate = as.Date(Sys.time())
#### (1) - Set your info
yourname = "Min-Yang"
youremail = "Min-Yang.Lee@noaa.gov"
max.nodes = 30 #processor nodes


#### Set directories

SSB.NETWORK=file.path("/net/work5/socialsci") #This is what you need to run networked
SSBdrive = file.path(SSB.NETWORK, "Geret_Rasters") #when running R script off Linux server
rasterfolder = file.path(SSBdrive, "Data", "individualrasters") 



GIS.PATH = file.path(SSBdrive, "Data")
source(file.path(SSBdrive,"FINAL_Raster_Functions.R"))




#where you putting the output?
ML.NETWORK.PATH=file.path("/net/home2/mlee")
ML.PROJECT.PATH=file.path(ML.NETWORK.PATH,"RasterRequests")


exportfolder = file.path(ML.PROJECT.PATH,paste0(todaysdate, "_rasterexport"))
dir.create(exportfolder, recursive=T)



#SET field you are trying to sum over
FIELD = "QTYKEPT" #Like "REVENUE","QTYKEPT", "QTYDISC", or "CATCH"
#SET margin to sum over
MARGIN = c("MY_MARGIN") #Like "SPPNM","NESPP3","GEARCAT","FMP","STATE1" Comment out if want to sum over all margins in a year

########## YOU need to define a custom margin name.  Then pass the name to 




#Define years to create rasters for here
START.YEAR = 2000   #Min = 1996
END.YEAR = 2014     #Max = 2013

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

## Load GIS maps
PROJ.USE = CRS('+proj=aea +lat_1=28 +lat_2=42 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0 ') 
# Albers Equal Area conic (in meters)
BASE.RASTER = raster(file.path(SSBdrive,"Data","BASERASTER_AEA_2"))

HABareas = LOAD.AND.PREP.GIS(SHPNAME="mults_efh", PROJECT.PATH = GIS.PATH, PROJ.USE = PROJ.USE)
East_Cst_cropped  = LOAD.AND.PREP.GIS(SHPNAME="East_Cst_cropped", PROJECT.PATH = GIS.PATH, PROJ.USE = PROJ.USE)
HABareas = gUnion(East_Cst_cropped,HABareas)


### GIS layers are ONLY used for mapping, they do not get used to cut donuts.

### Stop! Think about this!!:
## Are you working with Lobster data? Do you need to re-scale lobster VTR in Maine to match 
# rescales up lobster landings that we know about spatially - changes target revenue 
# Only used if working aggregate for lobster in only Maine. NOT for southern NE. 

### Maine-DMR's landings totals by zone-year? Then do this:
#ME.LOB.DIFF = read.csv(file = file.path(SSBdrive,"DataIn","LOB_VTR_MULTIPLIER_APR16ID.csv"), as.is=T)
#ME.LOB.DIFF = ME.LOB.DIFF[which(!is.na(ME.LOB.DIFF$DIFF)),]  # the H_0 VTR points had NA for DIFF, which resulted in NA-ing their REVENUE when multipled below
#FINAL = merge(x=FINAL, y=ME.LOB.DIFF, all.x=T, all.y=F)
#cond.MEL = FINAL$APR16_ID %in% ME.LOB.DIFF$APR16_ID
#PRE.LIVE = sum(FINAL$LIVE[which(FINAL$SPPNM=="LOBSTER")])
#PRE.REVENUE = sum(FINAL$REVENUE[which(FINAL$SPPNM=="LOBSTER")])
#FINAL$LIVE[cond.MEL] = FINAL$LIVE[cond.MEL]*FINAL$DIFF[cond.MEL]
#FINAL$REVENUE[cond.MEL] = FINAL$REVENUE[cond.MEL]*FINAL$DIFF[cond.MEL]
#FINAL$DIFF=NULL
#POST.LIVE = sum(FINAL$LIVE[which(FINAL$SPPNM=="LOBSTER")])
#POST.REVENUE = sum(FINAL$REVENUE[which(FINAL$SPPNM=="LOBSTER")])

#CSV of each APRID, and revenue for each IDNUM by WEA for each state, and revenue OUTside WEAs ("REV_OUT") & split IDNUM from APR16_ID name
#Remember - REV_RI = WEA is really MA/RI WEA 

#FINALSREF = read.csv(file=file.path(SSBdrive,"DataIn","IDNUM_IN_WEAS.csv"), stringsAsFactors=F, header=T)




#### (2) -  Get available IDNUMs

# Creates list of full filename for each individual raster, as in : I:/individualrasters/CT/2007/IDNUM.gri"
# Divided into 12 list elements, for each state 
#Don't run more than you have to.....takes time. 
filelist = lapply(as.list(list.dirs(path=rasterfolder, recursive=F)), list.files, recursive=T, full.names=T, pattern=glob2rx("*.gri"))

# Create one single-column dataframe with all elements in form of the filepath, but R recgonizes it only as text
# Dataframe with ~1.8 million records (comercial only) 

#The following create new dataframe fields for IDnum and year..
fl = do.call(rbind, lapply(filelist, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILEPATH" 
  return(xx) }) )                                         

fl$STRIPGRID =  sapply(fl$FILEPATH, USE.NAMES=F, function(zz) {
  strsplit(x = as.character(zz), split = ".gri")[[1]]
})
fl$IDNUM = sapply(fl$STRIPGRID, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })

fl$YEAR = sapply(fl$STRIPGRID, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[(NCOL(temp)-1)]) })


#### (3) - Query said data, yielding a unique list of IDNUMs (which are the APR16_ID's but stripped to just numerics:
## Use GEARCAT2 for Gear Category
## PORTLND1 is actual VTR port-landed
## PORTGROUP - for useful mapping, based on Lisa/Julie port community groups
## Remember PORTGROUP has structure "PORTGROUP, ST" = includes State 

# If pulling by a permitlist, use below text, then use cond.ONE below to pull from the permitlist : 
#permitlist <- read.csv(file="C:/BOEM/NEWBED_GILLNET_PERMITS_2014.csv", head=T, as.is=T)[,1] #<- put permits I want here 
#permitlist<- read.csv(file="Y:/BOEM/FROM_JUSTIN/CLUSTER1_2-20-2014.csv", head=T, as.is=T)[,1]
#triplist <- read.csv(file="/net/work5/socialsci/BOEM/FROM_JUSTIN/New Revenue Maps/Cluster 3/Cl3_TRIPS_6-20-14.csv", head=T, as.is=T)[,1]
#triplist <- read.csv(file = "/net/work5/socialsci/BOEM/FROM_JUSTIN/New Revenue Maps/Cluster 4/Cl4_trips_used.csv", head=T, as.is=T)[,1]

# If pulling permits based on conditions, set them here: 

#FINAL$GEARCAT <- as.factor(FINAL$GEARCAT)

#####################################################

##########################################################
#Need to account for fact that a very small # of points are completely on land and can't be spatially allocated 


for (yr in START.YEAR:END.YEAR)  {
  for (MARG in MARGIN)  {
  #### (1) - Load relevant VTR data:
  FINAL <- read.dbf(file = paste0(SSBdrive,"/Data/ExportAll",yr,".dbf"))
  FINAL = subset(FINAL, select=-c(distance25, distance50, distance75, distance90, distance95))
  FINAL = FINAL[which(!is.na(FINAL[[FIELD]])),]
  FINAL = FINAL[which(FINAL[[FIELD]]!=0),]
 
  
  #THIS IS WHERE I CONSTRUCT MY MARGIN VARIABLE
  #subset the species and gear.  cast OTM and PTM to MWT
  
  FINAL=FINAL[which(FINAL$NESPP3 %in% c("168", "212")),]
  FINAL=FINAL[which(FINAL$GEARCODE %in% c("OTM","PTM","PUR")),] # <-MWT and PUR
  
  # make a new gear column. This casts OTM and PTM to "MWT"
  FINAL$MY_GEAR[FINAL$GEARCODE=="PUR"]<-"PUR"
  FINAL$MY_GEAR[FINAL$GEARCODE=="OTM"]<-"MWT"
  FINAL$MY_GEAR[FINAL$GEARCODE=="PTM"]<-"MWT"  

  
  #THIS IS THE NAME OF MY MARGIN VARIABLE
  FINAL$MY_MARGIN<-paste(FINAL$MY_GEAR,FINAL$NESPP3, sep="_")
  
  
  RASTER_FILE = FINAL[which(FINAL$IDNUM%in%fl$IDNUM),] 
  RASTER_FILE = aggregate(get(FIELD) ~ get(MARG) + IDNUM, data=RASTER_FILE, FUN = "sum")
  names(RASTER_FILE) <- c(paste0(MARG),"IDNUM",paste0(FIELD))
  MARGINS <- as.character(unique(RASTER_FILE[[paste0(MARG)]]))

#cond.ONE = paste0('FINAL$GEARNM ==',gear, collapse="")
#cond.ONE = FINAL$GEARCAT == "Clam Dredge"

####
#rastername = paste0(gear,yr)


#U.IDNUM = FINAL$IDNUM[cond.ONE & cond.TWO & cond.THREE & cond.FOUR & cond.FIVE]
U.IDNUM = unique(RASTER_FILE$IDNUM)

fileswanted <- fl[which(fl$IDNUM %in% U.IDNUM),]
fileswanted <- merge(fileswanted,y=subset(RASTER_FILE,select=c("IDNUM",paste0(MARG))))
fileswanted[[paste0(MARG)]] <- as.character(fileswanted[[paste0(MARG)]])
fileswanted$FILEPATH <- paste(fileswanted[['FILEPATH']],fileswanted[[paste0(MARG)]],sep="@")
fileswanted$FILEPATH <- paste0(fileswanted[['FILEPATH']],'@')
fileswanted = split(fileswanted$FILEPATH, f=fileswanted[[paste0(MARG)]])
fileswanted = lapply(fileswanted, as.list)
#fileswanted <- as.character(fileswanted)

# Number records
length(U.IDNUM)

#target.revenue = sum(FINAL$REVENUE[which(FINAL$IDNUM %in% U.IDNUM)], na.rm=T)

# Initiate the multicores!
#### (4) Import and sum these rasters
max.nodes = min(30,as.numeric(length(unique(RASTER_FILE[[paste0(MARG)]]))))
sfInit(parallel=T, cpus=max.nodes)
sfLibrary(raster, verbose=F)
sfLibrary(sp, verbose=F)
sfLibrary(rgeos, verbose=F)
sfLibrary(rgdal, verbose=F)
sfLibrary(R2HTML, verbose=F)
YEAR = yr
sfExport("fileswanted", "BASE.RASTER","RASTER_FILE","FIELD","YEAR","exportfolder","MARG")

if(NROW(fileswanted)==1) {
  print("Only one margin category to sum over - adding blank raster to allow multicore")
  fileswanted = c(fileswanted, paste0(file.path(SSBdrive,"Data","BASERASTER_AEA_2.grd"),"@"))
  names(fileswanted)[2] = "BLANK"
}

## Remove objects to see if it fails

##
RAS1 = sfLapply(fileswanted,function(x,...) {     #usually run in sfLapply
    ERRS = as.character(0) # creat empty character vector 
    
  NR = NROW(x) #NR = number of rows in fileswanted
  if(NR==1) { # If there's only one row of years (as in, there's only one year), then...
    PATH_MARGIN <- do.call(rbind,strsplit(as.character(x[[1]]),split="@"))
    MARG_NAME <- as.character(PATH_MARGIN[NCOL(PATH_MARGIN)])
    rastername = paste0(MARG_NAME,FIELD,YEAR, sep="_")
    HOL2 <- raster(PATH_MARGIN[1])
    ID =  strsplit(PATH_MARGIN[1], split = ".gri")
    ID = do.call(rbind,strsplit(as.character(ID), split = "/"))
    ID = as.character(ID[NCOL(ID)])
    TARGET = RASTER_FILE[[paste0(FIELD)]][RASTER_FILE$IDNUM==ID & RASTER_FILE[paste0(MARG)]==MARG_NAME]
    HOL2 = calc(HOL2,fun=function(z) {z*TARGET})
    target.sum = TARGET
    rastername = paste0(MARG_NAME,FIELD,YEAR)
  }   else { 
    BR = seq(1,NR,by=25) #BR is a sequence 
    if(!NR%in%BR) BR=c(BR, NR) # takes bricks of 25 
    for (i in 1:(NROW(BR)-1)){ #use row # of what's in that "brick" 
      t.index = (BR[i]):(BR[i+1]-1)
      if(i==(NROW(BR)-1)) (t.index = (BR[i]):(BR[i+1])) 
      isfirst = T
      for (j in t.index) {   
        PATH_MARGIN <- do.call(rbind,strsplit(as.character(x[[j]]),split="@"))
        MARG_NAME <- as.character(PATH_MARGIN[NCOL(PATH_MARGIN)])
        rastername = paste0(MARG_NAME,FIELD,YEAR)
        ID =  strsplit(PATH_MARGIN[1], split = ".gri")
        ID = do.call(rbind,strsplit(as.character(ID), split = "/"))
        ID = as.character(ID[NCOL(ID)])
        TARGET = RASTER_FILE[[paste0(FIELD)]][RASTER_FILE$IDNUM==ID & RASTER_FILE[paste0(MARG)]==MARG_NAME]
        if(isfirst) {         
          HOL=raster(PATH_MARGIN[1])
          HOL = calc(HOL,fun=function(z) {z*TARGET})
          target.sum = TARGET
          rastername = paste0(MARG_NAME,FIELD,YEAR)
          isfirst=F 
        } else {   
          tt = try(raster(PATH_MARGIN[1]))
          tt = try(calc(tt,fun=function(z) {z*TARGET}))
          target.sum = target.sum+TARGET
          if(class(tt)=="try-error") {
            tt = BASE.RASTER #if it doesn't work, returns empty raster 
            ERRS = c(ERRS,as.character(j))  # add filename to list of errors
          }
          HOL = (mosaic(tt, HOL, fun='sum', na.rm=T, filename="")) 
          #HOL = holder, thing you're binding to? 
          ## mosaic sums together raster - need to have same resolution and center point, but NOT same extent (obviously)
        } # end else 
      } # end j loop
      if(i==1) {
        HOL2 = HOL 
      } #end if
      else {
        HOL2 = mosaic(HOL2, HOL, fun='sum', na.rm=T)
      }   #end big else
    }   #end else
  }   #end i loop
  #if(cellStats(HOL2, stat='sum')/target.revenue > 0.99) print(paste("Hurray! ", (cellStats(RASsum, stat="sum")/target.revenue)*100, "% match! Huzzah!"))
  writeRaster(HOL2, file.path(exportfolder,rastername), format="GTiff", overwrite=T)
  
  w <- file.path(exportfolder, paste0(rastername,".html"))  
  HTML(paste0("Raster Name: ", rastername), w, F)
  HTML(paste0("Target Sum: ", target.sum), w, T)
  HTML(paste0("Number of Records): ", NR), w, T)
  HTML(paste0("Percent Match: ", (cellStats(HOL2, stat="sum")/target.sum)*100),w,T)
  #HTML(paste("Share of Revenue:", percent(round(SHARE.OF.REVENUE,3)), "percent", sep=" "),w,T)
  return(list(HOL2, ERRS,rastername))}

  ,RASTER_FILE=RASTER_FILE,FIELD=FIELD,YEAR=YEAR,MARG=MARG, exportfolder=exportfolder)
#### Stop Here ###

## DEBUGGING ##
#summary(RASsum)
##
#summary(RAS2[[1]])

####

sfStop()       #sfstop = stops multi-core work 
gc() # "garbage collection" - "gets rid of junk in the memory?"

RAS1$BLANK = NULL #"BLANK" is inserted if fileswanted is only 1 year so that sfLapply will run - it requires a list of 2 or more to function.

#RAS2 = lapply(RAS1, function(pp) return(pp[[1]])) #take r
#MISSING = unlist(lapply(RAS1, function(qq) return(qq[[2]]))); MISSING = MISSING[which(MISSING!="0")]


#if(NROW(RAS2)==1) {
  #RASsum=(RAS2[[1]]) } else {
   # RASsum = do.call(mosaic, args = c(unlist(RAS2, use.names=F), fun='sum', na.rm=T))} #mosaic sums all rasters in list RAS2
#rm(SHARE.OF.REVENUE)
#SHARE.OF.TARGET = cellStats(RASsum, stat='sum') / target;  SHARE.OF.TARGET

#Get info on rasters
#cellStats(RASsum, stat='sum') # Gives # value - there are also other options( median value, # of NAs, etc) 
#cellStats(RASsum, stat='sum')/target.revenue #Checks that the sum of cells matches the expected sum of revenue. 

#if(cellStats(RASsum, stat='sum')/target.revenue > 0.99) print(paste("Hurray! ", round((cellStats(RASsum, stat="sum")/target.revenue))*100, "% match! Huzzah!"))


#
############
# If creating PVC: 
#Determine quantiles
#r <- RASsum
#f <- readGDAL("/net/work5/socialsci/RasterFootprint/Products/Sharon/2014-06-20_rasterexport/NY_CCE_Trawl_June20.tif")
#r<-raster(f)
#
#myints <- quantile(r, c(0,0.75,0.95,0.99,0.999, 0.9999, 1), na.rm=T)
#myints
#uints <- unique(myints)
#uints
#plot(r)
#plot(rc)
#
#Create polygon from raster
#rcpols <- rasterToPolygons(rc, dissolve=T)
#
#Save as shapefile
#savingfolder = file.path(SSBdrive, "Products",yourname,paste0(todaysdate, "_rasterexport"),"Cont_Poly_Shapefiles")
#dir.create(exportfolder, recursive=T)
#writeOGR(rcpols, savingfolder, overwrite_layer=T, 
#         layer=paste(rastername, "_contours"), verbose=T, driver='ESRI Shapefile', morphToESRI = TRUE)
#
#

#Write report to HTML file

#browseURL(w)
#  }
rm(RAS1, RAS2,RASsum)
  }
}
### email you when it's done 
sendmail(youremail,subject=paste("Raster Query is finished", sep=" "), 
         message=paste("Time to reset code?"),
         password="rmail")


#Check results by using the following text:
#View(FINAL[which(FINAL$PERMIT %in% as.character(permitlist)),])
########
########DEBUGGING#################################################

# ARE.IN = fl[which(fl$IDNUM %in% U.IDNUM), 3]
# #ARE.OUT = fl[which(!fl$IDNUM %in% U.IDNUM),]
# ARE.OUT = U.IDNUM[!U.IDNUM %in% fl$IDNUM]  #—> this will get us all of the U.IDNUMs which do not have corresponding files
# NROW(fl)
# NROW(U.IDNUM)
# NROW(ARE.IN)
# NROW(ARE.OUT)
# # Note: NROW(ARE.IN) + NROW(ARE.OUT) should equal NROW(U.IDNUM) 
# 
# 
# View(FINAL[which(FINAL$IDNUM %in% ARE.OUT),]) 
# mat.are.out <- FINAL[which(FINAL$IDNUM %in% ARE.OUT),] 
# mat.are.in <- FINAL[which(FINAL$IDNUM %in% ARE.IN),] 
# 
# sort(unique(FINAL$GEARNM[which(FINAL$IDNUM %in% ARE.OUT)]))
# sort(unique(FINAL$YEAR[which(FINAL$IDNUM %in% ARE.OUT)]))
# #—> will show us the records in FINAL which do not have raster files that could be found. Any pattern? Any common state or year or gear?
# 
# #Also, I’m a little concerned about the quantity in ARE.OUT. 1.691 million seems a little low. Run this:
# NROW(unique(FINAL$IDNUM[which(FINAL$IDNUM %in% fl$IDNUM)])) #This should give us a count of the unique FINAL IDNUMs that are on the fl$IDNUM list.
# 
# #Can you also run:
#NROW(unique(FINAL$IDNUM[which(FINAL$TRIPCATG==1)]))   #—> this will tell us how many “commercial” records we would expect to find.
# NROW(unique(FINAL$IDNUM))  #—> this will tell us how many records (in total) we would expect to find.

##############
#END DEBUGGING 
####################################################################



