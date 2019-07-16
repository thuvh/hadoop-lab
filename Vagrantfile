# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'ipaddr'
require 'yaml'

configs = YAML.load_file('config.yaml')
puts "Config: #{configs.inspect}\n\n"

node_configs = configs.fetch('node')
node_ip = IPAddr.new(configs.fetch('ip').fetch('node'))
roles = configs.fetch('roles')

Vagrant.configure("2") do |config|
    roles.each do | role |
        count = role.fetch('count')
        hostname_template = role.fetch('hostname_template')
        (1..count).each do | i |
            hostname = hostname_template % i
            config.vm.define hostname do |node|
                node.vm.box = node_configs.fetch('box')
                node.vm.box_url = node_configs.fetch('box_url')
                node.vm.provider "virtualbox" do |v|
                    v.cpus = node_configs.fetch('cpus')
                    v.memory = node_configs.fetch('memory')
                    v.name = hostname
                end

                node.vm.network configs.fetch('net').fetch('network_type'), ip: IPAddr.new(node_ip.to_i + i - 1, Socket::AF_INET).to_s, nic_type: $private_nic_type
                node.vm.hostname = hostname
                node.vm.provision "file", source: "./files/passwordless", destination: "$HOME/passwordless"
                node.vm.provision "file", source: "./files/id_rsa", destination: "$HOME/.ssh/id_rsa"
                node.vm.provision "file", source: "./files/id_rsa.pub", destination: "$HOME/.ssh/id_rsa.pub"
                node.vm.provision "shell", path: "scripts/setup-user-passwordless.sh"
            end
        end
    end
end
