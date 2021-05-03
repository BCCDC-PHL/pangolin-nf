# pangolin-nf

## Usage
```
nextflow run BCCDC-PHL/pangolin-nf \
  --analysis_parent_dir <analysis_parent_dir> \
  [--genome_completeness_threshold <genome_completeness_threshold> \
  --outdir <outdir>
```

## Output


| run_id                             | sample_id | genome_completeness |        genome_completeness_status  | lineage | conflict | pangoLEARN_version | pangolin_version | pango_version |    status | note |
|:-----------------------------------|:----------|--------------------:|-----------------------------------:|--------:|---------:|-------------------:|-----------------------------:|---------------|-----------|------|
| 210330_M01234_0123_000000000-G653A | sample-01 |                95.1 | ABOVE_GENOME_COMPLETENESS_THRESHOLD | B.1    |        0 |         2021-04-28 |                  2.4              |       v1.1.23 | passed_qc |      |
| 210330_M01234_0123_000000000-G653A | sample-02 |                75.2 | BELOW_GENOME_COMPLETENESS_THRESHOLD | P.1    |        0 |         2021-04-28 |                  2.4              |       v1.1.23 | passed_qc | 15/17 P.1 (B.1.1.28.1) SNPs (1 ref and 0 other)     |
| 210330_M01234_0123_000000000-G653A | sample-03 |                0    | BELOW_GENOME_COMPLETENESS_THRESHOLD | None    |        0 |         2021-04-28 |                  2.4              |       v1.1.23 | fail | N_content:1.0     |


