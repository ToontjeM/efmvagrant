#!/bin/bash

. ./env.sh

printf "${G}*** De-provisioning old VM's ***${N}\n"

vagrant destroy -f

printf "${G}*** Provisioning new VM's ***${N}\n"

vagrant up --provision