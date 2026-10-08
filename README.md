# Anna Zhao — AEDS 6400 Website and Blog

This repository maintains the blog articles, display images, and Quarto website. Analysis code, data, and results are maintained in separate assignment repositories.

## Assignment navigation

| Assignment | Article source | Code, data, and reproduction instructions |
| --- | --- | --- |
| Blog 1 | [QMD](blog/posts/post1/Untitled.qmd) | Introductory post |
| Blog 2: ACME job skills | [QMD](blog/posts/post2/index.qmd) | [BLOG2](https://github.com/annzhao-77/BLOG2) |
| Blog 3: Education and unemployment | [QMD](blog/posts/post3/index.qmd) | [BLOG3](https://github.com/annzhao-77/BLOG3) |
| Blog 4: Prosperity and longevity | [QMD](blog/posts/post4/index.qmd) | [BLOG4](https://github.com/annzhao-77/BLOG4) |

## Repository layout

- `blog/posts/postN/index.qmd`: article source (Blog 1 uses Untitled.qmd).
- `blog/posts/postN/figures/`: display images, including analysis plots and illustrations.
- `_quarto.yml`: website configuration.
- `studentname-website.Rproj`: RStudio project for this website.
- `docs/`: generated website output; edit original QMDs rather than HTML files here.

## Update an analysis and publish its figures

1. Open the corresponding BLOG repository and follow its README. Run its R script from that project's root.
2. Copy the generated PNGs from its `results/figures/` into this website's corresponding `blog/posts/postN/figures/` folder.
3. Update the article as needed. Each article links to its analysis repository.
4. Render from this website's root in a terminal:

```sh
quarto render
```

To render one post, for example:

```sh
quarto render blog/posts/post3/index.qmd
```

Rendering displays saved figures; it does not run the separate analysis scripts. Check the rendered output before publishing. Commit and push each changed repository separately; the repositories do not synchronize automatically.

Blog 3 requires your own IPUMS CPS extract. Its raw person-level data stay local; acquisition steps and summary results are provided in BLOG3. Blog 4 includes its saved World Bank snapshot to reproduce the original results without a new download.
