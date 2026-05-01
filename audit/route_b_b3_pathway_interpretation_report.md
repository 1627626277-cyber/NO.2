# Route B B3 Pathway and Biological Interpretation Report

Generated at: 2026-05-01 08:17:08

## Scope

- Performed over-representation enrichment for Route B stable and unstable gene sets.
- Used all S3 candidates as the primary background for stable-vs-unstable interpretation.
- Recorded the all-assayed GSE63060 annotated universe size, but did not use it for the main B3 run because B3 asks whether transportable genes differ from non-transportable S3 candidates.
- Databases: GO Biological Process, KEGG, and Reactome.

## Input Gene Sets

                         gene_set input_entrez_genes
                           <char>              <int>
1:          stable_strict_primary                103
2: stable_directional_sensitivity                327
3:               unstable_primary                235
   candidate_background_overlap assayed_background_overlap
                          <int>                      <int>
1:                          103                        103
2:                          327                        327
3:                          235                        235

## Database Summary

Index: <background>
             background                       gene_set database tested_terms
                 <char>                         <char>   <char>        <int>
1: candidate_background stable_directional_sensitivity    GO_BP         1045
2: candidate_background stable_directional_sensitivity     KEGG           85
3: candidate_background stable_directional_sensitivity Reactome          326
4: candidate_background          stable_strict_primary    GO_BP          900
5: candidate_background          stable_strict_primary     KEGG           59
6: candidate_background          stable_strict_primary Reactome          308
7: candidate_background               unstable_primary    GO_BP         1039
8: candidate_background               unstable_primary     KEGG           84
9: candidate_background               unstable_primary Reactome          326
   significant_terms_fdr_005      min_fdr
                       <int>        <num>
1:                         0 7.552529e-02
2:                         2 1.231207e-02
3:                        45 4.801177e-04
4:                        12 4.647918e-06
5:                         2 2.489618e-06
6:                        52 2.383809e-08
7:                         0 2.242052e-01
8:                         0 8.732691e-01
9:                         0 1.258295e-01

## Significant Module Summary

Index: <background>
              background                       gene_set database
                  <char>                         <char>   <char>
 1: candidate_background stable_directional_sensitivity     KEGG
 2: candidate_background stable_directional_sensitivity     KEGG
 3: candidate_background stable_directional_sensitivity Reactome
 4: candidate_background stable_directional_sensitivity Reactome
 5: candidate_background stable_directional_sensitivity Reactome
 6: candidate_background          stable_strict_primary    GO_BP
 7: candidate_background          stable_strict_primary    GO_BP
 8: candidate_background          stable_strict_primary    GO_BP
 9: candidate_background          stable_strict_primary     KEGG
10: candidate_background          stable_strict_primary     KEGG
11: candidate_background          stable_strict_primary Reactome
12: candidate_background          stable_strict_primary Reactome
13: candidate_background          stable_strict_primary Reactome
                   module significant_terms      min_fdr median_gene_ratio
                   <char>             <int>        <num>             <num>
 1: ribosomal_translation                 1 1.231207e-02         0.2330097
 2: other_or_unclassified                 1 1.231207e-02         0.1844660
 3:        rna_processing                 7 4.801177e-04         0.1591837
 4: other_or_unclassified                21 4.801177e-04         0.1591837
 5: ribosomal_translation                17 4.801177e-04         0.1469388
 6: ribosomal_translation                 7 4.647918e-06         0.1041667
 7:        rna_processing                 3 4.188909e-05         0.1875000
 8: other_or_unclassified                 2 2.381129e-03         0.0937500
 9: other_or_unclassified                 1 2.489618e-06         0.3466667
10: ribosomal_translation                 1 1.086788e-04         0.3733333
11: ribosomal_translation                18 2.383809e-08         0.2976190
12: other_or_unclassified                27 2.383809e-08         0.3095238
13:        rna_processing                 7 2.383809e-08         0.3214286

## Candidate-Background Top Stable Terms

- Reactome: Eukaryotic Translation Elongation (FDR=2.38e-08)
- Reactome: Selenoamino acid metabolism (FDR=2.38e-08)
- Reactome: Formation of a pool of free 40S subunits (FDR=2.38e-08)
- Reactome: Major pathway of rRNA processing in the nucleolus and cytosol (FDR=2.38e-08)
- Reactome: L13a-mediated translational silencing of Ceruloplasmin expression (FDR=2.38e-08)
- Reactome: Eukaryotic Translation Initiation (FDR=2.38e-08)
- Reactome: GTP hydrolysis and joining of the 60S ribosomal subunit (FDR=2.38e-08)
- Reactome: Cap-dependent Translation Initiation (FDR=2.38e-08)

## Candidate-Background Top Unstable Terms

- No terms returned.

## Gate B3 Decision

Gate B3 status: **CONDITIONAL_PASS_TO_B4**

## Interpretation

- Stable strict set significant candidate-background terms: 66.
- Unstable primary set significant candidate-background terms: 0.
- Stable significant modules: ribosomal_translation, rna_processing, other_or_unclassified.
- Unstable significant modules: .
- The enrichment output should be framed as biology of transportable vs non-transportable transcriptional signals, not as diagnostic classifier validation.

## Outputs

- `results/route_b_b3_enrichment_all.csv`
- `results/route_b_b3_enrichment_significant_fdr005.csv`
- `results/route_b_b3_top_terms_for_manuscript.csv`
- `results/route_b_b3_ranked_terms_audit_only.csv`
- `results/route_b_b3_module_summary.csv`
- `results/route_b_b3_database_summary.csv`
- `results/route_b_b3_gene_set_input_summary.csv`
- `figures/route_b/B3_GO_BP_candidate_background_dotplot.png`
- `figures/route_b/B3_significant_module_heatmap.png`
- `figures/route_b/B3_enrichment_database_yield.png`
