# Route B B4 Transportability Audit Report

Generated at: 2026-05-01 12:10:51

## Scope

- Consolidated mapping, direction concordance, nominal replication, targeted replication FDR, frozen model AUC decay, MCI placement, and pathway-yield evidence.
- Built main-figure drafts for a limited-transferability manuscript.
- Did not tune or refit classifiers.

## Transportability Metrics

Key: <dataset_accession>
   dataset_accession                       validation_role
              <char>                                <char>
1:         GSE140829 large_independent_external_validation
2:          GSE63061           related_external_validation
3:          GSE85426            cross_platform_stress_test
                      platform_or_mapping n_samples  n_ad n_control
                                   <char>     <int> <int>     <int>
1: GPL15988 normalized gene-symbol matrix       427   198       229
2:                GPL10558 GEO annotation       273   139       134
3:     GSE85426 row-name Entrez ID suffix       180    90        90
   mapped_s3_candidate_genes mapped_fraction direction_concordance_rate
                       <int>           <num>                      <num>
1:                       460       0.9663866                  0.8978261
2:                       476       1.0000000                  0.9894958
3:                       451       0.9474790                  0.7494457
   nominal_concordant nominal_fraction fdr_concordant fdr_fraction
                <int>            <num>          <int>        <num>
1:                122       0.26521739              5   0.01086957
2:                448       0.94117647            395   0.82983193
3:                 35       0.07760532              0   0.00000000
   median_auc_oriented max_auc_oriented best_frozen_model_auc
                 <num>            <num>                 <num>
1:           0.5343721        0.6037449             0.5692956
2:           0.6373081        0.7614088             0.7844948
3:           0.5370988        0.6524074             0.5866667
   any_model_reaches_070        external_validity_status
                  <lgcl>                          <char>
1:                 FALSE independent_validation_degraded
2:                  TRUE        near_cohort_reproducible
3:                 FALSE independent_validation_degraded
                                                                                  route_b_interpretation
                                                                                                  <char>
1: Independent-validation transferability is limited; model performance should be treated as cautionary.
2:                              Related-cohort signal is reproducible and supports non-random discovery.
3: Independent-validation transferability is limited; model performance should be treated as cautionary.
   direction_concordant auc_ge_060 auc_ge_060_fraction
                  <int>      <int>               <num>
1:                  413          3         0.006521739
2:                  471        394         0.827731092
3:                  338         28         0.062084257

## AUC Decay Summary

Key: <model_role, model_id, covariate_mode>
                       model_role                                    model_id
                           <char>                                      <char>
1:              primary_gene_only                                sig_dev_p_k3
2: primary_integrated_or_clinical       glmnet_dev_auc_k5_a05_lambda.min_clin
3:       train_dev_refit_selected refit_glmnet_dev_p_k100_a05_lambda.1se_gene
         covariate_mode GSE140829  GSE63060 GSE63060+GSE63061  GSE63061
                 <char>     <num>     <num>             <num>     <num>
1:            gene_only 0.5542984 0.8751326                NA 0.7805755
2: gene_plus_age_gender 0.5665387 0.8755968                NA 0.7844948
3:            gene_only 0.5692956        NA         0.8429844        NA
    GSE85426 dev_to_gse85426_delta dev_to_gse140829_delta
       <num>                 <num>                  <num>
1: 0.5666667             0.2139089              0.2262771
2: 0.5682716             0.2162232              0.2179560
3: 0.5866667                    NA                     NA
   independent_validation_best_auc independent_validation_reaches_070
                             <num>                             <lgcl>
1:                       0.5666667                              FALSE
2:                       0.5682716                              FALSE
3:                       0.5866667                              FALSE

## MCI Score Gradient

                                   model_role
                                       <char>
1:                   frozen_primary_gene_only
2:                  frozen_primary_integrated
3: train_dev_refit_selected_without_gse140829
                                      model_id auc_ad_vs_control auc_ci_low
                                        <char>             <num>      <num>
1:                                sig_dev_p_k3         0.5542984  0.5001174
2:       glmnet_dev_auc_k5_a05_lambda.min_clin         0.5665387  0.5127707
3: refit_glmnet_dev_p_k100_a05_lambda.1se_gene         0.5692956  0.5174435
   auc_ci_high mean_control   mean_mci    mean_ad mci_between_control_ad
         <num>        <num>      <num>      <num>                 <lgcl>
1:   0.6042196   -0.1103455 0.06103013 0.08940096                   TRUE
2:   0.6201877    0.5501667 0.60867546 0.59801299                  FALSE
3:   0.6239281    0.5121610 0.56110013 0.56788002                   TRUE
   reaches_auc_070                   mci_position
            <lgcl>                         <char>
1:           FALSE     MCI_between_Control_and_AD
2:           FALSE MCI_not_between_Control_and_AD
3:           FALSE     MCI_between_Control_and_AD

## B4 Gate Summary

                         criterion   pass
                            <char> <lgcl>
1:        near_cohort_reproducible   TRUE
2: independent_validation_degraded   TRUE
3:                 auc_decay_clear   TRUE
4:    mci_gradient_partial_support   TRUE
5:     pathway_context_conditional   TRUE
                                                                                             evidence
                                                                                               <char>
1:                   GSE63061 direction=0.989, targeted FDR genes=395, highest frozen-model AUC=0.784
2:                    GSE85426/GSE140829 highest frozen-model AUC=0.587/0.569; targeted FDR genes=0/5
3:                        Primary model development-to-independent-validation AUC deltas exceed 0.15.
4:                           2 of 3 GSE140829 model score summaries place MCI between Control and AD.
5: Stable genes have significant pathway enrichment while unstable genes have no FDR<0.05 enrichment.

## Gate B4 Decision

Gate B4 status: **PASS_TO_B5_Q4_FRAMING**

## Interpretation

- The evidence clearly supports related-cohort reproducibility and independent-validation degradation.
- The manuscript should frame modeling as an external-validation cautionary result.
- MCI score placement is partial support only and should not be elevated to a primary claim.
- Pathway evidence is useful context for stable transportable genes but remains conservative.

## Outputs

- `results/route_b_b4_transportability_metrics.csv`
- `results/route_b_b4_auc_decay_summary.csv`
- `results/route_b_b4_mci_score_gradient.csv`
- `results/route_b_b4_top50_signature_score_summary.csv`
- `results/route_b_b4_pathway_yield_summary.csv`
- `results/route_b_b4_main_figure_plan.csv`
- `results/route_b_b4_manuscript_claim_audit.csv`
- `results/route_b_b4_gate_summary.csv`
- `figures/route_b/B4_main_figure1_dataset_workflow.png`
- `figures/route_b/B4_main_figure2_validation_heatmap.png`
- `figures/route_b/B4_main_figure3_auc_and_scores.png`
- `figures/route_b/B4_main_figure4_pathway_comparison.png`
