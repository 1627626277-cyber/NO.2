# 项目执行日志

项目名称：AD 外周血转录组诊断标志物纯生信项目  
日志创建日期：2026-04-30  
日志用途：记录所有关键决策、数据动作、分析结果、审核意见、阻断问题和投稿状态。

## 日志规则

1. 每完成一个实质动作必须新增一条记录。
2. 每条记录必须包含日期、阶段、动作、证据文件、判断、下一步。
3. 任何失败、返工、参数改动必须记录，不得只记录成功结果。
4. 影响论文结论的决定必须附证据路径或来源链接。
5. 投稿前以本日志作为过程透明度和复现说明的底稿。

## 阶段编号

| 阶段 | 名称 | 输出物 |
|---|---|---|
| S0 | 项目治理 | 日志、监督章程、总规划、可行性审核 |
| S1 | 数据冻结 | 数据下载记录、样本标签表、平台注释表 |
| S2 | 预处理与 QC | 标准化矩阵、PCA/箱线图/RLE、排除样本记录 |
| S3 | 候选基因筛选 | DEG 表、候选基因表、筛选阈值记录 |
| S4 | 富集与 PPI | GO/KEGG/Reactome 表、PPI 边表、hub genes |
| S5 | 建模与验证 | 模型对象、ROC/AUC、校准、外部验证结果 |
| S6 | 稳健性分析 | 敏感性分析、批次/平台影响、特征稳定性 |
| S7 | 写作 | 初稿、图表、补充材料、引用库 |
| S8 | 预投稿审核 | 完整性审核、审稿模拟、修改路线图 |
| S9 | 选刊与投稿 | 候选期刊表、投稿包、投稿记录 |

## 当前日志

### 2026-04-30｜S0｜项目初始核查

动作：核查当前文件夹材料，发现核心材料为 `deep-research-report.md`。  
证据文件：`deep-research-report.md`。  
判断：该报告已包含题目建议、数据集路线、五步方法链、风险表和 10 到 12 周时间线，但缺少项目治理文件和阶段监督机制。  
决定：新增 SCI Q3/Q4 可行性核查、项目日志、监督角色章程和总推进规划。  
下一步：进入 S1，下载或确认 GSE63060、GSE63061、GSE85426 数据文件，并建立样本标签表。

### 2026-04-30｜S0｜SCI Q3/Q4 能力判断

动作：基于本地报告和公开来源核查项目发表能力。  
证据来源：
- `deep-research-report.md`
- NCBI GEO: GSE63060、GSE63061、GSE85426
- Journal of Translational Medicine 2025 模板论文

判断：项目具备 Q4 可投基础和 Q3 条件性竞争能力；目前不具备直接投稿能力。  
阻断问题：无数据下载记录、无样本标签表、无代码、无外部验证结果、无候选期刊表。  
下一步：按 `MASTER_PROJECT_PLAN.md` 执行 S1 数据冻结。

### 2026-04-30｜S1｜GEO 数据冻结与初版样本表

动作：建立项目目录并下载 GSE63060、GSE63061、GSE85426 的 GEO matrix / supplementary 数据文件。  
输入：NCBI GEO FTP 文件。  
输出：
- `data/data_inventory.csv`
- `data/sample_sheet.csv`
- `data/primary_inclusion_locked.csv`
- `data/dataset_readme.md`
- `audit/s1_sample_summary.csv`
- `scripts/freeze_s1_geo_metadata.py`

证据文件或链接：
- `data/raw/GSE63060_series_matrix.txt.gz`
- `data/raw/GSE63060_normalized.txt.gz`
- `data/raw/GSE63060_non-normalized.txt.gz`
- `data/raw/GSE63060_RAW.tar`
- `data/raw/GSE63061_series_matrix.txt.gz`
- `data/raw/GSE63061_normalized.txt.gz`
- `data/raw/GSE63061_non-normalized.txt.gz`
- `data/raw/GSE63061_RAW.tar`
- `data/raw/GSE85426_series_matrix.txt.gz`
- `data/raw/GSE85426_normalized_data.txt.gz`
- `data/raw/GSE85426_raw_data.txt.gz`

质量检查：
- `data/data_inventory.csv` 已记录每个文件的来源 URL、大小和 SHA-256。
- `data/sample_sheet.csv` 已从 GEO series matrix 解析样本 accession、平台、状态、年龄、性别、组织等 metadata。
- `data/primary_inclusion_locked.csv` 已锁定主分析 AD/Control 样本。
- `audit/s1_sample_summary.csv` 计数结果：GSE63060 = 145 AD / 104 Control / 80 MCI；GSE63061 = 139 AD / 134 Control / 112 MCI / 2 Transition / 1 OTHER；GSE85426 = 90 AD / 90 Control。

风险/异常：
- GSE85426 的标准 `series_matrix` 文件只有 metadata，表达矩阵位于 supplementary `GSE85426_normalized_data.txt.gz`。
- GSE63061 中有 1 个 `OTHER` 样本和 2 个诊断转换状态样本，已在锁定纳入表中排除。

决定：S1 数据冻结通过，可进入 S2 预处理与 QC。  
下一步：基于 `data/primary_inclusion_locked.csv` 编写 S2 数据读取、注释和 QC 脚本。  
责任人/监督角色：Data Integrity Auditor。

### 2026-04-30｜Gate 1｜Data Freeze Review

动作：执行 S1 数据冻结门槛审核。  
输入：`data/data_inventory.csv`、`data/sample_sheet.csv`、`audit/s1_sample_summary.csv`、`data/raw/`。  
输出：`audit/gate1_data_freeze_review.md`。  
质量检查：所有 `.gz` 和 `.tar` 文件均可打开；样本表共有 897 条记录；锁定主分析样本 702 条；数据清单共有 11 条文件记录且包含 SHA-256。  
结论：PASS。  
阻断问题：无 P0/P1。  
下一步：进入 S2 预处理与 QC。

## 新日志模板

### YYYY-MM-DD｜阶段｜动作标题

动作：  
输入：  
输出：  
证据文件或链接：  
关键参数：  
质量检查：  
风险/异常：  
决定：  
下一步：  
责任人/监督角色：  

## 阻断问题登记

| ID | 日期 | 阶段 | 问题 | 严重度 | 处理状态 | 解决标准 |
|---|---|---|---|---:|---|---|
| B-001 | 2026-04-30 | S0 | 尚未建立真实数据下载与样本标签记录 | P0 | closed | 三个 GEO 数据集完成下载记录和样本表 |
| B-002 | 2026-04-30 | S0 | 尚无防泄漏建模脚本 | P0 | open | 训练集内部筛选、外部集只验证的脚本完成 |
| B-003 | 2026-04-30 | S0 | 尚无候选期刊分区复核 | P1 | open | 至少 8 个候选期刊完成 JCR/SCIE 状态复核 |
| B-004 | 2026-04-30 | S1 | GSE63061 Control 计数与计划报告引用值不完全一致 | P1 | closed | 已排除 `OTHER`、`CTL to AD`、`MCI to CTL`，锁定 139 AD / 134 Control |
| B-005 | 2026-05-01 | S5 | GSE85426 跨平台最终验证 AUC 未达到 0.70 | P0 | open | 重新设计后，在未参与模型选择的外部集中达到 AUC >= 0.70，或正式降低论文主张 |

### 2026-04-30｜S2｜预处理与 QC

动作：安装项目 R 环境 `three-r`，读取锁定 AD/Control 样本对应的 normalized 表达矩阵，生成处理后矩阵、样本 QC 指标、PCA 和表达分布图。  
输入：
- `data/primary_inclusion_locked.csv`
- `data/raw/GSE63060_normalized.txt.gz`
- `data/raw/GSE63061_normalized.txt.gz`
- `data/raw/GSE85426_normalized_data.txt.gz`

