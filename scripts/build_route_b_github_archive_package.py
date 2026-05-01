from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from pathlib import Path
import hashlib
import shutil
import zipfile


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_NAME = "ad-blood-transcriptome-transportability"
ARCHIVE_DATE = date(2026, 5, 1).isoformat()
OUT_ROOT = ROOT / "submission" / "github_NO2_archive"
PKG = OUT_ROOT / ARCHIVE_NAME
ZIP_PATH = OUT_ROOT / f"{ARCHIVE_NAME}_{ARCHIVE_DATE}.zip"
UPLOAD_ZIP_PATH = OUT_ROOT / f"{ARCHIVE_NAME}_{ARCHIVE_DATE}_github_upload_snapshot.zip"
UPLOAD_PARTS = OUT_ROOT / "github_upload_parts"
REPO_URL = "https://github.com/1627626277-cyber/NO.2"
ARCHIVE_URL = f"{REPO_URL}/tree/main/{ARCHIVE_NAME}"


@dataclass(frozen=True)
class Include:
    src: str
    dst: str


INCLUDES = [
    Include("scripts/freeze_s1_geo_metadata.py", "scripts/freeze_s1_geo_metadata.py"),
    Include("scripts/s2_preprocess_qc.R", "scripts/s2_preprocess_qc.R"),
    Include("scripts/s3_limma_deg.R", "scripts/s3_limma_deg.R"),
    Include("scripts/s4_external_validation.R", "scripts/s4_external_validation.R"),
    Include("scripts/s5_model_optimization.R", "scripts/s5_model_optimization.R"),
    Include("scripts/s5_gse85426_posthoc_upper_bound.R", "scripts/s5_gse85426_posthoc_upper_bound.R"),
    Include("scripts/s5_train_dev_refit_final_validation.R", "scripts/s5_train_dev_refit_final_validation.R"),
    Include("scripts/s6_risk_route_dataset_scan.R", "scripts/s6_risk_route_dataset_scan.R"),
    Include("scripts/s7_route_a_gse140829_validation.R", "scripts/s7_route_a_gse140829_validation.R"),
    Include("scripts/s8_route_b_b1_evidence_consolidation.R", "scripts/s8_route_b_b1_evidence_consolidation.R"),
    Include("scripts/s9_route_b_b2_stable_unstable_gene_sets.R", "scripts/s9_route_b_b2_stable_unstable_gene_sets.R"),
    Include("scripts/s10_route_b_b3_pathway_enrichment.R", "scripts/s10_route_b_b3_pathway_enrichment.R"),
    Include("scripts/s11_route_b_b4_transportability_audit.R", "scripts/s11_route_b_b4_transportability_audit.R"),
    Include("results/route_b_b1_dataset_role_summary.csv", "results/route_b_b1_dataset_role_summary.csv"),
    Include("results/route_b_b1_evidence_dashboard.csv", "results/route_b_b1_evidence_dashboard.csv"),
    Include("results/route_b_b1_model_auc_long.csv", "results/route_b_b1_model_auc_long.csv"),
    Include("results/route_b_b1_replication_summary.csv", "results/route_b_b1_replication_summary.csv"),
    Include("results/route_b_b2_gene_transportability_classification.csv", "results/route_b_b2_gene_transportability_classification.csv"),
    Include("results/route_b_b2_overlap_table.csv", "results/route_b_b2_overlap_table.csv"),
    Include("results/route_b_b2_set_summary.csv", "results/route_b_b2_set_summary.csv"),
    Include("results/route_b_stable_genes.csv", "results/route_b_stable_genes.csv"),
    Include("results/route_b_stable_directional_sensitivity_genes.csv", "results/route_b_stable_directional_sensitivity_genes.csv"),
    Include("results/route_b_unstable_genes.csv", "results/route_b_unstable_genes.csv"),
    Include("results/route_b_b3_database_summary.csv", "results/route_b_b3_database_summary.csv"),
    Include("results/route_b_b3_enrichment_significant_fdr005.csv", "results/route_b_b3_enrichment_significant_fdr005.csv"),
    Include("results/route_b_b3_module_summary.csv", "results/route_b_b3_module_summary.csv"),
    Include("results/route_b_b3_top_terms_for_manuscript.csv", "results/route_b_b3_top_terms_for_manuscript.csv"),
    Include("results/route_b_b4_auc_decay_summary.csv", "results/route_b_b4_auc_decay_summary.csv"),
    Include("results/route_b_b4_gate_summary.csv", "results/route_b_b4_gate_summary.csv"),
    Include("results/route_b_b4_manuscript_claim_audit.csv", "results/route_b_b4_manuscript_claim_audit.csv"),
    Include("results/route_b_b4_mci_score_gradient.csv", "results/route_b_b4_mci_score_gradient.csv"),
    Include("results/route_b_b4_pathway_yield_summary.csv", "results/route_b_b4_pathway_yield_summary.csv"),
    Include("results/route_b_b4_transportability_metrics.csv", "results/route_b_b4_transportability_metrics.csv"),
    Include("results/route_b_b5_claim_evidence_matrix.csv", "results/route_b_b5_claim_evidence_matrix.csv"),
    Include("figures/route_b/B4_main_figure1_dataset_workflow.png", "figures/route_b/B4_main_figure1_dataset_workflow.png"),
    Include("figures/route_b/B4_main_figure2_validation_heatmap.png", "figures/route_b/B4_main_figure2_validation_heatmap.png"),
    Include("figures/route_b/B4_main_figure3_auc_and_scores.png", "figures/route_b/B4_main_figure3_auc_and_scores.png"),
    Include("figures/route_b/B4_main_figure4_pathway_comparison.png", "figures/route_b/B4_main_figure4_pathway_comparison.png"),
    Include("audit/route_b_b1_evidence_consolidation_report.md", "audit/route_b_b1_evidence_consolidation_report.md"),
    Include("audit/route_b_b2_stable_unstable_gene_sets_report.md", "audit/route_b_b2_stable_unstable_gene_sets_report.md"),
    Include("audit/route_b_b3_pathway_interpretation_report.md", "audit/route_b_b3_pathway_interpretation_report.md"),
    Include("audit/route_b_b4_transportability_audit_report.md", "audit/route_b_b4_transportability_audit_report.md"),
    Include("audit/gate_b5_b6_framing_submission_review.md", "audit/gate_b5_b6_framing_submission_review.md"),
    Include("audit/s2_sessionInfo.txt", "audit/s2_sessionInfo.txt"),
    Include("audit/s3_limma_sessionInfo.txt", "audit/s3_limma_sessionInfo.txt"),
    Include("audit/s4_sessionInfo.txt", "audit/s4_sessionInfo.txt"),
    Include("audit/s5_sessionInfo.txt", "audit/s5_sessionInfo.txt"),
    Include("manuscript/ROUTE_B_REPRODUCIBILITY_TRACEABILITY_TABLE_V1_2.md", "manuscript/ROUTE_B_REPRODUCIBILITY_TRACEABILITY_TABLE_V1_2.md"),
    Include("manuscript/ROUTE_B_SUPPLEMENTARY_TABLES.md", "manuscript/ROUTE_B_SUPPLEMENTARY_TABLES.md"),
    Include("PROJECT_ROUTE_B_EXECUTION_PLAN.md", "PROJECT_ROUTE_B_EXECUTION_PLAN.md"),
]


