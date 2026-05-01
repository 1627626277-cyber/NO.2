# Route B Execution Plan

Generated at: 2026-05-01

## Positioning

Route A failed on GSE140829. The project should now stop claiming a robust diagnostic model and switch to a conservative Q4-oriented manuscript:

**Working title**

Peripheral blood transcriptomic signatures of Alzheimer's disease show cohort-dependent reproducibility and limited cross-platform diagnostic transferability

## Central Claim

AD-related blood transcriptional signals are detectable and partially reproducible in related cohorts, but diagnostic performance decays substantially across platforms and cohorts. This limitation is itself the key scientific and methodological finding.

## Technical Stages

### B1. Evidence Consolidation

Inputs:

- S3 differential expression results.
- S4 external validation results.
- S5 failed model optimization.
- Route A GSE140829 failed validation.

Outputs:

- Consolidated evidence table across GSE63060, GSE63061, GSE85426, and GSE140829.
- AUC decay figure.
- Direction concordance and mapping-rate figure.

Gate:

- The evidence must clearly show near-cohort reproducibility and cross-platform degradation.

### B2. Stable vs Unstable Gene Sets

Stable set definition:

- S3 candidate genes with concordant direction in GSE63061.
- Optional stricter set: concordant in GSE63061 and at least direction-consistent in GSE85426 or GSE140829.

Unstable set definition:

- S3 candidate genes that replicate in GSE63061 but reverse or vanish in GSE85426/GSE140829.

Outputs:

- `route_b_stable_genes.csv`
- `route_b_unstable_genes.csv`
- UpSet/Venn-style overlap table.

Gate:

- Stable and unstable sets must be interpretable and not dominated only by low-information artifacts.

### B3. Pathway and Biological Interpretation

Analyses:

- GO Biological Process.
- KEGG/Reactome if package availability allows.
- Separate enrichment for stable and unstable gene sets.
- Optional immune-cell proxy score analysis using known blood lineage marker sets.

Expected framing:

- Stable signals: immune/inflammatory, mitochondrial, ribosomal/protein synthesis, or blood cell composition-related modules.
- Unstable signals: platform-sensitive or cohort-composition-sensitive modules.

Gate:

- Enrichment must support a coherent biological story. If enrichment is generic housekeeping only, manuscript risk remains high.

### B4. Transportability Audit

Metrics:

- Mapping rate by dataset.
- Direction concordance by dataset.
- Nominal/FDR replication by dataset.
- Signature AUC decay.
- MCI score placement where available.

Outputs:

- Main Figure 1: workflow and dataset roles.
- Main Figure 2: cohort-by-cohort validation heatmap.
- Main Figure 3: AUC decay and score distributions.
- Main Figure 4: pathway comparison of stable vs unstable genes.

Gate:

- The manuscript must present diagnostic modeling as a cautionary result, not a positive biomarker claim.

### B5. Manuscript Framing

Allowed wording:

- "transportability"
- "cross-cohort validation"
- "limited diagnostic transferability"
- "blood transcriptional signatures"
- "external validation failure as evidence of cohort dependence"

Avoid:

- "robust diagnostic biomarker"
- "high-performance model"
- "clinically useful classifier"
- "validated diagnostic signature"

### B6. Submission Strategy

Primary target:

- SCI Q4 bioinformatics/translational medicine journals that accept public-data reanalysis and negative/limitation-oriented validation studies.

Conditional Q3:

- Only if Route B produces strong pathway coherence and a clear methodological contribution on validation failure.

## Immediate Next Step

Run B1:

1. Merge S4, S5, and Route A model-validation summaries.
2. Create cross-dataset evidence table.
3. Generate AUC decay and replication metrics figures.
4. Produce Gate B1 report.

## B1 Execution Result

Executed on: 2026-05-01

Evidence files:

- `audit/route_b_b1_evidence_consolidation_report.md`
- `audit/gate_b1_evidence_consolidation_review.md`
- `results/route_b_b1_replication_summary.csv`
- `results/route_b_b1_model_auc_long.csv`
- `results/route_b_b1_evidence_dashboard.csv`

Gate B1 status: **PASS_ROUTE_B_FRAMING**.

Key result:

