suppressPackageStartupMessages({
  library(data.table)
  library(limma)
  library(AnnotationDbi)
  library(org.Hs.eg.db)
})

script_path <- normalizePath(sub("--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]), winslash = "/", mustWork = TRUE)
root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
raw_dir <- file.path(root, "data", "raw")
processed_dir <- file.path(root, "data", "processed")
results_dir <- file.path(root, "results")
audit_dir <- file.path(root, "audit")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

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
  data.table(
    probe_id = as.character(annot$ID),
    gene_symbol = primary_token(annot$`Gene symbol`),
    gene_id = primary_gene_id(annot$`Gene ID`),
    gene_title = as.character(annot$`Gene title`),
    is_annotated_gene = valid_symbol(primary_token(annot$`Gene symbol`)) & !is.na(primary_gene_id(annot$`Gene ID`))
  )
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
    gene_title = NA_character_,
    is_annotated_gene = !is.na(gene_id)
  )
}

collapse_to_gene_matrix <- function(mat, map, key_col = "gene_id") {
  probe_var <- apply(mat, 1, var, na.rm = TRUE)
  probe_map <- data.table(probe_id = rownames(mat), probe_variance = probe_var)
  probe_map <- merge(probe_map, map, by = "probe_id", all.x = TRUE, sort = FALSE)
  probe_map <- probe_map[!is.na(get(key_col)) & nzchar(as.character(get(key_col)))]
  setorderv(probe_map, c(key_col, "probe_variance", "probe_id"), order = c(1L, -1L, 1L))
  selected <- probe_map[, .SD[1], by = key_col]
  gene_mat <- mat[selected$probe_id, , drop = FALSE]
  rownames(gene_mat) <- selected[[key_col]]
  list(matrix = gene_mat, selected_map = selected)
}

zscore_rows <- function(mat) {
  z <- t(scale(t(mat)))
  z[is.na(z)] <- 0
  z
}

map_marker_entrez <- function(markers) {
  ids <- AnnotationDbi::mapIds(
    org.Hs.eg.db,
    keys = unique(markers$gene_symbol),
    keytype = "SYMBOL",
    column = "ENTREZID",
    multiVals = "first"
  )
  out <- copy(markers)
  out[, gene_id := unname(ids[gene_symbol])]
  out
}

make_marker_scores <- function(gene_mat, markers, dataset_accession, key_type) {
  z <- zscore_rows(gene_mat)
  score_list <- list()
  coverage <- list()
  for (marker_set_name in unique(markers$marker_set)) {
    mk <- markers[marker_set == marker_set_name]
    feature_ids <- if (key_type == "gene_id") mk$gene_id else mk$gene_symbol
    feature_ids <- unique(feature_ids[!is.na(feature_ids) & nzchar(feature_ids)])
    available <- intersect(feature_ids, rownames(z))
    score <- if (length(available) == 0) rep(NA_real_, ncol(z)) else colMeans(z[available, , drop = FALSE], na.rm = TRUE)
    score_list[[paste0(marker_set_name, "_score")]] <- score
    coverage[[marker_set_name]] <- data.table(
      dataset_accession = dataset_accession,
      marker_set = marker_set_name,
      requested_marker_genes = length(unique(mk$gene_symbol)),
      mapped_marker_ids = length(feature_ids),
      available_marker_features = length(available),
      available_markers = paste(mk$gene_symbol[match(available, feature_ids)], collapse = ";")
    )
  }
  list(scores = as.data.table(score_list), coverage = rbindlist(coverage, fill = TRUE))
}

