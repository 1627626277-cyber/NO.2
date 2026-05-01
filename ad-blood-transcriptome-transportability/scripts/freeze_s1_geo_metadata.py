from __future__ import annotations

import csv
import gzip
import hashlib
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
AUDIT = ROOT / "audit"
AUDIT.mkdir(exist_ok=True)


DATASETS = {
    "GSE63060": {
        "role": "training_candidate",
        "geo_page": "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63060",
        "source_note": "AddNeuroMed cohort batch 1; planned primary training dataset after AD/Control filtering.",
        "files": {
            "series_matrix": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63060/matrix/GSE63060_series_matrix.txt.gz",
            "normalized": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63060/suppl/GSE63060_normalized.txt.gz",
            "non_normalized": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63060/suppl/GSE63060_non-normalized.txt.gz",
            "raw_tar": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63060/suppl/GSE63060_RAW.tar",
        },
    },
    "GSE63061": {
        "role": "external_validation_1",
        "geo_page": "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE63061",
        "source_note": "AddNeuroMed cohort batch 2; planned first independent external validation dataset.",
        "files": {
            "series_matrix": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63061/matrix/GSE63061_series_matrix.txt.gz",
            "normalized": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63061/suppl/GSE63061_normalized.txt.gz",
            "non_normalized": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63061/suppl/GSE63061_non-normalized.txt.gz",
            "raw_tar": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE63nnn/GSE63061/suppl/GSE63061_RAW.tar",
        },
    },
    "GSE85426": {
        "role": "external_validation_2",
        "geo_page": "https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE85426",
        "source_note": "Peripheral blood AD early detection dataset; planned second external validation dataset.",
        "files": {
            "series_matrix_metadata": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE85nnn/GSE85426/matrix/GSE85426_series_matrix.txt.gz",
            "normalized": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE85nnn/GSE85426/suppl/GSE85426_normalized_data.txt.gz",
            "raw": "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE85nnn/GSE85426/suppl/GSE85426_raw_data.txt.gz",
        },
    },
}


