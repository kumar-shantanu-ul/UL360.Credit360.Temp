-- Please update version.sql too -- this keeps clean builds in sync
define version=28
@update_header

-- Need to do some more work on the actions indicator structure
DECLARE
    v_act_id 			security_pkg.T_ACT_ID;
    v_projects_ind_sid	security_pkg.T_SID_ID;
    v_row				csr.ind%ROWTYPE;
BEGIN
    user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);    
    FOR r IN (
        SELECT DISTINCT c.app_sid, ind_root_sid
          FROM csr.customer c, project p 
         WHERE c.app_sid = p.app_sid
    ) LOOP
    	v_projects_ind_sid := NULL;
    	--
    	IF r.app_sid > 0 THEN
	    	-- Find the actions folder
	    	BEGIN
	        	v_projects_ind_sid := securableobject_pkg.GetSIDFromPath(v_act_id, r.ind_root_sid, 'Actions/Projects');
	        EXCEPTION
	            WHEN security_pkg.OBJECT_NOT_FOUND THEN 
	         		v_projects_ind_sid := NULL;
	        END;
	        -- nothing to do where the folder if not found
	        IF v_projects_ind_sid IS NOT NULL THEN	
	        	-- Rename the SO
	        	security.securableobject_pkg.RenameSO(v_act_id, v_projects_ind_sid, 'Progress');
	        	-- Amend the indicator name (use existing values for everything else)
	        	SELECT *
				 INTO v_row
				 FROM csr.ind
				WHERE ind_sid = v_projects_ind_sid;
	        	csr.indicator_pkg.AmendIndicator(v_act_id, v_projects_ind_sid, 'Progress', 
	        		v_row.active, v_row.measure_sid, v_row.multiplier, v_row.scale, v_row.format_mask, 
	        		v_row.target_direction, v_row.gri, v_row.pos, v_row.info_xml, v_row.divisible, 
	        		v_row.start_month, v_row.ind_type, v_row.aggregate, v_row.aggr_estimate_with_ind_sid);
	        	-- Change the 'name' column (not set by AmendIndicator)
	        	UPDATE csr.ind SET name = 'Progress' WHERE ind_sid = v_projects_ind_sid;
	        END IF;
		END IF;
	END LOOP;
END;
/

COMMIT;

@..\task_body
@..\project_body

@update_tail