UPLOAD_ZIP_EXCLUDES = {
    "results/route_b_b2_gene_transportability_classification.csv",
    "results/route_b_stable_directional_sensitivity_genes.csv",
    "results/route_b_unstable_genes.csv",
    "figures/route_b/B4_main_figure1_dataset_workflow.png",
    "figures/route_b/B4_main_figure2_validation_heatmap.png",
    "figures/route_b/B4_main_figure3_auc_and_scores.png",
    "figures/route_b/B4_main_figure4_pathway_comparison.png",
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def build_readme() -> str:
    return f"""# AD blood transcriptome transportability archive

This archive supports the Route B manuscript:

Peripheral blood transcriptomic signatures of Alzheimer's disease show cohort-dependent reproducibility and limited diagnostic transferability.

## Scope

This is a compact reproducibility package for the public-data transportability audit. It contains analysis scripts, key result tables, audit reports, and manuscript figures needed to trace the main claims. Large raw GEO files and large intermediate matrices are not included because they can be retrieved from GEO or regenerated by the scripts.

## Public datasets

- GSE63060: discovery cohort
- GSE63061: related validation cohort
- GSE85426: cross-platform stress-test cohort
- GSE140829: large independent cross-platform validation cohort

## Reproduction order

Run the scripts in this order from the project root:

1. `scripts/freeze_s1_geo_metadata.py`
2. `scripts/s2_preprocess_qc.R`
3. `scripts/s3_limma_deg.R`
4. `scripts/s4_external_validation.R`
5. `scripts/s5_model_optimization.R`
6. `scripts/s5_gse85426_posthoc_upper_bound.R`
7. `scripts/s5_train_dev_refit_final_validation.R`
8. `scripts/s6_risk_route_dataset_scan.R`
9. `scripts/s7_route_a_gse140829_validation.R`
10. `scripts/s8_route_b_b1_evidence_consolidation.R`
11. `scripts/s9_route_b_b2_stable_unstable_gene_sets.R`
12. `scripts/s10_route_b_b3_pathway_enrichment.R`
13. `scripts/s11_route_b_b4_transportability_audit.R`

## Software

The final analysis was run with R 4.5.3. Key R packages included data.table 1.17.8, limma 3.66.0, ggplot2 4.0.3, glmnet 4.1.10, pROC 1.19.0.1, clusterProfiler 4.18.4, org.Hs.eg.db 3.22.0, ReactomePA 1.54.0, AnnotationDbi 1.72.0, GO.db 3.22.0, KEGGREST 1.50.0, patchwork 1.3.2, and png 0.1.9.

## Main interpretation

The archive is designed to support a cautious negative-validation claim. GSE85426 and GSE140829 were not used to rescue or tune a diagnostic model. The main conclusion is limited cross-platform diagnostic transferability, not a successful diagnostic classifier.

## Repository URL

{ARCHIVE_URL}
"""


def build_scope() -> str:
    return """# Archive Scope

Included:

- Analysis scripts used for the staged Route B workflow.
- Key CSV outputs supporting dataset roles, replication metrics, stable/unstable gene sets, pathway summaries, AUC decay, and manuscript claim checks.
- Route B audit reports and R session information files.
- Four main manuscript figures from `figures/route_b`.
- Reproducibility traceability and supplementary tables.

Excluded:

- Raw GEO downloads and large processed expression matrices.
- Large prediction grids and full model-prediction tables that are not necessary for tracing the manuscript's main claims.
- Personal credentials, browser caches, local environment files, and unrelated project content.
- Any files from the external reference folder used only for author metadata; this archive is built only from `D:\\three`.

The compact package is intended for manuscript review and reproducibility tracing. If a journal or reviewer requests full intermediate matrices, deposit those separately or add them through a release asset rather than expanding the manuscript repository.
"""


def build_root_readme() -> str:
    return f"""# NO.2

## AD blood transcriptome transportability archive

This repository contains the public archive index for the Route B Alzheimer's disease peripheral blood transcriptomics manuscript.

- Archive folder: [{ARCHIVE_NAME}]({ARCHIVE_NAME}/)
- Snapshot reconstruction: [{ARCHIVE_NAME}/ARCHIVE_RECONSTRUCTION.md]({ARCHIVE_NAME}/ARCHIVE_RECONSTRUCTION.md)
- Purpose: scripts, key results, audit reports, and figures for a limited-transferability external-validation study.

The study uses public GEO datasets GSE63060, GSE63061, GSE85426, and GSE140829.
"""


def build_reconstruction(part_names: list[str]) -> str:
    part_lines = "\n".join(f"- `archive_parts/{name}`" for name in part_names)
    return f"""# Archive Reconstruction

Because this session does not have a local Git client available, the compact GitHub upload snapshot is stored as base64 split parts. Reconstruct it by concatenating the parts in lexical order and base64-decoding them.

## Parts

{part_lines}

## PowerShell reconstruction

Run from the repository root after downloading or cloning the repository:

```powershell
$parts = Get-ChildItem -Path "{ARCHIVE_NAME}\\archive_parts" -Filter "*.b64.part*" | Sort-Object Name
$base64 = ($parts | ForEach-Object {{ Get-Content -Raw -Path $_.FullName }}) -join ""
[IO.File]::WriteAllBytes("{ARCHIVE_NAME}\\{ARCHIVE_NAME}_{ARCHIVE_DATE}_github_upload_snapshot.zip", [Convert]::FromBase64String($base64))
```

The reconstructed ZIP contains scripts, key result tables, audit reports, session information, reproducibility traceability materials, and the execution plan.
"""


def write_base64_parts(path: Path, chunk_size: int = 30000) -> list[str]:
    import base64

    if UPLOAD_PARTS.exists():
        shutil.rmtree(UPLOAD_PARTS)
    UPLOAD_PARTS.mkdir(parents=True, exist_ok=True)
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    names: list[str] = []
    for idx, start in enumerate(range(0, len(encoded), chunk_size), start=1):
        name = f"{path.name}.b64.part{idx:02d}"
        write_text(UPLOAD_PARTS / name, encoded[start : start + chunk_size] + "\n")
        names.append(name)
    return names


def main() -> int:
    if PKG.exists():
        shutil.rmtree(PKG)
    PKG.mkdir(parents=True, exist_ok=True)

    rows = ["path\tsize_bytes\tsha256"]
    for item in INCLUDES:
        src = ROOT / item.src
        if not src.exists():
            raise FileNotFoundError(src)
        dst = PKG / item.dst
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        rows.append(f"{item.dst}\t{dst.stat().st_size}\t{sha256(dst)}")

    write_text(PKG / "README.md", build_readme())
    write_text(PKG / "ARCHIVE_SCOPE.md", build_scope())
    write_text(PKG / "MANIFEST.tsv", "\n".join(rows) + "\n")
    write_text(OUT_ROOT / "README_FOR_GITHUB_ROOT.md", build_root_readme())

    if ZIP_PATH.exists():
        ZIP_PATH.unlink()
    with zipfile.ZipFile(ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for path in sorted(PKG.rglob("*")):
            if path.is_file():
                zf.write(path, path.relative_to(OUT_ROOT).as_posix())

    if UPLOAD_ZIP_PATH.exists():
        UPLOAD_ZIP_PATH.unlink()
    with zipfile.ZipFile(UPLOAD_ZIP_PATH, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for path in sorted(PKG.rglob("*")):
            if path.is_file():
                rel = path.relative_to(PKG).as_posix()
                if rel in UPLOAD_ZIP_EXCLUDES:
                    continue
                zf.write(path, path.relative_to(OUT_ROOT).as_posix())

    part_names = write_base64_parts(UPLOAD_ZIP_PATH)
    write_text(PKG / "ARCHIVE_RECONSTRUCTION.md", build_reconstruction(part_names))

    summary = OUT_ROOT / "ARCHIVE_BUILD_SUMMARY.md"
    write_text(
        summary,
        "\n".join(
            [
                "# GitHub Archive Build Summary",
                "",
                f"- Archive name: `{ARCHIVE_NAME}`",
                f"- Local package directory: `{PKG}`",
                f"- Local compact zip: `{ZIP_PATH}`",
                f"- GitHub upload snapshot zip: `{UPLOAD_ZIP_PATH}`",
                f"- Target repository: `{REPO_URL}`",
                f"- Target archive URL: `{ARCHIVE_URL}`",
                f"- Included files before generated README/scope/manifest: {len(INCLUDES)}",
                f"- Compact zip size bytes: {ZIP_PATH.stat().st_size}",
                f"- Compact zip SHA-256: `{sha256(ZIP_PATH)}`",
                f"- GitHub upload snapshot size bytes: {UPLOAD_ZIP_PATH.stat().st_size}",
                f"- GitHub upload snapshot SHA-256: `{sha256(UPLOAD_ZIP_PATH)}`",
                f"- GitHub upload base64 parts: {len(part_names)}",
                "",
                "Gate: READY_FOR_GITHUB_NO2_UPLOAD",
            ]
        )
        + "\n",
    )
    print(summary.read_text(encoding="utf-8"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
