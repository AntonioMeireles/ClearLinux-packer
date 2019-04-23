.DEFAULT_GOAL := help
.EXPORT_ALL_VARIABLES:

PROVIDERS := libvirt vmware virtualbox

BOX_NAME := ClearLinux
OWNER ?= AntonioMeireles
REPOSITORY := $(OWNER)/$(BOX_NAME)
VERSION ?= $(shell curl -Ls $(CLR_BASE_URL)/latest)

CLR_BASE_URL := https://download.clearlinux.org
CLR_RELEASE_URL := $(CLR_BASE_URL)/releases/$(VERSION)/clear

NV := $(BOX_NAME)-$(VERSION)
OSV := clear-$(VERSION)

VAGRANT_REPO := https://app.vagrantup.com/api/v1/box/$(REPOSITORY)

UNAME := $(shell uname)
LIBVIRT_HOST ?= libvirt-host.clearlinux.local
LIBVIRT_CONNECT :=

ifneq ($(UNAME),Linux)
	LIBVIRT_CONNECT := ssh clear@$(LIBVIRT_HOST)
endif

define mediaFactory
media/$(OSV)-$1-factory
endef

define VMDKtarget
ifneq ($T,libvirt)
media/$(OSV)-$T-factory.vmdk: media/$(OSV)-$T-factory.img
	$(call imgToVMDK,$T)
endif
endef

define IMGtarget
media/$(OSV)-$T-factory.img:
	$(call buildBaseImg,$T)
endef

define PROVIDERtarget
$T: boxes/$T/$(NV).$T.box
endef

define UploadBoxTarget
.PHONY: upload-$T-box
upload-$T-box: boxes/$T/$(NV).$T.box
	$(call boxUpload,$T)
endef

define smokeTESTtarget
.PHONY: test-$T
test-$T: boxes/$T/$(NV).$T.box
	$(call boxSmokeTest,$T)
	$(if $(filter $T,libvirt),$(LIBVIRT_CONNECT) sudo virsh vol-delete clear-test_vagrant_box_image_0.img default,)
endef

define targetConfig
builders/$1.yml.$(VERSION)
endef

define buildBaseImg
	@mkdir -p media
	@echo "- assembling v$(VERSION) base img for $1 guests..."

	sed -e "s,^version:.*,version: $(VERSION)," builders/$1.yml > $(targetConfig)
	sudo clr-installer --config $(targetConfig) -l 4 -b installer:media/$(OSV)-$1-factory.img

	rm -rf $(targetConfig)
endef

define imgToVMDK
	qemu-img convert -p -C media/$(OSV)-$1-factory.img -O vmdk media/$(OSV)-$1-factory.vmdk
endef

define vmxBuilder
	@mkdir -p media/$(OSV)-$1-factory
	@for f in virtualbox.vmx vmware.vmx vmxf vmsd plist; do                                           \
		cp template/$(BOX_NAME).$$f.tmpl media/$(OSV)-$1-factory/$(NV).$$f; done

	@cp media/$(OSV)-$1-factory/$(NV).$1.vmx media/$(OSV)-$1-factory/$(NV).vmx

	@pushd media/$(OSV)-$1-factory && sed -i "s,VERSION,$(VERSION)," $(BOX_NAME)-* && popd

	@ln -sf ../$(OSV)-$1-factory.vmdk media/$(OSV)-$1-factory/

	@pushd media/$(OSV)-$1-factory && sed -i "s,VMDK_SIZE,$$( stat --printf="%s" ../$(OSV)-$1-factory.vmdk)," $(BOX_NAME)-* && popd
endef

define pack
	packer build -force -only=$(strip $(builder)) packer.conf.$1.json
endef

define builder
$(if $(filter $1,libvirt),qemu,)
$(if $(filter $1,vmware),vmware-vmx,)
$(if $(filter $1,virtualbox),virtualbox-ovf,)
endef

define provider
$(if $(filter $1,vmware),vmware_desktop,$1)
endef

define boxSmokeTest
	vagrant box add --name clear-test --provider $(strip $(provider)) boxes/$1/$(NV).$1.box --force
	@pushd extras/test;                                                                        \
	vagrant up --provider $(strip $(provider)) ;                                              \
	vagrant ssh -c "w; sudo swupd info" && echo "- $1 box (v$(VERSION)) looks OK" || exit 1; \
	vagrant halt -f ;                                                                       \
	vagrant destroy -f;                                                                    \
	vagrant box remove clear-test --provider $(strip $(provider));                        \
	popd
endef

