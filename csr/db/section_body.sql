CREATE OR REPLACE PACKAGE BODY CSR.section_Pkg
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
	FOR r IN (SELECT table_user, table_name, cms.item_id_seq.NEXTVAL id FROM csr.plugin_lookup)
	LOOP
		EXECUTE IMMEDIATE 'BEGIN INSERT INTO ' || r.table_user||'.'||r.table_name || ' (' || r.table_name || '_ID, APP_SID, SECTION_SID)' || ' VALUES (' || r.id || ', ' || security_pkg.getapp || ', ' || in_sid_id || '); END;';
	END LOOP;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
	v_version				section_version.version_number%TYPE;
BEGIN
	-- it is possible that the obejct may be renamed
	-- through security so we need to support this
	IF in_new_name IS NULL THEN
		-- but not if it's being set to null (function of being deleted)
		RETURN;
	END IF;
	v_version := GetLatestVersion(in_sid_id);
	UPDATE section_version
	   SET title = replace(in_new_name,'/','\') --'
	 WHERE section_sid = in_sid_id
	   AND version_number = v_version;
END;

PROCEDURE TrashObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_section_sid		IN security_pkg.T_SID_ID
)
AS
	v_app_sid			security_pkg.T_SID_ID;
	v_module_root_sid	security_pkg.T_SID_ID;
	v_parent_sid		security_pkg.T_SID_ID;
BEGIN
	-- Check for delete permissions
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting object with sid '||in_section_sid);
	END IF;
	-- get name and sid
	SELECT app_sid, module_root_sid, parent_sid
	  INTO v_app_sid, v_module_root_sid, v_parent_sid
	  FROM section
	 WHERE section_sid = in_section_sid;

	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_section_sid,
		'Moved "'||GetPathFromSectionSID(in_act_id, in_section_sid)||'" to trash');

	trash_pkg.TrashObject(in_act_id, in_section_sid,
		securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Trash'),
		GetPathFromSectionSID(in_act_id, in_section_sid));
	-- do this after we trash it because trashing involves moving, and moving
	-- involves setting active to 1 if it was in the trash :)
	UPDATE section
	   SET active = 0
	 WHERE section_sid IN (
        SELECT section_sid
          FROM section
         	   START WITH section_sid = in_section_sid
        	   CONNECT BY PRIOR section_sid = parent_sid);

	-- Ensure position data is valid for the parent
	FixSectionPositionData(v_app_sid, v_module_root_sid, v_parent_sid);
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
	v_app_sid				security_pkg.T_SID_ID;
	v_module_root_sid		security_pkg.T_SID_ID;
	v_parent_sid			security_pkg.T_SID_ID;
	v_flow_item_id			section.flow_item_id%TYPE;
	v_route_id				route.route_id%TYPE;
	CURSOR c_attachments IS
		SELECT attachment_id
		  FROM attachment_history
		 WHERE section_sid = in_sid_id;
BEGIN
	-- We'll need some information later on
	BEGIN
		SELECT app_sid, module_root_sid, parent_sid, flow_item_id
		  INTO v_app_sid, v_module_root_sid, v_parent_sid, v_flow_item_id
		  FROM section
		 WHERE section_sid = in_sid_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- hmm, maybe we have left over SOs and no data?
			RETURN;
	END;

	-- Remove links to this content in other sections
	UPDATE section
	   SET previous_section_sid = NULL
	 WHERE previous_section_sid = in_sid_id;

	-- Attachments relating to this section
	FOR r_attach IN c_attachments LOOP
		DELETE FROM attachment_history
	 	 WHERE SECTION_SID = in_sid_id
	 	   AND ATTACHMENT_ID = r_attach.ATTACHMENT_ID;
		DELETE FROM attachment
		 WHERE ATTACHMENT_ID = r_attach.ATTACHMENT_ID;
	END LOOP;

	-- Comments relating to this section
	DELETE FROM section_comment
	 WHERE section_sid = in_sid_id;

	-- Transition comments relating to this section
	DELETE FROM section_trans_comment
	 WHERE section_sid = in_sid_id;

	-- Section version history
	UPDATE section
	   SET checked_out_version_number = NULL, visible_version_number = NULL, current_route_step_id = NULL
	 WHERE section_sid = in_sid_id;

	DELETE FROM section_version
	 WHERE section_sid = in_sid_id;

	-- Delete flow item and related stuff
	DELETE FROM flow_state_log
	 WHERE flow_item_id = v_flow_item_id;

	-- Delete association to section tags
	DELETE FROM section_tag_member
	 WHERE section_sid = in_sid_id;

	DELETE FROM section_alert
	 WHERE section_sid = in_sid_id;

	-- Delete route
	FOR r_route IN (
		SELECT r.route_id, rs.route_step_id
		  FROM route r, route_step rs
	     WHERE r.route_id = rs.route_id
           AND r.section_sid = in_sid_id
	)
	LOOP
		DELETE FROM route_step_user
	 	 WHERE route_step_id = r_route.route_step_id;
		DELETE FROM route_step_vote
	 	 WHERE route_step_id = r_route.route_step_id
			OR dest_route_step_id = r_route.route_step_id;
		DELETE FROM route_step
		 WHERE route_step_id = r_route.route_step_id;
	END LOOP;

	DELETE FROM route
     WHERE section_sid = in_sid_id;

	DELETE FROM section_attach_log
	 WHERE section_sid = in_sid_id;

	-- Any cart membership?
	DELETE FROM section_cart_member
	 WHERE section_sid = in_sid_id;

	-- Delete fact
	DELETE FROM section_fact_attach
	 WHERE section_sid = in_sid_id;

	DELETE FROM section_val
	 WHERE section_sid = in_sid_id;

	DELETE FROM section_fact
	 WHERE section_sid = in_sid_id;

	--Content Doc
	DELETE FROM section_content_doc
	 WHERE section_sid = in_sid_id;

	-- Delete, the section itself
	DELETE FROM section
	 WHERE section_sid = in_sid_id;

	-- delete the flow item
	DELETE FROM flow_item
	 WHERE flow_item_id = v_flow_item_id;

	-- Ensure position data is valid for the parent
	FixSectionPositionData(v_app_sid, v_module_root_sid, v_parent_sid);

	FOR r IN (SELECT table_user, table_name FROM csr.plugin_lookup)
	LOOP
		EXECUTE IMMEDIATE 'BEGIN DELETE FROM ' || r.table_user||'.'||r.table_name || ' WHERE SECTION_SID = ' || in_sid_id || ' AND APP_SID = ' || security_pkg.getapp || '; END;';
	END LOOP;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
	v_count					NUMBER(10);
	v_app_sid				security_pkg.T_SID_ID;
	v_module_root_sid		security_pkg.T_SID_ID;
	v_position				section.section_position%TYPE;
	v_new_parent_sid		security_pkg.T_SID_ID;
	v_old_parent_sid		security_pkg.T_SID_ID;
	v_in_trash				NUMBER;
BEGIN
	-- We will state that a user must have add/delete content permissions to move a section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not able to move object with sid '||in_sid_id||' without add contents permissions');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_sid_id, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not able to move object with sid '||in_sid_id||' without delete contents permissions');
	END IF;

	-- We'll need some information about
	-- the old parent before we move the object
	SELECT parent_sid
	  INTO v_old_parent_sid
	  FROM section
	 WHERE section_sid = in_sid_id;

	-- Try to find the parent section
	SELECT COUNT(0)
	  INTO v_count
	  FROM section
	 WHERE section_sid = in_new_parent_sid;

	-- If we can't find the section then
	-- assume root (parent_sid is NULL)
	v_new_parent_sid := in_new_parent_sid;
	IF v_count = 0 THEN
		v_new_parent_sid := NULL;
	END IF;

	-- Get the next position
	SELECT app_sid, module_root_sid
	  INTO v_app_sid, v_module_root_sid
	  FROM section
	 WHERE section_sid = in_sid_id;
	v_position := GetNextSectionPosition(v_app_sid, v_module_root_sid, v_new_parent_sid);

	-- Move the section
	UPDATE section
	   SET parent_sid = v_new_parent_sid,
	   	   section_position = v_position
	 WHERE section_sid = in_sid_id;

	-- Ensure position data is valid for the old parent
	FixSectionPositionData(v_app_sid, v_module_root_sid, v_old_parent_sid);

	-- If the object was in the trash, reactivate it
	SELECT COUNT(*)
	  INTO v_in_trash
	  FROM trash
	 WHERE trash_sid = in_sid_id;

	IF v_in_trash > 0 THEN
		UPDATE section
		   SET active = 1
		 WHERE section_sid = in_sid_id;
	END IF;
END;

-- Functions
FUNCTION HasCapabilityAccess(
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_capability_id			IN	flow_capability.flow_capability_id%TYPE,
	in_permission				IN	NUMBER
) RETURN BOOLEAN
AS
BEGIN
	
	IF csr_user_pkg.IsSuperAdmin > 0 THEN
		RETURN TRUE;
	END IF;

	FOR r IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT *
			  FROM v$corp_rep_capability
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND section_sid = in_section_sid
			   AND flow_capability_id = in_capability_id
			   AND bitand(permission_set, in_permission) = in_permission
		)
	) LOOP
		RETURN TRUE;
	END LOOP;

	RETURN FALSE;
END;

FUNCTION SQL_HasEditFactCapability(
	in_section_sid				IN	security_pkg.T_SID_ID
) RETURN BINARY_INTEGER
AS
BEGIN
	IF HasCapabilityAccess(in_section_sid, csr_data_pkg.FLOW_CAP_CORP_REP_EDIT_FACT, security_pkg.PERMISSION_WRITE) THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;

FUNCTION SQL_HasClearFactCapability(
	in_section_sid				IN	security_pkg.T_SID_ID
) RETURN BINARY_INTEGER
AS
BEGIN
	IF HasCapabilityAccess(in_section_sid, csr_data_pkg.FLOW_CAP_CORP_REP_CLEAR_FACT, security_pkg.PERMISSION_WRITE) THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;

FUNCTION GetFirstRouteStepId(
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE
)	RETURN route_step.route_step_id%TYPE
AS
	v_route_step_id		route_step.route_step_id%TYPE;
BEGIN
	SELECT route_step_id
	  INTO v_route_step_id
	  FROM route_step rs, route r
	  WHERE r.route_id = rs.route_id
	    AND r.flow_state_id = in_flow_state_id
	    AND r.section_sid = in_section_sid
	    AND POS = (SELECT MIN(POS) FROM route_step WHERE route_id = r.route_id AND route_step_id = route_step_id);

	RETURN v_route_step_id;
END;

FUNCTION GetLastRouteStepId(
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_flow_state_id	IN	flow_state.flow_state_id%TYPE
)	RETURN route_step.route_step_id%TYPE
AS
	v_route_step_id		route_step.route_step_id%TYPE;
BEGIN
	SELECT route_step_id
	  INTO v_route_step_id
	  FROM route_step rs, route r
	  WHERE r.route_id = rs.route_id
	    AND r.flow_state_id = in_flow_state_id
	    AND r.section_sid = in_section_sid
	    AND POS = (SELECT MAX(POS) FROM route_step WHERE route_id = r.route_id AND route_step_id = route_step_id);

	RETURN v_route_step_id;
END;

FUNCTION GetNextVersionNumber(
	in_section_sid		IN	security_pkg.T_SID_ID
) RETURN section_version.version_number%TYPE
AS
	v_max_version_number	section_version.version_number%TYPE;
BEGIN
	SELECT NVL(MAX(version_number),0)
	  INTO v_max_version_number
	  FROM section_version
	 WHERE section_sid = in_section_sid;

	RETURN v_max_version_number+1;
END;

