pause off

/* annual prices and revenue */
do "${analysis_code}/annual_revenue_grapher.do"


/* utilization */

do "${analysis_code}/utilization_grapher.do"


/* prices */

do "${analysis_code}/price_grapher.do"

graph close _all

do "${analysis_code}/prices/A0_annual_price_regression.do"


do "${analysis_code}/prices/A1_monthly_price_regression.do"