输出：
- `scripts/s2_preprocess_qc.R`
- `data/processed/GSE63060_primary_normalized_matrix.rds`
- `data/processed/GSE63061_primary_normalized_matrix.rds`
- `data/processed/GSE85426_primary_normalized_matrix.rds`
- `data/processed/s2_expression_column_sample_map.csv`
- `results/s2_qc_dataset_summary.csv`
- `results/s2_qc_sample_metrics.csv`
- `results/s2_qc_pca_summary.csv`
- `figures/qc/`
- `audit/s2_qc_report.md`
- `audit/gate2_preprocessing_qc_review.md`

质量检查：
- GSE63060：保留 38,322 个 feature、249 个样本、无缺失值、无样本级 QC 标记。
- GSE63061：保留 32,049 个 feature、273 个样本、无缺失值、无样本级 QC 标记。
- GSE85426：保留 14,113 个 feature、180 个样本、无缺失值、无样本级 QC 标记。
- Gate 2 结论：PASS。

风险/异常：
- GSE63060 中 1 行 malformed feature 和 1 行无效 feature ID 已剔除。
- GSE63061 中 2 个 `#N/A` feature ID 已剔除。
- GSE85426 采用列顺序匹配 GEO metadata，映射已记录在 `data/processed/s2_expression_column_sample_map.csv`。

决定：S2 自动 QC 通过，可进入 S3 候选基因筛选；S3 只能在 GSE63060 训练集中做 DEG 和特征发现，GSE63061/GSE85426 保持外部验证用途。  
下一步：安装/确认 Bioconductor `limma`，编写 S3 差异表达脚本。

### 2026-04-30 - S3 - 候选基因筛选

动作：安装并验证 Bioconductor `limma`，解析 GPL6947 注释文件，在 GSE63060 训练发现集内执行差异表达筛选。
输入：
- `data/processed/GSE63060_primary_normalized_matrix.rds`
- `data/primary_inclusion_locked.csv`
- `data/raw/GPL6947.annot.gz`

输出：
- `scripts/s3_limma_deg.R`
- `results/s3_deg_limma_gse63060_all.csv`
- `results/s3_deg_limma_gse63060_main_threshold.csv`
- `results/s3_candidate_probes_main.csv`
- `results/s3_candidate_genes_main.csv`
- `results/s3_deg_threshold_sensitivity.csv`
- `results/s3_limma_model_summary.csv`
- `results/s3_gpl6947_annotation_summary.csv`
- `figures/s3/`
- `audit/s3_candidate_gene_screening_report.md`
- `audit/gate3_candidate_gene_review.md`

关键参数：
- 发现集：GSE63060 only。
- 模型：`limma: expression ~ diagnosis + age + gender`。
- 主阈值：BH adjusted P < 0.05 且 `abs(logFC) >= 0.20`。
- 数据防泄漏：GSE63061 与 GSE85426 未参与候选筛选。

质量检查：
- 训练样本：249 个，其中 AD = 145，Control = 104。
- 测试特征：38,322 个 probe，零方差剔除 = 0。
- GPL6947 注释：49,576 行；训练矩阵 38,322 个 probe 均有平台注释行；25,073 个训练 probe 有 gene symbol。
- 主阈值候选：623 个 probe、546 个已注释 probe、476 个唯一 gene。
- 方向：AD 上调 probe = 155，AD 下调 probe = 468。
- 最小 BH adjusted P = 3.881267e-21。
- Gate 3 结论：PASS。

风险/异常：
- 候选筛选仍是训练集发现结果，不能直接声明诊断效能。
- 下一阶段不得根据 GSE63061/GSE85426 的验证表现回头调整 S3 阈值，否则会产生验证集泄漏。

决定：S3 通过，可进入 S4 外部验证/候选稳定性评估。
下一步：在 GSE63061 与 GSE85426 中检查候选信号方向、可映射比例、单基因 AUC 和多基因模型的外部验证表现。
责任人/监督角色：Methodology Auditor + Data Leakage Auditor。

### 2026-04-30 - S4 - 外部验证与候选稳定性评估

动作：冻结 S3 候选基因后，在 GSE63061 与 GSE85426 中执行基因层面外部验证，检查方向一致性、显著性、单基因方向化 AUC 和签名分数 AUC。
输入：
- `results/s3_candidate_genes_main.csv`
- `data/processed/GSE63061_primary_normalized_matrix.rds`
- `data/processed/GSE85426_primary_normalized_matrix.rds`
- `data/processed/s2_expression_column_sample_map.csv`
- `data/raw/GPL10558.annot.gz`

输出：
- `scripts/s4_external_validation.R`
- `results/s4_candidate_external_validation.csv`
- `results/s4_external_validation_dataset_summary.csv`
- `results/s4_gene_mapping_selected_representatives.csv`
- `results/s4_signature_score_summary.csv`
- `results/s4_signature_sample_scores.csv`
- `results/s4_annotation_resource_summary.csv`
- `figures/s4/`
- `audit/s4_external_validation_report.md`
- `audit/gate4_external_validation_review.md`

关键参数：
- 跨平台验证统一到 Entrez gene 层面。
- 重复 probe/gene 映射用验证集内方差最高的 probe 作为代表。
- 每个验证集的差异模型：`expression ~ diagnosis + age + gender`。
- 签名分数：按 S3 logFC 方向加权的候选基因行 z-score 均值。

质量检查：
- GSE63061：映射 476/476 个 S3 候选基因；方向一致率 0.989；名义一致 448；FDR 一致 395；中位方向化 AUC 0.637；最大方向化 AUC 0.761；top50 签名 AUC 0.742。
- GSE85426：映射 451/476 个 S3 候选基因；方向一致率 0.749；名义一致 35；FDR 一致 0；中位方向化 AUC 0.537；最大方向化 AUC 0.652；top50 签名 AUC 0.577。
- Gate 4 结论：CONDITIONAL PASS。

风险/异常：
- GSE63061 复现强，但与训练队列同属 AddNeuroMed 系列，独立性强于内部验证但仍可能共享队列/流程特征。
- GSE85426 为真正跨平台验证，信号较弱，不能据此宣称已有稳定高性能诊断模型。
- GSE85426 未找到标准 GEO `annot/GPL14550.annot.gz`，本阶段使用表达矩阵行名中的 Entrez ID 后缀映射。

决定：项目可以继续，但后续建模必须采用保守策略；SCI Q4 仍具备可落地基础，SCI Q3 需要 S5 证明跨平台模型性能达到可接受水平。
下一步：进入 S5 建模与验证，优先使用冻结候选规则构建低维、可解释、跨平台可映射的诊断模型；不得根据 GSE85426 的结果回调 S3 阈值。
责任人/监督角色：External Validation Auditor + Data Leakage Auditor。

### 2026-05-01 - S5 - 模型优化与 0.70 AUC 门槛核查

动作：按无泄漏策略执行模型优化，目标是在 GSE85426 最终验证集中达到 AUC >= 0.70；同时补充训练+开发集合并重训练和 GSE85426 标签驱动上限诊断。
输入：
- `results/s3_candidate_genes_main.csv`
- `results/s4_candidate_external_validation.csv`
- `data/processed/GSE63060_primary_normalized_matrix.rds`
- `data/processed/GSE63061_primary_normalized_matrix.rds`
- `data/processed/GSE85426_primary_normalized_matrix.rds`

输出：
- `scripts/s5_model_optimization.R`
- `scripts/s5_train_dev_refit_final_validation.R`
- `scripts/s5_gse85426_posthoc_upper_bound.R`
- `results/s5_model_optimization_grid.csv`
- `results/s5_primary_model_summary.csv`
- `results/s5_train_dev_refit_summary.csv`
- `results/s5_gse85426_posthoc_signature_upper_bound.csv`
- `results/s5_gse85426_within_dataset_cv_upper_bound.csv`
- `audit/s5_model_optimization_report.md`
- `audit/gate5_model_optimization_review.md`

