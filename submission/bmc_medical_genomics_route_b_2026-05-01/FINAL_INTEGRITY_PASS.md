# Final Integrity Pass

Date: 2026-05-01

Target journal: BMC Medical Genomics

Manuscript package: `submission/bmc_medical_genomics_route_b_2026-05-01`

## Generated files

| File | Status | Size bytes |
|---|---:|---:|
| `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.docx` | Generated | 560354 |
| `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.pdf` | Generated | 712031 |
| `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_SUBMISSION_READY.docx` | Generated | 665991 |
| `READING_VERSION_CELLS_STYLE_MANUSCRIPT.docx` | Generated | 683213 |
| `READING_VERSION_CELLS_STYLE_MANUSCRIPT.pdf` | Generated | 527831 |
| `COVER_LETTER_BMC_MEDICAL_GENOMICS_ROUTE_B.docx` | Generated | 11430 |
| `COVER_LETTER_BMC_MEDICAL_GENOMICS_ROUTE_B.pdf` | Generated | 50805 |

## Render checks

| Output | Render method | Pages | Result |
|---|---|---:|---|
| Manuscript DOCX | `render_docx.py --renderer artifact-tool` | 15 | Pass |
| Submission-ready DOCX | `render_docx.py --renderer artifact-tool` | 22 | Pass |
| Integrated reading DOCX | `render_docx.py --renderer artifact-tool` | 12 | Pass |
| Cover letter DOCX | `render_docx.py --renderer artifact-tool` | 1 | Pass |
| Manuscript PDF | Edge headless PDF export | 14 | Pass |
| Cover letter PDF | Edge headless PDF export | 1 | Pass |

Visual inspection summary:

- Manuscript pages render without obvious clipping, text overlap, missing figures, or blank-page errors.
- Submission-ready DOCX is double-spaced and page-numbered; line numbering is enabled in the DOCX Word page setup and OOXML, although the artifact renderer does not visually display left-margin line numbers.
- Integrated reading version renders as 12 pages with title/abstract, inline figures, AUC CI table, marker-score sensitivity table, supplementary table map, and references visible.
- Cover letter renders as one clean page.
- Figures 3 and 4 include A/B panel labels after regeneration.

## Citation and manuscript integrity

- References: 20.
- In-text citation coverage: 20/20.
- DOI terminal check: Crossref found 15/15 DOI records; DOI resolver returned valid redirect chains for 15/15 DOI URLs.
- PMID terminal check: no PMID fields are present in the manuscript reference list.
- Non-DOI URL terminal check: WHO, ORCID, GEO, GitHub repository page, and BMC/Springer URLs returned HTTP 200 after redirects.
- Missing in-text citations: none.
- TODO markers: 0.
- BMC-style declarations present: ethics approval and consent to participate; consent for publication; availability of data and materials; competing interests; funding; authors' contributions; acknowledgements.
- Main interpretation preserved: cohort-dependent reproducibility with limited independent-validation transferability.
- Diagnostic-success phrasing: no unqualified claim of a robust, clinically useful, validated diagnostic biomarker.

## Reproducibility and archive status

- R runtime: R 4.5.3 through conda environment `three-r`.
- Pandoc available and used.
- Figure-generation script updated: `scripts/s11_route_b_b4_transportability_audit.R`.
- Blood-cell marker-score sensitivity script added: `scripts/s13_blood_cell_marker_sensitivity.R`.
- Public GitHub repository page: `https://github.com/1627626277-cyber/NO.2/tree/main/ad-blood-transcriptome-transportability`.
- Archive gate: `GITHUB_INDEX_CREATED; FULL_SNAPSHOT_SYNC_PENDING_BEFORE_FORMAL_SUBMISSION`.
- GitHub connector limitation: full binary ZIP/release asset upload could not be completed because local `git`/`gh` are unavailable and the available connector exposes UTF-8 file/blob tools but no release-asset/local binary upload workflow.

## Residual before journal portal upload

1. Synchronize the local compact archive ZIP or base64 split parts to GitHub, or create a GitHub release/Zenodo DOI.
2. Upload figure PNGs separately in the journal portal even though embedded review figures are present in the generated manuscript.
3. Confirm journal portal metadata matches the title page exactly.

## Gate result

**DOCUMENT_GENERATION_PASS; RENDER_QA_PASS; DOI_URL_METADATA_PASS; FINAL_INTEGRITY_CONDITIONAL_PASS_PENDING_FULL_GITHUB_SNAPSHOT_SYNC**

The package is suitable for author review and near-submission preparation. It should not be journal-uploaded until the full GitHub snapshot or DOI-backed archive is synchronized with the manifest.
