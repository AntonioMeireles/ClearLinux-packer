Vagrant.require_version '>= 2.1.5'

ENV['LC_ALL'] = 'en_US.UTF-8'

# Exit early in 2.1.2 due to bug: https://github.com/hashicorp/vagrant/issues/10013
#  https://github.com/hashicorp/vagrant/pull/10030
need_restart = false
unless ['plugin'].include? ARGV[0]
  [
    {
      name: 'vagrant-guests-clearlinux',
      version: '>= 1.2.2'
    }
  ].each do |plugin|
    next if Vagrant.has_plugin?(plugin[:name], plugin[:version])

    verb = Vagrant.has_plugin?(plugin[:name]) ? 'update' : 'install'
    system("vagrant plugin #{verb} #{plugin[:name]}", chdir: '/tmp') || exit!
    need_restart = true
  end
end

exec "vagrant #{ARGV.join(' ')}" if need_restart

Vagrant.configure(2) do |config|
  headless = ENV['HEADLESS'] || true
  name = 'clearlinux'

  config.vm.hostname = name.to_s
  config.vm.define :name.to_s
  config.vm.synced_folder '.', '/vagrant', disabled: true
  config.vm.box_check_update = false
  # always use Vagrants' insecure key
  config.ssh.insert_key = false
  config.ssh.username = 'clear'
  # no point on todays' networks and only adds extra overhead...
  config.ssh.compression = false

  ['vmware_workstation', 'vmware_fusion', 'vmware_desktop'].each do |vmw|
    config.vm.provider(vmw) do |vmware|
      vmware.whitelist_verified = true
      vmware.gui = !headless

      {
        'mks.enable3d' => 'TRUE',
        'cpuid.coresPerSocket' => '1',
        'memsize' => '2048',
        'numvcpus' => '2'
      }.each { |k, v| vmware.vmx[k.to_s] = v.to_s }

      (0..7).each do |n|
        vmware.vmx["ethernet#{n}.virtualDev"] = 'vmxnet3'
      end
    end
  end
  config.vm.provider 'virtualbox' do |vbox|
    vbox.gui = !headless
    vbox.linked_clone = false

    {
      '--memory' => 2048,
      '--cpus' => 2,
      '--hwvirtex' => 'on',
      '--nestedpaging' => 'on',
      '--largepages' => 'on',
      '--vtxvpid' => 'on',
      '--vtxux' => 'on',
      '--graphicscontroller' => 'vmsvga',
      '--accelerate3d' => 'on',
      '--clipboard' => 'bidirectional',
      '--draganddrop' => 'bidirectional'
    }.each { |k, v| vbox.customize ['modifyvm', :id, k.to_s, v.to_s] }

    (1..8).each do |n|
      vbox.customize ['modifyvm', :id, "--nictype#{n}", 'virtio']
    end
  end
  config.vm.provider 'libvirt' do |libvirt, override|
    # bellow, it is assumed that the remote libvirt host is running not only
    # clearlinux but also is matching our conventions ...
    # If it isn't `LIBVIRT_USERNAME` needs to be set to match users' local
    # environment.
    unless ENV['LIBVIRT_HOST'].nil? || ENV['LIBVIRT_HOST'].empty?
      host = ENV['LIBVIRT_HOST']
      username = if ENV['LIBVIRT_USERNAME'].nil? ||
                    ENV['LIBVIRT_USERNAME'].empty?
                   'clear'
                 else
                   ENV['LIBVIRT_USERNAME']
                 end

      libvirt.host = host
      libvirt.connect_via_ssh = true
      libvirt.username = username
      override.ssh.forward_agent = true
      override.ssh.proxy_command = "ssh -q -W %h:%p -l #{username} -x #{host}"
    end
    # XXX: this is the default location in ClearLinux and Debian
    libvirt.loader = '/usr/share/qemu/OVMF.fd'
    libvirt.driver = 'kvm'
    libvirt.cpu_mode = 'host-passthrough'
    libvirt.nested = true
    libvirt.memory = 2048
    libvirt.cpus = 2
    libvirt.channel target_name: 'org.qemu.guest_agent.0',
                    type: 'unix',
                    target_type: 'virtio'
  end
  if Vagrant.has_plugin?('vagrant-proxyconf')
    config.proxy.http = (ENV['http_proxy'] || ENV['HTTP_PROXY'])
    config.proxy.https = (ENV['https_proxy'] || ENV['HTTPS_PROXY'])
    config.proxy.no_proxy =
      (ENV['no_proxy'] || ENV['NO_PROXY'] || 'localhost,127.0.0.1')
    # since we're masking it by default ...
    config.proxy.enabled = { docker: false }
  end
end
