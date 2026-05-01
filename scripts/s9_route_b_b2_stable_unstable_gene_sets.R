suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
results_dir <- file.path(root, "results")
fig_dir <- file.path(root, "figures", "route_b")
audit_dir <- file.path(root, "audit")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

now_stamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

as_bool <- function(x) {
  x <- as.logical(x)
  x[is.na(x)] <- FALSE
  x
}

max_or_na <- function(...) {
  out <- pmax(..., na.rm = TRUE)
  out[is.infinite(out)] <- NA_real_
  out
}

min_or_na <- function(...) {
  out <- pmin(..., na.rm = TRUE)
  out[is.infinite(out)] <- NA_real_
  out
}

category_one <- function(symbol, title) {
  text <- toupper(paste(symbol, title, sep = " "))
  if (grepl("(^| )HLA|(^| )CD[0-9]|CHEMOKINE|CYTOKINE|INTERLEUKIN|INTERFERON|IMMUN|COMPLEMENT|FCGR|TLR|TYROBP|LST1|S100A|OAS|IFI|IRF|STAT|NFKB|(^| )IL[0-9]|CCL|CXCL|CCR|CXCR|LYZ|MPO|MS4A|ITGAM|ITGB2|SELL|LILR|KIR|CLEC|CTSS|AIF1|MNDA|NLRP|CASP", text)) {
    return("immune_inflammatory")
  }
  if (grepl("MITOCHONDR|(^| )MT-|(^| )NDUF|(^| )COX|(^| )ATP5|(^| )UQCR|(^| )SDH|(^| )MRPL|(^| )MRPS|OXIDATIVE PHOSPHORYLATION", text)) {
    return("mitochondrial_oxphos")
  }
  if (grepl("RIBOSOM|(^| )RPL|(^| )RPS|TRANSLATION|EUKARYOTIC TRANSLATION|(^| )EIF|(^| )EEF", text)) {
    return("ribosomal_translation")
  }
  if (grepl("PROTEASOM|UBIQUITIN|(^| )PSMA|(^| )PSMB|(^| )PSMC|(^| )PSMD|(^| )PSME", text)) {
    return("proteostasis_ubiquitin")
  }
  if (grepl("HEMOGLOBIN|ERYTHRO|PLATELET|(^| )HBA|(^| )HBB|(^| )ALAS2|(^| )PF4|(^| )PPBP|GP1B|ITGA2B", text)) {
    return("blood_cell_platelet_erythroid")
  }
  if (grepl("SPLICE|SPLICING|RNA BINDING|RNA PROCESS|RIBONUCLEOPROTEIN|HNRNP|SNRP|SRSF", text)) {
    return("rna_processing")
  }
  if (grepl("CELL CYCLE|CYCLIN|DNA REPAIR|REPLICATION|CHROMATIN|HISTONE", text)) {
    return("cell_cycle_dna_chromatin")
  }
  "other_or_unclassified"
}

candidate <- fread(file.path(results_dir, "s3_candidate_genes_main.csv"))
candidate[, gene_id := as.character(gene_id)]
candidate[, s3_rank := seq_len(.N)]
candidate_ref <- candidate[, .(
  gene_id,
  gene_symbol,
  gene_title,
  s3_rank,
  s3_probe_id = probe_id,
  s3_logFC = logFC,
  s3_abs_logFC = abs_logFC,
  s3_adj.P.Val = adj.P.Val,
  s3_P.Value = P.Value,
  s3_direction = direction
)]

s4 <- fread(file.path(results_dir, "s4_candidate_external_validation.csv"))
s4[, gene_id := as.character(gene_id)]
s4_validation <- s4[, .(
  dataset_accession,
  gene_id,
  validation_gene_symbol = gene_symbol,
  validation_logFC,
  validation_p_value = `validation_P.Value`,
  validation_adj_p_value = `validation_adj.P.Val`,
  direction_concordant,
  nominal_concordant,
  fdr_concordant,
  auc_oriented,
  mapped = TRUE
)]

