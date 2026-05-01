suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(limma)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
results_dir <- file.path(root, "results")
processed_dir <- file.path(root, "data", "processed")
fig_dir <- file.path(root, "figures", "route_b")
audit_dir <- file.path(root, "audit")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

target_auc <- 0.70

auc_rank <- function(labels, scores) {
  keep <- !is.na(labels) & !is.na(scores)
  labels <- labels[keep]
  scores <- scores[keep]
  pos <- labels == 1
  n_pos <- sum(pos)
  n_neg <- sum(!pos)
  if (n_pos == 0 || n_neg == 0) return(NA_real_)
  ranks <- rank(scores, ties.method = "average")
  (sum(ranks[pos]) - n_pos * (n_pos + 1) / 2) / (n_pos * n_neg)
}

primary_token <- function(x) {
  x <- trimws(as.character(x))
  x[is.na(x)] <- ""
  vapply(strsplit(x, "///|//|;|,"), function(parts) {
    parts <- trimws(parts)
    parts <- parts[nzchar(parts)]
    if (length(parts) == 0) "" else parts[1]
  }, character(1))
}

primary_gene_id <- function(x) {
  token <- primary_token(x)
  token <- sub("^([0-9]+).*$", "\\1", token)
  token[!grepl("^[0-9]+$", token)] <- NA_character_
  token
}

valid_symbol <- function(x) {
  x <- trimws(as.character(x))
  !is.na(x) & x != "" & toupper(x) != "NA" & x != "---"
}

candidate <- fread(file.path(results_dir, "s3_candidate_genes_main.csv"))
candidate[, s3_rank := seq_len(.N)]
candidate[, gene_id := primary_gene_id(gene_id)]
candidate <- candidate[!is.na(gene_id) & valid_symbol(gene_symbol)]
candidate <- candidate[, .SD[1], by = gene_id]
setorder(candidate, s3_rank)
candidate_ref <- candidate[, .(
  gene_id,
  gene_symbol,
  s3_rank,
  s3_logFC = logFC,
  s3_adj.P.Val = adj.P.Val,
  s3_P.Value = P.Value
)]

sample_info <- fread(file.path(root, "data", "gse140829_route_a_sample_sheet.csv"))
symbol_mat <- readRDS(file.path(processed_dir, "GSE140829_primary_normalized_symbol_matrix.rds"))
sample_info <- sample_info[match(colnames(symbol_mat), expression_column)]
if (!identical(sample_info$expression_column, colnames(symbol_mat))) {
  stop("GSE140829 sample metadata and expression columns are not aligned")
}

ad_ctl <- sample_info[diagnosis_clean %in% c("AD", "Control")]
mat_ad_ctl <- symbol_mat[, ad_ctl$expression_column, drop = FALSE]
ad_ctl[, diagnosis_clean := factor(diagnosis_clean, levels = c("Control", "AD"))]
ad_ctl[, age_numeric := suppressWarnings(as.numeric(age))]
ad_ctl[, gender_factor := factor(gender)]
ad_ctl[, batch_factor := factor(batch)]
keep_samples <- !is.na(ad_ctl$diagnosis_clean) & !is.na(ad_ctl$age_numeric) & !is.na(ad_ctl$gender_factor) & !is.na(ad_ctl$batch_factor)
ad_ctl <- ad_ctl[keep_samples]
mat_ad_ctl <- mat_ad_ctl[, ad_ctl$expression_column, drop = FALSE]

design_full <- model.matrix(~ diagnosis_clean + age_numeric + gender_factor + batch_factor, data = ad_ctl)
coef_name <- "diagnosis_cleanAD"
if (!coef_name %in% colnames(design_full)) {
  stop("Expected diagnosis coefficient missing in GSE140829 design")
}
fit <- eBayes(lmFit(mat_ad_ctl, design_full))
tt <- as.data.table(topTable(fit, coef = coef_name, number = Inf, adjust.method = "BH", sort.by = "none"))
tt[, gene_symbol := rownames(topTable(fit, coef = coef_name, number = Inf, adjust.method = "BH", sort.by = "none"))]
setcolorder(tt, c("gene_symbol", setdiff(names(tt), "gene_symbol")))

