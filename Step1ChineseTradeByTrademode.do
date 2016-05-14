clear all
set more off
cd C:\QuickData

* Step 1(Calculating China's ex/import w/ World, Japan, and Korea by trade mode)

use CleanedCC, clear

ren v v
keep if year==2007 | year==2011 | year==2014
keep if ctry=="World" | ctry=="Japan" | ctry=="Korea"
collapse (sum) v, by(ctry year flow trademode)
reshape wide v, i(ctry year trademode) j(flow)
reshape wide v*, i(ctry trademode) j(year)
forvalues f=1/2{
	foreach y in 2007 2011 2014{
		egen tv`f'`y'=total(v`f'`y'), by(ctry)
		replace v`f'`y'=0 if v`f'`y'==.
		gen r`f'`y'=100*v`f'`y'/tv`f'`y'
		}
	}
drop tv*
format r* %5.2f
format v* %14.0fc 
preserve

keep if ctry=="World"
drop ctry
order trademode v1* r1* v2* r2*
export excel China_Trademode.xlsx, firstrow(variables) replace
