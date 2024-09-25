#R code to get data ready to check for confidentiality.
#load/install libraries
#Project name and directories
#Years.   
# Get the gearid level data files into memory
#subset the columns and add the permit column
# Leaves behind a dataframe (FINAL) that is had permit numbers added to it.


#Pull Data
###########################################################################################
#First, pull in permits and tripids.
permit_tripids<-list()
i<-0
for (years in START.YEAR:END.YEAR){
  i<-i+1
  querystring<-paste0("select permit, tripid from veslog",years,"t")
  permit_tripids[[i]]<-dbGetQuery(con, querystring)
}
permit_tripids<-do.call(rbind.data.frame, permit_tripids)

FINAL<-data.frame()


for (yr in START.YEAR:END.YEAR)  {
  FINAL2 <- read.dbf(file = paste0(GD.GIS.PATH,"/ExportAll",yr,".dbf"), as.is=TRUE)
  FINAL=rbind(FINAL,FINAL2)
  rm(FINAL2)
}


FINAL <- subset(FINAL, select=-c(DAY, AREA, DAS, SERIAL_NUM, PORTLANDED, PORTGROUP, PORTAREAKE, PORTLND1, STATE1, VHP, LEN, PORT_LON, PORT_LAT,distance25, distance50, distance75, distance90, distance95))
FINAL <- base::merge(FINAL,permit_tripids, all.x=TRUE,all.y=FALSE, by="TRIPID")

#VAST majority of no permits are from SCOQ fishery, but we'll just copy over VESID into permit for these anywa
#table(FINAL[which(is.na(FINAL$permit)),]$FMP) 
FINAL$PERMIT[FINAL$FMP == "SURF CLAM OCEAN QUAHOG MIDATLANTIC *"] <-FINAL$VESID[FINAL$FMP == "SURF CLAM OCEAN QUAHOG MIDATLANTIC *"]

















