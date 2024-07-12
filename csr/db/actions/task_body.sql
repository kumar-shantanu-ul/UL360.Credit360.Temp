CREATE OR REPLACE PACKAGE BODY ACTIONS.task_Pkg
IS
-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	NULL;
END;

FUNCTION GetAppSid(
	in_task_sid IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
    v_app_sid   security_pkg.T_SID_ID;
BEGIN
    SELECT app_sid
      INTO v_app_sid
      FROM task t
     WHERE t.task_sid = in_task_sid;
       
    RETURN v_app_sid;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS	
    v_name  			VARCHAR2(1024);
    v_count 			NUMBER;
    v_weighting			task.weighting%TYPE;
    v_parent_sid		security_pkg.T_SID_ID;
    v_ind_sid			security_pkg.T_SID_ID;
BEGIN
	-- Get the parent sid and output indicator sid
	BEGIN
		SELECT parent_task_sid, output_ind_sid
		  INTO v_parent_sid, v_ind_sid
		  FROM task	
		 WHERE task_sid = in_sid_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- The task doesn't exist so there's nothing to do
			RETURN;
	END;
	
	v_weighting := NULL;
	IF v_parent_sid IS NOT NULL THEN
		-- Does the parent action have any children 
		-- other than the one to be deleted	
		SELECT COUNT(0)
		  INTO v_count
		  FROM task
		 WHERE NOT task_sid = in_sid_id
		   AND NOT task_sid = v_parent_sid
		  	START WITH parent_task_sid = v_parent_sid
		  	CONNECT BY PRIOR task_sid = parent_task_sid;
	 
	 	-- Get the weighting
	 	SELECT weighting
 	  	  INTO v_weighting 
 	  	  FROM task
 	 	 WHERE task_sid = in_sid_id;
		
		IF v_count = 0 THEN
		 	-- There are no children, just pass the 
		 	-- weighting back up to the parent and mark 
		 	-- the parent as a management type task
		 	UPDATE task
		 	   SET weighting = v_weighting,
		 	   	   action_type = 'M'
		 	 WHERE task_sid = v_parent_sid;
		 	 
		 	-- Clear parent data
		 	-- REALLY CLEAR?
		 	-- ClearTaskData(in_act_id, v_parent_sid);
			
		 	-- Clear the weighting variable so we don't do spreading later
		 	v_weighting := NULL;
		END IF;
	END IF;
	
    SELECT name  
      INTO v_name
      FROM task
     WHERE task_sid = in_sid_id;
     
    csr.csr_data_pkg.WriteAppAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_TASK, GetAppSid(in_sid_id), in_sid_id, 'Action {0} deleted', v_name);
    
     -- Delete metric, 3 passes, NPV, then calculations, then standard metrics
	FOR r IN (
		SELECT from_ind_template_id, inst.ind_sid
		  FROM task_ind_template_instance inst, ind_template it
		 WHERE inst.task_sid = in_sid_id
		   AND it.ind_template_id = inst.from_ind_template_id
		   AND it.is_npv = 1
	) LOOP
		ind_template_pkg.DeleteMetric(in_sid_id, r.from_ind_template_id);
	END LOOP;
	FOR r IN (
		SELECT from_ind_template_id, inst.ind_sid
		  FROM task_ind_template_instance inst, ind_template it
		 WHERE inst.task_sid = in_sid_id
		   AND it.ind_template_id = inst.from_ind_template_id
		   AND it.calculation IS NOT NULL
		   AND it.is_npv = 0
	) LOOP
		ind_template_pkg.DeleteMetric(in_sid_id, r.from_ind_template_id);
	END LOOP;
	FOR r IN (
		SELECT from_ind_template_id, inst.ind_sid
		  FROM task_ind_template_instance inst, ind_template it
		 WHERE inst.task_sid = in_sid_id
		   AND it.ind_template_id = inst.from_ind_template_id
		   AND it.calculation IS NULL
	) LOOP
		ind_template_pkg.DeleteMetric(in_sid_id, r.from_ind_template_id);
	END LOOP;
    
	DELETE FROM TASK_STATUS_HISTORY WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_TAG WHERE TASK_SID = in_sid_id;
	DELETE FROM CSR_TASK_ROLE_MEMBER WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_ROLE_MEMBER WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_COMMENT WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_BUDGET_HISTORY WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_BUDGET_PERIOD WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_INDICATOR WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_PERIOD_OVERRIDE WHERE TASK_SID = in_sid_id;
	DELETE FROM task_period_file_upload WHERE task_sid = in_sid_id;
	DELETE FROM TASK_PERIOD_OVERRIDE WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_RECALC_PERIOD WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_PERIOD WHERE TASK_SID = in_sid_id;
	DELETE FROM AGGR_TASK_PERIOD_OVERRIDE WHERE TASK_SID = in_sid_id;
	DELETE FROM AGGR_TASK_PERIOD WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_RECALC_REGION WHERE TASK_SID = in_sid_id;
	DELETE FROM TASK_REGION WHERE TASK_SID = in_sid_id;
	
	DELETE FROM task_ind_dependency WHERE task_sid = in_sid_id;
	DELETE FROM task_task_dependency WHERE task_sid = in_sid_id;
	DELETE FROM task_task_dependency WHERE depends_on_task_sid = in_sid_id;
	DELETE FROM task_recalc_job WHERE task_sid = in_sid_id;
	DELETE FROM task_file_upload WHERE task_sid = in_sid_id;
	
	DELETE FROM initiative_project_team WHERE task_sid = in_sid_id;
	DELETE FROM initiative_sponsor WHERE task_sid = in_sid_id;
	DELETE FROM initiative_extra_info WHERE task_sid = in_sid_id;
	
	DELETE FROM task_file_upload WHERE task_sid = in_sid_id;
	
	-- Remove issues
	FOR r IN (
		SELECT issue_id
		  FROM csr.issue i, csr.issue_action ia
		 WHERE i.issue_action_id = ia.issue_action_id
		   AND ia.task_sid = in_sid_id
	) LOOP	
		csr.issue_pkg.UNSEC_DeleteIssue(r.issue_id);
	END LOOP;
	
	DELETE FROM csr.issue_action 
	 WHERE task_sid = in_sid_id;
	
	-- Finally remove the task table entry
	DELETE FROM TASK WHERE TASK_SID = in_sid_id;
	
	-- To allow us to delete the indicator we need to 
	-- remove it from the calc dependency table 
	DELETE FROM csr.calc_dependency
	 WHERE ind_sid = v_ind_sid;
	
	-- Delete the indicator associated with this action, 
	-- this will also delete the action's associated data
	IF v_ind_sid IS NOT NULL THEN 
		security.Securableobject_pkg.DeleteSO(in_act_id, v_ind_sid);
	END IF;
	
	-- Final processing
	IF v_parent_sid IS NOT NULL THEN
		-- Do we need to spread the weighting left over from the child
		IF v_weighting IS NOT NULL THEN
			SpreadWeightings(in_act_id, v_parent_sid, v_weighting);
		END IF;
	
		-- We need to update weightings to recmopute indicator calcs etc.
		UpdateWeightings(in_act_id, v_parent_sid);
		
		-- Mark any remaining leaf node data for re-aggregation
		UPDATE task_period
		   SET needs_aggregation = 1
		 WHERE task_sid IN (
			SELECT task_sid
			  FROM task
		  	WHERE CONNECT_BY_ISLEAF = 1
		  	  AND NOT task_sid = v_parent_sid
		    	START WITH task_sid = v_parent_sid
		    	CONNECT BY PRIOR task_sid = parent_task_sid
		);
	END IF;
END;

