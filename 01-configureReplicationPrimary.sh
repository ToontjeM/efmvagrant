#!/bin/bash

. /vagrant/env.sh

if [ `hostname` != "primary" ]
then
  printf "${R}--- You must run this from the primary! ---${N}\n"
  exit
fi

if [ `whoami` != "enterprisedb" ]
then
  printf "${R}--- You must execute this as enterprisedb! ---${N}\n"
  exit
fi

# Begin script
printf "${G}--- Configuring replication ---${N}\n"

# Create replication user
psql enterprisedb edb <<EOF
create user replication password 'replication' replication;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text,bigint,bigint,boolean) TO replication;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text,bigint,bigint) TO replication;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text) TO replication;
EOF

# Configure host-based authentication
cat >> /var/lib/edb/as15/data/pg_hba.conf <<EOF

#Replication Standby
host    replication     replication      192.168.56.0/24        md5
host    edb             replication      192.168.56.0/24        md5
host    postgres        replication      192.168.56.0/24        md5
EOF

# Configure streaming replication
cat >> /var/lib/edb/as15/data/postgresql.conf <<EOF
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

# Configure password-less access
cat >> ~/.pgpass <<EOF
192.168.56.11:5444:*:replication:replication
192.168.56.12:5444:*:replication:replication
EOF
chmod 600 ~/.pgpass

# Configure replication slot
psql -c "SELECT * FROM pg_create_physical_replication_slot('replicationslot2');"
psql -c "select * from pg_replication_slots;"

