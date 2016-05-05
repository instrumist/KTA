clear all
set more off
cd C:\QuickData

global flo=2

program common
	decode rep, gen(repd)
	decode ctryn, gen(pard)
	gen idn=repd+" and "+pard
	encode idn, gen(idm)
	xtset idm year
	la var esi "Export Similarity Index"
end

use EsiF${flo}S0, clear
	common
xtline esi if idm<3, overlay
graph export F${flo}ESIofCJK1.png, replace
xtline esi if idm>=3, overlay
graph export F${flo}ESIofCJK2.png, replace

* This graph seemingly reflects convergence of export structure among three countires

forvalues i=1/9{
use EsiF${flo}S1, clear
ren isic productcode
gen tier=length(prod)
joinby tier prod using sitc_des_sim
encode productd, gen(code)
keep if code==`i'
	common
local t : label code `i'
display "`t'"
xtline esi if idm<3, title("`t'") overlay
graph export F${flo}ESIofCJK1S`i'.png, replace
xtline esi if idm>=3, title("`t'") overlay
graph export F${flo}ESIofCJK2S`i'.png, replace
}
