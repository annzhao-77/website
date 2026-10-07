# Blog 4: Economic prosperity and life expectancy
# From the repository root: source("blog/posts/post4/worldbank_analysis.R", chdir = TRUE)
# Set the working directory to post4 before running this script.
# RStudio: Session > Set Working Directory > To Source File Location.
# Install once: install.packages(c("WDI", "dplyr", "ggplot2"))
library(WDI)
library(dplyr)
library(ggplot2)

# 1. Download data --------------------------------------------------------
# Keep a local snapshot so rerunning does not silently change the data.
# Set refresh_data to TRUE only when you want a new World Bank download.
refresh_data <- FALSE
dir.create("data", showWarnings = FALSE)
dir.create("figures", showWarnings = FALSE)

if (refresh_data | !file.exists("data/worldbank_data.csv")) {
  wb <- WDI(
    country = "all",
    indicator = c(gdp_per_capita = "NY.GDP.PCAP.PP.KD",
                  life_expectancy = "SP.DYN.LE00.IN"),
    start = 2000, end = 2024, extra = TRUE
  )
  wb$download_date <- as.character(Sys.Date())
  write.csv(wb, "data/worldbank_data.csv", row.names = FALSE)
} else {
  wb <- read.csv("data/worldbank_data.csv")
}

# 2. Clean and check coverage --------------------------------------------
# Remove regional/income/world aggregates, not individual economies.
# Do not replace missing observations with zero.
countries <- wb %>%
  filter(!is.na(region), region != "Aggregates")

# Each economy should occur only once in each year.
stopifnot(all(c("iso3c", "year", "gdp_per_capita", "life_expectancy") %in% names(countries)))
stopifnot(!anyNA(countries$iso3c), all(nzchar(countries$iso3c)),
          !anyDuplicated(countries[c("iso3c", "year")]))

coverage <- countries %>%
  group_by(year) %>%
  summarise(
    economies = n(),
    complete_pairs = sum(!is.na(gdp_per_capita) & gdp_per_capita > 0 &
                           !is.na(life_expectancy)),
    .groups = "drop"
  )
print(coverage)
write.csv(coverage, "data/coverage.csv", row.names = FALSE)

# Explicit endpoints: check coverage before changing these years.
start_year <- 2000
end_year <- 2024
latest <- countries %>%
  filter(year == end_year, !is.na(gdp_per_capita), gdp_per_capita > 0,
         !is.na(life_expectancy))
stopifnot(nrow(latest) > 0, !anyDuplicated(latest$iso3c))
write.csv(latest, "data/latest_year.csv", row.names = FALSE)

baseline <- countries %>%
  filter(year == start_year, !is.na(gdp_per_capita), gdp_per_capita > 0,
         !is.na(life_expectancy)) %>%
  select(iso3c, gdp_start = gdp_per_capita, life_start = life_expectancy)

# Join by country code, keeping only economies observed at both endpoints.
changes <- latest %>%
  inner_join(baseline, by = "iso3c") %>%
  mutate(
    gdp_growth = 100 * (gdp_per_capita / gdp_start - 1),
    life_gain = life_expectancy - life_start
  )
write.csv(changes, "data/country_changes.csv", row.names = FALSE)
cat("Economies in 2024 figures:", nrow(latest), "\n")
cat("Economies in the change figure:", nrow(changes), "\n")

# Every economy is one observation; these are NOT population distributions.
# Regions are the metadata returned with this download, not historical groups.

# 3. Figures 1-2: separate distributions ----------------------------------
# Explicit bin widths and boundaries make the intervals easy to interpret.
# A bar counts economies in an interval, not at a single GDP value.
plot_gdp <- ggplot(latest, aes(x = gdp_per_capita)) +
  geom_histogram(binwidth = 5000, boundary = 0, closed = "left",
                 fill = "#287D8E", color = "white", linewidth = 0.4) +
  scale_x_continuous(breaks = seq(0, 150000, 25000),
                     labels = scales::label_number(big.mark = ","),
                     expand = expansion(mult = c(0, 0.02))) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(title = "The distribution of economic prosperity",
       subtitle = paste(end_year, "|", nrow(latest), "economies | Each bin spans 5,000 international dollars"),
       x = "GDP per capita (PPP, constant 2021 international $)",
       y = "Number of economies",
       caption = "Source: World Bank WDI. Each economy counts once.\nThe first bar covers 0 to <5,000; it does not mean GDP per capita equals zero.") +
  theme_light(base_size = 13) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0))

