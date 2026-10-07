# Blog 3: Education and unemployment, 2024
# From the repository root: source("blog/posts/post3/analysis.R", chdir = TRUE)
library(dplyr)
library(ggplot2)

# Read the data ---------------------------------------------------------
data_file <- Sys.getenv("CPS_DATA_FILE", unset = "data/cps.csv")
if (!file.exists(data_file)) {
  stop("CPS data not found. Follow README.md to obtain the CSV and set CPS_DATA_FILE.")
}
cps <- read.csv(data_file)

# Stop if a different extract was selected by mistake.
stopifnot(all(c("YEAR", "MONTH", "AGE", "SEX", "EDUC", "EMPSTAT", "WTFINL") %in% names(cps)))
stopifnot(!anyNA(cps$YEAR), all(cps$YEAR == 2024),
          !anyNA(cps$MONTH), setequal(cps$MONTH, 1:12))

print(table(cps$YEAR, cps$MONTH))

# Select adults and create groups ---------------------------------------
# Official code definitions:
# https://cps.ipums.org/cps-action/variables/EDUC
# https://cps.ipums.org/cps-action/variables/EMPSTAT
# EDUC 1 means not in universe; EDUC 2 means no schooling/preschool.
# EMPSTAT 10, 12 = employed; 20, 21, 22 = unemployed.
# Other EMPSTAT codes are not part of the civilian labor force.
adults <- cps %>%
  filter(AGE >= 25, AGE <= 64, WTFINL > 0) %>%
  mutate(
    education = case_when(
      EDUC %in% c(2, 10, 20, 30, 40, 50, 60, 71) ~ "Less than high school",
      EDUC == 73 ~ "High school graduate",
      EDUC %in% c(81, 91, 92) ~ "Some college / associate",
      EDUC %in% c(111, 123, 124, 125) ~ "Bachelor's or higher",
      TRUE ~ NA_character_
    ),
    sex = case_when(
      SEX == 1 ~ "Male",
      SEX == 2 ~ "Female",
      TRUE ~ NA_character_
    ),
    age_group = ifelse(AGE <= 44, "25-44", "45-64"),
    unemployed = EMPSTAT %in% c(20, 21, 22),
    in_labor_force = EMPSTAT %in% c(10, 12, 20, 21, 22)
  )

# Display exclusions before dropping any records.
print(adults %>% summarise(
  adult_records = n(),
  missing_education = sum(is.na(education)),
  missing_sex = sum(is.na(sex)),
  outside_labor_force_or_NIU = sum(!in_labor_force)
))

jobs <- adults %>%
  filter(in_labor_force, !is.na(education), !is.na(sex)) %>%
  mutate(education = factor(education, levels = c(
    "Less than high school", "High school graduate",
    "Some college / associate", "Bachelor's or higher"
  )))

# Each row is a person in one month, not necessarily a different person.
# Keep repeated respondents across months. Do not deduplicate these rows.
# CSV weights already contain decimals: do not divide WTFINL by 10,000.

# Calculate weighted unemployment rates --------------------------------
# Denominator: employed + unemployed people, not all adults.
# Pooling months gives a ratio of annual-average population counts.
# Both weighted totals could be divided by 12; the rate stays the same.
by_education <- jobs %>%
  group_by(education) %>%
  summarise(
    sample_records = n(),
    unemployed_records = sum(unemployed),
    weighted_labor_force = sum(WTFINL),
    weighted_unemployed = sum(WTFINL[unemployed]),
    .groups = "drop"
  ) %>%
  mutate(unemployment_rate = 100 * weighted_unemployed / weighted_labor_force)

by_sex <- jobs %>%
  group_by(education, sex) %>%
  summarise(
    sample_records = n(),
    unemployed_records = sum(unemployed),
    weighted_labor_force = sum(WTFINL),
    weighted_unemployed = sum(WTFINL[unemployed]),
    .groups = "drop"
  ) %>%
  mutate(unemployment_rate = 100 * weighted_unemployed / weighted_labor_force)

by_age <- jobs %>%
  group_by(education, age_group) %>%
  summarise(
    sample_records = n(),
    unemployed_records = sum(unemployed),
    weighted_labor_force = sum(WTFINL),
    weighted_unemployed = sum(WTFINL[unemployed]),
    .groups = "drop"
  ) %>%
  mutate(unemployment_rate = 100 * weighted_unemployed / weighted_labor_force)

print(by_education)
print(by_sex)
print(by_age)

# Save one small table for checking values.
# Weighted counts are sums of person-month weights, NOT unique annual people.
results <- bind_rows(
  by_education %>% mutate(comparison = "Overall", subgroup = "All"),
  by_sex %>% rename(subgroup = sex) %>% mutate(comparison = "Sex"),
  by_age %>% rename(subgroup = age_group) %>% mutate(comparison = "Age")
)
write.csv(results, "unemployment_summary.csv", row.names = FALSE)

