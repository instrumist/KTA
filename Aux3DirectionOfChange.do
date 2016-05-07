clear all
set more off
cd C:\QuickData

global lev=1

*변화가 가장 큰 sector 를 찾아내기! (가장 작은 sector도)
*Effect of (processing) import on Structural change(export), then which country's model is most likely?
*산업구조 변화와 (processing)수입의 관계
*Similarity

* Functions
program exporting_rca
	reshape wide rca, i(ctry prod) j(year)
	gen tier=length(prod)
	joinby tier prod using sitc_des
	compress
	keep ctry productd r*
	order ctry productd r*
end

program matching
	gen type=7
	replace type=12 if year>=2012
	capture merge m:1 hs type using hs_sitc4, assert(match) keep(match)
	keep if _merge==3
	gen productcode=substr(sitca,1,$lev)

	keep if productcode=="7"
	drop prod* _merge type
	*ren rep ctry
	*egen vt=total(v), by(year ctry prod)
	*collapse (sum) v, by(year ctry prod)
end

* Step 2(Calculating RCA of CJK, plus China w/o export by processing trade)
use CleanedCC, clear
keep if ctry=="World"
replace ctry="CHN_P" if t==14|t==15|t==33|t==34
replace ctry="CHN_O" if ctry=="World"
replace hs=substr(hs,1,6)
ren v v
collapse (sum) v, by(ctry hs flow year)
replace ctry=ctry+string(flow)
drop flow
save temp_CHN, replace

use CleanedComtrade_exp, clear
keep if year<2015 & flow==2
ren rep ctry
keep if ctry=="KOR" | ctry=="CHN" | ctry=="JPN"
collapse (sum) v, by(year ctry hs)
save temp_CJK, replace

use CleanedComtrade_exp, clear
keep if year<2015 & flow==2
ren rep ctry
joinby ctry using worldbank2015
replace ctry=income
collapse (sum) v, by(year ctry hs)
save temp_income, replace

use CleanedComtrade_exp, clear
keep if year<2015 & flow==2
collapse (sum) v, by(year hs)
gen ctry="WLD"
append using temp_CJK temp_CHN temp_income

matching
*matching can be inserted

egen vt=total(v), by(ctry year)
gen r=v/vt
drop v*
replace ctry="HI_OECD" if ctry=="High income: OECD"
replace ctry="HI_NOECD" if ctry=="High income: nonOECD"
replace ctry="LI" if ctry=="Low income"
replace ctry="UMI" if ctry=="Upper middle income"
replace ctry="LMI" if ctry=="Lower middle income"

save tempResult, replace
reshape wide r, i(year hs) j(ctry) string

foreach x in CHN KOR JPN WLD HI_OECD HI_NOECD LI UMI LMI CHN_P1 CHN_P2 CHN_O1 CHN_O2{
replace r`x'=0 if r`x'==.
}
foreach x in KOR JPN WLD HI_OECD HI_NOECD LI UMI LMI{
	foreach y in KOR JPN CHN CHN_P1 CHN_P2 CHN_O1 CHN_O2{
gen etp`y'`x'=r`y'*ln(r`y'/r`x')
replace etp`y'`x'=0 if etp`y'`x'==.
}
}
collapse (sum) etp* ,by(year)

line etpCHNWLD etpCHN_P2WLD etpCHN_O2WLD etpKORWLD etpJPNWLD year
line etpCHNHI_OECD etpCHN_P2HI_OECD etpCHN_O2HI_OECD etpKORHI_OECD etpJPNHI_OECD year

*Aboves plots show decoupling of China's processing export and ordinary export

line etpCHNUMI etpCHN_P2UMI etpCHN_O2UMI etpKORUMI etpJPNUMI year
