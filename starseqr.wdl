version 1.0

workflow starseqr {

  input {
    File inputBam
    File indexBam
    File reads1
    File reads2
    File chimericjunction
    String outputFileNamePrefix
  }

  parameter_meta {
    inputBam: "STAR BAM aligned to genome"
    indexBam: "Index for STAR Bam file"
    reads1: "fastq1"
    reads2: "fastq2"
    chimericjunction: "chimeric junctions from STAR workflow"
    outputFileNamePrefix: "Prefix for filename"
  }

  call runSeqr {
    input:
    inputBam = inputBam,
    indexBam = indexBam,
    reads1 = reads1,
    reads2 = reads2,
    chimericjunction = chimericjunction,
    outputFileNamePrefix = outputFileNamePrefix
   }

  output {
    File fusionsPredictions     = runSeqr.fusionPredictions
    File fusionDiscarded        = runSeqr.fusionDiscarded
    File fusionFigure           = runSeqr.fusionFigure
  }

  meta {
    author: "Alexander Fortuna"
    email: "alexander.fortuna@oicr.on.ca"
    description: "Workflow that takes the Bam output from STAR and detects RNA-seq fusion events."
    dependencies: [
     {
       name: "star-seqr/0.6.7",
       url: "https://github.com/ExpressionAnalysis/STAR-SEQR"
     }
    ]
  }
}

task runSeqr {
  input {
    File   inputBam
    File   indexBam
    File   reads1
    File   reads2
    File   chimericjunction
    String outputFileNamePrefix
    String modules = "star-seqr/0.6.7 hg38-star-index100/2.7.6a"
    String gencode = "$GENCODE_ROOT/gencode.v31.annotation.gtf"
    String genome = "$HG38_ROOT/hg38_random.fa"
    Int threads = 8
    Int jobMemory = 64
    Int timeout = 72
  }

  parameter_meta {
    inputBam: "STAR bam"
    indexBam: "STAR bam index"
    outputFileNamePrefix: "Prefix for filename"
    chimericjunction: "Chimeric junctions from STAR"
    modules: "modules for running star-seqr"
    threads: "Requested CPU threads"
    jobMemory: "Memory allocated for this job"
    timeout: "Hours before task timeout"
  }

  command <<<
      set -euo pipefail

      starseqr.py \
      -1 ~{reads1} \
      -2 ~{reads2} \
      -sb ~{inputBam} \
      -sj ~{chimericjunction} \
      -m 1 -p ~{outputFileNamePrefix} -t 1 -g ~{gencode} \
      -r ~{genome} -vv

  >>>

  runtime {
    memory:  "~{jobMemory} GB"
    modules: "~{modules}"
    cpu:     "~{threads}"
    timeout: "~{timeout}"
  }

  output {
      File fusionPredictions        = "~{outputFileNamePrefix}.fusions.tsv"
      File fusionDiscarded          = "~{outputFileNamePrefix}.fusions.discarded.tsv"
      File fusionFigure             = "~{outputFileNamePrefix}.fusions.pdf"
  }

  meta {
    output_meta: {
      fusionPredictions: "Fusion output tsv",
      fusionDiscarded:   "Discarded fusion output tsv",
      fusionFigure: "PDF rendering of candidate fusions"
    }
  }
}
