#!/bin/bash

# Run analysis for GenAI_creativity_scripts project

# Print current directory
echo "Current directory: $(pwd)"

# Change to the project directory
cd "$(dirname "$0")"

# Print new current directory
echo "New current directory: $(pwd)"

# List contents of current directory
echo "Contents of current directory:"
ls -R

# Create necessary directories
mkdir -p processed_data
mkdir -p tables_graphs/writers

# Debug: Print PATH
echo "Current PATH:"
echo $PATH

# Activate the virtual environment
VENV_PATH="../genai_env"
if [ -f "$VENV_PATH/bin/activate" ]; then
    echo "Activating virtual environment..."
    source "$VENV_PATH/bin/activate"
else
    echo "Error: Virtual environment not found at $VENV_PATH"
    exit 1
fi

# Debug: Check Python version and location
which python
python --version

# Update pip
echo "Updating pip..."
python -m pip install --upgrade pip

# Install required Python packages
echo "Installing required Python packages..."
python -m pip install pandas pyreadstat openai==1.3.5

# Install system dependencies (you might need sudo for this)
echo "Installing system dependencies..."
if command -v brew >/dev/null 2>&1; then
    brew install freetype harfbuzz fribidi
else
    echo "Homebrew not found. Please install freetype, harfbuzz, and fribidi manually."
fi

# Set the OpenAI API key (replace YOUR_API_KEY with your actual key)
sed -i '' 's/api_key='"'"'YOUR_API_KEY'"'"'/api_key='"'"'YOUR_ACTUAL_API_KEY'"'"'/' scripts/ai_human_story_similarity.py

# Run the Python script for story similarity and capture output
echo "Running Python script for similarity calculation..."
python scripts/ai_human_story_similarity.py > tables_graphs/writers/python_script_output.txt 2>&1

# Check if the Python script ran successfully
if [ $? -ne 0 ]; then
    echo "Error: Python script failed. Check tables_graphs/writers/python_script_output.txt for details."
    cat tables_graphs/writers/python_script_output.txt
    exit 1
fi

# Install R packages
echo "Installing R packages..."
Rscript -e 'install.packages(c("tidyverse", "lmtest", "sandwich", "ggplot2", "broom", "stargazer", "haven"), repos="https://cran.rstudio.com/", dependencies=TRUE)'

# Run the R analysis
echo "Running R script for statistical analysis..."
Rscript scripts/03_analysis.R > tables_graphs/writers/r_script_output.txt 2>&1

# Check if the R script ran successfully
if [ $? -ne 0 ]; then
    echo "Error: R script failed. Check tables_graphs/writers/r_script_output.txt for details."
    cat tables_graphs/writers/r_script_output.txt
    exit 1
fi

echo "Analysis complete. Results can be found in the tables_graphs/writers directory."
echo "Check the following files for results:"
echo "- tables_graphs/writers/python_script_output.txt"
echo "- tables_graphs/writers/r_script_output.txt"
echo "- tables_graphs/writers/similarity_summary.csv"
echo "- tables_graphs/writers/similarity_boxplot.png"

# Display the contents of the Python script output
echo "Python script output:"
cat tables_graphs/writers/python_script_output.txt

# Display the contents of the R script output
echo "R script output:"
cat tables_graphs/writers/r_script_output.txt

