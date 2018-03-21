BOX_NAME := ClearLinux
OWNER ?= AntonioMeireles
REPOSITORY := $(OWNER)/$(BOX_NAME)

VERSION ?= $(shell curl -Ls https://download.clearlinux.org/latest)
BUILD_ID   ?= $(shell date -u '+%Y-%m-%d-%H%M')

VMDK := clear-$(VERSION)-vmware.vmdk
NV := $(BOX_NAME)-$(VERSION)

PWD := `pwd`

.PHONY: clean all seed packer addbox

# all: clear-$(VERSION_ID)-vmware-box

$(VMDK):
	@echo "downloading v$(VERSION) base image..."
	curl -Ls https://download.clearlinux.org/releases/$(VERSION)/clear/$(VMDK).xz -o $(VMDK).xz
	@unxz $(VMDK).xz
	@echo "v$(VERSION) base image unpacked..."

seed: seed-$(VERSION)

seed-$(VERSION): $(VMDK)
	@mkdir -p seed-$(VERSION)
	@for f in vmx vmxf vmsd plist; do \
		cp template/$(BOX_NAME).$$f.tmpl seed-$(VERSION)/$(NV).$$f; done
	@(cd seed-$(VERSION); gsed -i "s,VERSION,$(VERSION)," $(BOX_NAME)-*)
	@cp ./$(VMDK) seed-$(VERSION)/
	@(cd seed-$(VERSION); \
		gsed -i "s,VMDK_SIZE,$$(/usr/bin/stat -f"%z" $(VMDK))," $(BOX_NAME)-* )
	@echo "vmware fusion VM (v$(VERSION)) syntetised from vmdk"

packer: $(NV).vmware.box

$(NV).vmware.box: seed-$(VERSION)
	packer build -var "name=$(BOX_NAME)" -var "version=$(VERSION)" packer.conf.json

publish:
	# Create a new version
	curl \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		https://app.vagrantup.com/api/v1/box/$(REPOSITORY)/versions \
		--data '{ "version": { "version": "$(VERSION)", "description": "#### **release notes** - https://download.clearlinux.org/releases/$(VERSION)/clear/RELEASENOTES\n\nbuilt with **[ClearLinux-packer](https://github.com/AntonioMeireles/ClearLinux-packer)**.\n**[feedback](https://github.com/AntonioMeireles/ClearLinux-packer/issues)** is welcome!" } }'
	# Create a new provider
	curl \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		https://app.vagrantup.com/api/v1/box/$(REPOSITORY)/version/$(VERSION)/providers \
		--data '{ "provider": { "name": "vmware_fusion" } }'
	curl \
		--header "Content-Type: application/json" \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		https://app.vagrantup.com/api/v1/box/$(REPOSITORY)/version/$(VERSION)/providers \
		--data '{ "provider": { "name": "vmware_desktop" } }'
	# Perform the upload
	curl --progress-bar $$(echo $$(curl -sSL \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		https://app.vagrantup.com/api/v1/box/$(REPOSITORY)/version/$(VERSION)/provider/vmware_fusion/upload | \
		jq .upload_path| sed -e 's,",,g')) --request PUT --upload-file $(BOX_NAME)-$(VERSION).vmware.box | tee /dev/null
	curl --progress-bar $$(echo $$(curl -sSL \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		https://app.vagrantup.com/api/v1/box/$(REPOSITORY)/version/$(VERSION)/provider/vmware_desktop/upload | \
		jq .upload_path| sed -e 's,",,g')) --request PUT --upload-file $(BOX_NAME)-$(VERSION).vmware.box | tee /dev/null

release:
	# Release the version
	curl \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		https://app.vagrantup.com/api/v1/box/$(REPOSITORY)/version/$(VERSION)/release \
		--request PUT

addbox: $(NV).vmware.box
	vagrant box add -f $(REPOSITORY) $(NV).vmware.box

clean:
	rm -rf seed-$(VERSION) $(NV).vmware.box

clean-all:
	rm -rf seed-* *.box *.vmdk


