#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}Database continues to be used\n${normal}"
printf "${red}psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'INSERT INTO test (random_text) SELECT md5(random()::text) FROM generate_series(1, 100);' edb${normal}\n\n"

psql -h 192.168.56.20 -U enterprisedb -p 5444 -c "INSERT INTO test (random_text) SELECT md5(random()::text) FROM generate_series(1, 100);" edb