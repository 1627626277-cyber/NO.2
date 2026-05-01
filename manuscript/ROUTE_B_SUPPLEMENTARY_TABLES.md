# Supplementary Table Plan

## Supplementary Table S1. Dataset inventory and inclusion criteria

Source files:

- `data/data_inventory.csv`
- `data/sample_sheet.csv`
- `data/primary_inclusion_locked.csv`
- `audit/s1_sample_summary.csv`

Purpose:
Document dataset accession, platform, raw file source, checksum, sample labels, and inclusion/exclusion criteria.

## Supplementary Table S2. QC summaries

Source files:

- `results/s2_qc_dataset_summary.csv`
- `results/s2_qc_sample_metrics.csv`
- `results/s2_qc_pca_summary.csv`

Purpose:
Document feature counts, sample counts, missingness, PCA summaries, and QC flags.

## Supplementary Table S3. Discovery differential-expression results

Source files:

- `results/s3_deg_limma_gse63060_all.csv`
- `results/s3_candidate_genes_main.csv`

Purpose:
Provide all GSE63060 differential-expression statistics and frozen candidate genes.

## Supplementary Table S4. External validation of candidate genes

Source files:

- `results/s4_candidate_external_validation.csv`
- `results/route_b_b1_gse140829_candidate_replication.csv`

Purpose:
Provide gene-level mapping, log fold-change, P values, FDR values, direction concordance, and oriented AUC in validation cohorts.

## Supplementary Table S5. Model and signature performance

Source files:

- `results/s5_primary_model_summary.csv`
- `results/s5_train_dev_refit_summary.csv`
- `results/route_a_gse140829_model_validation.csv`
- `results/route_b_b4_auc_decay_summary.csv`
- `results/route_b_auc_ci_summary.csv`

Purpose:
Document primary models, refit models, leakage classification, feature counts, AUC values, 95% confidence intervals, and independent-validation degradation.

## Supplementary Table S6. Stable and unstable gene sets

Source files:

- `results/route_b_stable_genes.csv`
- `results/route_b_stable_directional_sensitivity_genes.csv`
- `results/route_b_unstable_genes.csv`
- `results/route_b_b2_gene_transportability_classification.csv`

Purpose:
Document gene-set classification rules and membership.

## Supplementary Table S7. Pathway enrichment results

Source files:

- `results/route_b_b3_enrichment_all.csv`
- `results/route_b_b3_enrichment_significant_fdr005.csv`
- `results/route_b_b3_top_terms_for_manuscript.csv`

Purpose:
Provide full GO BP, KEGG, and Reactome enrichment results for stable and unstable sets.

## Supplementary Table S8. Interpretation audit and manuscript safeguards

Source files:

- `results/route_b_b4_manuscript_claim_audit.csv`
- `results/route_b_b5_claim_evidence_matrix.csv`

Purpose:
Document which manuscript statements are supported, which require caution, and which overstatements should be avoided.

## Supplementary Table S9. Reproducibility traceability table

Source files:

- `manuscript/ROUTE_B_REPRODUCIBILITY_TRACEABILITY_TABLE_V1_2.md`
- `scripts/`
- `results/`
- `audit/`

Purpose:
Map each main manuscript claim to the exact script, result file, figure, and audit record that supports it.

## Supplementary Table S10. Demographic and mapping audit

Source files:

- `results/route_b_demographic_mapping_audit.csv`
- `audit/s12_auc_ci_and_demographic_audit.md`

Purpose:
Summarize AD/control/MCI counts, age and sex availability, platform identifiers, mapped and unmapped candidate-gene counts, mapping fraction, concordance metrics, targeted replication FDR-concordant genes, mapping-audit notes, and highest AUC among the frozen candidate models by dataset.

## Supplementary Table S11. Blood-cell marker-score sensitivity analysis

Source files:

- `results/blood_cell_marker_sensitivity_summary.csv`
- `results/blood_cell_marker_sensitivity_gene_level.csv`
- `results/blood_cell_marker_coverage.csv`
- `results/blood_cell_marker_sensitivity_model_terms.csv`
- `audit/s13_blood_cell_marker_sensitivity.md`

Purpose:
Summarize neutrophil, monocyte, and lymphocyte marker coverage and compare strict stable-gene direction and nominal concordance before and after marker-score adjustment.
