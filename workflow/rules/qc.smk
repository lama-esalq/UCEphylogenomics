rule fastqc_raw:
    input:
        lambda wc: [R1[wc.sample], R2[wc.sample]]
    output:
        "results/00-qc/fastqc/raw/{sample}.fastqc.done"
    log:
        "logs/fastqc/{sample}.fastqc_raw.err"
    conda:
        config["env"]["qc"]
    params:
        dir="results/00-qc/fastqc/raw"
    shell:
        "fastqc --outdir {params.dir} {input} > {output} 2> {log}"

rule fastp:
    input:
        r1=lambda wc: R1[wc.sample],
        r2=lambda wc: R2[wc.sample]
    output:
        r1="results/00-qc/fastp/{sample}/{sample}-READ1.fastq.gz",
        r2="results/00-qc/fastp/{sample}/{sample}-READ2.fastq.gz",
        single="results/00-qc/fastp/{sample}/{sample}-READ-singleton.fastq.gz",
        json="results/00-qc/fastp/{sample}/{sample}.fastp.json",
        html="results/00-qc/fastp/{sample}/{sample}.fastp.html"
    log:
        "logs/fastp/{sample}.err"
    conda:
        config["env"]["qc"]
    threads:
        config["threads"]["fastp"]
    params:
        config["params"]["fastp"]
    shell:
        """
        fastp --in1 {input.r1} --in2 {input.r2} \
            --out1 {output.r1} --out2 {output.r2} --unpaired1 {output.single} --unpaired2 {output.single} \
            {params} --thread {threads} \
            --json {output.json} --html {output.html} 2> {log}
        """

rule fastqc_clean:
    input:
        r1="results/00-qc/fastp/{sample}/{sample}-READ1.fastq.gz",
        r2="results/00-qc/fastp/{sample}/{sample}-READ2.fastq.gz",
        single="results/00-qc/fastp/{sample}/{sample}-READ-singleton.fastq.gz",
    output:
        "results/00-qc/fastqc/cleaned/{sample}.fastqc.done"
    log:
        "logs/fastqc/{sample}.fastqc_clean.err"
    conda:
        config["env"]["qc"]
    params:
        dir="results/00-qc/fastqc/cleaned"
    shell:
        "fastqc --outdir {params.dir} {input} > {output} 2> {log}"

rule multiqc:
    input:
        expand("results/00-qc/fastp/{sample}/{sample}.fastp.json", sample=SAMPLES),
        expand("results/00-qc/fastqc/cleaned/{sample}.fastqc.done", sample=SAMPLES),
        expand("results/00-qc/fastqc/raw/{sample}.fastqc.done", sample=SAMPLES)
    output:
        "results/00-qc/multiqc/multiqc_report.html"
    log:
        "logs/multiqc/multiqc.err"
    conda:
        config["env"]["qc"]
    params:
        outdir="results/00-qc/multiqc",
        indir="results/00-qc"
    shell:
        "multiqc {params.indir} -f -z --outdir {params.outdir} 2> {log}"
