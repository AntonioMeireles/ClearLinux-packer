ENV['LC_ALL'] = 'en_US.UTF-8'

# Exit early in 2.1.2 due to bug: https://github.com/hashicorp/vagrant/issues/10013
#  https://github.com/hashicorp/vagrant/pull/10030
need_restart = false
unless ['plugin'].include? ARGV[0]
  [
    {
      name: 'vagrant-guests-clearlinux',
      version: '>= 1.0.10'
    }
  ].each do |plugin|
    unless Vagrant.has_plugin?(plugin[:name], plugin[:version])
      system("vagrant plugin install #{plugin[:name]}", chdir: '/tmp') || exit!
      need_restart = true
    end
  end
end

exec "vagrant #{ARGV.join(' ')}" if need_restart

Vagrant.configure(2) do |config|
  name = 'clearlinux'
  config.vm.hostname = name.to_s
  config.vm.define :name.to_s
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.box_check_update = false
  # always use Vagrants insecure key
  config.ssh.insert_key = false
  config.ssh.username = 'clear'

  %w[vmware_workstation vmware_fusion vmware_desktop].each do |vmware_provider|
    config.vm.provider(vmware_provider) do |vmware|
      vmware.whitelist_verified = true
      vmware.gui = false
      (0..7).each do |n|
        vmware.vmx["ethernet#{n}.virtualDev"] = 'vmxnet3'
      end
    end
  end
  config.vm.provider 'virtualbox' do |vbox|
    vbox.gui = false
    vbox.linked_clone = false
    vbox.customize ['modifyvm', :id, '--audio', 'none']
    (1..8).each do |n|
      vbox.customize ['modifyvm', :id, "--nictype#{n}", 'virtio']
    end
  end
end
