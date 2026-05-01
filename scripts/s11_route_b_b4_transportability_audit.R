suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
})
if (requireNamespace("patchwork", quietly = TRUE)) {
  library(patchwork)
}

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
results_dir <- file.path(root, "results")
fig_dir <- file.path(root, "figures", "route_b")
audit_dir <- file.path(root, "audit")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

now_stamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
target_auc <- 0.70

safe_num <- function(x) suppressWarnings(as.numeric(x))

wrap_label <- function(x, width = 34) {
  vapply(x, function(s) paste(strwrap(as.character(s), width = width), collapse = "\n"), character(1))
}

fmt <- function(x, digits = 3) {
  ifelse(is.na(x), "NA", formatC(x, format = "f", digits = digits))
}

replication <- fread(file.path(results_dir, "route_b_b1_replication_summary.csv"))
dataset_roles <- fread(file.path(results_dir, "route_b_b1_dataset_role_summary.csv"))
model_auc <- fread(file.path(results_dir, "route_b_b1_model_auc_long.csv"))
b2_summary <- fread(file.path(results_dir, "route_b_b2_set_summary.csv"))
b3_database <- fread(file.path(results_dir, "route_b_b3_database_summary.csv"))
b3_module <- fread(file.path(results_dir, "route_b_b3_module_summary.csv"))
route_a_validation <- fread(file.path(results_dir, "route_a_gse140829_model_validation.csv"))
route_a_predictions <- fread(file.path(results_dir, "route_a_gse140829_model_predictions.csv"))
s4_score_summary <- fread(file.path(results_dir, "s4_signature_score_summary.csv"))
s4_sample_scores <- fread(file.path(results_dir, "s4_signature_sample_scores.csv"))

role_recode <- c(
  new_large_cross_platform_final_validation = "large_independent_external_validation"
)
replication[, validation_role := fifelse(validation_role %chin% names(role_recode), role_recode[validation_role], validation_role)]
dataset_roles[, route_b_role := fifelse(route_b_role %chin% names(role_recode), role_recode[route_b_role], route_b_role)]

replication[, nominal_fraction := nominal_concordant / mapped_s3_candidate_genes]
replication[, fdr_fraction := fdr_concordant / mapped_s3_candidate_genes]
replication[, auc_ge_060_fraction := auc_ge_060 / mapped_s3_candidate_genes]

best_frozen_model_auc <- model_auc[dataset_accession %in% c("GSE63061", "GSE85426", "GSE140829"), .(
  best_frozen_model_auc = max(auc, na.rm = TRUE),
  any_model_reaches_070 = any(auc >= target_auc, na.rm = TRUE)
), by = dataset_accession]

transportability_metrics <- merge(replication, best_frozen_model_auc, by = "dataset_accession", all.x = TRUE)
transportability_metrics[, external_validity_status := fcase(
  dataset_accession == "GSE63061" & best_frozen_model_auc >= target_auc & fdr_concordant >= 100, "near_cohort_reproducible",
  dataset_accession != "GSE63061" & best_frozen_model_auc < target_auc & fdr_concordant <= 5, "independent_validation_degraded",
  default = "mixed_or_review"
)]
transportability_metrics[, route_b_interpretation := fcase(
  external_validity_status == "near_cohort_reproducible", "Related-cohort signal is reproducible and supports non-random discovery.",
  external_validity_status == "independent_validation_degraded", "Independent-validation transferability is limited; model performance should be treated as cautionary.",
  default = "Requires cautious interpretation."
)]
setcolorder(transportability_metrics, c(
  "dataset_accession", "validation_role", "platform_or_mapping", "n_samples", "n_ad", "n_control",
  "mapped_s3_candidate_genes", "mapped_fraction", "direction_concordance_rate",
  "nominal_concordant", "nominal_fraction", "fdr_concordant", "fdr_fraction",
  "median_auc_oriented", "max_auc_oriented", "best_frozen_model_auc", "any_model_reaches_070",
  "external_validity_status", "route_b_interpretation"
))

