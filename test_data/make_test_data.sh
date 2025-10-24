# download gencode fasta and annotation
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_49/gencode.v49.annotation.gtf.gz
wget https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_49/GRCh38.p14.genome.fa.gz

# extract single chromosomes 
zcat GRCh38.p14.genome.fa.gz | awk -v seq="chr22" -v RS='>' '$1 == seq {print RS $0}' - > chr22.fa
zcat GRCh38.p14.genome.fa.gz | awk -v seq="chrM" -v RS='>' '$1 == seq {print RS $0}' - > chrM.fa
cat chr22.fa chrM.fa > test_human_chrM_22.fa

zcat gencode.v49.annotation.gtf.gz | grep "^chr22" > chr22.gtf
zcat gencode.v49.annotation.gtf.gz | grep "^chrM" > chrM.gtf
cat chr22.gtf chrM.gtf > test_human_chrM_22.gtf
