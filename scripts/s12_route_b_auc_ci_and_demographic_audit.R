suppressPackageStartupMessages({
  library(data.table)
  library(pROC)
})

script_path <- normalizePath(sub("--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1]), winslash = "/", mustWork = TRUE)
root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
results_dir <- file.path(root, "results")
data_dir <- file.path(root, "data")

auc_ci <- function(dt) {
  roc_obj <- roc(
    response = dt$diagnosis_clean,
    predictor = dt$score,
    levels = c("Control", "AD"),
    direction = "<",
    quiet = TRUE
  )
  ci <- ci.auc(roc_obj, method = "delong")
  c(
    auc = as.numeric(auc(roc_obj)),
    ci_low = as.numeric(ci[1]),
    ci_high = as.numeric(ci[3])
  )
}

read_primary_predictions <- function() {
  primary_ids <- c(
    "sig_dev_p_k3",
    "glmnet_dev_auc_k5_a05_lambda.min_clin"
  )
  primary <- fread(file.path(results_dir, "s5_model_predictions.csv"))[
    model_id %in% primary_ids &
      dataset_accession %in% c("GSE63060", "GSE63061", "GSE85426") &
      diagnosis_clean %in% c("AD", "Control"),
    .(model_id, dataset_accession, sample_geo_accession, diagnosis_clean, score)
  ]
  primary[, model_role := fifelse(
    model_id == "sig_dev_p_k3",
    "primary_gene_only",
    "primary_integrated"
  )]
  primary[]
}

read_refit_predictions <- function() {
  refit_id <- "refit_glmnet_dev_p_k100_a05_lambda.1se_gene"
  refit <- fread(file.path(results_dir, "s5_train_dev_refit_final_predictions.csv"))[
    model_id == refit_id &
      dataset_accession == "GSE85426" &
      diagnosis_clean %in% c("AD", "Control"),
    .(model_id, dataset_accession, sample_geo_accession, diagnosis_clean, score)
  ]
  refit[, model_role := "train_dev_refit_selected"]
  refit[]
}

read_gse140829_predictions <- function() {
  keep_ids <- c(
    "sig_dev_p_k3",
    "glmnet_dev_auc_k5_a05_lambda.min_clin",
    "refit_glmnet_dev_p_k100_a05_lambda.1se_gene"
  )
  ra <- fread(file.path(results_dir, "route_a_gse140829_model_predictions.csv"))[
    model_id %in% keep_ids &
      diagnosis_clean %in% c("AD", "Control"),
    .(model_id, sample_geo_accession, diagnosis_clean, score)
  ]
  ra[, dataset_accession := "GSE140829"]
  ra[, model_role := fifelse(
    model_id == "sig_dev_p_k3",
    "primary_gene_only",
    fifelse(
      model_id == "glmnet_dev_auc_k5_a05_lambda.min_clin",
      "primary_integrated",
      "train_dev_refit_selected"
    )
  )]
  ra[]
}

pred <- rbindlist(
  list(read_primary_predictions(), read_refit_predictions(), read_gse140829_predictions()),
  fill = TRUE
)

auc_summary <- pred[, {
  ci <- auc_ci(.SD)
  .(
    n_ad = sum(diagnosis_clean == "AD"),
    n_control = sum(diagnosis_clean == "Control"),
    auc = ci[["auc"]],
    auc_ci_low = ci[["ci_low"]],
    auc_ci_high = ci[["ci_high"]]
  )
}, by = .(model_role, model_id, dataset_accession)]

role_order <- data.table(
  dataset_accession = c("GSE63060", "GSE63061", "GSE85426", "GSE140829"),
  validation_context = c(
    "discovery_training",
    "related_external_validation",
    "cross_platform_stress_test",
    "large_independent_external_validation"
  )
)
auc_summary <- merge(auc_summary, role_order, by = "dataset_accession", all.x = TRUE)
setorder(auc_summary, model_role, dataset_accession)
fwrite(auc_summary, file.path(results_dir, "route_b_auc_ci_summary.csv"))

validation_metrics <- fread(file.path(results_dir, "route_b_b4_transportability_metrics.csv"))[
  ,
  .(
    dataset_accession,
    mapped_s3_candidate_genes,
    s3_candidate_genes_unmapped = 476L - mapped_s3_candidate_genes,
    mapped_fraction,
    direction_concordance_rate,
    nominal_concordant,
    fdr_concordant,
    best_frozen_model_auc
  )
]

sample_sheet <- fread(file.path(data_dir, "sample_sheet.csv"))[
  diagnosis_clean %in% c("AD", "Control")
]
sample_sheet[, gender_norm := tolower(gender)]

demo_main <- sample_sheet[, .(
  n_ad = sum(diagnosis_clean == "AD"),
  n_control = sum(diagnosis_clean == "Control"),
  n_mci = 0L,
  age_nonmissing = sum(!is.na(age)),
  age_mean = mean(age, na.rm = TRUE),
  age_sd = sd(age, na.rm = TRUE),
  female_n = sum(gender_norm == "female", na.rm = TRUE),
  male_n = sum(gender_norm == "male", na.rm = TRUE),
  sex_missing_n = sum(is.na(gender_norm) | gender_norm == "" | !(gender_norm %in% c("female", "male"))),
  platform_id = first(platform_id)
), by = dataset_accession]

gse140829_demo <- fread(file.path(results_dir, "route_a_gse140829_model_predictions.csv"))[
  model_id == "sig_dev_p_k3"
]
gse140829_demo[, dataset_accession := "GSE140829"]
gse140829_demo[, gender_norm := tolower(gender)]
demo_140829 <- gse140829_demo[, .(
  n_ad = sum(diagnosis_clean == "AD"),
  n_control = sum(diagnosis_clean == "Control"),
  n_mci = sum(diagnosis_clean == "MCI"),
  age_nonmissing = sum(!is.na(age)),
  age_mean = mean(age, na.rm = TRUE),
  age_sd = sd(age, na.rm = TRUE),
  female_n = sum(gender_norm == "female", na.rm = TRUE),
  male_n = sum(gender_norm == "male", na.rm = TRUE),
  sex_missing_n = sum(is.na(gender_norm) | gender_norm == "" | !(gender_norm %in% c("female", "male"))),
  platform_id = "GPL15988"
), by = dataset_accession]

demo <- rbindlist(list(demo_main, demo_140829), fill = TRUE)
demo <- merge(demo, role_order, by = "dataset_accession", all.x = TRUE)
demo <- merge(demo, validation_metrics, by = "dataset_accession", all.x = TRUE)
demo[dataset_accession == "GSE63060", `:=`(
  mapped_s3_candidate_genes = 476,
  s3_candidate_genes_unmapped = 0L,
  mapped_fraction = 1,
  direction_concordance_rate = NA_real_,
  nominal_concordant = NA_integer_,
  fdr_concordant = NA_integer_,
  best_frozen_model_auc = NA_real_
)]
demo[, mapping_audit_note := fcase(
  dataset_accession == "GSE63060", "Discovery dataset; candidate universe defined here.",
  dataset_accession == "GSE63061", "GPL10558 GEO annotation used; multiple probes per Entrez gene collapsed by highest variance.",
  dataset_accession == "GSE85426", "Rows without numeric Entrez suffix excluded; 10,775/14,113 rows retained before candidate overlap; 451/476 candidates mapped and 25 remained unmapped.",
  dataset_accession == "GSE140829", "Normalized gene-symbol matrix used; 460/476 candidates mapped and 16 remained unmapped.",
  default = "Review"
)]
setorder(demo, dataset_accession)
fwrite(demo, file.path(results_dir, "route_b_demographic_mapping_audit.csv"))

qa <- c(
  "# S12 Route B AUC CI and demographic/mapping audit",
  "",
  paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "",
  "Outputs:",
  "",
  "- `results/route_b_auc_ci_summary.csv`",
  "- `results/route_b_demographic_mapping_audit.csv`",
  "",
  "AUC confidence intervals were estimated with pROC DeLong 95% CIs using AD as the higher-score event and Control as the reference level.",
  "GSE140829 is labelled as `large_independent_external_validation`; GSE85426 is labelled as `cross_platform_stress_test`.",
  "FDR concordance in the validation audit refers to Benjamini-Hochberg targeted replication FDR within the mapped discovery-derived candidate-gene universe for each validation dataset.",
  "The demographic/mapping audit reports mapped and unmapped candidate counts, mapping notes, and the highest AUC among frozen candidate models.",
  ""
)
writeLines(qa, file.path(root, "audit", "s12_auc_ci_and_demographic_audit.md"))

print(auc_summary)
print(demo)
