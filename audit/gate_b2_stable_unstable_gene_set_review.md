# Gate B2 Stable/Unstable Gene-Set Review

Review date: 2026-05-01 07:09:52

## Decision

Gate B2 status: **PASS_TO_B3**

## Quantitative Basis

- Stable strict primary genes: 103
- Stable directional sensitivity genes: 327
- Unstable primary genes: 235
- Unstable reversal genes: 139
- Unstable signal-loss genes: 190
- Stable interpretable keyword fraction: 0.456
- Stable housekeeping-like keyword fraction: 0.408
- Stable immune/inflammatory keyword fraction: 0.049

## Required Next Step

- Proceed to B3 pathway and biological interpretation.
- Use `route_b_stable_genes.csv` as the primary stable set and `route_b_stable_directional_sensitivity_genes.csv` as sensitivity evidence.
- Treat keyword categories as a preliminary sanity check only; formal GO/KEGG/Reactome enrichment is still required.
