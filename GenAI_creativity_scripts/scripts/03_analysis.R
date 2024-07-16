# 03_analysis.R

library(tidyverse)
library(lmtest)
library(sandwich)
library(ggplot2)
library(broom)
library(stargazer)
library(haven)

print(paste("Current working directory:", getwd()))

# Load data
writers <- read_csv("processed_data/creators_with_similarity.csv")
print("Successfully loaded creators_with_similarity.csv")
print(paste("Shape of writers dataframe:", nrow(writers), "rows,", ncol(writers), "columns"))
print("Columns in writers dataframe:")
print(colnames(writers))

# Drop admitted to using GenAI
writers <- writers %>% filter(!human_admitted)

# Define high-ability writers (above median DAT score)
dat_median <- median(writers$dat, na.rm = TRUE)
writers <- writers %>% mutate(high_ability = dat > dat_median)

# Print summary of condition and high_ability
print("Summary of condition:")
print(table(writers$condition))
print("Summary of high_ability:")
print(table(writers$high_ability))
print("Cross-tabulation of condition and high_ability:")
print(table(writers$condition, writers$high_ability))

# Compute mean and sd of similarity scores
similarity_summary <- writers %>%
  group_by(condition, high_ability) %>%
  summarise(
    mean_similarity = mean(sim_cstories, na.rm = TRUE),
    sd_similarity = sd(sim_cstories, na.rm = TRUE),
    n = n(),
    na_count = sum(is.na(sim_cstories))
  ) %>%
  arrange(high_ability, condition)

print("Summary of similarity scores:")
print(similarity_summary)

# Save summary to file
write.csv(similarity_summary, "tables_graphs/writers/similarity_summary.csv", row.names = FALSE)

# Perform ANOVA
model <- aov(sim_cstories ~ condition * high_ability, data = writers)
print("ANOVA results:")
print(summary(model))

# Perform pairwise t-tests
print("Pairwise t-tests for condition:")
print(pairwise.t.test(writers$sim_cstories, writers$condition, p.adjust.method = "bonferroni"))

print("Pairwise t-tests for high ability:")
print(t.test(sim_cstories ~ high_ability, data = writers))

# Perform t-tests for high-ability writers across conditions
high_ability_writers <- writers %>% filter(high_ability == TRUE)

print("T-test results (High ability: Human only vs Human with 1 GenAI idea):")
print(t.test(sim_cstories ~ condition, data = high_ability_writers %>% 
             filter(condition %in% c("Human only", "Human with 1 GenAI idea"))))

print("T-test results (High ability: Human only vs Human with 5 GenAI ideas):")
print(t.test(sim_cstories ~ condition, data = high_ability_writers %>% 
             filter(condition %in% c("Human only", "Human with 5 GenAI ideas"))))

# Create boxplot
p <- ggplot(writers, aes(x = condition, y = sim_cstories, fill = high_ability)) +
  geom_boxplot() +
  theme_minimal() +
  labs(title = "Story Similarity by Condition and Writer Ability",
       x = "Condition",
       y = "Similarity Score",
       fill = "High Ability") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("tables_graphs/writers/similarity_boxplot.png", plot = p, width = 10, height = 6)

print("Analysis complete. Results can be found in the tables_graphs/writers directory.")
