
# We loop over metiers (MARGINS in Geret's original code.)  
#Sharon coded QTYKEPT and REVENUE in 2 separate chunks. So I will loop over "GROUP"

#There are 16 FMPs (including "none").
#there are also NN "GEARs"
#THere are SS Species


#vsubs<-c("YEAR","GROUP", "NAME", "GROUPUNIT")
#working_group<-working_group[vsubs]


FINAL_w<-NULL
TMES<-substr(TME,1,nchar(TME)-2)
TMES<-gsub("_regime","",TMES)

REGIME<-substr(TME,nchar(TME),nchar(TME))
if(TMES=="herring_pounds_allgears") {
  logical_subset<-quote(which(FINAL$NESPP3 %in% c(168)))
  FIELD = "QTYKEPT"
  
  } else if(TMES=="herring_pounds_noPUR") {
    logical_subset<-quote(which(FINAL$NESPP3 %in% c(168) & !(FINAL$GEARCODE %in% c("PUR") )))
    FIELD = "QTYKEPT"
    
} else if(TMES=="hrgmack_revenue_allgears") {
  logical_subset<-quote(which(FINAL$NESPP3 %in% c(212,168)))
  FIELD = "REVENUE"
  
} else if(TMES=="other_revenue_avgmonth") {
  logical_subset<-quote(which(!(FINAL$NESPP3 %in% c(212,168))))
  FIELD = "REVENUE"
} else if(TMES=="herring_pounds_avgmonth") {
  logical_subset<-quote(which(FINAL$NESPP3 %in% c(168) ))
  FIELD = "QTYKEPT"
 }else if(TMES=="mackerel_pounds_avgmonth") {
  logical_subset<-quote(which(FINAL$NESPP3 %in% c(212) ))
  FIELD = "QTYKEPT"
}  


if(REGIME=="1") {
  logical_subset2<-quote(which(FINAL_w$YEAR >= START.YEAR & FINAL_w$YEAR <= 2013))
  
} else if(REGIME=="2") {
  logical_subset2<-quote(which(FINAL_w$YEAR >= 2014 & FINAL_w$YEAR <= END.YEAR))
  FIELD = "QTYKEPT"
}

# Subset to the gearids and YEARS that I need 
  FINAL_w=FINAL[eval(logical_subset),]
  FINAL_w=FINAL_w[eval(logical_subset2),]
  
  counter<-nrow(FINAL_w)

print(paste0(working_group$NAME[1]," is in the group gear.  This is iteration ", i, ".  ", counter, " Rows of data"))





