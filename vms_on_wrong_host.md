# Nova reports that a VM is on the incorrect host

Usually this is due to a failed migration

## Detect

If not known, find the VM with:

````shell
virsh dominfo UUID
````

## Fix

````SQL
UPDATE nova.instances
SET    host = '$CORRECT_HOST',
       node = '$CORRECT_NODE'
WHERE  uuid = '$UUID';

UPDATE nova.instances
SET    host = '$CORRECT_HOST',
       node = '$CORRECT_NODE'
WHERE  uuid = '$UUID';

DELETE FROM neutron.ml2_port_bindings
WHERE  status = 'INACTIVE'
       AND port_id = '$PORT_ID';

UPDATE neutron.ml2_port_bindings
SET    host = '$CORRECT_HOST',
       profile = ''
WHERE  port_id = '$PORT_ID';

UPDATE neutron.ml2_port_binding_levels
SET    host = '$CORRECT_HOST'
WHERE  port_id = '$PORT_ID';

DELETE FROM neutron.ml2_port_binding_levels
WHERE  host != '$CORRECT_HOST'
       AND port_id = '$PORT_ID';
````
