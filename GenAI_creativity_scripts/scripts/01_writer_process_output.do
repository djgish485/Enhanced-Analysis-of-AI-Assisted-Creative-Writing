* 01_writer_process_output.co
set seed 1234
cd `"`mywd'"'
log using "./log_files/writer_process_output.log", replace

frame create writers
frame change writers
import delimited "raw_data/writers-2023-06-28.csv", case(preserve) clear

* # Rename variables used in analysis
rename ai_story_gen1playerai_idea*     writer_ai_idea*
rename writer_ai_idea?_erro            writer_ai_idea?_error
rename ai_story_gen1playerstory_id     story_id // used for merging
rename ai_story_gen1playerstory        writer_story
rename ai_story_gen1playerword*        dat_word*
rename ai_story_gen1playerstory_time_s writer_story_time
rename participantcondition            condition
rename participantcode                 writer_id
rename participanttopic                writer_topic
rename participantfollow_up_order      writer_followup_order
rename participantid_in_session        writer_session_order
rename follow_up1player*               writer_*
drop payment1playerrole payment1playerid_in_group payment1playerpayoff
rename payment1player*                 writer_*
rename writer_ai_catagories*           writer_aicat*
rename writer_aicat_Audi               writer_aicat_Audio
rename writer_aicat_Imag               writer_aicat_Image
rename writer_aicat_Musi               writer_aicat_Music
rename writer_aicat_Vide               writer_aicat_Video
rename writer_ai_tools*                writer_aitools*
rename writer_aitools_GoogleBar        writer_aitools_GoogleBard
rename writer_aitools_Midjourne        writer_aitools_Midjourney
rename writer_aitools_other_nam        writer_aitools_othernames

* NOTE: Question was phrased as whether story was "badly written" during pilot
* study. Question was changed to whether story was "well written" in final
* study, but table name was not updated in database.
rename *badly_written *well_written

count
tab participant_current_page_name, mi
* Drop prior to consent, 169
drop if mi(participant_current_page_name)
* Drop did not give consent, 22
drop if participant_current_page_name=="ConsentDropout"
* Drop did not complete, 13
keep if participant_current_page_name=="Finally"
drop participant_current_page_name participant_index_in_pages participant_is_bot sessionis_demo
count

* ## Manually code the condition variable (to keep consistent with prior iterations)
rename condition condition_str
gen condition = 1 if condition_str == "human"
replace condition = 2 if condition_str == "human_1AI"
replace condition = 3 if condition_str == "human_5AI"
replace condition = 4 if condition_str == "AI"
lab def condition 1 "Human only" 2 "Human with 1 GenAI idea" 3 "Human with 5 GenAI ideas"
la val condition condition
drop condition_str

gen conditionAI = condition != "Human only":condition
lab def conditionAI 0 "Human only" 1 "Human with GenAI idea(s)"
la val conditionAI conditionAI


* ## Variables defined over multiple measures
foreach stub in used_ai_tool own_ideas novel original rare appropriate feasible publishable ai_idea0_assist ai_idea1_assist ai_idea2_assist ai_idea3_assist ai_idea4_assist tt_well_written tt_boring tt_enjoyed tt_funny tt_future tt_twist {
	replace writer_`stub' = follow_up2player`stub' if mi(writer_`stub') & !mi(follow_up2player`stub')
	drop follow_up2player`stub'
}
replace writer_profit = follow_up2playerprofit if writer_profit==50 & follow_up2playerprofit!=50
tostring writer_spark, replace
replace writer_spark = "" if writer_spark == "."
replace writer_spark = follow_up2playerspark if mi(writer_spark) & !mi(follow_up2playerspark)
drop follow_up2playerprofit follow_up2playerspark

gen human_admitted = condition == "Human only":condition & writer_used_ai_tool & !mi(writer_used_ai_tool)
tab condition human_admitted

replace writer_income = subinstr(writer_income, "Â", "", .)

* # FIllin zeroes for missing checkboxes
mvencode writer_aitools_None writer_aitools_ChatGPT writer_aitools_DallE writer_aitools_OpenAI writer_aitools_StableDif writer_aitools_NightCafe writer_aitools_Jasper writer_aitools_BingChat writer_aitools_GoogleBard writer_aitools_YouCom writer_aitools_Midjourney writer_aitools_Other writer_aicat_Text writer_aicat_Image writer_aicat_Audio writer_aicat_Music writer_aicat_Video writer_aicat_None, mv(0) o

