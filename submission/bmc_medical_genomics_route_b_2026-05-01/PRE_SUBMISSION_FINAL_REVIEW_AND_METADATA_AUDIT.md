# Pre-submission Final Review and Metadata Audit

Date: 2026-05-01

Target journal: BMC Medical Genomics

Review mode: author final review / pre-submission terminal check

## Verdict

**AUTHOR_FINAL_REVIEW_CONDITIONAL_PASS_PENDING_FULL_ARCHIVE_SYNC**.

The manuscript writing package is complete for author review and near-submission preparation. The remaining submission blocker is reproducibility archive synchronization: the GitHub repository currently contains the repository page, manifest, scope, and reconstruction instructions, but not the full local compact snapshot or a DOI-backed release.

## Manuscript and format terminal check

Official guidance checked:

- BMC Medical Genomics research article manuscript guidance: https://bmcmedgenomics.biomedcentral.com/submission-guidelines/preparing-your-manuscript/research-article
- Springer Nature pre-submission checklist for journal 12920: https://link.springer.com/pre-submission?journalId=12920

Files generated:

- `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.docx`
- `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_FULL.pdf`
- `MANUSCRIPT_BMC_MEDICAL_GENOMICS_ROUTE_B_SUBMISSION_READY.docx`
- `READING_VERSION_CELLS_STYLE_MANUSCRIPT.docx`
- `READING_VERSION_CELLS_STYLE_MANUSCRIPT.pdf`
- `COVER_LETTER_BMC_MEDICAL_GENOMICS_ROUTE_B.docx`
- `COVER_LETTER_BMC_MEDICAL_GENOMICS_ROUTE_B.pdf`

Submission-ready DOCX checks:

- Double-spaced body text: applied.
- Page numbering: applied and updated through Microsoft Word COM; artifact render shows visible page numbers.
- Line numbering: enabled in Word page setup and present in OOXML as `w:lnNumType` with `countBy=1`, `distance=360`, and `restart=continuous`. The artifact renderer does not visually show the left-margin line numbers, so this item is XML/Word-setting verified rather than artifact-visual verified.
- Artifact-tool DOCX render: 22 pages, no obvious clipping, blank-page failure, missing figure, or overlap.
- Contact sheet: `qa_render_submission_ready_contact_sheet.png`.

## Journal-system metadata check

- Article type: Research article.
- Title: External validation audit of peripheral blood transcriptomic signatures in Alzheimer's disease reveals cohort-dependent reproducibility and limited transferability.
- Title length: 163 characters.
- Running title: External validation audit of AD blood transcriptomic signatures.
- Author: Zhuang Jiang.
- Affiliation: Guangdong University of Petrochemical Technology (GDUPT), 139 Guandu 2nd Road, Maoming 525000, Guangdong, China.
- Corresponding email: 1627626277@qq.com.
- ORCID: https://orcid.org/0009-0007-4388-5901.
- Abstract word count: 330.
- Main manuscript word count before references and figures: 5,101.
- Keywords: 8.
- Figures: 4.
- Supplementary tables: S1-S11.
- Required declarations present: ethics approval and consent to participate; consent for publication; availability of data and materials; competing interests; funding; authors' contributions; acknowledgements.

## DOI, PMID, and URL live-link check

Outputs:

- `crossref_doi_check.tsv`
- `doi_resolver_live_check.tsv`
- `url_live_check_final.tsv`

Results:

- DOI records: 15/15 found through Crossref.
- DOI resolver check: 15/15 DOI URLs resolved at `https://doi.org/...`; several publisher endpoints returned 403 after DOI redirection, consistent with publisher anti-bot access rather than missing DOI records.
- PMID fields: none present in the manuscript reference list, so no PMID live-link failures were detected or applicable.
- Non-DOI URL live check: WHO, ORCID, GEO accessions GSE63060/GSE63061/GSE85426/GSE140829, GitHub repository page, and BMC/Springer guideline URLs returned HTTP 200 after redirects.

## Reproducibility archive status

Repository:

- GitHub repository: `1627626277-cyber/NO.2`
- Repository page URL: https://github.com/1627626277-cyber/NO.2/tree/main/ad-blood-transcriptome-transportability

Remote currently contains:

- `README.md`
- `ad-blood-transcriptome-transportability/README.md`
- `ad-blood-transcriptome-transportability/ARCHIVE_SCOPE.md`
- `ad-blood-transcriptome-transportability/ARCHIVE_RECONSTRUCTION.md`
- `ad-blood-transcriptome-transportability/MANIFEST.tsv`
- `ad-blood-transcriptome-transportability/PRE_SUBMISSION_ARCHIVE_STATUS_2026-05-01.md`

Local complete package:

- Full compact package directory: `D:\three\submission\github_NO2_archive\ad-blood-transcriptome-transportability`
- Full compact ZIP: `D:\three\submission\github_NO2_archive\ad-blood-transcriptome-transportability_2026-05-01.zip`
- Full compact ZIP SHA-256: `909b2acfd40a12c4f73e87f30a276c179ccfccb2a6d7f22a35779149ec733393`
- GitHub upload snapshot ZIP: `D:\three\submission\github_NO2_archive\ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip`
- GitHub upload snapshot ZIP SHA-256: `909b2acfd40a12c4f73e87f30a276c179ccfccb2a6d7f22a35779149ec733393`

Synchronization status:

- Full binary ZIP or release asset upload was not completed in this environment.
- Local `git` and `gh` are not available in PATH.
- The available GitHub connector can create/update UTF-8 text files and blobs, but no release-asset/local binary upload or tree/commit publication tool is available in this session.

## Submission decision

The manuscript files can be treated as writing-complete. Formal journal upload should wait until one of the following is completed:

1. Upload the full compact ZIP or reconstructed base64 split parts to GitHub.
2. Create a GitHub release containing the full compact ZIP.
3. Create a Zenodo/OSF DOI-backed archive from the same local package and replace or supplement the current Data/code availability URL.

Until then, the correct gate remains:

**WRITING_COMPLETE; PRE_SUBMISSION_QA_PASS; ARCHIVE_SYNC_BLOCKER_REMAINS**.
