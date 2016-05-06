* 세계시장에서의 경합도가 어떻게 변했는가, 상호간 제외할 경우

clear all
set more off
cd C:\QuickData

use CleanedComtrade_imp, clear
keep if flow==1
drop if year==2015
ren par ctry
keep if ctry=="KOR" | ctry=="CHN" | ctry=="JPN"
drop if rep=="EUN"
drop if rep=="KOR" | rep=="CHN" | rep=="JPN" // inserted clause for excluding mutual trade
collapse (sum) v, by(year ctry hs)
duplicates drop

reshape wide v, i(hs year) j(ctry) string
foreach x in CHN JPN KOR{
replace v`x'=0 if v`x'==.
egen vt`x'=total(v`x'), by(year)
gen r`x'=100*v`x'/vt`x'
}
gen eCJ=min(rC,rJ)
gen eCK=min(rC,rK)
gen eJK=min(rJ,rK)
collapse (sum) e*, by(year)
twoway (line eCJ year, sort)
line eCJ eCK eJK year