关键参数：
- 训练集：GSE63060。
- 开发/模型选择集：GSE63061。
- 最终验证集：GSE85426。
- 主模型选择不得使用 GSE85426 标签。
- 目标门槛：GSE85426 AUC >= 0.70。

质量检查：
- 无泄漏 primary gene-only 模型：GSE63061 AUC 0.781；GSE85426 AUC 0.567。
- 无泄漏 primary integrated 模型：GSE63061 AUC 0.784；GSE85426 AUC 0.568。
- 原优化网格中事后最高 GSE85426 AUC：0.620。
- GSE63060+GSE63061 合并重训练后，无 GSE85426 标签选择的 gene-only refit：GSE85426 AUC 0.587。
- 合并重训练后事后最高 GSE85426 AUC：0.640。
- GSE85426 标签驱动 signature 上限：in-sample AUC 0.688。
- GSE85426 内部 glmnet CV 上限：best CV AUC 0.668。
- Gate 5 结论：REVIEW。

风险/异常：
- 当前候选集无法支持跨平台 GSE85426 AUC >= 0.70。
- 即使使用不可作为主结果的 GSE85426 标签驱动上限诊断，也未稳定超过 0.70。
- 继续按“诊断模型论文”主线推进将产生较高拒稿风险。

决定：暂停默认论文写作/富集/PPI推进；进入项目风险处置与重设计决策。
下一步：选择处理路线：重新定义论文主张、增加/更换外部验证数据、调整终点或转为机制/稳定性分析，而不是继续包装当前诊断模型。
责任人/监督角色：Model Validation Auditor + Publication Risk Auditor。

### 2026-05-01 - R1 - 项目风险处置双路线规划

动作：对 Gate 5 失败后的两种处置方法进行初步尝试：检索/扫描新增外部验证数据，并制定降级为 Q4 稳妥论文的替代技术路线。
输入：
- `audit/gate5_model_optimization_review.md`
- NCBI GEO: GSE140829, GSE97760, GSE18309, GSE4226, GSE165090

输出：
- `scripts/s6_risk_route_dataset_scan.R`
- `results/risk_external_dataset_scan.csv`
- `audit/risk_external_dataset_scan_report.md`
- `PROJECT_RISK_RESPONSE_ROUTES.md`

关键发现：
- GSE140829：587 个外周血样本，AD = 204，Control = 249，MCI = 134；可作为 Route A 的新主外部验证候选。
- GSE97760：19 个全血样本，AD = 9，Control = 10；样本太小，只能支持性验证。
- GSE18309：9 个 PBMC 样本，AD = 3，Control = 3，MCI = 3；仅支持性验证。
- GSE4226：28 个 PBMC 样本，AD = 14，Control = 14；仅支持性验证。
- GSE165090：不是 AD 血液队列，排除。

决定：
- Route A：先尝试 GSE140829 数据救援，保留诊断模型主张，但必须在未参与模型选择的新外部集中达到 AUC >= 0.70。
- Route B：若 Route A 失败，降级为 Q4 风险较低的“跨队列可迁移性有限的血液转录组特征研究”。

下一步：下载并冻结 GSE140829，运行当前冻结模型和预注册 refit 模型，决定是否继续 Route A。
责任人/监督角色：External Dataset Auditor + Publication Risk Auditor。

### 2026-05-01 - Route A - GSE140829 数据救援验证

动作：下载并冻结 GSE140829，解析 metadata 与标准化表达矩阵，将其作为新的最终验证集评估冻结模型和预注册 refit 模型。
输入：
- `data/raw/GSE140829_series_matrix.txt.gz`
- `data/raw/GSE140829_final_normalized_data.txt.gz`
- `results/s5_primary_model_summary.csv`
- `results/s5_train_dev_refit_summary.csv`

输出：
- `scripts/s7_route_a_gse140829_validation.R`
- `data/gse140829_route_a_sample_sheet.csv`
- `data/processed/GSE140829_primary_normalized_symbol_matrix.rds`
- `results/route_a_gse140829_dataset_summary.csv`
- `results/route_a_gse140829_model_validation.csv`
- `results/route_a_gse140829_model_predictions.csv`
- `results/route_a_gse140829_feature_mapping.csv`
- `figures/route_a/GSE140829_route_a_model_score_boxplot.png`
- `audit/route_a_gse140829_validation_report.md`
- `audit/gate_route_a_gse140829_review.md`

关键参数：
- GSE140829 只作为 Route A 新最终验证集。
- 未使用 GSE140829 标签进行特征选择或超参数调优。
- 主终点：AD vs Control AUC >= 0.70。
- MCI 仅作为分数梯度检查。

质量检查：
- 标准化表达矩阵可解析样本：551 个，其中 AD = 198，Control = 229，MCI = 124。
- 表达特征：15,987 个 gene symbol；缺失值 = 0；重复 gene symbol 剔除 = 0。
- Frozen gene-only 模型 `sig_dev_p_k3`：AUC 0.554，95% CI 0.500-0.604。
- Frozen integrated 模型 `glmnet_dev_auc_k5_a05_lambda.min_clin`：AUC 0.567，95% CI 0.513-0.620。
- Train+development refit 模型 `refit_glmnet_dev_p_k100_a05_lambda.1se_gene`：AUC 0.569，95% CI 0.517-0.624。
- Route A Gate 结论：FAIL_SWITCH_TO_ROUTE_B。

风险/异常：
- GSE140829 series matrix metadata 中有 587 个样本，但 normalized expression 文件中可用列为 551 个；Route A 以表达矩阵可验证样本为准。
- GEO 标准路径没有可用的 `GPL15988.annot.gz` 注释文件，表达矩阵使用 gene symbol 行名。
- 三个预注册模型均未接近 AUC 0.70，继续优化将构成明显验证集驱动风险。

决定：Route A 失败，停止诊断模型救援；转入 Route B。
下一步：按 Route B 执行“跨队列可迁移性有限的血液转录组特征研究”，重点做稳定/不稳定基因、通路富集、AUC 衰减和队列异质性解释。
责任人/监督角色：External Validation Auditor + Publication Risk Auditor。

### 2026-05-01 - Route B B1 - 证据整合与叙事门控

动作：在 Route A 失败后，进入 Route B，整合 S3/S4/S5 与 GSE140829 结果，并新增 GSE140829 候选基因层面的复现分析。
输入：
- `results/s3_candidate_genes_main.csv`
- `results/s4_external_validation_dataset_summary.csv`
- `results/s5_primary_model_summary.csv`
- `results/s5_train_dev_refit_summary.csv`
- `results/route_a_gse140829_model_validation.csv`
- `data/gse140829_route_a_sample_sheet.csv`
- `data/processed/GSE140829_primary_normalized_symbol_matrix.rds`

输出：
- `scripts/s8_route_b_b1_evidence_consolidation.R`
- `results/route_b_b1_gse140829_candidate_replication.csv`
- `results/route_b_b1_replication_summary.csv`
- `results/route_b_b1_dataset_role_summary.csv`
- `results/route_b_b1_model_auc_long.csv`
- `results/route_b_b1_evidence_dashboard.csv`
- `figures/route_b/B1_model_auc_decay.png`
- `figures/route_b/B1_mapping_direction_concordance.png`
- `figures/route_b/B1_concordant_replication_counts.png`
- `figures/route_b/B1_candidate_oriented_auc_distribution.png`
- `audit/route_b_b1_evidence_consolidation_report.md`
- `audit/gate_b1_evidence_consolidation_review.md`

