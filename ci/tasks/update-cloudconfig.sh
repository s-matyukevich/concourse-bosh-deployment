#!/bin/bash -e

vault read -field=value /concourse/$CONCOURSE_TEAM/bosh_creds > creds.yml
yaml2json < creds.yml > creds.json

export BOSH_CLIENT=admin
export BOSH_CLIENT_SECRET=$(cat creds.json  | jq -r ".admin_password")
export BOSH_CA_CERT=$(cat creds.json  | jq -r ".default_ca.ca")
export BOSH_ENVIRONMENT=$BOSH_EXTERNAL_IP

#save creds for next pipelines
vault write /concourse/$CONCOURSE_TEAM/bosh_client value=$BOSH_CLIENT 
vault write /concourse/$CONCOURSE_TEAM/bosh_client_secret value=$BOSH_CLIENT_SECRET 
vault write /concourse/$CONCOURSE_TEAM/bosh_ca_cert value=$BOSH_CA_CERT 
vault write /concourse/$CONCOURSE_TEAM/bosh_environment value=$BOSH_ENVIRONMENT 

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

