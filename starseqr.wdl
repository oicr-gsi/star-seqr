version 1.0

workflow starseqr {

  input {
    File inputBam
    File indexBam
    String outputFileNamePrefix
  }

  parameter_meta {
    inputBam: "STAR BAM aligned to genome"
    indexBam: "Index for STAR Bam file"
    outputFileNamePrefix: "Prefix for filename"
  }

  call runSeqr {
    input:
    inputBam = inputBam,
    indexBam = indexBam,
    outputFileNamePrefix = outputFileNamePrefix,
    structuralVariants = structuralVariants }

  output {
    File fusionsPredictions     = runseqr.fusionPredictions
    File fusionDiscarded        = runseqr.fusionDiscarded
    File fusionFigure           = runseqr.fusionFigure
  }

  meta {
    author: "Alexander Fortuna"
    email: "alexander.fortuna@oicr.on.ca"
    description: "Workflow that takes the Bam output from STAR and detects RNA-seq fusion events."
    dependencies: [
     {
       name: "star-seqr/0.6.7",
       url: "https://github.com/ExpressionAnalysis/STAR-SEQR"
     },
     {
       name: "rstats/3.6",
       url: "https://www.r-project.org/"
     },
     {
       name: "star/2.7.6a",
       url: "https://github.com/alexdobin/STAR"
     }
    ]
  }
}

task runSeqr {
  input {
    File   inputBam
    File   indexBam
    File?  structuralVariants
    String draw = "$seqr_ROOT/bin/draw_fusions.R"
    String modules = "star-seqr/0.6.7 samtools/1.9 hg38-star-index100/2.7.6a"
    String gencode = "$GENCODE_ROOT/gencode.v31.annotation.gtf"
    String genome = "$HG38_ROOT/hg38_random.fa"
    String knownfusions = "$ARRIBA_ROOT/share/database/known_fusions_hg38_GRCh38_v2.0.0.tsv.gz"
    String cytobands = "$ARRIBA_ROOT/share/database/cytobands_hg38_GRCh38_v2.0.0.tsv"
    String domains = "$ARRIBA_ROOT/share/database/protein_domains_hg38_GRCh38_v2.0.0.gff3"
    String blacklist = "$ARRIBA_ROOT/share/database/blacklist_hg38_GRCh38_v2.0.0.tsv.gz"
    String cosmic = "$HG38_COSMIC_FUSION_ROOT/CosmicFusionExport.tsv"
    String outputFileNamePrefix
    Int threads = 8
    Int jobMemory = 64
    Int timeout = 72
  }

  parameter_meta {
    inputBam: "STAR bam"
    indexBam: "STAR bam index"
    structuralVariants: "file containing structural variant calls"
    outputFileNamePrefix: "Prefix for filename"
    draw: "path to arriba draw command"
    modules: "Names and versions of modules to load"
    gencode: "Path to gencode annotation file"
    knownfusions: "database of known fusions"
    domains: "protein domains for annotation"
    cytobands: "cytobands for figure annotation"
    cosmic: "known fusions from cosmic"
    blacklist: "List of fusions which are seen in normal tissue or artefacts"
    genome: "Path to loaded genome"
    threads: "Requested CPU threads"
    jobMemory: "Memory allocated for this job"
    timeout: "Hours before task timeout"
  }

  command <<<
      set -euo pipefail

      starseqr.py \
      -1 /.mounts/labs/gsi/testdata/STAR/2.1/input_data/EPT105_A_R1_001.fastq.gz \
      -2 /.mounts/labs/gsi/testdata/STAR/2.1/input_data/EPT105_A_R1_001.fastq.gz \
      -sb /.mounts/labs/gsi/testdata/arriba/2.0/input_data/EPT105.Aligned.sortedByCoord.out.bam \
      -m 1 -p EPT105 -t 1 -g $GENCODE_ROOT/gencode.v31.annotation.gtf \
      -r $HG38_ROOT/hg38_random.fa -vv

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
