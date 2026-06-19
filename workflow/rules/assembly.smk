rule assembly_conf:
    output:
        "results/assembly.conf"
    run:
        with open(output[0], "w") as fout:
            fout.write("[samples]\n")
            for sample in SAMPLES:
                fout.write(
                    f"{sample}:"
                    f"results/00-qc/fastp/{sample}/\n"
                )

rule spades_assembly:
    input:
        conf="results/assembly.conf",
        files=expand("results/00-qc/fastp/{sample}/{sample}.fastp.json", sample=SAMPLES)
    output:
        expand("results/spades-assemblies/{sample}/{sample}.contigs.fasta", sample=SAMPLES)
    conda:
        config["env"]["phyluce"]
    threads:
        config["threads"]["assembly"]
    params:
        outdir="results/spades-assemblies/",
        memory=config["memory"]["assembly"]
    log:
        "logs/assembly/spades.log"
    shell:
        """
        phyluce_assembly_assemblo_spades \
            --conf {input.conf} \
            --output {params.outdir} \
            --cores {threads} \
            --memory {params.memory} \
            > {log} 2>&1
        """
