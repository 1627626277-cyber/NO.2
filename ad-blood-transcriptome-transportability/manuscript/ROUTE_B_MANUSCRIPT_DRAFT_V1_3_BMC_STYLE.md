# External validation audit of peripheral blood transcriptomic signatures in Alzheimer's disease reveals cohort-dependent reproducibility and limited transferability

Zhuang Jiang1*

1 Guangdong University of Petrochemical Technology (GDUPT), 139 Guandu 2nd Road, Maoming 525000, Guangdong, China

*Correspondence: Zhuang Jiang, 1627626277@qq.com

ORCID: https://orcid.org/0009-0007-4388-5901

## Abstract

### Background

Peripheral blood transcriptomic profiles have been proposed as Alzheimer's disease (AD) biomarker signatures, but their cross-cohort reproducibility and transferability remain uncertain.

### Methods

We performed a staged transferability audit of public peripheral blood transcriptomic datasets. GSE63060 was used as the discovery cohort, GSE63061 as a related validation cohort, GSE85426 as an independent cross-platform stress-test cohort, and GSE140829 as a large independent external validation cohort. GSE63060 differential-expression candidates were frozen using age/sex-adjusted linear modeling. Validation analyses quantified candidate-gene mapping, direction concordance, nominal and FDR-level replication, gene-level oriented AUC, signature/model AUC with 95% confidence intervals (CIs), stable and unstable transportability classes, and pathway enrichment. GSE85426 and GSE140829 were not used to optimize candidate selection or tune models.

### Results

The discovery-derived candidate set showed strong related-cohort reproducibility in GSE63061, with 476/476 mapped genes, direction concordance of 0.989, 448 nominally concordant genes, 395 targeted FDR-concordant genes, median oriented gene-level AUC of 0.637, and highest AUC among the frozen candidate models of 0.784 (95% CI, 0.731-0.838). In contrast, independent validation was weaker. GSE85426 mapped 451/476 candidates but showed direction concordance of 0.749, 35 nominally concordant genes, no targeted FDR-concordant genes, median oriented AUC of 0.537, and highest AUC among the frozen candidate models of 0.587 (95% CI, 0.503-0.671). GSE140829 mapped 460/476 candidates and showed direction concordance of 0.898, 122 nominally concordant genes, 5 targeted FDR-concordant genes, median oriented AUC of 0.534, and highest AUC among the frozen candidate models of 0.569 (95% CI, 0.515-0.624). Strict stable genes numbered 103, whereas 235 genes were classified as unstable. Stable genes were enriched for translation, ribosomal, and RNA-processing pathways, while unstable genes showed no FDR-significant GO BP, KEGG, or Reactome enrichment.

### Conclusions

AD-related peripheral blood transcriptional signals are detectable and can reproduce strongly in a related cohort, but their transferability is limited in independent validation. These findings support a cautious interpretation of public blood transcriptomic signatures and reinforce the need for strict external validation before biomarker claims.

Keywords: Alzheimer's disease; peripheral blood; transcriptomics; external validation; transferability audit; reproducibility; public datasets; pathway enrichment.

## Background

Alzheimer's disease (AD) is the most common cause of dementia and a major contributor to disability and care burden in ageing populations. The World Health Organization estimates that 57 million people were living with dementia worldwide in 2021 and that AD may account for 60-70% of dementia cases [1]. Contemporary research criteria increasingly define AD through biological processes, particularly amyloid, tau, and neurodegeneration biomarkers, rather than through clinical symptoms alone [2]. This biomarker shift has strengthened disease classification, but many established biomarkers still rely on cerebrospinal fluid, positron-emission tomography, or specialized assays that are not equally accessible in all settings.

Blood-based molecular readouts are therefore attractive for AD research because peripheral sampling is comparatively scalable, repeatable, and compatible with large cohorts. Whole-blood or peripheral-blood transcriptomic profiles are one such readout. They may capture immune activation, inflammatory tone, metabolic state, cellular composition, and systemic physiological changes that accompany neurodegenerative disease. Earlier blood biomarker reviews emphasized both the promise of minimally invasive assays and the difficulty of achieving reproducible performance across cohorts [3,4]. Blood gene-expression studies have reported AD-associated classifiers or candidate markers using whole-blood or leukocyte transcriptomic profiles, including early microarray classifiers, leukocyte biomarker work, and AddNeuroMed-based signatures for cognitive impairment or early AD detection [5-8]. These findings helped establish peripheral blood transcriptomics as a plausible exploratory biomarker domain.

