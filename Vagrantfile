# -*- mode: ruby -*-
# vi: set ft=ruby :

# VM
var_box            = "bento/almalinux-9.5"
var_box_version    = "202502.21.0"

Vagrant.configure("2") do |config|

  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  # Box
  config.vm.box = var_box
  config.vm.box_version = var_box_version

  # Share files
  config.vm.synced_folder ".", "/vagrant", type: "rsync"
  config.vm.synced_folder "./scripts", "/scripts", type: "rsync"
  config.vm.synced_folder "./config", "/config", type: "rsync"
  config.vm.synced_folder "#{ENV['HOME']}/tokens", "/tokens", type: "rsync"
  config.vm.provision "shell", path: "scripts/bootstrap_general.sh"
  config.vm.provision :hosts, :sync_hosts => true

  # primary
  config.vm.define "pg1" do |node|
    node.vm.box               = var_box
    node.vm.hostname          = "pg1"
    node.vm.network  "private_network", ip: "192.168.56.11"
    node.vm.provider :virtualbox do |v|
      v.name    = "pg1"
      v.memory  = 2048
      v.cpus    = 2
    end      
    node.vm.provision "shell", path: "scripts/bootstrap_pg1.sh"
  end

  # standby
  config.vm.define "pg2" do |node|
    node.vm.box               = var_box
    node.vm.hostname          = "pg2"
    node.vm.network  "private_network", ip: "192.168.56.12"
    node.vm.provider :virtualbox do |v|
      v.name    = "pg2"
      v.memory  = 2048
      v.cpus    = 2
    end      
    node.vm.provision "shell", path: "scripts/bootstrap_pg2.sh"
  end

  # witness node
  config.vm.define "w1" do |node|
    node.vm.box               = var_box
    node.vm.hostname          = "w1"
    node.vm.network  "private_network", ip: "192.168.56.13"
    node.vm.provider :virtualbox do |v|
      v.name    = "w1"
      v.memory  = 1024
      v.cpus    = 1
    end
    node.vm.provision "shell", path: "scripts/bootstrap_w1.sh"
  end 

end
