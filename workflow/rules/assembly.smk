rule assembly_conf:
    output:
        temp("results/01-assembly/{sample}.conf")
    run:
        sample = wildcards.sample
        with open(output[0], "w") as fout:
            fout.write("[samples]\n")
            fout.write(
                f"{sample}:"
                f"results/00-qc/fastp/{sample}/\n"
            )

rule spades_assembly:
    input:
        conf="results/01-assembly/{sample}.conf",
        file="results/00-qc/fastp/{sample}/{sample}.fastp.json"
    output:
        contigs="results/01-assembly/{sample}_spades/contigs.fasta",
        done="results/01-assembly/{sample}_spades/.assembly_ran"
    conda:
        config["env"]["phyluce"]
    threads:
        config["threads"]["assembly"]
    params:
        outdir="results/01-assembly/",
        memory=config["memory"]["assembly"],
        dirsample="results/01-assembly/{sample}_spades"
    log:
        "logs/assembly/{sample}.spades_assembly.log"
    shell:
        """
        if [ -d "{params.dirsample}" ]; then rm -rf {params.dirsample}; fi
        phyluce_assembly_assemblo_spades \
            --conf {input.conf} \
            --output {params.outdir} \
            --cores {threads} \
            --memory {params.memory} \
            > {log} 2>&1
        touch {output.done}
        """

rule assembly_qc:
    input:
        expand("results/01-assembly/{sample}_spades/contigs.fasta", sample=SAMPLES)
    output:
        "results/01-assembly/qc/contig_lengths.csv"
    conda:
        config["env"]["phyluce"]
    params:
        "results/01-assembly/contigs"
    log:
        "logs/assembly/assembly_qc.log"
    shell:
        """
        echo "samples,contigs,total bp,mean length,95 CI length,min length,max length,median legnth,contigs >1kb" > {output}

        for i in $(ls {params}/*); do
        phyluce_assembly_get_fasta_lengths --input $i --csv >> {output} 2>> {log}
        done
        """
