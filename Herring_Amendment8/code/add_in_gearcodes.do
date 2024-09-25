/***********************   
This is a bit of code that classifies each
"tripid-species" into 3 areas:
Mid-atlantic (MA), New England (NE) and Null (00) based on the carea reported in the corresponding "gearids"
    "MA" : carea >= 600 & carea < 700
    "NE" : carea >= 464 & carea <600
is can be joined to the "veslog_species_huge.dta" or "veslog_species.dta" datsets using

merge 1:m tripid myspp using "veslog_species_huge.dta"

you should expect some _merge=1 and no _merge=2.  This is because a larger set of data was extracted for the 

***************************/
#delimit;
clear;
pause off;

cd "/home/mlee/Documents/projects/spacepanels/scallop/spatial_project_10192017";

cd "/home/mlee/Documents/Herring_PDT_work/Amendment8/round4";

quietly do "/home/mlee/Documents/Workspace/technical folder/do file scraps/odbc_connection_macros.do";
global oracle_cxn "conn("$mysole_conn") lower";

global firstyr 2010;
global lastyr 2017;


/* make a table of nespp3 and 4 */
#delimit;
tempfile nespp34;
odbc load, exec("select distinct nespp3, nespp4, sppcode from vlsppsyn;") $oracle_cxn;   
destring, replace ;
renvarlab, lower ;
duplicates drop (sppcode), force  ;
save `nespp34', replace ;
clear; 


clear ;
forvalues yr=$firstyr/$lastyr{ ;
	tempfile add;
	local CAREAS1`"`CAREAS1'"`add'" "'  ;
	clear;
	odbc load, exec("select t.permit, to_char(g.tripid) as tripid, to_char(g.gearid) as gearid, t.state1, g.gearcode, s.qtykept, s.sppcode, g.carea from vtr.veslog`yr't t, vtr.veslog`yr's s, vtr.veslog`yr'g g 
		where g.gearid=s.gearid and t.tripid=g.tripid
		and s.dealnum not in ('99998', '1', '2', '5', '7', '8') and s.qtykept>=1 and s.qtykept is not null;") $oracle_cxn;   
	gen dbyear= `yr';
	quietly save `add';
};
	dsconcat `CAREAS1';
	renvarlab, lower;
	destring, replace;
	compress;

drop if inlist(sppcode, "WHAK","HAKNS","RHAK","WHAK","SHAK","HAKOS","WHB");
collapse (sum) qtykept, by(gearid tripid sppcode carea state1 dbyear gearcode );

save extra.dta, replace;


/***********drop hake and add recalssified velsog query**************/
clear ;
quietly forvalues yr=$firstyr/$lastyr{ ;
	tempfile new6;
	local hake `"`hake'"`new6'" "'  ;
	clear;
	odbc load, exec("select  g.gearid, s.qtykept as qtykept, s.sppcode, s.dealnum, t.state1, t.portlnd1, t. permit, t.port, t.tripid, trunc(nvl(s.datesold, t.datelnd1)) as datesell,
		 g.mesh, g.gearqty, g.gearcode, g.carea from vtr.veslog`yr's s, vtr.veslog`yr'g g, vtr.veslog`yr't t
	where t.tripid=s.tripid  and (t.tripcatg=1 or t.tripcatg=4) and g.gearid=s.gearid
	and s.dealnum not in ('99998', '1', '2', '5', '7', '8')  and s.qtykept>=1 and s.qtykept is not null
	and sppcode in ('WHAK','HAKNS','RHAK','WHAK','SHAK','HAKOS','WHB');")  $oracle_cxn;   
	quietly count;
	scalar pp=r(N);
	if pp==0{;
		set obs 1;
	};
	else{;
	};
	gen dbyear= `yr';
	quietly save `new6';
};
	dsconcat `hake';
	drop if qtykept==.;
	renvarlab, lower;
	destring, replace;
	compress;

replace sppcode="SHAK" if sppcode=="WHAK" & mesh<=3.5 ;
replace sppcode="SHAK" if sppcode=="HAKOS" | sppcode=="WHB"  ;
drop mesh gearqty;
collapse (sum) qtykept, by(gearid tripid sppcode carea state1 dbyear gearcode );



append using "extra.dta";
save "extra.dta", replace;


/***********Deal with WOLFFISHES ('CAT') and ACADIAN REDFISH ('RED').  There is mis-reporting of some catfish as "WOLFFISH".  We will use the rule that only 'CAT' that is caught in a carea<=599 is actually WOLF.
EVERYTHING ELSE IS ASSUMED TO BE MISREPORTED. We need to handle YEARS where no 'CAT' are landed, since STATA really complains about stacking empty datasets.  I handled this with an if there are no obs, 
set the number of obs=1.  Then later we drop any observations that have missing sppcodes.

There is a little bit of this problem with White Perch being encoded as Ocean Perch (Redfish).  The same carea rule will be used.

  **************/
clear ;
forvalues yr=$firstyr/$lastyr{ ;
	tempfile newWOLF;
	local WOLF `"`WOLF'"`newWOLF'" "'  ;
	clear;
	odbc load, exec("select  g.gearid, sum(s.qtykept) as qtykept, s.sppcode, s. dealnum, g.gearcode, t.state1, t.portlnd1, t. permit, t.port, t.tripid, trunc(nvl(s.datesold, t.datelnd1)) as datesell, g.carea from vtr.veslog`yr's s, vtr.veslog`yr't t, vtr.veslog`yr'g g 
		where t.tripid= s.tripid and t.tripid=g.tripid and g.gearid=s.gearid and (t.tripcatg=1 or t.tripcatg=4) and g.carea between 400 and 599
			and s.dealnum not in ('99998', '1', '2', '5', '7', '8')  and s.qtykept>=1 and s.qtykept is not null
			and s.sppcode in ('CAT', 'RED')    
			group by s.sppcode,  g.gearid, t.state1, t.portlnd1, s.dealnum, t. permit, t.port, g.gearcode, t.tripid, trunc(nvl(s.datesold, t.datelnd1)), g.carea;")  $oracle_cxn;   
	quietly count;
	scalar pp=r(N);
	if pp==0{;  
		set obs 1;
	};
	else{;
	};
	gen dbyear= `yr';
	quietly save `newWOLF';
};
	dsconcat `WOLF';
	renvarlab, lower;
	destring, replace;
	compress;
	drop if strmatch(sppcode,"")==1;
	
collapse (sum) qtykept, by(gearid tripid sppcode carea state1 dbyear gearcode );


append using "extra.dta";
save "extra.dta", replace;


