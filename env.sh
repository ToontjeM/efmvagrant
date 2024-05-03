#!/bin/bash
export N=$(tput sgr0)
export R=$(tput setaf 1)
export G=$(tput setaf 2)

export NETWORK=192.168.0.21
export EDBTOKEN=$(cat /vagrant/.edbtoken)
export EDBVERSION=15
export EDBCONFIGDIR=/var/lib/edb/as15
export EFMVERSION=4.8