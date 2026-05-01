# S5 Leakage-Safe Model Optimization Report

Generated at: 2026-05-01 06:24:08

## Leakage Policy

- Training set: GSE63060.
- Development/model-selection set: GSE63061.
- Final validation set: GSE85426.
- GSE85426 labels were not used for primary model selection.
- Any model selected by final AUC is reported only as a post-hoc upper bound and is not paper-primary evidence.

## Selected Models

- Primary gene-only model: sig_dev_p_k3; covariates=gene_only; n_features=3; train AUC=0.875; GSE63061 AUC=0.781; GSE85426 AUC=0.567
- Primary integrated/clinical model: glmnet_dev_auc_k5_a05_lambda.min_clin; covariates=gene_plus_age_gender; n_features=5; train AUC=0.876; GSE63061 AUC=0.784; GSE85426 AUC=0.568
- Post-hoc final-AUC upper bound: glmnet_dev_nominal_concordant_auc_k100_a0_lambda.min_clin; covariates=gene_plus_age_gender; n_features=100; train AUC=0.955; GSE63061 AUC=0.783; GSE85426 AUC=0.620

## Gate 5 Preliminary Decision

REVIEW. Target final AUC threshold was 0.7.

## Interpretation

- Gene-only model does not reach the requested GSE85426 AUC threshold under leakage-safe selection.
- Integrated model also does not reach the requested GSE85426 AUC threshold under leakage-safe selection.
- The post-hoc upper-bound result is useful for feasibility diagnosis only; it cannot be used as the primary validation claim without another independent dataset.

## Additional Optimization Diagnostics

- Train+development refit selected without GSE85426 final labels: `refit_glmnet_dev_p_k100_a05_lambda.1se_gene`; combined train+development AUC = 0.843; combined CV/development selection score = 0.859; GSE85426 final AUC = 0.587.
- Train+development refit post-hoc best final model: `refit_glmnet_dev_fdr_concordant_auc_k100_a0_lambda.min_clin`; GSE85426 final AUC = 0.640. This is not a valid primary model because it is selected after observing final validation performance.
- GSE85426 label-driven post-hoc signature upper bound: best in-sample AUC = 0.688 with 5 genes. This still does not reach 0.70.
- Within-GSE85426 cross-validation upper bound using glmnet: best CV AUC = 0.668.

## S5 Decision

- The requested GSE85426 AUC >= 0.70 target was not achieved.
- This is not a simple tuning failure; multiple leakage-safe and post-hoc upper-bound checks suggest the cross-platform GSE85426 signal is intrinsically weak for the current S3 candidate set.
- Proceeding to manuscript writing as a diagnostic model paper is not recommended unless the endpoint, dataset strategy, or model claim is revised.

## Outputs

- `results/s5_model_optimization_grid.csv`
- `results/s5_primary_model_summary.csv`
- `results/s5_model_predictions.csv`
- `results/s5_glmnet_nonzero_coefficients.csv`
- `results/s5_train_dev_refit_grid.csv`
- `results/s5_train_dev_refit_summary.csv`
- `results/s5_gse85426_posthoc_signature_upper_bound.csv`
- `results/s5_gse85426_within_dataset_cv_upper_bound.csv`
- `figures/s5/selected_model_auc_comparison.png`
- `figures/s5/selected_model_score_boxplot.png`
- `figures/s5/gse85426_posthoc_upper_bound_scan.png`
- `audit/s5_sessionInfo.txt`
