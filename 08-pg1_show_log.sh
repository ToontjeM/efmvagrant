#!/bin/bash

/scripts/check_host.sh pg1 || exit 1

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}Database didn't start to prevent split-brain\n${normal}"
printf "${red}sudo su - enterprisedb -c 'tail -f <latest postgres.log>'${normal}\n\n"

sudo su - enterprisedb -c 'tail -f "$(ls -t ${PGDATA}/log/*.log | head -n 1)"'