关键参数：
- GSE140829 候选基因复现模型：`expression ~ diagnosis + age + gender + batch`。
- 不使用 GSE85426 或 GSE140829 标签进行模型优化。
- Route B 主张从“诊断模型成功”调整为“近缘队列可复现，但跨平台诊断迁移有限”。

质量检查：
- GSE63061：映射 476/476；方向一致率 0.989；名义一致 448；FDR 一致 395；中位方向化 AUC 0.637。
- GSE85426：映射 451/476；方向一致率 0.749；名义一致 35；FDR 一致 0；中位方向化 AUC 0.537。
- GSE140829：映射 460/476；方向一致率 0.898；名义一致 122；FDR 一致 5；中位方向化 AUC 0.534。
- 模型层面：GSE85426 最佳外部 AUC 0.587；GSE140829 最佳外部 AUC 0.569；均未达到 0.70。
- Gate B1 结论：PASS_ROUTE_B_FRAMING。

风险/异常：
- GSE140829 虽然方向一致率较高，但单基因判别能力弱，说明其更适合支持“转录信号存在但诊断迁移有限”，不适合救援诊断模型主张。
- 后续不得恢复 classifier tuning，除非新增完全独立外部数据或重新定义终点。

决定：Route B B1 通过；论文主张降级为 Q4 风险较低的“跨队列可迁移性有限的血液转录组特征研究”。
下一步：进入 B2，构建 stable/unstable gene sets，并检查这些基因集是否具有可解释的生物学结构。
责任人/监督角色：Publication Risk Auditor + Data Leakage Auditor + Biological Interpretation Auditor。

### 2026-05-01 - Route B B2 - stable/unstable gene sets 构建

动作：基于冻结的 S3 候选基因、GSE63061 近缘验证、GSE85426 与 GSE140829 跨平台验证，构建稳定和不稳定基因集合，并做关键词级别的初步生物学可解释性检查。
输入：
- `results/s3_candidate_genes_main.csv`
- `results/s4_candidate_external_validation.csv`
- `results/route_b_b1_gse140829_candidate_replication.csv`

输出：
- `scripts/s9_route_b_b2_stable_unstable_gene_sets.R`
- `results/route_b_stable_genes.csv`
- `results/route_b_stable_directional_sensitivity_genes.csv`
- `results/route_b_unstable_genes.csv`
- `results/route_b_b2_gene_transportability_classification.csv`
- `results/route_b_b2_overlap_table.csv`
- `results/route_b_b2_set_summary.csv`
- `results/route_b_b2_interpretability_keyword_summary.csv`
- `figures/route_b/B2_transportability_class_counts.png`
- `figures/route_b/B2_directional_overlap_counts.png`
- `figures/route_b/B2_stable_unstable_category_composition.png`
- `audit/route_b_b2_stable_unstable_gene_sets_report.md`
- `audit/gate_b2_stable_unstable_gene_set_review.md`

关键参数：
- strict stable 主集合：GSE63061 名义一致；所有可映射跨平台队列方向一致；至少一个跨平台队列名义一致。
- directional stable 敏感性集合：GSE63061 方向一致；所有可映射跨平台队列方向一致。
- unstable 主集合：GSE63061 名义一致但不属于 strict stable，且出现跨平台反向或跨平台信号消失。
- signal loss 定义：跨平台无名义一致，且跨平台最大方向化 AUC < 0.55。

质量检查：
- S3 候选基因：476。
- GSE63061 方向锚定：471；GSE63061 名义锚定：448。
- strict stable 主集合：103。
- directional stable 敏感性集合：327。
- unstable 主集合：235；其中 reversal = 139，signal-loss = 190。
- stable 与 unstable 主集合交集：0。
- strict stable 初步关键词可解释比例：0.456；housekeeping-like 比例：0.408；immune/inflammatory 比例：0.049。
- Gate B2 结论：PASS_TO_B3。

风险/异常：
- strict stable 集合中核糖体/线粒体相关信号明显，免疫炎症比例较低；B3 必须用正式 GO/KEGG/Reactome 富集确认其不是低信息 housekeeping 主导。
- 关键词分类只是 sanity check，不能替代正式通路富集。

决定：B2 通过，可进入 B3 通路与生物学解释；论文仍按“有限迁移性”而非“诊断模型成功”推进。
下一步：进入 B3，对 stable 和 unstable 基因分别做 GO/KEGG/Reactome 富集，并判断是否存在足够清晰的生物学故事。
责任人/监督角色：Biological Interpretation Auditor + Publication Risk Auditor。

### 2026-05-01 - Route B B3 - 通路富集与生物学解释

动作：对 B2 产生的 stable/unstable gene sets 进行 GO Biological Process、KEGG 和 Reactome 过度富集分析，判断可迁移与不可迁移信号是否具有可解释的生物学结构。
输入：
- `results/route_b_stable_genes.csv`
- `results/route_b_stable_directional_sensitivity_genes.csv`
- `results/route_b_unstable_genes.csv`
- `results/route_b_b2_gene_transportability_classification.csv`
- `results/s3_deg_limma_gse63060_all.csv`

输出：
- `scripts/s10_route_b_b3_pathway_enrichment.R`
- `results/route_b_b3_enrichment_all.csv`
- `results/route_b_b3_enrichment_significant_fdr005.csv`
- `results/route_b_b3_top_terms_for_manuscript.csv`
- `results/route_b_b3_ranked_terms_audit_only.csv`
- `results/route_b_b3_module_summary.csv`
- `results/route_b_b3_database_summary.csv`
- `results/route_b_b3_gene_set_input_summary.csv`
- `figures/route_b/B3_GO_BP_candidate_background_dotplot.png`
- `figures/route_b/B3_significant_module_heatmap.png`
- `figures/route_b/B3_enrichment_database_yield.png`
- `audit/route_b_b3_pathway_interpretation_report.md`
- `audit/gate_b3_pathway_interpretation_review.md`

关键参数：
- 主要背景：全部 S3 candidate genes，用于比较 stable/unstable 在候选信号内部的相对富集。
- 数据库：GO BP、KEGG、Reactome。
- 显著阈值：BH FDR < 0.05。
- 不对候选基因或模型进行重新筛选；富集只用于解释 Route B 的可迁移性差异。

质量检查：
- strict stable 输入 Entrez genes：103。
- directional stable sensitivity 输入 Entrez genes：327。
- unstable 输入 Entrez genes：235。
- strict stable 显著通路：GO BP = 12，KEGG = 2，Reactome = 52。
- directional stable sensitivity 显著通路：GO BP = 0，KEGG = 2，Reactome = 45。
- unstable 显著通路：GO BP = 0，KEGG = 0，Reactome = 0。
- strict stable 主要模块：ribosomal_translation、rna_processing，以及部分 other/unclassified translation-related Reactome/KEGG terms。
- Gate B3 结论：CONDITIONAL_PASS_TO_B4。

风险/异常：
- stable 富集可解释，但明显偏向翻译、核糖体和 RNA processing；没有显著 immune/blood 模块。
- unstable 集合无 FDR<0.05 富集，因此不能主张 unstable 具有清晰独立机制，只能表述为“非迁移/队列敏感信号缺乏一致富集结构”。
- B3 支持的是机制背景和方法学解释，不支持恢复诊断模型主张。

决定：B3 条件通过；可以进入 B4 transportability audit，但论文生物学表述必须谨慎，避免夸大为明确 AD 机制或临床诊断机制。
下一步：进入 B4，整合 mapping rate、方向一致率、nominal/FDR replication、AUC decay、MCI 分数梯度和主图规划。
责任人/监督角色：Biological Interpretation Auditor + Publication Risk Auditor + Figure Integrity Auditor。

### 2026-05-01 - Route B B4 - transportability audit 与主图组装

