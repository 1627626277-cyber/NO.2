# S2 Preprocessing and QC Report

Generated at: 2026-04-30 22:21:32

## Scope

- Used locked AD/Control sample list from `data/primary_inclusion_locked.csv`.
- Read normalized expression files only; no cross-platform merging, ComBat, or disease modeling was performed at S2.
- Saved one primary normalized matrix per dataset as RDS.

## Dataset QC Summary

   dataset_accession platform_id                  role   match_mode
              <char>      <char>                <char>       <char>
1:          GSE63060     GPL6947    training_candidate sample_title
2:          GSE63061    GPL10558 external_validation_1 sample_title
3:          GSE85426    GPL14550 external_validation_2 column_order
   raw_feature_rows removed_invalid_feature_ids removed_all_missing_expression
              <int>                       <int>                          <int>
1:            38324                           1                              1
2:            32051                           2                              0
3:            14113                           0                              0
   removed_total_feature_rows n_features n_samples  n_ad n_control
                        <int>      <int>     <int> <int>     <int>
1:                          2      38322       249   145       104
2:                          2      32049       273   139       134
3:                          0      14113       180    90        90
   missing_values missing_fraction duplicate_feature_ids zero_variance_features
            <int>            <num>                 <int>                  <int>
1:              0                0                     0                      0
2:              0                0                     0                      0
3:              0                0                     0                      0
   global_min  global_q1 global_median global_mean global_q3 global_max
        <num>      <num>         <num>       <num>     <num>      <num>
1:   7.204489  7.4509681      7.543224  7.91215286 7.8538132   15.04979
2:   3.926741  6.0552570      6.156383  6.60569657 6.6873316   14.77843
3: -10.599529 -0.5290862      0.000000 -0.02311384 0.4931484   12.00180
   samples_flagged_review qc_status
                    <int>    <char>
1:                      0      PASS
2:                      0      PASS
3:                      0      PASS

## PCA Variance Summary

   dataset_accession pc1_variance pc2_variance
              <char>        <num>        <num>
1:          GSE63060    0.2500120    0.1231618
2:          GSE63061    0.2963486    0.1094726
3:          GSE85426    0.3764430    0.2117306

## Important Notes

- GSE63060 and GSE63061 expression columns were matched to GEO metadata by `sample_title`.
- GSE85426 expression columns were matched by column order because GEO metadata does not provide expression filename-to-GSM mapping in the series matrix.
- GSE85426 values are on a different processed scale from the AddNeuroMed Illumina datasets, so cross-dataset matrix concatenation is not allowed at this stage.

## Outputs

- `data/processed/GSE63060_primary_normalized_matrix.rds`
- `data/processed/GSE63061_primary_normalized_matrix.rds`
- `data/processed/GSE85426_primary_normalized_matrix.rds`
- `data/processed/s2_expression_column_sample_map.csv`
- `results/s2_qc_dataset_summary.csv`
- `results/s2_qc_sample_metrics.csv`
- `results/s2_qc_pca_summary.csv`
- `figures/qc/*_boxplot.png`, `*_density.png`, `*_pca.png`
- `audit/s2_sessionInfo.txt`

## Gate 2 Preliminary Decision

PASS at the automated QC level. Proceed to manual inspection of QC figures before S3.