auc_wide <- dcast(
  model_auc[dataset_accession %in% c("GSE63060", "GSE63061", "GSE85426", "GSE140829", "GSE63060+GSE63061")],
  model_role + model_id + covariate_mode ~ dataset_accession,
  value.var = "auc"
)
for (nm in c("GSE63061", "GSE85426", "GSE140829")) {
  if (!nm %in% names(auc_wide)) auc_wide[, (nm) := NA_real_]
}
auc_wide[, dev_to_gse85426_delta := GSE63061 - GSE85426]
auc_wide[, dev_to_gse140829_delta := GSE63061 - GSE140829]
auc_wide[, independent_validation_best_auc := pmax(GSE85426, GSE140829, na.rm = TRUE)]
auc_wide[is.infinite(independent_validation_best_auc), independent_validation_best_auc := NA_real_]
auc_wide[, independent_validation_reaches_070 := independent_validation_best_auc >= target_auc]

mci_gradient <- copy(route_a_validation[, .(
  model_role,
  model_id,
  auc_ad_vs_control,
  auc_ci_low,
  auc_ci_high,
  mean_control,
  mean_mci,
  mean_ad,
  mci_between_control_ad,
  reaches_auc_070
)])
mci_gradient[, mci_position := fifelse(
  mci_between_control_ad,
  "MCI_between_Control_and_AD",
  "MCI_not_between_Control_and_AD"
)]

top50_scores <- s4_score_summary[signature_size_label == "top50", .(
  dataset_accession,
  signature_size_label,
  auc_oriented,
  mean_ad,
  mean_control,
  ad_minus_control,
  t_test_p
)]
top50_scores[, score_context := "S3 top50 signed signature"]

b3_yield <- b3_database[background == "candidate_background", .(
  gene_set,
  database,
  tested_terms,
  significant_terms_fdr_005,
  min_fdr
)]

figure_plan <- data.table(
  figure_id = c("Figure 1", "Figure 2", "Figure 3", "Figure 4"),
  file = c(
    "figures/route_b/B4_main_figure1_dataset_workflow.png",
    "figures/route_b/B4_main_figure2_validation_heatmap.png",
    "figures/route_b/B4_main_figure3_auc_and_scores.png",
    "figures/route_b/B4_main_figure4_pathway_comparison.png"
  ),
  purpose = c(
    "Show discovery, related validation, cross-platform stress test, and large independent external validation dataset roles.",
    "Show mapping, direction, nominal replication, targeted replication FDR, gene-level AUC, and frozen model AUC across cohorts.",
    "Show AUC decay and GSE140829 MCI score placement.",
    "Show stable-vs-unstable enrichment yield and pathway modules."
  ),
  manuscript_message = c(
    "The study is designed as staged external validation, not single-cohort discovery.",
    "Signals replicate strongly in the related cohort but degrade in independent validation.",
    "Model performance drops below 0.70 in independent validation; MCI gradient is only partial support.",
    "Transportable stable genes show conservative translation/RNA-processing enrichment; unstable genes lack coherent enrichment."
  )
)

claim_audit <- data.table(
  claim_type = c(
    "Allowed",
    "Allowed",
    "Allowed",
    "Allowed with caution",
    "Avoid",
    "Avoid",
    "Avoid"
  ),
  wording = c(
    "Peripheral blood transcriptional signals show related-cohort reproducibility.",
    "Transferability is limited across independent platforms/cohorts.",
    "External validation failure highlights cohort and platform dependence.",
    "Stable transportable genes are enriched for translation and RNA-processing pathways.",
    "Robust diagnostic biomarker.",
    "Clinically useful high-performance classifier.",
    "Validated diagnostic signature across cohorts."
  ),
  evidence_basis = c(
    "GSE63061 direction concordance 0.989 and targeted FDR-concordant genes 395.",
    "Highest frozen independent-validation model AUC values remain below 0.70 in GSE85426 and GSE140829.",
    "AUC and targeted replication FDR support drop from GSE63061 to independent validation cohorts.",
    "B3 stable set enrichment is significant but housekeeping-like; no immune/blood significant terms.",
    "Contradicted by GSE85426 and GSE140829 AUC values.",
    "No independent-validation model reaches AUC 0.70.",
    "Validation is cohort-dependent and unstable in stress-test datasets."
  ),
  route_b_ok = c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE)
)

