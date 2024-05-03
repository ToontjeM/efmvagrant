# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
vars = YAML.load_file 'vars.yml'

VAGRANT_BOX = vars['shared']['box']
CPUS_PG_NODE = vars['pgnode']['cpus']
CPUS_WITNESS_NODE = vars['witness']['cpus']
MEMORY_PG_NODE = vars['pgnode']['mem_size']
MEMORY_WITNESS_NODE = vars['witness']['mem_size']
NETWORK = vars['shared']['network']
NETWORKTYPE = vars['shared']['networktype']

Vagrant.configure("2") do |config|

  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  config.vm.synced_folder ".", "/vagrant"
  config.vm.provision "shell", path: "bootstrap_general.sh"
  config.vm.provision :hosts, :sync_hosts => true

  # primary
  config.vm.define "primary" do |node|
    node.vm.box               = VAGRANT_BOX
    node.vm.box_check_update  = false
    node.vm.hostname          = "primary"
    node.vm.network vars['shared']['networktype'] + "_network", ip: vars['shared']['network'] + "1", bridge: "enx24f5a28b44a6"
    node.vm.provider :virtualbox do |v|
      v.name    = "primary"
      v.memory  = MEMORY_PG_NODE
      v.cpus    = CPUS_PG_NODE
    end      
    node.vm.provision "shell", path: "bootstrap_primary.sh"
  end

  # standby
  config.vm.define "standby" do |node|
    node.vm.box               = VAGRANT_BOX
    node.vm.box_check_update  = false
    node.vm.hostname          = "standby"
    node.vm.network vars['shared']['networktype'] + "_network", ip: vars['shared']['network'] + "2", bridge: "enx24f5a28b44a6"
    node.vm.provider :virtualbox do |v|
      v.name    = "standby"
      v.memory  = MEMORY_PG_NODE
      v.cpus    = CPUS_PG_NODE
    end      
    node.vm.provision "shell", path: "bootstrap_standby.sh"
  end

#   # witness node
#   config.vm.define "witness" do |node|
#     node.vm.box               = VAGRANT_BOX
#     node.vm.box_check_update  = false
#     node.vm.hostname          = "witness"
#     node.vm.network vars['shared']['networktype'] + "_network", ip: vars['shared']['network'] + "0", bridge: "enx24f5a28b44a6"
#     node.vm.provider :virtualbox do |v|
#       v.name    = "witness"
#       v.memory  = MEMORY_WITNESS_NODE
#       v.cpus    = CPUS_WITNESS_NODE
#     end
#     node.vm.provision "shell", path: "bootstrap_witness.sh"
#   end 

# Reboot all nodes after provisioning
  config.vm.provision :reload
end