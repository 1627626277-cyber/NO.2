# Route B Manuscript V1.2 Revision Audit

Date: 2026-05-01

Manuscript checked: `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_2.md`

## V1.2 Scope

V1.2 addresses the major revision items raised in `manuscript/ROUTE_B_FULL_REVIEW_V1_1.md`, with special attention to author metadata, declarations, method transparency, figure legends, and reproducibility traceability.

## Source Used for Author and Declaration Details

The author and declaration fields were taken from the existing submission package in `D:\二区`:

- `D:\二区\submission\bmc_medical_genomics_2026-05-01\TITLE_PAGE_DRAFT.md`
- `D:\二区\submission\bmc_medical_genomics_2026-05-01\DECLARATIONS_DRAFT.md`
- `D:\二区\submission\bmc_medical_genomics_2026-05-01\AUTHOR_AND_ORCID_STATUS.md`
- `D:\二区\reports\manuscript\SUBMISSION_PREP_CHECKLIST_BMC_MEDICAL_GENOMICS.md`

Transferred fields:

- Author: Zhuang Jiang
- Affiliation: Guangdong University of Petrochemical Technology (GDUPT), 139 Guandu 2nd Road, Maoming 525000, Guangdong, China
- Corresponding author email: 1627626277@qq.com
- ORCID: https://orcid.org/0009-0007-4388-5901
- Funding: No specific funding was received for this work.
- Competing interests: The author declares that there are no competing interests.

## V1.1 Reviewer Items

| Reviewer item | V1.2 status | Evidence in V1.2 |
|---|---|---|
| R1. Complete journal-style reference formatting and DOI/PMID reconciliation | Partially addressed | References expanded to 20 numbered entries and all are cited in text; final target-journal style and DOI/PMID pass still needed |
| R2. Fill Author Contributions, Funding, and Conflicts of Interest | Addressed | Author Contributions, Funding, Conflicts of Interest, Ethics, Consent for Publication, and Acknowledgements updated |
| R3. Expand probe/gene mapping, duplicate handling, and feature-collapsing details | Addressed | Methods now describe first-token parsing, unique discovery-gene selection, highest-variance validation probe retention, and metadata alignment checks |
| R4. Expand glmnet/model fitting details and threshold rationale | Addressed | Methods now describe binomial glmnet, feature grid, alpha values, lambda rules, 5-fold CV, AUC metric, standardize=FALSE, covariate coding, and AUC gate rationale |
| R5. Add reproducibility traceability table | Addressed | `manuscript/ROUTE_B_REPRODUCIBILITY_TRACEABILITY_TABLE_V1_2.md` created and Supplementary Table S9 added |
| R6. Add more AD blood transcriptomic/multi-cohort validation references | Addressed | Added blood biomarker review and AD blood-expression references; reference list increased from 16 to 20 |
| R7. Clarify stable pathway enrichment as conservative context, not AD mechanism | Addressed | Discussion now states the stable signal may reflect blood-cell, RNA-quality, systemic, or platform-stable biology and is not evidence of brain AD pathogenesis |
| R8. Add figure callouts and captions | Mostly addressed | Figure legends added for Figures 1-4; existing Results callouts retained. Actual figure panel lettering should still be checked before DOCX/PDF preparation |

## Mechanical Checks

- Approximate word count: 5016 words.
- References: 20.
- In-text reference coverage: all 20 references are cited.
- Remaining TODO markers in manuscript: 0.
- Route B claim preserved: yes.
- Prohibited diagnostic-success phrasing detected only in negated/cautionary wording: yes.

## Residual Risks Before Submission

1. Final DOI/PMID and target-journal reference style check remains required.
2. Public code/result archive has not yet been deposited.
3. Figure files should be checked for panel labels and final journal resolution.
4. A target-journal title page and cover letter still need to be prepared specifically for this AD Route B manuscript, rather than copied from the multiple-myeloma package.
5. ORCID profile cleanup noted in the source package remains outside the manuscript.

## Gate Result

V1.2 status: **PASS_MAJOR_REVISION_CONTENT; HOLD_FOR_FINAL_CITATION_FORMAT_AND_SUBMISSION_PACKAGE**.

The manuscript is materially stronger than V1.1 and can proceed to final citation/style cleanup, figure package preparation, and target-journal adaptation. It should still not be submitted until references, code archive, and figure files are finalized.
