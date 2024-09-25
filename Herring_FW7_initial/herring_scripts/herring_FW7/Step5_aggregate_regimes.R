#Aggregate the first level Rasters to a second level.






#################################################
## END SECTION 4 
#################################################

list1<- lapply(as.list(list.dirs(path=export.geotiff.path, recursive=T)), list.files, recursive=F, full.names=T, pattern=mypat1)
parsed_list1 = do.call(rbind, lapply(list1, function(xx) {
  xx = as.data.frame(xx, stringsAsFactors=F)
  names(xx) = "FILENAME" 
  return(xx) }) )      


parsed_list1$NAME = sapply(parsed_list1$FILENAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "/"))
  return(temp[NCOL(temp)]) })

parsed_list1$NAME <-gsub(".tif","",parsed_list1$NAME)

parsed_list1$MONTH = as.numeric(sapply(parsed_list1$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[1]) }))

parsed_list1$type = as.character(sapply(parsed_list1$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[2]) }))


parsed_list1$metric = as.character(sapply(parsed_list1$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[3]) }))


parsed_list1$YEAR = as.numeric(sapply(parsed_list1$NAME, USE.NAMES=F, function(zz) {
  temp = do.call(rbind,strsplit(as.character(zz), split = "_"))
  return(temp[4]) }))

parsed_list1$REGIME<-0
parsed_list1$REGIME[which(parsed_list1$YEAR>=2008 & parsed_list1$YEAR<=2013)]<-1
parsed_list1$REGIME[which(parsed_list1$YEAR>=2014 & parsed_list1$YEAR<=2018)]<-2



for (mymonth in 1:12) {
for (myr in 1:2)  {
   yearfileswanted <- parsed_list1[which(parsed_list1$REGIME==myr & parsed_list1$MONTH==mymonth),]
if (nrow(yearfileswanted)==0){
#If there are no matching files, do nothing
  }
else{   
# If there is at least 1 matching file, build the name
outfilename<-paste0(outfilestub,"month_",mymonth,"_regime_",myr,".tif")
  
f<-extent(raster(file.path(yearfileswanted$FILENAME[1])))
new_xmin<-xmin(f)
new_ymin<-ymin(f)
new_xmax<-xmax(f)
new_ymax<-ymax(f)


if (nrow(yearfileswanted)==1){
#There's nothing really to do except save the raster as outfilename  
  holding_summer<-raster(file.path(yearfileswanted$FILENAME[1]))
  writeRaster(holding_summer, filename=file.path(regime.geotiff.path,outfilename), overwrite=TRUE)
}
else{
for (pp in 2:nrow(yearfileswanted)){
  f<-extent(raster(file.path(yearfileswanted$FILENAME[pp])))
  new_xmin<-min(new_xmin,xmin(f))
  new_ymin<-min(new_ymin,ymin(f))
  new_xmax<-max(new_xmax,xmax(f))
  new_ymax<-max(new_ymax, ymax(f))
}

## THIS SETS THE NEW EXTENT
f3<-extent(new_xmin,new_xmax, new_ymin, new_ymax)





holding_summer<-extend(raster(file.path(yearfileswanted$FILENAME[1])), f3, value=0)

for (ppp in 2:nrow(yearfileswanted)){
  temp<-extend(raster(file.path(yearfileswanted$FILENAME[ppp])), f3, value=0)
  holding_summer<-temp+holding_summer
}
}

nyears<-length(unique(yearfileswanted$YEAR))
holding_summer<-holding_summer/nyears

writeRaster(holding_summer, filename=file.path(regime.geotiff.path,outfilename), overwrite=TRUE)
}

}
}




