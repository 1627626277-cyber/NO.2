suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(clusterProfiler)
  library(org.Hs.eg.db)
  library(ReactomePA)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
results_dir <- file.path(root, "results")
fig_dir <- file.path(root, "figures", "route_b")
audit_dir <- file.path(root, "audit")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(audit_dir, showWarnings = FALSE, recursive = TRUE)

now_stamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

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

valid_entrez <- function(x) {
  x <- unique(na.omit(as.character(x)))
  x[grepl("^[0-9]+$", x)]
}

ratio_to_numeric <- function(x) {
  out <- rep(NA_real_, length(x))
  for (i in seq_along(x)) {
    parts <- strsplit(as.character(x[i]), "/", fixed = TRUE)[[1]]
    if (length(parts) == 2) {
      out[i] <- suppressWarnings(as.numeric(parts[1]) / as.numeric(parts[2]))
    }
  }
  out
}

wrap_term <- function(x, width = 48) {
  vapply(x, function(s) paste(strwrap(s, width = width), collapse = "\n"), character(1))
}

term_module <- function(description) {
  text <- toupper(description)
  if (grepl("RIBOSOM|TRANSLATION|PEPTIDE BIOSYNTH|AMIDE BIOSYNTH|PROTEIN TARGETING|SRP|NONSENSE-MEDIATED", text)) {
    return("ribosomal_translation")
  }
  if (grepl("MITOCHONDR|RESPIRATORY|OXIDATIVE PHOSPHORYLATION|ELECTRON TRANSPORT|ATP SYNTHESIS|NADH|PROTON", text)) {
    return("mitochondrial_oxphos")
  }
  if (grepl("IMMUN|INFLAM|CYTOKINE|INTERFERON|LEUKOCYTE|LYMPHOCYTE|NEUTROPHIL|MONOCYTE|PHAGOCYT|ANTIGEN|COMPLEMENT|TOLL|DEFENSE RESPONSE", text)) {
    return("immune_inflammatory")
  }
  if (grepl("PROTEASOM|UBIQUITIN|PROTEIN CATABOLIC|PROTEOLYSIS|PROTEIN QUALITY", text)) {
    return("proteostasis_ubiquitin")
  }
  if (grepl("RNA|SPLIC|MRNA|RIBONUCLEOPROTEIN|NUCLEOLAR", text)) {
    return("rna_processing")
  }
  if (grepl("PLATELET|ERYTHRO|HEMOGLOBIN|HEMOSTASIS|COAGULATION", text)) {
    return("blood_cell_platelet_erythroid")
  }
  if (grepl("CELL CYCLE|DNA REPAIR|CHROMATIN|REPLICATION", text)) {
    return("cell_cycle_dna_chromatin")
  }
  "other_or_unclassified"
}

run_go_bp <- function(genes, universe, set_name, background_name) {
  if (length(genes) < 5 || length(universe) < 20) return(data.table())
  res <- tryCatch(
    enrichGO(
      gene = genes,
      universe = universe,
      OrgDb = org.Hs.eg.db,
      keyType = "ENTREZID",
      ont = "BP",
      pAdjustMethod = "BH",
      pvalueCutoff = 1,
      qvalueCutoff = 1,
      minGSSize = 5,
      maxGSSize = 500,
      readable = TRUE
    ),
    error = function(e) e
  )
  if (inherits(res, "error") || is.null(res)) return(data.table())
  dt <- as.data.table(as.data.frame(res))
  if (nrow(dt) == 0) return(dt)
  dt[, `:=`(gene_set = set_name, background = background_name, database = "GO_BP")]
  dt
}

run_kegg <- function(genes, universe, set_name, background_name) {
  if (length(genes) < 5 || length(universe) < 20) return(data.table())
  res <- tryCatch(
    enrichKEGG(
      gene = genes,
      universe = universe,
      organism = "hsa",
      keyType = "kegg",
      pAdjustMethod = "BH",
      pvalueCutoff = 1,
      qvalueCutoff = 1,
      minGSSize = 5,
      maxGSSize = 500
    ),
    error = function(e) e
  )
  if (inherits(res, "error") || is.null(res)) return(data.table())
  dt <- as.data.table(as.data.frame(res))
  if (nrow(dt) == 0) return(dt)
  dt[, `:=`(gene_set = set_name, background = background_name, database = "KEGG")]
  dt
}

