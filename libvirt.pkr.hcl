
variable "box_tag" {
  type    = string
  default = "${env("REPOSITORY")}"
}

variable "cloud_token" {
  type    = string
  default = "${env("VAGRANT_CLOUD_TOKEN")}"
}

variable "name" {
  type    = string
  default = "${env("BOX_NAME")}"
}

variable "version" {
  type    = string
  default = "${env("VERSION")}"
}

source "qemu" "libvirt" {
  accelerator         = "kvm"
  boot_wait           = "20s"
  cpus                = 2
  disk_detect_zeroes  = "unmap"
  disk_discard        = "unmap"
  disk_image          = true
  disk_interface      = "virtio-scsi"
  disk_size           = 5120
  format              = "qcow2"
  headless            = false
  iso_checksum        = "none"
  iso_url             = "media/clear-${var.version}-libvirt-factory.img"
  memory              = 2048
  net_device          = "virtio-net"
  output_directory    = "boxes/tmp"
  qemuargs            = [["-bios", "/usr/share/qemu/OVMF.fd"]]
  shutdown_command    = "sudo fstrim -a -v && sudo sync && sudo shutdown -P now"
  ssh_password        = "V@grant!"
  ssh_port            = 22
  ssh_timeout         = "5m"
  ssh_username        = "clear"
  use_default_display = true
  vm_name             = "${var.name}"
}

build {
  sources = ["source.qemu.libvirt"]

  provisioner "shell" {
    inline = ["sudo timedatectl set-ntp true"]
  }

  provisioner "shell" {
    expect_disconnect   = true
    inline              = ["echo 'rebooting...'", "sudo systemctl reboot"]
  }

  provisioner "shell" {
    start_retry_timeout = "600s"
    inline = ["uname -a; swupd info"]
  }

  post-processor "vagrant" {
    compression_level    = 9
    include              = ["info.json"]
    output               = "boxes/{{ .Provider }}/${var.name}-${var.version}.{{ .Provider }}.box"
    vagrantfile_template = "Vagrantfile.template.rb"
  }

  post-processor "checksum" {
    checksum_types = ["sha1", "sha256"]
    output         = "boxes/{{ .BuildName }}/${var.name}-${var.version}.{{.BuildName}}.box.{{.ChecksumType}}.checksum"

  }
}
