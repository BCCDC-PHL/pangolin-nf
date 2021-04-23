process update_pangolin {
  executor 'local'

  input:
  val(should_update)

  output:
  val(true)

  script:
  """
  pangolin --update
  """
}

process list_all_samples_for_run {
  tag { run_id }

  executor 'local'

  input:
  val(run_id)

  output:
  tuple val(run_id), path(sample_list)

  script
  """
  """
}

process get_latest_artic_analysis_version {

  tag { run_id }

  executor 'local'

  input:
  path(analysis_dir)

  output:
  tuple val(run_id), path("latest_artic_analysis_version")

  script:
  run_id = analysis_dir.baseName
  """
  ls -1 ${run_id} | grep "ncov2019-artic-nf-.*-output" | cut -d '-' -f 4 | tail -n 1 > latest_artic_analysis_version
  """
}

process prepare_multi_fasta {

  tag { run_id }

  executor 'local'

  input:
  tuple val(run_id), path(analysis_dir), path(latest_artic_analysis_version), val(genome_completeness_threshold)

  output:
  tuple val(run_id), path("${run_id}.consensus.fa")

  script:
  // awk line takes fasta header like this:     >Consensus_R123456.primertrimmed.consensus_threshol_0.75_quality_20
  // ...and converts it to something like this: >R123456
  """
  export LATEST_ANALYSIS=\$(cat ${latest_artic_analysis_version})
  tail -n+2 ${analysis_dir}/ncov2019-artic-nf-\${LATEST_ANALYSIS}-output/*.qc.csv | grep -v '^NEG' | grep -v '^POS' | awk -F "," 'BEGIN {OFS=FS}; \$2 < (100 - ${genome_completeness_threshold}) {print \$1,\$2}' > included_samples.csv
  tail -n+2 ${analysis_dir}/ncov2019-artic-nf-\${LATEST_ANALYSIS}-output/*.qc.csv | grep -v '^NEG' | grep -v '^POS' | awk -F "," 'BEGIN {OFS=FS}; \$2 > (100 - ${genome_completeness_threshold}) {print \$1,\$2}' > excluded_samples.csv
  while IFS="," read -r sample_id percent_n; do
    cat ${analysis_dir}/ncov2019-artic-nf-\${LATEST_ANALYSIS}-output/ncovIllumina_sequenceAnalysis_makeConsensus/\${sample_id}*.fa \
      | awk -F "_" '/^>/ { split(\$2, a, "."); print ">"a[1] }; !/^>/ { print \$0 }' \
      >> ${run_id}.consensus.fa;
  done < included_samples.csv
  """
}

process pangolin {

  tag { run_id }

  input:
  tuple val(run_id), path(consensus_multi_fasta), val(pangolin_updated)

  output:
  path("${run_id}_lineage_report.csv")

  script:
  """
  PANGOLIN_VERSION=\$(pangolin -v | cut -d ' ' -f 2)
  pangolin ${consensus_multi_fasta}
  awk -F "," -v pangolin_version="\${PANGOLIN_VERSION}" 'BEGIN { OFS=FS }; /^taxon/ { print "run_id", "sample_id", \$2, \$3, \$4, "pangolin_version", \$5, \$6 }; !/^taxon/ { print "${run_id}", \$1, \$2, \$3, \$4, pangolin_version, \$5, \$6 }' lineage_report.csv > ${run_id}_lineage_report.csv
  """
}
