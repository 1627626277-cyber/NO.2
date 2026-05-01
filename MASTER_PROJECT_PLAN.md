# 项目总推进规划

创建日期：2026-04-30  
项目目标：在 10 到 12 周内形成一篇面向 SCI Q3/Q4 的纯生信可投稿稿件。  
核心策略：以 Q3 为竞争目标，以 Q4 为稳定备选；先结果复现，再写作选刊。

## 一、项目定位

拟定题目：
基于公共外周血转录组与机器学习的阿尔茨海默病诊断标志物筛选及外部验证研究

论文卖点：
1. 公开大样本外周血转录组。
2. 训练集和外部验证集严格分离。
3. 双外部验证。
4. 防泄漏机器学习流程。
5. 可复现脚本和完整参数记录。

不作为卖点：
1. 不宣称发现全新机制。
2. 不宣称可直接临床诊断。
3. 不把堆叠算法数量作为创新点。
4. 不把公共数据相关性结果写成因果结论。

## 二、总时间线

| 周次 | 阶段 | 主要任务 | 核心输出 |
|---:|---|---|---|
| 1 | S1 数据冻结 | 下载数据、建立样本表、确定纳入排除 | data_inventory、sample_sheet |
| 2 | S2 预处理与 QC | probe 注释、标准化、QC、排除记录 | processed_matrix、QC 图 |
| 3 | S3 DEG 与候选基因 | limma、阈值敏感性、候选基因表 | DEG 表、候选基因表 |
| 4 | S4 富集与 PPI | GO/KEGG/Reactome、STRING、hub genes | 富集表、PPI 图、hub 表 |
| 5-6 | S5 建模 | LASSO/RF/SVM/Logistic、交叉验证、防泄漏检查 | 模型、ROC、校准 |
| 7 | S5 外部验证 | GSE63061、GSE85426 外部验证 | 外部验证表和图 |
| 8 | S6 稳健性 | 特征稳定性、平台差异、敏感性分析 | 稳健性报告 |
| 9-10 | S7 写作 | Methods、Results、Discussion、图表补充材料 | 初稿和图表包 |
| 11 | S8 预投稿审核 | 完整性核查、模拟审稿、修订 | 审核报告、修订版 |
| 12 | S9 选刊投稿 | 候选期刊复核、投稿材料、cover letter | 投稿包 |

## 三、阶段任务清单

### S1 数据冻结

任务：
- 下载 GSE63060、GSE63061、GSE85426。
- 保存下载链接、日期、文件大小、平台信息。
- 建立样本标签表，明确 AD、Control、MCI、排除样本。
- 建立数据字典。

完成标准：
- `data_inventory.csv`
- `sample_sheet.csv`
- `dataset_readme.md`
- 项目日志新增 S1 记录

### S2 预处理与 QC

任务：
- probe 到 gene symbol 注释。
- 去除空 symbol。
- 重复 probe 折叠。
- 标准化表达矩阵。
- 生成 PCA、箱线图或 RLE 图。

完成标准：
- `processed_expression_matrix.rds`
- `qc_report.md`
- `figures/qc_*`
- Data Integrity Auditor 放行

### S3 候选基因筛选

任务：
- 训练集内部完成 limma 差异分析。
- 根据血液转录组特征设置主阈值和敏感性阈值。
- 可选 WGCNA 作为辅助，不作为唯一筛选依据。
- 输出候选基因表。

完成标准：
- `deg_results.csv`
- `candidate_genes.csv`
- `parameter_table.md`
- Methodology Reviewer 放行

### S4 富集与 PPI

任务：
- GO、KEGG、Reactome 或 GSEA。
- STRING 建网。
- Cytoscape/cytoHubba 识别 hub genes。
- 将富集结果与 AD 机制连接。

完成标准：
- `enrichment_results.csv`
- `ppi_edges.csv`
- `hub_genes.csv`
- Domain Reviewer 放行

### S5 建模与外部验证

任务：
- 在训练集内部完成特征选择、调参和交叉验证。
- 对 LASSO、RF、SVM、Logistic 进行固定比较。
- 锁定最终特征和模型。
- 在 GSE63061、GSE85426 上做外部验证。

