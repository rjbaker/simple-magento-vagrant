# -*- mode: ruby -*-
# vi: set ft=ruby :

# To install store sample data
sample_data    = "true"
mage_version   = "1.6.2.0"
sample_version = "1.6.1.0"
domain_name    = "domain-name"

Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/trusty64"

  config.vm.provision :shell, :path => "bootstrap.sh", :args => [sample_data, mage_version, sample_version, domain_name]

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network :forwarded_port, guest: 80, host: 80
  config.vm.synced_folder "assets", "/vagrant/assets", :mount_options => ["dmode=777","fmode=666"]
  config.vm.synced_folder "../code", "/vagrant/code", :mount_options => ["dmode=777","fmode=666"]
  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    vb.name = domain_name
  end

  config.vm.hostname = domain_name+'.local'
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

end
