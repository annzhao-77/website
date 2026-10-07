# Blog 3: Education and Unemployment

[Repository guide](../../../README.md) | [Blog source](index.qmd) | [Analysis script](analysis.R) | [Results](unemployment_summary.csv) | [Figures](figures/)

## Files at a glance

| File | Purpose |
| --- | --- |
| [analysis.R](analysis.R) | Reads your CPS extract, calculates weighted rates, and saves the table and three plots |
| [unemployment_summary.csv](unemployment_summary.csv) | Saved values underlying all three plots |
| [figures/](figures/) | Generated plots and any blog illustrations |
| [index.qmd](index.qmd) | Blog narrative displaying the saved figures |

The original CPS microdata are not included. Obtain your own extract below; the saved summary and figures can be inspected without downloading it.

## Research question

How does unemployment vary by educational attainment among U.S. adults aged 25–64? The figures compare education groups overall, by sex, and by age group (25–44 and 45–64).

## Data source and samples

- Source: IPUMS Current Population Survey (CPS), https://cps.ipums.org/cps/.
- Selected samples: all 12 Basic Monthly samples from January through December 2024.
- Extract format: CSV; rectangular (cross-sectional) structure.
- Download date: September 27, 2026.

## Variables

| Variable | Meaning and use |
| --- | --- |
| YEAR | Survey year; check that all records are from 2024. |
| MONTH | Survey month; check that months 1–12 are present. |
| AGE | Age; restrict the analysis to ages 25–64. |
| SEX | Sex; compare male and female respondents. |
| EDUC | Educational attainment; construct education groups using the codebook. |
| EMPSTAT | Employment status; identify employed and unemployed civilians. |
| WTFINL | Final Basic Weight; use for population estimates from Basic Monthly samples. |

Education groups: less than high school; high school graduate; some college or associate degree; bachelor's degree or higher. The numeric codes used are documented below and in the script.

## How to download the same data

1. Register for an IPUMS account if needed, sign in at https://cps.ipums.org/cps/, and open **Select Data**.
2. Click **Select Samples**. Select the 12 Basic Monthly samples for 2024, January through December. Remove other years and all ASEC samples, then confirm the selection.
3. Keep **Harmonized Variables** selected. Search for and add YEAR, MONTH, AGE, SEX, EDUC, EMPSTAT, and WTFINL. Some variables may already be selected.
4. Open **View Cart**. Check that the selected samples are exactly the 12 months of 2024 and that all seven variables are included.
5. Click **Create Data Extract**. Choose **CSV** and **Rectangular (cross-sectional)**. Leave case selection and other optional settings unchanged.
6. Enter an extract description such as `2024 CPS: Education and Unemployment`, then click **Submit Extract**.
7. Once processing finishes, download the data file and its codebook. Save the citation supplied by IPUMS for the blog. Extract numbers and filenames may differ between users.

## Local data and reading it in R

Keep your downloaded data outside the repository. If the download ends in `.csv.gz`, decompress it to a `.csv` first. Set its location in your R session; no personal computer path is embedded in the analysis script:

```r
# Replace this example with the full path to your own CSV.
Sys.setenv(CPS_DATA_FILE = "C:/path/to/your/cps_00001.csv")
```

Set this variable again after restarting R. Alternatively, create a `data` folder inside `post3` and save the CSV as `data/cps.csv`; this is the default path. The local `.gitignore` excludes this folder and standard CPS data filenames. Keep the codebook with your local data. The script checks the seven required variables, year 2024, and the presence of all 12 months.

## Analysis definitions

- Keep adults aged 25–64 and valid observations for the variables used in each comparison.
- The unemployment-rate denominator is the civilian labor force: employed plus unemployed people. People outside the labor force are not counted in this denominator.
- For each group, calculate `100 * sum(weights of unemployed people) / sum(weights of people in the labor force)`, using WTFINL.
- Pool all 12 months. The resulting rate is the ratio of annual-average weighted unemployment to annual-average weighted labor force. Dividing both totals by 12 gives the same rate; it is not necessarily the simple average of the 12 monthly percentages.
- CPS respondents can appear in multiple months. Keep these person-month observations; do not describe the number of rows as the number of unique people surveyed during the year.
- These are descriptive associations, not estimates of the causal effect of education. Any future uncertainty estimates would need to account for the CPS survey design and repeated observations.

Weight documentation: https://cps.ipums.org/cps-action/variables/WTFINL.

## Run the analysis

Open `studentname-website.Rproj` at the repository root. Run in the R Console:

```r
install.packages(c("dplyr", "ggplot2")) # once
Sys.setenv(CPS_DATA_FILE = "C:/path/to/your/cps_00001.csv") # your actual path
source("blog/posts/post3/analysis.R", chdir = TRUE)
```

`chdir = TRUE` temporarily uses the script's folder for its output paths. Alternatively, open the script in RStudio, select **Session > Set Working Directory > To Source File Location**, set `CPS_DATA_FILE`, and click **Source**. Tested with R 4.5.3.

For the original extract, expect 1,187,356 person-month records and 468,745 records in the final analysis. Overall unemployment rates, in education order from lowest to highest, round to 6.3%, 4.4%, 3.4%, and 2.3%. Later source revisions may change results. Review printed month and exclusion counts if your results differ.

Outputs generated by the script:

- `unemployment_summary.csv`: overall, sex-specific, and age-specific results. Rates are percentages. Sample counts are unweighted person-month records; weighted counts are sums across all months, not unique annual populations.
- `figures/unemployment_education.png`
- `figures/unemployment_sex.png`
- `figures/unemployment_age.png`

Code definitions used for 2024: EDUC 2, 10, 20, 30, 40, 50, 60, 71 = less than high school; 73 = high school graduate; 81, 91, 92 = some college or associate degree; 111, 123, 124, 125 = bachelor's or higher. EMPSTAT 10 and 12 = employed; 20, 21 and 22 = unemployed. Other employment statuses are excluded from the unemployment-rate denominator. SEX 1 = male and 2 = female. Missing or unclassified education/sex records and nonpositive weights are excluded. The CSV weight is already decimal-adjusted.

Variable documentation: [EDUC](https://cps.ipums.org/cps-action/variables/EDUC), [EMPSTAT](https://cps.ipums.org/cps-action/variables/EMPSTAT), [SEX](https://cps.ipums.org/cps-action/variables/SEX).

## Write and preview the blog

### Figure design

Following Class 8's emphasis on clear comparisons, meaningful colors, direct labels, and reproducible exports:

- Overall education comparison: horizontal bars with `theme_classic()`. Bar length shows the rate from a zero baseline.
- Sex comparison: horizontal grouped dots with `theme_minimal()`. Orange triangles and blue circles distinguish women and men; a small vertical offset avoids overlap. Compare horizontal positions within each education group.
- Age comparison: a labeled heatmap with `theme_light()`. Darker blue indicates a higher unemployment rate. Read across rows to compare ages and down columns to compare education groups.

All three keep education groups in the same order, identify the population and source, and display rates to one decimal place. Themes are customized using `theme()` and `element_text()`; no additional R packages are required. Chart titles describe the observed estimates, not causal effects or statistically significant differences.

Edit the blog narrative in [index.qmd](index.qmd). Keep the formal IPUMS citation with the article. If the YAML header contains `draft: true`, remove it or change it to `draft: false` when ready to publish.

After running the R script, preview `index.qmd` using RStudio's **Render** button. To render from a terminal at the website root (`website1`), run `quarto render blog/posts/post3/index.qmd`. The QMD displays the saved figures; rendering it does not rerun the analysis.
