# Route B Manuscript V1.1 Citation and Reproducibility Audit

Date: 2026-05-01

Manuscript checked: `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_1.md`

## Scope

This audit records the V1.1 changes requested before full peer-style review:

- strengthened Introduction literature context;
- converted placeholder references into numbered working references;
- added R version, package versions, and executable script names to Methods;
- preserved the Route B claim that the study shows limited diagnostic transferability rather than a successful diagnostic model.

## Citation Additions

V1.1 added or formalized references for:

1. dementia and AD burden, using the WHO dementia fact sheet;
2. biomarker-oriented AD research framing, using the NIA-AA research framework;
3. earlier AD blood-expression work and AddNeuroMed-related transcriptomic literature;
4. primary GEO accession pages for GSE63060, GSE63061, GSE85426, and GSE140829;
5. prediction-model reporting expectations, using TRIPOD;
6. software and database citations for limma, glmnet, pROC, clusterProfiler, ReactomePA, and Reactome.

## Source Traceability

Primary source pages consulted during V1.1:

- WHO dementia fact sheet: https://www.who.int/news-room/fact-sheets/detail/dementia
- GSE63060: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63060
- GSE63061: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63061
- GSE85426: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE85426
- GSE140829: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE140829
- TRIPOD statement source search and bibliographic cross-check
- Package citation source search for limma, glmnet, pROC, clusterProfiler, ReactomePA, and Reactome

## Software Versions Added to Methods

R version:

- R 4.5.3

R packages:

- data.table 1.17.8
- limma 3.66.0
- ggplot2 4.0.3
- glmnet 4.1.10
- pROC 1.19.0.1
- clusterProfiler 4.18.4
- org.Hs.eg.db 3.22.0
- ReactomePA 1.54.0
- AnnotationDbi 1.72.0
- GO.db 3.22.0
- KEGGREST 1.50.0
- patchwork 1.3.2
- png 0.1.9

## Script Chain Added to Methods

- `freeze_s1_geo_metadata.py`
- `s2_preprocess_qc.R`
- `s3_limma_deg.R`
- `s4_external_validation.R`
- `s5_model_optimization.R`
- `s5_gse85426_posthoc_upper_bound.R`
- `s5_train_dev_refit_final_validation.R`
- `s6_risk_route_dataset_scan.R`
- `s7_route_a_gse140829_validation.R`
- `s8_route_b_b1_evidence_consolidation.R`
- `s9_route_b_b2_stable_unstable_gene_sets.R`
- `s10_route_b_b3_pathway_enrichment.R`
- `s11_route_b_b4_transportability_audit.R`

## Mechanical Checks

- Approximate word count after V1.1 expansion: 4138 words.
- Introduction expanded from 5 paragraphs to 7 paragraphs.
- Dataset accessions now carry in-text citations.
- Software tools now carry in-text citations.
- Methods now include the local R/package environment.
- Methods now include staged script names.

## Remaining Citation Risks

This audit is not the final submission-level citation check. Before submission, the following still need a formal pass:

- confirm DOI/PMID details for every non-GEO article in the selected journal style;
- decide whether the target journal prefers GEO accessions in References, Data Availability, or both;
- verify whether the final reference list should cite the most recent Reactome database paper or the ReactomePA package alone;
- confirm all package citations against `citation("package")` output in the final R environment;
- add any target-journal-required dataset citation wording.

## Gate Result

V1.1 citation/reproducibility revision status: **PASS_TO_FULL_REVIEW_WITH_MINOR_CITATION_RISK**.

The manuscript is now suitable for a full academic-paper-reviewer assessment, but it is not yet a submission-ready reference package.
