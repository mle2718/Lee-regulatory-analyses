cd "/home/mlee/Documents/Workspace/technical folder/do file scraps"
quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do"
#delimit;
global oracle_cxn "conn("$mysole_conn") lower";
/* ORACLE SQL IN UBUNTU using Stata's connectstring feature.*/

#delimit ;
/* LOOPS OVER A QUERY from SOLE */
forvalues myy=2010/2015{;
	tempfile new;
	local NEWfiles `"`NEWfiles'"`new'" "'  ;
	clear;

	odbc load,  exec("	odbc load,  exec("SELECT sum(sppvalue) as value, sum(spplndlb) as landings FROM cfders`yr' 
		where nespp3=168") conn("`mysole_conn'") lower;") $oracle_cxn;

	gen dbyear= `myy';
	quietly save `new';
};

dsconcat `NEWfiles';
	renvarlab, lower;

