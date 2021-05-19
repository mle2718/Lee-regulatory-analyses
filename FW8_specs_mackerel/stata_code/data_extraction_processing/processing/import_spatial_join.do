global codedir "/home/mlee/Documents/Herring_PDT_work/fw6/code"
global datadir "/home/mlee/Documents/Herring_PDT_work/fw6/data"
global outputdir "/home/mlee/Documents/Herring_PDT_work/fw6/outputs"



import delimited "$datadir/gis/herrring_spatial_join4.csv", clear 

keep my_id garfo_id commname areaname 
rename commname hma_comm

save "$datadir/gis/herring_spatial_join4.dta", replace
