# S12 Route B AUC CI and demographic/mapping audit

Generated: 2026-05-01 12:11:02

Outputs:

- `results/route_b_auc_ci_summary.csv`
- `results/route_b_demographic_mapping_audit.csv`

AUC confidence intervals were estimated with pROC DeLong 95% CIs using AD as the higher-score event and Control as the reference level.
GSE140829 is labelled as `large_independent_external_validation`; GSE85426 is labelled as `cross_platform_stress_test`.
FDR concordance in the validation audit refers to Benjamini-Hochberg targeted replication FDR within the mapped discovery-derived candidate-gene universe for each validation dataset.
The demographic/mapping audit reports mapped and unmapped candidate counts, mapping notes, and the highest AUC among frozen candidate models.

