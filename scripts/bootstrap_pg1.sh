#!/bin/bash

. /config/config.sh

printf "${R}*** Installing EPAS $EDBVERSION on pg1 ***${N}\n"
dnf -y install edb-as$EDBVERSION-server

printf "${R}*** Starting database ***${N}\n"
sudo PGSETUP_INITDB_OPTIONS="-E UTF-8" /usr/edb/as$EDBVERSION/bin/edb-as-$EDBVERSION-setup initdb
# Configure PostgreSQL for remote access
echo "Configuring PostgreSQL..."
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $EDBCONFIGDIR/data/postgresql.conf
sudo su - enterprisedb -c "cat >> /var/lib/edb/as${EDBVERSION}/data/postgresql.conf <<EOF
# Streaming replication
primary_conninfo = 'application_name=instance1'
primary_slot_name='slot_pg1'
EOF"
sudo systemctl start edb-as-$EDBVERSION
sudo su - enterprisedb -c "psql -c \"ALTER ROLE enterprisedb IDENTIFIED BY enterprisedb superuser;\" edb"

printf "${R}*** Configuring EFM $EFMVERSION on  ***${N}\n"
printf "${R}*** Add enterprisedb to EFM group ***${N}\n"
usermod -a -G efm enterprisedb
usermod -aG wheel enterprisedb
echo "export PATH=/usr/edb/efm-$EFMVERSION/bin:$PATH" >> $HOME/.bash_profile
echo "export PATH=/usr/edb/efm-$EFMVERSION/bin:$PATH" >> /home/vagrant/.bash_profile
echo "export LC_ALL='en_US.UTF-8'" >> $HOME/.bash_profile

printf "${R}*** Setting default EFM configuration ***${N}\n"
cd /etc/edb/efm-$EFMVERSION
cp efm.properties.in efm.properties
cp efm.nodes.in efm.nodes
chown efm:efm efm.properties
chown efm:efm efm.nodes

printf "${R}*** Create EFM database user ***${N}\n"
sudo su - enterprisedb -c "psql -c \"create user efm login password 'efm' superuser;\" edb"

printf "${R}*** Configuring pg_hba.conf ***${N}\n"
sudo su - enterprisedb -c 'echo "
# Replication parameters
local   all             all                                 trust
host    replication     replicator      0.0.0.0/0      trust
host    all             all             0.0.0.0/0      trust

$(cat /var/lib/edb/as17/data/pg_hba.conf)" > /var/lib/edb/as17/data/pg_hba.conf'

sed -i 's/127\.0\.0\.1\/32/0.0.0.0\/0/g' $EDBCONFIGDIR/data/pg_hba.conf

printf "${R}*** Restart database ***${N}\n"
sudo su - enterprisedb -c "/usr/edb/as17/bin/pg_ctl -D /var/lib/edb/as17/data restart"

printf "${G}*** Create replication user ***${N}\n"
sudo su - enterprisedb -c "psql edb <<EOF
create user replicator password 'replicator' replication;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text,bigint,bigint,boolean) TO replicator;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text,bigint,bigint) TO replicator;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text) TO replicator;
EOF"
printf "${G}*** Configure streaming replication ***${N}\n"
mkdir -p /tmp/enterprisedb/backup
mkdir -p /tmp/enterprisedb/archive

mkdir -p $EDBCONFIGDIR/data/archivedir
chown enterprisedb:enterprisedb $EDBCONFIGDIR/data/archivedir
chmod 700 $EDBCONFIGDIR/data/archivedir

sed -i "s/#wal_level = .*/wal_level = 'replica'/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#archive_mode = .*/archive_mode = on/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#archive_command = .*/archive_command = '\/bin\/true'/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#max_wal_senders = .*/max_wal_senders = 10/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#wal_log_hints = .*/wal_log_hints = on/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#hot_standby = .*/hot_standby = on/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#wal_keep_size = .*/wal_keep_size = 160/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#synchronous_commit = .*/synchronous_commit = on/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#max_replication_slots = .*/max_replication_slots = 10/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#wal_compression = .*/wal_compression = on/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#unix_socket_directories = .*/unix_socket_directories = '\/tmp'/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#checkpoint_timeout = .*/checkpoint_timeout = '15min'/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#checkpoint_completion_target = .*/checkpoint_completion_target = 0.9/g" /var/lib/edb/as17/data/postgresql.conf
sed -i "s/#primary_slot_name = .*/primary_slot_name = 'slot_pg1'/g" /var/lib/edb/as17/data/postgresql.conf

