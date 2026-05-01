suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(limma)
  library(pheatmap)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
raw_dir <- file.path(root, "data", "raw")
processed_dir <- file.path(root, "data", "processed")
results_dir <- file.path(root, "results")
fig_dir <- file.path(root, "figures", "s3")
audit_dir <- file.path(root, "audit")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

training_acc <- "GSE63060"
main_adj_p <- 0.05
main_abs_logfc <- 0.20

safe_log10 <- function(x) {
  -log10(pmax(x, .Machine$double.xmin))
}

valid_symbol <- function(x) {
  x <- trimws(as.character(x))
  !is.na(x) & x != "" & toupper(x) != "NA" & x != "---"
}

primary_symbol <- function(x) {
  x <- trimws(as.character(x))
  x[is.na(x)] <- ""
  first <- vapply(strsplit(x, "///|//|;|,"), function(parts) {
    parts <- trimws(parts)
    parts <- parts[nzchar(parts)]
    if (length(parts) == 0) "" else parts[1]
  }, character(1))
  first
}

read_geo_annotation <- function(path) {
  con <- gzfile(path, "rt")
  on.exit(close(con), add = TRUE)
  lines <- readLines(con, warn = FALSE)
  begin <- grep("^!platform_table_begin", lines)
  end <- grep("^!platform_table_end", lines)
  if (length(begin) != 1 || length(end) != 1 || begin >= end) {
    stop("Could not find GEO platform table boundaries in ", path)
  }
  table_lines <- lines[(begin + 1):(end - 1)]
  annot <- fread(text = paste(table_lines, collapse = "\n"), sep = "\t", fill = TRUE, quote = "")
  required <- c("ID", "Gene symbol", "Gene ID", "Gene title")
  missing <- setdiff(required, names(annot))
  if (length(missing) > 0) {
    stop("GPL annotation missing required columns: ", paste(missing, collapse = ", "))
  }
  annot[, probe_id := as.character(ID)]
  annot[, gene_symbol_raw := as.character(`Gene symbol`)]
  annot[, gene_symbol := primary_symbol(gene_symbol_raw)]
  annot[, gene_id := as.character(`Gene ID`)]
  annot[, gene_title := as.character(`Gene title`)]
  annot[, is_annotated_gene := valid_symbol(gene_symbol)]
  annot[, .(probe_id, gene_symbol, gene_symbol_raw, gene_id, gene_title, is_annotated_gene)]
}

plot_volcano <- function(deg) {
  deg[, threshold_class := fifelse(
    adj.P.Val < main_adj_p & abs(logFC) >= main_abs_logfc,
    fifelse(logFC > 0, "AD_up", "AD_down"),
    "not_main"
  )]
  p <- ggplot(deg, aes(x = logFC, y = safe_log10(adj.P.Val), color = threshold_class)) +
    geom_point(alpha = 0.65, size = 0.8) +
    geom_vline(xintercept = c(-main_abs_logfc, main_abs_logfc), linetype = "dashed", color = "#6b7280") +
    geom_hline(yintercept = -log10(main_adj_p), linetype = "dashed", color = "#6b7280") +
    scale_color_manual(values = c(AD_down = "#2f6f9f", AD_up = "#b23a48", not_main = "#9ca3af")) +
    labs(
      title = paste0(training_acc, " limma differential expression"),
      subtitle = "Primary model: AD vs Control adjusted for age and gender",
      x = "log2 fold change (AD - Control)",
      y = "-log10(BH adjusted P value)",
      color = "Class"
    ) +
    theme_minimal(base_size = 12)
  ggsave(file.path(fig_dir, paste0(training_acc, "_volcano.png")), p, width = 7, height = 5.5, dpi = 180)
}

plot_pvalue_histogram <- function(deg) {
  p <- ggplot(deg, aes(x = P.Value)) +
    geom_histogram(bins = 50, fill = "#4b5563", color = "white", linewidth = 0.15) +
    labs(
      title = paste0(training_acc, " nominal P-value distribution"),
      x = "Nominal P value",
      y = "Probe count"
    ) +
    theme_minimal(base_size = 12)
  ggsave(file.path(fig_dir, paste0(training_acc, "_pvalue_histogram.png")), p, width = 7, height = 4.5, dpi = 180)
}

