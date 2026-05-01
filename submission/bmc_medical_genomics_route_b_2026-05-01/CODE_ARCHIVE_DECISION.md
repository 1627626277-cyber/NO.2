# Code and Result Archive Decision

Date: 2026-05-01

Project: AD Route B limited diagnostic transferability manuscript

## Decision

Use GitHub for the first public archive step. The confirmed author-controlled repository is `1627626277-cyber/NO.2`, with the Route B archive index at:

https://github.com/1627626277-cyber/NO.2/tree/main/ad-blood-transcriptome-transportability

The local compact package has been prepared in `D:\three\submission\github_NO2_archive`. The remote repository currently contains the archive index, scope, manifest, and reconstruction instructions. The full compact snapshot should be synchronized to the repository, or a GitHub release/Zenodo DOI should be created, before formal journal submission.

During the 2026-05-01 pre-submission pass, full binary synchronization could not be completed from this environment because local `git`/`gh` were unavailable and the available GitHub connector did not expose a release-asset or local binary upload workflow.

## Recommended archive name

`ad-blood-transcriptome-transportability`

## Recommended public contents

Include:

- `scripts/`
- `results/*.csv`
- `audit/*.md`
- `figures/route_b/*.png`
- `manuscript/ROUTE_B_REPRODUCIBILITY_TRACEABILITY_TABLE_V1_2.md`
- `manuscript/ROUTE_B_SUPPLEMENTARY_TABLES.md`
- `PROJECT_ROUTE_B_EXECUTION_PLAN.md`
- a `README.md` describing dataset accessions, script order, R version, package versions, and expected outputs

Exclude or avoid uploading without review:

- large raw GEO files if they can be re-downloaded from GEO;
- large processed RDS matrices unless required for exact reproduction;
- personal account tokens, local credentials, browser caches, or unrelated project folders;
- any material copied from external reference folders or unrelated manuscripts.

## Minimum archive README content

- Study title.
- Dataset accessions: GSE63060, GSE63061, GSE85426, GSE140829.
- Execution order from `freeze_s1_geo_metadata.py` to `s11_route_b_b4_transportability_audit.R`.
- R version: 4.5.3.
- Key packages and versions.
- Explanation that validation datasets were not used to rescue diagnostic model claims.
- Contact: Zhuang Jiang, 1627626277@qq.com.

## Gate result

**GITHUB_INDEX_CREATED; FULL_SNAPSHOT_SYNC_PENDING_BEFORE_FORMAL_SUBMISSION**.

The manuscript may now cite the GitHub archive index URL. Before final journal upload, synchronize the full compact snapshot or create a release/Zenodo DOI so that the archive contains the files listed in `MANIFEST.tsv`.
