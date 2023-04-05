# Cinder attachment
````SQL
select instance_uuid,volume_id,group_concat(id) as attachment_ids from cinder.volume_attachment where deleted = 0 group by volume_id having (count(id) > 1);
````

# Neutron port binding
````SQL
select port_id,group_concat(host),group_concat(status) from neutron.ml2_port_bindings group by port_id having (count(port_id) > 1);
````
