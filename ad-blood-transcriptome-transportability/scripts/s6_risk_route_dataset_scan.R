suppressPackageStartupMessages({
  library(data.table)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
results_dir <- file.path(root, "results")
audit_dir <- file.path(root, "audit")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

datasets <- data.table(
  dataset_accession = c("GSE140829", "GSE97760", "GSE18309", "GSE4226", "GSE165090"),
  matrix_url = c(
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE140nnn/GSE140829/matrix/GSE140829_series_matrix.txt.gz",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE97nnn/GSE97760/matrix/GSE97760_series_matrix.txt.gz",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE18nnn/GSE18309/matrix/GSE18309_series_matrix.txt.gz",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE4nnn/GSE4226/matrix/GSE4226_series_matrix.txt.gz",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE165nnn/GSE165090/matrix/GSE165090_series_matrix.txt.gz"
  ),
  geo_page = c(
    "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE140829",
    "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE97760",
    "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE18309",
    "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE4226",
    "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE165090"
  ),
  normalized_url = c(
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE140nnn/GSE140829/suppl/GSE140829_final_normalized_data.txt.gz",
    "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE97nnn/GSE97760/suppl/GSE97760_loess.txt.gz",
    NA_character_,
    NA_character_,
    NA_character_
  )
)

read_matrix_metadata <- function(url, max_lines = 200) {
  con <- gzcon(url(url, "rb"))
  on.exit(close(con), add = TRUE)
  lines <- character()
  repeat {
    line <- readLines(con, n = 1, warn = FALSE)
    if (length(line) == 0) break
    lines <- c(lines, line)
    if (startsWith(line, "!series_matrix_table_begin")) break
    if (length(lines) >= max_lines) break
  }
  lines
}

extract_field <- function(lines, field) {
  hit <- lines[startsWith(lines, field)]
  if (length(hit) == 0) return(character())
  vals <- strsplit(hit[1], "\t", fixed = TRUE)[[1]][-1]
  gsub("^\"|\"$", "", vals)
}

classify_title <- function(dataset, titles) {
  if (length(titles) == 0) return(character())
  if (dataset == "GSE140829") {
    dx <- sub("^Whole blood, ([^,]+),.*$", "\\1", titles)
    return(ifelse(dx %in% c("AD", "MCI", "Control"), dx, "Other"))
  }
  text <- tolower(titles)
  dx <- rep("Other", length(text))
  dx[grepl("control|normal|nec|healthy|nc", text)] <- "Control"
  dx[grepl("\\bad\\b|alzheimer", text)] <- "AD"
  dx[grepl("\\bmci\\b|mild cognitive", text)] <- "MCI"
  dx
}

scan_one <- function(dataset, matrix_url) {
  lines <- tryCatch(read_matrix_metadata(matrix_url), error = function(e) paste0("ERROR: ", conditionMessage(e)))
  if (length(lines) == 1 && startsWith(lines, "ERROR:")) {
    return(data.table(
      dataset_accession = dataset,
      status = "fetch_failed",
      n_samples = NA_integer_,
      n_ad = NA_integer_,
      n_control = NA_integer_,
      n_mci = NA_integer_,
      n_other = NA_integer_,
      title = NA_character_,
      platform = NA_character_,
      notes = lines
    ))
  }
  titles <- extract_field(lines, "!Sample_title")
  dx <- classify_title(dataset, titles)
  if (dataset == "GSE97760") {
    dx <- c(rep("AD", 9), rep("Control", 10))
  } else if (dataset == "GSE4226") {
    dx <- c(rep("AD", 14), rep("Control", 14))
  }
  title_line <- sub("^!Series_title = ", "", lines[startsWith(lines, "!Series_title")][1])
  platform <- unique(extract_field(lines, "!Sample_platform_id"))
  platform <- paste(platform, collapse = ";")
  if (dataset == "GSE165090") {
    notes <- "Excluded: SERPINA1 trophoblast siRNA experiment, not Alzheimer blood cohort."
  } else if (dataset == "GSE140829") {
    notes <- "High-priority rescue dataset: large peripheral blood dementia cohort with AD/MCI/Control labels."
  } else if (dataset == "GSE97760") {
    notes <- "Whole blood AD/control but very small and female-only; support-only validation."
  } else if (dataset %in% c("GSE18309", "GSE4226")) {
    notes <- "PBMC AD/control dataset; small sample size and older platform; support-only validation."
  } else {
    notes <- ""
  }
  data.table(
    dataset_accession = dataset,
    status = "metadata_scanned",
    n_samples = length(titles),
    n_ad = sum(dx == "AD", na.rm = TRUE),
    n_control = sum(dx == "Control", na.rm = TRUE),
    n_mci = sum(dx == "MCI", na.rm = TRUE),
    n_other = sum(dx == "Other", na.rm = TRUE),
    title = title_line,
    platform = platform,
    notes = notes
  )
}

scan <- rbindlist(lapply(seq_len(nrow(datasets)), function(i) {
  scan_one(datasets$dataset_accession[i], datasets$matrix_url[i])
}), fill = TRUE)
scan <- merge(scan, datasets[, .(dataset_accession, geo_page, matrix_url, normalized_url)], by = "dataset_accession", all.x = TRUE, sort = FALSE)

scan[, route_a_role := fifelse(
  dataset_accession == "GSE140829", "primary_new_external_validation",
  fifelse(dataset_accession %in% c("GSE97760", "GSE18309", "GSE4226"), "supporting_sensitivity_only", "exclude")
)]
scan[, route_b_role := fifelse(
  dataset_accession %in% c("GSE140829", "GSE97760", "GSE18309", "GSE4226"), "context_for_transportability_limits", "exclude"
)]

fwrite(scan, file.path(results_dir, "risk_external_dataset_scan.csv"))

report <- c(
  "# Risk Response External Dataset Scan",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Summary",
  "",
  paste(capture.output(print(scan[, .(
    dataset_accession, n_samples, n_ad, n_control, n_mci, n_other, platform, route_a_role, route_b_role
  )])), collapse = "\n"),
  "",
  "## Decision-Relevant Notes",
  "",
  "- GSE140829 is the only high-priority rescue dataset identified in this scan because it is large, peripheral blood, and has AD/MCI/Control labels.",
  "- GSE97760, GSE18309, and GSE4226 are too small for primary validation but can support a transportability or sensitivity narrative.",
  "- GSE165090 is excluded because it is not an Alzheimer blood cohort."
)
writeLines(report, file.path(audit_dir, "risk_external_dataset_scan_report.md"))

print(scan[, .(dataset_accession, n_samples, n_ad, n_control, n_mci, n_other, platform, route_a_role, route_b_role)])
