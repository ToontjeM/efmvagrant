#!/bin/bash

/scripts/check_host.sh pg1 || exit 1

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}Recovering old Primary by:\n\n${normal}"

printf "${green}1. Remove old database\n${normal}"
printf "${red}rm -rf $\{PGDATA\}/*\n${normal}"

sudo su - enterprisedb -c 'rm -rf ${PGDATA}/*'

printf "${green}2. Remove replication slot from the Primary ${normal}"
printf "${red}SELECT pg_drop_replication_slot('slotpg1')\n${normal}"
sudo su - enterprisedb -c "psql -U enterprisedb -h pg2 -c \"SELECT pg_drop_replication_slot('slotpg1');\" edb"

printf "\n${green}3. Restore database from standby and recreate replication slot\n${normal}"
printf "${red}pg_basebackup -h pg2 -D $\{PGDATA\} -U replicator -P -R -v -X stream -C -S slotpg1'\n${normal}"

sudo su - enterprisedb -c 'pg_basebackup -h pg2 -D ${PGDATA} -U replicator -P -R -v -X stream -C -S slotpg1'

printf "\n${green}3. Restart pg1 as standby\n${normal}"
printf "${red}sudo systemctl restart edb-as-17\n${normal}"

sudo systemctl restart edb-as-17
sudo su - efm -c '/usr/edb/efm-5.0/bin/efm resume efm'
