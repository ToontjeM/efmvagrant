#!/bin/bash

/vagrant_scripts/check_host.sh pg1 || exit 1

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}Remove old database${normal}"
printf "\n${green}rm -rf $\{PGDATA\}/*\n\n"

sudo su - enterprisedb -c 'rm -rf ${PGDATA}/*'

printf "\n${green}Restore database from standby'${normal}"
printf "\n${green}pg_basebackup -h pg2 -D $\{PGDATA\} -U replicator -P -R\n"

sudo su - enterprisedb -c 'pg_basebackup -h pg2 -D /var/lib/edb/as17/data -U replicator -P -R'

printf "\n${green}Restart pg1 as standby'${normal}"
printf "\n${green}sudo systemctl restart edb-as-17\n"

sudo systemctl restart edb-as-17

