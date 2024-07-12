CREATE OR REPLACE PACKAGE BODY ACTIONS.setup_Pkg
IS

PROCEDURE GetAllTaskStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading app');
	END IF;

	OPEN out_cur FOR
		SELECT ts.task_status_id, ts.LABEL, ts.is_live, ts.colour, ts.is_default
		  FROM task_status ts
		 WHERE app_sid = in_app_sid
		 ORDER BY task_status_id;
END;

PROCEDURE GetAllProjectTaskStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading app');
	END IF;

	OPEN out_cur FOR
		SELECT ts.task_status_id, ts.label, ts.is_live, ts.colour, pts.project_sid, ts.is_default
		  FROM task_status ts, project_task_status pts
		 WHERE ts.app_sid = in_app_sid
		   AND pts.app_sid(+) = ts.app_sid
		   AND pts.task_status_id(+) = ts.task_status_id
	  ORDER BY task_status_id, project_sid;
END;

PROCEDURE GetAllTaskStatusesForProject(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading app');
	END IF;

	OPEN out_cur FOR
		SELECT ts.task_status_id, ts.LABEL, ts.is_live, ts.colour, pts.project_sid, ts.is_default
		  FROM task_status ts, project_task_status pts, task t
		 WHERE ts.app_sid = in_app_sid
		   AND ts.task_status_id = pts.task_status_id
		   AND pts.project_sid = t.project_sid
		   AND t.task_sid = in_task_sid
		 ORDER BY task_status_id;
END;

PROCEDURE GetAllPeriodStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading app');
	END IF;

	OPEN out_cur FOR
		-- todo: remove this NVL special meaning thing (in there for Credit360.Actions.Export which barfs on null)
		SELECT tps.task_period_status_id, tps.LABEL, tps.colour, NVL(tps.special_meaning,'-') special_meaning, means_pct_complete
		  FROM task_period_status tps
		 WHERE app_sid = in_app_sid
		 ORDER BY task_period_status_id;
END;

PROCEDURE GetAllPeriodStatusesForProject(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_task_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading app');
	END IF;

	OPEN out_cur FOR
		SELECT tps.task_period_status_id, tps.LABEL, tps.colour, tps.special_meaning, means_pct_complete
		  FROM task_period_status tps, project_task_period_status ptps, task t
		 WHERE tps.app_sid = in_app_sid
		   AND tps.task_period_status_id = ptps.task_period_status_id
		   AND ptps.project_sid = t.project_sid
		   AND t.task_sid = in_task_sid
		 ORDER BY means_pct_complete, task_period_status_id;
END;

PROCEDURE GetAllProjectPeriodStatuses(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading app');
	END IF;

	OPEN out_cur FOR
		SELECT tps.task_period_status_id, tps.label, tps.colour, tps.special_meaning, ptps.project_sid, tps.means_pct_complete
		  FROM task_period_status tps, project_task_period_status ptps
		 WHERE tps.task_period_status_id = ptps.task_period_status_id(+)
		   AND tps.app_sid = in_app_sid
		   AND ptps.app_sid = in_app_sid
		   AND tps.app_sid = ptps.app_sid
		 ORDER BY task_period_status_id, project_sid;
END;

PROCEDURE GetAllRoles(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading app');
	END IF;
	
	OPEN out_cur FOR
		SELECT r.role_id, r.NAME, r.show_in_filter, r.permission_set_on_task, r.show_in_filter, pr.project_sid
		  FROM ROLE r, PROJECT_ROLE pr
		 WHERE r.app_sid = in_app_sid
		   AND r.role_id = pr.role_id(+)
	 ORDER BY role_id, project_sid;
END;

-- return all tag groups and the Projects they are associated with for given app_sid
PROCEDURE GetAllTagGroups(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tg.app_sid, tg.tag_group_id, tg.name, tg.label, tg.multi_select, tg.mandatory, tg.render_as, 
			tgm.tag_Id, tgm.pos, tgm.is_visible, t.tag, t.explanation, tg.show_in_filter, t.explanation
		  FROM tag_group tg, tag_group_member tgm, tag t
		 WHERE tg.app_sid = in_app_sid
		   AND tg.tag_group_id = tgm.tag_group_id(+)
		   AND tgm.tag_id = t.tag_id(+)
		 ORDER BY tg.tag_group_id, tgm.pos;
END;

PROCEDURE GetAllTagGroupProjects(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
  		SELECT tg.tag_group_id, ptg.project_sid
		  FROM TAG_GROUP tg, PROJECT_TAG_GROUP ptg
		 WHERE tg.app_sid = in_app_sid
		   AND tg.tag_group_id = ptg.tag_group_Id;
END;

PROCEDURE RemoveAssociatedProjects(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	in_id				IN	NUMBER,
	in_type			IN	VARCHAR2,
	in_sids			IN	VARCHAR2
)
AS
	CURSOR c IS
		SELECT DISTINCT task_sid
		  FROM task_role_member
		 WHERE project_sid IN
			(SELECT item FROM TABLE(csr.utils_pkg.splitString(in_sids,',')));
	r	c%ROWTYPE;
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;
	
	CASE in_type
		WHEN 'task_status' THEN
			DELETE FROM project_task_status
			 WHERE task_status_id = in_id
			   AND project_sid IN 
			   	(SELECT item FROM TABLE(csr.utils_pkg.splitString(in_sids,',')));
		WHEN 'task_period_status' THEN
			DELETE FROM project_task_period_status
			 WHERE task_period_status_id = in_id
			   AND project_sid IN 
			   	(SELECT item FROM TABLE(csr.utils_pkg.splitString(in_sids,',')));
		WHEN 'role' THEN	
			-- open cursor now before we delete!
			OPEN c;		
			DELETE FROM project_role
			 WHERE role_id = in_id
			   AND project_sid IN 
				(SELECT item FROM TABLE(csr.utils_pkg.splitString(in_sids,',')));		
			LOOP
				FETCH c INTO r;
				EXIT WHEN c%NOTFOUND;
				task_pkg.RefreshTaskACL(in_act_id, r.task_sid);
			END LOOP;
		WHEN 'tag_group' THEN	
			DELETE FROM project_tag_group
			 WHERE tag_group_id = in_id
			   AND project_sid IN 
			   	(SELECT item FROM TABLE(csr.utils_pkg.splitString(in_sids,',')));
	END CASE;
END;    

PROCEDURE AddAssociatedProjects(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	in_id				IN	NUMBER,
	in_type			IN	VARCHAR2,
	in_sids			IN	VARCHAR2
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;

	FOR r IN (SELECT item FROM TABLE(csr.utils_pkg.splitString(in_sids,',')))
	LOOP
		BEGIN
			CASE in_type
				WHEN 'task_status' THEN
					INSERT INTO project_task_status (task_Status_id, project_sid) VALUES (in_id, r.item);
				WHEN 'task_period_status' THEN
					INSERT INTO project_task_period_status (task_period_status_id, project_sid) VALUES (in_id, r.item);
				WHEN 'role' THEN
					INSERT INTO project_role (role_id, project_sid) VALUES (in_id, r.item);
				WHEN 'tag_group' THEN
					INSERT INTO project_tag_group (tag_group_id, project_sid) VALUES (in_id, r.item);
			END CASE;
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;    


PROCEDURE DeleteTaskStatus(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_id				IN	task_status.task_status_id%TYPE
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT app_sid INTO v_app_sid
		  FROM TASK_STATUS
		 WHERE TASK_STATUS_ID = in_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			RETURN;
	END;
	
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;
	
	DELETE FROM project_task_status
	 WHERE task_status_id = in_id;

	DELETE FROM task_status 
	 WHERE task_status_id = in_id;
END;


PROCEDURE SetTaskStatus(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	in_id				IN	task_status.task_status_id%TYPE,
	in_label		IN	task_status.label%TYPE,
	in_is_live	IN	task_status.is_live%TYPE,
	in_colour		IN	task_status.colour%TYPE,
	in_is_default	IN	task_Status.is_default%TYPE,
	out_id			OUT	task_status.task_status_id%TYPE
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;
	
	IF in_id = -1 THEN	
		BEGIN
			SELECT task_status_id INTO out_id
			  FROM task_status
			 WHERE LOWER(label) = LOWER(in_label)
			   AND app_sid = in_app_sid;			
		EXCEPTION
			WHEN NO_DATA_FOUND THEN		 
				INSERT INTO TASK_STATUS (task_status_id, app_sid, label, is_Live, colour, is_default)
				  VALUES (task_Status_id_seq.nextval, in_app_sid, in_label, in_is_live, in_colour, in_is_default)
				 RETURNING task_status_id INTO out_id;
		END;
	ELSE
		UPDATE TASK_STATUS
		   SET label = in_label,
		   	is_live = in_is_live,
		   	colour = in_colour,
		   	is_default = in_is_default
		 WHERE app_sid = in_app_sid -- just in case someone tries to fiddles IDs, tie to AppSid since this is what we test security on
		   AND task_status_id = in_id;
		out_id := in_id;
	END IF;
END;
	


PROCEDURE DeleteTaskPeriodStatus(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_id			IN	TASK_PERIOD_STATUS.TASK_PERIOD_STATUS_id%TYPE
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT app_sid INTO v_app_sid
		  FROM TASK_PERIOD_STATUS
		 WHERE TASK_PERIOD_STATUS_ID = in_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			RETURN;
	END;
	
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;
	
	
	DELETE FROM project_task_period_status
	 WHERE task_period_status_id = in_id;

	DELETE FROM task_period_status
	 WHERE task_period_status_id = in_id;
END;


PROCEDURE SetTaskPeriodStatus(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_id							IN	TASK_PERIOD_STATUS.TASK_PERIOD_STATUS_id%TYPE,
	in_label						IN	TASK_PERIOD_STATUS.label%TYPE,
	in_colour						IN	TASK_PERIOD_STATUS.colour%TYPE,
	in_special_meaning				IN	TASK_PERIOD_STATUS.special_meaning%TYPE,
	in_means_pct_complete			IN	TASK_PERIOD_STATUS.means_pct_complete%TYPE,
	out_id							OUT	TASK_PERIOD_STATUS.TASK_PERIOD_STATUS_id%TYPE
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;
	
	IF in_id = -1 THEN	
		BEGIN
			SELECT task_period_status_id INTO out_id
			  FROM task_period_status
			 WHERE LOWER(label) = LOWER(in_label)
			   AND app_sid = in_app_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				INSERT INTO TASK_PERIOD_STATUS (TASK_PERIOD_STATUS_id, app_sid, label, colour, special_meaning, means_pct_complete)
				  VALUES (TASK_PERIOD_STATUS_id_seq.nextval, in_app_sid, in_label, in_colour, in_special_meaning, in_means_pct_complete)
				 RETURNING TASK_PERIOD_STATUS_id INTO out_id;
		END;
	ELSE
		UPDATE TASK_PERIOD_STATUS
		   SET label = in_label,
		   	colour = in_colour,
		   	special_meaning = in_special_meaning,
		   	means_pct_complete = in_means_pct_complete
		 WHERE app_sid = in_app_sid -- just in case someone tries to fiddles IDs, tie to AppSid since this is what we test security on
		   AND TASK_PERIOD_STATUS_id = in_id;
		out_id := in_id;
	END IF;
	
	-- Create a calc job for the tasks (if any exist) so we update
	-- according to the changes made to the task progress status.
	FOR r IN (
		SELECT task_sid FROM actions.task WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		actions.dependency_pkg.CreateJobForTask(r.task_sid);
	END LOOP;
  
END;




PROCEDURE DeleteRole(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_id				IN	ROLE.ROLE_id%TYPE
)
AS
	v_app_sid	security_pkg.T_SID_ID;
	CURSOR c_tasks IS
		SELECT DISTINCT task_sid FROM TASK_ROLE_MEMBER WHERE role_id = in_id;
	r_tasks	c_tasks%ROWTYPE;
BEGIN
	BEGIN
		SELECT app_sid INTO v_app_sid
		  FROM ROLE
		 WHERE ROLE_ID = in_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			RETURN;
	END;
	
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;
	
	-- open it before we delete so we know what we need to update
	OPEN c_tasks;

	DELETE FROM task_role_member
	 WHERE role_id = in_id;

	DELETE FROM project_role_member
	 WHERE role_id = in_id;

	DELETE FROM project_role
	 WHERE role_id = in_id;

 	DELETE FROM role
	 WHERE role_id = in_id;

	-- refresh all affected tasks
	LOOP
		FETCH c_tasks INTO r_tasks;
		EXIT WHEN c_tasks%NOTFOUND;
		task_pkg.RefreshTaskACL(in_act_id, r_tasks.task_sid);
	END LOOP;
	
END;


PROCEDURE SetRole(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_id						IN	ROLE.ROLE_id%TYPE,
	in_name						IN	ROLE.name%TYPE,
	in_show_in_filter			IN	ROLE.show_in_filter%TYPE,
	in_permission_set_on_task	IN	ROLE.permission_set_on_task%TYPE,
	out_id						OUT	ROLE.ROLE_id%TYPE
)
AS
	v_old_permission_set_on_task	ROLE.permission_set_on_task%TYPE;
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;
	
	IF in_id = -1 THEN		
		INSERT INTO ROLE (ROLE_id, app_sid, name, show_in_filter, permission_set_on_task)
		  VALUES (ROLE_id_seq.nextval, in_app_sid, in_name, in_show_in_filter, in_permission_set_on_task)
		 RETURNING ROLE_id INTO out_id;
	ELSE
		SELECT permission_set_on_task INTO v_old_permission_set_on_task
		  FROM ROLE
		 WHERE ROLE_id = in_id;
		
		UPDATE ROLE
		   SET name = in_name,
		   	show_in_filter = in_show_in_filter,
		   	permission_set_on_task = in_permission_set_on_task
		 WHERE app_sid = in_app_sid -- just in case someone tries to fiddles IDs, tie to AppSid since this is what we test security on
		   AND ROLE_id = in_id;
		out_id := in_id;
		
		IF v_old_permission_set_on_Task != in_permission_set_on_task THEN
			FOR r IN (SELECT DISTINCT TASK_SID FROM TASK_ROLE_MEMBER WHERE role_id = in_id)
			LOOP
				task_pkg.RefreshTaskACL(in_act_id, r.task_sid);
			END LOOP;
		END IF;
	END IF;
END;

	

PROCEDURE DeleteTagGroup(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_tag_group_id		IN tag_group.tag_group_id%TYPE
) AS
BEGIN
	-- TODO: this might orphan tags, i.e. tags which no longer belong to a group
	DELETE FROM tag_group_member
	 WHERE tag_group_id = in_tag_group_id;
	DELETE FROM project_tag_group
	 WHERE tag_group_id = in_tag_group_id;
	DELETE FROM tag_group
	 WHERE tag_group_id = in_tag_group_id;
END;




-- creates or amends a tag_group
PROCEDURE SetTagGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	in_name					IN  tag_group.name%TYPE,
	in_label				IN  tag_group.label%TYPE,
	in_multi_select			IN	tag_group.multi_select%TYPE,
	in_mandatory			IN	tag_group.mandatory%TYPE,
	in_render_as			IN	tag_group.render_as%TYPE,
	in_show_in_filter		IN	tag_group.show_in_filter%TYPE,
	out_tag_group_id		OUT	tag_group.tag_group_id%TYPE
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app');
	END IF;
	
	IF in_tag_group_id = -1 THEN		
		INSERT INTO TAG_GROUP
		(tag_group_id, app_sid, name, multi_select, mandatory, render_as, show_in_filter, label)
		 VALUES (tag_group_id_seq.nextval, in_app_sid, in_name, in_multi_select, in_mandatory, in_render_as, in_show_in_filter, in_label)
		RETURNING tag_group_id INTO out_tag_Group_id;
	ELSE	
		UPDATE tag_group
		 SET multi_select = in_multi_select,
			 mandatory = in_mandatory,
			 render_as = in_render_as,
			 show_in_filter = in_show_in_filter,
			 name = in_name,
			 label = in_label
		 WHERE app_sid = in_app_sid -- just in case someone tries to fiddles IDs, tie to AppSid since this is what we test security on
		   AND tag_group_id = in_tag_group_id;
		out_tag_group_id := in_tag_group_id;
	END IF;
END;


PROCEDURE GetAllRolesAndMembers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO should we check permissions on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading app');
	END IF;

	OPEN out_cur FOR
		-- get roles (DETAIL)
		-- DISTINCT to get rid of multiple projects
		SELECT DISTINCT r.role_id, r.NAME, user_or_group_sid, NVL(cu.full_name, so.NAME) user_or_group_name,
			r.show_in_filter, r.permission_set_on_task
		  FROM PROJECT_ROLE_MEMBER PRM, ROLE r, SECURITY.securable_object SO, csr.CSR_USER cu 
		 WHERE prm.user_or_group_sid = so.sid_id 
		   AND prm.user_or_group_sid = cu.csr_user_sid(+)
		   AND R.role_id = prm.role_id (+)
		   AND r.app_sid = in_app_sid
		 ORDER BY r.role_Id, user_or_group_name;
END;


PROCEDURE ImportSetTaskRoleMember(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_role_id				IN	ROLE.role_id%TYPE,
	in_user_or_group_name	IN	VARCHAR2,
	in_pref_is_group		IN 	NUMBER,
	out_user_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_safe_name			VARCHAR2(255);
	v_user_sid			security_pkg.T_SID_ID;
	v_groups_sid		security_pkg.T_SID_ID;
	v_sid				security_pkg.T_SID_ID;
	v_csr_user_group_class_id	security_pkg.T_CLASS_ID;
BEGIN
	v_safe_name := REPLACE(in_user_or_group_name, '/', '\');
	v_groups_sid := securableobject_pkg.GetSIDFromPath(in_act_id,in_app_sid,'groups');

	-- check role set up for this project
	BEGIN
		SELECT project_sid INTO v_sid
		  FROM PROJECT_ROLE
		 WHERE role_id = in_role_Id
		   AND project_sid = in_project_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
	 		INSERT INTO project_role 	                         
	 	    	(role_Id, project_sid) 	 
			VALUES 	 
	            (in_role_id, in_project_sid);
	END;
	
	-- look up user_or_group_sid
	BEGIN
		v_csr_user_group_class_id := class_pkg.getclassid('csrusergroup');
		IF in_pref_is_group = 1 THEN
			-- TODO: check in groups				
			SELECT sid_id INTO v_user_sid 
			  FROM SECURITY.securable_object
			 WHERE class_id IN (security_pkg.SO_GROUP,v_csr_user_group_class_id)
			   AND parent_sid_id = v_groups_sid
			   AND LOWER(name) = LOWER(v_safe_name);
		ELSE
			SELECT csr_user_sid
			  INTO v_user_sid
			  FROM csr.CSR_USER
			 WHERE app_sid = in_app_sid
			   AND LOWER(user_name) = LOWER(v_safe_name);
		END IF;		   
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF in_pref_is_group = 1 THEN
				group_pkg.CreateGroup(in_act_id, v_groups_sid, 1, v_safe_name, v_user_sid);				
			ELSE
				csr.csr_user_pkg.createUser(
					in_act						=> in_act_id, 
					in_app_sid					=> in_app_sid, 
					in_user_name				=> v_safe_name,
					in_password					=> null,
					in_full_name				=> in_user_or_group_name,
					in_friendly_name			=> null,
					in_email					=> 'bounce@credit360.com',
					in_job_title				=> null,
					in_phone_number				=> null,
					in_info_xml					=> null,
					in_send_alerts				=> 1,
					out_user_sid				=> v_user_sid
				);		
			END IF;
	END;

	BEGIN
		-- is it in project_role_member?
		SELECT project_sid INTO v_sid
		  FROM project_role_member
		 WHERE user_or_group_sid = v_user_sid
		   AND project_sid = in_project_sid
		   AND role_id = in_role_Id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- insert into prm			
			INSERT INTO project_role_member 
				(project_sid, role_id, user_or_group_sid) 	 
            VALUES
				(in_project_sid, in_role_id, v_user_sid);
	END;
	BEGIN
		-- is it in task_role_member?
		SELECT task_sid INTO v_sid
		  FROM TASK_role_member
		 WHERE task_sid = in_task_sid
		   AND user_or_group_sid = v_user_sid
		   AND project_sid = in_project_sid
		   AND role_id = in_role_Id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- insert into trm
			INSERT INTO task_role_member
				(project_sid, role_id, user_or_group_sid, task_sid, pos)
			VALUES
				(in_project_sid, in_role_id, v_user_sid, in_task_sid, 0);		
	END;
	out_user_sid := v_user_sid;
END;


-- updates all tasks and sets the correct ACLs
PROCEDURE ImportDone(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT task_sid 
		  FROM TASK t, PROJECT p
		 WHERE t.project_sid = p.project_sid
	   	   AND p.app_sid = in_app_sid)
	LOOP
		task_pkg.RefreshTaskACL(in_act_id, r.task_sid);
	END LOOP;
END;

PROCEDURE ImportSetTaskStatus(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid				IN	security_pkg.T_SID_ID,
	in_task_status_id		IN 	task_status.task_status_id%TYPE,
	in_comment_text			IN	task_status_history.comment_text%TYPE,
	in_user_or_group_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	task_pkg.SetTaskStatus(in_act_id, in_task_sid, in_task_Status_id, in_comment_text);
	-- hack to get right sid (if a group)
	UPDATE TASK_STATUS_HISTORY SET set_by_user_sid = in_user_or_group_sid
	 WHERE task_sid = in_task_sid AND task_status_id = in_task_status_id AND set_by_user_sid = 3;
END;


PROCEDURE ImportAddComment(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_task_sid					IN	security_pkg.T_SID_ID,
	in_comment_text				IN	TASK_COMMENT.comment_text%TYPE,
	in_user_or_group_sid		IN	security_pkg.T_SID_ID
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_task_comment_id		task_comment.task_comment_id%TYPE;
BEGIN
 	task_pkg.AddComment(in_act_id, in_task_sid, in_comment_text, v_task_comment_id);
 	
	-- hack to get right sid (if a group)
	UPDATE TASK_COMMENT 
	   SET user_sid = in_user_or_group_sid
	 WHERE task_comment_id = v_task_comment_id;
END;

END setup_Pkg;
/
