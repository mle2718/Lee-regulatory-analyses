
/* annual prices and revenue */
do "${analysis_code}/annual_revenue_grapher.do"


/* utilization */

do "${analysis_code}/utilization_grapher.do"


/* prices */

do "${analysis_code}/price_grapher.do"

/* predict prices 2019 and average 

dont think this is needed*/

do "${analysis_code}/prices2019.do"


do "${analysis_code}/average_prices.do"

graph close _all

do "${analysis_code}/rebuild_analysis/annual_price_regression.do"


do "${analysis_code}/rebuild_analysis/A1_rebuild_analysis.do"
do "${analysis_code}/rebuild_analysis/A3_rebuild_analysis_mean_ABCs.do"


/*needs to go after the rebuild_mean */
do "${analysis_code}/rebuild_analysis/A2_rebuild_annual_revenues.do"

do "${analysis_code}/rebuild_analysis/A4_rebuild_analysis_stacked.do"


do "${analysis_code}/rebuild_analysis/A5_graph_predicted_rev.do"