At the same time, blood transcriptomic signatures are exposed to multiple sources of instability. Measured expression can vary with blood-cell composition, age, sex, medication exposure, comorbidity, RNA handling, microarray chemistry, preprocessing, probe annotation, and cohort recruitment. These factors are not merely technical nuisances: they can create signatures that appear strong in one cohort yet fail to retain direction, statistical support, or diagnostic discrimination elsewhere. For this reason, a clinically oriented biomarker claim requires strict external validation rather than only internal resampling or validation in a closely related dataset.

Public transcriptomic repositories make this problem testable. The Gene Expression Omnibus (GEO) contains multiple peripheral-blood AD microarray datasets with AD, mild cognitive impairment (MCI), and control samples. GSE63060 and GSE63061 are AddNeuroMed blood-expression datasets generated in related study contexts but on different Illumina HumanHT-12 platform versions [9,10]. GSE85426 is an independent Agilent blood microarray dataset with 90 AD cases and 90 non-demented controls [11]. GSE140829 is a large independent peripheral-blood expression dataset spanning AD, MCI, controls, and other dementia disorders, with a reported innate immune inflammatory signal across neurodegenerative conditions [12]. Together, these datasets permit a staged assessment of related-cohort reproducibility, cross-platform stress testing, and additional independent external validation.

Many public-data biomarker studies emphasize the best-performing model after feature filtering, threshold selection, or repeated dataset reuse. That practice can lead to optimistic conclusions when external datasets influence candidate selection or model tuning. Reporting guidance for prediction models, including TRIPOD, stresses transparent separation of model development and validation, because diagnostic performance estimates are difficult to interpret when the validation role is blurred [13]. In AD blood transcriptomics, the distinction is especially important: a signature that performs well in a related AddNeuroMed-like cohort may still be insufficiently transferable to an independent cohort with different platform chemistry or recruitment.

We therefore designed this study as a transferability audit rather than as a search for a high-performance diagnostic classifier. GSE63060 was used for discovery, GSE63061 for related-cohort validation, GSE85426 for independent cross-platform stress testing, and GSE140829 for sequential additional independent external validation. The central question was not whether a model could be tuned until it exceeded an AUC threshold in a known validation set, but whether a discovery-derived blood transcriptional signal retained direction, statistical support, and discrimination across increasingly independent validation contexts.

The study had four objectives. First, we quantified candidate-gene reproducibility across validation cohorts using mapping rate, direction concordance, nominal replication, FDR-level replication, and gene-level oriented AUC. Second, we evaluated whether simple and penalized models selected without using final validation labels retained performance in independent validation. Third, we separated stable transportable genes from unstable genes that reversed direction or lost external-validation signal. Fourth, we tested whether stable and unstable gene sets had coherent pathway context. This framing allows external-validation failure to be treated as the main empirical finding, not as an inconvenient negative result.

## Methods

### Study design

This was a retrospective public-data bioinformatics validation study. The analysis followed a staged design with prespecified dataset roles. GSE63060 was used as the discovery cohort. GSE63061 was used as a related external validation cohort because it comes from the same broad AddNeuroMed context but a different batch/platform. GSE85426 was used as an independent cross-platform stress-test cohort. GSE140829 was used as a sequential additional large independent external validation cohort. Candidate selection, model selection, and refit decisions were completed without using GSE140829 labels, and GSE140829 was used only to test whether already frozen analysis rules and signatures generalized to a larger independent dataset.

All datasets were publicly available and de-identified. No new human-subject recruitment, intervention, or sample collection was performed.

### Datasets and sample inclusion

The primary discovery dataset was GSE63060, an AddNeuroMed peripheral blood microarray dataset measured on GPL6947 Illumina HumanHT-12 V3.0 expression beadchip [9]. The locked AD-versus-control analysis included 145 AD cases and 104 controls.

The related validation dataset was GSE63061, an AddNeuroMed peripheral blood microarray dataset measured on GPL10558 Illumina HumanHT-12 V4.0 expression beadchip [10]. The locked AD-versus-control analysis included 139 AD cases and 134 controls.

The independent cross-platform stress-test dataset was GSE85426, a peripheral blood microarray dataset measured on GPL14550 Agilent-028004 SurePrint G3 Human GE 8x60K Microarray [11]. The locked AD-versus-control analysis included 90 AD cases and 90 controls.

The sequential additional independent external validation dataset was GSE140829, a large peripheral blood expression dataset measured on GPL15988 HumanHT-12 v4 Expression BeadChip [12]. The analyzable normalized expression subset contained 198 AD cases, 229 controls, and 124 MCI samples. AD-versus-control discrimination was the primary endpoint, while MCI score placement was retained as exploratory context only.

### Data freeze and quality control

