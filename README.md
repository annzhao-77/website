# Anna Zhao — AEDS 6400 Website and Blog

This repository maintains the blog articles, display images, and Quarto website. Analysis code, data, and results are maintained in separate assignment repositories.

## Assignment navigation

| Assignment | Article source | Code, data, and reproduction instructions |
| --- | --- | --- |
| Blog 1 | [QMD](blog/posts/post1/Untitled.qmd) | Introductory post |
| Blog 2: ACME job skills | [QMD](blog/posts/post2/index.qmd) | [BLOG2](https://github.com/annzhao-77/BLOG2) |
| Blog 3: Education and unemployment | [QMD](blog/posts/post3/index.qmd) | [BLOG3](https://github.com/annzhao-77/BLOG3) |
| Blog 4: Prosperity and longevity | [QMD](blog/posts/post4/index.qmd) | [BLOG4](https://github.com/annzhao-77/BLOG4) |
| Blog 5: Pennsylvania population and migration | [QMD](blog/posts/post5/index.qmd) | [BLOG5](https://github.com/annzhao-77/BLOG5) |
| Blog 6: Matching fathers and children with SQL | [QMD](blog/posts/post6/index.qmd) | [BLOG6](https://github.com/annzhao-77/BLOG6) |
| Blog 7: Everyday expenses since 2019 | [QMD](blog/posts/post7/index.qmd) | [BLOG7](https://github.com/annzhao-77/BLOG7) |

## Blog 6: Matching Fathers and Children: A SQL Tutorial in Python

**Question:** Do higher-income fathers tend to have higher-income children?

The tutorial uses SQL within Python to connect PSID individuals to their biological fathers through FIMS, select each person's own labor income, and build comparable income measures. It explains `SELECT`, `JOIN`, `CASE`, `GROUP BY`, and aggregation.

The analysis uses the 1994–2023 surveys to maintain a consistent labor-income definition and converts income to 2022 dollars using CPI-U. It compares two log–log OLS regressions on the same 143 father–child pairs (123 distinct fathers): single-year income at approximate age 36 and mean income from available observations at ages 29–43, requiring at least three observations per person. Estimated IGE is 0.220 and 0.297, respectively. The post discusses income measurement and life-cycle bias without treating the difference as proof that averaging eliminates bias.

See the [analysis script](https://github.com/annzhao-77/BLOG6/blob/main/code/analysis.py) and [BLOG6 README](https://github.com/annzhao-77/BLOG6/blob/main/README.md) for inputs and replication instructions. The article displays a results table and one figure comparing the two income relationships.

## Blog 7: Which Everyday Expenses Have Increased the Most Since 2019?

Inspired by **衣食住行** (clothing, food, housing, and transportation), the post compares six categories using [BLS Consumer Price Index data](https://www.bls.gov/cpi/data.htm) downloaded through FRED. The chart covers January 2019–December 2025, using the **2019 annual average as the pre-pandemic baseline**. It includes apparel, groceries, dining out, shelter, electricity, and gasoline, with overall CPI as a benchmark.

The interactive Plotly explorer has an All categories comparison tab and a separate, color-themed tab for each series. The comparison switches between cumulative and year-over-year changes. Category tabs show monthly line charts or annual bar charts, both relative to the 2019 annual average. Cards show the latest, highest, and lowest cumulative changes. Annual comparisons stop at 2024 because six series lack October 2025; monthly data extend through December 2025. Electricity and dining out have the largest cumulative endpoint increases among these categories. Shelter and groceries also increased more than overall CPI. The article cites EIA on the role of Russia's invasion of Ukraine in the 2022 oil-price rise, and its takeaway highlights food as a recurring expense. Its limitations cover seasonality and missing observations.

See the [analysis script](https://github.com/annzhao-77/BLOG7/blob/main/code/analysis.py) and [BLOG7 README](https://github.com/annzhao-77/BLOG7) for the saved data and replication steps. Edit the article in `BLOG7/index.qmd`, including the “What the Chart Shows” section; there is no separate results QMD. Running `python code/analysis.py --website` from BLOG7 reruns the analysis and copies that article and `figures/everyday_prices.html` into this website. It replaces the website's article copy, so make narrative edits in BLOG7 first. The HTML includes Plotly itself, so its interactive controls do not require a CDN. Render the website after copying; the command does not publish it.

## Repository layout

- `blog/posts/postN/index.qmd`: article source (Blog 1 uses Untitled.qmd).
- `blog/posts/postN/figures/`: display images, including analysis plots and illustrations.
- `_quarto.yml`: website configuration.
- `studentname-website.Rproj`: RStudio project for this website.
- `docs/`: generated website output; edit original QMDs rather than HTML files here.

## Update an analysis and publish its figures

1. Open the corresponding BLOG repository and follow its README. Run its R or Python analysis script from that project's root.
2. Copy the generated figures from its `results/figures/` into this website's corresponding `blog/posts/postN/figures/` folder. For interactive Plotly figures, also copy any HTML assets and dependencies required by the chosen embedding method; a PNG alone does not preserve interactivity.
3. Update the article as needed. Each article links to its analysis repository.
4. Render from this website's root in a terminal:

```sh
quarto render
```

To render one post, for example:

```sh
quarto render blog/posts/post3/index.qmd
```

Rendering displays saved figures; it does not run the separate analysis scripts. Check image paths and, where applicable, interactive controls in the rendered page before publishing. Commit and push each changed repository separately; the repositories do not synchronize automatically.

Blog 3 requires your own IPUMS CPS extract. Its raw person-level data stay local; acquisition steps and summary results are provided in BLOG3. Blog 4 includes its saved World Bank snapshot to reproduce the original results without a new download.
