# GSE85426 Post-Hoc Upper-Bound Diagnostic

Generated at: 2026-05-01 06:25:48

## Important Warning

- This analysis uses GSE85426 labels to rank or orient features.
- It is not valid as primary external validation evidence.
- It is only a diagnostic upper-bound analysis for deciding whether the dataset contains enough signal to justify redesign.

## Best Post-Hoc Signature

- Ranking: s3_oriented_by_gse85426_auc
- k: 5
- In-sample GSE85426 AUC: 0.688

## Within-GSE85426 CV Upper-Bound

                                method cv_auc_max  lambda_min  lambda_1se
                                <char>      <num>       <num>       <num>
1:   within_GSE85426_cv_glmnet_alpha_0  0.6582876 1.525488601 34.43057854
2: within_GSE85426_cv_glmnet_alpha_0.5  0.6676617 0.022548924  0.03590426
3:   within_GSE85426_cv_glmnet_alpha_1  0.6590980 0.001389968  0.03958680

## Outputs

- `results/s5_gse85426_posthoc_single_gene_upper_bound.csv`
- `results/s5_gse85426_posthoc_signature_upper_bound.csv`
- `results/s5_gse85426_within_dataset_cv_upper_bound.csv`
- `figures/s5/gse85426_posthoc_upper_bound_scan.png`
