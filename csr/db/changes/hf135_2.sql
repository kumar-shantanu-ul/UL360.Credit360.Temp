-- Please update version.sql too -- this keeps clean builds in sync
--define version=xxxx
--define minor_version=x
--@update_header

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
@../changes/latestDE13520_packages

EXEC security.user_pkg.LogonAdmin('');

DECLARE
	v_act_id 		security.security_pkg.T_ACT_ID;
	v_throwaway_id	NUMBER;
BEGIN
	FOR R IN (
		-- All lower property delegation plans after broken date.
		WITH root_delegs AS (
			SELECT dp.app_sid, dpdrd.maps_to_root_deleg_sid, dpdrd.APPLIED_TO_REGION_SID, dp.deleg_plan_sid, dp.dynamic
			  FROM csr.deleg_plan dp
			  JOIN csr.deleg_plan_col dpc ON dp.app_sid = dpc.app_sid AND dp.deleg_plan_sid = dpc.deleg_plan_sid
			  JOIN csr.deleg_plan_deleg_region dpdr ON dpc.app_sid = dpdr.app_sid AND dpc.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
			  JOIN csr.deleg_plan_deleg_region_deleg dpdrd ON dpdrd.app_sid = dpc.app_sid AND dpc.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpdr.region_sid = dpdrd.region_sid
			 WHERE dp.last_applied_dtm > '25-JUN-20'
			   AND dpdr.region_type = 3
			   AND dpdr.region_selection in ('PT')
		)   
		SELECT dr.app_sid, dr.region_sid, rd.maps_to_root_deleg_sid, rd.deleg_plan_sid, rd.dynamic
		  FROM csr.delegation_region dr
		  JOIN root_delegs rd ON dr.app_sid = rd.app_sid AND dr.delegation_sid = rd.maps_to_root_deleg_sid AND dr.region_sid = rd.APPLIED_TO_REGION_SID
		 WHERE EXISTS (SELECT NULL FROM csr.delegation_region WHERE app_sid = dr.app_sid AND delegation_sid = dr.delegation_sid AND region_sid != dr.region_sid) -- has other regions
		   AND EXISTS ( -- The lower delegations seem to be correct so check if this region is on the sub delegation.
				SELECT NULL 
				  FROM csr.delegation nd
				  JOIN csr.delegation_region ndr ON nd.app_sid = ndr.app_sid AND nd.delegation_sid = ndr.delegation_sid 
				 WHERE nd.app_sid = dr.app_sid AND nd.parent_sid = dr.delegation_sid AND (ndr.region_sid = dr.region_sid OR ndr.aggregate_to_region_sid = dr.region_sid)
			)
	) LOOP
		security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 172800, r.app_sid, v_act_id);
		-- Check the delegation has no data entered for incorrect regions
		FOR s IN (
			SELECT dr.delegation_sid
			  FROM csr.delegation_region dr
			  -- constrain to inds actually part of the delegation
			  LEFT JOIN csr.delegation_ind di ON dr.app_sid = di.app_sid AND dr.delegation_sid = di.delegation_sid
			  -- ignore data for calculated inds
			  LEFT JOIN csr.ind i ON di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid AND i.ind_type = csr.csr_data_pkg.IND_TYPE_NORMAL
			  LEFT JOIN csr.sheet s ON s.app_sid = dr.app_sid AND s.delegation_sid = dr.delegation_sid
			  LEFT JOIN csr.sheet_value sv ON sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id AND sv.region_sid = dr.region_sid AND sv.ind_sid = di.ind_sid
			  LEFT JOIN csr.sheet_value_file svf ON svf.app_sid = sv.app_sid AND svf.sheet_value_id = sv.sheet_value_id
			 WHERE dr.delegation_sid = r.maps_to_root_deleg_sid
			   AND dr.region_sid != r.region_sid
			 GROUP BY dr.delegation_sid
			HAVING SUM(CASE WHEN sv.val_number IS NOT NULL OR NVL(LENGTH(sv.note),0)!=0 OR svf.sheet_value_id IS NOT NULL THEN 1 ELSE 0 END) = 0
		) LOOP
			-- Set the region to the correct region.
			csr.temp_delegation_pkg.SetRegions(
				in_act_id			=> v_act_id,
				in_delegation_sid	=> r.maps_to_root_deleg_sid,
				in_regions_list		=> TO_CHAR(r.region_sid),
				in_mandatory_list	=> ''
			);
			
			-- Remove all other regions to sop this happening again
			DELETE FROM csr.deleg_plan_deleg_region_deleg
			 WHERE maps_to_root_deleg_sid = r.maps_to_root_deleg_sid
			   AND applied_to_region_sid != r.region_sid;
			
			-- Re apply plan to roll our correctly to deleted regions.  
			csr.temp_deleg_plan_pkg.AddApplyPlanJob(
				in_deleg_plan_sid				=> r.deleg_plan_sid,
				in_is_dynamic_plan				=> r.dynamic,
				in_overwrite_dates				=> 0,
				out_batch_job_id				=> v_throwaway_id
			);
		END LOOP;
	END LOOP;
END;
/

EXEC security.user_pkg.LogonAdmin('');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
DROP PACKAGE csr.temp_csr_data_pkg;
DROP PACKAGE csr.temp_batch_job_pkg;
DROP PACKAGE csr.temp_deleg_plan_pkg;
DROP PACKAGE csr.temp_delegation_pkg;

--@update_tail
