CREATE OR REPLACE PACKAGE BODY ACTIONS.tag_Pkg
IS



-- update or insert tag 
PROCEDURE SetTag(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	in_tag_id					IN	tag.tag_id%TYPE,
	in_tag						IN	tag.tag%TYPE,
	in_explanation		IN	tag.explanation%TYPE,
	in_pos						IN	tag_group_member.pos%TYPE,
	in_is_visible			IN	tag_group_member.is_visible%TYPE,
	out_tag_id				OUT	tag.tag_id%TYPE
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	
	IF NVL(in_tag_id,-1) = -1 THEN	
		INSERT INTO TAG
			(TAG_ID, TAG, EXPLANATION)
		VALUES
			(tag_id_seq.nextval, in_tag, in_explanation)
		RETURNING TAG_ID into out_tag_id;
	
		INSERT INTO TAG_GROUP_MEMBER
			(tag_group_id, tag_id, pos, is_visible)
		SELECT in_tag_group_id, out_tag_id, NVL(in_pos, NVL(MAX(POS),0)+1), in_is_visible FROM TAG_GROUP_MEMBER;
	ELSE
			UPDATE TAG
				SET tag = in_tag, explanation = in_explanation
			WHERE tag_id = in_tag_id;
			
			UPDATE TAG_GROUP_MEMBER
				SET pos = NVL(in_pos, pos), is_visible = in_is_visible
			WHERE tag_id = in_tag_id 
			  AND tag_group_id = in_tag_group_id;
			  
			out_tag_id := in_tag_id;
	END IF;
END;

PROCEDURE RemoveTagFromTask(
	in_task_sid	IN	task.task_sid%TYPE,
	in_tag_id	IN	tag.tag_id%TYPE
)
AS
BEGIN
	DELETE FROM task_tag WHERE tag_id = in_tag_id AND task_sid = in_task_sid;
END;

PROCEDURE RemoveTagFromGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	tag_group.tag_group_id%TYPE,
	in_tag_id				IN	tag.tag_id%TYPE
)
AS
	v_in_use	NUMBER(10);
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- check to see if tag is in use for this tag_group_id
	SELECT COUNT(*) INTO v_in_use
	  FROM TASK t, TASK_TAG tt, project_tag_group ptg
	 WHERE tt.tag_id = in_tag_id	-- donations where tag is in use
	   AND tt.task_sid = t.task_sid -- join to task
	   AND t.project_sid = ptg.project_sid -- join to project_tag_group
	   AND ptg.tag_group_id = in_tag_group_id; -- in our tag group
	
	IF v_in_use > 0 THEN 
		RAISE_APPLICATION_ERROR(project_pkg.ERR_TAG_IN_USE, 'Tag in use');
	END IF;

	DELETE FROM TAG_GROUP_MEMBER
	 WHERE tag_group_id = in_tag_group_id
	   AND tag_id = in_tag_id;

	-- don't delete if it's used in other tag_group
	DELETE FROM TAG
	 WHERE tag_id = in_tag_id AND tag_id NOT IN (SELECT tag_id FROM tag_group_member);
END;


PROCEDURE SetTaskTag(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_tag_id			IN	tag.tag_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_WRITE) 		THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	BEGIN
		INSERT INTO TASK_TAG
			(task_sid, tag_id)
		VALUES
			(in_task_sid, in_tag_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;						
	END;
END;



PROCEDURE SetTaskTags(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_task_sid			IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	VARCHAR2
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_task_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- insert new items
	INSERT INTO task_tag (task_sid, tag_id)
		SELECT in_task_sid, item
		  FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_tag_ids,','))
		 WHERE item NOT IN (SELECT tag_id FROM task_tag WHERE task_sid = in_task_sid);
	 
	-- delete leftovers
	DELETE FROM TASK_TAG
	 WHERE TASK_SID = in_task_sid
	   AND TAG_ID NOT IN (SELECT item FROM TABLE(CSR.UTILS_PKG.SPLITSTRING(in_tag_ids,',')));
END;


