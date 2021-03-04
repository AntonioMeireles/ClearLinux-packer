
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

source "virtualbox-ovf" "virtualbox" {
  boot_wait            = "20s"
  output_directory     = "boxes/tmp"
  shutdown_command     = "cat /dev/zero > zero.fill; sudo sync; sleep 5; sudo sync; rm -f zero.fill; sudo shutdown -P now"
  ssh_password         = "V@grant!"
  ssh_port             = 22
  ssh_timeout          = "5m"
  ssh_username         = "clear"
  vm_name              = "${var.name}"
  source_path          = "media/clear-${var.version}-virtualbox-factory/ClearLinux-${var.version}.ova"
  checksum             = "none"
  guest_additions_mode = "upload"
  vboxmanage           = [
    [
      "modifyvm",
      "{{ .Name }}",
      "--memory", "2048"
    ], [
      "modifyvm",
      "{{ .Name }}",
      "--ostype",
      "Linux26_64"
    ], [
      "modifyvm",
      "{{ .Name }}",
      "--cpus", "2"
    ], [
      "modifyvm",
      "{{ .Name }}",
      "--chipset", "ich9"
    ], [
      "modifyvm",
      "{{ .Name }}",
      "--firmware", "efi"
    ], [
      "modifyvm",
      "{{ .Name }}",
      "--paravirtprovider",
      "kvm"
    ], [
      "modifyvm",
      "{{ .Name }}",
      "--rtcuseutc", "on"
    ], [
      "modifyvm",
      "{{ .Name }}",
      "--boot1", "disk"
    ]
  ]
}

build {
  sources = ["source.virtualbox-ovf.virtualbox"]

  provisioner "shell" {
    inline = ["sudo timedatectl set-ntp true"]
  }

  provisioner "shell" {
    execute_command = "sudo bash {{ .Path }}"
    script          = "vboxguestsetup.sh"
  }

  provisioner "shell" {
    expect_disconnect   = true
    inline              = ["echo 'rebooting...'", "sudo systemctl reboot"]
    start_retry_timeout = "600s"
  }

  provisioner "shell" {
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
