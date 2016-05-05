clear all
set more off
cd C:\QuickData

local level=1 // KEY parameter

* Plotting graphs - a: extracting matching code
use inter_result, clear
encode ctry, gen(c)
keep c*
duplicates drop
sort c
su c
local m=`r(max)'
forvalues i=1/`m'{
global l`i'=ctry[`i']
}
use inter_result,clear
encode ctry, gen(c)
drop ctry

reshape wide r, i(pro year) j(c)
forvalues i=1/`m'{
local temp="${l`i'}"
la var rca`i' "`temp'"
}
gen tier=length(prod)
joinby tier prod using sitc_des
	compress
format rca* %4.0f
drop if productc=="9"
line rca4 rca5 rca8-rca10 year, by(productc)
graph export RcaByIncomeS`level'.png, replace
line rca1 rca6 rca7 year, by(productc)
graph export RcaByCountyS`level'.png, replace
line rca1-rca3 year, by(productc)
graph export RcaChinaByModeS`level'.png, replace

format rca* %4.1f
encode productd, gen(code)
su code
forvalues i=1/`r(max)'{
local t : label code `i'
display "`t'"
line rca4 rca5 rca8-rca10 year if code==`i', title("`t'")
graph export RcaByIncomeS`level'Lev`i'.png, replace
line rca1 rca6 rca7 year if code==`i', title("`t'")
graph export RcaByCountyS`level'Lev`i'.png, replace
line rca1-rca3 year if code==`i', title("`t'")
graph export RcaChinaByModeS`level'Lev`i'.png, replace
}