gse140829 <- fread(file.path(results_dir, "route_b_b1_gse140829_candidate_replication.csv"))
gse140829[, gene_id := as.character(gene_id)]
gse140829_validation <- gse140829[, .(
  dataset_accession,
  gene_id,
  validation_gene_symbol = gene_symbol,
  validation_logFC,
  validation_p_value = `validation_P.Value`,
  validation_adj_p_value = `validation_adj.P.Val`,
  direction_concordant,
  nominal_concordant,
  fdr_concordant,
  auc_oriented,
  mapped
)]

validation_long <- rbindlist(list(s4_validation, gse140829_validation), fill = TRUE)
validation_long[, mapped := as_bool(mapped)]
validation_long[, direction_concordant := as_bool(direction_concordant)]
validation_long[, nominal_concordant := as_bool(nominal_concordant)]
validation_long[, fdr_concordant := as_bool(fdr_concordant)]

prefix_dataset <- function(ds, prefix) {
  dt <- copy(validation_long[dataset_accession == ds])
  dt[, dataset_accession := NULL]
  rename_cols <- setdiff(names(dt), "gene_id")
  setnames(dt, rename_cols, paste0(prefix, "_", rename_cols))
  dt
}

classification <- Reduce(
  function(x, y) merge(x, y, by = "gene_id", all.x = TRUE, sort = FALSE),
  list(
    candidate_ref,
    prefix_dataset("GSE63061", "gse63061"),
    prefix_dataset("GSE85426", "gse85426"),
    prefix_dataset("GSE140829", "gse140829")
  )
)

for (prefix in c("gse63061", "gse85426", "gse140829")) {
  for (col in c("mapped", "direction_concordant", "nominal_concordant", "fdr_concordant")) {
    nm <- paste0(prefix, "_", col)
    classification[, (nm) := as_bool(get(nm))]
  }
}

classification[, gse63061_reversed := gse63061_mapped & !gse63061_direction_concordant]
classification[, gse85426_reversed := gse85426_mapped & !gse85426_direction_concordant]
classification[, gse140829_reversed := gse140829_mapped & !gse140829_direction_concordant]

classification[, cross_mapped_count := as.integer(gse85426_mapped) + as.integer(gse140829_mapped)]
classification[, cross_direction_count := as.integer(gse85426_direction_concordant) + as.integer(gse140829_direction_concordant)]
classification[, cross_nominal_count := as.integer(gse85426_nominal_concordant) + as.integer(gse140829_nominal_concordant)]
classification[, cross_fdr_count := as.integer(gse85426_fdr_concordant) + as.integer(gse140829_fdr_concordant)]
classification[, cross_reversal_count := as.integer(gse85426_reversed) + as.integer(gse140829_reversed)]
classification[, cross_max_auc := max_or_na(gse85426_auc_oriented, gse140829_auc_oriented)]
classification[, cross_min_auc := min_or_na(gse85426_auc_oriented, gse140829_auc_oriented)]

classification[, near_cohort_anchor := gse63061_direction_concordant]
classification[, near_cohort_nominal := gse63061_nominal_concordant]
classification[, stable_strict := near_cohort_nominal &
  cross_mapped_count >= 1 &
  cross_direction_count == cross_mapped_count &
  cross_nominal_count >= 1]
classification[, stable_directional := near_cohort_anchor &
  cross_mapped_count >= 1 &
  cross_direction_count == cross_mapped_count]
classification[, unstable_reversal := near_cohort_anchor & cross_reversal_count >= 1]
classification[, unstable_vanish := near_cohort_nominal & cross_nominal_count == 0 & cross_max_auc < 0.55]
classification[, unstable_primary := near_cohort_nominal &
  !stable_strict &
  (unstable_reversal | unstable_vanish)]
classification[, unstable_vanish := as_bool(unstable_vanish)]
classification[, unstable_primary := as_bool(unstable_primary)]

classification[, transportability_class := fcase(
  stable_strict, "stable_strict",
  unstable_reversal & unstable_vanish, "unstable_reversal_and_vanish",
  unstable_reversal, "unstable_reversal",
  unstable_vanish, "unstable_vanish",
  stable_directional, "stable_directional_only",
  near_cohort_anchor, "near_cohort_only_or_mixed",
  default = "not_replicated_near_cohort"
)]

