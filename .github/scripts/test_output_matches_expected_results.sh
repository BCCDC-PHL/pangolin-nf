#!/bin/bash

set -eo pipefail

export PATH=/opt/miniconda3/bin:$PATH
export PATH=/opt/nextflow/bin:$PATH

nextflow -quiet self-update 2> /dev/null

# write test log as github Action artifact
echo Nextflow run current PR >> artifacts/test_artifact.log
NXF_VER=20.10.0 nextflow -quiet run ./main.nf \
       -profile conda \
       --cache ~/.conda/envs \
       --analysis_parent_dir ${PWD}/.github/data/mock_runs \
       --outdir test_analysis_results

cp .nextflow.log artifacts/
cp -r test_analysis_results artifacts/test_analysis_results

# Compare test results against previously-generated expected results
echo "Compare ouputs of current PR vs expected results.." >> artifacts/test_artifact.log
if ! git diff --stat --no-index test_analysis_results/pangolin_lineages.csv ${PWD}/.github/data/expected_results/pangolin_lineages.csv > diffs.txt ; then
  echo "test failed: differences found between PR and expected results" >> artifacts/test_artifact.log
  echo "see diffs.txt" >> artifacts/test_artifact.log 
  cp diffs.txt artifacts/  
  exit 1
else
  echo "No differences found between PR and expected results" >> artifacts/test_artifact.log
fi

# clean-up for following tests
rm -rf test_analysis_results && rm -rf work && rm -rf .nextflow*