# Data visualization ---------------------------------------------------
dir.create("figures", showWarnings = FALSE)
source_note <- "Source: IPUMS CPS, Jan-Dec 2024 | WTFINL weights\nCivilian labor force, ages 25-64. Descriptive estimates; no confidence intervals."
education_order <- rev(levels(jobs$education))
education_labels <- c("Bachelor's or higher", "Some college / associate",
                      "High school graduate", "Less than high school")

# Figure 1:
plot_education <- ggplot(by_education,
                         aes(x = unemployment_rate, y = education)) +
  geom_col(fill = "#287D8E", width = 0.58) +
  geom_text(aes(label = sprintf("%.1f%%", unemployment_rate)),
            hjust = -0.25, size = 4.5, color = "#23343B") +
  scale_y_discrete(limits = education_order, labels = education_labels) +
  scale_x_continuous(limits = c(0, 9), breaks = seq(0, 8, 2),
                     expand = expansion(mult = c(0, 0))) +
  labs(title = "Higher education, lower unemployment",
       subtitle = "Overall comparison | United States, 2024",
       x = "Unemployment rate (%)", y = NULL, caption = source_note) +
  theme_classic(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 19, color = "#183E4B"),
    plot.subtitle = element_text(color = "#52646D", margin = margin(b = 18)),
    axis.line.y = element_blank(), axis.ticks.y = element_blank(),
    axis.text = element_text(color = "#34454D"),
    plot.caption = element_text(hjust = 0, size = 10, color = "#52646D"),
    plot.title.position = "plot", plot.caption.position = "plot",
    plot.margin = margin(15, 22, 15, 15)
  )

# Figure 2
plot_sex <- ggplot(by_sex,
                   aes(x = unemployment_rate, y = education,
                       color = sex, shape = sex)) +
  geom_point(size = 4, position = position_dodge(width = 0.5)) +
  geom_text(aes(label = sprintf("%.1f%%", unemployment_rate)),
            position = position_dodge(width = 0.5),
            hjust = -0.45, size = 4, show.legend = FALSE) +
  scale_color_manual(values = c("Female" = "#AC580C", "Male" = "#286A91")) +
  scale_shape_manual(values = c("Female" = 17, "Male" = 16)) +
  scale_y_discrete(limits = education_order, labels = education_labels) +
  scale_x_continuous(limits = c(0, 9), breaks = seq(0, 8, 2)) +
  labs(title = "The sex gap is widest below high school",
       subtitle = "Compare women and men within each education group | 2024",
       x = "Unemployment rate (%)", y = NULL, color = NULL, shape = NULL,
       caption = source_note) +
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 19, color = "#183E4B"),
    plot.subtitle = element_text(color = "#52646D", margin = margin(b = 12)),
    panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(color = "#E0E7EA"),
    axis.text = element_text(color = "#34454D"),
    legend.position = "top", legend.justification = "left",
    plot.caption = element_text(hjust = 0, size = 10, color = "#52646D"),
    plot.title.position = "plot", plot.caption.position = "plot",
    plot.margin = margin(15, 22, 15, 15)
  )

# Figure 3
plot_age <- ggplot(by_age,
                   aes(x = age_group, y = education, fill = unemployment_rate)) +
  geom_tile(color = "white", linewidth = 2, width = 0.96, height = 0.92) +
  geom_text(aes(label = sprintf("%.1f%%", unemployment_rate),
                color = unemployment_rate >= 5),
            size = 5.5, fontface = "bold", show.legend = FALSE) +
  scale_color_manual(values = c("FALSE" = "#183E4B", "TRUE" = "white")) +
  scale_fill_gradient(low = "#F1F6FA", high = "#155273", limits = c(0, 9),
                      breaks = c(0, 3, 6, 9), name = "Rate (%)") +
  scale_y_discrete(limits = education_order, labels = education_labels,
                   expand = expansion(add = 0.05)) +
  scale_x_discrete(labels = c("25-44" = "Ages 25-44", "45-64" = "Ages 45-64"),
                   position = "top", expand = expansion(add = 0.05)) +
  labs(title = "Younger adults have higher rates in every group",
       subtitle = "Read across for age differences; down for education | 2024",
       x = NULL, y = NULL, caption = source_note) +
  theme_light(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 18, color = "#183E4B"),
    plot.subtitle = element_text(color = "#52646D", margin = margin(b = 16)),
    panel.grid = element_blank(), panel.border = element_blank(),
    axis.ticks = element_blank(), axis.text = element_text(color = "#34454D"),
    axis.text.x = element_text(face = "bold"), legend.position = "bottom",
    plot.caption = element_text(hjust = 0, size = 10, color = "#52646D"),
    plot.title.position = "plot", plot.caption.position = "plot",
    plot.margin = margin(15, 22, 15, 15)
  )

ggsave("figures/unemployment_education.png", plot_education, width = 10, height = 5.8, dpi = 200)
ggsave("figures/unemployment_sex.png", plot_sex, width = 10, height = 6.3, dpi = 200)
ggsave("figures/unemployment_age.png", plot_age, width = 10, height = 6.3, dpi = 200)

if (interactive()) {
  print(plot_education)
  print(plot_sex)
  print(plot_age)
}