fit_gene_effects <- function(expr_mat, metadata, include_markers, include_batch) {
  metadata <- copy(metadata)
  metadata[, diagnosis_clean := factor(diagnosis_clean, levels = c("Control", "AD"))]
  metadata[, age_numeric := suppressWarnings(as.numeric(age))]
  metadata[, gender_factor := factor(gender)]
  if (include_batch && "batch" %in% names(metadata)) {
    metadata[, batch_factor := factor(batch)]
  }
  terms <- c("diagnosis_clean")
  if (sum(!is.na(metadata$age_numeric)) == nrow(metadata) && sd(metadata$age_numeric) > 0) terms <- c(terms, "age_numeric")
  if (length(unique(metadata$gender_factor[!is.na(metadata$gender_factor)])) > 1) terms <- c(terms, "gender_factor")
  if (include_batch && "batch_factor" %in% names(metadata) && length(unique(metadata$batch_factor)) > 1) terms <- c(terms, "batch_factor")
  if (include_markers) {
    for (score_name in c("neutrophil_score", "monocyte_score", "lymphocyte_score")) {
      if (score_name %in% names(metadata) && all(is.finite(metadata[[score_name]])) && sd(metadata[[score_name]]) > 0) {
        terms <- c(terms, score_name)
      }
    }
  }
  design <- model.matrix(as.formula(paste("~", paste(terms, collapse = " + "))), data = metadata)
  if (qr(design)$rank < ncol(design)) {
    stop("Design matrix is rank deficient: ", paste(colnames(design), collapse = ", "))
  }
  fit <- eBayes(lmFit(expr_mat, design))
  coef_name <- "diagnosis_cleanAD"
  if (!coef_name %in% colnames(fit$coefficients)) stop("Missing coefficient: ", coef_name)
  tt <- as.data.table(topTable(fit, coef = coef_name, number = nrow(expr_mat), adjust.method = "BH", sort.by = "none"))
  tt[, feature_id := rownames(expr_mat)]
  setcolorder(tt, c("feature_id", setdiff(names(tt), "feature_id")))
  list(table = tt, terms = terms)
}

load_validation_dataset <- function(dataset_accession) {
  acc <- dataset_accession
  if (dataset_accession %in% c("GSE63061", "GSE85426")) {
    mat <- readRDS(file.path(processed_dir, paste0(acc, "_primary_normalized_matrix.rds")))
    column_map <- fread(file.path(processed_dir, "s2_expression_column_sample_map.csv"))[dataset_accession == acc]
    locked <- fread(file.path(root, "data", "primary_inclusion_locked.csv"))[
      dataset_accession == acc & diagnosis_clean %in% c("AD", "Control")
    ]
    column_map <- column_map[sample_geo_accession %in% locked$sample_geo_accession]
    mat <- mat[, column_map$expression_column, drop = FALSE]
    metadata <- locked[match(column_map$sample_geo_accession, sample_geo_accession)]
    metadata[, expression_column := column_map$expression_column]
    if (!identical(metadata$expression_column, colnames(mat))) stop(acc, " metadata/matrix alignment failed")
    if (acc == "GSE63061") {
      collapsed <- collapse_to_gene_matrix(mat, read_geo_annotation(file.path(raw_dir, "GPL10558.annot.gz")), key_col = "gene_id")
    } else {
      collapsed <- collapse_to_gene_matrix(mat, parse_gse85426_row_map(mat), key_col = "gene_id")
    }
    return(list(matrix = collapsed$matrix, metadata = metadata, key_type = "gene_id", include_batch = FALSE))
  }

  if (dataset_accession == "GSE140829") {
    mat <- readRDS(file.path(processed_dir, "GSE140829_primary_normalized_symbol_matrix.rds"))
    metadata <- fread(file.path(root, "data", "gse140829_route_a_sample_sheet.csv"))[
      diagnosis_clean %in% c("AD", "Control")
    ]
    mat <- mat[, metadata$expression_column, drop = FALSE]
    if (!identical(metadata$expression_column, colnames(mat))) stop("GSE140829 metadata/matrix alignment failed")
    return(list(matrix = mat, metadata = metadata, key_type = "gene_symbol", include_batch = TRUE))
  }

  stop("Unsupported dataset: ", dataset_accession)
}