classification[, biological_keyword_category := mapply(category_one, gene_symbol, gene_title)]
classification[, direction_membership := paste0(
  ifelse(gse63061_direction_concordant, "GSE63061", ""),
  ifelse(gse85426_direction_concordant, "|GSE85426", ""),
  ifelse(gse140829_direction_concordant, "|GSE140829", "")
)]
classification[direction_membership == "", direction_membership := "none"]
classification[, direction_membership := gsub("^\\|", "", direction_membership)]
classification[, nominal_membership := paste0(
  ifelse(gse63061_nominal_concordant, "GSE63061", ""),
  ifelse(gse85426_nominal_concordant, "|GSE85426", ""),
  ifelse(gse140829_nominal_concordant, "|GSE140829", "")
)]
classification[nominal_membership == "", nominal_membership := "none"]
classification[, nominal_membership := gsub("^\\|", "", nominal_membership)]

stable_genes <- classification[stable_strict == TRUE]
stable_sensitivity <- classification[stable_directional == TRUE]
unstable_genes <- classification[unstable_primary == TRUE]

setorder(classification, transportability_class, s3_rank)
setorder(stable_genes, s3_rank)
setorder(stable_sensitivity, s3_rank)
setorder(unstable_genes, s3_rank)

overlap_table <- classification[, .(
  n_genes = .N,
  stable_strict = sum(stable_strict),
  stable_directional = sum(stable_directional),
  unstable_primary = sum(unstable_primary),
  median_cross_max_auc = median(cross_max_auc, na.rm = TRUE)
), by = .(
  direction_membership,
  nominal_membership,
  gse63061_direction_concordant,
  gse85426_direction_concordant,
  gse140829_direction_concordant,
  gse63061_nominal_concordant,
  gse85426_nominal_concordant,
  gse140829_nominal_concordant
)]
setorder(overlap_table, -n_genes)

set_summary <- data.table(
  metric = c(
    "s3_candidate_genes",
    "near_cohort_directional_anchor",
    "near_cohort_nominal_anchor",
    "stable_strict_primary",
    "stable_directional_sensitivity",
    "unstable_primary",
    "unstable_reversal",
    "unstable_vanish",
    "gse85426_direction_concordant",
    "gse140829_direction_concordant",
    "gse85426_nominal_concordant",
    "gse140829_nominal_concordant"
  ),
  n_genes = c(
    nrow(classification),
    sum(classification$near_cohort_anchor),
    sum(classification$near_cohort_nominal),
    nrow(stable_genes),
    nrow(stable_sensitivity),
    nrow(unstable_genes),
    sum(classification$unstable_reversal),
    sum(classification$unstable_vanish),
    sum(classification$gse85426_direction_concordant),
    sum(classification$gse140829_direction_concordant),
    sum(classification$gse85426_nominal_concordant),
    sum(classification$gse140829_nominal_concordant)
  )
)

category_all <- classification[, .N, by = biological_keyword_category]
category_all[, set_name := "all_candidates"]
category_stable <- stable_genes[, .N, by = biological_keyword_category]
category_stable[, set_name := "stable_strict_primary"]
category_stable_sensitivity <- stable_sensitivity[, .N, by = biological_keyword_category]
category_stable_sensitivity[, set_name := "stable_directional_sensitivity"]
category_unstable <- unstable_genes[, .N, by = biological_keyword_category]
category_unstable[, set_name := "unstable_primary"]
category_summary <- rbindlist(list(
  category_all,
  category_stable,
  category_stable_sensitivity,
  category_unstable
), fill = TRUE)
setcolorder(category_summary, c("set_name", "biological_keyword_category", "N"))
category_summary[, fraction := N / sum(N), by = set_name]
setorder(category_summary, set_name, -N)

