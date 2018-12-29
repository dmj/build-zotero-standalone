# -*- mode: ruby -*-
Vagrant.configure("2") do |config|
  config.vm.box = "generic/debian9"
  config.vm.box_check_update = false
  config.vm.synced_folder "guest", "/host"
  config.vm.provision "ansible" do |ansible|
    ansible.raw_arguments = ["--connection=paramiko"]
    ansible.playbook = "ansible/playbook.yml"
  end
end
