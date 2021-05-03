# pangolin-nf

![push main](https://github.com/BCCDC-PHL/pangolin-nf/actions/workflows/push_main.yml/badge.svg)

Call SARS-CoV-2 lineages using [pangolin](https://github.com/cov-lineages/pangolin) across many sequencing runs. Before each analysis, update pangolin/pangoLEARN to ensure that the latest lineage definitions are used.

This pipeline also incorporates a 'genome completeness threshold' to assist with quality control. The genome completeness is the proportion of the full SARS-CoV-2 genome for which consensus sequence was successfully generated. That statistic is included in the output. In addition, the `genome_completeness_status` field indicates whether the sample was above or below a genome completness threshold. The genome completeness threshold is set to 85% by default but can be set to another value using the `--genome_completeness_threshold` flag.

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


