suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(glmnet)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
processed_dir <- file.path(root, "data", "processed")
results_dir <- file.path(root, "results")
fig_dir <- file.path(root, "figures", "s5")
audit_dir <- file.path(root, "audit")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

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

mat <- readRDS(file.path(processed_dir, "GSE85426_primary_normalized_matrix.rds"))
column_map <- fread(file.path(processed_dir, "s2_expression_column_sample_map.csv"))[dataset_accession == "GSE85426"]
locked <- fread(file.path(root, "data", "primary_inclusion_locked.csv"))[dataset_accession == "GSE85426"]
locked <- locked[match(column_map$sample_geo_accession, sample_geo_accession)]
mat <- mat[, column_map$expression_column, drop = FALSE]
labels <- as.integer(locked$diagnosis_clean == "AD")

gene_id <- sub("^.*\\|", "", rownames(mat))
gene_id[!grepl("^[0-9]+$", gene_id)] <- NA_character_
probe_var <- apply(mat, 1, var, na.rm = TRUE)
map <- data.table(probe_id = rownames(mat), gene_id = gene_id, probe_var = probe_var)
map <- map[!is.na(gene_id)]
setorder(map, gene_id, -probe_var, probe_id)
selected <- map[, .SD[1], by = gene_id]
gene_mat <- mat[selected$probe_id, , drop = FALSE]
rownames(gene_mat) <- selected$gene_id
gene_z <- zscore_rows(gene_mat)

candidate <- fread(file.path(results_dir, "s3_candidate_genes_main.csv"))
candidate[, s3_rank := seq_len(.N)]
candidate[, gene_id := primary_gene_id(gene_id)]
candidate <- candidate[!is.na(gene_id)]
candidate <- candidate[gene_id %in% rownames(gene_z)]
candidate <- candidate[, .SD[1], by = gene_id]

single <- candidate[, {
  expr <- as.numeric(gene_z[gene_id, ])
  raw_auc <- auc_rank(labels, expr)
  oriented_auc_s3 <- auc_rank(labels, sign(logFC) * expr)
  oracle_sign <- ifelse(raw_auc >= 0.5, 1, -1)
  .(
    gene_symbol = gene_symbol[1],
    s3_logFC = logFC[1],
    s3_rank = s3_rank[1],
    raw_auc = raw_auc,
    oriented_auc_s3 = oriented_auc_s3,
    oracle_auc = max(raw_auc, 1 - raw_auc),
    oracle_sign = oracle_sign
  )
}, by = gene_id]

ks <- unique(c(1:50, 75, 100, 150, 200, nrow(single)))
upper_rows <- list()
score_rows <- list()
rankings <- list(
  s3_oriented_by_gse85426_auc = single[order(-oriented_auc_s3, s3_rank)],
  oracle_by_gse85426_auc = single[order(-oracle_auc, s3_rank)]
)
for (ranking_name in names(rankings)) {
  ranked <- rankings[[ranking_name]]
  for (k in ks) {
    if (k > nrow(ranked)) next
    ids <- ranked$gene_id[seq_len(k)]
    if (ranking_name == "oracle_by_gse85426_auc") {
      signs <- ranked$oracle_sign[seq_len(k)]
    } else {
      signs <- sign(ranked$s3_logFC[seq_len(k)])
    }
    score <- as.numeric(colMeans(gene_z[ids, , drop = FALSE] * signs, na.rm = TRUE))
    auc <- auc_rank(labels, score)
    upper_rows[[paste(ranking_name, k, sep = "_")]] <- data.table(
      ranking_name = ranking_name,
      k = k,
      auc = auc,
      mean_ad = mean(score[labels == 1]),
      mean_control = mean(score[labels == 0])
    )
    score_rows[[paste(ranking_name, k, sep = "_")]] <- data.table(
      ranking_name = ranking_name,
      k = k,
      sample_geo_accession = locked$sample_geo_accession,
      diagnosis_clean = locked$diagnosis_clean,
      score = score
    )
  }
}

upper <- rbindlist(upper_rows, fill = TRUE)
scores <- rbindlist(score_rows, fill = TRUE)
best <- upper[order(-auc, k)][1]

set.seed(20260501)
x <- t(gene_z[single$gene_id, , drop = FALSE])
y <- labels
cv_rows <- list()
for (alpha in c(0, 0.5, 1)) {
  cvfit <- cv.glmnet(x, y, family = "binomial", alpha = alpha, type.measure = "auc", nfolds = 10, standardize = FALSE)
  cv_rows[[as.character(alpha)]] <- data.table(
    method = paste0("within_GSE85426_cv_glmnet_alpha_", alpha),
    cv_auc_max = max(cvfit$cvm, na.rm = TRUE),
    lambda_min = cvfit$lambda.min,
    lambda_1se = cvfit$lambda.1se
  )
}
cv_summary <- rbindlist(cv_rows, fill = TRUE)

fwrite(single[order(-oracle_auc)], file.path(results_dir, "s5_gse85426_posthoc_single_gene_upper_bound.csv"))
fwrite(upper[order(-auc)], file.path(results_dir, "s5_gse85426_posthoc_signature_upper_bound.csv"))
fwrite(scores, file.path(results_dir, "s5_gse85426_posthoc_signature_scores.csv"))
fwrite(cv_summary, file.path(results_dir, "s5_gse85426_within_dataset_cv_upper_bound.csv"))

p <- ggplot(upper, aes(x = k, y = auc, color = ranking_name)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.2, alpha = 0.75) +
  geom_hline(yintercept = 0.70, linetype = "dashed", color = "#b91c1c") +
  coord_cartesian(ylim = c(0.45, 1)) +
  labs(
    title = "GSE85426 post-hoc signature upper-bound scan",
    x = "Number of GSE85426-selected genes",
    y = "In-sample AUC",
    color = "Ranking"
  ) +
  theme_minimal(base_size = 12)
ggsave(file.path(fig_dir, "gse85426_posthoc_upper_bound_scan.png"), p, width = 7, height = 5, dpi = 180)

report <- c(
  "# GSE85426 Post-Hoc Upper-Bound Diagnostic",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Important Warning",
  "",
  "- This analysis uses GSE85426 labels to rank or orient features.",
  "- It is not valid as primary external validation evidence.",
  "- It is only a diagnostic upper-bound analysis for deciding whether the dataset contains enough signal to justify redesign.",
  "",
  "## Best Post-Hoc Signature",
  "",
  paste0("- Ranking: ", best$ranking_name),
  paste0("- k: ", best$k),
  paste0("- In-sample GSE85426 AUC: ", sprintf("%.3f", best$auc)),
  "",
  "## Within-GSE85426 CV Upper-Bound",
  "",
  paste(capture.output(print(cv_summary)), collapse = "\n"),
  "",
  "## Outputs",
  "",
  "- `results/s5_gse85426_posthoc_single_gene_upper_bound.csv`",
  "- `results/s5_gse85426_posthoc_signature_upper_bound.csv`",
  "- `results/s5_gse85426_within_dataset_cv_upper_bound.csv`",
  "- `figures/s5/gse85426_posthoc_upper_bound_scan.png`"
)
writeLines(report, file.path(audit_dir, "s5_gse85426_posthoc_upper_bound_report.md"))

print(best)
print(cv_summary)
message("GSE85426 post-hoc upper-bound diagnostic complete.")