gse140829_validation <- merge(candidate_ref, tt, by = "gene_symbol", all.x = TRUE, sort = FALSE)
setnames(gse140829_validation, old = c("logFC", "AveExpr", "t", "P.Value", "adj.P.Val", "B"), new = c(
  "validation_logFC", "validation_AveExpr", "validation_t", "validation_P.Value", "validation_adj.P.Val", "validation_B"
))
gse140829_validation[, dataset_accession := "GSE140829"]
gse140829_validation[, mapped := !is.na(validation_logFC)]
gse140829_validation[, direction_concordant := mapped & sign(s3_logFC) == sign(validation_logFC)]
gse140829_validation[, nominal_concordant := direction_concordant & validation_P.Value < 0.05]
gse140829_validation[, fdr_concordant := direction_concordant & validation_adj.P.Val < 0.05]
labels <- as.integer(ad_ctl$diagnosis_clean == "AD")
gse140829_validation[mapped == TRUE, auc_oriented := {
  expr <- as.numeric(mat_ad_ctl[gene_symbol[1], ])
  auc_rank(labels, sign(s3_logFC[1]) * expr)
}, by = gene_symbol]
gse140829_validation[, auc_ge_060 := auc_oriented >= 0.60]
setcolorder(gse140829_validation, c(
  "dataset_accession", "gene_id", "gene_symbol", "s3_rank", "s3_logFC",
  "validation_logFC", "validation_P.Value", "validation_adj.P.Val",
  "direction_concordant", "nominal_concordant", "fdr_concordant", "auc_oriented",
  setdiff(names(gse140829_validation), c(
    "dataset_accession", "gene_id", "gene_symbol", "s3_rank", "s3_logFC",
    "validation_logFC", "validation_P.Value", "validation_adj.P.Val",
    "direction_concordant", "nominal_concordant", "fdr_concordant", "auc_oriented"
  ))
))

s4_summary <- fread(file.path(results_dir, "s4_external_validation_dataset_summary.csv"))
replication_summary <- s4_summary[, .(
  dataset_accession,
  validation_role = fifelse(dataset_accession == "GSE63061", "related_external_validation", "cross_platform_stress_test"),
  platform_or_mapping = map_source,
  n_samples,
  n_ad,
  n_control,
  mapped_s3_candidate_genes,
  mapped_fraction,
  direction_concordant,
  direction_concordance_rate,
  nominal_concordant,
  fdr_concordant,
  auc_ge_060,
  median_auc_oriented,
  max_auc_oriented
)]

gse140829_replication <- data.table(
  dataset_accession = "GSE140829",
  validation_role = "new_large_cross_platform_final_validation",
  platform_or_mapping = "GPL15988 normalized gene-symbol matrix",
  n_samples = nrow(ad_ctl),
  n_ad = sum(ad_ctl$diagnosis_clean == "AD"),
  n_control = sum(ad_ctl$diagnosis_clean == "Control"),
  mapped_s3_candidate_genes = sum(gse140829_validation$mapped, na.rm = TRUE),
  mapped_fraction = mean(gse140829_validation$mapped, na.rm = TRUE),
  direction_concordant = sum(gse140829_validation$direction_concordant, na.rm = TRUE),
  direction_concordance_rate = mean(gse140829_validation$direction_concordant[gse140829_validation$mapped == TRUE], na.rm = TRUE),
  nominal_concordant = sum(gse140829_validation$nominal_concordant, na.rm = TRUE),
  fdr_concordant = sum(gse140829_validation$fdr_concordant, na.rm = TRUE),
  auc_ge_060 = sum(gse140829_validation$auc_ge_060, na.rm = TRUE),
  median_auc_oriented = median(gse140829_validation$auc_oriented, na.rm = TRUE),
  max_auc_oriented = max(gse140829_validation$auc_oriented, na.rm = TRUE)
)
replication_summary <- rbindlist(list(replication_summary, gse140829_replication), fill = TRUE)

