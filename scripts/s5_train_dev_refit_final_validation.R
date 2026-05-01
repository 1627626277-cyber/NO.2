suppressPackageStartupMessages({
  library(data.table)
  library(glmnet)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
raw_dir <- file.path(root, "data", "raw")
processed_dir <- file.path(root, "data", "processed")
results_dir <- file.path(root, "results")
audit_dir <- file.path(root, "audit")

datasets <- c("GSE63060", "GSE63061", "GSE85426")
train_dev_sets <- c("GSE63060", "GSE63061")
final_acc <- "GSE85426"
target_final_auc <- 0.70

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

read_geo_annotation <- function(path) {
  con <- gzfile(path, "rt")
  on.exit(close(con), add = TRUE)
  lines <- readLines(con, warn = FALSE)
  begin <- grep("^!platform_table_begin", lines)
  end <- grep("^!platform_table_end", lines)
  table_lines <- lines[(begin + 1):(end - 1)]
  annot <- fread(text = paste(table_lines, collapse = "\n"), sep = "\t", fill = TRUE, quote = "")
  data.table(
    probe_id = as.character(annot$ID),
    gene_id = primary_gene_id(annot$`Gene ID`)
  )
}

parse_gse85426_row_map <- function(mat) {
  row_id <- rownames(mat)
  gene_id <- sub("^.*\\|", "", row_id)
  gene_id[!grepl("^[0-9]+$", gene_id)] <- NA_character_
  data.table(probe_id = row_id, gene_id = gene_id)
}

collapse_to_gene_matrix <- function(mat, map) {
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

safe_glm <- function(x, y) {
  df <- as.data.frame(x)
  df$y <- y
  tryCatch(suppressWarnings(glm(y ~ ., data = df, family = binomial())), error = function(e) NULL)
}

predict_glm <- function(model, x) {
  if (is.null(model)) return(rep(NA_real_, nrow(x)))
  suppressWarnings(as.numeric(predict(model, newdata = as.data.frame(x), type = "response")))
}

locked <- fread(file.path(root, "data", "primary_inclusion_locked.csv"))
column_map <- fread(file.path(processed_dir, "s2_expression_column_sample_map.csv"))
gpl6947 <- read_geo_annotation(file.path(raw_dir, "GPL6947.annot.gz"))
gpl10558 <- read_geo_annotation(file.path(raw_dir, "GPL10558.annot.gz"))
candidate <- fread(file.path(results_dir, "s3_candidate_genes_main.csv"))
candidate[, gene_id := primary_gene_id(gene_id)]
candidate <- candidate[!is.na(gene_id)]
candidate <- candidate[, .SD[1], by = gene_id]
s3_sign <- setNames(sign(candidate$logFC), candidate$gene_id)

gene_z <- list()
metadata <- list()
labels <- list()
for (acc in datasets) {
  mat <- readRDS(file.path(processed_dir, paste0(acc, "_primary_normalized_matrix.rds")))
  cm <- column_map[dataset_accession == acc]
  mat <- mat[, cm$expression_column, drop = FALSE]
  md <- locked[dataset_accession == acc]
  md <- md[match(cm$sample_geo_accession, sample_geo_accession)]
  metadata[[acc]] <- md
  labels[[acc]] <- as.integer(md$diagnosis_clean == "AD")
  map <- switch(acc, GSE63060 = gpl6947, GSE63061 = gpl10558, GSE85426 = parse_gse85426_row_map(mat))
  gene_z[[acc]] <- zscore_rows(collapse_to_gene_matrix(mat, map))
}

common_genes <- Reduce(intersect, lapply(gene_z, rownames))
common_genes <- intersect(common_genes, names(s3_sign))

combined_meta <- rbindlist(lapply(train_dev_sets, function(acc) metadata[[acc]]), fill = TRUE)
combined_clin <- make_clinical(combined_meta)
clinical <- list()
clinical[["combined"]] <- combined_clin$matrix
clinical[[final_acc]] <- make_clinical(metadata[[final_acc]], combined_clin$reference)$matrix

x_combined_gene_all <- do.call(rbind, lapply(train_dev_sets, function(acc) t(gene_z[[acc]][common_genes, , drop = FALSE])))
rownames(x_combined_gene_all) <- NULL
y_combined <- unlist(labels[train_dev_sets], use.names = FALSE)
x_final_gene_all <- t(gene_z[[final_acc]][common_genes, , drop = FALSE])

grid <- fread(file.path(results_dir, "s5_model_optimization_grid.csv"))
grid <- grid[leakage_class == "primary_eligible" & !is.na(development_auc)]
setorder(grid, -development_auc, n_model_features)
grid_top <- grid[seq_len(min(220, .N))]

rows <- list()
preds <- list()

for (i in seq_len(nrow(grid_top))) {
  spec <- grid_top[i]
  feature_ids <- if (is.na(spec$feature_ids) || spec$feature_ids == "") character(0) else strsplit(spec$feature_ids, ";", fixed = TRUE)[[1]]
  feature_ids <- intersect(feature_ids, common_genes)
  if (spec$covariate_mode != "age_gender_only" && length(feature_ids) == 0) next

  model_id <- paste0("refit_", spec$model_id)
  if (spec$model_family == "signed_mean_signature") {
    signs <- s3_sign[feature_ids]
    train_scores_by_set <- lapply(train_dev_sets, function(acc) {
      as.numeric(colMeans(gene_z[[acc]][feature_ids, , drop = FALSE] * signs, na.rm = TRUE))
    })
    combined_score <- unlist(train_scores_by_set, use.names = FALSE)
    final_score <- as.numeric(colMeans(gene_z[[final_acc]][feature_ids, , drop = FALSE] * signs, na.rm = TRUE))
    combined_auc <- auc_rank(y_combined, combined_score)
    final_auc <- auc_rank(labels[[final_acc]], final_score)
    cv_auc <- NA_real_
  } else if (spec$model_family == "signature_plus_clinical_glm") {
    signs <- s3_sign[feature_ids]
    train_scores_by_set <- lapply(train_dev_sets, function(acc) {
      as.numeric(colMeans(gene_z[[acc]][feature_ids, , drop = FALSE] * signs, na.rm = TRUE))
    })
    combined_sig <- unlist(train_scores_by_set, use.names = FALSE)
    final_sig <- as.numeric(colMeans(gene_z[[final_acc]][feature_ids, , drop = FALSE] * signs, na.rm = TRUE))
    x_combined <- cbind(signature_score = combined_sig, clinical[["combined"]])
    x_final <- cbind(signature_score = final_sig, clinical[[final_acc]])
    model <- safe_glm(x_combined, y_combined)
    combined_score <- predict_glm(model, x_combined)
    final_score <- predict_glm(model, x_final)
    combined_auc <- auc_rank(y_combined, combined_score)
    final_auc <- auc_rank(labels[[final_acc]], final_score)
    cv_auc <- NA_real_
  } else if (grepl("^glmnet_alpha_", spec$model_family)) {
    alpha <- as.numeric(sub("^glmnet_alpha_", "", spec$model_family))
    feature_idx <- match(feature_ids, common_genes)
    x_combined <- x_combined_gene_all[, feature_idx, drop = FALSE]
    x_final <- x_final_gene_all[, feature_idx, drop = FALSE]
    if (spec$covariate_mode == "gene_plus_age_gender") {
      x_combined <- cbind(x_combined, clinical[["combined"]])
      x_final <- cbind(x_final, clinical[[final_acc]])
    }
    cvfit <- tryCatch(
      suppressWarnings(cv.glmnet(x_combined, y_combined, family = "binomial", alpha = alpha, nfolds = 5, type.measure = "auc", standardize = FALSE)),
      error = function(e) NULL
    )
    if (is.null(cvfit)) next
    lambda_value <- if (grepl("lambda\\.1se", spec$model_id)) cvfit$lambda.1se else cvfit$lambda.min
    combined_score <- as.numeric(predict(cvfit, newx = x_combined, s = lambda_value, type = "response"))
    final_score <- as.numeric(predict(cvfit, newx = x_final, s = lambda_value, type = "response"))
    combined_auc <- auc_rank(y_combined, combined_score)
    final_auc <- auc_rank(labels[[final_acc]], final_score)
    cv_auc <- max(cvfit$cvm, na.rm = TRUE)
  } else if (spec$model_family == "clinical_glm") {
    x_combined <- clinical[["combined"]]
    x_final <- clinical[[final_acc]]
    model <- safe_glm(x_combined, y_combined)
    combined_score <- predict_glm(model, x_combined)
    final_score <- predict_glm(model, x_final)
    combined_auc <- auc_rank(y_combined, combined_score)
    final_auc <- auc_rank(labels[[final_acc]], final_score)
    cv_auc <- NA_real_
  } else {
    next
  }

  rows[[model_id]] <- data.table(
    model_id = model_id,
    source_model_id = spec$model_id,
    model_family = spec$model_family,
    covariate_mode = spec$covariate_mode,
    n_model_features = length(feature_ids),
    source_development_auc = spec$development_auc,
    combined_train_dev_auc = combined_auc,
    combined_cv_auc = cv_auc,
    final_auc = final_auc,
    reaches_final_auc_070 = final_auc >= target_final_auc,
    feature_ids = paste(feature_ids, collapse = ";")
  )
  preds[[model_id]] <- data.table(
    model_id = model_id,
    dataset_accession = final_acc,
    sample_geo_accession = metadata[[final_acc]]$sample_geo_accession,
    diagnosis_clean = metadata[[final_acc]]$diagnosis_clean,
    score = final_score
  )
}

refit <- rbindlist(rows, fill = TRUE)
refit[, selection_score := fifelse(is.na(combined_cv_auc), source_development_auc, combined_cv_auc)]
setorder(refit, -selection_score, n_model_features)
selected <- refit[1]
best_final_upper <- refit[order(-final_auc, -selection_score, n_model_features)][1]
predictions <- rbindlist(preds, fill = TRUE)

fwrite(refit[order(-selection_score)], file.path(results_dir, "s5_train_dev_refit_grid.csv"))
fwrite(rbindlist(list(
  data.table(selection_role = "train_dev_refit_selected_without_final", selected),
  data.table(selection_role = "train_dev_refit_posthoc_best_final_not_primary", best_final_upper)
), fill = TRUE), file.path(results_dir, "s5_train_dev_refit_summary.csv"))
fwrite(predictions, file.path(results_dir, "s5_train_dev_refit_final_predictions.csv"))

report <- c(
  "# S5 Train+Development Refit Final Validation",
  "",
  paste0("Generated at: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Policy",
  "",
  "- Model families/features came from the prior GSE63060 -> GSE63061 development grid.",
  "- GSE63060 and GSE63061 were combined for refitting.",
  "- GSE85426 was used only for final validation.",
  "- Selected refit model was chosen by combined CV/development score, not by GSE85426 final AUC.",
  "",
  "## Selected Refit Model",
  "",
  paste0("- Model: ", selected$model_id),
  paste0("- Covariate mode: ", selected$covariate_mode),
  paste0("- Features: ", selected$n_model_features),
  paste0("- Combined train+development AUC: ", sprintf("%.3f", selected$combined_train_dev_auc)),
  paste0("- Combined CV/development selection score: ", sprintf("%.3f", selected$selection_score)),
  paste0("- GSE85426 final AUC: ", sprintf("%.3f", selected$final_auc)),
  "",
  "## Post-Hoc Best Final Refit Model",
  "",
  paste0("- Model: ", best_final_upper$model_id),
  paste0("- Covariate mode: ", best_final_upper$covariate_mode),
  paste0("- Features: ", best_final_upper$n_model_features),
  paste0("- GSE85426 final AUC: ", sprintf("%.3f", best_final_upper$final_auc)),
  "",
  "## Interpretation",
  "",
  if (selected$final_auc >= target_final_auc) {
    "- Leakage-safe train+development refit reaches the requested 0.70 final AUC threshold."
  } else {
    "- Leakage-safe train+development refit does not reach the requested 0.70 final AUC threshold."
  },
  "- The post-hoc best final refit is not a valid primary selection if it differs from the selected refit model."
)
writeLines(report, file.path(audit_dir, "s5_train_dev_refit_final_validation_report.md"))

print(rbindlist(list(
  data.table(selection_role = "selected_without_final", selected),
  data.table(selection_role = "posthoc_best_final_not_primary", best_final_upper)
), fill = TRUE)[, .(selection_role, model_id, covariate_mode, n_model_features, selection_score, combined_train_dev_auc, final_auc, reaches_final_auc_070)])
message("S5 train+development refit final validation complete.")
