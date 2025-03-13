#!/bin/bash

red=$(tput setaf 1)
green=$(tput setaf 2)
normal=$(tput sgr0)

printf "\n${green}Create table test\n\n${normal}"
printf "\n${red}psql -h 192.168.56.20 -U enterprisedb -p 5444 -c 'CREATE TABLE test (id SERIAL PRIMARY KEY, random_text TEXT);' edb${normal}\n\n"

psql -h 192.168.56.20 -U enterprisedb -p 5444 -c "CREATE TABLE test (id SERIAL PRIMARY KEY, random_text TEXT);" edb