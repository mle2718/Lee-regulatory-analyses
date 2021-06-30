
/* annual prices and revenue */
do "${analysis_code}/annual_revenue_grapher.do""


/* utilization */

do "${analysis_code}/utilization_grapher.do""


/* prices */

do "${analysis_code}/price_grapher.do""

/* predict prices 2019 and average 

dont think this is needed*/

do "${analysis_code}/prices2019.do""


do "${analysis_code}/average_prices.do""

graph close _all