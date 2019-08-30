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
roles = configs.fetch('roles')
prefix = node_configs.fetch('prefix')
domain = node_configs.fetch('domain')
network_type = configs.fetch('net').fetch('network_type')
nic_type = configs.fetch('net').fetch('nic_type')

KEY_ALL = 'all'
KEY_CHILDREN = 'children'
KEY_HOSTS = 'hosts'
KEY_ANSIBLE_HOST = 'ansible_host'
KEY_ANSIBLE_PYTHON_INTERPRETER = 'ansible_python_interpreter'
KEY_ANSIBLE_SSH_PRIVATE_KEY = 'ansible_ssh_private_key_file'

def generate_inventories(configs, dynamic = false)
  inventories = {
    KEY_ALL => {
      KEY_CHILDREN => Hash.new
    }
  }
  node_ip = IPAddr.new(configs.fetch('ip', Hash.new).fetch('node', '192.168.46.100'))
  node_configs = configs.fetch('node')
  roles = configs.fetch('roles')
  prefix = node_configs.fetch('prefix')
  domain = node_configs.fetch('domain')

  roles.each do | role |
    role_name = role.fetch('name')
    _role = {
      KEY_HOSTS => Hash.new
    }
    enabled = role.fetch('enabled', false)
    count = role.fetch('count', 0)
    hostname_template = role.fetch('hostname_template')
    (1..count).each do |i|
      _host = Hash.new
      hostname = hostname_template % i

      python_interpreter = role.fetch(KEY_ANSIBLE_PYTHON_INTERPRETER, node_configs.fetch(KEY_ANSIBLE_PYTHON_INTERPRETER))
      unless python_interpreter.nil?
        _host[KEY_ANSIBLE_PYTHON_INTERPRETER] = python_interpreter
      end

      ssh_private_key = role.fetch(KEY_ANSIBLE_SSH_PRIVATE_KEY, node_configs.fetch(KEY_ANSIBLE_SSH_PRIVATE_KEY))
      unless ssh_private_key.nil?
        _host[KEY_ANSIBLE_SSH_PRIVATE_KEY] = ssh_private_key
      end

      _host[KEY_ANSIBLE_HOST] = node_ip.to_s
      if not dynamic or enabled
        node_ip = IPAddr.new(node_ip.to_i + 1, Socket::AF_INET)
      end

      _role[KEY_HOSTS][hostname] = _host
    end
    inventories[KEY_ALL][KEY_CHILDREN][role_name] = _role
  end

  return inventories
end

inventories = generate_inventories(configs, dynamic=false)
inventory_directory = 'ansible/hosts'
Dir.mkdir(inventory_directory) unless File.exists?(inventory_directory)
File.write(File.join(inventory_directory, 'main.yml'), inventories.to_yaml)

Vagrant.configure("2") do |config|
  roles.each do |role|
    role_name = role.fetch('name')

    enabled = role.fetch('enabled', false)
    next unless enabled
    count = role.fetch('count', 0)
    hostname_template = role.fetch('hostname_template')
    (1..count).each do |i|
      hostname = hostname_template % i
      node_vm_fqdn = [hostname, domain].join('.')
      node_ip = inventories.fetch(KEY_ALL).fetch(KEY_CHILDREN).fetch(role_name).fetch(KEY_HOSTS).fetch(hostname).fetch(KEY_ANSIBLE_HOST)

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

        if network_type == "public_network"
          node.vm.network network_type, ip: node_ip, nic_type: nic_type, bridge: configs.fetch('net').fetch('bridge')
        else
          node.vm.network network_type, ip: node_ip, nic_type: nic_type
        end

        node.vm.hostname = hostname

        if Vagrant.has_plugin?('vagrant-hostmanager')
          node.hostmanager.aliases = %W[#{node_vm_fqdn}]
        end

        node.vm.provision "file", source: "./files/passwordless", destination: "$HOME/passwordless"
        node.vm.provision "file", source: "./files/id_rsa", destination: "$HOME/.ssh/id_rsa"
        node.vm.provision "file", source: "./files/id_rsa.pub", destination: "$HOME/.ssh/id_rsa.pub"
        node.vm.provision "file", source: "./files/99-ipv6-thuvh.conf", destination: "$HOME/"
        node.vm.provision "file", source: "./files/99-swappiness.conf", destination: "$HOME/"
        node.vm.provision "shell", path: "scripts/setup-user-passwordless.sh"
        node.vm.provision "shell", path: "scripts/setup-swappiness.sh"
        node.vm.provision "shell", path: "scripts/setup-ipv6-disabled.sh"
      end
    end
  end
end
