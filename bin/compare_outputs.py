#!/usr/bin/env python

import argparse
import csv
import json
import sys

def parse_output(output_path):
    output = {}
    with open(output_path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            run_id = row['run_id']
            sample_id = row['sample_id']

            if run_id not in output:
                output[run_id] = {}

            output[run_id][sample_id]  = row

    return output


def summarize_lineages(output):
    lineage_summary = {}
    for run, samples in output.items():
        for sample_id, sample in samples.items():
            lineage = sample['lineage']
            if lineage not in lineage_summary:
                lineage_summary[lineage] = 0
            lineage_summary[lineage] += 1

    return lineage_summary


def summarize_output(output):
    summary = {}
    summary['total_runs'] = len(output.keys())
    summary['total_samples'] = sum([len(output[x].keys()) for x in output])
    summary['lineage_counts'] = summarize_lineages(output)

    return summary


def compare_outputs(output_1, output_2):
    comparison = {}
    for run in output_1.keys():
        matches = []
        mismatches = []
        missing = []
        if run in output_1 and run in output_2:
            samples_1 = set(output_1[run].keys())
            samples_2 = set(output_2[run].keys())
            shared_samples = samples_1.intersection(samples_2)
            missing = list(samples_1.symmetric_difference(samples_2))
            for sample in shared_samples:
                output_1_lineage = output_1[run][sample]['lineage']
                output_2_lineage = output_2[run][sample]['lineage']
                sample_lineage_comparison = {sample: { 'output_1_lineage': output_1_lineage,
                                               'output_2_lineage': output_2_lineage}}
                if output_1_lineage == output_2_lineage:
                    matches.append(sample_lineage_comparison)
                else:
                    mismatches.append(sample_lineage_comparison)

        comparison[run] = {}
        comparison[run]['num_matches'] = len(matches)
        comparison[run]['num_mismatches'] = len(mismatches)
        comparison[run]['num_missing'] = len(missing)
        comparison[run]['mismatches'] = mismatches
    

    return comparison


def main(args):
    output_1 = parse_output(args.output_1)
    output_2 = parse_output(args.output_2)

    # print(json.dumps(output_1['200819_M00325_0220_000000000-G677V']['E3320047144-1-X-B04'], indent=2))

    output = {}
    output['output_1_summary'] = summarize_output(output_1)
    output['output_2_summary'] = summarize_output(output_2)
    
    comparison = compare_outputs(output_1, output_2)
    for run in comparison.keys():
        for mismatch in comparison[run]['mismatches']:
            sample_id = mismatch.keys()[0]
            output_1_lineage = mismatch[sample_id]['output_1_lineage']
            output_2_lineage = mismatch[sample_id]['output_2_lineage']
            print('\t'.join([run, sample_id, output_1_lineage, output_2_lineage]))
    
    
    exit(0)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output-1')
    parser.add_argument('--output-2')
    args = parser.parse_args()
    main(args)
