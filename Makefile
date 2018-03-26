BOX_NAME := ClearLinux
OWNER ?= AntonioMeireles
REPOSITORY := $(OWNER)/$(BOX_NAME)

VERSION ?= $(shell curl -Ls https://download.clearlinux.org/latest)
BUILD_ID ?= $(shell date -u '+%Y-%m-%d-%H%M')

VMDK := clear-$(VERSION)-vmware.vmdk
NV := $(BOX_NAME)-$(VERSION)
SEED_URL := https://download.clearlinux.org/releases/$(VERSION)/clear/$(VMDK).xz

MEDIADIR := media
BOXDIR := boxes
PWD := `pwd`

.PHONY: clean-all clean-current all seed boxes addboxlocally release

$(MEDIADIR)/$(VMDK):
	@mkdir -p $(MEDIADIR)
	@echo "downloading v$(VERSION) base image..."
	@curl -sSL $(SEED_URL) -o $(MEDIADIR)/$(VMDK).xz
	@cd $(MEDIADIR) && unxz $(VMDK).xz && cd -
	@echo "v$(VERSION) base image unpacked..."

seed: $(MEDIADIR)/seed-$(VERSION)

$(MEDIADIR)/seed-$(VERSION): $(MEDIADIR)/$(VMDK)
	@mkdir -p $(MEDIADIR)/seed-$(VERSION)
	@for f in vmx vmxf vmsd plist; do                                           \
		cp template/$(BOX_NAME).$$f.tmpl $(MEDIADIR)/seed-$(VERSION)/$(NV).$$f; done
	@(cd $(MEDIADIR)/seed-$(VERSION); gsed -i "s,VERSION,$(VERSION)," $(BOX_NAME)-*)
	@cp ./$(MEDIADIR)/$(VMDK) $(MEDIADIR)/seed-$(VERSION)/
	@(cd $(MEDIADIR)/seed-$(VERSION);                                      \
		gsed -i "s,VMDK_SIZE,$$(/usr/bin/stat -f"%z" $(VMDK))," $(BOX_NAME)-* )
	@echo "vmware fusion VM (v$(VERSION)) syntetised from vmdk"

boxes: $(MEDIADIR)/$(NV).ova
	@mkdir -p $(BOXDIR)
	packer build  -force                              \
		-var "name=$(BOX_NAME)"                          \
		-var "version=$(VERSION)"                         \
		-var "box_tag=$(REPOSITORY)" packer.conf.vmware.json
	packer build -force                                   \
		-var "name=$(BOX_NAME)"                              \
		-var "version=$(VERSION)"                             \
		-var "box_tag=$(REPOSITORY)" packer.conf.virtualbox.json

$(MEDIADIR)/seed-$(VERSION)/$(NV).vmx: $(MEDIADIR)/seed-$(VERSION)

$(MEDIADIR)/$(NV).ova: $(MEDIADIR)/seed-$(VERSION)/$(NV).vmx
	ovftool $(MEDIADIR)/seed-$(VERSION)/$(NV).vmx $(MEDIADIR)/$(NV).ova

release:
	@curl --silent                                                                \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}"                      \
		https://app.vagrantup.com/api/v1/box/$(REPOSITORY)/version/$(VERSION)/release \
		--request PUT | jq .

addboxlocally: $(BOXDIR)/$(NV).vmware.box
	vagrant box add -f $(REPOSITORY) $(BOXDIR)/$(NV).vmware.box

clean-current:
	rm -rf $(MEDIADIR)/seed-$(VERSION) $(BOXDIR)/$(NV).vmware.box $(MEDIADIR)/$(NV).ova

clean-all:
	rm -rf $(MEDIADIR)/* $(BOXDIR)/* packer_cache