run_reactome <- function(genes, universe, set_name, background_name) {
  if (length(genes) < 5 || length(universe) < 20) return(data.table())
  res <- tryCatch(
    enrichPathway(
      gene = genes,
      universe = universe,
      organism = "human",
      pAdjustMethod = "BH",
      pvalueCutoff = 1,
      qvalueCutoff = 1,
      minGSSize = 5,
      maxGSSize = 500,
      readable = TRUE
    ),
    error = function(e) e
  )
  if (inherits(res, "error") || is.null(res)) return(data.table())
  dt <- as.data.table(as.data.frame(res))
  if (nrow(dt) == 0) return(dt)
  dt[, `:=`(gene_set = set_name, background = background_name, database = "Reactome")]
  dt
}

standardize_enrichment <- function(dt) {
  if (nrow(dt) == 0) return(dt)
  needed <- c("ID", "Description", "GeneRatio", "BgRatio", "pvalue", "p.adjust", "qvalue", "geneID", "Count")
  for (nm in needed) {
    if (!nm %in% names(dt)) dt[, (nm) := NA]
  }
  dt[, gene_ratio_numeric := ratio_to_numeric(GeneRatio)]
  dt[, bg_ratio_numeric := ratio_to_numeric(BgRatio)]
  dt[, module := vapply(Description, term_module, character(1))]
  setcolorder(dt, c(
    "gene_set", "background", "database", "ID", "Description", "module",
    "GeneRatio", "gene_ratio_numeric", "BgRatio", "bg_ratio_numeric",
    "pvalue", "p.adjust", "qvalue", "Count", "geneID",
    setdiff(names(dt), c(
      "gene_set", "background", "database", "ID", "Description", "module",
      "GeneRatio", "gene_ratio_numeric", "BgRatio", "bg_ratio_numeric",
      "pvalue", "p.adjust", "qvalue", "Count", "geneID"
    ))
  ))
  dt
}

stable <- fread(file.path(results_dir, "route_b_stable_genes.csv"))
stable_sensitivity <- fread(file.path(results_dir, "route_b_stable_directional_sensitivity_genes.csv"))
unstable <- fread(file.path(results_dir, "route_b_unstable_genes.csv"))
classification <- fread(file.path(results_dir, "route_b_b2_gene_transportability_classification.csv"))
s3_all <- fread(file.path(results_dir, "s3_deg_limma_gse63060_all.csv"))

stable_genes <- valid_entrez(stable$gene_id)
stable_sensitivity_genes <- valid_entrez(stable_sensitivity$gene_id)
unstable_genes <- valid_entrez(unstable$gene_id)
candidate_universe <- valid_entrez(classification$gene_id)
s3_all[, gene_id_primary := primary_gene_id(gene_id)]
assayed_universe <- valid_entrez(s3_all[is_annotated_gene == TRUE, gene_id_primary])

gene_sets <- list(
  stable_strict_primary = stable_genes,
  stable_directional_sensitivity = stable_sensitivity_genes,
  unstable_primary = unstable_genes
)
backgrounds <- list(
  candidate_background = candidate_universe
)

enrichment_list <- list()
for (set_name in names(gene_sets)) {
  for (background_name in names(backgrounds)) {
    genes <- intersect(gene_sets[[set_name]], backgrounds[[background_name]])
    universe <- backgrounds[[background_name]]
    enrichment_list[[paste(set_name, background_name, "go", sep = "__")]] <- run_go_bp(genes, universe, set_name, background_name)
    enrichment_list[[paste(set_name, background_name, "kegg", sep = "__")]] <- run_kegg(genes, universe, set_name, background_name)
    enrichment_list[[paste(set_name, background_name, "reactome", sep = "__")]] <- run_reactome(genes, universe, set_name, background_name)
  }
}

enrichment_all <- rbindlist(enrichment_list, fill = TRUE)
enrichment_all <- standardize_enrichment(enrichment_all)
setorder(enrichment_all, background, gene_set, database, p.adjust, pvalue)

