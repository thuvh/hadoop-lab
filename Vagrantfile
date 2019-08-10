# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'ipaddr'
require 'yaml'

configs = YAML.load_file('config.yaml')
puts "Config: #{configs.inspect}\n\n"

root = File.expand_path('~/VirtualBox VMs')
unless File.exist?(root)
  root = File.expand_path('~/vms')
end

node_configs = configs.fetch('node')
node_ip = IPAddr.new(configs.fetch('ip').fetch('node'))
roles = configs.fetch('roles')
prefix = node_configs.fetch('prefix')
domain = node_configs.fetch('domain')

Vagrant.configure("2") do |config|
  roles.each do |role|
    enabled = role.fetch('enabled', false)
    next unless enabled
    count = role.fetch('count')
    hostname_template = role.fetch('hostname_template')
    (1..count).each do |i|
      hostname = hostname_template % i
      if Vagrant.has_plugin?('vagrant-hostmanager')
        config.hostmanager.enabled = true
        config.hostmanager.manage_host = true
        config.hostmanager.manage_guest = true
        config.hostmanager.ignore_private_ip = false
        config.hostmanager.include_offline = true
      end

      config.ssh.insert_key = false
      config.ssh.private_key_path = ["files/id_rsa", "~/.vagrant.d/insecure_private_key"]
      config.vm.provision "file", source: "files/id_rsa.pub", destination: "~/.ssh/authorized_keys"

      config.vm.define hostname do |node|
        node.vm.box = node_configs.fetch('box')
        node.vm.box_url = node_configs.fetch('box_url')
        node.vm.provider "virtualbox" do |v|
          if role.has_key?('cpus')
            v.cpus = role.fetch('cpus')
          else
            v.cpus = node_configs.fetch('cpus')
          end

          if role.has_key?('memory')
            v.memory = role.fetch('memory')
          else
            v.memory = node_configs.fetch('memory')
          end

          v.name = [prefix, hostname].join('-').squeeze('-')
          second_disk_ext = "vmdk"
          second_disk_name = [hostname, "disk02"].join('-')
          second_disk_full_name = [second_disk_name, second_disk_ext].join('.')
          second_disk = File.join(root, v.name, second_disk_full_name)
          unless File.exist?(second_disk)
            v.customize [ "createmedium", "disk", "--filename", second_disk, "--format", second_disk_ext, "--size", 20 * 1024]    
          end
          v.customize [ "storageattach", :id, "--storagectl", "SCSI", "--port", "1", "--device", "0", "--medium", second_disk]
        end
        node.vm.network configs.fetch('net').fetch('network_type'), ip: node_ip.to_s, nic_type: $private_nic_type
        node.vm.hostname = hostname
        if Vagrant.has_plugin?('vagrant-hostmanager')
          node_vm_fqdn = [hostname, domain].join('.')
          node.hostmanager.aliases = %W[#{node_vm_fqdn}]
        end
        node.vm.provision "file", source: "./files/passwordless", destination: "$HOME/passwordless"
        node.vm.provision "file", source: "./files/id_rsa", destination: "$HOME/.ssh/id_rsa"
        node.vm.provision "file", source: "./files/id_rsa.pub", destination: "$HOME/.ssh/id_rsa.pub"
        node.vm.provision "file", source: "./files/99-ipv6-thuvh.conf", destination: "~/"
        node.vm.provision "file", source: "./files/99-swappiness.conf", destination: "~/"
        node.vm.provision "shell", path: "scripts/setup-user-passwordless.sh"
        node.vm.provision "shell", path: "scripts/setup-swappiness.sh"
        node.vm.provision "shell", path: "scripts/setup-ipv6-disabled.sh"
        node_ip = IPAddr.new(node_ip.to_i + 1, Socket::AF_INET)
      end
    end
  end
end
