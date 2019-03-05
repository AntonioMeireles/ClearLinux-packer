#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

systemctl enable libvirtd --now

for group in kvm libvirt; do
  usermod -G ${group} -a clear
done

mkdir -p /var/lib/libvirt/{isos,images}/ /etc/profile.d/ /usr/local/bin
chown root:kvm /var/lib/libvirt/{isos,images}/
chmod g+rwx /var/lib/libvirt/{isos,images}/

echo 'export LIBVIRT_DEFAULT_URI="qemu:///system"' > /etc/profile.d/libvirt.conf

wget -q https://releases.hashicorp.com/packer/1.3.4/packer_1.3.4_linux_amd64.zip
unzip -qq packer_1.3.4_linux_amd64.zip
mv packer /usr/local/bin
rm -rf packer_1.3.4_linux_amd64.zip
