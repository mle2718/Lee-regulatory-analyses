

#You'll need to modify this to account for the regimes (cross years) and monthly blocks (June-Sept)

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


# We loop over metiers (MARGINS in Geret's original code.)  
#Sharon coded QTYKEPT and REVENUE in 2 separate chunks. So I will loop over "GROUP"

#There are 16 FMPs (including "none").
#there are also NN "GEARs"
#THere are SS Species


vsubs<-c("YEAR","GROUP", "NAME", "GROUPUNIT")
working_group<-temp_Q_list[vsubs]
working_group$YEAR<-as.numeric(working_group$YEAR)






FINAL_w<-NULL

  temp_Q_list$metier =  sapply(working_group$NAME, USE.NAMES=F, function(zz) { # We are referring to "REVENUE" versus "QTYKEPT here
    temp <- do.call(rbind,strsplit(as.character(zz), split = "_")) 
    return(temp[3]) }) # Adding "-1" moves you back one "/"  - as in, back one "/" separator to get the group/file folder name
  matcher<- working_group$metier[1]
  
  if(matcher=="allgears"){
    FINAL_w=FINAL
  } else 
  
        FINAL_w=FINAL[which(FINAL$MY_GEAR %in% matcher),]
  


