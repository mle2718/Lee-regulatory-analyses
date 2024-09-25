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
  
  
  exportfolder = file.path(ML.PROJECT.PATH,paste0("extra_year_",todaysdate, "_rasterexport"))
  dir.create(exportfolder, recursive=T)
  
  
  
  #SET field you are trying to sum over
  FIELD = "QTYKEPT" #Like "REVENUE","QTYKEPT", "QTYDISC", or "CATCH"
  #SET margin to sum over
  MARGIN = c("NESPP3") #Like "SPPNM","NESPP3","GEARCAT","FMP","STATE1" Comment out if want to sum over all margins in a year
  
  ########## YOU need to define a custom margin name.  Then pass the name to 
  
  
  
  
  #Define years to create rasters for here
  START.YEAR = 2015   #Min = 1996
  END.YEAR = 2015     #Max = 2013
  
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
  

  
  
  #LOAD IN THE INVENTORY OF RASTERS
  load(file.path(SSBdrive,"Data","RasterDate.Rdata"))
  fl<-FILE_INFO[c(1:4)]
  rm(list="FILE_INFO")
  # If pulling permits based on conditions, set them here: 
  
  #Need to account for fact that a very small # of points are completely on land and can't be spatially allocated 
  
  FINAL=data.frame()
  for (yr in START.YEAR:END.YEAR)  {
    
    FINALa <- read.dbf(file = paste0(SSBdrive,"/Data/ExportAll",yr,".dbf"))
    FINALa = subset(FINALa, select=-c(distance25, distance50, distance75, distance90, distance95))
    FINALa = FINALa[which(!is.na(FINALa[[FIELD]])),]
    FINALa = FINALa[which(FINALa[[FIELD]]!=0),]
    
    FINALa=FINALa[which(FINALa$NESPP3 %in% c("168", "81", "352", "269")),]

    #THIS IS WHERE I CONSTRUCT MY MARGIN VARIABLE
    #subset the species and gear.  cast OTM and PTM to MWT
    FINAL=rbind(FINAL, FINALa)
  }
  
  for (yr in START.YEAR:END.YEAR)  {
    
    for (MARG in MARGIN)  {
      
      #THIS IS THE NAME OF MY MARGIN VARIABLE
      
      
      RASTER_FILE = FINAL[which(FINAL$YEAR==yr),] 
            RASTER_FILE = RASTER_FILE[which(RASTER_FILE$IDNUM%in%fl$IDNUM),] 
      
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

  sfStop()       #sfstop = stops multi-core work 
  gc() # "garbage collection" - "gets rid of junk in the memory?"
  
  RAS1$BLANK = NULL #"BLANK" is inserted if fileswanted is only 1 year so that sfLapply will run - it requires a list of 2 or more to function.
  
  #browseURL(w)
  #  }
  rm(RAS1)
    }
  }
  