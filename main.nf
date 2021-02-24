#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { prepare_multi_fasta } from './modules/pangolin.nf'
include { pangolin } from './modules/pangolin.nf'

workflow {

  ch_analysis_dirs = Channel.fromPath("${params.analysis_parent_dir}/*", type: 'dir')
  ch_artic_analysis_version = Channel.value("${params.artic_analysis_version}")

  main:
    prepare_multi_fasta(ch_analysis_dirs.combine(ch_artic_analysis_version))
    pangolin(prepare_multi_fasta.out)
    pangolin.out.collectFile(keepHeader: true, sort: { it.text }, name: "pangolin_lineages.csv", storeDir: "${params.outdir}")
  
}
