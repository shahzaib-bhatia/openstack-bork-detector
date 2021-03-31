# Nova "orphaned" VM

Sometimes (usually due to a compute host being renamed) a VM will be "orphaned" and some operations (usually migrations) will fail.

## Detect

````SQL
select
  uuid,
  host,
  node
from
  nova.instances
where
  host not in (
    select host from nova.compute_nodes where deleted=0
  )
or
  node not in (
    select node from nova.compute_nodes where deleted=0
  );
````

## Fix

````SQL
update nova.instances set host='CORRECT_HOST_NAME',node='CORRECT_NODE_NAME' where uuid = 'INSTANCE_UUID';
update neutron.ml2_port_bindings set host='CORRECT_HOST_NAME',profile ='' where port_id = 'INSTANCE_PORT_UUID';
update neutron.ml2_port_binding_levels set host = 'CORRECT_HOST_NAME' where port_id = 'INSTANCE_PORT_UUID';
````
