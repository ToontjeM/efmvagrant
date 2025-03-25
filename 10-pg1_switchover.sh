#!/bin/bash

/scripts/check_host.sh pg1 || exit 1

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}Switching pg1 back to Primary\n${normal}"

printf "${red}/usr/edb/efm-4.10/bin/efm promote efm -switchover\n"
sudo su - enterprisedb -c '/usr/edb/efm-4.10/bin/efm promote efm -switchover'
psql -U enterprisedb -p 5444 -c "SELECT pg_create_physical_replication_slot('slot');" edb