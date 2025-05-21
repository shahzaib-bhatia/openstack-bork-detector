#!/usr/bin/bash

for IFACE in $(cat /sys/class/net/*/bonding/slaves) ; do
  echo "==> ${IFACE} <=="
  source /sys/class/net/${IFACE}/device/uevent
  cat << EOF | tee -a /etc/udev/rules.d/70-persistent-net.rules
SUBSYSTEM=="net", ACTION=="add", KERNELS=="${PCI_SLOT_NAME}", NAME="${IFACE}"
EOF
  udevadm -d test /sys/class/net/${IFACE} 2>&1 | grep ' NAME ' ;
done
