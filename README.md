# [Clear Linux](https://clearlinux.org) guest boxes for [Vagrant](http://www.vagrantup.com/)

#### This is work in progress, [feedback](https://github.com/AntonioMeireles/ClearLinux-packer/issues) is welcome.

## Pre-requisites

- You'll need to have installed the (latest) [`vagrant-guests-clearlinux`](https://github.com/AntonioMeireles/vagrant-guests-clearlinux) plugin release:

  ```bash
  vagrant plugin install vagrant-guests-clearlinux
  ```

- currently supported are the [VirtualBox](https://www.vagrantup.com/docs/virtualbox/) and [VMware](https://www.vagrantup.com/docs/vmware/) providers.

## Quickstart

In an empty directory:

```bash
vagrant init AntonioMeireles/ClearLinux
vagrant up
```

## Vagrant Cloud

Vagrant boxes can be downloaded on Vagrant Cloud at [AntonioMeireles/Clearlinux](https://app.vagrantup.com/AntonioMeireles/boxes/ClearLinux)