printf "${G}*** Configure password-less access ***${N}\n"
cat >> ~/.pgpass <<EOF
192.168.56.11:5444:*:replication:replicator
192.168.56.12:5444:*:replication:replicator
192.168.56.13:5444:*:replication:replicator
EOF
chmod 600 ~/.pgpass

printf "${R}*** Modify default EFM config ***${N}\n"
sed -i "s@db.user=@db.user=efm@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.password.encrypted=@db.password.encrypted=bc3ebd41e84e67787877b16bdfeae3f5@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.port=@db.port=5444@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.database=@db.database=edb@" /etc/edb/efm-$EFMVERSION/efm.properties

sed -i "s@virtual.ip=@virtual.ip=192.168.56.20@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@virtual.ip.interface=@virtual.ip.interface=eth1@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@virtual.ip.prefix=@virtual.ip.prefix=24@" /etc/edb/efm-$EFMVERSION/efm.properties

sed -i "s@local.timeout=60@local.timeout=15@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.bin=@db.bin=/usr/edb/as17/bin@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.data.dir=@db.data.dir=$EDBCONFIGDIR/data@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.config.dir=@db.config.dir=$EDBCONFIGDIR/data@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@user.email=@user.email=dba\@domain.com@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@bind.address=@bind.address=192.168.56.11:7800@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@is.witness=@is.witness=false@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@auto.allow.hosts=false@auto.allow.hosts=true@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.service.owner=@db.service.owner=enterprisedb@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.service.name=@db.service.name=edb-as-17@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@log.dir=@log.dir=/var/log/efm-${EFMVERSION}@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@update.physical.slots.period=0@update.physical.slots.period=5@" /etc/edb/efm-${EFMVERSION}/efm.properties

cat >> /etc/edb/efm-$EFMVERSION/efm.nodes <<EOF
192.168.56.11:7800
192.168.56.12:7800
192.168.56.13:7800
EOF

printf "${R}*** Setting path for EFM and Enterprisedb users ***${N}\n"
PATH=$PATH:/usr/edb/efm-$EFMVERSION/bin::/usr/edb/as$EDBVERSION/bin
cat >> ~/.bashrc << EOF
export PATH=$PATH:/usr/edb/efm-$EFMVERSION/bin:/usr/edb/as$EDBVERSION/bin
EOF

cat >> /var/lib/edb/.bash_profile << EOF
export PATH=\$PATH:/usr/edb/efm-$EFMVERSION/bin:/usr/edb/as$EDBVERSION/bin
EOF

printf "${R}*** Restart database ***${N}\n"
sudo su - enterprisedb -c "/usr/edb/as17/bin/pg_ctl -D /var/lib/edb/as17/data stop"
sudo systemctl enable edb-as-$EDBVERSION
sudo systemctl restart edb-as-$EDBVERSION
sudo systemctl status edb-as-$EDBVERSION

printf "${G}*** Create replication slot ***${N}\n"
sudo su - enterprisedb -c "psql -c \"SELECT * FROM pg_create_physical_replication_slot('slot_pg1');\" edb"
sudo su - enterprisedb -c "psql -c 'select * from pg_replication_slots;' edb"

ps -ef | grep sender

printf "${R}*** Start EDB Enterprise Failover Manager ***${N}\n"
systemctl enable edb-efm-$EFMVERSION
systemctl start edb-efm-$EFMVERSION

printf "${R}*** Status Enterprise Failover Manager ***${N}\n"
/usr/edb/efm-$EFMVERSION/bin/efm cluster-status efm

#logs
cat /var/log/efm-$EFMVERSION/startup-efm.log


