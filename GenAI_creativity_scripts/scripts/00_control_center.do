version 17
clear all
macro drop _all
set more off
capture log close
set seed 1234

* 1. Change mywd to the filepath of the GenAI_creativity_scripts folder
local mywd = "~/Desktop/GenAI_creativity_scripts"

* 2. Set compile_type to "all" in order to compile all files
* 	 Set compile_type to "analysis" in order to perform the processed file analysis
* Note: any string other than "all" will perform processed file analysis
local compile_type = "analysis"

cd `"`mywd'"'

if `"`compile_type'"' == `"all"' {
	local processed_folder = "processed_data"
	include "./scripts/01_writer_process_output.do"
	include "./scripts/02_evaluator_process_output.do"
	include "./scripts/03_analysis.do"
}
else {
	local processed_folder = "already_processed_data"
	include "./scripts/03_analysis.do"
}