stable_interpretable_fraction <- category_summary[
  set_name == "stable_strict_primary" & biological_keyword_category != "other_or_unclassified",
  sum(fraction)
]
stable_housekeeping_fraction <- category_summary[
  set_name == "stable_strict_primary" & biological_keyword_category %in% c(
    "mitochondrial_oxphos",
    "ribosomal_translation",
    "proteostasis_ubiquitin",
    "rna_processing"
  ),
  sum(fraction)
]
stable_immune_fraction <- category_summary[
  set_name == "stable_strict_primary" & biological_keyword_category == "immune_inflammatory",
  sum(fraction)
]
if (length(stable_interpretable_fraction) == 0) stable_interpretable_fraction <- 0
if (length(stable_housekeeping_fraction) == 0) stable_housekeeping_fraction <- 0
if (length(stable_immune_fraction) == 0) stable_immune_fraction <- 0

gate_status <- if (
  nrow(stable_genes) >= 30 &&
    nrow(unstable_genes) >= 30 &&
    stable_interpretable_fraction >= 0.25 &&
    (stable_housekeeping_fraction <= 0.70 || stable_immune_fraction >= 0.05)
) {
  "PASS_TO_B3"
} else {
  "REVIEW_BEFORE_B3"
}

fwrite(classification, file.path(results_dir, "route_b_b2_gene_transportability_classification.csv"))
fwrite(stable_genes, file.path(results_dir, "route_b_stable_genes.csv"))
fwrite(stable_sensitivity, file.path(results_dir, "route_b_stable_directional_sensitivity_genes.csv"))
fwrite(unstable_genes, file.path(results_dir, "route_b_unstable_genes.csv"))
fwrite(overlap_table, file.path(results_dir, "route_b_b2_overlap_table.csv"))
fwrite(set_summary, file.path(results_dir, "route_b_b2_set_summary.csv"))
fwrite(category_summary, file.path(results_dir, "route_b_b2_interpretability_keyword_summary.csv"))

class_counts <- classification[, .N, by = transportability_class]
class_counts[, transportability_class := factor(
  transportability_class,
  levels = class_counts[order(N), transportability_class]
)]
p_class <- ggplot(class_counts, aes(x = transportability_class, y = N, fill = transportability_class)) +
  geom_col(width = 0.72, show.legend = FALSE) +
  coord_flip() +
  labs(x = NULL, y = "Genes", title = "Route B B2 transportability classes") +
  theme_minimal(base_size = 11)
ggsave(file.path(fig_dir, "B2_transportability_class_counts.png"), p_class, width = 7.2, height = 4.8, dpi = 300)

direction_overlap <- classification[, .N, by = direction_membership]
setorder(direction_overlap, -N)
top_overlap <- direction_overlap[1:min(.N, 12)]
top_overlap[, direction_membership := factor(direction_membership, levels = rev(direction_membership))]
p_overlap <- ggplot(top_overlap, aes(x = direction_membership, y = N)) +
  geom_col(fill = "#4E79A7", width = 0.7) +
  coord_flip() +
  labs(x = "Direction-concordant dataset combination", y = "Genes", title = "Directional overlap among validation cohorts") +
  theme_minimal(base_size = 11)
ggsave(file.path(fig_dir, "B2_directional_overlap_counts.png"), p_overlap, width = 7.5, height = 5, dpi = 300)

cat_plot <- copy(category_summary[set_name %in% c("stable_strict_primary", "unstable_primary")])
cat_plot[, set_name := factor(set_name, levels = c("stable_strict_primary", "unstable_primary"))]
p_cat <- ggplot(cat_plot, aes(x = set_name, y = fraction, fill = biological_keyword_category)) +
  geom_col(width = 0.7) +
  labs(x = NULL, y = "Fraction", title = "Keyword-based biological composition") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_text(angle = 10, hjust = 1))
ggsave(file.path(fig_dir, "B2_stable_unstable_category_composition.png"), p_cat, width = 7.5, height = 4.8, dpi = 300)

