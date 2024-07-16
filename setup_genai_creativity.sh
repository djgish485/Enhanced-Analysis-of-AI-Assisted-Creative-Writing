#!/bin/bash

# Setup script for GenAI_creativity_scripts project

# Check if Homebrew is installed, install if not
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed."
fi

# Install Python 3 and R
brew install python r

# Create and activate a virtual environment for Python
python3 -m venv genai_env
source genai_env/bin/activate

# Install required Python packages
pip install numpy scipy openai pandas

# Install required R packages
Rscript -e 'install.packages(c("tidyverse", "lmtest", "sandwich", "ggplot2", "broom", "stargazer"), repos="https://cran.rstudio.com/", dependencies=TRUE)'

# Download required files
cd GenAI_creativity_scripts/scripts
curl -O https://raw.githubusercontent.com/jayolson/divergent-association-task/main/dat.py
mkdir -p words_glove
cd words_glove
curl -O https://raw.githubusercontent.com/jayolson/divergent-association-task/main/words.txt
curl -O http://nlp.stanford.edu/data/glove.840B.300d.zip
unzip glove.840B.300d.zip
cd ../..

echo "Setup complete. Please ensure you have set your OpenAI API key in scripts/ai_human_story_similarity.py"
