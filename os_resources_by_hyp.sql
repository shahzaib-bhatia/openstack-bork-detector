-- nova db

SELECT COALESCE(m.value, 'default') AS AZ,
       c.hypervisor_hostname,
       SUM(COALESCE(i.count, 0)) AS VMs,
       SUM(c.vcpus) AS vCPUs,
       SUM(COALESCE(i.vcpus, 0)) AS vCPUS_Used,
       CONCAT(ROUND(SUM(COALESCE(i.vcpus, 0)) / SUM(c.vcpus) * 100, 2), ' %') AS vcpu_util,
       SUM(c.memory_mb) / 1024 AS mem_gb,
       SUM(COALESCE(i.memory_mb, 0)) / 1024 AS mem_gb_alloc,
       SUM(c.free_ram_mb) / 1024 AS memory_gb_free,
       CONCAT(ROUND(SUM(c.memory_mb_used) / SUM(c.memory_mb) * 100, 2), ' %') AS mem_util,
       SUM(c.local_gb) AS disk_gb,
       SUM(c.local_gb_used) disk_gb_used,
       SUM(c.disk_available_least) AS disk_available_least,
       SUM(c.free_disk_gb) AS free_disk_gb,
       CONCAT(ROUND(SUM(c.local_gb_used) / SUM(c.local_gb) * 100, 2), ' %') AS disk_util
FROM nova_api.aggregate_hosts h
JOIN nova_api.aggregate_metadata m ON nova_api.m.aggregate_id = nova_api.h.aggregate_id
AND (m.key = 'availability_zone'
     OR m.key = 'family')
RIGHT JOIN nova.compute_nodes c ON c.hypervisor_hostname = h.host
                                   OR LOCATE(CONCAT(h.host,'.'), c.hypervisor_hostname) = 1
                                   OR LOCATE(CONCAT(c.hypervisor_hostname,'.'), h.host) = 1
LEFT JOIN
  (SELECT host,
          count(host) AS count,
          sum(vcpus) AS vcpus,
          sum(memory_mb) AS memory_mb
   FROM nova.instances
   WHERE deleted = 0
   GROUP BY host) i ON i.host = c.hypervisor_hostname
                       OR LOCATE(CONCAT(i.host,'.'), c.hypervisor_hostname) = 1
                       OR LOCATE(CONCAT(c.hypervisor_hostname,'.'), i.host) = 1
WHERE c.deleted = 0 
GROUP BY az ASC, c.hypervisor_hostname ASC
WITH ROLLUP;

-- placement db

 SELECT (SELECT name
        FROM   placement.resource_providers
        WHERE  id = resource_provider_id)
       AS name,
       (SELECT name
        FROM   placement.resource_classes
        WHERE  id = resource_class_id)
       AS resource,
       (SELECT total
        FROM   placement.inventories
        WHERE  inventories.resource_provider_id =
               allocations.resource_provider_id
               AND inventories.resource_class_id =
       allocations.resource_class_id) AS
       real_total,
       (SELECT total * allocation_ratio
        FROM   placement.inventories
        WHERE  inventories.resource_provider_id =
               allocations.resource_provider_id
               AND inventories.resource_class_id =
       allocations.resource_class_id) AS
       virtual_total,
       SUM(used)
       AS used,
       (SELECT total - SUM(used)
        FROM   placement.inventories
        WHERE  inventories.resource_provider_id =
               allocations.resource_provider_id
               AND inventories.resource_class_id =
       allocations.resource_class_id) AS
       real_available,
       (SELECT ( total * allocation_ratio ) - SUM(used)
        FROM   placement.inventories
        WHERE  inventories.resource_provider_id =
               allocations.resource_provider_id
               AND inventories.resource_class_id =
       allocations.resource_class_id) AS
       virtual_available
FROM   placement.allocations
GROUP  BY resource_class_id,
          resource_provider_id
ORDER  BY name,
          resource ASC;  
