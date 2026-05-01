# Project Risk Response Routes

Generated at: 2026-05-01

## Trigger

Gate 5 failed the requested external validation threshold:

- Primary gene-only model: GSE85426 AUC = 0.567.
- Primary gene + age/gender model: GSE85426 AUC = 0.568.
- Best post-hoc model in the previous optimization grid: GSE85426 AUC = 0.620.
- GSE85426 label-driven upper-bound diagnostic: best in-sample AUC = 0.688.

Conclusion: the current candidate set does not support a robust cross-platform diagnostic model at AUC >= 0.70.

## External Dataset Scan

Evidence file: `results/risk_external_dataset_scan.csv`.

| Dataset | Role | Samples | AD | Control | MCI | Platform | Assessment |
|---|---:|---:|---:|---:|---:|---|---|
| GSE140829 | Route A primary rescue dataset | 587 | 204 | 249 | 134 | GPL15988 | High priority. Large peripheral blood AD/MCI/Control dataset. |
| GSE97760 | Support only | 19 | 9 | 10 | 0 | GPL16699 | Very small, female-only, advanced AD. Not primary validation. |
| GSE18309 | Support only | 9 | 3 | 3 | 3 | GPL570 | Very small PBMC dataset. Directional support only. |
| GSE4226 | Support only | 28 | 14 | 14 | 0 | GPL1211 | Small PBMC dataset. Directional support only. |
| GSE165090 | Exclude | 6 | 0 | 3 | 0 | GPL24676 | False hit; trophoblast SERPINA1 siRNA experiment, not AD blood. |

## Route A: Data-Rescue Diagnostic Model

### Objective

Preserve a diagnostic-model manuscript only if a newly frozen, previously unused external dataset supports AUC >= 0.70.

### Revised Claim

"A peripheral blood transcriptomic signature for Alzheimer's disease shows reproducible diagnostic potential across multiple public cohorts, with final validation in an independent large blood cohort."

This claim is allowed only if GSE140829 final validation passes. Otherwise Route A must stop.

### Dataset Roles

- Discovery: GSE63060.
- Development/model selection: GSE63061.
- Stress-test dataset already seen: GSE85426. Use only as a known difficult cross-platform benchmark, not as the final proof.
- New final validation: GSE140829.
- Support-only sensitivity datasets: GSE97760, GSE18309, GSE4226.

### Technical Steps

1. Freeze GSE140829.
   - Download `GSE140829_series_matrix.txt.gz`.
   - Download `GSE140829_final_normalized_data.txt.gz`.
   - Parse labels from `Sample_title`: AD, Control, MCI.
   - Lock AD vs Control for primary endpoint; reserve MCI for secondary gradient analysis.

2. QC and gene mapping.
   - Parse GPL15988 or row-level probe annotation.
   - Collapse probes to Entrez gene by highest within-dataset variance.
   - Record mapping rate for S3 candidates and S5 model features.

3. Frozen-model validation.
   - Apply current S5 primary gene-only model and integrated model to GSE140829 without refitting.
   - Required pass: AD vs Control AUC >= 0.70, bootstrap 95% CI lower bound preferably > 0.60.

4. Pre-registered refit.
   - If frozen validation is borderline, refit only on GSE63060 + GSE63061 using the existing feature-selection family.
   - Do not use GSE140829 labels for tuning.
   - GSE140829 remains final validation.

5. Secondary analyses.
   - MCI score should fall between Control and AD.
   - Report GSE85426 as a difficult stress-test and explain platform/cohort heterogeneity.
   - Use GSE97760/GSE18309/GSE4226 only for directional support, not main AUC claims.

### Go/No-Go Gates

- A-Gate 1: GSE140829 metadata and expression data parse cleanly.
- A-Gate 2: >=70% of model genes map to GSE140829.
- A-Gate 3: frozen or refit model reaches GSE140829 AUC >= 0.70.
- A-Gate 4: no model-selection step uses GSE140829 labels.

### Outcome If Successful