| Dataset | Role | Direction concordance | Nominal concordant | FDR concordant | Median oriented AUC | Best model AUC |
|---|---|---:|---:|---:|---:|---:|
| GSE63061 | Related external validation | 0.989 | 448 | 395 | 0.637 | 0.784 |
| GSE85426 | Cross-platform stress test | 0.749 | 35 | 0 | 0.537 | 0.587 |
| GSE140829 | New large cross-platform validation | 0.898 | 122 | 5 | 0.534 | 0.569 |

Interpretation:

- The project has enough evidence to support cohort-dependent reproducibility.
- The project does not have enough evidence to support a robust diagnostic classifier.
- Route B should continue with stable/unstable gene-set construction, pathway interpretation, and transportability audit.

Next stage: B2 stable vs unstable gene sets.

## B2 Execution Result

Executed on: 2026-05-01

Evidence files:

- `audit/route_b_b2_stable_unstable_gene_sets_report.md`
- `audit/gate_b2_stable_unstable_gene_set_review.md`
- `results/route_b_stable_genes.csv`
- `results/route_b_stable_directional_sensitivity_genes.csv`
- `results/route_b_unstable_genes.csv`
- `results/route_b_b2_gene_transportability_classification.csv`
- `results/route_b_b2_overlap_table.csv`

Gate B2 status: **PASS_TO_B3**.

Definitions used:

- Primary stable set: GSE63061 nominally concordant, all mapped cross-platform cohorts direction-concordant, and at least one cross-platform cohort nominally concordant.
- Directional stable sensitivity set: GSE63061 direction-concordant and all mapped cross-platform cohorts direction-concordant.
- Primary unstable set: GSE63061 nominally concordant but not strict-stable, with either cross-platform reversal or cross-platform signal loss.

Key result:

| Set or metric | Genes |
|---|---:|
| S3 candidates | 476 |
| GSE63061 direction anchor | 471 |
| GSE63061 nominal anchor | 448 |
| Primary stable set | 103 |
| Directional stable sensitivity set | 327 |
| Primary unstable set | 235 |
| Cross-platform reversal | 139 |
| Cross-platform signal loss | 190 |

Preliminary biological sanity check:

- Stable interpretable keyword fraction: 0.456.
- Stable housekeeping-like fraction: 0.408.
- Stable immune/inflammatory fraction: 0.049.

Interpretation:

- Stable biological signal is present but appears weighted toward ribosomal/mitochondrial modules.
- The signal is not strong enough to revive a diagnostic-classifier claim.
- B3 enrichment is required to decide whether the biological story is publishable or only descriptive.

Next stage: B3 pathway and biological interpretation.

## B3 Execution Result

Executed on: 2026-05-01

Evidence files:

- `audit/route_b_b3_pathway_interpretation_report.md`
- `audit/gate_b3_pathway_interpretation_review.md`
- `results/route_b_b3_enrichment_all.csv`
- `results/route_b_b3_enrichment_significant_fdr005.csv`
- `results/route_b_b3_top_terms_for_manuscript.csv`
- `results/route_b_b3_ranked_terms_audit_only.csv`
- `results/route_b_b3_module_summary.csv`
- `results/route_b_b3_database_summary.csv`

Gate B3 status: **CONDITIONAL_PASS_TO_B4**.

Key result:

| Gene set | GO BP FDR<0.05 | KEGG FDR<0.05 | Reactome FDR<0.05 | Interpretation |
|---|---:|---:|---:|---|
| Primary stable set | 12 | 2 | 52 | Enriched for translation, ribosome, rRNA/RNA processing modules |
| Directional stable sensitivity set | 0 | 2 | 45 | Reactome support remains, GO BP support weaker |
| Primary unstable set | 0 | 0 | 0 | No coherent significant enrichment |

Interpretation:

- Stable transportable genes have a coherent but conservative biological signal, mainly ribosomal translation and RNA processing.
- Unstable genes should not be assigned a strong mechanism; they are better described as non-transportable or cohort-sensitive signals without coherent enrichment.
- These results support Route B only as a limited-transferability paper, not as a diagnostic biomarker paper.

Next stage: B4 transportability audit and main figure assembly.

## B4 Execution Result

Executed on: 2026-05-01

Evidence files:

