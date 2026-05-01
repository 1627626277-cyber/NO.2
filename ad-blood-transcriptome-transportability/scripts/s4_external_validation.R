suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(limma)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
raw_dir <- file.path(root, "data", "raw")
processed_dir <- file.path(root, "data", "processed")
results_dir <- file.path(root, "results")
fig_dir <- file.path(root, "figures", "s4")
audit_dir <- file.path(root, "audit")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

validation_sets <- c("GSE63061", "GSE85426")
signature_sizes <- c(20, 50, 100, Inf)

valid_symbol <- function(x) {
  x <- trimws(as.character(x))
  !is.na(x) & x != "" & toupper(x) != "NA" & x != "---"
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
    stop("Platform annotation missing required columns: ", paste(missing, collapse = ", "))
  }
  out <- data.table(
    probe_id = as.character(annot$ID),
    gene_symbol = primary_token(annot$`Gene symbol`),
    gene_symbol_raw = as.character(annot$`Gene symbol`),
    gene_id = primary_gene_id(annot$`Gene ID`),
    gene_title = as.character(annot$`Gene title`)
  )
  out[, is_annotated_gene := valid_symbol(gene_symbol) & !is.na(gene_id)]
  out
}

parse_gse85426_row_map <- function(mat) {
  row_id <- rownames(mat)
  gene_id <- sub("^.*\\|", "", row_id)
  gene_id[!grepl("^[0-9]+$", gene_id)] <- NA_character_
  probe_id <- sub("\\|.*$", "", row_id)
  data.table(
    probe_id = row_id,
    platform_probe_id = probe_id,
    gene_id = gene_id,
    gene_symbol = NA_character_,
    gene_symbol_raw = NA_character_,
    gene_title = NA_character_,
    is_annotated_gene = !is.na(gene_id)
  )
}

collapse_to_gene_matrix <- function(mat, map, dataset_accession) {
  probe_var <- apply(mat, 1, var, na.rm = TRUE)
  probe_map <- data.table(probe_id = rownames(mat), probe_variance = probe_var)
  probe_map <- merge(probe_map, map, by = "probe_id", all.x = TRUE, sort = FALSE)
  probe_map <- probe_map[!is.na(gene_id) & grepl("^[0-9]+$", gene_id)]
  if (nrow(probe_map) == 0) {
    stop(dataset_accession, " has no gene-level mapping")
  }
  probe_map[, probes_per_gene := .N, by = gene_id]
  setorder(probe_map, gene_id, -probe_variance, probe_id)
  selected <- probe_map[, .SD[1], by = gene_id]
  gene_mat <- mat[selected$probe_id, , drop = FALSE]
  rownames(gene_mat) <- selected$gene_id
  list(matrix = gene_mat, selected_map = selected, full_map = probe_map)
}

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

zscore_rows <- function(mat) {
  z <- t(scale(t(mat)))
  z[is.na(z)] <- 0
  z
}

run_limma_gene <- function(gene_mat, metadata, dataset_accession) {
  metadata[, diagnosis_clean := factor(diagnosis_clean, levels = c("Control", "AD"))]
  metadata[, age_numeric := suppressWarnings(as.numeric(age))]
  metadata[, gender_factor := factor(gender)]
  if (any(is.na(metadata$diagnosis_clean))) {
    stop(dataset_accession, " diagnosis labels are invalid")
  }
  if (any(is.na(metadata$age_numeric))) {
    stop(dataset_accession, " age has missing/non-numeric values")
  }
  if (any(is.na(metadata$gender_factor))) {
    stop(dataset_accession, " gender has missing values")
  }
  design <- model.matrix(~ diagnosis_clean + age_numeric + gender_factor, data = metadata)
  fit <- eBayes(lmFit(gene_mat, design))
  coef_name <- "diagnosis_cleanAD"
  if (!coef_name %in% colnames(fit$coefficients)) {
    stop(dataset_accession, " expected coefficient not found: ", coef_name)
  }
  tt <- as.data.table(topTable(fit, coef = coef_name, number = nrow(gene_mat), adjust.method = "BH", sort.by = "none"))
  tt[, gene_id := rownames(topTable(fit, coef = coef_name, number = nrow(gene_mat), adjust.method = "BH", sort.by = "none"))]
  setcolorder(tt, c("gene_id", setdiff(names(tt), "gene_id")))
  tt
}

