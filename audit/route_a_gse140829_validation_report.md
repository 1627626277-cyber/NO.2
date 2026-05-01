# Route A GSE140829 Final Validation Report

Generated at: 2026-05-01 06:54:22

## Scope

- GSE140829 was used as a newly frozen final validation dataset.
- No GSE140829 labels were used for feature selection or hyperparameter tuning.
- AD vs Control was the primary endpoint; MCI was evaluated only as a score-gradient check.

## Dataset Summary

   dataset_accession platform_id n_samples  n_ad n_control n_mci n_features_raw
              <char>      <char>     <int> <int>     <int> <int>          <int>
1:         GSE140829    GPL15988       551   198       229   124          15987
   n_symbols_retained missing_values duplicate_symbol_rows_removed
                <int>          <int>                         <int>
1:              15987              0                             0
                                               series_matrix_sha256
                                                             <char>
1: be4f08a2cb01fe912a764df66fd654dec70d9e1ecd36bded00b675b27e7f83f3
                                             normalized_data_sha256
                                                             <char>
1: 28613d74484a130cfe7f00034db6ae7358983adb50a1e8b01fb2d1e17ae1798b

## Model Validation Summary

                                   model_role
                                       <char>
1:                   frozen_primary_gene_only
2:                  frozen_primary_integrated
3: train_dev_refit_selected_without_gse140829
                                      model_id n_features auc_ad_vs_control
                                        <char>      <int>             <num>
1:                                sig_dev_p_k3          3         0.5542984
2:       glmnet_dev_auc_k5_a05_lambda.min_clin          5         0.5665387
3: refit_glmnet_dev_p_k100_a05_lambda.1se_gene         97         0.5692956
   auc_ci_low auc_ci_high mean_control   mean_mci    mean_ad
        <num>       <num>        <num>      <num>      <num>
1:  0.5001174   0.6042196   -0.1103455 0.06103013 0.08940096
2:  0.5127707   0.6201877    0.5501667 0.60867546 0.59801299
3:  0.5174435   0.6239281    0.5121610 0.56110013 0.56788002
   mci_between_control_ad reaches_auc_070
                   <lgcl>          <lgcl>
1:                   TRUE           FALSE
2:                  FALSE           FALSE
3:                   TRUE           FALSE

## Route A Gate Decision

Gate status: **FAIL_SWITCH_TO_ROUTE_B**

Best GSE140829 AD vs Control AUC: 0.569 (refit_glmnet_dev_p_k100_a05_lambda.1se_gene).

## Outputs

- `data/gse140829_route_a_sample_sheet.csv`
- `data/processed/GSE140829_primary_normalized_symbol_matrix.rds`
- `results/route_a_gse140829_dataset_summary.csv`
- `results/route_a_gse140829_model_validation.csv`
- `results/route_a_gse140829_model_predictions.csv`
- `results/route_a_gse140829_feature_mapping.csv`
- `figures/route_a/GSE140829_route_a_model_score_boxplot.png`
