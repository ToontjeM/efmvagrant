#!/bin/bash

. /vagrant/env.sh

if [ `hostname` != "standby" ]
then
  printf "${R}*** You must run this from the standby! ***${N}\n"
  exit
fi

if [ `whoami` != "enterprisedb" ]
then
  printf "${R}*** You must execute this as enterprisedb! ***${N}\n"
  exit
fi

psql -c "SELECT * FROM pg_create_physical_replication_slot('replicationslot1');" edb
ps -ef | grep receiver
