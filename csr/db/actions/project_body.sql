CREATE OR REPLACE PACKAGE BODY ACTIONS.project_Pkg
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

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) 
AS	
    v_ind_sid   security_pkg.T_SID_ID;
BEGIN					
	-- Delete metric (use SP as metrics structure is managed)
	FOR r IN (
		SELECT from_ind_template_id
		  FROM project_ind_template_instance
		 WHERE project_sid = in_sid_id
	) LOOP
		ind_template_pkg.DeleteProjectMetric(in_sid_id, r.from_ind_template_id);
	END LOOP;
	
	DELETE FROM import_template_mapping
	 WHERE (app_sid, import_template_id) IN (
	 	SELECT app_sid, import_template_id
	 	  FROM import_template 
	 	 WHERE project_sid = in_sid_id
	);
	
	DELETE FROM import_template WHERE project_sid = in_sid_id;
   
	DELETE FROM project_role_member WHERE project_sid = in_sid_id; 
	DELETE FROM project_region_role_member WHERE project_sid = in_sid_id; 
    DELETE FROM project_role WHERE project_sid = in_sid_id;
	DELETE FROM project_task_status WHERE project_sid = in_sid_id;
	DELETE FROM project_task_period_status WHERE project_sid = in_sid_id;
	DELETE FROM reckoner_tag WHERE project_sid = in_sid_id;
	DELETE FROM reckoner_tag_group WHERE project_sid = in_sid_id;
	DELETE FROM project_tag_group WHERE project_sid = in_sid_id;
	DELETE FROM project_ind_template WHERE project_sid = in_sid_id;
	DELETE FROM ind_template_group WHERE project_sid = in_sid_id;
	
    -- tidy up project indicators
    BEGIN
	    SELECT ind_sid 
	      INTO v_ind_sid
	      FROM project
	     WHERE project_sid = in_sid_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- don't worry if this is lost during cleanup
	END;
	
	DELETE FROM project WHERE project_sid = in_sid_id;
	
	IF v_ind_sid IS NOT NULL THEN
		securableobject_pkg.DeleteSO(in_act_id, v_ind_sid);
	END IF;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS   
BEGIN		 
	NULL;
END;

PROCEDURE TrashObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_project_sid		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE GetProjects(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT project_sid, name, app_sid, max_period_duration, start_dtm, end_dtm, task_fields_xml, task_period_fields_xml, icon, pos_group, pos,
			security_pkg.SQL_IsAccessAllowedSID(in_act_id, project_sid, security_pkg.PERMISSION_ADD_CONTENTS) can_add,
			security_pkg.SQL_IsAccessAllowedSID(in_act_id, project_sid, security_pkg.PERMISSION_WRITE) can_edit
		  FROM project
		 WHERE app_sid = in_app_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, project_sid, security_pkg.PERMISSION_READ) = 1
		   	ORDER BY pos_group, pos, name;
END;