Proceed to enrichment/PPI and manuscript planning. Target remains Q4 stable, Q3 conditional.

### Outcome If Failed

Stop diagnostic-model claim and switch to Route B.

## Route B: Conservative Q4 Transportability-Limits Paper

### Objective

Lower the paper claim so that the negative GSE85426 result becomes part of the scientific contribution rather than a fatal weakness.

### Revised Claim

"Peripheral blood transcriptomic signatures of Alzheimer's disease are reproducible within related cohorts but show limited cross-platform diagnostic transferability, highlighting immune/mitochondrial pathway signals and the need for strict external validation."

### Dataset Roles

- Discovery: GSE63060.
- Related-cohort validation: GSE63061.
- Cross-platform stress test: GSE85426.
- Optional context dataset: GSE140829, used for pathway/transportability confirmation rather than hard diagnostic rescue.
- Small support datasets: GSE97760, GSE18309, GSE4226 for direction-only sensitivity.

### Technical Steps

1. Keep S3/S4/S5 results unchanged.
   - Preserve failed GSE85426 AUC as an explicit external-validity finding.

2. Reframe model outputs.
   - Report diagnostic AUC as exploratory and limited.
   - Primary results become: direction concordance, pathway consistency, gene-set stability, and cohort heterogeneity.

3. Biological interpretation.
   - Run GO/KEGG/Reactome enrichment on stable genes and discordant genes separately.
   - Compare near-cohort stable genes versus cross-platform unstable genes.
   - Add immune cell-type signature or blood cell composition proxy analysis if feasible.

4. Transportability analysis.
   - Quantify mapping rate, direction concordance, nominal/FDR replication, and AUC decay from GSE63061 to GSE85426.
   - Treat AUC decay as a central figure rather than hiding it.

5. Manuscript framing.
   - Avoid title terms like "robust diagnostic model" or "high-performance biomarker".
   - Use terms like "transportability", "external validation", "cross-platform limitations", and "blood transcriptional signatures".

### Go/No-Go Gates

- B-Gate 1: Stable biological signals remain after separating GSE63061 and GSE85426.
- B-Gate 2: Enrichment results are coherent and not just generic housekeeping/ribosomal artifacts.
- B-Gate 3: The paper can make a clear methodological contribution about external validation failure and cohort dependence.
- B-Gate 4: Candidate Q4 journals accept negative/limitation-oriented bioinformatics studies.

### Outcome If Successful

Proceed as a Q4-risk-controlled manuscript. Q3 should not be the primary target unless GSE140829 or another large external dataset improves the evidence.

## Recommendation

Execute Route A first because GSE140829 is large enough to rescue the diagnostic-model claim. If A-Gate 3 fails, switch immediately to Route B and stop optimizing classifiers.

Near-term next step:

1. Download and freeze GSE140829.
2. Run frozen S5 models on GSE140829.
3. Decide between Route A continuation and Route B downgrade based on the new final AUC.

## Route A Execution Result

Executed on: 2026-05-01

Evidence files:

- `audit/route_a_gse140829_validation_report.md`
- `audit/gate_route_a_gse140829_review.md`
- `results/route_a_gse140829_model_validation.csv`

Final analyzable normalized-data subset:

- Total samples with expression: 551.
- AD = 198.
- Control = 229.
- MCI = 124.

Validation results:

| Model | Role | GSE140829 AD vs Control AUC | 95% CI | Decision |
|---|---|---:|---|---|
| `sig_dev_p_k3` | Frozen primary gene-only model | 0.554 | 0.500-0.604 | Fail |
| `glmnet_dev_auc_k5_a05_lambda.min_clin` | Frozen primary integrated model | 0.567 | 0.513-0.620 | Fail |
| `refit_glmnet_dev_p_k100_a05_lambda.1se_gene` | Train+development refit without GSE140829 labels | 0.569 | 0.517-0.624 | Fail |

Route A status: **FAIL_SWITCH_TO_ROUTE_B**.

Decision: stop diagnostic-model rescue. Do not tune classifiers against GSE140829. Proceed with Route B.
