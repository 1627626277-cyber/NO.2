# Q4 Readiness Revision Log

Date: 2026-05-01

## Scope

This revision addressed the pre-submission risk points raised for a Q4-oriented external-validation manuscript. The framing remains a cautious transferability audit, not a diagnostic classifier success paper.

## Changes completed

1. Removed public-facing internal labels from the reading manuscript front matter: no Route B, reading proof, Generated, or Claim sidebar labels remain.
2. Revised the title, abstract, title page, and cover letter to emphasize external validation audit and limited transferability.
3. Repositioned GSE140829 as a large independent external validation cohort, not as a cross-platform validation cohort.
4. Added model-level AUC 95% confidence intervals using DeLong intervals from pROC.
5. Clarified that GSE140829 was used as sequential additional independent validation and was not used for candidate selection, model selection, or tuning.
6. Clarified FDR correction universes: discovery FDR across the modeled GSE63060 feature universe, validation FDR within the mapped discovery-derived candidate-gene universe, and pathway FDR within each tested database/gene-set comparison.
7. Added demographic/mapping audit outputs and Supplementary Table S10.
8. Regenerated Figure 1 to remove internal route labels and to label GSE140829 as large independent external validation.
9. Regenerated the submission-ready DOCX/PDF, cover letter, and integrated reading manuscript.
10. Removed unsupported `pre-registered` wording and replaced visible ambiguous `best model AUC` language with frozen-model wording.
11. Strengthened GSE85426 mapping details: 10,775/14,113 rows retained by row-name Entrez suffix parsing, 451/476 candidates mapped, 25 unmapped, ambiguous/unmapped rows excluded, and multiple probes collapsed by highest variance.
12. Added within-dataset z-score interpretation limits: the modeling analysis is a cohort-level transferability audit, not a deployable single-sample diagnostic assay.
13. Added S13 blood-cell marker-score sensitivity analysis and Supplementary Table S11.

## Key statistical additions

- Primary gene-only model:
  - GSE63061: AUC 0.781 (95% CI, 0.727-0.834)
  - GSE85426: AUC 0.567 (95% CI, 0.483-0.651)
  - GSE140829: AUC 0.554 (95% CI, 0.500-0.609)
- Primary integrated model:
  - GSE63061: AUC 0.784 (95% CI, 0.731-0.838)
  - GSE85426: AUC 0.568 (95% CI, 0.484-0.653)
  - GSE140829: AUC 0.567 (95% CI, 0.512-0.621)
- Train-development refit model:
  - GSE85426: AUC 0.587 (95% CI, 0.503-0.671)
  - GSE140829: AUC 0.569 (95% CI, 0.515-0.624)
- Blood-cell marker-score sensitivity:
  - GSE63061: adjusted direction concordance 103/103; adjusted nominal concordance 97/103.
  - GSE85426: adjusted direction concordance 69/100; adjusted nominal concordance 12/100.
  - GSE140829: adjusted direction concordance 99/102; adjusted nominal concordance 26/102.

## Files generated or updated

- `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_SUBMISSION_READY.docx`
- `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.docx`
- `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.pdf`
- `READING_VERSION_CELLS_STYLE_MANUSCRIPT.docx`
- `READING_VERSION_CELLS_STYLE_MANUSCRIPT.pdf`
- `COVER_LETTER_BMC_MEDICAL_GENOMICS_ROUTE_B.docx`
- `COVER_LETTER_BMC_MEDICAL_GENOMICS_ROUTE_B.pdf`
- `results/route_b_auc_ci_summary.csv`
- `results/route_b_demographic_mapping_audit.csv`
- `results/blood_cell_marker_sensitivity_summary.csv`
- `results/blood_cell_marker_sensitivity_gene_level.csv`
- `results/blood_cell_marker_coverage.csv`
- `audit/s12_auc_ci_and_demographic_audit.md`
- `audit/s13_blood_cell_marker_sensitivity.md`
- `SUBMISSION_ISSUE_NOTEBOOK.md`

## Render QA

- Submission-ready DOCX: 22 pages, artifact-tool render pass.
- Integrated reading manuscript DOCX: 12 pages, artifact-tool render pass.
- Full manuscript DOCX: 15 pages, artifact-tool render pass.
- Cover letter DOCX: 1 page, artifact-tool render pass.

## Remaining submission blocker

The manuscript revision itself is complete for author review. Formal journal upload should still wait until the complete local reproducibility snapshot is synchronized to GitHub release, Zenodo, OSF, or an equivalent DOI-backed archive.
