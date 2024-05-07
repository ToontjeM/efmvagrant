#!/bin/bash

. ./env.sh

printf "${G}*** Un-register PEM agents ***${N}\n"
servers=$(vagrant status | grep 'running' | awk '{print $1}')
for server in $servers
do
    printf "${G}*** De-registering $server from PEM ***${N}\n"
    vagrant ssh $server -c "sudo PEM_SERVER_PASSWORD=enterprisedb /usr/edb/pem/agent/bin/pemworker --unregister-server \
    --pem-user enterprisedb \
    --server-addr ${PEMSERVER} \
    --server-port 5444"
    printf "${G}*** De-registering agent from $server ***${N}\n"
    vagrant ssh $server -c "sudo PEM_SERVER_PASSWORD=enterprisedb /usr/edb/pem/agent/bin/pemworker --unregister-agent \
    --pem-user enterprisedb \
    --server-addr ${PEMSERVER} \
    --server-port 5444"
done
