#!/bin/bash

set -eo pipefail

export PATH=/opt/miniconda3/bin:$PATH
export PATH=/opt/nextflow/bin:$PATH

# write test log as github Action artifact
echo Nextflow run current PR >> artifacts/test_artifact.log
NXF_VER=20.10.0 nextflow -quiet run ./main.nf \
       -profile conda \
       --cache ~/.conda/envs \
       --analysis_parent_dir $PWD/.github/data/mock_runs \
       --outdir results

cp .nextflow.log artifacts/
cp -r results artifacts/pull_request_results

# run tests against previous previous_release to compare outputs 
git clone https://github.com/BCCDC-PHL/pangolin-nf.git previous_release 
cd previous_release
git checkout -b previous-release bdb233155b5589dd146c7e1dbb1d2a8cb338f3f3


echo Nextflow run previous release >> ../artifacts/test_artifact.log
NXF_VER=20.10.0 nextflow -quiet run ./main.nf \
       -profile conda \
       --cache ~/.conda/envs \
       --analysis_parent_dir $PWD/../.github/data/mock_runs \
       --outdir results

cp .nextflow.log ../artifacts/previous_release.nextflow.log
cp -r results ../artifacts/previous_release_results

cd ..

# exclude files from comparison
# and list differences
# None of these are actually expected to be present for this pipeline.
# Leaving this logic here for now in case we do want to exclude some files.
echo "Compare ouputs of current PR vs those of previous release.." >> artifacts/test_artifact.log
find results ./previous_release/results \
     -name "*.fq.gz" \
     -o -name "*.bam" \
     -o -name "*.bam.bai" \
     -o -name "*.vcf" \
    | xargs rm -rf
if ! git diff --stat --no-index results ./previous_release/results > diffs.txt ; then
  echo "test failed: differences found between PR and previous release" >> artifacts/test_artifact.log
  echo "see diffs.txt" >> artifacts/test_artifact.log 
  cp diffs.txt artifacts/  
  exit 1
else
  echo "no differences found between PR and previous release" >> artifacts/test_artifact.log
fi

# clean-up for following tests
rm -rf previous_release && rm -rf results && rm -rf work && rm -rf .nextflow*
