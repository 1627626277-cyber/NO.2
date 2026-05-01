# Gate 5 Model Optimization Review

Review date: 2026-05-01 06:24:08

## Decision

Gate 5 status: **REVIEW**

## Quantitative Basis

- Primary gene-only model: sig_dev_p_k3; covariates=gene_only; n_features=3; train AUC=0.875; GSE63061 AUC=0.781; GSE85426 AUC=0.567
- Primary integrated/clinical model: glmnet_dev_auc_k5_a05_lambda.min_clin; covariates=gene_plus_age_gender; n_features=5; train AUC=0.876; GSE63061 AUC=0.784; GSE85426 AUC=0.568
- Post-hoc final-AUC upper bound: glmnet_dev_nominal_concordant_auc_k100_a0_lambda.min_clin; covariates=gene_plus_age_gender; n_features=100; train AUC=0.955; GSE63061 AUC=0.783; GSE85426 AUC=0.620
- Train+development refit selected without GSE85426 labels: gene-only 100-feature glmnet; combined CV/development selection score=0.859; GSE85426 AUC=0.587
- Train+development refit post-hoc best final model: gene+age/gender 100-feature ridge glmnet; GSE85426 AUC=0.640
- GSE85426 label-driven signature upper bound: in-sample AUC=0.688
- GSE85426 within-dataset glmnet CV upper bound: best CV AUC=0.668

## Interpretation

- The requested GSE85426 AUC >= 0.70 target was not achieved.
- Because even label-driven and within-dataset upper-bound checks remain below 0.70, the current candidate set does not support a robust cross-platform diagnostic model.
- Advancing as a diagnostic-model manuscript would be high risk without redesign.

## Required Next Step

- Stop the default downstream writing path.
- Reassess endpoint, dataset strategy, or paper framing before enrichment/PPI/manuscript drafting.
