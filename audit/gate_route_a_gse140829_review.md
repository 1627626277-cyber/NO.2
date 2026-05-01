# Route A Gate Review: GSE140829 Rescue Validation

Review date: 2026-05-01 06:54:22

## Decision

Route A status: **FAIL_SWITCH_TO_ROUTE_B**

## Quantitative Basis

- frozen_primary_gene_only: AUC=0.554 (95% CI 0.500-0.604); features=3
- frozen_primary_integrated: AUC=0.567 (95% CI 0.513-0.620); features=5
- train_dev_refit_selected_without_gse140829: AUC=0.569 (95% CI 0.517-0.624); features=97

## Required Next Step

- Switch to Route B. Do not keep optimizing classifiers against GSE140829.