FUNCTION GetCheckedOutToSID(
	in_section_sid			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_checked_out_to_sid	security_pkg.T_SID_ID;
BEGIN
	-- Get the SID of the user who has this section checked out
	SELECT checked_out_to_sid
	  INTO v_checked_out_to_sid
	  FROM section
	 WHERE section_sid = in_section_sid;

	RETURN v_checked_out_to_sid;
END;

PROCEDURE GetCheckedOutTo(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Check for read access on section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;
	OPEN out_cur FOR
		SELECT s.checked_out_to_sid, cu.user_name, cu.full_name, cu.friendly_name,
			   CASE WHEN SYS_CONTEXT('SECURITY', 'SID') = s.checked_out_to_sid THEN 1 ELSE 0 END checked_out_to_self
		  FROM section s, csr_user cu
		 WHERE s.section_sid = in_section_sid AND
		 	   s.checked_out_to_sid = cu.csr_user_sid(+);
END;

FUNCTION GetLatestVersion(
	in_section_sid			IN	security_pkg.T_SID_ID
) RETURN section_version.VERSION_NUMBER%TYPE
AS
	v_version	section_version.VERSION_NUMBER%TYPE;
BEGIN
	-- Get the latest version number
	SELECT MAX(version_number)
	  INTO v_version
	  FROM section_version
	 WHERE section_sid = in_section_sid;

	RETURN v_version;
END;

FUNCTION GetLatestCheckedInVersion(
	in_section_sid			IN	security_pkg.T_SID_ID
) RETURN section_version.VERSION_NUMBER%TYPE
AS
	v_version	section_version.VERSION_NUMBER%TYPE;
BEGIN
	-- Get the latest checked in version number
	SELECT MAX(version_number)
	  INTO v_version
	  FROM section_version
	 WHERE section_sid = in_section_sid
	   AND CHANGED_BY_SID IS NOT NULL;

	RETURN v_version;
END;

FUNCTION GetLatestApprovedVersion(
	in_section_sid			IN	security_pkg.T_SID_ID
) RETURN section_version.VERSION_NUMBER%TYPE
AS
	v_version	section_version.VERSION_NUMBER%TYPE;
BEGIN
	-- Get the latest approved version number
	SELECT MAX(version_number)
	  INTO v_version
	  FROM section_version
	 WHERE section_sid = in_section_sid
	   AND APPROVED_BY_SID IS NOT NULL;

	RETURN v_version;
END;

FUNCTION GetLatestVisibleVersion(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID
) RETURN section_version.VERSION_NUMBER%TYPE
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_checked_out_to_sid	security_pkg.T_SID_ID;
BEGIN
	-- Get the sid of this user
	user_pkg.GetSID(in_act_id, v_user_sid);

	-- Get the sid of the user who has this section checked out if any
	v_checked_out_to_sid := GetCheckedOutToSID(in_section_sid);

	-- If this user has the section checked out then get the very latest version nmber
	IF v_user_sid = v_checked_out_to_sid THEN
		RETURN GetLatestVersion(in_section_sid);
	END IF;

	-- otherwise get the latest checked in version number
	RETURN GetLatestCheckedInVersion(in_section_sid);
END;

FUNCTION GetNextSectionPosition(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_parent_section_sid	IN	security_pkg.T_SID_ID
) RETURN section.section_position%TYPE
AS
	v_count			NUMBER(10);
	v_position 		section.section_position%TYPE;
	v_parent_section_sid	security_pkg.T_SID_ID;
BEGIN
	v_parent_section_sid := 0;

	IF in_parent_section_sid IS NOT NULL THEN
		-- Try to find the specified parent section
		SELECT COUNT(0)
		  INTO v_count
		  FROM section
		 WHERE parent_sid = in_parent_section_sid;
		-- If we can't find the section then assume root
		IF v_count != 0 THEN
			v_parent_section_sid := in_parent_section_sid;
		END IF;
	END IF;

	SELECT MAX(section_position)
	  INTO v_position
	  FROM section
	 WHERE app_sid = in_app_sid
	   AND module_root_sid = in_module_root_sid
	   AND NVL(parent_sid,0) = v_parent_section_sid;

	v_position :=  NVL(v_position,-1);
	RETURN v_position + 1;
END;

FUNCTION GetPathFromSectionSID(
    in_act_id			IN	Security_Pkg.T_ACT_ID,
	in_sid_id 			IN	Security_Pkg.T_SID_ID,
	in_join_with		IN	VARCHAR2 DEFAULT ' / ',
	in_ignore_last_lvl	IN	NUMBER DEFAULT 0
) RETURN VARCHAR2
AS
	v_name 	VARCHAR2(4000) := NULL;
BEGIN
	FOR r IN (
		SELECT sv.title, lvl
		  FROM section_version sv, (
			  	SELECT section_sid, LEVEL lvl, visible_version_number version_number
		          FROM SECTION
		          WHERE (in_ignore_last_lvl = 0 OR section_sid != in_sid_id)
		         START WITH section_sid = in_sid_id
		        CONNECT BY PRIOR parent_sid = section_sid
			 )s
		 WHERE sv.section_sid = s.section_sid
		   AND sv.version_number = s.version_number
		 ORDER BY lvl DESC
	)
	LOOP
		-- Append the current level to the name-so-far
		v_name := v_name || r.title || in_join_with;
	END LOOP;

	-- return path without last in_join_with string
	RETURN SUBSTR(v_name, 0, LENGTH(v_name) - LENGTH(in_join_with));
END;

FUNCTION GetModuleName(
	in_section_sid		IN	Security_Pkg.T_SID_ID
) RETURN section_module.LABEL%TYPE
AS
	v_name 			section_module.label%TYPE;
BEGIN
	SELECT sm.label
	  INTO v_name
	  FROM section_module sm, section s
	 WHERE sm.module_root_sid = s.module_root_sid
	   AND s.section_sid = in_section_sid;

	RETURN v_name;
END;

FUNCTION GetSectionTagPath(
	in_section_tag_id	IN	section_tag.section_tag_id%TYPE,
	in_join_with		IN	VARCHAR2 DEFAULT ' / '
) RETURN VARCHAR2
AS
	v_name VARCHAR2(4000) := NULL;
BEGIN
	FOR r IN (
		SELECT section_tag_id, tag, LEVEL lvl
		  FROM SECTION_tag
			START WITH section_tag_id = in_section_tag_id
			CONNECT BY PRIOR parent_id = section_tag_id
		 ORDER BY lvl DESC
	)
	LOOP
		-- Append the current level to the name-so-far
		v_name := v_name || r.tag;
		IF r.lvl > 1 THEN
			v_name := v_name || in_join_with;
		END IF;
	END LOOP;
	RETURN v_name;
END;

FUNCTION GetNextFactId	RETURN VARCHAR2
AS
	v_fact_id VARCHAR2(4000);
BEGIN

	SELECT 'AUTO'||TO_CHAR(section_fact_id_seq.NEXTVAL)
	  INTO v_fact_id
	  FROM dual;

	RETURN v_fact_id;
END;

PROCEDURE FixSectionPositionData(
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_parent_section_sid	IN	security_pkg.T_SID_ID
)
AS
	v_count			NUMBER(10);
	v_position 		section.section_position%TYPE;
	v_parent_section_sid	security_pkg.T_SID_ID;
BEGIN
	IF in_parent_section_sid IS NULL THEN
		v_parent_section_sid := NULL;
	ELSE
		-- Try to find the specified parent section
		SELECT COUNT(0)
		  INTO v_count
		  FROM section
		 WHERE parent_sid = in_parent_section_sid;

		-- If we can't find the section then
		-- assume root (parent_sid is NULL)
		v_parent_section_sid := in_parent_section_sid;
		IF v_count = 0 THEN
			v_parent_section_sid := NULL;
		END IF;
	END IF;

	v_position := 0;
	IF v_parent_section_sid IS NULL THEN
		FOR r_section IN (
				SELECT section_sid
				  FROM section
				 WHERE app_sid = in_app_sid
				   AND module_root_sid = in_module_root_sid
				   AND parent_sid IS NULL
				   	ORDER BY section_position ASC) LOOP
			UPDATE section
			   SET section_position = v_position
			 WHERE section_sid = r_section.section_sid;
			v_position := v_position + 1;
	END LOOP;
	ELSE
		FOR r_section IN (
				SELECT section_sid
				  FROM section
				 WHERE parent_sid = v_parent_section_sid
				 	ORDER BY section_position ASC) LOOP
			UPDATE section
		   	   SET section_position = v_position
		 	 WHERE section_sid = r_section.section_sid;
		 	v_position := v_position + 1;
		END LOOP;
	END IF;
END;

PROCEDURE ValidateVersion(
	in_section_sid			IN security_pkg.T_SID_ID,
	in_version				IN section_version.VERSION_NUMBER%TYPE
)
AS
	v_version_count			INT(10);
BEGIN
	-- TODO: is there a better way to do this!?
	SELECT COUNT(1)
	  INTO v_version_count
	  FROM section_version
	 WHERE SECTION_SID = in_section_sid
	   AND VERSION_NUMBER = in_version;

	 -- We are assuming that exceptions are propogated up the call stack until thay are caught
	 IF v_version_count = 0 THEN
	 	RAISE_APPLICATION_ERROR(ERR_INVALID_VERSION, 'Content for an invalid version was requested for section with sid '||in_section_sid);
	 END IF;
END;

-- NB - this automatically checks it out to this user
-- 'WithPerms' allows the G3 index importer for example to create nodes
-- where users don't have permissions to delete / add children etc
PROCEDURE CreateSectionWithPerms(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_access_perms			IN	security_pkg.T_PERMISSION,
	in_parent_sid_id		IN	security_pkg.T_SID_ID,
	in_title				IN	section_version.title%TYPE,
	in_title_only			IN	section.title_only%TYPE,
	in_body					IN	section_version.body%TYPE,
	in_help_text			IN	section.help_text%TYPE,
	in_ref					IN	section.ref%TYPE,
	in_further_info_url		IN	section.further_info_url%TYPE,
	in_plugin				IN  section.plugin%TYPE,
	in_auto_checkout		IN	NUMBER,
	out_sid_id				OUT	security_pkg.T_SID_ID
)
AS
	v_user_sid							security_pkg.T_SID_ID;
	v_visible_version_number			section_version.version_number%TYPE;
	v_checked_out_version_number		section_version.version_number%TYPE;
	v_parent_sid_id						security_pkg.T_SID_ID;
	v_so_section_name					section_version.title%TYPE;
	v_def_section_status_sid            security_pkg.T_SID_ID;
	v_flow_sid							security_pkg.T_SID_ID;
	v_flow_id							csr_data_pkg.T_FLOW_ITEM_ID;
BEGIN
	v_parent_sid_id := COALESCE(in_parent_sid_id, in_module_root_sid);

	-- Check add content permissions
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_parent_sid_id, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding contents to object with sid '||v_parent_sid_id);
	END IF;

	-- Truncate to 255 chars and remove '/' from the name
	-- TODO: this could lead to dupe onbject name errors??
	v_so_section_name := TruncateString(in_title, 255);
	v_so_section_name := replace(v_so_section_name,'/','\'); -- '
	-- createGroupWithClass will check permissions for us
	group_pkg.CreateGroupWithClass(in_act_id, v_parent_sid_id, security_pkg.GROUP_TYPE_SECURITY,
		v_so_section_name, class_pkg.getClassID('CSRSection'), out_sid_id);

	-- add this group to the DACL for this group object (members of this group have access to this and its children)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_sid_id), security_pkg.ACL_INDEX_LAST,
		security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, out_sid_id, in_access_perms);

	-- get the sid of this user
	user_pkg.GetSid(in_act_id, v_user_sid);

	v_visible_version_number := GetNextVersionNumber(out_sid_id);

	SELECT default_status_sid, flow_sid
	  INTO v_def_section_status_sid, v_flow_sid
	  FROM section_module
	 WHERE module_root_sid = in_module_root_sid;

	-- insert the section
	INSERT INTO section
		(section_sid, app_sid, module_root_sid, parent_sid,
		 section_position, title_only, section_status_sid,
		 help_text, further_info_url, plugin, ref)
	VALUES
		(out_sid_id, in_app_sid, in_module_root_sid, in_parent_sid_id,
		 GetNextSectionPosition(in_app_sid, in_module_root_sid, in_parent_sid_id),
		 in_title_only, v_def_section_status_sid,
		 in_help_text, in_further_info_url, in_plugin, in_ref);

	IF v_flow_sid IS NOT NULL THEN
		-- add flow item if it's in a workflow
		flow_pkg.AddSectionItem(out_sid_id, v_flow_id);
	END IF;

	-- insert this so that people can see it exists (with a null body)
	INSERT INTO SECTION_VERSION
		(section_sid, version_number, title, body, changed_by_sid, changed_dtm)
	VALUES
		(out_sid_id, v_visible_version_number, in_title, in_body, v_user_sid, SYSDATE);

	UPDATE section
	   SET visible_version_number = v_visible_version_number
	 WHERE section_sid = out_sid_id;

	IF in_auto_checkout = 1 THEN
		-- insert a fresh, checked out version for us to edit
		v_checked_out_version_number := GetNextVersionNumber(out_sid_id);

		INSERT INTO SECTION_VERSION
			(section_sid, version_number, title, body)
		VALUES
			(out_sid_id, v_checked_out_version_number, in_title, in_body);

		UPDATE SECTION
		   SET checked_out_to_sid = v_user_sid,
			   checked_out_dtm = SYSDATE,
			   checked_out_version_number = v_checked_out_version_number
		 WHERE section_sid = out_sid_Id;
	END IF;
END;

PROCEDURE CreateSection(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid_id		IN	security_pkg.T_SID_ID,
	in_title				IN	section_version.title%TYPE,
	in_title_only			IN	section.title_only%TYPE,
	in_body					IN	section_version.body%TYPE,
	in_auto_checkout		IN	NUMBER,
	out_sid_id				OUT	security_pkg.T_SID_ID
)
AS
	v_access_perms			security_pkg.T_PERMISSION;
BEGIN
	-- Standard access perms where adding a section is allowed in general use
	v_access_perms := security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_DELETE +
		security_pkg.PERMISSION_ADD_CONTENTS + csr_data_pkg.PERMISSION_CHANGE_TITLE + security_pkg.PERMISSION_WRITE;

	-- Create the sectioon with the given perms
	CreateSectionWithPerms(in_act_id, in_app_sid, in_module_root_sid, v_access_perms, in_parent_sid_id, in_title, in_title_only, in_body,
		null, -- help_text
		null, -- ref
		null, -- further info url
		null, -- section plugin
		in_auto_checkout, out_sid_id);
END;

PROCEDURE CopySection(
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid		IN 	security_pkg.T_SID_ID,
	in_title			IN	section_version.title%TYPE,
	out_section_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT');
	v_module_root_sid		security_pkg.T_SID_ID;
	v_body					section_version.body%TYPE;
	v_title					section_version.title%TYPE;
	v_parent_sid			security_pkg.T_SID_ID;
	v_attachment_id			security_pkg.T_SID_ID;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	v_flow_state_id			security_pkg.T_SID_ID;
	v_cache_keys			security_pkg.T_VARCHAR2_ARRAY;
	v_title_only			section.title_only%TYPE;
BEGIN
	-- read on source section
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;
	-- write on parent container
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;
	-- add contents on parent container
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_parent_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not able to copy object under sid '||in_parent_sid||' without add contents permissions');
	END IF;

	SELECT module_root_sid, parent_sid, sv.body, s.flow_item_id, s.title_only
	  INTO v_module_root_sid, v_parent_sid, v_body, v_flow_item_id, v_title_only
	  FROM section s
	  JOIN section_version sv ON s.section_sid = sv.section_sid AND sv.version_number = s.visible_version_number
	 WHERE s.section_sid = in_section_sid;

	IF in_parent_sid IS NOT NULL THEN
		v_parent_sid := in_parent_sid;
	END IF;

	-- create new section
	CreateSection(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'),
			v_module_root_sid,
			v_parent_sid,		-- parent_sid_id
			in_title,
			v_title_only,
			v_body,
			0, --in_auto_checkout
			out_section_sid
		);

	-- copy parent's sectiona attributes
	UPDATE section
	   SET
			(ref, plugin, plugin_config, section_status_sid, further_info_url, help_text) =
			(
			 SELECT ref, plugin, plugin_config, section_status_sid, further_info_url, help_text
			   FROM section
			  WHERE section_sid = v_parent_sid
			)
	 WHERE section_sid = out_section_sid;

	-- copy section tags
	FOR r IN (SELECT section_tag_id FROM section_tag_member WHERE section_sid = in_section_sid)
	LOOP
		section_pkg.AddTagToSection(out_section_sid, r.section_tag_id);
	END LOOP;

	-- copy flow state
	IF v_flow_item_id IS NOT NULL THEN
		SELECT CURRENT_STATE_ID
		  INTO v_flow_state_id
		  FROM flow_item
		 WHERE flow_item_id = v_flow_item_id;

		-- set flow state same as the source was
		flow_pkg.SetItemState(
			v_flow_item_id,
			v_flow_state_id,
			null,	-- in_comment_text
			v_cache_keys,
			SYS_CONTEXT('SECURITY','SID'),
			1 -- force item state change
		);
	END IF;

	-- copy attachments
	FOR r IN (
		SELECT a.filename, a.mime_type, a.data, a.embed, a.dataview_sid, a.last_updated_from_dataview, a.view_as_table, a.indicator_sid, a.doc_id, a.url, ah.attach_name, ah.pg_num, ah.attach_comment,
			ah.section_sid, ah.version_number
		  FROM attachment a, attachment_history ah, section_fact_attach sfa
		 WHERE a.ATTACHMENT_ID = ah.ATTACHMENT_ID
		   AND ah.SECTION_SID = in_section_sid
		   AND sfa.section_sid(+) = in_section_sid
		   AND sfa.attachment_id(+) = a.attachment_id
		   AND sfa.fact_id IS NULL
	)
	LOOP
		-- Generate a new attachment id
		SELECT attachment_id_seq.NEXTVAL
		  INTO v_attachment_id
		  FROM dual;

		-- Copy attachment data
		INSERT INTO attachment
			(ATTACHMENT_ID,FILENAME, MIME_TYPE,DATA,EMBED,DATAVIEW_SID,LAST_UPDATED_FROM_DATAVIEW,VIEW_AS_TABLE,INDICATOR_SID,DOC_ID,URL)
		VALUES
			(v_attachment_id, r.filename, r.mime_type, r.data, r.embed, r.dataview_sid, r.last_updated_from_dataview, r.view_as_table, r.indicator_sid, r.doc_id, r.url);

		-- set version number to 1
		INSERT INTO attachment_history
			(SECTION_SID, VERSION_NUMBER, ATTACHMENT_ID,ATTACH_NAME,PG_NUM,ATTACH_COMMENT)
		VALUES
			(out_section_sid, 1, v_attachment_id, r.attach_name, r.pg_num, r.attach_comment);

		--AddComment(v_act_id, out_section_sid, NULL, 'Attachments copied from section with sid: ' || in_section_sid);
	END LOOP;
END;

PROCEDURE SaveContent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_title				IN	section_version.title%TYPE,
	in_title_only			IN	section.title_only%TYPE,
	in_plugin				IN	section.plugin%TYPE,
	in_body					IN	section_version.body%TYPE,
	in_gen_attach_disabled	IN	section.disable_general_attachments%TYPE DEFAULT 0
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_checked_out_to_sid		security_pkg.T_SID_ID;
	v_latest_version_number		section_version.VERSION_NUMBER%TYPE;
	v_old_title					section_version.TITLE%TYPE;
BEGIN
	-- Check the user has write access to the section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	IF in_title_only != 1 THEN
		-- Get the sid of this user
		user_pkg.GetSID(in_act_id, v_user_sid);

		-- Get the sid of the user who has this section checked out
		v_checked_out_to_sid := GetCheckedOutToSID(in_section_sid);

		-- This user must have the section checked out
		IF v_checked_out_to_sid IS NULL THEN
			-- Section not checked out to anyone
			RAISE_APPLICATION_ERROR(ERR_NOT_CHECKED_OUT, 'Section with sid '||in_section_sid||' not checkd out');
		ELSIF v_checked_out_to_sid != v_user_sid THEN
			-- Section checked out by another user
			RAISE_APPLICATION_ERROR(ERR_CHECKED_OUT_OTHERUSER, 'Section with sid '||in_section_sid||' is checked out by another user');
		END IF;
	END IF;

	-- So we got here with no exceptions, we must have the correct access and the document checked out

	-- Get the latest version number
	v_latest_version_number := GetLatestVersion(in_section_sid);

	-- Should a change in title rename the obejct in security,
	-- would seem to make sense so we're going to do it now
	SELECT TITLE
	  INTO v_old_title
	  FROM section_version
	 WHERE SECTION_SID = in_section_sid
	   AND VERSION_NUMBER = v_latest_version_number;

	IF v_old_title != in_title THEN
		-- Check change title permissions
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, csr_data_pkg.PERMISSION_CHANGE_TITLE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Change title denied on object with sid '||in_section_sid);
		END IF;
		-- Rename securable object
		IF LENGTH(in_title) > 255 THEN
			securableobject_pkg.RenameSO(in_act_id, in_section_sid, '');
		ELSE
			securableobject_pkg.RenameSO(in_act_id, in_section_sid, replace(in_title,'/','\')); -- '
		END IF;
	END IF;

	-- Write the title and body data
	UPDATE section_version
	   SET TITLE = in_title, BODY = in_body
	 WHERE SECTION_SID = in_section_sid
	   AND VERSION_NUMBER = v_latest_version_number;

	UPDATE section
	   SET plugin = in_plugin, disable_general_attachments = in_gen_attach_disabled
	 WHERE SECTION_SID = in_section_sid;
END;

PROCEDURE GetLatestContent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_checked_out_to_sid	security_pkg.T_SID_ID;
BEGIN
	-- Check access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	-- Get the sid of this user
	user_pkg.GetSID(in_act_id, v_user_sid);

	-- Get the sid of the user who has this section checked out if any
	v_checked_out_to_sid := GetCheckedOutToSID(in_section_sid);

	-- If this user has the section checked out then get the very
	-- latest content, otherwise get the latest checked in content
	IF v_user_sid = v_checked_out_to_sid THEN
		GetContent(in_act_id, in_section_sid, GetLatestVersion(in_section_sid), out_cur);
	ELSE
		GetLatestCheckedInContent(in_act_id, in_section_sid, out_cur);
	END IF;
END;

PROCEDURE GetLatestCheckedInContent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_checked_out_to_sid	security_pkg.T_SID_ID;
BEGIN
	-- Check access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	-- Get the latest checked in content
	GetContent(in_act_id, in_section_sid, GetLatestCheckedInVersion(in_section_sid), out_cur);
END;

PROCEDURE GetLatestApprovedContent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_checked_out_to_sid	security_pkg.T_SID_ID;
BEGIN
	-- Check access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	-- Get the latest approved content
	GetContent(in_act_id, in_section_sid, GetLatestApprovedVersion(in_section_sid), out_cur);
END;

PROCEDURE GetSection(
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check for read access on section object
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	-- Return content for the specified or computed version
	OPEN out_cur FOR
		SELECT section_sid, parent_sid, checked_out_to_sid, checked_out_dtm, checked_out_version_number, visible_version_number,
			section_position, active, module_root_sid, title_only, ref, plugin, plugin_config, section_status_sid, further_info_url,
			help_text, flow_item_id, current_route_step_id, is_split
		  FROM section
		 WHERE section_sid = in_section_sid;
END;

PROCEDURE GetContent(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_version				IN	section_version.VERSION_NUMBER%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_write_access			NUMBER(1);
BEGIN
	-- Check for read access on section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	-- Check for write access
	v_write_access := 0;
		IF security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
			v_write_access := 1;
		END IF;

	-- Check the requested version exists (raises exception on invlaid version)
	ValidateVersion(in_section_sid, in_version);

	-- Return content for the specified or computed version
	OPEN out_cur FOR
		SELECT	v.section_sid,
				v.TITLE,
				v.BODY,
				v.APPROVED_BY_SID,
				v.APPROVED_DTM,
				u.FULL_NAME,
				v_write_access WRITE_ACCESS,
				s.title_only,
				s.section_status_sid,
				s.plugin,
				s.plugin_config,
				sm.label previous_module,
				s.disable_general_attachments
		  FROM	section_version v
		  JOIN section s ON s.SECTION_SID = v.SECTION_SID
		  LEFT JOIN csr_user u ON u.CSR_USER_SID = v.APPROVED_BY_SID
		  LEFT JOIN v$visible_version vv ON s.previous_section_sid = vv.section_sid -- if copied from previous section
		  LEFT JOIN section_module sm ON vv.module_root_sid = sm.module_root_sid
		 WHERE v.SECTION_SID = in_section_sid
		   AND v.VERSION_NUMBER = in_version;
END;

PROCEDURE CheckOut(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_checked_out_to_sid	security_pkg.T_SID_ID;
	v_version_number		section_version.VERSION_NUMBER%TYPE;
	v_title_only			section.title_only%TYPE;
BEGIN
	-- Check for write access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Check for title only section
	SELECT title_only
	  INTO v_title_only
	  FROM section
	 WHERE section_sid = in_section_sid;

	IF v_title_only != 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check out title-only section with sid '||in_section_sid);
	END IF;

	-- Get the sid of this user
	user_pkg.GetSID(in_act_id, v_user_sid);

	-- Get the sid of the user who has this section checked out if any
	v_checked_out_to_sid := GetCheckedOutToSID(in_section_sid);

	-- Check if this user already has the section checked ou	t
	IF v_checked_out_to_sid = v_user_sid THEN
		-- Is this an error condition, it's not fatal so just return?
		RETURN;
	END IF;

	-- Check to see if someone else has the section checked out
	IF v_checked_out_to_sid IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(ERR_CHECKED_OUT_OTHERUSER, 'Section with sid '||in_section_sid||' is checked out by another user');
	END IF;

	-- Right go ahead and check out the section to this user
	-- we MUST do this before we get the next version number (since this will effectively
	-- lock the row)
	UPDATE section
	   SET CHECKED_OUT_TO_SID = v_user_sid, CHECKED_OUT_DTM = SYSDATE
	 WHERE SECTION_SID = in_section_sid;

	-- Get next version number
	v_version_number := GetNextVersionNumber(in_section_sid);

	-- Update the version table with a new copy of the data and a new verison number
	INSERT INTO section_version
		(SECTION_SID, VERSION_NUMBER, TITLE, BODY)
		SELECT SECTION_SID, v_version_number, TITLE, BODY
		  FROM section_version
		 WHERE SECTION_SID = in_section_sid
		   AND VERSION_NUMBER = v_version_number-1;

	UPDATE section
	   SET CHECKED_OUT_VERSION_NUMBER = v_version_number
	 WHERE SECTION_SID = in_section_sid;
END;

PROCEDURE CheckIn(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_reason_for_change	IN	section_version.REASON_FOR_CHANGE%TYPE
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_checked_out_to_sid	security_pkg.T_SID_ID;
	v_latest_version		section_version.VERSION_NUMBER%TYPE;
BEGIN
	-- Check for write access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Get the sid of this user
	user_pkg.GetSID(in_act_id, v_user_sid);

	-- Get the sid of the user who has this section checked out if any
	v_checked_out_to_sid := GetCheckedOutToSID(in_section_sid);

	-- This user must have the section checked out
	IF v_checked_out_to_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(ERR_NOT_CHECKED_OUT, 'Section with sid '||in_section_sid||' is not checked out');
	ELSIF v_checked_out_to_sid != v_user_sid THEN
		RAISE_APPLICATION_ERROR(ERR_CHECKED_OUT_OTHERUSER, 'Section with sid '||in_section_sid||' is checked out by another user');
	END IF;
	 -- Getl latest version
	 v_latest_version := GetLatestVersion(in_section_sid);

	-- Clear the checkout status from the section table
	UPDATE section
	   SET CHECKED_OUT_TO_SID = NULL, CHECKED_OUT_DTM = NULL, CHECKED_OUT_VERSION_NUMBER = NULL,
	   		VISIBLE_VERSION_NUMBER = v_latest_version
	 WHERE SECTION_SID = in_section_sid;

	-- Update the verison table with the check-in information
	UPDATE section_version
	   SET CHANGED_BY_SID = v_user_sid, CHANGED_DTM = SYSDATE, REASON_FOR_CHANGE = in_reason_for_change
	 WHERE SECTION_SID = in_section_sid
	   AND VERSION_NUMBER = v_latest_version;
END;

PROCEDURE CancelChanges(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_deleted				OUT	NUMBER
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_checked_out_to_sid	security_pkg.T_SID_ID;
	v_version_number		section_version.version_number%TYPE;
BEGIN
	-- Check for write access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Get the sid of this user
	user_pkg.GetSID(in_act_id, v_user_sid);

	-- Get the sid of the user who has this section checked out if any
	v_checked_out_to_sid := GetCheckedOutToSID(in_section_sid);

	-- This user must have the section checked out
	IF v_checked_out_to_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(ERR_NOT_CHECKED_OUT, 'Section with sid '||in_section_sid||' is not checked out');
	ELSIF v_checked_out_to_sid != v_user_sid THEN
		RAISE_APPLICATION_ERROR(ERR_CHECKED_OUT_OTHERUSER, 'Section with sid '||in_section_sid||' is checked out by another user');
	END IF;

	-- Pass the call off to the internal version
	internal_CancelChanges(in_act_id, in_section_sid, out_deleted);
END;

PROCEDURE ForceCancelChanges(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_deleted				OUT	NUMBER
)
AS
	v_checked_out_to_sid	security_pkg.T_SID_ID;
	v_version_number		section_version.version_number%TYPE;
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	-- Get the csr root sid
	SELECT app_sid
	  INTO v_app_sid
	  FROM section
	 WHERE section_sid = in_section_sid;

	-- The user must be an admin to do this, check for write permission on the csr root sid
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - only admin users can forcibly undo check-outs');
	END IF;
	-- Check for write access on the section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Pass the call off to the internal version
	internal_CancelChanges(in_act_id, in_section_sid, out_deleted);
END;

PROCEDURE internal_CancelChanges(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_deleted				OUT	NUMBER
)
AS
	v_version_number		section_version.version_number%TYPE;
BEGIN
	-- Simply undoing the checkout is not a good idea as it will delete
	-- the node if there is no previous version, this not only confuses
	-- clients but we have seen a few cases where a node that has many
	-- children has been undone and all the children have been deleted
	-- too. We don't want this behaviour so we now do the following:
	--
	-- 1. If there are previous versions just roll-back as normal.
	-- 2. If there are no previous versions then check-in but with
	--    a null body text, this saves the customer loosing the node.
	--
	-- These changes coupled with a warning to the user that they will lose
	-- their changes if they cancel the check-out should address the issue.

	out_deleted := 0;
	v_version_number := GetLatestVersion(in_section_sid);

	IF v_version_number > 1 THEN
		-- Case 1: rollback as normal
		UndoCheckout(in_act_id, in_section_sid, out_deleted);
	ELSE
		-- Case 2: ckeck in with null body text
		UPDATE section_version
		   SET BODY = NULL
		 WHERE section_sid = in_section_sid
		   AND version_number = v_version_number;
		CheckIn(in_act_id, in_section_sid, '');
	END IF;
END;

PROCEDURE UndoCheckout(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_deleted				OUT	NUMBER
)
AS
	v_version				section_version.VERSION_NUMBER%TYPE;
BEGIN
	out_deleted := 0;
	-- Check for write access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Get latest version number for this section
	v_version :=  GetLatestVersion(in_section_sid);

	-- Hmm to avoid removeing attachments that have been added at the
	-- latest version level, set the version numbers to the previous version
	-- This is probably a very bad idea but until I have a solution this is how it will be.
	UPDATE attachment_history
	   SET VERSION_NUMBER = (v_version - 1)
	 WHERE SECTION_SID = in_section_sid
	   AND VERSION_NUMBER = v_version;

	-- Clear the checkout status from the section table
	UPDATE section
	   SET CHECKED_OUT_TO_SID = NULL, CHECKED_OUT_DTM = NULL, CHECKED_OUT_VERSION_NUMBER = NULL
	 WHERE SECTION_SID = in_section_sid;
	-- Remove the changes from the verison table
	DELETE FROM section_version
	 WHERE SECTION_SID = in_section_sid
	   AND VERSION_NUMBER = v_version;

	-- If this was the first version then we have effectively
	-- deleted the object, remove the obejct from security
	-- THIS REMOVED FOR SAFETY, IT'S BEEN CAUSING PROBLEMS!!
	/*
	IF GetLatestVersion(in_section_sid) IS NULL THEN
		group_pkg.DeleteGroup(in_act_id, in_section_sid);
		out_deleted := 1;
	END IF;
	*/
END;

PROCEDURE AddComment(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_in_reply_to_id		IN	section_comment.IN_REPLY_TO_ID%TYPE,
	in_comment_text			IN	section_comment.COMMENT_TEXT%TYPE

)
AS
	v_user_sid			security_pkg.T_SID_ID;
BEGIN
	-- Check for read access (yes users with read-only access are allowed to add comments!)
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	-- Get the sid of this user
	user_pkg.GetSID(in_act_id, v_user_sid);

	-- Insert the new comment
	IF LENGTH(TRIM(in_comment_text)) > 0 THEN
		INSERT INTO section_comment
			(SECTION_COMMENT_ID, SECTION_SID, IN_REPLY_TO_ID, COMMENT_TEXT, ENTERED_BY_SID, ENTERED_DTM)
		VALUES
			(section_comment_id_seq.NEXTVAL, in_section_sid, in_in_reply_to_id, in_comment_text, v_user_sid, SYSDATE);
	END IF;
END;

PROCEDURE RemoveComment(
	in_section_sid				IN	section.section_sid%TYPE,
	in_section_comment_id		IN	section_comment.section_comment_id%TYPE
)
AS
	v_section_ids	security_pkg.T_SID_IDS; -- it's going to be single one
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can delete section comments') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have capability to delete section comments');
	END IF;
	-- Check for write access on section object
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	SELECT section_sid
	   BULK COLLECT INTO v_section_ids
	  FROM section
	 WHERE section_sid = in_section_sid;

	DELETE FROM SECTION_COMMENT
	 WHERE SECTION_COMMENT_ID = in_section_comment_id
	   AND section_sid = in_section_sid;
END;

PROCEDURE RemoveTransitionComment(
	in_section_sid			IN	section.section_sid%TYPE,
	in_trans_comment_id		IN	section_trans_comment.section_trans_comment_id%TYPE
)
AS
	v_section_ids	security_pkg.T_SID_IDS; -- it's going to be single one
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can delete section comments') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have capability to delete section comments');
	END IF;
	-- Check for write access on section object
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	SELECT section_sid
	   BULK COLLECT INTO v_section_ids
	  FROM section
	 WHERE section_sid = in_section_sid;

	DELETE FROM SECTION_TRANS_COMMENT
	 WHERE section_trans_comment_id = in_trans_comment_id
	   AND section_sid = in_section_sid;
END;

PROCEDURE CloseComment(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_comment_id	IN	section_comment.SECTION_COMMENT_ID%TYPE
)
AS
	v_section_sid	security_pkg.T_SID_ID;
BEGIN
	-- TODO: do we also need to close all comments that are in reply
	-- to this comment or perhaps supply that as an option?
	-- Get the section sid so we can check for access
	SELECT section_sid
	  INTO v_section_sid
	  FROM section_comment
	 WHERE section_comment_id = in_section_comment_id;
	-- Check for write access on parent section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||v_section_sid);
	END IF;

	-- Set the closed flag
	UPDATE section_comment
	   SET is_closed = 1
	 WHERE section_comment_id = in_section_comment_id;
END;

PROCEDURE GetComments(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_in_reply_to_id		IN	section_comment.IN_REPLY_TO_ID%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check for read access on section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	-- If in_in_reply_to_id is null, select all comments relating to the specifed section
	-- otherwise select only comments in reply to the specified comment
	OPEN out_cur FOR
		SELECT sc.section_comment_id, sc.section_sid, sc.in_reply_to_id, sc.comment_text, sc.entered_by_sid,
			   cu.user_name entered_by_user_name, sc.entered_dtm
	 	  FROM section_comment sc, csr_user cu
	 	 WHERE sc.section_sid = in_section_sid
	 	   AND (in_in_reply_to_id IS NULL OR sc.in_reply_to_id = in_in_reply_to_id)
	 	   AND sc.is_closed = 0
	 	   AND sc.app_sid = cu.app_sid
	 	   AND sc.entered_by_sid = cu.csr_user_sid
	 	 ORDER BY sc.entered_dtm DESC;
END;

PROCEDURE GetVersionLog(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_max_records			IN	INT,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_now					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check for read access on section object
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;
	OPEN out_cur FOR
		SELECT *
		  FROM (
		  		-- some i18n issues here!
				SELECT 'flow_state_log' src, fsl.flow_state_log_id id, cu.full_name, 'Set to '||fs.label action, fsl.set_dtm dtm, comment_text, null param_1, null param_2, null param_3
				  FROM section s
				  JOIN flow_state_log fsl ON s.flow_Item_id = fsl.flow_Item_id AND s.app_sid = fsl.app_sid
				  JOIN flow_state fs ON fsl.flow_state_id = fs.flow_state_id AND fsl.app_sid = fs.app_sid
				  JOIN csr_user cu ON fsl.set_by_user_sid = cu.csr_user_sid AND fsl.app_sid = cu.app_sid
				 WHERE s.section_sid = in_section_sid
				 UNION ALL
				SELECT 'section_trans_comment' src, section_trans_comment_id id, cu.full_name, 'Comment' action, entered_dtm dtm, comment_text, null param_1, null param_2, null param_3
				  FROM section_trans_comment stc
				  JOIN csr_user cu ON stc.entered_by_sid = cu.csr_user_sid AND stc.app_sid = cu.app_sid
				 WHERE stc.section_sid = in_section_sid
				 UNION ALL
				SELECT 'section_comment' src, section_comment_id id, cu.full_name, 'Feedback' action, entered_dtm dtm, comment_text, null param_1, null param_2, null param_3
				  FROM section_comment sc
				  JOIN csr_user cu ON sc.entered_by_sid = cu.csr_user_sid AND sc.app_sid = cu.app_sid
				 WHERE sc.section_sid = in_section_sid
				 UNION ALL
				SELECT 'section_version' src, sv.version_number id, cu.full_name, 'Version '||sv.version_number action, sv.changed_dtm dtm, sv.reason_for_change comment_text, null param_1, null param_2, null param_3
				  FROM section_version sv
				  JOIN csr_user cu ON sv.changed_by_sid = cu.csr_user_sid AND sv.app_sid = cu.app_sid
				 WHERE sv.section_sid = in_section_sid
				 UNION ALL
				SELECT 'route_log' src, route_log_id id, cu.full_name, summary action, log_date dtm, description comment_text, param_1, param_2, param_3
 				  FROM route_log rl
				  JOIN csr_user cu ON rl.csr_user_sid = cu.csr_user_sid AND rl.app_sid = cu.app_sid
				  JOIN route r ON r.route_id = rl.route_id AND r.app_sid = rl.app_sid
 				 WHERE r.section_sid = in_section_sid
				UNION ALL
				SELECT 'section_attach_log' src, section_attach_log_id id, cu.full_name, summary action, log_date dtm, description comment_text, param_1, param_2, param_3
				  FROM section_attach_log sal
				  JOIN csr_user cu ON sal.csr_user_sid = cu.csr_user_sid AND sal.app_sid = cu.app_sid
 				 WHERE sal.section_sid = in_section_sid
				 ORDER BY dtm DESC, id DESC
		  )
		  WHERE in_max_records IS NULL OR rownum <= in_max_records;

	-- lame I know but can't be bothered to do a proper output param
	OPEN out_now FOR
		SELECT SYSDATE now FROM DUAL;
END;

-- these are possibly deprecated since they use the old approval stuff. Consider removing.
PROCEDURE ApproveVersion(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_version				IN	section_version.VERSION_NUMBER%TYPE
)
AS
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	-- Check for write access on section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Get the sid of this user
	user_pkg.GetSID(in_act_id, v_user_sid);

	-- Check the version is valid (raises exception on invalid version)
	ValidateVersion(in_section_sid, in_version);

	-- Approve the version
	UPDATE section_version
	   SET APPROVED_BY_SID = v_user_sid, APPROVED_DTM = SYSDATE
	 WHERE SECTION_SID = in_section_sid
	   AND VERSION_NUMBER = in_version;
END;

-- these are possibly deprecated since they use the old approval stuff. Consider removing.
PROCEDURE ApproveLatestCheckedInVersion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID
)
AS
	v_version			section_version.VERSION_NUMBER%TYPE;
BEGIN
	-- Check for write access on section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	v_version := GetLatestCheckedInVersion(in_section_sid);

	ApproveVersion(in_act_id, in_section_sid, v_version);
END;

PROCEDURE GetUserMountPoints(
	in_module_root_sid	IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT v.section_sid, title, null csr_user_sid, class_pkg.GetClassName(class_id) class_name,
			   section_pkg.SecurableObjectChildCount(SYS_CONTEXT('SECURITY','ACT'), v.section_sid) has_children, s.title_only
		  FROM section s
          JOIN section_version v
          		ON s.section_sid = v.section_sid
           		AND DECODE(checked_out_to_sid, SYS_CONTEXT('SECURITY','SID'), s.checked_out_version_number, s.visible_version_number) = v.version_number
          JOIN security.securable_object so ON s.section_sid = so.sid_id
		 WHERE v.section_sid IN (
				SELECT section_sid
				  FROM section
				 WHERE parent_sid IS NULL
				   AND active = 1
				   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), section_sid, security_pkg.PERMISSION_READ) != 0
				   AND module_root_sid = in_module_root_sid
            )
		 ORDER BY s.section_position ASC;
END;

PROCEDURE GetTreeNodeChildren(
	in_parent_sid 		IN security_pkg.T_SID_ID,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading section information');
	END IF;

	OPEN out_cur FOR
		SELECT v.section_sid, title, null csr_user_sid, class_pkg.GetClassName(class_id) class_name,
			SecurableObjectChildCount(SYS_CONTEXT('SECURITY','ACT'), v.section_sid) has_children, s.title_only
		  FROM section s
          JOIN section_version v
          		ON s.section_sid = v.section_sid
           		AND DECODE(checked_out_to_sid, SYS_CONTEXT('SECURITY','SID'), s.checked_out_version_number, s.visible_version_number) = v.version_number
          JOIN security.securable_object so ON s.section_sid = so.sid_id
		 WHERE active = 1
		   AND v.section_sid IN(
				SELECT section_sid
				  FROM section
				 WHERE PARENT_SID = in_parent_sid
				   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), section_sid, security_pkg.PERMISSION_READ) != 0
			)
		  ORDER BY s.section_position ASC;
END;

-- Return a list of attachment information
PROCEDURE GetAttachmentList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	out_attachments		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_docs_sid			security_pkg.T_SID_ID;
BEGIN
	-- Check read access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	BEGIN
		v_docs_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'Documents');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_docs_sid := -1;
	END;

	OPEN out_attachments FOR
		SELECT attachment.ATTACHMENT_ID, attachment.FILENAME, attachment.MIME_TYPE, attachment.DATAVIEW_SID, attachment.DOC_ID,
			attachment.LAST_UPDATED_FROM_DATAVIEW, attachment_history.VERSION_NUMBER, dataview.NAME DATAVIEW_NAME, attachment.VIEW_AS_TABLE,
			attachment.INDICATOR_SID ind_sid, ind.NAME ind_name, ind.DESCRIPTION ind_description, ind.IND_TYPE, attachment.embed, attachment.url,
			attachment_history.attach_name name, attachment_history.pg_num page, attachment_history.attach_comment "COMMENT", sfa.fact_id, sfa.fact_idx,
			decode(doc_folder_pkg.GetLibraryContainer(dc.parent_sid),v_docs_sid,1,0) in_doc_lib
		  FROM attachment, attachment_history, dataview, v$ind ind, section_fact_attach sfa, v$doc_current dc
		 WHERE attachment.ATTACHMENT_ID = attachment_history.ATTACHMENT_ID
		   AND attachment_history.SECTION_SID = in_section_sid
		   AND dataview.DATAVIEW_SID(+) = attachment.DATAVIEW_SID
		   AND ind.IND_SID(+) = attachment.INDICATOR_SID
		   AND sfa.attachment_id(+) = attachment.attachment_id
		   AND sfa.section_sid(+) = in_section_sid
		   AND attachment.doc_id = dc.doc_id(+)
		 ORDER BY attachment.ATTACHMENT_ID;
END;

-- Return a list of content doc information
PROCEDURE GetContentDocList (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	out_content_docs	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check read access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	OPEN out_content_docs FOR
		SELECT scd.DOC_ID
		 FROM section_content_doc scd
		 WHERE scd.section_sid = in_section_sid;
END;

PROCEDURE GetContentDocData (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_doc_id			IN	section_content_doc.DOC_ID%TYPE,
	out_content_doc		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check read access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	OPEN out_content_doc FOR
		SELECT scd.doc_id, doc.FILENAME, doc.MIME_TYPE, doc.data
		  FROM section_content_doc scd
		  JOIN v$doc_current doc ON scd.doc_id = doc.doc_id
		 WHERE scd.section_sid = in_section_sid;
END;

-- Create Attachment from cache
PROCEDURE CreateAttachmentFromCache(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_dataview_sid		IN	security_pkg.T_SID_ID,
    in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	in_embed        	IN	attachment.embed%TYPE,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE,
	in_fact_id			IN	section_fact.fact_id%TYPE,
	in_fact_idx			IN	section_fact_attach.fact_idx%TYPE,
	out_attachment_id	OUT	attachment.ATTACHMENT_ID%TYPE
)
AS
	v_filename			aspen2.filecache.FILENAME%TYPE;
	v_mime_type			aspen2.filecache.MIME_TYPE%TYPE;
	v_data				aspen2.filecache.OBJECT%TYPE;
	v_index_library		section_module.LIBRARY_SID%TYPE;
	v_version			attachment_history.VERSION_NUMBER%TYPE;
	v_updated_dtm		attachment.LAST_UPDATED_FROM_DATAVIEW%TYPE;
	v_doc_id			doc_version.DOC_ID%TYPE;
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	SELECT library_sid
	  INTO v_index_library
	  FROM section_module
	 WHERE module_root_sid = (select module_root_sid from section where section_sid = in_section_sid);

	SELECT filename, mime_type, object
	  INTO v_filename, v_mime_type, v_data
	  FROM aspen2.filecache
	 WHERE cache_key = in_cache_key;

	-- Should the user have the section checked out to add attachments?
	doc_pkg.SaveDoc(
		in_doc_id				=> NULL, --DOC_ID
		in_parent_sid			=> v_index_library, --Parent_Sid
		in_filename				=> v_filename,
		in_mime_type			=> v_mime_type,
		in_data					=> v_data,
		in_description			=> 'Attachment for section', --Description
		in_change_description	=> 'Created', --change description
		out_doc_id				=> v_doc_id);

	CreateDocumentAttachment(in_act_id, in_section_sid, v_doc_id, in_name, in_pg_num, in_comment, in_fact_id, in_fact_idx, out_attachment_id);
END;

PROCEDURE GetAttachmentData(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_attachment_id	IN	attachment.ATTACHMENT_ID%TYPE,
	out_attachment		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check read access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	OPEN out_attachment FOR
		SELECT attachment.FILENAME, attachment.MIME_TYPE, NVL(attachment.DATA, dc.DATA) data, dataview.NAME DATAVIEW_NAME, attachment.VIEW_AS_TABLE, dataview.DATAVIEW_SID,
			attachment.INDICATOR_SID ind_sid, ind.NAME ind_name, ind.DESCRIPTION ind_description, ind.IND_TYPE, attachment.embed, attachment.url, attachment.doc_id,
			attachment_history.pg_num page
		  FROM attachment, attachment_history, dataview, v$ind ind, v$doc_current dc
		 WHERE attachment_history.SECTION_SID = in_section_sid
		   AND attachment.ATTACHMENT_ID = attachment_history.ATTACHMENT_ID
		   AND attachment.ATTACHMENT_ID = in_attachment_id
		   AND dataview.DATAVIEW_SID(+) = attachment.DATAVIEW_SID
		   AND ind.IND_SID(+) = attachment.INDICATOR_SID
		   AND attachment.doc_id = dc.doc_id(+)
		 ORDER BY attachment.attachment_id;
END;

PROCEDURE RemoveAttachment(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_attachment_id	IN 	attachment.ATTACHMENT_ID%TYPE
)
AS
	v_filename			attachment.FILENAME%TYPE;
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	SELECT filename
	  INTO v_filename
	  FROM attachment
	 WHERE ATTACHMENT_ID = in_attachment_id;

	DELETE FROM attachment_history
	 WHERE SECTION_SID = in_section_sid
	   AND ATTACHMENT_ID = in_attachment_id;

	DELETE FROM section_fact_attach
	 WHERE section_sid = in_section_sid
	   AND attachment_id = in_attachment_id;

	DELETE FROM attachment
	 WHERE ATTACHMENT_ID = in_attachment_id;

	DELETE FROM section_plugin_lookup
	 WHERE section_sid = in_section_sid
	   AND plugin_name = v_filename;

	INSERT INTO section_attach_log
		(SECTION_SID, SECTION_ATTACH_LOG_ID, ATTACHMENT_ID, LOG_DATE, CSR_USER_SID, SUMMARY, DESCRIPTION, PARAM_1, PARAM_2, PARAM_3)
		VALUES (in_section_sid, sec_attach_log_id_seq.nextval, in_attachment_id, sysdate, sys_context('security','sid'), 'Attachment change', 'Attachment {0} removed', v_filename, null, null);
END;

/*
 * Used to export to word only specific sections
 */
PROCEDURE GetDocumentSections(
	in_section_sids		IN	security_pkg.T_SID_IDS,
	out_sections		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_ids		security.T_SID_TABLE;
BEGIN
	t_section_ids := security_pkg.SidArrayToTable(in_section_sids);

	-- NOTE: It will return only sections user has READ permissions, ignoring others without announcing it

	-- Return data for specified sections only
	-- HACK level will stay as 1, this is going to produce flat list of sections

	OPEN out_sections FOR
		SELECT swt.section_sid,
				swt.ref,
				ac.body,
				swt.plugin,
				ac.plugin_config,
				swt.lvl,
				swt.rn,
				swt.title,
				swt.title_only,
				swt.previous_section_sid,
				swt.previous_ref,
				swt.tags,
				ac.help_text
		  FROM
			(SELECT sv.section_sid SECTION_SID,
					s.ref,
					s.plugin,
					st.lvl,
					st.rn,
					CASE WHEN s.is_split = 1 THEN (
						SELECT title || ' / ' from v$visible_version where section_sid = s.parent_sid
					) ELSE NULL END || sv.title TITLE,
					s.title_only,
					p.section_sid previous_section_sid,
					p.ref previous_ref,
					replace(replace(stragg(replace(stag.tag,',','~')),',','|'),'~',',') tags
			   FROM section_version sv, section s, section p,
					(
					SELECT section_sid, level lvl, rownum rn
						  FROM section
						 WHERE active = 1
						 START WITH parent_sid IS NULL
					   CONNECT BY PRIOR section_sid = parent_sid
						ORDER SIBLINGS BY module_root_sid, section_position
					) st, section_tag stag, section_tag_member stm
			 WHERE s.active = 1
			   AND s.previous_section_sid = p.section_sid(+)
			   AND s.section_sid IN (SELECT column_value FROM TABLE(t_section_ids))
			   AND st.section_sid = s.section_sid
			   AND sv.section_sid = s.section_sid
			   AND sv.version_number = s.visible_version_number
			   AND stm.section_sid(+) = s.section_sid
			   AND stag.section_tag_id(+) = stm.section_tag_id
			   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), s.section_sid, security_pkg.PERMISSION_READ) = 1
			 GROUP BY sv.section_sid, s.ref, s.plugin, st.lvl, st.rn, sv.title, s.title_only, p.section_sid, p.ref, s.is_split, s.parent_sid) swt --Section With Tags
		 JOIN v$visible_version ac ON swt.section_sid = ac.section_sid --Additional Columns
		 ORDER BY swt.rn;
END;

-- Tags can be in a hierarchy so name could occur more than once...
-- You can pass in a / separated path. No security as it's not
-- really that exciting to figure out that a certain tag exists.
-- Returns -1 if it doesn't exist as C# handles NULL return values
-- really badly.
FUNCTION GetTagId(
	in_path  IN  VARCHAR2
) RETURN section_tag.section_tag_id%TYPE
AS
	v_tag_id section_tag.section_tag_id%TYPE;
BEGIN
	SELECT NVL(MIN(section_tag_id), -1)
	  INTO v_tag_id
	  FROM (
	    SELECT section_tag_id, LOWER(REPLACE(LTRIM(SYS_CONNECT_BY_PATH(REPLACE(TRIM(tag),'/',CHR(0)), '/'),'/'),CHR(0),'/')) path
	      FROM section_tag
	     WHERE app_sid = security_pkg.getApp
	     START WITH parent_id IS NULL CONNECT BY PRIOR section_tag_id = parent_id
	)
	WHERE path = LOWER(TRIM(in_path));

	RETURN v_tag_id;
END;

/*
 * This is legacy procedure used to export single section or whole module. If section_sid
 * is a module, then you get the whole lot.
 */
PROCEDURE GetDocumentSections(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_section_tag_id 	IN  section_tag_member.section_tag_id%TYPE,
	out_sections		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_is_module		NUMBER(10);
BEGIN
	-- Check for read access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	-- bit icky -- is the sid a "module", or just a node in the tree?
	SELECT COUNT(*)
	  INTO v_is_module
	  FROM section
	 WHERE module_root_sid = in_section_sid;

	IF v_is_module = 0 THEN
		-- Return data for specified section and all children
		OPEN out_sections FOR
			SELECT os.section_sid, os.ref, os.title, os.plugin, os."LEVEL", os.lvl, os.title_only,
				    os.previous_section_sid, os.previous_ref, os.rn, os.tags, ac.body, ac.help_text, ac.plugin_config
			  FROM
				(SELECT s.section_sid, s.ref, s.title, s.plugin, s."LEVEL", s.lvl, s.title_only,
						s.previous_section_sid, s.previous_ref, s.rn, replace(replace(stragg(replace(st.tag,',','~')),',','|'),'~',',') tags
				  FROM (
					SELECT vv.section_sid, vv.ref, vv.title, vv.plugin, level, level lvl, vv.title_only,
						vv.previous_section_sid, p.ref previous_ref, rownum rn
					  FROM v$visible_version vv
					  LEFT JOIN section p ON vv.previous_section_sid = p.section_sid AND vv.app_sid = p.app_sid
					 WHERE vv.active = 1
					 START WITH vv.section_sid = in_section_sid
				   CONNECT BY PRIOR vv.section_sid = vv.parent_sid
					 ORDER SIBLINGS BY vv.section_position
				) s
				 LEFT JOIN section_tag_member stm ON s.section_sid = stm.section_sid
				 LEFT JOIN section_tag st ON stm.section_tag_id = st.section_tag_id
				WHERE in_section_tag_id IS NULL OR s.section_sid IN (
					SELECT section_sid
					  FROM section
					 START WITH section_sid IN (
						SELECT section_sid FROM section_tag_member WHERE section_tag_id = in_section_tag_id
					)
					CONNECT BY PRIOR parent_sid = section_sid
				)
				GROUP BY s.section_sid, s.ref, s.title, s.plugin, s."LEVEL", s.lvl, s.title_only,
						s.previous_section_sid, s.previous_ref, s.rn) os --Ordered Sections
			JOIN v$visible_version ac ON os.section_sid = ac.section_sid --Additional Columns
			ORDER BY rn;
	ELSE
		-- Return data for whole tree and all children
		OPEN out_sections FOR
			SELECT os.section_sid, os.ref, os.title, os.plugin, os."LEVEL", os.lvl, os.title_only,
				    os.previous_section_sid, os.previous_ref, os.rn, os.tags, ac.body, ac.help_text, ac.plugin_config
			  FROM (
				SELECT s.section_sid, s.ref, s.title, s.plugin, s."LEVEL", s.lvl, s.title_only,
						s.previous_section_sid, s.previous_ref, s.rn, replace(replace(stragg(replace(st.tag,',','~')),',','|'),'~',',') tags
				  FROM (
					SELECT vv.section_sid, vv.ref, vv.title, vv.plugin, level, level lvl, vv.help_text, vv.title_only,
						vv.previous_section_sid, p.ref previous_ref, rownum rn
					  FROM v$visible_version vv
					  LEFT JOIN section p ON vv.previous_section_sid = p.section_sid AND vv.app_sid = p.app_sid
					 WHERE vv.active = 1
					   AND vv.module_root_sid = in_section_sid
					 START WITH vv.parent_sid IS NULL
				   CONNECT BY PRIOR vv.section_sid = vv.parent_sid
					 ORDER SIBLINGS BY vv.section_position
				) s
				 LEFT JOIN section_tag_member stm ON s.section_sid = stm.section_sid
				 LEFT JOIN section_tag st ON stm.section_tag_id = st.section_tag_id
				WHERE in_section_tag_id IS NULL OR s.section_sid IN (
					SELECT section_sid
					  FROM section
					 START WITH section_sid IN (
						SELECT section_sid FROM section_tag_member WHERE section_tag_id = in_section_tag_id
					)
					CONNECT BY PRIOR parent_sid = section_sid
				)
				GROUP BY s.section_sid, s.ref, s.title, s.plugin, s."LEVEL", s.lvl, s.title_only,
							s.previous_section_sid, s.previous_ref, s.rn) os --Ordered Sections
			 JOIN v$visible_version ac ON os.section_sid = ac.section_sid --Additional Columns
			ORDER BY rn;
	END IF;
END;

PROCEDURE GetDocumentSections(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	out_sections		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetDocumentSections(
		in_act_id 			=> in_act_id,
		in_section_sid 		=> in_section_sid,
		in_section_tag_id 	=> null,
		out_sections 		=> out_sections
	);
END;

PROCEDURE GetRouteUpTree(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_section_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT section_sid, module_root_sid
		  FROM SECTION
		 START WITH section_sid = in_section_sid
		 CONNECT BY PRIOR parent_sid = section_sid
		 ORDER BY LEVEL DESC;
END;

PROCEDURE CreateIndicatorAttachment(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_indicator_sid	IN	security_pkg.T_SID_ID,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE,
	in_fact_id			IN	section_fact.fact_id%TYPE,
	in_fact_idx			IN	section_fact_attach.fact_idx%TYPE,
	out_attachment_id	OUT	attachment.ATTACHMENT_ID%TYPE
)
AS
	v_version			attachment_history.VERSION_NUMBER%TYPE;
	v_updated_dtm		attachment.LAST_UPDATED_FROM_DATAVIEW%TYPE;
	v_indicator_name	ind.name%TYPE;
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Generate a new attachment id
	SELECT attachment_id_seq.NEXTVAL
	  INTO out_attachment_id
	  FROM dual;

	-- Get the indicator name
	SELECT name
	  INTO v_indicator_name
	  FROM ind
	 WHERE ind_sid = in_indicator_sid;

	-- Insert the data into the attachment table
	INSERT INTO attachment
		(ATTACHMENT_ID, FILENAME, MIME_TYPE, INDICATOR_SID)
      VALUES (out_attachment_id, v_indicator_name, 'application/indicator-sid', in_indicator_sid);

    -- Link the attachment data to the correct section
    v_version := GetLatestVersion(in_section_sid);

    INSERT INTO attachment_history
    		(SECTION_SID, VERSION_NUMBER, ATTACHMENT_ID)
    	VALUES (in_section_sid, v_version, out_attachment_id);

    --AddComment(in_act_id, in_section_sid, NULL, 'Created indicator attachment: ' || v_indicator_name);

	IF in_fact_id IS NOT NULL THEN
		INSERT INTO csr.section_fact_attach (fact_id, section_sid, attachment_id, fact_idx)
		VALUES (in_fact_id, in_section_sid, out_attachment_id, in_fact_idx);
	END IF;
END;

PROCEDURE CreateDocumentAttachment(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_doc_id					IN	security_pkg.T_SID_ID,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE,
	in_fact_id			IN	section_fact.fact_id%TYPE,
	in_fact_idx			IN	section_fact_attach.fact_idx%TYPE,
	out_attachment_id	OUT	attachment.ATTACHMENT_ID%TYPE
)
AS
	v_version						attachment_history.VERSION_NUMBER%TYPE;
	v_updated_dtm				attachment.LAST_UPDATED_FROM_DATAVIEW%TYPE;
	v_document_name 		doc_version.filename%TYPE;
	v_mime_type					doc_data.mime_type%TYPE;
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Generate a new attachment id
	SELECT attachment_id_seq.NEXTVAL
	  INTO out_attachment_id
	  FROM dual;

	-- Get the document's latest version filenamename
	SELECT dv.filename, dd.mime_type
	  INTO v_document_name, v_mime_type
	  FROM doc_version dv
	  JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
	 WHERE doc_id = in_doc_id
	   AND version = (
						SELECT MAX(version)
						  FROM doc_version
						 WHERE doc_id = in_doc_id
					);
	-- Insert the data into the attachment table
	INSERT INTO attachment
		(ATTACHMENT_ID, FILENAME, MIME_TYPE, DOC_ID)
      VALUES (out_attachment_id, v_document_name, v_mime_type, in_doc_id);

    -- Link the attachment data to the correct section
    v_version := GetLatestVersion(in_section_sid);

    INSERT INTO attachment_history
    		(SECTION_SID, VERSION_NUMBER, ATTACHMENT_ID, ATTACH_NAME, PG_NUM, ATTACH_COMMENT)
    	VALUES (in_section_sid, v_version, out_attachment_id, in_name, in_pg_num, in_comment);

	INSERT INTO section_attach_log
		(SECTION_SID, SECTION_ATTACH_LOG_ID, ATTACHMENT_ID, LOG_DATE, CSR_USER_SID, SUMMARY, DESCRIPTION, PARAM_1, PARAM_2, PARAM_3)
		VALUES (in_section_sid, sec_attach_log_id_seq.nextval, out_attachment_id, sysdate, sys_context('security','sid'), 'Attachment change', 'Attachment {0} added', v_document_name, null, null);
    --AddComment(in_act_id, in_section_sid, NULL, 'Created document attachment: ' || v_document_name);

	IF in_fact_id IS NOT NULL THEN
		INSERT INTO csr.section_fact_attach (fact_id, section_sid, attachment_id, fact_idx)
		VALUES (in_fact_id, in_section_sid, out_attachment_id, in_fact_idx);
	END IF;
END;

PROCEDURE CreateAttachmentFromBlob(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_dataview_sid		IN	security_pkg.T_SID_ID,
	in_filename			IN	attachment.filename%TYPE,
	in_mime_type		IN	attachment.mime_type%TYPE,
	in_view_as_table	IN	attachment.view_as_table%TYPE,
	in_embed        	IN	attachment.embed%TYPE,
    in_data				IN	attachment.data%TYPE,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE,
	out_attachment_id	OUT	attachment.ATTACHMENT_ID%TYPE
)
AS
	v_version			attachment_history.VERSION_NUMBER%TYPE;
	v_updated_dtm		attachment.LAST_UPDATED_FROM_DATAVIEW%TYPE;
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Should the user have the section checked out to add attachments?

	-- Generate a new attachment id
	SELECT attachment_id_seq.NEXTVAL
	  INTO out_attachment_id
	  FROM dual;

	-- Get current dtm if the dataview sid is set
	v_updated_dtm := NULL;
	IF in_dataview_sid IS NOT NULL THEN
		v_updated_dtm := SYSDATE;
	END IF;

	-- Insert the data into the attachment table
	INSERT INTO attachment
		(ATTACHMENT_ID, FILENAME, MIME_TYPE, DATA, DATAVIEW_SID, LAST_UPDATED_FROM_DATAVIEW, VIEW_AS_TABLE, embed)
      VALUES (out_attachment_id, in_filename, in_mime_type, in_data, in_dataview_sid, v_updated_dtm, in_view_as_table, in_embed);

    -- Link the attachment data to the correct section
    v_version := GetLatestVersion(in_section_sid);

    INSERT INTO attachment_history
    		(SECTION_SID, VERSION_NUMBER, ATTACHMENT_ID)
    	VALUES (in_section_sid, v_version, out_attachment_id);

--    IF in_view_as_table = 1 THEN
--		AddComment(in_act_id, in_section_sid, NULL, 'Created table attachment:' || in_filename);
--	ELSE
--		AddComment(in_act_id, in_section_sid, NULL, 'Created chart attachment: ' || in_filename);
--	END IF;
END;

-- Update Attachemnt from cache
PROCEDURE UpdateAttachmentFromBlob(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_attachment_id	IN 	attachment.ATTACHMENT_ID%TYPE,
	in_dataview_sid		IN	security_pkg.T_SID_ID,
	in_filename			IN	attachment.filename%TYPE,
	in_mime_type		IN	attachment.mime_type%TYPE,
	in_view_as_table	IN	attachment.view_as_table%TYPE,
    in_data				IN	attachment.data%TYPE,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE
)
AS
	v_version			attachment_history.VERSION_NUMBER%TYPE;
	v_updated_dtm		attachment.LAST_UPDATED_FROM_DATAVIEW%TYPE;
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Should the user have the section checked out to update attachments?

	-- Get current dtm if the dataview sid is set
	v_updated_dtm := NULL;
	IF in_dataview_sid IS NOT NULL THEN
		v_updated_dtm := SYSDATE;
	END IF;

	-- Update the attachment data from the file cache
	UPDATE attachment
	   SET 	MIME_TYPE = in_mime_type,
	   		DATA = in_data,
	   		DATAVIEW_SID = in_dataview_sid,
	   		LAST_UPDATED_FROM_DATAVIEW = v_updated_dtm,
	   		VIEW_AS_TABLE = in_view_as_table
     WHERE ATTACHMENT_ID = in_attachment_id;

--    IF in_view_as_table = 1 THEN
--		AddComment(in_act_id, in_section_sid, NULL, 'Updated table attachment: ' || in_filename);
--	ELSE
--		AddComment(in_act_id, in_section_sid, NULL, 'Updated chart attachment: ' || in_filename);
--	END IF;
END;

PROCEDURE CreateURLAttachment(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_url				IN	attachment.url%TYPE,
	in_name				IN	attachment.filename%TYPE,
	in_pg_num			IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE,
	in_fact_id			IN	section_fact.fact_id%TYPE,
	in_fact_idx			IN	section_fact_attach.fact_idx%TYPE,
	out_attachment_id	OUT	attachment.ATTACHMENT_ID%TYPE
)
AS
	v_version			attachment_history.VERSION_NUMBER%TYPE;
	v_updated_dtm		attachment.LAST_UPDATED_FROM_DATAVIEW%TYPE;
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Generate a new attachment id
	SELECT attachment_id_seq.NEXTVAL
	  INTO out_attachment_id
	  FROM dual;

	-- Insert the data into the attachment table
	INSERT INTO attachment
		(ATTACHMENT_ID, URL, FILENAME, MIME_TYPE)
      VALUES (out_attachment_id, in_url, in_name, 'application/url');

    -- Link the attachment data to the correct section
    v_version := GetLatestVersion(in_section_sid);

    INSERT INTO attachment_history
    		(SECTION_SID, VERSION_NUMBER, ATTACHMENT_ID, ATTACH_NAME, PG_NUM, ATTACH_COMMENT)
    	VALUES (in_section_sid, v_version, out_attachment_id, in_name, in_pg_num, in_comment);

	INSERT INTO section_attach_log
		(SECTION_SID, SECTION_ATTACH_LOG_ID, ATTACHMENT_ID, LOG_DATE, CSR_USER_SID, SUMMARY, DESCRIPTION, PARAM_1, PARAM_2, PARAM_3)
		VALUES (in_section_sid, sec_attach_log_id_seq.nextval, out_attachment_id, sysdate, sys_context('security','sid'), 'Attachment change', 'Attachment {0} added', in_name, null, null);
--	AddComment(in_act_id, in_section_sid, NULL, 'Created URL attachment: ' || in_name);

	IF in_fact_id IS NOT NULL THEN
		INSERT INTO csr.section_fact_attach (fact_id, section_sid, attachment_id, fact_idx)
		VALUES (in_fact_id, in_section_sid, out_attachment_id, in_fact_idx);
	END IF;
END;

FUNCTION SecurableObjectChildCount(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_sid_id		IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count			NUMBER(10);
BEGIN
	SELECT COUNT(0)
	  INTO v_count
	  FROM TABLE(securableobject_pkg.GetChildrenAsTable(in_act_id, in_sid_id));
	RETURN v_count;
END;

PROCEDURE RepositionSection(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_module_root_sid	IN	security_pkg.T_SID_ID,
	in_section_sid		IN	security_pkg.T_SID_ID,
	in_new_position		IN	section.section_position%TYPE
)
AS
	v_parent_sid		security_pkg.T_SID_ID;
	v_new_position		section.section_position%TYPE;
	v_position			section.section_position%TYPE;
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;
	-- We will state that a user must have add/delete content permissions to move a section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not able to reposition object with sid '||in_section_sid||' without add contents permissions');
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Not able to reposition object with sid '||in_section_sid||' without delete contents permissions');
	END IF;

	-- Get the parent sid
	SELECT parent_sid
	  INTO v_parent_sid
	  FROM section
	 WHERE section_sid = in_section_sid;

	-- Get the maximum possible position
	IF v_parent_sid IS NULL THEN
		SELECT MAX(section_position)
			  INTO v_position
			  FROM section
			 WHERE parent_sid IS NULL
			   AND app_sid = in_app_sid
			   AND module_root_sid = in_module_root_sid;
	ELSE
		SELECT MAX(section_position)
			  INTO v_position
			  FROM section
			 WHERE parent_sid = v_parent_sid;
	END IF;

	 -- Bounds check the new position
	 v_new_position := in_new_position;
	 IF v_new_position < 0 THEN
	 	v_new_position := 0;
	 ELSIF v_new_position > v_position THEN
	 	v_new_position := v_position + 1;
	 END IF;

	 -- Re-order sections
	 v_position := 0;
	 IF v_parent_sid IS NULL THEN
	 	-- no parent (direct descendent of root)
	 	FOR r_section IN (
	 		SELECT section_sid, section_position
	 		  FROM section
	 		 WHERE app_sid = in_app_sid
	 		   AND module_root_sid =  in_module_root_sid
	 		   AND parent_sid IS NULL
	 		   	ORDER BY section_position ASC) LOOP
	 		-- Skip over the new position while re-ordering
	 		IF v_position = v_new_position THEN
	 			v_position := v_position + 1;
	 		END IF;
	 		-- Don't adjust the position of the object being modified while re-ordering
	 		IF r_section.section_sid != in_section_sid THEN
		 		UPDATE section
		 		   SET section_position = v_position
		 		 WHERE section_sid = r_section.section_sid;
		 		 v_position := v_position + 1;
		 	END IF;
	 	END LOOP;
	 ELSE
	 	-- Another section as parent
	 	FOR r_section IN (
	 		SELECT section_sid, section_position
	 		  FROM section
	 		 WHERE parent_sid = v_parent_sid
	 		   	ORDER BY section_position ASC) LOOP
	 		-- Skip over the new position while re-ordering
	 		IF v_position = v_new_position THEN
	 			v_position := v_position + 1;
	 		END IF;
	 		-- Don't adjust the position of the object being modified while re-ordering
	 		IF r_section.section_sid != in_section_sid THEN
		 		UPDATE section
		 		   SET section_position = v_position
		 		 WHERE section_sid = r_section.section_sid;
		 		 v_position := v_position + 1;
		 	END IF;
	 	END LOOP;
	 END IF;

	  --  Update the section's new position
 	UPDATE section
 	   SET section_position = v_new_position
 	 WHERE section_sid = in_section_sid;
END;

-- Update the section table with position data
PROCEDURE GeneratePositionData(
	in_app_sid		IN section.app_sid%TYPE
)
AS
	v_position		section.section_position%TYPE;
BEGIN
	-- position information for the root nodes
	v_position := 0;
	FOR r_section IN (
			SELECT section_sid
			  FROM section
			 WHERE parent_sid IS NULL
			   AND app_sid = in_app_sid
			   	ORDER BY section_sid) LOOP
		UPDATE section
			   SET section_position = v_position
			 WHERE section_sid = r_section.section_sid;
			v_position := v_position + 1;
	END LOOP;
	-- for each root section node
	FOR r_section IN (
			SELECT section_sid
			  FROM section
			 WHERE parent_sid IS NULL
			   AND app_sid = in_app_sid
			   	ORDER BY section_sid) LOOP
		PositionDataProcessNode(r_section.section_sid);
	END LOOP;
END;

PROCEDURE PositionDataProcessNode(
	in_parent_sid	IN security_pkg.T_SID_ID
)
AS
	v_position		section.section_position%TYPE;
BEGIN
	-- process parent section node
	v_position := 0;
	FOR r_section IN (SELECT section_sid
	  FROM (
		SELECT section_sid, level lvl
		  FROM section
			START WITH section_sid = in_parent_sid
			CONNECT BY PRIOR section_sid = parent_sid)
		WHERE lvl = 2 ORDER BY section_sid ASC) LOOP
			UPDATE section
			   SET section_position = v_position
			 WHERE section_sid = r_section.section_sid;
			v_position := v_position + 1;
	END LOOP;

	-- process direct decendent section nodes
	FOR r_section IN (SELECT section_sid
	  FROM (
		SELECT section_sid, level lvl
		  FROM section
			START WITH section_sid = in_parent_sid
			CONNECT BY PRIOR section_sid = parent_sid)
		WHERE lvl = 2) LOOP
		PositionDataProcessNode(r_section.section_sid);
	END LOOP;

END;

PROCEDURE GetWholeModule(
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	out_tree_cur			OUT	SYS_REFCURSOR,
	out_attachment_cur		OUT	SYS_REFCURSOR
)
AS
	t_tree			security.T_SO_TREE_TABLE;
	v_user_sid		security_pkg.T_SID_ID;
	v_docs_sid			security_pkg.T_SID_ID;
BEGIN
	-- we check the tree in both calls, so get it once here
	t_tree := securableobject_pkg.GetTreeWithPermAsTable(security_pkg.GetACT(), in_module_root_sid, security_pkg.PERMISSION_READ);
	v_user_sid := security_pkg.GetSID();

	BEGIN
		v_docs_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'Documents');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_docs_sid := -1;
	END;

	OPEN out_tree_cur FOR
		SELECT s.section_sid, s.title_only, s.ref ref, t.so_level-1 lvl, t.is_leaf, sv.version_number,
			sv.title, s.section_status_sid, length(sv.body) body_length, s.help_text, s.further_info_url,
			s.is_split, s.plugin, sv.body raw_body, s.disable_general_attachments,
			CASE
				WHEN NVL(checked_out_to_sid, v_user_sid) != v_user_Sid THEN 1
				ELSE 0
			END is_locked
		  FROM (
			SELECT rownum rn, lvl, section_sid, version_number
    		  FROM (
					SELECT level lvl, section_sid,
						 CASE
							 WHEN checked_out_to_sid = v_user_sid THEN checked_out_version_number
							 ELSE visible_version_number
						 END version_number
					  FROM section
				     WHERE active = 1
					 START WITH parent_sid IS NULL
					   AND module_root_sid = in_module_root_sid
				   CONNECT BY PRIOR section_sid = parent_sid
					   AND PRIOR active = 1
					ORDER SIBLINGS BY section_position
				)
		    )st, TABLE(t_tree)t,
				section s, section_version sv
		 WHERE t.sid_id = st.section_sid
		   AND st.section_sid = s.section_sid
		   AND s.module_root_sid = in_module_root_sid
		   AND s.section_sid = sv.section_sid
		   AND st.version_number = sv.version_number
		 ORDER BY st.rn;

	OPEN out_attachment_cur FOR
		SELECT ah.section_sid, ah.version_number, ah.attachment_id,
			CASE
				WHEN dataview_sid IS NOT NULL THEN 'dataview'
				WHEN ind_sid IS NOT NULL THEN 'indicator'
				WHEN a.data IS NOT NULL THEN 'file'
				WHEN a.doc_id IS NOT NULL THEN 'document'
				WHEN a.url IS NOT NULL THEN 'url'
				WHEN a.mime_type = 'application/form' THEN 'form'
				ELSE 'unknown'
			END type,
			CASE
				WHEN dataview_sid IS NOT NULL THEN a.filename
				WHEN ind_sid IS NOT NULL THEN i.description
				WHEN a.data IS NOT NULL THEN a.filename
				WHEN a.doc_id IS NOT NULL THEN a.filename
				WHEN a.url IS NOT NULL THEN a.filename
				WHEN a.mime_type = 'application/form' THEN a.filename
				ELSE 'unknown'
			END label,
			a.filename, a.mime_type,
			CASE
				WHEN a.data IS NULL THEN 0
				ELSE 1
			END has_data, a.doc_id, a.dataview_sid, a.last_updated_from_Dataview, a.view_as_table,
				i.ind_sid, indicator_pkg.INTERNAL_GetIndPathString(i.ind_Sid) ind_path, a.embed, a.url,
				ah.attach_name name, ah.attach_comment "COMMENT", ah.pg_num page,
				sfa.fact_id, sfa.fact_idx, decode(doc_folder_pkg.GetLibraryContainer(dc.parent_sid),v_docs_sid,1,0) in_doc_lib
		  FROM section s, section_version sv, attachment_history ah, attachment a, v$ind i, section_fact_attach sfa, v$doc_current dc
		 WHERE s.module_root_sid = in_module_root_sid
		   AND s.section_sid = sv.section_sid
		   AND sv.version_number = NVL(checked_out_version_number, visible_version_number)
			/*( -- this is how it should work, i.e. only shows attachments that are assigned to the version you can see.
				-- We're using NVL above to mimic how Dickie's code works at the moment
				CASE
					WHEN checked_out_to_sid = v_user_sid THEN checked_out_version_number
					ELSE visible_version_number
				END
		   )*/
		   --AND sv.version_number = ah.version_number
		   AND sv.section_sid = ah.section_sid
		   AND ah.attachment_id = a.attachment_id
		   AND a.indicator_sid = i.ind_Sid(+)
		   AND sfa.attachment_id(+) = ah.attachment_id
		   AND sfa.section_sid(+) = ah.section_sid
		   AND a.doc_id = dc.doc_id(+)
		   AND s.section_sid IN (
		   	  -- check permissions
		   	  SELECT sid_id FROM TABLE(t_tree)
		   )
		 ORDER BY attachment_id;
END;

/* Used by the grid view which doesn't require users to do a check out / check in */
PROCEDURE CheckoutAndUpdateBody(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_body					IN	section_version.body%TYPE,
	in_reason_for_change	IN	section_version.REASON_FOR_CHANGE%TYPE,
	in_section_status_sid	IN	security_pkg.T_SID_ID
)
AS
	v_title				section_version.title%TYPE;
	v_plugin			section.plugin%TYPE;
BEGIN
	section_pkg.CheckOut(security_pkg.GetACT(), in_section_sid);

	SELECT title
	  INTO v_title
	  FROM v$checked_out_version
	 WHERE section_sid = in_section_sid;

	SELECT plugin
	  INTO v_plugin
	  FROM section
	 WHERE section_sid = in_section_sid;
	-- Update status of section, only if permitted
	-- message if that's not allowed ?
	-- actually that should not happen because this status_sid won't appear on screen
	IF security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_section_status_sid, security_pkg.PERMISSION_READ) THEN
		UPDATE section
			 SET section_status_sid = in_section_status_sid
		 WHERE section_sid = in_section_sid;
	END IF;

	section_pkg.SaveContent(security_pkg.GetACT(), in_section_sid, v_title, 0, v_plugin, in_body);
	section_pkg.CheckIn(security_pkg.GetACT(), in_section_sid, in_reason_for_change);
END;

PROCEDURE AddTagToSection(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_tag_id				IN	security_PKG.T_SID_ID
)
AS
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	BEGIN
		INSERT
		  INTO section_tag_member (
				app_sid, section_sid, section_tag_id
		 ) VALUES (
				SYS_CONTEXT('SECURITY','APP'), in_section_sid,  in_tag_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE AddTagToSectionByName(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_tag_name				IN	section_tag.tag%TYPE
)
AS
	v_tag_id	security_pkg.T_SID_ID;
BEGIN

	SELECT min(section_tag_id)
	  INTO v_tag_id
	  FROM section_tag
	 WHERE tag = in_tag_name;

	IF v_tag_id IS NOT NULL THEN
		AddTagToSection(in_section_sid, v_tag_id);
	END IF;
END;

PROCEDURE RemoveTagFromSection(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_tag_id				IN	security_PKG.T_SID_ID
)
AS
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	DELETE FROM section_tag_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND section_sid = in_section_sid
	   AND section_tag_id = in_tag_id;
END;

PROCEDURE GetModuleSectionTags(
	in_module_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_section_ids		security_pkg.T_SID_IDS;
BEGIN
	-- Check for read access on section object
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_module_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_module_sid	);
	END IF;
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can view section tags') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to view section tags');
	END IF;
	-- collect sids of all sections belonging to module_sid
	SELECT section_sid
	  BULK COLLECT INTO v_section_ids
	  FROM section
	 WHERE module_root_sid = in_module_sid;

	-- get tags for all sections
	GetSectionsTags(v_section_ids, out_cur);
END;

PROCEDURE GetSectionsTags(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_ids		security.T_SID_TABLE;
BEGIN
	t_section_ids	:= security_pkg.SidArrayToTable(in_section_sids);

	OPEN out_cur FOR
		SELECT stm.section_sid, st.section_tag_id, st.tag, section_pkg.GetSectionTagPath(stm.section_tag_id) path
		  FROM section_tag st, section_tag_member stm
		 WHERE st.section_tag_id = stm.section_tag_id
		   AND st.active = 1
		   AND stm.section_sid IN (
				SELECT column_value
				  FROM TABLE(t_section_ids)
		)
		ORDER by section_sid, path;
END;

PROCEDURE CreateSectionTag(
	in_tag				IN	csr.section_tag.tag%TYPE,
	in_parent_id		IN	csr.section_tag.parent_id%TYPE,
	out_tag_id			OUT	csr.section_tag.tag%TYPE
)
AS
	v_cnt 				NUMBER(10);
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit section tags') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have capability to edit tags');
	END IF;

	-- check for duplicates [in a really BAD way - should use upsert and unique key constraint]
	SELECT count(section_tag_id)
	  INTO v_cnt
	  FROM section_tag
	 WHERE active = 1
	   AND lower(tag) = lower(in_tag)
	   AND ((in_parent_id IS NULL AND parent_id IS NULL) OR parent_id = in_parent_id);

	-- add only if no dups
	IF v_cnt = 0 THEN
		INSERT INTO SECTION_TAG
			(app_sid, parent_id, section_tag_id, tag)
		VALUES
			(security_pkg.getapp, in_parent_id, section_tag_id_seq.nextval, in_tag)
		RETURNING section_tag_id INTO out_tag_id;
	ELSE
		-- duplicate found
		out_tag_id := -1;
	END IF;
END;

PROCEDURE DeleteSectionTag(
	in_section_tag_id			IN	csr.section_tag.section_tag_id%TYPE,
	removed_ids_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit section tags') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have capability to edit tags');
	END IF;

	-- collect section_tag_ids of ones we're going to disactivate
	INSERT INTO TEMP_SECTION_FILTER
		SELECT section_tag_id
		  FROM section_tag
		 WHERE active = 1
		 START WITH section_tag_id = in_section_tag_id
	   CONNECT BY PRIOR section_tag_id = parent_id AND active = 1;
	-- set them as inactive
	UPDATE SECTION_TAG
	   SET active = 0
	 WHERE section_tag_id IN (SELECT section_sid FROM TEMP_SECTION_FILTER);

	-- return cursor with removed ids
	OPEN removed_ids_cur FOR
		SELECT section_sid section_tag_id FROM TEMP_SECTION_FILTER;
END;

PROCEDURE FilterSurvey(
	in_filter				IN	csr.section_module.label%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT module_root_sid, label
		  FROM section_module
		 WHERE lower(label) like '%'||lower(in_filter)||'%'
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), module_root_sid, security_pkg.PERMISSION_READ) = 1
		   AND active = 1
		  ORDER BY label;
END;

PROCEDURE FilterCart(
	in_filter				IN	csr.section_module.label%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT sc.section_cart_id, sc.name
		  FROM section_cart sc
			JOIN section_cart_member scm on sc.section_cart_id = scm.section_cart_id
			JOIN section s ON s.section_sid = scm.section_sid
		 WHERE lower(sc.name) like '%'||lower(in_filter)||'%'
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), s.module_root_sid, security_pkg.PERMISSION_READ) = 1;
END;

PROCEDURE FilterSectionTag(
	in_filter				IN	csr.section_tag.tag%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- hmmm... not sure if we need security check here and on what
	OPEN out_cur FOR
		SELECT section_tag_id, tag, replace(SYS_CONNECT_BY_PATH(replace(tag,chr(1),'_'),''), '','/') path
		  FROM section_tag
		 WHERE lower(tag) like '%'||lower(in_filter)||'%'
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND active = 1
		 START WITH parent_id IS NULL
	   CONNECT BY PRIOR section_tag_id = parent_id;
END;

PROCEDURE FilterStatus(
	in_filter				IN	csr.section_status.description%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT section_status_sid, description
		  FROM section_status
		 WHERE lower(description) like '%'||lower(in_filter)||'%';
END;

PROCEDURE FilterFlowState(
	in_filter				IN	csr.section_status.description%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT fs.flow_state_id, fs.label
		  FROM flow_state fs, section_module sm
		 WHERE sm.flow_sid = fs.flow_sid
		   AND lower(fs.label) like '%'||lower(in_filter)||'%'
		   AND fs.is_deleted = 0;
END;

PROCEDURE ApplyFilter(
	in_contains_text			IN	VARCHAR2,
	in_include_answers			IN	NUMBER,
	in_changed_dtm				IN	SECTION_VERSION.changed_dtm%TYPE,
	in_changed_dir				IN  NUMBER,
	in_flow_state_ids			IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_module_ids				IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_tag_ids					IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_assigned_to_ids			IN	security_pkg.T_SID_IDS,
	in_progress_state_ids		IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_section_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_path_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_flow_state_ids			security.T_SID_TABLE;
	t_module_ids				security.T_SID_TABLE;
	t_tag_ids					security.T_SID_TABLE;
	t_assigned_to_ids			security.T_SID_TABLE;
	t_progress_state_ids		security.T_SID_TABLE;
	t_section_sids				security.T_SID_TABLE;

	v_section_sids				security_pkg.T_SID_IDS;
	v_has_flow_state_filter		NUMBER DEFAULT 1;
	v_has_module_filter			NUMBER DEFAULT 1;
	v_has_tag_filter			NUMBER DEFAULT 1;
	v_has_assigned_to_filter	NUMBER DEFAULT 1;
	v_has_progress_state_filter	NUMBER DEFAULT 1;
	v_has_sid_filter			NUMBER DEFAULT 1;
	t_tree						security.T_SO_TREE_TABLE;
	v_user_sid					security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID');
	v_sanitised_search			VARCHAR2(4000) := aspen2.utils_pkg.SanitiseOracleContains(in_contains_text);
BEGIN
	t_flow_state_ids	:= security_pkg.SidArrayToTable(in_flow_state_ids);
	t_module_ids		:= security_pkg.SidArrayToTable(in_module_ids);
	t_tag_ids			:= security_pkg.SidArrayToTable(in_tag_ids);
	t_section_sids		:= security_pkg.SidArrayToTable(in_section_sids);
	t_assigned_to_ids	:= security_pkg.SidArrayToTable(in_assigned_to_ids);
	t_progress_state_ids	:= security_pkg.SidArrayToTable(in_progress_state_ids);

	IF in_flow_state_ids.COUNT = 0 OR (in_flow_state_ids.COUNT = 1 AND in_flow_state_ids(1) IS NULL) THEN
		v_has_flow_state_filter := 0;
	END IF;
	IF in_module_ids.COUNT = 0 OR (in_module_ids.COUNT = 1 AND in_module_ids(1) IS NULL) THEN
		v_has_module_filter := 0;
	END IF;
	IF in_tag_ids.COUNT = 0 OR (in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL) THEN
		v_has_tag_filter := 0;
	END IF;
	IF in_section_sids.COUNT = 0 OR (in_section_sids.COUNT = 1 AND in_section_sids(1) IS NULL) THEN
		v_has_sid_filter := 0;
	END IF;
	IF in_assigned_to_ids.COUNT = 0 OR (in_assigned_to_ids.COUNT = 1 AND in_assigned_to_ids(1) IS NULL) THEN
		v_has_assigned_to_filter := 0;
	END IF;
	IF in_progress_state_ids.COUNT = 0 OR (in_progress_state_ids.COUNT = 1 AND in_progress_state_ids(1) IS NULL) THEN
		v_has_progress_state_filter := 0;
	END IF;

	ctx_doc.set_key_type('ROWID');
	-- collect sids of filtered sections
	-- NOTE: There is a bug in Oracle 11g (BUG: 9149005/14113225) using CONTAINS with ANSI joins, the workaround is to use oracle style joins
	SELECT DISTINCT s.section_sid
	  BULK COLLECT INTO v_section_sids
	  FROM section s
	  JOIN section_version sv ON s.section_sid = sv.section_sid AND s.visible_version_number = sv.version_number AND s.app_sid = sv.app_sid
	  LEFT JOIN section sp ON s.parent_sid = sp.section_sid AND s.app_sid = sp.app_sid
	  LEFT JOIN section_version spv ON sp.section_sid = spv.section_sid AND sp.visible_version_number = spv.version_number AND sp.app_sid = spv.app_sid
	  LEFT JOIN section_tag_member stm ON s.section_sid = stm.section_sid AND s.app_sid = stm.app_sid
	  LEFT JOIN flow_item fi ON s.flow_item_id = fi.flow_item_id AND s.app_sid = fi.app_sid
	 WHERE (in_contains_text IS NULL
			OR (in_include_answers = 1 AND LENGTH(TRIM(v_sanitised_search)) > 0 AND (CONTAINS(sv.body, v_sanitised_search, 1) > 0 
				OR LOWER(DECODE(s.is_split, 1, spv.title||' '||sv.title, sv.title)) LIKE '%' ||LOWER(in_contains_text) || '%'))
			OR (in_include_answers = 0 AND LOWER(DECODE(s.is_split, 1, spv.title||' '||sv.title, sv.title)) LIKE '%' ||LOWER(in_contains_text) || '%')
		)
	   AND (in_changed_dtm IS NULL OR ((in_changed_dir = 1 AND sv.changed_dtm >= in_changed_dtm) OR (in_changed_dir != 1 AND sv.changed_dtm <= in_changed_dtm)))
	   AND s.title_only = 0
	   AND (v_has_flow_state_filter = 0 OR s.flow_item_id IN (SELECT flow_item_id FROM flow_item WHERE current_state_id IN (SELECT column_value FROM TABLE(t_flow_state_ids))))
	   AND (v_has_module_filter = 0 OR s.module_root_sid IN (SELECT column_value FROM TABLE(t_module_ids)))
	   AND (v_has_tag_filter = 0 OR stm.section_tag_id IN (SELECT column_value FROM TABLE(t_tag_ids)))
	   AND (v_has_sid_filter = 0 OR s.section_sid IN (SELECT column_value FROM TABLE(t_section_sids)))
	   AND (v_has_assigned_to_filter = 0 OR s.section_sid IN (
			SELECT section_sid
			  FROM route r
			  JOIN route_step rs ON r.route_id = rs.route_id AND r.app_sid = rs.app_sid
			  JOIN route_step_user rsu ON rs.route_step_id = rsu.route_step_id AND rs.app_sid = rsu.app_sid
			 WHERE rsu.csr_user_sid IN (SELECT column_value FROM TABLE(t_assigned_to_ids))
	   -- TODO: Progress State filter
	   -- 1=In Progress
	   -- 2=No route assigned
	   -- 3=No available route
	   -- 4=Overdue
	   -- 5=Completed
	   --AND (v_has_progress_state_filter = 0
		--	OR (5 IN (SELECT column_value from TABLE(t_progress_state_ids))
		--	AND s.flow_item_id IN (SELECT fi.flow_item_id FROM flow_item fi)
		--	))
		));

	-- now we can fetch section's details
	GetSections(v_section_sids, out_section_cur);
	GetRoutes(v_section_sids, out_route_cur, out_route_step_cur, out_route_step_user_cur);
	GetSectionsPaths(v_section_sids, out_path_cur);
	GetSectionsTags(v_section_sids, out_tag_cur);
END;

PROCEDURE ApplyFilter(
	in_contains_text			IN	VARCHAR2,
	in_include_answers			IN	NUMBER,
	in_changed_dtm				IN	SECTION_VERSION.changed_dtm%TYPE,
	in_changed_dir				IN  NUMBER,
	in_flow_state_ids			IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_module_ids				IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_tag_ids					IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_assigned_to_ids			IN	security_pkg.T_SID_IDS,
	in_progress_state_ids		IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	out_section_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_path_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_section_sids				security_pkg.T_SID_IDS;	-- empty
BEGIN
	section_pkg.ApplyFilter(in_contains_text, in_include_answers, in_changed_dtm, in_changed_dir, in_flow_state_ids, in_module_ids, in_tag_ids, in_assigned_to_ids,in_progress_state_ids,
					v_section_sids, out_section_cur, out_route_cur, out_route_step_cur, out_route_step_user_cur, out_path_cur, out_tag_cur);
END;

PROCEDURE ApplyUserViewFilter(
	in_contains_text			IN	VARCHAR2,
	in_include_answers			IN	NUMBER,
	in_module_ids				IN	security_pkg.T_SID_IDS,
	in_tag_ids					IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	out_section_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_path_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_transition_cur			OUT security_pkg.T_OUTPUT_CUR --keep last!
)
AS
	v_section_sids				security_pkg.T_SID_IDS;
	v_empty_ids					security_pkg.T_SID_IDS;
	v_user_sid					security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID');
BEGIN
	-- collect sections we're interested in
	SELECT section_sid
	  BULK COLLECT INTO v_section_sids
	FROM v$my_section;

	IF v_section_sids.COUNT = 0 OR (v_section_sids.COUNT = 1 AND v_section_sids(1) IS NULL) THEN
		-- if we have no sections to show to the user just set invalid sid, so the filter will return no rows (but instantiated empty cursors!)
		v_section_sids(1) := -1;
	END IF;

	-- apply filter
	section_pkg.ApplyFilter(
		in_contains_text		=> in_contains_text,
		in_include_answers		=> in_include_answers,
		in_changed_dtm 			=> NULL,
		in_changed_dir			=> 1,
		in_flow_state_ids		=> v_empty_ids,
		in_module_ids			=> in_module_ids,
		in_tag_ids				=> in_tag_ids,
		in_assigned_to_ids		=> v_empty_ids,
		in_progress_state_ids	=> v_empty_ids,
		in_section_sids			=> v_section_sids,
		out_section_cur 		=> out_section_cur,
		out_route_cur			=> out_route_cur,
		out_route_step_cur		=> out_route_step_cur,
		out_route_step_user_cur	=> out_route_step_user_cur,
		out_path_cur			=> out_path_cur,
		out_tag_cur				=> out_tag_cur);

	OPEN out_transition_cur FOR
		SELECT rt.section_sid, rt.flow_state_transition_id, rt.to_state_id, rt.verb, rt.to_state_label, rt.ask_for_comment, rt.transition_pos,
			   rt.to_submit_routed_user, rt.to_return_routed_user
		  FROM (
			SELECT sm.module_root_sid, s.section_sid, fitrm.flow_state_transition_id, fitrm.to_state_id, fitrm.verb, fitrm.to_state_label, fitrm.ask_for_comment, fitrm.transition_pos,
			   (
					SELECT stragg(full_name) full_names
					  FROM csr_user cu
						JOIN route_step_user rsu
							ON rsu.csr_user_sid = cu.csr_user_sid
					 WHERE rsu.route_step_id = section_pkg.GetFirstRouteStepId(s.section_sid, fitrm.to_state_id)
			   ) to_submit_routed_user,
			   (
					SELECT stragg(full_name) full_names
					  FROM csr_user cu
						JOIN route_step_user rsu
							ON rsu.csr_user_sid = cu.csr_user_sid
					 WHERE rsu.route_step_id = section_pkg.GetLastRouteStepId(s.section_sid, fitrm.to_state_id)
			   ) to_return_routed_user
				  FROM v$FLOW_ITEM_TRANS_ROLE_MEMBER fitrm
					JOIN section s ON fitrm.flow_item_id = s.flow_item_id AND fitrm.app_sid = s.app_sid
					LEFT JOIN section_module sm
						ON s.module_root_sid = sm.module_root_sid AND s.app_sid = sm.app_sid
						AND fitrm.region_sid = sm.region_sid AND fitrm.app_sid = sm.app_sid
				 WHERE NOT EXISTS (
					-- exclude if sections are currently in a workflow state that is routed
					SELECT null FROM csr.section_routed_flow_state WHERE flow_state_id = fitrm.from_state_id
				)
			UNION ALL
			--Should fix better but distinct will do for now
			SELECT DISTINCT sm.module_root_sid, s.section_sid, fitrm.flow_state_transition_id, fitrm.to_state_id, fitrm.verb, fitrm.to_state_label, fitrm.ask_for_comment, fitrm.transition_pos,
			   (
					SELECT stragg(full_name) full_names
					  FROM csr_user cu
						JOIN route_step_user rsu
							ON rsu.csr_user_sid = cu.csr_user_sid
					 WHERE rsu.route_step_id = section_pkg.GetFirstRouteStepId(s.section_sid, fitrm.to_state_id)
			   ) to_submit_routed_user,
			   (
					SELECT stragg(full_name) full_names
					  FROM csr_user cu
						JOIN route_step_user rsu
							ON rsu.csr_user_sid = cu.csr_user_sid
					 WHERE rsu.route_step_id = section_pkg.GetLastRouteStepId(s.section_sid, fitrm.to_state_id)
			   ) to_return_routed_user
				  FROM v$FLOW_ITEM_TRANS_ROLE_MEMBER fitrm
					JOIN section s ON fitrm.flow_item_id = s.flow_item_id AND fitrm.app_sid = s.app_sid
					LEFT JOIN section_module sm
						ON s.module_root_sid = sm.module_root_sid AND s.app_sid = sm.app_sid
						AND fitrm.region_sid = sm.region_sid AND fitrm.app_sid = sm.app_sid
					JOIN route r ON fitrm.from_state_id = r.flow_state_id AND fitrm.app_sid = r.app_sid
					JOIN route_step rs
						ON r.route_id = rs.route_id AND r.app_sid = rs.app_sid
						AND s.current_route_step_id = rs.route_step_id AND s.app_sid = rs.app_sid
					JOIN route_step_user rsu
						ON rs.route_step_id = rsu.route_step_id
						AND rs.app_sid = rsu.app_sid
						AND rsu.csr_user_sid = SYS_CONTEXT('SECURITY','SID')
		) rt
		WHERE rt.module_root_sid IS NOT NULL
		ORDER BY section_sid, transition_pos;
END;

PROCEDURE GetDashboardData(
	in_flow_state_ids			IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_module_ids				IN	security_pkg.T_SID_IDS,
	in_tag_ids					IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_assigned_to_ids			IN	security_pkg.T_SID_IDS,
	in_cart_ids					IN	security_pkg.T_SID_IDS, -- not sids, but will do
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_flow_state_ids			security.T_SID_TABLE;
	t_module_ids				security.T_SID_TABLE;
	t_tag_ids					security.T_SID_TABLE;
	t_assigned_to_ids			security.T_SID_TABLE;
	t_cart_ids					security.T_SID_TABLE;

	v_has_flow_state_filter		NUMBER DEFAULT 1;
	v_has_module_filter			NUMBER DEFAULT 1;
	v_has_tag_filter			NUMBER DEFAULT 1;
	v_has_assigned_to_filter	NUMBER DEFAULT 1;
	v_has_cart_filter			NUMBER DEFAULT 1;
	v_user_sid					security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID');
BEGIN
	t_flow_state_ids	:= security_pkg.SidArrayToTable(in_flow_state_ids);
	t_module_ids		:= security_pkg.SidArrayToTable(in_module_ids);
	t_tag_ids			:= security_pkg.SidArrayToTable(in_tag_ids);
	t_assigned_to_ids	:= security_pkg.SidArrayToTable(in_assigned_to_ids);
	t_cart_ids			:= security_pkg.SidArrayToTable(in_cart_ids);

	IF in_flow_state_ids.COUNT = 0 OR (in_flow_state_ids.COUNT = 1 AND in_flow_state_ids(1) IS NULL) THEN
		v_has_flow_state_filter := 0;
	END IF;
	IF in_module_ids.COUNT = 0 OR (in_module_ids.COUNT = 1 AND in_module_ids(1) IS NULL) THEN
		v_has_module_filter := 0;
	END IF;
	IF in_tag_ids.COUNT = 0 OR (in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL) THEN
		v_has_tag_filter := 0;
	END IF;
	IF in_assigned_to_ids.COUNT = 0 OR (in_assigned_to_ids.COUNT = 1 AND in_assigned_to_ids(1) IS NULL) THEN
		v_has_assigned_to_filter := 0;
	END IF;
	IF in_cart_ids.COUNT = 0 OR (in_cart_ids.COUNT = 1 AND in_cart_ids(1) IS NULL) THEN
		v_has_cart_filter := 0;
	END IF;

	OPEN out_cur FOR
		SELECT flow_state_id, label, state_colour, pos, CASE WHEN routed_flow_state_id IS NULL THEN 0 ELSE 1 END  is_routed, SUM(overdue_cnt) overdue_cnt, SUM(ontime_cnt) ontime_cnt, SUM(cnt) cnt
		  FROM (
			SELECT fs.flow_state_id, fs.state_colour, fs.label, fs.pos,
				(SELECT flow_state_id FROM section_routed_flow_state WHERE flow_state_id = fs.flow_state_id) routed_flow_state_id,
				CASE WHEN rs.step_due_dtm IS NOT NULL AND TRUNC(SYSDATE) > rs.step_due_dtm THEN 1 ELSE 0 END overdue_cnt,
				CASE WHEN rs.step_due_dtm IS NOT NULL AND TRUNC(SYSDATE) <= rs.step_due_dtm THEN 1 ELSE 0 END ontime_cnt,
				1 cnt
			  FROM section s
			  JOIN section_module sm ON s.module_root_sid = sm.module_root_sid
			  JOIN flow_item fi ON s.flow_item_id = fi.flow_item_id AND s.app_sid = fi.app_sid
			  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
			  LEFT JOIN route_step rs ON s.current_route_step_id = rs.route_step_id
			  LEFT JOIN route r ON rs.route_id = r.route_id AND rs.app_sid = r.app_sid AND fs.flow_state_id = r.flow_state_id
			 WHERE (v_has_flow_state_filter = 0 OR s.flow_item_id IN (SELECT flow_item_id FROM flow_item WHERE current_state_id IN (SELECT column_value FROM TABLE(t_flow_state_ids))))
			   AND (v_has_module_filter = 0 OR s.module_root_sid IN (SELECT column_value FROM TABLE(t_module_ids)))
			   AND (v_has_cart_filter = 0 OR s.section_sid IN (SELECT section_sid FROM section_cart_member WHERE section_cart_id IN (SELECT column_value FROM TABLE(t_cart_ids))))
			   AND (v_has_tag_filter = 0 OR s.section_sid IN (SELECT section_sid FROM section_tag_member WHERE section_tag_id IN (SELECT  column_value FROM TABLE(t_tag_ids))))
			   AND (v_has_assigned_to_filter = 0 OR s.section_sid IN (
						SELECT section_sid
						  FROM route rr
						  JOIN route_step rrs ON rrs.route_id = rr.route_id
						  JOIN route_step_user rrsu ON rrsu.route_step_id = rrs.route_step_id
						 WHERE csr_user_sid IN (SELECT column_value FROM TABLE(t_assigned_to_ids))
						   AND rrsu.route_step_id = s.current_route_step_id
					   )
					)
			  AND title_only = 0
			  AND s.active = 1
			  AND sm.active = 1
		)
		GROUP BY flow_state_id, label, state_colour, pos, CASE WHEN routed_flow_state_id IS NULL THEN 0 ELSE 1 END
		ORDER BY pos;
END;

PROCEDURE GetDashboardDetails(
	in_flow_state_ids			IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_module_ids				IN	security_pkg.T_SID_IDS,
	in_tag_ids					IN	security_pkg.T_SID_IDS,	-- not sids, but will do
	in_assigned_to_ids			IN	security_pkg.T_SID_IDS,
	in_cart_ids					IN	security_pkg.T_SID_IDS, -- not sids, but will do
	in_filter_type				IN  NUMBER DEFAULT '0',
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_flow_state_ids			security.T_SID_TABLE;
	t_module_ids				security.T_SID_TABLE;
	t_tag_ids					security.T_SID_TABLE;
	t_assigned_to_ids			security.T_SID_TABLE;
	t_cart_ids					security.T_SID_TABLE;

	v_has_flow_state_filter		NUMBER DEFAULT 1;
	v_has_module_filter			NUMBER DEFAULT 1;
	v_has_tag_filter			NUMBER DEFAULT 1;
	v_has_assigned_to_filter	NUMBER DEFAULT 1;
	v_has_cart_filter			NUMBER DEFAULT 1;
	v_user_sid					security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID');
	v_section_ids				security_pkg.T_SID_IDS;
BEGIN
	t_flow_state_ids	:= security_pkg.SidArrayToTable(in_flow_state_ids);
	t_module_ids		:= security_pkg.SidArrayToTable(in_module_ids);
	t_tag_ids			:= security_pkg.SidArrayToTable(in_tag_ids);
	t_assigned_to_ids	:= security_pkg.SidArrayToTable(in_assigned_to_ids);
	t_cart_ids			:= security_pkg.SidArrayToTable(in_cart_ids);

	IF in_flow_state_ids.COUNT = 0 OR (in_flow_state_ids.COUNT = 1 AND in_flow_state_ids(1) IS NULL) THEN
		v_has_flow_state_filter := 0;
	END IF;

	IF in_module_ids.COUNT = 0 OR (in_module_ids.COUNT = 1 AND in_module_ids(1) IS NULL) THEN
		v_has_module_filter := 0;
	END IF;

	IF in_tag_ids.COUNT = 0 OR (in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL) THEN
		v_has_tag_filter := 0;
	END IF;

	IF in_assigned_to_ids.COUNT = 0 OR (in_assigned_to_ids.COUNT = 1 AND in_assigned_to_ids(1) IS NULL) THEN
		v_has_assigned_to_filter := 0;
	END IF;

	IF in_cart_ids.COUNT = 0 OR (in_cart_ids.COUNT = 1 AND in_cart_ids(1) IS NULL) THEN
		v_has_cart_filter := 0;
	END IF;

	IF LOWER(in_filter_type) NOT IN (1,2,3) THEN
		-- 1 = all, 2 = overdue, 3 = ontime (as in c:\cvs\csr\web\site\text\overview\filter\dashboardTable.js)
		RAISE_APPLICATION_ERROR(-20001, 'Unknown filter type: ' || in_filter_type);
	END IF;

	OPEN out_cur FOR
		SELECT s.section_sid, s.title title, s.current_route_step_id, GetModuleName(s.section_sid) module_name,
				CASE WHEN s.is_split = 1 THEN (
					SELECT title from v$visible_version where section_sid = s.parent_sid
				) ELSE NULL END parent_title
		 FROM v$visible_version s
		 JOIN (
					SELECT level lvl, section_sid, rownum rn
					  FROM section
					 WHERE active = 1
					 START WITH parent_sid IS NULL
				   CONNECT BY PRIOR section_sid = parent_sid
					ORDER SIBLINGS BY module_root_sid, section_position
			   ) st ON s.section_sid = st.section_sid
	     JOIN flow_item fi ON s.flow_item_id = fi.flow_item_id AND s.app_sid = fi.app_sid
	     JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
	     LEFT JOIN route_step rs ON s.current_route_step_id = rs.route_step_id
	     LEFT JOIN route r ON rs.route_id = r.route_id AND rs.app_sid = r.app_sid AND fs.flow_state_id = r.flow_state_id
	    WHERE (v_has_flow_state_filter = 0 OR s.flow_item_id IN (SELECT flow_item_id FROM flow_item WHERE current_state_id IN (SELECT column_value FROM TABLE(t_flow_state_ids))))
		  AND (v_has_module_filter = 0 OR s.module_root_sid IN (SELECT column_value FROM TABLE(t_module_ids)))
		  AND (v_has_cart_filter = 0 OR s.section_sid IN (SELECT section_sid FROM section_cart_member WHERE section_cart_id IN (SELECT column_value FROM TABLE(t_cart_ids))))
		  AND (v_has_tag_filter = 0 OR s.section_sid IN (SELECT section_sid FROM section_tag_member WHERE section_tag_id IN (SELECT  column_value FROM TABLE(t_tag_ids))))
		  AND (v_has_assigned_to_filter = 0 OR s.section_sid IN (
				SELECT section_sid
				  FROM route rr
				  JOIN route_step rrs ON rrs.route_id = rr.route_id
				  JOIN route_step_user rrsu ON rrsu.route_step_id = rrs.route_step_id
				 WHERE csr_user_sid IN (SELECT column_value FROM TABLE(t_assigned_to_ids))
				   AND rrsu.route_step_id = s.current_route_step_id
				)
			)
		  AND (in_filter_type = 1 OR
				(in_filter_type = 2 AND rs.step_due_dtm IS NOT NULL AND TRUNC(SYSDATE) > rs.step_due_dtm) OR
				(in_filter_type = 3 AND rs.step_due_dtm IS NOT NULL AND TRUNC(SYSDATE) <= rs.step_due_dtm)
		      )
		  AND title_only = 0
	    ORDER BY st.rn;
END;

PROCEDURE CreateCart(
	in_name					IN	csr.section_cart.name%TYPE,
	in_section_sids			IN	security_pkg.T_SID_IDS,
	out_id					OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Manage text question carts') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to manage question carts');
	END IF;

	INSERT INTO csr.section_cart (section_cart_id, name, section_cart_folder_id)
	 VALUES (section_cart_id_seq.nextval, in_name, section_cart_folder_pkg.GetRootFolderId)
	 RETURNING section_cart_id INTO out_id;

	SetCartSections(out_id, in_section_sids);
END;

PROCEDURE DeleteCart(
	in_section_cart_id		IN	csr.section_cart.section_cart_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Manage text question carts') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to manage question carts');
	END IF;

	DELETE FROM section_cart_member
	 WHERE section_cart_id = in_section_cart_id;

	DELETE FROM section_cart
	 WHERE section_cart_id = in_section_cart_id;
END;

PROCEDURE SetCartSections(
	in_section_cart_id		IN	csr.section_cart.section_cart_id%TYPE,
	in_section_sids			IN	security_pkg.T_SID_IDS
)
AS
	t_section_sids	security.T_SID_TABLE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Manage text question carts') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to manage question carts');
	END IF;

	t_section_sids	:= security_pkg.SidArrayToTable(in_section_sids);

	-- delete current setup
	DELETE FROM section_cart_member
	 WHERE section_cart_id = in_section_cart_id;

	-- set new sections
	FOR r IN (SELECT column_value FROM TABLE(t_section_sids))
	LOOP
		INSERT INTO section_cart_member
			(section_cart_id, section_sid)
		VALUES
			(in_section_cart_id, r.column_value);
	END LOOP;
END;

PROCEDURE SetCartName(
	in_section_cart_id		IN	csr.section_cart.section_cart_id%TYPE,
	in_name					IN	csr.section_cart.name%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Manage text question carts') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to manage question carts');
	END IF;

	UPDATE section_cart
	   SET name = in_name
	 WHERE section_cart_id = in_section_cart_id;
END;

PROCEDURE GetLatestContentFull(
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_section_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_section_tag_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_content_docs_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_attachment_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_plugins_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_comments_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_section_sids		security_pkg.T_SID_IDS;
BEGIN
	-- convert to array
	SELECT in_section_sid
	   BULK COLLECT INTO v_section_sids
	  FROM DUAL;

	GetLatestContent(security.security_pkg.getact, in_section_sid, out_section_cur);
	GetSectionsTags(v_section_sids, out_section_tag_cur);
	GetAttachments(v_section_sids, out_attachment_cur);
	GetFormPlugins(v_section_sids, out_plugins_cur);
	GetContentDocs(v_section_sids, out_content_docs_cur);
	GetComments(v_section_sids, out_comments_cur);
END;

PROCEDURE GetBodies(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_ids		security.T_SID_TABLE;
BEGIN
	t_section_ids	:= security_pkg.SidArrayToTable(in_section_sids);

	OPEN out_cur FOR
		SELECT s.section_sid, vv.body, vv.body raw_body, s.plugin
		  FROM section s
		  JOIN v$visible_version vv ON s.section_sid = vv.section_sid
		 WHERE s.section_sid IN (SELECT column_value FROM TABLE(t_section_ids));
END;

PROCEDURE GetSectionsFull(
	in_section_sids					IN	security_pkg.T_SID_IDS,
	out_section_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_body_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_route_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_section_tag_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_attachment_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_content_docs_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_plugins_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_path_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_comment_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetSections(in_section_sids, out_section_cur);
	GetBodies(in_section_sids, out_body_cur);
	GetRoutes(in_section_sids, out_route_cur, out_route_step_cur, out_route_step_user_cur);
	GetSectionsTags(in_section_sids, out_section_tag_cur);
	GetAttachments(in_section_sids, out_attachment_cur);
	GetFormPlugins(in_section_sids, out_plugins_cur);
	GetContentDocs(in_section_sids, out_content_docs_cur);
	GetSectionsPaths(in_section_sids, out_path_cur);
	GetComments(in_section_sids, out_comment_cur);
END;

PROCEDURE GetSections(
	in_section_sids			IN	security_pkg.T_SID_IDS,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id			security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT');
	t_section_ids		security.T_SID_TABLE;
	v_user_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID');
	v_is_admin			NUMBER DEFAULT 0;
BEGIN
	t_section_ids	:= security_pkg.SidArrayToTable(in_section_sids);

	v_is_admin := csr_data_pkg.SQL_CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Can edit section docs');

	-- return sections with security_pkg.PERMISSION_READ permission
	OPEN out_cur FOR
		SELECT x.section_sid, x.parent_sid, x.plugin, x.current_route_step_id, x.is_split, x.module_root_sid, x.module_name, x.flow_state_id, x.version, x.flow_sid,
		x.title, x.section_status_sid, x.further_info_url, x.body_length, x.is_locked, x.checked_out_to_sid, x.changed_by_sid, x.changed_by_name, x.changed_by_email, x.changed_dtm,
		x.previous_section_sid, x.previous_body_length, x.previous_plugin, x.rn, x.lvl, x.is_admin, s.help_text, cu.full_name checked_out_to_name, cu.email checked_out_to_email, sf.split_question_flow_state_id,
		x.disable_general_attachments, x.show_fact_icon, CASE WHEN SQL_HasEditFactCapability(x.section_sid) = 1 THEN 1 ELSE 0 END has_edit_fact_capability,
		CASE WHEN SQL_HasClearFactCapability(x.section_sid) = 1 THEN 1 ELSE 0 END has_clear_fact_capability,
		NVL(sf.dflt_ret_aft_inc_usr_submit,0) dflt_ret_aft_inc_usr_submit -- left join but DTO doesn't like nulls
		  FROM (SELECT section_sid, parent_sid, module_root_sid, module_name, flow_state_id, version, title, section_status_sid, current_route_step_id,
				is_split, plugin,
				v_is_admin is_admin,
				flow_sid,
				further_info_url, body_length, is_locked, checked_out_to_sid, changed_by_sid, changed_by_name, changed_by_email, changed_dtm,
				previous_section_sid,
				previous_body_length,
				previous_plugin,
				rn, lvl, disable_general_attachments, show_fact_icon
		  FROM (
				SELECT s.section_sid, s.parent_sid, s.plugin, s.current_route_step_id, s.is_split,
						s.module_root_sid, s.disable_general_attachments,
						GetModuleName(s.section_sid) module_name,
						fi.current_state_id flow_state_id, ss.version_number version, fi.flow_sid,
						CASE
							WHEN s.is_split = 1 THEN (
									SELECT title || ' / ' from v$visible_version where section_sid = s.parent_sid
								)
							ELSE NULL
						END || ss.title title,
						s.section_status_sid, s.further_info_url, body_length,
						CASE
							WHEN s.checked_out_to_sid IS NOT NULL THEN 1
							ELSE 0
						END is_locked,
						s.checked_out_to_sid,
						ss.changed_by_sid,
						cu.full_name changed_by_name,
						cu.email changed_by_email,
						ss.changed_dtm,
						s.previous_section_sid,
						LENGTH(cf.body) previous_body_length,
						cf.plugin previous_plugin,
						st.rn, st.lvl - 1 lvl, sm.show_fact_icon
				  FROM (
						SELECT v.rowid rid, v.section_sid, v.version_number, v.title, LENGTH(v.body) body_length, v.changed_by_sid, v.changed_dtm
						  FROM csr.section s
						  JOIN section_version v
							ON s.section_sid = v.section_sid
							AND s.visible_version_number = v.version_number
						) ss,
						(
							SELECT level lvl, section_sid, rownum rn
							  FROM section
							 WHERE active = 1
							 START WITH parent_sid IS NULL
						   CONNECT BY PRIOR section_sid = parent_sid
							ORDER SIBLINGS BY module_root_sid, is_split desc, section_position
						) st,
						section s, section_module sm, section_tag_member stm, csr_user cu, flow_item fi,
						v$visible_version cf
				 WHERE ss.section_sid = s.section_sid
				   AND st.section_sid = s.section_sid
				   AND sm.module_root_sid = s.module_root_sid
				   AND sm.active = 1
				   AND cu.csr_user_sid = ss.changed_by_sid(+)
				   AND s.section_sid = stm.section_sid(+)
				   AND fi.flow_item_id(+) = s.flow_item_id
				   AND s.previous_section_sid = cf.section_sid(+)
				   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, s.section_sid, security_pkg.PERMISSION_READ) = 1
				   AND s.section_sid IN (SELECT column_value FROM TABLE(t_section_ids))
		) y
		GROUP BY section_sid, parent_sid, module_root_sid, module_name, flow_state_id, flow_sid, version, title, section_status_sid, current_route_step_id,
				is_split, plugin,
				further_info_url, body_length, is_locked, checked_out_to_sid, changed_by_sid, changed_by_name, changed_by_email, changed_dtm,
				previous_section_sid, previous_body_length, previous_plugin, rn, lvl, disable_general_attachments, show_fact_icon
	) x LEFT JOIN csr_user cu ON x.checked_out_to_sid = cu.csr_user_sid
		LEFT JOIN csr.section_flow sf on x.flow_sid = sf.flow_sid
		JOIN csr.v$visible_version s ON s.section_sid = x.section_sid --Cannot use clob in group by so rejoin to get help_text
	ORDER BY rn;
END;

PROCEDURE GetSectionsPaths(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_ids		security.T_SID_TABLE;
BEGIN
	t_section_ids	:= security_pkg.SidArrayToTable(in_section_sids);

	OPEN out_cur FOR
		SELECT s.root_section_sid section_sid, sv.title, lvl
		  FROM section_version sv, (
				 SELECT s.section_sid, LEVEL lvl, visible_version_number version_number, CONNECT_BY_ROOT section_sid root_section_sid
		           FROM SECTION s
		          WHERE s.section_sid != CONNECT_BY_ROOT section_sid
			 START WITH s.section_sid IN (SELECT column_value FROM TABLE(t_section_ids))
		     CONNECT BY PRIOR parent_sid = section_sid
			   ORDER BY root_section_sid
	 )s
		 WHERE sv.section_sid = s.section_sid
		   AND sv.version_number = s.version_number
		 ORDER BY root_section_sid, lvl DESC;

END;

PROCEDURE GetContentDocs(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_sids		security.T_SID_TABLE;
	v_docs_sid			security_pkg.T_SID_ID;
BEGIN
	t_section_sids		:= security_pkg.SidArrayToTable(in_section_sids);

	BEGIN
		v_docs_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'Documents');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_docs_sid := -1;
	END;

	OPEN out_cur FOR
		SELECT scd.section_sid, scd.doc_id, dc.version version_number, dc.FILENAME, dc.description, dc.mime_type,
			decode(dc.locked_by_sid, null, decode(scd.checked_out_to_sid, null, 0, 1), 1) is_checked_out,
			nvl(dc.locked_by_sid, scd.checked_out_to_sid) checked_out_to_sid,
			nvl(dcu.full_name, scu.full_name) checked_out_to_name, dc.parent_sid, decode(scdw.section_sid, null, 0, 1) is_waiting,
			dc.changed_dtm, dc.changed_by_sid, ccu.full_name changed_by_name,
			decode(doc_folder_pkg.GetLibraryContainer(dc.parent_sid),v_docs_sid,1,0) in_doc_lib, v_docs_sid lib_sid,
			t.path
		  FROM section_content_doc scd
		  JOIN v$doc_current dc on scd.doc_id = dc.doc_id
		  LEFT JOIN section_content_doc_wait scdw ON scd.section_sid = scdw.section_sid AND scd.doc_id = scdw.doc_id AND scdw.csr_user_sid = sys_context('security','sid')
		  LEFT JOIN csr_user scu on  scd.checked_out_to_sid = scu.csr_user_sid
		  LEFT JOIN csr_user dcu on  dc.locked_by_sid = dcu.csr_user_sid
		  LEFT JOIN csr_user ccu on  dc.changed_by_sid = ccu.csr_user_sid
		  LEFT JOIN TABLE ( SecurableObject_pkg.GetTreeWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'),
						v_docs_sid, security_pkg.PERMISSION_READ) ) t ON t.sid_id = dc.parent_sid
		 WHERE scd.section_sid IN (
		   	  SELECT column_value FROM TABLE(t_section_sids)
		   )
		   AND dc.version IS NOT NULL -- exclude docs that have never been published yet and are pending approval
		 ORDER BY dc.filename;
END;

PROCEDURE GetAttachments(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_sids		security.T_SID_TABLE;
	v_docs_sid			security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_docs_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'Documents');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_docs_sid := -1;
	END;

	t_section_sids		:= security_pkg.SidArrayToTable(in_section_sids);

	OPEN out_cur FOR
		SELECT ah.section_sid, ah.version_number, ah.attachment_id,
			CASE
				WHEN dataview_sid IS NOT NULL THEN 'dataview'
				WHEN ind_sid IS NOT NULL THEN 'indicator'
				WHEN a.data IS NOT NULL THEN 'file'
				WHEN a.doc_id IS NOT NULL THEN 'document'
				WHEN a.url IS NOT NULL THEN 'url'
				WHEN a.mime_type = 'application/form' THEN 'form'
				ELSE 'unknown'
			END type,
			CASE
				WHEN dataview_sid IS NOT NULL THEN a.filename
				WHEN ind_sid IS NOT NULL THEN i.description
				WHEN a.data IS NOT NULL THEN a.filename
				WHEN a.doc_id IS NOT NULL THEN a.filename
				WHEN a.url IS NOT NULL THEN a.filename
				WHEN a.mime_type = 'application/form' THEN a.filename
				ELSE 'unknown'
			END label,
			a.filename, a.mime_type,
			CASE
				WHEN a.data IS NULL THEN 0
				ELSE 1
			END has_data, a.doc_id, a.dataview_sid, a.last_updated_from_Dataview, a.view_as_table,
				i.ind_sid, indicator_pkg.INTERNAL_GetIndPathString(i.ind_Sid) ind_path, a.embed, a.url,
				sal.changed_dtm, sal.changed_by_sid, sal.changed_by_name,
				ah.attach_name name, ah.attach_comment "COMMENT", ah.pg_num page,
				sfa.fact_id, sfa.fact_idx, decode(doc_folder_pkg.GetLibraryContainer(dc.parent_sid),v_docs_sid,1,0) in_doc_lib
		  FROM section s
		  JOIN section_version sv
					ON s.section_sid = sv.section_sid
					AND sv.version_number = NVL(checked_out_version_number, visible_version_number)
					/*( -- this is how it should work, i.e. only shows attachments that are assigned to the version you can see.
						-- We're using NVL above to mimic how Dickie's code works at the moment
						CASE
							WHEN checked_out_to_sid = v_user_sid THEN checked_out_version_number
							ELSE visible_version_number
						END
				   )*/
		  JOIN attachment_history ah ON sv.section_sid = ah.section_sid
		  JOIN attachment a ON ah.attachment_id = a.attachment_id
		  LEFT JOIN v$ind i ON a.indicator_sid = i.ind_Sid
		  LEFT JOIN v$section_attach_log_last sal
					ON a.attachment_id = sal.attachment_id
					AND s.section_sid = sal.section_sid
		  LEFT JOIN section_fact_attach sfa ON sfa.section_sid = s.section_sid AND sfa.attachment_id = a.attachment_id
		  LEFT JOIN v$doc_current dc on a.doc_id = dc.doc_id
		 WHERE security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), s.section_sid, security_pkg.PERMISSION_READ) = 1
		   AND s.section_sid IN (
		   	  SELECT column_value FROM TABLE(t_section_sids)
		   )
		 ORDER BY attachment_id;
END;

PROCEDURE GetComments(
	in_section_sids			IN	security_pkg.T_SID_IDS,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_ids		security.T_SID_TABLE;
BEGIN
	t_section_ids	:= security_pkg.SidArrayToTable(in_section_sids);

	OPEN out_cur FOR
		SELECT sc.section_comment_id, sc.section_sid, sc.in_reply_to_id, sc.comment_text, sc.entered_by_sid,
			   cu.full_name entered_by_name, cu.email entered_by_email, sc.entered_dtm, level lvl
	 	  FROM section_comment sc, csr_user cu
	 	 WHERE sc.section_sid IN (SELECT column_value FROM TABLE(t_section_ids))
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), sc.section_sid, security_pkg.PERMISSION_READ) = 1
	 	   AND sc.entered_by_sid = cu.csr_user_sid
    START WITH sc.in_reply_to_id IS NULL
    CONNECT BY PRIOR section_comment_id = sc.in_reply_to_id
	     ORDER SIBLINGS BY sc.entered_dtm DESC;
END;

PROCEDURE AddTransitionComment(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_comment_text			IN	section_trans_comment.COMMENT_TEXT%TYPE
)
AS
	v_user_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID');
BEGIN
	-- Check for write access
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	-- Insert the new comment
	IF LENGTH(TRIM(in_comment_text)) > 0 THEN
		INSERT INTO section_trans_comment
			(SECTION_TRANS_COMMENT_ID, SECTION_SID, COMMENT_TEXT, ENTERED_BY_SID, ENTERED_DTM)
		VALUES
			(section_trans_comment_id_seq.NEXTVAL, in_section_sid, in_comment_text, v_user_sid, SYSDATE);
	END IF;
END;

PROCEDURE GetTransitionComments(
	in_section_sids			IN	security_pkg.T_SID_IDS,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_ids		security.T_SID_TABLE;
BEGIN
	t_section_ids	:= security_pkg.SidArrayToTable(in_section_sids);

	OPEN out_cur FOR
		SELECT stc.section_trans_comment_id, stc.section_sid,  stc.comment_text, stc.entered_by_sid,
			   cu.full_name entered_by_name, cu.email entered_by_email, stc.entered_dtm
	 	  FROM section_trans_comment stc, csr_user cu
	 	 WHERE stc.section_sid IN (SELECT column_value FROM TABLE(t_section_ids))
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), stc.section_sid, security_pkg.PERMISSION_READ) = 1
	 	   AND stc.entered_by_sid = cu.csr_user_sid
	     ORDER BY stc.entered_dtm DESC;
END;

PROCEDURE GetCarts(
	out_carts_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_cart_members_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_sections_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_section_sids	security_pkg.T_SID_IDS;
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Manage text question carts') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to manage question carts');
	END IF;

	OPEN out_carts_cur FOR
		SELECT section_cart_id, name
		  FROM section_cart
		 WHERE section_cart_folder_id IN
				(SELECT section_cart_folder_id FROM section_cart_folder WHERE is_visible = 1)
		 ORDER BY name;

	OPEN out_cart_members_cur FOR
		SELECT scm.section_cart_id, scm.section_sid
		  FROM section_cart_member scm
		  JOIN section_cart sc
					 ON sc.section_cart_id = scm.section_cart_id
					AND sc.section_cart_folder_id IN (
							SELECT section_cart_folder_id
							  FROM section_cart_folder
							 WHERE is_visible = 1);

	SELECT DISTINCT section_sid
	  BULK COLLECT INTO v_section_sids
	  FROM section_cart_member;

	 GetSections(v_section_sids, out_sections_cur);
END;

PROCEDURE GetSectionsCarts(
	in_section_sids			IN	security_pkg.T_SID_IDS,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_ids		security.T_SID_TABLE;
BEGIN
	t_section_ids	:= security_pkg.SidArrayToTable(in_section_sids);

	OPEN out_cur FOR
		SELECT section_sid, sc.section_cart_id, sc.name
	 	  FROM section_cart_member scm
		  JOIN section_cart sc ON sc.section_cart_id = scm.section_cart_id
	 	 WHERE scm.section_sid IN (SELECT column_value FROM TABLE(t_section_ids));
END;

PROCEDURE GetFlows(
	out_flow_cur					OUT		SYS_REFCURSOR,
	out_state_cur					OUT		SYS_REFCURSOR,
	out_trans_cur					OUT		SYS_REFCURSOR,
	out_routed_cur					OUT		SYS_REFCURSOR
)
AS
BEGIN
	-- Check read permissions on all flows
	FOR r IN (
		SELECT DISTINCT flow_sid
		  FROM section_module
		 WHERE flow_sid IS NOT NULL
	) LOOP
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, r.flow_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||r.flow_sid);
		END IF;
	END LOOP;

	OPEN out_flow_cur FOR
		SELECT f.flow_sid, f.label, f.default_state_id, f.flow_alert_class
		  FROM flow f
		 WHERE flow_sid IN (SELECT DISTINCT sm.flow_sid FROM section_module sm WHERE sm.flow_sid IS NOT NULL);

	OPEN out_state_cur FOR
		-- sorted so that default state is first
		SELECT fs.flow_sid, fs.flow_state_id, fs.label, fs.lookup_Key, fs.attributes_xml, fs.is_final, fs.state_colour, CASE WHEN srfs.flow_state_id IS NULL THEN 1 ELSE 0 END not_routable
		  FROM flow_state fs
		  JOIN flow f ON fs.flow_sid = f.flow_sid AND fs.app_sid = f.app_sid
		  LEFT JOIN section_routed_flow_state srfs ON fs.flow_state_id = srfs.flow_state_id
		 WHERE fs.flow_sid IN (SELECT DISTINCT sm.flow_sid FROM section_module sm WHERE sm.flow_sid IS NOT NULL)
		   AND fs.is_deleted = 0
		 ORDER BY CASE WHEN f.default_state_id = fs.flow_state_id THEN 1 ELSE 0 END DESC, fs.pos;

	OPEN out_trans_cur FOR
		SELECT flow_sid, flow_state_transition_id, from_state_id, to_state_id, verb, lookup_key, ask_for_comment,
			   mandatory_fields_message, hours_before_auto_tran, button_icon_path, attributes_xml, helper_sp, pos, owner_can_set
		  FROM flow_state_transition fst
		 WHERE flow_sid IN (SELECT DISTINCT sm.flow_sid FROM section_module sm WHERE sm.flow_sid IS NOT NULL)
		 ORDER BY from_state_id, pos;

	OPEN out_routed_cur FOR
		SELECT srfs.flow_sid, srfs.flow_state_id, srfs.reject_fs_transition_id
		  FROM section_routed_flow_state srfs, flow_state fs
		 WHERE fs.flow_state_id = srfs.flow_state_id
		   AND fs.is_deleted = 0
		   AND srfs.flow_sid IN (SELECT DISTINCT sm.flow_sid FROM section_module sm WHERE sm.flow_sid IS NOT NULL)
		 ORDER BY fs.pos;
END;

FUNCTION GetStateChangeAlertId(
	in_vote_direction	IN  NUMBER DEFAULT NULL,
	in_route_step_id	IN 	NUMBER DEFAULT NULL
) RETURN NUMBER
AS
	v_section_alert_type_id				customer_alert_type.customer_alert_type_id%type;
	v_fwd_alert_type_id					customer_alert_type.customer_alert_type_id%type;
	v_back_alert_type_id				customer_alert_type.customer_alert_type_id%type;
BEGIN
	SELECT
		MIN(CASE WHEN std_alert_type_id = csr_data_pkg.ALERT_SECTION_STATE_CHANGE THEN customer_alert_type_id ELSE NULL END),
	    MIN(CASE WHEN std_alert_type_id = csr_data_pkg.ALERT_SECTION_ROUTE_FWD THEN customer_alert_type_id ELSE NULL END),
    	MIN(CASE WHEN std_alert_type_id = csr_data_pkg.ALERT_SECTION_ROUTE_BACK THEN customer_alert_type_id ELSE NULL END)
      INTO v_section_alert_type_id, v_fwd_alert_type_id, v_back_alert_type_id
	  FROM customer_alert_type
	 WHERE std_alert_type_id IN (
	 	csr_data_pkg.ALERT_SECTION_STATE_CHANGE,
	 	csr_data_pkg.ALERT_SECTION_ROUTE_FWD,
	 	csr_data_pkg.ALERT_SECTION_ROUTE_BACK
	 );

	IF in_route_step_id IS NOT NULL THEN
		RETURN v_section_alert_type_id;
	ELSE
		IF in_vote_direction = 1 THEN
			RETURN v_fwd_alert_type_id;
		ELSIF in_vote_direction = -1 THEN
			RETURN v_back_alert_type_id;
		END IF;
	END IF;
END;

PROCEDURE ProcessStateChangeAlerts(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_vote_direction		IN  NUMBER DEFAULT NULL
)
AS

	v_user_sid							security_pkg.T_SID_ID	DEFAULT SYS_CONTEXT('SECURITY','SID');
	v_section_alert_type_id				customer_alert_type.customer_alert_type_id%type;
	v_fwd_alert_type_id					customer_alert_type.customer_alert_type_id%type;
	v_back_alert_type_id				customer_alert_type.customer_alert_type_id%type;
	v_is_current						NUMBER(1) := 0;
	v_route_step_id						NUMBER(10) := NULL;
	v_flow_state_id						NUMBER(10) := NULL;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	SELECT
		MIN(CASE WHEN std_alert_type_id = csr_data_pkg.ALERT_SECTION_STATE_CHANGE THEN customer_alert_type_id ELSE NULL END),
	    MIN(CASE WHEN std_alert_type_id = csr_data_pkg.ALERT_SECTION_ROUTE_FWD THEN customer_alert_type_id ELSE NULL END),
    	MIN(CASE WHEN std_alert_type_id = csr_data_pkg.ALERT_SECTION_ROUTE_BACK THEN customer_alert_type_id ELSE NULL END)
      INTO v_section_alert_type_id, v_fwd_alert_type_id, v_back_alert_type_id
	  FROM customer_alert_type
	 WHERE std_alert_type_id IN (
	 	csr_data_pkg.ALERT_SECTION_STATE_CHANGE,
	 	csr_data_pkg.ALERT_SECTION_ROUTE_FWD,
	 	csr_data_pkg.ALERT_SECTION_ROUTE_BACK
	 );

	SELECT s.current_route_step_id, fi.current_state_id
	  INTO v_route_step_id, v_flow_state_id
	  FROM section s
	  JOIN flow_item fi ON fi.flow_item_id = s.flow_item_id
	  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
	 WHERE s.section_sid = in_section_sid;

	IF v_route_step_id IS NULL OR
		(in_vote_direction = 1 AND NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_SECTION_ROUTE_FWD)) OR
		(in_vote_direction = -1 AND NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_SECTION_ROUTE_BACK)) OR
		NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_SECTION_STATE_CHANGE)
	THEN
		RETURN;
	END IF;

	/*SELECT DISTINCT x.flow_state_transition_id, x.flow_item_alert_id, s.section_sid
	 FROM v$open_flow_item_alert x
	 JOIN section s ON s.section_sid = in_section_sid AND x.flow_item_id = s.flow_item_id AND x.app_sid = s.app_sid;*/

	-- delete prev unsent alerts for this section,
	DELETE FROM section_alert
	 WHERE section_sid = in_section_sid
	   AND sent_dtm IS NULL AND cancelled_dtm IS NULL;

	-- if we've been pushed through to a routed state then use the routed state alert in preference
	-- to the state change. If we're already in the routed state then this is what we want anyway.
	-- add alerts for users added to step
	INSERT INTO SECTION_ALERT (section_alert_id, section_sid, customer_alert_type_id, raised_dtm,
		from_user_sid, notify_user_sid, flow_state_id, route_step_id)
		SELECT section_alert_id_seq.nextval, in_section_sid,
			CASE
				-- if they've passed us an explicit direction the use that. This is needed
				-- when we've moved route state as the new route_step_id has been set already
				-- so we can't easily get the vote direction of the old step.
				WHEN in_vote_direction = 1 THEN v_fwd_alert_type_id
				WHEN in_vote_direction = -1 THEN v_back_alert_type_id
				ELSE v_section_alert_type_id
			END customer_alert_type_id,
			SYSDATE,
			v_user_sid, rsu.csr_user_sid, v_flow_state_id, v_route_step_id
		  FROM ROUTE_STEP_USER rsu
		 WHERE rsu.route_step_id = v_route_step_id;
END;

PROCEDURE SetSectionState(
	in_section_sid			IN	security_pkg.T_SID_ID,
	in_flow_state_id		IN	flow_state.flow_state_id%TYPE,
	in_direction			IN	NUMBER
)
AS
	v_flow_item_id			section.flow_item_id%TYPE;
	v_is_routed				NUMBER(1);
	v_route_step_id			NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- get flow_item_id from section_sid
	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM section s
	 WHERE section_sid = in_section_sid;

	-- check if destination state is routed
	SELECT CASE WHEN count(*) > 0 THEN 1 ELSE 0 END
	  INTO v_is_routed
	  FROM section_routed_flow_state
	 WHERE flow_state_id = in_flow_state_id;

	IF v_is_routed = 1 THEN
		BEGIN
			IF in_direction = -1 THEN
				v_route_step_id := GetLastRouteStepId(in_section_sid, in_flow_state_id);
			ELSE
				v_route_step_id := GetFirstRouteStepId(in_section_sid, in_flow_state_id);
			END IF;

			SELECT rs.route_step_id
			  INTO v_route_step_id
			  FROM route_step rs, route r
			 WHERE rs.route_id = r.route_id
			   AND r.flow_state_id = in_flow_state_id
			   AND r.section_sid = in_section_sid
			   AND rs.route_step_id = v_route_step_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- means there is no route configured
				v_route_step_Id := NULL;
		END;
	ELSE
		-- it is not routed state so current_step_id to null
		v_route_step_id := NULL;
	END IF;

	-- update route step
	UPDATE section
	   SET current_route_step_id = v_route_step_id
	 WHERE section_sid = in_section_sid;

	-- set new state finally
	flow_pkg.SetItemState(v_flow_item_id, in_flow_state_id, NULL, SYS_CONTEXT('SECURITY','SID'));

	-- clean state change alerts
	ProcessStateChangeAlerts(in_section_sid, in_direction);
END;

PROCEDURE ReleaseCart(
	in_section_sids			IN	security_pkg.T_SID_IDS,
	in_flow_state_ids		IN	security_pkg.T_SID_IDS
)
AS
	v_flow_item_id								section.flow_item_id%TYPE;
	v_is_routed									NUMBER(1);
	v_send_admin_state_chng_alert				NUMBER(1) := 0;
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Manage text question carts') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the capability to manage question carts');
	END IF;

	IF NOT (in_section_sids.COUNT = 0 OR (in_section_sids.COUNT = 1 AND in_section_sids(1) IS NULL)) THEN
		FOR i IN 1 .. in_section_sids.COUNT LOOP
			-- security check is made in there :
			SetSectionState(in_section_sids(i), in_flow_state_ids(i), v_send_admin_state_chng_alert);
		END LOOP;
	END IF;
END;

PROCEDURE DeleteRoute(
	in_route_id    IN	route.route_id%TYPE
)
AS
	v_section_sid  security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(section_sid)
	  INTO v_section_sid
	  FROM route
	 WHERE route_id = in_route_id;

	IF v_section_sid IS NULL THEN
		RETURN;
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||v_section_sid);
	END IF;

	FOR r IN (
		SELECT rs.route_id, rs.route_step_id
		  FROM route_step rs
		 WHERE rs.route_id = in_route_id
	)
	LOOP
		-- clear alerts
		DELETE FROM section_alert
		 WHERE route_step_id = r.route_step_id;
		-- clear route step users and any stray votes
		DELETE FROM route_step_user
		 WHERE route_step_id = r.route_step_id;
		DELETE FROM route_step_vote
		 WHERE route_step_id = r.route_step_id;
		-- just in case
		UPDATE section
		   SET current_route_step_id = null
		 WHERE current_route_step_id = r.route_step_id;
		-- clear step
		DELETE FROM route_step
		 WHERE route_step_id = r.route_step_id;
	END LOOP;

	DELETE FROM route
	 WHERE route_id = in_route_id;
END;

PROCEDURE SetRoute(
	in_section_sid		IN	section.section_sid%TYPE,
	in_flow_state_id	IN	route.flow_state_id%TYPE,
	in_due_dtm			IN  route.due_dtm%TYPE,
	out_route_id		OUT	route.route_id%TYPE
)
AS
	v_flow_sid					flow.flow_sid%TYPE;
	v_flow_state_id				flow_state.flow_state_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- find flow_sid
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM section_module
	 WHERE module_root_sid = (
		SELECT module_root_sid FROM section WHERE section_sid = in_section_sid
	  );

	BEGIN
		INSERT INTO route
			(route_id, section_sid, flow_state_id, flow_sid, due_dtm)
		VALUES
			(route_id_seq.NEXTVAL, in_section_sid, in_flow_state_id, v_flow_sid, in_due_dtm)
			RETURNING route_id INTO out_route_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- not sure how sane this is, but it's what Emil's pre upsert code used to do
			SELECT route_id
			  INTO out_route_id
			  FROM route
			 WHERE section_sid = in_section_sid
			   AND flow_state_id = in_flow_state_id;

			UPDATE route
			   SET due_dtm = in_due_dtm
			 WHERE route_id = out_route_id;

			UPDATE route_step
			   SET step_due_dtm = aspen2.utils_pkg.SubtractWorkingDays(in_due_dtm, work_days_offset)
			 WHERE route_id = out_route_id;
	END;
END;

PROCEDURE GetRoutes(
	in_section_sids				IN	security_pkg.T_SID_IDS,
	out_route_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_route_step_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur 	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_ids		security.T_SID_TABLE;
BEGIN
	t_section_ids	:= security_pkg.SidArrayToTable(in_section_sids);

	OPEN out_route_cur FOR
		SELECT r.route_id, r.flow_state_id, r.section_sid, s.current_route_step_id, r.due_dtm, r.completed_dtm
		  FROM csr.route r, csr.section s
		 WHERE r.section_sid IN (SELECT column_value FROM TABLE(t_section_ids))
		   AND r.section_sid = s.section_sid;

	OPEN out_route_step_cur FOR
		SELECT rs.route_id, rs.route_step_id, rs.work_days_offset, rs.step_due_dtm, rs.pos,
			CASE WHEN rs.route_step_id = (
				SELECT current_route_step_id FROM section WHERE section_sid = r.section_sid)
			THEN 1 ELSE 0 END is_current
		  FROM route_step rs, route r
		 WHERE rs.route_id = r.route_id
		   AND r.section_sid IN (SELECT column_value FROM TABLE(t_section_ids))
		 ORDER BY r.route_id, rs.work_days_offset DESC, rs.pos ASC;

	OPEN out_route_step_user_cur FOR
		SELECT rs.route_step_id, rsu.csr_user_sid user_sid, cu.full_name, cu.email,
			rsv.vote_dtm, rsv.vote_direction, rsv.is_return declined
		  FROM route r
		  JOIN route_step rs ON r.route_id = rs.route_id AND r.app_sid = rs.app_sid
		  JOIN route_step_user rsu ON rs.route_step_id = rsu.route_step_id AND rs.app_sid = rsu.app_sid
		  JOIN csr_user cu ON rsu.csr_user_sid = cu.csr_user_sid AND rsu.app_sid = cu.app_sid
		  LEFT JOIN route_step_vote rsv
		  	ON rs.route_step_id = rsv.route_step_id AND rs.app_sid = rsv.app_sid
		  	AND cu.csr_user_sid = rsv.user_sid AND cu.app_sid = rsv.app_sid
		 WHERE r.section_sid IN (SELECT column_value FROM TABLE(t_section_ids));
END;

PROCEDURE GetRoute(
	in_section_sid				IN	security_pkg.T_SID_ID,
	out_route_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_route_step_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur 	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_section_sids		security_pkg.T_SID_IDS;
BEGIN
	-- convert to array
	SELECT in_section_sid
	   BULK COLLECT INTO v_section_sids
	  FROM DUAL;
	-- request single route
	GetRoutes(v_section_sids, out_route_cur, out_route_step_cur, out_route_step_user_cur);
END;

PROCEDURE ClearRouteSteps(
	in_route_id			IN	route.route_id%TYPE,
	in_route_step_ids	IN	security_pkg.T_SID_IDS	-- an array of ids that WON'T be deleted (so we can update them)
)
AS
	t_route_step_ids	security.T_SID_TABLE;
	v_section_sid		security_pkg.T_SID_ID;
	v_flow_state_id		flow_state.flow_state_id%TYPE;
	v_flow_item_id		flow_item.flow_item_id%TYPE;
	v_rc				NUMBER(10);
	v_flow_label		flow_state.label%TYPE;
BEGIN
	SELECT section_sid, flow_state_id
	  INTO v_section_sid, v_flow_state_id
	  FROM route WHERE route_id = in_route_id;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||v_section_sid);
	END IF;

	t_route_step_ids := security_pkg.SidArrayToTable(in_route_step_ids);

	-- update step to null only if we're going to delete it
	UPDATE section
	   SET current_route_step_id = NULL
	 WHERE section_sid = v_section_sid
	   AND flow_item_id IN (
			SELECT flow_item_id FROM flow_item WHERE current_state_id = v_flow_state_id)
	   AND current_route_step_id NOT IN (SELECT column_value FROM TABLE(t_route_step_ids));

	-- delete users
	DELETE FROM route_step_user
	 WHERE route_step_id IN (
		SELECT route_step_id FROM route_step WHERE route_id = in_route_id AND route_step_id NOT IN (SELECT column_value FROM TABLE(t_route_step_ids))
	 );
	DELETE FROM route_step_vote
	 WHERE route_step_id IN (
		SELECT route_step_id FROM route_step WHERE route_id = in_route_id AND route_step_id NOT IN (SELECT column_value FROM TABLE(t_route_step_ids))
	 );

	DELETE FROM route_step_vote
	 WHERE dest_route_step_id IN (
		SELECT route_step_id FROM route_step WHERE route_id = in_route_id AND route_step_id NOT IN (SELECT column_value FROM TABLE(t_route_step_ids))
	 );

	-- delete from section alert
	DELETE FROM section_alert
	 WHERE route_step_id NOT IN (SELECT column_value FROM TABLE(t_route_step_ids))
	   AND section_sid = v_section_sid
	   AND flow_state_id = v_flow_state_id;

	-- delete steps
	DELETE FROM route_step
	 WHERE route_id = in_route_id
	   AND route_step_id NOT IN (SELECT column_value FROM TABLE(t_route_step_ids));

	v_rc := SQL%ROWCOUNT;

	IF v_rc > 0 THEN
		SELECT label
		  INTO v_flow_label
		  FROM flow_state fs
		 WHERE flow_state_id = v_flow_state_id;

		INSERT INTO route_log (ROUTE_STEP_ID, ROUTE_ID, ROUTE_LOG_ID, CSR_USER_SID, SUMMARY, DESCRIPTION, PARAM_1, PARAM_2)
			 VALUES (-1, in_route_id, route_log_id_seq.nextval, sys_context('security', 'sid'), 'Route step removed', '{0} route step(s) removed for state "{1}"', v_rc, v_flow_label);
	END IF;

END;

PROCEDURE InsertStepAfter(
	in_route_id				IN	route.route_id%TYPE,
	in_route_step_id		IN	route_step.route_step_id%TYPE,
	in_work_days_offset		IN	route_step.work_days_offset%TYPE,
	in_user_sids			IN	security_pkg.T_SID_IDS,
	out_route_step_id		OUT	route_step.route_step_id%TYPE
)
AS
	t_user_ids				security.T_SID_TABLE;
	v_pos					route_step.pos%TYPE;
	v_cnt					NUMBER(10);
	v_due_dtm				route.due_dtm%TYPE;
	v_new_users				route_log.param_1%TYPE;
BEGIN
	t_user_ids := security_pkg.SidArrayToTable(in_user_sids);

	SELECT due_dtm
	  INTO v_due_dtm
	  FROM route
	 WHERE route_id = in_route_id;

	-- figure out position
	SELECT POS + 1
	  INTO v_pos
	  FROM route_step
	 WHERE route_step_id = in_route_step_id;

	SELECT count(route_step_id)
	  INTO v_cnt
	  FROM route_step
	 WHERE route_id = in_route_id AND pos = v_pos;

	IF v_cnt > 0 THEN
		UPDATE route_step
		   SET pos = pos + 1
		 WHERE route_id = in_route_id
		   AND pos >= v_pos;
	END IF;

	INSERT INTO route_step
				(route_step_id, route_id, work_days_offset, step_due_dtm, pos)
		 VALUES
				(route_step_id_seq.NEXTVAL, in_route_id, in_work_days_offset,
				aspen2.utils_pkg.SubtractWorkingDays(v_due_dtm, in_work_days_offset),
				v_pos)
	   RETURNING ROUTE_STEP_ID INTO out_route_step_id;

	-- insert users
	INSERT
	  INTO route_step_user (route_step_id, csr_user_sid)
		SELECT out_route_step_id, column_value FROM TABLE(t_user_ids);

	SELECT stragg(full_name)
	  INTO v_new_users
	  FROM route_step_user rsu
	  JOIN csr_user u ON rsu.csr_user_sid = u.csr_user_sid
	 WHERE route_step_id = out_route_step_id;

	INSERT INTO route_log (ROUTE_STEP_ID, ROUTE_ID, ROUTE_LOG_ID, CSR_USER_SID, SUMMARY, DESCRIPTION, PARAM_1)
	VALUES (out_route_step_id, in_route_id, route_log_id_seq.nextval, sys_context('security', 'sid'), 'Route step added', 'Route step for {0} added', v_new_users);
END;

PROCEDURE SetRouteStep(
	in_route_id				IN	route.route_id%TYPE,
	in_route_step_id		IN	route_step.route_step_id%TYPE,
	in_work_days_offset		IN	route_step.work_days_offset%TYPE,
	in_user_sids			IN	security_pkg.T_SID_IDS,
	in_pos					IN	NUMBER DEFAULT 0,
	out_route_step_id		OUT	route_step.route_step_id%TYPE
)
AS
	t_user_ids				security.T_SID_TABLE;
	v_due_dtm				route.due_dtm%TYPE;
	v_flow_label			flow_state.label%TYPE;
BEGIN
	-- TODO: security???

	t_user_ids := security_pkg.SidArrayToTable(in_user_sids);

	SELECT due_dtm
	  INTO v_due_dtm
	  FROM route
	 WHERE route_id = in_route_id;

	SELECT label
	  INTO v_flow_label
	  FROM route r
	  JOIN flow_state fs ON r.flow_state_id = fs.flow_state_id
	 WHERE r.route_id = in_route_id;

	IF in_route_step_id < 0 THEN
		-- insert at specific position
		-- if it's occupied already, then we need to move all remaining items
		BEGIN
			-- create new step
			INSERT INTO route_step
				(route_step_id, route_id, work_days_offset, step_due_dtm, pos)
			VALUES
				(route_step_id_seq.NEXTVAL, in_route_id, in_work_days_offset,
				aspen2.utils_pkg.SubtractWorkingDays(v_due_dtm, in_work_days_offset),
				in_pos)
			RETURNING ROUTE_STEP_ID INTO out_route_step_id;

			INSERT INTO route_log (ROUTE_STEP_ID, ROUTE_ID, ROUTE_LOG_ID, CSR_USER_SID, SUMMARY, DESCRIPTION, param_1, param_2, param_3)
			VALUES (out_route_step_id, in_route_id, route_log_id_seq.nextval, sys_context('security', 'sid'), 'Route step added', 'Route step added at position {0} for state "{1}", due on {2}', in_pos, v_flow_label, aspen2.utils_pkg.SubtractWorkingDays(v_due_dtm, in_work_days_offset));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- means that there is step at this position, so just move all of them 1 step forward and make step for current step
				UPDATE route_step
				   SET pos = pos + 1
				 WHERE route_id = in_route_id
				   AND pos >= in_pos;

				-- now it has to be success
				INSERT INTO route_step
					(route_step_id, route_id, work_days_offset, step_due_dtm, pos)
				VALUES
					(route_step_id_seq.NEXTVAL, in_route_id, in_work_days_offset,
					aspen2.utils_pkg.SubtractWorkingDays(v_due_dtm, in_work_days_offset),
					in_pos)
				RETURNING ROUTE_STEP_ID INTO out_route_step_id;

				INSERT INTO route_log (ROUTE_STEP_ID, ROUTE_ID, ROUTE_LOG_ID, CSR_USER_SID, SUMMARY, DESCRIPTION, param_1, param_2, param_3)
			VALUES (out_route_step_id, in_route_id, route_log_id_seq.nextval, sys_context('security', 'sid'), 'Route step added', 'Route step added at position {0} for state "{1}", due on {2}', in_pos, v_flow_label, aspen2.utils_pkg.SubtractWorkingDays(v_due_dtm, in_work_days_offset));
		END;
	ELSE
		out_route_step_id := in_route_step_id;
	END IF;

	-- delete incorrect users
	DELETE FROM ROUTE_STEP_USER
	 WHERE route_step_id = out_route_step_id
	   AND csr_user_sid NOT IN (SELECT column_value FROM TABLE(t_user_ids));

	DELETE FROM ROUTE_STEP_VOTE
	 WHERE route_step_id = out_route_step_id
	   AND user_sid NOT IN (SELECT column_value FROM TABLE(t_user_ids));

	-- update users
	FOR r IN (
		SELECT column_value FROM TABLE(t_user_ids)
	)
	LOOP
		BEGIN
			INSERT INTO route_step_user (route_step_id, csr_user_sid)
				VALUES (out_route_step_id, r.column_value);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	-- update work days offset and due dtm in case we modified existing step
	IF in_route_step_id >= 0 THEN
		-- update days and due date of current step
		UPDATE route_step
		   SET work_days_offset = in_work_days_offset,
		       step_due_dtm = aspen2.utils_pkg.SubtractWorkingDays(v_due_dtm, in_work_days_offset)
	     WHERE route_step_id = out_route_step_id;

	    -- hmm, not sure, but I guess it's ok to clear reminder_sent flag if the route has been modified? This will make sure we resend the reminders at specific day.
	    UPDATE route_step_user
	       SET reminder_sent_dtm = NULL
	     WHERE route_step_id = out_route_step_id;
	END IF;
END;

PROCEDURE Split(
	in_section_sid			IN 	security_pkg.T_SID_ID,
	in_titles				IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_titles				security.T_VARCHAR2_TABLE;
	v_module_root_sid		security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','SID');
	v_out_sid				security_PKG.T_SID_ID;
	v_split_sids			security_PKG.T_SID_IDS;
	t_split_sids			security.T_SID_TABLE;
	v_needs_route_clear		NUMBER(1);
	v_flow_state_id 		flow_state.flow_state_id%TYPE;
	v_flow_item_id			section.flow_item_id%TYPE;
	v_cache_keys			security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	-- Security checks are done in CopySection (read and write reqired)
	t_titles := security_pkg.Varchar2ArrayToTable(in_titles);
	-- We need root sid
	SELECT module_root_sid
	  INTO v_module_root_sid
	  FROM SECTION
	 WHERE section_sid = in_section_sid;

	-- Copy sections and put them as child of src section
	FOR r IN (select value FROM TABLE(t_titles))
	LOOP
		BEGIN
			-- Security checks are made there
			CopySection(
				in_section_sid,
				in_section_sid, -- parent_sid
				r.value,
				v_out_sid
			);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				-- Hmm, just add it to list, so we fetch it, might be worth sending msg to people though
				SELECT SID_ID
				  INTO v_out_sid
				  FROM security.securable_object
				 WHERE parent_sid_id = in_section_sid
				   AND name = r.value;
		END;

		v_split_sids(v_split_sids.COUNT) := v_out_sid;

		UPDATE section SET is_split = 1 WHERE section_sid = v_out_sid;

		-- Copy routes
		FOR r IN (SELECT route_id, flow_state_id FROM route WHERE section_sid = in_section_sid)
		LOOP
			section_pkg.ApplyRoute(r.route_id, v_out_sid, r.flow_state_id);
		END LOOP;
	END LOOP;

	-- Clear parent's route only if parent is in initial flow state
	SELECT CASE WHEN count(*) > 0 THEN 1 ELSE 0 END
	  INTO v_needs_route_clear
	  FROM flow f, flow_item fi, section s
     WHERE s.flow_item_id = fi.flow_item_id
       AND fi.current_state_id = f.default_state_id
       AND fi.flow_sid = f.flow_sid
       AND s.section_sid = in_section_sid;

	IF v_needs_route_clear = 1 THEN
		UPDATE section
		   SET current_route_step_id = NULL
		 WHERE section_sid = in_section_sid;

		FOR r_route IN (
			SELECT r.route_id, rs.route_step_id
			  FROM route r, route_step rs
			 WHERE r.route_id = rs.route_id
			   AND r.section_sid = in_section_sid
		)
		LOOP
			-- clear alerts
			DELETE FROM section_alert
			 WHERE route_step_id = r_route.route_step_id;

			-- clear route step users and votes
			DELETE FROM route_step_user
			 WHERE route_step_id = r_route.route_step_id;

			DELETE FROM route_step_vote
			 WHERE route_step_id = r_route.route_step_id;

			-- clear step
			DELETE FROM route_step
			 WHERE route_step_id = r_route.route_step_id;
		END LOOP;

		DELETE FROM route
		 WHERE section_sid = in_section_sid;
	END IF;

	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM section
	 WHERE section_sid = in_section_sid;

	SELECT split_question_flow_state_id
	  INTO v_flow_state_id
	  FROM section_flow sf
	  JOIN flow_item fi ON sf.flow_sid = fi.flow_sid
	  WHERE fi.flow_item_id = v_flow_item_id;

	IF v_flow_state_id IS NOT NULL THEN
		flow_pkg.SetItemState(v_flow_item_id, v_flow_state_id, 'Section split', v_cache_keys, SYS_CONTEXT('SECURITY', 'SID'), 1);
	END IF;

	-- before re-fetching sections add src section_sid, so we can refetch it (ie. when route has been changed!)
	v_split_sids(v_split_sids.COUNT) := in_section_sid;
	t_split_sids := security_pkg.SidArrayToTable(v_split_sids);

	-- Ensure position data is valid for the parent
	FixSectionPositionData(SYS_CONTEXT('SECURITY','APP'), v_module_root_sid, in_section_sid);

	-- return updated sections
	GetSections(v_split_sids, out_cur);
END;

PROCEDURE RemoveSplit(
	in_section_sid			IN 	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_flow_state_id 		flow_state.flow_state_id%TYPE;
	v_flow_item_id			section.flow_item_id%TYPE;
	v_split_flow_state		section_flow.split_question_flow_state_id%TYPE;
	v_cache_keys			security_pkg.T_VARCHAR2_ARRAY;
	v_cnt					NUMBER;
	v_parent_sid			security_pkg.T_SID_ID;
	v_split_sids			security_PKG.T_SID_IDS;
BEGIN
	SELECT parent_sid
	  INTO v_parent_sid
	  FROM section
	 WHERE section_sid = in_section_sid;

	SELECT count(section_sid)
	  INTO v_cnt
	  FROM section
	 WHERE parent_sid = v_parent_sid
	   AND section_sid != in_section_sid;

	SELECT flow_item_id
	  INTO v_flow_item_id
	  FROM section
	 WHERE section_sid = v_parent_sid;

	SELECT split_question_flow_state_id
	  INTO v_split_flow_state
	  FROM section_flow sf
	  JOIN flow_item fi ON sf.flow_sid = fi.flow_sid
	  WHERE fi.flow_item_id = v_flow_item_id;

	security.securableObject_pkg.DeleteSO(SYS_CONTEXT('SECURITY','ACT'), in_section_sid);
	IF v_cnt = 0 AND v_split_flow_state IS NOT NULL THEN
		SELECT flow_state_id
		  INTO v_flow_state_id
		  FROM flow_state_log
		 WHERE flow_item_id = v_flow_item_id
		   AND flow_state_log_id = (SELECT MAX(flow_state_log_id) - 1
									  FROM csr.flow_state_log
									 WHERE flow_state_id = v_split_flow_state and flow_item_id = v_flow_item_id
						  );
		IF v_flow_state_id IS NOT NULL THEN
			flow_pkg.SetItemState(v_flow_item_id, v_flow_state_id, '', v_cache_keys, SYS_CONTEXT('SECURITY', 'SID'), 1);
		END IF;
	END IF;

	v_split_sids(v_split_sids.COUNT) := v_parent_sid;
	GetSections(v_split_sids, out_cur);
END;

PROCEDURE ApplyRoute(
	in_route_id				IN	ROUTE.ROUTE_ID%TYPE,
	in_dst_section_sid		IN	SECTION.SECTION_SID%TYPE,
	in_dst_flow_state_id	IN	ROUTE.FLOW_STATE_ID%TYPE
)
AS
	v_due_dtm						route.due_dtm%TYPE;
	v_dst_route_id					NUMBER(10);
	v_route_step_id					NUMBER(10);
	v_needs_reset					NUMBER(1) := 0;
	v_is_current					NUMBER(1) := 0;
BEGIN
	-- Check access
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_dst_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on section with sid '||in_dst_section_sid);
	END IF;

	SELECT due_dtm
	  INTO v_due_dtm
	  FROM route
	 WHERE route_id = in_route_id;

	SetRoute(in_dst_section_sid, in_dst_flow_state_id, v_due_dtm, v_dst_route_id);

	-- are we overwriting current section's route. If so then make sure section doesn't use it anymore
	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
	  INTO v_is_current
	  FROM section s, flow_item fi
	 WHERE s.section_sid = in_dst_section_sid
	   AND s.flow_item_id = fi.flow_item_id
	   AND fi.current_state_id = in_dst_flow_state_id;

	IF v_is_current = 1 THEN
		-- make sure section is not on route
		UPDATE section
		   SET current_route_step_id = NULL
		 WHERE section_sid = in_dst_section_sid;
	END IF;

	-- clean old route steps
	-- XXX: this doesn't look like a great idea because surely we want to keep track
	-- of the alerts we're sending or due to send? Maybe it's ok for apply but we might be
	-- applying 90% of the same stuff.
	FOR r IN (
		SELECT route_step_id FROM route_step WHERE route_id = v_dst_route_id
	)
	LOOP
		DELETE FROM route_step_user WHERE route_step_id = r.route_step_id;
		DELETE FROM route_step_vote WHERE route_step_id = r.route_step_id;
		DELETE FROM section_alert WHERE route_step_id = r.route_step_id;
		DELETE FROM route_step WHERE route_step_id = r.route_step_id;
	END LOOP;

	-- copy steps and users
	FOR r IN (
		SELECT route_step_id FROM route_step WHERE route_id = in_route_id
	)
	LOOP
		SELECT route_step_id_seq.nextval
		  INTO v_route_step_id
		  FROM DUAL;

		INSERT INTO route_step (route_step_id, route_id, work_days_offset, step_due_dtm, pos)
			  SELECT v_route_step_id, v_dst_route_id, work_days_offset, step_due_dtm, pos
				FROM route_step
			   WHERE route_step_id = r.route_step_id
			   ORDER BY work_days_offset DESC;

		INSERT INTO route_step_user (route_step_id, csr_user_sid)
			  SELECT v_route_step_id, csr_user_sid
				FROM route_step_user
			   WHERE route_step_id = r.route_step_id;
	END LOOP;

	BEGIN
		SELECT 1
		  INTO v_needs_reset
		  FROM section s
		  JOIN flow_item fi ON s.flow_item_id = fi.flow_item_id AND fi.current_state_id = in_dst_flow_state_id AND s.app_sid = fi.app_sid
		  JOIN section_routed_flow_state srfs ON srfs.flow_state_id = fi.current_state_id AND srfs.app_sid = fi.app_sid
		 WHERE s.section_sid = in_dst_section_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	IF v_needs_reset = 1 THEN
		ResetSectionRoute(in_dst_section_sid, in_dst_flow_state_id, null);
	END IF;
END;

PROCEDURE ResetSectionRoute(
	in_section_sid				IN 	security_pkg.T_SID_ID,
	in_flow_state_id			IN  route.flow_state_id%TYPE,
	in_comment					IN	section_trans_comment.comment_text%TYPE
)
AS
	v_first_route_step_id		route_step.route_step_id%TYPE;
BEGIN
	-- Check access
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on section with sid '||in_section_sid);
	END IF;

	BEGIN
		v_first_route_step_id := GetFirstRouteStepId(in_section_sid, in_flow_state_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- route is empty
	END;


	-- set route's initial step on section
	UPDATE section
	   SET current_route_step_id = v_first_route_step_id
	 WHERE section_sid = in_section_sid;

	-- reset route's completed_dtm
	UPDATE route
	   SET completed_dtm = NULL
	 WHERE route_id = (SELECT route_id FROM route_step WHERE route_step_id = v_first_route_step_id);

	-- make sure we clean scheduled invalid alerts
	ProcessStateChangeAlerts(in_section_sid);

	-- insert transition comment
	IF LENGTH(TRIM(in_comment)) > 0 THEN
		INSERT INTO section_trans_comment
			(section_trans_comment_id, section_sid, entered_by_sid, entered_dtm, comment_text)
		VALUES
			(SECTION_TRANS_COMMENT_ID_SEQ.nextval, in_section_sid, SYS_CONTEXT('SECURITY','SID'), SYSDATE, in_comment);
	END IF;
END;

PROCEDURE INTERNAL_DeleteRouteStep(
	in_route_step_id 		IN route_step.route_step_id%TYPE
)
AS
	v_work_days_offset			route_step.work_days_offset%TYPE;
	v_step_due_dtm				route_step.step_due_dtm%TYPE;
	v_pos						route_step.pos%TYPE;
	v_old_users					route_log.param_1%TYPE;
	v_route_id					route_step.route_id%TYPE;
	v_prev_step_id				route_step.route_step_id%TYPE;
	v_next_step_id				route_step.route_step_id%TYPE;
	v_recurse_delete_step_id	route_step.route_step_id%TYPE := NULL;
	v_cnt 						NUMBER(10);
BEGIN
	-- inernal code - no security

	-- what's the due date + route_id of the step we're deleting?
	-- e.g. with A -> B -> C, if we remove B, then A will receive B's due date.
	SELECT work_days_offset, step_due_dtm, pos, route_id
	  INTO v_work_days_offset, v_step_due_dtm, v_pos, v_route_id
	  FROM route_step
	 WHERE route_step_id = in_route_step_id;

	-- now, we also need to double check because we might have two adjacent steps
	-- with the same users. This is especially common if you add a user, and select
	-- that you want it returning to you for review, i.e. A -> B -> A. If we delete
	-- the route step for user B, then we end up with A -> A. This isn't the end of
	-- the world but it's potentially confusing (users might miss this and think) their
	-- job was done.
	SELECT prev_step_id, next_step_Id
	  INTO v_prev_step_id, v_next_step_id
	  FROM (
	    SELECT rs.route_step_id,
	        LAG(route_step_id) OVER (ORDER BY POS) prev_step_id,
	        LEAD(route_step_id) OVER (ORDER BY POS) next_step_id
	      FROM route r
	      JOIN route_step rs ON r.route_id = rs.route_id AND r.app_sid = rs.app_sid
	     WHERE r.route_id = v_route_id
	  )
	 WHERE route_step_id = in_route_step_id;

	-- see if we need to delete the next step. We do a full join.
	-- If identical users are in both steps then we'll have values in both
	-- columns. If there's a difference we'll have some nulls. If we have
	-- no nulls, then it means they're both the same.
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM (
		SELECT x.csr_user_sid x_sid, y.csr_user_sid y_sid
		  FROM (
		  	SELECT csr_user_sid
			  FROM route_step_user
			 WHERE route_step_id = v_prev_step_id
		  )x
		  FULL JOIN (
		  	SELECT csr_user_sid
			  FROM route_step_user
			 WHERE route_step_id = v_next_step_id
		  )y ON x.csr_user_sid = y.csr_user_sid
	 )
	 WHERE x_sid IS NULL OR y_sid IS NULL;

	IF v_cnt = 0 THEN
		v_recurse_delete_step_id := v_next_step_id;
	END IF;

	UPDATE route_step
	   SET work_days_offset = v_work_days_offset,
	   	step_due_dtm = v_step_due_dtm
	 WHERE route_step_id = v_prev_step_id;

	UPDATE section
	   SET current_route_step_id = null
	 WHERE current_route_step_id = in_route_step_id;

	SELECT stragg(full_name)
	  INTO v_old_users
	  FROM route_step_user rsu
	  JOIN csr_user u ON rsu.csr_user_sid = u.csr_user_sid
	 WHERE route_step_id = in_route_step_id;

	DELETE FROM route_step_user
	 WHERE route_step_id = in_route_step_id;

	DELETE FROM route_step_vote
	 WHERE route_step_id = in_route_step_id;

	DELETE FROM route_step_vote
	 WHERE dest_route_step_id = in_route_step_id;

	DELETE FROM section_alert
	 WHERE route_step_id = in_route_step_id;

	DELETE FROM route_step
	 WHERE route_step_id = in_route_step_id;

	INSERT INTO route_log (ROUTE_STEP_ID, ROUTE_ID, ROUTE_LOG_ID, CSR_USER_SID, SUMMARY, DESCRIPTION, PARAM_1)
	VALUES (in_route_step_id, v_route_id, route_log_id_seq.nextval, sys_context('security', 'sid'), 'Route step deleted', 'Route step for {0} deleted', v_old_users);

	IF v_recurse_delete_step_id IS NOT NULL THEN
		INTERNAL_DeleteRouteStep(v_recurse_delete_step_id);
	END IF;
END;

PROCEDURE VoteAndProcessAction(
	in_section_sid    		IN  security_pkg.T_SID_ID,
	in_vote_direction		IN  route_step_vote.vote_direction%TYPE DEFAULT 0,
	in_is_casting_vote		IN  NUMBER DEFAULT 0,
	in_is_return			IN	NUMBER DEFAULT 0,
	in_dest_flow_state_id	IN  route_step_vote.dest_flow_state_id%TYPE DEFAULT NULL,
	in_dest_route_step_id	IN 	route_step_vote.dest_route_step_id%TYPE DEFAULT NULL,
	in_send_alert			IN	NUMBER DEFAULT 1
)
AS
	v_cnt 					NUMBER(10);
	v_users_left_to_vote 	NUMBER(10);
	v_route_id				route.route_id%TYPE;
	v_route_step_id      	route_step.route_step_id%TYPE;
	v_current_flow_state_id flow_state.flow_state_id%TYPE;
	v_max_direction			route_step_vote.vote_direction%TYPE;
	v_max_flow_state_id		route_step_vote.dest_flow_state_id%TYPE;
	v_max_route_step_id		route_step_vote.dest_route_step_id%TYPE;
	v_old_users				route_log.param_1%TYPE;
	v_new_users				route_log.param_2%TYPE;
	v_description			VARCHAR2(1024);
BEGIN
	SELECT s.current_route_step_id, fi.current_state_id, rs.route_id
	  INTO v_route_step_id, v_current_flow_state_id, v_route_id
	  FROM section s
	  JOIN flow_item fi ON s.flow_item_id = fi.flow_item_id AND s.app_sid = fi.app_sid
	  JOIN route_step rs ON s.current_route_step_id = rs.route_step_id and s.app_sid = rs.app_sid
	 WHERE s.section_sid = in_section_sid;

	-- vote
	IF in_vote_direction != 0 AND v_route_step_id IS NOT NULL THEN
		BEGIN
			INSERT INTO route_step_vote (route_step_id, user_sid, vote_dtm, vote_direction, dest_flow_state_id, dest_route_step_id, is_return)
				VALUES (v_route_step_id, SYS_CONTEXT('SECURITY','SID'), SYSDATE, in_vote_direction, in_dest_flow_state_id, in_dest_route_step_id, in_is_return);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE route_step_vote
				   SET vote_dtm = SYSDATE, vote_direction = in_vote_direction,
				    dest_flow_state_id = in_dest_flow_state_id, dest_route_step_id = in_dest_route_step_id, is_return = in_is_return
				 WHERE route_step_id = v_route_step_id
				   AND user_sid = SYS_CONTEXT('SECURITY','SID');
		END;
	END IF;

	IF in_is_casting_vote = 1 OR in_is_return = 1 THEN
		-- casting votes override everything
		v_max_direction := in_vote_direction;
		v_max_flow_state_id := in_dest_flow_state_id;
		v_max_route_step_id := in_dest_route_step_id;
		v_users_left_to_vote := 0;
	ELSE
		SELECT COUNT(*)
		  INTO v_users_left_to_vote
		  FROM (
		    SELECT route_step_id, csr_user_sid
		      FROM route_step_user
		     WHERE route_step_id = v_route_step_id
		     MINUS
		    SELECT route_step_id, user_sid
		      FROM route_step_vote
		     WHERE route_step_id = v_route_step_id
		);

		IF v_users_left_to_vote = 0 THEN
			-- did anyone vote in favour? If so then we can proceed

			-- This is a bit arbitrary (using MAX on the flow and route ids). It's not so bad on the
			-- routings (which are linear), but for the workflow states we ought to restrict it so that
			-- we can't have user A voting for "Legal check" and user B voting for "Normal submission".
			-- I guess the best strategy would be to restrict the UI once someone has voted so that people
			-- can either reject, or go with the initial vote.
			BEGIN
				SELECT vote_direction, dest_flow_state_id, dest_route_step_id
				  INTO v_max_direction, v_max_flow_state_id, v_max_route_step_id
				  FROM (
					SELECT vote_direction, dest_flow_state_id, dest_route_step_id,
						ROW_NUMBER() OVER (ORDER BY vote_direction DESC) rn
					  FROM route_step_vote
					 WHERE route_step_id = v_route_step_id
				  )
				  WHERE rn = 1;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					-- wtf? just run with what we've been passed
					v_max_direction := in_vote_direction;
					v_max_flow_state_id := in_dest_flow_state_id;
					v_max_route_step_id := in_dest_route_step_id;
			END;
		END IF;
	END IF;

	IF v_users_left_to_vote = 0 THEN
		IF v_max_direction = 0 THEN
			-- this should never happen
			RAISE_APPLICATION_ERROR(-20001, 'No overall vote direction');
		END IF;

		-- if we're changing flow_state then remove the users who declined otherwise they'll get annoyed
		-- if we re-route and ask them again.
		IF in_dest_flow_state_id IS NOT NULL THEN
			DELETE FROM route_step_user
			 WHERE (route_step_id, csr_user_sid) IN (
			 	SELECT rsv.route_step_id, rsv.user_sid
			 	  FROM route_step_vote rsv
			 	  JOIN route_step rs ON rsv.route_step_id = rs.route_step_id AND rsv.app_sid = rs.app_sid
			 	  JOIN route r
			 	  	ON rs.route_id = r.route_id AND rs.app_sid = r.app_sid
			 	   AND r.section_sid = in_section_sid
			 	   AND r.flow_state_id = v_current_flow_state_id
			 	 WHERE rsv.vote_direction = -1
				   AND rsv.is_return = 0
			 );
			-- clean up route steps
			FOR r IN (
				SELECT rs.route_step_id
				  FROM route_step rs
				  JOIN route r
			 	  	ON rs.route_id = r.route_id AND rs.app_sid = r.app_sid
			 	  	AND r.section_sid = in_section_sid
			 	  	AND r.flow_state_id = v_current_flow_state_id
				  LEFT JOIN route_step_user rsu ON rs.route_step_id = rsu.route_step_id AND rs.app_sid = rsu.app_sid
				 GROUP BY rs.route_step_id
				 HAVING COUNT(rsu.csr_user_sid) = 0
			)
			LOOP
				section_pkg.INTERNAL_DeleteRouteStep(r.route_step_id);
				IF r.route_step_id = v_route_step_id THEN
					v_route_step_id := null; -- it's deleted
				END IF;
			END LOOP;
		END IF;

		-- if everyone has deleted themselves then remove the step
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM route_step_user rsu
		  LEFT JOIN route_step_vote rsv
		  	ON rsu.route_step_id = rsv.route_step_id AND rsu.app_sid = rsv.app_sid
		  	AND rsu.csr_user_sid = rsv.user_sid AND rsu.app_sid = rsv.app_sid
		 WHERE rsu.route_step_id = v_route_step_id
		   AND (NVL(vote_direction, 1) = 1 OR rsv.is_return = 1);

		-- it's a change so clear everything down (if it's a flow_state change).
		-- if it's a step change, then delete votes from everyone except those who have declined
		DELETE FROM route_step_vote
		 WHERE route_step_id = v_route_step_id
		   AND (in_dest_flow_state_id IS NOT NULL OR NOT (vote_direction = -1 AND is_return = 0)); -- leave declines if within the route step still

		SELECT stragg(full_name)
		  INTO v_old_users
		  FROM route_step_user rsu
		  JOIN csr_user u ON rsu.csr_user_sid = u.csr_user_sid
		 WHERE route_step_id = v_route_step_id;

		IF v_cnt = 0 AND v_route_step_id IS NOT NULL THEN
			section_pkg.INTERNAL_DeleteRouteStep(v_route_step_id);
		END IF;

		IF v_max_route_step_id IS NOT NULL THEN
			-- means we need to advance to the given route step
			-- TODO: check if this is even a valid transition?
			UPDATE section
			   SET current_route_step_id = v_max_route_step_id
			 WHERE section_sid = in_section_sid;

			-- send state change alerts
			-- We must do this AFTER updating current_route_step_id
			-- hence why we pass through the vote direction
			ProcessStateChangeAlerts(in_section_sid, v_max_direction);

			SELECT stragg(full_name)
			  INTO v_new_users
			  FROM route_step_user rsu
			  JOIN csr_user u ON rsu.csr_user_sid = u.csr_user_sid
			 WHERE route_step_id = v_max_route_step_id;

			IF v_max_direction = 1 THEN v_description := 'Route step for {0} submitted to {1}';
			ELSIF in_is_return = 1 THEN v_description := 'Route step for {0} returned to {1}';
			ELSIF v_max_direction = -1 THEN v_description := 'Route step for {0} rejected to {1}';
			ELSE v_description := 'er...error?'; END IF;

			INSERT INTO route_log (ROUTE_STEP_ID, ROUTE_ID, ROUTE_LOG_ID, CSR_USER_SID, SUMMARY, DESCRIPTION, PARAM_1, PARAM_2)
			VALUES (v_route_step_id, v_route_id, route_log_id_seq.nextval, sys_context('security', 'sid'), 'Route step changed', v_description, v_old_users, v_new_users);
		ELSIF v_max_flow_state_id IS NOT NULL THEN
			-- we're changing state, it means the route has been completed (if any)
			IF v_route_step_id IS NOT NULL THEN
				UPDATE route
				   SET completed_dtm = SYSDATE
				 WHERE route_id = (SELECT route_id FROM route_step WHERE route_step_id = v_route_step_id);
			END IF;

			SetSectionState(in_section_sid, v_max_flow_state_id, v_max_direction);
		END IF;
	END IF;
END;

-- TODO  -- in admin if we delete we need to look at votes etc to see if everyone has voted?
PROCEDURE AdvanceSectionState(
	in_section_sid			IN 	security_pkg.T_SID_ID,
	in_comment				IN	section_trans_comment.comment_text%TYPE,
	in_dest_flow_state_id	IN	flow_state.flow_state_id%TYPE,
	in_vote_direction		IN  NUMBER DEFAULT 0,
	in_is_return			IN	NUMBER DEFAULT 0,
	in_is_casting_vote	    IN  NUMBER DEFAULT 0,
	in_send_alert			IN	NUMBER DEFAULT 1,
	out_flow_state_id		OUT	flow_state.flow_state_id%TYPE
)
AS
	v_section_sids			security_pkg.T_SID_IDS;	-- we will have only single element here
BEGIN
	VoteAndProcessAction(
		in_section_sid    		=> in_section_sid,
		in_vote_direction		=> in_vote_direction,
		in_dest_flow_state_id	=> in_dest_flow_state_id,
		in_is_casting_vote	    => in_is_casting_vote,
		in_is_return			=> in_is_return,
		in_send_alert			=> in_send_alert
	);

	-- insert transition comment
	IF LENGTH(TRIM(in_comment)) > 0 THEN
		INSERT INTO section_trans_comment
			(section_trans_comment_id, section_sid, entered_by_sid, entered_dtm, comment_text)
		VALUES
			(SECTION_TRANS_COMMENT_ID_SEQ.nextval, in_section_sid, SYS_CONTEXT('SECURITY','SID'), SYSDATE, in_comment);
	END IF;

	SELECT NVL(fi.current_state_id, -1) -- we can't return null
	  INTO out_flow_state_id
	  FROM section s
	  JOIN flow_item fi ON s.flow_item_id = fi.flow_item_id AND s.app_sid = fi.app_sid
	 WHERE s.section_sid = in_section_sid;
END;

PROCEDURE AdvanceSectionStep(
	in_section_sid			IN 	security_pkg.T_SID_ID,
	in_comment				IN	section_trans_comment.comment_text%TYPE,
	in_dest_route_step_id	IN	section.current_route_step_id%TYPE,
	in_vote_direction		IN  NUMBER DEFAULT 0,
	in_is_return			IN	NUMBER DEFAULT 0,
	in_is_casting_vote	    IN  NUMBER DEFAULT 0,
	in_send_alert			IN	NUMBER DEFAULT 1,
	out_route_step_id		OUT	section.current_route_step_id%TYPE
)
AS
	v_cnt			NUMBER(1);
BEGIN
	-- Rather than doing a security check, we check whether current route step involves this user
	-- or it's first step in the route (so the setRoute stuff could set initial step)
	SELECT CASE WHEN count(csr_user_sid) > 0 THEN 1 ELSE 0 END
	  INTO v_cnt
	  FROM route_step_user
	 WHERE route_step_id = (SELECT current_route_step_id FROM section WHERE section_sid = in_section_sid)
	   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID');

	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'You aren''t part of the current route for the section with sid '||in_section_sid||'.');
	END IF;

	VoteAndProcessAction(
		in_section_sid    		=> in_section_sid,
		in_vote_direction		=> in_vote_direction,
		in_dest_route_step_id	=> in_dest_route_step_id,
		in_is_casting_vote	    => in_is_casting_vote,
		in_is_return			=> in_is_return,
		in_send_alert			=> in_send_alert
	);

	-- insert transition comment
	IF LENGTH(TRIM(in_comment)) > 0 THEN
		INSERT INTO section_trans_comment
			(section_trans_comment_id, section_sid, entered_by_sid, entered_dtm, comment_text)
		VALUES
			(SECTION_TRANS_COMMENT_ID_SEQ.nextval, in_section_sid, SYS_CONTEXT('SECURITY','SID'), SYSDATE, in_comment);
	END IF;

	-- return the current step which might or might not have changed
	SELECT NVL(current_route_step_id, -1) -- we can't return null
	  INTO out_route_step_id
	  FROM section
	 WHERE section_sid = in_section_sid;
END;

PROCEDURE GetFlowSummary(
	in_parent_section_sid			IN security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_flow_sid				security_PKG.T_SID_ID;
BEGIN
	-- get the flow sid, no matter if we ask for module or section
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM (
		SELECT flow_sid FROM section_module WHERE module_root_sid = in_parent_section_sid
		 UNION
		SELECT flow_sid FROM section_module WHERE module_root_sid = (
			SELECT module_root_sid FROM section WHERE section_sid = in_parent_section_sid
		)
	);

	OPEN out_cur FOR
		-- XXX: yikes do we really really need correlated sub-queries like this?
		SELECT fs.flow_state_id, fs.state_colour colour, fs.label, (
			SELECT COUNT(section_sid)
			  FROM section
			 WHERE flow_item_id IN (
				SELECT flow_item_id FROM flow_item WHERE current_state_id = fs.flow_state_id
			  )
			   AND title_only = 0
			   AND CONNECT_BY_ISLEAF = 1
			  START WITH section_sid in (
				SELECT sid_id FROM security.securable_object WHERE parent_sid_id = in_parent_section_sid
			 )
			CONNECT BY PRIOR section_sid = parent_sid
		  ) total_number
		  FROM flow_state fs
		 WHERE fs.flow_sid = v_flow_sid
		 ORDER BY label;

--		SELECT fs.flow_state_id, fs.state_colour, fs.label, count(s.section_sid) total_number
--		  FROM section s , flow_item fi, flow_state fs
--		 WHERE s.flow_item_id = fi.flow_item_id
--		   AND fs.flow_state_id = fi.current_state_id
--		   AND s.title_only = 0
--		   AND CONNECT_BY_ISLEAF = 1
--	      START WITH section_sid in (
--				SELECT sid_id FROM security.securable_object WHERE parent_sid_id = in_parent_section_sid)
--	    CONNECT BY PRIOR section_sid = parent_sid
--	     GROUP BY fs.flow_state_id, fs.state_colour, fs.label;
END;

PROCEDURE GetAlertData(
    out_cur    OUT  SYS_REFCURSOR
)
AS
BEGIN
	--Clear out old alerts ie state changed twice
	UPDATE section_alert
	   SET cancelled_dtm = SYSDATE
	 WHERE section_alert_id IN (
		SELECT sa.section_alert_id
		  FROM section_alert sa
			 JOIN section s ON sa.section_sid = s.section_sid AND sa.app_sid = s.app_sid
			 JOIN flow_item fi ON s.flow_item_id = fi.flow_item_id AND s.app_sid = fi.app_sid
		 WHERE sent_dtm IS NULL AND cancelled_DTM IS NULL AND fi.current_state_id != sa.flow_state_id
	);

	--Cancel inactive questionnaire alerts
	UPDATE section_alert
	   SET cancelled_dtm = SYSDATE
	 WHERE section_alert_id IN (
		SELECT sa.section_alert_id
		  FROM section_alert sa
			 JOIN section s ON sa.section_sid = s.section_sid AND sa.app_sid = s.app_sid
			 JOIN section_module sm ON s.module_root_sid = sm.module_root_sid AND s.app_sid = sm.app_sid
		 WHERE sent_dtm IS NULL AND cancelled_DTM IS NULL
		   AND sm.active = 0
	);

	OPEN out_cur FOR
		SELECT
			CASE WHEN sa.route_step_id IS NULL THEN NULL ELSE rs.step_due_dtm end due_dtm, -- step_due_dtm [need to upadte SectionStateChangeJob.cs]
			sa.app_sid, sa.customer_alert_type_id,
			sa.section_alert_id, sa.section_sid, sa.raised_dtm, s.title,
			fs.label state_label,
			fcu.full_name from_full_name, fcu.email from_email, fcu.csr_user_sid from_user_sid,
			tcu.full_name to_full_name, tcu.email to_email, tcu.friendly_name to_friendly_name, tcu.csr_user_sid to_user_sid
		  FROM section_alert sa
			 JOIN v$visible_version s ON sa.section_sid = s.section_sid AND sa.app_sid = s.app_sid
			 JOIN flow_state fs ON sa.flow_state_id = fs.flow_state_id AND sa.app_sid = fs.app_sid
			 JOIN csr_user tcu ON sa.notify_user_sid = tcu.csr_user_sid AND sa.app_sid = tcu.app_sid
			 JOIN csr_user fcu ON sa.from_user_sid = fcu.csr_user_sid AND sa.app_sid = fcu.app_sid
			 JOIN customer_alert_type cat ON sa.app_sid = cat.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_SECTION_STATE_CHANGE
			 LEFT JOIN route r ON fs.flow_state_id = r.flow_state_id AND s.section_sid = r.section_sid
			 LEFT JOIN route_step rs ON r.route_id = rs.route_id AND rs.route_step_id = sa.route_step_id
		 WHERE sent_dtm IS NULL AND cancelled_DTM IS NULL
		 ORDER BY sa.customer_alert_type_id, sa.notify_user_sid, state_label, s.title; -- order matters!
END;

PROCEDURE MarkSectionAlertsProcessed (
    in_section_alert_ids    IN    security_pkg.T_SID_IDS
)
AS
BEGIN
    FORALL i IN in_section_alert_ids.FIRST..in_section_alert_ids.LAST
        UPDATE section_alert
           SET sent_dtm = SYSDATE
         WHERE section_alert_id = in_section_alert_ids(i);
    COMMIT;
END;

PROCEDURE GetReminderAlertData(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	csr.alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_SECTION_REMINDER);

	OPEN out_cur FOR
		SELECT rs.app_sid, rs.route_step_id, rs.work_days_offset, rs.step_due_dtm due_dtm,  -- step_due_dtm [need to upadte SectionStateChangeJob.cs]
			    rsu.csr_user_sid, cu.full_name to_full_name, cu.friendly_name to_friendly_name,
			    vs.title section_title, vs.section_sid,
			    fs.label state_label
           FROM route_step_user rsu
           JOIN route_step rs ON rs.route_step_id = rsu.route_step_id
           JOIN csr_user cu ON rsu.csr_user_sid = cu.csr_user_sid AND rsu.app_sid = cu.app_sid
           JOIN temp_alert_batch_run tabr ON tabr.app_sid = rsu.app_sid AND tabr.csr_user_sid = rsu.csr_user_sid
           JOIN route r ON r.route_id = rs.route_id
           JOIN v$visible_version vs ON vs.section_sid = r.section_sid AND vs.current_route_step_id = rs.route_step_id -- important to join on current_route_step
		   JOIN section s ON r.section_sid = s.section_sid
		   JOIN section_module sm ON s.module_root_sid = sm.module_root_sid
           JOIN flow_state fs ON fs.flow_state_id = r.flow_state_id
		   LEFT JOIN route_step_vote rsv
			  	ON rsu.route_step_id = rsv.route_step_id AND rsu.app_sid = rsv.app_sid
			  	AND rsu.csr_user_sid = rsv.user_sid AND rsu.app_sid = rsv.app_sid
          WHERE tabr.std_alert_type_id = csr_data_pkg.ALERT_SECTION_REMINDER
			AND reminder_sent_dtm IS NULL	-- reminder not sent yet
			AND vote_direction IS NULL
			AND rs.step_due_dtm = TO_DATE(SYSDATE + sm.reminder_offset)	-- and it's the day to do so (we ignore stuff if it wasn't sent in past, even if it should)
			AND sm.active = 1
          ORDER BY rsu.app_sid, rsu.csr_user_sid, step_due_dtm DESC;
END;

PROCEDURE RecordReminderSent(
	in_csr_user_sid					security_pkg.T_SID_ID,
	in_route_step_id				security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE route_step_user
	   SET reminder_sent_dtm = SYSDATE
	 WHERE route_step_id = in_route_step_id AND csr_user_sid = in_csr_user_sid;
END;

PROCEDURE GetOverdueAlertData(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	csr.alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_SECTION_OVERDUE);

	OPEN out_cur FOR
		SELECT rs.app_sid, rs.route_step_id, rs.work_days_offset, rs.step_due_dtm due_dtm, -- step_due_dtm [need to upadte SectionStateChangeJob.cs]
			    rsu.csr_user_sid, cu.full_name to_full_name, cu.friendly_name to_friendly_name,
			    vs.title section_title, vs.section_sid,
			    fs.label state_label
           FROM route_step_user rsu
           JOIN route_step rs ON rs.route_step_id = rsu.route_step_id
           JOIN csr_user cu ON rsu.csr_user_sid = cu.csr_user_sid AND rsu.app_sid = cu.app_sid
           JOIN temp_alert_batch_run tabr ON tabr.app_sid = rsu.app_sid AND tabr.csr_user_sid = rsu.csr_user_sid
           JOIN route r ON r.route_id = rs.route_id
           JOIN v$visible_version vs ON vs.section_sid = r.section_sid AND vs.current_route_step_id = rs.route_step_id -- important to join on current_route_step
		   JOIN section s ON r.section_sid = s.section_sid
		   JOIN section_module sm ON s.module_root_sid = sm.module_root_sid
           JOIN flow_state fs ON fs.flow_state_id = r.flow_state_id
		   LEFT JOIN route_step_vote rsv
			  	ON rsu.route_step_id = rsv.route_step_id AND rsu.app_sid = rsv.app_sid
			  	AND rsu.csr_user_sid = rsv.user_sid AND rsu.app_sid = rsv.app_sid
          WHERE tabr.std_alert_type_id = csr_data_pkg.ALERT_SECTION_OVERDUE
			AND overdue_sent_dtm IS NULL	-- reminder not sent yet
			AND vote_direction IS NULL
			AND rs.step_due_dtm < TO_DATE(SYSDATE)	-- and it's the day to do so (we ignore stuff if it wasn't sent in past, even if it should)
			AND sm.active = 1
          ORDER BY rsu.app_sid, rsu.csr_user_sid, rs.step_due_dtm DESC;
END;

PROCEDURE RecordOverdueSent(
	in_csr_user_sid					security_pkg.T_SID_ID,
	in_route_step_id				security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE route_step_user
	   SET overdue_sent_dtm = SYSDATE
	 WHERE route_step_id = in_route_step_id AND csr_user_sid = in_csr_user_sid;
END;

PROCEDURE GetDeclinedAlertData(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	csr.alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_SECTION_DECLINED);

	OPEN out_cur FOR
		SELECT rsu.app_sid,  rsu.csr_user_sid,
			   rsu.csr_user_sid, cu.full_name to_full_name, cu.friendly_name to_friendly_name, cu.email to_email,
			   rsv.user_sid, cu2.full_name by_full_name, cu2.friendly_name by_friendly_name, cu2.email by_email,
			   rsv.route_step_id, sm.label module_title,
			   vs.title section_title, vs.section_sid,
			   fs.label state_label, rs.step_due_dtm due_dtm
		  FROM route_step_user rsu
		  JOIN route_step_vote rsv ON rsu.route_step_id=rsv.route_step_id
          JOIN csr_user cu ON rsu.csr_user_sid = cu.csr_user_sid AND rsu.app_sid = cu.app_sid
		  JOIN csr_user cu2 ON rsv.user_sid = cu2.csr_user_sid AND rsu.app_sid = cu2.app_sid
		  JOIN route_step rs ON rs.route_step_id = rsv.route_step_id
		  JOIN route r ON r.route_id = rs.route_id
		  JOIN section s ON s.section_sid = r.section_sid
		  JOIN section_module sm ON sm.module_root_sid = s.module_root_sid
		  JOIN v$visible_version vs ON vs.section_sid = r.section_sid AND vs.current_route_step_id = rs.route_step_id -- important to join on current_route_step
		  JOIN flow_state fs ON fs.flow_state_id = r.flow_state_id
		  JOIN temp_alert_batch_run tabr ON tabr.app_sid = rsu.app_sid AND tabr.csr_user_sid = rsu.csr_user_sid
		 WHERE rsv.vote_direction = -1 AND rsv.is_return = 0
		   AND (rsv.vote_dtm > rsu.declined_sent_dtm OR rsu.declined_sent_dtm IS NULL)
		   AND rsu.route_step_id = rsv.route_step_id AND rsu.app_sid = rsv.app_sid
		   AND rsu.app_sid = rsv.app_sid
		   AND rsu.csr_user_sid != rsv.user_sid
		   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_SECTION_DECLINED
		 ORDER BY rsu.app_sid, rsu.csr_user_sid DESC;
END;

PROCEDURE RecordDeclinedSent(
	in_csr_user_sid					security_pkg.T_SID_ID,
	in_route_step_id				security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE route_step_user
	   SET declined_sent_dtm = SYSDATE
	 WHERE route_step_id = in_route_step_id AND csr_user_sid = in_csr_user_sid;
END;

PROCEDURE PromoteAttach(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_attachment_id		   	IN	attachment.ATTACHMENT_ID%TYPE
)
AS
	v_doc_id	doc_version.DOC_ID%TYPE;
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit section docs') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have capability to delete section comments');
	END IF;

	SELECT doc_id
	  INTO v_doc_id
	  FROM attachment
	 WHERE attachment_id = in_attachment_id;

	INSERT INTO section_content_doc (section_sid, doc_id)
	VALUES (in_section_sid, v_doc_id);

	RemoveAttachment(in_act_id, in_section_sid, in_attachment_id);
END;

FUNCTION GetFormPathFromName(
	in_form_name			VARCHAR2
) RETURN VARCHAR2
AS
	v_form_path		VARCHAR2(255);
BEGIN
	SELECT form_path
	  INTO v_form_path
	  FROM plugin_lookup
	 WHERE plugin_name = in_form_name;

	RETURN v_form_path;
END;

PROCEDURE GetFormPlugins(
	in_section_sids		IN	security_pkg.T_SID_IDS,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_section_ids		security.T_SID_TABLE;
BEGIN
	t_section_ids	:= security_pkg.SidArrayToTable(in_section_sids);
	OPEN out_cur FOR
		SELECT spl.section_sid, form_path, pl.plugin_name, label plugin_label
		  FROM section_plugin_lookup spl
		  JOIN plugin_lookup pl ON spl.plugin_name = pl.plugin_name
		  JOIN section s ON s.section_sid =  spl.section_sid
		 WHERE spl.section_sid IN (SELECT column_value FROM TABLE(t_section_ids))
		   AND (NOT EXISTS (SELECT * FROM plugin_lookup_flow_state plfs WHERE plfs.plugin_name = spl.plugin_name)
				OR
				EXISTS (SELECT * FROM flow_item fi JOIN plugin_lookup_flow_state plfs ON fi.flow_sid=plfs.flow_sid AND fi.current_state_id=plfs.flow_state_id WHERE plfs.plugin_name= spl.plugin_name AND fi.flow_Item_id = s.flow_Item_id));
END;

PROCEDURE MoveToDocLib(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_doc_folder_sid			IN	security_pkg.T_SID_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE,
	in_desc						IN	VARCHAR2
)
AS
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Check write access on doc folder
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_doc_folder_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_doc_folder_sid);
	END IF;

	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit section docs') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have capability to delete section comments');
	END IF;

	doc_pkg.MoveDoc(in_doc_id, in_doc_folder_sid, 'Added from section with sid ' || in_section_sid);

	UPDATE doc_version
	   SET description = in_desc
	 WHERE doc_id = in_doc_id
	   AND version = (SELECT version FROM doc_current WHERE doc_id = in_doc_id);
END;

PROCEDURE CheckoutDoc(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE
)
AS
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	UPDATE section_content_doc
	   SET CHECKED_OUT_TO_SID = sys_context('security','sid'),
			  CHECKED_OUT_DTM = sysdate,
   CHECKED_OUT_VERSION_NUMBER = (SELECT version
								   FROM doc_current
								  WHERE doc_id = in_doc_id)
	 WHERE section_sid = in_section_sid
	   AND doc_id = in_doc_id;

	doc_pkg.StartEditing(in_doc_id);
END;

PROCEDURE RevertDocCheckout(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE
)
AS
BEGIN
	UPDATE section_content_doc
	   SET CHECKED_OUT_TO_SID = null,
			  CHECKED_OUT_DTM = null,
   CHECKED_OUT_VERSION_NUMBER = null
	 WHERE doc_id = in_doc_id;

	UPDATE doc_current
	   SET locked_by_sid = NULL
	 WHERE doc_id = in_doc_id;
END;

PROCEDURE GetEmailInfo(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT scdw.csr_user_sid user_sid, cu.email, cu.full_name, cu.friendly_name, nvl(cu2.full_name, cu3.full_name) name, scdw.section_sid, dc.filename,
			'"'||GetModuleName(s.section_sid)||' / '||GetPathFromSectionSID(in_act_id, scdw.section_sid, ' / ', 1) || ' / ' || sv.title || '"' question_label
		   FROM section_content_doc_wait scdw
		  JOIN section_content_doc scd ON scd.section_sid = scdw.section_sid AND scd.doc_id = scdw.doc_id
		  JOIN v$doc_current dc ON scdw.doc_id = dc.doc_id
		  JOIN section s ON scdw.section_sid = s.section_sid
		  JOIN section_version sv ON s.section_sid = sv.section_sid AND sv.version_number = s.VISIBLE_VERSION_NUMBER
		  JOIN csr_user cu ON scdw.csr_user_sid = cu.csr_user_sid
		  LEFT JOIN csr_user cu2 ON scd.checked_out_to_sid = cu2.csr_user_sid
		  LEFT JOIN csr_user cu3 ON dc.locked_by_sid = cu3.csr_user_sid
		 WHERE scdw.doc_id = in_doc_id;
END;

PROCEDURE RemoveContentDoc(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE
)
AS
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit section docs') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have capability to delete section comments');
	END IF;
	DELETE FROM section_content_doc
	 WHERE section_sid = in_section_sid
	   AND doc_id = in_doc_id;
END;

PROCEDURE GetCustomerForms(
	in_act_Id			IN	security_pkg.T_ACT_ID,
	in_app_sid  		IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT plugin_name, label
		  FROM plugin_lookup
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE AddFormToSection(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_section_sid			IN security_pkg.T_SID_ID,
	in_form_name			IN VARCHAR2,
	out_attachment_id		OUT	attachment.ATTACHMENT_ID%TYPE
)
AS
	v_version			attachment_history.VERSION_NUMBER%TYPE;
BEGIN
	-- Check write access on section
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	-- Generate a new attachment id
	SELECT attachment_id_seq.NEXTVAL
	  INTO out_attachment_id
	  FROM dual;

	-- Insert the data into the attachment table
	INSERT INTO attachment
		(ATTACHMENT_ID, FILENAME, MIME_TYPE)
      VALUES (out_attachment_id, in_form_name, 'application/form');

	-- Link the attachment data to the correct section
    v_version := GetLatestVersion(in_section_sid);

    INSERT INTO attachment_history
    		(SECTION_SID, VERSION_NUMBER, ATTACHMENT_ID)
    	VALUES (in_section_sid, v_version, out_attachment_id);

	INSERT INTO section_plugin_lookup (plugin_name, section_sid)
	VALUES (in_form_name, in_section_sid);
END;

PROCEDURE AddDocWait(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE,
	in_csr_user_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	INSERT INTO section_content_doc_wait (section_sid, doc_id, csr_user_sid)
	VALUES (in_section_sid, in_doc_id, in_csr_user_sid);
END;

PROCEDURE RemoveDocWait(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_section_sid				IN	security_pkg.T_SID_ID,
	in_doc_id		   			IN	doc_version.DOC_ID%TYPE,
	in_csr_user_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM section_content_doc_wait
	 WHERE section_sid = in_section_sid
	   AND doc_id =  in_doc_id
	   AND csr_user_sid = in_csr_user_sid;
END;

PROCEDURE GetRouteExportData(
	in_section_sids					IN	security_pkg.T_SID_IDS,
	out_module_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_section_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_flow_state_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_route_step_user_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id			security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT');
	t_section_sids		security.T_SID_TABLE;
BEGIN
	t_section_sids	:= security_pkg.SidArrayToTable(in_section_sids);

	OPEN out_module_cur FOR
		SELECT sm.module_root_sid,
				sm.label,
				sm.flow_sid
		  FROM section_module sm
		  JOIN section s ON s.module_root_sid = sm.module_root_sid
		  JOIN section_version sv
					 ON sv.section_sid = s.section_sid
					AND sv.version_number = s.visible_version_number
		 WHERE s.section_sid IN (SELECT column_value FROM TABLE(t_section_sids))
		   AND sm.flow_sid IS NOT NULL
		   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, sm.module_root_sid, security_pkg.PERMISSION_READ) = 1
		 GROUP BY sm.module_root_sid, sm.label, sm.flow_sid;

	OPEN out_flow_state_cur FOR
		SELECT flow_sid,
				flow_state_id,
				label,
				state_colour,
				lookup_key,
				pos seq
		  FROM flow_state
		 WHERE flow_sid IN (
					SELECT DISTINCT sm.flow_sid
					  FROM section s
					  JOIN section_module sm
							 ON s.module_root_sid = sm.module_root_sid
							AND sm.flow_sid IS NOT NULL
					 WHERE section_sid IN (SELECT column_value FROM TABLE(t_section_sids))
					   AND SECURITY.security_pkg.SQL_IsAccessAllowedSID(v_act_id, sm.flow_sid, security_pkg.PERMISSION_READ) = 1
			   )
		   AND is_deleted = 0
		 ORDER BY pos ASC;

	GetSections(in_section_sids, out_section_cur);
	GetRoutes(in_section_sids, out_route_cur, out_route_step_cur, out_route_step_user_cur);
END;

PROCEDURE GetSingleAlertData (
	in_section_sid  		IN	security_pkg.T_SID_ID,
	in_route_step_id 		IN	security_pkg.T_SID_ID,
	in_flow_state_id  		IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.due_dtm, s.app_sid, s.title, fs.label state_label,
			tcu.full_name to_full_name, tcu.email to_email, tcu.friendly_name to_friendly_name, tcu.csr_user_sid to_user_sid
		  FROM v$visible_version s
		  JOIN route r ON r.section_sid = s.section_sid AND r.app_sid = s.app_sid
		  JOIN section_routed_flow_state srfs ON srfs.FLOW_SID = r.flow_sid AND srfs.flow_state_id = r.flow_state_id AND r.app_sid = srfs.app_sid
		  JOIN flow_state fs ON srfs.flow_state_id = fs.flow_state_id AND fs.app_sid = srfs.app_sid
		  JOIN route_step rs ON r.route_id = rs.route_id AND r.app_sid = rs.app_sid
		  JOIN route_step_user rsu ON rs.route_step_id = rsu.route_step_id AND rsu.app_sid = rs.app_sid
		  JOIN csr_user tcu ON rsu.csr_user_sid = tcu.csr_user_sid AND rsu.app_sid = tcu.app_sid
		 WHERE s.section_sid = in_section_sid
		   AND (in_flow_state_id IS NULL OR r.flow_state_id = in_flow_state_id)
		   AND (in_route_step_id IS NULL OR rs.route_step_id = in_route_step_id);
END;

PROCEDURE SetPreviousSectionByRef(
	in_section_sid		IN	section.section_sid%TYPE,
	in_previous_ref		IN	section.ref%TYPE
)
AS
	v_previous_module_sid	section_module.module_root_sid%TYPE;
	v_previous_module_label	section_module.label%TYPE;
	v_previous_section_sid	section.previous_section_sid%TYPE;
	CURSOR getPrevious_cur IS
		SELECT ps.section_sid, sm.previous_module_sid, pm.label
		  FROM section s
		  JOIN section_module sm ON s.module_root_sid = sm.module_root_sid
		  JOIN section_module pm ON pm.module_root_sid = sm.previous_module_sid
		  LEFT JOIN section ps
					 ON ps.module_root_sid = sm.previous_module_sid
					AND LOWER(ps.ref) = LOWER(in_previous_ref)
		 WHERE s.section_sid = in_section_sid;
BEGIN
	OPEN getPrevious_cur;
	FETCH getPrevious_cur
	 INTO v_previous_section_sid, v_previous_module_sid, v_previous_module_label;

	-- Cursor will only return if the module has a previous module sid. If notm the previous module is not installed -> skip
	IF getPrevious_cur%FOUND THEN

		-- If previous module linked and ref is not found it should fail
		IF v_previous_section_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'Previous section with ref '||in_previous_ref||' was not found in module '|| v_previous_module_label || ' (' ||TO_CHAR(v_previous_module_sid) || ')');
		ELSE
			UPDATE section
			   SET previous_section_sid = v_previous_section_sid
			 WHERE section_sid = in_section_sid;
		END IF;
	END IF;
END;

PROCEDURE GetSectionRoutedFlowState(
	in_flow_state_id				IN section_routed_flow_state.flow_state_id%TYPE,
	out_section_flow_cur			OUT SYS_REFCURSOR,
	out_routed_state_cur			OUT SYS_REFCURSOR
)
AS
	v_app_sid						security_pkg.T_SID_ID;
	v_flow_sid						security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	BEGIN
		SELECT flow_sid
		  INTO v_flow_sid
		  FROM flow_state
		 WHERE app_sid = v_app_sid
		   AND flow_state_id = in_flow_state_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_flow_sid := NULL;
	END;

	OPEN out_section_flow_cur FOR
		SELECT flow_sid
		  FROM csr.section_flow
		 WHERE app_sid = v_app_sid
		   AND flow_sid = v_flow_sid
		   AND split_question_flow_state_id = in_flow_state_id;

	OPEN out_routed_state_cur FOR
		SELECT srfs.flow_state_id, srfs.reject_fs_transition_id,
	           fst.from_state_id AS transition_from_state_id,
			   fst.to_state_id AS transition_to_state_id
		  FROM section_routed_flow_state srfs
		  LEFT JOIN flow_state_transition fst
			ON srfs.app_sid = fst.app_sid
		   AND srfs.reject_fs_transition_id = fst.flow_state_transition_id
		 WHERE srfs.app_sid = v_app_sid
		   AND srfs.flow_state_id = in_flow_state_id;
END;

PROCEDURE SetSectionRoutedFlowState(
	in_flow_state_id				IN section_routed_flow_state.flow_state_id%TYPE,
	in_is_section_routed 			IN NUMBER,
	in_is_split_ques_flow_state		IN section_flow.split_question_flow_state_id%TYPE,
	in_reject_from_state_id			IN flow_state_transition.from_state_id%TYPE,
	in_reject_to_state_id			IN flow_state_transition.to_state_id%TYPE
)
AS
	v_app_sid						security_pkg.T_SID_ID;
	v_flow_sid						security_pkg.T_SID_ID;
	v_reject_fs_transition_id		section_routed_flow_state.reject_fs_transition_id%TYPE;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	SELECT flow_sid
	  INTO v_flow_sid
	  FROM flow_state
	 WHERE app_sid = v_app_sid
	   AND flow_state_id = in_flow_state_id;

	IF in_is_section_routed = 1 THEN
		BEGIN
			SELECT flow_state_transition_id
			  INTO v_reject_fs_transition_id
			  FROM flow_state_transition
			 WHERE app_sid = v_app_sid
			   AND from_state_id = in_reject_from_state_id
			   AND to_state_id = in_reject_to_state_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_reject_fs_transition_id := NULL;
		END;

		BEGIN
			INSERT INTO section_routed_flow_state (flow_sid, flow_state_id, reject_fs_transition_id)
			VALUES (v_flow_sid, in_flow_state_id, v_reject_fs_transition_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE section_routed_flow_state
				   SET reject_fs_transition_id = v_reject_fs_transition_id
				 WHERE app_sid = v_app_sid
				   AND flow_sid = v_flow_sid
				   AND flow_state_id = in_flow_state_id;
		END;
	ELSE
		DELETE FROM section_routed_flow_state
		 WHERE app_sid = v_app_sid
		   AND flow_sid = v_flow_sid
		   AND flow_state_id = in_flow_state_id;
	END IF;

	SetSplitQuestionFlowState (v_flow_sid, in_flow_state_id, in_is_split_ques_flow_state);
END;

PROCEDURE SetSplitQuestionFlowState(
	in_flow_sid						IN flow.flow_sid%TYPE,
	in_split_ques_flow_state_id		IN section_flow.split_question_flow_state_id%TYPE,
	in_is_split_ques_flow_state		IN NUMBER DEFAULT 0
)
AS
	v_exists						NUMBER;
	v_app_sid						security_pkg.T_SID_ID;
	v_split_ques_flow_state_id		section_flow.split_question_flow_state_id%TYPE;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY','APP');

	SELECT COUNT(*)
	  INTO v_exists
	  FROM section_flow
	 WHERE app_sid = v_app_sid
	   AND flow_sid = in_flow_sid;

	IF v_exists = 0 THEN
		INSERT INTO section_flow (flow_sid, split_question_flow_state_id)
		VALUES (in_flow_sid, in_split_ques_flow_state_id);
	ELSE
		SELECT split_question_flow_state_id
		  INTO v_split_ques_flow_state_id
		  FROM section_flow
		 WHERE app_sid = v_app_sid
		   AND flow_sid = in_flow_sid;

		IF in_is_split_ques_flow_state = 1 THEN
			UPDATE section_flow
			   SET split_question_flow_state_id = in_split_ques_flow_state_id
			 WHERE app_sid = v_app_sid
			   AND flow_sid = in_flow_sid;
		ELSE
			UPDATE section_flow
			   SET split_question_flow_state_id = NULL
			 WHERE app_sid = v_app_sid
			   AND flow_sid = in_flow_sid
			   AND in_split_ques_flow_state_id = v_split_ques_flow_state_id;
		END IF;
   END IF;
END;

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE
AS
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids_t
	  FROM section s
	  JOIN section_module sm ON s.module_root_sid = sm.module_root_sid
	 WHERE s.app_sid = security_pkg.getApp
	   AND s.flow_item_id = in_flow_item_id;

	RETURN v_region_sids_t;
END;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN
	SELECT DECODE(count(*), 0, 0, 1)
	  INTO v_count
	  FROM section s
	  JOIN section_module sm ON s.module_root_sid = sm.module_root_sid
	 WHERE s.app_sid = security_pkg.getApp
	   AND s.flow_item_id = in_flow_item_id;

	RETURN v_count;
END;

PROCEDURE GetFlowAlerts(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT figa.app_sid, figa.from_state_Label, figa.to_state_label, figa.set_dtm, figa.customer_alert_type_id,
		 figa.flow_state_log_id, figa.flow_state_transition_id, figa.flow_item_generated_alert_id,
		 figa.set_by_user_sid, figa.set_by_user_name, figa.set_by_full_name, figa.set_by_email,
		 figa.to_user_sid, figa.to_user_name, figa.to_full_name, figa.to_email, figa.to_friendly_name, figa.to_initiator,
		 s.section_sid, sv.TITLE, figa.comment_text, figa.flow_item_id, figa.flow_alert_helper,
		 'csr/site/text/overview/filter.acds?sectionSid=' || s.section_sid as section_link
		 FROM v$open_flow_item_gen_alert figa
		 JOIN section s ON figa.flow_item_id = s.flow_item_id AND figa.app_sid = s.app_sid
		 JOIN section_module sm ON s.module_root_sid = sm.module_root_sid AND sm.app_sid = s.app_sid
		 JOIN section_version sv on sv.SECTION_SID = s.SECTION_SID and sv.version_number = s.VISIBLE_VERSION_NUMBER AND sv.app_sid = s.app_sid
		ORDER BY figa.app_sid, figa.customer_alert_type_id, figa.to_user_sid, figa.flow_item_id; -- order matters!
END;

PROCEDURE GetContentVal(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	in_idx							IN	section_val.idx%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid							security_pkg.T_SID_ID;
BEGIN
	-- Check access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	v_app_sid := security.security_pkg.GetApp;

	OPEN out_cur FOR
		SELECT sf.section_sid, sf.fact_id, sf.map_to_ind_sid, sf.data_type,
			   sf.map_to_region_sid, sv.start_dtm, sv.end_dtm, sv.idx, sv.val_number,
			   sv.note, sf.std_measure_conversion_id
		  FROM section_fact sf
		  JOIN section_val sv ON sf.app_sid = sv.app_sid AND sf.section_sid = sv.section_sid AND sf.fact_id = sv.fact_id
		 WHERE sv.app_sid = v_app_sid
		   AND sv.section_sid = in_section_sid
		   AND sv.fact_id = in_fact_id
		   AND sv.idx = in_idx;
END;

PROCEDURE SaveContentVal(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	in_idx							IN	section_val.idx%TYPE,
	in_start_dtm					IN	section_val.start_dtm%TYPE,
	in_end_dtm						IN	section_val.end_dtm%TYPE,
	in_val_number					IN	section_val.val_number%TYPE,
	in_note							IN	section_val.note%TYPE,
	in_entry_type					IN	section_val.entry_type%TYPE,
	in_period_set_id				IN	section_val.period_set_id%TYPE,
	in_period_interval_id			IN	section_val.period_interval_id%TYPE
)
AS
	v_app_sid							security_pkg.T_SID_ID;
BEGIN
	-- Check the user has write access to the section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	v_app_sid := security.security_pkg.GetApp;

	BEGIN
		INSERT INTO section_val (
			section_val_id, section_sid, fact_id, idx, start_dtm, end_dtm, val_number, note, entry_type, period_set_id,
			period_interval_id
		) VALUES (
			section_val_id_seq.NEXTVAL, in_section_sid, in_fact_id, in_idx, in_start_dtm, in_end_dtm, 
			in_val_number, in_note, in_entry_type, in_period_set_id, in_period_interval_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE section_val
			   SET start_dtm = in_start_dtm,
		           end_dtm = in_end_dtm,
				   val_number = in_val_number,
				   note = in_note,
				   entry_type = in_entry_type,
				   period_set_id = in_period_set_id,
				   period_interval_id = in_period_interval_id
			 WHERE app_sid = v_app_sid
			   AND section_sid = in_section_sid
			   AND fact_id = in_fact_id
			   AND idx = in_idx;
	END;
END;

PROCEDURE SaveContentValueNoDates(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	in_idx							IN	section_val.idx%TYPE,
	in_val_number					IN	section_val.val_number%TYPE,
	in_note							IN	section_val.note%TYPE,
	in_entry_type					IN	section_val.entry_type%TYPE
)
AS
	v_app_sid							security_pkg.T_SID_ID;
BEGIN
	-- Check the user has write access to the section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	v_app_sid := security.security_pkg.GetApp;

	BEGIN
		INSERT INTO section_val (
			section_val_id, section_sid, fact_id, idx, val_number, note, entry_type, period_set_id,
			period_interval_id
		) VALUES (
			section_val_id_seq.NEXTVAL, in_section_sid, in_fact_id, in_idx, in_val_number, in_note, in_entry_type,
			1, 1
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE section_val
			   SET val_number = in_val_number,
				   note = in_note,
				   entry_type = in_entry_type
			 WHERE app_sid = v_app_sid
			   AND section_sid = in_section_sid
			   AND fact_id = in_fact_id
			   AND idx = in_idx;
	END;
END;

PROCEDURE GetSectionFact(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid							security_pkg.T_SID_ID;
BEGIN
	-- Check access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	v_app_sid := security.security_pkg.GetApp;

	OPEN out_cur FOR
		SELECT sf.section_sid, vv.module_root_sid module_sid, sf.fact_id, sf.is_active, sf.map_to_ind_sid, nvl(sf.map_to_region_sid, sm.region_sid) map_to_region_sid,
			nvl(sf.std_measure_conversion_id, smcd.std_measure_conversion_id) std_measure_conversion_id, sf.data_type, sf.max_length, vv.title section_title, i.description ind_description,
			nvl(r1.description, r2.description) region_description, nvl(smc.description, smcd.description) std_measure_conversion_desc, s.previous_section_sid
		  FROM section_fact sf
		  JOIN v$visible_version vv ON sf.section_sid = vv.section_sid
		  JOIN section_module sm ON vv.module_root_sid = sm.module_root_sid
		  LEFT JOIN v$ind i ON sf.map_to_ind_sid = i.ind_sid
		  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
		  LEFT JOIN std_measure_conversion smcd ON smcd.std_measure_conversion_id = m.std_measure_conversion_id
		  LEFT JOIN v$region r1 ON sf.map_to_region_sid = r1.region_sid
		  LEFT JOIN v$region r2 ON sm.region_sid = r2.region_sid
		  LEFT JOIN std_measure_conversion smc ON smc.std_measure_conversion_id = sf.std_measure_conversion_id
		  LEFT JOIN section s ON s.section_sid = sf.section_sid
		 WHERE sf.section_sid = in_section_sid
		   AND sf.fact_id = in_fact_id
		   AND sf.app_sid = v_app_sid;
END;

PROCEDURE GetSectionFacts(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid							security_pkg.T_SID_ID;
BEGIN
	-- Check access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	v_app_sid := security.security_pkg.GetApp;

	OPEN out_cur FOR
		SELECT sf.section_sid, sf.fact_id, sf.map_to_ind_sid, sf.map_to_region_sid,
			   sf.std_measure_conversion_id, sf.data_type, sf.max_length, sf.is_active
		  FROM section_fact sf
		 WHERE app_sid = v_app_sid
		   AND sf.section_sid = in_section_sid;
END;

PROCEDURE DisableSectionFacts(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID
)
AS
	v_app_sid							security_pkg.T_SID_ID;
BEGIN
	-- Check the user has write access to the section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	v_app_sid := security.security_pkg.GetApp;

	UPDATE section_fact
	   SET is_active = 0
	 WHERE app_sid = v_app_sid
	   AND section_sid = in_section_sid;
END;

FUNCTION SaveSectionFact(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	in_data_type					IN	section_fact.data_type%TYPE,
	in_max_length					IN	section_fact.max_length%TYPE,
	in_map_to_ind_sid				IN	section_fact.map_to_ind_sid%TYPE DEFAULT NULL,
	in_map_to_region_sid			IN	section_fact.map_to_region_sid%TYPE DEFAULT NULL,
	in_measure_conversion			IN	section_fact.std_measure_conversion_id%TYPE DEFAULT NULL
)	RETURN section_fact.fact_id%TYPE
AS
	v_app_sid							security_pkg.T_SID_ID;
	v_fact_id							section_fact.fact_id%TYPE;
BEGIN
	-- Check the user has write access to the section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	IF NOT HasCapabilityAccess(in_section_sid, csr.csr_data_pkg.FLOW_CAP_CORP_REP_EDIT_FACT,
		security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User doesn''t have flow capability Edit indicator fact over section '
			||in_section_sid|| ' at its current state.' );
	END IF;

	v_app_sid := security.security_pkg.GetApp;
	v_fact_id := COALESCE(in_fact_id, GetNextFactId);

	BEGIN
		INSERT INTO section_fact (
			section_sid, fact_id, data_type, max_length, map_to_ind_sid, map_to_region_sid, std_measure_conversion_id
		) VALUES (
			in_section_sid, v_fact_id, in_data_type, in_max_length, in_map_to_ind_sid, in_map_to_region_sid, in_measure_conversion
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE section_fact
			   SET is_active = 1,
				   data_type = in_data_type,
				   max_length = in_max_length,
				   map_to_ind_sid = in_map_to_ind_sid,
				   map_to_region_sid = in_map_to_region_sid,
				   std_measure_conversion_id = in_measure_conversion
			 WHERE app_sid = v_app_sid
			   AND section_sid = in_section_sid
			   AND fact_id = v_fact_id;
	END;

	RETURN v_fact_id;
END;

PROCEDURE SaveSectionFact(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE,
	in_data_type					IN	section_fact.data_type%TYPE,
	in_max_length					IN	section_fact.max_length%TYPE,
	in_map_to_ind_sid				IN	section_fact.map_to_ind_sid%TYPE DEFAULT NULL,
	in_map_to_region_sid			IN	section_fact.map_to_region_sid%TYPE DEFAULT NULL,
	in_measure_conversion			IN	section_fact.std_measure_conversion_id%TYPE DEFAULT NULL
)
AS
	v_fact_id							section_fact.fact_id%TYPE;
BEGIN
	v_fact_id := SaveSectionFact(in_act_id, in_section_sid, in_fact_id, in_data_type,
		in_max_length, in_map_to_ind_sid, in_map_to_region_sid, in_measure_conversion);
END;

PROCEDURE DeleteFact(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE
)
AS
	v_app_sid							security_pkg.T_SID_ID;
BEGIN
	-- Check the user has write access to the section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	IF NOT HasCapabilityAccess(in_section_sid, csr.csr_data_pkg.FLOW_CAP_CORP_REP_CLEAR_FACT,
		security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User doesn''t have flow capability Clear indicator mapping over section '
			||in_section_sid|| ' at its current state.' );
	END IF;

	v_app_sid := security.security_pkg.GetApp;

	DELETE FROM section_fact_attach
	 WHERE app_sid = v_app_sid
	   AND section_sid = in_section_sid
	   AND fact_id = in_fact_id;

	DELETE FROM section_val
	 WHERE app_sid = v_app_sid
	   AND section_sid = in_section_sid
	   AND fact_id = in_fact_id;

	DELETE FROM section_fact
	 WHERE app_sid = v_app_sid
	   AND section_sid = in_section_sid
	   AND fact_id = in_fact_id;

END;

-- Like delete but sets fact config to null instead of deleting the fact.
PROCEDURE ClearFact(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	in_fact_id						IN	section_fact.fact_id%TYPE
)
AS
	v_app_sid							security_pkg.T_SID_ID;
BEGIN
	-- Check the user has write access to the section object
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on object with sid '||in_section_sid);
	END IF;

	IF NOT HasCapabilityAccess(in_section_sid, csr.csr_data_pkg.FLOW_CAP_CORP_REP_CLEAR_FACT,
		security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User doesn''t have flow capability Clear indicator mapping over section '
			||in_section_sid|| ' at its current state.' );
	END IF;

	v_app_sid := security.security_pkg.GetApp;

	DELETE FROM section_fact_attach
	 WHERE app_sid = v_app_sid
	   AND section_sid = in_section_sid
	   AND fact_id = in_fact_id;

	DELETE FROM section_val
	 WHERE app_sid = v_app_sid
	   AND section_sid = in_section_sid
	   AND fact_id = in_fact_id;

	UPDATE section_fact
	   SET map_to_ind_sid = NULL,  map_to_region_sid = NULL, std_measure_conversion_id = NULL, data_type = NULL, max_length = NULL, is_active = 1
	 WHERE app_sid = v_app_sid
	   AND section_sid = in_section_sid
	   AND fact_id = in_fact_id;
END;

PROCEDURE GetSectionFactValues(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	fact_values_out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	fact_attch_out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check access
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_section_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_section_sid);
	END IF;

	OPEN fact_values_out_cur FOR
		SELECT sv.section_sid, sv.idx, sf.fact_id, sv.start_dtm, sv.end_dtm, sv.val_number, sv.note, sv.entry_type,
			sv.period_set_id, sv.period_interval_id
		  FROM section_fact sf
		  JOIN section_val sv
		    ON sf.app_sid = sv.app_sid
		   AND sf.section_sid = sv.section_sid
		   AND sf.fact_id = sv.fact_id
		 WHERE sf.is_active = 1
		   AND sf.section_sid = in_section_sid
		 ORDER BY sv.fact_id, sv.idx;

	OPEN fact_attch_out_cur FOR
		SELECT sv.section_sid, sv.idx, sf.fact_id,
			   ah.attach_name name, ah.pg_num, ah.attach_comment "comment",
			   CASE
					WHEN a.doc_id IS NOT NULL THEN a.filename
					WHEN a.url IS NOT NULL THEN a.url
					WHEN a.indicator_sid IS NOT NULL THEN i.description
					WHEN a.dataview_sid IS NOT NULL THEN dw.name
					WHEN a.data IS NOT NULL THEN a.filename
					ELSE ''
				END src
		  FROM section_fact sf
		  JOIN section_val sv ON sf.app_sid = sv.app_sid AND sf.section_sid = sv.section_sid AND sf.fact_id = sv.fact_id
		  JOIN section_fact_attach sfa ON sfa.app_sid = sv.app_sid AND sfa.section_sid = sv.section_sid AND sfa.fact_id = sv.fact_id AND sfa.fact_idx = sv.idx
		  JOIN attachment a ON sfa.app_sid = a.app_sid AND sfa.attachment_id = a.attachment_id
		  JOIN attachment_history ah ON sv.section_sid = ah.section_sid AND a.attachment_id = ah.attachment_id
		  LEFT JOIN v$ind i ON i.app_sid = a.app_sid AND i.ind_sid = a.indicator_sid
		  LEFT JOIN dataview dw	ON dw.app_sid = a.app_sid AND a.dataview_sid = dw.dataview_sid
		 WHERE sf.is_active = 1
		   AND sf.section_sid = in_section_sid
		 ORDER BY sv.fact_id, sv.idx;
END;

PROCEDURE GetSectionContext(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_section_sid					IN	security_pkg.T_SID_ID,
	module_out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	facts_out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	fact_values_out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	fact_attch_out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	section_root_pkg.GetModuleBySectionSid(in_section_sid, module_out_cur);
	GetSectionFacts(in_act_id, in_section_sid, facts_out_cur);
	GetSectionFactValues(in_act_id, in_section_sid, fact_values_out_cur, fact_attch_out_cur);
END;

PROCEDURE UNSECURE_UpdateContent( --Used by array bind in copy module
	in_section_sid		IN	section.section_sid%TYPE,
	in_body				IN	section_version.body%TYPE
)
AS
BEGIN
	--This should be done immediately after module creation so there should only be one version, but just in case get the visible version number.
	UPDATE section_version
	   SET body = in_body
	 WHERE section_sid = in_section_sid
       AND version_number IN (SELECT visible_version_number FROM section WHERE section_sid = in_section_sid);
END;

PROCEDURE UpdateMetaData(
	in_attachment_id	IN	attachment.ATTACHMENT_ID%TYPE,
	in_name				IN	attachment_history.attach_name%TYPE,
	in_page				IN	attachment_history.pg_num%TYPE,
	in_comment			IN	attachment_history.attach_comment%TYPE
)
AS
BEGIN
	UPDATE attachment_history
	   SET attach_name = in_name,
		   pg_num = in_page,
		   attach_comment = in_comment
	 WHERE attachment_id = in_attachment_id;
END;

PROCEDURE GetModuleSectionFacts(
	in_module_root_sid	IN	section_module.module_root_sid%TYPE,
	in_section_sid		IN	section.section_sid%TYPE DEFAULT NULL,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sf.section_sid, vv.module_root_sid module_sid, sf.fact_id, sf.map_to_ind_sid, nvl(sf.map_to_region_sid, sm.region_sid) map_to_region_sid,
			nvl(sf.std_measure_conversion_id, smcd.std_measure_conversion_id) std_measure_conversion_id, sf.data_type, sf.max_length, vv.title section_title, i.description ind_description,
			nvl(r1.description, r2.description) region_description, nvl(smc.description, smcd.description) std_measure_conversion_desc
		  FROM section_fact sf
		  JOIN v$visible_version vv ON sf.section_sid = vv.section_sid
		  JOIN section_module sm ON vv.module_root_sid = sm.module_root_sid
		  LEFT JOIN v$ind i ON sf.map_to_ind_sid = i.ind_sid
		  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
		  LEFT JOIN std_measure_conversion smcd ON smcd.std_measure_conversion_id = m.std_measure_conversion_id
		  LEFT JOIN v$region r1 ON sf.map_to_region_sid = r1.region_sid
		  LEFT JOIN v$region r2 ON sm.region_sid = r2.region_sid
		  LEFT JOIN std_measure_conversion smc ON smc.std_measure_conversion_id = sf.std_measure_conversion_id
		 WHERE vv.module_root_sid = in_module_root_sid
		   AND sf.is_active = 1
		   AND (in_section_sid IS NULL OR sf.section_sid = in_section_sid)
		 ORDER BY vv.title, sf.fact_id;
END;

PROCEDURE GetModuleAttachmentList(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	out_attachments			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_docs_sid					security_pkg.T_SID_ID;
	v_section_ids				security_pkg.T_SID_IDS;
	t_section_ids				security.T_SID_TABLE;
BEGIN
	-- Check read access on module
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_module_root_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_module_root_sid);
	END IF;

	BEGIN
		v_docs_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getact, security.security_pkg.getapp, 'Documents');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			v_docs_sid := -1;
	END;

	SELECT section_sid
	  BULK COLLECT INTO v_section_ids
	  FROM section
	 WHERE module_root_sid = in_module_root_sid
	   AND (SELECT security_pkg.SQL_IsAccessAllowedSID(in_act_id, section_sid, security_pkg.PERMISSION_READ) FROM DUAL) = 1;

	t_section_ids := security_pkg.SidArrayToTable(v_section_ids);

	OPEN out_attachments FOR
		SELECT a.attachment_id, a.filename, a.mime_type, NVL(a.data, dc.data) data,
			   a.dataview_sid, a.doc_id,
			   a.last_updated_from_dataview, ah.version_number, dv.name dataview_name, a.view_as_table,
			   a.indicator_sid ind_sid, i.name ind_name, i.description ind_description, i.ind_type, a.embed, a.url,
			   ah.attach_name name, ah.pg_num page, ah.attach_comment "comment", sfa.fact_id, sfa.fact_idx,
			   DECODE(doc_folder_pkg.GetLibraryContainer(dc.parent_sid),v_docs_sid,1,0) in_doc_lib,
			   NVL(sv.start_dtm, sm.start_dtm) start_dtm, NVL(sv.end_dtm, sm.end_dtm) end_dtm
		  FROM section_module sm
		  JOIN section s ON sm.app_sid = s.app_sid AND sm.module_root_sid = s.module_root_sid
		  JOIN attachment_history ah ON s.app_sid = ah.app_sid AND s.section_sid = ah.section_sid
		  JOIN attachment a ON ah.app_sid = a.app_sid AND ah.attachment_id = a.attachment_id
		  LEFT JOIN dataview dv ON a.app_sid = dv.app_sid AND a.dataview_sid = dv.dataview_sid
		  LEFT JOIN v$ind i ON a.app_sid = i.app_sid AND a.indicator_sid = i.ind_sid
		  LEFT JOIN section_fact_attach sfa ON s.app_sid = sfa.app_sid AND s.section_sid = sfa.section_sid AND a.attachment_id = sfa.attachment_id
		  LEFT JOIN section_val sv ON sfa.app_sid = sv.app_sid AND sfa.section_sid = sv.section_sid AND sfa.fact_id = sv.fact_id AND sfa.fact_idx = sv.idx
		  LEFT JOIN v$doc_current dc ON a.doc_id = dc.doc_id
		 WHERE sm.module_root_sid = in_module_root_sid
		   AND s.section_sid IN (SELECT column_value FROM TABLE (t_section_ids))
		 ORDER BY a.attachment_id;
END;

PROCEDURE GetModuleVal(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_module_root_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_section_ids						security_pkg.T_SID_IDS;
	t_section_ids						security.T_SID_TABLE;
BEGIN
	-- Check read access on module
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_module_root_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_module_root_sid);
	END IF;

	SELECT section_sid
	  BULK COLLECT INTO v_section_ids
	  FROM section
	 WHERE module_root_sid = in_module_root_sid
	   AND (SELECT security_pkg.SQL_IsAccessAllowedSID(in_act_id, section_sid, security_pkg.PERMISSION_READ) FROM DUAL) = 1;

	t_section_ids := security_pkg.SidArrayToTable(v_section_ids);

	OPEN out_cur FOR
		  SELECT section_sid, fact_id, data_type, is_enum, fact_type,
				 start_dtm, end_dtm, val_number, note, max_length
			FROM (
			  SELECT sv.section_sid, sv.fact_id, sv.idx, sf.data_type, 0 AS is_enum, sfe.fact_type,
					 NVL(sv.start_dtm, sm.start_dtm) start_dtm, NVL(sv.end_dtm, sm.end_dtm) end_dtm,
					 sv.val_number, sv.note, sf.max_length, sv.period_set_id, sv.period_interval_id
				FROM section_module sm
				JOIN section s ON sm.app_sid = s.app_sid AND sm.module_root_sid = s.module_root_sid
				JOIN section_fact sf ON s.app_sid = sf.app_sid AND s.section_sid = sf.section_sid
				JOIN section_val sv ON sf.app_sid = sv.app_sid AND sf.section_sid = sv.section_sid AND sv.fact_id = sf.fact_id
				JOIN section_fact_enum sfe ON sv.app_sid = sfe.app_sid AND sv.section_sid = sfe.section_sid AND sv.fact_id = sfe.fact_id
			   WHERE sm.module_root_sid = in_module_root_sid
			     AND s.section_sid IN (SELECT column_value FROM TABLE (t_section_ids))
				 AND sfe.enumeration IS NULL
				 AND sf.is_active = 1
				 AND ((sf.data_type = 'NUMBER' and sv.val_number IS NOT NULL) OR ((sf.data_type IS NULL or sf.data_type = 'TEXT') and sv.note IS NOT NULL))
				 AND sf.data_type != 'FILE' -- exclude attachment type facts
			   UNION ALL
			  SELECT sv.section_sid, sv.fact_id, sv.idx, sf.data_type, 1 AS is_enum, sfe.fact_type,
					 NVL(sv.start_dtm, sm.start_dtm) start_dtm, NVL(sv.end_dtm, sm.end_dtm) end_dtm,
					 NULL AS val_number, to_clob(sfe.enumeration) AS note, sf.max_length, sv.period_set_id, sv.period_interval_id
				FROM section_module sm
				JOIN section s ON sm.app_sid = s.app_sid AND sm.module_root_sid = s.module_root_sid
				JOIN section_fact sf ON s.app_sid = sf.app_sid AND s.section_sid = sf.section_sid
				JOIN section_val sv ON sf.app_sid = sv.app_sid AND sf.section_sid = sv.section_sid AND sv.fact_id = sf.fact_id
				JOIN section_fact_enum sfe ON sv.app_sid = sfe.app_sid AND sv.section_sid = sfe.section_sid AND sv.fact_id = sfe.fact_id AND sv.idx = sfe.idx
			   WHERE sm.module_root_sid = in_module_root_sid
			     AND s.section_sid IN (SELECT column_value FROM TABLE (t_section_ids))
				 AND sfe.enumeration IS NOT NULL
				 AND sf.is_active = 1
				 AND ((sf.data_type = 'NUMBER' AND sv.val_number = 1) OR ((sf.data_type IS NULL OR sf.data_type = 'TEXT') AND DBMS_LOB.SUBSTR(sv.note, 1, 1) = '1'))
				 AND sf.data_type != 'FILE' -- exclude attachment type facts
		   )
		   ORDER BY section_sid, fact_id, idx;
END;

PROCEDURE GetModulePeriod(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_module_root_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check read access on module
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_module_root_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on object with sid '||in_module_root_sid);
	END IF;

	OPEN out_cur FOR
		SELECT start_dtm, end_dtm
		  FROM section_module
		 WHERE start_dtm IS NOT NULL
		   AND end_dtm IS NOT NULL
		   AND module_root_sid = in_module_root_sid
		 UNION
		SELECT DISTINCT sv.start_dtm, sv.end_dtm
		  FROM section s
		  JOIN section_fact sf ON s.app_sid = sf.app_sid AND s.section_sid = sf.section_sid
		  JOIN section_val sv ON sf.app_sid = sv.app_sid AND sf.fact_id = sv.fact_id
		 WHERE start_dtm IS NOT NULL
		   AND end_dtm IS NOT NULL
		   AND s.module_root_sid = in_module_root_sid;
END;

PROCEDURE GetModuleValFull(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_module_root_sid				IN	security_pkg.T_SID_ID,
	out_period_context_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_module_val_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_module_attachment_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetModulePeriod(in_act_id, in_module_root_sid, out_period_context_cur);
	GetModuleVal(in_act_id, in_module_root_sid, out_module_val_cur);
	GetModuleAttachmentList(in_act_id, in_module_root_sid, out_module_attachment_cur);
END;

END section_Pkg;
/
