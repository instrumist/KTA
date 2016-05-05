clear all
set more off
cd C:\QuickData

*Setting parameters (do lev 0 and lev 1, then run siblings of step 4)
global lev=1
global flo=2

* Functions
program preprocessing
	keep if flow==$flo
	gen type=7
	replace type=12 if year>=2012
	capture merge m:1 hs type using hs_sitc4, assert(match) keep(match)
	keep if _merge==3
	gen productcode=substr(sitca,1,$lev)
	ren rep ctry
	collapse (sum) v, by(year ctry prod hs)
end

program match
	gen code=substr(id,1,strpos(id, "_")-1)
	gen pcode=substr(id,strpos(id, "_")+1,length(id)-length(code)-1)
	
	joinby code using country_matching
	ren ctryn rep
	ren code rcode
	ren pcode code
	joinby code using country_matching
	ren code par
	keep if id=="1_4" | id=="1_5" | id=="2_4" | id=="2_5" | id=="3_4" | id=="3_5"
end

* Step 4(Calculating Intra industry trade indices, export similarity indices)
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
keep if ctry=="KOR" | ctry=="CHN" | ctry=="JPN"
save temp_CJK, replace
append using temp_CHN
encode ctry, gen(ctryn)

preserve
	keep ctr*
	duplicates drop
	gen str2 code=string(ctryn+0)
	drop ctry
	export excel using "Code_matching", sheet("country") sheetreplace
	save country_matching, replace
restore

* Renaming for code recycling
ren ctryn repn
ren hs prod
ren productcode isic 

* Convert to ratio
egen vt=total(v), by(year repn)
gen r=v*100/vt
drop v
ren r v
save temp, replace
*/

* Calculate pairwise similarity (for a nested country set)
use temp, clear
keep repn prod year isic v
su repn
scalar n=r(max)
scalar n_m1=r(max)-1
reshape wide v, i(year prod isic) j(repn)
save temp_w, replace

* ESI
use temp_w, clear
forvalues x = 1/`=n'{
	replace v`x'=0 if v`x'==.
}
forvalues x = 1/`=n'{
local z=`x'+1
	forvalues y = 1/`=n'{
		capture gen esi`x'_`y'=min(v`x',v`y')
		}
}
collapse (sum) esi* , by(year isic)
reshape long esi, i(year isic) j(id) string

match
save EsiF${flo}S${lev}, replace

* FK
use temp_w, clear
forvalues x = 1/`=n'{
	replace v`x'=0 if v`x'==.
}
forvalues x = 1/`=n_m1'{
local z=`x'+1
	forvalues y = `z'/`=n'{
		gen FKsim`x'_`y'=abs(v`x'-v`y')
		}
}
collapse (sum) FKsim* , by(year isic)

forvalues x = 1/`=n_m1'{
local z=`x'+1
	forvalues y = `z'/`=n'{
		replace FKsim`x'_`y'=1-(.5*FKsim`x'_`y')
		}
}
reshape long FKsim, i(year isic) j(id) string
match
save FKsimF${flo}S${lev}, replace
