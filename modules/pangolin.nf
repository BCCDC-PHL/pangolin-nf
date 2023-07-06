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
  tuple val(should_update), val(pangolin_did_update)

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

process prepare_multi_fasta {

  tag { run_id }

  executor 'local'

  input:
  tuple val(run_id), path(analysis_dir)

  output:
  tuple val(run_id), path("${run_id}.consensus.fa"), path("${run_id}.qc.csv")

  script:
  // awk line takes ivar fasta header like this:     >Consensus_R123456.primertrimmed.consensus_threshold_0.75_quality_20
  // ...and converts it to something like this:      >R123456
  // for freebayes consensus, header is unchanged but fasta is converted to single line
  consensus_subdir = params.ivar_consensus ? 'ncovIllumina_sequenceAnalysis_makeConsensus' : 'ncovIllumina_sequenceAnalysis_callConsensusFreebayes'
  awk_string = params.ivar_consensus ? '/^>/ { split($2, a, "."); print ">"a[1] }; !/^>/ { print $0 }' : '/^>/ { print $0 }; !/^>/ { printf "%s", $0 }; END { print ""}'
  """
  export LATEST_ARTIC_ANALYSIS_VERSION=\$(ls -1 ${run_id} | grep "ncov2019-artic-nf-.*-output" | cut -d '-' -f 4 | tail -n 1 | tr -d \$'\\n')
  cp ${analysis_dir}/ncov2019-artic-nf-\${LATEST_ARTIC_ANALYSIS_VERSION}-output/${run_id}.qc.csv .
  tail -n+2 ${run_id}.qc.csv | grep -iv '^NEG' | cut -d ',' -f 1 > ${run_id}_samples.csv
  touch ${run_id}.consensus.fa
  while IFS="," read -r sample_id; do
    cat ${analysis_dir}/ncov2019-artic-nf-\${LATEST_ARTIC_ANALYSIS_VERSION}-output/${consensus_subdir}/\${sample_id}*.fa \
      | awk -F "_" '${awk_string}' \
      >> ${run_id}.consensus.fa;
  done < ${run_id}_samples.csv
  """
}

process pangolin {

  tag { run_id }

  input:
  tuple val(run_id), path(consensus_multi_fasta), path(artic_qc)

  output:
  tuple val(run_id), path("${run_id}_lineage_report_with_genome_completeness.csv")

  script:
  """
  mkdir -p ./tmp

  pangolin \
    --threads ${task.cpus} \
    --tempdir ./tmp \
    --analysis-mode ${params.analysis_mode} \
    ${consensus_multi_fasta}

  awk -F "," 'BEGIN { OFS=FS }; /^taxon/ { print "run_id", \$0 }; !/^taxon/ { print "${run_id}", \$0 }' lineage_report.csv | sed 's/taxon/sample_id/' > ${run_id}_lineage_report_no_completeness_info.csv

  add_genome_completeness.py \
    --genome-completeness-threshold ${params.genome_completeness_threshold} \
    --artic-qc ${artic_qc} \
    --pangolin-lineages ${run_id}_lineage_report_no_completeness_info.csv \
    > ${run_id}_lineage_report_with_genome_completeness.csv
  """
}
