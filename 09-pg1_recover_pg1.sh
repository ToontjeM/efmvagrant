#!/bin/bash

/vagrant_scripts/check_host.sh pg1 || exit 1

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}Recovering old Primary by:\n\n${normal}"
printf "\n${green}1. Remove old database${normal}"
printf "\n${red}rm -rf $\{PGDATA\}/*\n\n${normal}"

sudo su - enterprisedb -c 'rm -rf ${PGDATA}/*'

printf "\n${green}2. Restore database from standby${normal}"
printf "\n${red}pg_basebackup -h pg2 -D $\{PGDATA\} -U replicator -P -R -v -X stream\n${normal}"

sudo su - enterprisedb -c 'pg_basebackup -h pg2 -D ${PGDATA} -U replicator -P -R -v -X stream -C -S pg2'

printf "\n${green}3. Restart pg1 as standby${normal}"
printf "\n${red}sudo systemctl restart edb-as-17\n${normal}"

sudo systemctl restart edb-as-17
sudo systemctl restart edb-efm-4.10

sudo su - enterprisedb -c 'pg_basebackup -h pg2 -D ${PGDATA} -U replicator -P -R -v -X stream -C -S pg2'
sudo su - enterprisedb -c "psql -c \"SELECT * FROM pg_create_physical_replication_slot('pg2');\" edb"