report_lines <- c(
  "# Route B B2 Stable/Unstable Gene-Set Report",
  "",
  paste0("Generated at: ", now_stamp),
  "",
  "## Scope",
  "",
  "- Constructed stable and unstable gene sets from frozen S3 candidates and B1 validation outputs.",
  "- Used GSE63061 as the related-cohort anchor and GSE85426/GSE140829 as cross-platform validation cohorts.",
  "- Did not optimize classifiers or reselect S3 candidates.",
  "",
  "## Definitions",
  "",
  "- Stable strict primary set: GSE63061 nominally concordant, all mapped cross-platform cohorts direction-concordant, and at least one cross-platform cohort nominally concordant.",
  "- Stable directional sensitivity set: GSE63061 direction-concordant and all mapped cross-platform cohorts direction-concordant.",
  "- Unstable primary set: GSE63061 nominally concordant but not strict-stable, with either cross-platform reversal or cross-platform signal loss.",
  "- Signal loss rule: no nominal cross-platform support and cross-platform maximum oriented AUC < 0.55.",
  "",
  "## Set Counts",
  "",
  paste(capture.output(print(set_summary)), collapse = "\n"),
  "",
  "## Keyword-Based Interpretability Check",
  "",
  paste(capture.output(print(category_summary)), collapse = "\n"),
  "",
  "## Gate B2 Decision",
  "",
  paste0("Gate B2 status: **", gate_status, "**"),
  "",
  "## Interpretation",
  "",
  paste0("- Stable strict primary set contains ", nrow(stable_genes), " genes."),
  paste0("- Stable directional sensitivity set contains ", nrow(stable_sensitivity), " genes."),
  paste0("- Unstable primary set contains ", nrow(unstable_genes), " genes."),
  paste0("- Stable interpretable keyword fraction = ", round(stable_interpretable_fraction, 3), "."),
  paste0("- Stable housekeeping-like keyword fraction = ", round(stable_housekeeping_fraction, 3), "."),
  paste0("- Stable immune/inflammatory keyword fraction = ", round(stable_immune_fraction, 3), "."),
  "",
  "The B2 output is suitable for B3 enrichment if the formal enrichment analysis confirms pathway coherence.",
  "",
  "## Outputs",
  "",
  "- `results/route_b_stable_genes.csv`",
  "- `results/route_b_stable_directional_sensitivity_genes.csv`",
  "- `results/route_b_unstable_genes.csv`",
  "- `results/route_b_b2_gene_transportability_classification.csv`",
  "- `results/route_b_b2_overlap_table.csv`",
  "- `results/route_b_b2_set_summary.csv`",
  "- `results/route_b_b2_interpretability_keyword_summary.csv`",
  "- `figures/route_b/B2_transportability_class_counts.png`",
  "- `figures/route_b/B2_directional_overlap_counts.png`",
  "- `figures/route_b/B2_stable_unstable_category_composition.png`"
)
writeLines(report_lines, file.path(audit_dir, "route_b_b2_stable_unstable_gene_sets_report.md"), useBytes = TRUE)

gate_lines <- c(
  "# Gate B2 Stable/Unstable Gene-Set Review",
  "",
  paste0("Review date: ", now_stamp),
  "",
  "## Decision",
  "",
  paste0("Gate B2 status: **", gate_status, "**"),
  "",
  "## Quantitative Basis",
  "",
  paste0("- Stable strict primary genes: ", nrow(stable_genes)),
  paste0("- Stable directional sensitivity genes: ", nrow(stable_sensitivity)),
  paste0("- Unstable primary genes: ", nrow(unstable_genes)),
  paste0("- Unstable reversal genes: ", sum(classification$unstable_reversal)),
  paste0("- Unstable signal-loss genes: ", sum(classification$unstable_vanish)),
  paste0("- Stable interpretable keyword fraction: ", round(stable_interpretable_fraction, 3)),
  paste0("- Stable housekeeping-like keyword fraction: ", round(stable_housekeeping_fraction, 3)),
  paste0("- Stable immune/inflammatory keyword fraction: ", round(stable_immune_fraction, 3)),
  "",
  "## Required Next Step",
  "",
  "- Proceed to B3 pathway and biological interpretation.",
  "- Use `route_b_stable_genes.csv` as the primary stable set and `route_b_stable_directional_sensitivity_genes.csv` as sensitivity evidence.",
  "- Treat keyword categories as a preliminary sanity check only; formal GO/KEGG/Reactome enrichment is still required."
)
writeLines(gate_lines, file.path(audit_dir, "gate_b2_stable_unstable_gene_set_review.md"), useBytes = TRUE)

print(set_summary)
cat("\n")
print(category_summary)
cat("\nGate B2 status:", gate_status, "\n")
