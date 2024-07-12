 
  select c.host, count(*) cnt, 'Values in sheet_inherited_value but not correctly marked up as is_inherited in sheet_value'
          from (
            select sheet_value_id, app_sid from sheet_inherited_value
            minus
            select sheet_value_id, app_sid
              from sheet_value sv
             where sv.is_inherited = 1
         )x, customer c
          where x.app_sid = c.app_sid
          group by c.host, 'Values in sheet_inherited_value but not correctly marked up as is_inherited in sheet_value';
          
          select c.host, count(*) cnt, 'Values marked up as is_inherited in sheet_value but not present in sheet_inherited_value'
          from (
            select sheet_value_id, sv.app_sid
              from sheet_value sv, sheet s, delegation d, delegation_region dr, delegation_ind di, delegation dc, delegation_region drc, sheet sc
             where sv.is_inherited = 1
               and sv.sheet_id = s.sheet_id
               and s.delegation_sid = d.delegation_sid
               and d.delegation_sid = dr.delegation_sid
               and d.delegation_sid = di.delegation_sid
               and dr.region_sid = sv.region_sid
               and di.ind_sid = sv.ind_sid -- ind + region must still be part of delegation
               and dc.parent_sid = d.delegation_sid -- must have a child sheet still
               and dc.delegation_sid = sc.delegation_sid
               and sc.start_dtm >= s.start_dtm
               and sc.end_dtm <= s.end_dtm
               and dc.delegation_sid = drc.delegation_sid
               and drc.aggregate_to_region_sid = dr.region_sid
             minus
            select sheet_value_id, app_sid from sheet_inherited_value
         )x, customer c
          where x.app_sid = c.app_sid
          group by c.host, 'Values marked up as is_inherited in sheet_value but not present in sheet_inherited_value'; 
          