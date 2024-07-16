import os
import sys
import random
import pandas as pd
import numpy as np
from scipy.spatial.distance import cosine
from openai import OpenAI

print(f"Current working directory: {os.getcwd()}")
print(f"Python version: {sys.version}")

random.seed(1234)
client = OpenAI(api_key='YOUR_OPEN_AI_KEY')

def get_embedding(text, model="text-embedding-ada-002"):
    text = text.replace("\n", " ")
    try:
        response = client.embeddings.create(input=[text], model=model)
        return response.data[0].embedding
    except Exception as e:
        print(f"Error getting embedding: {e}")
        return None

# Try to load data
try:
    writers = pd.read_stata("already_processed_data/creators.dta")
    print("Successfully loaded creators.dta")
    print(f"Shape of writers dataframe: {writers.shape}")
    print(f"Columns in writers dataframe: {writers.columns}")
except FileNotFoundError:
    print("Error: creators.dta not found in already_processed_data directory")
    exit(1)

stories = writers['writer_story'].values
ai_ideas = writers['ai_idea_combined0'].values
conditions = writers['condition'].values

story_embeddings = []
sim_idea = []
sim_allstories = []
sim_cstories = []

print(f"Processing {len(stories)} stories...")

for row_idx, story in enumerate(stories):
    if row_idx % 10 == 0:
        print(f"Processing story {row_idx}...")
    
    if isinstance(story, str):
        story_embedding = get_embedding(story)
        if story_embedding is not None:
            story_embeddings.append(story_embedding)
        else:
            print(f"Failed to get embedding for story {row_idx}")
            story_embeddings.append([])
            sim_idea.append(None)
            continue
    else:
        print(f"Story {row_idx} is not a string")
        story_embeddings.append([])
        sim_idea.append(None)
        continue
    
    idea = ai_ideas[row_idx]
    if isinstance(idea, str):
        idea_embedding = get_embedding(idea)
        if idea_embedding is not None:
            sim_idea_score = 1 - cosine(story_embedding, idea_embedding)
            sim_idea.append(sim_idea_score)
        else:
            print(f"Failed to get embedding for idea {row_idx}")
            sim_idea.append(None)
    else:
        print(f"Idea {row_idx} is not a string")
        sim_idea.append(None)

print("Calculating similarity scores...")

for idx, story_embedding in enumerate(story_embeddings):
    if idx % 10 == 0:
        print(f"Calculating similarity for story {idx}...")
    
    if len(story_embedding) > 0:
        embeddings_allbuti = [item for item in story_embeddings if len(item) > 0 and item != story_embedding]
        if embeddings_allbuti:
            average_allbuti = np.mean(embeddings_allbuti, axis=0)
            sim_allstories_score = 1 - cosine(story_embedding, average_allbuti)
            sim_allstories.append(sim_allstories_score)
        else:
            print(f"No other valid embeddings for story {idx}")
            sim_allstories.append(None)

        condidx = conditions[idx]
        embeddings_allbutcondi = [embed for embed, cond in zip(story_embeddings, conditions) if len(embed) > 0 and cond == condidx]
        if embeddings_allbutcondi:
            average_allbutcondi = np.mean(embeddings_allbutcondi, axis=0)
            sim_cstories_score = 1 - cosine(story_embedding, average_allbutcondi)
            sim_cstories.append(sim_cstories_score)
        else:
            print(f"No other valid embeddings for condition {condidx} of story {idx}")
            sim_cstories.append(None)
    else:
        print(f"No valid embedding for story {idx}")
        sim_allstories.append(None)
        sim_cstories.append(None)

# Add new columns to the dataframe
writers['sim_idea'] = sim_idea
writers['sim_allstories'] = sim_allstories
writers['sim_cstories'] = sim_cstories

# Convert similarity scores to float type
writers['sim_idea'] = pd.to_numeric(writers['sim_idea'], errors='coerce')
writers['sim_allstories'] = pd.to_numeric(writers['sim_allstories'], errors='coerce')
writers['sim_cstories'] = pd.to_numeric(writers['sim_cstories'], errors='coerce')

# Save the updated dataframe
writers.to_csv("processed_data/creators_with_similarity.csv", index=False)

print("Story similarity analysis complete. Results saved to processed_data/creators_with_similarity.csv")
print(f"Shape of final dataframe: {writers.shape}")
print(f"Columns in final dataframe: {writers.columns}")
print("Summary of similarity scores:")
print(writers[['sim_idea', 'sim_allstories', 'sim_cstories']].describe())
print("Number of NA values in each similarity score:")
print(writers[['sim_idea', 'sim_allstories', 'sim_cstories']].isna().sum())
