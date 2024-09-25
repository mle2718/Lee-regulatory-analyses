# INPUTS: myr2 (raster* object)
# DEPENDENCIES: FINAL_w (VTR data that has permit numbers joined) and fla (manifest of individual rasters)
# OUTPUTS: confidentialized version of myr2
# This checks confidentiality by having at least 3 distinct permits in a feature. 
# stops after 3. While parallelized, this doesn't benefit too much from scaling sfClusterApplyLB().  The bottleneck is probably is the rastertoPolygons command.
# The other bottlneck will occur for metiers that are really patchy.
# individual rasters are checked based on distance from VTR point to the centriod of the feature being checked.  This might not be optimal if the feature is a donut.  I don't know what to do about this.
## Min-Yang.Lee@noaa.gov
## April 11, 2017



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


#SUBSET THE DATASET -- FINAL_w holds the metier in memory, but we are looping across years using worki



FINAL_wy=FINAL_w
shortlist<-c("IDNUM","PERMIT","LAT","LON")
FINAL_wyshort=unique(FINAL_wy[shortlist])


#SUBSET THE raster inventory based on the DATASET 
flwy=fl[which(fl$IDNUM%in%FINAL_wy$IDNUM),]

#A bit of a hack: this is <duplicates, drop>
flwy=unique(flwy)






fileswanted<-merge(flwy,FINAL_wyshort, all.x=TRUE,all.y=FALSE, by.x = 'IDNUM', by.y='IDNUM')


fileswanted$myid <- seq.int(nrow(fileswanted))
fileswanted$LAT<-abs(fileswanted$LAT)
fileswanted$LON<-abs(fileswanted$LON)



timer1<-Sys.time()
#THIS is the loop across the classification levels
for (working_level in blength:2){ 
  
  #Some metier-years may have nothing in a particular level. This is mostly likely for working_level=blength. The next bit of code handles this possiblity.
  # A more elegant way to do this is:
  # zz<-cellStats(myr2, "max")
  # if zz<working_level {    print(paste0("No polygons in level ", working_level, "in this metier to crack open"))     }
  #  else{ 
  #}
  # But you have not tested this and it's unlikely to save much time.
  options(warn=-1)
  split_polys<-rasterToPolygons(myr2, fun=function(x){x==working_level}, n=8, dissolve="TRUE")
  options(warn=0)
  
  #If (NULL) do nothing.  I'm not sure if we want is.null() or length(split_polys)==0.
  if(is.null(split_polys)) {
    print(paste0("No polygons in level ", working_level, "in this metier to crack open"))     
    #We do nothing
  } else {
  
  print(paste0("split_polys is not null so..."))
  n_poly <- length(split_polys)
  out <- lapply(1:n_poly, function(i) split_polys[i,])
  print(paste0("this is working level ", working_level))
  sfInit(parallel=T, cpus=max.nodes)
  sfLibrary(raster, verbose=F)
  sfLibrary(sp, verbose=F)
  sfLibrary(rgeos, verbose=F)
  sfLibrary(rgdal, verbose=F)
  sfLibrary(R2HTML, verbose=F)
  
  NR = as.numeric(NROW(fileswanted)) #NR = number of rows in fileswanted
  sfExport("fileswanted","BASE.RASTER", "NR")
  
  results<-NULL
  AREA_SHP<-out  
  
  #This function make 4 outputs:  the ID number of the checked feature, a 0/1 that indicates "3 or more permits", 
  # The number of trips actually checked, and an ERRS =0 field. The last two aren't really needed.
      
      ACTIVITY = sfClusterApplyLB(AREA_SHP,function(x,...) {     #usually run in sfLapply
        shape_cent<-spTransform(gCentroid(x),CRS=('+init=epsg:4326'))
          lon<-abs(slot(shape_cent,'coords')[1])
          lat<-abs(slot(shape_cent,'coords')[2])
          fileswanted$DIST=sqrt(  (fileswanted$LON-lon)^2 + (fileswanted$LAT-lat)^2)
          fileswanted<-fileswanted[order(fileswanted$DIST),]
        plist<-as.list(NULL)
    ERRS = as.character(0) # create empty character vector 
    
    id.list <- matrix(nrow = 1,ncol = 3)
    id.list[1,1] <- sapply(slot(x, "polygons"), function(y) slot(y, "ID"))       
    
    id.list[1,2] <- 0       
    
    for (j in 1:NR) {   
      id.list[1,3] <- j       
      
      #IF the permit number is not in the plist, do the raster and masking.  
      if(!fileswanted$PERMIT[j] %in% plist ){
        tt = raster(fileswanted$FILEPATH[j])
        tt = mask(tt, x, byid=c(T,F))
        tt <- unlist(as.numeric(cellStats(tt,stat='sum')))
        
        # IF the raster is inside the area, add it to the list of permits. Then check uniqueness of the list of permits.
        if (tt>0) {
          plist[[length(plist)+1]]<-fileswanted$PERMIT[j]
          plist<-unique(plist)
        }
      }
      if(length(plist)>=3){
        id.list[2]<-1
        break
      }
      
    }
    return(list(id.list, ERRS))})
  
  #THIS CODE IS SOOOO UGLY, but it works. 
  # We send the results of ACTIVITY (sfClusterApplyLB) to a dataframe, then name the columns and force to numeric.
  #NOTE, it would be more elegant to set disclosable to be a logical, but whatever.
  # We keep the observations which are not disclosable.  If there are any, we go back up to the polygons and keep the corresponding polygons
  # We rasterize them,and then re-characterize them down to the next level.  
  
  ACTIVITY <- do.call(rbind,lapply(ACTIVITY,data.frame,stringsAsFactors=FALSE) )
  colnames(ACTIVITY)<-c("feature","disclosable","tripschecked","ERRS")
  ACTIVITY$disclosable <- as.numeric(as.character(ACTIVITY$disclosable))
  ACTIVITY$feature <- as.numeric(as.character(ACTIVITY$feature))
  ACTIVITY$disclosable <- as.numeric(as.character(ACTIVITY$disclosable))
  
  
  ACTIVITY <- ACTIVITY[which(ACTIVITY$disclosable==0),]
  if (NROW(ACTIVITY) >=1){
    
    changeme<- sapply(slot(split_polys, "polygons"), function(y){
      slot(y, "ID") %in%ACTIVITY$feature
    }
    ) 
    changeme<-split_polys[changeme,]
    changeme <- lapply(1:length(changeme), function(xx) changeme[xx,])
    
    
    for (wr in 1:length(changeme)){
      zz<-rasterize(changeme[[wr]], myr2, background=0)*100  
      myr2<-myr2+zz
      myr2[myr2>100]<-working_level-1
    }  
  }
  
  
  sfStop() 
  }
}
timerB<-Sys.time()
timerB
print(paste0("The confidentiality checker for metier took this long:"))
print(round(difftime(timerB, timer1, units='min'),3))