Raw and normalized GEO files were downloaded and recorded with source URLs, file sizes, and SHA-256 checksums. Sample metadata were parsed from the GEO series matrix files, and AD/control inclusion was locked before modeling. Dataset-level quality control checked feature counts, sample counts, missingness, expression distributions, and PCA structure. Processed expression matrices were stored as RDS files and were not redefined during downstream modeling.

### Discovery differential-expression analysis

Differential expression was performed in GSE63060 only. Linear models were fitted using limma with diagnosis as the main coefficient and age and sex as covariates when available [14]. Candidate genes were selected using Benjamini-Hochberg adjusted P < 0.05 and absolute log fold-change >= 0.20. Probe annotation used GEO platform files where available. When a probe annotation field contained multiple symbols or Entrez identifiers, the first non-empty token separated by common GEO delimiters was used. Candidate genes were collapsed to unique gene symbols by retaining the probe with the lowest adjusted P value and, if needed, the larger absolute log fold-change. The main discovery output contained 623 candidate probes, 546 annotated candidate probes, and 476 unique genes. GSE63061, GSE85426, and GSE140829 were not used to select discovery candidates.

### Candidate-gene mapping and external validation

Discovery candidates were mapped into each validation dataset at the Entrez gene or gene-symbol level depending on the available platform annotation. For GSE63061, GPL10558 annotation was used. For GSE85426, row-name Entrez suffixes were used because a standard GEO platform annotation file was not available in the analysis workflow; rows without a numeric Entrez suffix were excluded from gene-level mapping. This retained 10,775 gene-mapped rows from 14,113 original rows and mapped 451/476 discovery-derived candidate genes, leaving 25 unmapped candidates. For GSE140829, the normalized expression matrix used gene symbols as row identifiers. In validation datasets with multiple probes mapping to the same Entrez gene, probe-level variance was calculated on the normalized expression matrix and the highest-variance probe was retained as the gene-level representative. Ambiguous or unmapped rows were not used for gene-level replication statistics. Expression columns were matched to locked sample metadata before modeling, and scripts stopped when metadata and matrix order did not align.

For each validation cohort, gene-level validation models estimated the AD-versus-control log fold-change while adjusting for available covariates. Direction concordance was defined as agreement between the sign of the GSE63060 discovery log fold-change and the validation log fold-change. Nominal concordance required direction concordance and validation P < 0.05. FDR concordance required direction concordance and validation adjusted P < 0.05. For validation-cohort gene-level replication, Benjamini-Hochberg targeted replication FDR was applied within the mapped discovery-derived candidate-gene universe in each validation dataset, rather than across the whole measured transcriptome. Gene-level oriented AUC was calculated using the validation expression value multiplied by the sign of the discovery log fold-change, so that higher oriented values consistently represented the discovery AD direction.

### Signature and model evaluation

The main modeling analyses used frozen discovery and validation roles. GSE63060 was used for training, GSE63061 for model selection or development evaluation, and GSE85426 for final stress testing. Primary models included a signed mean gene-only signature and an integrated penalized model including gene features plus age and sex where available. Gene-expression inputs were row-wise z-scored within each dataset before signature scoring or penalized modeling. Because expression features were standardized within each cohort, the modeling analysis should be interpreted as a cohort-level transferability audit rather than as a deployable single-sample diagnostic assay. Age was standardized using the GSE63060 training mean and standard deviation, and sex was encoded as a binary male indicator.

Penalized models were fitted with glmnet binomial models [15]. Candidate model grids included ranked feature sets of 5, 10, 15, 20, 30, 50, 100, or all mapped candidate genes; alpha values of 0, 0.5, or 1; lambda.min or lambda.1se selection; and gene-only or gene-plus-age/sex covariate modes. Five-fold cross-validation used AUC as the internal selection metric. glmnet standardization was disabled because gene features had already been z-scored and age had been standardized. A train-development refit model was also evaluated by refitting on GSE63060 plus GSE63061 without using GSE85426 or GSE140829 labels for tuning. After model rules had been locked, the same locked signatures and label-independent model rules were evaluated in GSE140829 as a sequential additional independent external validation cohort without label-driven optimization.

The prespecified performance threshold was AUC >= 0.70 in an independent validation cohort. This was a pragmatic study gate used to prevent weak independent-validation discrimination from being interpreted as diagnostic evidence; it was not defined as a threshold for clinical adequacy. AUC 95% CIs for model-level AD-versus-control discrimination were estimated with DeLong intervals using pROC, with AD specified as the higher-score event. Models that did not meet this threshold were not interpreted as supporting clinical use. Because no model achieved this gate in independent validation, calibration, sensitivity, specificity, and decision-curve analyses were not emphasized as clinical performance summaries.

### Stable and unstable transportability classes

