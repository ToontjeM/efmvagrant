#!/bin/bash

echo "Configuring witness"

. /vagrant/env.sh

dnf -y install edb-as${EDBVERSION}-server-client

# Install java
dnf -y install java

echo "******************************************************************************"
echo "Install EDB Enterprise Failover Manager." `date`
echo "******************************************************************************"
echo "export PATH=/usr/edb/efm-${EFMVERSION}/bin:$PATH" >> $HOME/.bash_profile
echo "export LC_ALL='en_US.UTF-8'" >> $HOME/.bash_profile

#EFM configuration
cd /etc/edb/efm-${EFMVERSION}
cp efm.properties.in efm.properties
cp efm.nodes.in efm.nodes
chown efm:efm efm.properties
chown efm:efm efm.nodes


sed -i "s@db.user=@db.user=efm@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.password.encrypted=@db.password.encrypted=bc3ebd41e84e67787877b16bdfeae3f5@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.port=@db.port=5444@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.database=@db.database=edb@" /etc/edb/efm-${EFMVERSION}/efm.properties

# VIP
sed -i "s@virtual.ip=@virtual.ip=192.168.0.220@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@virtual.ip.interface=@virtual.ip.interface=eth1@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@virtual.ip.prefix=@virtual.ip.prefix=24@" /etc/edb/efm-${EFMVERSION}/efm.properties

sed -i "s@local.timeout=60@local.timeout=15@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.bin=@db.bin=/usr/edb/as${EDBVERSION}/bin@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.data.dir=@db.data.dir=/var/lib/edb/as${EDBVERSION}/data@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.config.dir=@db.config.dir=/var/lib/edb/as${EDBVERSION}/data@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@user.email=@user.email=dba\@domain.com@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@bind.address=@bind.address=192.168.0.210:7800@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@is.witness=@is.witness=true@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@auto.allow.hosts=false@auto.allow.hosts=true@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.service.owner=@db.service.owner=enterprisedb@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@db.service.name=@db.service.name=edb-as-15@" /etc/edb/efm-${EFMVERSION}/efm.properties
sed -i "s@log.dir=@log.dir=/var/log/efm-${EFMVERSION}@" /etc/edb/efm-${EFMVERSION}/efm.properties

cat >> /etc/edb/efm-${EFMVERSION}/efm.nodes <<EOF
192.168.0.211:7800
192.168.0.212:7800
192.168.0.220:7800
EOF

#PATH modification
PATH=$PATH:/usr/edb/efm-${EFMVERSION}/bin
cat >> ~/.bash_profile << EOF
PATH=$PATH:/usr/edb/efm-${EFMVERSION}/bin
export PATH
# Avoid locale messages
export LC_ALL="en_US.UTF-8"
EOF


echo "******************************************************************************"
echo "Start EDB Enterprise Failover Manager." `date`
echo "******************************************************************************"
#Start EFM
systemctl start edb-efm-${EFMVERSION}

echo "******************************************************************************"
echo "Status Enterprise Failover Manager." `date`
echo "******************************************************************************"

cd /etc/edb/efm-${EFMVERSION}
/usr/edb/efm-${EFMVERSION}/bin/efm cluster-status efm

#logs
cat /var/log/efm-${EFMVERSION}/startup-efm.log
