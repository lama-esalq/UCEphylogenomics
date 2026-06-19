# UCE Assembly and PHYLUCE Processing Pipeline

This workflow implements the initial stages of a UCE (Ultraconserved Elements) phylogenomics analysis using Snakemake. The pipeline performs raw read quality assessment, adapter and quality trimming, de novo assembly of cleaned reads, and preparation of assembled contigs for downstream PHYLUCE analyses.

The workflow is designed to be modular, allowing additional PHYLUCE steps such as probe matching, locus extraction, alignment generation, matrix construction, and phylogenetic inference to be incorporated in future releases. **It's a work in progress! So use it with caution and be aware it's not complete.**

## Workflow Overview

The current implementation includes:

1. **Quality Control**

   * Raw sequencing reads are assessed with FastQC.
   * Adapter removal and quality filtering are performed with Fastp.
   * Cleaned reads are evaluated again with FastQC.
   * MultiQC reports are generated to summarize sequencing quality metrics across all samples.

2. **De Novo Assembly**

   * Cleaned reads are assembled independently for each sample using SPAdes through the PHYLUCE framework.
   * Assemblies are stored in a standardized directory structure compatible with downstream PHYLUCE modules.


## Configuration

Pipeline settings are controlled through the `config/config.yaml` file.

Example configuration:

```yaml
samples: 'samples.csv'

threads:
  fastp: 4
  assembly: 6

# memory for assembly is in Gb
memory:
  assembly: 4

params:
  fastp: "--cut_mean_quality 24 --cut_tail --cut_front --trim_poly_g --detect_adapter_for_pe --dont_eval_duplication --length_required 50"

env:
  qc: "../../envs/qc.yml"
  phyluce: "../../envs/phyluce-1.7.3-py36-macOS-conda.yml"
```

Sample metadata are provided in a CSV file:

```csv
sample,r1,r2,layout
Sample1,data/Sample1_R1.fastq.gz,data/Sample1_R2.fastq.gz,PE
Sample2,data/Sample2_R1.fastq.gz,data/Sample2_R2.fastq.gz,PE
```
**OBS:** Not configured to use SE reads as raw inputs. This feature is in progress.

## Conda Environments

Software dependencies are managed using Conda environments specified in the configuration file. Separate environments are used for quality control and PHYLUCE assembly steps, ensuring reproducibility and simplifying software installation. Snakemake can automatically create environments, you'll just need to execute with the `--use-conda` flag.

If preferred, before running the workflow, you can create the required environments with the provided yml files. However, it'll be necessary give an specific name for them and change the config file with these respective names:

```bash
conda env create -f envs/qc.yaml -n qc
conda env create -f envs/phyluce-1.7.3-py36-macOS-conda.yml
```


## Running the Pipeline

Execute the complete workflow with:

```bash
snakemake --use-conda --cores 16
```

To perform a dry run (highly recommended for checking input files and paths):

```bash
snakemake -n
```


## Output Structure

```text
config/
envs/
logs/
results/
├── 00-qc/
│   ├── fastp/
│   ├── fastqc/
│   └── multiqc/
├── spades-assemblies/
│   ├── Sample1_spades/
│   ├── Sample2_spades/
│   └── contigs/
```
