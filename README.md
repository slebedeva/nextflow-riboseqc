# nextflow-riboseqc

A single-file basic nextflow pipeline to perform Ribosome profiling quality control using [RiboseQC R package](https://rdrr.io/github/ohlerlab/RiboseQC/).

## Test data

To obtain test data:

1. Download the original RiboseQC test `test_human_HEK293.bam` file using this [link](https://drive.google.com/uc?export=download&id=11PP5y2QH7si81rbEBJsOB-Lt3l_JowRW) and place it into the `test_data` subdirectory.
2. Run [test_data/make_test_data.sh](test_data/make_test_data.sh) to regenerate the annotation.

## How to run

`nextflow run riboseqc.nf` will run the pipeline on test data. It will generate `results` folder with the results of the analysis.

For debugging, use `nextflow run riboseqc.nf -resume`.