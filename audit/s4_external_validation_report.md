# S4 External Validation and Candidate Stability Report

Generated at: 2026-04-30 23:00:03

## Scope

- Validation datasets: GSE63061 and GSE85426.
- S3 candidate threshold and ranking were frozen before validation.
- Validation was performed at Entrez gene level to avoid invalid cross-platform probe matching.
- Repeated validation probes per gene were collapsed by highest within-dataset variance.
- Primary validation model per dataset: limma linear model `expression ~ diagnosis + age + gender`.

## Dataset Summary

   dataset_accession                         map_source n_samples  n_ad
              <char>                             <char>     <int> <int>
1:          GSE63061            GPL10558 GEO annotation       273   139
2:          GSE85426 GSE85426 row-name Entrez ID suffix       180    90
   n_control original_features mapped_gene_rows_before_collapse
       <int>             <int>                            <int>
1:       134             32049                            22296
2:        90             14113                            10775
   collapsed_unique_genes s3_candidate_genes_with_entrez
                    <int>                          <int>
1:                  16030                            476
2:                  10775                            476
   mapped_s3_candidate_genes mapped_fraction direction_concordant
                       <int>           <num>                <int>
1:                       476        1.000000                  471
2:                       451        0.947479                  338
   direction_concordance_rate nominal_concordant fdr_concordant auc_ge_060
                        <num>              <int>          <int>      <int>
1:                  0.9894958                448            395        394
2:                  0.7494457                 35              0         28
   median_auc_oriented max_auc_oriented
                 <num>            <num>
1:           0.6373081        0.7614088
2:           0.5370988        0.6524074

## Signed Signature Score Summary

Index: <signature_size_label>
   dataset_accession signature_size_label n_features auc_oriented    mean_ad
              <char>               <char>      <int>        <num>      <num>
1:          GSE63061                top20         20    0.7512617 0.36192274
2:          GSE63061                top50         50    0.7424568 0.33601838
3:          GSE63061               top100        100    0.7305916 0.30776978
4:          GSE63061           all_mapped        476    0.7032106 0.23825936
5:          GSE85426                top20         20    0.5829630 0.08293253
6:          GSE85426                top50         50    0.5769136 0.07641899
7:          GSE85426               top100        100    0.5754321 0.06571458
8:          GSE85426           all_mapped        451    0.5930864 0.04805269
   mean_control ad_minus_control     t_test_p
          <num>            <num>        <num>
1:  -0.37542732       0.73735006 1.011660e-14
2:  -0.34855638       0.68457477 1.391531e-12
3:  -0.31925373       0.62702351 2.941612e-11
4:  -0.24714964       0.48540900 5.259421e-09
5:  -0.08293253       0.16586507 9.440215e-02
6:  -0.07641899       0.15283797 1.085465e-01
7:  -0.06571458       0.13142916 1.411163e-01
8:  -0.04805269       0.09610538 8.078552e-02

## Highest Single-Gene Oriented AUC Candidates

- GSE63061: NDUFA1 (Entrez=4694, validation effect=-0.484, P=2.16e-14, oriented AUC=0.761, direction=concordant)
- GSE63061: NDUFS5 (Entrez=4725, validation effect=-0.411, P=2.16e-13, oriented AUC=0.761, direction=concordant)
- GSE63061: RPL36AL (Entrez=6166, validation effect=-0.435, P=1.43e-14, oriented AUC=0.755, direction=concordant)
- GSE63061: RPS25 (Entrez=6230, validation effect=-0.445, P=4.58e-14, oriented AUC=0.753, direction=concordant)
- GSE63061: CETN2 (Entrez=1069, validation effect=-0.183, P=2.85e-14, oriented AUC=0.749, direction=concordant)
- GSE63061: UFC1 (Entrez=51506, validation effect=-0.216, P=2.99e-13, oriented AUC=0.742, direction=concordant)
- GSE63061: MRPL51 (Entrez=51258, validation effect=-0.281, P=3.65e-13, oriented AUC=0.740, direction=concordant)
- GSE63061: RPA3 (Entrez=6119, validation effect=-0.247, P=5.59e-11, oriented AUC=0.736, direction=concordant)
- GSE63061: UQCRH (Entrez=7388, validation effect=-0.398, P=1.03e-11, oriented AUC=0.735, direction=concordant)
- GSE63061: COX17 (Entrez=10063, validation effect=-0.247, P=2.93e-12, oriented AUC=0.731, direction=concordant)
- GSE85426: BEX2 (Entrez=84707, validation effect=-0.178, P=8.65e-02, oriented AUC=0.652, direction=concordant)
- GSE85426: LSM5 (Entrez=23658, validation effect=-0.232, P=1.41e-02, oriented AUC=0.645, direction=concordant)
- GSE85426: PGS1 (Entrez=9489, validation effect=0.410, P=1.98e-04, oriented AUC=0.640, direction=concordant)
- GSE85426: CD3D (Entrez=915, validation effect=-0.267, P=7.13e-03, oriented AUC=0.634, direction=concordant)
- GSE85426: CKS1B (Entrez=1163, validation effect=-0.247, P=7.88e-03, oriented AUC=0.633, direction=concordant)
- GSE85426: RBX1 (Entrez=9978, validation effect=-0.276, P=6.68e-03, oriented AUC=0.633, direction=concordant)
- GSE85426: POLE4 (Entrez=56655, validation effect=-0.235, P=1.21e-02, oriented AUC=0.624, direction=concordant)
- GSE85426: COMMD6 (Entrez=170622, validation effect=-0.242, P=2.87e-02, oriented AUC=0.621, direction=concordant)
- GSE85426: SNRPD2 (Entrez=6633, validation effect=-0.330, P=6.29e-03, oriented AUC=0.620, direction=concordant)
- GSE85426: SOD1 (Entrez=6647, validation effect=-0.280, P=1.53e-02, oriented AUC=0.619, direction=concordant)

## Outputs

- `results/s4_candidate_external_validation.csv`
- `results/s4_external_validation_dataset_summary.csv`
- `results/s4_gene_mapping_selected_representatives.csv`
- `results/s4_signature_score_summary.csv`
- `results/s4_signature_sample_scores.csv`
- `results/s4_annotation_resource_summary.csv`
- `figures/s4/*_s3_vs_validation_effect.png`
- `figures/s4/*_signature_score_boxplot.png`
- `figures/s4/signature_auc_barplot.png`
- `audit/s4_sessionInfo.txt`

## Gate 4 Preliminary Decision

CONDITIONAL PASS. External validation evidence is evaluated by mapping coverage and top50 signed signature AUC.

## Caveats

- GSE63061 and GSE85426 use different platforms from GSE63060; validation is gene-level rather than identical-probe validation.
- GSE85426 mapping uses Entrez IDs embedded in expression row names because no standard GEO platform annotation file is available at the expected FTP annot path.
- S4 evaluates transportability of frozen S3 candidates; formal diagnostic model development remains S5.