- `audit/route_b_b4_transportability_audit_report.md`
- `audit/gate_b4_transportability_audit_review.md`
- `results/route_b_b4_transportability_metrics.csv`
- `results/route_b_b4_auc_decay_summary.csv`
- `results/route_b_b4_mci_score_gradient.csv`
- `results/route_b_b4_main_figure_plan.csv`
- `results/route_b_b4_manuscript_claim_audit.csv`
- `results/route_b_b4_gate_summary.csv`

Main figures:

- `figures/route_b/B4_main_figure1_dataset_workflow.png`
- `figures/route_b/B4_main_figure2_validation_heatmap.png`
- `figures/route_b/B4_main_figure3_auc_and_scores.png`
- `figures/route_b/B4_main_figure4_pathway_comparison.png`

Gate B4 status: **PASS_TO_B5_Q4_FRAMING**.

Key result:

| Dataset | Role | Direction concordance | FDR concordant | Best model AUC | B4 interpretation |
|---|---|---:|---:|---:|---|
| GSE63061 | Related validation | 0.989 | 395 | 0.784 | Related-cohort reproducible |
| GSE85426 | Cross-platform stress test | 0.749 | 0 | 0.587 | Cross-platform degraded |
| GSE140829 | New large validation | 0.898 | 5 | 0.569 | Cross-platform degraded |

Additional audit result:

- Primary gene-only model AUC drop from GSE63061 to GSE85426/GSE140829: 0.214 / 0.226.
- Primary integrated model AUC drop from GSE63061 to GSE85426/GSE140829: 0.216 / 0.218.
- GSE140829 MCI score placement is partial only: 2/3 model summaries place MCI between Control and AD.

Interpretation:

- Route B is now technically coherent for a Q4-oriented manuscript.
- The manuscript must foreground cohort dependence and cross-platform degradation.
- Diagnostic model wording remains prohibited.

Next stage: B5 manuscript framing and B6 submission strategy.

## B5/B6 Execution Result

Executed on: 2026-05-01

Evidence files:

- `MANUSCRIPT_ROUTE_B_FRAMING_PLAN.md`
- `SUBMISSION_STRATEGY_ROUTE_B.md`
- `results/route_b_b5_claim_evidence_matrix.csv`
- `results/route_b_b6_candidate_journal_screen.csv`
- `audit/gate_b5_b6_framing_submission_review.md`

Gate B5 status: **PASS_TO_B6_SUBMISSION_STRATEGY**.

Gate B6 status: **PASS_TO_DRAFTING_WITH_Q4_STRATEGY**.

Accepted manuscript title direction:

Peripheral blood transcriptomic signatures of Alzheimer's disease show cohort-dependent reproducibility and limited diagnostic transferability

Accepted central claim:

AD-related blood transcriptional signals are detectable and partially reproducible, but their diagnostic transferability is limited across independent platforms and cohorts.

Primary journal candidates:

- BMC Medical Genomics.
- BioData Mining.

Backup candidates:

- BMC Genomics.
- Medicine.
- Genetics Research, only after current indexing verification.

Fallback:

- BMC Research Notes only if downgraded to a short negative/validation note.

Excluded:

- Molecular Biology Reports, because the official scope excludes purely bioinformatic / in silico papers.

Required next stage:

- Build full IMRaD outline with word allocation.
- Draft figure captions for the four B4 main figures.
- Prepare supplementary table list.
- Draft Methods first, because reproducibility and leakage control are the manuscript's main defense.

## Drafting V1 Execution Result

Executed on: 2026-05-01

Drafting files:

- `manuscript/ROUTE_B_PAPER_CONFIGURATION.md`
- `manuscript/ROUTE_B_IMRAD_OUTLINE.md`
- `manuscript/ROUTE_B_FIGURE_CAPTIONS.md`
- `manuscript/ROUTE_B_SUPPLEMENTARY_TABLES.md`
- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1.md`
- `manuscript/ROUTE_B_INITIAL_REVIEW_RISK_CHECK.md`

Draft status:

- Full English V1 manuscript draft created.
- Approximate draft length: 3570 words.
- Route B framing preserved.
- No new model optimization or evidence reinterpretation performed.

Initial reviewer-style decision:

Major revision before submission.

Required next revision pass:

- Verify and format references.
- Expand Introduction with verified AD blood transcriptomics and validation-failure literature.
- Add exact software versions and script names to Methods.
- Add panel labels to figures and captions.
- Run full academic-paper-reviewer review after V1.1.

## Drafting V1.1 Execution Result

Executed on: 2026-05-01

Revision files:

- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_1.md`
- `manuscript/ROUTE_B_CITATION_AND_REPRODUCIBILITY_AUDIT_V1_1.md`
- `manuscript/ROUTE_B_FULL_REVIEW_V1_1.md`

