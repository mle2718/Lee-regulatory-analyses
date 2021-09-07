/*****************************************************/
/*
This is a small piece of code to graph gross revenue as a function of landings.  
An equation from prices comes from 

/$analysis_code/annual_price_regression.do

and is copied in below


*/
/*****************************************************/
version 16.1
clear
set scheme s2mono

/*

. ivregress 2sls pricemt_realGDP (landings=l1.landings), first;


-----------------------

                                                Number of obs     =         17
                                                F(   1,     15)   =      29.57
                                                Prob > F          =     0.0001
                                                R-squared         =     0.6635
                                                Adj R-squared     =     0.6410
                                                Root MSE          =    16.7516

------------------------------------------------------------------------------
    landings |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
    landings |
         L1. |   .9654579   .1775325     5.44   0.000     .5870563     1.34386
             |
       _cons |  -2.511697   14.17393    -0.18   0.862    -32.72271    27.69932
------------------------------------------------------------------------------


Instrumental variables (2SLS) regression          Number of obs   =         17
                                                  Wald chi2(1)    =      88.00
                                                  Prob > chi2     =     0.0000
                                                  R-squared       =     0.8607
                                                  Root MSE        =     57.234

------------------------------------------------------------------------------
pricemt_re~P |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
    landings |  -5.893482    .628265    -9.38   0.000    -7.124858   -4.662105
       _cons |   815.0201    46.9175    17.37   0.000     723.0635    906.9767
------------------------------------------------------------------------------



*/

/* pass in the coefficients */

global cons 815.0201
global beta_land -5.893482


/* find the landings that maximize revenue and the maximized value of revenues*/
global lmax=-1*$cons/(2*$beta_land)
global ymax= ($cons + $beta_land*$lmax)*$lmax/1000

/*graph options */
/* upper bound for the range of x to graph */
local  x_upper=2*$lmax
local axis_opts ylabel(0(5)30) xlabel(0(25)150)  xmtick(##5)
local add_line_options  xline($lmax) text(29.4 $lmax "  Maximum Revenue", size(vsmall) placement(e))






twoway function y=($cons + $beta_land*x)*x/1000, range(0 `x_upper') xtitle("Landings (000mt)") ytitle("Predicted Revenues (Million USD)") `axis_opts' `add_line_options'

graph export "${my_images}/graph_predicted_rev.png", as(png) replace












