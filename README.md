# Enhanced Analysis of AI-Assisted Creative Writing

This project extends the analysis from the paper "Generative artificial intelligence enhances creativity but reduces the diversity of novel content" by Anil R. Doshi and Oliver P. Hauser.

## Original Research

- Paper: [Generative artificial intelligence enhances creativity but reduces the diversity of novel content](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4535536)
- Original codebase: [Dryad Data Repository](https://datadryad.org/stash/dataset/doi:10.5061/dryad.qfttdz0pm)

## Modifications

We modified the original codebase to:
1. Use R instead of Stata for statistical analysis.
2. Implement additional statistical tests to assess the significance of the results.
3. Focus on the question: "For writers with inherently higher ability, did their output with AI assistance also make their stories more similar?"

## Setup and Execution

1. Clone this repository.
2. Replace `YOUR_OPEN_AI_KEY` in `GenAI_creativity_scripts/scripts/ai_human_story_similarity.py` with your actual OpenAI API key.
3. Run the setup script to install dependencies (designed for MacBook M3): ./setup_genai_creativity.sh
4. Execute the analysis: ./GenAI_creativity_scripts/run_genai_analysis.sh
## Findings

Our analysis revealed:

1. There is a statistically significant main effect of AI assistance on story similarity across all writers.
2. However, for high-ability writers specifically:
- The increase in similarity with AI assistance is not statistically significant.
- There is no significant difference in similarity between stories written with no AI, 1 AI idea, or 5 AI ideas.
3. The effect of AI assistance on story similarity is not significantly different between high-ability and low-ability writers.

In conclusion, while AI assistance tends to increase story similarity overall, high-ability writers appear to maintain their unique style more effectively when using AI assistance compared to the general trend. However, this difference is not statistically significant, suggesting that the impact of AI on story similarity is relatively consistent across different levels of writer ability.

These findings provide a nuanced understanding of how AI affects creative writing, particularly for writers of different skill levels.

