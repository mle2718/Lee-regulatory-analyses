numclasses=8

#### "Fancy" colors scheme that's color-blind friendly, 8 bins, and includes a 9th bin of 0 values  
brewer.friendly.ygb <- c("#ffffff", brewer.pal(numclasses, "YlGnBu"))
my.friendly.YGB=rasterTheme(region=brewer.friendly.ygb)
mycoloropts <- c(my.friendly.YGB)#, "#ffffff") # GOOD

###
###


#3B. classInt options
#if you want, you can set the number of breaks less than (numclasses+1).  Which I have done.
nbreaks=8
# How large do you want the subsample for Jenks Natural breaks classifications? 
# 10,000 runs reasonably quickly. don't pick too many
# If you ask for a subsample, it's a good idea to set a seed.
num_jenks_subs=2000
set.seed(8675309)
# You might want to exclude zeros or anythign that is below a threshold. I'm going to exclude all cells <=1.
jenks.lowerbound=1


my.ylimit=c(-300000,900000)
my.xlimit=c(1700000,2600000)

#turn things on or or off 
myscaleopts <- list(draw=FALSE) #Don't draw axes
# myscaleopts <- list(draw=TRUE) #draw axes



#color options (par.setting)
mycoloropts <- c(my.friendly.YGB)#, "#ffffff") # GOOD
#mycoloropts <- mydichrome  #Use the theme "mydichrome" defined above
#mycoloropts <- myBLUETHEME #Use the theme "myBLUETHEME" defined above


#colorkey  -- set the size of the labels
myckey <- list(labels=list(cex=2)) #This makes the scale of the labels "big"

##HERE ARE SOME OPTIONS TO PASS TO PNG
png.height<-1000
png.width<-1000

## land color 
mylandfill<- "#d1d1e0"
############################