Revision status:

- Introduction expanded with AD burden, biomarker framing, public GEO dataset context, external-validation rationale, and TRIPOD-style validation concern.
- References converted from placeholder list to numbered working references.
- Dataset accessions, limma, glmnet, pROC, clusterProfiler, ReactomePA, and Reactome citations inserted into the manuscript.
- R 4.5.3, package versions, and the full staged script chain added to Methods.
- Approximate manuscript length increased to 4138 words.

Full reviewer-style decision:

**Major Revision Before Submission.**

Reviewer consensus:

- Route B framing is correct and should not be redirected toward diagnostic-model success.
- V1.1 is stronger than V1 and suitable for serious revision toward Q4-risk-controlled submission.
- V1.1 is not submission-ready because formal reference formatting, declarations, figure integration, mapping/model details, supplementary traceability, and additional AD blood-transcriptomics literature remain incomplete.

Required next stage:

- Build V1.2 by completing declarations, finalizing references, expanding mapping/model methods, adding figure callouts, adding a reproducibility traceability table, and strengthening domain literature integration.

Gate result: **MAJOR_REVISION_TO_V1_2; DO_NOT_SUBMIT_V1_1**.

## Drafting V1.2 Execution Result

Executed on: 2026-05-01

Revision files:

- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_2.md`
- `manuscript/ROUTE_B_REPRODUCIBILITY_TRACEABILITY_TABLE_V1_2.md`
- `manuscript/ROUTE_B_V1_2_REVISION_AUDIT.md`
- `manuscript/ROUTE_B_SUPPLEMENTARY_TABLES.md`

External source files used for author/declaration details:

- `D:\二区\submission\bmc_medical_genomics_2026-05-01\TITLE_PAGE_DRAFT.md`
- `D:\二区\submission\bmc_medical_genomics_2026-05-01\DECLARATIONS_DRAFT.md`
- `D:\二区\submission\bmc_medical_genomics_2026-05-01\AUTHOR_AND_ORCID_STATUS.md`
- `D:\二区\reports\manuscript\SUBMISSION_PREP_CHECKLIST_BMC_MEDICAL_GENOMICS.md`

V1.2 changes:

- Added author metadata: Zhuang Jiang; Guangdong University of Petrochemical Technology (GDUPT), 139 Guandu 2nd Road, Maoming 525000, Guangdong, China; correspondence email; ORCID.
- Filled Ethics, Consent for Publication, Author Contributions, Funding, Conflicts of Interest, and Acknowledgements.
- Added four additional blood biomarker / AD blood-expression references and expanded the field-positioning paragraph.
- Expanded Methods for probe/gene mapping, duplicate feature handling, metadata alignment, glmnet model grid, covariate scaling, AUC threshold rationale, and non-emphasis of clinical calibration metrics after cross-platform AUC failure.
- Added Figure Legends for Figures 1-4.
- Added Supplementary Table S9 reproducibility traceability mapping claims to scripts, results, figures, and audit files.

Mechanical checks:

- Approximate V1.2 manuscript length: 5016 words.
- References: 20.
- In-text reference coverage: 20/20.
- Remaining manuscript TODO markers: 0.

Gate result: **PASS_MAJOR_REVISION_CONTENT; HOLD_FOR_FINAL_CITATION_FORMAT_AND_SUBMISSION_PACKAGE**.

Required next stage:

- Final DOI/PMID and target-journal reference style check.
- Public code/result archive decision and upload.
- Figure panel-label and resolution check.
- AD Route B title page and cover letter preparation.
- Target-journal adaptation for the selected Q4/Q3 venue.

## Pre-Generation Submission Package Result

Executed on: 2026-05-01

Target journal used for preparation: BMC Medical Genomics.

Files created:

- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_3_BMC_STYLE.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/TITLE_PAGE_DRAFT.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/COVER_LETTER_DRAFT.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/FINAL_CITATION_STYLE_AUDIT.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/FIGURE_PANEL_RESOLUTION_QC.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/CODE_ARCHIVE_DECISION.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/GENERATION_READY_CHECKPOINT.md`

