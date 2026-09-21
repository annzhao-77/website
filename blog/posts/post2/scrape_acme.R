# ACME jobs near Philadelphia: job information and requirements
# Run once if needed: install.packages(c("rvest", "chromote", "stringr", "magrittr"))
library(rvest)
library(stringr)
library(magrittr) # %>%: pass the result to the next step, as in DataCamp

setwd("C:/Users/DELL/Desktop/AEDS 6400/website1/blog/posts/post2")
if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", ".UTF-8")

# 1. Open the search page. This website loads its jobs using JavaScript.
url <- "https://eofd.fa.us6.oraclecloud.com/hcmUI/CandidateExperience/en/sites/CX_1001/jobs?location=Philadelphia%2C+PA%2C+United+States&locationId=300000002802382&locationLevel=city&mode=location&radius=25&radiusUnit=KM"
page <- read_html_live(url)
Sys.sleep(8)

# Extra step for this dynamic website (beyond the static DataCamp examples).
# Take the loaded HTML and remove invisible comments/scripts before reading text.
loaded_html <- function(page) {
  html <- page$session$Runtime$evaluate("document.documentElement.outerHTML")$result$value
  html <- read_html(html)
  xml2::xml_remove(html_elements(html, "script, style"))
  xml2::xml_remove(xml2::xml_find_all(html, "//comment()"))
  html
}

# 2. Scroll until the number of jobs stops increasing three times in a row.
previous_count <- 0
unchanged <- 0
for (i in 1:50) {
  html <- loaded_html(page)
  # .class selects a class; the space means find elements inside the first class.
  cards <- html %>%
    html_elements(".jobs-list__list .job-list-item")
  count <- length(cards)
  cat("Jobs loaded:", count, "\n")
  if (count == previous_count) unchanged <- unchanged + 1 else unchanged <- 0
  if (unchanged == 3) break
  previous_count <- count
  page$session$Runtime$evaluate("document.querySelector('.search-pagination').scrollIntoView({block:'end'}); window.scrollBy(0,400)")
  Sys.sleep(4)
}
page$session$close()
if (length(cards) == 0 || unchanged < 3) stop("The search page did not finish loading.")

# 3. Get links only from cards whose Banner is ACME Markets.
job_links <- c()
for (card in cards) {
  labels <- card %>%
    html_elements(".job-list-item__job-info-label") %>%
    html_text2() %>%
    str_squish()
  values <- card %>%
    html_elements(".job-list-item__job-info-value") %>%
    html_text2() %>%
    str_squish()
  if (any(values[labels == "Banner"] == "ACME Markets", na.rm = TRUE)) {
    # a is the link tag; href is the attribute containing its URL.
    link <- card %>%
      html_element("a.job-list-item__link") %>%
      html_attr("href")
    job_links <- c(job_links, sub("\\?.*$", "", link))
  }
}
job_links <- unique(job_links)
if (length(job_links) == 0) stop("No ACME links were found.")
cat("ACME jobs to collect:", length(job_links), "\n")

# 4. Read each job. Keep only its title, Job Info, and requirements section.
jobs <- list()
failed_links <- c()
for (i in seq_along(job_links)) {
  cat("Reading job", i, "of", length(job_links), "\n")
  tryCatch({
    page <- read_html_live(job_links[i])
    Sys.sleep(5)
    html <- loaded_html(page)
    page$session$close()

    # Page -> select elements by class -> extract text -> tidy whitespace.
    # html_text2() is similar to html_text(), but handles line breaks better.
    title <- html %>%
      html_element(".job-details__title") %>%
      html_text2() %>%
      str_squish()
    labels <- html %>%
      html_elements(".job-meta__title") %>%
      html_text2() %>%
      str_squish()
    values <- html %>%
      html_elements(".job-meta__subitem") %>%
      html_text2() %>%
      str_squish()
    info <- setNames(values, labels)
    if (is.na(title) || !length(info)) stop("Job details did not load.")
    if (!identical(unname(info["Banner"]), "ACME Markets")) stop("Banner is not ACME Markets.")

    description <- html %>%
      html_element('.job-details__description-content[data-bind*="job.description"]') %>%
      html_text2() %>%
      str_squish()
    # Most jobs use the first heading; some managers use Qualifications instead.
    start <- "(?:What you bring to the table|We are looking for candidates who possess the following|Qualifications|Requirements)\\s*:"
    end <- "(?=Why you will choose us|Why choose us|What we offer|WORK ENVIRONMENT|Disclaimer:|We also provide|Our Values|About Us|Respond to:|$)"
    requirements <- str_match(description, paste0("(?is)", start, "(.*?)", end))[, 2] %>%
      str_trim()

    jobs[[length(jobs) + 1]] <- data.frame(
      title = title,
      job_id = unname(info["Job Identification"]),
      job_category = unname(info["Job Category"]),
      posting_date = unname(info["Posting Date"]),
      apply_before = unname(info["Apply Before"]),
      job_schedule = unname(info["Job Schedule"]),
      locations = unname(info["Locations"]),
      banner = unname(info["Banner"]),
      requirements = requirements
    )
    # Update the same CSV so progress is kept if the run is interrupted.
    write.csv(do.call(rbind, jobs), "acme_jobs.csv", row.names = FALSE, na = "", fileEncoding = "UTF-8")
  }, error = function(e) {
    failed_links <<- c(failed_links, job_links[i])
    message("Could not read: ", job_links[i], " — ", conditionMessage(e))
    try(page$session$close(), silent = TRUE)
  })
  Sys.sleep(3)
}
if (!length(jobs)) stop("No job details were collected.")
acme_jobs <- do.call(rbind, jobs)
cat("Saved", nrow(acme_jobs), "jobs to acme_jobs.csv\n")
cat("Missing requirements:", sum(is.na(acme_jobs$requirements)), "\n")
cat("Failed pages:", length(failed_links), "\n")
if (length(failed_links)) print(failed_links)