Stable and unstable gene sets were constructed after independent-validation performance was judged insufficient for clinical model interpretation. The strict stable set required nominal concordance in GSE63061, direction concordance in all mapped independent validation cohorts, and nominal concordance in at least one independent validation cohort. A directional stable sensitivity set required direction concordance in GSE63061 and all mapped independent validation cohorts. The unstable set required nominal concordance in GSE63061 but failure to meet the strict stable definition, together with either independent-validation direction reversal or independent-validation signal loss. Signal loss was defined as no nominal independent-validation support and maximum independent-validation oriented AUC < 0.55.

### Pathway enrichment

Pathway over-representation analysis was performed separately for strict stable, directional stable sensitivity, and unstable gene sets. The main background was the full S3 candidate gene universe, because the biological question was whether transportable genes differed from the pool of discovery-derived AD blood transcriptional candidates. GO Biological Process, KEGG, and Reactome analyses were performed with Benjamini-Hochberg FDR control within each gene-set/database analysis using clusterProfiler and ReactomePA, with Reactome pathway definitions interpreted against the Reactome Pathway Knowledgebase [17-20]. Enrichment results were used as biological context and not as causal evidence.

### Blood-cell marker-score sensitivity analysis

Because measured whole-blood expression can reflect blood-cell composition, an exploratory marker-score sensitivity analysis was performed for the strict stable gene set. Neutrophil, monocyte, and lymphocyte proxy scores were calculated within each validation cohort as mean row-wise z-scores of available marker genes. Strict stable genes were then re-tested with limma models including diagnosis, available age and sex covariates, GSE140829 batch where applicable, and the three marker scores. This analysis was intended as a coarse sensitivity check rather than formal cell-type deconvolution.

### Statistical analysis and reproducibility

AUC values were calculated using rank-based or ROC-based methods depending on the analysis stage; ROC analyses and model-level AUC 95% CIs used pROC where applicable [16]. Differential-expression P values in the discovery analysis were adjusted by the Benjamini-Hochberg method across the modeled GSE63060 feature universe. Validation-cohort targeted replication FDR was adjusted within the mapped discovery-derived candidate-gene universe, and pathway-enrichment FDR was adjusted within each tested database and gene-set comparison. Analyses were run in R 4.5.3 with data.table 1.17.8, limma 3.66.0, ggplot2 4.0.3, glmnet 4.1.10, pROC 1.19.0.1, clusterProfiler 4.18.4, org.Hs.eg.db 3.22.0, ReactomePA 1.54.0, AnnotationDbi 1.72.0, GO.db 3.22.0, KEGGREST 1.50.0, patchwork 1.3.2, and png 0.1.9.

The executable analysis chain is stored in the project `scripts/` directory and is organized as sequential scripts S1-S13 covering GEO source freeze, preprocessing and QC, discovery differential expression, initial external validation, model evaluation and refit testing, additional independent validation assessment, evidence consolidation, stable/unstable gene-set construction, pathway enrichment, transportability-audit figures and tables, AUC confidence intervals, demographic/mapping audit tables, and blood-cell marker-score sensitivity analysis. Exact script filenames and output paths are listed in the supplementary reproducibility traceability table. Main outputs are stored in `results/`, figures in `figures/`, and audit reports in `audit/`.

## Results

### Dataset roles were separated to prevent validation leakage

The final analysis used four datasets with distinct roles. GSE63060 was the discovery cohort with 145 AD cases and 104 controls. GSE63061 was the related validation cohort with 139 AD cases and 134 controls. GSE85426 was the independent cross-platform stress-test cohort with 90 AD cases and 90 controls. GSE140829 was the large independent external validation cohort with 198 AD cases, 229 controls, and 124 MCI samples in the analyzable normalized expression subset.

This design separated discovery, related-cohort validation, cross-platform stress testing, and sequential additional independent validation. Candidate selection was restricted to GSE63060, and the independent validation datasets were not used to tune feature thresholds or optimize models. The staged design is summarized in Figure 1.

### Discovery-derived candidates replicated strongly in the related validation cohort

The GSE63060 discovery analysis identified 476 unique candidate genes after annotation and gene-level consolidation. In GSE63061, all 476 candidates were mapped. Direction concordance was 0.989, with 471 genes showing the same AD direction as in the discovery cohort. Nominal concordance was observed for 448 genes, and 395 genes remained concordant at FDR < 0.05. The median oriented gene-level AUC was 0.637, and the maximum oriented gene-level AUC was 0.761.

Model-level performance in the related validation context was also high. The primary gene-only model reached AUC 0.781 (95% CI, 0.727-0.834) in GSE63061, and the primary integrated model reached AUC 0.784 (95% CI, 0.731-0.838). These results indicate that the discovery-derived signal was not random within the related AddNeuroMed-like validation context.

