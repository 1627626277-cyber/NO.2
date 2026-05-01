# S3 Candidate Gene Screening Report

Generated at: 2026-04-30 22:33:29

## Scope

- Discovery set: GSE63060 only.
- External validation datasets GSE63061 and GSE85426 were not used for feature discovery.
- Primary model: limma linear model `expression ~ diagnosis + age + gender`.
- Primary threshold: BH adjusted P < 0.05 and absolute log2 fold change >= 0.2.

## Model Summary

   dataset_accession                                        model n_samples
              <char>                                       <char>     <int>
1:          GSE63060 limma: expression ~ diagnosis + age + gender       249
    n_ad n_control n_features_tested n_zero_variance_removed
   <int>     <int>             <int>                   <int>
1:   145       104             38322                       0
   n_main_candidate_probes n_main_candidate_annotated_probes
                     <int>                             <int>
1:                     623                               546
   n_main_candidate_genes n_nominal_candidate_probes
                    <int>                      <int>
1:                    476                        640
   n_bh_005_probes_without_logfc_cutoff n_main_up n_main_down    min_adj_p
                                  <int>     <int>       <int>        <num>
1:                                 3527       155         468 3.881267e-21
          min_p
          <num>
1: 1.012804e-25

## Annotation Summary

   platform_id annotation_rows expression_features
        <char>           <int>               <int>
1:     GPL6947           49576               38322
   expression_features_with_annotation_row expression_features_with_gene_symbol
                                     <int>                                <int>
1:                                   38322                                25073

## Threshold Sensitivity

Key: <adj_p_cutoff, abs_logfc_cutoff>
    adj_p_cutoff abs_logfc_cutoff n_probes n_annotated_probes n_unique_genes
           <num>            <num>    <int>              <int>          <int>
 1:         0.01              0.0     2269               2039           1811
 2:         0.01              0.1     1678               1521           1360
 3:         0.01              0.2      594                521            453
 4:         0.01              0.3      271                227            193
 5:         0.01              0.5       98                 81             65
 6:         0.05              0.0     3527               3101           2728
 7:         0.05              0.1     2106               1909           1693
 8:         0.05              0.2      623                546            476
 9:         0.05              0.3      274                230            196
10:         0.05              0.5       98                 81             65
11:         0.10              0.0     4436               3848           3371
12:         0.10              0.1     2255               2043           1806
13:         0.10              0.2      630                551            481
14:         0.10              0.3      275                230            196
15:         0.10              0.5       98                 81             65
     n_up n_down
    <int>  <int>
 1:  1084   1185
 2:   781    897
 3:   140    454
 4:    17    254
 5:     1     97
 6:  1868   1659
 7:  1062   1044
 8:   155    468
 9:    17    257
10:     1     97
11:  2422   2014
12:  1150   1105
13:   156    474
14:    17    258
15:     1     97

## Top Gene-Level Primary Candidates

- MRPL51 (probe=ILMN_2097421, logFC=-0.554, adj.P=3.88e-21)
- NDUFA1 (probe=ILMN_1784286, logFC=-1.075, adj.P=4.66e-20)
- RPL36AL (probe=ILMN_2189936, logFC=-0.687, adj.P=4.28e-17)
- CETN2 (probe=ILMN_1695645, logFC=-0.336, adj.P=4.28e-17)
- NDUFS5 (probe=ILMN_1776104, logFC=-0.894, adj.P=9.81e-17)
- RPS25 (probe=ILMN_1746516, logFC=-0.648, adj.P=3.47e-16)
- SHFM1 (probe=ILMN_2128128, logFC=-0.940, adj.P=9.02e-16)
- ATP6V1E1 (probe=ILMN_2339779, logFC=-0.407, adj.P=9.02e-16)
- RPA3 (probe=ILMN_1716895, logFC=-0.425, adj.P=1.46e-15)
- COX17 (probe=ILMN_2187718, logFC=-0.514, adj.P=1.83e-15)
- ING3 (probe=ILMN_2237746, logFC=-0.369, adj.P=1.88e-15)
- CALML4 (probe=ILMN_1815707, logFC=-0.383, adj.P=2.22e-15)
- ATP5I (probe=ILMN_1726603, logFC=-0.716, adj.P=4.46e-15)
- RPS27A (probe=ILMN_2048326, logFC=-0.471, adj.P=6.68e-15)
- UQCRH (probe=ILMN_2232936, logFC=-0.745, adj.P=8.44e-15)
- HSPE1 (probe=ILMN_1803775, logFC=-0.726, adj.P=3.19e-14)
- TBCA (probe=ILMN_1726239, logFC=-0.618, adj.P=4.22e-14)
- RPF2 (probe=ILMN_1664167, logFC=-0.368, adj.P=1.24e-13)
- ENY2 (probe=ILMN_2166865, logFC=-0.666, adj.P=1.86e-13)
- ATP5O (probe=ILMN_1791332, logFC=-0.669, adj.P=4.17e-13)

## Outputs

- `results/s3_deg_limma_gse63060_all.csv`
- `results/s3_deg_limma_gse63060_main_threshold.csv`
- `results/s3_candidate_probes_main.csv`
- `results/s3_candidate_genes_main.csv`
- `results/s3_deg_threshold_sensitivity.csv`
- `results/s3_limma_model_summary.csv`
- `results/s3_gpl6947_annotation_summary.csv`
- `figures/s3/GSE63060_volcano.png`
- `figures/s3/GSE63060_pvalue_histogram.png`
- `figures/s3/GSE63060_ma_plot.png`
- `figures/s3/GSE63060_top50_heatmap.png`
- `audit/s3_limma_sessionInfo.txt`

## Gate 3 Preliminary Decision

PASS. Candidate discovery is sufficient for downstream validation if external validation performance is independently confirmed.

## Caveats

- Probe-level signals were collapsed to genes only after differential expression; modeling was performed at probe level.
- This step does not claim diagnostic utility. Diagnostic model construction and external validation must be completed in S4-S5.
- Batch/platform effects are not adjusted across datasets here because S3 deliberately uses only the training discovery dataset.