PROCEDURE GetTaskStatuses(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_project_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT project_sid
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	
	GetProjectTaskStatuses(in_act_id, v_project_sid, out_cur);
END;

PROCEDURE GetProjectTaskStatuses(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_project_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ts.task_Status_id, LABEL, is_live, colour, is_default
		  FROM project_task_status pts, task_status ts
		 WHERE pts.task_status_id = ts.task_status_id
		   AND project_sid =  in_project_sid
		 ORDER BY LABEL;
END;

PROCEDURE GetProjectTaskPeriodStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tps.task_period_status_id, tps.LABEL, tps.colour, tps.special_meaning, means_pct_complete
		  FROM task_period_status tps, project_task_period_status ptps
		 WHERE tps.task_period_status_Id = ptps.task_period_status_id(+)
		   AND project_sid = in_project_sid
		 ORDER BY LABEL;
END;




PROCEDURE CreateProject(
	in_act_id									IN security_pkg.T_ACT_ID,
	in_app_sid 								IN security_pkg.T_SID_ID,
	in_name										IN project.name%TYPE,
	in_start_dtm							IN project.start_dtm%TYPE,
	in_duration								IN NUMBER,
	in_max_period_duration		IN project.max_period_duration%TYPE,
	in_task_fields_xml				IN project.task_fields_xml%TYPE,
	in_task_period_fields_xml	IN project.task_period_fields_xml%TYPE,
	out_project_sid						OUT security_pkg.T_SID_ID
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
	v_ind_sid		security_pkg.T_SID_ID;
BEGIN	   

	-- get securable object Actions
	v_parent_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Actions');
	SecurableObject_Pkg.CreateSO(in_act_id, v_parent_sid, class_pkg.getClassID('ActionsProject'), Replace(in_name,'/','\'), out_project_sid);
	
	-- Create an indicator folder for the project
	v_ind_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Indicators/Actions/Progress');
	csr.indicator_pkg.CreateIndicator(
		in_act_id 				=> in_act_id,
		in_parent_sid_id 		=> v_ind_sid,
		in_app_sid 				=> in_app_sid,
		in_name 				=> SUBSTR(in_name, 0, 255),
		in_description 			=> in_name,
		in_multiplier			=> 1,
		in_aggregate			=> 'SUM',
		in_core					=> 0,
		out_sid_id				=> v_ind_sid
	);
	
	INSERT INTO project
		(project_sid, app_sid, name, start_dtm, end_dtm, max_period_duration, 
			task_Fields_xml, task_period_fields_xml, ind_sid)
	VALUES
		(out_project_sid, in_app_sid, in_name, in_start_dtm, ADD_MONTHS(in_Start_dtm, in_duration), in_max_period_duration, 
			in_task_fields_xml, in_task_period_fields_xml, v_ind_sid);
END;

PROCEDURE AmendProject(
	in_act_id									IN security_pkg.T_ACT_ID,
	in_project_sid 						IN security_pkg.T_SID_ID,
	in_name										IN project.name%TYPE,
	in_start_dtm							IN project.start_dtm%TYPE,
	in_duration								IN NUMBER,
	in_max_period_duration		IN project.max_period_duration%TYPE,
	in_task_fields_xml				IN project.task_fields_xml%TYPE,
	in_task_period_fields_xml	IN project.task_period_fields_xml%TYPE
)
AS
	v_start_dtm	DATE;
	v_end_dtm		DATE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_project_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- check that altering these dates doesn't mess up existing data
	SELECT MIN(start_dtm), MAX(end_dtm) 
	  INTO v_start_dtm, v_end_dtm
	  FROM TASK
	 WHERE PROJECT_SID = in_project_sid;

	-- if proposed start > earliest task_start OR last task_end > proposed end
	IF v_start_dtm IS NOT NULL AND in_duration IS NOT NULL AND
		(in_start_dtm > v_start_dtm OR v_end_dtm > ADD_MONTHS(in_start_dtm, in_duration) ) THEN
--		RAISE_APPLICATION_ERROR(project_pkg.ERR_DATES_OUT_OF_RANGE, 'Dates out of range of tasks');			
null;
	END IF;

	
	UPDATE PROJECT
		 SET task_fields_xml = in_task_fields_xml,
			 task_period_fields_xml = in_task_period_fields_xml,
			 name = in_name,
			 start_dtm = in_start_dtm,
			 end_dtm = ADD_MONTHS(in_start_dtm, in_duration),			 
			 max_period_duration = in_max_period_duration
	 WHERE project_sid = in_project_sid;
	 
	 -- we update the name here 
	 securableobject_pkg.RenameSO(in_act_id, in_project_sid, REPLACE(in_name,'/','\'));
END;


PROCEDURE GetProject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_project_sid 			IN security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_project_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading scheme');
	END IF;

	OPEN out_cur FOR
	  	SELECT project_sid, name, task_fields_xml, task_period_fields_xml, max_period_duration, start_dtm, end_dtm,	  	
	  		MONTHS_BETWEEN(end_dtm, start_dtm) duration, app_sid,
   	         (SELECT ts.task_Status_id
	           FROM TASK_STATUS TS, PROJECT_TASK_STATUS PTS
	          WHERE PTS.project_sid = in_project_sid
	          	AND PTS.task_status_id = ts.task_Status_id
		        AND TS.is_default = 1) default_task_status_id
	      FROM PROJECT
	     WHERE project_sid = in_project_sid
	     	ORDER BY name;
END;



PROCEDURE GetRolesAndMembers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_project_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading project');
	END IF;
	OPEN out_cur FOR
		SELECT r.role_id, r.name, r.permission_set_on_task, show_in_filter,
			so.sid_id user_or_group_sid, NVL(cu.full_name, so.NAME) user_or_group_name
		  FROM project_role pr, ROLE r, PROJECT_ROLE_MEMBER prm, security.Securable_object so, csr.CSR_USER cu
		 WHERE pr.role_id = r.role_id
		   AND pr.project_sid = in_project_sid
		   AND prm.project_sid(+) = pr.project_sid
		   AND prm.role_id(+) = pr.role_id
		   AND prm.user_or_group_sid = so.sid_id(+)
       AND prm.user_or_group_sid = cu.csr_user_sid(+)
		 ORDER BY r.name, r.role_id, so.name;
END;



PROCEDURE SetRoleMembers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	in_role_Id			IN	ROLE.role_id%TYPE,
	in_members_list	IN	VARCHAR2
)
AS
	t_members_list	csr.T_SPLIT_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_project_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to project');
	END IF;
	
	t_members_list := utils_pkg.splitString(in_members_list,',');
	
	-- TODO: figure out which tasks are affected by the change (i.e. anything removed / anything added)
	
	-- we do a cast as without it with one or zero rows you get 'cannot access rows from a non-nested table item' for some bizarre reason!!
	FOR r IN (SELECT user_or_group_sid sid
			  FROM PROJECT_ROLE_MEMBER
			 WHERE role_id = in_role_Id
			   AND project_sid = in_project_sid
			 MINUS 
			SELECT TO_NUMBER(item) sid
			  FROM TABLE(CAST(t_members_list AS csr.T_SPLIT_TABLE)))
	LOOP	
		-- find any tasks affected
		FOR t IN (SELECT DISTINCT TASK_SID 
						FROM TASK_ROLE_MEMBER 
					   WHERE project_sid = in_project_sid
					     AND role_id = in_role_id
					     AND user_or_group_sid = r.sid)
		LOOP
			DELETE FROM TASK_ROLE_MEMBER
			 WHERE role_id = in_role_Id
			   AND project_sid = in_project_sid
			   AND user_or_group_sid = r.sid
			   AND task_sid = t.task_sid;
			task_pkg.RefreshTaskACL(in_act_id, t.task_sid);
		END LOOP;			
		
		DELETE FROM PROJECT_ROLE_MEMBER
		 WHERE role_id = in_role_Id
		   AND project_sid = in_project_sid
		   AND user_or_group_sid = r.sid;
	END LOOP;
	
   
	   
	FOR r IN (SELECT item FROM TABLE(csr.utils_pkg.splitString(in_members_list,',')))
	LOOP
		BEGIN
			INSERT INTO PROJECT_ROLE_MEMBER (project_sid, role_id, user_or_group_sid)
				VALUES (in_project_sid, in_role_id, r.item);
			-- if we got here ok, then it's new and we need to alter any relevant tasks
			FOR t IN (SELECT DISTINCT TASK_SID 
						FROM TASK_ROLE_MEMBER 
					   WHERE project_sid = in_project_sid
					     AND role_id = in_role_id
					     AND user_or_group_sid = r.item)
			LOOP
				task_pkg.RefreshTaskACL(in_act_id, t.task_sid);
			END LOOP;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN NULL;
		END;
	END LOOP;	
END;

PROCEDURE GetProjectFromTask(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_project_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT project_sid 
	  INTO v_project_sid
	  FROM task
	 WHERE task_sid = in_task_sid;
	 
	 GetProject(in_act_id, v_project_sid, out_cur);
END;

END project_Pkg;
/
