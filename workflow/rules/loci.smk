rule match_contigs:
    input:
        config["match_contigs"]["probes"],
        expand("results/01-assembly/{sample}_spades/contigs.fasta", sample=SAMPLES)
    output:
        expand("results/03-match_contigs/{sample}.contigs.lastz", sample=SAMPLES),
        "results/03-match_contigs/probe.matches.sqlite"
    conda:
        config["env"]["phyluce"]
    params:
        outdir="results/03-match_contigs",
        indir="results/01-assembly/contigs"
    log:
        "logs/phyluce/match_contigs.log"
    shell:
        """
        if [ -d "{params.outdir}" ]; then rm -rf {params.outdir}; fi
        phyluce_assembly_match_contigs_to_probes \
            --contigs {params.indir} \
            --probes {input[0]} \
            --output {params.outdir} \
            > {log} 2>&1
        """

rule match_counts:
    input:
        db="results/03-match_contigs/probe.matches.sqlite",
        conf=config["match_contigs"]["taxon-set_file"]
    output:
        "results/03-match_contigs/{dataset}.probe.matches.conf"
    conda:
        config["env"]["phyluce"]
    params:
        name=config["match_contigs"]["taxon-set_name"],
        params=config["match_contigs"]["get_match_counts_params"]
    log:
        "logs/phyluce/{dataset}.match_counts.log"
    shell:
        """
        phyluce_assembly_get_match_counts \
            --locus-db {input.db} \
            --taxon-list-config {input.conf} \
            --taxon-group {params.name} \
            {params.params} \
            --output {output} > {log} 2>&1
        """

rule get_fastas:
    input:
        conf="results/03-match_contigs/{dataset}.probe.matches.conf",
        contig=expand("results/01-assembly/{sample}_spades/contigs.fasta", sample=SAMPLES),
        db="results/03-match_contigs/probe.matches.sqlite"
    output:
        fasta=temp("results/04-uce-fastas/{dataset}.probe.matches.fasta"),
        incomp=temp("results/04-uce-fastas/{dataset}.probe.matches.incomplete")
    conda:
        config["env"]["phyluce"]
    params:
        contig="results/01-assembly/contigs"
    log:
        "logs/phyluce/{dataset}.get_fastas.log"
    shell:
        """
        phyluce_assembly_get_fastas_from_match_counts \
            --contigs {params.contig} \
            --locus-db {input.db} \
            --match-count-output {input.conf} \
            --output {output.fasta} \
            --incomplete-matrix {output.incomp} \
            > {log} 2>&1
        """

checkpoint explode_fastas:
    input:
        "results/04-uce-fastas/{dataset}.probe.matches.fasta"
    output:
        directory("results/04-uce-fastas/exploded/{dataset}")
    conda:
        config["env"]["phyluce"]
    params:
        "results/04-uce-fastas/exploded/{dataset}"
    log:
        "logs/phyluce/{dataset}.explode_fastas.log"
    shell:
        """
        if [ -d "{params}" ]; then rm -rf {params}; fi
        phyluce_assembly_explode_get_fastas_file --input {input} --output {params} --by-taxon > {log} 2>&1
        """

rule exploded_fasta_qc:
    input:
        exploded_fastas
    output:
        "results/04-uce-fastas/exploded/{dataset}.contig_lengths.csv"
    conda:
        config["env"]["phyluce"]
    log:
        "logs/phyluce/{dataset}.merge_exploded_fasta_qc.log"
    shell:
        """
        echo "samples,contigs,total bp,mean length,95 CI length,min length,max length,median legnth,contigs >1kb" > {output}

        for i in {input}; do
        phyluce_assembly_get_fasta_lengths --input $i --csv >> {output} 2>> {log}
        done
        """
