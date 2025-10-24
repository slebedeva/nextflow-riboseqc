#!/usr/bin/env nextflow

/*
 * The following pipeline parameters specify the reference genomes
 * and mapped reads and can be provided as command line options
 * Mapped reads are downloaded from Google drive as described in Riboseqc manual
 * Reference genome and gtf are chr22 and chrM of the hg38 gencode assembly.
 */
params.bam = "$baseDir/test_data/test_human_HEK293.bam"
params.gtf = "$baseDir/test_data/test_human_chrM_22.gtf"
params.fasta = "$baseDir/test_data/test_human_chrM_22.fa"
params.outdir = "results"


workflow {
    reads_ch = channel.fromPath( params.bam, checkIfExists: true )
    twobit_ch = UCSC_FATOTWOBIT(params.fasta)
    rannot_ch = RIBOSEQC_ANNOTATION(params.gtf, twobit_ch, params.fasta)
    RIBOSEQC(reads_ch, rannot_ch, params.fasta)
}

process UCSC_FATOTWOBIT {
    tag "${fasta}"

    // WARN: Version information not provided by tool on CLI. Please update version string below when bumping container versions.
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
    ? 'oras://community.wave.seqera.io/library/ucsc-fatotwobit:482--1d5005b012bd3271'
    : 'community.wave.seqera.io/library/ucsc-fatotwobit:482--f820aabce6f6870e'}"

    input:
        path fasta

    output:
        path "${twobit}"

    script:
    def extension = fasta.toString().tokenize('.')[-1]
    def name = fasta.toString() - ".${extension}"
    twobit = name + ".2bit"
    """
    faToTwoBit $fasta ${twobit}
    """

}

process RIBOSEQC_ANNOTATION {
    tag "$gtf"
    publishDir params.outdir


    // WARN: only works with given version, do not bump up!
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
    ? 'https://depot.galaxyproject.org/singularity/riboseqc:1.1--r36_1'
    : 'quay.io/biocontainers/riboseqc:1.1--r36_1'}"

    input:
    path gtf
    path twobit
    path fasta

    output:
    path '*Rannot'

    script:
    """
    #!/usr/bin/env Rscript

    library('RiboseQC')

    # general annotation

    prepare_annotation_files(annotation_directory="."
                            , twobit_file="${twobit}"
                            , gtf_file="${gtf}" 
                            , genome_seq="${fasta}"
                            )
    """
}

process RIBOSEQC {
    tag "RIBOSEQC on $reads.simpleName"
    publishDir params.outdir

    // WARN: only works with given version, do not bump up!
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
    ? 'https://depot.galaxyproject.org/singularity/riboseqc:1.1--r36_1'
    : 'quay.io/biocontainers/riboseqc:1.1--r36_1'}"

    input:
    path reads
    path Rannot
    path fasta

    output:
    path "*_coverage*bedgraph"
    path "*_for_ORFquant"
    path "*P_sites*"
    path "*_junctions"
    path "*_results_RiboseQC"
    path "*_results_RiboseQC_all"

    script:
    """
    #!/usr/bin/env Rscript

    library("RiboseQC")

    RiboseQC_analysis(annotation_file="${Rannot}"
                    , bam_files="${reads}"
                    , genome_seq="${fasta}"
                    , create_report = FALSE
    )
    """
}

