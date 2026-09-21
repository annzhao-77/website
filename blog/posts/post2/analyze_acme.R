# ACME: which skills are mentioned, and how do they differ by job type?
library(dplyr)
library(stringr)
library(ggplot2)

setwd("C:/Users/DELL/Desktop/AEDS 6400/website1/blog/posts/post2")
if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", ".UTF-8")

# 1. Read and check the data. One row should mean one job posting.
jobs <- read.csv("acme_jobs.csv", fileEncoding = "UTF-8", stringsAsFactors = FALSE)
stopifnot(!anyDuplicated(jobs$job_id), all(jobs$banner == "ACME Markets"))
stopifnot(all(!is.na(jobs$requirements)), all(nzchar(jobs$requirements)))
cat("Job postings:", nrow(jobs), "\n")

# 2. Group titles into job types.
jobs <- jobs %>%
  mutate(job_type = case_when(
    str_detect(title, regex("pharmac", ignore_case = TRUE)) ~ "Pharmacy",
    str_detect(title, regex("manager|director|supervisor", ignore_case = TRUE)) ~ "Management",
    str_detect(title, regex("refrigeration", ignore_case = TRUE)) ~ "Maintenance",
    str_detect(title, regex("front end|customer service", ignore_case = TRUE)) ~ "Front end",
    str_detect(title, regex("shopper", ignore_case = TRUE)) ~ "Online order picking",
    str_detect(title, regex("stocker|store support", ignore_case = TRUE)) ~ "Stocking / store support",
    str_detect(title, regex("deli|produce|meat|seafood|bakery|baker|cake|dairy|barista|beverage", ignore_case = TRUE)) ~ "Food / beverage",
    TRUE ~ "Other"
  ))
job_counts <- jobs %>% count(job_type, name = "postings") %>% arrange(desc(postings))
print(job_counts)

# 3. Define skill categories and phrases before counting.
# Age, degrees, licenses, lifting, shifts, and enthusiasm are not counted as skills.
skills <- data.frame(
  skill = c("Teamwork", "Communication",
    "Organization / time management", "Attention to detail", "Food preparation",
    "Food safety / sanitation", "Digital tools", "Inventory / merchandising",
    "Cash handling", "Leadership / coaching", "Problem solving",
    "Numeracy / finance", "Creativity"),
  pattern = c(
    "teamwork|team collaboration|ability to contribute effectively|ability to work independently as well as within a large team|coordinating order needs with team members",
    "communicat|interpersonal",
    "organizational skills|organization|organizational|organized|time management|multi-task|multitask|managing multiple|prioritize tasks|prioritization|manage workflow",
    "attention to detail|eye for detail|observational skills|accuracy|accurately|precision",
    "food prep experience|food preparation skills|knife skills|food preparation equipment|deli preparation techniques|deli production|experience preparing deli",
    "food safety|food handling|sanitation|sanitary",
    "computer|handheld|digital order|technology use|store systems|ordering platforms|workforce management tools|financial analysis platforms",
    "inventory|stocking|stock levels|rotate stock|merchandising|shrink management|shrink control",
    "cash handling|cash register|counting money|cash transactions|transaction handling|counting change|balancing registers",
    "leadership|coaching|supervisory|supervisor|manage people|team development|train, coach|supervising",
    "problem-solving|problem solving|problem awareness|identify needs, problems|maintain composure",
    "basic math|accounting|financial knowledge|financial analysis|profit and loss|financial platforms|strong analytical",
    "artistic and creative skillset|creative skills|artistic skills"
  )
)

# "Helping customers and fellow associates gives you energy" is NOT teamwork.
# Enjoying a team-based environment is also not an explicit collaboration ability.
# Food interests and general pride in work are not food preparation/detail skills.

# Normalize different hyphen characters; remove trailing pay/workplace prose.
jobs <- jobs %>% mutate(
  text = str_to_lower(requirements),
  text = str_replace_all(text, "[\u2010-\u2015]", "-"),
  text = str_remove(text, "(?s)(physical environment:|pay transparency:).*$")
)
jobs <- jobs %>% mutate(service_language = str_detect(text,
  "customer service|customer-service|customer interaction|helping customers|assist customers|assisting customers|assisting patients"))
cat("General service language (excluded from skill rankings):", sum(jobs$service_language), "\n")