define authBearer
--header "Authorization: Bearer ${VAGRANT_CLOUD_TOKEN}"
endef

define isJson
--header "Content-Type: application/json"
endef

define boxUpload
	@echo "- '$(OWNER)/$(BOX_NAME)/$(VERSION)/$1' uploading..."
	@curl `curl -s $(authBearer) $(VAGRANT_REPO)/version/${VERSION}/provider/$(if $(filter $1, vmware),vmware_desktop,$1)/upload | jq .upload_path | tr -d \"` \
		--upload-file boxes/$1/$(NV).$1.box && echo "- '$(OWNER)/$(BOX_NAME)/$(VERSION)/$1' uploaded"
endef

define addProviderToRelease
	curl -s $(isJson) $(authBearer) $(VAGRANT_REPO)/version/${VERSION}/providers \
		--data '{"provider": {"name": "$(if $(filter $1,vmware),vmware_desktop,$1)"}}' && \
		echo "- added '$1' provider to '$(OWNER)/$(BOX_NAME)/$(VERSION)'"
endef

.PHONY: help
help:
	@echo
	@echo "the following PROVIDERS are currently available: \033[36m$(PROVIDERS)\033[0m"
	@echo
	@echo "available 'make' targets:"
	@echo
	@grep -E "^.*:.*?## .*$$" $(MAKEFILE_LIST) | grep -vE "(grep|BEGIN)" | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\t\033[36m%-30s\033[0m %s\n", $$1, $$2}' | \
		envsubst
	@echo
	@echo "By default the target VERSION is the 'latest' one, currently at $(VERSION)"
	@echo "To target a specific one add 'VERSION=...' to your make invocation"
	@echo

$(foreach T,$(PROVIDERS),$(eval $(IMGtarget)))

$(foreach T,$(PROVIDERS),$(eval $(VMDKtarget)))

$(call mediaFactory,virtualbox)/$(NV).ova: $(call mediaFactory,virtualbox).vmdk
	# synthethising VirtualBox OVA
	$(call vmxBuilder,virtualbox)
	ovftool $(call mediaFactory,virtualbox)/$(NV).vmx $(call mediaFactory,virtualbox)/$(NV).ova
	# VirtualBox VM (OVA) syntethised from vmdk

$(call mediaFactory,vmware)/$(NV).vmx: $(call mediaFactory,vmware).vmdk
	# synthethising VMware VM
	$(call vmxBuilder,vmware)
	# vmware fusion VM (v$(VERSION)) syntetised from vmdk

.PHONY: media $(foreach p,$(PROVIDERS),media/$(p))
media: $(foreach p,$(PROVIDERS),media/$(p))  ## Media Fetcher  Assembles locally all media needed by Packer
media/vmware: $(call mediaFactory,vmware)/$(NV).vmx
media/libvirt: $(call mediaFactory,libvirt).img
media/virtualbox: $(call mediaFactory,virtualbox).vmdk

.PHONY: all $(PROVIDERS) release upload publish clean
all: $(PROVIDERS) ## Packer Builds  All providers boxes

$(foreach T,$(PROVIDERS),$(eval $(PROVIDERtarget)))

boxes/libvirt/$(NV).libvirt.box: $(call mediaFactory,libvirt).img
	$(call pack,libvirt)

boxes/virtualbox/$(NV).virtualbox.box: $(call mediaFactory,virtualbox)/$(NV).ova
	$(call pack,virtualbox)

boxes/vmware/$(NV).vmware.box: $(call mediaFactory,vmware)/$(NV).vmx
	$(call pack,vmware)

release: ## Vagrant Cloud  Create a new release
	( cat new.tmpl.json | envsubst | curl --silent $(isJson) $(authBearer) $(VAGRANT_REPO)/versions \
		--data-binary @- ) && echo "- '$(OWNER)/$(BOX_NAME)/$(VERSION)' release created on Vagrant Cloud"
	$(call addProviderToRelease,libvirt)
	$(call addProviderToRelease,vmware)
	$(call addProviderToRelease,virtualbox)

upload: $(foreach p,$(PROVIDERS),upload-$(p)-box) ## Vagrant Cloud  Uploads all built boxes for version

$(foreach T,$(PROVIDERS),$(eval $(UploadBoxTarget)))

publish: ## Vagrant Cloud  make uploaded boxes public
	@curl --silent $(authBearer) $(VAGRANT_REPO)/version/$(VERSION)/release --request PUT | jq .

$(foreach T,$(PROVIDERS),$(eval $(smokeTESTtarget)))

clean: ## frees space
	rm -rf media/* boxes/* packer_cache/*


