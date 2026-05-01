# Gate 4 External Validation Review

Review date: 2026-04-30 23:00:03

## Decision

Gate 4 status: **CONDITIONAL PASS**

## Checks

- Validation datasets were not used to change S3 thresholds: PASS.
- Cross-platform validation used Entrez gene-level mapping: PASS.
- Age and gender covariates included in validation differential models: PASS.
- Direction concordance, nominal significance, FDR significance, single-gene AUC and signature AUC exported: PASS.

## Quantitative Basis

- GSE63061: mapped candidate genes = 476; direction concordance = 0.989; nominal concordant = 448; FDR concordant = 395; median oriented AUC = 0.637; max oriented AUC = 0.761
- GSE85426: mapped candidate genes = 451; direction concordance = 0.749; nominal concordant = 35; FDR concordant = 0; median oriented AUC = 0.537; max oriented AUC = 0.652

## Required Next Step

- If Gate 4 is PASS or CONDITIONAL PASS, proceed to biological interpretation and/or model construction using only frozen feature rules.
- If Gate 4 is REVIEW, revisit project feasibility before investing in downstream paper writing.