### Independent validation showed substantial degradation

The same candidate set transferred less well to GSE85426, the cross-platform stress-test cohort. Of 476 discovery-derived genes, 451 were mapped. Direction concordance remained above chance at 0.749, but only 35 genes were nominally concordant and none were targeted FDR-concordant after Benjamini-Hochberg correction within the mapped candidate-gene universe. The median oriented gene-level AUC was 0.537, close to a weak discrimination range, although the maximum oriented gene-level AUC reached 0.652.

GSE140829, the large independent external validation cohort, showed a different but still limited pattern. Mapping was high, with 460/476 genes available. Direction concordance was 0.898, higher than in GSE85426, but targeted replication FDR support remained limited, with 122 nominally concordant genes and only 5 targeted FDR-concordant genes after candidate-universe correction. The median oriented gene-level AUC was 0.534 and the maximum oriented gene-level AUC was 0.604. Thus, high direction concordance in GSE140829 did not translate into strong gene-level discrimination.

The cross-cohort transportability heatmap is shown in Figure 2.

### Model performance decayed below the prespecified threshold

Model performance showed the clearest evidence of limited transferability. The primary gene-only model had AUC 0.875 (95% CI, 0.832-0.918) in GSE63060 and 0.781 (95% CI, 0.727-0.834) in GSE63061, but fell to 0.567 (95% CI, 0.483-0.651) in GSE85426 and 0.554 (95% CI, 0.500-0.609) in GSE140829. The primary integrated model had AUC 0.876 (95% CI, 0.833-0.919) in GSE63060 and 0.784 (95% CI, 0.731-0.838) in GSE63061, but fell to 0.568 (95% CI, 0.484-0.653) in GSE85426 and 0.567 (95% CI, 0.512-0.621) in GSE140829.

A train-development refit model selected without final validation labels reached AUC 0.843 in combined GSE63060 plus GSE63061 training and AUC 0.587 (95% CI, 0.503-0.671) in GSE85426 and 0.569 (95% CI, 0.515-0.624) in GSE140829. No primary or frozen refit model achieved the prespecified independent-validation AUC threshold of 0.70.

The AUC drop from GSE63061 to the independent validation datasets exceeded 0.21 for both primary models. This supports the interpretation that model performance is cohort-dependent and not consistently transferable across independent validation settings. AUC decay and exploratory GSE140829 MCI score placement are shown in Figure 3. MCI score placement was intermediate between control and AD in 2 of 3 model summaries and was treated as exploratory support only.

### Stable and unstable gene sets separated transportable from non-transportable signals

After independent-validation degradation was established, candidate genes were classified by transportability. The near-cohort directional anchor included 471 genes, and the near-cohort nominal anchor included 448 genes. The strict stable primary set contained 103 genes. A broader directional stable sensitivity set contained 327 genes. The unstable primary set contained 235 genes, including 139 genes with independent-validation reversal and 190 genes with independent-validation signal loss. The strict stable and unstable primary sets had no gene overlap.

These results show that a transportable component exists, but a large part of the discovery-derived signal is unstable across independent validation contexts.

### Stable genes showed conservative pathway context, whereas unstable genes lacked coherent enrichment

The strict stable set showed significant pathway enrichment under the candidate-background analysis. It had 12 significant GO BP terms, 2 significant KEGG terms, and 52 significant Reactome terms at FDR < 0.05. Enriched modules were dominated by cytoplasmic translation, ribosomal biology, rRNA processing, and RNA-processing pathways. The directional stable sensitivity set retained Reactome support, with 45 significant Reactome terms and 2 significant KEGG terms, although GO BP support was weaker.

In contrast, the unstable primary set showed no FDR-significant GO BP, KEGG, or Reactome enrichment. These results suggest that the stable transportable subset has a coherent but conservative biological context, whereas non-transportable genes do not form a clear enriched pathway module. The pathway comparison is summarized in Figure 4.

### Marker-score sensitivity supported cautious interpretation

The blood-cell marker-score sensitivity analysis had usable marker coverage in all validation cohorts. Neutrophil, monocyte, and lymphocyte marker coverage was 8/8, 8/8, and 7/8 genes in GSE63061; 4/8, 7/8, and 7/8 genes in GSE85426; and 8/8, 8/8, and 7/8 genes in GSE140829. After marker-score adjustment, strict stable genes retained discovery-concordant direction for 103/103 mapped genes in GSE63061 and 99/102 mapped genes in GSE140829, but this fell to 69/100 mapped genes in GSE85426. Nominal concordance after marker-score adjustment was 97/103 in GSE63061, 12/100 in GSE85426, and 26/102 in GSE140829.

