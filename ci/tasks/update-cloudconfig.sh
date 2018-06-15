#!/bin/bash -e

vault read -field=value /concourse/$CONCOURSE_TEAM/bosh_creds > creds.yml
yaml2json < creds.yml > creds.json

export BOSH_CLIENT=
export BOSH_CLIENT_SECRET=
export BOSH_CA_CERT=
export BOSH_ENVIRONMENT=

bosh interpolate concourse-bosh-deployment/ci/templates/cloud-config.yml \
  -v vcenter_dc1_cluster1=$BOSH_DC1_CIDR \
  -v vcenter_dc2_cluster1=$BOSH_DC2_CIDR \
  -v bosh_dc1_cidr=$BOSH_DC1_CIDR \
  -v bosh_dc1_internal_gw=$BOSH_DC1_INTERNAL_GW \
  -v bosh_dc1_dns=$BOSH_DC1_DNS \
  -v bosh_dc1_network_reserved=$BOSH_DC1_NETWORK_RESERVED \
  -v bosh_dc1_vcenter_network_name=$BOSH_DC1_VCENTER_NETWORK_NAME \
  -v bosh_dc2_cidr=$BOSH_DC2_CIDR \
  -v bosh_dc2_internal_gw=$BOSH_DC2_INTERNAL_GW \
  -v bosh_dc2_dns=$BOSH_DC2_DNS \
  -v bosh_dc2_network_reserved=$BOSH_DC2_NETWORK_RESERVED \
  -v bosh_dc1_vcenter_network_name=$BOSH_DC1_VCENTER_NETWORK_NAME > cc.yml

bosh -n update-cloud-config cc.yml

