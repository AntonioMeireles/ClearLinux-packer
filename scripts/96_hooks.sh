#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

# keep intel people happy - workaround for vagrant-proxyconf
mkdir -p /etc/default