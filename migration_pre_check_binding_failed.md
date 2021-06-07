# Migration pre-check error: Binding failed for port 

Sometimes a migration will fail with an error like `Migration pre-check error: Binding failed for port $PORT_ID, please check neutron logs for more information. (HTTP 400) (Request-ID: $REQ_ID)`. This is probably due to a duplicate port binding record.

# Detect

Possible offending ports can be found with the query below that will return all inactive port bindings for ports that also have active port bindings. Note that this condition is expected while migrations are in flight and may also be expected under other circumstanaces.

````SQL
select * from ml2_port_bindings where status = 'INACTIVE' and port_id in (select port_id from ml2_port_bindings where status = 'ACTIVE') ;
````

# Correct

````SQL
delete from ml2_port_bindings where port_id = '$PORT_ID' and host != '$HOST';

delete from ml2_port_binding_levels where port_id = '$PORT_ID' and host != '$HOST';
````