enrichment_sig <- enrichment_all[!is.na(p.adjust) & p.adjust < 0.05]
ranked_terms <- enrichment_all[
  background == "candidate_background" & gene_set %in% c("stable_strict_primary", "unstable_primary"),
  .SD[order(p.adjust, pvalue)][1:min(.N, 12)],
  by = .(gene_set, database)
]
ranked_terms <- ranked_terms[!is.na(ID)]
ranked_terms[, term_status := fifelse(!is.na(p.adjust) & p.adjust < 0.05, "significant_fdr005", "ranked_not_significant")]
top_terms <- enrichment_sig[
  background == "candidate_background" & gene_set %in% c("stable_strict_primary", "unstable_primary"),
  .SD[order(p.adjust, pvalue)][1:min(.N, 12)],
  by = .(gene_set, database)
]
top_terms <- top_terms[!is.na(ID)]

module_summary <- enrichment_sig[, .(
  significant_terms = .N,
  min_fdr = min(p.adjust, na.rm = TRUE),
  median_gene_ratio = median(gene_ratio_numeric, na.rm = TRUE)
), by = .(background, gene_set, database, module)]
setorder(module_summary, background, gene_set, database, min_fdr)

database_summary <- enrichment_all[, .(
  tested_terms = .N,
  significant_terms_fdr_005 = sum(!is.na(p.adjust) & p.adjust < 0.05),
  min_fdr = suppressWarnings(min(p.adjust, na.rm = TRUE))
), by = .(background, gene_set, database)]
database_summary[is.infinite(min_fdr), min_fdr := NA_real_]

gene_set_summary <- data.table(
  gene_set = names(gene_sets),
  input_entrez_genes = vapply(gene_sets, length, integer(1)),
  candidate_background_overlap = vapply(gene_sets, function(g) length(intersect(g, candidate_universe)), integer(1)),
  assayed_background_overlap = vapply(gene_sets, function(g) length(intersect(g, assayed_universe)), integer(1))
)

fwrite(enrichment_all, file.path(results_dir, "route_b_b3_enrichment_all.csv"))
fwrite(enrichment_sig, file.path(results_dir, "route_b_b3_enrichment_significant_fdr005.csv"))
fwrite(top_terms, file.path(results_dir, "route_b_b3_top_terms_for_manuscript.csv"))
fwrite(ranked_terms, file.path(results_dir, "route_b_b3_ranked_terms_audit_only.csv"))
fwrite(module_summary, file.path(results_dir, "route_b_b3_module_summary.csv"))
fwrite(database_summary, file.path(results_dir, "route_b_b3_database_summary.csv"))
fwrite(gene_set_summary, file.path(results_dir, "route_b_b3_gene_set_input_summary.csv"))

for (set_name in names(gene_sets)) {
  for (db in unique(enrichment_all$database)) {
    out <- enrichment_all[gene_set == set_name & database == db & background == "candidate_background"]
    if (nrow(out) > 0) {
      fwrite(out, file.path(results_dir, paste0("route_b_b3_", tolower(db), "_", set_name, ".csv")))
    }
  }
}

plot_terms <- top_terms[database == "GO_BP"]
if (nrow(plot_terms) > 0) {
  plot_terms[, term_label := wrap_term(Description)]
  plot_terms[, term_label := factor(term_label, levels = rev(unique(term_label[order(gene_set, p.adjust)])))]
  p_go <- ggplot(plot_terms, aes(x = gene_set, y = term_label, size = Count, color = -log10(p.adjust))) +
    geom_point(alpha = 0.88) +
    scale_color_viridis_c(option = "D", na.value = "grey70") +
    labs(x = NULL, y = NULL, size = "Genes", color = "-log10(FDR)", title = "GO BP enrichment: stable vs unstable") +
    theme_minimal(base_size = 10) +
    theme(axis.text.x = element_text(angle = 12, hjust = 1))
  ggsave(file.path(fig_dir, "B3_GO_BP_candidate_background_dotplot.png"), p_go, width = 9, height = 6.5, dpi = 300)
}

