-- Please update version.sql too -- this keeps clean builds in sync
define version=3315
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
EXEC security.user_pkg.LogonAdmin('');

DECLARE
	v_act_id 	security.security_pkg.T_ACT_ID;
BEGIN
    FOR R IN (
		-- Find all regions that shouldn't be on the delegation
        SELECT r.app_sid, r.region_sid, dpdrd.maps_to_root_deleg_sid
          FROM csr.deleg_plan_deleg_region dpdr
          JOIN csr.deleg_plan_deleg_region_deleg dpdrd ON dpdrd.app_sid = dpdr.app_sid AND dpdrd.region_sid = dpdr.region_sid AND dpdrd.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
          JOIN csr.delegation_region dr ON dr.delegation_sid = dpdrd.maps_to_root_deleg_sid AND dr.region_sid = dpdrd.applied_to_region_sid AND dr.app_sid = dpdrd.app_sid
          JOIN csr.region r ON r.app_sid = dr.app_sid AND r.region_sid = dr.region_sid
		  JOIN csr.deleg_plan_col dpc ON dpc.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
		  JOIN csr.deleg_plan dp ON dpc.deleg_plan_sid = dp.deleg_plan_sid
         WHERE dpdr.region_selection = 'PT'
           AND EXISTS ( -- We want to make sure that there are multiple items, otherwise we find those correctly rolled out
                SELECT NULL
                  FROM csr.deleg_plan_deleg_region_deleg
                 WHERE  app_sid = dpdrd.app_sid AND maps_to_root_deleg_sid = dpdrd.maps_to_root_deleg_sid AND region_sid = dpdrd.region_sid AND applied_to_region_sid != r.region_sid
            )
           AND EXISTS ( -- There is an item above me with the same region type and tag up to the selected region. 
                SELECT NULL
                  FROM csr.region nr
                 WHERE (dpdr.region_type IS NULL OR region_type = dpdr.region_type)
                   AND (dpdr.tag_id IS NULL OR EXISTS (SELECT NULL FROM csr.region_tag WHERE app_sid = dpdr.app_sid AND tag_id = dpdr.tag_id AND region_sid = nr.region_sid))
                   AND region_sid != r.region_sid -- Not Me
                 START WITH region_sid = r.region_sid AND app_sid = r.app_sid
               CONNECT BY PRIOR parent_sid = region_sid AND PRIOR app_sid = app_sid AND PRIOR region_sid != dpdrd.region_sid -- Stop at selected region
            )
    ) LOOP
		security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 172800, r.app_sid, v_act_id);
		-- Check the delegation has no data entered
		FOR s IN (
			SELECT dr.delegation_sid, dr.region_sid
			  FROM csr.delegation_region dr
			  -- constrain to inds actually part of the delegation
			  LEFT JOIN csr.delegation_ind di ON dr.app_sid = di.app_sid AND dr.delegation_sid = di.delegation_sid
			  -- ignore data for calculated inds
			  LEFT JOIN csr.ind i ON di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid AND i.ind_type = 0 --csr.csr_data_pkg.IND_TYPE_NORMAL
			  LEFT JOIN csr.sheet s ON s.app_sid = dr.app_sid AND s.delegation_sid = dr.delegation_sid
			  LEFT JOIN csr.sheet_value sv ON sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id AND sv.region_sid = dr.region_sid AND sv.ind_sid = di.ind_sid
			  LEFT JOIN csr.sheet_value_file svf ON svf.app_sid = sv.app_sid AND svf.sheet_value_id = sv.sheet_value_id
			 WHERE dr.delegation_sid = r.maps_to_root_deleg_sid
			 GROUP BY dr.delegation_sid, dr.region_sid
			HAVING SUM(CASE WHEN sv.val_number IS NOT NULL OR NVL(LENGTH(sv.note),0)!=0 OR svf.sheet_value_id IS NOT NULL THEN 1 ELSE 0 END) = 0
		) LOOP
			DELETE FROM csr.delegation_region_description
			 WHERE delegation_sid = r.maps_to_root_deleg_sid 
			   AND region_sid = r.region_sid;
			
			DELETE FROM csr.delegation_region
			 WHERE delegation_sid = r.maps_to_root_deleg_sid 
			   AND region_sid = r.region_sid;

			DELETE FROM csr.deleg_plan_deleg_region_deleg
			 WHERE maps_to_root_deleg_sid = r.maps_to_root_deleg_sid
			   AND applied_to_region_sid = r.region_sid;
         END LOOP;  
    END LOOP;
END;
/

EXEC security.user_pkg.LogonAdmin('');
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
