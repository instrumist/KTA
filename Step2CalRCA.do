clear all
set more off
cd C:\QuickData

global lev=1 // KEY parameter

* Functions
program exporting_rca
	reshape wide rca, i(ctry prod) j(year)
	gen tier=length(prod)
	joinby tier prod using sitc_des
	compress
	keep ctry productd r*
	order ctry productd r*
end

program preprocessing
	keep if flow==2
	gen type=7
	replace type=12 if year>=2012
	capture merge m:1 hs type using hs_sitc4, assert(match) keep(match)
	keep if _merge==3
	gen productcode=substr(sitca,1,$lev)
	ren rep ctry
	collapse (sum) v, by(year ctry prod)
end

* Step 2(Calculating RCA of CJK, plus China w/o export by processing trade)
use CleanedCC, clear
keep if ctry=="World"
replace ctry="CHN(P)" if t==14|t==15|t==33|t==34
replace ctry="CHN(O)" if ctry=="World"
replace hs=substr(hs,1,6)
ren ctry rep
ren v v
	preprocessing
save temp_CHN, replace

use CleanedComtrade_exp, clear
drop if year==2015
	preprocessing
preserve

* Generating world
collapse (sum) v, by(year prod)
ren v wv
egen wt=total(wv), by(year)
save temp_world, replace

* Generating CJK
restore, preserve
keep if ctry=="KOR" | ctry=="CHN" | ctry=="JPN"
save temp_CJK, replace

* Generating ctry grps by income level
restore
joinby ctry using worldbank2015
replace ctry=income
collapse (sum) v, by(year ctry  prod)

append using temp_CJK temp_CHN
joinby prod year using temp_world

egen vt=total(v), by(year ctry)
gen rca=(v/vt)/(wv/wt)
format rca %5.2f
keep ctry year prod rca
save inter_result, replace
preserve

* RCA of CJK
keep if length(ctry)<8
exporting_rca
export excel RCA_result.xlsx, sheet(CJK_$lev) firstrow(var) sheetreplace
save rca_CJK, replace

* RCA by income level
restore
keep if length(ctry)>=8
exporting_rca
export excel RCA_result.xlsx, sheet(Income_$lev) firstrow(var) sheetreplace
save rca_income, replace