marker_symbols <- data.table(
  marker_set = c(
    rep("neutrophil", 8),
    rep("monocyte", 8),
    rep("lymphocyte", 8)
  ),
  gene_symbol = c(
    "S100A8", "S100A9", "FCGR3B", "CSF3R", "CXCR2", "CEACAM8", "MPO", "ELANE",
    "LYZ", "LST1", "FCN1", "CD14", "CTSS", "MS4A7", "FCGR3A", "S100A12",
    "CD3D", "CD3E", "CD2", "TRAC", "IL7R", "LTB", "CD79A", "MS4A1"
  )
)
marker_map <- map_marker_entrez(marker_symbols)

stable <- fread(file.path(results_dir, "route_b_stable_genes.csv"))[stable_strict == TRUE]
stable[, gene_id := as.character(gene_id)]

summary_list <- list()
gene_level_list <- list()
coverage_list <- list()
term_list <- list()

for (acc in c("GSE63061", "GSE85426", "GSE140829")) {
  message("Running marker-score sensitivity for ", acc)
  ds <- load_validation_dataset(acc)
  marker_scores <- make_marker_scores(ds$matrix, marker_map, acc, ds$key_type)
  coverage_list[[acc]] <- marker_scores$coverage
  metadata <- cbind(copy(ds$metadata), marker_scores$scores)

  if (ds$key_type == "gene_id") {
    stable_key <- unique(stable$gene_id)
  } else {
    stable_key <- unique(stable$gene_symbol)
  }
  stable_key <- intersect(stable_key, rownames(ds$matrix))
  expr_stable <- ds$matrix[stable_key, , drop = FALSE]
  stable_ref <- if (ds$key_type == "gene_id") {
    stable[match(stable_key, stable$gene_id), .(feature_id = gene_id, gene_symbol, s3_logFC)]
  } else {
    stable[match(stable_key, stable$gene_symbol), .(feature_id = gene_symbol, gene_symbol, s3_logFC)]
  }

  base <- fit_gene_effects(expr_stable, metadata, include_markers = FALSE, include_batch = ds$include_batch)
  adjusted <- fit_gene_effects(expr_stable, metadata, include_markers = TRUE, include_batch = ds$include_batch)
  term_list[[acc]] <- data.table(
    dataset_accession = acc,
    model = c("base", "marker_adjusted"),
    terms = c(paste(base$terms, collapse = " + "), paste(adjusted$terms, collapse = " + "))
  )

  base_dt <- base$table[, .(feature_id, base_logFC = logFC, base_p_value = P.Value, base_adj_p_value = adj.P.Val)]
  adj_dt <- adjusted$table[, .(feature_id, adjusted_logFC = logFC, adjusted_p_value = P.Value, adjusted_adj_p_value = adj.P.Val)]
  gene_dt <- merge(stable_ref, base_dt, by = "feature_id", all.x = TRUE, sort = FALSE)
  gene_dt <- merge(gene_dt, adj_dt, by = "feature_id", all.x = TRUE, sort = FALSE)
  gene_dt[, dataset_accession := acc]
  gene_dt[, base_direction_concordant := sign(base_logFC) == sign(s3_logFC)]
  gene_dt[, adjusted_direction_concordant := sign(adjusted_logFC) == sign(s3_logFC)]
  gene_dt[, base_nominal_concordant := base_direction_concordant & base_p_value < 0.05]
  gene_dt[, adjusted_nominal_concordant := adjusted_direction_concordant & adjusted_p_value < 0.05]
  gene_dt[, same_direction_after_adjustment := sign(base_logFC) == sign(adjusted_logFC)]
  gene_dt[, abs_logfc_change := abs(adjusted_logFC - base_logFC)]
  gene_dt[, adjusted_to_base_abs_ratio := abs(adjusted_logFC) / pmax(abs(base_logFC), .Machine$double.eps)]
  gene_level_list[[acc]] <- gene_dt

  summary_list[[acc]] <- data.table(
    dataset_accession = acc,
    mapped_strict_stable_genes = nrow(gene_dt),
    base_direction_concordant = sum(gene_dt$base_direction_concordant, na.rm = TRUE),
    marker_adjusted_direction_concordant = sum(gene_dt$adjusted_direction_concordant, na.rm = TRUE),
    base_direction_rate = mean(gene_dt$base_direction_concordant, na.rm = TRUE),
    marker_adjusted_direction_rate = mean(gene_dt$adjusted_direction_concordant, na.rm = TRUE),
    base_nominal_concordant = sum(gene_dt$base_nominal_concordant, na.rm = TRUE),
    marker_adjusted_nominal_concordant = sum(gene_dt$adjusted_nominal_concordant, na.rm = TRUE),
    same_direction_after_adjustment_rate = mean(gene_dt$same_direction_after_adjustment, na.rm = TRUE),
    median_abs_logfc_change = median(gene_dt$abs_logfc_change, na.rm = TRUE),
    median_adjusted_to_base_abs_ratio = median(gene_dt$adjusted_to_base_abs_ratio, na.rm = TRUE)
  )
}

