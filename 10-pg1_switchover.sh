#!/bin/bash

/scripts/check_host.sh pg1 || exit 1

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "${green}Performing switchover\n${normal}"

printf "${red}/usr/edb/efm-5.0/bin/efm promote efm -switchover\n\n${normal}"
sudo su - enterprisedb -c '/usr/edb/efm-5.0/bin/efm promote efm -switchover'
