-- find regions in secondary trees that are linked to more than once. e.g. linking to "Europe", and also "France"
SELECT *
  FROM (
    SELECT NVL(link_to_region_sid, region_sid) resolved_region_sid, region_sid, 
        COUNT(*) OVER (PARTITION BY NVL(link_to_region_sid, region_sid), CONNECT_BY_ROOT region_sid) cnt,
        REPLACE(LTRIM(SYS_CONNECT_BY_PATH(description,''),''),'',' / ') path,         
        CONNECT_BY_ROOT region_sid secondary_tree_root_sid
      FROM region
     START WITH region_sid IN (
        SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 0
     )
    CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
 ) 
WHERE cnt > 1
ORDER BY resolved_region_sid;