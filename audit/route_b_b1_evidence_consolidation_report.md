# Route B B1 Evidence Consolidation Report

Generated at: 2026-05-01 11:26:03

## Scope

- Consolidated S3/S4/S5 evidence after model-level external validation failed.
- Added GSE140829 candidate-gene replication analysis using limma with diagnosis, age, sex, and batch covariates.
- Did not optimize or tune models against GSE85426 or GSE140829.

## Dataset Roles

   dataset_accession                          route_b_role
              <char>                                <char>
1:          GSE63060                    discovery_training
2:          GSE63061           related_external_validation
3:          GSE85426            cross_platform_stress_test
4:         GSE140829 large_independent_external_validation
                        platform_or_scale  n_ad n_control
                                   <char> <int>     <int>
1:              GPL6947 Illumina HT-12 v3   145       104
2:             GPL10558 Illumina HT-12 v4   139       134
3:    GPL14550 Agilent row Entrez mapping    90        90
4: GPL15988 normalized gene-symbol matrix   198       229
             diagnostic_model_status
                              <char>
1:                    discovery_only
2: strong_related_cohort_performance
3:              failed_070_threshold
4:              failed_070_threshold

## Candidate Replication Summary

Index: <dataset_accession>
   dataset_accession                       validation_role
              <char>                                <char>
1:          GSE63061           related_external_validation
2:          GSE85426            cross_platform_stress_test
3:         GSE140829 large_independent_external_validation
                      platform_or_mapping n_samples  n_ad n_control
                                   <char>     <int> <int>     <int>
1:                GPL10558 GEO annotation       273   139       134
2:     GSE85426 row-name Entrez ID suffix       180    90        90
3: GPL15988 normalized gene-symbol matrix       427   198       229
   mapped_s3_candidate_genes mapped_fraction direction_concordant
                       <int>           <num>                <int>
1:                       476       1.0000000                  471
2:                       451       0.9474790                  338
3:                       460       0.9663866                  413
   direction_concordance_rate nominal_concordant fdr_concordant auc_ge_060
                        <num>              <int>          <int>      <int>
1:                  0.9894958                448            395        394
2:                  0.7494457                 35              0         28
3:                  0.8978261                122              5          3
   median_auc_oriented max_auc_oriented
                 <num>            <num>
1:           0.6373081        0.7614088
2:           0.5370988        0.6524074
3:           0.5343721        0.6037449

## Model AUC Summary

                        model_role                                    model_id
                            <char>                                      <char>
 1:              primary_gene_only                                sig_dev_p_k3
 2:              primary_gene_only                                sig_dev_p_k3
 3:              primary_gene_only                                sig_dev_p_k3
 4:              primary_gene_only                                sig_dev_p_k3
 5: primary_integrated_or_clinical       glmnet_dev_auc_k5_a05_lambda.min_clin
 6: primary_integrated_or_clinical       glmnet_dev_auc_k5_a05_lambda.min_clin
 7: primary_integrated_or_clinical       glmnet_dev_auc_k5_a05_lambda.min_clin
 8: primary_integrated_or_clinical       glmnet_dev_auc_k5_a05_lambda.min_clin
 9:       train_dev_refit_selected refit_glmnet_dev_p_k100_a05_lambda.1se_gene
10:       train_dev_refit_selected refit_glmnet_dev_p_k100_a05_lambda.1se_gene
11:       train_dev_refit_selected refit_glmnet_dev_p_k100_a05_lambda.1se_gene
    dataset_accession             evaluation_context       auc reaches_070
               <char>                         <char>     <num>      <lgcl>
 1:          GSE63060                       training 0.8751326        TRUE
 2:          GSE63061          development_selection 0.7805755        TRUE
 3:          GSE85426           external_stress_test 0.5666667       FALSE
 4:         GSE140829 sequential_external_validation 0.5542984       FALSE
 5:          GSE63060                       training 0.8755968        TRUE
 6:          GSE63061          development_selection 0.7844948        TRUE
 7:          GSE85426           external_stress_test 0.5682716       FALSE
 8:         GSE140829 sequential_external_validation 0.5665387       FALSE
 9: GSE63060+GSE63061        combined_refit_training 0.8429844        TRUE
10:          GSE85426           external_stress_test 0.5866667       FALSE
11:         GSE140829 sequential_external_validation 0.5692956       FALSE

## B1 Gate Decision

Gate B1 status: **PASS_ROUTE_B_FRAMING**

## Interpretation

- GSE63061 shows strong related-cohort replication, supporting that the S3 signal is not purely random within AddNeuroMed-like blood data.
- GSE85426 and GSE140829 show markedly weaker single-gene and model-level transportability.
- The evidence supports cohort-dependent reproducibility with limited independent-validation transferability.

## Outputs

- `results/route_b_b1_gse140829_candidate_replication.csv`
- `results/route_b_b1_replication_summary.csv`
- `results/route_b_b1_dataset_role_summary.csv`
- `results/route_b_b1_model_auc_long.csv`
- `results/route_b_b1_evidence_dashboard.csv`
- `figures/route_b/B1_model_auc_decay.png`
- `figures/route_b/B1_mapping_direction_concordance.png`
- `figures/route_b/B1_concordant_replication_counts.png`
- `figures/route_b/B1_candidate_oriented_auc_distribution.png`
