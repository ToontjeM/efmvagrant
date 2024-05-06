#!/bin/bash

. /vagrant/env.sh

printf "${R}*** Installing EPAS $EDBVERSION on primary ***${N}\n"
dnf -y install edb-as$EDBVERSION-server

printf "${R}*** Starting database ***${N}\n"
sudo PGSETUP_INITDB_OPTIONS="-E UTF-8" /usr/edb/as$EDBVERSION/bin/edb-as-$EDBVERSION-setup initdb
sudo systemctl start edb-as-$EDBVERSION
sudo su - enterprisedb -c "psql -c \"ALTER ROLE enterprisedb IDENTIFIED BY enterprisedb superuser;\" edb"

printf "${R}*** Configuring EFM $EFMVERSION on primary ***${N}\n"
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
#Replication parameters
host    replication     replicator      192.168.0.210/32        md5
host    replication     replicator      192.168.0.211/32        md5
host    replication     replicator      192.168.0.212/32        md5

host    edb             replicator      192.168.0.210/32        md5
host    edb             replicator      192.168.0.211/32        md5
host    edb             replicator      192.168.0.212/32        md5

host    postgres        replicator      192.168.0.210/32        md5
host    postgres        replicator      192.168.0.211/32        md5
host    postgres        replicator      192.168.0.212/32        md5

local   edb             efm                                    md5
host    edb             efm             192.168.0.210/32       md5
host    edb             efm             192.168.0.211/32       md5
host    edb             efm             192.168.0.212/32       md5
host    edb             efm             192.168.0.220/32       md5

$(cat /var/lib/edb/as15/data/pg_hba.conf)" > /var/lib/edb/as15/data/pg_hba.conf'

sed -i 's/127\.0\.0\.1\/32/0.0.0.0\/0/g' $EDBCONFIGDIR/data/pg_hba.conf

printf "${R}*** Restart database ***${N}\n"
sudo su - enterprisedb -c "/usr/edb/as15/bin/pg_ctl -D /var/lib/edb/as15/data restart"

printf "${R}*** Modify default EFM config ***${N}\n"
sed -i "s@db.user=@db.user=efm@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.password.encrypted=@db.password.encrypted=bc3ebd41e84e67787877b16bdfeae3f5@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.port=@db.port=5444@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.database=@db.database=edb@" /etc/edb/efm-$EFMVERSION/efm.properties

sed -i "s@virtual.ip=@virtual.ip=192.168.0.220@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@virtual.ip.interface=@virtual.ip.interface=eth1@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@virtual.ip.prefix=@virtual.ip.prefix=24@" /etc/edb/efm-$EFMVERSION/efm.properties

sed -i "s@local.timeout=60@local.timeout=15@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.bin=@db.bin=/usr/edb/as15/bin@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.data.dir=@db.data.dir=$EDBCONFIGDIR/data@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.config.dir=@db.config.dir=$EDBCONFIGDIR/data@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@user.email=@user.email=dba\@domain.com@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@bind.address=@bind.address=192.168.0.211:7800@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@is.witness=@is.witness=false@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@auto.allow.hosts=false@auto.allow.hosts=true@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.service.owner=@db.service.owner=enterprisedb@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@db.service.name=@db.service.name=edb-as-15@" /etc/edb/efm-$EFMVERSION/efm.properties
sed -i "s@log.dir=@log.dir=/var/log/efm-$EFMVERSION@" /etc/edb/efm-$EFMVERSION/efm.properties

cat >> /etc/edb/efm-$EFMVERSION/efm.nodes <<EOF
192.168.0.210:7800
192.168.0.211:7800
192.168.0.212:7800
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
sudo su - enterprisedb -c "/usr/edb/as15/bin/pg_ctl -D /var/lib/edb/as15/data stop"
sudo systemctl enable edb-as-$EDBVERSION
sudo systemctl restart edb-as-$EDBVERSION
sudo systemctl status edb-as-$EDBVERSION

printf "${R}*** Start EDB Enterprise Failover Manager ***${N}\n"
systemctl enable edb-efm-$EFMVERSION
systemctl start edb-efm-$EFMVERSION

printf "${R}*** Status Enterprise Failover Manager ***${N}\n"
/usr/edb/efm-$EFMVERSION/bin/efm cluster-status efm

#logs
cat /var/log/efm-$EFMVERSION/startup-efm.log

sudo su - enterprisedb /vagrant/configurePrimary.sh