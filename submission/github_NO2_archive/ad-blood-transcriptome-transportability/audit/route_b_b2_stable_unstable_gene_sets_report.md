# Route B B2 Stable/Unstable Gene-Set Report

Generated at: 2026-05-01 07:09:52

## Scope

- Constructed stable and unstable gene sets from frozen S3 candidates and B1 validation outputs.
- Used GSE63061 as the related-cohort anchor and GSE85426/GSE140829 as cross-platform validation cohorts.
- Did not optimize classifiers or reselect S3 candidates.

## Definitions

- Stable strict primary set: GSE63061 nominally concordant, all mapped cross-platform cohorts direction-concordant, and at least one cross-platform cohort nominally concordant.
- Stable directional sensitivity set: GSE63061 direction-concordant and all mapped cross-platform cohorts direction-concordant.
- Unstable primary set: GSE63061 nominally concordant but not strict-stable, with either cross-platform reversal or cross-platform signal loss.
- Signal loss rule: no nominal cross-platform support and cross-platform maximum oriented AUC < 0.55.

## Set Counts

                            metric n_genes
                            <char>   <int>
 1:             s3_candidate_genes     476
 2: near_cohort_directional_anchor     471
 3:     near_cohort_nominal_anchor     448
 4:          stable_strict_primary     103
 5: stable_directional_sensitivity     327
 6:               unstable_primary     235
 7:              unstable_reversal     139
 8:                unstable_vanish     190
 9:  gse85426_direction_concordant     338
10: gse140829_direction_concordant     413
11:    gse85426_nominal_concordant      35
12:   gse140829_nominal_concordant     122

## Keyword-Based Interpretability Check

Indices: <biological_keyword_category__set_name>, <set_name>
                          set_name   biological_keyword_category     N
                            <char>                        <char> <int>
 1:                 all_candidates         other_or_unclassified   314
 2:                 all_candidates         ribosomal_translation    51
 3:                 all_candidates          mitochondrial_oxphos    46
 4:                 all_candidates           immune_inflammatory    33
 5:                 all_candidates                rna_processing    16
 6:                 all_candidates        proteostasis_ubiquitin    12
 7:                 all_candidates      cell_cycle_dna_chromatin     3
 8:                 all_candidates blood_cell_platelet_erythroid     1
 9: stable_directional_sensitivity         other_or_unclassified   198
10: stable_directional_sensitivity         ribosomal_translation    46
11: stable_directional_sensitivity          mitochondrial_oxphos    37
12: stable_directional_sensitivity           immune_inflammatory    17
13: stable_directional_sensitivity                rna_processing    14
14: stable_directional_sensitivity        proteostasis_ubiquitin    11
15: stable_directional_sensitivity      cell_cycle_dna_chromatin     3
16: stable_directional_sensitivity blood_cell_platelet_erythroid     1
17:          stable_strict_primary         other_or_unclassified    56
18:          stable_strict_primary         ribosomal_translation    31
19:          stable_strict_primary          mitochondrial_oxphos     8
20:          stable_strict_primary           immune_inflammatory     5
21:          stable_strict_primary                rna_processing     2
22:          stable_strict_primary        proteostasis_ubiquitin     1
23:               unstable_primary         other_or_unclassified   167
24:               unstable_primary           immune_inflammatory    23
25:               unstable_primary          mitochondrial_oxphos    18
26:               unstable_primary         ribosomal_translation     9
27:               unstable_primary        proteostasis_ubiquitin     8
28:               unstable_primary                rna_processing     7
29:               unstable_primary      cell_cycle_dna_chromatin     2
30:               unstable_primary blood_cell_platelet_erythroid     1
                          set_name   biological_keyword_category     N
       fraction
          <num>
 1: 0.659663866
 2: 0.107142857
 3: 0.096638655
 4: 0.069327731
 5: 0.033613445
 6: 0.025210084
 7: 0.006302521
 8: 0.002100840
 9: 0.605504587
10: 0.140672783
11: 0.113149847
12: 0.051987768
13: 0.042813456
14: 0.033639144
15: 0.009174312
16: 0.003058104
17: 0.543689320
18: 0.300970874
19: 0.077669903
20: 0.048543689
21: 0.019417476
22: 0.009708738
23: 0.710638298
24: 0.097872340
25: 0.076595745
26: 0.038297872
27: 0.034042553
28: 0.029787234
29: 0.008510638
30: 0.004255319
       fraction

## Gate B2 Decision

Gate B2 status: **PASS_TO_B3**

## Interpretation

- Stable strict primary set contains 103 genes.
- Stable directional sensitivity set contains 327 genes.
- Unstable primary set contains 235 genes.
- Stable interpretable keyword fraction = 0.456.
- Stable housekeeping-like keyword fraction = 0.408.
- Stable immune/inflammatory keyword fraction = 0.049.

The B2 output is suitable for B3 enrichment if the formal enrichment analysis confirms pathway coherence.

## Outputs

- `results/route_b_stable_genes.csv`
- `results/route_b_stable_directional_sensitivity_genes.csv`
- `results/route_b_unstable_genes.csv`
- `results/route_b_b2_gene_transportability_classification.csv`
- `results/route_b_b2_overlap_table.csv`
- `results/route_b_b2_set_summary.csv`
- `results/route_b_b2_interpretability_keyword_summary.csv`
- `figures/route_b/B2_transportability_class_counts.png`
- `figures/route_b/B2_directional_overlap_counts.png`
- `figures/route_b/B2_stable_unstable_category_composition.png`
