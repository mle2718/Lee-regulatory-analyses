# This is simply a table of contents/key file that describes the R scripts in this folder.


# STEP 4: This step subsets all the rasters and aggregates them in a moderately flexible way.

# Step_4_generic_raster_aggregator.R -- this file does as much of the heavy lifiting. 
#    It subsets the "FINAL" dataset, picks up the relevant field, and constructs an aggregated raster.
# 
# 
# Step4_herring.R  Herring pounds, all gears. 1996-2018. MM_QTYKEPT_herring_YYYY into FW7_initial_date. 
# Step4_herring_noPUR.R Herring pounds, EXCLUDES Purse Seine. 2008-2018. MM_QTYKEPT_herringnoPUR_YYYY into FW7_initial_date. 
# Step4_herring_rev.R Herring revenue, all gears. 1996-2018. MM_REVENUE_herring_YYYY into FW7_initial_date.
# 
# Step4_hrg_mack_rev.R Herring & Mackerel revenue, all gears combined. 1996-2018. MM_REVENUE_herring_YYYY into FW7_initial_date.
# 
# Step4_mackerel.R -- Mackerel pounds. 1996-2018. MM_QTYKEPT_mackerel_YYYY into FW7_initial_date. Month is not zero-padded
# Step4_mack_rev.R Mackerel revenue 1996-2018. MM_QTYKEPT_mackerel_YYYY into FW7_initial_date. 

# Step4_nonhrg_mack.R -- all revenue that is not herring or mackerel. 


# STEP 5: This step takes the output of step 4 and aggregates further, saving the geotiffs.

# Step5_aggregate_hermack.R  Aggregate  herring+mackerel revenue into total monthly revenue across 2 regimes. 2008-2015 and 2016-2018
# Step5_aggregate_herring.R  Aggregate  herring revenue into total monthly revenue across 2 regimes. 2008-2015 and 2016-2018
# 
# Step5_aggregate_herringnoPUR.R  Aggregate  herring (non Purse Seine) into total monthly revenue across 2 regimes. 2008-2015 and 2016-2018
# 
# 
# Step5_aggregate_herringother.R Aggregate  other revenue into total monthly revenue across 2 regimes. 2008-2015 and 2016-2018
# 




 
# Step5_background_all_gears_monthly.R  
# 
#These all look into a folder containing geotiffs produced in Step5.  It makes maps of aggregations, parsing on the filenames.
# Step6_illustrate_background_regimes.R
# Step6_illustrate_background_trimmed_rescaled.R <-- this may be a leftover.
# Step6_illustrate_herring_background.R  <-make maps of herring
# 

# This checks confidentiality.
# Step7_check_confidentiality.R: Check rasters for the rule of 3.  rebins when this doesn't hold. creates new (reclassified) rasters and new images.

  #Depends on 
# Step7A_confidentiality_setup.R  -- setup raw data
# confid_match_subset_mod.R keeps just the rasters that I need.  There is some  hard-coding here that I'm not excited about.
# production_confidential_checker. R -- actually does the confid check




# Plan -- I need to set up a slightly different aggregation in step 5.  
#  We need to condense months, but aggregate across a slightly different regime of years