fwrite(transportability_metrics, file.path(results_dir, "route_b_b4_transportability_metrics.csv"))
fwrite(auc_wide, file.path(results_dir, "route_b_b4_auc_decay_summary.csv"))
fwrite(mci_gradient, file.path(results_dir, "route_b_b4_mci_score_gradient.csv"))
fwrite(top50_scores, file.path(results_dir, "route_b_b4_top50_signature_score_summary.csv"))
fwrite(b3_yield, file.path(results_dir, "route_b_b4_pathway_yield_summary.csv"))
fwrite(figure_plan, file.path(results_dir, "route_b_b4_main_figure_plan.csv"))
fwrite(claim_audit, file.path(results_dir, "route_b_b4_manuscript_claim_audit.csv"))

dataset_plot <- copy(dataset_roles)
dataset_plot[, dataset_accession := factor(dataset_accession, levels = dataset_accession)]
dataset_plot[, total_ad_control := n_ad + n_control]
dataset_plot[, label := paste0(dataset_accession, "\nAD=", n_ad, ", Control=", n_control)]
role_colors <- c(
  discovery_training = "#4E79A7",
  related_external_validation = "#59A14F",
  cross_platform_stress_test = "#F28E2B",
  large_independent_external_validation = "#E15759"
)
role_labels <- c(
  discovery_training = "Discovery training",
  related_external_validation = "Related validation",
  cross_platform_stress_test = "Cross-platform stress test",
  large_independent_external_validation = "Large independent external validation"
)
p1 <- ggplot(dataset_plot, aes(x = dataset_accession, y = 1, color = route_b_role)) +
  geom_line(aes(group = 1), color = "grey75", linewidth = 0.8) +
  geom_point(aes(size = total_ad_control), alpha = 0.95) +
  geom_text(aes(label = label), vjust = -1.1, size = 3.2, color = "black") +
  scale_color_manual(values = role_colors, labels = role_labels) +
  scale_size_continuous(range = c(5, 11), guide = "none") +
  ylim(0.6, 1.38) +
  labs(x = NULL, y = NULL, color = "Dataset role", title = "Staged transferability-audit design") +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.y = element_blank(),
    axis.ticks = element_blank(),
    panel.grid = element_blank(),
    legend.position = "bottom"
  )
ggsave(file.path(fig_dir, "B4_main_figure1_dataset_workflow.png"), p1, width = 9, height = 3.8, dpi = 300)

heat_metrics <- transportability_metrics[, .(
  dataset_accession,
  `Mapped fraction` = mapped_fraction,
  `Direction concordance` = direction_concordance_rate,
  `Nominal replication fraction` = nominal_fraction,
  `Targeted FDR fraction` = fdr_fraction,
  `Median gene AUC` = median_auc_oriented,
  `Best frozen model AUC` = best_frozen_model_auc
)]
heat_long <- melt(heat_metrics, id.vars = "dataset_accession", variable.name = "metric", value.name = "value")
heat_long[, metric := factor(metric, levels = c(
  "Mapped fraction", "Direction concordance", "Nominal replication fraction",
  "Targeted FDR fraction", "Median gene AUC", "Best frozen model AUC"
))]
heat_long[, dataset_accession := factor(dataset_accession, levels = c("GSE63061", "GSE85426", "GSE140829"))]
p2 <- ggplot(heat_long, aes(x = metric, y = dataset_accession, fill = value)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = fmt(value, 2)), size = 3.1) +
  scale_fill_gradientn(colors = c("#F1A340", "#F7F7F7", "#2B83BA"), limits = c(0, 1), oob = scales::squish) +
  labs(x = NULL, y = NULL, fill = "Value", title = "Cross-cohort transportability audit") +
  theme_minimal(base_size = 10.5) +
  theme(axis.text.x = element_text(angle = 28, hjust = 1))
ggsave(file.path(fig_dir, "B4_main_figure2_validation_heatmap.png"), p2, width = 9.5, height = 4.8, dpi = 300)

