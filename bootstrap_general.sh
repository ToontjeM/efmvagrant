#!/bin/bash

echo "--- Running Bootstrap_general.sh ---"
ufw disable

echo "--- Configuring repo ---"
EDBTOKEN=$(cat /vagrant/.edbtoken)
export DEBIAN_FRONTEND=noninteractive
curl -1sLf "https://downloads.enterprisedb.com/$EDBTOKEN/enterprise/setup.deb.sh" | bash

echo "--- Running updates ---"
apt-get update && apt-get dist-upgrade -y && apt-get autoremove -y

echo "--- Installing dependencies ---"
apt-get install openjdk-21-jdk -y

echo "--- Installing EFM 4.8 on all nodes"
apt-get install edb-efm48 -y