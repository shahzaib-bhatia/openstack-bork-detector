# Nova / Placement mismatch

Sometimes nova and placement might disagree about where a VM lives.

## Detect

````SQL
SELECT DISTINCT nova.instances.uuid,
                nova.instances.node               AS nova_node,
                placement.resource_providers.name AS placement_provider
FROM   nova.instances
       LEFT JOIN placement.allocations
              ON nova.instances.uuid = placement.allocations.consumer_id
       LEFT JOIN placement.resource_providers
              ON placement.allocations.resource_provider_id =
                 placement.resource_providers.id
WHERE  nova.instances.deleted = 0
       AND nova.instances.node != placement.resource_providers.name;  
````

## Fix

````bash
nova-manage placement heal_allocations –verbose
````
