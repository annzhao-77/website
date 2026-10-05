# Blog 4: Richer Countries, Longer Lives?

## Question and data

How is economic prosperity associated with life expectancy across economies, and does faster economic growth accompany larger longevity gains?

Source: World Bank, World Development Indicators (WDI), accessed programmatically through the public API using the R package `WDI`. No account or API key is required.

| Indicator | Code | Meaning |
| --- | --- | --- |
| GDP per capita, PPP (constant 2021 international dollars) | NY.GDP.PCAP.PP.KD | Average economic output per person, adjusted for purchasing power and prices over time. Not personal income or household wealth. |
| Life expectancy at birth, total (years) | SP.DYN.LE00.IN | Years a newborn would live if prevailing age-specific mortality patterns remained the same. Not the average age of people currently alive. |

Request all economies and years 2000–2024, with country codes and region metadata. Exclude World Bank aggregates (world, regions and income groups). Keep only positive, nonmissing GDP and nonmissing life expectancy for each comparison. Do not impute missing values or treat them as zero.

## Files and replication

- `worldbank_analysis.R`: download, cleaning, analysis, and plotting in one script.
- `data/worldbank_data.csv`: downloaded snapshot, including source metadata and retrieval date. Retaining the file preserves the data version used for this blog.
- `data/coverage.csv`: annual country coverage and number of complete indicator pairs.
- `data/country_changes.csv`: endpoint values and computed changes for matched economies.
- `figures/`: four programmatically saved PNGs.
- `index.qmd`: blog opening and writing framework, initially marked as a draft.

1. Open `worldbank_analysis.R` in RStudio.
2. Set the working directory to this `post4` folder: **Session > Set Working Directory > To Source File Location**.
3. Install packages once: `install.packages(c("WDI", "dplyr", "ggplot2"))`.
4. Run the whole script with **Source**. Internet access is required for the initial download. Subsequent runs use the saved CSV. Setting `refresh_data <- TRUE` deliberately replaces the snapshot with a new download, which may contain revisions.
5. Check the coverage table and plotted results. Continue writing in `index.qmd` and use **Render** to preview. The QMD uses saved figures and does not rerun the analysis.
6. From the website root, the equivalent render command is `quarto render blog/posts/post4/index.qmd`. Change `draft: true` to `draft: false` when ready to publish.

## Four figures and calculations

The initial download contains 217 individual economies per year. In 2024, 195 have valid values for both indicators (22 are excluded from the first three figures). Of those 195, 189 also have complete 2000 values and enter the change comparison. These are data-availability samples, not a claim to cover every economy equally well.

1. **GDP distribution:** a separate histogram with bins of 5,000 international dollars, anchored at zero. The first interval is [0, 5,000), not a count of zero-GDP economies. Saved as `gdp_distribution.png`.
2. **Life expectancy distribution:** a separate histogram with two-year bins, saved as `life_expectancy_distribution.png`. Both histograms use the same 195 complete-case economies in 2024, one observation per economy regardless of population.
3. **Levels:** 2024 GDP per capita versus life expectancy, with a log GDP axis and OLS fit `life_expectancy ~ log(gdp_per_capita)`. Every economy receives equal weight. No causal interpretation or confidence band is provided.
4. **Changes:** keep only economies with valid observations in both 2000 and 2024. GDP growth = `100 * (GDP_2024 / GDP_2000 - 1)`; life expectancy gain = `LE_2024 - LE_2000`. Growth is cumulative, not annualized. Dashed zero lines distinguish increases and decreases. Regions use the metadata from the download, not historical classifications.

PPP allows better cross-country price comparisons; constant prices support comparisons over time; per-capita measures account for population size. Logarithmic positioning makes differences at low and high income levels readable. Country-level findings cannot be interpreted as individual-level income effects. Endpoint changes do not describe the entire time path. Missingness, source estimates and revisions, inequality, health systems, conflict and other unmeasured factors limit interpretation.

## Sources

- GDP: https://data.worldbank.org/indicator/NY.GDP.PCAP.PP.KD
- Life expectancy: https://data.worldbank.org/indicator/SP.DYN.LE00.IN
- API documentation: https://datahelpdesk.worldbank.org/knowledgebase/articles/889392
- World Bank indicator pages provide underlying sources and license information (CC BY 4.0 for these indicators).
