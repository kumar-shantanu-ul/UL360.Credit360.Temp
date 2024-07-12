 SELECT *
   FROM (
 SELECT d.*, dr.region_sid deleg_region_sid
   FROM (
        SELECT d.delegation_sid, sv.sheet_value_id, sv.val_number, sv.region_sid
          FROM sheet_value sv, sheet s, delegation d
         where sv.sheet_id = s.sheet_id
           AND s.delegation_sid = d.delegation_sid
        )d, delegation_region dr
 WHERE d.delegation_sid = dr.delegation_sid(+)
   AND d.region_sid = dr.region_sid(+)
)
where deleg_region_sid is null;