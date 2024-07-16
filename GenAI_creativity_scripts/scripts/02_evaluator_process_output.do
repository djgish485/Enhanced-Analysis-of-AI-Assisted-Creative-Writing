* 02_evaluator_process_output.do
cd `"`mywd'"'
log using "./log_files/evaluator_process_output.log", replace
set seed 1234

frame create evaluators
frame change evaluators
import delimited "raw_data/evaluators-2023-07-06.csv", case(preserve) clear

* Drop observations that fail tests
count
tab participant_current_page_name if participant_index_in_pages == 0, mi
tab participant_current_page_name if sessionconfiguse_canned_response == ., mi
tab participant_current_page_name if participant_is_bot == 1, mi
keep if participant_current_page_name == "Finally"
count
drop participant_current_page_name participant_index_in_pages participant_max_page_index sessionconfiguse_canned_response participant_is_bot

drop evaluator*groupid_in_subsession evaluator*subsessionround_number evaluator*playerrole evaluator*playerpayoff evaluator*playerid_in_group evaluator_p2*groupid_in_subsessi evaluator_p2*playerid_in_group evaluator_p2*playerpayoff evaluator_p2*playerrole evaluator_p2*playerstory evaluator_p2*playerstory_id evaluator_p2*playertopic evaluator_p2*subsessionround_num evaluator_p210subsessionround_nu evaluator_p210groupid_in_subsess evaluator10subsessionround_numbe
drop session*
drop consent1playerid_in_group consent1playerrole consent1playerpayoff consent1playerbrowser_type consent1playerscreen_size consent1playercomprehension_atte consent1playeroverview_comp_q consent1groupid_in_subsession consent1subsessionround_number
drop payment1groupid_in_subsession payment1subsessionround_number payment1playerid_in_group payment1playerrole payment1playerpayoff
drop participantid_in_session participantvisited participantmturk_worker_id participantmturk_assignment_id participantpayoff participanttopic participantfollow_up_order participant_current_app_name participantcondition

rename evaluator*playerstory_id     story_id*
rename evaluator*playerstory        eval_story*
rename evaluator*playertopic        eval_topic*
rename evaluator*playernovel        eval_novel*
rename evaluator*playeroriginal     eval_original*
rename evaluator*playerrare         eval_rare*
rename evaluator*playerappropriate  eval_appropriate*
rename evaluator*playerfeasible     eval_feasible*
rename evaluator*playerpublishable  eval_publishable*
rename evaluator_p2*playerai_assist    eval_ai_assist*
rename evaluator_p2*playerai_usage      eval_ai_usage*
rename evaluator_p2*playerauthors_ideas eval_auth_ideas*
rename evaluator_p2*playerownership     eval_ownership*
rename evaluator_p2*playerprofit        eval_profit*
rename participantcode              eval_id
rename participantordered_topics    eval_question_order
rename payment1player*              eval_*
rename eval_ai_catagories*     eval_aicat*
rename eval_aicat_Audi         eval_aicat_Audio
rename eval_aicat_Imag         eval_aicat_Image
rename eval_aicat_Musi         eval_aicat_Music
rename eval_aicat_Vide         eval_aicat_Video
rename eval_ai_tools*          eval_aitools*
rename eval_aitools_GoogleBar  eval_aitools_GoogleBard
rename eval_aitools_Midjourne  eval_aitools_Midjourney
rename eval_aitools_other_nam  eval_aitools_othernames
rename evaluator*playertt_enjoyed       eval_tt_enjoyed*
rename evaluator*playertt_twist         eval_tt_twist*
rename evaluator*playertt_funny         eval_tt_funny*
rename evaluator*playertt_future        eval_tt_future*
rename evaluator*playertt_boring        eval_tt_boring*
rename evaluator_p31playerethical       eval_val_ethical
rename evaluator_p31playercreative_act  eval_val_creative_act
rename evaluator_p31playerethical_initi eval_val_eth_idea
rename evaluator_p31playerethical_ackno eval_val_eth_story
rename evaluator_p31playercompansate_ai eval_val_paycontent
rename evaluator_p31playeraccess_ai_con eval_val_aicontent

* NOTE: Question was phrased as whether story was "badly written" during pilot
* study. Question was changed to whether story was "well written" in final
* study, but table name was not updated in database.
rename evaluator*playertt_badly_written eval_tt_well_written*

replace eval_income = subinstr(eval_income, "Â", "", .)

foreach v of var eval_gender eval_education eval_employment eval_income eval_question_order {
	rename `v' `v'_str
	encode `v'_str, gen(`v')
	drop `v'_str
}

tostring story_id* eval_story* eval_topic*, replace
foreach v of var story_id* eval_story* eval_topic* {
	replace `v' = "" if `v' == "."
}

gen eval_employement_ptft = eval_employment == 2 | eval_employment == 3
gen eval_gender_female = eval_gender == "Female":eval_gender if !mi(eval_gender)
gen eval_education_high = eval_education == "Doctorate":eval_education | eval_education == "Postgraduate Master's degree":eval_education | eval_education == "Professional degree (e.g. MBA, JD)":eval_education
gen eval_income_high = eval_income == "More than £150,00":eval_income | eval_income =="£125,000-£149,999":eval_income | eval_income == "£50,000-£74,999":eval_income | eval_income ==  "£75,000-£99,999":eval_income

