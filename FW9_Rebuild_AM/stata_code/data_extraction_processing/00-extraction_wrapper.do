
/* external data */
do "$extraction_code/extractZ01_external_data_FRED.do"



/* only do this 1 time */
do "$extraction_code/B01_get_ABCs.do"
do "$extraction_code/B02_readin_ABCs.do"



/*
/* 
pulls data out of oracle and constructs a datset of prices. No depends.

Ran properly */

do "$extraction_code/A01price_maker2.do"



do "$extraction_code/A02permits.do"
/* 
pulls data out of oracle and constructs a datset of herring permits with their categories.  Does not handle the DE vessels properly 
Depends on nothing.

Ran properly, created 1x observation per permit-year
*/

/*monthly prices and landings */
do "$extraction_code/A04herring_monthly_prices_quantities.do"

do "$extraction_code/A03extracting_loop_herring_vtr2.do"
/* 
pulls data out of oracle and constructs a dataset of herring trips.
Constructs a csv containing just lat, lon, and an id that can be used in a spatial join.

Depends on prices 
Depends on herring permits

Ran properly */


/*
This should go elsewhere

/* have to do the stupid spatial join by hand */

do "$codedir/merge_gis_and_vtr.do"



do "$codedir/areas_and_categories_part2.do"
/* 
Computes herring_revenue and all revenue, by HMA and permit category 
    C's in 3 and 1B are aggregated with A.  DE is aggregated with D.
uses herring_from_vtr2.dta
uses herring_points_spatial_join2.dta */




do "$codedir/areas_and_categories.do"
/* 
Computes kept pounds, herring revenue, and number of vessels, by HMA and permit category 

uses herring_spatial_classified.dta*/




do "$codedir/areas_and_gears.do"
/* 
Computes kept pounds, herring revenue, and number of vessels, by HMA and gear category
uses herring_spatial_classified.dta */




do "$codedir/areas_and_ports.do"
/* 
Computes kept pounds, herring revenue, and number of vessels, by HMA, portlnd1, state1
uses herring_spatial_classified.dta */

/* cleanups*/
cd $datadir 
rm 

*/

*/