plot_validation_scatter <- function(dataset_accession, validation) {
  p <- ggplot(validation, aes(x = s3_logFC, y = validation_logFC)) +
    geom_hline(yintercept = 0, color = "#6b7280", linewidth = 0.3) +
    geom_vline(xintercept = 0, color = "#6b7280", linewidth = 0.3) +
    geom_point(aes(color = validation_class), alpha = 0.72, size = 1.4) +
    scale_color_manual(values = c(
      fdr_concordant = "#0f766e",
      nominal_concordant = "#2563eb",
      direction_only = "#9ca3af",
      discordant = "#b91c1c"
    )) +
    labs(
      title = paste0(dataset_accession, " candidate effect concordance"),
      x = "S3 logFC/effect (GSE63060)",
      y = paste0(dataset_accession, " validation effect"),
      color = "Validation class"
    ) +
    theme_minimal(base_size = 12)
  ggsave(file.path(fig_dir, paste0(dataset_accession, "_s3_vs_validation_effect.png")), p, width = 6.5, height = 5.2, dpi = 180)
}

plot_signature_scores <- function(dataset_accession, scores) {
  p <- ggplot(scores, aes(x = diagnosis_clean, y = signature_score, fill = diagnosis_clean)) +
    geom_boxplot(width = 0.55, outlier.alpha = 0.35) +
    geom_jitter(width = 0.12, alpha = 0.45, size = 0.8) +
    facet_wrap(~ signature_size_label, scales = "free_y") +
    scale_fill_manual(values = c(AD = "#b23a48", Control = "#2f6f9f")) +
    labs(
      title = paste0(dataset_accession, " signed candidate signature scores"),
      x = NULL,
      y = "Signed mean z-score"
    ) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "none")
  ggsave(file.path(fig_dir, paste0(dataset_accession, "_signature_score_boxplot.png")), p, width = 8, height = 5.2, dpi = 180)
}

candidate <- fread(file.path(results_dir, "s3_candidate_genes_main.csv"))
candidate[, s3_rank := seq_len(.N)]
candidate[, s3_gene_id_raw := gene_id]
candidate[, gene_id := primary_gene_id(s3_gene_id_raw)]
candidate <- candidate[!is.na(gene_id)]
setorder(candidate, s3_rank)
candidate <- candidate[, .SD[1], by = gene_id]
setorder(candidate, s3_rank)
candidate_ref <- candidate[, .(
  gene_id,
  gene_symbol,
  s3_probe_id = probe_id,
  s3_logFC = logFC,
  s3_adj.P.Val = adj.P.Val,
  s3_P.Value = P.Value,
  s3_rank
)]

locked <- fread(file.path(root, "data", "primary_inclusion_locked.csv"))
column_map <- fread(file.path(processed_dir, "s2_expression_column_sample_map.csv"))
gpl10558 <- read_geo_annotation(file.path(raw_dir, "GPL10558.annot.gz"))
annotation_resources <- data.table(
  platform_id = c("GPL10558", "GPL14550"),
  source = c(
    "https://ftp.ncbi.nlm.nih.gov/geo/platforms/GPL10nnn/GPL10558/annot/GPL10558.annot.gz",
    "No standard GEO FTP annot/GPL14550.annot.gz file available; GSE85426 row-name Entrez ID suffix used"
  ),
  local_path = c(file.path(raw_dir, "GPL10558.annot.gz"), NA_character_),
  file_size_bytes = c(file.info(file.path(raw_dir, "GPL10558.annot.gz"))$size, NA_real_),
  sha256 = c(unname(tools::sha256sum(file.path(raw_dir, "GPL10558.annot.gz"))), NA_character_)
)

validation_tables <- list()
dataset_summaries <- list()
mapping_tables <- list()
signature_summary_tables <- list()
signature_score_tables <- list()

