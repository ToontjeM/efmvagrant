#!/bin/bash

. /config/config.sh

printf "${R}*** Running Bootstrap_general.sh ***${N}\n"
systemctl stop firewalld.service
systemctl disable firewalld.service
sed -i 's/%wheel/#%wheel/g' /etc/sudoers
sed -i 's/# #%wheel/%wheel/g' /etc/sudoers


printf "${R}*** Configuring repo with token ${EDB_SUBSCRIPTION_TOKEN} ***${N}\n"
curl -1sLf "https://downloads.enterprisedb.com/${EDB_SUBSCRIPTION_TOKEN}/enterprise/setup.rpm.sh" | sudo -E bash

printf "${R}*** Running updates ***${N}\n"
dnf update && dnf -y upgrade

printf "${R}*** Installing dependencies ***${N}\n"
dnf -y install java-21-openjdk

printf "${R}*** Installing EFM 4.10 on all nodes ***${N}\n"
dnf -y install edb-efm410