s3_model <- fread(file.path(results_dir, "s3_limma_model_summary.csv"))
dataset_role_summary <- data.table(
  dataset_accession = c("GSE63060", "GSE63061", "GSE85426", "GSE140829"),
  route_b_role = c("discovery_training", "related_external_validation", "cross_platform_stress_test", "new_large_cross_platform_final_validation"),
  platform_or_scale = c("GPL6947 Illumina HT-12 v3", "GPL10558 Illumina HT-12 v4", "GPL14550 Agilent row Entrez mapping", "GPL15988 normalized gene-symbol matrix"),
  n_ad = c(s3_model$n_ad, replication_summary[dataset_accession == "GSE63061"]$n_ad, replication_summary[dataset_accession == "GSE85426"]$n_ad, gse140829_replication$n_ad),
  n_control = c(s3_model$n_control, replication_summary[dataset_accession == "GSE63061"]$n_control, replication_summary[dataset_accession == "GSE85426"]$n_control, gse140829_replication$n_control),
  diagnostic_model_status = c("discovery_only", "strong_related_cohort_performance", "failed_070_threshold", "failed_070_threshold")
)

s5_primary <- fread(file.path(results_dir, "s5_primary_model_summary.csv"))
route_a_auc <- fread(file.path(results_dir, "route_a_gse140829_model_validation.csv"))
refit_summary <- fread(file.path(results_dir, "s5_train_dev_refit_summary.csv"))

model_auc_rows <- list()
for (role in c("primary_gene_only", "primary_integrated_or_clinical")) {
  row <- s5_primary[selection_role == role][1]
  model_auc_rows[[paste0(role, "_train")]] <- data.table(
    model_role = role,
    model_id = row$model_id,
    covariate_mode = row$covariate_mode,
    dataset_accession = "GSE63060",
    evaluation_context = "training",
    auc = row$train_auc
  )
  model_auc_rows[[paste0(role, "_dev")]] <- data.table(
    model_role = role,
    model_id = row$model_id,
    covariate_mode = row$covariate_mode,
    dataset_accession = "GSE63061",
    evaluation_context = "development_selection",
    auc = row$development_auc
  )
  model_auc_rows[[paste0(role, "_gse85426")]] <- data.table(
    model_role = role,
    model_id = row$model_id,
    covariate_mode = row$covariate_mode,
    dataset_accession = "GSE85426",
    evaluation_context = "external_stress_test",
    auc = row$final_auc
  )
  ra <- route_a_auc[model_id == row$model_id][1]
  model_auc_rows[[paste0(role, "_gse140829")]] <- data.table(
    model_role = role,
    model_id = row$model_id,
    covariate_mode = row$covariate_mode,
    dataset_accession = "GSE140829",
    evaluation_context = "new_final_validation",
    auc = ra$auc_ad_vs_control,
    auc_ci_low = ra$auc_ci_low,
    auc_ci_high = ra$auc_ci_high
  )
}
refit_row <- refit_summary[selection_role == "train_dev_refit_selected_without_final"][1]
refit_a <- route_a_auc[model_id == refit_row$model_id][1]
model_auc_rows[["refit_train_dev"]] <- data.table(
  model_role = "train_dev_refit_selected",
  model_id = refit_row$model_id,
  covariate_mode = refit_row$covariate_mode,
  dataset_accession = "GSE63060+GSE63061",
  evaluation_context = "combined_refit_training",
  auc = refit_row$combined_train_dev_auc
)
model_auc_rows[["refit_gse85426"]] <- data.table(
  model_role = "train_dev_refit_selected",
  model_id = refit_row$model_id,
  covariate_mode = refit_row$covariate_mode,
  dataset_accession = "GSE85426",
  evaluation_context = "external_stress_test",
  auc = refit_row$final_auc
)
model_auc_rows[["refit_gse140829"]] <- data.table(
  model_role = "train_dev_refit_selected",
  model_id = refit_row$model_id,
  covariate_mode = refit_row$covariate_mode,
  dataset_accession = "GSE140829",
  evaluation_context = "new_final_validation",
  auc = refit_a$auc_ad_vs_control,
  auc_ci_low = refit_a$auc_ci_low,
  auc_ci_high = refit_a$auc_ci_high
)
model_auc_long <- rbindlist(model_auc_rows, fill = TRUE)
model_auc_long[, reaches_070 := auc >= target_auc]

evidence_dashboard <- replication_summary[, .(
  dataset_accession,
  validation_role,
  mapped_fraction = round(mapped_fraction, 3),
  direction_concordance_rate = round(direction_concordance_rate, 3),
  nominal_concordant,
  fdr_concordant,
  median_auc_oriented = round(median_auc_oriented, 3),
  max_auc_oriented = round(max_auc_oriented, 3)
)]
best_model_auc <- model_auc_long[dataset_accession %in% c("GSE85426", "GSE140829"), .(
  best_model_auc = max(auc, na.rm = TRUE),
  any_model_reaches_070 = any(reaches_070, na.rm = TRUE)
), by = dataset_accession]
evidence_dashboard <- merge(evidence_dashboard, best_model_auc, by = "dataset_accession", all.x = TRUE)

