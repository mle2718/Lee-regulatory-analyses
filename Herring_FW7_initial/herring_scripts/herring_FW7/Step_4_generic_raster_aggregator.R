
#READ in all the data
FINAL=data.frame()
for (yr in START.YEAR:END.YEAR)  {
  
  FINAL <- read.dbf(file = paste0(SSBdrive,"/Data/ExportAll",yr,".dbf"))
  FINAL = subset(FINAL, select=-c(distance25, distance50, distance75, distance90, distance95))
  FINAL = FINAL[which(!is.na(FINAL[[FIELD]])),]
  FINAL = FINAL[which(FINAL[[FIELD]]!=0),]
  
  #Pass in a previously defined "thing" logical_subset<-"which(FINAL$NESPP3 %in% c("212"))"
  FINAL=FINAL[eval(logical_subset),]
  

  
  #THIS IS THE NAME OF MY MARGIN VARIABLE
  #FINAL$MY_MARGIN<-paste(FINAL$MONTH,readable_name, sep="_")
  FINAL$MY_MARGIN<-eval(my_margin_name)
  
    
  for (MARG in MARGIN)  {
    
    RASTER_FILE = FINAL[which(FINAL$IDNUM%in%fl$IDNUM),]
    
    RASTER_FILE = aggregate(get(FIELD) ~ get(MARG) + IDNUM, data=RASTER_FILE, FUN = "sum")
    names(RASTER_FILE) <- c(paste0(MARG),"IDNUM",paste0(FIELD))
    MARGINS <- unique(RASTER_FILE[[paste0(MARG)]])
    
    #cond.ONE = paste0('FINAL$GEARNM ==',gear, collapse="")
    #cond.ONE = FINAL$GEARCAT == "Clam Dredge"
    
    ####
    #rastername = paste0(gear,yr)
    
    
    #U.IDNUM = FINAL$IDNUM[cond.ONE & cond.TWO & cond.THREE & cond.FOUR & cond.FIVE]
    U.IDNUM = unique(RASTER_FILE$IDNUM)
    
    fileswanted <- fl[which(fl$IDNUM %in% U.IDNUM),]
    fileswanted <- merge(fileswanted,y=subset(RASTER_FILE,select=c("IDNUM",paste0(MARG))))
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
    sfExport("fileswanted", "BASE.RASTER","RASTER_FILE","FIELD","YEAR","export.geotiff.path","MARG")
    
    if(NROW(fileswanted)==1) {
      print("Only one margin category to sum over - adding blank raster to allow multicore")
      fileswanted = c(fileswanted, file.path(SSBdrive,"DataIn","BASERASTER_AEA_2.grd"))
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
        rastername = paste0(MARG_NAME,FIELD,YEAR)
        HOL2 <- raster(PATH_MARGIN[1])
        ID =  strsplit(PATH_MARGIN[1], split = ".gri")
        ID = do.call(rbind,strsplit(as.character(ID), split = "/"))
        ID = as.character(ID[NCOL(ID)])
        TARGET = RASTER_FILE[[paste0(FIELD)]][RASTER_FILE$IDNUM==ID & RASTER_FILE[paste0(MARG)]==MARG_NAME]
        HOL2 = calc(HOL2,fun=function(z) {z*TARGET})
        target.sum = TARGET
        rastername = paste0(MARG_NAME,"_",FIELD,"_",YEAR)
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
            rastername = paste0(MARG_NAME,"_",FIELD,"_",YEAR)
            ID =  strsplit(PATH_MARGIN[1], split = ".gri")
            ID = do.call(rbind,strsplit(as.character(ID), split = "/"))
            ID = as.character(ID[NCOL(ID)])
            TARGET = RASTER_FILE[[paste0(FIELD)]][RASTER_FILE$IDNUM==ID & RASTER_FILE[paste0(MARG)]==MARG_NAME]
            if(isfirst) {         
              HOL=raster(PATH_MARGIN[1])
              HOL = calc(HOL,fun=function(z) {z*TARGET})
              target.sum = TARGET
              rastername = paste0(MARG_NAME,"_",FIELD,"_",YEAR)
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
      writeRaster(HOL2, file.path(export.geotiff.path,rastername), format="GTiff", overwrite=T)
      
      w <- file.path(export.geotiff.path, paste0(rastername,".html"))  
      HTML(paste0("Raster Name: ", rastername), w, F)
      HTML(paste0("Target Sum: ", target.sum), w, T)
      HTML(paste0("Number of Records): ", NR), w, T)
      HTML(paste0("Percent Match: ", (cellStats(HOL2, stat="sum")/target.sum)*100),w,T)
      #HTML(paste("Share of Revenue:", percent(round(SHARE.OF.REVENUE,3)), "percent", sep=" "),w,T)
      return(list(HOL2, ERRS,rastername))}
      
      ,RASTER_FILE=RASTER_FILE,FIELD=FIELD,YEAR=YEAR,MARG=MARG, exportfolder=export.geotiff.path)
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
    
    
    #  }
    rm(RAS1)
  }
}

