clear all
set more off
cd C:\QuickData

*Preparing world demand(execpt China) as a control variable
use CleanedComtrade_imp, clear
keep if par=="CHN" | par=="WLD"
drop if rep=="EUN"
keep if flow==1
collapse (sum) v, by(year par hs)
reshape wide v, i(hs year) j(par) string
replace vC=0 if vC==.
replace vW=vW-vC
egen vtw=total(vW), by(year)
gen rw=vW/vtw
keep year hs rw
save tempWorld, replace

*Impact of China's import from world to China's export
use CleanedCC, clear
keep if ctry=="World"
ren v v
replace hs=substr(hs,1,6)
collapse (sum) v, by(hs year flow)
egen vt=total(v), by(year flow)
gen r=v/vt
keep year flow hs r
reshape wide r, i(hs year) j(flow)
joinby hs year using tempWorld
replace r1=0 if r1==.
replace r2=0 if r2==.

encode hs, gen(productcode)
xtset prod year
tab year, gen(year_dum)
xtreg r1 L.r1 L(1/3).r2 year_dum*, fe
xtreg r1 L.r1 rw L(1/3).r2 year_dum*, fe

*capture qui xtabond2 rEXP L.rEXP L(1/3).r`pname' year_dum*, gmm(rEXP r`pname', lag(1 3))
