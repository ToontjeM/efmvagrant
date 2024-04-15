# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
vars = YAML.load_file 'vars.yml'

VAGRANT_BOX = vars['shared']['box']
VAGRANT_BOX_VERSION = vars['shared']['box_version']
CPUS_PG_NODE = vars['pgnode']['cpus']
CPUS_WITNESS_NODE = vars['witness']['cpus']
MEMORY_PG_NODE = vars['pgnode']['mem_size']
MEMORY_WITNESS_NODE = vars['witness']['mem_size']
NETWORK = vars['shared']['network']

Vagrant.configure("2") do |config|

  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  config.vm.synced_folder ".", "/vagrant"
  config.vm.provision "shell", path: "bootstrap_general.sh"
  config.vm.provision :hosts, :sync_hosts => true

  # pg nodes
  (1..2).each do |i|
    config.vm.define "pg#{i}" do |node|
      node.vm.box               = VAGRANT_BOX
      node.vm.box_check_update  = false
      node.vm.box_version       = VAGRANT_BOX_VERSION
      node.vm.hostname          = "pg#{i}.home"
      node.vm.network "private_network", ip: NETWORK + "#{i}", virtualbox__intnet: true
      node.vm.provider :virtualbox do |v|
        v.name    = "pg#{i}"
        v.memory  = MEMORY_PG_NODE
        v.cpus    = CPUS_PG_NODE
      end
      
      node.vm.provision "shell", path: "bootstrap_witness.sh"
    end

  # witness node
  config.vm.define "witness" do |node|
    node.vm.box               = VAGRANT_BOX
    node.vm.box_check_update  = false
    node.vm.box_version       = VAGRANT_BOX_VERSION
    node.vm.hostname          = "witness.home"
    node.vm.network "private_network", ip: NETWORK + "0", virtualbox__intnet: true
    node.vm.provider :virtualbox do |v|
      v.name    = "witness"
      v.memory  = MEMORY_WITNESS_NODE
      v.cpus    = CPUS_WITNESS_NODE
    end
    node.vm.provision "env", { "pgnodeIP" => vars['shared']['network'] + "0" , "NETWORKCIDR" => vars['shared']['networkcidr'] }
    node.vm.provision "shell", path: "bootstrap_pgnode.sh"
  end

  end
end