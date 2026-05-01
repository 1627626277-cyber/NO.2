# S5 Train+Development Refit Final Validation

Generated at: 2026-05-01 06:29:29

## Policy

- Model families/features came from the prior GSE63060 -> GSE63061 development grid.
- GSE63060 and GSE63061 were combined for refitting.
- GSE85426 was used only for final validation.
- Selected refit model was chosen by combined CV/development score, not by GSE85426 final AUC.

## Selected Refit Model

- Model: refit_glmnet_dev_p_k100_a05_lambda.1se_gene
- Covariate mode: gene_only
- Features: 100
- Combined train+development AUC: 0.843
- Combined CV/development selection score: 0.859
- GSE85426 final AUC: 0.587

## Post-Hoc Best Final Refit Model

- Model: refit_glmnet_dev_fdr_concordant_auc_k100_a0_lambda.min_clin
- Covariate mode: gene_plus_age_gender
- Features: 100
- GSE85426 final AUC: 0.640

## Interpretation

- Leakage-safe train+development refit does not reach the requested 0.70 final AUC threshold.
- The post-hoc best final refit is not a valid primary selection if it differs from the selected refit model.
