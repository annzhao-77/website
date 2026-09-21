# Blog 2: ACME job skills

Question: Which skills appear most often in ACME job requirements(specific in philadelphia area), and how do they differ across job types?

## Files
- `scrape_acme.R`: the R script for web scraping.
- `acme_jobs.csv`: the collected job information (one row per posting).
- `analyze_acme.R`: skill analysis with an editable phrase dictionary and three plots.
- `figures/`: job counts, skill frequencies, and comparisons by job type.
- `index.qmd`: the blog qmd.

## Run
For analysis, install `dplyr`, `stringr`, and `ggplot2`, then Source `analyze_acme.R`. The script uses a for loop to match each skill, then calculates counts and percentages with group_by and summarise. Tables remain in RStudio; only three PNG figures are saved. Each skill counts once per posting. Required and preferred mentions are combined. Repeated requirement templates are retained and their distinct count is printed. These are initial phrase-based classifications to review before final recommendations.

Install `rvest`, `chromote`, `stringr`, and `magrittr`, and have Google Chrome installed.
Open `scrape_acme.R` in RStudio and click Source. Update the setwd path if using another computer.
The script opens the public search page, scrolls to load jobs, reads each ACME posting, and saves one CSV. It waits between requests and does not log in or submit applications.

Source: [Albertsons Companies careers — Philadelphia +25 km](https://eofd.fa.us6.oraclecloud.com/hcmUI/CandidateExperience/en/sites/CX_1001/jobs?location=Philadelphia%2C+PA%2C+United+States&locationId=300000002802382&locationLevel=city&mode=location&radius=25&radiusUnit=KM).

The accepted scope is the 118 retrievable ACME postings. The site's counter showed 119; that difference is not pursued. Some returned postings cover regional or multiple locations, so this is the website's search result set rather than an independently verified geographic boundary.

The table contains the title, seven requested Job Info fields, and requirements text. Missing fields are blank. Some jobs use Qualifications or another equivalent heading. The console reports failed pages and missing requirements. The CSV is updated as the script runs; check its final row count before analysis.



`analyze_acme.R` excludes general customer-service language from skill rankings and does not count enjoying a team environment or helping colleagues as teamwork on its own. Specific skill phrases are listed in `skills`; `skill_evidence` retains matching text for review in RStudio. The dictionary is a conservative text measure, not an exhaustive assessment of skills actually needed.
