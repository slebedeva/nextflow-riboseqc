# nextflow-riboseqc

A single-file basic nextflow pipeline to perform Ribosome profiling quality control using [RiboseQC R package](https://rdrr.io/github/ohlerlab/RiboseQC/).

## Test data

To obtain test data:

1. Download the original RiboseQC test `test_human_HEK293.bam` file using this [link](https://drive.google.com/uc?export=download&id=11PP5y2QH7si81rbEBJsOB-Lt3l_JowRW) and place it into the `test_data` subdirectory.
2. Run [test_data/make_test_data.sh](test_data/make_test_data.sh) to regenerate the annotation.

## How to run

`nextflow run . -profile local,docker` will run the pipeline on test data locally (prerequisite: docker rights).

It will generate `results` folder with the results of the analysis.

For debugging, use `nextflow run . -profile local,docker -resume`.

## Run on your data

To run on your data, you need to specify the following parameters:

`input_dir` : directory containing aligned bam files of the riboseq data
`gtf` : unzipped gtf file of your annotation
`fasta` : unzipped genome sequence of your annotation

Optionally, specify output directory with `--outdir` (default: `results`).
```
nextflow run slebedeva/nextflow-riboseqc \
--input_dir $INPUT_DIR \
--gtf $GTF \
--fasta $FASTA
```