module_plot <- module_summary[background == "candidate_background"]
if (nrow(module_plot) > 0) {
  module_plot[, module := factor(module, levels = rev(unique(module[order(significant_terms)])))]
  p_mod <- ggplot(module_plot, aes(x = gene_set, y = module, fill = significant_terms)) +
    geom_tile(color = "white", linewidth = 0.5) +
    facet_wrap(~ database, scales = "free_x") +
    scale_fill_viridis_c(option = "C") +
    labs(x = NULL, y = NULL, fill = "FDR<0.05 terms", title = "Significant pathway modules by gene set") +
    theme_minimal(base_size = 10) +
    theme(axis.text.x = element_text(angle = 12, hjust = 1))
  ggsave(file.path(fig_dir, "B3_significant_module_heatmap.png"), p_mod, width = 9.5, height = 5.5, dpi = 300)
}

db_plot <- database_summary[background == "candidate_background"]
if (nrow(db_plot) > 0) {
  p_db <- ggplot(db_plot, aes(x = database, y = significant_terms_fdr_005, fill = gene_set)) +
    geom_col(position = position_dodge(width = 0.75), width = 0.68) +
    labs(x = NULL, y = "FDR < 0.05 terms", title = "Enrichment yield by database") +
    theme_minimal(base_size = 10) +
    theme(axis.text.x = element_text(angle = 12, hjust = 1))
  ggsave(file.path(fig_dir, "B3_enrichment_database_yield.png"), p_db, width = 8, height = 4.8, dpi = 300)
}

stable_candidate_sig <- enrichment_sig[background == "candidate_background" & gene_set == "stable_strict_primary"]
unstable_candidate_sig <- enrichment_sig[background == "candidate_background" & gene_set == "unstable_primary"]
stable_modules <- stable_candidate_sig[, unique(module)]
unstable_modules <- unstable_candidate_sig[, unique(module)]
stable_sig_n <- nrow(stable_candidate_sig)
unstable_sig_n <- nrow(unstable_candidate_sig)
stable_non_other_n <- nrow(stable_candidate_sig[module != "other_or_unclassified"])
unstable_non_other_n <- nrow(unstable_candidate_sig[module != "other_or_unclassified"])
stable_housekeeping_n <- nrow(stable_candidate_sig[module %in% c("ribosomal_translation", "mitochondrial_oxphos", "proteostasis_ubiquitin", "rna_processing")])
stable_immune_n <- nrow(stable_candidate_sig[module %in% c("immune_inflammatory", "blood_cell_platelet_erythroid")])

gate_status <- if (stable_sig_n >= 5 && unstable_sig_n >= 5 && stable_non_other_n >= 3 && unstable_non_other_n >= 3) {
  if (stable_housekeeping_n / max(stable_sig_n, 1) > 0.75 && stable_immune_n == 0) {
    "CONDITIONAL_PASS_TO_B4"
  } else {
    "PASS_TO_B4"
  }
} else if (stable_sig_n >= 3 && stable_non_other_n >= 2) {
  "CONDITIONAL_PASS_TO_B4"
} else {
  "REVIEW_BEFORE_B4"
}

top_text <- function(dt, n = 8) {
  if (nrow(dt) == 0) return("- No terms returned.")
  paste(
    paste0(
      "- ", head(dt[order(p.adjust, pvalue)]$database, n), ": ",
      head(dt[order(p.adjust, pvalue)]$Description, n),
      " (FDR=", sprintf("%.3g", head(dt[order(p.adjust, pvalue)]$p.adjust, n)), ")"
    ),
    collapse = "\n"
  )
}

