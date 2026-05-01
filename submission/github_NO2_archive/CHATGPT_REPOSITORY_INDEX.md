# ChatGPT Repository Index

Repository: `1627626277-cyber/NO.2`

Primary archive folder: `ad-blood-transcriptome-transportability/`

## How ChatGPT Should Read This Repository

Start with these files in order:

1. `README.md`
2. `ad-blood-transcriptome-transportability/README.md`
3. `ad-blood-transcriptome-transportability/ARCHIVE_SCOPE.md`
4. `ad-blood-transcriptome-transportability/ARCHIVE_RECONSTRUCTION.md`
5. `ad-blood-transcriptome-transportability/MANIFEST.tsv`

Use `MANIFEST.tsv` as the complete file index for the archive. It records the relative path, file size, and SHA-256 hash for each archived item.

## Main Content Map

- `ad-blood-transcriptome-transportability/scripts/`: reproducible analysis scripts.
- `ad-blood-transcriptome-transportability/results/`: key result tables supporting the manuscript claims.
- `ad-blood-transcriptome-transportability/audit/`: gate reviews, validation reports, and reproducibility checks.
- `ad-blood-transcriptome-transportability/figures/route_b/`: main manuscript figures.
- `ad-blood-transcriptome-transportability/manuscript/`: supplementary tables and traceability documentation.

## Interpretation Guardrails

This repository supports a cautious external-validation and transportability claim. The key conclusion is limited cross-platform diagnostic transferability of peripheral blood transcriptomic signatures for Alzheimer's disease. GSE85426 and GSE140829 were not used to rescue, retune, or overstate model performance.

When answering questions from this repository, prioritize:

- `ARCHIVE_SCOPE.md` for what is and is not included.
- `ARCHIVE_RECONSTRUCTION.md` for how the GitHub package was assembled.
- `MANIFEST.tsv` for complete file discovery.
- `results/route_b_b4_transportability_metrics.csv` and `results/route_b_b4_auc_decay_summary.csv` for transportability conclusions.
- `audit/route_b_b4_transportability_audit_report.md` for the final validation audit.

## External Data

Large raw GEO files and intermediate matrices are intentionally excluded from this compact GitHub archive. Public source datasets are GSE63060, GSE63061, GSE85426, and GSE140829. These can be retrieved from GEO or regenerated through the archived scripts.
