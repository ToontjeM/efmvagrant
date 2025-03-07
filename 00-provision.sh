#!/bin/bash

. ./config/config.sh

printf "${G}*** Provisioning new VM's ***${N}\n"
vagrant up --provision