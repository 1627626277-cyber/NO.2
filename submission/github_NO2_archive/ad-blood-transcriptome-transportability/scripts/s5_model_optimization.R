suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(limma)
  library(glmnet)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
raw_dir <- file.path(root, "data", "raw")
processed_dir <- file.path(root, "data", "processed")
results_dir <- file.path(root, "results")
fig_dir <- file.path(root, "figures", "s5")
audit_dir <- file.path(root, "audit")
models_dir <- file.path(root, "models")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(models_dir, showWarnings = FALSE, recursive = TRUE)

datasets <- c("GSE63060", "GSE63061", "GSE85426")
training_acc <- "GSE63060"
development_acc <- "GSE63061"
final_acc <- "GSE85426"
target_final_auc <- 0.70

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
  data.table(
    probe_id = as.character(annot$ID),
    gene_symbol = primary_token(annot$`Gene symbol`),
    gene_symbol_raw = as.character(annot$`Gene symbol`),
    gene_id = primary_gene_id(annot$`Gene ID`),
    gene_title = as.character(annot$`Gene title`)
  )
}

parse_gse85426_row_map <- function(mat) {
  row_id <- rownames(mat)
  gene_id <- sub("^.*\\|", "", row_id)
  gene_id[!grepl("^[0-9]+$", gene_id)] <- NA_character_
  data.table(
    probe_id = row_id,
    gene_symbol = NA_character_,
    gene_symbol_raw = NA_character_,
    gene_id = gene_id,
    gene_title = NA_character_
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
  list(matrix = gene_mat, selected_map = selected)
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

make_clinical <- function(meta, train_reference = NULL) {
  age <- suppressWarnings(as.numeric(as.character(meta[["age"]])))
  gender_male <- as.integer(tolower(as.character(meta[["gender"]])) == "male")
  if (length(age) != nrow(meta) || length(gender_male) != nrow(meta)) {
    stop("Clinical covariate length mismatch")
  }
  if (is.null(train_reference)) {
    ref <- list(age_mean = mean(age, na.rm = TRUE), age_sd = sd(age, na.rm = TRUE))
  } else {
    ref <- train_reference
  }
  age_z <- ifelse(ref$age_sd == 0, 0, (age - ref$age_mean) / ref$age_sd)
  list(
    matrix = cbind(clinical_age_z = age_z, clinical_gender_male = gender_male),
    reference = ref
  )
}

sigmoid <- function(x) 1 / (1 + exp(-x))

safe_glm <- function(x, y) {
  df <- as.data.frame(x)
  df$y <- y
  tryCatch(
    suppressWarnings(glm(y ~ ., data = df, family = binomial())),
    error = function(e) NULL
  )
}

predict_glm <- function(model, x) {
  if (is.null(model)) return(rep(NA_real_, nrow(x)))
  suppressWarnings(as.numeric(predict(model, newdata = as.data.frame(x), type = "response")))
}

evaluate_scores <- function(model_id, model_family, feature_strategy, feature_ids, score_list, labels_by_dataset, covariate_mode, leakage_class) {
  rows <- lapply(names(score_list), function(acc) {
    scores <- score_list[[acc]]
    data.table(
      model_id = model_id,
      model_family = model_family,
      feature_strategy = feature_strategy,
      covariate_mode = covariate_mode,
      leakage_class = leakage_class,
      n_model_features = length(feature_ids),
      feature_ids = paste(feature_ids, collapse = ";"),
      dataset_accession = acc,
      auc = auc_rank(labels_by_dataset[[acc]], scores),
      mean_ad_score = mean(scores[labels_by_dataset[[acc]] == 1], na.rm = TRUE),
      mean_control_score = mean(scores[labels_by_dataset[[acc]] == 0], na.rm = TRUE)
    )
  })
  rbindlist(rows, fill = TRUE)
}

locked <- fread(file.path(root, "data", "primary_inclusion_locked.csv"))
column_map <- fread(file.path(processed_dir, "s2_expression_column_sample_map.csv"))
candidate <- fread(file.path(results_dir, "s3_candidate_genes_main.csv"))
candidate[, s3_rank := seq_len(.N)]
candidate[, s3_gene_id_raw := gene_id]
candidate[, gene_id := primary_gene_id(s3_gene_id_raw)]
candidate[, gene_id := as.character(gene_id)]
candidate <- candidate[!is.na(gene_id)]
candidate <- candidate[, .SD[1], by = gene_id]
setorder(candidate, s3_rank)
candidate_ref <- candidate[, .(
  gene_id,
  gene_symbol,
  s3_probe_id = probe_id,
  s3_logFC = logFC,
  s3_abs_logFC = abs(logFC),
  s3_adj.P.Val = adj.P.Val,
  s3_rank
)]

gpl6947 <- read_geo_annotation(file.path(raw_dir, "GPL6947.annot.gz"))
gpl10558 <- read_geo_annotation(file.path(raw_dir, "GPL10558.annot.gz"))

gene_z <- list()
gene_raw <- list()
metadata_by_dataset <- list()
labels_by_dataset <- list()
clinical_by_dataset <- list()
selected_maps <- list()

for (acc in datasets) {
  mat <- readRDS(file.path(processed_dir, paste0(acc, "_primary_normalized_matrix.rds")))
  cm <- column_map[dataset_accession == acc]
  mat <- mat[, cm$expression_column, drop = FALSE]
  metadata <- locked[dataset_accession == acc]
  metadata <- metadata[match(cm$sample_geo_accession, sample_geo_accession)]
  metadata[, expression_column := cm$expression_column]
  metadata_by_dataset[[acc]] <- metadata
  labels_by_dataset[[acc]] <- as.integer(metadata$diagnosis_clean == "AD")

  platform_map <- switch(
    acc,
    GSE63060 = gpl6947,
    GSE63061 = gpl10558,
    GSE85426 = parse_gse85426_row_map(mat)
  )
  collapsed <- collapse_to_gene_matrix(mat, platform_map, acc)
  gene_raw[[acc]] <- collapsed$matrix
  gene_z[[acc]] <- zscore_rows(collapsed$matrix)
  selected_maps[[acc]] <- data.table(dataset_accession = acc, collapsed$selected_map)
}

train_clinical <- make_clinical(metadata_by_dataset[[training_acc]])
clinical_by_dataset[[training_acc]] <- train_clinical$matrix
for (acc in setdiff(datasets, training_acc)) {
  clinical_by_dataset[[acc]] <- make_clinical(metadata_by_dataset[[acc]], train_clinical$reference)$matrix
}

common_gene_ids <- Reduce(intersect, c(lapply(gene_z, rownames), list(candidate_ref$gene_id)))
candidate_ref <- candidate_ref[gene_id %in% common_gene_ids]
setorder(candidate_ref, s3_rank)

s4_validation <- fread(file.path(results_dir, "s4_candidate_external_validation.csv"))
s4_validation[, gene_id := as.character(gene_id)]
dev_metrics <- s4_validation[dataset_accession == development_acc, .(
  gene_id,
  dev_logFC = validation_logFC,
  dev_P.Value = validation_P.Value,
  dev_adj.P.Val = validation_adj.P.Val,
  dev_auc_oriented = auc_oriented,
  dev_direction_concordant = direction_concordant,
  dev_nominal_concordant = nominal_concordant,
  dev_fdr_concordant = fdr_concordant
)]
candidate_ref <- merge(candidate_ref, dev_metrics, by = "gene_id", all.x = TRUE, sort = FALSE)
candidate_ref[is.na(dev_auc_oriented), dev_auc_oriented := 0.5]
candidate_ref[is.na(dev_P.Value), dev_P.Value := 1]
candidate_ref[is.na(dev_adj.P.Val), dev_adj.P.Val := 1]
candidate_ref[is.na(dev_direction_concordant), dev_direction_concordant := FALSE]
candidate_ref[is.na(dev_nominal_concordant), dev_nominal_concordant := FALSE]
candidate_ref[is.na(dev_fdr_concordant), dev_fdr_concordant := FALSE]

ranking_tables <- list(
  s3_rank = candidate_ref[order(s3_rank)],
  dev_auc = candidate_ref[order(-dev_auc_oriented, dev_P.Value, s3_rank)],
  dev_p = candidate_ref[order(dev_P.Value, -dev_auc_oriented, s3_rank)],
  dev_fdr_concordant_auc = candidate_ref[dev_fdr_concordant == TRUE][order(-dev_auc_oriented, dev_P.Value, s3_rank)],
  dev_nominal_concordant_auc = candidate_ref[dev_nominal_concordant == TRUE][order(-dev_auc_oriented, dev_P.Value, s3_rank)]
)
ranking_tables <- ranking_tables[vapply(ranking_tables, nrow, integer(1)) > 0]

model_rows <- list()
prediction_tables <- list()
coefficient_tables <- list()
model_objects <- list()

add_model <- function(model_id, model_family, feature_strategy, feature_ids, score_list, covariate_mode = "gene_only", leakage_class = "primary_eligible") {
  model_rows[[model_id]] <<- evaluate_scores(
    model_id, model_family, feature_strategy, feature_ids, score_list, labels_by_dataset, covariate_mode, leakage_class
  )
  prediction_tables[[model_id]] <<- rbindlist(lapply(names(score_list), function(acc) {
    data.table(
      model_id = model_id,
      dataset_accession = acc,
      sample_geo_accession = metadata_by_dataset[[acc]]$sample_geo_accession,
      diagnosis_clean = metadata_by_dataset[[acc]]$diagnosis_clean,
      score = score_list[[acc]]
    )
  }), fill = TRUE)
}

signature_ks <- unique(c(1:25, 30, 40, 50, 75, 100, 150, 200, nrow(candidate_ref)))
for (ranking_name in names(ranking_tables)) {
  ranked <- ranking_tables[[ranking_name]]
  for (k in signature_ks) {
    if (k > nrow(ranked)) next
    feat <- ranked$gene_id[seq_len(k)]
    signs <- sign(candidate_ref[match(feat, gene_id), s3_logFC])
    score_list <- lapply(datasets, function(acc) {
      z <- gene_z[[acc]][feat, , drop = FALSE]
      as.numeric(colMeans(z * signs, na.rm = TRUE))
    })
    names(score_list) <- datasets
    dev_auc <- auc_rank(labels_by_dataset[[development_acc]], score_list[[development_acc]])
    orientation <- ifelse(!is.na(dev_auc) && dev_auc < 0.5, -1, 1)
    score_list <- lapply(score_list, function(x) orientation * x)
    add_model(
      paste0("sig_", ranking_name, "_k", k),
      "signed_mean_signature",
      paste0(ranking_name, "_top", k),
      feat,
      score_list,
      "gene_only",
      "primary_eligible"
    )

    x_train <- cbind(signature_score = score_list[[training_acc]], clinical_by_dataset[[training_acc]])
    glm_model <- safe_glm(x_train, labels_by_dataset[[training_acc]])
    clinical_scores <- lapply(datasets, function(acc) {
      x <- cbind(signature_score = score_list[[acc]], clinical_by_dataset[[acc]])
      predict_glm(glm_model, x)
    })
    names(clinical_scores) <- datasets
    add_model(
      paste0("sigclin_", ranking_name, "_k", k),
      "signature_plus_clinical_glm",
      paste0(ranking_name, "_top", k),
      feat,
      clinical_scores,
      "gene_plus_age_gender",
      "primary_eligible"
    )
  }
}

clinical_model <- safe_glm(clinical_by_dataset[[training_acc]], labels_by_dataset[[training_acc]])
clinical_scores <- lapply(datasets, function(acc) predict_glm(clinical_model, clinical_by_dataset[[acc]]))
names(clinical_scores) <- datasets
add_model("clinical_only", "clinical_glm", "age_gender_only", character(0), clinical_scores, "age_gender_only", "primary_eligible")

glmnet_pool_ks <- unique(c(5, 10, 15, 20, 30, 50, 100, nrow(candidate_ref)))
glmnet_specs <- CJ(
  ranking_name = names(ranking_tables),
  k = glmnet_pool_ks,
  alpha = c(0, 0.5, 1),
  lambda_rule = c("lambda.min", "lambda.1se"),
  include_clinical = c(FALSE, TRUE)
)

set.seed(20260501)
for (i in seq_len(nrow(glmnet_specs))) {
  spec <- glmnet_specs[i]
  ranked <- ranking_tables[[spec$ranking_name]]
  if (spec$k > nrow(ranked)) next
  feat <- ranked$gene_id[seq_len(spec$k)]
  x_train_gene <- t(gene_z[[training_acc]][feat, , drop = FALSE])
  if (spec$include_clinical) {
    x_train <- cbind(x_train_gene, clinical_by_dataset[[training_acc]])
    cov_mode <- "gene_plus_age_gender"
  } else {
    x_train <- x_train_gene
    cov_mode <- "gene_only"
  }
  y_train <- labels_by_dataset[[training_acc]]
  cvfit <- tryCatch(
    suppressWarnings(cv.glmnet(
      x_train,
      y_train,
      family = "binomial",
      alpha = spec$alpha,
      nfolds = 5,
      type.measure = "auc",
      standardize = FALSE
    )),
    error = function(e) NULL
  )
  if (is.null(cvfit)) next
  lambda_value <- if (spec$lambda_rule == "lambda.min") cvfit$lambda.min else cvfit$lambda.1se
  score_list <- lapply(datasets, function(acc) {
    x_gene <- t(gene_z[[acc]][feat, , drop = FALSE])
    if (spec$include_clinical) {
      x <- cbind(x_gene, clinical_by_dataset[[acc]])
    } else {
      x <- x_gene
    }
    as.numeric(predict(cvfit, newx = x, s = lambda_value, type = "response"))
  })
  names(score_list) <- datasets
  model_id <- paste0(
    "glmnet_", spec$ranking_name, "_k", spec$k,
    "_a", gsub("\\.", "", as.character(spec$alpha)),
    "_", spec$lambda_rule,
    ifelse(spec$include_clinical, "_clin", "_gene")
  )
  add_model(
    model_id,
    paste0("glmnet_alpha_", spec$alpha),
    paste0(spec$ranking_name, "_top", spec$k, "_", spec$lambda_rule),
    feat,
    score_list,
    cov_mode,
    "primary_eligible"
  )
  coef_mat <- as.matrix(coef(cvfit, s = lambda_value))
  coef_dt <- data.table(
    model_id = model_id,
    feature = rownames(coef_mat),
    coefficient = as.numeric(coef_mat[, 1])
  )[coefficient != 0]
  coefficient_tables[[model_id]] <- coef_dt
  model_objects[[model_id]] <- list(cvfit = cvfit, lambda_value = lambda_value, features = feat, include_clinical = spec$include_clinical)
}

model_perf_long <- rbindlist(model_rows, fill = TRUE)
model_perf <- dcast(
  model_perf_long,
  model_id + model_family + feature_strategy + covariate_mode + leakage_class + n_model_features + feature_ids ~ dataset_accession,
  value.var = c("auc", "mean_ad_score", "mean_control_score")
)
setnames(model_perf, old = c(
  paste0("auc_", training_acc), paste0("auc_", development_acc), paste0("auc_", final_acc)
), new = c("train_auc", "development_auc", "final_auc"))
model_perf[, reaches_final_auc_070 := final_auc >= target_final_auc]
model_perf[, development_minus_final_auc := development_auc - final_auc]

select_primary <- function(dt, cov_modes) {
  candidates <- dt[covariate_mode %in% cov_modes & leakage_class == "primary_eligible"]
  candidates <- candidates[!is.na(development_auc) & !is.na(final_auc)]
  if (nrow(candidates) == 0) return(NULL)
  max_dev <- max(candidates$development_auc, na.rm = TRUE)
  near_best <- candidates[development_auc >= max_dev - 0.01]
  setorder(near_best, n_model_features, -development_auc, model_family)
  near_best[1]
}

primary_gene <- select_primary(model_perf, "gene_only")
primary_integrated <- select_primary(model_perf, c("gene_plus_age_gender", "age_gender_only"))
posthoc_upper_bound <- model_perf[!is.na(final_auc)][order(-final_auc, -development_auc, n_model_features)][1]
if (nrow(posthoc_upper_bound) > 0) {
  posthoc_upper_bound[, leakage_class := "posthoc_final_auc_upper_bound_not_primary"]
}

primary_models <- rbindlist(list(
  data.table(selection_role = "primary_gene_only", primary_gene),
  data.table(selection_role = "primary_integrated_or_clinical", primary_integrated),
  data.table(selection_role = "posthoc_upper_bound_not_primary", posthoc_upper_bound)
), fill = TRUE)

predictions <- rbindlist(prediction_tables, fill = TRUE)
coefficients <- rbindlist(coefficient_tables, fill = TRUE)
if (nrow(coefficients) == 0) {
  coefficients <- data.table(model_id = character(), feature = character(), coefficient = numeric())
}

fwrite(model_perf[order(-development_auc, n_model_features)], file.path(results_dir, "s5_model_optimization_grid.csv"))
fwrite(primary_models, file.path(results_dir, "s5_primary_model_summary.csv"))
fwrite(predictions, file.path(results_dir, "s5_model_predictions.csv"))
fwrite(coefficients, file.path(results_dir, "s5_glmnet_nonzero_coefficients.csv"))
fwrite(rbindlist(selected_maps, fill = TRUE), file.path(results_dir, "s5_gene_mapping_selected_representatives.csv"))

if (nrow(primary_gene) > 0 && primary_gene$model_id %in% names(model_objects)) {
  saveRDS(model_objects[[primary_gene$model_id]], file.path(models_dir, "s5_primary_gene_model.rds"))
}
if (nrow(primary_integrated) > 0 && primary_integrated$model_id %in% names(model_objects)) {
  saveRDS(model_objects[[primary_integrated$model_id]], file.path(models_dir, "s5_primary_integrated_model.rds"))
}

plot_dt <- rbindlist(list(
  data.table(selection_role = "primary_gene_only", primary_gene),
  data.table(selection_role = "primary_integrated_or_clinical", primary_integrated),
  data.table(selection_role = "posthoc_upper_bound_not_primary", posthoc_upper_bound)
), fill = TRUE)
plot_dt <- melt(
  plot_dt,
  id.vars = c("selection_role", "model_id", "covariate_mode", "n_model_features"),
  measure.vars = c("train_auc", "development_auc", "final_auc"),
  variable.name = "evaluation_set",
  value.name = "auc"
)
auc_plot <- ggplot(plot_dt, aes(x = evaluation_set, y = auc, fill = selection_role)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.65) +
  geom_hline(yintercept = target_final_auc, linetype = "dashed", color = "#b91c1c") +
  coord_cartesian(ylim = c(0.45, 1)) +
  labs(
    title = "S5 selected model AUC comparison",
    x = NULL,
    y = "AUC",
    fill = "Selection"
  ) +
  theme_minimal(base_size = 12)
ggsave(file.path(fig_dir, "selected_model_auc_comparison.png"), auc_plot, width = 8, height = 5, dpi = 180)

selected_prediction_ids <- unique(primary_models$model_id)
score_plot_dt <- predictions[model_id %in% selected_prediction_ids]
score_plot_dt <- merge(score_plot_dt, primary_models[, .(model_id, selection_role)], by = "model_id", all.x = TRUE)
score_plot <- ggplot(score_plot_dt, aes(x = diagnosis_clean, y = score, fill = diagnosis_clean)) +
  geom_boxplot(width = 0.55, outlier.alpha = 0.35) +
  geom_jitter(width = 0.12, alpha = 0.45, size = 0.75) +
  facet_grid(selection_role ~ dataset_accession, scales = "free_y") +
  scale_fill_manual(values = c(AD = "#b23a48", Control = "#2f6f9f")) +
  labs(
    title = "S5 selected model score distributions",
    x = NULL,
    y = "Model score"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none")
ggsave(file.path(fig_dir, "selected_model_score_boxplot.png"), score_plot, width = 10, height = 7, dpi = 180)

session_lines <- capture.output(sessionInfo())
writeLines(session_lines, file.path(audit_dir, "s5_sessionInfo.txt"))

primary_gene_final <- if (nrow(primary_gene) > 0) primary_gene$final_auc else NA_real_
primary_integrated_final <- if (nrow(primary_integrated) > 0) primary_integrated$final_auc else NA_real_
gate_status <- if (!is.na(primary_gene_final) && primary_gene_final >= target_final_auc) {
  "PASS"
} else if (!is.na(primary_integrated_final) && primary_integrated_final >= target_final_auc) {
  "CONDITIONAL PASS"
} else {
  "REVIEW"
}

format_model_line <- function(role, row) {
  if (nrow(row) == 0) return(paste0("- ", role, ": not available"))
  paste0(
    "- ", role, ": ", row$model_id,
    "; covariates=", row$covariate_mode,
    "; n_features=", row$n_model_features,
    "; train AUC=", sprintf("%.3f", row$train_auc),
    "; GSE63061 AUC=", sprintf("%.3f", row$development_auc),
    "; GSE85426 AUC=", sprintf("%.3f", row$final_auc)
  )
}

report <- c(
  "# S5 Leakage-Safe Model Optimization Report",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Leakage Policy",
  "",
  "- Training set: GSE63060.",
  "- Development/model-selection set: GSE63061.",
  "- Final validation set: GSE85426.",
  "- GSE85426 labels were not used for primary model selection.",
  "- Any model selected by final AUC is reported only as a post-hoc upper bound and is not paper-primary evidence.",
  "",
  "## Selected Models",
  "",
  format_model_line("Primary gene-only model", primary_gene),
  format_model_line("Primary integrated/clinical model", primary_integrated),
  format_model_line("Post-hoc final-AUC upper bound", posthoc_upper_bound),
  "",
  "## Gate 5 Preliminary Decision",
  "",
  paste0(gate_status, ". Target final AUC threshold was ", target_final_auc, "."),
  "",
  "## Interpretation",
  "",
  if (!is.na(primary_gene_final) && primary_gene_final >= target_final_auc) {
    "- Gene-only model reaches the requested GSE85426 AUC threshold under leakage-safe selection."
  } else {
    "- Gene-only model does not reach the requested GSE85426 AUC threshold under leakage-safe selection."
  },
  if (!is.na(primary_integrated_final) && primary_integrated_final >= target_final_auc) {
    "- Integrated model reaches the requested GSE85426 AUC threshold, but this must be presented separately from gene-only biomarker performance."
  } else {
    "- Integrated model also does not reach the requested GSE85426 AUC threshold under leakage-safe selection."
  },
  "- The post-hoc upper-bound result is useful for feasibility diagnosis only; it cannot be used as the primary validation claim without another independent dataset.",
  "",
  "## Outputs",
  "",
  "- `results/s5_model_optimization_grid.csv`",
  "- `results/s5_primary_model_summary.csv`",
  "- `results/s5_model_predictions.csv`",
  "- `results/s5_glmnet_nonzero_coefficients.csv`",
  "- `figures/s5/selected_model_auc_comparison.png`",
  "- `figures/s5/selected_model_score_boxplot.png`",
  "- `audit/s5_sessionInfo.txt`"
)
writeLines(report, file.path(audit_dir, "s5_model_optimization_report.md"))

gate <- c(
  "# Gate 5 Model Optimization Review",
  "",
  paste0("Review date: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Decision",
  "",
  paste0("Gate 5 status: **", gate_status, "**"),
  "",
  "## Quantitative Basis",
  "",
  format_model_line("Primary gene-only model", primary_gene),
  format_model_line("Primary integrated/clinical model", primary_integrated),
  format_model_line("Post-hoc final-AUC upper bound", posthoc_upper_bound),
  "",
  "## Required Next Step",
  "",
  "- If Gate 5 is PASS, proceed to biological interpretation and manuscript planning.",
  "- If Gate 5 is CONDITIONAL PASS, proceed only with a conservative paper framing and clearly separate gene-only from integrated model claims.",
  "- If Gate 5 is REVIEW, stop downstream writing and reassess endpoint, datasets, or study design."
)
writeLines(gate, file.path(audit_dir, "gate5_model_optimization_review.md"))

print(primary_models[, .(selection_role, model_id, covariate_mode, n_model_features, train_auc, development_auc, final_auc, leakage_class)])
message("S5 leakage-safe model optimization complete.")
