# Gate 2 Preprocessing and QC Review

Review date: 2026-04-30  
Review role: Data Integrity Auditor + Reproducibility Auditor  
Stage: S2 Preprocessing and QC  
Conclusion: PASS

## Inputs

- `data/primary_inclusion_locked.csv`
- `data/raw/GSE63060_normalized.txt.gz`
- `data/raw/GSE63061_normalized.txt.gz`
- `data/raw/GSE85426_normalized_data.txt.gz`
- `scripts/s2_preprocess_qc.R`

## Automated QC Results

| Dataset | Role | Features retained | Samples | AD | Control | Missing values | Removed rows | Sample QC flags | Status |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|
| GSE63060 | Training | 38,322 | 249 | 145 | 104 | 0 | 2 | 0 | PASS |
| GSE63061 | External validation 1 | 32,049 | 273 | 139 | 134 | 0 | 2 | 0 | PASS |
| GSE85426 | External validation 2 | 14,113 | 180 | 90 | 90 | 0 | 0 | 0 | PASS |

## PCA Summary

| Dataset | PC1 variance | PC2 variance |
|---|---:|---:|
| GSE63060 | 25.0% | 12.3% |
| GSE63061 | 29.6% | 10.9% |
| GSE85426 | 37.6% | 21.2% |

## Cleaning Decisions

1. GSE63060 contained one malformed feature row with an ID but no expression values; it was removed.
2. GSE63060 also had one invalid/empty feature ID row after fill-aware reading; it was removed.
3. GSE63061 contained two invalid `#N/A` feature IDs; they were removed.
4. No sample was removed at S2.
5. No cross-platform concatenation, batch correction, differential expression, or model training was performed.

## Important Caveat

GSE85426 expression columns do not contain GEO sample accession IDs. They were mapped to GEO metadata by column order after confirming the expression file has exactly 180 columns and the locked sample list has exactly 180 samples. This is acceptable for S2 preprocessing, but the column-order mapping must remain documented in `data/processed/s2_expression_column_sample_map.csv`.

## Outputs

- `data/processed/GSE63060_primary_normalized_matrix.rds`
- `data/processed/GSE63061_primary_normalized_matrix.rds`
- `data/processed/GSE85426_primary_normalized_matrix.rds`
- `data/processed/s2_expression_column_sample_map.csv`
- `results/s2_qc_dataset_summary.csv`
- `results/s2_qc_sample_metrics.csv`
- `results/s2_qc_pca_summary.csv`
- `figures/qc/GSE63060_boxplot.png`
- `figures/qc/GSE63060_density.png`
- `figures/qc/GSE63060_pca.png`
- `figures/qc/GSE63061_boxplot.png`
- `figures/qc/GSE63061_density.png`
- `figures/qc/GSE63061_pca.png`
- `figures/qc/GSE85426_boxplot.png`
- `figures/qc/GSE85426_density.png`
- `figures/qc/GSE85426_pca.png`
- `audit/s2_qc_report.md`
- `audit/s2_sessionInfo.txt`

## Gate Decision

Gate 2 passes. The project may proceed to S3 candidate gene screening, with GSE63060 as the training dataset and GSE63061/GSE85426 held out for external validation.

## Required Next Actions

1. Use only `GSE63060_primary_normalized_matrix.rds` for DEG and feature discovery in S3.
2. Keep `GSE63061_primary_normalized_matrix.rds` and `GSE85426_primary_normalized_matrix.rds` untouched for external validation.
3. Do not perform feature selection on external validation datasets.
