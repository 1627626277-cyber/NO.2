# Figure Captions

## Figure 1. Staged validation design for the Route B transportability analysis

The analysis used GSE63060 as the discovery cohort, GSE63061 as a related validation cohort, GSE85426 as a cross-platform stress-test cohort, and GSE140829 as a large independent cross-platform validation cohort. Candidate genes and model-selection rules were frozen before the cross-platform validation steps. The figure emphasizes the separation between discovery, related-cohort validation, and independent cross-platform validation.

File: `figures/route_b/B4_main_figure1_dataset_workflow.png`

## Figure 2. Cross-cohort transportability audit of discovery-derived candidate genes

Heatmap showing mapping fraction, direction concordance, nominal replication fraction, targeted replication FDR fraction, median gene-level oriented AUC, and highest AUC among the frozen candidate models across validation cohorts. GSE63061 showed strong related-cohort replication, whereas GSE85426 and GSE140829 showed reduced FDR-level replication and model AUC values below 0.70.

File: `figures/route_b/B4_main_figure2_validation_heatmap.png`

## Figure 3. Diagnostic AUC decay and exploratory MCI score placement

The upper panel summarizes AUC values across training, related validation, and cross-platform validation contexts for the primary gene-only model, primary integrated model, and train-development refit model. The dashed line indicates the prespecified AUC threshold of 0.70. The lower panel shows GSE140829 score distributions for Control, MCI, and AD samples using the frozen primary gene-only signature. MCI placement is exploratory and was not used for model optimization.

File: `figures/route_b/B4_main_figure3_auc_and_scores.png`

## Figure 4. Pathway context of stable and unstable transportability classes

The figure compares FDR-significant GO BP, KEGG, and Reactome enrichment yields for the strict stable and unstable gene sets. Stable transportable genes showed significant enrichment dominated by ribosomal translation and RNA-processing pathways, whereas unstable genes did not show FDR-significant enrichment in GO BP, KEGG, or Reactome under the candidate-background analysis.

File: `figures/route_b/B4_main_figure4_pathway_comparison.png`