-- returns the Projects and tag groups this user can see 
PROCEDURE GetTagGroups(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT tg.tag_group_id, tg.name, tg.mandatory, tg.multi_select, tg.label
		  FROM tag_group tg
		 WHERE tg.app_sid = in_app_sid;
END;

PROCEDURE GetTagGroupsForProject(
	in_project_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT tg.tag_group_id, tg.name, tg.mandatory, tg.multi_select, tg.label, tg.render_as, tg.show_in_filter
		  FROM tag_group tg, project p, project_tag_group ptg
		 WHERE p.project_sid = in_project_sid
		   AND ptg.project_sid = p.project_sid
		   AND tg.tag_group_id = ptg.tag_group_id;
END;

PROCEDURE GetTagGroupsAndMemebrsProject (
	in_project_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_project_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading project with sid ' || in_project_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT tg.app_sid, tg.tag_group_id, tg.name, tg.label, tg.multi_select, tg.mandatory, tg.render_as, tg.show_in_filter, 
			tgm.tag_Id, tgm.pos, tgm.is_visible, t.tag, t.explanation, t.explanation
		  FROM tag_group tg, tag_group_member tgm, tag t, project_tag_group ptg
		 WHERE tg.app_sid = security_pkg.GetAPP
		   AND ptg.project_sid = in_project_sid
		   AND tg.tag_group_id = ptg.tag_group_id
		   AND tg.tag_group_id = tgm.tag_group_id(+)
		   AND tgm.tag_id = t.tag_id(+)
		 ORDER BY tg.tag_group_id, tgm.pos;
END;


-- DEPRECATED - use GetTagGroupAndMembers in preference
PROCEDURE GetTagGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT name, multi_select, mandatory, render_as, show_in_filter, label
		  FROM tag_group
		 WHERE tag_group_id = in_tag_group_id;
END;



-- return tag groups and their members for this project
-- optioinal task_sid (null if not interested) which will return selected if
-- selected for given task
PROCEDURE GetVisibleTagGroupsForProject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	in_task_sid			IN	TASK.task_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission on project
	-- (we assume that if they can see the project, they can see associated tag_groups)
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_project_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tg.label, ptg.pos,
			t.tag_id, t.tag, t.explanation, DECODE(tt.task_sid, null, 0, 1) selected, render_as, tg.show_in_filter
		  FROM project_tag_group ptg, tag_group tg, tag_group_member tgm, tag t, task_tag tt
		 WHERE ptg.tag_group_id = tg.tag_group_id
		   AND tg.tag_group_id = tgm.tag_group_id
		   AND tgm.is_visible = 1
		   AND tgm.tag_id = t.tag_id
		   AND ptg.project_sid = in_project_sid
	  	 AND tt.tag_id(+) = t.tag_id
		   AND tt.task_sid(+) = in_task_sid
		 ORDER BY tag_group_id, tgm.pos, tag_id;
END;


-- DEPRECATED - use GetTagGroupAndMembers in preference
PROCEDURE GetTagGroupMembers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_id	IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	
	OPEN out_cur FOR
		SELECT t.tag_id, tag, explanation, is_visible, pos
		  FROM tag_group_member tgm, tag t
		 WHERE tgm.tag_id = t.tag_id
		   AND tgm.tag_group_id = in_tag_group_id
		 ORDER BY pos;
END;

-- returns basic details of specified tag_group 
PROCEDURE GetTagGroupAndMembers(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	out_group_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_members_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid INTO v_app_sid FROM tag_group WHERE tag_group_id = in_tag_group_id;

	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_group_cur FOR
		SELECT name, multi_select, mandatory, render_as, show_in_filter, label
		  FROM tag_group
		 WHERE tag_group_id = in_tag_group_id;
		 
	
	OPEN out_members_cur FOR
		SELECT t.tag_id, tag, explanation, is_visible, pos
		  FROM tag_group_member tgm, tag t
		 WHERE tgm.tag_id = t.tag_id
		   AND tgm.tag_group_id = in_tag_group_id
		 ORDER BY pos;
END;

PROCEDURE GetTagGroupsForProjectSetup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_project_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	OPEN out_cur FOR
   SELECT tg.tag_group_id, tg.name, multi_select, mandatory, ptg.project_sid
 		 FROM tag_group tg, project_tag_group ptg
		WHERE tg.tag_group_id = ptg.tag_group_id(+)
      AND ptg.project_sid(+) = in_project_sid
	    AND tg.app_sid = in_app_sid
    ORDER BY ptg.pos;
END;

FUNCTION ConcatTagGroupMembers(
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE,
	in_max_length			IN 	INTEGER
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(512);
	v_sep VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (
		SELECT tag
		  FROM tag_group_member tgm, tag t
		 WHERE tgm.tag_id = t.tag_id
		   AND tgm.tag_group_id = in_tag_group_id)
	LOOP
		IF LENGTH(v_s) + LENGTH(r.tag) + 3 >= in_max_length THEN
			v_s := v_s || '...';
			EXIT;
		END IF;
		v_s := v_s || v_sep || r.tag;		
		v_sep := ', ';
	END LOOP;
	RETURN v_s;
END;


PROCEDURE GetTagGroupsSummary(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tag_group_id, name,
			(SELECT count(*) FROM tag_group_member tgm WHERE tag_group_id = tg.tag_group_id) member_count,
		    tag_pkg.ConcatTagGroupMembers(tg.tag_group_id, 30) MEMBERS
		  FROM tag_group tg
		 WHERE app_sid = in_app_sid;
END;

END tag_Pkg;
/