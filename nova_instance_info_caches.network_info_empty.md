# nova.instance_info_caches.network_info empty

Sometimes the record for a VM's network_info in instance_info_caches will be an empty JSON object (`[]`). This will present as the VM having no network interfaces in the output of `nova show` or `openstack server show` but the ports will appear attached when looking at `openstack port list --server $VM_UUID`. The VMs will likely fail to reboot/migrate/etc.

## Detect

````SQL
SELECT nova.instances.uuid,
       nova.instances.display_name,
       nova.instance_info_caches.network_info,
       (SELECT COUNT(id)
        FROM   nova.virtual_interfaces
        WHERE  nova.virtual_interfaces.instance_uuid = nova.instances.uuid) AS
       ports
FROM   nova.instances
       LEFT JOIN nova.instance_info_caches
              ON nova.instances.uuid = nova.instance_info_caches.instance_uuid
WHERE  nova.instance_info_caches.network_info = '[]'
       AND nova.instances.deleted = 0;  
````

## Fix

Options:

1. Delete the interfaces and re-create them. This is the cleanest and easiest way to correct the condition.
2. Re-create the nova.instance_info_caches.network_info JSON object. This can be quite involved.
3. Update the port so that it is detached in the DB and becomes manageable again. Then reattach the port via the API to re-create the nova.instance_info_caches.network_info JSON object.

````SQL
update nova.virtual_interfaces set deleted=1 where instance_uuid='$INSTANCE_UUID' and deleted=0
update neutron.ports set device_id='',device_owner='' where device_id='$INSTANCE_UUID'
````

````
neutron port-update $PORT_ID --admin-state-up False
neutron port-update $PORT_ID --admin-state-up True
nova interface-attach $INSTANCE_UUID --port-id $PORT_ID
````

## Known Issues

If the VM has been rebooted it may have started without a NIC and triggered a libvirt+apparmor bug that will prevent the NIC from being attached with an error like 
````
ERROR (ClientException): Failed to attach network adapter device to 84f4fec3-5f59-4643-af0f-4b06598c2afa (HTTP 500) (Request-ID: req-2ac05793-6a8d-49ec-bd1f-bd72851a8e5f)
````
This can be corrected by adding the line
````
  /dev/vhost-net rw,
````
to the file
````
/etc/apparmor.d/libvirt/libvirt-${VM_UUID}.files
````
Note the lack of quotes surrounding `/dev/vhost-net`. It will differ from other lines in the file. This is expected. Compare it to the file for a working VM if unsure.