动作：整合 B1-B3 证据，完成跨队列可迁移性审计、AUC 衰减审计、MCI 分数梯度检查、主图草案和论文表述审计。
输入：
- `results/route_b_b1_replication_summary.csv`
- `results/route_b_b1_model_auc_long.csv`
- `results/route_b_b1_dataset_role_summary.csv`
- `results/route_b_b2_set_summary.csv`
- `results/route_b_b3_database_summary.csv`
- `results/route_b_b3_module_summary.csv`
- `results/route_a_gse140829_model_validation.csv`
- `results/route_a_gse140829_model_predictions.csv`
- `results/s4_signature_score_summary.csv`
- `results/s4_signature_sample_scores.csv`

输出：
- `scripts/s11_route_b_b4_transportability_audit.R`
- `results/route_b_b4_transportability_metrics.csv`
- `results/route_b_b4_auc_decay_summary.csv`
- `results/route_b_b4_mci_score_gradient.csv`
- `results/route_b_b4_top50_signature_score_summary.csv`
- `results/route_b_b4_pathway_yield_summary.csv`
- `results/route_b_b4_main_figure_plan.csv`
- `results/route_b_b4_manuscript_claim_audit.csv`
- `results/route_b_b4_gate_summary.csv`
- `figures/route_b/B4_main_figure1_dataset_workflow.png`
- `figures/route_b/B4_main_figure2_validation_heatmap.png`
- `figures/route_b/B4_main_figure3_auc_and_scores.png`
- `figures/route_b/B4_main_figure4_pathway_comparison.png`
- `audit/route_b_b4_transportability_audit_report.md`
- `audit/gate_b4_transportability_audit_review.md`

关键参数：
- 诊断模型门槛仍为外部跨平台 AUC >= 0.70；B4 不允许重新调参。
- 主图必须突出近缘复现与跨平台衰减，而不是包装成诊断模型成功。
- claim audit 明确允许“limited diagnostic transferability / cohort dependence”，禁止“robust diagnostic biomarker / clinically useful classifier”。

质量检查：
- GSE63061：方向一致率 0.989；FDR 一致 395；best model AUC 0.784。
- GSE85426：best model AUC 0.587；FDR 一致 0。
- GSE140829：best model AUC 0.569；FDR 一致 5。
- primary gene-only 模型从 GSE63061 到 GSE85426/GSE140829 的 AUC 下降分别为 0.214 和 0.226。
- primary integrated 模型从 GSE63061 到 GSE85426/GSE140829 的 AUC 下降分别为 0.216 和 0.218。
- GSE140829 MCI 分数梯度：3 个模型摘要中 2 个显示 MCI 位于 Control 与 AD 之间。
- 四张 B4 主图均可读取且非空白：像素标准差 0.0999-0.2368。
- Gate B4 结论：PASS_TO_B5_Q4_FRAMING。

风险/异常：
- MCI 分数梯度只是部分支持，不得提升为主结论。
- B4 支持 Q4 风险受控论文；不支持 Q3 强竞争或诊断模型主张。
- 后续写作必须把模型结果作为 cautionary external-validation evidence。

决定：B4 通过，进入 B5 manuscript framing 与 B6 submission strategy；当前定位为 Q4-oriented limited-transferability manuscript。
下一步：进入 B5/B6，确定标题、摘要主张、结果结构、禁用词清单和候选投稿方向。
责任人/监督角色：Publication Risk Auditor + Figure Integrity Auditor + Manuscript Framing Auditor。

### 2026-05-01 - Route B B5/B6 - manuscript framing 与 submission strategy

动作：基于 B4 transportability audit 固定论文主张、标题方向、摘要骨架、结果结构、禁用表述、投稿候选期刊和投稿风险处置。
输入：
- `results/route_b_b4_manuscript_claim_audit.csv`
- `results/route_b_b4_gate_summary.csv`
- `audit/gate_b4_transportability_audit_review.md`
- `results/route_b_b3_database_summary.csv`
- 当前期刊 scope 网页核查结果

输出：
- `MANUSCRIPT_ROUTE_B_FRAMING_PLAN.md`
- `SUBMISSION_STRATEGY_ROUTE_B.md`
- `results/route_b_b5_claim_evidence_matrix.csv`
- `results/route_b_b6_candidate_journal_screen.csv`
- `audit/gate_b5_b6_framing_submission_review.md`

关键参数：
- 论文主张固定为：AD 外周血转录组信号在近缘队列可复现，但跨平台诊断迁移能力有限。
- 首选标题方向：`Peripheral blood transcriptomic signatures of Alzheimer's disease show cohort-dependent reproducibility and limited diagnostic transferability`。
- 禁用表述：`robust diagnostic biomarker`、`clinically useful classifier`、`validated diagnostic signature`。
- 投稿策略：Q4-oriented，Q3 仅在外部验证方法学和 transportability audit 被编辑认可时尝试。

质量检查：
- B5 Gate：PASS_TO_B6_SUBMISSION_STRATEGY。
- B6 Gate：PASS_TO_DRAFTING_WITH_Q4_STRATEGY。
- 首选投稿候选：BMC Medical Genomics、BioData Mining。
- 备选：BMC Genomics、Medicine、Genetics Research（需确认当前索引）。
- fallback：BMC Research Notes（仅限降级为短篇 negative/validation note）。
- 排除：Molecular Biology Reports，因为官方 scope 不接收纯 bioinformatic / in silico 论文。

风险/异常：
- 当前候选期刊分区需在投稿前用 2026 JCR / Web of Science 正式复核。
- 没有湿实验验证，仍是中等拒稿风险；必须把模型弱性能作为研究发现而不是遮掩问题。
- BMC Genomics、BioData Mining 可能要求更强方法学新意；Medicine 可能要求更清晰临床叙事。

决定：Route B 进入 manuscript drafting package 阶段；优先起草 Methods 和 Results，确保 reproducibility、leakage control 和 limited transferability 主张不偏离证据。
下一步：构建完整 IMRaD 大纲、字数分配、图注、补充表清单，并开始 Methods 初稿。
责任人/监督角色：Manuscript Framing Auditor + Submission Strategy Auditor + Data Integrity Auditor。

### 2026-05-01 - Drafting V1 - Route B manuscript 初稿启动

动作：按 academic-paper full drafting mode 启动 Route B 写作，生成论文配置、IMRaD 大纲、图注、补充表清单、英文正文初稿和初步 reviewer-style 风险检查。
输入：
- `MANUSCRIPT_ROUTE_B_FRAMING_PLAN.md`
- `SUBMISSION_STRATEGY_ROUTE_B.md`
- `results/route_b_b5_claim_evidence_matrix.csv`
- `results/route_b_b4_transportability_metrics.csv`
- `results/route_b_b4_auc_decay_summary.csv`
- `results/route_b_b2_set_summary.csv`
- `results/route_b_b3_database_summary.csv`
- `audit/gate_b5_b6_framing_submission_review.md`

输出：
- `manuscript/ROUTE_B_PAPER_CONFIGURATION.md`
- `manuscript/ROUTE_B_IMRAD_OUTLINE.md`
- `manuscript/ROUTE_B_FIGURE_CAPTIONS.md`
- `manuscript/ROUTE_B_SUPPLEMENTARY_TABLES.md`
- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1.md`
- `manuscript/ROUTE_B_INITIAL_REVIEW_RISK_CHECK.md`

关键参数：
- 写作方向严格固定为 Q4 风险可控的有限迁移性/外部验证失败论文。
- 正文标题使用：`Peripheral blood transcriptomic signatures of Alzheimer's disease show cohort-dependent reproducibility and limited diagnostic transferability`。
- 不新增模型优化，不改变 Route B 证据链。
- 初稿引用暂为待核查参考清单，正式投稿前必须进行 citation-check。

