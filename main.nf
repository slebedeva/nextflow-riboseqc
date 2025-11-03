#!/usr/bin/env nextflow

/*
 * The following pipeline parameters specify the reference genomes
 * and mapped reads and can be provided as command line options
 * Input is the directory where bam files are located and pipeline will take all bam files in that directory
 * Mapped reads for test data are downloaded from Google drive as described in Riboseqc manual
 * Reference genome and gtf are chr22 and chrM of the hg38 gencode assembly.
 */
params.input_dir = "$baseDir/test_data"
params.gtf = "$baseDir/test_data/test_human_chrM_22.gtf"
params.fasta = "$baseDir/test_data/test_human_chrM_22.fa"
params.rmd_template = "$baseDir/riboseqc_template.Rmd"
params.outdir = "results"


workflow {
    reads_ch = channel.fromPath( "${params.input_dir}/*.bam", checkIfExists: true )
    twobit_ch = UCSC_FATOTWOBIT(params.fasta)
    rannot_ch = RIBOSEQC_ANNOTATION(params.gtf, twobit_ch, params.fasta)
    RIBOSEQC(reads_ch, rannot_ch, params.fasta)
    RIBOSEQC_REPORT(RIBOSEQC.out.riboseqc_results.collect(), params.rmd_template)
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
    path "*_results_RiboseQC", emit: riboseqc_results
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

process RIBOSEQC_REPORT{

    publishDir params.outdir

    // WARN: only works with given version, do not bump up!
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
    ? 'https://depot.galaxyproject.org/singularity/riboseqc:1.1--r36_1'
    : 'quay.io/biocontainers/riboseqc:1.1--r36_1'}"

    containerOptions { "-v /usr/share/fonts:/usr/share/fonts:ro" }

    input:
    path riboseqc_results
    path rmd_template

    output:
    path "RiboseQC_report.html"

    script:
    """
    #!/usr/bin/env Rscript

    library('RiboseQC')

    input_files = "${riboseqc_results}" %>% stringr::str_split(" ") %>% unlist()
    sample_names <- input_files %>% sub(".bam_results_RiboseQC","",.)
    output_file="RiboseQC_report.html"

    # This function is broken:
    #create_html_report(input_files=inpt_files, input_sample_names=smaple_names, output_file=output_file, extended=FALSE)

    # Instead, run parts of the create_html_report function by hand
    input_files <- paste(normalizePath(dirname(input_files)), 
            basename(input_files), sep = "/")
    output_file <- paste(normalizePath(dirname(output_file)), 
            basename(output_file), sep = "/")
    # change rmd path to local template (reason: render params not declared in YAML: intermediates_dir)
    #original was: rmd_path <- paste(system.file(package = "RiboseQC", mustWork = TRUE), "/rmd/riboseqc_template.Rmd", sep = "")
    rmd_path <- "${rmd_template}"
    output_fig_path <- paste(output_file, "_plots/", sep = "")
    dir.create(paste0(output_fig_path, "rds/"), recursive = TRUE, showWarnings = FALSE)
    dir.create(paste0(output_fig_path, "pdf/"), recursive = TRUE, showWarnings = FALSE)
    
    knitclean <- knitr::knit_meta(class = NULL, clean = TRUE)
    # give intermediates_dir here
    int_dir = 'knitr_tmp'
    if(! dir.exists(int_dir)){ dir.create(int_dir) }
    render(rmd_path, params = list(input_files = input_files, 
            input_sample_names = sample_names,
            output_fig_path = output_fig_path,
            intermediates_dir=int_dir), 
            output_file = output_file)

    """
}