plot_life <- ggplot(latest, aes(x = life_expectancy)) +
  geom_histogram(binwidth = 2, boundary = 0, closed = "left",
                 fill = "#C06B20", color = "white", linewidth = 0.4) +
  scale_x_continuous(breaks = seq(50, 90, 5)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.08))) +
  labs(title = "The distribution of life expectancy",
       subtitle = paste(end_year, "|", nrow(latest), "economies | Each bin spans 2 years"),
       x = "Life expectancy at birth (years)", y = "Number of economies",
       caption = "Source: World Bank WDI. Each economy counts once.\nSame complete-case sample as the GDP histogram; not the distribution of individual lifespans.") +
  theme_light(base_size = 13) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(hjust = 0))
# 4. Figure 3: prosperity and life expectancy -----------------------------
# Model: life expectancy = intercept + slope * log(GDP per capita).
# This line summarizes association; it is NOT a causal effect.
# Each economy receives equal weight in the fit.
fit <- lm(life_expectancy ~ log(gdp_per_capita), data = latest)
fit_line <- data.frame(gdp_per_capita = exp(seq(
  log(min(latest$gdp_per_capita)), log(max(latest$gdp_per_capita)), length.out = 150
)))
fit_line$life_expectancy <- predict(fit, newdata = fit_line)
print(summary(fit)$coefficients)
write.csv(data.frame(term = names(coef(fit)), estimate = unname(coef(fit))),
          "data/model_coefficients.csv", row.names = FALSE)

# Fix region colors so they are consistent in both scatterplots.
region_names <- sort(unique(latest$region))
region_colors <- setNames(
  c("#286A91", "#C06B20", "#6C659B", "#238779", "#A34E70",
    "#77813A", "#765741", "#5F7280")[seq_along(region_names)], region_names
)
stopifnot(!anyNA(region_colors))

plot_relationship <- ggplot(latest, aes(x = gdp_per_capita, y = life_expectancy)) +
  geom_point(aes(color = region), size = 2.5, alpha = 0.8) +
  geom_line(data = fit_line, color = "#26343D", linewidth = 0.9) +
  scale_x_log10(breaks = c(1000, 3000, 10000, 30000, 100000),
                labels = scales::label_number(big.mark = ",")) +
  scale_color_manual(values = region_colors) +
  labs(title = "Are richer economies associated with longer lives?",
       subtitle = paste(end_year, "| Each point represents one economy"),
       x = "GDP per capita (PPP, constant 2021 international $; log scale)",
       y = "Life expectancy at birth (years)", color = NULL,
       caption = "Source: World Bank WDI. Line: OLS fit of life expectancy on log GDP per capita.\nEqual weight per economy; descriptive association, not causation. No confidence band shown.") +
  theme_classic(base_size = 12) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom", legend.text = element_text(size = 9),
        plot.caption = element_text(hjust = 0)) +
  guides(color = guide_legend(ncol = 2, override.aes = list(alpha = 1)))

# 5. Figure 4: growth and longevity gains --------------------------------
# GDP change is cumulative percentage growth, not an annual growth rate.
# Life expectancy change is in years, not percent.
plot_changes <- ggplot(changes, aes(x = gdp_growth, y = life_gain)) +
  geom_hline(yintercept = 0, color = "#8C969B", linetype = "dashed") +
  geom_vline(xintercept = 0, color = "#8C969B", linetype = "dashed") +
  geom_point(aes(color = region), size = 2.6, alpha = 0.8) +
  scale_color_manual(values = region_colors) +
  labs(title = "Does faster growth accompany larger longevity gains?",
       subtitle = paste(start_year, "to", end_year, "|", nrow(changes), "economies observed in both years"),
       x = "Real GDP per capita growth (%)", y = "Life expectancy gain (years)",
       color = NULL,
       caption = "Source: World Bank WDI. GDP uses PPP, constant 2021 international dollars.\nChanges compare endpoints, not the path between them. No population weighting.") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"), panel.grid.minor = element_blank(),
        legend.position = "bottom", legend.text = element_text(size = 9),
        plot.caption = element_text(hjust = 0)) +
  guides(color = guide_legend(ncol = 2, override.aes = list(alpha = 1)))

# 6. Save the four figures ----------------------------------------------
ggsave("figures/gdp_distribution.png", plot_gdp, width = 10, height = 6, dpi = 200)
ggsave("figures/life_expectancy_distribution.png", plot_life, width = 10, height = 6, dpi = 200)
ggsave("figures/prosperity_longevity.png", plot_relationship, width = 10, height = 7.5, dpi = 200)
ggsave("figures/growth_longevity.png", plot_changes, width = 10, height = 7.5, dpi = 200)

if (interactive()) {
  print(plot_gdp)
  print(plot_life)
  print(plot_relationship)
  print(plot_changes)
}
