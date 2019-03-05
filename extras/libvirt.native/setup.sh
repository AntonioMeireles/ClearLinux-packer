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

PACKER_VERSION=1.3.5
PACKER_ZIP=packer_${PACKER_VERSION}_linux_amd64.zip
PACKER_URL=https://releases.hashicorp.com/packer/${PACKER_VERSION}/${PACKER_ZIP}

curl -s ${PACKER_URL} -o ${PACKER_ZIP}
unzip -qq ${PACKER_ZIP} && mv packer /usr/local/bin && rm -rf ${PACKER_ZIP}
