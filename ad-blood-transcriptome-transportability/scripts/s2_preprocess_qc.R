suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
raw_dir <- file.path(root, "data", "raw")
processed_dir <- file.path(root, "data", "processed")
results_dir <- file.path(root, "results")
fig_dir <- file.path(root, "figures", "qc")
audit_dir <- file.path(root, "audit")
dir.create(processed_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

locked <- fread(file.path(root, "data", "primary_inclusion_locked.csv"))

dataset_specs <- list(
  GSE63060 = list(
    path = file.path(raw_dir, "GSE63060_normalized.txt.gz"),
    id_col = "ID_REF",
    match_mode = "sample_title"
  ),
  GSE63061 = list(
    path = file.path(raw_dir, "GSE63061_normalized.txt.gz"),
    id_col = "ID_REF",
    match_mode = "sample_title"
  ),
  GSE85426 = list(
    path = file.path(raw_dir, "GSE85426_normalized_data.txt.gz"),
    id_col = "Gene_ID",
    match_mode = "column_order"
  )
)

sanitize_filename <- function(x) {
  gsub("[^A-Za-z0-9_.-]+", "_", x)
}

read_expr <- function(path) {
  fread(path, data.table = TRUE, showProgress = FALSE, fill = TRUE)
}

clean_expr_table <- function(dt, id_col, cols) {
  raw_rows <- nrow(dt)
  ids <- as.character(dt[[id_col]])
  mat_dt <- dt[, ..cols]
  mat <- as.matrix(mat_dt)
  suppressWarnings(storage.mode(mat) <- "numeric")

  invalid_id <- is.na(ids) | trimws(ids) == "" | toupper(trimws(ids)) %in% c("#N/A", "NA", "N/A", "NULL")
  all_missing <- rowSums(!is.na(mat)) == 0
  keep <- !(invalid_id | all_missing)

  list(
    dt = dt[keep],
    raw_rows = raw_rows,
    removed_invalid_feature_ids = sum(invalid_id),
    removed_all_missing_expression = sum(all_missing & !invalid_id),
    removed_total = sum(!keep)
  )
}

numeric_matrix <- function(dt, id_col, cols) {
  ids <- dt[[id_col]]
  mat_dt <- dt[, ..cols]
  mat <- as.matrix(mat_dt)
  suppressWarnings(storage.mode(mat) <- "numeric")
  rownames(mat) <- ids
  mat
}

sample_metrics <- function(acc, mat, sample_info, expression_cols) {
  qs <- t(apply(mat, 2, quantile, probs = c(0, 0.25, 0.5, 0.75, 1), na.rm = TRUE))
  out <- data.table(
    dataset_accession = acc,
    expression_column = expression_cols,
    sample_geo_accession = sample_info$sample_geo_accession,
    sample_title = sample_info$sample_title,
    diagnosis_clean = sample_info$diagnosis_clean,
    n_features = nrow(mat),
    missing_values = colSums(is.na(mat)),
    missing_fraction = colMeans(is.na(mat)),
    mean = colMeans(mat, na.rm = TRUE),
    sd = apply(mat, 2, sd, na.rm = TRUE),
    min = qs[, 1],
    q1 = qs[, 2],
    median = qs[, 3],
    q3 = qs[, 4],
    max = qs[, 5],
    iqr = qs[, 4] - qs[, 2]
  )
  med_center <- median(out$median, na.rm = TRUE)
  med_mad <- mad(out$median, constant = 1, na.rm = TRUE)
  iqr_center <- median(out$iqr, na.rm = TRUE)
  iqr_mad <- mad(out$iqr, constant = 1, na.rm = TRUE)
  out[, median_mad_z := ifelse(med_mad == 0, 0, abs(median - med_center) / med_mad)]
  out[, iqr_mad_z := ifelse(iqr_mad == 0, 0, abs(iqr - iqr_center) / iqr_mad)]
  out[, qc_flag := fifelse(missing_fraction > 0.01 | median_mad_z > 6 | iqr_mad_z > 6, "review", "pass")]
  out
}

plot_boxplot <- function(acc, mat, sample_info) {
  png(file.path(fig_dir, paste0(acc, "_boxplot.png")), width = 1800, height = 900, res = 150)
  cols <- ifelse(sample_info$diagnosis_clean == "AD", "#b23a48", "#2f6f9f")
  par(mar = c(8, 4, 3, 1))
  boxplot(
    mat,
    outline = FALSE,
    las = 2,
    cex.axis = 0.35,
    col = cols,
    main = paste0(acc, " normalized expression distributions"),
    ylab = "Normalized expression"
  )
  legend("topright", legend = c("AD", "Control"), fill = c("#b23a48", "#2f6f9f"), bty = "n")
  dev.off()
}

plot_density <- function(acc, mat, sample_info) {
  set.seed(1)
  n_features <- nrow(mat)
  take <- if (n_features > 5000) sample(seq_len(n_features), 5000) else seq_len(n_features)
  long <- data.table(
    value = as.vector(mat[take, , drop = FALSE]),
    sample_index = rep(seq_len(ncol(mat)), each = length(take))
  )
  long[, diagnosis_clean := sample_info$diagnosis_clean[sample_index]]
  p <- ggplot(long, aes(x = value, color = diagnosis_clean)) +
    geom_density(linewidth = 0.7, alpha = 0.8) +
    scale_color_manual(values = c(AD = "#b23a48", Control = "#2f6f9f")) +
    labs(title = paste0(acc, " expression density"), x = "Normalized expression", y = "Density", color = "Diagnosis") +
    theme_minimal(base_size = 12)
  ggsave(file.path(fig_dir, paste0(acc, "_density.png")), p, width = 8, height = 5, dpi = 160)
}

plot_pca <- function(acc, mat, sample_info) {
  vars <- apply(mat, 1, var, na.rm = TRUE)
  vars[is.na(vars)] <- 0
  keep <- order(vars, decreasing = TRUE)[seq_len(min(5000, length(vars)))]
  pca <- prcomp(t(mat[keep, , drop = FALSE]), center = TRUE, scale. = TRUE)
  ve <- (pca$sdev^2) / sum(pca$sdev^2)
  pc <- data.table(
    PC1 = pca$x[, 1],
    PC2 = pca$x[, 2],
    diagnosis_clean = sample_info$diagnosis_clean,
    sample_geo_accession = sample_info$sample_geo_accession
  )
  p <- ggplot(pc, aes(x = PC1, y = PC2, color = diagnosis_clean)) +
    geom_point(size = 2, alpha = 0.85) +
    scale_color_manual(values = c(AD = "#b23a48", Control = "#2f6f9f")) +
    labs(
      title = paste0(acc, " PCA on top variable features"),
      x = sprintf("PC1 (%.1f%%)", 100 * ve[1]),
      y = sprintf("PC2 (%.1f%%)", 100 * ve[2]),
      color = "Diagnosis"
    ) +
    theme_minimal(base_size = 12)
  ggsave(file.path(fig_dir, paste0(acc, "_pca.png")), p, width = 7, height = 5.5, dpi = 160)
  data.table(dataset_accession = acc, pc1_variance = ve[1], pc2_variance = ve[2])
}

dataset_summaries <- list()
sample_metric_list <- list()
pca_summaries <- list()
column_maps <- list()

for (acc in names(dataset_specs)) {
  spec <- dataset_specs[[acc]]
  message("Processing ", acc)
  expr <- read_expr(spec$path)
  sample_info <- locked[dataset_accession == acc]

  all_expr_cols <- setdiff(names(expr), spec$id_col)
  if (spec$match_mode == "sample_title") {
    wanted <- sample_info$sample_title
    missing_cols <- setdiff(wanted, all_expr_cols)
    if (length(missing_cols) > 0) {
      stop(acc, " missing expression columns for sample_title: ", paste(missing_cols, collapse = ", "))
    }
    expr_cols <- wanted
  } else if (spec$match_mode == "column_order") {
    if (length(all_expr_cols) != nrow(sample_info)) {
      stop(acc, " column-order mapping failed: expression columns=", length(all_expr_cols), " locked samples=", nrow(sample_info))
    }
    expr_cols <- all_expr_cols
  } else {
    stop("Unknown match mode: ", spec$match_mode)
  }

  clean <- clean_expr_table(expr, spec$id_col, expr_cols)
  expr <- clean$dt
  mat <- numeric_matrix(expr, spec$id_col, expr_cols)
  saveRDS(mat, file.path(processed_dir, paste0(acc, "_primary_normalized_matrix.rds")))

  map <- data.table(
    dataset_accession = acc,
    expression_column = expr_cols,
    sample_geo_accession = sample_info$sample_geo_accession,
    sample_title = sample_info$sample_title,
    diagnosis_clean = sample_info$diagnosis_clean,
    match_mode = spec$match_mode
  )
  column_maps[[acc]] <- map

  metrics <- sample_metrics(acc, mat, sample_info, expr_cols)
  sample_metric_list[[acc]] <- metrics

  zero_var <- sum(apply(mat, 1, var, na.rm = TRUE) == 0, na.rm = TRUE)
  dup_features <- sum(duplicated(rownames(mat)))
  dataset_summaries[[acc]] <- data.table(
    dataset_accession = acc,
    platform_id = unique(sample_info$platform_id)[1],
    role = unique(sample_info$dataset_role)[1],
    match_mode = spec$match_mode,
    raw_feature_rows = clean$raw_rows,
    removed_invalid_feature_ids = clean$removed_invalid_feature_ids,
    removed_all_missing_expression = clean$removed_all_missing_expression,
    removed_total_feature_rows = clean$removed_total,
    n_features = nrow(mat),
    n_samples = ncol(mat),
    n_ad = sum(sample_info$diagnosis_clean == "AD"),
    n_control = sum(sample_info$diagnosis_clean == "Control"),
    missing_values = sum(is.na(mat)),
    missing_fraction = mean(is.na(mat)),
    duplicate_feature_ids = dup_features,
    zero_variance_features = zero_var,
    global_min = min(mat, na.rm = TRUE),
    global_q1 = quantile(as.vector(mat), 0.25, na.rm = TRUE),
    global_median = median(as.vector(mat), na.rm = TRUE),
    global_mean = mean(mat, na.rm = TRUE),
    global_q3 = quantile(as.vector(mat), 0.75, na.rm = TRUE),
    global_max = max(mat, na.rm = TRUE),
    samples_flagged_review = sum(metrics$qc_flag == "review"),
    qc_status = ifelse(sum(metrics$qc_flag == "review") == 0 && sum(is.na(mat)) == 0, "PASS", "REVIEW")
  )

  plot_boxplot(acc, mat, sample_info)
  plot_density(acc, mat, sample_info)
  pca_summaries[[acc]] <- plot_pca(acc, mat, sample_info)
}

dataset_summary <- rbindlist(dataset_summaries, fill = TRUE)
sample_metrics_all <- rbindlist(sample_metric_list, fill = TRUE)
pca_summary <- rbindlist(pca_summaries, fill = TRUE)
column_map <- rbindlist(column_maps, fill = TRUE)

fwrite(dataset_summary, file.path(results_dir, "s2_qc_dataset_summary.csv"))
fwrite(sample_metrics_all, file.path(results_dir, "s2_qc_sample_metrics.csv"))
fwrite(pca_summary, file.path(results_dir, "s2_qc_pca_summary.csv"))
fwrite(column_map, file.path(processed_dir, "s2_expression_column_sample_map.csv"))

session_lines <- capture.output(sessionInfo())
writeLines(session_lines, file.path(audit_dir, "s2_sessionInfo.txt"))

report <- c(
  "# S2 Preprocessing and QC Report",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Scope",
  "",
  "- Used locked AD/Control sample list from `data/primary_inclusion_locked.csv`.",
  "- Read normalized expression files only; no cross-platform merging, ComBat, or disease modeling was performed at S2.",
  "- Saved one primary normalized matrix per dataset as RDS.",
  "",
  "## Dataset QC Summary",
  "",
  paste(capture.output(print(dataset_summary)), collapse = "\n"),
  "",
  "## PCA Variance Summary",
  "",
  paste(capture.output(print(pca_summary)), collapse = "\n"),
  "",
  "## Important Notes",
  "",
  "- GSE63060 and GSE63061 expression columns were matched to GEO metadata by `sample_title`.",
  "- GSE85426 expression columns were matched by column order because GEO metadata does not provide expression filename-to-GSM mapping in the series matrix.",
  "- GSE85426 values are on a different processed scale from the AddNeuroMed Illumina datasets, so cross-dataset matrix concatenation is not allowed at this stage.",
  "",
  "## Outputs",
  "",
  "- `data/processed/GSE63060_primary_normalized_matrix.rds`",
  "- `data/processed/GSE63061_primary_normalized_matrix.rds`",
  "- `data/processed/GSE85426_primary_normalized_matrix.rds`",
  "- `data/processed/s2_expression_column_sample_map.csv`",
  "- `results/s2_qc_dataset_summary.csv`",
  "- `results/s2_qc_sample_metrics.csv`",
  "- `results/s2_qc_pca_summary.csv`",
  "- `figures/qc/*_boxplot.png`, `*_density.png`, `*_pca.png`",
  "- `audit/s2_sessionInfo.txt`",
  "",
  "## Gate 2 Preliminary Decision",
  "",
  if (all(dataset_summary$qc_status == "PASS")) {
    "PASS at the automated QC level. Proceed to manual inspection of QC figures before S3."
  } else {
    "REVIEW required. At least one sample-level or dataset-level QC flag was raised."
  }
)
writeLines(report, file.path(audit_dir, "s2_qc_report.md"))

print(dataset_summary)
print(pca_summary)
message("S2 QC complete.")