质量检查：
- 英文正文初稿：约 3570 words，98 lines。
- 机械检查未发现未限定使用的禁用短语：`robust diagnostic biomarker`、`clinically useful classifier`、`validated cross-cohort diagnostic signature`。
- 初步审稿风险结论：major revision before submission；主要缺口为文献引用核查、引言文献扩展、软件版本整合和最终图形 panel 标注。

风险/异常：
- 当前还不是可投稿终稿；它是 V1 起草稿。
- 引用仍未完成 PubMed/DOI/GEO 逐条核查。
- 需要将 R 版本、包版本、脚本名和可复现流程进一步写入 Methods。

决定：写作已正式开始，V1 初稿完成；下一步进入 V1.1 修订，优先补参考文献、Methods 版本信息和 Figure panel captions。
下一步：执行 citation/literature 补强与 Methods 精修，随后进入正式 academic-paper-reviewer full review。
责任人/监督角色：Draft Writer + Citation Compliance Auditor + Methodology Reviewer。

### 2026-05-01 - Drafting V1.1 - 文献、复现信息补强与完整审稿

动作：按 Route B 固定方向完成 V1.1 修订；补强 Introduction 文献背景，加入编号引用、R/包版本和完整脚本链，并执行 academic-paper-reviewer full review。

输入：
- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1.md`
- `scripts/`
- GEO 与方法学/软件引用核查来源

输出：
- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_1.md`
- `manuscript/ROUTE_B_CITATION_AND_REPRODUCIBILITY_AUDIT_V1_1.md`
- `manuscript/ROUTE_B_FULL_REVIEW_V1_1.md`

关键参数：
- 稿件方向仍固定为 Q4 风险可控的 limited diagnostic transferability / external validation failure。
- R 版本：4.5.3。
- 新增 Methods 包版本：data.table 1.17.8、limma 3.66.0、ggplot2 4.0.3、glmnet 4.1.10、pROC 1.19.0.1、clusterProfiler 4.18.4、org.Hs.eg.db 3.22.0、ReactomePA 1.54.0、AnnotationDbi 1.72.0、GO.db 3.22.0、KEGGREST 1.50.0、patchwork 1.3.2、png 0.1.9。
- 新增脚本链：`freeze_s1_geo_metadata.py` 到 `s11_route_b_b4_transportability_audit.R`。

质量检查：
- V1.1 约 4138 words。
- Introduction 已从 5 段扩展为 7 段。
- 数据集 accession、主要统计/建模/富集软件均已有正文引用。
- 完整 reviewer-style 审稿结论：Major Revision Before Submission。

风险/异常：
- V1.1 仍不是可投稿稿；References 仍需按目标期刊正式格式核查，作者贡献/基金/利益冲突仍是 TODO。
- 仍需补 figure panel labels、补充表 traceability、probe/gene 映射细节、glmnet 参数细节和更多 AD blood transcriptomics 文献。
- 审稿意见明确要求不要转回“诊断模型成功”叙事。

决定：V1.1 通过写作补强关口，但未通过投稿关口；进入 V1.2 major revision。
下一步：执行 V1.2 修订，优先处理 declarations、References 正式化、Methods 细节、figure callouts、supplementary traceability table 和领域文献补充。
责任人/监督角色：Citation Compliance Auditor + Methodology Reviewer + Domain Reviewer + Devil's Advocate。

### 2026-05-01 - Drafting V1.2 - declarations、Methods 细节与 traceability 修订

动作：根据 V1.1 完整审稿结果执行 V1.2 major revision；从 `D:\二区` 投稿包核对作者单位、ORCID、基金、利益冲突和声明模板，并补充方法细节、领域文献、图注和可复现性追踪表。

输入：
- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_1.md`
- `manuscript/ROUTE_B_FULL_REVIEW_V1_1.md`
- `D:\二区\submission\bmc_medical_genomics_2026-05-01\TITLE_PAGE_DRAFT.md`
- `D:\二区\submission\bmc_medical_genomics_2026-05-01\DECLARATIONS_DRAFT.md`
- `D:\二区\submission\bmc_medical_genomics_2026-05-01\AUTHOR_AND_ORCID_STATUS.md`
- `D:\二区\reports\manuscript\SUBMISSION_PREP_CHECKLIST_BMC_MEDICAL_GENOMICS.md`
- `scripts/s3_limma_deg.R`
- `scripts/s4_external_validation.R`
- `scripts/s5_model_optimization.R`
- `scripts/s8_route_b_b1_evidence_consolidation.R`
- `scripts/s11_route_b_b4_transportability_audit.R`

输出：
- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_2.md`
- `manuscript/ROUTE_B_REPRODUCIBILITY_TRACEABILITY_TABLE_V1_2.md`
- `manuscript/ROUTE_B_V1_2_REVISION_AUDIT.md`
- `manuscript/ROUTE_B_SUPPLEMENTARY_TABLES.md`

关键参数：
- 作者：Zhuang Jiang。
- 单位：Guangdong University of Petrochemical Technology (GDUPT), 139 Guandu 2nd Road, Maoming 525000, Guangdong, China。
- 通讯邮箱：1627626277@qq.com。
- ORCID：https://orcid.org/0009-0007-4388-5901。
- Funding：No specific funding was received for this work。
- Competing interests：The author declares that there are no competing interests。
- Methods 新增：probe/gene first-token parsing、discovery gene collapsing、validation highest-variance representative probe、metadata alignment stop checks、glmnet binomial/alpha/lambda/grid/CV 细节、AUC>=0.70 作为研究 gate 而非临床充分阈值。

质量检查：
- V1.2 约 5016 words。
- References：20 条。
- 正文引用覆盖：20/20。
- manuscript TODO markers：0。
- Route B 主张保持为 limited diagnostic transferability / external validation failure。

风险/异常：
- 当前 V1.2 已通过 major revision content，但仍不是最终投稿包。
- 投稿前仍需 final DOI/PMID/style check、公共代码/结果归档、图件 panel label/resolution 检查、AD Route B 专属 title page 与 cover letter。
- ORCID 资料中此前记录的 profile 清理问题属于投稿前外部账户事项，不应写入正文。

决定：V1.2 内容修订通过，进入 final citation/style cleanup 与 submission package preparation。
下一步：执行 final citation-check、目标期刊格式适配、图件终检和 cover letter/title page 构建。
责任人/监督角色：Citation Compliance Auditor + Submission Package Auditor + Figure Integrity Auditor。

### 2026-05-01 - Pre-generation submission package - BMC style cleanup 与生成前报告

动作：按 BMC Medical Genomics 目标期刊完成 final citation/style cleanup、图件 panel/resolution 终检、代码归档决策、AD Route B 专属 title page 和 cover letter；按用户要求在完整论文生成前停止并报告。

输入：
- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_2.md`
- `scripts/s11_route_b_b4_transportability_audit.R`
- `figures/route_b/B4_main_figure*.png`
- BMC Medical Genomics 当前投稿说明网页

输出：
- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_3_BMC_STYLE.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/TITLE_PAGE_DRAFT.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/COVER_LETTER_DRAFT.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/FINAL_CITATION_STYLE_AUDIT.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/FIGURE_PANEL_RESOLUTION_QC.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/CODE_ARCHIVE_DECISION.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/GENERATION_READY_CHECKPOINT.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/Figure1_dataset_workflow.png`
- `submission/bmc_medical_genomics_route_b_2026-05-01/Figure2_validation_heatmap.png`
- `submission/bmc_medical_genomics_route_b_2026-05-01/Figure3_auc_and_scores.png`
- `submission/bmc_medical_genomics_route_b_2026-05-01/Figure4_pathway_comparison.png`

关键参数：
- 目标期刊格式：BMC Medical Genomics research article。
- 参考文献：Vancouver-style numbered，20 条，正文覆盖 20/20。
- BMC-style 正文标题：Background、Methods、Results、Discussion、Conclusions、Declarations、Figure Legends、References。
- Figure 3/4 已重新生成并加入 A/B panel labels。
- 图件均为 300 dpi PNG，尺寸满足 full-width 需求。

