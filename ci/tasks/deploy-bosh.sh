#!/bin/bash -e
set -o pipefail

bosh_state=$(vault read -field=value /concourse/$CONCOURSE_TEAM/bosh_state || true)

if [ "$bosh_state" ]; then
  echo $bosh_state > state.json
fi

error=false
director_name=bosh-$CONCOURSE_TEAM
if ! bosh create-env bosh-deployment/bosh.yml \
    --state=state.json \
    --vars-store=creds.yml \
    -o bosh-deployment/vsphere/cpi.yml \
    -v director_name=$director_name \
    -v internal_cidr=$BOSH_DC1_CIDR \
    -v internal_gw=$BOSH_DC1_INTERNAL_GW \
    -v internal_ip=$BOSH_IP \
    -v network_name="BOSH Network" \
    -v vcenter_dc=$VCENTER_DC1_DATACENTER \
    -v vcenter_ds=$VCENTER_DC1_DATASTORE \
    -v vcenter_ip=$VCENTER_DC1_IP \
    -v vcenter_user=$VCENTER_DC1_USER \
    -v vcenter_password=$VCENTER_DC1_PASSWORD \
    -v vcenter_templates=$director_name-templates \
    -v vcenter_vms=$director_name-vms \
    -v vcenter_disks=$director_name-disks \
    -v vcenter_cluster=$VCENTER_DC1_CLUSTER1
then
	error=true
fi

vault write /concourse/$CONCOURSE_TEAM/bosh_state value=@state.json 

options=$(yaml2json $yaml | jq -r '. | to_entries[] | "\(.key)\t\(.value)"')

while read -r line; do
  array=($line)
  key=${array[0]}
  val=${array[1]}
  if [ "$val" == "null" ]; then
    val=""
  fi  
  vault write /concourse/$CONCOURSE_TEAM/bosh_$key value=$val
done <<< "$options"

if [ "$error" = true ] ; then
	exit 1
fi