# Check one skill at a time and add its results to a table.
# str_extract() returns the first matched phrase, or NA if nothing matches.
skill_results <- data.frame()
for (i in 1:nrow(skills)) {
  matched_phrase <- str_extract(jobs$text, skills$pattern[i])
  one_skill <- data.frame(
    job_id = jobs$job_id, title = jobs$title, job_type = jobs$job_type,
    skill = skills$skill[i], matched_phrase = matched_phrase,
    mentioned = !is.na(matched_phrase)
  )
  skill_results <- rbind(skill_results, one_skill)
}
# A simple table to inspect when checking the classification.
skill_evidence <- skill_results %>% filter(mentioned)

# 4. Overall frequency. The denominator includes all 118 postings.
skill_summary <- skill_results %>%
  group_by(skill) %>%
  summarise(postings = sum(mentioned), .groups = "drop") %>%
  mutate(percent = postings / nrow(jobs) * 100) %>%
  arrange(desc(postings))
print(skill_summary)

# Remember: many stores use the same wording, so postings are not unique templates.
cat("Distinct requirement texts:", n_distinct(jobs$text), "\n")

# 5. Compare percentages WITHIN each job type, not raw numbers across types.
by_type <- skill_results %>%
  group_by(job_type, skill) %>%
  summarise(postings = n(), mentions = sum(mentioned), .groups = "drop") %>%
  mutate(percent = mentions / postings * 100)

# 6. Make three figures. Only the figures are saved; analysis tables stay in R.
dir.create("figures", showWarnings = FALSE)
theme_set(theme_minimal(base_size = 12))
source_note <- paste0("Source: ACME career postings, collected 20 Sep 2026 | N = ", nrow(jobs), ".")

p1 <- ggplot(job_counts, aes(x = postings, y = reorder(job_type, postings))) +
  geom_col(fill = "#215E78", width = 0.65) +
  geom_text(aes(label = postings), hjust = -0.3, size = 4) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(title = "Which job types are in the sample?", subtitle = "Job types grouped from posting titles",
       x = "Number of postings", y = NULL, caption = source_note) +
  theme(panel.grid.major.y = element_blank())
ggsave("figures/job_types.png", p1, width = 10, height = 5.5, dpi = 180, bg = "white")

p2 <- ggplot(skill_summary, aes(x = percent, y = reorder(skill, percent))) +
  geom_col(fill = "#B53B46", width = 0.65) +
  geom_text(aes(label = sprintf("%d (%.1f%%)", postings, percent)), hjust = -0.15, size = 3.6) +
  scale_x_continuous(labels = scales::label_percent(scale = 1),
                     expand = expansion(mult = c(0, 0.25))) +
  labs(title = "Which specific skills are mentioned most often?", subtitle = "Explicit skill phrases; general service attitudes excluded",
       x = "Share of all postings", y = NULL,
       caption = paste(source_note, "\nEach skill counted once per posting; required/preferred mentions combined. Repeated templates retained.")) +
  theme(panel.grid.major.y = element_blank())
ggsave("figures/skill_frequency.png", p2, width = 11, height = 8, dpi = 180, bg = "white")

# Show groups with at least five postings; smaller groups are too sparse here.
heatmap_data <- by_type %>% filter(postings >= 5) %>%
  mutate(group_label = paste0(job_type, "\n(n = ", postings, ")"),
         skill = factor(skill, levels = rev(skill_summary$skill)))
p3 <- ggplot(heatmap_data, aes(x = group_label, y = skill, fill = percent)) +
  geom_tile(color = "white", linewidth = 0.6) +
  geom_text(aes(label = sprintf("%.0f%%", percent), color = percent >= 55), size = 3.4) +
  scale_color_manual(values = c("FALSE" = "#243A48", "TRUE" = "white"), guide = "none") +
  scale_fill_gradient(low = "#F0F4F6", high = "#18516B", limits = c(0, 100), name = "Share (%)") +
  labs(title = "How do specific skill mentions differ by job type?", subtitle = "General service attitudes excluded; groups with at least 5 postings",
       x = NULL, y = NULL,
       caption = paste(source_note, "\nPharmacy (n = 3) and maintenance (n = 1) omitted here. 0% means no matched phrase, not no skill needed.")) +
  theme(panel.grid = element_blank(), axis.text.x = element_text(size = 10))
ggsave("figures/skills_by_job_type.png", p3, width = 12, height = 8, dpi = 180, bg = "white")

if (interactive()) {
  print(p1)
  print(p2)
  print(p3)
}
# Main RStudio tables: jobs, skills, skill_results, skill_summary, by_type.
# These are descriptive text frequencies, not hiring probabilities or causal effects.
