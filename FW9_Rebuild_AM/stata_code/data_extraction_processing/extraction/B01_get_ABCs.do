version 16.1
clear
/* code to copy over the ABC's from derobas folder.

You've mapped his /work2/jderoba to X */

global subfolder "Herring/2021 Rebuild Projections"
global deroba_full "X://$subfolder"

/* look up the directories in his folder */
local mm: dir "$deroba_full" dirs "*", respectcase

/* Look through for the *12.xx6 files and copy them down to your computer*/
foreach folder of local mm{
	local getme 
	local getme : dir "$deroba_full/`folder'" files "*12.xx6", respectcase
	local getme :subinstr local getme `"""' "", all
	local f  $deroba_full/`folder'/`getme'
	

	
	if "`getme'"!=""{
		di "getting `f'"
		! cp "`f'" "$data_raw"
	} 
	else{
		di "no matching file in ${deroba_full}/`folder'"
	}
}

/* Look through for the *13.xx6 files and copy them down to your computer*/


foreach folder of local mm{
	local getme 
	local getme : dir "$deroba_full/`folder'" files "*13.xx6", respectcase
	local getme :subinstr local getme `"""' "", all
	local f  $deroba_full/`folder'/`getme'
	

	
	if "`getme'"!=""{
		di "getting `f'"
		! cp "`f'" "$data_raw"
	} 
	else{
		di "no matching file in ${deroba_full}/`folder'"
	}
}

filelist, directory("$data_raw") pattern("*.xx6") save ("${data_raw}/simfileslist_${vintage_string}.dta") replace



