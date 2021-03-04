
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

source "vmware-vmx" "vmware" {
  boot_wait        = "20s"
  output_directory = "boxes/tmp"
  shutdown_command = "cat /dev/zero > zero.fill; sudo sync; sleep 5; sudo sync; rm -f zero.fill; sudo shutdown -P now"
  ssh_password     = "V@grant!"
  ssh_port         = 22
  ssh_timeout      = "5m"
  ssh_username     = "clear"
  vm_name          = "${var.name}"
  source_path      = "media/clear-${var.version}-vmware-factory/ClearLinux-${var.version}.vmx"
  vmx_data = {
    "cpuid.coresPerSocket" = "1"
    memsize                = "2048"
    numvcpus               = "2"
  }
  vmx_data_post = {
    cleanShutdown              = "TRUE"
    "ethernet0.startConnected" = "TRUE"
    "ethernet0.wakeonpcktrcv"  = "false"
    softPowerOff               = "FALSE"
  }
}

build {
  sources = ["source.vmware-vmx.vmware"]

  provisioner "shell" {
    inline = ["sudo timedatectl set-ntp true"]
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