These results did not rescue the diagnostic interpretation of the frozen models. Instead, they suggest that broad blood-cell marker scores do not fully explain the related-cohort and GSE140829 stable-gene directionality, while the attenuation in GSE85426 reinforces the need to treat the stable pathway signal as conservative biological context rather than as cell-composition-independent AD biology.

## Discussion

This study evaluated the cross-cohort transferability of AD peripheral blood transcriptomic signatures using a staged validation design. The central finding is that discovery-derived blood transcriptional signals can reproduce strongly in a related cohort but show limited transferability in independent validation. This distinction is important because a related-cohort validation result alone could support an overly optimistic biomarker interpretation, whereas independent validation reveals substantial degradation.

The findings extend prior blood-transcriptomic AD studies by changing the evidentiary emphasis. Earlier work helped establish that blood expression profiles can contain AD- or ageing-related molecular signals and can yield apparently discriminative signatures in selected cohorts [5-8]. The present analysis does not dispute that premise. Instead, it shows that the same biomarker domain can produce a strong related-cohort result and still fail a stricter external-validation transferability audit. This is a narrower but more defensible contribution for public-data transcriptomics.

The GSE63061 results demonstrate that the discovery-derived signal is not simply random. Mapping was complete, direction concordance was very high, hundreds of genes replicated at FDR < 0.05, and model AUC exceeded 0.78. If the analysis had stopped at GSE63061, the results could have been interpreted as evidence of an apparently promising blood transcriptomic classifier. However, GSE63061 is a related validation cohort, and its strong performance must be interpreted in the context of shared study structure and related platform characteristics.

The independent validation datasets changed the interpretation. In GSE85426, FDR-level replication disappeared and model AUC values remained below 0.59. In GSE140829, direction concordance remained relatively high, but FDR-level replication and discrimination were weak, and model AUC values remained below 0.57. The GSE140829 result is especially informative because it is a large independent external validation cohort, so failure cannot be dismissed only as a sample-size problem. Instead, the result suggests that the measured blood transcriptional signal is sensitive to platform, cohort composition, preprocessing, phenotype definition, or unmeasured biological and technical factors.

These findings do not mean that peripheral blood transcriptomics is uninformative for AD. Rather, they show that evidence standards matter. A signal can be biologically plausible and reproducible in one external context while still lacking the stability required for diagnostic use. For public-data biomarker studies, this is a critical distinction. External validation should include cohorts that differ meaningfully from the discovery cohort; otherwise, model performance may mostly reflect related-cohort reproducibility rather than clinical transferability.

The stable/unstable gene-set analysis adds biological context to the validation results. A strict stable subset of 103 genes was identified, and this subset was enriched for translation, ribosomal, and RNA-processing pathways. These pathways may represent a conservative blood transcriptional background that is more transferable across cohorts than weaker or more context-sensitive signals. However, this enrichment should not be overinterpreted as a disease-specific AD mechanism. Many translation and RNA-processing terms are broad cellular modules, and the current analysis cannot separate AD-related biology from blood-cell composition, systemic physiology, RNA quality, or platform-related measurement stability. The marker-score sensitivity analysis partly addressed this concern: stable-gene directionality was retained in GSE63061 and mostly preserved in GSE140829, but it was attenuated in GSE85426 after adjustment for neutrophil, monocyte, and lymphocyte proxy scores. The stable pathway signal is therefore best interpreted as conservative context for transportability, not as evidence of brain AD pathogenesis.

The unstable gene set was also informative. It contained 235 genes that were nominally reproducible in the related cohort but reversed or lost signal in independent validation. This set showed no FDR-significant GO BP, KEGG, or Reactome enrichment. The absence of coherent enrichment supports the interpretation that unstable genes may reflect heterogeneous cohort-sensitive signals rather than a single consistent biological program.

The modeling results should be read as a cautionary transferability finding. The primary models performed well in training and related validation, but the same models failed to meet the AUC 0.70 threshold in GSE85426 and GSE140829, with 95% CIs that remained compatible with weak discrimination in both independent validation settings. A refit strategy using GSE63060 plus GSE63061 also failed to rescue independent-validation performance. These results argue against presenting the current signature as ready for clinical use. They instead support the need for strict validation, transparent reporting of negative validation results, and interpretation audits before public transcriptomic signatures are promoted as diagnostic biomarkers.

This study has limitations. First, it is based entirely on public transcriptomic datasets and lacks wet-lab validation. Second, microarray platforms and annotation resources differ across cohorts, which can affect mapping and expression comparability. Third, blood-cell composition was assessed only with coarse marker-score proxies rather than formal cell-type deconvolution, and residual cell-composition confounding remains possible. Fourth, metadata harmonization was limited by the information available in GEO records. Fifth, pathway enrichment provides biological context but not causal mechanism. Sixth, MCI analyses in GSE140829 were exploratory and should not be treated as evidence of clinical staging performance.

