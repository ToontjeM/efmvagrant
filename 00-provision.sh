#!/bin/bash

. ./env.sh 2>/dev/null

printf "${G}*** Provisioning new VM's ***${N}\n"
vagrant up --provision

printf "${G}Registar servers in PEM? (Y/N)${N}\n"
read answer
if [[ $answer == "Y" ]]; then
    . ./registerPEM.sh
fi