#!/bin/bash

. env.sh >/dev/null

servers=(primary standby witness)
for server in "${servers[@]}" ; do 
    vagrant ssh $server -c "sudo reboot"
      printf "${R}--- $server rebooted! ---${N}\n"
done