Despite these limitations, the study provides a reproducible validation audit of AD blood transcriptomic signatures across multiple public cohorts. The results show that related-cohort reproducibility is achievable, but transferability in independent validation remains limited. Future work should combine standardized sample processing, cell-composition adjustment, independent prospective validation, and predefined reporting standards before peripheral blood transcriptomic signatures are advanced as diagnostic tools.

## Conclusions

Peripheral blood transcriptional signatures of AD show strong related-cohort reproducibility but limited transferability in independent validation. Stable transportable genes show conservative enrichment for translation and RNA-processing pathways, while unstable genes lack coherent pathway enrichment. These findings support cautious use of public blood transcriptomic signatures and argue for strict external validation before diagnostic biomarker claims.

## List of abbreviations

AD: Alzheimer's disease; AUC: area under the receiver operating characteristic curve; FDR: false discovery rate; GEO: Gene Expression Omnibus; GO BP: Gene Ontology Biological Process; KEGG: Kyoto Encyclopedia of Genes and Genomes; MCI: mild cognitive impairment; ROC: receiver operating characteristic.

## Declarations

### Ethics approval and consent to participate

Not applicable. This study analyzed publicly available, de-identified datasets and did not involve new recruitment of human participants, new collection of human specimens, or access to directly identifiable private information.

### Consent for publication

Not applicable.

### Availability of data and materials

All datasets analyzed in this study are publicly available from GEO under accessions GSE63060, GSE63061, GSE85426, and GSE140829. Analysis scripts are stored in the project `scripts/` directory. Main outputs are stored in `results/`, figures in `figures/`, and audit reports in `audit/`. The supplementary reproducibility traceability table maps each main manuscript statement to the corresponding script and result file. A public GitHub repository page and manifest for the compact reproducibility package are available at https://github.com/1627626277-cyber/NO.2/tree/main/ad-blood-transcriptome-transportability. Raw GEO files and large intermediate expression matrices are not included in the compact archive because they can be retrieved from GEO or regenerated from the scripts.

### Competing interests

The author declares that there are no competing interests.

### Funding

No specific funding was received for this work.

### Authors' contributions

Z.J. conceived the study, designed the analysis strategy, curated public datasets, performed the computational analysis, interpreted the results, prepared the manuscript, and approved the submitted version. This statement should be revised if additional authors are added before submission.

### Acknowledgements

The author acknowledges the investigators and participants associated with the public GEO resources used in this study.

## Figure Legends

### Figure 1. Staged validation design for the transferability audit

The analysis used GSE63060 as the discovery cohort, GSE63061 as a related validation cohort, GSE85426 as an independent cross-platform stress-test cohort, and GSE140829 as a large independent external validation cohort. Candidate genes and model-selection rules were frozen before the independent validation steps. The figure emphasizes the separation between discovery, related-cohort validation, cross-platform stress testing, and sequential additional independent external validation.

### Figure 2. Cross-cohort transportability audit of discovery-derived candidate genes

Heatmap showing mapping fraction, direction concordance, nominal replication fraction, targeted replication FDR fraction, median gene-level oriented AUC, and highest AUC among the frozen candidate models across validation cohorts. GSE63061 showed strong related-cohort replication, whereas GSE85426 and GSE140829 showed reduced FDR-level replication and model AUC values below 0.70.

### Figure 3. AUC decay and exploratory MCI score placement

The upper panel summarizes AUC values across training, related validation, cross-platform stress testing, and large independent external validation contexts for the primary gene-only model, primary integrated model, and train-development refit model. The dashed line indicates the prespecified AUC threshold of 0.70. The lower panel shows GSE140829 score distributions for Control, MCI, and AD samples using the frozen primary gene-only signature. MCI placement is exploratory and was not used for model optimization.

### Figure 4. Pathway context of stable and unstable transportability classes

The figure compares FDR-significant GO BP, KEGG, and Reactome enrichment yields for the strict stable and unstable gene sets. Stable transportable genes showed significant enrichment dominated by ribosomal translation and RNA-processing pathways, whereas unstable genes did not show FDR-significant enrichment in GO BP, KEGG, or Reactome under the candidate-background analysis.

## References

