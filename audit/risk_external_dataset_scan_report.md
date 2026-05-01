# Risk Response External Dataset Scan

Generated at: 2026-05-01 06:44:26

## Summary

   dataset_accession n_samples  n_ad n_control n_mci n_other platform
              <char>     <int> <int>     <int> <int>   <int>   <char>
1:         GSE140829       587   204       249   134       0 GPL15988
2:          GSE97760        19     9        10     0       0 GPL16699
3:          GSE18309         9     3         3     3       0   GPL570
4:           GSE4226        28    14        14     0       0  GPL1211
5:         GSE165090         6     0         3     0       3 GPL24676
                      route_a_role                        route_b_role
                            <char>                              <char>
1: primary_new_external_validation context_for_transportability_limits
2:     supporting_sensitivity_only context_for_transportability_limits
3:     supporting_sensitivity_only context_for_transportability_limits
4:     supporting_sensitivity_only context_for_transportability_limits
5:                         exclude                             exclude

## Decision-Relevant Notes

- GSE140829 is the only high-priority rescue dataset identified in this scan because it is large, peripheral blood, and has AD/MCI/Control labels.
- GSE97760, GSE18309, and GSE4226 are too small for primary validation but can support a transportability or sensitivity narrative.
- GSE165090 is excluded because it is not an Alzheimer blood cohort.
