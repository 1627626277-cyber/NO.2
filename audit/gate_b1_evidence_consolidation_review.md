# Gate B1 Evidence Consolidation Review

Review date: 2026-05-01 11:26:03

## Decision

Gate B1 status: **PASS_ROUTE_B_FRAMING**

## Quantitative Basis

- GSE63061: mapped=476; direction concordance=0.989; nominal concordant=448; FDR concordant=395; median oriented AUC=0.637
- GSE85426: mapped=451; direction concordance=0.749; nominal concordant=35; FDR concordant=0; median oriented AUC=0.537
- GSE140829: mapped=460; direction concordance=0.898; nominal concordant=122; FDR concordant=5; median oriented AUC=0.534

## Model-Level Evidence

- primary_gene_only / GSE63060: AUC=0.875
- primary_gene_only / GSE63061: AUC=0.781
- primary_gene_only / GSE85426: AUC=0.567
- primary_gene_only / GSE140829: AUC=0.554
- primary_integrated_or_clinical / GSE63060: AUC=0.876
- primary_integrated_or_clinical / GSE63061: AUC=0.784
- primary_integrated_or_clinical / GSE85426: AUC=0.568
- primary_integrated_or_clinical / GSE140829: AUC=0.567
- train_dev_refit_selected / GSE63060+GSE63061: AUC=0.843
- train_dev_refit_selected / GSE85426: AUC=0.587
- train_dev_refit_selected / GSE140829: AUC=0.569

## Required Next Step

- Proceed to B2 stable vs unstable gene-set construction.
- Do not resume diagnostic classifier optimization unless a new independent dataset or a new endpoint is introduced.
