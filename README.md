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

> if you happen to be running multiple providers in the same vagrant host just specify which
> one you want to actually consume when invoking `vagrant`...
>
> ```bash
> vagrant up --provider (virtualbox|vmware|libvirt)
> ```

## Going Full Circle - [Vagrant](http://www.vagrantup.com/), and [Packer](https://www.packer.io), natively on top of Clear Linux

on your **Clear Linux** setup _just_ run ...

- setup **libvirt**

  ```bash
  curl https://raw.githubusercontent.com/AntonioMeireles/ClearLinux-packer/master/extras/clearlinux/setup/libvirtd.sh
  chmod +x libvirtd.sh
  ./libvirtd.sh
  ```

- install **Vagrant**

  ```bash
  curl https://raw.githubusercontent.com/AntonioMeireles/ClearLinux-packer/master/extras/clearlinux/setup/vagrant.sh
  chmod +x vagrant.sh
  ./vagrant.sh
  ```

- install **Packer**

  ```bash
  curl https://raw.githubusercontent.com/AntonioMeireles/ClearLinux-packer/master/extras/clearlinux/setup/packer.sh
  chmod +x packer.sh
  ./packer.sh
  ```

... and that's it :-)

## Tips & Tricks

- take a deep look at the *guest* plugin available features and capabilities by reading its
  [documentation](https://github.com/AntonioMeireles/vagrant-guests-clearlinux/blob/master/README.md)
  in order to take maximum advantage of this.

- By default boxes are loaded in _headless_ mode.

  When using **Virtualbox** or **VMware** if you wish to have access to the boot console you can boot them
  in graphical mode by invoking `vagrant` with `HEADLESS=false` set in your environment.
- if you want to consume additional **Vagrant** plugins from your *Vagrantfile* the preferred way to
   do it is along the snippet bellow...

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

- the available **Clear Linux** boxes ship with a default timezone set unlikely to suit everyone,
  as the default is **`Europe/Lisbon`**, since the Author is based in **Porto**, **Portugal**.

  Here's how to programmatically set your own one straight from the `Vagrantfile`:

  ```ruby
  config.vm.provision :set_timezone, timezone: 'Asia/Dili'
  ```

- The boxes expect the UEFI bios to be found on the host filesystem, where libvirt sits, at
  `/usr/share/qemu/OVMF.fd` which is its canonical location on major OSs.

  If you are consuming the boxes over a OS that has `OVMF.fd` placed elsewhere please adapt your
  `Vagrantfile` accordingly:

  ```ruby
  config.vm.provider :libvirt do |libvirt, override|
    libvirt.loader = '/NON_DEFAULT_LOCATION/OVMF.fd'
  end
  ```

## Vagrant Cloud

This project Vagrant boxes are hosted on **Vagrant Cloud** at
**[AntonioMeireles/Clearlinux](https://app.vagrantup.com/AntonioMeireles/boxes/ClearLinux)**

## What else do you need to know?

- the default password of the default user (`clearlinux`) is `V@grant!`
- a ready to use, over Vagrant, native Clear Linux libvirt setup is available inside
  [`extras/libvirt.native`](./extras/libvirt.native/)
- **All** boxes use para-virtualized drivers by default, when possible, for optimal performance.
- Graphical/Desktop performance optimization wasn't originally a primary concern as the Author's
  primary use case was towards headless use.

  Things changed, as the user base increased and spoken, and now desktop focused user cases are
  first class citizens too.

  Inside [`extras/gnome-desktop`](./extras/gnome-desktop/) there is a sample
  [`Vagrantfile`](./extras/gnome-desktop/Vagrantfile) that will fully setup and boot
  **[Gnome Desktop](https://www.gnome.org)** on top of **Clear Linux**.
  > - Over a **VMware** hypervisor just make sure that you are using a *box* post `29520`
  >   - shared clipboard (copy/paste to/from host) works out of the box since `29780`.
  > - Over **VirtualBox** just make sure you are using a *box* post `29610`
  >   - shared clipboard (copy/paste to/from host) works out of the box.

  So, if you happen to have a desktop oriented use case and something isn't still working as you'd
  expect just [tell](https://github.com/AntonioMeireles/ClearLinux-packer/issues)!

## release schedule

By default these boxes are updated around once a week, unless:

- key functionality, bug fix or whatever, is added either to the guest plugin
  ([changelog](https://github.com/AntonioMeireles/vagrant-guests-clearlinux/commits/master)) or to
  the box itself ([changelog](https://github.com/AntonioMeireles/ClearLinux-packer/commits/master)).
- key features are added to ClearLinux upstream (say - refreshed VirtualBox drivers, key bug fixes, etc).
