# ChatGPT Repository Index

Repository: `1627626277-cyber/NO.2`

Primary workspace folders: `audit/`, `data/`, `figures/`, `manuscript/`, `models/`, `references/`, `results/`, `scripts/`, `submission/`

Compact archive folder: `ad-blood-transcriptome-transportability/`

## How ChatGPT Should Read This Repository

Start with these files in order:

1. `README.md`
2. `MASTER_PROJECT_PLAN.md`
3. `PROJECT_LOG.md`
4. `PROJECT_ROUTE_B_EXECUTION_PLAN.md`
5. `data/dataset_readme.md`
6. `data/data_inventory.csv`
7. `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_3_BMC_STYLE.md`
8. `submission/bmc_medical_genomics_route_b_2026-05-01/SUBMISSION_PACKAGE_INDEX.md`
9. `ad-blood-transcriptome-transportability/README.md`
10. `ad-blood-transcriptome-transportability/MANIFEST.tsv`

Use `ad-blood-transcriptome-transportability/MANIFEST.tsv` as the complete file index for the compact public archive. The root-level folders contain the full working project snapshot.

## Main Content Map

- `scripts/`: full analysis and document-building scripts.
- `data/`: sample sheets, raw public GEO downloads, and processed matrices.
- `results/`: full result tables from preprocessing, differential expression, validation, Route A, and Route B analyses.
- `audit/`: quality gates, validation reports, reproducibility checks, and sensitivity audits.
- `figures/`: QC, candidate-gene, external-validation, Route A, and Route B figures.
- `manuscript/`: manuscript drafts, supplementary tables, figure captions, and traceability files.
- `submission/`: submission-ready BMC Medical Genomics package, render QA outputs, and GitHub archive build files.
- `ad-blood-transcriptome-transportability/`: compact archive retained for public reproducibility navigation.

## Interpretation Guardrails

This repository supports a cautious external-validation and transportability claim. The key conclusion is limited cross-platform diagnostic transferability of peripheral blood transcriptomic signatures for Alzheimer's disease. GSE85426 and GSE140829 were not used to rescue, retune, or overstate model performance.

When answering questions from this repository, prioritize:

- `ARCHIVE_SCOPE.md` for what is and is not included.
- `ARCHIVE_RECONSTRUCTION.md` for how the GitHub package was assembled.
- `MANIFEST.tsv` for complete file discovery.
- `results/route_b_b4_transportability_metrics.csv` and `results/route_b_b4_auc_decay_summary.csv` for transportability conclusions.
- `audit/route_b_b4_transportability_audit_report.md` for the final validation audit.

## Large Files

The full repository includes large public GEO data files and processed matrices. Files over GitHub's regular 100 MB limit are stored with Git LFS. Public source datasets are GSE63060, GSE63061, GSE85426, and GSE140829.