for (acc in validation_sets) {
  message("Validating ", acc)
  mat <- readRDS(file.path(processed_dir, paste0(acc, "_primary_normalized_matrix.rds")))
  cm <- column_map[dataset_accession == acc]
  if (!all(cm$expression_column %in% colnames(mat))) {
    missing_cols <- setdiff(cm$expression_column, colnames(mat))
    stop(acc, " missing expression columns: ", paste(missing_cols, collapse = ", "))
  }
  mat <- mat[, cm$expression_column, drop = FALSE]
  metadata <- locked[dataset_accession == acc]
  metadata <- metadata[match(cm$sample_geo_accession, sample_geo_accession)]
  if (any(is.na(metadata$sample_geo_accession))) {
    stop(acc, " metadata alignment failed")
  }
  metadata[, expression_column := cm$expression_column]

  if (acc == "GSE63061") {
    platform_map <- gpl10558
    map_source <- "GPL10558 GEO annotation"
  } else if (acc == "GSE85426") {
    platform_map <- parse_gse85426_row_map(mat)
    map_source <- "GSE85426 row-name Entrez ID suffix"
  } else {
    stop("Unsupported validation set: ", acc)
  }

  collapsed <- collapse_to_gene_matrix(mat, platform_map, acc)
  gene_mat <- collapsed$matrix
  selected_map <- collapsed$selected_map
  mapping_tables[[acc]] <- data.table(dataset_accession = acc, selected_map)

  limma_res <- run_limma_gene(gene_mat, metadata, acc)
  limma_res <- merge(limma_res, selected_map[, .(
    gene_id,
    validation_probe_id = probe_id,
    validation_gene_symbol = gene_symbol,
    validation_probe_variance = probe_variance,
    validation_probes_per_gene = probes_per_gene
  )], by = "gene_id", all.x = TRUE, sort = FALSE)

  validation <- merge(candidate_ref, limma_res, by = "gene_id", all.x = FALSE, sort = FALSE)
  setnames(validation, old = c("logFC", "AveExpr", "t", "P.Value", "adj.P.Val", "B"), new = c(
    "validation_logFC", "validation_AveExpr", "validation_t", "validation_P.Value", "validation_adj.P.Val", "validation_B"
  ))
  validation[, dataset_accession := acc]
  validation[, direction_concordant := sign(s3_logFC) == sign(validation_logFC)]
  validation[, nominal_concordant := direction_concordant & validation_P.Value < 0.05]
  validation[, fdr_concordant := direction_concordant & validation_adj.P.Val < 0.05]
  labels <- as.integer(metadata$diagnosis_clean == "AD")
  validation[, auc_oriented := {
    expr <- as.numeric(gene_mat[gene_id[1], ])
    auc_rank(labels, sign(s3_logFC) * expr)
  }, by = gene_id]
  validation[, auc_raw_expression := {
    expr <- as.numeric(gene_mat[gene_id[1], ])
    auc_rank(labels, expr)
  }, by = gene_id]
  validation[, auc_ge_060 := auc_oriented >= 0.60]
  validation[, validation_class := fifelse(
    fdr_concordant, "fdr_concordant",
    fifelse(nominal_concordant, "nominal_concordant",
      fifelse(direction_concordant, "direction_only", "discordant")
    )
  )]
  setcolorder(validation, c("dataset_accession", "gene_id", "gene_symbol", "s3_rank", setdiff(names(validation), c("dataset_accession", "gene_id", "gene_symbol", "s3_rank"))))
  validation_tables[[acc]] <- validation

  plot_validation_scatter(acc, validation)

  signature_rows <- list()
  signature_scores <- list()
  for (n in signature_sizes) {
    mapped <- validation[order(s3_rank)]
    if (is.finite(n)) {
      mapped <- mapped[seq_len(min(n, .N))]
      size_label <- paste0("top", n)
    } else {
      size_label <- "all_mapped"
    }
    feature_ids <- mapped$gene_id
    signs <- sign(mapped$s3_logFC)
    z <- zscore_rows(gene_mat[feature_ids, , drop = FALSE])
    score <- colMeans(z * signs, na.rm = TRUE)
    auc <- auc_rank(labels, score)
    t_p <- tryCatch(t.test(score[labels == 1], score[labels == 0])$p.value, error = function(e) NA_real_)
    mean_ad <- mean(score[labels == 1], na.rm = TRUE)
    mean_control <- mean(score[labels == 0], na.rm = TRUE)
    signature_rows[[size_label]] <- data.table(
      dataset_accession = acc,
      signature_size_label = size_label,
      n_features = length(feature_ids),
      auc_oriented = auc,
      mean_ad = mean_ad,
      mean_control = mean_control,
      ad_minus_control = mean_ad - mean_control,
      t_test_p = t_p
    )
    signature_scores[[size_label]] <- data.table(
      dataset_accession = acc,
      signature_size_label = size_label,
      sample_geo_accession = metadata$sample_geo_accession,
      expression_column = metadata$expression_column,
      diagnosis_clean = as.character(metadata$diagnosis_clean),
      signature_score = score
    )
  }
  sig_summary <- rbindlist(signature_rows, fill = TRUE)
  sig_scores <- rbindlist(signature_scores, fill = TRUE)
  signature_summary_tables[[acc]] <- sig_summary
  signature_score_tables[[acc]] <- sig_scores
  plot_signature_scores(acc, sig_scores)

  dataset_summaries[[acc]] <- data.table(
    dataset_accession = acc,
    map_source = map_source,
    n_samples = ncol(mat),
    n_ad = sum(metadata$diagnosis_clean == "AD"),
    n_control = sum(metadata$diagnosis_clean == "Control"),
    original_features = nrow(mat),
    mapped_gene_rows_before_collapse = nrow(collapsed$full_map),
    collapsed_unique_genes = nrow(gene_mat),
    s3_candidate_genes_with_entrez = nrow(candidate_ref),
    mapped_s3_candidate_genes = nrow(validation),
    mapped_fraction = nrow(validation) / nrow(candidate_ref),
    direction_concordant = sum(validation$direction_concordant, na.rm = TRUE),
    direction_concordance_rate = mean(validation$direction_concordant, na.rm = TRUE),
    nominal_concordant = sum(validation$nominal_concordant, na.rm = TRUE),
    fdr_concordant = sum(validation$fdr_concordant, na.rm = TRUE),
    auc_ge_060 = sum(validation$auc_ge_060, na.rm = TRUE),
    median_auc_oriented = median(validation$auc_oriented, na.rm = TRUE),
    max_auc_oriented = max(validation$auc_oriented, na.rm = TRUE)
  )
}

