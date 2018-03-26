ENV['LC_ALL'] = 'en_US.UTF-8'
[
  {
    name: 'vagrant-guests-clearlinux',
    version: '>= 1.0.7'
  }
].each do |plugin|
  unless Vagrant.has_plugin?(plugin[:name],
                             plugin[:version]) || ARGV[0] == 'plugin'
    exec "vagrant plugin install #{plugin}; vagrant #{ARGV.join(' ')}"
  end
end

Vagrant.configure(2) do |config|
  name = 'clearlinux'
  config.vm.hostname = name.to_s
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.box_check_update = false
  # always use Vagrants insecure key
  config.ssh.insert_key = false
  config.ssh.username = 'clear'

  %w[vmware_workstation vmware_fusion vmware_desktop].each do |vmware_provider|
    config.vm.provider(vmware_provider) do |vmware|
      vmware.whitelist_verified = true
      vmware.gui = false
      vmware.vmx['displayName'] = name.to_s
    end
  end
  config.vm.provider 'virtualbox' do |vbox|
    vbox.gui = false
    vbox.name = name.to_s
    vbox.linked_clone = true
  end
end
