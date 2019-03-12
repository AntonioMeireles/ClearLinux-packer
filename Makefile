.DEFAULT_GOAL := help

BOX_NAME := ClearLinux
OWNER ?= AntonioMeireles
REPOSITORY := $(OWNER)/$(BOX_NAME)

VERSION ?= $(shell curl -Ls $(CLR_BASE_URL)/latest)
CLR_BASE_URL := https://download.clearlinux.org
CLR_RELEASE_URL := $(CLR_BASE_URL)/releases/$(VERSION)/clear
BUILD_ID ?= $(shell date -u '+%Y-%m-%d-%H%M')
NV := $(BOX_NAME)-$(VERSION)

SEED_PREFIX = clear-$(VERSION)

VB_GA ?= $(shell curl -Ls http://download.virtualbox.org/virtualbox/LATEST.TXT)

MEDIADIR := media
BOXDIR := boxes
PWD := `pwd`

VMWARE_FACTORY := $(MEDIADIR)/$(SEED_PREFIX)-vmware-factory
VIRTUALBOX_FACTORY := $(MEDIADIR)/$(SEED_PREFIX)-virtualbox-factory
LIBVIRT_FACTORY := $(MEDIADIR)/$(SEED_PREFIX)-libvirt-factory

VAGRANT_REPO = https://app.vagrantup.com/api/v1/box/$(REPOSITORY)

.PHONY: help
help:
	@echo "available 'make' targets:"
	@echo
	@grep -E "^.*:.*?## .*$$" $(MAKEFILE_LIST) | grep -vE "(grep|BEGIN)" | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\t\033[36m%-30s\033[0m %s\n", $$1, $$2}' | \
		VERSION=$(VERSION) envsubst
	@echo
	@echo "By default the target VERSION is the 'latest' one, currently $(VERSION)"
	@echo "To target a specific one add 'VERSION=...' to your make invocation"
	@echo

$(MEDIADIR)/OVMF.fd:
	@mkdir -p $(MEDIADIR)
	@curl -sSL $(CLR_BASE_URL)/image/OVMF.fd -o $(MEDIADIR)/OVMF.fd

$(LIBVIRT_FACTORY).img:
	@mkdir -p $(MEDIADIR)
	# generating v$(VERSION) base image for libVirt guests...
	sed -e "s,^version:.*,version: $(VERSION)," builders/libvirt.yml > builders/libvirt.yml.$(VERSION)
	sudo clr-installer --config builders/libvirt.yml.$(VERSION) -l 4 -b installer:$(LIBVIRT_FACTORY).img
	rm -rf builders/libvirt.yml.$(VERSION)

$(VIRTUALBOX_FACTORY).vmdk:
		@mkdir -p $(MEDIADIR)
		# for now we just reuse libvirt base image
		# converting libvirt img to VMDK...
		qemu-img convert $(LIBVIRT_FACTORY).img -O vmdk $(VIRTUALBOX_FACTORY).vmdk

$(VIRTUALBOX_FACTORY)/$(NV).ova: $(VIRTUALBOX_FACTORY).vmdk
	@mkdir -p $(VIRTUALBOX_FACTORY)
	# synthethising VirtualBox OVA
	@for f in pv.vmx vmx vmxf vmsd plist; do                                           \
		cp template/$(BOX_NAME).$$f.tmpl $(VIRTUALBOX_FACTORY)/$(NV).$$f; done

	@pushd $(VIRTUALBOX_FACTORY) && sed -i "s,VERSION,$(VERSION)," $(BOX_NAME)-* && popd

	@ln -sf ../$(SEED_PREFIX)-virtualbox-factory.vmdk $(VIRTUALBOX_FACTORY)/

	@pushd $(VIRTUALBOX_FACTORY) && sed -i "s,VMDK_SIZE,$$( stat --printf="%s" ../$(SEED_PREFIX)-virtualbox-factory.vmdk)," $(BOX_NAME)-* && popd

	ovftool $(VIRTUALBOX_FACTORY)/$(NV).vmx $(VIRTUALBOX_FACTORY)/$(NV).ova
	# VirtualBox VM (OVA) syntethised from vmdk

$(VMWARE_FACTORY).vmdk:
		@mkdir -p $(MEDIADIR)
		# generating v$(VERSION) base image for VMware guests...
		sed -e "s,^version:.*,version: $(VERSION)," builders/vmware.yml > builders/vmware.yml.$(VERSION)
		sudo clr-installer --config builders/vmware.yml.$(VERSION) -l 4 -b installer:$(VMWARE_FACTORY).img
		rm -rf builders/vmware.yml.$(VERSION)
		# finally, converting to VMDK...
		qemu-img convert $(VMWARE_FACTORY).img -O vmdk $(VMWARE_FACTORY).vmdk

$(VMWARE_FACTORY)/$(NV).vmx: $(VMWARE_FACTORY).vmdk
	@mkdir -p $(VMWARE_FACTORY)

	@for f in pv.vmx vmx vmxf vmsd plist; do                                           \
		cp template/$(BOX_NAME).$$f.tmpl $(VMWARE_FACTORY)/$(NV).$$f; done

	@cp $(VMWARE_FACTORY)/$(NV).pv.vmx $(VMWARE_FACTORY)/$(NV).vmx

	pushd $(VMWARE_FACTORY) && sed -i "s,VERSION,$(VERSION)," $(BOX_NAME)-* && popd

	@ln -sf ../$(SEED_PREFIX)-vmware-factory.vmdk $(VMWARE_FACTORY)/

	pushd $(VMWARE_FACTORY) && sed -i "s,VMDK_SIZE,$$( stat --printf="%s" ../$(SEED_PREFIX)-vmware-factory.vmdk)," $(BOX_NAME)-* && popd

	# vmware fusion VM (v$(VERSION)) syntetised from vmdk

.PHONY: $(MEDIADIR)/vmware
$(MEDIADIR)/vmware: $(VMWARE_FACTORY)/$(NV).vmx

.PHONY: $(MEDIADIR)/libvirt
$(MEDIADIR)/libvirt: $(LIBVIRT_FACTORY).img

.PHONY: $(MEDIADIR)/virtualbox
$(MEDIADIR)/virtualbox: $(VIRTUALBOX_FACTORY).vmdk

.PHONY: media
media: $(VMWARE_FACTORY)/$(NV).vmx $(LIBVIRT_FACTORY).img $(VIRTUALBOX_FACTORY).vmdk  ## Base Builder   Assembles all media needed to pack the boxes

.PHONY: all virtualbox vmware libvirt
all: virtualbox vmware libvirt ## Packer Build   All box flavors

virtualbox: $(BOXDIR)/virtualbox/$(NV).virtualbox.box ## Packer Build   VirtualBox

vmware: $(BOXDIR)/vmware/$(NV).vmware.box ## Packer Build   VMware

libvirt: $(BOXDIR)/libvirt/$(NV).libvirt.box ## Packer Build   LibVirt

$(BOXDIR)/libvirt/$(NV).libvirt.box: $(LIBVIRT_FACTORY).img $(MEDIADIR)/OVMF.fd
	packer build -force -var "name=$(BOX_NAME)" -var "version=$(VERSION)" -var "box_tag=$(REPOSITORY)" -only=qemu packer.conf.libvirt.json

$(BOXDIR)/virtualbox/$(NV).virtualbox.box: $(VIRTUALBOX_FACTORY)/$(NV).ova
	packer build -force -var "name=$(BOX_NAME)" -var "vb_ga=$(VB_GA)" -var "version=$(VERSION)" -var "box_tag=$(REPOSITORY)" -only=virtualbox-ovf packer.conf.virtualbox.json

$(BOXDIR)/vmware/$(NV).vmware.box: $(VMWARE_FACTORY)/$(NV).vmx
	packer build -force -var "name=$(BOX_NAME)" -var "version=$(VERSION)" -var "box_tag=$(REPOSITORY)" -only=vmware-vmx packer.conf.vmware.json

.PHONY: release
release: ## Vagrant Cloud  create a new release
	( cat new.tmpl.json | envsubst | curl --silent --header "Content-Type: application/json" \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" $(VAGRANT_REPO)/versions      \
		--data-binary @- ) && echo "created release $(VERSION) on Vagrant Cloud"
	curl --header "Content-Type: application/json" \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		$(VAGRANT_REPO)/version/${VERSION}/providers \
		--data '{"provider": {"name": "virtualbox"}}'
	curl --header "Content-Type: application/json" \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		$(VAGRANT_REPO)/version/${VERSION}/providers \
		--data '{"provider": {"name": "vmware_desktop"}}'
	curl --header "Content-Type: application/json" \
		--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		$(VAGRANT_REPO)/version/${VERSION}/providers \
		--data '{"provider": {"name": "libvirt"}}'

.PHONY: upload-libvirt-box
upload-libvirt-box: $(BOXDIR)/libvirt/$(NV).libvirt.box ## Vagrant Cloud  LibVirt upload
	@curl $$(curl -s --header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		$(VAGRANT_REPO)/version/${VERSION}/provider/libvirt/upload | jq .upload_path | tr -d \") \
		--upload-file $(BOXDIR)/libvirt/$(NV).libvirt.box && echo "LibVirt box (v$(VERSION)) uploaded"

.PHONY: upload-virtualbox-box
upload-virtualbox-box: $(BOXDIR)/virtualbox/$(NV).virtualbox.box ## Vagrant Cloud  VirtualBox upload
	@curl $$(curl -s --header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		$(VAGRANT_REPO)/version/${VERSION}/provider/virtualbox/upload | jq .upload_path | tr -d \") \
		--upload-file $(BOXDIR)/virtualbox/$(NV).virtualbox.box && echo "VirtualBox box (v$(VERSION)) uploaded"

.PHONY: upload-vmware-box
upload-vmware-box: $(BOXDIR)/vmware/$(NV).vmware.box ## Vagrant Cloud  VMware upload
	@curl $$(curl -s --header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		$(VAGRANT_REPO)/version/${VERSION}/provider/vmware_desktop/upload | jq .upload_path | tr -d \") \
		--upload-file $(BOXDIR)/vmware/$(NV).vmware.box && echo "VMware box (v$(VERSION)) uploaded"

.PHONY: upload-all publish
upload-all: upload-virtualbox-box upload-libvirt-box upload-vmware-box ## Vagrant Cloud  Uploads all built boxes

publish: ## Vagrant Cloud  make uploaded boxes public
	@curl --silent --header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}" \
		$(VAGRANT_REPO)/version/$(VERSION)/release --request PUT | jq .

.PHONY: test-vmware test-virtualbox test-libvirt
test-vmware: $(BOXDIR)/vmware/$(NV).vmware.box ## Smoke Testing  VMware
	@vagrant box add --name clear-test --provider vmware_desktop $(BOXDIR)/vmware/$(NV).vmware.box --force
	@pushd extras/test;                                                                            \
	vagrant up --provider vmware_desktop ;                                                        \
	vagrant ssh -c "w; sudo swupd info" && echo "- VMware box (v$(VERSION)) looks OK" || exit 1; \
	vagrant halt -f ;                                                                           \
	vagrant destroy -f;                                                                        \
	vagrant box remove clear-test --provider vmware_desktop;                                 \
	popd

test-virtualbox: $(BOXDIR)/virtualbox/$(NV).virtualbox.box ## Smoke Testing  VirtualBox
	@vagrant box add --name clear-test --provider virtualbox $(BOXDIR)/virtualbox/$(NV).virtualbox.box --force
	@pushd extras/test;                                                                                \
	vagrant up --provider virtualbox ;                                                                \
	vagrant ssh -c "w; sudo swupd info" && echo "- Virtualbox box (v$(VERSION)) looks OK" || exit 1; \
	vagrant halt -f ;                                                                               \
	vagrant destroy -f;                                                                            \
	vagrant box remove clear-test --provider virtualbox;                                          \
	popd

test-libvirt: $(BOXDIR)/libvirt/$(NV).libvirt.box ## Smoke Testing  LibVirt
	@vagrant box add --name clear-test --provider libvirt $(BOXDIR)/libvirt/$(NV).libvirt.box --force
	@pushd extras/test;                                                                             \
	vagrant up --provider libvirt ;                                                                \
	vagrant ssh -c "w; sudo swupd info" && echo "- Libvirt box (v$(VERSION)) looks OK" || exit 1; \
	vagrant halt -f ;                                                                            \
	vagrant destroy -f;                                                                         \
	vagrant box remove clear-test --provider libvirt;                                          \
	popd
	ssh clear@libvirt-host.clearlinux.local "sudo virsh vol-delete clear-test_vagrant_box_image_0.img default"

.PHONY: clean
clean: # does what it says ...
	rm -rf $(MEDIADIR)/* $(BOXDIR)/* packer_cache


