
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