质量检查：
- V1.3 BMC style manuscript before references：4516 words。
- TODO markers：0。
- Figure QC：RESOLUTION_PASS; PANEL_LABEL_PASS。
- Code archive decision：HOLD_PUBLIC_UPLOAD_PENDING_AUTHOR_CONFIRMATION。
- Pandoc 可用：`C:\Users\jz\anaconda3\Library\bin\pandoc.exe`。
- Rscript 可通过 conda env `three-r` 使用，版本 R 4.5.3。
- 当前 shell 未检测到 git。

风险/异常：
- 尚未生成完整论文 DOCX/PDF；这是按用户要求在生成前停止。
- 尚未上传公共代码/结果归档，不能在稿件中填最终 URL/DOI。
- 投稿前仍需最终 DOI/PMID live-link check。

决定：进入完整论文生成前 checkpoint；等待用户确认是否生成 DOCX/PDF 与最终 submission manuscript。
下一步：若用户确认，执行完整论文生成、渲染检查、DOCX/PDF 输出与最终 integrity pass。
责任人/监督角色：Formatter Agent + Citation Compliance Auditor + Figure Integrity Auditor。

### 2026-05-01 - Full manuscript generation - DOCX/PDF、渲染检查与最终 integrity pass

动作：在用户确认后生成完整 manuscript DOCX/PDF 和 cover letter DOCX/PDF；执行 artifact-tool DOCX 渲染 QA、PDF 页数检查和最终 integrity pass。

输入：
- `manuscript/ROUTE_B_MANUSCRIPT_DRAFT_V1_3_BMC_STYLE.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/COVER_LETTER_DRAFT.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/Figure*.png`
- `scripts/build_route_b_submission_documents.py`

输出：
- `submission/bmc_medical_genomics_route_b_2026-05-01/MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.docx`
- `submission/bmc_medical_genomics_route_b_2026-05-01/MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.pdf`
- `submission/bmc_medical_genomics_route_b_2026-05-01/COVER_LETTER_BMC_MEDICAL_GENOMICS_ROUTE_B.docx`
- `submission/bmc_medical_genomics_route_b_2026-05-01/COVER_LETTER_BMC_MEDICAL_GENOMICS_ROUTE_B.pdf`
- `submission/bmc_medical_genomics_route_b_2026-05-01/FINAL_INTEGRITY_PASS.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/SUBMISSION_PACKAGE_INDEX.md`

质量检查：
- Manuscript DOCX 渲染：14 pages，pass。
- Cover letter DOCX 渲染：1 page，pass。
- Manuscript PDF：14 pages。
- Cover letter PDF：1 page。
- References：20；正文覆盖 20/20。
- TODO markers：0。
- BMC declarations 完整。
- Route B 主张未偏离。

风险/异常：
- 公共代码/结果归档 URL/DOI 尚未创建；最终 gate 为 conditional pass。
- 当前 shell 仍未检测到 git；未做 repository status 验证。
- 正式 journal portal upload 前仍需 final DOI/PMID live-link check。

决定：完整论文生成和渲染 QA 通过；进入作者审阅与 public archive 决策。
下一步：确认是否创建/上传 public code archive，并将 URL/DOI 写入 Availability of data and materials。
责任人/监督角色：Final Integrity Auditor + Submission Package Auditor。

## 决策登记

| ID | 日期 | 决策 | 理由 | 可逆性 |
|---|---|---|---|---|
| D-001 | 2026-04-30 | 以 AD 外周血转录组诊断模型为主方向 | 样本量、外部验证、文件体量和硬件约束匹配 | 可逆，但不建议频繁换题 |
| D-002 | 2026-04-30 | 以 Q3 竞争、Q4 稳定备选为投稿策略 | 纯公共数据无湿实验，Q2 以上风险偏高 | 可逆，取决于结果强度 |
| D-003 | 2026-04-30 | 先复现与建模，再写作和选刊 | 防止先写后补导致结果不支撑论点 | 不建议逆转 |
| D-004 | 2026-04-30 | Gate 3 后优先执行外部验证，再进入富集/PPI 或正式建模 | 跨平台复现是项目能否落地和能否冲击 SCI Q3/Q4 的核心门槛，早验证可避免在弱结果上过早写作 | 可逆，但不建议在未验证前投入论文主文 |
| D-005 | 2026-05-01 | 暂停诊断模型论文主线，先做项目风险处置 | S5 多策略优化未能使 GSE85426 AUC 达到 0.70，继续包装会形成高拒稿风险 | 可逆，前提是新增独立验证或重新定义论文主张 |
| D-006 | 2026-05-01 | 先执行 Route A 的 GSE140829 数据救援，再保留 Route B 作为兜底 | GSE140829 是当前扫描中唯一大样本 AD/MCI/Control 外周血候选；若其失败，诊断模型主张应主动降级 | 可逆，取决于 GSE140829 冻结验证结果 |
| D-007 | 2026-05-01 | Route A 失败后切换至 Route B | GSE140829 上三个冻结/预注册模型 AUC 均为 0.55-0.57，未达到 0.70 门槛 | 不建议逆转，除非新增完全独立数据或改变终点 |
| D-008 | 2026-05-01 | Route B B1 通过，采用“有限迁移性”论文主张 | GSE63061 强复现但 GSE85426/GSE140829 模型 AUC 明显衰减，证据支持队列依赖和跨平台限制，而不支持高性能诊断模型 | 不建议逆转，除非后续 B2/B3 无法形成稳定且可解释的生物学结构 |
| D-009 | 2026-05-01 | B2 stable/unstable gene sets 通过，进入 B3 富集解释 | strict stable 有 103 个基因、unstable 有 235 个基因且两者不重叠；初步关键词检查显示存在核糖体、线粒体和少量免疫炎症信号 | 有条件可逆；若 B3 富集只显示低信息 housekeeping，则需要进一步降级或重写生物学主张 |
| D-010 | 2026-05-01 | B3 条件通过，进入 B4 transportability audit | strict stable 有显著 GO/KEGG/Reactome 富集，但主要集中在核糖体翻译和 RNA processing；unstable 无显著富集，适合谨慎机制背景，不适合强机制主张 | 有条件可逆；若 B4 主图无法清楚呈现转移性衰减，则需进一步降级为描述性验证研究 |
| D-011 | 2026-05-01 | B4 通过，进入 B5/B6 写作框架和投稿策略 | B4 清楚显示 GSE63061 强复现但 GSE85426/GSE140829 跨平台 AUC 与 FDR 复现衰减，主图和 claim audit 支持 Q4-oriented limited-transferability manuscript | 不建议逆转，除非新增外部数据改变跨平台 AUC 结论 |
| D-012 | 2026-05-01 | B5/B6 通过，进入论文起草包 | 写作框架已将主张限制为 limited diagnostic transferability，投稿策略已有 Q4-oriented 路线和期刊排除清单 | 可逆；若投稿前 JCR/SCIE 复核不匹配，则调整候选期刊但不改变论文证据主张 |
| D-013 | 2026-05-01 | Route B manuscript V1 初稿完成 | 初稿完整覆盖 Abstract、Introduction、Methods、Results、Discussion、Conclusion、Data/Code/Ethics 和待核查参考文献，且未偏离 limited transferability 主张 | 可逆；下一轮将补文献、软件版本和投稿格式 |
| D-014 | 2026-05-01 | Route B manuscript V1.1 完成但不得投稿，进入 V1.2 major revision | V1.1 已补强 Introduction、引用框架、R/包版本和脚本链；完整审稿认为 Route B 主张正确但投稿前仍需补 declarations、正式 references、mapping/model details、figure callouts 和 supplementary traceability | 可逆；仅在 V1.2 修复后重新审稿并判断是否进入投稿准备 |
| D-015 | 2026-05-01 | Route B manuscript V1.2 内容修订通过，进入投稿包准备 | V1.2 已补齐 GDUPT 作者单位、ORCID、基金、利益冲突、声明、Methods 细节、图注、领域文献和 traceability table；20 条参考文献均被正文调用，TODO 为 0 | 可逆；若 final citation/style 或图件终检失败，则回到 V1.2 修订，不改变 Route B 主张 |
| D-016 | 2026-05-01 | 完整论文生成前停止并报告 | BMC-style V1.3、title page、cover letter、citation/style audit、figure QC 和 code archive decision 已完成；图件分辨率和 panel labels 通过；用户要求进入完整论文生成时报告 | 可逆；用户确认后进入 DOCX/PDF 生成和最终渲染检查 |
| D-017 | 2026-05-01 | 完整论文 DOCX/PDF 与 cover letter 生成通过 | Manuscript DOCX/PDF、cover letter DOCX/PDF 均生成；artifact-tool 渲染 QA 通过；引用覆盖 20/20；TODO 为 0 | 条件通过；公共代码归档 URL/DOI 和最终 DOI/PMID live-link check 仍需投稿前完成 |

