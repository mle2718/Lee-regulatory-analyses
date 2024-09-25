



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


#vsubs<-c("YEAR","GROUP", "NAME", "GROUPUNIT")
#working_group<-working_group[vsubs]
working_group$YEAR<-as.numeric(working_group$YEAR)

#I turned off warnings for a very small section of code. 
options(warn=-1)
isall<-grepl(glob2rx("*ALL_ANNUAL*"), working_group$GROUP[1])

isfmp<-grepl(glob2rx("*FMP*"), working_group$GROUP[1])
isfmp<-ifelse(grepl(glob2rx("*HMS*"),working_group$GROUP[1]), "TRUE",isfmp)
isfmp<-ifelse(grepl(glob2rx("Small Mesh Multispecies*"),working_group$GROUP[1]), "TRUE",isfmp)

grouptest<-tolower(working_group$GROUP[1])
grouptest<-gsub(" ","",grouptest)
isgear<-grep(grouptest, mygears)

# To check for species, you can strip off the last 8 characters from NAME (which are YYYY.tif).  Then strip off QTYKEPT and or REVENUE
# Then see if you have a numeric left over.

test_species<-working_group$NAME[1]
test_species<-substr(test_species,1, nchar(test_species)-8)
test_species<-gsub("REVENUE","",test_species)
test_species<-gsub("QTYKEPT","",test_species)

#If the prefix is can be coerced to a numeric, then this will evaluate to TRUE. 
# If not, then this will evaluate to false.
isspecies<-!is.na(as.numeric(test_species))

type<- ifelse(isgear>=1,"gear",0)
type<- ifelse(isfmp,"FMP",type)
type<- ifelse(isall,"aggregated",type)
type<- ifelse(isspecies,"species",type)
options(warn=0)
#I turned warnings back on here. 

FINAL_w<-NULL
#TYPE = GEAR if strmatch(working_group$GROUP in list of gears)
if(type=="gear"){ 
  working_group$NAME<-substr(working_group$NAME,1, nchar(working_group$NAME)-8)
  working_group$NAME<-gsub("REVENUE","",working_group$NAME)
  working_group$NAME<-gsub("QTYKEPT","",working_group$NAME)
  matcher<-unique(working_group$NAME)
  FINAL_w=FINAL[which(FINAL$GEARCAT %in% matcher),]
  counter<-NROW(FINAL_w)
  print(paste0(working_group$NAME[1]," is in the group gear.  This is iteration ", i, ".  ", counter, "Rows of data"))
  
} else if(type=="FMP") {
  working_group$NAME<-gsub("FMP","",working_group$NAME)
  working_group$NAME<-tolower(working_group$NAME)
  working_group$NAME<-gsub("midatlantic [/*]", "", working_group$NAME)
  working_group$NAME<-gsub("midatlantic", "", working_group$NAME)
  working_group$NAME<-gsub(" ne", "", working_group$NAME)
  working_group$NAME<-gsub(" joint", "", working_group$NAME)
  working_group$NAME<-gsub(" ","",working_group$NAME)
  working_group$NAME<-substr(working_group$NAME,1, nchar(working_group$NAME)-8)
  working_group$NAME<-gsub("revenue","",working_group$NAME)
  working_group$NAME<-gsub("qtykept","",working_group$NAME)
  matcher<-unique(working_group$NAME)
  FINAL_w=FINAL[which(FINAL$tFMP %in% matcher),]
  counter<-NROW(FINAL_w)
  
  print(paste0(working_group$NAME[1]," is in the group FMP. This is iteration ", i, ".  ", counter, "Rows of data"))
  
} else if(type=="species") {
  matcher<-working_group$NAME[1]
  matcher<-substr(matcher,1, nchar(matcher)-8)
  matcher<-gsub("REVENUE","",matcher)
  matcher<-gsub("QTYKEPT","",matcher)
  FINAL_w=FINAL[which(FINAL$NESPP3 %in% matcher),]
  counter<-NROW(FINAL_w)
  
  print(paste0(working_group$NAME[1]," is in the group species. This is iteration ",i, ".  ", counter, " rows of data"))
  
} else if(type=="aggregated") {
  FINAL_w<-FINAL
  counter<-NROW(FINAL_w)
  
  print(paste0(working_group$NAME[1]," is in the group species. This is iteration ",i, ".  ", counter, " rows of data"))
  
} else
  print("SOMETHING BROKE")


