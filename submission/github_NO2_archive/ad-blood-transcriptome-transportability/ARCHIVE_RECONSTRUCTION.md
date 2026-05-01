# Archive Reconstruction

Because this session does not have a local Git client available, the compact GitHub upload snapshot is stored as base64 split parts. Reconstruct it by concatenating the parts in lexical order and base64-decoding them.

## Parts

- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part01`
- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part02`
- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part03`
- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part04`
- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part05`
- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part06`
- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part07`
- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part08`
- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part09`
- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part10`
- `archive_parts/ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip.b64.part11`

## PowerShell reconstruction

Run from the repository root after downloading or cloning the repository:

```powershell
$parts = Get-ChildItem -Path "ad-blood-transcriptome-transportability\archive_parts" -Filter "*.b64.part*" | Sort-Object Name
$base64 = ($parts | ForEach-Object { Get-Content -Raw -Path $_.FullName }) -join ""
[IO.File]::WriteAllBytes("ad-blood-transcriptome-transportability\ad-blood-transcriptome-transportability_2026-05-01_github_upload_snapshot.zip", [Convert]::FromBase64String($base64))
```

The reconstructed ZIP contains scripts, key result tables, audit reports, session information, reproducibility traceability materials, and the execution plan.
