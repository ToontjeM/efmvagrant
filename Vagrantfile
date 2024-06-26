# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
vars = YAML.load_file 'vars.yml'

Vagrant.configure("2") do |config|

  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  config.vm.synced_folder ".", "/vagrant"
  config.vm.provision "shell", path: "bootstrap_general.sh"
  config.vm.provision :hosts, :sync_hosts => true

  # primary
  config.vm.define "primary" do |node|
    node.vm.box               = vars['shared']['box']
    node.vm.box_check_update  = false
    node.vm.hostname          = "primary"
    node.vm.network vars['shared']['networktype'] + "_network", ip: vars['shared']['network'] + "1", bridge: "enx24f5a28b44a6"
    node.vm.provider :virtualbox do |v|
      v.name    = "primary"
      v.memory  = vars['pgnode']['mem_size']
      v.cpus    = vars['pgnode']['cpus']
    end      
    node.vm.provision "shell", path: "bootstrap_primary.sh"
  end

  # standby
  config.vm.define "standby" do |node|
    node.vm.box               = vars['shared']['box']
    node.vm.box_check_update  = false
    node.vm.hostname          = "standby"
    node.vm.network vars['shared']['networktype'] + "_network", ip: vars['shared']['network'] + "2", bridge: "enx24f5a28b44a6"
    node.vm.provider :virtualbox do |v|
      v.name    = "standby"
      v.memory  = vars['pgnode']['mem_size']
      v.cpus    = vars['pgnode']['cpus']
    end      
    node.vm.provision "shell", path: "bootstrap_standby.sh"
  end

  # witness node
  config.vm.define "witness" do |node|
    node.vm.box               = vars['shared']['box']
    node.vm.box_check_update  = false
    node.vm.hostname          = "witness"
    node.vm.network vars['shared']['networktype'] + "_network", ip: vars['shared']['network'] + "0", bridge: "enx24f5a28b44a6"
    node.vm.provider :virtualbox do |v|
      v.name    = "witness"
      v.memory  = vars['witness']['mem_size']
      v.cpus    = vars['witness']['cpus']
    end
    node.vm.provision "shell", path: "bootstrap_witness.sh"
  end 

  # Reboot all nodes after provisioning
  config.vm.provision :reload
end