plot_ma <- function(deg) {
  deg[, threshold_class := fifelse(
    adj.P.Val < main_adj_p & abs(logFC) >= main_abs_logfc,
    fifelse(logFC > 0, "AD_up", "AD_down"),
    "not_main"
  )]
  p <- ggplot(deg, aes(x = AveExpr, y = logFC, color = threshold_class)) +
    geom_point(alpha = 0.6, size = 0.75) +
    geom_hline(yintercept = c(-main_abs_logfc, main_abs_logfc), linetype = "dashed", color = "#6b7280") +
    scale_color_manual(values = c(AD_down = "#2f6f9f", AD_up = "#b23a48", not_main = "#9ca3af")) +
    labs(
      title = paste0(training_acc, " MA plot"),
      x = "Average expression",
      y = "log2 fold change (AD - Control)",
      color = "Class"
    ) +
    theme_minimal(base_size = 12)
  ggsave(file.path(fig_dir, paste0(training_acc, "_ma_plot.png")), p, width = 7, height = 5, dpi = 180)
}

plot_top_heatmap <- function(mat, metadata, deg) {
  top <- deg[order(adj.P.Val, -abs(logFC))]
  if (nrow(top[main_candidate == TRUE]) >= 50) {
    top <- top[main_candidate == TRUE][1:50]
    heatmap_label <- "top 50 primary-threshold probes"
  } else {
    top <- top[1:min(50, .N)]
    heatmap_label <- "top 50 ranked probes"
  }
  hmat <- mat[top$probe_id, , drop = FALSE]
  hmat <- t(scale(t(hmat)))
  hmat[is.na(hmat)] <- 0
  ann_col <- data.frame(
    Diagnosis = metadata$diagnosis_clean,
    Gender = metadata$gender_factor,
    Age = metadata$age_numeric
  )
  rownames(ann_col) <- metadata$sample_title
  row_labels <- ifelse(valid_symbol(top$gene_symbol), top$gene_symbol, top$probe_id)
  rownames(hmat) <- make.unique(row_labels)
  png(file.path(fig_dir, paste0(training_acc, "_top50_heatmap.png")), width = 1450, height = 1700, res = 180)
  pheatmap(
    hmat,
    annotation_col = ann_col,
    show_colnames = FALSE,
    fontsize_row = 6,
    main = paste0(training_acc, " ", heatmap_label, " (row z-score)")
  )
  dev.off()
}

locked <- fread(file.path(root, "data", "primary_inclusion_locked.csv"))
metadata <- locked[dataset_accession == training_acc]
if (nrow(metadata) == 0) {
  stop("No locked metadata found for ", training_acc)
}
metadata[, sample_title := as.character(sample_title)]
metadata[, diagnosis_clean := factor(diagnosis_clean, levels = c("Control", "AD"))]
metadata[, age_numeric := suppressWarnings(as.numeric(age))]
metadata[, gender_factor := factor(gender)]

if (any(is.na(metadata$diagnosis_clean))) {
  stop("Diagnosis has missing or unexpected labels in ", training_acc)
}
if (any(is.na(metadata$age_numeric))) {
  stop("Age is missing/non-numeric for ", sum(is.na(metadata$age_numeric)), " training samples")
}
if (any(is.na(metadata$gender_factor))) {
  stop("Gender is missing for ", sum(is.na(metadata$gender_factor)), " training samples")
}

mat <- readRDS(file.path(processed_dir, paste0(training_acc, "_primary_normalized_matrix.rds")))
if (!all(metadata$sample_title %in% colnames(mat))) {
  missing_cols <- setdiff(metadata$sample_title, colnames(mat))
  stop("Training matrix missing columns: ", paste(missing_cols, collapse = ", "))
}
mat <- mat[, metadata$sample_title, drop = FALSE]
if (!identical(colnames(mat), metadata$sample_title)) {
  stop("Training matrix and metadata alignment failed")
}

zero_var <- apply(mat, 1, var, na.rm = TRUE) == 0
if (any(zero_var)) {
  mat <- mat[!zero_var, , drop = FALSE]
}

annot <- read_geo_annotation(file.path(raw_dir, "GPL6947.annot.gz"))
annot_summary <- data.table(
  platform_id = "GPL6947",
  annotation_rows = nrow(annot),
  expression_features = nrow(mat),
  expression_features_with_annotation_row = sum(rownames(mat) %in% annot$probe_id),
  expression_features_with_gene_symbol = sum(annot[match(rownames(mat), probe_id), is_annotated_gene], na.rm = TRUE)
)

design <- model.matrix(~ diagnosis_clean + age_numeric + gender_factor, data = metadata)
fit <- lmFit(mat, design)
fit <- eBayes(fit)
coef_name <- "diagnosis_cleanAD"
if (!coef_name %in% colnames(fit$coefficients)) {
  stop("Expected coefficient not found: ", coef_name)
}

