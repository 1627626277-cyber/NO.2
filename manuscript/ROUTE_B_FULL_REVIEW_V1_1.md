# Full Academic-Paper-Reviewer Report for Route B Manuscript V1.1

Review date: 2026-05-01

Manuscript reviewed: `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_1.md`

Title: Peripheral blood transcriptomic signatures of Alzheimer's disease show cohort-dependent reproducibility and limited diagnostic transferability

## Phase 0: Reviewer Configuration

Primary field: Alzheimer's disease bioinformatics and peripheral blood transcriptomics.

Secondary fields: diagnostic-model validation, public microarray reanalysis, pathway enrichment, reproducible computational biology.

Target tier assumed for review: Q4 or lower-risk Q3 bioinformatics/genomics journal.

Review team:

| Reviewer | Identity | Main focus |
|---|---|---|
| EIC | Editor for a Q4/Q3 computational genomics journal | Journal fit, claim discipline, contribution |
| Reviewer 1 | Statistical bioinformatics reviewer | Dataset roles, validation design, leakage control, reproducibility |
| Reviewer 2 | AD/transcriptomics domain reviewer | Disease framing, blood biomarker literature, biological interpretation |
| Reviewer 3 | Translational prediction-model reviewer | Diagnostic interpretation, clinical relevance, TRIPOD-style reporting |
| Devil's Advocate | Skeptical biomarker-methods reviewer | Core counterarguments, overclaiming, rejection risks |

## EIC Report

Recommendation: **Major Revision**

Confidence: 4/5

The manuscript presents a staged public-data audit of AD peripheral-blood transcriptomic signatures across GSE63060, GSE63061, GSE85426, and GSE140829. Its most valuable feature is the decision to foreground external-validation failure rather than repackage weak cross-platform AUCs as a successful classifier. This framing is appropriate for a Q4 validation or computational genomics venue, especially because the Results clearly separate related-cohort reproducibility from cross-platform degradation.

Strengths:

- The title and conclusions are aligned with the actual evidence rather than overstating diagnostic utility.
- The dataset-role design is clear: discovery, related validation, cross-platform stress test, and additional large validation.
- The manuscript now includes software versions and the script chain, improving reproducibility.

Weaknesses:

- The paper is not yet submission-ready because the references still need final journal-style formatting and several formal declarations remain as TODOs.
- Figure captions and supplementary material are not yet integrated into the manuscript body.
- The Introduction is improved, but the contribution still needs sharper positioning against prior AD blood-expression studies.

EIC decision rationale: the paper is coherent and potentially publishable as a cautious validation audit, but it needs one more revision cycle before journal submission.

## Reviewer 1: Methodology and Reproducibility

Recommendation: **Major Revision**

Confidence: 5/5

The methods are the strongest part of the manuscript. The staged design reduces validation leakage, and the manuscript explicitly states that GSE85426 and GSE140829 were not used for candidate selection or final tuning. The R/package versions and script names added in V1.1 materially improve reproducibility.

Major strengths:

- Dataset roles are prespecified and repeatedly enforced.
- The paper reports mapping rate, direction concordance, nominal replication, FDR replication, oriented AUC, and model AUC rather than relying on one metric.
- The negative cross-platform model result is interpreted conservatively.

Major weaknesses:

- Probe-to-gene mapping rules are still too compressed. The manuscript should state how multiple probes per gene were collapsed, how duplicate gene symbols were handled, and whether mapping was performed before or after normalization.
- The model section should specify cross-validation or penalty-selection details for glmnet, including family, alpha choice, lambda selection rule, scaling, and handling of missing covariates.
- The manuscript reports local script names but not a permanent repository, archive, or commit/hash. For submission, Code Availability should name the repository or state that scripts will be deposited on request/Zenodo/GitHub.
- The absence of cell-composition adjustment is acknowledged, but no sensitivity or proxy analysis is provided. If no deconvolution is possible, the limitation should be emphasized more strongly.

Required methodological fixes:

1. Expand mapping and gene-collapsing details.
2. Expand penalized-model fitting details.
3. Add a reproducibility table mapping each manuscript result to the script and output file that generated it.
4. Decide whether a public code archive will be made available.

