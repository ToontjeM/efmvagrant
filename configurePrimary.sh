#!/bin/bash

. /vagrant/env.sh

if [ `hostname` != "primary" ]
then
  printf "${R}*** You must run this from the primary! ***${N}\n"
  exit
fi

if [ `whoami` != "enterprisedb" ]
then
  printf "${R}*** You must execute this as enterprisedb! ***${N}\n"
  exit
fi

# Begin script
printf "${G}*** Configuring replication ***${N}\n"

printf "${G}*** Create replication user ***${N}\n"
psql postgres <<EOF
create user replicator password 'replicator' replication;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text,bigint,bigint,boolean) TO replicator;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text,bigint,bigint) TO replicator;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text) TO replicator;

EOF

printf "${G}*** Configure streaming replication ***${N}\n"
mkdir -p /tmp/enterprisedb/backup
mkdir -p /tmp/enterprisedb/archive

mkdir -p $EDBCONFIGDIR/data/archivedir
chown enterprisedb:enterprisedb $EDBCONFIGDIR/data/archivedir
chmod 700 $EDBCONFIGDIR/data/archivedir
mkdir -p $EDBCONFIGDIR/data/conf.d
chown enterprisedb:enterprisedb $EDBCONFIGDIR/data/conf.d
chmod 700 $EDBCONFIGDIR/data/conf.d
cat >> /var/lib/edb/as15/data/conf.d/01-replication.conf <<EOF
#Streaming replication
wal_level=replica
archive_mode = on
#archive_command = 'cp -i %p /tmp/enterprisedb/archive/%f'
archive_command = '/bin/true'


max_wal_senders=10
wal_log_hints=on
hot_standby=on
wal_log_hints='on'
wal_keep_size=160
synchronous_commit=on

max_replication_slots=10
wal_compression='on'
unix_socket_directories = '/tmp'
checkpoint_timeout='15min'
checkpoint_completion_target='0.9'
primary_slot_name='replicationslot1'

EOF
printf "${G}*** Configure password-less access ***${N}\n"
cat >> ~/.pgpass <<EOF
192.168.0.210:5444:*:replication:replicator
192.168.0.211:5444:*:replication:replicator
192.168.0.212:5444:*:replication:replicator
EOF
chmod 600 ~/.pgpass

printf "${G}*** Restart EPAS ***${N}\n"
/usr/edb/as15/bin/pg_ctl -D $EDBCONFIGDIR/data stop
sudo systemctl restart edb-as-15

printf "${G}*** Create replication slot ***${N}\n"
psql -c "SELECT * FROM pg_create_physical_replication_slot('replicationslot2');" edb
psql -c 'select * from pg_replication_slots;' edb

ps -ef | grep sender