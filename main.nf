#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { update_pangolin } from './modules/pangolin.nf'
include { update_pangolin_data } from './modules/pangolin.nf'
include { prepare_multi_fasta } from './modules/pangolin.nf'
include { pangolin } from './modules/pangolin.nf'


def getArticSubDirs(Path p) {
  pattern = ~/ncov2019-artic-nf*/
  FileFilter filter = { x -> x.isDirectory() && x.getName() =~ pattern }
  articSubDirs = p.toFile().listFiles(filter)

  return articSubDirs
}

def hasArticSubDirs(Path p) {
  articSubDirs = getArticSubDirs(p)

  return (articSubDirs.size() > 0)
}

def latestArticSubdirHasQCFile(Path p) {
  runID = p.toFile().getName()
  articSubDirs = getArticSubDirs(p)
  latestArticSubdir = articSubDirs.last()
  def pattern = ~/[A-Za-z0-9_\-]+\.qc\.csv/
  FileFilter filter = { x -> x.isFile() && x.getName() =~ pattern }
  articQCFiles = latestArticSubdir.listFiles(filter)
  hasQCFile = articQCFiles.size() > 0

  return hasQCFile
}


workflow {

  ch_analysis_dirs = Channel.fromPath("${params.analysis_parent_dir}/*", type: 'dir')

  main:
    update_pangolin(Channel.value(params.update_pangolin))
    update_pangolin_data(Channel.value(params.update_pangolin_data).combine(update_pangolin.out))
    prepare_multi_fasta(ch_analysis_dirs.map{ it -> [it.baseName, it] }.filter{ it -> hasArticSubDirs(it[1]) }.filter{ it -> latestArticSubdirHasQCFile(it[1]) })  // Check that analysis dirs contain artic outputs, exclude those that don't
    pangolin(prepare_multi_fasta.out)
    pangolin.out.map{ it -> it[1] }.collectFile(keepHeader: true, sort: { it.text }, name: "pangolin_lineages.csv", storeDir: "${params.outdir}")
}