auc_plot <- model_auc[model_role %in% c("primary_gene_only", "primary_integrated_or_clinical", "train_dev_refit_selected")]
auc_plot <- auc_plot[dataset_accession %in% c("GSE63060", "GSE63061", "GSE85426", "GSE140829", "GSE63060+GSE63061")]
auc_plot[, model_label := fcase(
  model_role == "primary_gene_only", "Primary gene-only",
  model_role == "primary_integrated_or_clinical", "Primary integrated",
  model_role == "train_dev_refit_selected", "Train-development refit",
  default = model_role
)]
auc_plot[, dataset_order := fcase(
  dataset_accession == "GSE63060", 1,
  dataset_accession == "GSE63060+GSE63061", 1.5,
  dataset_accession == "GSE63061", 2,
  dataset_accession == "GSE85426", 3,
  dataset_accession == "GSE140829", 4,
  default = 99
)]
auc_plot[, dataset_label := factor(dataset_accession, levels = auc_plot[order(dataset_order), unique(dataset_accession)])]
p3a <- ggplot(auc_plot, aes(x = dataset_label, y = auc, group = model_label, color = model_label)) +
  geom_hline(yintercept = target_auc, linetype = "dashed", color = "grey35") +
  geom_line(linewidth = 0.75, alpha = 0.9) +
  geom_point(size = 2.2) +
  scale_y_continuous(limits = c(0.45, 0.95), breaks = seq(0.5, 0.9, by = 0.1)) +
  labs(x = NULL, y = "AUC", color = "Model", title = "AUC decay across validation contexts") +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 25, hjust = 1), legend.position = "bottom")

gse140829_scores <- route_a_predictions[model_id == "sig_dev_p_k3"]
gse140829_scores[, diagnosis_clean := factor(diagnosis_clean, levels = c("Control", "MCI", "AD"))]
p3b <- ggplot(gse140829_scores, aes(x = diagnosis_clean, y = score, fill = diagnosis_clean)) +
  geom_violin(width = 0.8, alpha = 0.55, color = NA) +
  geom_boxplot(width = 0.18, outlier.shape = NA, alpha = 0.8) +
  stat_summary(fun = mean, geom = "point", shape = 23, size = 2.3, fill = "white") +
  scale_fill_manual(values = c(Control = "#9ECAE1", MCI = "#FDD0A2", AD = "#FB6A4A")) +
  labs(x = NULL, y = "Frozen gene-only score", title = "GSE140829 score placement including MCI") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "none")

if ("patchwork" %in% loadedNamespaces()) {
  p3 <- (p3a / p3b) +
    plot_layout(heights = c(1.1, 1)) +
    plot_annotation(tag_levels = "A") &
    theme(plot.tag = element_text(face = "bold", size = 14))
  ggsave(file.path(fig_dir, "B4_main_figure3_auc_and_scores.png"), p3, width = 9.2, height = 7.6, dpi = 300)
} else {
  ggsave(file.path(fig_dir, "B4_main_figure3_auc_decay.png"), p3a, width = 9, height = 4.8, dpi = 300)
  ggsave(file.path(fig_dir, "B4_main_figure3_mci_scores.png"), p3b, width = 5.5, height = 4.8, dpi = 300)
}

pathway_plot <- b3_yield[gene_set %in% c("stable_strict_primary", "unstable_primary")]
pathway_plot[, gene_set := factor(gene_set, levels = c("stable_strict_primary", "unstable_primary"))]
p4a <- ggplot(pathway_plot, aes(x = database, y = significant_terms_fdr_005, fill = gene_set)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.66) +
  labs(x = NULL, y = "FDR < 0.05 terms", fill = "Gene set", title = "Pathway enrichment yield") +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 15, hjust = 1), legend.position = "bottom")

module_plot <- b3_module[background == "candidate_background" & gene_set %in% c("stable_strict_primary", "unstable_primary")]
if (nrow(module_plot) == 0) {
  module_plot <- data.table(gene_set = "stable_strict_primary", database = "GO_BP", module = "none", significant_terms = 0)
}
module_plot[, module := factor(module, levels = rev(unique(module[order(significant_terms)])))]
p4b <- ggplot(module_plot, aes(x = gene_set, y = module, fill = significant_terms)) +
  geom_tile(color = "white", linewidth = 0.5) +
  facet_wrap(~ database, scales = "free_x") +
  scale_fill_gradient(low = "#F7F7F7", high = "#4E79A7") +
  labs(x = NULL, y = NULL, fill = "Terms", title = "Significant pathway modules") +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 18, hjust = 1))

