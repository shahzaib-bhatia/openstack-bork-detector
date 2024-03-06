#!/bin/bash
set -euf
set -o pipefail

WORKDIR="$(dirname $0)/$(date +%F_%T)"

mkdir "${WORKDIR}"
cd "${WORKDIR}"

touch check_hosts.txt

source /root/openrc
HOSTS=$(openstack compute service list --service nova-compute -c Host -f value)

for HOST in ${HOSTS} ; do
  echo "==> ${HOST} <=="
  echo "nova:			                                	libvirt:"
  set +e
  openstack server list --all --host "${HOST}" -c ID -f value | sort > "${HOST}_nova.txt"
  ssh "${HOST}" virsh list --uuid --all 2>&- | grep -v -e '^$' | sort > "${HOST}_libvirt.txt"
  diff -y "${HOST}_nova.txt" "${HOST}_libvirt.txt" || echo ${HOST} >> check_hosts.txt
  set -e
done

set +f
cat *_libvirt.txt | sort | uniq -c | awk '$1 > 1 {print $2}' >> check_vms.txt

for VM in $(cat check_vms.txt) ; do
  grep ${VM} *_nova.txt *_libvirt.txt
done
set -f

mysql -tne 'select instance_uuid,volume_id,group_concat(id) as attachment_ids from cinder.volume_attachment where deleted = 0 group by volume_id having (count(id) > 1);' > check_volumes.txt
cat check_volumes.txt

mysql -tne 'select port_id,group_concat(host),group_concat(status) from neutron.ml2_port_bindings group by port_id having (count(port_id) > 1);' > check_ports.txt
cat check_ports.txt