完成标准：
- `model_comparison.csv`
- `final_model.rds`
- `external_validation_results.csv`
- ROC、校准曲线、性能表
- Methodology Reviewer 和 Devil's Advocate 放行

### S6 稳健性分析

任务：
- 检查最终基因方向一致性。
- 检查不同阈值下特征稳定性。
- 检查年龄/性别等元数据可用性，若可用则做敏感性分析。
- 记录跨平台差异。

完成标准：
- `robustness_report.md`
- `feature_stability.csv`
- Reproducibility Auditor 放行

### S7 写作

任务：
- 写 Methods 时保证可复现。
- 写 Results 时每张图对应数据和脚本。
- Discussion 聚焦稳健性和限制。
- 补齐声明：Data Availability、Ethics、Author Contributions、Conflict of Interest、Funding、AI disclosure。

完成标准：
- `manuscript_draft.md`
- `figures/`
- `supplementary_tables/`
- Writing Quality Reviewer 放行

### S8 预投稿审核

任务：
- 完整性核查。
- 模拟审稿。
- Devil's Advocate 查找拒稿风险。
- 根据审核报告修订。

完成标准：
- `pre_submission_integrity_check.md`
- `simulated_peer_review.md`
- `revision_roadmap.md`
- 无未关闭 P0/P1 问题

### S9 选刊与投稿

任务：
- 建立至少 8 个候选期刊。
- 复核 SCIE、JCR 分区、范围、APC、审稿周期、公共数据研究接受度。
- 准备 cover letter、highlights、graphical abstract 或补充材料。

完成标准：
- `journal_shortlist.csv`
- `submission_package_checklist.md`
- `cover_letter.md`
- 投稿记录写入 `PROJECT_LOG.md`

## 四、周会与监督节奏

每周固定检查：
- 本周完成了什么。
- 哪些结果可复现。
- 哪些参数改变过。
- 哪些问题阻断下一阶段。
- 是否偏离 Q3/Q4 稿件定位。

每两周固定输出：
- 阶段审核报告。
- 风险更新。
- 日志更新。
- 下一阶段放行判断。

## 五、优先级

P0：
- 数据下载和样本表。
- 防泄漏建模脚本。
- 外部验证。
- 复现记录。

P1：
- 富集和 PPI 解释。
- 稳健性分析。
- 候选期刊复核。
- 完整性审核。

P2：
- SHAP、XGBoost、额外机制数据库。
- 图形美化。
- 扩展补充分析。

## 六、机会点

1. 若双外部验证 AUC 稳定，可把目标提升到 Q3。
2. 若最终基因能与免疫炎症、外周血细胞组成和 AD 文献形成一致链条，可增强 Discussion。
3. 若代码和数据记录完整，可把“可复现公共数据诊断模型”作为稿件特色。
4. 若 GSE85426 跨平台验证仍稳定，这是很强的稳健性卖点。

## 七、主要风险

| 风险 | 影响 | 应对 |
|---|---|---|
| 外部验证不稳定 | 降低 Q3 可能性 | 降级为 Q4 或重做特征筛选策略 |
| 特征泄漏 | 直接失去可信度 | 从脚本层面固定训练/验证边界 |
| 创新性不足 | 容易被拒 | 强调双外部验证、可复现、防泄漏和克制解释 |
| 生物学解释弱 | Discussion 空洞 | 只保留有文献和通路支撑的最终基因 |
| 选刊过高 | 周期损耗 | Q3/Q4 双层投稿池 |

## 八、立即执行清单

1. 建立项目目录：`data/raw`、`data/processed`、`scripts`、`results`、`figures`、`manuscript`、`audit`。
2. 下载并记录 GSE63060、GSE63061、GSE85426。
3. 建立 `sample_sheet.csv`。
4. 写第一个可运行脚本：数据读取、样本筛选、表达矩阵标准化。
5. 在 `PROJECT_LOG.md` 记录 S1 数据冻结过程。
6. 完成 Gate 1 数据冻结审核。