validation_all <- rbindlist(validation_tables, fill = TRUE)
dataset_summary <- rbindlist(dataset_summaries, fill = TRUE)
mapping_all <- rbindlist(mapping_tables, fill = TRUE)
signature_summary <- rbindlist(signature_summary_tables, fill = TRUE)
signature_scores <- rbindlist(signature_score_tables, fill = TRUE)

fwrite(validation_all, file.path(results_dir, "s4_candidate_external_validation.csv"))
fwrite(dataset_summary, file.path(results_dir, "s4_external_validation_dataset_summary.csv"))
fwrite(mapping_all, file.path(results_dir, "s4_gene_mapping_selected_representatives.csv"))
fwrite(signature_summary, file.path(results_dir, "s4_signature_score_summary.csv"))
fwrite(signature_scores, file.path(results_dir, "s4_signature_sample_scores.csv"))
fwrite(annotation_resources, file.path(results_dir, "s4_annotation_resource_summary.csv"))

auc_bar <- ggplot(signature_summary, aes(x = signature_size_label, y = auc_oriented, fill = dataset_accession)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.65) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "#6b7280") +
  coord_cartesian(ylim = c(0.45, 1)) +
  scale_fill_manual(values = c(GSE63061 = "#2563eb", GSE85426 = "#b23a48")) +
  labs(
    title = "External validation signed signature AUC",
    x = "S3 candidate signature",
    y = "AUC",
    fill = "Dataset"
  ) +
  theme_minimal(base_size = 12)
ggsave(file.path(fig_dir, "signature_auc_barplot.png"), auc_bar, width = 7, height = 4.8, dpi = 180)

session_lines <- capture.output(sessionInfo())
writeLines(session_lines, file.path(audit_dir, "s4_sessionInfo.txt"))

top50 <- signature_summary[signature_size_label == "top50"]
gate_status <- if (
  all(dataset_summary$mapped_s3_candidate_genes >= 150) &&
    all(top50$auc_oriented >= 0.60)
) {
  "PASS"
} else if (
  all(dataset_summary$mapped_s3_candidate_genes >= 100) &&
    all(top50$auc_oriented >= 0.55)
) {
  "CONDITIONAL PASS"
} else {
  "REVIEW"
}

