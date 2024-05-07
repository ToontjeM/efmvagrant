#!/bin/bash

. ./env.sh 2>/dev/null

printf "${G}*** Registering PEM agents ***${N}\n"
# Run 'vagrant status' to get the list of running servers
servers=$(vagrant status | grep 'running' | awk '{print $1}')
for server in $servers
do
    printf "${G}*** Registering agent on $server ***${N}\n"
    vagrant ssh $server -c "sudo PEM_SERVER_PASSWORD=enterprisedb /usr/edb/pem/agent/bin/pemworker --register-agent \
        --pem-server 192.168.0.112 \
        --pem-port 5444 \
        --pem-user enterprisedb"
    printf "${G}*** Registering $server in PEM ***${N}\n"
    vagrant ssh $server -c "sudo PEM_SERVER_PASSWORD=enterprisedb PEM_MONITORED_SERVER_PASSWORD=enterprisedb /usr/edb/pem/agent/bin/pemworker --register-server \
        --pem-user enterprisedb \
        --server-addr 192.168.0.112 \
        --server-port 5444 \
        --server-database edb \
        --server-user enterprisedb \
        --server-service-name edb-as-$EDBVERSION \
        --efm-cluster-name efm \
        --efm-install-path /usr/edb/efm-$EFMVERSION \
        --display-name $server \
        --group Demo \
        --remote-monitoring no"    
done
