#!/bin/bash -e
set -o pipefail

bosh_state=$(vault read -field=value /concourse/$CONCOURSE_TEAM/bosh_state || true)
bosh_creds=$(vault read -field=value /concourse/$CONCOURSE_TEAM/bosh_creds || true)

if [ "$bosh_state" ]; then
  echo "$bosh_state" > state.json
fi

if [ "$bosh_creds" ]; then
  echo "$bosh_creds" > creds.yml 
fi

error=false
director_name=bosh-$CONCOURSE_TEAM
if ! bosh create-env bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o bosh-deployment/vsphere/cpi.yml \
    -o bosh-deployment/uaa.yml \
    -o concourse-bosh-deployment/ci/opfiles/external-ip.yml \
    -o concourse-bosh-deployment/ci/opfiles/set_vm_password.yml \
    -v vm_password=$vm_password \
    -v director_name=$director_name \
    -v internal_cidr=$BOSH_CIDR \
    -v internal_gw=$BOSH_INTERNAL_GW \
    -v internal_ip=$BOSH_INTERNAL_IP \
    -v external_ip=$BOSH_EXTERNAL_IP \
    -v network_name=$BOSH_VCENTER_NETWORK_NAME \
    -v vcenter_dc=$VCENTER_DC1_DATACENTER \
    -v vcenter_ds=$VCENTER_DC1_DATASTORE \
    -v vcenter_ip=$VCENTER_DC1_IP \
    -v vcenter_user=$VCENTER_DC1_USER \
    -v vcenter_password=$VCENTER_DC1_PASSWORD \
    -v vcenter_templates=$director_name-templates1 \
    -v vcenter_vms=$director_name-vms1 \
    -v vcenter_disks=$director_name-disks1 \
    -v vcenter_cluster=$VCENTER_DC1_CLUSTER1
then
	error=true
fi

# save state even in case of an error
vault write /concourse/$CONCOURSE_TEAM/bosh_state value=@state.json 
vault write /concourse/$CONCOURSE_TEAM/bosh_creds value=@creds.yml 

if [ "$error" = true ] ; then
	exit 1
fi

