#!/usr/bin/env bash

default="/home/clear/VBoxGuestAdditions.iso"

mountpoint=$(mktemp -d -t vbga.XXXXXXXXXX)
guest_additions=$(mktemp -d -t vbga.XXXXXXXXXX)
linux_bits=$(mktemp -d -t vbga.XXXXXXXXXX)

function error() {
  echo "E: $*" >>/dev/stderr
  exit 1
}

function cleanup() {
  umount "${mountpoint}"
  rm -rf "${guest_additions}" "${default}" "${mountpoint}" "${linux_bits}"
}

trap cleanup EXIT

if [ "$(id -u)" -ne 0 ]; then
  error "You must be 'root' to execute this script"
fi

if [[ -f "${default}" ]]; then
  mount "${default}" "${mountpoint}" -t iso9660 -o ro
else
  drives_found=$(lsblk | grep sr | cut -c -3)
  if [ -z "${drives_found}" ]; then
    error 'CDROM drives NOT FOUND - Please attach the Guest Additions CD image...'
  fi
  ga_found=0
  for cdrom in ${drives_found}; do
    mount "/dev/${cdrom}" "${mountpoint}" -t iso9660 -o ro
    if [ -f "${mountpoint}/VBoxLinuxAdditions.run" ]; then
      ga_found=1
      break
    fi
    umount "${mountpoint}"
  done
  [[ ga_found -eq 1 ]] || error 'CDROM drives NOT FOUND - Please attach the Guest Additions CD image...'
fi

"${mountpoint}/VBoxLinuxAdditions.run" --noexec --keep --nox11 --target "${guest_additions}"
tar xjf "${guest_additions}/VBoxGuestAdditions-amd64.tar.bz2" -C "${linux_bits}"

for f in "${linux_bits}"{/bin/{VBoxClient,VBoxControl},/sbin/VBoxService,/other/mount.vboxsf}; do
  install -m0755 "${f}" '/usr/bin'
done

install -Dm0755 "${linux_bits}/other/98vboxadd-xclient" '/usr/bin/VBoxClient-all'
install -Dm0644 "${linux_bits}/other/vboxclient.desktop" '/usr/share/xdg/autostart/vboxclient.desktop'

# gone with the wind - https://www.mail-archive.com/vbox-dev@virtualbox.org/msg09732.html
#
# install -m0755 "${linux_bits}/lib/"VBoxOGL*.so '/usr/lib64/'
# install -d '/usr/lib64/dri'
# ln -s '/usr/lib64/VBoxOGL.so' '/usr/lib64/dri/vboxvideo_dri.so'

install -Dm0755 -D "${linux_bits}/other/pam_vbox.so" '/usr/lib64/security/pam_vbox.so'

install -d '/etc/udev/rules.d'
printf %s '
ACTION=="add", KERNEL=="vboxguest", SUBSYSTEM=="misc", OWNER="root", MODE="0600"
ACTION=="add", KERNEL=="vboxuser", SUBSYSTEM=="misc", OWNER="root", MODE="0666"
' | tee '/etc/udev/rules.d/60-vboxguest.rules'
chmod 0644 '/etc/udev/rules.d/60-vboxguest.rules'

printf %s '
[Unit]
Description=VirtualBox Guest Service
ConditionVirtualization=oracle
[Service]
ExecStartPre=-/usr/bin/modprobe vboxguest
ExecStartPre=-/usr/bin/modprobe vboxvideo
ExecStartPre=-/usr/bin/modprobe vboxsf
ExecStart=/usr/bin/VBoxService -f
[Install]
WantedBy=multi-user.target
' | tee '/etc/systemd/system/vboxservice.service'
chmod 0644 '/etc/systemd/system/vboxservice.service'