deg <- as.data.table(topTable(fit, coef = coef_name, number = Inf, adjust.method = "BH", sort.by = "P"))
deg[, probe_id := rownames(topTable(fit, coef = coef_name, number = Inf, adjust.method = "BH", sort.by = "P"))]
setcolorder(deg, c("probe_id", setdiff(names(deg), "probe_id")))
deg <- merge(deg, annot, by = "probe_id", all.x = TRUE, sort = FALSE)
deg[, abs_logFC := abs(logFC)]
deg[, direction := fifelse(logFC > 0, "AD_up", "AD_down")]
deg[, main_candidate := adj.P.Val < main_adj_p & abs_logFC >= main_abs_logfc]
deg[, nominal_candidate := P.Value < 0.05 & abs_logFC >= main_abs_logfc]

main_probes <- deg[main_candidate == TRUE][order(adj.P.Val, -abs_logFC)]
candidate_probes <- copy(main_probes)
candidate_genes <- candidate_probes[is_annotated_gene == TRUE & valid_symbol(gene_symbol)]
if (nrow(candidate_genes) > 0) {
  setorder(candidate_genes, gene_symbol, adj.P.Val, -abs_logFC)
  candidate_genes <- candidate_genes[, .SD[1], by = gene_symbol]
  setorder(candidate_genes, adj.P.Val, -abs_logFC)
}

threshold_grid <- CJ(
  adj_p_cutoff = c(0.01, 0.05, 0.10),
  abs_logfc_cutoff = c(0, 0.10, 0.20, 0.30, 0.50)
)
threshold_sensitivity <- threshold_grid[, {
  keep <- deg$adj.P.Val < adj_p_cutoff & deg$abs_logFC >= abs_logfc_cutoff
  annotated <- keep & deg$is_annotated_gene == TRUE & valid_symbol(deg$gene_symbol)
  .(
    n_probes = sum(keep, na.rm = TRUE),
    n_annotated_probes = sum(annotated, na.rm = TRUE),
    n_unique_genes = uniqueN(deg$gene_symbol[annotated]),
    n_up = sum(keep & deg$logFC > 0, na.rm = TRUE),
    n_down = sum(keep & deg$logFC < 0, na.rm = TRUE)
  )
}, by = .(adj_p_cutoff, abs_logfc_cutoff)]

model_summary <- data.table(
  dataset_accession = training_acc,
  model = "limma: expression ~ diagnosis + age + gender",
  n_samples = ncol(mat),
  n_ad = sum(metadata$diagnosis_clean == "AD"),
  n_control = sum(metadata$diagnosis_clean == "Control"),
  n_features_tested = nrow(deg),
  n_zero_variance_removed = sum(zero_var),
  n_main_candidate_probes = nrow(candidate_probes),
  n_main_candidate_annotated_probes = sum(candidate_probes$is_annotated_gene == TRUE, na.rm = TRUE),
  n_main_candidate_genes = nrow(candidate_genes),
  n_nominal_candidate_probes = sum(deg$nominal_candidate, na.rm = TRUE),
  n_bh_005_probes_without_logfc_cutoff = sum(deg$adj.P.Val < main_adj_p, na.rm = TRUE),
  n_main_up = sum(candidate_probes$logFC > 0, na.rm = TRUE),
  n_main_down = sum(candidate_probes$logFC < 0, na.rm = TRUE),
  min_adj_p = min(deg$adj.P.Val, na.rm = TRUE),
  min_p = min(deg$P.Value, na.rm = TRUE)
)

fwrite(deg, file.path(results_dir, "s3_deg_limma_gse63060_all.csv"))
fwrite(main_probes, file.path(results_dir, "s3_deg_limma_gse63060_main_threshold.csv"))
fwrite(candidate_probes, file.path(results_dir, "s3_candidate_probes_main.csv"))
fwrite(candidate_genes, file.path(results_dir, "s3_candidate_genes_main.csv"))
fwrite(threshold_sensitivity, file.path(results_dir, "s3_deg_threshold_sensitivity.csv"))
fwrite(model_summary, file.path(results_dir, "s3_limma_model_summary.csv"))
fwrite(annot_summary, file.path(results_dir, "s3_gpl6947_annotation_summary.csv"))

plot_volcano(deg)
plot_pvalue_histogram(deg)
plot_ma(deg)
plot_top_heatmap(mat, metadata, deg)

session_lines <- capture.output(sessionInfo())
writeLines(session_lines, file.path(audit_dir, "s3_limma_sessionInfo.txt"))