PROCEDURE MoveObject(
	in_act					IN security_pkg.T_ACT_ID,
	in_task_sid				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
	v_old_parent_project_sid	security_pkg.T_SID_ID;
	v_old_parent_task_sid		security_pkg.T_SID_ID;
	v_output_ind_sid			security_pkg.T_SID_ID;
	v_new_parent_project_sid	security_pkg.T_SID_ID;
	v_new_parent_task_sid		security_pkg.T_SID_ID;
	v_new_parent_ind_sid		security_pkg.T_SID_ID;
BEGIN	
	-- Get current project/parent and output indicator
	SELECT project_sid, parent_task_sid, output_ind_sid
	  INTO v_old_parent_project_sid, v_old_parent_task_sid, v_output_ind_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	
	-- Get the new parent project/task and the new parent output indicator
	SELECT project_sid, task_sid, new_parent_ind_sid
	  INTO v_new_parent_project_sid, v_new_parent_task_sid, v_new_parent_ind_sid
	  FROM (
		SELECT NULL project_sid, task_sid, output_ind_sid new_parent_ind_sid
		  FROM task
		 WHERE task_sid = in_new_parent_sid
		UNION
		SELECT project_sid, NULL task_sid, ind_sid new_parent_ind_sid
		  FROM project
		 WHERE project_sid = in_new_parent_sid
	);
	
	-- Update the task parent (project or task)
	IF v_new_parent_task_sid IS NOT NULL THEN
		UPDATE task
		   SET parent_task_sid = in_new_parent_sid
		 WHERE task_sid = in_task_sid;
	ELSIF v_new_parent_project_sid IS NOT NULL THEN
		UPDATE task
		   SET parent_task_sid = NULL,
		   	   project_sid = v_new_parent_project_sid
		 WHERE task_sid = in_task_sid;
	END IF;
	
	-- move output indicator and update weightings
	csr.indicator_pkg.MoveIndicator(security_pkg.GetACT, v_output_ind_sid, v_new_parent_ind_sid);
	UpdateWeightings(security_pkg.GetACT, in_task_sid);
	
	-- TODO: Update weightings on old parent
	IF v_old_parent_task_sid IS NOT NULL THEN
		UpdateWeightings(security_pkg.GetACT, v_old_parent_task_sid);
	END IF;
	
	-- Move associated metrics (ind template instances)
	ind_template_pkg.MoveMetrics(in_task_sid, in_new_parent_sid);
END;

PROCEDURE TrashObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_task_sid		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE CreateTask(
	in_project_sid			    IN	security_pkg.T_SID_ID,
	in_parent_task_sid	        IN	security_pkg.T_SID_ID,
	in_task_status_id		    IN 	task_status.task_status_id%TYPE,
	in_name						IN	TASK.name%TYPE,
	in_start_dtm				IN	TASK.start_dtm%TYPE,
	in_end_dtm					IN	TASK.end_dtm%TYPE,
	in_period_duration	        IN	TASK.period_duration%TYPE,
	in_fields_xml				IN	TASK.fields_xml%TYPE,
	in_is_container			    IN	TASK.is_container%TYPE,
	in_internal_Ref			    IN	TASK.internal_ref%TYPE,
	in_budget					IN	TASK.budget%TYPE,
	in_short_name				IN	TASK.short_name%TYPE,	
	in_input_ind_sid			IN	security_pkg.T_SID_ID,
	in_target_ind_sid			IN	security_pkg.T_SID_ID,
	in_weighting				IN	TASK.weighting%TYPE,
	in_action_type				IN	TASK.action_type%TYPE,
	in_entry_type				IN	TASK.entry_type%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_task_sid					security_pkg.T_SID_ID;
	v_parent_task_sid			security_pkg.T_SID_ID;
	v_top_task_sid				security_pkg.T_SID_ID;
	v_internal_ref            	task.internal_ref%TYPE;
	v_action_ind_sid			security_pkg.T_SID_ID;
	v_weighting					task.weighting%TYPE;
	v_name						task.name%TYPE;
	v_child_count				NUMBER;	
	v_try_count					NUMBER;
	v_try_continue				NUMBER;
	v_actions_v2				NUMBER;
	
	CURSOR c_id IS     
        SELECT next_id
          FROM PROJECT p
         WHERE project_sid = in_project_sid
           FOR UPDATE OF next_id;
    v_id        project.next_id%TYPE;
BEGIN
	v_child_count := -1;
	v_weighting := in_weighting;
	
	-- -ve parent task sid means NULL
	v_parent_task_sid := in_parent_task_sid;
	IF v_parent_task_sid < 0 THEN
		v_parent_task_sid := NULL;
	END IF;
	
	IF v_parent_task_sid IS NOT NULL THEN
		-- How many children does this task have
		SELECT COUNT(0)
		  INTO v_child_count
		  FROM task
		 WHERE parent_task_sid = v_parent_task_sid;
		 
		-- If the parent task doesn't have children at the moment then we need to 
		-- set its weighting to zero and pass that weighting on to the new child
		IF v_child_count = 0 THEN
			-- Get parent weighting and output ind sid
			IF v_weighting IS NULL THEN
				SELECT weighting
				  INTO v_weighting
				  FROM task
				 WHERE task_sid = v_parent_task_sid;
			END IF;	
			
			-- Clear the parent's weighting
			UPDATE task
			   SET weighting = 0,
			   	   action_type = 'A'
			 WHERE task_sid = v_parent_task_sid;
			 
			-- Clear the parent's task_period/csr.val data
			-- REALLY CLEAR?
			--ClearTaskData(in_act_id, v_parent_task_sid);
			
			-- We probably need to reaggregate the whole tree for this action
			-- Find the very top parent task sid
			SELECT task_sid 
			  INTO v_top_task_sid
			  FROM (
			  	SELECT task_sid 
			   	  FROM task 
			  		START WITH task_sid = v_parent_task_sid
			  		CONNECT BY PRIOR parent_task_sid = task_sid
			  	ORDER BY LEVEL DESC)
			WHERE ROWNUM = 1;
			
			-- Update the needs aggregation flag for 
			-- all data for this top level action
			UPDATE task_period
			   SET needs_aggregation = 1
			 WHERE task_sid IN (
				SELECT task_sid
				  FROM task
				  WHERE CONNECT_BY_ISLEAF = 1
				    START WITH task_sid = v_top_task_sid
				    CONNECT BY PRIOR task_sid = parent_task_sid
				);
		END IF;
	END IF;
	
	--***************************************************************
	
	-- If a name collision occurs then use the form "name (n)"
	-- We don't use a null name because we need a valid unique
	-- name for all the indicators created form the indicator templates!
	v_try_count := 1;
	v_try_continue := 1;
	v_name := in_name;
	WHILE v_try_continue <> 0
	LOOP
		BEGIN
			SecurableObject_Pkg.CreateSO(
				security_pkg.GetACT, 
				NVL(v_parent_task_sid, in_project_sid), 
				class_pkg.getClassID('ActionsTask'), 
				SUBSTR(Replace(v_name,'/','\'), 0, 255), 
				v_task_sid);
			v_try_continue := 0;
		EXCEPTION 
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_try_count := v_try_count + 1;
				v_name := in_name || ' (' || v_try_count || ')';
				IF v_try_count > 1000 THEN
					RAISE; -- Possible as the name is truncated to 255 in security
				END IF;
		END;
	END LOOP;
		
	-- set some permissions - the user might have "add children" permissions on parent - we need
	-- to make sure they have write permissions
	acl_pkg.AddACE(
		security_pkg.GetACT, 
		acl_pkg.GetDACLIdForSID(v_task_sid), 
		-1, 
		security_pkg.ACE_TYPE_ALLOW, 
		security_pkg.ACE_FLAG_DEFAULT,
		security_pkg.GetSID, 
		task_pkg.PERMISSION_FULL
	);
	
	v_internal_ref := in_internal_ref;	
	IF in_internal_Ref IS NULL THEN
        -- look up next possible value
        OPEN c_id;
        FETCH c_id INTO v_id;
        UPDATE PROJECT SET next_id = v_id + 1 WHERE CURRENT OF c_id;
        v_internal_ref := v_id;
	END IF;
	
	INSERT INTO TASK
		(task_Sid, project_sid, parent_task_sid, task_status_id, name, 
			start_dtm, end_dtm, fields_xml, is_container, internal_ref, 
			period_duration, budget, short_name, owner_sid, action_type, entry_type)
		VALUES (v_task_sid, in_project_sid, DECODE(in_parent_task_sid,-1,NULL,in_parent_task_Sid), in_task_status_id, v_name,
			in_start_dtm, in_end_dtm, in_fields_xml, in_is_container, v_internal_ref,
			in_period_duration, in_budget, in_short_name, security_pkg.GetSID, 'A', 'R');		    
	
	--***************************************************************
	
	-- Get actions version flag
	SELECT use_actions_v2
	  INTO v_actions_v2
	  FROM customer_options
	 WHERE app_sid = security_pkg.GetAPP;
	
	-- If this is "old actions" then update the task region with the root region sid
	IF v_actions_v2 = 0 THEN
		INSERT INTO task_region (task_sid, region_sid)
        SELECT v_task_sid, region_root_sid
          FROM csr.customer c
         WHERE c.app_sid = security_pkg.GetAPP;
	END IF;

	-- Update the new task
	UPDATE task
	   SET input_ind_sid = DECODE(UPPER(in_action_type), 'P', in_input_ind_sid, NULL),
	   	   target_ind_sid = DECODE(UPPER(in_action_type), 'P', in_target_ind_sid, NULL),
	   	   weighting = NVL(v_weighting, 0),
	   	   action_type = NVL(in_action_type, 'A'),
	   	   entry_type = NVL(in_entry_type, 'R')
	 WHERE task_sid = v_task_sid;
	 
	-- Right depending on the action type we need to create the output indicator
	-- This process will update the task table with the output ind sid as it is created
	v_action_ind_sid := NULL;
	CreateOutputInd(security_pkg.GetACT, v_task_sid, v_name, in_start_dtm, v_action_ind_sid);
	UpdateWeightings(security_pkg.GetACT, v_task_sid);
	
	-- Insert dependencies if required
	-- Insert job if required
	IF UPPER(in_action_type) = 'P' THEN
		IF in_input_ind_sid IS NOT NULL THEN
			dependency_pkg.AddIndDependency(security_pkg.GetACT, v_task_sid, in_input_ind_sid);
			dependency_pkg.CreateJobForTask(v_task_sid);
		END IF;
		IF in_target_ind_sid IS NOT NULL THEN
			dependency_pkg.AddIndDependency(security_pkg.GetACT, v_task_sid, in_target_ind_sid);
			dependency_pkg.CreateJobForTask(v_task_sid);
		END IF;
	END IF;
	
	-- Return new task info
	-- Get task returns far too much data for out needs si it's been replaced -> GetTask(security_pkg.GetACT, v_task_sid, out_cur);
	-- NOTE: The selected information is defined by task_pkg.REC_SIMPLE_TASK_INFO, if the data 
	-- we select here changes then the definition of REC_SIMPLE_TASK_INFO must also be updated
	OPEN out_cur FOR
		SELECT task_sid, name, internal_ref
		  FROM task
		 WHERE task_sid = v_task_sid;
	
	-- Write an audit log entry
	csr.csr_data_pkg.WriteAppAuditLogEntry(
		security_pkg.GetACT, 
		csr.csr_data_pkg.AUDIT_TYPE_TASK, 
		security_pkg.GetAPP, 
		v_task_sid, 
		'Action {0} created', 
		v_name
	);
END;

PROCEDURE CreateOutputInd(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_name				IN	task.name%TYPE,
	in_start_dtm		IN	TASK.start_dtm%TYPE,
	out_ind_sid			OUT security_pkg.T_SID_ID
)
AS
	v_parent_task_sid			security_pkg.T_SID_ID;
	v_parent_task_name			task.name%TYPE;
	v_parent_ind_sid			security_pkg.T_SID_ID;
BEGIN
	-- Fetch the parent ind sid if available
	BEGIN
		SELECT parent.task_sid, parent.name, parent.output_ind_sid
		  INTO v_parent_task_sid, v_parent_task_name, v_parent_ind_sid
		  FROM task child, task parent
		 WHERE child.task_sid = in_task_sid
		   AND parent.task_sid = child.parent_task_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_parent_ind_sid := NULL;
	END;
	
	-- If the task has a parent but there is no parent ind then create one
	IF v_parent_task_sid IS NOT NULL AND v_parent_ind_sid IS NULL THEN
		CreateOutputInd(in_act_id, v_parent_task_sid, v_parent_task_name, in_start_dtm, v_parent_ind_sid);
		UPDATE task
		   SET output_ind_sid = v_parent_ind_sid
		 WHERE task_sid = v_parent_task_sid;
	END IF;
	
	-- Still no ind sid, fetch the base path for action indicators
	IF v_parent_ind_sid IS NULL THEN
		-- Get the project indicator sid
		SELECT ind_sid
		  INTO v_parent_ind_sid
		  FROM project p, task t
		 WHERE t.task_sid = in_task_sid
		   AND p.project_sid = t.project_sid;
	END IF;
	  
	-- Now create a new output indicator for the action from the template
	-- Use the ind_template called 'action_progress'
	ind_template_pkg.CreateIndicator('action_progress', v_parent_ind_sid, in_start_dtm, in_name, out_ind_sid);	
	
	-- Update the task with the new name and sid
	UPDATE task
	   SET output_ind_sid = out_ind_sid
	 WHERE task_sid = in_task_sid;
END;

PROCEDURE UpdateWeightings(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_is_script_updated	IN	BOOLEAN	DEFAULT FALSE
)
AS
	v_parent_task_sid		security_pkg.T_SID_ID;
BEGIN
	-- Get the top parent sid
	SELECT task_sid
	  INTO v_parent_task_sid
	  FROM task
	 WHERE parent_task_sid IS NULL
	    START WITH task_sid = in_task_sid
	    CONNECT BY PRIOR parent_task_sid = task_sid;
	
	-- Call internal procedure
	Internal_UpdateWeightings(in_act_id, v_parent_task_sid, in_is_script_updated);
END;

-- TODO: 13p fix needed
PROCEDURE Internal_UpdateWeightings(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_task_sid						IN	security_pkg.T_SID_ID,
	in_is_script_updated			IN	BOOLEAN	DEFAULT FALSE
)
AS
	v_parent_task_sid				security_pkg.T_SID_ID;
	v_ind_sid						security_pkg.T_SID_ID;
	v_ind_desc						csr.ind_description.description%TYPE;
	v_interval_months				task.period_duration%TYPE;
	v_period_set_id					csr.ind.period_set_id%TYPE := 1;
	v_period_interval_id			csr.ind.period_interval_id%TYPE;
	v_calc_xml						clob := EMPTY_CLOB;
	v_temp_calc_xml					clob := EMPTY_CLOB;
	v_swap_calc_xml					clob := EMPTY_CLOB;
	v_str 							varchar2(32000);
	v_calc_part						VARCHAR2(512);
	v_wrap_with_add					NUMBER(1);
	v_use_weightings				NUMBER(1);
	v_child_count					NUMBER(10);
	v_avg_calc						VARCHAR2(1024);
	v_val_script_len				NUMBER;
	v_disable_calcs_when_scripted	NUMBER(1);
BEGIN
	-- Get task and ind sids, and interval
	BEGIN
		SELECT t.task_sid, t.output_ind_sid, t.period_duration, i.description, DBMS_LOB.GETLENGTH(t.value_script)
		  INTO v_parent_task_sid, v_ind_sid, v_interval_months, v_ind_desc, v_val_script_len
		  FROM task t, csr.v$ind i
		 WHERE t.task_sid = in_task_sid
		   AND i.ind_sid = t.output_ind_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_ind_sid := NULL;
	END;
	 
	-- Nothing to do if we don't have an ind sid
	IF v_ind_sid IS NULL THEN
		RETURN;
	END IF; 
	
	-- Work out default interval string
	IF v_interval_months = 1 THEN
		v_period_interval_id := 1;
	ELSIF v_interval_months = 3 THEN
		v_period_interval_id := 2;
	ELSIF v_interval_months = 6 THEN
		v_period_interval_id := 3;
	ELSIF v_interval_months = 12 THEN
		v_period_interval_id := 4;
	ELSE
		v_period_interval_id := 4;
	END IF;
	
	-- init LOB for calculation XML - should maybe switch
	-- to building the XML properly with Oracle packages (probably a PITA)
	DBMS_LOB.CREATETEMPORARY( v_calc_xml, true );
	DBMS_LOB.OPEN( v_calc_xml, DBMS_LOB.LOB_READWRITE );
	
	-- Should calcs be generated?
	SELECT disable_calcs_when_scripted
	  INTO v_disable_calcs_when_scripted
	  FROM actions.customer_options;

	-- Don't create calc XML if we have/are saving a script AND 'disable calcs when scripted' = 1
	IF v_disable_calcs_when_scripted = 0 OR (in_is_script_updated AND v_disable_calcs_when_scripted = 1) OR (v_val_script_len IS NULL AND v_disable_calcs_when_scripted = 1) THEN
		DBMS_LOB.CREATETEMPORARY( v_temp_calc_xml, true );
		DBMS_LOB.OPEN( v_temp_calc_xml, DBMS_LOB.LOB_READWRITE );
		
		SELECT show_weightings
		  INTO v_use_weightings
		  FROM customer_options
		 WHERE app_sid = security_pkg.GetAPP;
		
		-- If weightings are turned off then just create an 'average of children calculation' 
		-- unless there are no children in which case remove the calc
		IF v_use_weightings = 0 THEN
			
			SELECT COUNT(*)
			  INTO v_child_count
			  FROM TASK
			 WHERE parent_task_sid = v_parent_task_sid;	
			
			IF v_child_count > 0 THEN
				v_avg_calc := '<average sid="'|| v_ind_sid ||'" description="'|| v_ind_desc ||'" node-id="1" />';
				DBMS_LOB.WRITEAPPEND(v_calc_xml, LENGTH(v_avg_calc), v_avg_calc);
			END IF;
		ELSE
			v_wrap_with_add := 0;
			
			-- Select the children and build the xml string	
			FOR r IN (
				SELECT task_sid, output_ind_sid, action_type,
					CASE WHEN is_leaf = 1 AND SUM(CASE WHEN is_leaf = 1 THEN weighting ELSE 0 END) OVER () = 0 THEN 0 
						 WHEN is_leaf = 1 AND SUM(CASE WHEN is_leaf = 1 THEN weighting ELSE 0 END) OVER () > 0 THEN weighting / SUM(CASE WHEN is_leaf = 1 THEN weighting ELSE 0 END) OVER ()
					ELSE -1 END weighting 
				  FROM (
					SELECT task_sid, action_type, output_ind_sid, level lvl, weighting, CONNECT_BY_ISLEAF is_leaf
					  FROM task
						START WITH task_sid = v_parent_task_sid
						CONNECT BY PRIOR task_sid = parent_task_sid
					)
				 WHERE NOT task_sid = v_parent_task_sid
			) LOOP
				IF r.weighting < 0 THEN
					-- Process children...
					Internal_UpdateWeightings(in_act_id, r.task_sid);
				ELSE
					-- Reset the calc part string
					v_calc_part := '';
				
					-- We have a valid child task, build 
					-- an xml calculation fragment for it
					v_calc_part := v_calc_part || '<multiply>';
					v_calc_part := v_calc_part ||   '<left>';
					v_calc_part := v_calc_part ||     '<path sid="' || r.output_ind_sid || '"/>';
					v_calc_part := v_calc_part ||   '</left>';
					v_calc_part := v_calc_part ||   '<right>';
					v_calc_part := v_calc_part ||     '<literal>' || NVL(r.weighting, 0) || '</literal>';
					v_calc_part := v_calc_part ||   '</right>';
					v_calc_part := v_calc_part || '</multiply>';
			
					-- Wrap existing calculation in a left hand node
					IF NOT v_wrap_with_add = 0 THEN
						-- ick - we've got to insert stuff at the start and at the end				
						dbms_lob.Trim(v_temp_calc_xml, 0); -- clear down our temporary clob
						v_str := '<add><left>'; DBMS_LOB.WRITEAPPEND( v_temp_calc_xml, LENGTH(v_str), v_str );
						-- append what we've built so far
						DBMS_LOB.WRITEAPPEND( v_temp_calc_xml, dbms_lob.getlength(v_calc_xml), v_calc_xml );
						-- now append a terminating tag
						v_str := '</left>'; DBMS_LOB.WRITEAPPEND( v_temp_calc_xml, LENGTH(v_str), v_str );
						-- now swap the lobs over
						v_swap_calc_xml	:= v_calc_xml;
						v_calc_xml := v_temp_calc_xml;
						v_temp_calc_xml := v_swap_calc_xml;
					END IF;
					
					-- Do we need to wrap the fragment we just built?
					IF NOT v_wrap_with_add = 0 THEN
						v_calc_part := '<right>' || v_calc_part || '</right>';
					END IF;
					
					-- Add the fragment we just built to the main calc xml
					DBMS_LOB.WRITEAPPEND( v_calc_xml, LENGTH(v_Calc_part), v_calc_part );
					
					IF NOT v_wrap_with_add = 0 THEN
						v_str := '</add>'; DBMS_LOB.WRITEAPPEND( v_calc_xml, LENGTH(v_str), v_str );
					END IF;
					
					-- Enable "wrap with add" after the first pass
					v_wrap_with_add := 1;
					
					csr.calc_pkg.SetCalcXML(
						in_act_id					=> in_act_id,
						in_calc_ind_sid				=> r.output_ind_Sid,
						in_calc_xml					=> '<nop/>',
						in_is_stored				=> 0,
						in_period_set_id			=> v_period_set_id,
						in_period_interval_id		=> v_period_interval_id,
						in_do_temporal_aggregation	=> 0,
						in_calc_description			=> NULL
					);
				END IF;
			END LOOP;
		END IF;
	END IF;
	
	-- Add the calculation to the indicator
	IF dbms_lob.GetLength(v_calc_xml) > 0 THEN
		-- Set-up the calculation
		csr.calc_pkg.SetCalcXML(
			in_act_id					=> in_act_id,
			in_calc_ind_sid				=> v_ind_sid,
			in_calc_xml					=> v_calc_xml,
			in_is_stored				=> 0,
			in_period_set_id			=> v_period_set_id,
			in_period_interval_id		=> v_period_interval_id,
			in_do_temporal_aggregation	=> 0,
			in_calc_description			=> NULL
		);
		
		-- We have to set-up the calculation dependencies ourselves
		IF v_use_weightings = 0 THEN
			INSERT INTO csr.calc_dependency (calc_ind_sid, ind_sid, dep_type)
			  VALUES (v_ind_sid, v_ind_sid, 2);
		ELSE
			INSERT INTO csr.calc_dependency (calc_ind_sid, ind_sid, dep_type)
				SELECT v_ind_sid, output_ind_sid, 1
				  FROM task
				 WHERE NOT task_sid = v_parent_task_sid
				 START WITH task_sid = v_parent_task_sid
				 CONNECT BY PRIOR task_sid = parent_task_sid;
		END IF;
	ELSE
		csr.calc_pkg.SetCalcXML(
			in_act_id					=> in_act_id,
			in_calc_ind_sid				=> v_ind_sid,
			in_calc_xml					=> '<nop/>',
			in_is_stored				=> 0,
			in_period_set_id			=> v_period_set_id,
			in_period_interval_id		=> v_period_interval_id,
			in_do_temporal_aggregation	=> 0,
			in_calc_description			=> NULL
		);
	END IF;	
END;

PROCEDURE SetTaskStatus(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_task_status_id		IN 	task_status.task_status_id%TYPE,
	in_comment_text			IN	task_status_history.comment_text%TYPE
)
AS
    v_old_label 	task_status.label%TYPE;
    v_label 		task_status.label%TYPE;
BEGIN
--	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, task_Pkg.PERMISSION_CHANGE_STATUS) THEN
--		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting task status');
--	END IF;
	
	-- get previous value
	SELECT ts.label
	  INTO v_old_label
	  FROM task_status ts, task t
	 WHERE ts.task_status_id = t.task_status_id
	   AND task_sid = in_task_sid;
	
	UPDATE TASK 
	   SET TASK_STATUS_ID = in_task_status_id
	 WHERE task_sid = in_task_sid;
	
	AppendTaskStatusHistory(in_task_sid, in_task_status_id, in_comment_text);
	
    -- Get the label for the new status to put into the audit log.
    BEGIN
		SELECT LABEL
		  INTO v_label
		  FROM TASK_STATUS
		 WHERE task_status_id = in_task_status_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_label := NULL;
	END;
	
	IF v_label IS NOT NULL AND v_old_label != v_label THEN	
		csr.csr_data_pkg.WriteAppAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_TASK_STATUS, GetAppSid(in_task_sid), 
		    in_task_sid, 'Status set to {0} - {1}', v_label, in_comment_text);	
	END IF;
END;

PROCEDURE AppendTaskStatusHistory(
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_task_status_id		IN 	task_status.task_status_id%TYPE,
	in_comment_text			IN	task_status_history.comment_text%TYPE
)
AS
	v_old_label 	task_status.label%TYPE;
    v_label 		task_status.label%TYPE;
BEGIN
	INSERT INTO task_status_history
		(task_sid, set_dtm, task_status_id, set_by_user_sid, comment_text, cnt)
	VALUES
		(in_task_sid, SYSDATE, in_task_status_id, security_pkg.GetSID, in_comment_text, cnt_seq.nextval);
END;

PROCEDURE AmendTask (
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_name					IN	TASK.name%TYPE,
	in_start_dtm			IN	TASK.start_dtm%TYPE,
	in_end_dtm				IN	TASK.end_dtm%TYPE,
	in_period_duration		IN	TASK.period_duration%TYPE,
	in_fields_xml			IN	TASK.fields_xml%TYPE,
	in_is_container			IN	TASK.is_container%TYPE,
	in_internal_Ref			IN	TASK.internal_ref%TYPE,
	in_budget				IN	TASK.budget%TYPE,
	in_short_name			IN	TASK.short_name%TYPE,
	in_output_ind_sid		IN	security_pkg.T_SID_ID,
	in_input_ind_sid		IN	security_pkg.T_SID_ID,
	in_target_ind_sid		IN	security_pkg.T_SID_ID,
	in_weighting			IN	TASK.weighting%TYPE,
	in_action_type			IN	TASK.action_type%TYPE,
	in_entry_type			IN	TASK.entry_type%TYPE
)AS
	CURSOR c IS
		SELECT name, project_sid, start_dtm, end_dtm, fields_xml, is_container, internal_ref, period_duration, budget, short_name
		  FROM task
		 WHERE task_sid = in_task_sid
		   FOR UPDATE;
	r	c%ROWTYPE;
	
	v_parent_start_dtm	TASK.start_dtm%TYPE;
	v_parent_end_dtm		TASK.end_dtm%TYPE;
	v_data_start_dtm		TASK_PERIOD.start_dtm%TYPE;
	v_data_end_dtm			TASK_PERIOD.end_dtm%TYPE;
	v_fields_xml			PROJECT.TASK_FIELDS_XML%TYPE;
	v_name					task.name%TYPE;
	v_so_name				security.securable_object.name%TYPE;

	v_output_ind_sid		security_pkg.T_SID_ID;
	v_old_input_ind_sid 	security_pkg.T_SID_ID;
	v_old_target_ind_sid 	security_pkg.T_SID_ID;
	v_add_job				NUMBER;
	v_try_count				NUMBER;
	v_try_continue			NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_task_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to task');
	END IF;
	
	SELECT TRUNC(tp.start_dtm, 'MONTH'), TRUNC(tp.end_dtm, 'MONTH'), t.output_ind_sid
		INTO v_parent_start_dtm, v_parent_end_dtm, v_output_ind_sid
	  FROM TASK t, TASK tp
	 WHERE t.task_sid = in_task_sid
	   AND t.parent_task_sid = tp.task_sid(+);
	   
	IF v_parent_end_dtm IS NOT NULL AND v_parent_start_dtm IS NOT NULL THEN
		IF TRUNC(in_end_dtm, 'MONTH') > v_parent_end_dtm OR TRUNC(in_start_dtm, 'MONTH') < v_parent_start_dtm THEN
			RAISE_APPLICATION_ERROR(project_pkg.ERR_DATES_OUT_OF_RANGE, 'Dates out of range of parent task');
		END IF;
	END IF;
	
	SELECT MIN(start_dtm), MAX(end_dtm)
		INTO v_data_start_dtm, v_data_end_dtm
	  FROM TASK_PERIOD
	 WHERE task_sid = in_task_sid;
	
	-- will changing the dates mess up any task_period data?
	IF v_data_end_dtm IS NOT NULL AND v_data_start_dtm IS NOT NULL THEN
		IF v_data_end_dtm  > in_end_dtm OR v_data_start_dtm < in_start_dtm THEN
			RAISE_APPLICATION_ERROR(project_pkg.ERR_DATES_AFFECT_DATA, 'Dates affect child data');
		END IF;
	END IF;
	
	IF in_name IS NOT NULL THEN
		
		SELECT t.name, so.name
		  INTO v_name, v_so_name
		  FROM task t, security.securable_object so
		 WHERE task_sid = in_task_sid
		   AND so.sid_id = t.task_sid;
		
		-- If the SO name is null then this task has moved and we need to validate 
		-- that the name doesn't clash with any sibling of the new parent
		IF in_name != v_name OR v_so_name IS NULL THEN
			v_try_count := 1;
			v_try_continue := 1;
			v_name := in_name;
			WHILE v_try_continue <> 0
			LOOP
				BEGIN
					SecurableObject_Pkg.RenameSO(security_pkg.GetACT, in_task_sid, SUBSTR(Replace(v_name,'/','\'),0,255));
					IF v_output_ind_sid IS NOT NULL THEN
						SecurableObject_Pkg.RenameSO(security_pkg.GetACT, v_output_ind_sid, SUBSTR(Replace(v_name,'/','\'),0,255));
						csr.indicator_pkg.RenameIndicator(v_output_ind_sid, v_name);
					END IF;
					v_try_continue := 0;
				EXCEPTION 
					WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
						v_try_count := v_try_count + 1;
						v_name := in_name || ' (' || v_try_count || ')';
						IF v_try_count > 1000 THEN
							RAISE; -- Possible as the name is truncated to 255 in security
						END IF;
				END;
			END LOOP;
		END IF;
	END IF;
	
	OPEN c;
	FETCH c INTO r;
	SELECT task_fields_xml 
	  INTO v_fields_xml			
	  FROM project
	 WHERE project_sid = r.project_sid;

	csr.csr_data_pkg.AuditValueChange(security_pkg.GetACT, csr.csr_data_pkg.AUDIT_TYPE_TASK, security_pkg.GetAPP, 
		in_task_sid, 'Name', r.name, v_name);
	csr.csr_data_pkg.AuditValueChange(security_pkg.GetACT, csr.csr_data_pkg.AUDIT_TYPE_TASK, security_pkg.GetAPP, 
		in_task_sid, 'Name', r.short_name, in_short_name);
	csr.csr_data_pkg.AuditValueChange(security_pkg.GetACT, csr.csr_data_pkg.AUDIT_TYPE_TASK, security_pkg.GetAPP, 
		in_task_sid, 'Start date', r.start_dtm, in_start_dtm);
	csr.csr_data_pkg.AuditValueChange(security_pkg.GetACT, csr.csr_data_pkg.AUDIT_TYPE_TASK, security_pkg.GetAPP, 
		in_task_sid, 'End date', r.end_dtm, in_end_dtm);
	csr.csr_data_pkg.AuditValueChange(security_pkg.GetACT, csr.csr_data_pkg.AUDIT_TYPE_TASK, security_pkg.GetAPP, 
		in_task_sid, 'Period duration', r.period_duration, in_period_duration);
	csr.csr_data_pkg.AuditValueChange(security_pkg.GetACT, csr.csr_data_pkg.AUDIT_TYPE_TASK, security_pkg.GetAPP, 
		in_task_sid, 'Internal ref', r.internal_ref, in_internal_ref);
	
	--csr.csr_data_pkg.AuditValueChange(security_pkg.GetACT, csr.csr_data_pkg.AUDIT_TYPE_TASK, security_pkg.GetAPP, 
	--	in_task_sid, 'Budget', r.budget, in_budget);
	/* WARNING!! */
	-- commented out for now as some of this audit info is private data, but some audit info is exposed
	-- via the web interface whistler have.
	-- info xml
	--csr.csr_data_pkg.AuditInfoXmlChanges(security_pkg.GetACT, csr.csr_data_pkg.AUDIT_TYPE_TASK, security_pkg.GetAPP, 
	--	in_task_sid, XmlType(v_fields_xml), XmlType(r.fields_xml), XmlType(in_fields_xml));
	
	IF in_fields_xml IS NULL THEN
		UPDATE TASK
		   SET name = DECODE(v_name, NULL, name, v_name),
	   		start_dtm = DECODE(in_start_dtm, NULL, start_dtm, in_start_dtm),
	   		end_dtm = DECODE(in_end_dtm, NULL, end_dtm, in_end_dtm),
	   		is_container = DECODE(in_is_container, NULL, is_container, in_is_container),
	   		internal_ref = DECODE(in_internal_ref, NULL, internal_ref, in_internal_ref),
	   		period_duration = DECODE(in_period_duration, NULL, period_duration, in_period_duration),
	   		budget = DECODE(in_budget, NULL, budget, in_budget),
	   		short_name = DECODE(in_short_name, NULL, short_name, in_short_name)
		 WHERE CURRENT OF c;
		CLOSE c;
	ELSE
		UPDATE TASK
		   SET name = DECODE(v_name, NULL, name, v_name),
	   		start_dtm = DECODE(in_start_dtm, NULL, start_dtm, in_start_dtm),
	   		end_dtm = DECODE(in_end_dtm, NULL, end_dtm, in_end_dtm),
	   		fields_xml = in_fields_xml,
	   		is_container = DECODE(in_is_container, NULL, is_container, in_is_container),
	   		internal_ref = DECODE(in_internal_ref, NULL, internal_ref, in_internal_ref),
	   		period_duration = DECODE(in_period_duration, NULL, period_duration, in_period_duration),
	   		budget = DECODE(in_budget, NULL, budget, in_budget),
	   		short_name = DECODE(in_short_name, NULL, short_name, in_short_name)
		 WHERE CURRENT OF c;
		CLOSE c;
	END IF;
		
	SELECT input_ind_sid, target_ind_sid
	  INTO v_old_input_ind_sid, v_old_target_ind_sid
	  FROM task
	 WHERE task_sid = in_task_sid;  
		
	UPDATE task
	   SET output_ind_sid = NVL(in_output_ind_sid, output_ind_sid),
	   	   weighting = NVL(in_weighting, weighting),
	   	   input_ind_sid = DECODE(UPPER(in_action_type), 'P', in_input_ind_sid, NULL),
	   	   target_ind_sid = DECODE(UPPER(in_action_type), 'P', in_target_ind_sid, NULL),
	   	   action_type = in_action_type,
	   	   entry_type = in_entry_type
	 WHERE task_sid = in_task_sid;
	 
	-- Update dependencies 
	IF v_old_input_ind_sid IS NOT NULL THEN
		dependency_pkg.RemoveIndDependency(security_pkg.GetACT, in_task_sid, v_old_input_ind_sid);
	END IF;
	IF v_old_target_ind_sid IS NOT NULL THEN
		dependency_pkg.RemoveIndDependency(security_pkg.GetACT, in_task_sid, v_old_target_ind_sid);
	END IF;
	
	v_add_job := 0;
	IF UPPER(in_action_type) = 'P' THEN
		IF in_input_ind_sid IS NOT NULL THEN
			dependency_pkg.AddIndDependency(security_pkg.GetACT, in_task_sid, in_input_ind_sid);
			IF v_old_input_ind_sid != in_input_ind_sid THEN
				v_add_job := 1;
			END IF;
		END IF;
		IF in_target_ind_sid IS NOT NULL THEN
			dependency_pkg.AddIndDependency(security_pkg.GetACT, in_task_sid, in_target_ind_sid);
			IF v_old_target_ind_sid != in_target_ind_sid THEN
				v_add_job := 1;
			END IF;
		END IF;
		IF v_add_job != 0 THEN
			dependency_pkg.CreateJobForTask(in_task_sid);
		END IF;
	END IF;	
END;

PROCEDURE SetRelatedIndicators(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_indicator_sids		IN	VARCHAR2
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	DELETE FROM TASK_INDICATOR
	 WHERE TASK_SID = in_task_sid;
	 
	INSERT INTO TASK_INDICATOR
		(task_sid, indicator_sid, priority_level)
	SELECT in_task_sid, t.item, 1
	  FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_indicator_sids,','))t;
END;

PROCEDURE SetRelatedRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_region_sids			IN	VARCHAR2
)
AS
	v_count					NUMBER;
	t_region_sids           T_SPLIT_NUMERIC_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	t_region_sids := UTILS_PKG.SplitNumericString(in_region_sids);
	
	SELECT COUNT (*)
	  INTO v_count
	  FROM (
	  	SELECT item
	  	  FROM TABLE(t_region_sids)
	  	MINUS
	  	SELECT region_sid
	  	  FROM task_region
	  	 WHERE task_sid = in_task_sid	  	
	);
	
	-- delete things not in the list
	DELETE FROM task_recalc_region
	 WHERE task_sid = in_task_sid
	   AND region_sid IN (
		SELECT region_sid
		  FROM task_region
		 WHERE task_sid = in_task_sid
		 MINUS
		SELECT item
		  FROM TABLE (t_region_sids)
	   );
	
	DELETE FROM task_period
	 WHERE task_sid = in_task_sid
	   AND region_sid IN (
		SELECT region_sid
          FROM task_region
         WHERE task_sid = in_task_sid
         MINUS
        SELECT item
		  FROM TABLE (t_region_sids)
	   );
	
	DELETE FROM TASK_REGION
	 WHERE TASK_SID = in_task_sid
	   AND region_sid IN (
	    SELECT region_sid
	  	  FROM task_region
	  	 WHERE task_sid = in_task_sid	
	  	 MINUS
	  	SELECT item
	  	  FROM TABLE(t_region_sids)
	   );
	   
	-- insert new things 
	INSERT INTO TASK_REGION
		(task_sid, region_sid)
	  	SELECT in_task_sid, item 
	  	  FROM TABLE(t_region_sids)
	  	MINUS
	  	SELECT in_task_sid, region_sid
	  	  FROM task_region
	  	 WHERE task_sid = in_task_sid;	
	  		  
	 -- If regions were added then add a task job
	IF v_count > 0 THEN
		dependency_pkg.CreateJobForTask(in_task_sid);
	END IF;
END;

PROCEDURE GetTaskRoleMembers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_project_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	OPEN out_cur FOR
     SELECT prm.role_id, r.NAME role_name, 
		r.permission_set_on_task, r.show_in_filter,
		prm.user_or_group_sid, trm.pos,
       NVL(cu.full_name, so.NAME) user_or_group_name, 
     	DECODE(trm.user_or_group_sid,NULL,0,1) selected 
       FROM PROJECT_ROLE_MEMBER prm, ROLE r, TASK_ROLE_MEMBER trm,
         SECURITY.securable_object SO, csr.CSR_USER cu
      WHERE prm.project_sid = in_project_sid
        AND prm.role_id = r.role_id
        AND prm.project_sid = trm.project_sid(+)
        AND prm.role_id = trm.role_id(+)
        AND prm.user_or_group_sid = trm.user_or_group_sid(+)            
        AND trm.task_sid(+) = NVL(in_task_sid,-1)
        AND prm.user_or_group_sid = so.sid_id  
    	AND prm.user_or_group_sid = cu.csr_user_sid(+)
      ORDER BY role_id, user_or_group_sid;
END;

PROCEDURE SetTaskRoleMembers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_role_id			IN	ROLE.ROLE_ID%TYPE,
	in_sids					IN	VARCHAR2
)
AS
	v_role_name			role.name%TYPE;
	v_project_sid 		security_pkg.T_SID_ID;
	v_cnt				NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, task_Pkg.PERMISSION_ASSIGN_USERS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied assigning users to task');
	END IF;
	SELECT project_sid 
	  INTO v_project_sid
	  FROM TASK 
	 WHERE task_sid = in_task_sid;
	 
	SELECT NAME 
	  INTO v_role_name
	  FROM ROLE
	 WHERE ROLE_ID = in_role_id;
		 
	-- count what's changed
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM (
		SELECT TO_NUMBER(item), trm.user_or_group_sid
		  FROM TABLE(csr.utils_pkg.splitString(in_sids,','))it
              FULL JOIN (
               SELECT user_or_group_sid 
                 FROM TASK_ROLE_MEMBER 
                WHERE TASK_SID = in_task_sid
                  AND PROJECT_SID = v_project_sid 
                  AND role_id = in_role_id
              )trm
             ON it.item = trm.user_or_group_sid
	     WHERE NVL(TO_NUMBER(item),-1) != NVL(trm.user_or_group_sid, -1)
	);
	IF v_cnt != 0 THEN
		csr.csr_data_pkg.WriteAppAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_TASK, GetAppSid(in_task_sid), in_task_sid, 
			'Members for role {0} changed', v_role_name);
	END IF;
		   
	DELETE FROM TASK_ROLE_MEMBER 
	 WHERE TASK_SID = in_task_sid
	   AND PROJECT_SID = v_project_sid
	   AND role_id = in_role_id;
	INSERT INTO TASK_ROLE_MEMBER
		(task_sid, project_sid, role_id, user_or_group_sid, pos)
		SELECT in_task_sid, v_project_sid, in_role_id, item, pos 
		  FROM TABLE(csr.utils_pkg.splitString(in_sids,','));
	
	-- figure out what permissions this role_id has on the task	 
	refreshTaskACL(in_act_id, in_task_sid);	  
END;

PROCEDURE FilterRoleUsers(
	in_project_sid	 	IN  security_pkg.T_SID_ID,	 
	in_role_id	 		IN  ROLE.role_id%TYPE,
	in_filter			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
)      
IS
BEGIN
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, cu.full_name 
		  FROM csr.csr_user cu, project_role_member prm, security.user_table ut
		 WHERE LOWER(cu.full_name) LIKE LOWER(in_filter)||'%'
		   AND cu.csr_user_sid = ut.sid_id
		   AND prm.user_or_group_sid = ut.sid_id
		   AND ut.account_enabled = 1 -- only show active users
		   AND prm.user_or_group_sid = cu.csr_user_sid
		   AND prm.role_id = in_role_id
		   AND prm.project_sid = in_project_sid;
END;

FUNCTION ConcatTagIds(
	in_task_sid	IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_s		VARCHAR2(4096);	
	v_sep	VARCHAR2(4096);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (SELECT tag_id FROM TASK_TAG WHERE TASK_SID = in_task_sid)
	LOOP
		v_s := v_s || v_sep || r.tag_id;
		v_sep := ',';
	END LOOP;	
	RETURN v_s;
END;

-- role_id,user_sid,user_sid,user_sid|role_id,user_sid,user_sid...
FUNCTION ConcatRoleIds(
	in_task_sid	IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_s							VARCHAR2(4096);	
	v_sep						VARCHAR2(4096);
	v_last_role_id	ROLE.role_id%TYPE;
BEGIN
	v_s := '';
	v_sep := '';
	v_last_role_id := -1;
	FOR r IN (SELECT role_id, user_or_group_sid FROM TASK_ROLE_MEMBER WHERE TASK_SID = in_task_sid ORDER BY role_id, pos)
	LOOP
		IF v_last_role_id != r.role_id THEN
			v_s := v_s || v_sep || r.role_id;
			v_sep := '|';
		END IF;
		v_s := v_s || ',' || r.user_or_group_sid;
		v_last_role_id := r.role_id;
	END LOOP;	
	RETURN v_s;
END;

FUNCTION FormatPeriod(
	in_start_dtm	IN	DATE,
	in_end_dtm		IN	DATE
) RETURN VARCHAR2
AS
BEGIN
	IF TO_CHAR(in_start_dtm, 'YYYY') = TO_CHAR(in_end_dtm, 'YYYY') THEN
		RETURN TO_CHAR(in_start_dtm, 'Mon')||' - '||TO_CHAR(in_end_dtm-1, 'Mon YYYY');
	ELSE
		RETURN TO_CHAR(in_start_dtm, 'Mon YYYY')||' - '||TO_CHAR(in_end_dtm-1, 'Mon YYYY');
	END IF;
END;

PROCEDURE GetRelatedIndicators(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task');
	END IF;
	
	OPEN out_cur FOR
		SELECT i.ind_sid, i.description
		  FROM task_indicator ti, csr.v$ind i
		 WHERE ti.task_sid = in_task_sid
		   AND ti.indicator_sid = i.ind_sid
		 ORDER BY description;		 
END;

PROCEDURE GetRelatedRegions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task');
	END IF;
	
	OPEN out_cur FOR
		SELECT r.region_sid, r.description
		  FROM task_region tr, csr.v$region r
		 WHERE task_sid = in_task_sid
		   AND tr.region_sid = r.region_sid
		 ORDER BY r.description;
END;

PROCEDURE GetComments(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task');
	END IF;
	
	OPEN out_cur FOR
		SELECT task_comment_id, user_sid, posted_dtm, comment_text, cu.full_name user_name
		  FROM task_comment tc, csr.csr_user cu
		 WHERE task_sid = in_task_sid
		   AND tc.user_Sid = cu.csr_user_sid		   
		 ORDER BY posted_dtm;		 
END;

-- Important, task periods are ordered by start_dtm asc
PROCEDURE GetTaskPeriods(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task');
	END IF;
	
	OPEN out_cur FOR
		SELECT tp.task_period_status_id, tps.label status_label, tps.colour status_colour,
			fields_xml,	start_dtm, end_dtm, task_pkg.FormatPeriod(start_dtm, end_dtm) period, region_sid, 
			-- approved
			approved_dtm, approved_by_sid,  NVL(approved.full_name,'(unknown)') approved_by_name,
			-- entered
			entered_dtm, entered_by_sid, NVL(entered.full_name,'(unknown)') entered_by_name,
			-- public comment
			public_comment_approved_dtm, public_comment_approved_by_sid, public_comment_approved.full_name public_comment_approved_name
	    FROM task_period tp, csr.csr_user approved, csr.csr_user entered, csr.csr_user public_comment_approved,
	    	task_period_status tps
	   WHERE tp.approved_by_sid = approved.csr_user_sid(+)
	     AND tp.entered_by_sid = entered.csr_user_sid(+)
	     AND tp.public_comment_approved_by_sid = public_comment_approved.csr_user_sid(+)	     
	     AND tp.task_period_status_id = tps.task_period_status_Id
	     AND tp.task_sid = in_task_Sid
		 ORDER BY start_dtm;
END;

PROCEDURE GetTaskRegions(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid '||in_task_sid);
	END IF;
		
	-- Fetch all distinct regions right up to the parent task level
	-- Filter out anything not below the user's region mount point
	OPEN out_cur FOR
		SELECT x.region_sid, x.parent_sid, x.name, x.description, x.active, x.pos, x.info_xml
			FROM (
			SELECT r.region_sid, r.parent_sid, r.name, r.description, r.active, 
				    r.pos, extract(r.info_xml,'/').getClobVal() info_xml
			FROM csr.v$region r, (
				SELECT DISTINCT region_sid
				FROM task_region
				    WHERE task_sid IN (
				    SELECT task_sid 
				        FROM task
				        START WITH task_sid = in_task_sid
				        CONNECT BY PRIOR task_sid = parent_task_sid)
				) tr
			WHERE r.region_sid = tr.region_sid
		) x, (
			SELECT sid_id region_sid
				FROM security.securable_object
				START WITH sid_id IN (SELECT region_sid FROM csr.region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
				CONNECT BY PRIOR sid_id = parent_sid_id
		) y
		WHERE x.region_sid = y.region_sid
			ORDER BY x.description;	
END;

PROCEDURE GetTaskRegionsAndParents(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid '||in_task_sid);
	END IF;
	
	-- Fetch all distinct regions right up to the parent task level
	-- and all the parents of those regions
	OPEN out_cur FOR
		SELECT r.region_sid, r.parent_sid, r.name, r.description, r.active, 
		   r.pos, extract(r.info_xml,'/').getClobVal() info_xml
		  FROM csr.v$region r, (
		    SELECT DISTINCT r.region_sid, r.description
		    FROM csr.v$region r
		      START WITH r.region_sid IN (   
		        SELECT r.region_sid
		          FROM csr.region r, (
		          SELECT region_sid
		            FROM task_region
		             WHERE task_sid IN (
		                SELECT task_sid 
		                  FROM task
		                    START WITH task_sid = in_task_sid
		                    CONNECT BY PRIOR task_sid = parent_task_sid)
		          ) tr
		        WHERE r.region_sid = tr.region_sid
		      )
		      CONNECT BY PRIOR r.parent_sid = region_sid
		        ORDER SIBLINGS BY r.description
		    ) p
		  WHERE r.region_sid = p.region_sid;
END;

PROCEDURE AddComment(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_comment_text				IN	TASK_COMMENT.comment_text%TYPE,
	out_task_comment_id			OUT	task_comment.task_comment_id%TYPE
)
AS
BEGIN
--	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, task_Pkg.PERMISSION_ADD_COMMENT) THEN
--		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding comment');
--	END IF;
		
	INSERT INTO TASK_COMMENT
		(task_comment_id, task_sid, user_sid, posted_dtm, comment_text)
	VALUES
		(task_comment_id_seq.nextval, in_task_sid, security_pkg.GetSID, SYSDATE, in_comment_text)
	RETURNING task_comment_id INTO out_task_comment_id;
	
	csr.csr_data_pkg.WriteAppAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_TASK, GetAppSid(in_task_sid), in_task_sid, 'Comment added');
END;

PROCEDURE GetStatusHistory(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task');
	END IF;
	OPEN out_cur FOR
		SELECT task_sid, set_dtm, tsh.task_status_id, ts.LABEL, NVL(cu.full_name,'Administrator') full_name, comment_text
		  FROM task_status_history tsh, csr.csr_user cu, task_status ts 
		 WHERE tsh.set_by_user_sid = cu.csr_user_sid(+)
		   AND ts.task_status_id = tsh.task_status_id
   	       AND task_sid = in_task_sid
		 ORDER BY SET_DTM DESC, cnt DESC;
END;

PROCEDURE GetStatusHistoryInclChildren(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task');
	END IF;
	OPEN out_cur FOR
		SELECT task_sid, set_dtm, tsh.task_status_id, ts.LABEL, NVL(cu.full_name,'Administrator') full_name, comment_text
		  FROM task_status_history tsh, csr.csr_user cu, task_status ts, 
		  	TABLE(securableobject_pkg.GetTreeWithPermAsTable(in_act_id, in_task_sid, security_pkg.PERMISSION_READ)) sec
		 WHERE tsh.set_by_user_sid = cu.csr_user_sid(+)
		   AND ts.task_status_id = tsh.task_status_id
   	       AND task_sid = sec.sid_id
		 ORDER BY task_sid DESC, SET_DTM DESC, cnt DESC;
END;

PROCEDURE GetCommentsInclChildren(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task');
	END IF;
	
	OPEN out_cur FOR
		SELECT task_sid, task_comment_id, user_sid, posted_dtm, comment_text, NVL(cu.full_name, so.NAME) user_name,
			sysdate set_dtm
		  FROM task_comment tc, SECURITY.securable_object SO, csr.CSR_USER cu,
		  	TABLE(securableobject_pkg.GetTreeWithPermAsTable(in_act_id, in_task_sid, security_pkg.PERMISSION_READ)) sec
         WHERE tc.user_Sid = so.sid_id  
	    	AND tc.user_Sid = cu.csr_user_sid(+)
		   AND task_sid = sec.sid_id
		 ORDER BY task_sid, posted_dtm DESC;  
END;

PROCEDURE GetCommentsForApp(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading app');
	END IF;
	
	OPEN out_cur FOR
		SELECT tc.task_sid, task_comment_id, user_sid, posted_dtm, comment_text, NVL(cu.full_name, so.NAME) user_name
		  FROM task_comment tc, SECURITY.securable_object SO, csr.CSR_USER cu, task t, project p
         WHERE tc.user_Sid = so.sid_id  
	    	AND tc.user_Sid = cu.csr_user_sid(+)
			AND tc.task_sid = t.task_sid
			AND t.project_sid = p.project_sid
			AND p.app_sid = in_app_sid
		ORDER BY task_sid, posted_dtm;
END;

PROCEDURE GetRoleMembersInclChildren(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
	   SELECT trm.task_sid, trm.role_id, r.NAME role_name, trm.user_or_group_sid, r.permission_set_on_task,
	       NVL(cu.full_name, so.NAME) user_or_group_name
	       FROM ROLE r, TASK_ROLE_MEMBER trm, PROJECT_ROLE_MEMBER prm,
	         SECURITY.securable_object SO, csr.CSR_USER cu, TASK t
	      WHERE trm.role_id = prm.role_id
	        AND trm.project_sid = prm.project_sid
	        AND trm.task_sid = t.task_sid
	        AND trm.user_or_group_sid = prm.user_or_group_sid
	        AND prm.user_or_group_sid = so.sid_id  
	    	AND prm.user_or_group_sid = cu.csr_user_sid(+)
        	AND prm.role_id = r.role_id
	        AND t.task_sid IN         
			(SELECT task_sid 
				  FROM TASK
				 START WITH task_sid = in_task_sid
				CONNECT BY PRIOR task_sid = parent_task_sid)
	      ORDER BY task_sid, role_id, user_or_group_name;
END;

PROCEDURE GetTaskFromRef(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_project_sid		IN	security_pkg.T_SID_ID,
	in_ref				IN	task.internal_ref%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_task_sid	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT task_sid
		  INTO v_task_sid
		  FROM task
		 WHERE internal_ref = in_ref
		   AND project_sid = in_project_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'No action found with ref '||in_ref||' for parent sid '||in_project_sid);
	END;
	-- this will check permissions
	GetTask(in_act_id, v_task_sid, out_cur);
END;

PROCEDURE GetTask(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid '||in_task_sid);
	END IF;
	OPEN out_cur FOR
		SELECT x.*, y.is_leaf FROM (
			SELECT t.parent_task_sid, tparent.NAME parent_task_name, 
		      	NVL(tparent.start_dtm, p.start_dtm) min_start_dtm, 
		      	NVL(tparent.end_dtm, p.end_dtm) max_end_dtm, 
		        NVL(tparent.period_duration, p.max_period_duration) max_period_duration,
		        p.NAME project_name,
		      	t.project_sid, t.NAME, t.short_name, t.start_dtm, t.end_dtm,
		      	t.internal_ref, t.period_duration, t.budget, t.task_status_id,
		      	t.fields_xml, p.task_fields_xml, p.task_period_fields_xml,
		      	t.task_sid, t.input_ind_sid, t.output_ind_sid, t.target_ind_sid, t.weighting, t.action_type,
		  		task_pkg.ConcatRoleIds(t.task_sid) role_ids, 
		  		task_pkg.ConcatTagIds(t.task_sid) tag_ids,  
		  		task_pkg.FormatPeriod(t.start_dtm, t.end_dtm) period, 
				tp.task_period_status_id, 
				tp.start_dtm task_period_start_dtm, tp.end_dtm task_period_end_dtm,
				task_pkg.FormatPeriod(tp.start_dtm, tp.end_dtm) task_period, tp.region_sid, 
				inputInd.description input_ind_description,
				targetInd.description target_ind_description,
				outputInd.description output_ind_description,
				t.entry_type, t.value_script, t.aggregate_script
			  FROM TASK t, TASK tparent, PROJECT p, TASK_PERIOD tp, csr.v$ind inputInd, csr.v$ind targetInd, csr.v$ind outputInd
			 WHERE t.task_sid = in_task_sid
			   AND tp.task_sid(+) = t.task_sid
			   AND tp.start_dtm(+) = t.last_task_period_dtm 
		       AND t.parent_task_sid = tparent.task_sid(+)
		       AND t.project_sid = p.project_sid
		       AND inputInd.ind_sid(+) = t.input_ind_sid
		       AND targetInd.ind_sid(+) = t.target_ind_sid
		       AND outputInd.ind_sid(+) = t.output_ind_sid
		) x, (
			SELECT task_sid, CONNECT_BY_ISLEAF is_leaf
			  FROM task
			 WHERE task_sid = in_task_sid
				 START WITH task_sid = in_task_sid
				 CONNECT BY PRIOR task_sid = parent_task_sid
		) y
		WHERE x.task_sid = y.task_sid;
END;

PROCEDURE GetTaskChildren(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading parent task with sid '||in_task_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT t.parent_task_sid, tparent.NAME parent_task_name, 
	      	NVL(tparent.start_dtm, p.start_dtm) min_start_dtm, 
	      	NVL(tparent.end_dtm, p.end_dtm) max_end_dtm, 
	        NVL(tparent.period_duration, p.max_period_duration) max_period_duration,
	        p.NAME project_name,
	      	t.project_sid, t.NAME, t.short_name, t.start_dtm, t.end_dtm, t.fields_xml, 
	      	t.internal_ref, t.period_duration, t.budget, t.task_status_id,
	      	t.fields_xml, p.task_fields_xml, p.task_period_fields_xml,
	      	t.task_sid, t.input_ind_sid, t.output_ind_sid, t.target_ind_sid, t.weighting, t.action_type,
	  		task_pkg.ConcatRoleIds(t.task_sid) role_ids, 
	  		task_pkg.ConcatTagIds(t.task_sid) tag_ids,  
	  		task_pkg.FormatPeriod(t.start_dtm, t.end_dtm) period, 
			tp.task_period_status_id, 
			tp.start_dtm task_period_start_dtm, tp.end_dtm task_period_end_dtm,
			task_pkg.FormatPeriod(tp.start_dtm, tp.end_dtm) task_period,
			tp.region_sid
		  FROM TASK t, TASK tparent, PROJECT p, TASK_PERIOD tp
		 WHERE t.parent_task_sid = in_task_sid
		   AND tp.task_sid(+) = t.task_sid
		   AND tp.start_dtm(+) = t.last_task_period_dtm 
	       AND t.parent_task_sid = tparent.task_sid(+)
	       AND t.project_sid = p.project_sid;
END;

PROCEDURE GetTaskChildrenAllPeriods(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading parent task with sid '||in_task_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT t.parent_task_sid, tparent.NAME parent_task_name, 
	      	NVL(tparent.start_dtm, p.start_dtm) min_start_dtm, 
	      	NVL(tparent.end_dtm, p.end_dtm) max_end_dtm, 
	        NVL(tparent.period_duration, p.max_period_duration) max_period_duration,
	        p.NAME project_name,
	      	t.project_sid, t.NAME, t.short_name, t.start_dtm, t.end_dtm, t.fields_xml, 
	      	t.internal_ref, t.period_duration, t.budget, t.task_status_id,
	      	t.fields_xml, p.task_fields_xml, p.task_period_fields_xml,
	      	t.task_sid, t.input_ind_sid, t.output_ind_sid, t.target_ind_sid, t.weighting, t.action_type,
	  		task_pkg.ConcatRoleIds(t.task_sid) role_ids, 
	  		task_pkg.ConcatTagIds(t.task_sid) tag_ids,  
	  		task_pkg.FormatPeriod(t.start_dtm, t.end_dtm) period, 
			tp.task_period_status_id, 
			tp.start_dtm task_period_start_dtm, tp.end_dtm task_period_end_dtm,
			task_pkg.FormatPeriod(tp.start_dtm, tp.end_dtm) task_period,
			tp.region_sid
		  FROM TASK t, TASK tparent, PROJECT p, TASK_PERIOD tp
		 WHERE t.parent_task_sid = in_task_sid
		   AND tp.task_sid(+) = t.task_sid
	       AND t.parent_task_sid = tparent.task_sid(+)
	       AND t.project_sid = p.project_sid;
END;

PROCEDURE GetTasks(
	in_act_id	IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * 
		  FROM ( 
		  	SELECT t.task_sid, t.name, t.task_status_id, 
		  		task_pkg.ConcatRoleIds(t.task_sid) role_ids, 
		  		task_pkg.ConcatTagIds(t.task_sid) tag_ids,  
		  		task_pkg.FormatPeriod(t.start_dtm, t.end_dtm) period, 
		  		t.start_dtm, t.end_dtm, t.period_duration,
		  		internal_ref, budget, t.project_sid, tp.task_period_status_id, 
		  		tp.start_dtm task_period_start_dtm, tp.end_dtm task_period_end_dtm,
		  		task_pkg.FormatPeriod(tp.start_dtm, tp.end_dtm) task_period, tp.region_sid,
		  		t.fields_xml, t.input_ind_sid, t.output_ind_sid, t.target_ind_sid, t.weighting, t.action_type
			  FROM TASK t, TASK_PERIOD tp, PROJECT p
			 WHERE t.project_sid = p.project_Sid
			   AND tp.task_sid(+) = t.task_sid
			   AND tp.start_dtm(+) = t.last_task_period_dtm 
			   AND t.parent_task_sid is null and p.app_sid = in_app_sid
		   )
		 WHERE security_pkg.SQL_IsAccessAllowedSID(in_act_id, task_sid, 1)=1 
		 ORDER BY internal_ref;
END;

PROCEDURE GetTasksAndRegionsForGrdExpt (
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
	  	SELECT t.task_sid, t.name, tr.region_sid
		  FROM task t, task_region tr
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tr.task_sid(+) = t.task_sid
		   AND t.parent_task_sid IS NULL
		   		ORDER BY task_sid, region_sid;		 
END;

PROCEDURE GetTasksInclChildren(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT t.task_sid, t.project_sid, t.parent_task_sid, t.task_status_id, t.NAME, t.created_dtm,
            TO_CHAR(t.created_dtm,'dd Mon yyyy') created_dtm_fmt,
			t.start_dtm, t.end_dtm, t.fields_xml, t.internal_ref, t.period_duration, 
		    t.budget, t.short_name, LEVEL, tp.task_period_status_id last_task_period_status_id,
		    t.input_ind_sid, t.output_ind_sid, t.target_ind_sid, t.weighting, t.action_type,
            security_pkg.SQL_IsAccessAllowedSID(in_act_id, t.task_sid, task_pkg.PERMISSION_ADD_COMMENT) can_add_comment,
            security_pkg.SQL_IsAccessAllowedSID(in_act_id, t.task_sid, task_pkg.PERMISSION_UPDATE_PROGRESS) can_update_progress,
            security_pkg.SQL_IsAccessAllowedSID(in_act_id, t.task_sid, task_pkg.PERMISSION_UPDATE_PROGRESS_XML) can_update_progress_xml,
            security_pkg.SQL_IsAccessAllowedSID(in_act_id, t.task_sid, task_pkg.PERMISSION_APPROVE_PROGRESS) can_approve_progress,
            security_pkg.SQL_IsAccessAllowedSID(in_act_id, t.task_sid, task_pkg.PERMISSION_CHANGE_STATUS) can_change_status,
            security_pkg.SQL_IsAccessAllowedSID(in_act_id, t.task_sid, security_pkg.PERMISSION_WRITE) can_edit,
            security_pkg.SQL_IsAccessAllowedSID(in_act_id, t.task_sid, security_pkg.PERMISSION_ADD_CONTENTS) can_add_tasks,
            security_pkg.SQL_IsAccessAllowedSID(in_act_id, t.task_sid, task_pkg.PERMISSION_ASSIGN_USERS) can_assign_users,
            ConcatTagIds(t.task_sid) tag_ids, tp.region_sid
		  FROM TASK t, TASK_PERIOD tp
		 WHERE security_pkg.SQL_IsAccessAllowedSID(in_act_id, t.task_sid, security_pkg.PERMISSION_READ)=1
		   AND tp.task_sid(+) = t.task_sid
		   AND tp.start_dtm(+) = t.last_task_period_dtm 
		 START WITH t.task_sid = in_task_sid
		CONNECT BY PRIOR t.task_sid = t.parent_task_sid;
END;

PROCEDURE GetTaskPeriodsInclChildren(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	/* security */
	
	OPEN out_cur FOR
		SELECT tp.task_sid, tp.task_period_status_id, tps.LABEL status_label, tps.colour status_colour,
			fields_xml,	start_dtm, end_dtm, task_pkg.FormatPeriod(start_dtm, end_dtm) period, region_sid, 
			-- approved
			approved_dtm, approved_by_sid, NVL(approved.full_name,'(unknown)') approved_by_name,
			-- entered
			entered_dtm, entered_by_sid,  NVL(entered.full_name,'(unknown)') entered_by_name,
			-- public comment
			public_comment_approved_dtm, public_comment_approved_by_sid, public_comment_approved.full_name public_comment_approved_name
	    FROM task_period tp, csr.csr_user approved, csr.csr_user entered, csr.csr_user public_comment_approved, task_period_status tps,
	    	TABLE(securableobject_pkg.GetTreeWithPermAsTable(in_act_id, in_task_sid, security_pkg.PERMISSION_READ)) sec
	   WHERE tp.approved_by_sid = approved.csr_user_sid(+)
	     AND tp.entered_by_sid = entered.csr_user_sid(+)
	     AND tp.public_comment_approved_by_sid = public_comment_approved.csr_user_sid(+)	     
	     AND tp.task_period_status_id = tps.task_period_status_Id
	     AND tp.task_sid = sec.sid_id
		 ORDER BY task_sid, start_dtm;
END;

PROCEDURE GetChartsInclChildren(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task');
	END IF;
	
	OPEN out_cur FOR
		SELECT task_sid, dv.dataview_sid, dv.name 
	      FROM csr.dataview_ind_member dim, csr.dataview dv, task_indicator ti,
	    	   TABLE(securableobject_pkg.GetTreeWithPermAsTable(in_act_id, in_task_sid, security_pkg.PERMISSION_READ)) sec
	     WHERE dv.app_sid = dim.app_sid AND dv.dataview_sid = dim.dataview_sid
	       AND ti.task_sid = sec.sid_id
	       AND ti.app_sid = dim.app_sid AND ti.indicator_sid = dim.ind_sid
	     ORDER BY task_sid, name;
END;

PROCEDURE GetInstancesInclChildren(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task');
	END IF;
	
	OPEN out_cur FOR
		SELECT task_sid, instance_Id, context
	    FROM TASK_INSTANCE,
	    	TABLE(securableobject_pkg.GetTreeWithPermAsTable(in_act_id, in_task_sid, security_pkg.PERMISSION_READ)) sec 
	   WHERE task_sid = sec.sid_id
	   ORDER BY task_sid;
END;

PROCEDURE ClearTaskPeriod(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	task_period.start_dtm%TYPE
)
AS
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, task_Pkg.PERMISSION_UPDATE_PROGRESS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating progress');
	END IF;
	user_pkg.GetSid(in_act_id, v_user_sid);
	DELETE FROM TASK_PERIOD
	 WHERE TASK_SID = in_task_sid
	   AND start_dtm = in_start_dtm;
	-- update to reflect last task period
	UPDATE TASK
	   SET LAST_TASK_PERIOD_DTM = 
	   	(SELECT MAX(START_DTM) FROM TASK_PERIOD WHERE TASK_SID = in_task_sid)
	 WHERE TASK_SID = in_task_sid;
END;  

PROCEDURE ClearTaskPeriod(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm	IN	task_period.start_dtm%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID
)
AS
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, task_Pkg.PERMISSION_UPDATE_PROGRESS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating progress');
	END IF;
	user_pkg.GetSid(in_act_id, v_user_sid);
	DELETE FROM TASK_PERIOD
	 WHERE TASK_SID = in_task_sid
	   AND start_dtm = in_start_dtm
	   AND region_sid = in_region_sid;
	-- update to reflect last task period
	UPDATE TASK
	   SET LAST_TASK_PERIOD_DTM = 
	   	(SELECT MAX(START_DTM) FROM TASK_PERIOD WHERE TASK_SID = in_task_sid)
	 WHERE TASK_SID = in_task_sid;
END;  

PROCEDURE Internal_UpsertTaskPeriodEntry(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE,
	out_old_label        		OUT	TASK_PERIOD_STATUS.LABEL%TYPE
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_fields_xml				task_period.fields_xml%TYPE;
	v_end_dtm					DATE;
	v_period_duration			TASK.period_duration%TYPE;
	v_project_sid				security_pkg.T_SID_ID;
	v_task_end_dtm				TASK.end_dtm%TYPE;
	v_task_start_dtm			TASK.start_dtm%TYPE;
BEGIN
	-- Get the user sid
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	-- Get some information about the task
	SELECT start_dtm, end_dtm, period_duration, project_sid
		INTO v_task_start_dtm, v_task_end_dtm, v_period_duration, v_project_sid
		FROM TASK
	 WHERE task_sid = in_task_sid;
	 
	v_end_dtm := ADD_MONTHS(in_start_dtm, v_period_duration);
	 
	IF v_end_dtm > v_task_end_dtm OR in_start_dtm < v_task_start_dtm THEN
		RAISE_APPLICATION_ERROR(project_pkg.ERR_DATES_OUT_OF_RANGE, 'Dates out of range');
	END IF;
	
	BEGIN	
		INSERT INTO TASK_PERIOD
			(TASK_SID, START_DTM, REGION_SID, PROJECT_SID, TASK_PERIOD_STATUS_ID, END_DTM, 
				FIELDS_XML, ENTERED_DTM, ENTERED_BY_SID)
		VALUES
			(in_task_sid, in_start_dtm, in_region_sid, v_project_sid, in_task_period_status_Id, v_end_dtm,
				in_fields_xml, SYSDATE, v_user_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
            BEGIN
                SELECT label, fields_xml
                  INTO out_old_label, v_fields_xml
                  FROM task_period_status tps, task_period tp
                 WHERE tps.task_period_status_id = tp.task_period_status_id(+)
                   AND task_sid = in_task_sid
                   AND start_dtm = in_start_dtm
                   AND region_sid = in_region_sid;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    out_old_label :=null;
                    v_fields_xml := null;
            END;
			
			UPDATE TASK_PERIOD
			   SET task_period_status_Id = 
			   	-- if null passed then don't change (legacy behaviour), if -1 passed then clear, else set to passed value
			   	DECODE(in_task_period_status_id, NULL, task_period_status_id, -1, NULL, in_task_period_status_id),
			   		fields_xml = NVL(in_fields_xml, v_fields_xml),  -- sometimes this is passed null which means "no change"
			   		entered_dtm = SYSDATE,
			   		entered_by_sid = v_user_sid
			 WHERE task_sid = in_task_sid
			   AND start_dtm = in_start_dtm
			   AND region_sid = in_region_sid;
		
		WHEN PARENT_KEY_NOT_FOUND THEN
			-- This should only be due to the fact that the status was 
			-- cleared for a task period with not existing data so the 
			-- insert statement tried to insert -1 into the task_period_status 
			-- column. We don't actually have to do anything in this case.
			NULL;
	END;
END;

PROCEDURE Internal_UpsertAggrTaskPeriod(
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE
)
AS
	v_end_dtm					DATE;
	v_period_duration			TASK.period_duration%TYPE;
	v_project_sid				security_pkg.T_SID_ID;
	v_task_end_dtm				TASK.end_dtm%TYPE;
	v_task_start_dtm			TASK.start_dtm%TYPE;
BEGIN
	-- Get some information about the task
	SELECT start_dtm, end_dtm, period_duration, project_sid
		INTO v_task_start_dtm, v_task_end_dtm, v_period_duration, v_project_sid
		FROM TASK
	 WHERE task_sid = in_task_sid;
	 
	v_end_dtm := ADD_MONTHS(in_start_dtm, v_period_duration);
	IF v_end_dtm > v_task_end_dtm OR in_start_dtm < v_task_start_dtm THEN
		RAISE_APPLICATION_ERROR(project_pkg.ERR_DATES_OUT_OF_RANGE, 'Dates out of range');
	END IF;
	
	BEGIN	
		INSERT INTO aggr_task_period
			(task_sid, start_dtm, region_sid, project_sid, task_period_status_id, end_dtm,fields_xml)
		VALUES (in_task_sid, in_start_dtm, in_region_sid, v_project_sid, in_task_period_status_Id, v_end_dtm, in_fields_xml);
		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE aggr_task_period
			   SET task_period_status_id = 
					   	-- if null passed then don't change (legacy behaviour), if -1 passed then clear, else set to passed value
					   	DECODE(in_task_period_status_id, NULL, task_period_status_id, -1, NULL, in_task_period_status_id),
			   	   fields_xml = NVL(in_fields_xml, fields_xml)  -- sometimes this is passed null which means "no change"
			 WHERE task_sid = in_task_sid
			   AND start_dtm = in_start_dtm
			   AND region_sid = in_region_sid;
		
		WHEN PARENT_KEY_NOT_FOUND THEN
			-- This should only be due to the fact that the status was 
			-- cleared for a task period with no existing data so the 
			-- insert statement tried to insert -1 into the task_period_status 
			-- column. We don't actually have to do anything in this case.
			NULL;
	END;
END;

PROCEDURE SetTaskPeriodFieldsXmlOnly(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_fields_xml				IN	task_period.fields_xml%TYPE
)
AS
	v_old_label        			TASK_PERIOD_STATUS.LABEL%TYPE;
	v_root_region_sid			security_pkg.T_SID_ID;
	v_region_sid				security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_count						NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, task_Pkg.PERMISSION_UPDATE_PROGRESS_XML) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating progress XML');
	END IF;
	
	-- We need the root region sid
	SELECT p.app_sid
	   INTO v_app_sid
	   FROM project p, task t
	  WHERE t.task_sid = in_task_sid
	    AND p.project_sid = t.project_sid;
	    
	v_root_region_sid := securableobject_pkg.GetSIDFromPath(
	 	in_act_id, v_app_sid, 'Regions');
	
	-- We use the root region sid if one was not specified
	v_region_sid := in_region_sid;
	IF v_region_sid IS NULL OR v_region_sid < 0 THEN
		v_region_sid := v_root_region_sid;
	END IF;
	
	-- Check for regional association
	SELECT COUNT(*)
	  INTO v_count
	  FROM task t, task_region r
	 WHERE t.task_sid = in_task_sid
	   AND r.region_sid = in_region_sid
	   AND r.task_sid = t.task_sid;
	
	IF v_count > 0 THEN
		-- If the action is associated directly with this 
		-- region then upsert into the task period table
		Internal_UpsertTaskPeriodEntry(
			in_act_id, in_task_sid, in_start_dtm, v_region_sid, 
			null,  -- null means don't change the old status
			in_fields_xml, 
			v_old_label);
	ELSE
		-- Otherwise upsert into the aggr_task_period table
		Internal_UpsertAggrTaskPeriod(
			in_task_sid, in_start_dtm, v_region_sid, 
			null,  -- null means don't change the old status
			in_fields_xml);	
	END IF;
END;

PROCEDURE SetTaskPeriodsFromUI(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_start_dtms		IN	T_DATES,
	in_status_ids		IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	-- We assume that all 'arrays' have the same length so we 
	-- can perform checks like this on just one of them
	IF (in_region_sids.COUNT = 0 OR (in_region_sids.COUNT = 1 AND in_region_sids(1) IS NULL)) THEN
		RETURN;
	END IF;

	-- Collect the progress data into a usable structure
	-- ...
	
	DELETE FROM progress_data;

	FOR i IN in_region_sids.FIRST .. in_region_sids.LAST
	LOOP
		INSERT INTO progress_data 
		  (idx, region_sid)
		  	VALUES (i, in_region_sids(i));
	END LOOP;
	
	FOR i IN in_start_dtms.FIRST .. in_start_dtms.LAST
	LOOP
		UPDATE progress_data 
		   SET period_start_dtm = in_start_dtms(i)
		 WHERE idx = i;
	END LOOP;
	
	-- USE THE IND_SID TO STORE THE STATUS ID
	FOR i IN in_status_ids.FIRST .. in_status_ids.LAST
	LOOP
		UPDATE progress_data 
		   SET ind_sid = in_status_ids(i)
		 WHERE idx = i;
	END LOOP;

	-- Update task progress data
	FOR r IN (
		SELECT region_sid, period_start_dtm, ind_sid status_id
		  FROM progress_data
	) LOOP
		SetTaskPeriodFromUI(
			security_pkg.GetAct,
			in_task_sid,
			r.period_start_dtm, 
			r.region_sid,
			NVL(r.status_id, -1), -- If the value is passed it is null then it was cleared (-1 means clear null means don't change).
			NULL, -- TODO: support fields xml too
			NULL, -- Don't specify fraction complete
			'Task period set by initiatives update process'
		);
	END LOOP;
END;

PROCEDURE SetTaskPeriodFromUI(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE,
	in_fraction_complete		IN	NUMBER,	-- (fraction between 0 and 1 indicating completeness where 1.00 is complete)
	in_override_reason			IN	task_period_override.reason%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	v_action_type				task.action_type%TYPE;
	v_count						NUMBER;
BEGIN	
	-- We use the root region sid if one was not specified
	v_region_sid := in_region_sid;
	IF v_region_sid IS NULL OR v_region_sid < 0 THEN
		v_region_sid := securableobject_pkg.GetSIDFromPath(in_act_id, security_pkg.GetAPP, 'Regions');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM task_region
	 WHERE task_sid = in_task_sid
	   AND region_sid = in_region_sid;
	   
	IF v_count > 0 THEN
		-- This is a normal task with associated region, 
		-- override the task_period table entry
		
		-- Set the value
		SetTaskPeriod(in_act_id, in_task_sid, in_start_dtm, in_region_sid, 
			in_task_period_status_id, in_fields_xml, in_fraction_complete);
		
		-- Fetch the action type
		SELECT action_type
		  INTO v_action_type
		  FROM task
		 WHERE task_sid = in_task_sid;
		
		-- If this task is "P" or "A" then this must be a user override
		-- Also clear the override if the status is cleared (in_task_period_status_id is -1)
		IF v_action_type = 'P' OR v_action_type = 'A' OR in_task_period_status_id < 0 THEN
			BEGIN
				INSERT INTO task_period_override
				   (task_sid, start_dtm, region_sid, overridden_by_sid, overridden_dtm, reason)
				   VALUES (in_task_sid, in_start_dtm, v_region_sid, security_pkg.GetSID, SYSDATE, in_override_reason);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE task_period_override
					   SET overridden_by_sid = security_pkg.GetSID,
					   	   overridden_dtm = SYSDATE,
					   	   reason = in_override_reason
					 WHERE task_sid = in_task_sid
					   AND start_dtm = in_start_dtm
					   AND region_sid = v_region_sid;
			END;
		ELSE
			DELETE FROM task_period_override
			 WHERE task_sid = in_task_sid
			   AND start_dtm = in_start_dtm
			   AND region_sid = v_region_sid;
		END IF;		
	ELSE
		-- This is a regionally aggregated value, 
		-- override the aggr_task_period table
		
		-- Set the value
		SetAggrTaskPeriod(in_act_id, in_task_sid, in_start_dtm, in_region_sid, 
			in_task_period_status_id, in_fields_xml, in_fraction_complete);

		-- This will always be an override regardless of 
		-- action type as this is regionally aggregated
		-- so only clear the override is task_period_status_id < 0
		IF in_task_period_status_id > -1 THEN
			BEGIN
				INSERT INTO aggr_task_period_override
				   (task_sid, start_dtm, region_sid, overridden_by_sid, overridden_dtm, reason)
				   VALUES (in_task_sid, in_start_dtm, v_region_sid, security_pkg.GetSID, SYSDATE, in_override_reason);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE aggr_task_period_override
					   SET overridden_by_sid = security_pkg.GetSID,
					   	   overridden_dtm = SYSDATE,
					   	   reason = in_override_reason
					 WHERE task_sid = in_task_sid
					   AND start_dtm = in_start_dtm
					   AND region_sid = v_region_sid;
			END;
		ELSE
			DELETE FROM aggr_task_period_override
			 WHERE task_sid = in_task_sid
			   AND start_dtm = in_start_dtm
			   AND region_sid = v_region_sid;
		END IF;
	END IF;
END;

PROCEDURE SetTaskPeriodUnlessOverridden(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE,
	in_fraction_complete		IN	NUMBER	-- (fraction between 0 and 1 indicating completeness where 1.00 is complete)
)
AS
	v_count						NUMBER;
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	-- We use the root region sid if one was not specified
	v_region_sid := in_region_sid;
	IF v_region_sid IS NULL OR v_region_sid < 0 THEN
		v_region_sid := securableobject_pkg.GetSIDFromPath(in_act_id, security_pkg.GetAPP, 'Regions');
	END IF;

	-- Is the value of this task period overridden?
	SELECT COUNT(*)
	  INTO v_count
	  FROM task_period_override
	 WHERE task_sid = in_task_sid
	   AND start_dtm = in_start_dtm
	   AND region_sid = v_region_sid;

	-- Don't set if the task period is overridden
	IF v_count > 0 THEN
		RETURN;
	END IF;

	-- Ok to set the task period
	SetTaskPeriod(in_act_id, in_task_sid, in_start_dtm, in_region_sid, 
		in_task_period_status_id, in_fields_xml, in_fraction_complete);
	
	-- Update task weightings
	UpdateWeightings(security_pkg.GetAct(), in_task_sid);
END;

PROCEDURE SetTaskPeriod(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE,
	in_fraction_complete		IN	NUMBER	-- (fraction between 0 and 1 indicating completeness where 1.00 is complete)
)
AS
	v_task_period_status_id		task_period.task_period_status_id%TYPE;
	v_end_dtm					task_period.end_dtm%TYPE;
	v_period_duration			TASK.period_duration%TYPE;
	v_old_label        			TASK_PERIOD_STATUS.LABEL%TYPE;
	v_label            			TASK_PERIOD_STATUS.LABEL%TYPE;
	v_root_region_sid			security_pkg.T_SID_ID;
	v_region_sid				security_pkg.T_SID_ID;
	v_app_sid					security_pkg.T_SID_ID;
	v_ind_sid					security_pkg.T_SID_ID;
	v_fraction_complete			NUMBER(24,10);
	v_val_id					csr.val.val_id%TYPE;
	v_action_type				task.action_type%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, task_Pkg.PERMISSION_UPDATE_PROGRESS) THEN
        -- we just check UPDATE_PROGRESS because having this implies that you can update the XML too. Or is this lazy?
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating progress');
	END IF;

	-- We might need to alter this later on
	v_task_period_status_id := in_task_period_status_id;
	
	-- We need the root region sid
	SELECT p.app_sid, UPPER(t.action_type), period_duration
	   INTO v_app_sid, v_action_type, v_period_duration
	   FROM project p, task t
	  WHERE t.task_sid = in_task_sid
	    AND p.project_sid = t.project_sid;
	
	-- Compute end dtm
	v_end_dtm := ADD_MONTHS(in_start_dtm, v_period_duration);
	
	IF csr.csr_data_pkg.IsPeriodLocked(v_app_sid, in_start_dtm, v_end_dtm) =1  THEN
		RETURN; -- don't saved locked values -- TODO: write to log? or will it go mental
	END IF;

	v_root_region_sid := securableobject_pkg.GetSIDFromPath(
	 	in_act_id, v_app_sid, 'Regions');
	
	-- We use the root region sid if one was not specified
	v_region_sid := in_region_sid;
	IF v_region_sid IS NULL OR v_region_sid < 0 THEN
		v_region_sid := v_root_region_sid;
	END IF;
	
	-- Fetch the status id if required
	IF v_task_period_status_id IS NULL THEN
		GetStatusIdFromPctValue(in_act_id, in_task_sid, NVL(in_fraction_complete, 0), v_task_period_status_id);
	END IF;
	
	Internal_UpsertTaskPeriodEntry(
		in_act_id, in_task_sid, in_start_dtm, v_region_sid, 
		v_task_period_status_id, in_fields_xml, v_old_label);
	
	-- update the task to reflect last task period
	IF v_task_period_status_id IS NOT NULL THEN
		UPDATE TASK
		   SET LAST_TASK_PERIOD_DTM = 
		   	(SELECT MAX(START_DTM) FROM TASK_PERIOD WHERE TASK_SID = in_task_sid AND task_period_status_id IS NOT NULL)
		 WHERE TASK_SID = in_task_sid;
		 
		BEGIN
			SELECT label
			  INTO v_label
			  FROM task_period_status
			 WHERE task_period_status_id = v_task_period_status_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_label := '(value cleared)';
		END;
		
		-- Might need recalc jobs as the task status has changed
		dependency_pkg.CreateJobsFromTask(in_act_id, v_app_sid, in_task_sid, in_region_sid, in_start_dtm);
		  
		/* WARNING: we don't audit the FIELDS_XML changes since some of the
		   data might be marked as private, and currently Whistler expose
		   parts of the audit log to the public - probably a bad idea */
		IF v_label != NVL(v_old_label,'(none)') THEN 
			csr.csr_data_pkg.WriteAppAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_TASK_PERIOD, GetAppSid(in_task_sid), in_task_sid, 
		        'Action for period {0} set to "{1}"', TO_CHAR(in_start_dtm, 'Mon yyyy'), v_label);
		END IF;
	END IF;
	
	-- Update the output indicator value for the task, 
	-- this region and the period time span
	SELECT output_ind_sid
	  INTO v_ind_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	
	-- -ve fraction complete means null
	v_fraction_complete := in_fraction_complete;
	IF v_fraction_complete < 0 THEN
		v_fraction_complete := NULL;
	END IF;

	-- If the fraction is not specified then try and get a value from the status
	IF v_fraction_complete IS NULL AND
	   v_task_period_status_id IS NOT NULL AND
	   v_task_period_status_id > -1 THEN
		SELECT means_pct_complete
		  INTO v_fraction_complete
		  FROM task_period_status
		 WHERE task_period_status_id = v_task_period_status_id;
	END IF;
	
	IF v_ind_sid IS NOT NULL AND
	   v_region_sid != v_root_region_sid THEN
		
		IF v_fraction_complete IS NOT NULL THEN
			-- Update val
			csr.indicator_pkg.SetValueWithReason(
				in_act_id, v_ind_sid, v_region_sid, in_start_dtm, 
				v_end_dtm,
				v_fraction_complete, 0, 0, NULL, NULL, NULL, 0,
				'Value changed by Actions.SetTaskPeriod',
				'Value changed by Actions.SetTaskPeriod',
				v_val_id);
		ELSE
			UPDATE csr.val
			   SET val_number = NULL,
			   	   entry_val_number = NULL
			 WHERE ind_sid = v_ind_sid
			   AND region_sid = v_region_sid
			   AND period_start_dtm = in_start_dtm;
		END IF;
		
		-- Task period data needs aggregation
		UPDATE task_period
		   SET needs_aggregation = 1
		 WHERE task_sid = in_task_sid
		   AND start_dtm = in_start_dtm
		   AND region_sid = v_region_sid;
	END IF;
END;

PROCEDURE SetAggrTaskPeriodUnlOverridden(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	task_period.fields_xml%TYPE,
	in_fraction_complete		IN	NUMBER	-- (fraction between 0 and 1 indicating completeness where 1.00 is complete)
)
AS
	v_count						NUMBER;
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	-- We use the root region sid if one was not specified
	v_region_sid := in_region_sid;
	IF v_region_sid IS NULL OR v_region_sid < 0 THEN
		v_region_sid := securableobject_pkg.GetSIDFromPath(in_act_id, security_pkg.GetAPP, 'Regions');
	END IF;

	-- Is the value of this task period overridden?
	SELECT COUNT(*)
	  INTO v_count
	  FROM aggr_task_period_override
	 WHERE task_sid = in_task_sid
	   AND start_dtm = in_start_dtm
	   AND region_sid = v_region_sid;

	-- Don't set if the task period is overridden
	IF v_count > 0 THEN
		RETURN;
	END IF;

	-- Ok to set the task period
	SetAggrTaskPeriod(in_act_id, in_task_sid, in_start_dtm, in_region_sid, 
		in_task_period_status_id, in_fields_xml, in_fraction_complete);
END;

PROCEDURE SetAggrTaskPeriod(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	aggr_task_period.start_dtm%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_task_period_status_id	IN	aggr_task_period.task_period_status_id%TYPE,
	in_fields_xml				IN	aggr_task_period.fields_xml%TYPE,
	in_fraction_complete		IN	NUMBER	-- (fraction between 0 and 1 indicating completeness where 1.00 is complete)
)
AS
	v_app_sid					security_pkg.T_SID_ID;
	v_user_sid					security_pkg.T_SID_ID;
	v_task_period_status_id		task_period.task_period_status_id%TYPE;
	v_period_duration			TASK.period_duration%TYPE;	
	v_root_region_sid			security_pkg.T_SID_ID;
	v_ind_sid					security_pkg.T_SID_ID;
	v_fraction_complete			NUMBER(24,10);
	v_val_id					csr.val.val_id%TYPE;
	v_project_sid				security_pkg.T_SID_ID;
	v_task_end_dtm				TASK.end_dtm%TYPE;
	v_task_start_dtm			TASK.start_dtm%TYPE;
	v_end_dtm					task_period.end_dtm%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, task_Pkg.PERMISSION_UPDATE_PROGRESS) THEN
	    -- we just check UPDATE_PROGRESS because having this implies that you can update the XML too. Or is this lazy?
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating progress');
	END IF;

	-- Get the user sid
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	-- Get some information about the task
	SELECT start_dtm, end_dtm, period_duration, project_sid, output_ind_sid, app_sid
		INTO v_task_start_dtm, v_task_end_dtm, v_period_duration, v_project_sid, v_ind_sid, v_app_sid
		FROM TASK
	 WHERE task_sid = in_task_sid;
	 
	-- Compute end dtm
	v_end_dtm := ADD_MONTHS(in_start_dtm, v_period_duration);
	
	IF csr.csr_data_pkg.IsPeriodLocked(v_app_sid, in_start_dtm, v_end_dtm) =1  THEN
		RETURN; -- don't saved locked values -- TODO: write to log? or will it go mental
	END IF;

	-- Deal with status ID
	v_task_period_status_id := in_task_period_status_id;
	IF v_task_period_status_id < 0 THEN
		v_task_period_status_id := NULL;
	END IF;
	
	IF v_task_period_status_id IS NULL THEN
		GetStatusIdFromPctValue(in_act_id, in_task_sid, NVL(in_fraction_complete, 0), v_task_period_status_id);
	END IF;
	
	-- Deal with fraction complete
	v_fraction_complete := in_fraction_complete;
	IF v_fraction_complete < 0 THEN
		v_fraction_complete := NULL;
	END IF;

	IF v_fraction_complete IS NULL AND
	   v_task_period_status_id IS NOT NULL THEN
		SELECT means_pct_complete
		  INTO v_fraction_complete
		  FROM task_period_status
		 WHERE task_period_status_id = v_task_period_status_id;
	END IF;
	
	-- Update aggr_task_period
	BEGIN
		INSERT INTO aggr_task_period (task_sid, start_dtm, region_sid, project_sid, 
			task_period_status_id, end_dtm, fields_xml, needs_aggregation)
		VALUES (in_task_sid, in_start_dtm, in_region_sid, 
			v_project_sid, v_task_period_status_id, v_end_dtm, in_fields_xml, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE aggr_task_period
			   SET project_sid = v_project_sid,
		   		   task_period_status_id = v_task_period_status_id,
		   		   end_dtm = v_end_dtm,
		   		   fields_xml = NVL(in_fields_xml, fields_xml),  -- sometimes this is passed null which means "no change"
		   		   needs_aggregation = 1
		     WHERE task_sid = in_task_sid 
		       AND start_dtm = in_start_dtm
		       AND region_sid = in_region_sid;
	END;	
	
	IF v_ind_sid IS NOT NULL AND
	   v_fraction_complete IS NOT NULL THEN
		-- Update val
		csr.indicator_pkg.SetValueWithReason(
			in_act_id, v_ind_sid, in_region_sid, in_start_dtm, 
			ADD_MONTHS(in_start_dtm, v_period_duration),
			v_fraction_complete, 0, 0, NULL, NULL, NULL, 0,
			'Value changed by Actions.SetTaskPeriod',
			'Value changed by Actions.SetTaskPeriod',
			v_val_id);
	END IF;
END;

PROCEDURE GetAuditLog(
    in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		    IN	security_pkg.T_SID_ID, 
	in_task_sid		    IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
    v_cnt   NUMBER(10);
BEGIN
    -- bit of belt and braces checking that this is a TASK and for this App
    -- Whistler make their actions audit log quite publicly available so we
    -- really need this
    SELECT COUNT(*) 
      INTO v_cnt
      FROM task t
     WHERE t.task_sid = in_task_sid
       AND t.app_sid = in_app_sid;

	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Task SID not found for this CSR app');
	END IF;

    csr.csr_data_pkg.GetAuditLogForObjectType(in_act_id, in_app_sid,
        in_task_sid, csr.csr_data_pkg.AUDIT_TYPE_TASK, NULL, out_cur);
END;

PROCEDURE GetPeriodAuditLog(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID, 
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
    v_cnt   NUMBER(10);
BEGIN
    -- bit of belt and braces checking that this is a TASK and for this App
    -- Whistler make their actions audit log quite publicly available so we
    -- really need this
    SELECT COUNT(*) 
      INTO v_cnt
      FROM task t
     WHERE t.task_sid = in_task_sid
       AND t.app_sid = in_app_sid;

	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Task SID not found for this CSR app');
	END IF;

    csr.csr_data_pkg.GetAuditLogForObjectType(in_act_id, in_app_sid,
        in_task_sid, csr.csr_data_pkg.AUDIT_TYPE_TASK_PERIOD, NULL, out_cur);
END;

PROCEDURE RefreshTaskACL(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID
)
AS
	v_dacl_id 			Security_Pkg.T_ACL_ID;
	c_aces				SYS_REFCURSOR;
	v_ace_type			Security_Pkg.T_ACE_TYPE;
    v_ace_flags			Security_Pkg.T_ACE_FLAGS;
    v_sid_id			Security_Pkg.T_SID_ID;
    v_permission_set	Security_Pkg.T_PERMISSION;
	v_acl_index			NUMBER(10);
	v_owner_sid			security_pkg.T_SID_ID;
BEGIN
	-- alter permission on tasks
	v_dacl_id := acl_pkg.GetDACLIDForSID(in_task_sid);
	acl_pkg.GetDACL(in_act_id, in_task_sid, c_aces);
	acl_pkg.DeleteAllACEs(in_act_id, v_dacl_id);
	-- delete all ACEs where not inherited
	LOOP
		FETCH c_aces INTO
			v_dacl_id, v_acl_index, v_ace_type, v_ace_flags, v_sid_id, v_permission_set;
		EXIT WHEN c_aces%NOTFOUND;
		-- don't reinsert non-inheritable stuff (assume non-inheritable = manually added by us)
		IF bitand(v_ace_flags, security_pkg.ACE_FLAG_INHERITED) > 0 THEN
			acl_pkg.AddACE(in_act_id, v_dacl_id, -1, v_ace_type, v_ace_flags, v_sid_id, v_permission_set);
		END IF;
	END LOOP;
	-- now reinsert the user_or_groups as non-inheritable
	FOR r IN (
		SELECT trm.user_or_group_sid, bitwise_pkg.bitor(r.permission_set_on_task, security_pkg.PERMISSION_STANDARD_READ) permission_set
		  FROM task_role_member trm, project_role_member prm, project_role pr, ROLE r
		 WHERE trm.task_sid = in_task_sid
		   AND trm.user_or_group_sid = prm.user_or_group_sid
		   AND trm.project_sid = prm.project_sid
		   AND trm.role_id = prm.role_id 
		   AND prm.project_sid = pr.project_sid
		   AND prm.role_id = pr.role_id
		   AND pr.role_id = r.role_id)
	LOOP
		-- insert ACEs as non-inheritable
		acl_pkg.AddACE(in_act_id, v_dacl_id, -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
			r.user_or_group_sid, r.permission_set );
	END LOOP;
	-- if owner_sid != builtin/admin (3) then add that too....	
	-- we don't add builtin/admin since this is going to have permissions
	-- anyway
	SELECT owner_sid 
	  INTO v_owner_sid 
	  FROM task
	 WHERE task_sid = in_task_sid;
	IF v_owner_sid != security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		acl_pkg.AddACE(in_act_id, v_dacl_id, -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
			v_owner_sid, task_pkg.PERMISSION_FULL );
	END IF;
END;

PROCEDURE GetVisibleInfoFields(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_visibility_sid	security_pkg.T_SID_ID;
BEGIN
	-- get securable object Actions
	BEGIN
		v_visibility_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Actions/Visibility');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			-- no node, so just return
			OPEN out_cur FOR
				SELECT NULL sid_id, NULL parent_sid_id, NULL dacl_id, NULL sacl_id, 
					NULL class_id, NULL name, NULL flags, NULL owner
				  FROM DUAL
				 WHERE 1 = 0;
			RETURN;
	END;
	securableobject_pkg.GetChildrenWithPerm(in_act_id, v_visibility_sid, security_pkg.PERMISSION_READ,
		out_cur);
END;

-- TODO should rename as it gets descendants
PROCEDURE GetTaskAndChildren (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid ' || in_task_sid);
	END IF;

	OPEN out_cur FOR
		SELECT LEVEL lvl, t.task_sid, t.project_sid, t.parent_task_sid, t.task_status_id, 
			t.name, t.start_dtm, t.end_dtm, t.fields_xml, t.is_container, t.internal_ref, t.period_duration, 
			t.budget, t.short_name, t.last_task_period_dtm, t.owner_sid, t.created_dtm, t.input_ind_sid, 
			t.target_ind_sid, t.output_ind_sid, t.weighting, t.action_type, t.entry_type,
			TRUNC(SYSDATE, 'MONTH') current_month
	      FROM task t
	     START WITH t.task_sid = in_task_sid
	      CONNECT BY PRIOR t.task_sid = t.parent_task_sid;
END;

-- Important, task periods are ordered by start_dtm asc
PROCEDURE GetTasksAndPeriodsForRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_task			OUT	SYS_REFCURSOR,
	out_period			OUT	SYS_REFCURSOR
)
AS
	v_project_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid ' || in_task_sid);
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region with sid ' || in_region_sid);
	END IF;
	
	-- Get the project sid
	SELECT project_sid 
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	
	-- Get task and it's children
	GetTaskAndChildren(in_act_id, in_task_sid, out_task);
	
	-- Now fetch all the task period information available for this task and all its descendants
	OPEN out_period FOR
		SELECT x.lvl, y.task_sid, y.start_dtm, y.project_sid, y.task_period_status_id, y.end_dtm, 
			y.approved_dtm, y.approved_by_sid, y.public_comment_approved_dtm, y.public_comment_approved_by_sid, 
			y.entered_dtm, y.entered_by_sid, y.fields_xml, y.region_sid,
			y.status_label, y.status_colour, y.status_special_meaning, y.status_means_pct_complete
		  FROM (
			SELECT LEVEL lvl, ROWNUM rn, t.task_sid
			  FROM task t
			 START WITH t.task_sid = in_task_sid
			  CONNECT BY PRIOR t.task_sid = t.parent_task_sid
		) x, (
			SELECT t.task_sid, start_dtm, t.project_sid, t.task_period_status_id, end_dtm, approved_dtm, 
				approved_by_sid, public_comment_approved_dtm, public_comment_approved_by_sid, entered_dtm, 
				entered_by_sid, fields_xml, region_sid,
				tps.label status_label, tps.colour status_colour, tps.special_meaning status_special_meaning, 
				tps.means_pct_complete status_means_pct_complete
			  FROM task_period t, task_period_status tps, project_task_period_status ptps
			 WHERE t.project_sid = v_project_sid
			   AND t.region_sid = in_region_sid
			   AND ptps.project_sid(+) = t.project_sid	
			   AND ptps.task_period_status_id(+) = t.task_period_status_id
			   AND tps.task_period_status_id(+) = ptps.task_period_status_id
		) y
		 WHERE y.task_sid = x.task_sid
		 ORDER BY x.rn, y.start_dtm;
END;

PROCEDURE GetTasksAndRegionsForPeriod(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_end_dtm			IN	task_period.end_dtm%TYPE,
	out_task			OUT	SYS_REFCURSOR,
	out_period			OUT	SYS_REFCURSOR
)
AS
	v_project_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid ' || in_task_sid);
	END IF;

	-- Get the project sid
	SELECT project_sid 
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	 
	-- Get task and its children
	GetTaskAndChildren(in_act_id, in_task_sid, out_task);
	
	-- Now fetch all the task period information available for this task and all its descendants
	OPEN out_period FOR
		SELECT x.lvl, y.task_sid, y.start_dtm, y.project_sid, y.task_period_status_id, y.end_dtm, 
			y.approved_dtm, y.approved_by_sid, y.public_comment_approved_dtm, y.public_comment_approved_by_sid, 
			y.entered_dtm, y.entered_by_sid, y.fields_xml, y.region_sid, y.region_name,
			y.status_label, y.status_colour, y.status_special_meaning, y.status_means_pct_complete
			FROM (
			SELECT LEVEL lvl, ROWNUM rn, t.task_sid
				FROM task t
				START WITH t.task_sid = in_task_sid
				CONNECT BY PRIOR t.task_sid = t.parent_task_sid
		) x, (
			SELECT p.task_sid, start_dtm, p.project_sid, p.task_period_status_id, end_dtm, approved_dtm, 
				approved_by_sid, public_comment_approved_dtm, public_comment_approved_by_sid, entered_dtm, 
				entered_by_sid, fields_xml, p.region_sid, r.description region_name,
				tps.label status_label, tps.colour status_colour, tps.special_meaning status_special_meaning, 
				tps.means_pct_complete status_means_pct_complete
				FROM task_period p, csr.v$region r, task_period_status tps, project_task_period_status ptps
				WHERE p.project_sid = v_project_sid
				AND r.region_sid = p.region_sid
				AND ptps.project_sid = p.project_sid
				AND ptps.task_period_status_id = p.task_period_status_id
				AND tps.task_period_status_id = ptps.task_period_status_id
				-- Select anything that falls in the 
				-- scope of the requested time period
				AND p.start_dtm < in_end_dtm
				AND p.end_dtm > in_start_dtm
				ORDER BY r.description
		) y, (
			SELECT sid_id region_sid
				FROM security.securable_object
				START WITH sid_id IN (SELECT region_sid FROM csr.region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
				CONNECT BY PRIOR sid_id = parent_sid_id
		) z
			WHERE y.task_sid = x.task_sid
			AND y.region_sid = z.region_sid
			ORDER BY x.rn;
END;

-- Important, task periods are ordered by start_dtm asc
PROCEDURE GetAggrTaskPeriods(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_project_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid ' || in_task_sid);
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region with sid ' || in_region_sid);
	END IF;
	
	-- Get the project sid
	SELECT project_sid 
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	 
	OPEN out_cur FOR
		SELECT t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id,
           tps.label status_label, tps.colour status_colour, tps.special_meaning status_special_meaning, 
           tps.means_pct_complete status_means_pct_complete, NVL(tp.fields_xml, atp.fields_xml) fields_xml,
           t.region_sid, task_pkg.FormatPeriod(t.start_dtm, t.end_dtm) period,
           tp.approved_dtm, tp.approved_by_sid, NVL(approved.full_name,'(unknown)') approved_by_name,
           tp.entered_dtm, tp.entered_by_sid, NVL(entered.full_name,'(unknown)') entered_by_name,
           public_comment_approved_dtm, public_comment_approved_by_sid, public_comment_approved.full_name public_comment_approved_name
          FROM task_period_status tps, project_task_period_status ptps, task_period tp, aggr_task_period atp, 
             csr.csr_user approved, csr.csr_user entered, csr.csr_user public_comment_approved, (
         		SELECT MIN(priority) OVER (partition by task_sid, region_sid, start_dtm) min_priority, priority,
               		project_sid, task_sid, region_sid, start_dtm, end_dtm, task_period_status_id
           		  FROM (
            		SELECT 1 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
              		  FROM task_period t
             		 WHERE t.project_sid = v_project_sid
               		   AND t.region_sid = in_region_sid
                   	   AND t.task_sid = in_task_sid
                   	   AND task_period_status_id IS NOT NULL
                	UNION ALL
                	SELECT 2 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
                  	  FROM aggr_task_period t
                 	 WHERE t.project_sid = v_project_sid
                   	   AND t.region_sid = in_region_sid
                   	   AND t.task_sid = in_task_sid
                   	   AND task_period_status_id IS NOT NULL
                	UNION ALL
                	SELECT 3 priority, t.project_sid, t.task_sid, v.region_sid, v.period_start_dtm start_dtm, v.period_end_dtm end_dtm,
                    	task_pkg.GetStatusIdFromPctValueFn('', t.task_sid, v.val_number) task_period_status_id    
                 	  FROM task t, csr.val v
                	 WHERE v.ind_sid(+) = t.output_ind_sid
                  	   AND v.region_sid = in_region_sid
                  	   AND val_number IS NOT NULL
                  	   AND t.task_sid = in_task_sid
                 	UNION ALL
                    SELECT 4 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
              		  FROM task_period t
             		 WHERE t.project_sid = v_project_sid
               		   AND t.region_sid = in_region_sid
                   	   AND t.task_sid = in_task_sid
                   	   AND task_period_status_id IS NULL
                   	   AND fields_xml IS NOT NULL
                	UNION ALL
                	SELECT 5 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
                  	  FROM aggr_task_period t
                 	 WHERE t.project_sid = v_project_sid
                   	   AND t.region_sid = in_region_sid
                   	   AND t.task_sid = in_task_sid
                   	   AND task_period_status_id IS NULL
                   	   AND fields_xml IS NOT NULL
	      	     )
	    ) t
	    WHERE priority = min_priority
	      AND ptps.project_sid(+) = t.project_sid	
	      AND ptps.task_period_status_id(+) = t.task_period_status_id
	      AND tps.task_period_status_id(+) = ptps.task_period_status_id
	      AND tp.task_sid(+) = t.task_sid
	      AND tp.region_sid(+) = t.region_sid
	      AND tp.start_dtm(+) = t.start_dtm
	      AND atp.task_sid(+) = t.task_sid
	      AND atp.region_sid(+) = t.region_sid
	      AND atp.start_dtm(+) = t.start_dtm
	      AND tp.approved_by_sid = approved.csr_user_sid(+)
	      AND tp.entered_by_sid = entered.csr_user_sid(+)
	      AND tp.public_comment_approved_by_sid = public_comment_approved.csr_user_sid(+)
	        ORDER BY start_dtm;
END;

-- Important, task periods are ordered by start_dtm asc
PROCEDURE GetAggrTasksAndPeriods(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_task			OUT	SYS_REFCURSOR,
	out_period			OUT	SYS_REFCURSOR
)
AS
	v_project_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid ' || in_task_sid);
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region with sid ' || in_region_sid);
	END IF;
	
	-- Get the project sid
	SELECT project_sid 
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	 
	-- Get task and it's descendants
	GetTaskAndChildren(in_act_id, in_task_sid, out_task);
	
	-- Now fetch all the task period information available, including from the aggr_task_period 
	-- table and on-the-fly status information created from the values aggregated by region.
	-- We have to fetch data for ALL descendent tasks

	OPEN out_period FOR
		SELECT t.lvl, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id,
           tps.label status_label, tps.colour status_colour, tps.special_meaning status_special_meaning, 
           tps.means_pct_complete status_means_pct_complete, NVL(tp.fields_xml, atp.fields_xml) fields_xml,
           t.region_sid, task_pkg.FormatPeriod(t.start_dtm, t.end_dtm) period,
           tp.approved_dtm, tp.approved_by_sid, NVL(approved.full_name,'(unknown)') approved_by_name,
           tp.entered_dtm, tp.entered_by_sid, NVL(entered.full_name,'(unknown)') entered_by_name,
           public_comment_approved_dtm, public_comment_approved_by_sid, public_comment_approved.full_name public_comment_approved_name
          FROM task_period_status tps, project_task_period_status ptps, task_period tp, aggr_task_period atp, 
             csr.csr_user approved, csr.csr_user entered, csr.csr_user public_comment_approved, (
         		SELECT MIN(priority) OVER (partition by task_sid, region_sid, start_dtm) min_priority, priority,
               		project_sid, task_sid, region_sid, start_dtm, end_dtm, task_period_status_id, z.lvl, z.rn
           		  FROM (
            		SELECT y.priority, y.project_sid, y.task_sid, y.region_sid, y.start_dtm, y.end_dtm, y.task_period_status_id,
            			x.rn, x.lvl 
              		  FROM (
              		  	-- This fetches all tasks for a project - potentially going to
              		  	-- be slow??
                		SELECT 1 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
                  		  FROM task_period t
                 		 WHERE t.project_sid = v_project_sid
                   		   AND t.region_sid = in_region_sid
                   		   AND task_period_status_id IS NOT NULL
	                	UNION ALL
	                	SELECT 2 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
	                  	  FROM aggr_task_period t
	                 	 WHERE t.project_sid = v_project_sid
	                   	   AND t.region_sid = in_region_sid
	                   	   AND task_period_status_id IS NOT NULL
	                	UNION ALL
	                	SELECT 3 priority, t.project_sid, t.task_sid, v.region_sid, v.period_start_dtm start_dtm, v.period_end_dtm end_dtm,
                     		task_pkg.GetStatusIdFromPctValueFn('', t.task_sid, v.val_number) task_period_status_id    
	                	  FROM task t, csr.val v
		                 WHERE v.ind_sid(+) = t.output_ind_sid
		                   AND v.region_sid = in_region_sid
		                   AND val_number IS NOT NULL
		             	UNION ALL
		             	SELECT 4 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
                  		  FROM task_period t
                 		 WHERE t.project_sid = v_project_sid
                   		   AND t.region_sid = in_region_sid
                   		   AND task_period_status_id IS NULL
                   		   AND fields_xml IS NOT NULL
	                	UNION ALL
	                	SELECT 5 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
	                  	  FROM aggr_task_period t
	                 	 WHERE t.project_sid = v_project_sid
	                   	   AND task_period_status_id IS NULL
                   		   AND fields_xml IS NOT NULL
	        		) y, (
						SELECT LEVEL lvl, ROWNUM rn, t.task_sid
						  FROM task t
						 START WITH t.task_sid = in_task_sid
					   CONNECT BY PRIOR t.task_sid = t.parent_task_sid
					) x
	        		WHERE y.task_sid = x.task_sid
	      	     )z
	     ) t
	    WHERE priority = min_priority
	      AND ptps.project_sid(+) = t.project_sid	
	      AND ptps.task_period_status_id(+) = t.task_period_status_id
	      AND tps.task_period_status_id(+) = ptps.task_period_status_id
	      AND tp.task_sid(+) = t.task_sid
	      AND tp.region_sid(+) = t.region_sid
	      AND tp.start_dtm(+) = t.start_dtm
	      AND atp.task_sid(+) = t.task_sid
	      AND atp.region_sid(+) = t.region_sid
	      AND atp.start_dtm(+) = t.start_dtm
	      AND tp.approved_by_sid = approved.csr_user_sid(+)
	      AND tp.entered_by_sid = entered.csr_user_sid(+)
	      AND tp.public_comment_approved_by_sid = public_comment_approved.csr_user_sid(+)
		ORDER BY t.rn, tp.start_dtm;
END;

-- Important, task periods are ordered by start_dtm asc
PROCEDURE GetTasksForRegionAndPeriod(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_end_dtm			IN	task_period.end_dtm%TYPE,
	out_task			OUT	SYS_REFCURSOR,
	out_period			OUT	SYS_REFCURSOR
)
AS
	v_project_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid ' || in_task_sid);
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region with sid ' || in_region_sid);
	END IF;
	
	-- Get the project sid
	SELECT project_sid 
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	
	-- Get task and it's children
	GetTaskAndChildren(in_act_id, in_task_sid, out_task);
	
	-- Now fetch all the task period information available
	OPEN out_period FOR
		SELECT x.lvl, y.task_sid, y.start_dtm, y.project_sid, y.task_period_status_id, y.end_dtm, 
			y.approved_dtm, y.approved_by_sid, y.public_comment_approved_dtm, y.public_comment_approved_by_sid, 
			y.entered_dtm, y.entered_by_sid, y.fields_xml, y.region_sid,
			y.status_label, y.status_colour, y.status_special_meaning, y.status_means_pct_complete
		  FROM (
			SELECT LEVEL lvl, ROWNUM rn, t.task_sid
			  FROM task t
			 START WITH t.task_sid = in_task_sid
			  CONNECT BY PRIOR t.task_sid = t.parent_task_sid
		) x, (
			SELECT t.task_sid, start_dtm, t.project_sid, t.task_period_status_id, end_dtm, approved_dtm, 
				approved_by_sid, public_comment_approved_dtm, public_comment_approved_by_sid, entered_dtm, 
				entered_by_sid, fields_xml, region_sid,
				tps.label status_label, tps.colour status_colour, tps.special_meaning status_special_meaning, 
				tps.means_pct_complete status_means_pct_complete
			  FROM task_period t, task_period_status tps, project_task_period_status ptps
			 WHERE t.project_sid = v_project_sid
			   AND t.region_sid = in_region_sid
			   AND ptps.project_sid(+) = t.project_sid	
			   AND ptps.task_period_status_id(+) = t.task_period_status_id
			   AND tps.task_period_status_id(+) = ptps.task_period_status_id
			   AND t.start_dtm < in_end_dtm
			   AND t.end_dtm > in_start_dtm
			  ORDER BY start_dtm
		) y
		 WHERE y.task_sid = x.task_sid
		 	ORDER BY x.rn;
END;

PROCEDURE GetAggrTasksForRegionAndPeriod(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_end_dtm			IN	task_period.end_dtm%TYPE,
	out_task			OUT	SYS_REFCURSOR,
	out_period			OUT	SYS_REFCURSOR
)
AS
	v_project_sid		security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading task with sid ' || in_task_sid);
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region with sid ' || in_region_sid);
	END IF;
	
	-- Get the project sid
	SELECT project_sid 
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	
	-- Get task and it's children
	GetTaskAndChildren(in_act_id, in_task_sid, out_task);
	
	-- Now fetch all the task period information available
	OPEN out_period FOR
		SELECT t.lvl, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id,
           tps.label status_label, tps.colour status_colour, tps.special_meaning status_special_meaning, 
           tps.means_pct_complete status_means_pct_complete, NVL(tp.fields_xml, atp.fields_xml) fields_xml,
           t.region_sid, task_pkg.FormatPeriod(t.start_dtm, t.end_dtm) period,
           tp.approved_dtm, tp.approved_by_sid, NVL(approved.full_name,'(unknown)') approved_by_name,
           tp.entered_dtm, tp.entered_by_sid, NVL(entered.full_name,'(unknown)') entered_by_name,
           public_comment_approved_dtm, public_comment_approved_by_sid, public_comment_approved.full_name public_comment_approved_name
          FROM task_period_status tps, project_task_period_status ptps, task_period tp, aggr_task_period atp, 
             csr.csr_user approved, csr.csr_user entered, csr.csr_user public_comment_approved, (
         		SELECT MIN(priority) OVER (partition by task_sid, region_sid, start_dtm) min_priority, priority,
               		project_sid, task_sid, region_sid, start_dtm, end_dtm, task_period_status_id, z.lvl, z.rn
           		  FROM (
            		SELECT y.priority, y.project_sid, y.task_sid, y.region_sid, y.start_dtm, y.end_dtm, y.task_period_status_id,
            			x.rn, x.lvl 
              		  FROM (
              		  	-- This fetches all tasks for a project - potentially going to
              		  	-- be slow??
                		SELECT 1 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
                  		  FROM task_period t
                 		 WHERE t.project_sid = v_project_sid
                   		   AND t.region_sid = in_region_sid
                   		   AND task_period_status_id IS NOT NULL
	                	UNION ALL
	                	SELECT 2 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
	                  	  FROM aggr_task_period t
	                 	 WHERE t.project_sid = v_project_sid
	                   	   AND t.region_sid = in_region_sid
	                   	   AND task_period_status_id IS NOT NULL
	                	UNION ALL
	                	SELECT 3 priority, t.project_sid, t.task_sid, v.region_sid, v.period_start_dtm start_dtm, v.period_end_dtm end_dtm,
                     		task_pkg.GetStatusIdFromPctValueFn('', t.task_sid, v.val_number) task_period_status_id    
	                	  FROM task t, csr.val v
		                 WHERE v.ind_sid(+) = t.output_ind_sid
		                   AND v.region_sid = in_region_sid
		                   AND val_number IS NOT NULL
		                UNION ALL
		             	SELECT 4 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
                  		  FROM task_period t
                 		 WHERE t.project_sid = v_project_sid
                   		   AND t.region_sid = in_region_sid
                   		   AND task_period_status_id IS NULL
                   		   AND fields_xml IS NOT NULL
	                	UNION ALL
	                	SELECT 5 priority, t.project_sid, t.task_sid, t.region_sid, t.start_dtm, t.end_dtm, t.task_period_status_id
	                  	  FROM aggr_task_period t
	                 	 WHERE t.project_sid = v_project_sid
	                   	   AND t.region_sid = in_region_sid
	                   	   AND task_period_status_id IS NULL
                   		   AND fields_xml IS NOT NULL
	        		) y, (
						SELECT LEVEL lvl, ROWNUM rn, t.task_sid
						  FROM task t
						 START WITH t.task_sid = in_task_sid
					   CONNECT BY PRIOR t.task_sid = t.parent_task_sid
					) x
	        		WHERE y.task_sid = x.task_sid
	      	     )z
	     ) t
	    WHERE priority = min_priority
	      AND ptps.project_sid(+) = t.project_sid	
	      AND ptps.task_period_status_id(+) = t.task_period_status_id
	      AND tps.task_period_status_id(+) = ptps.task_period_status_id
	      AND tp.task_sid(+) = t.task_sid
	      AND tp.region_sid(+) = t.region_sid
	      AND tp.start_dtm(+) = t.start_dtm
	      AND atp.task_sid(+) = t.task_sid
	      AND atp.region_sid(+) = t.region_sid
	      AND atp.start_dtm(+) = t.start_dtm
	      AND tp.approved_by_sid = approved.csr_user_sid(+)
	      AND tp.entered_by_sid = entered.csr_user_sid(+)
	      AND tp.public_comment_approved_by_sid = public_comment_approved.csr_user_sid(+)
	      AND t.start_dtm < in_end_dtm
	      AND t.end_dtm > in_start_dtm
		ORDER BY t.rn, tp.start_dtm;
END;

PROCEDURE SetWeightings (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_sids				IN	T_TASK_SIDS,
	in_weightings		IN	T_WEIGHTINGS
)
AS
BEGIN
	-- Set the weightings
	FOR i IN in_sids.FIRST .. in_sids.LAST
	LOOP
		-- Update the weighting value
		UPDATE task
		   SET weighting = in_weightings(i)
		 WHERE task_sid = in_sids(i);
		-- If there is any task period data for this 
		-- task then it will need re-aggregating
		UPDATE task_period
		   SET needs_aggregation = 1
		 WHERE task_sid = in_sids(i);
	END LOOP;

	-- We need to update the weighting calcs	
	UpdateWeightings(in_act_id, in_parent_sid);
	Internal_CompenasteWgtRndg(in_parent_sid);
END;

PROCEDURE GetTasksForAggregation(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Hmm, we might use the temp table 
	-- more than once during a transaction
	DELETE FROM aggregate_tasks;

	FOR r IN (
		SELECT tp.task_sid, tp.start_dtm, tp.end_dtm, tp.region_sid
		  FROM task_period tp, task t, project p
		 WHERE tp.needs_aggregation = 1
		   AND t.task_sid = tp.task_sid
		   AND p.project_sid = t.project_sid
		   AND p.app_sid = in_app_sid)
	LOOP
		INSERT INTO aggregate_tasks (
			SELECT LEVEL lvl, task_sid, 
				start_dtm, end_dtm, period_duration, 
				r.region_sid, output_ind_sid, 
				r.start_dtm, r.end_dtm, NULL
			  FROM task
			START WITH task_sid = r.task_sid
			CONNECT BY PRIOR parent_task_sid = task_sid
		);
	END LOOP;
	
	OPEN out_cur FOR
		SELECT DISTINCT lvl, task_sid, task_start_dtm, task_end_dtm, 
			task_interval, region_sid, ind_sid, period_start_dtm, period_end_dtm
		  FROM aggregate_tasks
		 WHERE lvl > 1
		   AND task_sid NOT IN (
		   		SELECT task_sid 
		   		  FROM task_period_override
		   	)
		  	ORDER BY lvl ASC;
END;

PROCEDURE GetTaskForAggregation(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Hmm, we might use the temp table 
	-- more than once during a transaction
	DELETE FROM aggregate_tasks;
	
	FOR r IN (
		SELECT task_sid, start_dtm, end_dtm, region_sid
		  FROM task_period
		 WHERE task_sid = in_task_sid
		   AND needs_aggregation = 1)
	LOOP
		INSERT INTO aggregate_tasks (
			SELECT LEVEL lvl, task_sid, 
				start_dtm, end_dtm, period_duration, 
				r.region_sid, output_ind_sid, 
				r.start_dtm, r.end_dtm, NULL
			  FROM task
			START WITH task_sid = r.task_sid
			CONNECT BY PRIOR parent_task_sid = task_sid
		);
	END LOOP;
	
	OPEN out_cur FOR
		SELECT DISTINCT lvl, task_sid, task_start_dtm, task_end_dtm, 
			task_interval, region_sid, ind_sid, period_start_dtm, period_end_dtm
		  FROM aggregate_tasks
		 WHERE lvl > 1
		   AND task_sid NOT IN (
		   		SELECT task_sid 
		   		  FROM task_period_override
		   	)
		  	ORDER BY lvl ASC;
END;

PROCEDURE GetTasksForRegionalAggregation(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Hmm, we might use the temp table 
	-- more than once during a transaction
	DELETE FROM aggregate_tasks;
	
	FOR r IN (
		SELECT tp.task_sid, tp.start_dtm, tp.region_sid, tp.end_dtm,
			t.start_dtm task_start_dtm, t.end_dtm task_end_dtm,
			t.period_duration, t.output_ind_sid
          FROM task_period tp, task t, project p
         WHERE p.app_sid = security_pkg.GetAPP
           AND t.project_sid = p.project_sid
           AND tp.task_sid = t.task_sid 
           AND needs_aggregation = 1
        UNION
        SELECT tp.task_sid, tp.start_dtm, tp.region_sid, tp.end_dtm,
			t.start_dtm task_start_dtm, t.end_dtm task_end_dtm,
			t.period_duration, t.output_ind_sid
          FROM aggr_task_period tp, task t, project p
         WHERE p.app_sid = security_pkg.GetAPP
           AND t.project_sid = p.project_sid
           AND tp.task_sid = t.task_sid 
           AND needs_aggregation = 1)
	LOOP
		INSERT INTO aggregate_tasks (
			SELECT 1 lvl, r.task_sid, 
				r.task_start_dtm, r.task_end_dtm, r.period_duration,
				region_sid, r.output_ind_sid, r.start_dtm, r.end_dtm, 
				DECODE (parent_sid, security_pkg.GetAPP, NULL, parent_sid)
			  FROM csr.region
			 WHERE region_sid = r.region_sid
		);
	END LOOP;
	
	OPEN out_cur FOR
		SELECT a.lvl, a.task_sid, a.task_start_dtm, a.task_end_dtm, a.task_interval period_duration, 
			a.region_sid, a.ind_sid, a.period_start_dtm, a.period_end_dtm, a.parent_region_sid,
			t.input_ind_sid, t.target_ind_sid, t.aggregate_script
		  FROM aggregate_tasks a, task t
		 WHERE t.task_sid = a.task_sid
		  	ORDER BY lvl ASC;
		
	-- Clear the needs_aggregation flags
	ClearAggregationFlags();
END;

PROCEDURE GetTaskForRegionalAggregation(
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Hmm, we might use the temp table 
	-- more than once during a transaction
	DELETE FROM aggregate_tasks;
	
	FOR r IN (
		SELECT tp.task_sid, tp.start_dtm, tp.region_sid, tp.end_dtm,
			t.start_dtm task_start_dtm, t.end_dtm task_end_dtm,
			t.period_duration, t.output_ind_sid
          FROM task_period tp, task t
         WHERE t.task_sid = in_task_sid
           AND tp.task_sid = t.task_sid 
           AND needs_aggregation = 1
        UNION
        SELECT tp.task_sid, tp.start_dtm, tp.region_sid, tp.end_dtm,
			t.start_dtm task_start_dtm, t.end_dtm task_end_dtm,
			t.period_duration, t.output_ind_sid
          FROM aggr_task_period tp, task t
         WHERE t.task_sid = in_task_sid
           AND tp.task_sid = t.task_sid 
           AND needs_aggregation = 1)
	LOOP
		INSERT INTO aggregate_tasks (
			SELECT 1 lvl, r.task_sid, 
				r.task_start_dtm, r.task_end_dtm, r.period_duration,
				region_sid, r.output_ind_sid, r.start_dtm, r.end_dtm, 
				DECODE (parent_sid, security_pkg.GetAPP, NULL, parent_sid)
			  FROM csr.region
			 WHERE region_sid = r.region_sid
		);
	END LOOP;
	
	OPEN out_cur FOR
		SELECT a.lvl, a.task_sid, a.task_start_dtm, a.task_end_dtm, a.task_interval period_duration, 
			a.region_sid, a.ind_sid, a.period_start_dtm, a.period_end_dtm, a.parent_region_sid,
			t.input_ind_sid, t.target_ind_sid, t.aggregate_script
		  FROM aggregate_tasks a, task t
		 WHERE t.task_sid = a.task_sid
		  	ORDER BY lvl ASC;
		
	-- Clear the needs_aggregation flags for this task
	ClearAggregationFlagsForTask(in_task_sid);
END;

PROCEDURE ClearAggregationFlags
AS
BEGIN
	-- Clear task_period flags for this app only
	UPDATE task_period
	  SET needs_aggregation = 0
	WHERE needs_aggregation <> 0
	  AND task_sid IN (
  		SELECT task_sid
  		  FROM task t, project p
  		 WHERE t.project_sid = p.project_sid
  		   AND p.app_sid = security_pkg.GetApp
	);
	
	-- Clear aggr_task_period flags for this app only
	UPDATE aggr_task_period
	  SET needs_aggregation = 0
	WHERE needs_aggregation <> 0
	  AND task_sid IN (
  		SELECT task_sid
  		  FROM task t, project p
  		 WHERE t.project_sid = p.project_sid
  		   AND p.app_sid = security_pkg.GetApp
	);
END;

PROCEDURE ClearAggregationFlagsForTask(
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Clear task_period flags for this app only
	UPDATE task_period
	  SET needs_aggregation = 0
	WHERE needs_aggregation <> 0
	  AND task_sid = in_task_sid;
	
	-- Clear aggr_task_period flags for this app only
	UPDATE aggr_task_period
	  SET needs_aggregation = 0
	WHERE needs_aggregation <> 0
	  AND task_sid = in_task_sid;
END;

PROCEDURE GetStatusIdFromPctValue(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_pct_complete		IN	task_period_status.means_pct_complete%TYPE,
	out_id				OUT	task_period_status.task_period_status_id%TYPE
)
AS
BEGIN
	out_id := GetStatusIdFromPctValueFn(
		in_act_id, in_task_sid, in_pct_complete);
END;

FUNCTION GetStatusIdFromPctValueFn(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_pct_complete		IN	task_period_status.means_pct_complete%TYPE
) RETURN task_period_status.task_period_status_id%TYPE
AS
	v_project_sid		security_pkg.T_SID_ID;
	v_status_id			task_period_status.task_period_status_id%TYPE;
BEGIN
	SELECT project_sid
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;

	v_status_id := NULL;
	BEGIN
		SELECT s.task_period_status_id 
		  INTO v_status_id
		  FROM (
		    SELECT s.task_period_status_id
		      FROM task_period_status s, project_task_period_status p
		     WHERE p.project_sid = v_project_sid
		       AND s.task_period_status_id = p.task_period_status_id
		       AND means_pct_complete <= (CASE WHEN in_pct_complete < 0 THEN 0 ELSE in_pct_complete END)
		        ORDER BY means_pct_complete DESC
		) s WHERE ROWNUM = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	RETURN v_status_id;
END;

PROCEDURE SetStatusBasedOnPctComplete (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	task_period.start_dtm%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_pct_complete		IN	task_period_status.means_pct_complete%TYPE
)
AS
	v_status_id			task_period_status.task_period_Status_id%TYPE;
	v_old_label        	task_period_status.label%TYPE;
BEGIN
	-- Get the best status
	GetStatusIdFromPctValue(in_act_id, in_task_sid, in_pct_complete, v_status_id); 
	
	-- Update/insert the task period
	Internal_UpsertTaskPeriodEntry(
		in_act_id, in_task_sid, in_start_dtm, in_region_sid, 
		v_status_id, NULL, v_old_label);
		
	-- Task period data needs aggregation
	UPDATE task_period
	   SET needs_aggregation = 1
	 WHERE task_sid = in_task_sid
	   AND start_dtm = in_start_dtm
	   AND region_sid = in_region_sid;
END;

PROCEDURE SpreadWeightings(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_task_sid	IN	security_pkg.T_SID_ID,
	in_spread_weighting	IN	task.weighting%TYPE
)
AS
	v_spread			task.weighting%TYPE;
	v_sum_before		NUMBER(24,10);
	v_sum_after			NUMBER(24,10);
	v_sum_delta			NUMBER(24,10);
	v_count				NUMBER;
BEGIN
	-- How many children
	SELECT COUNT(0)
	  INTO v_count
	  FROM task
	 WHERE task_sid IN (
		 SELECT task_sid
		   FROM task
		  WHERE CONNECT_BY_ISLEAF = 1
		    AND NOT task_sid = in_parent_task_sid
		  START WITH task_sid = in_parent_task_sid
		CONNECT BY PRIOR task_sid = parent_task_sid
	 );
	 
	-- Nothing to do if no children
	IF v_count = 0 THEN
		-- DONE
		RETURN;
	END IF;
	 
	-- If only one child then spreading is very simple
	IF v_count = 1 THEN
		UPDATE task
		   SET weighting = weighting + in_spread_weighting 
		 WHERE task_sid = (
			 SELECT task_sid
			   FROM task
			  WHERE CONNECT_BY_ISLEAF = 1
			    AND NOT task_sid = in_parent_task_sid
			  START WITH task_sid = in_parent_task_sid
			CONNECT BY PRIOR task_sid = parent_task_sid
		);
		-- DONE
		RETURN;
	END IF;
	
	-- What's the sum before spreading
	 SELECT SUM(weighting)
	   INTO v_sum_before
	   FROM task
	  WHERE CONNECT_BY_ISLEAF = 1
	    AND NOT task_sid = in_parent_task_sid
	  START WITH task_sid = in_parent_task_sid
	CONNECT BY PRIOR task_sid = parent_task_sid;
	
	-- divide up the weighting to spread
	v_spread := ROUND(in_spread_weighting / v_count, 4);
	
	-- Spread the weighting
	UPDATE task
	   SET weighting = weighting + v_spread
	 WHERE task_sid IN (
		 SELECT task_sid
		   FROM task
		  WHERE CONNECT_BY_ISLEAF = 1
		    AND NOT task_sid = in_parent_task_sid
		  START WITH task_sid = in_parent_task_sid
		CONNECT BY PRIOR task_sid = parent_task_sid
	 );
	
	Internal_CompenasteWgtRndg(in_parent_task_sid);
	
	/*
	-- The sum of the applied weightings may not
	-- match the full amount due to rounding errors
	SELECT SUM(weighting)
	  INTO v_sum_after
	  FROM task
  	WHERE CONNECT_BY_ISLEAF = 1
  	  AND NOT task_sid = in_parent_task_sid
    	START WITH task_sid = in_parent_task_sid
    	CONNECT BY PRIOR task_sid = parent_task_sid;
	 
	-- What's the difference
	v_sum_delta := v_sum_after - v_sum_before - in_spread_weighting;
	
	-- Just add the descrepency to the first weighting 
	-- we find that is a child/leaf of the parent
	IF v_sum_delta != 0 THEN
		UPDATE task
		  SET weighting = weighting - v_sum_delta
		WHERE task_sid = (
			SELECT task_sid
			  FROM (
			 	SELECT task_sid
				  FROM task
			  	WHERE CONNECT_BY_ISLEAF = 1
			  	  AND NOT task_sid = in_parent_task_sid
			    	START WITH task_sid = in_parent_task_sid
			    	CONNECT BY PRIOR task_sid = parent_task_sid
			) WHERE ROWNUM = 1
		);
	END IF;
	*/
END;

PROCEDURE Internal_CompenasteWgtRndg(
	in_parent_task_sid	IN	security_pkg.T_SID_ID
)
AS
	v_sum			NUMBER(24,10);
	v_delta			NUMBER(24,10);
BEGIN
	-- The sum of the applied weightings may not 
	-- add up to 1.00 due to rounding errors
	 SELECT SUM(weighting)
	   INTO v_sum
	   FROM task
	  WHERE CONNECT_BY_ISLEAF = 1
	    AND NOT task_sid = in_parent_task_sid
	  START WITH task_sid = in_parent_task_sid
	CONNECT BY PRIOR task_sid = parent_task_sid;
	 
	-- What's the difference
	v_delta := ROUND(1.0 - v_sum, 4);
	
	-- Just add the discrepancy to the first weighting 
	-- we find that is a child/leaf of the parent
	IF v_delta != 0.0 THEN
		UPDATE task
		  SET weighting = weighting + v_delta
		WHERE task_sid = (
			SELECT task_sid
			  FROM (
				 SELECT task_sid
				   FROM task
				  WHERE CONNECT_BY_ISLEAF = 1
				    AND NOT task_sid = in_parent_task_sid
				  START WITH task_sid = in_parent_task_sid
				CONNECT BY PRIOR task_sid = parent_task_sid
			) WHERE ROWNUM = 1
		);
	END IF;
END;

PROCEDURE ClearTaskData(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID
)
AS
	v_parent_ind_sid	security_pkg.T_SID_ID;
BEGIN
	-- Clear down the task's actions data
	DELETE FROM task_period
	 WHERE task_sid = in_task_sid;
	
	-- We need the output ind
	SELECT output_ind_sid 
	  INTO v_parent_ind_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	
	-- Clear down the task's val data
	IF v_parent_ind_sid IS NOT NULL THEN
		DELETE FROM csr.val_change
		 WHERE ind_sid = v_parent_ind_sid;

		DELETE FROM csr.val
		 WHERE ind_sid = v_parent_ind_sid; 
	END IF;
END;

FUNCTION LastTaskPeriod(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN task_period.start_dtm%TYPE
AS
	v_start_dtm			task_period.start_dtm%TYPE;
BEGIN
	BEGIN
		SELECT MAX(start_dtm) 
		  INTO v_start_dtm
		  FROM task_period 
		 WHERE task_sid = in_task_sid
		   AND region_sid = in_region_sid;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_start_dtm := NULL;
	END;
	
	RETURN v_start_dtm;
END;

PROCEDURE SaveValueScript(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_script			IN	task.value_script%TYPE
)
AS
BEGIN
	-- Is this user a member of the super admins group?
	-- This measure is temporary but at the moment we need to 
	-- make sure that only super admins can alter the scripts
	IF Internal_IsSuperAdmin() = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting script');
	END IF;
	
	-- Ok update the script
	UPDATE task
	   SET value_script = in_script
	 WHERE task_sid = in_task_sid;
	 
	-- Need to add a recalc job
	dependency_pkg.CreateJobForTask(in_task_sid);
	
	-- Update the weightings.
	UpdateWeightings(security_pkg.GetAct(), in_task_sid, true);
END;

PROCEDURE SaveAggrScript(
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_script			IN	task.value_script%TYPE
)
AS
	CURSOR c (cin_ind_sid security_pkg.T_SID_ID) IS
		SELECT description, active, measure_sid, multiplier, scale, format_mask, 
			   info_xml, gri, target_direction, pos, divisibility, start_month, ind_type, 
			   aggregate, ind_activity_type_id,
			   factor_type_id, gas_measure_sid, gas_type_id, map_to_ind_sid,
			   core, roll_forward, normalize, prop_down_region_tree_sid, is_system_managed
		  FROM csr.v$ind
		 WHERE ind_sid = cin_ind_sid;
	r c%ROWTYPE;
	v_output_ind_sid		security_pkg.T_SID_ID;
	v_aggregate				csr.ind.aggregate%TYPE;
	v_track_emissions		NUMBER;
BEGIN
	-- Is this user a member of the super admins group?
	-- This measure is temporary but at the moment we need to 
	-- make sure that only super admins can alter the scripts
	IF Internal_IsSuperAdmin() = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting script');
	END IF;
	
	-- Ok update the script
	UPDATE task
	   SET aggregate_script = in_script
	 WHERE task_sid = in_task_sid;
	 
	-- Get the output indicator sid
	SELECT output_ind_sid
	  INTO v_output_ind_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	 
	-- If there is a script the we want to turn 
	-- aggregation off for the output indicator
	v_aggregate := 'AVERAGE';
	IF LENGTH(in_script) > 0 THEN
		v_aggregate := 'NONE';
	END IF;
	
	OPEN c(v_output_ind_sid);
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		-- TODO: throw error
		RETURN;
	END IF;
	
	v_track_emissions := 0;
	IF r.map_to_ind_sid IS NOT NULL THEN
		v_track_emissions := 1;
	END IF;
	
	-- Use AmendIndicator to switch aggregation on/off
	csr.indicator_pkg.AmendIndicator(
		in_act_id						=> security_pkg.GetACT,
		in_ind_sid						=> v_output_ind_sid,
		in_description					=> r.description,
		in_active						=> r.active,
		in_measure_sid					=> r.measure_sid,
		in_multiplier					=> r.multiplier,
		in_scale						=> r.scale,
		in_format_mask					=> r.format_mask,
		in_target_direction				=> r.target_direction,
		in_gri							=> r.gri,
		in_pos							=> r.pos,
		in_info_xml						=> r.info_xml,
		in_divisibility					=> r.divisibility,
		in_start_month					=> r.start_month,
		in_ind_type						=> r.ind_type,
		in_aggregate					=> v_aggregate,
		in_is_gas_ind					=> v_track_emissions,
		in_factor_type_id				=> r.factor_type_id,
		in_gas_measure_sid				=> r.gas_measure_sid,
		in_gas_type_id					=> r.gas_type_id,
		in_core							=> r.core,
		in_roll_forward					=> r.roll_forward,
		in_normalize					=> r.normalize,
		in_prop_down_region_tree_sid	=> r.prop_down_region_tree_sid,
		in_is_system_managed			=> r.is_system_managed
	);	
	
	-- Update task period and aggr task period 
	-- entries as they will need re-aggregating
	UPDATE task_period
	   SET needs_aggregation = 1
	 WHERE task_sid = in_task_sid;
	 
	UPDATE aggr_task_period
	   SET needs_aggregation = 1
	 WHERE task_sid = in_task_sid;
	
	-- Update weightings
	UpdateWeightings(security_pkg.GetAct(), in_task_sid, true);
END;

PROCEDURE IsSuperAdmin(
	out_result			OUT	NUMBER
)
AS
BEGIN
	out_result := Internal_IsSuperAdmin();
END;

FUNCTION Internal_IsSuperAdmin
 RETURN NUMBER
AS
	v_count NUMBER;
BEGIN
	-- Is this user a member of the super admins group?
	-- This measure is temporary but at the moment we need to 
	-- make sure that only super admins can alter the scripts
	SELECT COUNT(*)
	  INTO v_count
  	  FROM TABLE(group_pkg.GetMembersAsTable(security_pkg.GetACT, 
  	  	securableobject_pkg.GetSidFromPath(security_pkg.GetACT, 0, '//csr/superadmins')))
 	WHERE sid_id = security_pkg.GetSID;
 	
 	IF v_count > 0 THEN
 		RETURN 1;
 	END IF;
 	RETURN 0;
END;

PROCEDURE GetTaskTreeRegions(
	in_task_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
        SELECT lvl, t.task_sid, tr.region_sid
          FROM (
             SELECT LEVEL lvl, task_sid, ROWNUM rn
               FROM task
              START WITH task_sid = in_task_sid
            CONNECT BY PRIOR task_sid = parent_task_sid
         )t, task_region tr
        WHERE t.task_sid = tr.task_sid(+)
        ORDER BY rn;
END;

PROCEDURE GetMyTasks(
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN

	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM task
	 WHERE owner_sid = security_pkg.GetSid; --SYS_CONTEXT('SECURITY', 'SID');

	OPEN out_cur FOR
		SELECT *
		  FROM (
                SELECT rownum rn, q.*
				  FROM (
	                        SELECT t.task_sid, t.project_sid, p.name project_name, t.name task_name, t.start_dtm, t.end_dtm, 
	                        	csr.stragg(tag.tag) tags, ts.task_status_id, ts.label task_status_label
							  FROM task t, task_tag tt, tag, project p, task_status ts
							 WHERE t.owner_sid = security_pkg.GetSid --SYS_CONTEXT('SECURITY', 'SID') 
	                           AND t.task_sid = tt.task_sid(+) 
	                           AND tt.tag_id = tag.tag_id(+) 
	                           AND t.project_sid = p.project_sid
	                           AND ts.task_status_id = t.task_status_id
						  GROUP BY t.task_sid, t.project_sid, p.name, t.name, t.start_dtm, t.end_dtm, ts.task_status_id, ts.label
						  ORDER BY t.end_dtm DESC
                    ) q
				  WHERE rownum <= in_start_row + in_page_size
            )
		  WHERE rn > in_start_row;
END;

PROCEDURE GetCsrTaskRoleMembers (
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT trm.task_sid, trm.role_sid, trm.user_sid,
			r.name, u.user_name, u.full_name
		  FROM csr_task_role_member trm, csr.role r, csr.csr_user u
		 WHERE r.role_sid = trm.role_sid
		   AND u.csr_user_sid = trm.user_sid;
END;

PROCEDURE GetCsrTaskRoleMembers (
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT trm.task_sid, trm.role_sid, trm.user_sid,
			r.name, u.user_name, u.full_name
		  FROM csr_task_role_member trm, csr.role r, csr.csr_user u
		 WHERE task_sid = in_task_sid
		   AND r.role_sid = trm.role_sid
		   AND u.csr_user_sid = trm.user_sid
		 ORDER BY role_sid;
END;

PROCEDURE SetCsrTaskRoleMemebrs (
	in_task_sid		IN	security_pkg.T_SID_ID,
	in_role_sids	IN	security_pkg.T_SID_IDS,
	in_user_sids	IN	security_pkg.T_SID_IDS
)
AS
	v_role_table	security.T_ORDERED_SID_TABLE;
	v_user_table	security.T_ORDERED_SID_TABLE;
BEGIN
	
	v_role_table := security_pkg.SidArrayToOrderedTable(in_role_sids);
	v_user_table := security_pkg.SidArrayToOrderedTable(in_user_sids);
	
	-- The passed arrays both have the same length and are 
	-- associated by order so we can key on the pos columns
	INSERT INTO csr_task_role_member (app_sid, task_sid, role_sid, user_sid) (
		SELECT SYS_CONTEXT('SECURITY', 'APP'), in_task_sid, r.sid_id, u.sid_id
		  FROM TABLE(v_role_table) r, TABLE(v_user_table) u
		 WHERE r.pos = u.pos
	);
END;

PROCEDURE SetCsrTaskRoleMemebrsFullName (
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_role_sids		IN	security_pkg.T_SID_IDS,
	in_user_full_names	IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_role_table	security.T_ORDERED_SID_TABLE;
	v_user_table	security.T_VARCHAR2_TABLE;
BEGIN
	
	v_role_table := security_pkg.SidArrayToOrderedTable(in_role_sids);
	v_user_table := security_pkg.Varchar2ArrayToTable(in_user_full_names);
	
	-- Remove previous associations
	DELETE FROM csr_task_role_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_sid = in_task_sid;
	
	-- The passed arrays both have the same length and are 
	-- associated by order so we can key on the pos columns
	INSERT INTO csr_task_role_member (app_sid, task_sid, role_sid, user_sid) (
		SELECT SYS_CONTEXT('SECURITY', 'APP'), in_task_sid, r.sid_id, cu.csr_user_sid
		  FROM TABLE(v_role_table) r, TABLE(v_user_table) u, csr.csr_user cu
		 WHERE r.pos = u.pos
		   AND LOWER(cu.full_name) = LOWER(u.value)
	);
END;

END task_pkg;
/