1. World Health Organization. Dementia. Fact sheet. Available from: https://www.who.int/news-room/fact-sheets/detail/dementia. Accessed 1 May 2026.
2. Jack CR Jr, Bennett DA, Blennow K, Carrillo MC, Dunn B, Haeberlein SB, et al. NIA-AA Research Framework: Toward a biological definition of Alzheimer's disease. Alzheimer's & Dementia. 2018;14(4):535-562. doi:10.1016/j.jalz.2018.02.018.
3. Snyder HM, Carrillo MC, Grodstein F, Henriksen K, Jeromin A, Lovestone S, et al. Developing novel blood-based biomarkers for Alzheimer's disease. Alzheimer's & Dementia. 2014;10(1):109-114. doi:10.1016/j.jalz.2013.10.007.
4. Kiddle SJ, Voyle N, Dobson RJB. A blood test for Alzheimer's disease: progress, challenges, and recommendations. Journal of Alzheimer's Disease. 2018;64(s1):S289-S297. doi:10.3233/JAD-179904.
5. Booij BB, Lindahl T, Wetterberg P, Skaane NV, Saebo S, Feten G, et al. A gene expression pattern in blood for the early detection of Alzheimer's disease. Journal of Alzheimer's Disease. 2011;23(1):109-119. doi:10.3233/JAD-2010-101518.
6. Chen KD, Chang PT, Ping YH, Lee HC, Yeh CW, Wang PN, et al. Gene expression profiling of peripheral blood leukocytes identifies and validates ABCB1 as a novel biomarker for Alzheimer's disease. Neurobiology of Disease. 2011;43(3):698-705. doi:10.1016/j.nbd.2011.05.023.
7. Lunnon K, Sattlecker M, Furney SJ, Coppola G, Simmons A, Proitsi P, et al. A blood gene expression marker of early Alzheimer's disease. Journal of Alzheimer's Disease. 2013;33(3):737-753. doi:10.3233/JAD-2012-121363.
8. Sood S, Gallagher IJ, Lunnon K, Rullman E, Keohane A, Crossland H, et al. A novel multi-tissue RNA diagnostic of healthy ageing relates to cognitive health status. Genome Biology. 2015;16:185. doi:10.1186/s13059-015-0750-x.
9. NCBI Gene Expression Omnibus. GSE63060: Alzheimer, MCI and control samples from AddneuroMed Cohort (batch 1). Available from: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63060. Accessed 1 May 2026.
10. NCBI Gene Expression Omnibus. GSE63061: Alzheimer, Mild Cognitive impairment and control samples from AddneuroMed Cohort (batch 2). Available from: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63061. Accessed 1 May 2026.
11. NCBI Gene Expression Omnibus. GSE85426: Peripheral blood gene expression as a biomarker for early detection of Alzheimer's disease. Available from: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE85426. Accessed 1 May 2026.
12. NCBI Gene Expression Omnibus. GSE140829: Systems-level analysis of peripheral blood gene expression in dementia patients reveals an innate immune response shared across multiple disorders. Available from: https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE140829. Accessed 1 May 2026.
13. Collins GS, Reitsma JB, Altman DG, Moons KGM. Transparent Reporting of a multivariable prediction model for Individual Prognosis Or Diagnosis (TRIPOD): The TRIPOD Statement. Annals of Internal Medicine. 2015;162(1):55-63. doi:10.7326/M14-0697.
14. Ritchie ME, Phipson B, Wu D, Hu Y, Law CW, Shi W, et al. limma powers differential expression analyses for RNA-sequencing and microarray studies. Nucleic Acids Research. 2015;43(7):e47. doi:10.1093/nar/gkv007.
15. Friedman J, Hastie T, Tibshirani R. Regularization paths for generalized linear models via coordinate descent. Journal of Statistical Software. 2010;33(1):1-22. doi:10.18637/jss.v033.i01.
16. Robin X, Turck N, Hainard A, Tiberti N, Lisacek F, Sanchez J-C, et al. pROC: an open-source package for R and S+ to analyze and compare ROC curves. BMC Bioinformatics. 2011;12:77. doi:10.1186/1471-2105-12-77.
17. Yu G, Wang L-G, Han Y, He Q-Y. clusterProfiler: an R package for comparing biological themes among gene clusters. OMICS. 2012;16(5):284-287. doi:10.1089/omi.2011.0118.
18. Wu T, Hu E, Xu S, Chen M, Guo P, Dai Z, et al. clusterProfiler 4.0: A universal enrichment tool for interpreting omics data. The Innovation. 2021;2(3):100141. doi:10.1016/j.xinn.2021.100141.
19. Yu G, He Q-Y. ReactomePA: an R/Bioconductor package for reactome pathway analysis and visualization. Molecular BioSystems. 2016;12(2):477-479. doi:10.1039/C5MB00663E.
20. Milacic M, Beavers D, Conley P, Gong C, Gillespie M, Griss J, et al. The Reactome Pathway Knowledgebase 2024. Nucleic Acids Research. 2024;52(D1):D672-D678. doi:10.1093/nar/gkad1025.
