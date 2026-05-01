# S13 Blood-cell marker-score sensitivity analysis

Generated: 2026-05-01 12:16:23

## Scope

- This is a lightweight marker-score sensitivity analysis, not formal cell-type deconvolution.
- Neutrophil, monocyte, and lymphocyte proxy scores were calculated as within-cohort mean z-scores of available marker genes.
- Strict stable genes were re-tested with diagnosis, available age/sex covariates, GSE140829 batch where applicable, and the three marker scores.
- The analysis checks whether stable-gene directionality is obviously explained away by broad blood-cell marker scores.

## Marker Coverage

- GSE63061 neutrophil: 8/8 marker genes available.
- GSE63061 monocyte: 8/8 marker genes available.
- GSE63061 lymphocyte: 7/8 marker genes available.
- GSE85426 neutrophil: 4/8 marker genes available.
- GSE85426 monocyte: 7/8 marker genes available.
- GSE85426 lymphocyte: 7/8 marker genes available.
- GSE140829 neutrophil: 8/8 marker genes available.
- GSE140829 monocyte: 8/8 marker genes available.
- GSE140829 lymphocyte: 7/8 marker genes available.

## Sensitivity Summary

- GSE63061: strict stable genes mapped=103; direction concordance base=1.000, marker-adjusted=1.000; nominal concordant base=103, marker-adjusted=97; same base/adjusted direction=1.000; median absolute logFC change=0.054.
- GSE85426: strict stable genes mapped=100; direction concordance base=1.000, marker-adjusted=0.690; nominal concordant base=31, marker-adjusted=12; same base/adjusted direction=0.690; median absolute logFC change=0.103.
- GSE140829: strict stable genes mapped=102; direction concordance base=1.000, marker-adjusted=0.971; nominal concordant base=82, marker-adjusted=26; same base/adjusted direction=0.971; median absolute logFC change=0.033.

## Interpretation

- Marker-score adjustment did not convert the independent-validation model findings into a positive diagnostic result.
- Directional stability of the strict stable gene set was retained in GSE63061, mostly preserved in GSE140829, and attenuated in GSE85426.
- Because marker scores are only coarse proxies and GSE85426 showed attenuation after adjustment, residual blood-cell-composition confounding remains a limitation.

## Outputs

- `results/blood_cell_marker_sensitivity_summary.csv`
- `results/blood_cell_marker_sensitivity_gene_level.csv`
- `results/blood_cell_marker_coverage.csv`
- `results/blood_cell_marker_sensitivity_model_terms.csv`
