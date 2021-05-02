#!/bin/bash

# In AIO testing going from centralized -> distributed worked fine but going
# from distributed -> centralized left some router ports in a state where they'd
# need manual database edits to recover.

# Disabling the ports before converting the routers and restarting the ovs 
# agents afterwards prevented this.


set -euf -o pipefail
set -x

RTRS="$(openstack router list -f value -c ID)"

for RTR in ${RTRS} ; do

  PORTS="$(openstack port list --device-owner network:router_interface_distributed --router ${RTR} -f value -c ID)"

  for PORT in ${PORTS} ; do
    openstack port set --disable ${PORT}
  done

  openstack router set --disable ${RTR}
  openstack router set --centralized ${RTR}
  openstack router set --ha ${RTR}
  openstack router set --enable ${RTR}

  for PORT in ${PORTS} ; do
    openstack port set --enable ${PORT}
  done

  (cd /opt/openstack-ansible/playbooks ; ansible -o neutron_l3_agent -m shell -a "systemctl restart neutron-openvswitch-agent ; systemctl restart neutron-l3-agent")

done
