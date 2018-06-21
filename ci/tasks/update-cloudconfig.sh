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
vault write /concourse/$CONCOURSE_TEAM/bosh_ca_cert value="$BOSH_CA_CERT"
vault write /concourse/$CONCOURSE_TEAM/bosh_environment value=$BOSH_ENVIRONMENT 

bosh interpolate concourse-bosh-deployment/ci/templates/cloud-config.yml \
  -v vcenter_dc1_cluster1=$VCENTER_DC1_CLUSTER1 \
  -v vcenter_dc2_cluster1=$VCENTER_DC2_CLUSTER1 \
  -v bosh_cidr_dc1=$BOSH_CIDR_DC1 \
  -v bosh_internal_gw_dc1=$BOSH_INTERNAL_GW_DC1 \
  -v bosh_dns_dc1="$BOSH_DNS_DC1" \
  -v bosh_network_reserved_dc1="$BOSH_NETWORK_RESERVED_DC1" \
  -v bosh_vcenter_network_name_dc1=$BOSH_VCENTER_NETWORK_NAME_DC1 \
  -v bosh_cidr_dc2=$BOSH_CIDR_DC2 \
  -v bosh_internal_gw_dc2=$BOSH_INTERNAL_GW_DC2 \
  -v bosh_dns_dc2="$BOSH_DNS_DC2" \
  -v bosh_network_reserved_dc2="$BOSH_NETWORK_RESERVED_DC2" \
  -v bosh_vcenter_network_name_dc2=$BOSH_VCENTER_NETWORK_NAME_DC2 > cc.yml

director_name=bosh-$CONCOURSE_TEAM

bosh interpolate concourse-bosh-deployment/ci/templates/cpi-config.yml \
  -v director_name=$director_name \
  -v vcenter_dc1_ip=$VCENTER_DC1_IP \
  -v vcenter_dc1_user=$VCENTER_DC1_USER \
  -v vcenter_dc1_password=$VCENTER_DC1_PASSWORD \
  -v vcenter_dc1_cluster1=$VCENTER_DC1_CLUSTER1 \
  -v vcenter_dc1_datastore=$VCENTER_DC1_DATASTORE \
  -v vcenter_dc1_datacenter=$VCENTER_DC1_DATACENTER \
  -v vcenter_dc2_ip=$VCENTER_DC2_IP \
  -v vcenter_dc2_user=$VCENTER_DC2_USER \
  -v vcenter_dc2_password=$VCENTER_DC2_PASSWORD \
  -v vcenter_dc2_cluster1=$VCENTER_DC2_CLUSTER1 \
  -v vcenter_dc2_datastore=$VCENTER_DC2_DATASTORE \
  -v vcenter_dc2_datacenter=$VCENTER_DC2_DATACENTER > cpi.yml

bosh -n update-cpi-config cpi.yml
bosh -n update-cloud-config cc.yml