report_lines <- c(
  "# Route B B3 Pathway and Biological Interpretation Report",
  "",
  paste0("Generated at: ", now_stamp),
  "",
  "## Scope",
  "",
  "- Performed over-representation enrichment for Route B stable and unstable gene sets.",
  "- Used all S3 candidates as the primary background for stable-vs-unstable interpretation.",
  "- Recorded the all-assayed GSE63060 annotated universe size, but did not use it for the main B3 run because B3 asks whether transportable genes differ from non-transportable S3 candidates.",
  "- Databases: GO Biological Process, KEGG, and Reactome.",
  "",
  "## Input Gene Sets",
  "",
  paste(capture.output(print(gene_set_summary)), collapse = "\n"),
  "",
  "## Database Summary",
  "",
  paste(capture.output(print(database_summary)), collapse = "\n"),
  "",
  "## Significant Module Summary",
  "",
  paste(capture.output(print(module_summary)), collapse = "\n"),
  "",
  "## Candidate-Background Top Stable Terms",
  "",
  top_text(stable_candidate_sig),
  "",
  "## Candidate-Background Top Unstable Terms",
  "",
  top_text(unstable_candidate_sig),
  "",
  "## Gate B3 Decision",
  "",
  paste0("Gate B3 status: **", gate_status, "**"),
  "",
  "## Interpretation",
  "",
  paste0("- Stable strict set significant candidate-background terms: ", stable_sig_n, "."),
  paste0("- Unstable primary set significant candidate-background terms: ", unstable_sig_n, "."),
  paste0("- Stable significant modules: ", paste(stable_modules, collapse = ", "), "."),
  paste0("- Unstable significant modules: ", paste(unstable_modules, collapse = ", "), "."),
  "- The enrichment output should be framed as biology of transportable vs non-transportable transcriptional signals, not as diagnostic classifier validation.",
  "",
  "## Outputs",
  "",
  "- `results/route_b_b3_enrichment_all.csv`",
  "- `results/route_b_b3_enrichment_significant_fdr005.csv`",
  "- `results/route_b_b3_top_terms_for_manuscript.csv`",
  "- `results/route_b_b3_ranked_terms_audit_only.csv`",
  "- `results/route_b_b3_module_summary.csv`",
  "- `results/route_b_b3_database_summary.csv`",
  "- `results/route_b_b3_gene_set_input_summary.csv`",
  "- `figures/route_b/B3_GO_BP_candidate_background_dotplot.png`",
  "- `figures/route_b/B3_significant_module_heatmap.png`",
  "- `figures/route_b/B3_enrichment_database_yield.png`"
)
writeLines(report_lines, file.path(audit_dir, "route_b_b3_pathway_interpretation_report.md"), useBytes = TRUE)

gate_lines <- c(
  "# Gate B3 Pathway and Biological Interpretation Review",
  "",
  paste0("Review date: ", now_stamp),
  "",
  "## Decision",
  "",
  paste0("Gate B3 status: **", gate_status, "**"),
  "",
  "## Quantitative Basis",
  "",
  paste0("- Stable strict significant terms with candidate background: ", stable_sig_n),
  paste0("- Unstable primary significant terms with candidate background: ", unstable_sig_n),
  paste0("- Stable non-other module terms: ", stable_non_other_n),
  paste0("- Unstable non-other module terms: ", unstable_non_other_n),
  paste0("- Stable housekeeping-like significant terms: ", stable_housekeeping_n),
  paste0("- Stable immune/blood significant terms: ", stable_immune_n),
  "",
  "## Reviewer Interpretation",
  "",
  if (gate_status == "PASS_TO_B4") {
    "- Enrichment is coherent enough to support a biological interpretation of transportability differences."
  } else if (gate_status == "CONDITIONAL_PASS_TO_B4") {
    "- Enrichment is usable but should be framed cautiously because stable signals may be weighted toward broad translation/mitochondrial modules."
  } else {
    "- Enrichment is not yet sufficient for a clear biological story; revise the gene-set definition or downgrade the biological claim."
  },
  "",
  "## Required Next Step",
  "",
  "- Proceed to B4 transportability audit if the conditional framing is accepted.",
  "- Keep diagnostic-model wording out of the manuscript title, abstract, and conclusion.",
  "- Use enrichment as mechanistic context, not as independent clinical validation."
)
writeLines(gate_lines, file.path(audit_dir, "gate_b3_pathway_interpretation_review.md"), useBytes = TRUE)

print(gene_set_summary)
cat("\n")
print(database_summary)
cat("\n")
print(module_summary)
cat("\nGate B3 status:", gate_status, "\n")
