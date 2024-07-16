* 03_analysis.do
cd `"`mywd'"'
log using "./log_files/analysis.log", replace
set seed 1234

* # PROGRAMS # *
capture program drop store_scalars
program store_scalars
	args scalarstring
	scalar b`scalarstring' = `r(estimate)'
	scalar b`scalarstring'_lb = `r(lb)'
	scalar b`scalarstring'_ub = `r(ub)'
end

* # MACROS # *
local writersdepvars "writer_novel writer_original writer_rare writer_novel_index writer_appropriate writer_feasible writer_publishable writer_useful_index writer_tt_well_written writer_tt_boring writer_tt_enjoyed writer_tt_funny writer_tt_future writer_tt_twist"
local eval_creativedepvars "eval_novel eval_original eval_rare eval_novel_index eval_appropriate eval_feasible eval_publishable eval_useful_index"
local eval_emotiondepvars "eval_tt_well_written eval_tt_boring eval_tt_enjoyed eval_tt_funny eval_tt_future eval_tt_twist"
local eval_otherdepvars "eval_ai_assist eval_auth_ideas eval_ownership eval_owner_index"

local opts_main `"cells(b(star fmt(%9.3f)) se(par fmt(3))) star(+ 0.10 * 0.05 ** 0.01 *** 0.001) compress nobaselevels noomitted collabels(none) label"'
local opts_stats `"stats(N F r2_a, fmt(a2) labels(`"Observations"' `"F-Stat"' `"Adj R-squared"'))"'

* ## Color scheme ## *
* local humancolor "gs4"
* local hybridcolor "purple"
* local ai1color `""251 179 35""' /*orange*/
* local ai5color `""0 176 240""' /*blue*/
* local noconditioncolor "dknavy"
* local noideascolor `""248 0 22""' /*red*/

local humancolor "gs4"
local hybridcolor "purple"
local ai1color "blue"
local ai5color "cranberry"
local noconditioncolor "dknavy"
local noideascolor "orange"

local coefplot2opts `"keep(2.condition) mcolor(`ai1color') ciopts(color(`ai1color'))"'
local coefplot3opts `"keep(3.condition) mcolor(`ai5color') ciopts(color(`ai5color'))"'
local coefplotmainopts `"xscale(range(0)) drop(_cons) xline(0, lpattern(-) lcolor(gs4)) subtitle(, nobox margin(t+2) j(left)) grid(none) nokey coeflabels(2.condition = "Human with 1 GenAI idea" 3.condition = "Human with 5 GenAI ideas", labsize(medsmall) wrap(12))"'

local igap 0.15
local componentgap 0.10
local gap1 = -`igap' + `componentgap'
local gap2 = -`igap'
local gap3 = -`igap' - `componentgap'

