clear all
set more off
cd C:\QuickData

global flo=1

*Step4-1 Plotting trade structure of CJK
*Warning! Step 4 should be executed beforehand(tradeflow & depth of SITC is also dependent)

use temp_CJK, clear
append using temp_CHN
encode ctry, gen(ctryn)
collapse (sum) v, by(prod ctryn year)
drop if prod=="N"
	preserve

	gen tier=length(prod)
	joinby tier prod using sitc_des_sim
	keep productcode productd
		compress
		duplicates drop
	sort productcode
	encode productcode, gen(cnt)
	su cnt
	local m=`r(max)'
	forvalues i=1/`m'{
	global l`i'=productd[`i']
	}
	restore
	
encode prod, gen(cnt)
drop prod
replace v=v*.000001
reshape wide v, i(ctryn year) j(cnt)

forvalues i=1/`m'{
local temp="${l`i'}"
la var v`i' "`temp'"
}
drop v10
graph bar (asis) v*, over(year, label(labsize(vsmall))) stack ytitle(Billion USD) ylabel(, labsize(vsmall)) legend(cols(3) size(small)) by(ctryn)
graph export F${flo}StructureCJK.png, replace
graph bar (asis) v*, over(year, label(labsize(vsmall))) percentages stack ytitle(per cent) ylabel(, labsize(vsmall)) legend(cols(3) size(small)) by(ctryn)
graph export F${flo}StructureCJKinPC.png, replace