def strip_geo_value(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        return value[1:-1]
    return value


def normalize_key(key: str) -> str:
    chars = []
    for ch in key.strip().lower():
        if ch.isalnum():
            chars.append(ch)
        else:
            chars.append("_")
    out = "".join(chars)
    while "__" in out:
        out = out.replace("__", "_")
    return out.strip("_")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_series_matrix(accession: str) -> tuple[dict[str, str], list[dict[str, str]]]:
    path = RAW / f"{accession}_series_matrix.txt.gz"
    metadata: dict[str, str] = {}
    sample_fields: dict[str, list[str]] = {}
    characteristics: list[list[str]] = []

    with gzip.open(path, "rt", encoding="utf-8", errors="replace", newline="") as fh:
        reader = csv.reader(fh, delimiter="\t")
        for row in reader:
            if not row:
                continue
            key = row[0]
            values = [strip_geo_value(v) for v in row[1:]]
            if key == "!series_matrix_table_begin":
                break
            if key.startswith("!Series_") and values:
                metadata[key[1:]] = "; ".join(values)
            elif key.startswith("!Sample_characteristics_ch1"):
                characteristics.append(values)
            elif key.startswith("!Sample_"):
                sample_fields[key[1:]] = values

    accessions = sample_fields.get("Sample_geo_accession", [])
    samples = [{"dataset_accession": accession, "sample_index": str(i + 1)} for i in range(len(accessions))]

    for field, values in sample_fields.items():
        out_field = normalize_key(field.replace("Sample_", "sample_"))
        for i, value in enumerate(values[: len(samples)]):
            samples[i][out_field] = value

    for values in characteristics:
        for i, value in enumerate(values[: len(samples)]):
            raw = value.strip()
            if ":" in raw:
                key, val = raw.split(":", 1)
                out_key = normalize_key(key)
                out_val = val.strip()
            else:
                out_key = "characteristic"
                out_val = raw
            if out_key in samples[i] and samples[i][out_key] != out_val:
                suffix = 2
                while f"{out_key}_{suffix}" in samples[i]:
                    suffix += 1
                out_key = f"{out_key}_{suffix}"
            samples[i][out_key] = out_val

    platform = metadata.get("Series_platform_id", "")
    title = metadata.get("Series_title", "")
    for sample in samples:
        sample["dataset_role"] = DATASETS[accession]["role"]
        sample["platform_id"] = platform
        sample["series_title"] = title
        sample["source_note"] = DATASETS[accession]["source_note"]
        status_raw = (
            sample.get("status")
            or sample.get("diagnosis")
            or sample.get("disease_state")
            or sample.get("sample_title")
            or ""
        )
        sample["status_raw"] = status_raw
        diagnosis = clean_diagnosis(status_raw)
        sample["diagnosis_clean"] = diagnosis
        include, reason = inclusion_status(diagnosis)
        sample["include_primary_ad_control"] = include
        sample["exclusion_reason"] = reason

    return metadata, samples


def clean_diagnosis(raw: str) -> str:
    text = raw.lower()
    exact = text.strip()
    if " to " in exact:
        return "Transition"
    if exact == "ctl":
        return "Control"
    if exact == "ad":
        return "AD"
    if "mci" in text or "mild cognitive" in text:
        return "MCI"
    if "ctl" in text or "control" in text or "non-demented" in text or "non dementia" in text:
        return "Control"
    if "probable ad" in text or "alzheimer" in text or text.strip() == "ad":
        return "AD"
    return "Unknown"


def inclusion_status(diagnosis: str) -> tuple[str, str]:
    if diagnosis in {"AD", "Control"}:
        return "yes", ""
    if diagnosis == "MCI":
        return "no", "Exclude MCI from primary AD vs Control analysis."
    if diagnosis == "Transition":
        return "no", "Exclude diagnosis transition status from stable AD vs Control analysis."
    return "no", "Diagnosis could not be normalized to AD or Control."


def write_csv(path: Path, rows: list[dict[str, str]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        writer.writerows(rows)


def build_inventory() -> list[dict[str, str]]:
    rows = []
    for accession, spec in DATASETS.items():
        for file_type, url in spec["files"].items():
            candidates = list(RAW.glob(f"{accession}*"))
            path = None
            filename_from_url = url.rsplit("/", 1)[-1]
            direct = RAW / filename_from_url
            if direct.exists():
                path = direct
            elif file_type == "series_matrix_metadata":
                alt = RAW / f"{accession}_series_matrix.txt.gz"
                if alt.exists():
                    path = alt
            elif file_type == "raw_tar":
                alt = RAW / f"{accession}_RAW.tar"
                if alt.exists():
                    path = alt
            elif candidates:
                matching = [p for p in candidates if file_type.replace("_", "-") in p.name or file_type in p.name]
                path = matching[0] if matching else None

            if path and path.exists():
                size = path.stat().st_size
                rows.append(
                    {
                        "dataset_accession": accession,
                        "dataset_role": spec["role"],
                        "file_type": file_type,
                        "relative_path": str(path.relative_to(ROOT)).replace("\\", "/"),
                        "bytes": str(size),
                        "mb": f"{size / 1024 / 1024:.2f}",
                        "sha256": sha256_file(path),
                        "source_url": url,
                        "geo_page": spec["geo_page"],
                        "download_status": "downloaded",
                        "frozen_at": datetime.now().isoformat(timespec="seconds"),
                    }
                )
            else:
                rows.append(
                    {
                        "dataset_accession": accession,
                        "dataset_role": spec["role"],
                        "file_type": file_type,
                        "relative_path": "",
                        "bytes": "",
                        "mb": "",
                        "sha256": "",
                        "source_url": url,
                        "geo_page": spec["geo_page"],
                        "download_status": "missing",
                        "frozen_at": datetime.now().isoformat(timespec="seconds"),
                    }
                )
    return rows


def main() -> None:
    inventory = build_inventory()
    write_csv(
        ROOT / "data" / "data_inventory.csv",
        inventory,
        [
            "dataset_accession",
            "dataset_role",
            "file_type",
            "relative_path",
            "bytes",
            "mb",
            "sha256",
            "source_url",
            "geo_page",
            "download_status",
            "frozen_at",
        ],
    )

    all_samples: list[dict[str, str]] = []
    series_metadata: dict[str, dict[str, str]] = {}
    for accession in DATASETS:
        meta, samples = parse_series_matrix(accession)
        series_metadata[accession] = meta
        all_samples.extend(samples)

    sample_fields = [
        "dataset_accession",
        "dataset_role",
        "platform_id",
        "sample_index",
        "sample_geo_accession",
        "sample_title",
        "sample_source_name_ch1",
        "sample_organism_ch1",
        "status_raw",
        "diagnosis_clean",
        "include_primary_ad_control",
        "exclusion_reason",
        "status",
        "diagnosis",
        "tissue",
        "age",
        "gender",
        "ethnicity",
        "included_in_case_control_study",
        "series_title",
        "source_note",
    ]
    write_csv(ROOT / "data" / "sample_sheet.csv", all_samples, sample_fields)

    locked_samples = [s for s in all_samples if s["include_primary_ad_control"] == "yes"]
    write_csv(ROOT / "data" / "primary_inclusion_locked.csv", locked_samples, sample_fields)

    summary_rows = []
    by_dataset: dict[str, Counter] = defaultdict(Counter)
    included_by_dataset: dict[str, Counter] = defaultdict(Counter)
    for sample in all_samples:
        acc = sample["dataset_accession"]
        diag = sample["diagnosis_clean"]
        by_dataset[acc][diag] += 1
        if sample["include_primary_ad_control"] == "yes":
            included_by_dataset[acc][diag] += 1
    for acc in DATASETS:
        for diag, count in sorted(by_dataset[acc].items()):
            summary_rows.append(
                {
                    "dataset_accession": acc,
                    "diagnosis_clean": diag,
                    "all_samples": str(count),
                    "included_primary_ad_control": str(included_by_dataset[acc][diag]),
                }
            )
    write_csv(
        AUDIT / "s1_sample_summary.csv",
        summary_rows,
        ["dataset_accession", "diagnosis_clean", "all_samples", "included_primary_ad_control"],
    )

    readme = [
        "# S1 Dataset Freeze README",
        "",
        f"Generated at: {datetime.now().isoformat(timespec='seconds')}",
        "",
        "## Frozen datasets",
        "",
    ]
    for acc, spec in DATASETS.items():
        meta = series_metadata[acc]
        readme.extend(
            [
                f"### {acc}",
                "",
                f"- Role: {spec['role']}",
                f"- GEO page: {spec['geo_page']}",
                f"- Series title: {meta.get('Series_title', '')}",
                f"- Platform: {meta.get('Series_platform_id', '')}",
                f"- Type: {meta.get('Series_type', '')}",
                f"- Design: {meta.get('Series_overall_design', '')}",
                "",
            ]
        )
    readme.extend(
        [
            "## Outputs",
            "",
            "- `data/data_inventory.csv`: downloaded files, source URLs, sizes, SHA-256 checksums.",
            "- `data/sample_sheet.csv`: parsed GEO sample metadata and AD/Control inclusion flag.",
            "- `data/primary_inclusion_locked.csv`: locked primary AD/Control sample list for downstream analysis.",
            "- `audit/s1_sample_summary.csv`: counts by dataset and normalized diagnosis.",
            "",
            "## Gate 1 status",
            "",
            "Pass for data freeze. Files, initial sample metadata, and the locked AD/Control inclusion list are frozen.",
            "S2 preprocessing should use `data/primary_inclusion_locked.csv` as the sample source of truth.",
            "",
        ]
    )
    (ROOT / "data" / "dataset_readme.md").write_text("\n".join(readme), encoding="utf-8")

    print("Wrote data/data_inventory.csv")
    print("Wrote data/sample_sheet.csv")
    print("Wrote data/primary_inclusion_locked.csv")
    print("Wrote audit/s1_sample_summary.csv")
    print("Wrote data/dataset_readme.md")
    print("Sample counts:")
    for row in summary_rows:
        print(row)


if __name__ == "__main__":
    main()
