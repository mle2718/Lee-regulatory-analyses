
/*describe all firms permitted for herring */
do "${analysis_code}/RFA/FW9_RFAanalysis_count_all_firms.do"

/*describe the ABCE firms */
do "${analysis_code}/RFA/FW9_RFAanalysis_count_ABCE_firms.do"


/*describe the active ABCE firms */
do "${analysis_code}/RFA/FW9_RFAanalysis_count_active_ABCE_firms.do"



/*describe active firms permitted for herring */
do "${analysis_code}/RFA/FW9_RFAanalysis_count_active_firms.do"




/*describe changes in revenues
requires A1_rebuild_analysis.do to have been done already

do "${analysis_code}/RFA/FW9_RFAanalysis_projections.do"
 */
 
 set scheme s2color
 

 /*Revenue changes for All firms (Tier 1)*/
do "${analysis_code}/RFA/FW9_RFAanalysis_all_firms_revenue_change.do"


/*Revenue changes for  ABCE firms (Tier 2)*/
do "${analysis_code}/RFA/FW9_RFAanalysis_ABCE_firms_revenue_change.do"
 

/*Revenue changes for Active ABCE firms (tier 3)*/
do "${analysis_code}/RFA/FW9_RFAanalysis_active_ABCE_firms_revenue_change.do"


 /*Revenue changes for Active firms (not presented)*/
do "${analysis_code}/RFA/FW9_RFAanalysis_active_firms_revenue_change.do"
