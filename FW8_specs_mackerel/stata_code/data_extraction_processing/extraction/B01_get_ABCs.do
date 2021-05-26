/* code to get and read in ABC's from derobas folder. */

global subfolder "2021 Rebuild Projections"
global deroba_full "${network_location_desktop}/$jderobafolder/$subfolder"


/*
The only two alternatives at this point are
 "7yrFconstant" with assumed average recruitment "F_CONSTANT_SEVENYR_REBUILD_STAGE"
 "ABC CR" with assumed average recruitment, "F40_ABC_CR_10YRFIXED_REBUILD_2BRG"
 
 
  "7yrFconstant" with AR recruitment instead of average "F_CONSTANT_SEVENYR_REBUILD_AR_STAGE"
 "ABC CR" with AR recruitment instead of average, "F40_ABC_CR_10YRFIXED_REBUILD_AR_2BRG"

  Any folder name ending in "...AVG_IN_AR" uses the projected catches based on assuming average recruitment in a projection where AR recruitment actually occurs;
  and visa versa for "...AR_IN_AVG".

Except for the "AVG_IN_AR" or "AR_IN_AVG" folders, the file you need ends with "...12.xx6". 

for the "AVG_IN_AR" or "AR_IN_AVG" folders, the file you need ends with "...13.xx6". 


Number of columns = number of years, with the first column being 2020.  

The number of rows = the number of stochastic realizations (I think = 1000).  

The values equal the ABCs. 

*/