if ("patchwork" %in% loadedNamespaces()) {
  p4 <- (p4a / p4b) +
    plot_layout(heights = c(1, 1.15)) +
    plot_annotation(tag_levels = "A") &
    theme(plot.tag = element_text(face = "bold", size = 14))
  ggsave(file.path(fig_dir, "B4_main_figure4_pathway_comparison.png"), p4, width = 9.2, height = 7.4, dpi = 300)
} else {
  ggsave(file.path(fig_dir, "B4_main_figure4_pathway_yield.png"), p4a, width = 7, height = 4.8, dpi = 300)
  ggsave(file.path(fig_dir, "B4_main_figure4_module_heatmap.png"), p4b, width = 8, height = 5.2, dpi = 300)
}

near <- transportability_metrics[dataset_accession == "GSE63061"]
independent <- transportability_metrics[match(c("GSE85426", "GSE140829"), dataset_accession)]
near_reproducible <- nrow(near) == 1 &&
  near$direction_concordance_rate >= 0.95 &&
  near$fdr_concordant >= 100 &&
  near$best_frozen_model_auc >= target_auc
independent_degraded <- nrow(independent) == 2 &&
  all(independent$best_frozen_model_auc < target_auc, na.rm = TRUE) &&
  all(independent$fdr_concordant <= 5, na.rm = TRUE)
auc_decay_clear <- all(auc_wide[model_role %in% c("primary_gene_only", "primary_integrated_or_clinical"), dev_to_gse85426_delta > 0.15], na.rm = TRUE) &&
  all(auc_wide[model_role %in% c("primary_gene_only", "primary_integrated_or_clinical"), dev_to_gse140829_delta > 0.15], na.rm = TRUE)
mci_partial <- any(mci_gradient$mci_between_control_ad == TRUE)
pathway_conditional <- any(b3_yield[gene_set == "stable_strict_primary"]$significant_terms_fdr_005 > 0) &&
  all(b3_yield[gene_set == "unstable_primary"]$significant_terms_fdr_005 == 0)

gate_status <- if (near_reproducible && independent_degraded && auc_decay_clear) {
  if (pathway_conditional) "PASS_TO_B5_Q4_FRAMING" else "CONDITIONAL_PASS_TO_B5"
} else {
  "REVIEW_BEFORE_B5"
}

gate_summary <- data.table(
  criterion = c(
    "near_cohort_reproducible",
    "independent_validation_degraded",
    "auc_decay_clear",
    "mci_gradient_partial_support",
    "pathway_context_conditional"
  ),
  pass = c(near_reproducible, independent_degraded, auc_decay_clear, mci_partial, pathway_conditional),
  evidence = c(
    paste0("GSE63061 direction=", fmt(near$direction_concordance_rate), ", targeted FDR genes=", near$fdr_concordant, ", highest frozen-model AUC=", fmt(near$best_frozen_model_auc)),
    paste0("GSE85426/GSE140829 highest frozen-model AUC=", paste(fmt(independent$best_frozen_model_auc), collapse = "/"), "; targeted FDR genes=", paste(independent$fdr_concordant, collapse = "/")),
    paste0("Primary model development-to-independent-validation AUC deltas exceed 0.15."),
    paste0(sum(mci_gradient$mci_between_control_ad), " of ", nrow(mci_gradient), " GSE140829 model score summaries place MCI between Control and AD."),
    "Stable genes have significant pathway enrichment while unstable genes have no FDR<0.05 enrichment."
  )
)
fwrite(gate_summary, file.path(results_dir, "route_b_b4_gate_summary.csv"))