fwrite(gse140829_validation, file.path(results_dir, "route_b_b1_gse140829_candidate_replication.csv"))
fwrite(replication_summary, file.path(results_dir, "route_b_b1_replication_summary.csv"))
fwrite(dataset_role_summary, file.path(results_dir, "route_b_b1_dataset_role_summary.csv"))
fwrite(model_auc_long, file.path(results_dir, "route_b_b1_model_auc_long.csv"))
fwrite(evidence_dashboard, file.path(results_dir, "route_b_b1_evidence_dashboard.csv"))

dataset_order <- c("GSE63060", "GSE63061", "GSE85426", "GSE140829", "GSE63060+GSE63061")
plot_auc <- model_auc_long[dataset_accession %in% dataset_order]
plot_auc[, dataset_accession := factor(dataset_accession, levels = dataset_order)]
p_auc <- ggplot(plot_auc, aes(x = dataset_accession, y = auc, group = model_role, color = model_role)) +
  geom_hline(yintercept = target_auc, linetype = "dashed", color = "#b91c1c") +
  geom_line(linewidth = 0.8, na.rm = TRUE) +
  geom_point(size = 2, na.rm = TRUE) +
  coord_cartesian(ylim = c(0.45, 1)) +
  labs(
    title = "Route B evidence: diagnostic AUC decays across external cohorts",
    x = "Dataset",
    y = "AUC",
    color = "Model role"
  ) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))
ggsave(file.path(fig_dir, "B1_model_auc_decay.png"), p_auc, width = 8.5, height = 5.2, dpi = 180)

metric_long <- melt(
  replication_summary,
  id.vars = c("dataset_accession", "validation_role"),
  measure.vars = c("mapped_fraction", "direction_concordance_rate"),
  variable.name = "metric",
  value.name = "value"
)
metric_long[, dataset_accession := factor(dataset_accession, levels = c("GSE63061", "GSE85426", "GSE140829"))]
p_metrics <- ggplot(metric_long, aes(x = dataset_accession, y = value, fill = metric)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.65) +
  coord_cartesian(ylim = c(0, 1.05)) +
  labs(
    title = "Route B evidence: candidate mapping and directional concordance",
    x = "External dataset",
    y = "Fraction",
    fill = "Metric"
  ) +
  theme_minimal(base_size = 12)
ggsave(file.path(fig_dir, "B1_mapping_direction_concordance.png"), p_metrics, width = 7.2, height = 4.8, dpi = 180)

rep_counts <- replication_summary[, .(
  dataset_accession,
  nominal_concordant,
  fdr_concordant
)]
count_long <- melt(rep_counts, id.vars = "dataset_accession", variable.name = "metric", value.name = "count")
count_long[, dataset_accession := factor(dataset_accession, levels = c("GSE63061", "GSE85426", "GSE140829"))]
p_counts <- ggplot(count_long, aes(x = dataset_accession, y = count, fill = metric)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.65) +
  labs(
    title = "Route B evidence: concordant nominal/FDR replication collapses in cross-platform cohorts",
    x = "External dataset",
    y = "Candidate gene count",
    fill = "Replication"
  ) +
  theme_minimal(base_size = 12)
ggsave(file.path(fig_dir, "B1_concordant_replication_counts.png"), p_counts, width = 7.2, height = 4.8, dpi = 180)

