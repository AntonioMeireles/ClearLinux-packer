BOX_NAME := ClearLinux
OWNER ?= AntonioMeireles
REPOSITORY := $(BOX_NAME)/$(OWNER)

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
	@echo "=== hack around https://github.com/hashicorp/packer/issues/5896 ==="
	@( \
		mkdir tmp; cd tmp; tar xzf ../$(NV).vmware.box; \
		echo '{"provider": "vmware_fusion"}' > metadata.json ; \
		tar czf ../$(NV).vmware.box *; \
		cd ..; rm -rf tmp;\
	)

addbox: $(NV).vmware.box
	vagrant box add -f $(REPOSITORY) $(NV).vmware.box --provider vmware_fusion

clean:
	rm -rf seed-$(VERSION) $(NV).vmware.box
