process prepare_multi_fasta {

  tag { run_id }

  executor 'local'

  input:
  tuple path(analysis_dir), val(artic_analysis_version)

  output:
  tuple val(run_id), path("${run_id}.consensus.fa")

  script:
  run_id = analysis_dir.baseName
  // awk line takes fasta header like this:     >Consensus_R123456.primertrimmed.consensus_threshol_0.75_quality_20
  // ...and converts it to something like this: >R123456
  """
  cat ${analysis_dir}/ncov2019-artic-nf-v${artic_analysis_version}-output/ncovIllumina_sequenceAnalysis_makeConsensus/*.fa \
    | awk -F "_" '/^>/ { split(\$2, a, "."); print ">"a[1] }; !/^>/ { print \$0 }' \
    > ${run_id}.consensus.fa
  """
}

process pangolin {

  tag { run_id }

  input:
  tuple val(run_id), path(consensus_multi_fasta)

  output:
  path("${run_id}_lineage_report.csv")

  script:
  """
  PANGOLIN_VERSION=\$(pangolin -v | cut -d ' ' -f 2)
  pangolin ${consensus_multi_fasta}
  awk -F "," -v pangolin_version="\${PANGOLIN_VERSION}" 'BEGIN { OFS=FS }; /^taxon/ { print "run_id", "sample_id", \$2, \$3, \$4, "pangolin_version", \$5, \$6 }; !/^taxon/ { print "${run_id}", \$1, \$2, \$3, \$4, pangolin_version, \$5, \$6 }' lineage_report.csv > ${run_id}_lineage_report.csv
  """
}