gate_status <- if (model_summary$n_main_candidate_genes >= 10) {
  "PASS"
} else if (model_summary$n_main_candidate_genes > 0) {
  "CONDITIONAL PASS"
} else {
  "REVIEW"
}

top_gene_lines <- if (nrow(candidate_genes) > 0) {
  paste0(
    "- ", head(candidate_genes$gene_symbol, 20),
    " (probe=", head(candidate_genes$probe_id, 20),
    ", logFC=", sprintf("%.3f", head(candidate_genes$logFC, 20)),
    ", adj.P=", formatC(head(candidate_genes$adj.P.Val, 20), format = "e", digits = 2),
    ")"
  )
} else {
  "- No gene-level candidates met the primary threshold."
}

report <- c(
  "# S3 Candidate Gene Screening Report",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Scope",
  "",
  "- Discovery set: GSE63060 only.",
  "- External validation datasets GSE63061 and GSE85426 were not used for feature discovery.",
  "- Primary model: limma linear model `expression ~ diagnosis + age + gender`.",
  paste0("- Primary threshold: BH adjusted P < ", main_adj_p, " and absolute log2 fold change >= ", main_abs_logfc, "."),
  "",
  "## Model Summary",
  "",
  paste(capture.output(print(model_summary)), collapse = "\n"),
  "",
  "## Annotation Summary",
  "",
  paste(capture.output(print(annot_summary)), collapse = "\n"),
  "",
  "## Threshold Sensitivity",
  "",
  paste(capture.output(print(threshold_sensitivity)), collapse = "\n"),
  "",
  "## Top Gene-Level Primary Candidates",
  "",
  top_gene_lines,
  "",
  "## Outputs",
  "",
  "- `results/s3_deg_limma_gse63060_all.csv`",
  "- `results/s3_deg_limma_gse63060_main_threshold.csv`",
  "- `results/s3_candidate_probes_main.csv`",
  "- `results/s3_candidate_genes_main.csv`",
  "- `results/s3_deg_threshold_sensitivity.csv`",
  "- `results/s3_limma_model_summary.csv`",
  "- `results/s3_gpl6947_annotation_summary.csv`",
  "- `figures/s3/GSE63060_volcano.png`",
  "- `figures/s3/GSE63060_pvalue_histogram.png`",
  "- `figures/s3/GSE63060_ma_plot.png`",
  "- `figures/s3/GSE63060_top50_heatmap.png`",
  "- `audit/s3_limma_sessionInfo.txt`",
  "",
  "## Gate 3 Preliminary Decision",
  "",
  paste0(gate_status, ". Candidate discovery is sufficient for downstream validation if external validation performance is independently confirmed."),
  "",
  "## Caveats",
  "",
  "- Probe-level signals were collapsed to genes only after differential expression; modeling was performed at probe level.",
  "- This step does not claim diagnostic utility. Diagnostic model construction and external validation must be completed in S4-S5.",
  "- Batch/platform effects are not adjusted across datasets here because S3 deliberately uses only the training discovery dataset."
)
writeLines(report, file.path(audit_dir, "s3_candidate_gene_screening_report.md"))

gate <- c(
  "# Gate 3 Candidate Gene Screening Review",
  "",
  paste0("Review date: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Decision",
  "",
  paste0("Gate 3 status: **", gate_status, "**"),
  "",
  "## Checks",
  "",
  "- Locked training dataset used: PASS.",
  "- External validation datasets protected from feature discovery: PASS.",
  "- Age and gender covariates included: PASS.",
  "- GPL6947 probe annotation parsed from local GEO annotation file: PASS.",
  "- Primary threshold and sensitivity table exported: PASS.",
  "",
  "## Quantitative Basis",
  "",
  paste0("- Primary candidate probes: ", model_summary$n_main_candidate_probes),
  paste0("- Annotated primary candidate probes: ", model_summary$n_main_candidate_annotated_probes),
  paste0("- Unique primary candidate genes: ", model_summary$n_main_candidate_genes),
  paste0("- Up-regulated probes in AD: ", model_summary$n_main_up),
  paste0("- Down-regulated probes in AD: ", model_summary$n_main_down),
  "",
  "## Required Next Step",
  "",
  "- S4 must validate candidate signals in GSE63061 and GSE85426 without using those datasets to revise S3 thresholds."
)
writeLines(gate, file.path(audit_dir, "gate3_candidate_gene_review.md"))

print(model_summary)
print(head(candidate_genes[, .(gene_symbol, probe_id, logFC, adj.P.Val, P.Value)], 20))
message("S3 limma differential expression screening complete.")
