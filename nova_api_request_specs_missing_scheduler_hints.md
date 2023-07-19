# nova_api.request_specs.spec missing instance group uuid scheduler hint

wip

## Detect

````SQL
SELECT nova.instances.uuid,
       nova.instances.display_name,
       nova_api.instance_groups.name group_name,
       nova_api.instance_groups.uuid group_uuid
FROM   nova.instances
      LEFT JOIN nova_api.request_specs
             ON nova.instances.uuid = nova_api.request_specs.instance_uuid
      LEFT JOIN nova_api.instance_group_member
             ON nova.instances.uuid =
                nova_api.instance_group_member.instance_uuid
      LEFT JOIN nova_api.instance_groups
             ON nova_api.instance_group_member.group_id =
                nova_api.instance_groups.id
WHERE  nova_api.instance_groups.uuid IS NOT NULL
      AND
LOCATE(nova_api.instance_groups.uuid, nova_api.request_specs.spec) = 0;  
````

## Fix

wip
