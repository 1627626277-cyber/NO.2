# Figure Panel and Resolution QC

Date: 2026-05-01

Target journal: BMC Medical Genomics

Figure source directory: `figures/route_b/`

Submission figure directory: `submission/bmc_medical_genomics_route_b_2026-05-01/`

## Resolution and size check

| Figure | File | Width px | Height px | DPI | Size MB | QC |
|---|---|---:|---:|---:|---:|---|
| Figure 1 | `Figure1_dataset_workflow.png` | 2700 | 1140 | 300 | 0.076 | Pass |
| Figure 2 | `Figure2_validation_heatmap.png` | 2850 | 1440 | 300 | 0.157 | Pass |
| Figure 3 | `Figure3_auc_and_scores.png` | 2760 | 2280 | 300 | 0.217 | Pass |
| Figure 4 | `Figure4_pathway_comparison.png` | 2760 | 2220 | 300 | 0.143 | Pass |

All four figures are 300 dpi PNG files and exceed the approximate full-width journal display requirement at 300 dpi. File sizes are small enough for standard journal upload.

## Panel-label check

- Figure 1 is a single workflow-style figure and does not require panel letters unless the journal requests them.
- Figure 2 is a single heatmap-style figure and does not require panel letters unless the journal requests them.
- Figure 3 is a two-panel figure and now includes visible A/B panel labels after regeneration from `scripts/s11_route_b_b4_transportability_audit.R`.
- Figure 4 is a two-panel figure and now includes visible A/B panel labels after regeneration from `scripts/s11_route_b_b4_transportability_audit.R`.

## Action before final generation

No figure-resolution blocker remains. Keep the regenerated Figure 3 and Figure 4 files in the submission package.

Gate result: **RESOLUTION_PASS; PANEL_LABEL_PASS**.