Additional edits:

- `scripts/s11_route_b_b4_transportability_audit.R` updated to add A/B panel tags to Figures 3 and 4.
- Figures 3 and 4 regenerated; B4 gate remained `PASS_TO_B5_Q4_FRAMING`.

Pre-generation checks:

- BMC-style manuscript word count before references: 4516.
- References: 20.
- In-text reference coverage: 20/20.
- TODO markers: 0.
- Figure resolution: pass.
- Figure panel labels: pass for Figures 3 and 4 after regeneration.
- Pandoc available.
- Rscript available through conda environment `three-r`.
- Git not detected in current shell PATH.

Gate result: **READY_FOR_FULL_MANUSCRIPT_GENERATION_PENDING_USER_CONFIRMATION**.

Per user instruction, the workflow stops here before generating the complete paper file.

## Full Manuscript Generation Result

Executed on: 2026-05-01

Files generated:

- `submission/bmc_medical_genomics_route_b_2026-05-01/MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.docx`
- `submission/bmc_medical_genomics_route_b_2026-05-01/MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.pdf`
- `submission/bmc_medical_genomics_route_b_2026-05-01/COVER_LETTER_BMC_MEDICAL_GENOMICS_ROUTE_B.docx`
- `submission/bmc_medical_genomics_route_b_2026-05-01/COVER_LETTER_BMC_MEDICAL_GENOMICS_ROUTE_B.pdf`
- `submission/bmc_medical_genomics_route_b_2026-05-01/FINAL_INTEGRITY_PASS.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/SUBMISSION_PACKAGE_INDEX.md`

Generation method:

- Markdown source built by `scripts/build_route_b_submission_documents.py`.
- DOCX generated with Pandoc.
- PDF generated from HTML through Microsoft Edge headless print-to-PDF.
- DOCX rendered with `render_docx.py --renderer artifact-tool`.

QA:

- Manuscript DOCX rendered to 14 pages; visual QA passed.
- Cover letter DOCX rendered to 1 page; visual QA passed.
- Manuscript PDF page count: 14.
- Cover letter PDF page count: 1.
- References: 20; in-text coverage: 20/20; TODO markers: 0.

Gate result: **DOCUMENT_GENERATION_PASS; RENDER_QA_PASS; FINAL_INTEGRITY_CONDITIONAL_PASS_PENDING_PUBLIC_ARCHIVE_URL**.

## GitHub Archive Index Update

Executed on: 2026-05-01

Repository:

- `1627626277-cyber/NO.2`
- Archive index URL: `https://github.com/1627626277-cyber/NO.2/tree/main/ad-blood-transcriptome-transportability`

Local archive package:

- `submission/github_NO2_archive/ad-blood-transcriptome-transportability/`
- `submission/github_NO2_archive/ad-blood-transcriptome-transportability_2026-05-01.zip`
- `submission/github_NO2_archive/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip`

Remote GitHub index files created:

- `README.md`
- `ad-blood-transcriptome-transportability/README.md`
- `ad-blood-transcriptome-transportability/ARCHIVE_SCOPE.md`
- `ad-blood-transcriptome-transportability/ARCHIVE_RECONSTRUCTION.md`
- `ad-blood-transcriptome-transportability/MANIFEST.tsv`

Manuscript update:

- `Availability of data and materials` now includes the GitHub archive index URL.
- DOCX/PDF outputs were regenerated after the URL update.

QA:

- Manuscript DOCX render: 14 pages, pass.
- Cover letter DOCX render: 1 page, pass.
- Manuscript PDF page count: 14.
- Cover letter PDF page count: 1.
- References: 20; in-text citation coverage: 20/20.
- TODO markers: 0.

Gate result: **GITHUB_INDEX_CREATED; FINAL_INTEGRITY_CONDITIONAL_PASS_PENDING_FULL_GITHUB_SNAPSHOT_SYNC**.

Remaining before formal journal upload:

- Synchronize the full compact archive ZIP or base64 split parts to GitHub, or create a GitHub release/Zenodo DOI.
- Repeat final DOI/PMID live-link check.
- Upload figure PNGs separately in the journal portal.
