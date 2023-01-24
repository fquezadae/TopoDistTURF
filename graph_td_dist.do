use "C:\Users\fequezad\OneDrive\UMass\Dissertation\02 TURFs Chile\Data\data_TURFS.dta", replace

collapse (mean) d_navy_jur td_navyj_km, by(id_area)
drop if d_navy_jur == . |  td_navyj_km == .
gen dif = td_navyj_km - d_navy_jur

sum dif 
**** 2.01 km

histogram td_navyj_km, frequency addplot((scatteri 100 10 0 10, recast(line) lcolor(red) ///
lwidth(medthick))) xtitle("Topographic distance to port captainship with jurisdiction (km)") ///
legend(order(1 "Frequency" 2 "Threshold (10 km)")) scheme(lean1) width(10)

graph export "C:\Users\fequezad\OneDrive\UMass\Dissertation\02 TURFs Chile\TopoDist\histogram.pdf", as(pdf) name("Graph") replace

 

