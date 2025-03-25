#!/bin/bash

. /config/config.sh

printf "${R}*** Installing EPAS $EDBVERSION on standby ***${N}\n"
dnf -y install edb-as$EDBVERSION-server

printf "${R}*** Starting database ***${N}\n"
usermod -aG wheel enterprisedb
sudo PGSETUP_INITDB_OPTIONS="-E UTF-8" /usr/edb/as$EDBVERSION/bin/edb-as-$EDBVERSION-setup initdb
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $EDBCONFIGDIR/data/postgresql.conf
sudo systemctl start edb-as-$EDBVERSION
sudo su - enterprisedb -c "psql -c \"ALTER ROLE enterprisedb IDENTIFIED BY enterprisedb superuser;\" edb"
usermod -a -G efm enterprisedb
echo "export PATH=/usr/edb/efm-${EFMVERSION}/bin:$PATH" >> $HOME/.bash_profile
echo "export PATH=/usr/edb/efm-${EFMVERSION}/bin:$PATH" >> /home/vagrant/.bash_profile
echo "export LC_ALL='en_US.UTF-8'" >> $HOME/.bash_profile

printf "${R}*** Create replication user ***${N}\n"
sudo su - enterprisedb -c "psql edb <<EOF
create user replicator password 'replicator' replication;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text,bigint,bigint,boolean) TO replicator;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text,bigint,bigint) TO replicator;
GRANT EXECUTE ON FUNCTION pg_read_binary_file(text) TO replicator;
GRANT EXECUTE ON FUNCTION pg_ls_dir(text, boolean, boolean) TO replicator;
GRANT EXECUTE ON function pg_stat_file(text, boolean) TO replicator;
EOF"

sudo systemctl stop edb-as-${EDBVERSION}
cp -R /var/lib/edb/as${EDBVERSION}/data /var/lib/edb/as${EDBVERSION}/data_origin
rm -Rf /var/lib/edb/as${EDBVERSION}/data

sudo su - enterprisedb -c "cat >> ~/.pgpass <<EOF
192.168.56.11:5444:*:replicator:replicator
192.168.56.12:5444:*:replicator:replicator
EOF"

printf "${R}*** Remove database and restore backup from primary ***${N}\n"
sudo su - enterprisedb -c "chmod 600 ~/.pgpass"
sudo su - enterprisedb -c "mkdir -p /tmp/enterprisedb/backup"
sudo su - enterprisedb -c "mkdir -p /tmp/enterprisedb/archive"
sudo su - enterprisedb -c "pg_basebackup -h 192.168.56.11 -p 5444 -U replicator -R -P -X stream -D /var/lib/edb/as${EDBVERSION}/data -C -S slot"

sudo su - enterprisedb -c "cat >> /var/lib/edb/as${EDBVERSION}/data/postgresql.conf <<EOF
#Streaming replication
primary_conninfo = 'application_name=instance2'
primary_slot_name='slot'

EOF"
sudo systemctl restart edb-as-${EDBVERSION}

printf "${R}*** EFM configuration ***${N}\n"
cd /etc/edb/efm-$EFMVERSION
cp efm.properties.in efm.properties
cp efm.nodes.in efm.nodes
chown efm:efm efm.properties
chown efm:efm efm.nodes

#printf "${G}*** Create replication slot ***${N}\n"
#sudo su - enterprisedb -c "psql -c \"SELECT * FROM pg_create_physical_replication_slot('slot2');\" edb"
#sudo su - enterprisedb -c "psql -c 'select * from pg_replication_slots;' edb"

printf "${R}*** Modify default EFM config ***${N}\n"
sed -i "s@db.user=@db.user=efm@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.password.encrypted=@db.password.encrypted=bc3ebd41e84e67787877b16bdfeae3f5@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.port=@db.port=5444@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.database=@db.database=edb@" /etc/edb/efm-${EFMVERSION}/efm.properties

sed -i "s@virtual.ip=@virtual.ip=192.168.56.20@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@virtual.ip.interface=@virtual.ip.interface=eth1@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@virtual.ip.prefix=@virtual.ip.prefix=24@" /etc/edb/efm-${EFMVERSION}/efm.properties

sed -i "s@local.timeout=60@local.timeout=15@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@update.physical.slots.period=@update.physical.slots.period=5@" /etc/edb/efm-${EFMVERSION}/efm.properties

sed -i "s@db.bin=@db.bin=/usr/edb/as${EDBVERSION}/bin@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.data.dir=@db.data.dir=/var/lib/edb/as${EDBVERSION}/data@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.config.dir=@db.config.dir=/var/lib/edb/as${EDBVERSION}/data@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.service.owner=@db.service.owner=enterprisedb@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.service.name=@db.service.name=edb-as-${EDBVERSION}@" /etc/edb/efm-${EFMVERSION}/efm.properties

sed -i "s@user.email=@user.email=dba\@domain.com@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@bind.address=@bind.address=192.168.56.12:7800@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@is.witness=@is.witness=false@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@auto.allow.hosts=false@auto.allow.hosts=true@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@log.dir=@log.dir=/var/log/efm-${EFMVERSION}@" /etc/edb/efm-${EFMVERSION}/efm.properties

cat >> /etc/edb/efm-${EFMVERSION}/efm.nodes <<EOF
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

printf "${R}*** Setting standby signal ***${N}\n"
sudo su - enterprisedb -c "touch /var/lib/edb/as${EDBVERSION}/data/standby.signal"

printf "${R}*** Restart database ***${N}\n"
sudo systemctl enable edb-as-$EDBVERSION
sudo systemctl restart edb-as-$EDBVERSION
sudo systemctl status edb-as-$EDBVERSION

printf "${R}*** Start EDB Enterprise Failover Manager ***${N}\n"
systemctl enable edb-efm-$EFMVERSION
systemctl start edb-efm-$EFMVERSION

printf "${R}*** Status Enterprise Failover Manager ***${N}\n"
/usr/edb/efm-$EFMVERSION/bin/efm cluster-status efm

#logs
ps -ef | grep receiver
cat /var/log/efm-$EFMVERSION/startup-efm.log

