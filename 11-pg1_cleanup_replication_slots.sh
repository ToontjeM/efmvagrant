#!/bin/bash

/scripts/check_host.sh pg1 || exit 1

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "${green}Cleaning up replication slots\n${normal}"
sudo su - enterprisedb -c "psql -U enterprisedb -h pg2 -c \"SELECT pg_drop_replication_slot('pg1');\" edb"
sudo su - enterprisedb -c "psql -U enterprisedb -h pg2 -c \"SELECT pg_drop_replication_slot('pg2');\" edb"
sudo su - enterprisedb -c "psql -c \"SELECT pg_create_physical_replication_slot('pg2');\" edb"

