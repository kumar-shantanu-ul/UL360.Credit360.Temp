-- Please update version.sql too -- this keeps clean builds in sync
define version=26
@update_header

-- Add ind sid to project table
ALTER TABLE PROJECT ADD (
	IND_SID	NUMBER(10, 0)	NULL
);

-- Need to do some work on the actions indicator structure
DECLARE
    v_act_id 			security_pkg.T_ACT_ID;
    v_ind_sid 			security_pkg.T_SID_ID;
    v_parent_ind_sid	security_pkg.T_SID_ID;
    v_output_ind_sid	security_pkg.T_SID_ID;
BEGIN
    user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);    
    FOR r IN (
        select distinct c.app_sid, ind_root_sid from csr.customer c, project p where c.app_sid = p.app_sid
    )
    LOOP
    	IF r.app_sid > 0 THEN
	    	-- Find/create actons folder
	        BEGIN
	            v_parent_ind_sid := securableobject_pkg.GetSIDFromPath(v_act_id, r.ind_root_sid, 'Actions');
	        EXCEPTION
	            WHEN security_pkg.OBJECT_NOT_FOUND THEN                
	        		-- Need to create the actions folder
	        		csr.indicator_pkg.CreateIndicator(
	                    v_act_id, r.ind_root_sid, r.app_sid, 'Actions', 'Actions', 
	                    0, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL,
	                    1, 1, 0, 'SUM', NULL, v_parent_ind_sid
	                );
	
	        END;
	        -- Create folders for all existing projects        
	    	FOR p IN (SELECT project_sid, name FROM project WHERE app_sid = r.app_sid)
	    	LOOP
	    		-- Create the porject indicator folder
	    		csr.indicator_pkg.CreateIndicator(
	                v_act_id, v_parent_ind_sid, r.app_sid, SUBSTR(p.name, 0, 255), p.name, 
	                1, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL,
	                1, 1, 0, 'SUM', NULL, v_output_ind_sid
	            );
	            -- Update the project ind sid
	            UPDATE project 
	               SET ind_sid = v_output_ind_sid 
	             WHERE project_sid = p.project_sid;
	    	END LOOP;
		END IF;    	    
	END LOOP;
    -- Move existing action indicators to the correct project folders
    FOR t IN (
		SELECT p.ind_sid project_ind_sid, t.output_ind_sid
		  FROM project p, task t
		 WHERE t.parent_task_sid IS NULL
		   AND p.project_sid = t.project_sid)
	LOOP
		IF t.output_ind_sid IS NOT NULL AND t.project_ind_sid IS NOT NULL THEN
			csr.indicator_pkg.MoveIndicator(v_act_id, t.output_ind_sid, t.project_ind_sid);
		END IF;
	END LOOP;
END;
/

COMMIT;

-- The project ind sids should be set, set the column to not null
ALTER TABLE PROJECT MODIFY (
	IND_SID NUMBER(10, 0) NOT NULL
);

@..\task_body
@..\project_body

@update_tail
