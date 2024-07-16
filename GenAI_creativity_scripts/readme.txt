# Dataset and Code for "Generative artificial intelligence enhances creativity but reduces the diversity of novel content" 
# by Anil R. Doshi and Oliver P. Hauser

## Introduction

We provide two methods to perform the data analysis.

  1. Compile all files. This method processes the raw csv files and performs the analysis. Requires some knowledge of Python and an API key to OpenAI.
  2. Processed file analysis. This allows you to run the analysis on the already processed dta files.

## 1. Compile all files method

If you would like to compile all files, please follow these steps to ensure your machine is set up to run all the necessary scripts.

### Machine setup

1. Ensure Python is installed (tested with Python 3)
2. Install the following packages in Python
  - numpy
  - scipy
  - openai

It may be necessary to install these packages from within Stata. Do so by first entering the Python environment in Stata using the `python` command and then `pip install numpy` and so forth.

3. Ensure Stata is able to call Python (see `help python` Stata help documentation).
4. Download **`dat.py`** from [https://github.com/jayolson/divergent-association-task](https://github.com/jayolson/divergent-association-task). Place file in **`scripts`** folder.
5. Download **`words.txt`** from [https://github.com/jayolson/divergent-association-task](https://github.com/jayolson/divergent-association-task). Place file in **`scripts/words_glove`** folder.
6. Download and extract **`glove.840B.300d.zip`** from [https://nlp.stanford.edu/projects/glove/](https://nlp.stanford.edu/projects/glove/). Place file in **`scripts/words_glove`** folder.
7. Obtain an OpenAI API key (see [https://platform.openai.com/docs/api-reference/introduction](https://platform.openai.com/docs/api-reference/introduction)).
8. Install the following packages in Stata:
  - coefplot
  - colorpalette
  - dstat
  - estout
  - grc1leg2
  - marginsplot
  - moremata (version 2.0.1 or newer)
  - violinplot

### Files setup

1. In **`scripts/00_control_center.do`**, change the following:
  - Change local macro `mywd` to the filepath of the **`GenAI_creativity_scripts`** folder.
  - Set local macro `compile_type` to "all" (`local compile_type = "all"`).
2. In **`scripts/ai_human_story_similarity.py`**, change the following:
  - Change the `openai.api_key` variable by replacing 'XXX' with your API key.
3. In compute_dats.py, change the following:
  - Change the genai_folder variable to the filepath of the **`GenAI_creativity_scripts`** folder.
4. Run the **`scripts/00_control_center.do`** file.

*Important note*: Sometimes the call to the OpenAI API will fail. If that occurs, the do file will quit with an error. It will be necessary to rerun the script.

## 2. Processed file analysis

If you would like to use the already processed dta files (found in the **`already_processed_data`** folder) and perform the analysis, please follow these steps to ensure your machine is setup to run all the necessary scripts.

### Machine setup

1. Install the following packages in Stata:
  - coefplot
  - colorpalette
  - dstat
  - estout
  - grc1leg2
  - marginsplot
  - moremata (version 2.0.1 or newer)
  - violinplot

### Files setup

1. In **`scripts/00_control_center.do`**, change the following:
  - Change local macro `mywd` to the filepath of the **`GenAI_creativity_scripts`** folder.
  - Set local macro `compile_type` to "analysis" (`local compile_type = "analysis"`).
2. Run the **`scripts/00_control_center.do`** file.