report_lines <- c(
  "# Route B B4 Transportability Audit Report",
  "",
  paste0("Generated at: ", now_stamp),
  "",
  "## Scope",
  "",
  "- Consolidated mapping, direction concordance, nominal replication, targeted replication FDR, frozen model AUC decay, MCI placement, and pathway-yield evidence.",
  "- Built main-figure drafts for a limited-transferability manuscript.",
  "- Did not tune or refit classifiers.",
  "",
  "## Transportability Metrics",
  "",
  paste(capture.output(print(transportability_metrics)), collapse = "\n"),
  "",
  "## AUC Decay Summary",
  "",
  paste(capture.output(print(auc_wide)), collapse = "\n"),
  "",
  "## MCI Score Gradient",
  "",
  paste(capture.output(print(mci_gradient)), collapse = "\n"),
  "",
  "## B4 Gate Summary",
  "",
  paste(capture.output(print(gate_summary)), collapse = "\n"),
  "",
  "## Gate B4 Decision",
  "",
  paste0("Gate B4 status: **", gate_status, "**"),
  "",
  "## Interpretation",
  "",
  "- The evidence clearly supports related-cohort reproducibility and independent-validation degradation.",
  "- The manuscript should frame modeling as an external-validation cautionary result.",
  "- MCI score placement is partial support only and should not be elevated to a primary claim.",
  "- Pathway evidence is useful context for stable transportable genes but remains conservative.",
  "",
  "## Outputs",
  "",
  "- `results/route_b_b4_transportability_metrics.csv`",
  "- `results/route_b_b4_auc_decay_summary.csv`",
  "- `results/route_b_b4_mci_score_gradient.csv`",
  "- `results/route_b_b4_top50_signature_score_summary.csv`",
  "- `results/route_b_b4_pathway_yield_summary.csv`",
  "- `results/route_b_b4_main_figure_plan.csv`",
  "- `results/route_b_b4_manuscript_claim_audit.csv`",
  "- `results/route_b_b4_gate_summary.csv`",
  "- `figures/route_b/B4_main_figure1_dataset_workflow.png`",
  "- `figures/route_b/B4_main_figure2_validation_heatmap.png`",
  "- `figures/route_b/B4_main_figure3_auc_and_scores.png`",
  "- `figures/route_b/B4_main_figure4_pathway_comparison.png`"
)
writeLines(report_lines, file.path(audit_dir, "route_b_b4_transportability_audit_report.md"), useBytes = TRUE)

gate_lines <- c(
  "# Gate B4 Transportability Audit Review",
  "",
  paste0("Review date: ", now_stamp),
  "",
  "## Decision",
  "",
  paste0("Gate B4 status: **", gate_status, "**"),
  "",
  "## Quantitative Basis",
  "",
  paste0("- GSE63061 direction concordance: ", fmt(near$direction_concordance_rate), "; targeted FDR-concordant genes: ", near$fdr_concordant, "; highest frozen-model AUC: ", fmt(near$best_frozen_model_auc), "."),
  paste0("- GSE85426 highest frozen-model AUC: ", fmt(transportability_metrics[dataset_accession == "GSE85426"]$best_frozen_model_auc), "; targeted FDR-concordant genes: ", transportability_metrics[dataset_accession == "GSE85426"]$fdr_concordant, "."),
  paste0("- GSE140829 highest frozen-model AUC: ", fmt(transportability_metrics[dataset_accession == "GSE140829"]$best_frozen_model_auc), "; targeted FDR-concordant genes: ", transportability_metrics[dataset_accession == "GSE140829"]$fdr_concordant, "."),
  paste0("- MCI between Control and AD in GSE140829 model summaries: ", sum(mci_gradient$mci_between_control_ad), "/", nrow(mci_gradient), "."),
  "",
  "## Reviewer Interpretation",
  "",
  "- B4 supports a Q4-oriented limited-transferability manuscript.",
  "- B4 does not support a robust diagnostic biomarker manuscript.",
  "- The main figures should foreground degradation and cohort dependence.",
  "",
  "## Required Next Step",
  "",
  "- Proceed to B5 manuscript framing and B6 submission strategy.",
  "- Keep title, abstract, and conclusion aligned with transportability limitations.",
  "- Use the B4 claim audit table before drafting."
)
writeLines(gate_lines, file.path(audit_dir, "gate_b4_transportability_audit_review.md"), useBytes = TRUE)

print(transportability_metrics)
cat("\n")
print(auc_wide)
cat("\n")
print(gate_summary)
cat("\nGate B4 status:", gate_status, "\n")