candidate_auc <- rbindlist(list(
  fread(file.path(results_dir, "s4_candidate_external_validation.csv"))[, .(dataset_accession, gene_symbol, auc_oriented)],
  gse140829_validation[mapped == TRUE, .(dataset_accession, gene_symbol, auc_oriented)]
), fill = TRUE)
candidate_auc[, dataset_accession := factor(dataset_accession, levels = c("GSE63061", "GSE85426", "GSE140829"))]
p_auc_dist <- ggplot(candidate_auc, aes(x = dataset_accession, y = auc_oriented, fill = dataset_accession)) +
  geom_boxplot(width = 0.58, outlier.alpha = 0.25) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "#6b7280") +
  geom_hline(yintercept = 0.6, linetype = "dotted", color = "#b91c1c") +
  scale_fill_manual(values = c(GSE63061 = "#2563eb", GSE85426 = "#b23a48", GSE140829 = "#0f766e")) +
  labs(
    title = "Route B evidence: single-gene oriented AUC distribution",
    x = "External dataset",
    y = "Oriented single-gene AUC"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")
ggsave(file.path(fig_dir, "B1_candidate_oriented_auc_distribution.png"), p_auc_dist, width = 7.2, height = 4.8, dpi = 180)

gate_status <- if (
  replication_summary[dataset_accession == "GSE63061"]$direction_concordance_rate > 0.90 &&
    all(model_auc_long[dataset_accession %in% c("GSE85426", "GSE140829")]$auc < target_auc, na.rm = TRUE)
) {
  "PASS_ROUTE_B_FRAMING"
} else {
  "REVIEW"
}

report <- c(
  "# Route B B1 Evidence Consolidation Report",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Scope",
  "",
  "- Consolidated S3/S4/S5/Route A evidence after Route A failed.",
  "- Added GSE140829 candidate-gene replication analysis using limma with diagnosis, age, sex, and batch covariates.",
  "- Did not optimize or tune models against GSE85426 or GSE140829.",
  "",
  "## Dataset Roles",
  "",
  paste(capture.output(print(dataset_role_summary)), collapse = "\n"),
  "",
  "## Candidate Replication Summary",
  "",
  paste(capture.output(print(replication_summary)), collapse = "\n"),
  "",
  "## Model AUC Summary",
  "",
  paste(capture.output(print(model_auc_long[, .(model_role, model_id, dataset_accession, evaluation_context, auc, reaches_070)])), collapse = "\n"),
  "",
  "## B1 Gate Decision",
  "",
  paste0("Gate B1 status: **", gate_status, "**"),
  "",
  "## Interpretation",
  "",
  "- GSE63061 shows strong related-cohort replication, supporting that the S3 signal is not purely random within AddNeuroMed-like blood data.",
  "- GSE85426 and GSE140829 show markedly weaker single-gene and model-level transportability.",
  "- The evidence supports Route B framing: cohort-dependent reproducibility with limited cross-platform diagnostic transferability.",
  "",
  "## Outputs",
  "",
  "- `results/route_b_b1_gse140829_candidate_replication.csv`",
  "- `results/route_b_b1_replication_summary.csv`",
  "- `results/route_b_b1_dataset_role_summary.csv`",
  "- `results/route_b_b1_model_auc_long.csv`",
  "- `results/route_b_b1_evidence_dashboard.csv`",
  "- `figures/route_b/B1_model_auc_decay.png`",
  "- `figures/route_b/B1_mapping_direction_concordance.png`",
  "- `figures/route_b/B1_concordant_replication_counts.png`",
  "- `figures/route_b/B1_candidate_oriented_auc_distribution.png`"
)
writeLines(report, file.path(audit_dir, "route_b_b1_evidence_consolidation_report.md"))

gate <- c(
  "# Gate B1 Evidence Consolidation Review",
  "",
  paste0("Review date: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Decision",
  "",
  paste0("Gate B1 status: **", gate_status, "**"),
  "",
  "## Quantitative Basis",
  "",
  paste0(
    "- ", replication_summary$dataset_accession,
    ": mapped=", replication_summary$mapped_s3_candidate_genes,
    "; direction concordance=", sprintf("%.3f", replication_summary$direction_concordance_rate),
    "; nominal concordant=", replication_summary$nominal_concordant,
    "; FDR concordant=", replication_summary$fdr_concordant,
    "; median oriented AUC=", sprintf("%.3f", replication_summary$median_auc_oriented)
  ),
  "",
  "## Model-Level Evidence",
  "",
  paste0(
    "- ", model_auc_long$model_role, " / ", model_auc_long$dataset_accession,
    ": AUC=", sprintf("%.3f", model_auc_long$auc)
  ),
  "",
  "## Required Next Step",
  "",
  "- Proceed to B2 stable vs unstable gene-set construction.",
  "- Do not resume diagnostic classifier optimization unless a new independent dataset or a new endpoint is introduced."
)
writeLines(gate, file.path(audit_dir, "gate_b1_evidence_consolidation_review.md"))

print(evidence_dashboard)
message("Route B B1 evidence consolidation complete.")
