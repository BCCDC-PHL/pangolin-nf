process update_pangolin {

  tag { should_update.toString() }
  
  executor 'local'

  input:
  val(should_update)

  output:
  val(did_update)

  script:
  did_update = should_update
  should_update_string = should_update ? "true" : "false"
  """
  should_update=${should_update_string}
  if [ "\$should_update" = true ]
  then
    pangolin --update
  fi
  """
}

process update_pangolin_data {

  tag { should_update.toString() }
  
  executor 'local'

  input:
  val(should_update)

  output:
  val(did_update)

  script:
  did_update = should_update
  should_update_string = should_update ? "true" : "false"
  """
  should_update=${should_update_string}
  if [ "\$should_update" = true ]
  then
    pangolin --update-data
  fi
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
  tuple val(run_id), path("${run_id}.consensus.fa"), path("${run_id}_above_completeness_threshold.csv"), path("${run_id}_below_completeness_threshold.csv")

  script:
  // awk line takes ivar fasta header like this:     >Consensus_R123456.primertrimmed.consensus_threshold_0.75_quality_20
  // ...and converts it to something like this:      >R123456
  // for freebayes consensus, header is unchanged but fasta is converted to single line
  consensus_subdir = params.ivar_consensus ? 'ncovIllumina_sequenceAnalysis_makeConsensus' : 'ncovIllumina_sequenceAnalysis_callConsensusFreebayes'
  awk_string = params.ivar_consensus ? '/^>/ { split($2, a, "."); print ">"a[1] }; !/^>/ { print $0 }' : '/^>/ { print $0 }; !/^>/ { printf "%s", $0 }; END { print ""}'
  """
  export LATEST_ANALYSIS=\$(cat ${latest_artic_analysis_version})
  tail -n+2 ${analysis_dir}/ncov2019-artic-nf-\${LATEST_ANALYSIS}-output/*.qc.csv | grep -iv '^NEG' | awk -F "," 'BEGIN {OFS=FS}; \$2 < (100 - ${genome_completeness_threshold}) {print \$1,(100 - \$2)}' > ${run_id}_above_completeness_threshold.csv
  tail -n+2 ${analysis_dir}/ncov2019-artic-nf-\${LATEST_ANALYSIS}-output/*.qc.csv | grep -iv '^NEG' | awk -F "," 'BEGIN {OFS=FS}; \$2 > (100 - ${genome_completeness_threshold}) {print \$1,(100 - \$2)}' > ${run_id}_below_completeness_threshold.csv
  while IFS="," read -r sample_id percent_n; do
    cat ${analysis_dir}/ncov2019-artic-nf-\${LATEST_ANALYSIS}-output/${consensus_subdir}/\${sample_id}*.fa \
      | awk -F "_" '${awk_string}' \
      >> ${run_id}.consensus.fa;
  done < <(cat ${run_id}_above_completeness_threshold.csv ${run_id}_below_completeness_threshold.csv)
  """
}

process pangolin {

  tag { run_id }

  input:
  tuple val(run_id), path(consensus_multi_fasta), path(above_threshold), val(below_threshold), val(pangolin_updated)

  output:
  tuple val(run_id), path("${run_id}_lineage_report.csv")

  script:
  """
  pangolin ${consensus_multi_fasta}
  awk -F "," 'BEGIN { OFS=FS }; /^taxon/ { print "run_id", \$0 }; !/^taxon/ { print "${run_id}", \$0 }' lineage_report.csv | sed 's/taxon/sample_id/' > ${run_id}_lineage_report.csv
  """
}

process add_records_for_samples_below_completeness_threshold {

  tag { run_id }

  executor 'local'
  
  input:
  tuple val(run_id), path(lineage_report), path(above_threshold), path(below_threshold)

  output:
  tuple val(run_id), path("${run_id}_lineage_report_with_incomplete.csv")

  script:
  """
  touch ${run_id}_lineage_report_below_completeness_threshold.csv
  while IFS=',' read -r sample_id genome_completeness; do
    sed -n s/\$sample_id,/\$sample_id,\$genome_completeness,BELOW_GENOME_COMPLETENESS_THRESHOLD,/p ${lineage_report} >> ${run_id}_lineage_report_below_completeness_threshold.csv
  done < ${below_threshold}

  touch ${run_id}_lineage_report_above_completeness_threshold.csv
  while IFS=',' read -r sample_id genome_completeness; do
    sed -n s/\$sample_id,/\$sample_id,\$genome_completeness,ABOVE_GENOME_COMPLETENESS_THRESHOLD,/p ${lineage_report} >> ${run_id}_lineage_report_above_completeness_threshold.csv
  done < ${above_threshold}

  head -n 1 ${lineage_report} | awk -F ',' 'BEGIN {OFS=FS}; {print \$1,\$2,"genome_completeness","genome_completness_status",\$3,\$4,\$5,\$6,\$7,\$8,\$9,\$10,\$11,\$12,\$13,\$14}' > header.csv

  cat ${run_id}_lineage_report_below_completeness_threshold.csv ${run_id}_lineage_report_above_completeness_threshold.csv | sort -k2,2 > ${run_id}_lineage_report_sorted.csv
  cat header.csv ${run_id}_lineage_report_sorted.csv > ${run_id}_lineage_report_with_incomplete.csv
  """
}