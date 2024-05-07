#!/bin/bash

. ./env.sh 2>/dev/null

printf "${G}*** Provisioning new VM's ***${N}\n"
vagrant up --provision