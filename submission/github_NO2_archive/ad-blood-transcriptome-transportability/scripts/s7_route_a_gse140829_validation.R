suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(glmnet)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
raw_dir <- file.path(root, "data", "raw")
processed_dir <- file.path(root, "data", "processed")
results_dir <- file.path(root, "results")
fig_dir <- file.path(root, "figures", "route_a")
audit_dir <- file.path(root, "audit")
dir.create(processed_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

target_auc <- 0.70
set.seed(20260501)

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

auc_ci_stratified <- function(labels, scores, b = 1000) {
  pos_idx <- which(labels == 1 & !is.na(scores))
  neg_idx <- which(labels == 0 & !is.na(scores))
  if (length(pos_idx) == 0 || length(neg_idx) == 0) {
    return(c(low = NA_real_, high = NA_real_))
  }
  vals <- replicate(b, {
    idx <- c(sample(pos_idx, length(pos_idx), replace = TRUE), sample(neg_idx, length(neg_idx), replace = TRUE))
    auc_rank(labels[idx], scores[idx])
  })
  as.numeric(quantile(vals, probs = c(0.025, 0.975), na.rm = TRUE, names = FALSE))
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

read_series_metadata_lines <- function(path) {
  con <- gzfile(path, "rt")
  on.exit(close(con), add = TRUE)
  lines <- character()
  repeat {
    line <- readLines(con, n = 1, warn = FALSE)
    if (length(line) == 0 || startsWith(line, "!series_matrix_table_begin")) break
    lines <- c(lines, line)
  }
  lines
}

extract_field <- function(lines, field) {
  hit <- lines[startsWith(lines, field)]
  if (length(hit) == 0) return(character())
  vals <- strsplit(hit[1], "\t", fixed = TRUE)[[1]][-1]
  gsub("^\"|\"$", "", vals)
}

extract_characteristics <- function(lines) {
  rows <- lines[startsWith(lines, "!Sample_characteristics_ch1")]
  out <- list()
  for (row in rows) {
    vals <- strsplit(row, "\t", fixed = TRUE)[[1]][-1]
    vals <- gsub("^\"|\"$", "", vals)
    key <- sub(":.*$", "", vals[1])
    value <- sub("^[^:]+:\\s*", "", vals)
    out[[key]] <- value
  }
  as.data.table(out)
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
  data.table(
    probe_id = as.character(annot$ID),
    gene_symbol = primary_token(annot$`Gene symbol`),
    gene_id = primary_gene_id(annot$`Gene ID`)
  )
}

collapse_probe_to_gene_id <- function(mat, map) {
  probe_var <- apply(mat, 1, var, na.rm = TRUE)
  probe_map <- data.table(probe_id = rownames(mat), probe_variance = probe_var)
  probe_map <- merge(probe_map, map, by = "probe_id", all.x = TRUE, sort = FALSE)
  probe_map <- probe_map[!is.na(gene_id) & grepl("^[0-9]+$", gene_id)]
  setorder(probe_map, gene_id, -probe_variance, probe_id)
  selected <- probe_map[, .SD[1], by = gene_id]
  gene_mat <- mat[selected$probe_id, , drop = FALSE]
  rownames(gene_mat) <- selected$gene_id
  gene_mat
}

make_clinical <- function(meta, ref = NULL) {
  age <- suppressWarnings(as.numeric(as.character(meta[["age"]])))
  gender_male <- as.integer(tolower(as.character(meta[["gender"]])) == "male")
  if (is.null(ref)) {
    ref <- list(age_mean = mean(age, na.rm = TRUE), age_sd = sd(age, na.rm = TRUE))
  }
  age_z <- ifelse(ref$age_sd == 0, 0, (age - ref$age_mean) / ref$age_sd)
  list(matrix = cbind(clinical_age_z = age_z, clinical_gender_male = gender_male), reference = ref)
}

feature_symbols <- function(feature_ids, candidate_map) {
  syms <- candidate_map$gene_symbol[match(feature_ids, candidate_map$gene_id)]
  names(syms) <- feature_ids
  syms
}

make_target_gene_matrix <- function(symbol_z, feature_ids, candidate_map) {
  syms <- feature_symbols(feature_ids, candidate_map)
  keep <- !is.na(syms) & syms %in% rownames(symbol_z)
  out <- t(symbol_z[syms[keep], , drop = FALSE])
  colnames(out) <- names(syms)[keep]
  list(matrix = out, mapped_feature_ids = names(syms)[keep], missing_feature_ids = names(syms)[!keep])
}

score_signature <- function(symbol_z, feature_ids, candidate_map) {
  syms <- feature_symbols(feature_ids, candidate_map)
  keep <- !is.na(syms) & syms %in% rownames(symbol_z)
  signs <- candidate_map$s3_sign[match(names(syms)[keep], candidate_map$gene_id)]
  score <- as.numeric(colMeans(symbol_z[syms[keep], , drop = FALSE] * signs, na.rm = TRUE))
  list(score = score, mapped_feature_ids = names(syms)[keep], missing_feature_ids = names(syms)[!keep])
}

safe_glmnet_predict <- function(model_object, x) {
  as.numeric(predict(model_object$cvfit, newx = x, s = model_object$lambda_value, type = "response"))
}

evaluate_model <- function(model_role, model_id, model_family, feature_ids, scores, sample_info) {
  labels <- as.integer(sample_info$diagnosis_clean == "AD")
  ad_ctl <- sample_info$diagnosis_clean %in% c("AD", "Control")
  ci <- auc_ci_stratified(labels[ad_ctl], scores[ad_ctl], b = 1000)
  data.table(
    model_role = model_role,
    model_id = model_id,
    model_family = model_family,
    n_features = length(feature_ids),
    feature_ids = paste(feature_ids, collapse = ";"),
    n_ad_control = sum(ad_ctl),
    n_ad = sum(sample_info$diagnosis_clean == "AD"),
    n_control = sum(sample_info$diagnosis_clean == "Control"),
    n_mci = sum(sample_info$diagnosis_clean == "MCI"),
    auc_ad_vs_control = auc_rank(labels[ad_ctl], scores[ad_ctl]),
    auc_ci_low = ci[1],
    auc_ci_high = ci[2],
    mean_ad = mean(scores[sample_info$diagnosis_clean == "AD"], na.rm = TRUE),
    mean_control = mean(scores[sample_info$diagnosis_clean == "Control"], na.rm = TRUE),
    mean_mci = mean(scores[sample_info$diagnosis_clean == "MCI"], na.rm = TRUE),
    mci_between_control_ad = {
      m <- mean(scores[sample_info$diagnosis_clean == "MCI"], na.rm = TRUE)
      a <- mean(scores[sample_info$diagnosis_clean == "AD"], na.rm = TRUE)
      c <- mean(scores[sample_info$diagnosis_clean == "Control"], na.rm = TRUE)
      (m >= min(a, c) && m <= max(a, c))
    },
    reaches_auc_070 = auc_rank(labels[ad_ctl], scores[ad_ctl]) >= target_auc
  )
}

series_path <- file.path(raw_dir, "GSE140829_series_matrix.txt.gz")
norm_path <- file.path(raw_dir, "GSE140829_final_normalized_data.txt.gz")

metadata_lines <- read_series_metadata_lines(series_path)
sample_info <- data.table(
  sample_geo_accession = extract_field(metadata_lines, "!Sample_geo_accession"),
  sample_title = extract_field(metadata_lines, "!Sample_title"),
  platform_id = extract_field(metadata_lines, "!Sample_platform_id")
)
char_dt <- extract_characteristics(metadata_lines)
sample_info <- cbind(sample_info, char_dt)
sample_info[, expression_column := sub("^Whole blood, [^,]+, ([^ ]+) \\[ad_mci\\]$", "\\1", sample_title)]
sample_info[, diagnosis_clean := fifelse(!is.na(diagnosis), diagnosis, sub("^Whole blood, ([^,]+),.*$", "\\1", sample_title))]
sample_info[, gender := fifelse(!is.na(Sex), Sex, NA_character_)]
sample_info[, age := suppressWarnings(as.numeric(age_at_draw))]
sample_info[, include_route_a_ad_control := diagnosis_clean %in% c("AD", "Control")]
sample_info[, dataset_accession := "GSE140829"]

expr <- fread(norm_path, data.table = TRUE, showProgress = FALSE)
id_col <- "ID_REF"
all_expr_cols <- setdiff(names(expr), id_col)
missing_metadata <- setdiff(all_expr_cols, sample_info$expression_column)
if (length(missing_metadata) > 0) {
  stop("GSE140829 metadata missing expression columns: ", paste(head(missing_metadata, 20), collapse = ", "))
}
sample_info <- sample_info[match(all_expr_cols, expression_column)]
if (!identical(sample_info$expression_column, all_expr_cols)) {
  stop("GSE140829 expression/metadata alignment failed")
}

ids <- as.character(expr[[id_col]])
mat <- as.matrix(expr[, ..all_expr_cols])
storage.mode(mat) <- "numeric"
rownames(mat) <- ids
valid_id <- !is.na(ids) & trimws(ids) != "" & !duplicated(ids)
mat <- mat[valid_id, , drop = FALSE]
symbol_z <- zscore_rows(mat)

saveRDS(mat, file.path(processed_dir, "GSE140829_primary_normalized_symbol_matrix.rds"))
fwrite(sample_info, file.path(root, "data", "gse140829_route_a_sample_sheet.csv"))

candidate <- fread(file.path(results_dir, "s3_candidate_genes_main.csv"))
candidate[, gene_id := primary_gene_id(gene_id)]
candidate <- candidate[!is.na(gene_id)]
candidate <- candidate[, .SD[1], by = gene_id]
candidate[, s3_sign := sign(logFC)]
candidate_map <- candidate[, .(gene_id, gene_symbol, s3_sign, s3_logFC = logFC, s3_rank = seq_len(.N))]

primary_summary <- fread(file.path(results_dir, "s5_primary_model_summary.csv"))
primary_gene <- primary_summary[selection_role == "primary_gene_only"][1]
primary_integrated <- primary_summary[selection_role == "primary_integrated_or_clinical"][1]

train_locked <- fread(file.path(root, "data", "primary_inclusion_locked.csv"))
train_meta <- train_locked[dataset_accession == "GSE63060"]
train_clin <- make_clinical(train_meta)
target_clinical <- make_clinical(sample_info, train_clin$reference)$matrix

scores <- list()
model_rows <- list()
feature_mapping_rows <- list()

gene_feature_ids <- strsplit(primary_gene$feature_ids, ";", fixed = TRUE)[[1]]
gene_sig <- score_signature(symbol_z, gene_feature_ids, candidate_map)
scores[[primary_gene$model_id]] <- gene_sig$score
model_rows[[primary_gene$model_id]] <- evaluate_model(
  "frozen_primary_gene_only",
  primary_gene$model_id,
  primary_gene$model_family,
  gene_sig$mapped_feature_ids,
  gene_sig$score,
  sample_info
)
feature_mapping_rows[[primary_gene$model_id]] <- data.table(
  model_id = primary_gene$model_id,
  requested_feature_id = gene_feature_ids,
  mapped = gene_feature_ids %in% gene_sig$mapped_feature_ids
)

integrated_object_path <- file.path(root, "models", "s5_primary_integrated_model.rds")
if (file.exists(integrated_object_path)) {
  integrated_object <- readRDS(integrated_object_path)
  integrated_features <- integrated_object$features
} else {
  integrated_object <- NULL
  integrated_features <- strsplit(primary_integrated$feature_ids, ";", fixed = TRUE)[[1]]
}
integrated_target <- make_target_gene_matrix(symbol_z, integrated_features, candidate_map)
if (!is.null(integrated_object) && all(integrated_features %in% integrated_target$mapped_feature_ids)) {
  x_integrated <- integrated_target$matrix[, integrated_features, drop = FALSE]
  x_integrated <- cbind(x_integrated, target_clinical)
  integrated_scores <- safe_glmnet_predict(integrated_object, x_integrated)
} else {
  integrated_scores <- rep(NA_real_, nrow(sample_info))
}
scores[[primary_integrated$model_id]] <- integrated_scores
model_rows[[primary_integrated$model_id]] <- evaluate_model(
  "frozen_primary_integrated",
  primary_integrated$model_id,
  primary_integrated$model_family,
  integrated_target$mapped_feature_ids,
  integrated_scores,
  sample_info
)
feature_mapping_rows[[primary_integrated$model_id]] <- data.table(
  model_id = primary_integrated$model_id,
  requested_feature_id = integrated_features,
  mapped = integrated_features %in% integrated_target$mapped_feature_ids
)

refit_summary <- fread(file.path(results_dir, "s5_train_dev_refit_summary.csv"))
refit_selected <- refit_summary[selection_role == "train_dev_refit_selected_without_final"][1]
refit_features <- strsplit(refit_selected$feature_ids, ";", fixed = TRUE)[[1]]

read_train_dev_gene_z <- function(acc) {
  raw_mat <- readRDS(file.path(processed_dir, paste0(acc, "_primary_normalized_matrix.rds")))
  map <- if (acc == "GSE63060") {
    read_geo_annotation(file.path(raw_dir, "GPL6947.annot.gz"))
  } else {
    read_geo_annotation(file.path(raw_dir, "GPL10558.annot.gz"))
  }
  zscore_rows(collapse_probe_to_gene_id(raw_mat, map))
}
train_z <- read_train_dev_gene_z("GSE63060")
dev_z <- read_train_dev_gene_z("GSE63061")
common_refit_features <- Reduce(intersect, list(refit_features, rownames(train_z), rownames(dev_z)))
refit_features <- refit_features[refit_features %in% common_refit_features]

train_dev_meta <- rbindlist(list(
  train_locked[dataset_accession == "GSE63060"],
  train_locked[dataset_accession == "GSE63061"]
), fill = TRUE)
train_dev_labels <- as.integer(train_dev_meta$diagnosis_clean == "AD")
train_dev_clin <- make_clinical(train_dev_meta)

x_train_dev_gene <- rbind(
  t(train_z[refit_features, , drop = FALSE]),
  t(dev_z[refit_features, , drop = FALSE])
)
target_refit <- make_target_gene_matrix(symbol_z, refit_features, candidate_map)
x_target_refit <- target_refit$matrix[, refit_features[refit_features %in% target_refit$mapped_feature_ids], drop = FALSE]
refit_features_mapped <- colnames(x_target_refit)
x_train_dev_gene <- x_train_dev_gene[, refit_features_mapped, drop = FALSE]

refit_alpha <- 0.5
refit_cv <- cv.glmnet(
  x_train_dev_gene,
  train_dev_labels,
  family = "binomial",
  alpha = refit_alpha,
  nfolds = 5,
  type.measure = "auc",
  standardize = FALSE
)
refit_scores <- as.numeric(predict(refit_cv, newx = x_target_refit, s = refit_cv$lambda.1se, type = "response"))
scores[[refit_selected$model_id]] <- refit_scores
model_rows[[refit_selected$model_id]] <- evaluate_model(
  "train_dev_refit_selected_without_gse140829",
  refit_selected$model_id,
  refit_selected$model_family,
  refit_features_mapped,
  refit_scores,
  sample_info
)
feature_mapping_rows[[refit_selected$model_id]] <- data.table(
  model_id = refit_selected$model_id,
  requested_feature_id = refit_features,
  mapped = refit_features %in% refit_features_mapped
)

validation_summary <- rbindlist(model_rows, fill = TRUE)
feature_mapping <- rbindlist(feature_mapping_rows, fill = TRUE)
predictions <- rbindlist(lapply(names(scores), function(mid) {
  data.table(
    model_id = mid,
    sample_geo_accession = sample_info$sample_geo_accession,
    expression_column = sample_info$expression_column,
    diagnosis_clean = sample_info$diagnosis_clean,
    age = sample_info$age,
    gender = sample_info$gender,
    score = scores[[mid]]
  )
}), fill = TRUE)

dataset_summary <- data.table(
  dataset_accession = "GSE140829",
  platform_id = unique(sample_info$platform_id)[1],
  n_samples = nrow(sample_info),
  n_ad = sum(sample_info$diagnosis_clean == "AD"),
  n_control = sum(sample_info$diagnosis_clean == "Control"),
  n_mci = sum(sample_info$diagnosis_clean == "MCI"),
  n_features_raw = nrow(expr),
  n_symbols_retained = nrow(mat),
  missing_values = sum(is.na(mat)),
  duplicate_symbol_rows_removed = sum(!valid_id),
  series_matrix_sha256 = unname(tools::sha256sum(series_path)),
  normalized_data_sha256 = unname(tools::sha256sum(norm_path))
)

fwrite(dataset_summary, file.path(results_dir, "route_a_gse140829_dataset_summary.csv"))
fwrite(validation_summary, file.path(results_dir, "route_a_gse140829_model_validation.csv"))
fwrite(predictions, file.path(results_dir, "route_a_gse140829_model_predictions.csv"))
fwrite(feature_mapping, file.path(results_dir, "route_a_gse140829_feature_mapping.csv"))

plot_dt <- predictions[diagnosis_clean %in% c("Control", "MCI", "AD")]
plot_dt[, diagnosis_clean := factor(diagnosis_clean, levels = c("Control", "MCI", "AD"))]
p <- ggplot(plot_dt, aes(x = diagnosis_clean, y = score, fill = diagnosis_clean)) +
  geom_boxplot(width = 0.55, outlier.alpha = 0.35) +
  geom_jitter(width = 0.13, alpha = 0.35, size = 0.7) +
  facet_wrap(~ model_id, scales = "free_y") +
  scale_fill_manual(values = c(Control = "#2f6f9f", MCI = "#7c6f2c", AD = "#b23a48")) +
  labs(title = "Route A GSE140829 model score validation", x = NULL, y = "Model score") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none")
ggsave(file.path(fig_dir, "GSE140829_route_a_model_score_boxplot.png"), p, width = 11, height = 5.5, dpi = 180)

gate_status <- if (any(validation_summary$reaches_auc_070, na.rm = TRUE)) "PASS" else "FAIL_SWITCH_TO_ROUTE_B"
best_row <- validation_summary[order(-auc_ad_vs_control)][1]

report <- c(
  "# Route A GSE140829 Final Validation Report",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Scope",
  "",
  "- GSE140829 was used as a newly frozen final validation dataset.",
  "- No GSE140829 labels were used for feature selection or hyperparameter tuning.",
  "- AD vs Control was the primary endpoint; MCI was evaluated only as a score-gradient check.",
  "",
  "## Dataset Summary",
  "",
  paste(capture.output(print(dataset_summary)), collapse = "\n"),
  "",
  "## Model Validation Summary",
  "",
  paste(capture.output(print(validation_summary[, .(
    model_role, model_id, n_features, auc_ad_vs_control, auc_ci_low, auc_ci_high,
    mean_control, mean_mci, mean_ad, mci_between_control_ad, reaches_auc_070
  )])), collapse = "\n"),
  "",
  "## Route A Gate Decision",
  "",
  paste0("Gate status: **", gate_status, "**"),
  "",
  paste0("Best GSE140829 AD vs Control AUC: ", sprintf("%.3f", best_row$auc_ad_vs_control), " (", best_row$model_id, ")."),
  "",
  "## Outputs",
  "",
  "- `data/gse140829_route_a_sample_sheet.csv`",
  "- `data/processed/GSE140829_primary_normalized_symbol_matrix.rds`",
  "- `results/route_a_gse140829_dataset_summary.csv`",
  "- `results/route_a_gse140829_model_validation.csv`",
  "- `results/route_a_gse140829_model_predictions.csv`",
  "- `results/route_a_gse140829_feature_mapping.csv`",
  "- `figures/route_a/GSE140829_route_a_model_score_boxplot.png`"
)
writeLines(report, file.path(audit_dir, "route_a_gse140829_validation_report.md"))

gate <- c(
  "# Route A Gate Review: GSE140829 Rescue Validation",
  "",
  paste0("Review date: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Decision",
  "",
  paste0("Route A status: **", gate_status, "**"),
  "",
  "## Quantitative Basis",
  "",
  paste0(
    "- ", validation_summary$model_role,
    ": AUC=", sprintf("%.3f", validation_summary$auc_ad_vs_control),
    " (95% CI ", sprintf("%.3f", validation_summary$auc_ci_low), "-",
    sprintf("%.3f", validation_summary$auc_ci_high), "); features=",
    validation_summary$n_features
  ),
  "",
  "## Required Next Step",
  "",
  if (gate_status == "PASS") {
    "- Proceed with Route A diagnostic-model manuscript planning and enrichment/PPI interpretation."
  } else {
    "- Switch to Route B. Do not keep optimizing classifiers against GSE140829."
  }
)
writeLines(gate, file.path(audit_dir, "gate_route_a_gse140829_review.md"))

print(validation_summary[, .(model_role, model_id, n_features, auc_ad_vs_control, auc_ci_low, auc_ci_high, mean_control, mean_mci, mean_ad, reaches_auc_070)])
message("Route A GSE140829 validation complete.")