### 2026-05-01 - GitHub NO.2 archive index and regenerated manuscript

Action: confirmed the connected GitHub repository as `1627626277-cyber/NO.2`, created the Route B archive index in that repository, updated the manuscript Availability of data and materials statement, rebuilt DOCX/PDF outputs, and reran render QA.

Outputs:
- `submission/github_NO2_archive/ad-blood-transcriptome-transportability/`
- `submission/github_NO2_archive/ad-blood-transcriptome-transportability_2026-05-01.zip`
- `submission/github_NO2_archive/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip`
- `submission/github_NO2_archive/github_upload_parts/`
- `submission/bmc_medical_genomics_route_b_2026-05-01/GITHUB_ARCHIVE_UPLOAD_STATUS.md`
- regenerated `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.docx`
- regenerated `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.pdf`

Remote GitHub files created:
- `README.md`
- `ad-blood-transcriptome-transportability/README.md`
- `ad-blood-transcriptome-transportability/ARCHIVE_SCOPE.md`
- `ad-blood-transcriptome-transportability/ARCHIVE_RECONSTRUCTION.md`
- `ad-blood-transcriptome-transportability/MANIFEST.tsv`

QC:
- GitHub archive index URL present in manuscript: `https://github.com/1627626277-cyber/NO.2/tree/main/ad-blood-transcriptome-transportability`.
- Manuscript DOCX render: 14 pages, pass.
- Cover letter DOCX render: 1 page, pass.
- Manuscript PDF page count: 14.
- Cover letter PDF page count: 1.
- References: 20; in-text coverage: 20/20.
- TODO markers: 0.
- No `D:\二区` reference remains in manuscript source or generated manuscript.

Risk:
- The GitHub remote currently contains the archive index, manifest, scope, and reconstruction instructions. The full compact snapshot is prepared locally but still needs final synchronization to the repository or a GitHub release/Zenodo DOI before formal journal upload.

Decision: proceed with GitHub URL in the manuscript as an archive index URL, but keep the final submission gate conditional until the full snapshot or DOI-backed archive is synchronized.

| D-018 | 2026-05-01 | Use `1627626277-cyber/NO.2` as the Route B GitHub archive index | The connected GitHub repository matches the user's NO.2 repository and is available for manuscript URL citation; local package and remote manifest now align | Conditional: full snapshot sync or DOI-backed archive still required before journal upload |

### 2026-05-01 - Author final review / pre-submission terminal check

Action: completed the author final review stage for the Route B manuscript package, regenerated a submission-ready DOCX, reran artifact-tool render QA, performed DOI/PMID/URL live-link checks, checked BMC/Springer submission metadata, and synchronized a pre-submission archive status file to GitHub NO.2.

Outputs:
- `submission/bmc_medical_genomics_route_b_2026-05-01/MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_SUBMISSION_READY.docx`
- `submission/bmc_medical_genomics_route_b_2026-05-01/qa_render_submission_ready/`
- `submission/bmc_medical_genomics_route_b_2026-05-01/qa_render_submission_ready_contact_sheet.png`
- `submission/bmc_medical_genomics_route_b_2026-05-01/crossref_doi_check.tsv`
- `submission/bmc_medical_genomics_route_b_2026-05-01/doi_resolver_live_check.tsv`
- `submission/bmc_medical_genomics_route_b_2026-05-01/url_live_check_final.tsv`
- `submission/bmc_medical_genomics_route_b_2026-05-01/PRE_SUBMISSION_FINAL_REVIEW_AND_METADATA_AUDIT.md`
- remote GitHub file `ad-blood-transcriptome-transportability/PRE_SUBMISSION_ARCHIVE_STATUS_2026-05-01.md`

QC:
- Submission-ready DOCX render: 20 pages, pass.
- Page numbering: applied and visibly rendered after Word COM field update.
- Line numbering: enabled in Word page setup and OOXML; artifact renderer does not visually show left-margin line numbers.
- DOI check: 15/15 Crossref records found; DOI resolver redirect chains present for 15/15 DOI URLs.
- PMID check: no PMID fields present.
- Non-DOI URL check: WHO, ORCID, GEO, GitHub archive index, and BMC/Springer URLs returned HTTP 200 after redirects.
- Metadata check: article type, title, author/affiliation, ORCID, abstract word count, keywords, declarations, figures, and supplementary tables are present.

Risk:
- Full binary archive synchronization was not completed. Local `git`/`gh` are unavailable and the available GitHub connector lacks release-asset/local binary upload capability. Formal journal upload should wait for GitHub release, full ZIP upload, base64 split-part upload, Zenodo DOI, or OSF DOI completion.

Decision: manuscript writing and pre-submission QA are complete, but submission gate remains conditional on full reproducibility archive synchronization.

| D-019 | 2026-05-01 | Treat Route B manuscript writing and pre-submission QA as complete but keep formal submission blocked | DOI/URL/metadata/render checks pass, but the GitHub remote still lacks the full local compact snapshot or DOI-backed archive | Reversible only after full archive sync or DOI creation |

### 2026-05-01 - Cells-style complete reading manuscript

Action: generated an integrated reading-version manuscript modeled on the Cells/MDPI reading experience, using the local `cells-15-00647-v3.pdf` as a layout reference. The reading version integrates title page metadata, abstract, keywords, main text, Figures 1-4, Tables 1-6, figure legends, supplementary table map, declarations, and references in one continuous document.

Outputs:
- `submission/bmc_medical_genomics_route_b_2026-05-01/READING_VERSION_CELLS_STYLE_MANUSCRIPT.docx`
- `submission/bmc_medical_genomics_route_b_2026-05-01/READING_VERSION_CELLS_STYLE_MANUSCRIPT.pdf`
- `submission/bmc_medical_genomics_route_b_2026-05-01/READING_VERSION_CELLS_STYLE_BUILD_QA.md`
- `submission/bmc_medical_genomics_route_b_2026-05-01/qa_render_cells_style_reading/`
- `submission/bmc_medical_genomics_route_b_2026-05-01/qa_render_cells_style_reading_contact_sheet.png`
- `scripts/build_cells_style_reading_manuscript.py`

QC:
- Artifact-tool DOCX render: 11 pages.
- Word-exported PDF: 11 pages.
- Figures 1-4 and Tables 1-6 render in reading order.
- No missing figure, blank-page failure, or obvious text overlap detected in the contact sheet.

Decision: use this file for author visual reading and holistic manuscript review only. It is not an official Cells template and does not change the Route B manuscript claim.