## Reviewer 2: AD and Blood Transcriptomics Domain

Recommendation: **Major Revision**

Confidence: 4/5

The paper is scientifically more defensible after the V1.1 Introduction expansion. The central claim is plausible: blood transcriptomic signals can reproduce in related cohorts while failing to become robust diagnostic models across platforms. The stable-gene pathway result is useful but modest and should remain framed as biological context.

Strengths:

- The Introduction now names the biomarker context, public GEO resources, and the specific risk of optimistic public-data validation.
- The Discussion correctly warns that translation/ribosomal/RNA-processing enrichment is not automatically AD-specific.
- The manuscript avoids claiming clinical diagnostic readiness.

Weaknesses:

- Prior literature coverage remains thin. The manuscript should add at least 3-5 additional AD blood transcriptomic or multi-cohort validation studies to show that the authors understand the field, not only the datasets.
- The biological interpretation is cautious, but the stable-pathway result could still be challenged as broad cellular housekeeping biology. The Discussion should explicitly state that this signal may reflect robustly measured blood-cell or RNA-processing biology rather than AD-specific pathogenesis.
- GSE140829 is described as a large validation set, but the link between that dataset's reported innate immune response and the current weak model transferability deserves more explanation.

Required domain fixes:

1. Add a short paragraph comparing this study with prior blood-expression AD biomarker reports.
2. Clarify whether the stable translation/RNA-processing signal is disease-specific, platform-stable, or unresolved.
3. Add a final domain limitation stating that peripheral blood expression cannot be interpreted as brain AD pathology without orthogonal validation.

## Reviewer 3: Translational Prediction-Model Perspective

Recommendation: **Major Revision**

Confidence: 4/5

The manuscript is commendably strict about diagnostic claims. It uses AUC >= 0.70 as a gate and refuses to interpret sub-threshold cross-platform AUC values as clinically useful. This is appropriate. However, the manuscript is still not a complete prediction-model report.

Strengths:

- The Results report both related-cohort success and independent-cohort decay.
- The paper states that final validation labels were not used to tune the models.
- The Discussion rejects clinical-use interpretation and calls for strict external validation.

Weaknesses:

- The AUC >= 0.70 threshold is reasonable but not justified. The manuscript should explain whether this is a pragmatic minimum, a predefined internal gate, or tied to a clinical screening use case.
- Calibration, sensitivity, specificity, and decision-curve analysis are not reported. Because the paper is not selling a model, these may not be mandatory, but their absence should be acknowledged.
- MCI score placement is mentioned, but the exploratory role should be made even clearer in the Results and figure captions.
- TRIPOD is cited, but the manuscript does not yet include a TRIPOD-style checklist or reporting map.

Required translational fixes:

1. Justify the AUC threshold and state that it is a study gate, not a clinical adequacy threshold.
2. Add a sentence explaining why calibration and threshold-based clinical metrics were not emphasized after cross-platform AUC failure.
3. Add a TRIPOD-style reporting checklist as supplementary material or explicitly state that the study is a validation audit rather than a deployable prediction-model report.

## Devil's Advocate Report

Recommendation: **Major Revision; Reject if claims are strengthened beyond Route B**

Confidence: 5/5

Strongest counterargument:

The manuscript may be vulnerable to the criticism that its main positive biological finding is not strongly disease-specific. The stable gene set is enriched for translation, ribosomal, and RNA-processing pathways, which can reflect broad cellular activity, blood-cell composition, RNA quality, or platform-stable measurement rather than AD biology. Meanwhile, the actual diagnostic models fail in independent cross-platform cohorts. A skeptical reviewer could argue that the study mostly shows that public blood microarray signatures are fragile, without adding enough new biological or methodological insight. The paper survives this critique only if it remains honest: its contribution is a reproducible audit of limited transportability, not a validated biomarker discovery.

Major challenges:

- If the paper uses phrases that imply a "signature" is clinically meaningful, reviewers may see a mismatch with AUC 0.56-0.59 external results.
- The stable-pathway interpretation must avoid drifting into mechanism.
- The reference list remains in a working numbered style and must be converted to the target journal format before submission.
- Declarations and author/funding/conflict statements are still placeholders.

