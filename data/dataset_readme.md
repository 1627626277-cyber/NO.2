# S1 Dataset Freeze README

Generated at: 2026-04-30T22:08:14

## Frozen datasets

### GSE63060

- Role: training_candidate
- GEO page: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63060
- Series title: Alzheimer, MCI and control samples from AddneuroMed Cohort (batch 1)
- Platform: GPL6947
- Type: Expression profiling by array
- Design: The design is case-control. Cases are either Alzheimer's disease patients, subjects with mild cognitive impairment or age and gender matched controls.

### GSE63061

- Role: external_validation_1
- GEO page: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63061
- Series title: Alzheimer, Mild Cognitive impairment and control samples from AddneuroMed Cohort (batch 2)
- Platform: GPL10558
- Type: Expression profiling by array
- Design: The design is case-control. Cases are either Alzheimer's disease patients, subjects with mild cognitive impairment or age and gender matched controls.

### GSE85426

- Role: external_validation_2
- GEO page: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE85426
- Series title: Peripheral blood gene expression as a biomarker for early detection of Alzheimer’s disease
- Platform: GPL14550
- Type: Expression profiling by array
- Design: Total RNA from peripheral blood cells was extracted, reverse-transcribed and labelled, then analysed for gene expression using GeneSpring GX12 (Agilent Technologies, USA). About 180 samples (AD=90, Non-demented control=90) was used for microarray analysis.

## Outputs

- `data/data_inventory.csv`: downloaded files, source URLs, sizes, SHA-256 checksums.
- `data/sample_sheet.csv`: parsed GEO sample metadata and AD/Control inclusion flag.
- `data/primary_inclusion_locked.csv`: locked primary AD/Control sample list for downstream analysis.
- `audit/s1_sample_summary.csv`: counts by dataset and normalized diagnosis.

## Gate 1 status

Pass for data freeze. Files, initial sample metadata, and the locked AD/Control inclusion list are frozen.
S2 preprocessing should use `data/primary_inclusion_locked.csv` as the sample source of truth.
