# Blog 2: ACME Job Skills

**Research question:** Which specific skills appear most often in ACME job requirements near Philadelphia, and how do mentions differ across job types?

[Back to repository guide](../../../README.md) | [Blog source](index.qmd) | [Analysis script](analyze_acme.R) | [Scraping script](scrape_acme.R)

## Files

| File or folder | Purpose |
| --- | --- |
| [acme_jobs.csv](acme_jobs.csv) | Historical input snapshot: 118 ACME postings, one row per job ID |
| [analyze_acme.R](analyze_acme.R) | Reads the snapshot, classifies jobs and skill phrases, calculates percentages, saves tables and plots |
| [scrape_acme.R](scrape_acme.R) | Optional collection from the live careers site |
| [results/](results/) | Generated job_counts.csv, skill_summary.csv, skills_by_job_type.csv |
| [figures/](figures/) | Generated job_types.png, skill_frequency.png, skills_by_job_type.png; also contains blog illustrations |
| [index.qmd](index.qmd) | Blog narrative and links to saved figures |

## Reproduce the historical analysis (recommended)

Requirements: R with `dplyr`, `stringr`, and `ggplot2`. The code has been run using R 4.5.3. Quarto is needed only to render the blog.

1. Download or clone the repository. Open `studentname-website.Rproj` at its root in RStudio.
2. In the R Console, install packages once:

```r
install.packages(c("dplyr", "stringr", "ggplot2"))
```

3. From the repository root, run:

```r
source("blog/posts/post2/analyze_acme.R", chdir = TRUE)
```

`chdir = TRUE` temporarily runs the script inside its own folder, so relative file paths work on another computer. Alternatively, open the script, select **Session > Set Working Directory > To Source File Location**, and click **Source**.

4. Inspect the three generated CSVs in `results/` and three PNGs in `figures/`. The included snapshot should produce 118 unique postings and 26 distinct cleaned requirement texts. Organization/time management has 37 mentions; communication and attention to detail each have 34. The script checks unique IDs, the ACME banner, and nonempty requirements.
5. From the repository root, run `quarto render blog/posts/post2/index.qmd` in a terminal. Rendering uses saved PNGs; it does not run the R script automatically.

## Data source and scope

Source: [Albertsons Companies careers — Philadelphia +25 km](https://eofd.fa.us6.oraclecloud.com/hcmUI/CandidateExperience/en/sites/CX_1001/jobs?location=Philadelphia%2C+PA%2C+United+States&locationId=300000002802382&locationLevel=city&mode=location&radius=25&radiusUnit=KM).

The snapshot was collected on September 20, 2026. The accepted scope is 118 retrievable ACME postings; the website counter displayed 119. Some returned postings cover regional or multiple locations, so the sample reflects the website search results rather than an independently verified geographic boundary.

Columns contain the job title, ID, category, posting date, application deadline, schedule, locations, banner, and requirements text. Missing fields are blank. Some requirements use a Qualifications or equivalent heading.

## Method and generated results

The script groups job titles into job types and matches an explicit skill-phrase dictionary against cleaned requirements. Each skill counts at most once per posting. Overall percentages use all 118 postings; job-type percentages use the number of postings within that type. Required and preferred mentions are combined. Repeated templates remain in the posting-level analysis.

General customer-service attitudes are excluded from skill rankings. Enjoying a team environment or helping colleagues alone is not classified as teamwork. The `skills` object contains the patterns; `skill_evidence` retains matching phrases for inspection in R. These are text mentions, not exhaustive measures of needed skills, hiring probabilities, or causal effects.

The heatmap displays job types with at least five postings. The saved `skills_by_job_type.csv` includes all job types, including smaller groups omitted from the plot.

## Optional: collect a new live sample

This is separate from reproducing the historical results. Live vacancies and page structure change; a fresh scrape may yield different counts or fail if the website changes.

Install `rvest`, `chromote`, `stringr`, and `magrittr`; Google Chrome must be installed. Use a version of rvest that provides `read_html_live()` (1.0.4 or later).

```r
install.packages(c("rvest", "chromote", "stringr", "magrittr"))
source("blog/posts/post2/scrape_acme.R", chdir = TRUE)
```

**Before running, preserve a copy of `acme_jobs.csv`: the scraper overwrites this file as it collects postings.** The scraper loads public pages, waits between requests, and does not log in, bypass access restrictions, or submit applications. Review failed-page messages, missing requirements, and the final row count. A new sample requires rerunning the analysis and revising the narrative and date labels to match it.
