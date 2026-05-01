# Submission Issue Notebook

Date opened: 2026-05-01

Purpose: track author-facing and reviewer-risk issues before journal upload.

| ID | Issue | Action | Status |
|---|---|---|---|
| SI-001 | Remove unsupported `pre-registered` wording. | Replaced with locked/frozen analysis rules and signatures; updated results sentence to "No primary or frozen refit model..." | Resolved |
| SI-002 | Clarify `best model AUC` to avoid validation-set cherry-picking implication. | Replaced visible wording with "highest AUC among the frozen candidate models" and compact table label "Best frozen model AUC"; result column renamed to `best_frozen_model_auc`. | Resolved |
| SI-003 | Strengthen GSE85426 mapping audit. | Added row-name Entrez suffix parsing, 10,775/14,113 retained row audit, 451/476 mapped candidates, 25 unmapped candidates, ambiguous/unmapped exclusion, and variance-based collapse rule in Methods/S10. | Resolved |
| SI-004 | Bound within-dataset z-score interpretation. | Added statement that the modeling analysis is a cohort-level transferability audit, not a deployable single-sample assay. | Resolved |
| SI-005 | Blood-cell composition sensitivity risk. | Completed S13 marker-score sensitivity analysis. Direction remained 103/103 in GSE63061, 99/102 in GSE140829, but attenuated to 69/100 in GSE85426; manuscript now states this as cautious support with residual confounding. | Resolved with caution |
| SI-006 | Clarify candidate-universe FDR as targeted replication FDR. | Replaced validation FDR wording with "targeted replication FDR within the mapped discovery-derived candidate-gene universe" in Methods, results labels, figures, and S10 wording. | Resolved |
| SI-007 | Reading-version metadata versus formal submission. | Reading-version metadata remains limited to local reading document; formal submission-ready DOCX was rebuilt and checked for absence of reading-version sidebar metadata. | Resolved |

## Notes

- Formal journal submission should not use the integrated reading version as the uploaded manuscript file.
- Archive synchronization remains a separate pre-submission blocker until the complete local reproducibility snapshot is placed in GitHub release, Zenodo, OSF, or equivalent.
- S13 is a marker-score sensitivity analysis only, not formal cell-type deconvolution; this should remain explicit if reviewers ask about blood-cell composition.
