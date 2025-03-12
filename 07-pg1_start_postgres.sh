#!/bin/bash

/vagrant_scripts/check_host.sh pg1 || exit 1

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}sudo su - enterprisedb -c 'pg_ctl start -D ${PGDATA}'${normal}\n\n"

sudo su - enterprisedb -c 'pg_ctl start -D ${PGDATA}' edb