# Nova Block Device Mapping has deleted volumes

If deleted volumes show up in "openstack server show" and prevent VMs from starting you might have ghost volumes in nova.block_device_mapping.

## Detect

````SQL
select
  nova.block_device_mapping.id,
  nova.block_device_mapping.volume_id
from nova.block_device_mapping
where 
  nova.block_device_mapping.deleted = 0
  and
  nova.block_device_mapping.volume_id not in (select id from cinder.volumes where deleted = 0);
````

## Fix

````SQL
update
  nova.block_device_mapping
set
  deleted_at = NOW(),
  deleted=id
where
  nova.block_device_mapping.deleted = 0
and
  nova.block_device_mapping.volume_id not in (select id from cinder.volumes where deleted = 0);
````