Acceptance condition from Devil's Advocate:

Keep the paper in Route B. Strengthen the methods transparency and field positioning, but do not try to rescue the diagnostic model narrative.

## Editorial Synthesis

Final decision: **Major Revision Before Submission**

The five-reviewer panel agrees that V1.1 is stronger than V1 and is now suitable for serious revision toward a Q4-risk-controlled submission. There is consensus that the Route B framing is correct, the validation evidence is coherent, and the manuscript should not be redirected toward a diagnostic model success claim. There is also consensus that the manuscript is not yet submission-ready because methods details, formal citations, declarations, figure integration, and supplementary traceability need further work.

## Required Revisions for V1.2

| ID | Required revision | Source | Severity | Target section |
|---|---|---|---|---|
| R1 | Complete journal-style reference formatting and DOI/PMID reconciliation | EIC, Devil's Advocate | Major | References |
| R2 | Fill Author Contributions, Funding, and Conflicts of Interest | EIC | Major | Declarations |
| R3 | Expand probe/gene mapping, duplicate handling, and feature-collapsing details | Reviewer 1 | Major | Methods |
| R4 | Expand glmnet/model fitting details and threshold rationale | Reviewer 1, Reviewer 3 | Major | Methods |
| R5 | Add or cite a reproducibility traceability table linking scripts to main results | Reviewer 1 | Major | Supplementary materials |
| R6 | Add 3-5 more AD blood transcriptomic/multi-cohort validation references | Reviewer 2 | Major | Introduction/Discussion |
| R7 | Clarify that stable pathway enrichment is conservative context, not AD mechanism | Reviewer 2, Devil's Advocate | Major | Discussion |
| R8 | Add figure panel labels/captions and supplementary table callouts in the manuscript | EIC, Reviewer 3 | Major | Results/Figures |

## Suggested Revisions

| ID | Suggested revision | Priority | Expected benefit |
|---|---|---|---|
| S1 | Add a short TRIPOD-style reporting checklist | P2 | Improves prediction-model reporting credibility |
| S2 | State why calibration/sensitivity/specificity are not central after AUC failure | P2 | Prevents clinical-reviewer objections |
| S3 | Add a sentence distinguishing study gate AUC >= 0.70 from clinical adequacy | P2 | Reduces overinterpretation risk |
| S4 | Consider a final supplementary table for all stable/unstable genes and pathway terms | P2 | Improves reproducibility and reviewer confidence |
| S5 | Decide target journal before final reference formatting | P3 | Avoids repeated style rework |

## Dimension Scores

| Dimension | Score | Descriptor | Rationale |
|---|---:|---|---|
| Originality | 72 | Adequate to strong | The negative transportability audit is useful, but not conceptually novel enough for a high-tier venue |
| Methodological rigor | 78 | Strong | Strong staged design; needs deeper mapping/model details |
| Evidence sufficiency | 76 | Strong for Route B | Supports limited transferability; does not support diagnostic utility |
| Argument coherence | 82 | Strong | Claim and evidence are well aligned |
| Literature integration | 65 | Adequate | Improved in V1.1 but still thin |
| Reproducibility | 73 | Adequate to strong | Versions/scripts added; public archive/traceability table still needed |
| Submission readiness | 58 | Not ready | Declarations, figure integration, final references, and supplements remain incomplete |

Overall weighted assessment: **72/100**.

## V1.2 Revision Roadmap

Priority 1:

- Complete declarations and formalize reference formatting.
- Expand Methods for mapping/collapsing and glmnet fitting.
- Add figure callouts and panel-level captions.
- Add a reproducibility traceability table.

Priority 2:

- Add more AD blood transcriptomics literature.
- Add AUC-threshold rationale and TRIPOD-style reporting note.
- Strengthen the conservative interpretation of stable pathway enrichment.

Priority 3:

- Finalize reference style after target journal selection.
- Prepare response-to-reviewer skeleton for internal tracking.

Gate result: **MAJOR_REVISION_TO_V1_2; DO_NOT_SUBMIT_V1_1**.
