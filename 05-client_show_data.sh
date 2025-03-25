#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}Database continues to be available\n${normal}"
printf "${red}psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'SELECT * FROM test LIMIT 10;' edb${normal}\n\n"
psql -h 192.168.56.20 -U enterprisedb -p 5444 -c "SELECT count(*) FROM test;" edb
psql -h 192.168.56.20 -U enterprisedb -p 5444 -c "SELECT * FROM test LIMIT 10;" edb

printf "${red}psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'SELECT count(*) FROM test;' edb${normal}\n"
psql -h 192.168.56.20 -U enterprisedb -p 5444 -c "SELECT count(*) FROM test;" edb