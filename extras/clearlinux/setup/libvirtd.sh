#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

[[ -x "$(command -v virsh)" ]] || {
  echo "Aborted: you do not appear to have the 'kvm-host' bundle installed"
  echo "         please run 'sudo swupd bundle-add kvm-host' and then try again"
  exit 1
}
sudo systemctl enable libvirtd --now

for group in kvm libvirt; do
  sudo usermod -G ${group} -a $USER
done

sudo mkdir -p /var/lib/libvirt/{isos,images}/ /etc/profile.d/ /usr/local/bin
sudo chown root:kvm /var/lib/libvirt/{isos,images}/
sudo chmod g+rwx /var/lib/libvirt/{isos,images}/

echo 'export LIBVIRT_DEFAULT_URI="qemu:///system"' | sudo tee /etc/profile.d/libvirt.conf
