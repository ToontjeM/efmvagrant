#!/bin/bash

source /vagrant/env.sh

printf "${G}*** Registering server ${HOSTNAME} (${SERVERIP}) in PEM ***${N}\n"
/usr/edb/pem/agent/bin/pemworker -f --register-server \
    --pem-server ${PEMSERVER} \
    --pem-port 5444 \
    --pem-user ${PEMUSER} \
    --server-addr ${SERVERIP} \
    --server-port 5444 \
    --server-database edb \
    --server-user ${PEMUSER} \
    --server-service-name edb-as-${EDBVERSION} \
    --efm-cluster-name efm \
    --efm-install-path /usr/edb/efm-${EFMVERSION} \
    --display-name ${HOSTNAME} \
    --group "EFM demo servers" \
    --remote-monitoring no

sudo systemctl restart pemagent
