###### This script pulls all queries rasters and sums them
###### creating a heat-map for any subset of VTR data.

FIELD = "QTYKEPT" #Like "REVENUE","QTYKEPT", "QTYDISC", or "CATCH"
#SET margin to sum over
MARGIN = c("MY_MARGIN") #Like "SPPNM","NESPP3","GEARCAT","FMP","STATE1" Comment out if want to sum over all margins in a year




logical_subset<-quote(which(FINAL$NESPP3 %in% c(168)))
readable_name ="herring"
my_margin_name<-quote(paste(FINAL$MONTH,readable_name, sep="_"))

source(file.path(ML.CODE.PATH, "Step_4_generic_raster_aggregator.R"))



logical_subset<-quote(which(FINAL$NESPP3 %in% c(212)))
readable_name ="mackerel"
my_margin_name<-quote(paste(FINAL$MONTH,readable_name, sep="_"))

source(file.path(ML.CODE.PATH, "Step_4_generic_raster_aggregator.R"))
