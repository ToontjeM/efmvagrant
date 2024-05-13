#!/bin/bash

source ./env.sh

SERVERS=$(vagrant status | grep 'running' | awk '{print $1}')
for SERVER in $SERVERS
do
    vagrant ssh ${SERVER} -c "sudo /vagrant/registerAgent.sh"
    vagrant ssh ${SERVER} -c "sudo /vagrant/registerServer.sh"
done


