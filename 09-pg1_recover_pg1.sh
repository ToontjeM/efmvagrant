#!/bin/bash

/scripts/check_host.sh pg1 || exit 1

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}Recovering old Primary by:\n\n${normal}"
printf "${green}1. Remove old database\n${normal}"
printf "${red}rm -rf $\{PGDATA\}/*\n${normal}"

sudo su - enterprisedb -c 'rm -rf ${PGDATA}/*'

printf "\n${green}2. Restore database from standby\n${normal}"
printf "${red}pg_basebackup -h pg2 -D $\{PGDATA\} -U replicator -P -R -v -X stream -C -S slot'\n${normal}"

sudo su - enterprisedb -c 'pg_basebackup -h pg2 -D ${PGDATA} -U replicator -P -R -v -X stream -C -S slot'

printf "\n${green}3. Restart pg1 as standby\n${normal}"
printf "${red}sudo systemctl restart edb-as-17\n${normal}"

sudo systemctl restart edb-as-17
sudo systemctl restart edb-efm-4.10
