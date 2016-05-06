clear all
set more off
cd C:\QuickData

global lev=1 // KEY parameter

*Converting HS to SITC and filtering specific industry
program Filtering
	gen type=12 if year>=2012
	replace type=7 if type==.
	capture merge m:1 hs type using hs_sitc4, assert(match) keep(match)
	keep if _merge==3
	gen productcode=substr(sitca,1,$lev)
	keep if prod=="7"
	drop _merge sitc* type prod
end

*Preparing world demand(execpt China) as a control variable
use CleanedComtrade_imp, clear
keep if par=="CHN" | par=="WLD"
drop if rep=="EUN"
keep if flow==1
replace hs=substr(hs,1,6)
collapse (sum) v, by(year par hs)
reshape wide v, i(hs year) j(par) string
replace vC=0 if vC==.
replace vW=vW-vC

*Ratio options
*egen vtw=total(vW), by(year)
*gen rw=vW/vtw

*Log options
gen rw=log(vW*1000)
replace rw=1 if rw==.

keep year hs rw
save tempWorld, replace
*/

*Impact of China's import(by country or world) on its export
use CleanedCC, clear
ren v v
gen mode="P" if t==14|t==15|t==33|t==34 // Trademode
replace mode="O" if mode==""
replace hs=substr(hs,1,6)
collapse (sum) v, by(ctry hs flow mode year)
	Filtering
reshape wide v, i(ctry hs year flow) j(mode) string
replace vO=0 if vO==.
replace vP=0 if vP==.
gen vT=vO+vP
foreach x in O P T{
*Ratio options
*egen vt`x'=total(v`x'), by(year flow ctry)
*gen r`x'=v`x'/vt`x'

*Log options
gen r`x'=log(v`x'*1000)
replace r`x'=1 if r`x'==.
}
keep  year flow hs ctry r*
reshape wide rO rP rT, i(hs year ctry) j(flow)
reshape wide rO1 rO2 rP1 rP2 rT1 rT2, i(hs year) j(ctry) string
forvalues f=1/2{
	foreach x in Germany Korea Japan Taiwan USA World{
		foreach t in O P T{
			replace r`t'`f'`x'=0 if r`t'`f'`x'==.
			}
		}
	}
joinby hs year using tempWorld
encode hs, gen(productcode)
xtset prod year
tab year, gen(year_dum)

*Result
*Save : Log opt. T P W J/K  W/U/G:ineffective for ind==7, J/K도 O가 T에 미치는 영향 X

*Criteria
local em T
local im P
local ec W
local ic K

reg r`em'2`ec' L.r`em'2`ec' L(1/3).r`im'1`ic' year_dum*
xtreg r`em'2`ec' L.r`em'2`ec' L(1/3).r`im'1`ic' year_dum*, fe
xtabond2 r`em'2`ec' L.r`em'2`ec' L(1/3).r`im'1`ic' year_dum*, gmm(L.r`em'2`ec') iv(L(1/3).r`im'1`ic' year_dum*) nolevel robust small

*W/ contol variable
reg r`em'2`ec' L.r`em'2`ec' L(1/3).r`im'1`ic' L(1/3).rw year_dum*
xtreg r`em'2`ec' L.r`em'2`ec' L(1/3).r`im'1`ic' L(1/3).rw year_dum*, fe
xtabond2 r`em'2`ec' L.r`em'2`ec' L(1/3).r`im'1`ic' L(1/3).rw year_dum*, gmm(L.r`em'2`ec') iv(L(1/3).r`im'1`ic' L(1/3).rw year_dum*) nolevel robust small

/*
xtabond2 rT2W L(1/2).rT2W L(0/2).rT1W year_dum*, gmm(L.rT2W) iv(L(0/2).rT1W year_dum*)

*World total import to the total export
xtabond2 rT2W L.rT2W L(1/3).rT1W year_dum*, gmm(rT2W rT1W, lag(1 3))
xtreg rT2W L.rT2W L(1/3).rT1W year_dum*, fe

*World pro. import to the pro. export
xtabond2 rP2W L.rP2W L(1/3).rP1W year_dum*, gmm(rT2W rT1W, lag(1 3))
xtreg rP2W L.rP2W L(1/3).rP1W year_dum*, fe

*World ori. import to the ori. export
xtabond2 rO2W L.rO2W L(1/3).rO1W year_dum*, gmm(rT2W rT1W, lag(1 3))
xtreg rO2W L.rO2W L(1/3).rO1W year_dum*, fe

*World pro. import to the ori. export
xtabond2 rO2W L.rO2W L(1/3).rP1W year_dum*, gmm(rT2W rT1W, lag(1 3))
xtreg rO2W L.rO2W L(1/3).rP1W year_dum*, fe

*World ori. import to the pro. export
xtabond2 rP2W L.rP2W L(1/3).rO1W year_dum*, gmm(rT2W rT1W, lag(1 3))
xtreg rP2W L.rP2W L(1/3).rO1W year_dum*, fe
