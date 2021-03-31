# Nova "orphaned" VM

Sometimes (usually due to a compute host being renamed) a VM will be "orphaned" and some operations (usually migrations) will fail.

## Detect

````SQL
SELECT uuid,
       host,
       node
FROM   nova.instances
WHERE  host NOT IN (SELECT host
                    FROM   nova.compute_nodes
                    WHERE  deleted = 0)
        OR node NOT IN (SELECT node
                        FROM   nova.compute_nodes
                        WHERE  deleted = 0);  
````

## Fix

````SQL
UPDATE nova.instances
SET    host = '$CORRECT_HOST',
       node = '$CORRECT_NODE'
WHERE  uuid = '$UUID';

UPDATE neutron.ml2_port_bindings
SET    host = '$CORRECT_HOST',
       profile = ''
WHERE  port_id = '$PORT_UUID';

UPDATE neutron.ml2_port_binding_levels
SET    host = '$CORRECT_HOST'
WHERE  port_id = '$PORT_UUID';  
````
