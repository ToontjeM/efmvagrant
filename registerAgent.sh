#!/bin/bash

source /vagrant/env.sh

printf "${G}*** Registering agent for ${HOSTNAME} (${SERVERIP}) in PEM ***${N}\n"
/usr/edb/pem/agent/bin/pemworker --register-agent \
    --pem-server ${PEMSERVER} \
    --pem-port 5444 \
    --pem-user ${PEMUSER} \
    --group "EFM demo agents"
sudo systemctl enable pemagent
sudo systemctl start pemagent
