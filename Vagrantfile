ENV['LC_ALL'] = 'en_US.UTF-8'

VAGRANTFILE_API_VERSION = '2'.freeze
Vagrant.require_version '>= 2.1.5'

name = 'clearlinux'
required_plugins = {
  'vagrant-guests-clearlinux' => { 'version' => '>= 1.0.13' }
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vagrant.plugins = required_plugins
  config.vm.hostname = name.to_s
  config.vm.define :name.to_s
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.box_check_update = false
  # always use Vagrants' insecure key
  config.ssh.insert_key = false
  config.ssh.username = 'clear'

  %w[vmware_workstation vmware_fusion vmware_desktop].each do |vmware_provider|
    config.vm.provider(vmware_provider) do |vmware|
      vmware.whitelist_verified = true
      vmware.gui = false
      # FIXME: only way to behave past 24950 ...
      vmware.ssh_info_public = true
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
