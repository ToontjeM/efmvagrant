#!/bin/bash

echo "Installing EPAS 15 on standby"
apt-get -y install edb-as15-server

sudo su - enterprisedb /vagrant/configureStandby.sh