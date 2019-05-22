#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

PACKER_VERSION=1.4.1
PACKER_ZIP=packer_${PACKER_VERSION}_linux_amd64.zip
PACKER_URL=https://releases.hashicorp.com/packer/${PACKER_VERSION}/${PACKER_ZIP}

curl -s ${PACKER_URL} -o ${PACKER_ZIP}
unzip -qq ${PACKER_ZIP} && sudo mv packer /usr/local/bin && rm -rf ${PACKER_ZIP}
