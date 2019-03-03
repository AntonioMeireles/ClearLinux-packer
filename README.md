# Intel's [Clear Linux](https://clearlinux.org) _guest_ boxes for [Vagrant](http://www.vagrantup.com/)

> This is *work in progress*, your
> **[feedback](https://github.com/AntonioMeireles/ClearLinux-packer/issues)**
> is welcome.

## Pre-requisites

These boxes require the most recent
[`vagrant-guests-clearlinux`](https://github.com/AntonioMeireles/vagrant-guests-clearlinux) plugin release, which *a priori* will be installed automatically when you use them

You can also manually install the [`vagrant-guests-clearlinux`](https://github.com/AntonioMeireles/vagrant-guests-clearlinux) plugin by...

```bash
vagrant plugin install vagrant-guests-clearlinux
```

## TL;DR

> currently supported are the **[VirtualBox](https://www.vagrantup.com/docs/virtualbox/)**,
> **[VMware](https://www.vagrantup.com/docs/vmware/)** and, up from **26510**,
> **[libvirt](https://github.com/vagrant-libvirt/vagrant-libvirt)** providers.

In an empty directory:

```bash
vagrant init AntonioMeireles/ClearLinux
vagrant up
```

> if you happen to be running multiple providers in same box just specify which
> one you want to actually use when invoking `vagrant`...
> ```bash
> vagrant up --provider (virtualbox|vmware|libvirt)
> ```

## Tips & Tricks

- By default boxes are loaded in _headless_ mode.

  When using Virtualbox or VMware if you wish to have access to the boot console you can boot them
  in graphical mode by invoking `vagrant` with `HEADLESS=false` set in your environment.
- if you want to consume additional Vagrant plugins from your *Vagrantfile* the prefered way to do it
  is along the snippet bellow...

  ```ruby
  additional_plugins = {
    'vagrant-compose' => {
      'version' => '>= 0.7.5'
    },
    'vagrant-reload' => {
      'version' => '>= 0.0.1'
    }
  }

  Vagrant.configure(2) do |config|
    config.vagrant.plugins = additional_plugins

  ...
  ```

## Vagrant Cloud

This project Vagrant boxes are hosted on **Vagrant Cloud** at
**[AntonioMeireles/Clearlinux](https://app.vagrantup.com/AntonioMeireles/boxes/ClearLinux)**

## What else do you need to know ?

- **All** boxes use para-virtualized drivers by default, when possible, for optimal performance.
- Graphical/Desktop performance optimization wasn't a concern at all (sound is disabled, etc) as the
  boxes are optimized for headless use. If you happen to have a desktop oriented use case just
  [bug](https://github.com/AntonioMeireles/ClearLinux-packer/issues) the author.

## release schedule

By default these boxes are updated around once a week, unless:

- key functionality, bug fix or whatever, is added either to the guest plugin
  ([changelog](https://github.com/AntonioMeireles/vagrant-guests-clearlinux/commits/master)) or to
  the box itself ([changelog](https://github.com/AntonioMeireles/ClearLinux-packer/commits/master)).
- key features are added to ClearLinux upstream (say - refreshed VirtualBox drivers, key bug fixes, etc).
