#!/usr/bin/env bash

mountpoint=$(mktemp -d -t tmp.XXXXXXXXXX)
unpack=$(mktemp -d -t tmp.XXXXXXXXXX)
store=$(mktemp -d -t tmp.XXXXXXXXXX)

function cleanup {
  umount "${mountpoint}"
  rm -rf "${unpack}" /home/clear/VBoxGuestAdditions.iso
  rm -rf "${mountpoint}" "${store}"
}

trap cleanup EXIT

mount /home/clear/VBoxGuestAdditions.iso "${mountpoint}" -t iso9660 -o ro
"${mountpoint}"/VBoxLinuxAdditions.run --noexec --keep --nox11 --target "${unpack}"

tar xjf "${unpack}"/VBoxGuestAdditions-amd64.tar.bz2 -C "${store}"

install -m0755 "${store}"/bin/{VBoxClient,VBoxControl} /usr/bin/
install -m0755 "${store}"/sbin/VBoxService /usr/bin/
install -m0755 "${store}"/other/mount.vboxsf /usr/bin/
install -m0755 -D "${store}"/other/98vboxadd-xclient /usr/bin/VBoxClient-all
install -Dm0644 "${store}"/other/vboxclient.desktop /usr/share/xdg/autostart/vboxclient.desktop

install -m0755 "${store}"/lib/VBoxOGL*.so /usr/lib64/
install -d /usr/lib64/dri
ln -s /usr/lib64/VBoxOGL.so /usr/lib64/dri/vboxvideo_dri.so

install -Dm0755 -D "${store}"/other/pam_vbox.so /usr/lib64/security/pam_vbox.so

install -d /etc/udev/rules.d
(
  echo 'ACTION=="add", KERNEL=="vboxguest", SUBSYSTEM=="misc", OWNER="root", MODE="0600"'
  echo 'ACTION=="add", KERNEL=="vboxuser", SUBSYSTEM=="misc", OWNER="root", MODE="0666"'
) | tee /etc/udev/rules.d/60-vboxguest.rules
chmod 0644 /etc/udev/rules.d/60-vboxguest.rules

(
  echo '[Unit]'
  echo 'Description=VirtualBox Guest Service'
  echo 'ConditionVirtualization=oracle'
  echo '[Service]'
  echo 'ExecStartPre=-/usr/bin/modprobe vboxguest'
  echo 'ExecStartPre=-/usr/bin/modprobe vboxvideo'
  echo 'ExecStartPre=-/usr/bin/modprobe vboxsf'
  echo 'ExecStart=/usr/bin/VBoxService -f'
  echo '[Install]'
  echo 'WantedBy=multi-user.target'
) | tee /etc/systemd/system/vboxservice.service
chmod 0644 /etc/systemd/system/vboxservice.service
install -d /etc/sysusers.d
echo "g vboxsf 109 -" | tee /etc/sysusers.d/virtualbox-guest-utils.conf
chmod 0644 /etc/sysusers.d/virtualbox-guest-utils.conf
