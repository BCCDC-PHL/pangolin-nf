#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { update_pangolin } from './modules/pangolin.nf'
include { list_all_samples_for_run } from './modules/pangolin.nf'
include { get_latest_artic_analysis_version } from './modules/pangolin.nf'
include { prepare_multi_fasta } from './modules/pangolin.nf'
include { pangolin } from './modules/pangolin.nf'
include { add_records_for_samples_below_completeness_threshold } from './modules/pangolin.nf'

workflow {

  ch_fastq_dirs = Channel.fromPath("${params.fastq_parent_dir}/*", type: 'dir')
  ch_analysis_dirs = Channel.fromPath("${params.analysis_parent_dir}/*", type: 'dir')
  ch_artic_analysis_version = Channel.value("${params.artic_analysis_version}")
  ch_genome_completeness_threshold = Channel.value("${params.genome_completeness_threshold}")

  main:
    update_pangolin(Channel.value(true))
    get_latest_artic_analysis_version(ch_analysis_dirs)
    list_all_samples_for_run(ch_fastq_dirs.map{ it -> [it.baseName, it] })
    prepare_multi_fasta(ch_analysis_dirs.map{ it -> [it.baseName, it] }.join(get_latest_artic_analysis_version.out).combine(ch_genome_completeness_threshold))
    pangolin(prepare_multi_fasta.out.combine(update_pangolin.out))
    pangolin.out.map{ it -> it[1] }.collectFile(keepHeader: true, sort: { it.text }, name: "pangolin_lineages.csv", storeDir: "${params.outdir}")
    add_records_for_samples_below_completeness_threshold(pangolin.out.join(prepare_multi_fasta.out.map{ it -> [it[0], it[2], it[3]] }))
    add_records_for_samples_below_completeness_threshold.out.map{ it -> it[1] }.collectFile(keepHeader: true, sort: { it.text }, name: "pangolin_lineages_with_incomplete.csv", storeDir: "${params.outdir}")
  
}