top_validation_lines <- validation_all[order(dataset_accession, -auc_oriented)][
  , head(.SD, 10), by = dataset_accession
][
  , paste0(
    "- ", dataset_accession, ": ", gene_symbol,
    " (Entrez=", gene_id,
    ", validation effect=", sprintf("%.3f", validation_logFC),
    ", P=", formatC(validation_P.Value, format = "e", digits = 2),
    ", oriented AUC=", sprintf("%.3f", auc_oriented),
    ", direction=", ifelse(direction_concordant, "concordant", "discordant"),
    ")"
  )
]

report <- c(
  "# S4 External Validation and Candidate Stability Report",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Scope",
  "",
  "- Validation datasets: GSE63061 and GSE85426.",
  "- S3 candidate threshold and ranking were frozen before validation.",
  "- Validation was performed at Entrez gene level to avoid invalid cross-platform probe matching.",
  "- Repeated validation probes per gene were collapsed by highest within-dataset variance.",
  "- Primary validation model per dataset: limma linear model `expression ~ diagnosis + age + gender`.",
  "",
  "## Dataset Summary",
  "",
  paste(capture.output(print(dataset_summary)), collapse = "\n"),
  "",
  "## Signed Signature Score Summary",
  "",
  paste(capture.output(print(signature_summary)), collapse = "\n"),
  "",
  "## Highest Single-Gene Oriented AUC Candidates",
  "",
  top_validation_lines,
  "",
  "## Outputs",
  "",
  "- `results/s4_candidate_external_validation.csv`",
  "- `results/s4_external_validation_dataset_summary.csv`",
  "- `results/s4_gene_mapping_selected_representatives.csv`",
  "- `results/s4_signature_score_summary.csv`",
  "- `results/s4_signature_sample_scores.csv`",
  "- `results/s4_annotation_resource_summary.csv`",
  "- `figures/s4/*_s3_vs_validation_effect.png`",
  "- `figures/s4/*_signature_score_boxplot.png`",
  "- `figures/s4/signature_auc_barplot.png`",
  "- `audit/s4_sessionInfo.txt`",
  "",
  "## Gate 4 Preliminary Decision",
  "",
  paste0(gate_status, ". External validation evidence is evaluated by mapping coverage and top50 signed signature AUC."),
  "",
  "## Caveats",
  "",
  "- GSE63061 and GSE85426 use different platforms from GSE63060; validation is gene-level rather than identical-probe validation.",
  "- GSE85426 mapping uses Entrez IDs embedded in expression row names because no standard GEO platform annotation file is available at the expected FTP annot path.",
  "- S4 evaluates transportability of frozen S3 candidates; formal diagnostic model development remains S5."
)
writeLines(report, file.path(audit_dir, "s4_external_validation_report.md"))

gate <- c(
  "# Gate 4 External Validation Review",
  "",
  paste0("Review date: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Decision",
  "",
  paste0("Gate 4 status: **", gate_status, "**"),
  "",
  "## Checks",
  "",
  "- Validation datasets were not used to change S3 thresholds: PASS.",
  "- Cross-platform validation used Entrez gene-level mapping: PASS.",
  "- Age and gender covariates included in validation differential models: PASS.",
  "- Direction concordance, nominal significance, FDR significance, single-gene AUC and signature AUC exported: PASS.",
  "",
  "## Quantitative Basis",
  "",
  paste0(
    "- ", dataset_summary$dataset_accession,
    ": mapped candidate genes = ", dataset_summary$mapped_s3_candidate_genes,
    "; direction concordance = ", sprintf("%.3f", dataset_summary$direction_concordance_rate),
    "; nominal concordant = ", dataset_summary$nominal_concordant,
    "; FDR concordant = ", dataset_summary$fdr_concordant,
    "; median oriented AUC = ", sprintf("%.3f", dataset_summary$median_auc_oriented),
    "; max oriented AUC = ", sprintf("%.3f", dataset_summary$max_auc_oriented)
  ),
  "",
  "## Required Next Step",
  "",
  "- If Gate 4 is PASS or CONDITIONAL PASS, proceed to biological interpretation and/or model construction using only frozen feature rules.",
  "- If Gate 4 is REVIEW, revisit project feasibility before investing in downstream paper writing."
)
writeLines(gate, file.path(audit_dir, "gate4_external_validation_review.md"))

print(dataset_summary)
print(signature_summary)
message("S4 external validation complete.")
