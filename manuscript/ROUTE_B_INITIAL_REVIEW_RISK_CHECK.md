# Initial Reviewer-Style Risk Check

Review date: 2026-05-01

## Overall Assessment

Decision at this draft stage: major revision before submission.

The manuscript has a coherent Q4-oriented argument, but it is still an initial draft. Its main strength is transparent staged validation. Its main risk is that editors may see the biological novelty as limited unless the validation-failure and transportability-audit contribution is made explicit throughout the manuscript.

## Major Issues

### 1. Citation verification is incomplete

The draft contains a "References to Verify" section rather than a finalized reference list. Before journal submission, all dataset, method, and disease-background citations must be converted to the target journal style and checked against PubMed, DOI, or official GEO records.

Severity: high.

### 2. Introduction needs stronger literature positioning

The introduction currently states the problem clearly but needs more support from prior AD blood transcriptomic studies, prior GSE63060/GSE63061 biomarker papers, and literature on external validation failure.

Severity: high.

### 3. Methods are strong but still need software versions

The methods describe the analysis flow, but submission will require package versions, R version, exact thresholds, and script names. These are available in the project but not yet fully integrated into prose.

Severity: medium.

### 4. Figure captions need panel labels after final figure polishing

Current captions describe the figures, but final manuscript captions should refer to panels A, B, C when the figures are relabeled.

Severity: medium.

### 5. Discussion must not drift toward biomarker promotion

The draft mostly avoids overclaiming. During revision, ensure that phrases such as "diagnostic signature" or "biomarker" always appear with qualifiers such as "limited transferability" or "not clinically validated."

Severity: high.

## Strengths

- Clear Route B framing.
- Strong evidence chain from discovery to related validation to cross-platform degradation.
- Transparent negative model-performance result.
- Stable/unstable gene-set analysis supports the transportability framing.
- Pathway interpretation is cautious and does not overstate causality.

## Recommended Next Revision Pass

1. Add verified references and target-journal citation style.
2. Expand Introduction with 8-12 verified literature citations.
3. Add a "Reproducibility and leakage control" methods subsection.
4. Convert result paragraphs into journal-ready style with table and figure cross-references.
5. Polish the four figures with panel labels and consistent typography.