reshape long eval_writerid story_id eval_story eval_topic eval_novel eval_original eval_rare eval_appropriate eval_feasible eval_publishable eval_ai_assist eval_ai_usage eval_auth_ideas eval_ownership eval_profit eval_tt_well_written eval_tt_boring eval_tt_enjoyed eval_tt_funny eval_tt_future eval_tt_twist, i(eval_id) j(story_number)

rename eval_topic eval_topic_str
encode eval_topic_str, gen(eval_topic)
drop eval_topic_str

mvencode eval_aitools_None eval_aitools_ChatGPT eval_aitools_DallE eval_aitools_OpenAI eval_aitools_StableDif eval_aitools_NightCafe eval_aitools_Jasper eval_aitools_BingChat eval_aitools_GoogleBard eval_aitools_YouCom eval_aitools_Midjourney eval_aitools_Other eval_aicat_Text eval_aicat_Image eval_aicat_Audio eval_aicat_Music eval_aicat_Video eval_aicat_None, mv(0) o

egen eval_novel_index = rowmean(eval_novel eval_original eval_rare)
egen eval_useful_index = rowmean(eval_appropriate eval_feasible eval_publishable)
egen eval_owner_index = rowmean(eval_auth_ideas eval_ownership)

la var eval_id                      "evaluator ID"
la var story_number                 "story number"
la var participanttime_started_utc  "start time"
la var story_id                     "story ID"
la var eval_story                   "story text"
la var eval_novel                   "Novel"
la var eval_original                "Original"
la var eval_rare                    "Rare"
la var eval_appropriate             "Appropriate"
la var eval_feasible                "Feasible"
la var eval_publishable             "Publishable"
la var eval_ai_assist               "AI assistance"
la var eval_ai_usage                "writer AI usage case"
la var eval_auth_ideas           "authors ideas"
la var eval_ownership               "ownership claim"
la var eval_profit                  "profit share"
la var eval_creative           "evaluator creative"
la var eval_creative_job       "evaluator creative job"
la var eval_comfort            "evaluator tech comfort"
la var eval_technologies       "evaluator AI engagement"
la var eval_aitools_None       "evaluator used None"
la var eval_aitools_ChatGPT    "evaluator used ChatGPT"
la var eval_aitools_DallE      "evaluator used DallE"
la var eval_aitools_OpenAI     "evaluator used OpenAI"
la var eval_aitools_StableDif  "evaluator used StableDif"
la var eval_aitools_NightCafe  "evaluator used NightCafe"
la var eval_aitools_Jasper     "evaluator used Jasper"
la var eval_aitools_BingChat   "evaluator used BingChat"
la var eval_aitools_GoogleBard "evaluator used GoogleBard"
la var eval_aitools_YouCom     "evaluator used YouCom"
la var eval_aitools_Midjourney "evaluator used Midjourney"
la var eval_aitools_Other      "evaluator used Other"
la var eval_aitools_othernames "names of other tools used"
la var eval_aicat_Text         "evaluator used text AI tools"
la var eval_aicat_Image        "evaluator used image AI tools"
la var eval_aicat_Audio        "evaluator used audio AI tools"
la var eval_aicat_Music        "evaluator used music AI tools"
la var eval_aicat_Video        "evaluator used video AI tools"
la var eval_aicat_None         "evaluator used none AI tools"
la var eval_gender_other       "Text of gender (if other)"
la var eval_age                "evaluator age"
la var eval_job_title          "evaluator job title"
la var eval_comments           "evaluator survey comments"
la var eval_gender             "evaluator gender"
la var eval_education          "evaluator education"
la var eval_employment         "evaluator employment"
la var eval_income             "evaluator income"
la var eval_question_order          "question order"
la var eval_topic                   "story topic"
la var eval_novel_index             "Novelty index"
la var eval_useful_index            "Usefulness index"
la var eval_owner_index          "Ownership index"
la var eval_tt_well_written              "Well written"
la var eval_tt_boring                  "Boring"
la var eval_tt_enjoyed                 "Enjoyed"
la var eval_tt_funny                   "Funny"
la var eval_tt_future                  "Future"
la var eval_tt_twist                   "Twist"
la var eval_gender_female "evaluator gender female"
la var eval_val_ethical      "AI is unethical"
la var eval_val_creative_act "Not a creative act"
la var eval_val_eth_idea     "Ethical to use AI for an idea"
la var eval_val_eth_story    "Ethical to use AI for entire story without acknolwedging"
la var eval_val_paycontent   "Content creator on which AI output is based should be compensated"
la var eval_val_aicontent    "AI-generated output accessible with story"
la var eval_employement_ptft "evaluator employed part- or full-time"

drop if mi(story_id)
compress
save "./processed_data/evaluators_stories.dta", replace

capture log close