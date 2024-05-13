#!/bin/bash

. ./env.sh

. ./deregisterPEM.sh

printf "${G}*** De-provisioning old VM's ***${N}\n"
vagrant destroy -f

rm *.log
