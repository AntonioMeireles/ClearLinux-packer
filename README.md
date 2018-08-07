# Intel's [Clear Linux](https://clearlinux.org) guest boxes for [Vagrant](http://www.vagrantup.com/)

> This is *work in progress*, **[feedback](https://github.com/AntonioMeireles/ClearLinux-packer/issues)** is welcome.

## Pre-requisites

- currently supported are the **[VirtualBox](https://www.vagrantup.com/docs/virtualbox/)** and **[VMware](https://www.vagrantup.com/docs/vmware/)** providers.
- You'll need to have installed the (latest) [`vagrant-guests-clearlinux`](https://github.com/AntonioMeireles/vagrant-guests-clearlinux) plugin release:

  ```bash
  vagrant plugin install vagrant-guests-clearlinux
  ```

## TL;DR

In an empty directory:

```bash
vagrant init AntonioMeireles/ClearLinux
vagrant up
```

## Vagrant Cloud

This project Vagrant boxes are hosted on **Vagrant Cloud** at **[AntonioMeireles/Clearlinux](https://app.vagrantup.com/AntonioMeireles/boxes/ClearLinux)**

## What else do you need to know ?

- Both the **VirtualBox** and **VMware** boxes use paravirtualized drivers by default, on networking and i/o, for optimal performance. graphical/desktop performance optimization wasn't a concern at all (sound is disabled, etc) ence the boxes are optimized for headless use. if you happen to have a desktop oriented use case just [bug](https://github.com/AntonioMeireles/ClearLinux-packer/issues) the author.
- If you plan to use nested virtualization (say kvm, etc) then the **VMware** box is your only option, as the VirtualBox hypervisor currently does not support that functionality.

## release schedule

By default these boxes are updated around once a week, unless:
- key functionality, bug fix or whatever, is added either to the guest plugin ([changelog](https://github.com/AntonioMeireles/vagrant-guests-clearlinux/commits/master)) or to the box itself ([changelog](https://github.com/AntonioMeireles/ClearLinux-packer/commits/master)).
- key features are added to ClearLinux upstream (say - refreshed VirtualBox drivers, key bug fixes, etc).