local coefplot2Iopts `"offset(`igap') keep(2.condition) mcolor(`ai1color') ciopts(color(`ai1color') lwidth(thick)) msize(large)"'
local coefplot3Iopts `"offset(`igap') keep(3.condition) mcolor(`ai5color') ciopts(color(`ai5color') lwidth(thick)) msize(large)"'
local coefplot2c1opts `"offset(`gap1') keep(2.condition) mfcolor(white) mcolor(`ai1color') ciopts(color(`ai1color') lwidth(thin)) msize(small)"'
local coefplot3c1opts `"offset(`gap1') keep(3.condition) mfcolor(white) mcolor(`ai5color') ciopts(color(`ai5color') lwidth(thin)) msize(small)"'
local coefplot2c2opts `"offset(`gap2') keep(2.condition) mfcolor(white) mcolor(`ai1color') ciopts(color(`ai1color') lwidth(thin)) msize(small)"'
local coefplot3c2opts `"offset(`gap2') keep(3.condition) mfcolor(white) mcolor(`ai5color') ciopts(color(`ai5color') lwidth(thin)) msize(small)"'
local coefplot2c3opts `"offset(`gap3') keep(2.condition) mfcolor(white) mcolor(`ai1color') ciopts(color(`ai1color') lwidth(thin)) msize(small)"'
local coefplot3c3opts `"offset(`gap3') keep(3.condition) mfcolor(white) mcolor(`ai5color') ciopts(color(`ai5color') lwidth(thin)) msize(small)"'

* # Writers frame
capture frame create writers
frame change writers
use `"./`processed_folder'/creators.dta"', clear
* Drop admitted to using GenAI, 3
drop if human_admitted

* # Evaluators frame
capture frame create evaluators
frame change evaluators
use `"./`processed_folder'/evaluators_stories.dta"', clear

frlink m:1 story_id, frame(writers)
frget condition conditionAI dat used_ai writer_used_ai_tool num_ai_ideas human_admitted writer_topic, from(writers)

replace eval_profit = . if condition == "Human only":condition | (eval_ai_usage == 0) | num_ai_ideas == 0

* Drop if writer did not qualify, 81
drop if mi(writers)
bysort eval_id: egen mins = min(story_number)
la var mins "first evaluated story number"

* ## DAT interactions
frame change evaluators
su dat, d
local h_p05 = floor(`r(p5)')
local h_p95 = ceil(`r(p95)')
local atinc = round((`h_p95' - `h_p05')/10,1)
local graphinc = ceil((`h_p95' - `h_p05')/3)

foreach depvar of var `eval_creativedepvars' `eval_emotiondepvars' {
	su `depvar'
	local maxdepvar = `r(max)'
	local depvarname = subinstr("`depvar'", "writer_", "", .)
	local depvarname = subinstr("`depvarname'", "eval_", "", .)
	local depvarname = subinstr("`depvarname'", "tt_", "", .)
	local depvarname = subinstr("`depvarname'", "well_written", "well", .)
	local depvarname = subinstr("`depvarname'", "_index", "I", .)
	local depvarlabel : variable label `depvar'

	eststo C3dat_`depvarname': reg `depvar' ib1.condition##c.dat, vce(cl eval_id)
	margins, at(dat = (`h_p05'(`atinc')`h_p95')) over(condition)
	
	marginsplot, graphregion(fcolor(white)) ytitle("`depvarlabel'") legend(region(style(none)) position(6) rows(1)) title("") xtitle(`"writer DAT score"') recast(line) recastci(rarea) plot1opt(lcolor(`humancolor')) plot2opt(lcolor(`ai1color')) plot3opt(lcolor(`ai5color')) ci1opt(color(`humancolor'%7)) ci2opt(color(`ai1color'%7)) ci3opt(color(`ai5color'%7)) ylabel(0(2)6) xlabel(`h_p05'(`graphinc')`h_p95') name(C3dat_`depvarname', replace)
	
	marginsplot, graphregion(fcolor(white)) ytitle("`depvarlabel'") legend(region(style(none)) position(6) rows(1)) title("") xtitle(`"writer DAT score"') recast(line) recastci(rarea) plot1opt(lcolor(`humancolor')) plot2opt(lcolor(`ai1color')) plot3opt(lcolor(`ai5color')) ci1opt(color(`humancolor'%7)) ci2opt(color(`ai1color'%7)) ci3opt(color(`ai5color'%7)) ylabel(3(1)6) xlabel(`h_p05'(`graphinc')`h_p95') name(C3dat_`depvarname'_abr, replace)
}

* ### Supplmentary Table 10
esttab C3dat_novelI C3dat_novel C3dat_original C3dat_rare C3dat_usefulI C3dat_appropriate C3dat_feasible C3dat_publishable, `opts_main' `opts_stats'
esttab C3dat_novelI C3dat_novel C3dat_original C3dat_rare C3dat_usefulI C3dat_appropriate C3dat_feasible C3dat_publishable using "./tables_graphs/evaluators/C3dat_creativity.rtf", `opts_main' `opts_stats' replace
* ### Supplementary Table 11
esttab C3dat_well C3dat_enjoyed C3dat_funny C3dat_future C3dat_twist C3dat_boring, `opts_main' `opts_stats'
esttab C3dat_well C3dat_enjoyed C3dat_funny C3dat_future C3dat_twist C3dat_boring using "./tables_graphs/evaluators/C3dat_emotions.rtf", `opts_main' `opts_stats' replace

* Other emotions for appendix (Supplementary Figure 3)
grc1leg2 C3dat_funny C3dat_future C3dat_twist, rows(1) scheme(s1color)
graph export `"./tables_graphs/evaluators/C3dat_otheremotions.png"', replace

* ## Baseline models; writers (base)
frame change writers
foreach depvar of var `writersdepvars' {
	su `depvar'
	local maxdepvar = `r(max)'
	local depvarname = subinstr("`depvar'", "writer_", "", .)
	local depvarname = subinstr("`depvarname'", "eval_", "", .)
	local depvarname = subinstr("`depvarname'", "tt_", "", .)
	local depvarname = subinstr("`depvarname'", "well_written", "well", .)
	local depvarname = subinstr("`depvarname'", "_index", "I", .)
	local depvarlabel : variable label `depvar'

	* ### 3 conditions
	eststo base3_`depvarname': reg `depvar' ib1.condition, vce(r)
}

* ### Supplentary Table 6
esttab base3_novelI base3_novel base3_original base3_rare base3_usefulI base3_appropriate base3_feasible base3_publishable, `opts_main' `opts_stats'
esttab base3_novelI base3_novel base3_original base3_rare base3_usefulI base3_appropriate base3_feasible base3_publishable using "./tables_graphs/writers/base3_creativity.rtf", `opts_main' `opts_stats' replace
* ### Supplentary Table 8
esttab base3_well base3_enjoyed base3_funny base3_future base3_twist base3_boring, `opts_main' `opts_stats'
esttab base3_well base3_enjoyed base3_funny base3_future base3_twist base3_boring using "./tables_graphs/writers/base3_emotions.rtf", `opts_main' `opts_stats' replace

* ## Baseline models; evaluators (base)
frame change evaluators
foreach depvar of var `eval_creativedepvars' {
	su `depvar'
	local maxdepvar = `r(max)'
	local depvarname = subinstr("`depvar'", "writer_", "", .)
	local depvarname = subinstr("`depvarname'", "eval_", "", .)
	local depvarname = subinstr("`depvarname'", "tt_", "", .)
	local depvarname = subinstr("`depvarname'", "well_written", "well", .)
	local depvarname = subinstr("`depvarname'", "_index", "I", .)
	local depvarlabel : variable label `depvar'

	* ### 2 conditions
	eststo base2_`depvarname': reg `depvar' i.conditionAI, vce(cl eval_id)
	lincom _cons
	store_scalars human
	lincom _cons + 1.condition
	store_scalars hybrid

	* ### 3 conditions
	eststo base3_`depvarname': reg `depvar' ib1.condition, vce(cl eval_id)
	test 2.condition = 3.condition
	lincom _cons
	store_scalars human
	lincom _cons + 2.condition
	store_scalars AI1
	lincom _cons + 3.condition
	store_scalars AI5
}

* ### Supplementary Table 3
esttab base2_novelI base2_novel base2_original base2_rare base2_usefulI base2_appropriate base2_feasible base2_publishable, `opts_main' `opts_stats'
esttab base2_novelI base2_novel base2_original base2_rare base2_usefulI base2_appropriate base2_feasible base2_publishable using "./tables_graphs/evaluators/base2_creativity.rtf", `opts_main' `opts_stats' replace
* ### Supplementary Table 4
esttab base3_novelI base3_novel base3_original base3_rare base3_usefulI base3_appropriate base3_feasible base3_publishable, `opts_main' `opts_stats'
esttab base3_novelI base3_novel base3_original base3_rare base3_usefulI base3_appropriate base3_feasible base3_publishable using "./tables_graphs/evaluators/base3_creativity.rtf", `opts_main' `opts_stats' replace

* ## Baseline models; evaluators (base)
frame change evaluators
foreach depvar of var `eval_emotiondepvars' `eval_otherdepvars' {
	su `depvar'
	local maxdepvar = `r(max)'
	local depvarname = subinstr("`depvar'", "writer_", "", .)
	local depvarname = subinstr("`depvarname'", "eval_", "", .)
	local depvarname = subinstr("`depvarname'", "tt_", "", .)
	local depvarname = subinstr("`depvarname'", "well_written", "well", .)
	local depvarname = subinstr("`depvarname'", "_index", "I", .)
	local depvarlabel : variable label `depvar'

	* ### 3 conditions
	eststo base3_`depvarname': reg `depvar' ib1.condition, vce(cl eval_id)
	test 2.condition = 3.condition
	lincom _cons
	store_scalars human
	lincom _cons + 2.condition
	store_scalars AI1
	lincom _cons + 3.condition
	store_scalars AI5
}

* ### Supplementary Table 7
esttab base3_well base3_enjoyed base3_funny base3_future base3_twist base3_boring, `opts_main' `opts_stats'
esttab base3_well base3_enjoyed base3_funny base3_future base3_twist base3_boring using "./tables_graphs/evaluators/base3_emotions.rtf", `opts_main' `opts_stats' replace
* ### Supplementary Table 12
esttab base3_ai_assist, `opts_main' `opts_stats'
esttab base3_ai_assist using "./tables_graphs/evaluators/base3_ai_assist.rtf", `opts_main' `opts_stats' replace
* ### Supplementary Table 13
esttab base3_ownerI base3_auth_ideas base3_ownership, `opts_main' `opts_stats'
esttab base3_ownerI base3_auth_ideas base3_ownership  using "./tables_graphs/evaluators/base3_ownership.rtf", `opts_main' `opts_stats' replace


* # Profit for AI conditions
frame change evaluators
eststo eval_profit: reg eval_profit ib2.condition if condition !="Human only":condition, vce(cl eval_id)
eststo eval_profit_ownerI: reg eval_profit ib2.condition eval_owner_index if condition !="Human only":condition, vce(cl eval_id)
eststo eval_profit_ownership: reg eval_profit ib2.condition eval_ownership if condition !="Human only":condition, vce(cl eval_id)
eststo eval_profit_authideas: reg eval_profit ib2.condition eval_auth_ideas if condition !="Human only":condition, vce(cl eval_id)

* Supplementary Table 14
esttab eval_profit eval_profit_ownerI eval_profit_ownership eval_profit_authideas, `opts_main' `opts_stats'
esttab eval_profit eval_profit_ownerI eval_profit_ownership eval_profit_authideas  using "./tables_graphs/evaluators/base3_profit.rtf", `opts_main' `opts_stats' replace

* # Old Figure 2a
frame change evaluators
foreach depvar of var eval_novel_index eval_useful_index {
	local depvarname = subinstr("`depvar'", "eval_", "", .)
	local depvarname = subinstr("`depvarname'", "_index", "I", .)

	* ### 2 conditions
	reg `depvar' 1.condition, vce(cl eval_id)
	lincom _cons
	store_scalars hybrid_`depvarname'
	lincom _cons + 1.condition
	store_scalars human_`depvarname'
}

frame create index2_results
frame change index2_results
set obs 5
gen model = "novelI" in 1
gen condition_str = "Human only" in 1
gen coef = bhuman_novelI in 1
gen lb95 = bhuman_novelI_lb in 1
gen ub95 = bhuman_novelI_ub in 1

replace model = "novelI" in 2
replace condition_str = "Human with GenAI ideas" in 2
replace coef = bhybrid_novelI in 2
replace lb95 = bhybrid_novelI_lb in 2
replace ub95 = bhybrid_novelI_ub in 2

replace model = "usefulI" in 4
replace condition_str = "Human only" in 4
replace coef = bhuman_usefulI in 4
replace lb95 = bhuman_usefulI_lb in 4
replace ub95 = bhuman_usefulI_ub in 4

replace model = "usefulI" in 5
replace condition_str = "Human with GenAI ideas" in 5
replace coef = bhybrid_usefulI in 5
replace lb95 = bhybrid_usefulI_lb in 5
replace ub95 = bhybrid_usefulI_ub in 5

gen bar_order = _n
list
tw (bar coef bar_order if condition_str=="Human only", color(`humancolor') barwidth(0.75)) (bar coef bar_order if condition_str=="Human with GenAI ideas", color(`hybridcolor') barwidth(0.75)) (rcap lb95 ub95 bar_order, lcolor(gs2)), ytitle(`"Value"') xtitle("") ylabel(3(1)6.5) xlabel(1 "Human only" 2 "Human with GenAI ideas" 4 "Human only" 5 "Human with GenAI ideas", noticks nogrid angle(25)) legend(off) t1title("Novelty index                                          Usefulness index") name(oldfig2a, replace) scheme(s1color)
graph export `"./tables_graphs/figs/creativity_combinedts.png"', replace

* # Figure 2a
coefplot (base3_novelI, `coefplot2Iopts') (base3_novelI, `coefplot3Iopts') (base3_novel, `coefplot2c1opts') (base3_novel,`coefplot3c1opts')  (base3_original, `coefplot2c2opts') (base3_original, `coefplot3c2opts')  (base3_rare, `coefplot2c3opts') (base3_rare, `coefplot3c3opts'), subtitle("{bf:A} Novelty", placement(left)) xscale(range(-0.1 0.8)) xlabel(0(0.2)0.8) drop(_cons) xline(0, lpattern(-) lcolor(gs4)) subtitle(, nobox margin(t+2) j(left)) grid(none) nokey coeflabels(2.condition = "Human with 1 GenAI idea" 3.condition = "Human with 5 GenAI ideas", labsize(medium) wrap(12) angle(90)) name(base3_coef_evaluators_novel, replace) scheme(s1color) text(.84 0.6 "{bf:Index}" 1.84 0.6 "{bf:Index}", placement(east)) text(1.04 0.6 "Novel" 1.145 0.6 "Original" 1.25 0.6 "Rare" 2.04 0.6 "Novel" 2.145 0.6 "Original" 2.25 0.6 "Rare", placement(east) size(small)) fxsize(70) xtitle("Effect size", size(small))

coefplot (base3_usefulI, `coefplot2Iopts') (base3_usefulI, `coefplot3Iopts') (base3_appropriate, `coefplot2c1opts') (base3_appropriate,`coefplot3c1opts') (base3_feasible, `coefplot2c2opts') (base3_feasible, `coefplot3c2opts') (base3_publishable, `coefplot2c3opts') (base3_publishable, `coefplot3c3opts'), subtitle("Usefulness", placement(left)) xscale(range(-0.1 1.1)) xlabel(0(0.2)0.8) drop(_cons) xline(0, lpattern(-) lcolor(gs4)) subtitle(, nobox margin(t+2) j(left)) grid(none) nokey coeflabels(2.condition = " " 3.condition = " ", labsize(medium) wrap(12)) name(base3_coef_evaluators_useful, replace) scheme(s1color) text(.84 0.75 "{bf:Index}" 1.84 0.75 "{bf:Index}", placement(east)) text(1.04 0.75 "Appropriate" 1.145 0.75 "Feasible" 1.25 0.75 "Publishable" 2.04 0.75 "Appropriate" 2.145 0.75 "Feasible" 2.25 0.75 "Publishable", placement(east) size(small)) fxsize(65) xtitle("Effect size", size(small))

* # Figure 2b
coefplot (base3_well, `coefplot2opts') (base3_well, `coefplot3opts') ||  (base3_future, `coefplot2opts') (base3_future, `coefplot3opts') ||  (base3_boring, `coefplot2opts') (base3_boring, `coefplot3opts') || (base3_enjoyed, `coefplot2opts') (base3_enjoyed, `coefplot3opts') || (base3_twist, `coefplot2opts') (base3_twist, `coefplot3opts') || (base3_funny, `coefplot2opts') (base3_funny, `coefplot3opts') ||, `coefplotmainopts' byopts(cols(2) colfirst)  name(base3_coef_evaluators_emotions, replace) bylabels(`"{bf:B}                                     This story is well written."' `"This story has changed what I expect of future stories I will read."' `"This story is boring."' `"I enjoyed reading this story."'`"This story has a surprising twist."' `"This story is funny."', wrap(25)) subtitle(, size(medsmall)) scheme(s1color) xtitle(`"                                       Effect size                             Effect size"', placement(left) size(small)) fxsize(110)

* # Figure 2
graph combine base3_coef_evaluators_novel base3_coef_evaluators_useful base3_coef_evaluators_emotions, rows(1) scheme(s1color) xsize(8) imargin(0 0 0 0) iscale(*1.28)
graph export `"./tables_graphs/figs/fig2.png"', replace

* # Violin plot of indices by condition (Supplmentary Figures 1 and 2)
frame change evaluators
violinplot eval_novel_index eval_useful_index, vert over(conditionAI) swap fill colors("`humancolor'" "`hybridcolor'") name(violin_2cond, replace) xsize(14) scheme(s1color)
graph export `"./tables_graphs/evaluators/fig2_violin.png"', replace
violinplot eval_novel_index eval_useful_index, vert over(condition) swap fill colors("`humancolor'" "`ai1color'" "`ai5color'") name(violin_condition, replace) xsize(14) scheme(s1color)
graph export `"./tables_graphs/evaluators/fig3_violin.png"', replace

* # Fig 3
graph combine C3dat_novelI_abr C3dat_usefulI_abr, rows(1) name(dat_creativity, replace) scheme(s1color)
graph combine C3dat_well_abr C3dat_enjoyed_abr C3dat_boring_abr, rows(1) name(dat_emotions, replace) scheme(s1color)
grc1leg2  dat_creativity dat_emotions , rows(2) scheme(s1color) iscale(*1.3)
graph export `"./tables_graphs/figs/fig3.png"', replace


* Writers means comparisons (Supplementary Table 1)
frame change writers

local writersttestvars "dat writer_creative writer_creative_job writer_comfort writer_technologies writer_aitools_ChatGPT writer_aicat_Text writer_aicat_Image writer_aicat_Audio writer_aicat_Music writer_aicat_Video writer_gender_female writer_income_high writer_education_high writer_employement_ptft writer_age"

foreach vlab in "Human only" "Human with 1 GenAI idea" "Human with 5 GenAI ideas" {
	local vlab_prefix = subinstr(`"`vlab'"'," ","",.)
	eststo wsu_`vlab_prefix': quietly estpost summarize `writersttestvars' if condition=="`vlab'":condition
}

eststo writer_diff_H_1: quietly estpost ttest `writersttestvars' if condition=="Human only":condition |  condition=="Human with 1 GenAI idea":condition, by(condition) unequal
eststo writer_diff_H_5: quietly estpost ttest `writersttestvars' if condition=="Human only":condition |  condition=="Human with 5 GenAI ideas":condition, by(condition) unequal
eststo writer_diff_1_5: quietly estpost ttest `writersttestvars' if condition=="Human with 1 GenAI idea":condition |  condition=="Human with 5 GenAI ideas":condition, by(condition) unequal

esttab wsu_Humanonly wsu_Humanwith1GenAIidea wsu_Humanwith5GenAIideas writer_diff_H_1 writer_diff_H_5 writer_diff_1_5, cells("mean(pattern(1 1 1 0 0 0) fmt(3)) p(pattern(0 0 0 1 1 1) par fmt(3))") label nonumbers mtitles("Human" "1AI idea" "5AI ideas" "Human / 1AI idea" "Human / 5AI ideas" "1AI idea / 5AI ideas")
esttab wsu_Humanonly wsu_Humanwith1GenAIidea wsu_Humanwith5GenAIideas writer_diff_H_1 writer_diff_H_5 writer_diff_1_5 using "./tables_graphs/writers/eval_means_bycondition.rtf", cells("mean(pattern(1 1 1 0 0 0) fmt(3)) p(pattern(0 0 0 1 1 1) par fmt(3))") label nonumbers mtitles("Human" "1AI idea" "5AI ideas" "Human / 1AI idea" "Human / 5AI ideas" "1AI idea / 5AI ideas") replace

* # Fig 4
frame change writers
_eststo sim_cstories: reg sim_cstories ib1.condition, vce(r)
_eststo sim_idea: reg sim_idea ib1.condition, vce(r)

_eststo sim_cstories_dat: reg sim_cstories ib1.condition##c.dat, vce(r)
_eststo sim_idea_dat: reg sim_idea ib1.condition##c.dat, vce(r)

* Supplementary Table 17
esttab sim_cstories sim_idea , `opts_main' `opts_stats'
esttab sim_cstories sim_idea  using "./tables_graphs/writers/base3_simstories.rtf", `opts_main' `opts_stats' replace

coefplot (sim_cstories, `coefplot2opts') (sim_cstories, `coefplot3opts') || (sim_idea, `coefplot2opts') (sim_idea, `coefplot3opts') || , `coefplotmainopts' byopts(compact cols(1) colfirst) name(sim_regs, replace) bylabels( `"{bf:B} Similarity to stories in same condition"' `"Similarity to AI idea"', wrap(50)) subtitle(, size(medsmall)) scheme(s1color) aspectratio(.75) xtitle(`"                                                         Effect size"', size(small) placement(left))

kdensity sim_cstories if condition=="Human only":condition, lcolor(`humancolor') addplot(kdensity sim_cstories if condition=="Human with 1 GenAI idea":condition, lcolor(`ai1color') legend(label(2 "Human with 1 GenAI idea"))  || kdensity sim_cstories if condition=="Human with 5 GenAI ideas":condition, lcolor(`ai5color') legend(label(3 "Human with 5 GenAI ideas") region(style(none)) rows(1) position(6))) xtitle("Similarity to stories in same condition") legend(label(1 "Human only")) scheme(s1color) title("") title("{bf:A}                                                                      ") name(kd_cstories, replace)

kdensity sim_idea if condition=="Human only":condition, lcolor(`humancolor') addplot(kdensity sim_idea if condition=="Human with 1 GenAI idea":condition, lcolor(`ai1color') legend(label(2 "Human with 1 GenAI idea"))  || kdensity sim_idea if condition=="Human with 5 GenAI ideas":condition, lcolor(`ai5color') legend(label(3 "Human with 5 GenAI ideas") region(style(none)) rows(1) position(6))) xtitle("Similarity to AI idea") legend(label(1 "Human only")) scheme(s1color) name(kd_idea, replace) title("")

grc1leg2 kd_cstories kd_idea, name(fig4a, replace) cols(1) scheme(s1color)
grc1leg2 fig4a sim_regs, name(fig4, replace) scheme(s1color)
graph export "./tables_graphs/figs/fig4.png", replace

* Supplementary Table 18
_eststo simidea_aibehavior: estpost tabstat sim_idea, s(n mean sd p25 p50 p75) by(ai_behavior) columns(statistics) nototal
esttab simidea_aibehavior using "./tables_graphs/writers/simidea_aibehavior.rtf", cells("count(fmt(%14.0fc)) mean(fmt(%14.2fc)) sd(fmt(%14.2fc)) p25(fmt(%14.2fc)) p50(fmt(%14.2fc)) p75(fmt(%14.2fc))") nomtitle collabels("Count" "Mean" "S.D." "25th pctile" "50th pctile" "75th pctile") nonum noobs replace

* Supplementary Figure 4
kdensity sim_idea if ai_behavior == "Human":ai_behavior, lcolor(`humancolor') addplot(kdensity sim_idea if ai_behavior == "No AI ideas":ai_behavior, lcolor(`noideascolor') legend(label(2 "No AI ideas")) || kdensity sim_idea if ai_behavior == "Used AI":ai_behavior,  lcolor(green) legend(label(3 "Used AI") region(style(none)) rows(1) position(6))) xtitle("Story-AI idea cosine similarity") legend(label(1 "Human")) scheme(s1color) title("")
graph export "./tables_graphs/writers/kd_sim_idea_bybehavior.png", replace


* Evaluator means comparisons (Supplementary Table 2)
frame copy evaluators evaluators_firststory
frame change evaluators_firststory

local evaluatorsttestvars "eval_creative eval_creative_job eval_comfort eval_technologies eval_aitools_ChatGPT eval_aicat_Text eval_aicat_Image eval_aicat_Audio eval_aicat_Music eval_aicat_Video eval_gender_female eval_income_high eval_education_high eval_employement_ptft eval_age"

keep if story_number == mins
drop mins

* # Table comparing means of evaluators by condition of first story
foreach vlab in "Human only" "Human with 1 GenAI idea" "Human with 5 GenAI ideas" {
	local vlab_prefix = subinstr(`"`vlab'"'," ","",.)
	eststo esu_`vlab_prefix': quietly estpost summarize `evaluatorsttestvars' if condition=="`vlab'":condition
}

eststo eval_diff_H_1: quietly estpost ttest `evaluatorsttestvars' if condition=="Human only":condition |  condition=="Human with 1 GenAI idea":condition, by(condition) unequal
eststo eval_diff_H_5: quietly estpost ttest `evaluatorsttestvars' if condition=="Human only":condition |  condition=="Human with 5 GenAI ideas":condition, by(condition) unequal
eststo eval_diff_1_5: quietly estpost ttest `evaluatorsttestvars' if condition=="Human with 1 GenAI idea":condition |  condition=="Human with 5 GenAI ideas":condition, by(condition) unequal

esttab esu_Humanonly esu_Humanwith1GenAIidea esu_Humanwith5GenAIideas eval_diff_H_1 eval_diff_H_5 eval_diff_1_5, cells("mean(pattern(1 1 1 0 0 0) fmt(3)) p(pattern(0 0 0 1 1 1) par fmt(3))") label nonumbers mtitles("Human" "1AI idea" "5AI ideas" "Human / 1AI idea" "Human / 5AI ideas" "1AI idea / 5AI ideas")
esttab esu_Humanonly esu_Humanwith1GenAIidea esu_Humanwith5GenAIideas eval_diff_H_1 eval_diff_H_5 eval_diff_1_5 using "./tables_graphs/evaluators/eval_means_bycondition.rtf", cells("mean(pattern(1 1 1 0 0 0) fmt(3)) p(pattern(0 0 0 1 1 1) par fmt(3))") label nonumbers mtitles("Human" "1AI idea" "5AI ideas" "Human / 1AI idea" "Human / 5AI ideas" "1AI idea / 5AI ideas") replace

* Supplementary Table 15
local sumvars "eval_val_ethical eval_val_creative_act eval_val_eth_idea eval_val_eth_story eval_val_paycontent eval_val_aicontent"
_eststo tab_sumstats: estpost tabstat `sumvars', s(n mean sd p25 median p75) columns(statistics)
esttab tab_sumstats using "./tables_graphs/evaluators/hist_sumstats.rtf", cells("mean(fmt(%14.2fc)) sd(fmt(%14.2fc)) p25(fmt(%14.2fc)) p50(fmt(%14.2fc)) p75(fmt(%14.2fc))") nomtitle collabels("Mean" "S.D." "25th pctile" "50th pctile" "75th pctile") nonum varlabels(eval_val_ethical `"AI unethical"' eval_val_creative_act `"not creative act"' eval_val_eth_idea `"initial idea acceptable"' eval_val_eth_story `"entire story acceptable"' eval_val_paycontent `"compensate underlying content"' eval_val_aicontent `"AI content accessible"') noobs replace

* Supplementary Table 16 (note table made in MS Excel)
tab1 `sumvars'

* # Supplementary Fig S5
coefplot (base3_ownerI, `coefplot2opts') (base3_ownerI, `coefplot3opts') || (base3_auth_ideas, `coefplot2opts') (base3_auth_ideas, `coefplot3opts') || (base3_ownership, `coefplot2opts') (base3_ownership, `coefplot3opts') || , `coefplotmainopts' byopts(compact cols(1)) ysize(9) name(base3_coef_evaluators_ownership, replace) bylabels(`"{bf:a}                                      {bf:Ownership index}"' `"... To what extent do you think, the story reflects the author’s own ideas?"' `"... To what extent does the author have, an “ownership” claim to the final story?"', wrap(45)) subtitle(, size(medsmall)) scheme(s1color)

hist eval_val_ethical, d name(heval_val_ethical, replace) color(`noconditioncolor') xtitle(`"Relying on the use of AI to write"' `"a new story is unethical."') title(`"{bf:b}                                                      "') scheme(s1color)
hist eval_val_creative_act, d name(heval_val_creative_act, replace) color(`noconditioncolor') xtitle(`"If AI is used in any part of the writing of a story,"' `"the final story no longer counts as a “creative act”."') scheme(s1color)
hist eval_val_eth_idea, d name(heval_val_eth_idea, replace) color(`noconditioncolor') xtitle(`"It is ethically acceptable to use AI to come"' `"up with {ul:an initial idea} for a story."') scheme(s1color)
hist eval_val_eth_story, d name(heval_val_eth_story, replace) color(`noconditioncolor') xtitle(`"It is ethically acceptable to use AI to write"' `"and publicly disseminate an {ul:entire story}"' `"without acknowledging the use of AI."') scheme(s1color)
hist eval_val_paycontent, d name(heval_val_paycontent, replace) color(`noconditioncolor') xtitle(`"If AI is used in any part of the writing"' `"of a story, the creators of the content on which"' `"the AI output was based on should be compensated."') scheme(s1color)
hist eval_val_aicontent, d name(heval_val_aicontent, replace) color(`noconditioncolor') xtitle(`"If a human creator (author) uses AI in part"' `"of the writing of a story the AI-generated content,"' `"should be accessible alongside the final story."') scheme(s1color)

graph combine heval_val_ethical heval_val_eth_idea heval_val_paycontent, cols(1) xsize(2) name(figS5_2, replace) title(`""') scheme(s1color)
graph combine  heval_val_creative_act heval_val_eth_story heval_val_aicontent, cols(1) xsize(2) name(figS5_3, replace) title(`" "') scheme(s1color)
graph combine base3_coef_evaluators_ownership figS5_2 figS5_3, rows(1) name(figS5, replace) scheme(s1color) iscale(*0.75)
graph export `"./tables_graphs/figs/figS5.png"', replace

* Supplementary Table 9
local opts_stats_usedai_dat `"stats(N Fv2 r2v2, fmt(a2) labels(`"Observations"' `"F-Stat / Wald Chi-squared (logistic)"' `"Adj R-squared / Pseudo R-squared (logistic)"'))"'
reg used_ai i.condition##c.dat if condition != "Human only":condition, vce(r)
estadd scalar Fv2 =  e(F)
estadd scalar r2v2 = e(r2_a)
eststo used_cdat
logit used_ai i.condition##c.dat if condition != "Human only":condition, vce(r)
estadd scalar Fv2 =  e(chi2)
estadd scalar r2v2 = e(r2_p)
eststo used_cdat_log
esttab used_cdat used_cdat_log, `opts_main' `opts_stats_usedai_dat'
esttab used_cdat used_cdat_log using "./tables_graphs/writers/base3_usedai_dat.rtf", `opts_main' `opts_stats_usedai_dat' replace

* Main result robustiness (Supplemenatary Table 5)
frame change evaluators
bysort eval_id (story_number): gen story_order = _n
egen eval_id_group = group(eval_id)
xtset eval_id_group

foreach depvar of var eval_novel_index eval_useful_index {
	local depvarname = subinstr("`depvar'", "eval_", "", .)
	local depvarname = subinstr("`depvarname'", "_index", "I", .)

	eststo rob_fe_`depvarname': xtreg `depvar' ib1.condition, vce(cl eval_id) fe
	estadd local efe "Yes"
	eststo rob_storyorder_`depvarname': xtreg `depvar' ib1.condition i.story_order, vce(cl eval_id) fe
	estadd local efe "Yes"
	eststo rob_topic_`depvarname': xtreg `depvar' ib1.condition i.story_order i.writer_topic, vce(cl eval_id) fe
	estadd local efe "Yes"
	eststo rob_usedai_`depvarname': xtreg `depvar' ib1.condition i.story_order i.writer_topic i.used_ai, vce(cl eval_id) fe
	estadd local efe "Yes"
}

* ### Baseline model output
local FEindoptions `"indicate("Story order fixed effects = *story_order" "Story topic fixed effects = *writer_topic*")"'
local FEopts_stats `"stats(efe N F r2_a, fmt(a2) labels(`"Evaluator fixed effects"' `"Observations"' `"F-Stat"' `"Adj R-squared"'))"'
esttab rob_fe_novelI rob_storyorder_novelI rob_topic_novelI rob_usedai_novelI rob_fe_usefulI rob_storyorder_usefulI rob_topic_usefulI rob_usedai_usefulI, `opts_main' `FEopts_stats' `FEindoptions'
esttab rob_fe_novelI rob_storyorder_novelI rob_topic_novelI rob_usedai_novelI rob_fe_usefulI rob_storyorder_usefulI rob_topic_usefulI rob_usedai_usefulI using "./tables_graphs/evaluators/rob_creativity.rtf", `opts_main' `FEopts_stats' `FEindoptions' replace

* ### Inter-rater reliability and evaluations per story
frame copy evaluators eval_wide
frame change eval_wide
bysort story_id: gen story_eval_num = _n
keep eval_topic condition eval_story *index story_eval_num story_id
reshape wide *index , i(story_id) j(story_eval_num)
order eval_novel* eval_useful* eval_owner*, after(condition)

foreach vstub in novel useful owner {
	egen `vstub'_mean = rowmean(eval_`vstub'_index*)
}

order eval_story condition eval_topic *mean, after(story_id)

egen novindcount = rownonmiss(*novel_index*)
tab novindcount

foreach vstub in novel useful owner {
	su `vstub'_mean, d
	alpha eval_`vstub'_index*, casewise
	di _newline(3)
}

* Histograms
hist novel_mean, color(`noconditioncolor') name(novel_mean_hist,replace) xtitle("Mean novelty")
graph export `"./tables_graphs/figs/novel_mean_hist.png"', replace
hist useful_mean, color(`noconditioncolor') name(useful_mean_hist,replace) xtitle("Mean usefulness")
graph export `"./tables_graphs/figs/useful_mean_hist.png"', replace



frame change evaluators
capture log close
