BOX_NAME := ClearLinux
OWNER ?= AntonioMeireles
REPOSITORY := $(OWNER)/$(BOX_NAME)

CLR_BASE_URL := https://download.clearlinux.org
VERSION ?= $(shell curl -Ls $(CLR_BASE_URL)/latest)
BUILD_ID ?= $(shell date -u '+%Y-%m-%d-%H%M')
NV := $(BOX_NAME)-$(VERSION)

SEED_PREFIX = clear-$(VERSION)
VMDK := $(SEED_PREFIX)-vmware.vmdk
LIBVIRT := $(SEED_PREFIX)-kvm.img

VMDK_SEED_URL := $(CLR_BASE_URL)/releases/$(VERSION)/clear/$(VMDK).xz
LIBVIRT_SEED_URL := $(CLR_BASE_URL)/releases/$(VERSION)/clear/$(LIBVIRT).xz
MEDIADIR := media
BOXDIR := boxes
PWD := `pwd`

.PHONY: clean clean-current all seed boxes addboxlocally release

$(MEDIADIR)/OVMF.fd:
	@mkdir -p $(MEDIADIR)
	@curl -sSL $(CLR_BASE_URL)/image/OVMF.fd -o $(MEDIADIR)/OVMF.fd
	@ln -sf $(MEDIADIR)/OVMF.fd $(MEDIADIR)/bios.bin

$(MEDIADIR)/$(VMDK):
	@mkdir -p $(MEDIADIR)
	@echo "downloading v$(VERSION) base image [VMDK]..."
	@curl -sSL $(VMDK_SEED_URL) -o $(MEDIADIR)/$(VMDK).xz
	@cd $(MEDIADIR) && unxz $(VMDK).xz && vmware-vdiskmanager -x 40Gb $(VMDK) && cd -
	@echo "v$(VERSION) base image unpacked..."

$(MEDIADIR)/$(LIBVIRT):
	@mkdir -p $(MEDIADIR)
	@echo "downloading v$(VERSION) base image [KVM/libvirt]..."
	@curl -sSL $(LIBVIRT_SEED_URL) -o /tmp/$(LIBVIRT).xz
	@unxz -f /tmp/$(LIBVIRT).xz && mv /tmp/$(LIBVIRT) $(MEDIADIR)/
	@echo "v$(VERSION) base image unpacked..."

seed: $(MEDIADIR)/seed-$(VERSION)

$(MEDIADIR)/$(NV).ova: $(MEDIADIR)/$(VMDK)
	@mkdir -p $(MEDIADIR)/seed-$(VERSION)
	@for f in pv.vmx vmx vmxf vmsd plist; do                                           \
		cp template/$(BOX_NAME).$$f.tmpl $(MEDIADIR)/seed-$(VERSION)/$(NV).$$f; done
	@(cd $(MEDIADIR)/seed-$(VERSION); gsed -i "s,VERSION,$(VERSION)," $(BOX_NAME)-*)
	@ln -sf ../$(VMDK) $(MEDIADIR)/seed-$(VERSION)/
	@(cd $(MEDIADIR)/seed-$(VERSION);                                      \
		gsed -i "s,VMDK_SIZE,$$(/usr/bin/stat -f"%z" ../$(VMDK))," $(BOX_NAME)-* )
	@echo "vmware fusion VM (v$(VERSION)) syntetised from vmdk"
	@ovftool $(MEDIADIR)/seed-$(VERSION)/$(NV).vmx $(MEDIADIR)/$(NV).ova
	@cp $(MEDIADIR)/seed-$(VERSION)/$(NV).pv.vmx $(MEDIADIR)/seed-$(VERSION)/$(NV).vmx

libvirt.box: $(MEDIADIR)/$(LIBVIRT) $(MEDIADIR)/OVMF.fd
	@mkdir -p $(BOXDIR)

	packer build -force                                        \
		-var "name=$(BOX_NAME)"                                   \
		-var "version=$(VERSION)"                                  \
		-var "box_tag=$(REPOSITORY)" packer.conf.libvirt.json

boxes: $(MEDIADIR)/$(NV).ova
	@mkdir -p $(BOXDIR)
	packer build -force                                               \
		-var "name=$(BOX_NAME)"                                          \
		-var "version=$(VERSION)"                                         \
		-var "box_tag=$(REPOSITORY)" packer.conf.vmware.json
	packer build -force                                                    \
		-var "name=$(BOX_NAME)"                                               \
		-var "version=$(VERSION)"                                              \
		-var "box_tag=$(REPOSITORY)" packer.conf.virtualbox.json

release:
	@curl --silent                                                                \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}"                      \
		https://app.vagrantup.com/api/v1/box/$(REPOSITORY)/version/$(VERSION)/release \
		--request PUT | jq .

addboxlocally: $(BOXDIR)/$(NV).vmware.box
	vagrant box add -f $(REPOSITORY) $(BOXDIR)/$(NV).vmware.box

clean-current:
	rm -rf $(MEDIADIR)/seed-$(VERSION) $(BOXDIR)/$(NV).vmware.box $(MEDIADIR)/$(NV).ova

clean:
	rm -rf $(MEDIADIR)/* $(BOXDIR)/* packer_cache


