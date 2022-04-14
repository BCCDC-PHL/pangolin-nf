#!/usr/bin/env python3

import argparse
import csv
import json
import sys
import os


def parse_artic_qc_csv(artic_qc_csv_path):
    artic_qc = {}
    with open(artic_qc_csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            artic_qc[row['sample_name']] = row

    return artic_qc


def parse_pangolin_lineages_csv(pangolin_lineages_csv_path):
    pangolin_lineages = {}
    with open(pangolin_lineages_csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            pangolin_lineages[row['sample_id']] = row

    return pangolin_lineages


def main(args):
    artic_qc = parse_artic_qc_csv(args.artic_qc)
    pangolin_lineages = parse_pangolin_lineages_csv(args.pangolin_lineages)

    for sample_id in pangolin_lineages:
        genome_completeness = float(artic_qc[sample_id]['pct_covered_bases'])

        genome_completeness_status = 'UNDETERMINED'
        if genome_completeness >= args.genome_completeness_threshold:
            genome_completeness_status = 'ABOVE_GENOME_COMPLETENESS_THRESHOLD'
        else:
            genome_completeness_status = 'BELOW_GENOME_COMPLETENESS_THRESHOLD'

        pangolin_lineages[sample_id]['genome_completeness'] = artic_qc[sample_id]['pct_covered_bases']
        pangolin_lineages[sample_id]['genome_completeness_status'] = genome_completeness_status        

    output_fieldnames = [
        'run_id',
        'sample_id',
        'genome_completeness',
        'genome_completeness_status',
        'lineage',
        'conflict',
        'ambiguity_score',
        'scorpio_call',
        'scorpio_support',
        'scorpio_conflict',
        'scorpio_notes',
        'version',
        'pangolin_version',
        'scorpio_version',
        'constellation_version',
        'pangoLEARN_version',
        'pango_version',
        'is_designated',
        'qc_status',
        'qc_notes',
        'note',
    ]

    writer = csv.DictWriter(sys.stdout, fieldnames=output_fieldnames, lineterminator=os.linesep)

    writer.writeheader()
    for sample_id, row in pangolin_lineages.items():
        writer.writerow(row)


          
if __name__ ==  '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--genome-completeness-threshold', type=float, default=85.0)
    parser.add_argument('--artic-qc')
    parser.add_argument('--pangolin-lineages')
    args = parser.parse_args()
    main(args)
