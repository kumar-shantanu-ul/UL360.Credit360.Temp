-- Please update version.sql too -- this keeps clean builds in sync
define version=27
@update_header

-- Need to do some more work on the actions indicator structure
DECLARE
    v_act_id 			security_pkg.T_ACT_ID;
    v_actions_ind_sid	security_pkg.T_SID_ID;
    v_projects_ind_sid	security_pkg.T_SID_ID;
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
	        v_actions_ind_sid := securableobject_pkg.GetSIDFromPath(v_act_id, r.ind_root_sid, 'Actions');
	         -- Create project folder
	        BEGIN
	            csr.indicator_pkg.CreateIndicator(
	                v_act_id, v_actions_ind_sid, r.app_sid, 'Projects', 'Projects', 
	                1, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL,
	                1, 1, 0, 'SUM', NULL, v_projects_ind_sid
	            );
	        EXCEPTION
	            WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
	                -- Already exists, get the sid
	                v_projects_ind_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_actions_ind_sid, 'Projects');
	        END;
	        -- Move existing project indicators to the projects folder for this app
		    FOR p IN (
				SELECT ind_sid
				  FROM project
				 WHERE app_sid = r.app_sid
				   AND ind_sid IS NOT NULL
			) LOOP
				csr.indicator_pkg.MoveIndicator(v_act_id, p.ind_sid, v_projects_ind_sid);
			END LOOP;
		END IF;
	END LOOP;
END;
/

COMMIT;

@..\task_body
@..\project_body

@update_tail