sensitivity_summary <- rbindlist(summary_list, fill = TRUE)
gene_level <- rbindlist(gene_level_list, fill = TRUE)
marker_coverage <- rbindlist(coverage_list, fill = TRUE)
model_terms <- rbindlist(term_list, fill = TRUE)

fwrite(sensitivity_summary, file.path(results_dir, "blood_cell_marker_sensitivity_summary.csv"))
fwrite(gene_level, file.path(results_dir, "blood_cell_marker_sensitivity_gene_level.csv"))
fwrite(marker_coverage, file.path(results_dir, "blood_cell_marker_coverage.csv"))
fwrite(model_terms, file.path(results_dir, "blood_cell_marker_sensitivity_model_terms.csv"))

fmt <- function(x, digits = 3) {
  ifelse(is.na(x), "NA", formatC(x, format = "f", digits = digits))
}

coverage_lines <- marker_coverage[, paste0(
  "- ", dataset_accession, " ", marker_set, ": ", available_marker_features, "/",
  requested_marker_genes, " marker genes available."
)]
summary_lines <- sensitivity_summary[, paste0(
  "- ", dataset_accession, ": strict stable genes mapped=", mapped_strict_stable_genes,
  "; direction concordance base=", fmt(base_direction_rate),
  ", marker-adjusted=", fmt(marker_adjusted_direction_rate),
  "; nominal concordant base=", base_nominal_concordant,
  ", marker-adjusted=", marker_adjusted_nominal_concordant,
  "; same base/adjusted direction=", fmt(same_direction_after_adjustment_rate),
  "; median absolute logFC change=", fmt(median_abs_logfc_change), "."
)]

audit_lines <- c(
  "# S13 Blood-cell marker-score sensitivity analysis",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "## Scope",
  "",
  "- This is a lightweight marker-score sensitivity analysis, not formal cell-type deconvolution.",
  "- Neutrophil, monocyte, and lymphocyte proxy scores were calculated as within-cohort mean z-scores of available marker genes.",
  "- Strict stable genes were re-tested with diagnosis, available age/sex covariates, GSE140829 batch where applicable, and the three marker scores.",
  "- The analysis checks whether stable-gene directionality is obviously explained away by broad blood-cell marker scores.",
  "",
  "## Marker Coverage",
  "",
  coverage_lines,
  "",
  "## Sensitivity Summary",
  "",
  summary_lines,
  "",
  "## Interpretation",
  "",
  "- Marker-score adjustment did not convert the independent-validation model findings into a positive diagnostic result.",
  "- Directional stability of the strict stable gene set was retained in GSE63061, mostly preserved in GSE140829, and attenuated in GSE85426.",
  "- Because marker scores are only coarse proxies and GSE85426 showed attenuation after adjustment, residual blood-cell-composition confounding remains a limitation.",
  "",
  "## Outputs",
  "",
  "- `results/blood_cell_marker_sensitivity_summary.csv`",
  "- `results/blood_cell_marker_sensitivity_gene_level.csv`",
  "- `results/blood_cell_marker_coverage.csv`",
  "- `results/blood_cell_marker_sensitivity_model_terms.csv`"
)
writeLines(audit_lines, file.path(audit_dir, "s13_blood_cell_marker_sensitivity.md"), useBytes = TRUE)

print(marker_coverage)
print(sensitivity_summary)
