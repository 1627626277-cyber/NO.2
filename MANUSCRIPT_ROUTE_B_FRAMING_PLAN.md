# Route B Manuscript Framing Plan

Generated at: 2026-05-01

## Manuscript Positioning

Article type: original research article / bioinformatics validation study.

Target positioning: Q4-oriented, Q3 only if reviewer-facing novelty is strengthened around external-validation methodology and transportability audit.

Working central claim:

Peripheral blood transcriptomic signals associated with Alzheimer's disease are reproducible in a related cohort but show limited diagnostic transferability across independent platforms and cohorts. Stable transportable genes show conservative enrichment for translation and RNA-processing pathways, whereas non-transportable genes lack coherent pathway enrichment.

Do not claim:

- A robust diagnostic biomarker.
- A clinically useful classifier.
- A validated cross-cohort diagnostic signature.
- A disease-specific mechanism proven by enrichment.

## Title Options

Preferred:

Peripheral blood transcriptomic signatures of Alzheimer's disease show cohort-dependent reproducibility and limited diagnostic transferability

Conservative alternative:

Cross-cohort transportability of Alzheimer's disease blood transcriptomic signatures: reproducibility, degradation, and pathway context

Methods-emphasis alternative:

A multi-cohort validation audit of Alzheimer's disease blood transcriptomic signatures reveals limited cross-platform diagnostic transferability

Avoid title wording:

- robust biomarker
- diagnostic model
- clinically useful
- validated signature

## Structured Abstract Skeleton

Background:
Peripheral blood transcriptomic studies of Alzheimer's disease have proposed diagnostic signatures, but their reproducibility and transferability across cohorts and platforms remain uncertain.

Methods:
We used GSE63060 as the discovery cohort, GSE63061 as a related validation cohort, and GSE85426 plus GSE140829 as cross-platform validation cohorts. Differential-expression candidates were frozen in the discovery cohort and evaluated for mapping, direction concordance, nominal and FDR-level replication, gene-level oriented AUC, signature/model AUC, stable/unstable transportability classes, and pathway enrichment.

Results:
The discovery-derived candidate set replicated strongly in GSE63061, with direction concordance of 0.989, 448 nominally concordant genes, 395 FDR-concordant genes, and best model AUC of 0.784. In contrast, cross-platform transferability was weaker in GSE85426 and GSE140829, where best model AUC values were 0.587 and 0.569, respectively, with 0 and 5 FDR-concordant genes. Strict stable genes numbered 103 and were enriched for ribosomal translation and RNA-processing pathways, whereas the 235 unstable genes showed no FDR-significant GO, KEGG, or Reactome enrichment.

Conclusion:
AD-related blood transcriptional signals are detectable and partially reproducible, but their diagnostic transferability is limited across independent platforms. These results support cautious use of public blood transcriptomic signatures and highlight the need for strict external validation before clinical biomarker claims.

Keywords:
Alzheimer's disease; peripheral blood; transcriptomics; external validation; transportability; diagnostic transferability; public datasets; pathway enrichment.

## Results Architecture

### Result 1: Dataset Design and Discovery Freeze

Message:
The analysis separates discovery, related validation, and cross-platform validation to prevent validation leakage.

Evidence:

- GSE63060 discovery: 145 AD / 104 Control.
- GSE63061 related validation: 139 AD / 134 Control.
- GSE85426 cross-platform stress test: 90 AD / 90 Control.
- GSE140829 large cross-platform validation: 198 AD / 229 Control plus 124 MCI.

Figure:

- `figures/route_b/B4_main_figure1_dataset_workflow.png`

### Result 2: Related-Cohort Reproducibility Versus Cross-Platform Degradation

Message:
The signal is not random, but it is cohort-dependent.

Evidence:

- GSE63061: direction concordance 0.989; FDR-concordant genes 395.
- GSE85426: direction concordance 0.749; FDR-concordant genes 0.
- GSE140829: direction concordance 0.898; FDR-concordant genes 5.

Figure:

- `figures/route_b/B4_main_figure2_validation_heatmap.png`

### Result 3: Diagnostic Model AUC Decay

Message:
Model performance decays below the diagnostic threshold in independent cross-platform cohorts.

Evidence:

- Best GSE63061 model AUC: 0.784.
- Best GSE85426 model AUC: 0.587.
- Best GSE140829 model AUC: 0.569.
- Primary model development-to-cross-platform AUC drops exceed 0.21.

Figure:

- `figures/route_b/B4_main_figure3_auc_and_scores.png`

### Result 4: Stable and Unstable Transportability Classes

Message:
A strict stable subset exists, but a large unstable subset shows reversal or signal loss.

Evidence:

- Strict stable genes: 103.
- Directional stable sensitivity genes: 327.
- Unstable genes: 235.
- Stable/unstable primary-set overlap: 0.

Table:

- `results/route_b_stable_genes.csv`
- `results/route_b_unstable_genes.csv`

### Result 5: Pathway Context of Transportable Genes

Message:
Stable transportable genes are enriched for broad translation and RNA-processing modules; unstable genes do not show coherent enrichment.

Evidence:

- Strict stable: GO BP = 12, KEGG = 2, Reactome = 52 FDR-significant terms.
- Unstable: GO BP = 0, KEGG = 0, Reactome = 0 FDR-significant terms.

Figure:

- `figures/route_b/B4_main_figure4_pathway_comparison.png`

## Discussion Blueprint

Paragraph 1:
Summarize the main finding: AD-related blood transcriptional signals replicate in a related cohort but diagnostic transferability decays across platforms.

Paragraph 2:
Interpret why GSE63061 performs strongly: related platform/cohort structure, shared preprocessing context, and biological overlap.

Paragraph 3:
Interpret why GSE85426 and GSE140829 degrade: platform differences, cohort ascertainment, phenotype composition, blood-cell composition, and public-data heterogeneity.

Paragraph 4:
Discuss stable genes: conservative ribosomal translation and RNA-processing modules; frame as transportable transcriptional background, not disease-specific mechanism.

Paragraph 5:
Discuss unstable genes: large non-transportable component, lack of coherent enrichment, and risk of overfitting in single-cohort biomarker studies.

Paragraph 6:
Clinical implication: public blood transcriptomic models require strict independent validation before diagnostic claims.

Limitations:

- Public dataset reanalysis only; no wet-lab validation.
- Heterogeneous platforms and metadata.
- Blood-cell composition cannot be fully controlled.
- Enrichment results are pathway context, not causal mechanism.
- MCI analysis is exploratory and partial.

Conclusion:
Use the exact phrase "limited diagnostic transferability" and avoid "validated diagnostic biomarker."

## Figure and Table Package

Main figures:

1. Dataset workflow and cohort roles.
2. Validation heatmap of mapping, direction, FDR replication, gene AUC, and model AUC.
3. AUC decay plus GSE140829 score distributions.
4. Stable-vs-unstable pathway comparison.

Main tables:

1. Dataset characteristics and roles.
2. Cross-cohort transportability metrics.
3. Stable and unstable gene-set summary.
4. Significant pathway enrichment terms.

Supplementary tables:

- Full candidate DEG table.
- Full validation table.
- Model AUC grid and post-hoc upper-bound table.
- Stable/unstable full gene lists.
- Full GO/KEGG/Reactome enrichment tables.
- Claim audit table.

## Gate B5 Decision

Gate B5 status: **PASS_TO_B6_SUBMISSION_STRATEGY**.

Reason:

The manuscript framing is aligned with the actual evidence, avoids overstated diagnostic claims, and has a coherent results structure for a Q4-oriented validation paper.