* # Variable cleaning and wrangling
* ## Categorical variables
foreach v of var writer_topic writer_gender writer_employment writer_followup_order writer_education writer_income {
	rename `v' `v'_str
	encode `v'_str, gen(`v')
	drop `v'_str
}

gen writer_education_high = writer_education == "Doctorate":writer_education | writer_education == "Postgraduate Master's degree":writer_education | writer_education == "Professional degree (e.g. MBA, JD)":writer_education
gen writer_income_high = writer_income == "More than £150,00":writer_income | writer_income =="£125,000-£149,999":writer_income | writer_income == "£50,000-£74,999":writer_income | writer_income ==  "£75,000-£99,999":writer_income
foreach v of var writer_creative writer_creative_job writer_comfort writer_technologies {
	gen `v'_high = `v' >= 7 if !mi(`v')
}

egen writer_novel_index = rowmean(writer_novel writer_original writer_rare)
egen writer_useful_index = rowmean(writer_appropriate writer_feasible writer_publishable)

* ## Compute dat for each writer
gen dat = .
python script ./scripts/compute_dats.py

* Used AI variables
gen used_ai = !missing(writer_ai_idea0) | !missing(writer_ai_idea1) | !missing(writer_ai_idea2) | !missing(writer_ai_idea3) | !missing(writer_ai_idea4)
la var used_ai "Used AI"
egen num_ai_ideas = rownonmiss(writer_ai_idea?), s

gen ai_behavior = 1 if condition=="Human only":condition
replace ai_behavior = 2 if (condition == "Human with 1 GenAI idea":condition | condition == "Human with 5 GenAI ideas":condition) & !used_ai
replace ai_behavior = 3 if (condition == "Human with 1 GenAI idea":condition | condition == "Human with 5 GenAI ideas":condition) & used_ai
lab def ai_behavior 1 "Human" 2 "No AI ideas" 3 "Used AI"
la val ai_behavior ai_behavior

* Get first available AI story for those that used AI
gen ai_idea_combined0 = writer_ai_idea0
forvalues i = 1/4 {
	replace ai_idea_combined0 = writer_ai_idea`i' if mi(ai_idea_combined0) & num_ai_ideas > 0
}

* # Frame containing all the actual ai ideas
frame copy writers ai_ideas_frame
frame change ai_ideas_frame
keep writer_topic writer_ai_idea0
drop if mi(writer_ai_idea)

* # Fill in "simulated" ideas for all users who did not use ideas (where !used_ai)
frame change writers
count if !used_ai
local not_used_ai_count = `r(N)'
sort used_ai
forvalues obsi = 1/`not_used_ai_count' {
	local obsi_topic = writer_topic in `obsi'

	frame change ai_ideas_frame
	gen randorder = runiform() if writer_topic == `obsi_topic'
	sort randorder
	local s0 = writer_ai_idea in 1
	drop randorder

	frame change writers
	quietly replace ai_idea_combined0 = `"`s0'"' in `obsi'
}


* ## Compute similarity of AI's first idea to writer's story
gen writer_story_for_python = writer_story if !human_admitted
gen sim_idea = .
gen sim_allstories = .
gen sim_cstories = .
python script ./scripts/ai_human_story_similarity.py
gen sim_idea_actual = sim_idea if used_ai
drop writer_story_for_python

replace sim_idea = sim_idea * 100
replace sim_allstories = sim_allstories * 100
replace sim_cstories = sim_cstories * 100


* ## Discretization
foreach v of var dat sim_idea sim_idea_actual writer_age {
	xtile `v'_xtile = `v' if `v' != 0, n(2)
	gen `v'_g50 = `v'_xtile - 1
	la var `v'_g50 "`v' > median"
	drop `v'_xtile
}
su sim_idea if !used_ai
local max_sim_noai = `r(max)'
gen sim_idea_gnoai = sim_idea > `max_sim_noai' if !mi(sim_idea)

gen writer_employement_ptft = writer_employment == 2 | writer_employment == 3

gen writer_gender_female = writer_gender == "Female":writer_gender if !mi(writer_gender)
lab def gender_female 1 "Female" 2 "Not Female"
la val writer_gender_female gender_female

* # Drop unused variables
drop evaluator* *playerrole *groupid_in_subsessi *playerid_in_group *playerpayoff *groupid_in_subsession *subsessionround_number sessionmturk*
drop ai_story_gen1subsessionround_num consent1playerbrowser_type consent1playerscreen_size consent1playerbrowser_type consent1playerscreen_size writer_id_in_group writer_role writer_session_order sessioncode sessioncomment sessionconfigname sessionconfigparticipation_fee sessionconfigreal_world_currency sessionconfigreview_count sessionconfiguse_canned_response sessionlabel participant_current_app_name participant_max_page_index participantmturk_assignment_id participantmturk_worker_id participantpayoff participanttime_started_utc participantvisited writer_payoff writer_id_in_group writer_role writer_payoff

la var writer_id                        "Writer ID"
la var dat_word1                        "word 1 provided for creativity score"
la var dat_word2                        "word 2 provided for creativity score"
la var dat_word3                        "word 3 provided for creativity score"
la var dat_word4                        "word 4 provided for creativity score"
la var dat_word5                        "word 5 provided for creativity score"
la var dat_word6                        "word 6 provided for creativity score"
la var dat_word7                        "word 7 provided for creativity score"
la var dat_word8                        "word 8 provided for creativity score"
la var dat_word9                        "word 9 provided for creativity score"
la var dat_word10                       "word 10 provided for creativity score"
la var writer_story                     "Text of story"
la var writer_story_time                "Time (in seconds) to write story"
la var story_id                         "Story ID"
la var writer_ai_idea0                  "Text of AI Idea 0"
la var writer_ai_idea1                  "Text of AI Idea 1"
la var writer_ai_idea2                  "Text of AI Idea 2"
la var writer_ai_idea3                  "Text of AI Idea 3"
la var writer_ai_idea4                  "Text of AI Idea 4"
la var writer_ai_idea0_error            "=1 if call to API for Idea 0 failed"
la var writer_ai_idea1_error            "=1 if call to API for Idea 1 failed"
la var writer_ai_idea2_error            "=1 if call to API for Idea 2 failed"
la var writer_ai_idea3_error            "=1 if call to API for Idea 3 failed"
la var writer_ai_idea4_error            "=1 if call to API for Idea 4 failed"
la var writer_used_ai_tool              "=1 if writer used AI tool"
la var writer_profit                    "story author profit %"
la var writer_own_ideas                 "story own ideas"
la var writer_novel                     "story novel"
la var writer_original                  "story original"
la var writer_rare                      "story rare"
la var writer_appropriate               "story appropriate"
la var writer_feasible                  "story feasible"
la var writer_publishable               "story publishable"
la var writer_ai_idea0_assist           "Extent to which AI Idea 0 helped with writing"
la var writer_ai_idea1_assist           "Extent to which AI Idea 1 helped with writing"
la var writer_ai_idea2_assist           "Extent to which AI Idea 2 helped with writing"
la var writer_ai_idea3_assist           "Extent to which AI Idea 3 helped with writing"
la var writer_ai_idea4_assist           "Extent to which AI Idea 4 helped with writing"
la var writer_creative             "writer creative"
la var writer_creative_job         "writer creative job"
la var writer_comfort              "writer tech comfort"
la var writer_technologies         "writer AI engagement"
la var writer_aitools_None         "writer used None"
la var writer_aitools_ChatGPT      "writer used ChatGPT"
la var writer_aitools_DallE        "writer used DallE"
la var writer_aitools_OpenAI       "writer used OpenAI"
la var writer_aitools_StableDif    "writer used StableDif"
la var writer_aitools_NightCafe    "writer used NightCafe"
la var writer_aitools_Jasper       "writer used Jasper"
la var writer_aitools_BingChat     "writer used BingChat"
la var writer_aitools_GoogleBard   "writer used GoogleBard"
la var writer_aitools_YouCom       "writer used YouCom"
la var writer_aitools_Midjourney   "writer used Midjourney"
la var writer_aitools_Other        "writer used Other"
la var writer_aitools_othernames  "Names of other tools used"
la var writer_aicat_Text           "writer used text AI tools"
la var writer_aicat_Image          "writer used image AI tools"
la var writer_aicat_Audio          "writer used audio AI tools"
la var writer_aicat_Music          "writer used music AI tools"
la var writer_aicat_Video          "writer used video AI tools"
la var writer_aicat_None           "writer used none AI tools"
la var writer_gender_other         "Text of gender (if other)"
la var writer_age                  "writer age"
la var writer_job_title            "writer job title"
la var writer_comments             "writer survey comments"
la var dat                              "writer DAT score"
la var sim_idea                         "story AI Idea similarity (incl simulated ideas)"
la var sim_idea_actual					"story AI Idea similarity (where used_ai)"
la var condition                        "condition"
la var conditionAI                        "condition (human or AI ideas)"
la var ai_behavior                 "Categorization by AI usage"
la var writer_topic                     "topic"
la var writer_gender               "writer gender"
la var writer_education            "writer education"
la var writer_employment           "writer employment"
la var writer_income               "writer income"
la var writer_education_high       "writer education undergraduate or more"
la var writer_income_high          "income > £50,000"
la var writer_creative_high        "writer creative >= 7"
la var writer_creative_job_high    "writer creative_job >= 7"
la var writer_comfort_high         "writer comfort >= 7"
la var writer_technologies_high    "writer technologies >= 7"
la var writer_followup_order            "question order"
la var dat_g50                          "high DAT score"
la var sim_idea_g50                     "story AI Idea similarity max high (incl simulated ideas)"
la var sim_idea_actual_g50              "story AI Idea similarity max high (where used_ai)"
la var sim_idea_gnoai                   "story AI similarity greater than no AI max"
la var writer_novel_index               "writer novel index"
la var writer_useful_index              "writer useful index"
la var writer_tt_well_written              "writer well written"
la var writer_tt_boring                  "writer boring"
la var writer_tt_enjoyed                 "writer enjoyed"
la var writer_tt_funny                   "writer funny"
la var writer_tt_future                  "writer future"
la var writer_tt_twist                   "writer twist"
la var num_ai_ideas                      "Number of AI Ideas Generated"
la var human_admitted "=1 if human only condition and admitted to using AI"
la var writer_gender_female "writer gender female"
la var writer_employement_ptft "writer employed part- or full-time"

compress
save "./processed_data/creators.dta", replace
capture log close
