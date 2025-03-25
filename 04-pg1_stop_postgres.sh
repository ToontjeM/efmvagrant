#!/bin/bash

/scripts/check_host.sh pg1 || exit 1

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)
printf "\n${green}Primary database failure!\n${normal}"
printf "${red}sudo su - enterprisedb -c 'pg_ctl stop -D ${PGDATA}'${normal}\n\n"

sudo su - enterprisedb -c 'pg_ctl stop -D ${PGDATA}' edb