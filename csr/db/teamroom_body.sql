CREATE OR REPLACE PACKAGE BODY CSR.teamroom_pkg IS

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
)
AS
BEGIN
	NULL;
END;

PROCEDURE MoveObject(
	in_act					IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE TrashObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM calendar_event
	 WHERE calendar_event_id IN (SELECT calendar_event_id FROM teamroom_event WHERE teamroom_sid = in_sid_id);

	UPDATE issue
	   SET deleted = 1
	 WHERE issue_id IN (
	 	SELECT issue_id FROM teamroom_issue WHERE teamroom_sid = in_sid_id
	 );

	DELETE FROM teamroom_issue
	 WHERE teamroom_sid = in_sid_id;

	DELETE FROM teamroom_member
	 WHERE teamroom_sid = in_sid_id;
	
	DELETE FROM teamroom_initiative
	 WHERE teamroom_sid = in_sid_id;
	
	DELETE FROM teamroom_user_msg
	 WHERE teamroom_sid = in_sid_id;
	
	DELETE FROM teamroom
	 WHERE teamroom_sid = in_sid_id;
END;

-- private
PROCEDURE AssertReadAccess(
	in_teamroom_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading teamroom sid '||in_teamroom_sid);
	END IF;
END;

-- private
PROCEDURE AssertWriteAccess(
	in_teamroom_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to teamroom sid '||in_teamroom_sid);
	END IF;
END;

PROCEDURE InsertTab(
	in_teamroom_type_id		IN  teamroom_type.teamroom_type_id%TYPE,
	in_js_class 		 	IN 	plugin.js_class%TYPE,
	in_tab_label			IN  teamroom_type_tab.tab_label%TYPE,
	in_pos 					IN  teamroom_type_tab.pos%TYPE
)
AS
	v_plugin_id			plugin.plugin_id%TYPE;
	v_plugin_type_id	plugin.plugin_type_id%TYPE;
BEGIN
	SELECT plugin_id, plugin_type_id
	  INTO v_plugin_id, v_plugin_type_id
	  FROM csr.plugin 
	 WHERE js_class = in_js_class 
	   AND plugin_type_id IN (csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB, csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_EDIT_PAGE, csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_MAIN_TAB);
	 
	BEGIN
		INSERT INTO csr.teamroom_type_tab (teamroom_type_id, plugin_id, plugin_type_id, pos, tab_label)
			VALUES (in_teamroom_type_id, v_plugin_id, v_plugin_type_id, in_pos, in_tab_label);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.teamroom_type_tab
			   SET pos = in_pos, tab_label = in_tab_label
			 WHERE plugin_id = v_plugin_id
			   AND teamroom_type_id = in_teamroom_type_id;
	END;
	
	-- assume registered users
	BEGIN
		INSERT INTO csr.teamroom_type_tab_group (teamroom_type_id, plugin_id, group_sid)
		     VALUES (in_teamroom_type_Id, v_plugin_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/RegisteredUsers'));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;	

-- we do this because we want to call this from the ASHX where ACT not available
PROCEDURE IsReadAccessAllowed(
	in_teamroom_sid			IN	security_pkg.T_SID_ID,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, security.security_pkg.PERMISSION_READ) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;

PROCEDURE CreateTeamroomType(
	in_label				IN  teamroom_type.label%TYPE,
	in_base_css_class		IN  teamroom_type.base_css_class%TYPE,
	out_teamroom_type_id	OUT teamroom_type.teamroom_type_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only a user with system management capability can create an teamroom type.');
	END IF;

	BEGIN	
		INSERT INTO teamroom_type (teamroom_type_id, label, base_css_class)
			VALUES (teamroom_type_id_seq.nextval, in_label, in_base_css_class)
			RETURNING teamroom_type_id INTO out_teamroom_type_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An teamroom type with this name already exists.');
	END;

	-- insert a bunch of tabs
	InsertTab(out_teamroom_type_id, 'Teamroom.SummaryPanel', 'Summary', 1);
	InsertTab(out_teamroom_type_id, 'Teamroom.DocumentsPanel', 'Documents', 2);
	InsertTab(out_teamroom_type_id, 'Teamroom.CalendarPanel', 'Calendar', 3);
	InsertTab(out_teamroom_type_id, 'Teamroom.IssuesPanel', 'Actions', 4);
	-- TODO: need to configure which tabs are available for which teamroom-type?
	InsertTab(out_teamroom_type_id, 'Teamroom.InitiativesPanel', 'Projects', 5);
	
	-- initiative page tabs
	/*
	InsertTab(out_teamroom_type_id, 'Teamroom.Initiatives.SummaryPanel', 'Summary', 1);
	InsertTab(out_teamroom_type_id, 'Teamroom.Initiatives.DocumentsPanel', 'Documents', 2);
	InsertTab(out_teamroom_type_id, 'Teamroom.Initiatives.CalendarPanel', 'Calendar', 3);
	InsertTab(out_teamroom_type_id, 'Teamroom.Initiatives.IssuesPanel', 'Milestones', 4);
	*/
	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY','APP'), 
		SYS_CONTEXT('SECURITY','APP'), 'Created teamroom type "{0}"', in_label);	
END;

PROCEDURE GetTeamroomTypes(
	out_teamroom_type_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_teamroom_type_cur FOR
		SELECT teamroom_type_id, label, hidden, base_css_class
		  FROM teamroom_type t
		 WHERE t.app_sid = security_pkg.getApp;		   
		 
END;

PROCEDURE GetTeamroomTabs (
	in_teamroom_sid 	IN 	 security_pkg.T_SID_ID,
	out_cur				OUT  SYS_REFCURSOR
)
AS
BEGIN
	-- no security used since we check group membership
	-- TODO: Extend this to check tab group role sid against region role member for the teamroom
	-- if we need to lock down by role
	OPEN out_cur FOR
		SELECT cs_class, js_include, js_class, tab_label, pos, plugin_type_id, MIN(is_read_only) is_read_only, teamroom_type_id
 		  FROM (
			SELECT p.cs_class, p.js_include, p.js_class, ttt.tab_label, ttt.pos, ttt.plugin_type_id, tttg.is_read_only, ttt.teamroom_type_id
			  FROM teamroom t
			  JOIN teamroom_type_tab ttt ON t.teamroom_type_id = ttt.teamroom_type_id AND t.app_sid = ttt.app_sid
			  JOIN teamroom_type_tab_group tttg ON ttt.teamroom_type_id = tttg.teamroom_type_id AND ttt.plugin_id = tttg.plugin_id AND ttt.app_sid = tttg.app_sid
			  JOIN plugin p ON ttt.plugin_id = p.plugin_id 
			  JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) y
				ON tttg.group_sid = y.column_value
			 WHERE t.teamroom_sid = in_teamroom_sid

			UNION
			
			SELECT p.cs_class, p.js_include, p.js_class, ttt.tab_label, ttt.pos, ttt.plugin_type_id, 0 is_read_only, ttt.teamroom_type_id
			  FROM plugin p
			  JOIN teamroom_type_tab ttt ON p.plugin_id = ttt.plugin_id
			  JOIN teamroom_type_tab_group tttg ON ttt.teamroom_type_id = tttg.teamroom_type_id AND ttt.plugin_id = tttg.plugin_id AND ttt.app_sid = tttg.app_sid
			  JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) y
				ON tttg.group_sid = y.column_value
			 WHERE p.plugin_type_id = csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_EDIT_PAGE
			   AND in_teamroom_sid = -1  -- only return all edit page plugins if it's a new teamroom
		 )
		 GROUP BY cs_class, js_include, js_class, tab_label, plugin_type_id, pos, teamroom_type_id
		 ORDER BY pos;	
END;

PROCEDURE ClearImg(
	in_teamroom_sid 				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, csr_data_pkg.PERMISSION_ADMINISTER_TEAMROOM) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to administer to teamroom sid'||in_teamroom_sid);
	END IF;

	UPDATE teamroom
	   SET img_data = null, img_sha1 = null, img_mime_type = null, img_last_modified_dtm = null
	 WHERE teamroom_sid = in_teamroom_sid;
END;

PROCEDURE SetImg(
	in_teamroom_sid 				IN  security_pkg.T_SID_ID,
	in_cache_key 				IN  VARCHAR2
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, csr_data_pkg.PERMISSION_ADMINISTER_TEAMROOM) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to administer to teamroom sid'||in_teamroom_sid);
	END IF;

	UPDATE teamroom
	   SET (img_data, img_sha1, img_mime_type, img_last_modified_dtm) = (
			SELECT object, dbms_crypto.hash(object, dbms_crypto.hash_sh1), mime_type, SYSDATE 				   
			  FROM aspen2.filecache 
			 WHERE cache_key = in_cache_key
		)
	  WHERE teamroom_sid = in_teamroom_sid;
END;

PROCEDURE AmendTeamroom(
	in_teamroom_sid 			IN  security_pkg.T_SID_ID,
	in_teamroom_type_id			IN  teamroom.teamroom_type_id%TYPE,
	in_name						IN  teamroom.name%TYPE,
	in_description				IN  teamroom.description%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, csr_data_pkg.PERMISSION_ADMINISTER_TEAMROOM) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to administer to teamroom sid'||in_teamroom_sid);
	END IF;

	UPDATE teamroom 
	   SET teamroom_type_id = in_teamroom_type_id,
		name = in_name,
		description = in_description
	 WHERE teamroom_sid = in_teamroom_sid;
END;

PROCEDURE INTERNAL_SetMemberPermissions(
	in_teamroom_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_can_administer		IN NUMBER
)
AS
	v_calendar_sid			security_pkg.T_SID_ID;
BEGIN
	IF in_can_administer = 1 THEN
		acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), acl_pkg.GetDACLIDForSID(in_teamroom_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, in_user_sid, csr_data_pkg.PERMISSION_ADMINISTER_TEAMROOM);
	END IF;
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY','ACT'), acl_pkg.GetDACLIDForSID(in_teamroom_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, in_user_sid, csr_data_pkg.PERMISSION_STD_TEAMROOM_MEMBER);	
	
	-- propagate ACEs down the SO tree
	acl_pkg.PropogateACEs(security.security_pkg.getAct, in_teamroom_sid);
END;

PROCEDURE CreateTeamroom(	
	in_teamroom_type_id			IN  teamroom.teamroom_type_id%TYPE,
	in_name						IN  teamroom.name%TYPE,
	in_description				IN  teamroom.description%TYPE,
	in_parent_sid 				IN  security_pkg.T_SID_ID DEFAULT NULL,
	out_teamroom_sid			OUT security_pkg.T_SID_ID
)
AS
	v_parent_sid  	security_pkg.T_SID_ID;
	v_doc_lib_sid 	security_pkg.T_SID_ID;	
BEGIN	
	v_parent_sid := COALESCE(in_parent_sid, securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Teamrooms'));

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), v_parent_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating a new teamroom');
	END IF;
	
	-- Create the securable object
	SecurableObject_Pkg.CreateSO(
		SYS_CONTEXT('SECURITY','ACT'),
		v_parent_sid,
		class_pkg.getClassID('Teamroom'),
		NULL, -- Create with null name the use UniqueSORename to ensure unique
		out_teamroom_sid
	);

	-- create doclib underneath and store doclib_sid
	doc_lib_pkg.CreateLibrary(
		in_parent_sid_id	=> out_teamroom_sid,
		in_library_name		=> 'DocLib',
		in_documents_name	=> 'Documents',
		in_trash_name		=> 'Recycling',
		in_app_sid			=> SYS_CONTEXT('SECURITY','APP'),
		out_doc_library_sid	=> v_doc_lib_sid
	);

	INSERT INTO teamroom (teamroom_sid, teamroom_type_id, name, description, doc_library_sid)
		VALUES (out_teamroom_sid,  in_teamroom_type_id, in_name, in_description, v_doc_lib_sid);

	-- make this user a member (and owner) of the teamroom
	INSERT INTO teamroom_member (teamroom_sid, user_sid, invited_by_sid, invited_dtm, accepted_dtm, can_invite_others)
		VALUES (out_teamroom_sid, SYS_CONTEXT('SECURITY','SID'), SYS_CONTEXT('SECURITY','SID'), SYSDATE, SYSDATE, 1);
		
	INTERNAL_SetMemberPermissions(out_teamroom_sid, SYS_CONTEXT('SECURITY','SID'), 1);
END;

PROCEDURE InviteMembers(
	in_teamroom_sid			IN  security_pkg.T_SID_ID,
	in_user_sids			IN 	security_pkg.T_SID_IDS,
	in_msg					IN  VARCHAR2,
	out_active_members_cur	OUT SYS_REFCURSOR
)
AS
	t_user_sids	security.T_SID_TABLE;
BEGIN
	t_user_sids := security_pkg.SidArrayToTable(in_user_sids);

	FOR r IN (
		SELECT column_value FROM TABLE(t_user_sids)
	)
	LOOP
		BEGIN
			INSERT INTO teamroom_member (teamroom_sid, user_sid, invited_by_sid, invited_dtm)
			 VALUES (in_teamroom_sid, r.column_value, SYS_CONTEXT('SECURITY', 'SID'), SYSDATE);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- if user was deactivated, re-activate them
				UPDATE teamroom_member
				   SET invited_by_sid = SYS_CONTEXT('SECURITY', 'SID'), invited_dtm = SYSDATE, accepted_dtm = NULL, deactivated_dtm = NULL	
				 WHERE teamroom_sid = in_teamroom_sid
				   AND user_sid = r.column_value
				   AND deactivated_dtm IS NOT NULL;
		END;
		-- TODO: ensure the users get added to the ACL for the teamroom sec objects
	END LOOP;
	
	OPEN out_active_members_cur FOR
		SELECT tm.user_sid, cu.full_name, cu.email, cu.phone_number, cu.job_title, CASE WHEN tm.accepted_dtm IS NOT NULL THEN 1 ELSE 0 END accepted_invitation,
				CASE WHEN au.created_user_sid IS NOT NULL AND au.activated_dtm IS NULL THEN 0 ELSE 1 END user_account_activated
		  FROM teamroom_member tm
		  JOIN csr_user cu ON tm.user_sid = cu.csr_user_sid AND tm.app_sid = cu.app_sid
		  LEFT JOIN autocreate_user au ON au.app_sid = cu.app_sid AND au.created_user_sid = cu.csr_user_sid
		 WHERE tm.teamroom_sid = in_teamroom_sid
		   AND tm.deactivated_dtm IS NULL
		 ORDER BY accepted_invitation DESC, cu.full_name;
END;

PROCEDURE AcceptInvitation(
	in_teamroom_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN 	security_pkg.T_SID_ID,
	out_accepted			OUT NUMBER
)
AS
	v_group_sid 			security_pkg.T_SID_ID;
	v_ucd_act 				security_pkg.T_ACT_ID;
BEGIN
	SELECT default_new_user_group_sid
	  INTO v_group_sid
	  FROM teamroom_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND teamroom_type_id IN (
			SELECT teamroom_type_id
			  FROM teamroom
			 WHERE teamroom_sid = in_teamroom_sid
	   );

	UPDATE teamroom_member
	   SET accepted_dtm = SYSDATE
	 WHERE teamroom_sid = in_teamroom_sid
	   AND user_sid = in_user_sid
	   AND accepted_dtm IS NULL
	   AND deactivated_dtm IS NULL;
		
	out_accepted := SQL%ROWCOUNT;
		
	IF out_accepted = 1 THEN
		-- set permissions as user creator daemon
		chain.helper_pkg.LogonUCD;
		v_ucd_act := security_pkg.GetAct;
		
		BEGIN
			-- grant standard permissions
			INTERNAL_SetMemberPermissions(in_teamroom_sid, in_user_sid, 0);
						
			-- add user to default group (if speciied)	
			IF v_group_sid IS NOT NULL THEN
				security.Group_Pkg.addMember(security.security_pkg.GetAct, in_user_sid, v_group_sid);
			END IF;	
		
			-- restore context ASAP
			chain.helper_pkg.RevertLogonUCD;
		EXCEPTION
			WHEN OTHERS THEN
				-- restore context
				chain.helper_pkg.RevertLogonUCD;
				RAISE;
		END;
	END IF;
END;

PROCEDURE DeactivateMember(
	in_teamroom_sid 	IN  security_pkg.T_SID_ID,
	in_user_sid 		IN  security_pkg.T_SID_ID
)
AS
	v_calendar_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, csr_data_pkg.PERMISSION_ADMINISTER_TEAMROOM) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to administer to teamroom sid'||in_teamroom_sid);
	END IF;

	UPDATE teamroom_member
	   SET deactivated_dtm = SYSDATE
	 WHERE teamroom_sid = in_teamroom_sid
	   AND user_sid = in_user_sid;
	   
	-- revoke permissions
	acl_pkg.RemoveACEsForSid(SYS_CONTEXT('SECURITY','ACT'), acl_pkg.GetDACLIDForSID(in_teamroom_sid), in_user_sid);
	acl_pkg.ResetDescendantACLs(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid);
END;

-- get the basics for editing
PROCEDURE GetSimpleTeamroom(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID, 
	out_cur 				OUT SYS_REFCURSOR
)
AS
BEGIN
	AssertReadAccess(in_teamroom_sid);

	OPEN out_cur FOR
		SELECT teamroom_sid, name, description, teamroom_type_Id, img_mime_type
		  FROM teamroom
		 WHERE teamroom_sid = in_teamroom_sid;
END;

PROCEDURE GetTeamroom(
	in_teamroom_sid 			IN  security_pkg.T_SID_ID, 
	out_teamroom_cur 			OUT SYS_REFCURSOR,
	out_active_members_cur  	OUT SYS_REFCURSOR	
)
AS
	v_can_administer	NUMBER(10);
BEGIN
	AssertReadAccess(in_teamroom_sid);

	IF security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, csr_data_pkg.PERMISSION_ADMINISTER_TEAMROOM) THEN
		v_can_administer := 1;
	ELSE
		v_can_administer := 0;
	END IF;

	OPEN out_teamroom_cur FOR
		SELECT t.teamroom_sid, t.name, t.description, t.teamroom_type_Id, tt.label teamroom_type_label,			
			tt.base_css_class, t.doc_library_sid,
			CASE WHEN img_mime_type IS NOT NULL THEN 1 ELSE 0 END has_img,
			v_can_administer can_administer
		  FROM teamroom t
		  JOIN teamroom_type tt ON t.teamroom_type_Id = tt.teamroom_type_id AND t.app_sid = tt.app_sid
		 WHERE t.teamroom_sid = in_teamroom_sid;

	-- TODO: chain company information?
	OPEN out_active_members_cur FOR
		SELECT tm.user_sid, cu.full_name, cu.email, cu.phone_number, cu.job_title, CASE WHEN tm.accepted_dtm IS NOT NULL THEN 1 ELSE 0 END accepted_invitation
		  FROM teamroom_member tm
		  JOIN csr_user cu ON tm.user_sid = cu.csr_user_sid AND tm.app_sid = cu.app_sid
		 WHERE tm.teamroom_sid = in_teamroom_sid
		   AND tm.deactivated_dtm IS NULL
		 ORDER BY cu.full_name;
END;

PROCEDURE GetUserMsgs(
	in_teamroom_sid 			IN  security_pkg.T_SID_ID, 
	out_msgs_cur 				OUT SYS_REFCURSOR,
	out_files_cur  				OUT SYS_REFCURSOR,
	out_likes_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	AssertReadAccess(in_teamroom_sid);

	OPEN out_msgs_cur FOR
		SELECT um.user_msg_id, um.user_sid, um.full_name, um.email, um.msg_dtm, um.msg_text, NVL(reply_count, 0) AS reply_count
		  FROM teamroom_user_msg tum
		  JOIN v$user_msg um ON tum.user_msg_id = um.user_msg_id
	 LEFT JOIN (
					SELECT reply_to_msg_id, COUNT(*) AS reply_count
					  FROM v$user_msg um
					 GROUP BY reply_to_msg_id
			   ) msg_reply
		    ON um.user_msg_id = msg_reply.reply_to_msg_id
		 WHERE tum.teamroom_sid = in_teamroom_sid
		 ORDER BY um.msg_dtm DESC;

	OPEN out_files_cur FOR
		SELECT umf.user_msg_file_id, umf.user_msg_id, umf.sha1, umf.mime_type
		  FROM teamroom_user_msg tum
		  JOIN v$user_msg_file umf ON tum.user_msg_id = umf.user_msg_id
		 WHERE tum.teamroom_sid = in_teamroom_sid;

	OPEN out_likes_cur FOR
		SELECT uml.user_msg_id, uml.liked_by_user_sid, uml.liked_dtm, uml.full_name, uml.email
		  FROM teamroom_user_msg tum
		  JOIN v$user_msg_like uml ON tum.user_msg_id = uml.user_msg_id
		 WHERE tum.teamroom_sid = in_teamroom_sid;
END;

-- private
PROCEDURE DoAddUserMsg(
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_user_msg_id			IN	user_msg.user_msg_id%TYPE,
	out_msg_cur 			OUT	SYS_REFCURSOR,
	out_files_cur			OUT	SYS_REFCURSOR
)
AS
	v_cache_key_tbl		security.T_VARCHAR2_TABLE;
BEGIN
	-- crap hack for ODP.NET
    IF in_cache_keys IS NULL OR (in_cache_keys.COUNT = 1 AND in_cache_keys(1) IS NULL) THEN
		-- do nothing
		NULL;
	ELSE
		v_cache_key_tbl := security_pkg.Varchar2ArrayToTable(in_cache_keys);
		INSERT INTO user_msg_file (user_msg_file_id, user_msg_id, filename, mime_type, data, sha1)
			SELECT user_msg_file_id_seq.nextval, in_user_msg_id, filename, mime_type, object,
				   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
			  FROM aspen2.filecache
			 WHERE cache_key IN (
				SELECT value FROM TABLE(v_cache_key_tbl)
			 );
	END IF;

	OPEN out_msg_cur FOR
		SELECT user_msg_id, user_sid, full_name, email, msg_dtm, msg_text
		  FROM v$user_msg
		 WHERE user_msg_id = in_user_msg_id;

	OPEN out_files_cur FOR
		SELECT user_msg_file_id, user_msg_id, sha1, mime_type
		  FROM v$user_msg_file
		 WHERE user_msg_id = in_user_msg_id;
END;

PROCEDURE AddUserMsg(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	in_msg_text				IN  user_msg.msg_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_msg_cur 			OUT SYS_REFCURSOR,
	out_files_cur  			OUT SYS_REFCURSOR
)
AS
	v_user_msg_id  		user_msg.user_msg_id%TYPE;
BEGIN	
	AssertWriteAccess(in_teamroom_sid);

	INSERT INTO user_msg (user_msg_Id, user_sid, msg_text, msg_dtm)
		VALUES (user_msg_id_seq.nextval, SYS_CONTEXT('SECURITY','SID'), in_msg_text, SYSDATE)
		RETURNING user_msg_id INTO v_user_msg_id;

	INSERT INTO teamroom_user_msg (teamroom_sid, user_msg_id)
		VALUES (in_teamroom_sid, v_user_msg_id);

	DoAddUserMsg(in_cache_keys, v_user_msg_id, out_msg_cur, out_files_cur);
END;

FUNCTION CanViewUserMsgImage(
	in_user_msg_file_Id		IN 	user_msg_file.user_msg_file_id%TYPE,
	in_sha1					IN	user_msg_file.sha1%TYPE
) RETURN NUMBER
AS
	v_teamroom_sid  security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(tum.teamroom_sid)
	  INTO v_teamroom_sid
	  FROM user_msg_file umf
	  JOIN csr.v$user_msg um ON umf.user_msg_id = um.user_msg_id
	  JOIN teamroom_user_msg tum ON umf.user_msg_id = tum.user_msg_id OR um.reply_to_msg_id = tum.user_msg_id
	 WHERE umf.sha1 = in_sha1 AND umf.user_msg_file_id = in_user_msg_file_id;

	IF v_teamroom_sid IS NULL THEN 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You cannot view this image - mismatched SHA1 or incorrect user_msg_file_id');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_teamroom_sid, security_pkg.PERMISSION_READ) THEN
		RETURN 0;
	END IF;

	RETURN 1;
END;

PROCEDURE GetTeamrooms(
	out_cur 				OUT SYS_REFCURSOR,
	out_open_invitations	OUT SYS_REFCURSOR
)
AS
	v_act						security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app						security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_teamrooms_sid				security_pkg.T_SID_ID;
	v_can_delete				NUMBER(10);
BEGIN
	v_teamrooms_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Teamrooms');
	v_can_delete := 0;	   	
	IF security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), v_teamrooms_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		v_can_delete := 1;
	END IF;
	
	OPEN out_cur FOR
		SELECT t.teamroom_sid, t.name, t.description, tt.label teamroom_type_label, tt.base_css_class, 
			CASE WHEN tm.teamroom_sid IS NOT NULL THEN 1 ELSE 0 END is_my_teamroom, v_can_delete can_delete
		  FROM teamroom t
		  JOIN teamroom_type tt ON t.teamroom_type_id = tt.teamroom_type_id AND t.app_sid = tt.app_sid
		  JOIN TABLE(securableObject_pkg.GetChildrenWithPermAsTable(v_act, securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Teamrooms'), security_pkg.PERMISSION_READ)) so ON t.teamroom_sid = so.sid_id
		  LEFT JOIN teamroom_member tm ON t.teamroom_sid = tm.teamroom_sid AND t.app_sid = tm.app_sid AND tm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		 ORDER BY t.name;

	OPEN out_open_invitations FOR
		SELECT t.teamroom_sid, t.name
		  FROM teamroom_member tm
		  JOIN teamroom t ON tm.app_sid = t.app_sid AND tm.teamroom_sid = t.teamroom_sid
		 WHERE tm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND tm.accepted_dtm IS NULL
		   AND tm.deactivated_dtm IS NULL;		 
END;

PROCEDURE GetTeamroomImage(
	in_teamroom_sid	IN 	security_pkg.T_SID_ID,
	out_cur			OUT  SYS_REFCURSOR
)
AS
BEGIN
	AssertReadAccess(in_teamroom_sid);

	OPEN out_cur FOR
		SELECT img_data, img_sha1, img_mime_type, img_last_modified_dtm
		  FROM teamroom
		 WHERE teamroom_sid = in_teamroom_sid;
END;

PROCEDURE IsTeamroomImageFresh(
	in_teamroom_sid			IN 	security_pkg.T_SID_ID,
	in_cached_image_mtime	IN DATE,
	out_image_fresh			OUT	NUMBER
)
AS
BEGIN
	AssertReadAccess(in_teamroom_sid);

	SELECT COUNT(*)
	  INTO out_image_fresh
	  FROM teamroom
	 WHERE teamroom_sid = in_teamroom_sid
	   AND img_last_modified_dtm = in_cached_image_mtime;
END;

PROCEDURE GetUserMsgImage(
	in_user_msg_file_Id		IN 	user_msg_file.user_msg_file_id%TYPE,
	in_sha1					IN	user_msg_file.sha1%TYPE,
	out_cur					OUT  SYS_REFCURSOR
)
AS
BEGIN
	IF CanViewUserMsgImage(in_user_msg_file_id, in_sha1) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You cannot view this image');
	END IF;

	OPEN out_cur FOR
		SELECT umf.filename, umf.data, umf.sha1, umf.mime_type, um.msg_dtm last_modified_dtm
		  FROM user_msg_file umf
		  JOIN user_msg um ON umf.user_msg_id = um.user_msg_id AND umf.app_sid = um.app_sid
		  JOIN teamroom_user_msg tum ON (um.user_msg_id = tum.user_msg_id OR um.reply_to_msg_id = tum.user_msg_id ) AND umf.app_sid = tum.app_sid	  
		 WHERE umf.sha1 = in_sha1 AND umf.user_msg_file_id = in_user_msg_file_id;
END;

PROCEDURE GetIssues(
	in_teamroom_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_show_rag_status		NUMBER(1);
BEGIN
	AssertReadAccess(in_teamroom_sid);

	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
	  INTO v_show_rag_status
	  FROM teamroom_issue ti
	  JOIN issue i ON ti.app_sid = i.app_sid AND ti.issue_id = i.issue_id
	  JOIN issue_type_rag_status itrs ON itrs.app_sid = i.app_sid AND itrs.issue_type_id = i.issue_type_id
	 WHERE ti.teamroom_sid = in_teamroom_sid;
	
	OPEN out_cur FOR
		SELECT i.issue_id, i.label, i.description, i.due_dtm, i.raised_dtm, i.resolved_dtm, i.manual_completion_dtm,
			   i.region_sid, i.region_name,
			   i.assigned_to_role_sid, i.assigned_to_role_name,
			   i.assigned_to_user_sid, i.assigned_to_full_name,
			   i.raised_by_user_sid, 
			   i.raised_full_name raised_by_full_name, -- ugh
			   i.closed_dtm,
			   i.issue_type_id, i.label issue_type_label, i.status, i.is_closed, 
			   i.is_resolved, i.is_rejected, i.is_overdue, i.is_critical,
			   itrs.label rag_status_label, itrs.colour rag_status_colour, v_show_rag_status show_rag_status
		  FROM teamroom_issue ti 
		  JOIN v$issue i ON ti.app_sid = i.app_sid AND ti.issue_id = i.issue_id
		  LEFT JOIN v$issue_type_rag_status itrs ON itrs.app_sid = i.app_sid AND itrs.issue_type_id = i.issue_type_id AND itrs.rag_status_id = i.rag_status_id
		 WHERE ti.teamroom_sid = in_teamroom_sid;
END;

PROCEDURE GetIssuesByDueDtm (
	in_teamroom_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	issue.due_dtm%TYPE,
	in_end_dtm					IN	issue.due_dtm%TYPE,
	in_my_issues				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	AssertReadAccess(in_teamroom_sid);

	OPEN out_cur FOR
		SELECT i.issue_id, i.status, i.issue_type_label, is_overdue, is_closed,
			   i.is_rejected, i.is_resolved, i.label, i.description, i.source_label, raised_full_name,
			   assigned_to_full_name, assigned_to_role_name, due_dtm, raised_dtm,
			   i.forecast_dtm, i.show_forecast_dtm, i.resolved_dtm, i.manual_completion_dtm
		  FROM teamroom_issue ti 
		  JOIN v$issue i ON ti.issue_id = i.issue_id
		 WHERE ti.teamroom_sid = in_teamroom_sid
		   AND COALESCE(i.manual_completion_dtm, i.resolved_dtm, i.forecast_dtm, i.due_dtm) >= in_start_dtm
		   AND COALESCE(i.manual_completion_dtm, i.resolved_dtm, i.forecast_dtm, i.due_dtm) < in_end_dtm
		   AND (in_my_issues = 0 OR (
				i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') 
				OR i.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID')
				OR i.issue_id IN (
					SELECT issue_id 
					  FROM issue_involvement 
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
				))
		   )
		 ORDER BY COALESCE(i.manual_completion_dtm, i.resolved_dtm, i.forecast_dtm, i.due_dtm);
END;

PROCEDURE AddIssue(
	in_teamroom_sid 				IN 	security_pkg.T_SID_ID,
	in_label						IN	issue.label%TYPE,
	in_description					IN	issue_log.message%TYPE,
	in_assign_to					IN	issue.assigned_to_user_sid%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_source_url					IN	issue.source_url%TYPE,
	in_is_urgent					IN	NUMBER,
	in_is_critical					IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id					OUT issue.issue_id%TYPE
)
AS
BEGIN
	AssertWriteAccess(in_teamroom_sid);

	issue_pkg.CreateIssue(
		in_label					=> in_label,
		in_description				=> in_description,
		in_source_label				=> null,
		in_issue_type_id			=> csr_data_pkg.ISSUE_TEAMROOM,
		in_correspondent_id			=> null,
		in_raised_by_user_sid		=> SYS_CONTEXT('SECURITY', 'SID'),
		in_assigned_to_user_sid		=> NVL(in_assign_to, SYS_CONTEXT('SECURITY', 'SID')),
		in_assigned_to_role_sid		=> null,
		in_priority_id				=> null,
		in_due_dtm					=> in_due_dtm,
		in_source_url				=> in_source_url,
		in_region_sid				=> null,
		in_is_urgent				=> in_is_urgent,
		in_is_critical				=> in_is_critical,
		out_issue_id				=> out_issue_id
	);

	-- bind to teamroom
	INSERT INTO teamroom_issue (teamroom_sid, issue_id)
		VALUES (in_teamroom_sid, out_issue_id);
END;

PROCEDURE GetCalendars(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act						security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app						security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	OPEN out_cur FOR
		SELECT cal.calendar_sid, p.description, p.js_include, p.js_class, /* TEMP: backwards compatibility */p.js_class js_class_type, p.cs_class, cal.applies_to_teamrooms, cal.applies_to_initiatives
		  FROM plugin p
		  JOIN calendar cal ON p.plugin_id = cal.plugin_id AND p.plugin_type_id = 12
		  JOIN TABLE(securableObject_pkg.GetChildrenWithPermAsTable(v_act, securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Calendars'), security_pkg.PERMISSION_READ)) so ON cal.calendar_sid = so.sid_id
		 WHERE cal.applies_to_teamrooms = 1; 
END;

-- in_start_dtm, in_end_dtm and in_teamroom_sid can all be null
PROCEDURE GetEvents(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	in_teamroom_sid 	IN 	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act						security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app						security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	OPEN out_cur FOR
		SELECT te.teamroom_sid, t.name teamroom_name, ce.calendar_event_id event_id, ce.description, ce.start_dtm, ce.end_dtm, ce.location, ce.created_by_sid, ce.created_dtm
		  FROM calendar_event ce
		  JOIN teamroom_event te ON ce.calendar_event_id = te.calendar_event_id AND ce.app_sid = te.app_sid
		  JOIN teamroom t ON t.app_sid = te.app_sid AND t.teamroom_sid = te.teamroom_sid
		  JOIN TABLE(securableObject_pkg.GetChildrenWithPermAsTable(v_act, securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Teamrooms'), security_pkg.PERMISSION_READ)) so ON te.teamroom_sid = so.sid_id
		 WHERE (in_teamroom_sid IS NULL OR te.teamroom_sid = in_teamroom_sid)
		   AND (in_start_dtm IS NULL OR ce.start_dtm < in_end_dtm)
		   AND (in_end_dtm IS NULL OR NVL(ce.end_dtm, in_end_dtm) > in_start_dtm);
END;

PROCEDURE GetEventUsers(
	in_event_id			IN	NUMBER,
	out_owner_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_attendee_cur	OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	OPEN out_owner_cur FOR 
		SELECT ceo.user_sid, ceo.added_dtm, ceo.added_by_sid, u.full_name, ceo.calendar_event_id event_id
		  FROM calendar_event_owner ceo
		  JOIN csr.v$csr_user u ON ceo.user_sid = u.csr_user_sid
		 WHERE calendar_event_id = in_event_id
	  ORDER BY full_name;
	
	OPEN out_attendee_cur FOR 
		SELECT cei.user_sid, cei.invited_dtm added_dtm, cei.invited_by_sid added_by_sid, u.full_name, cei.calendar_event_id event_id, cei.accepted_dtm, cei.declined_dtm, cei.attended
		  FROM calendar_event_invite cei
		  JOIN csr.v$csr_user u ON cei.user_sid = u.csr_user_sid
		 WHERE calendar_event_id = in_event_id
	  ORDER BY full_name;
END;

PROCEDURE GetUpcomingEvents(
	in_teamroom_sid 	IN 	security_pkg.T_SID_ID,
	in_max_events		IN	NUMBER,	
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	AssertReadAccess(in_teamroom_sid);

	OPEN out_cur FOR
		SELECT * 
		FROM (
			SELECT te.teamroom_sid, te.calendar_event_id event_id, 'event' event_type, ce.description, ce.start_dtm event_date, 
				ce.created_by_sid, ce.created_dtm
			  FROM calendar_event ce
			  JOIN teamroom_event te ON ce.calendar_event_id = te.calendar_event_id AND ce.app_sid = te.app_sid
			 WHERE te.teamroom_sid = in_teamroom_sid
			   AND ce.start_dtm > SYSDATE			 
			 UNION		
			SELECT ti.teamroom_sid, i.issue_id event_id, 'issue' event_type, i.label description, due_dtm event_date, 
				raised_by_user_sid created_by_sid, raised_dtm created_dtm		
			  FROM teamroom_issue ti 
			  JOIN v$issue i ON ti.issue_id = i.issue_id
			 WHERE ti.teamroom_sid = in_teamroom_sid
			   AND i.due_dtm > SYSDATE	   
			   -- limit to my issues only
			   AND (i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') 
					OR i.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					OR i.issue_id IN (
						SELECT issue_id 
						  FROM issue_involvement 
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
					)
				)
			ORDER BY event_date
		   )		
		WHERE ROWNUM <= in_max_events;		
END;

PROCEDURE AddEvent(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	in_description			IN  calendar_event.description%TYPE,
	in_start_dtm			IN	calendar_event.start_dtm%TYPE,
	in_end_dtm				IN	calendar_event.end_dtm%TYPE,
	in_location				IN  calendar_event.location%TYPE,
	in_owner_ids			IN	security.security_pkg.T_SID_IDS,
	in_invited_ids			IN	security.security_pkg.T_SID_IDS
)
AS
	v_calendar_event_id 	calendar_event.calendar_event_id%TYPE;
	v_sid_table				security.T_SID_TABLE;
BEGIN	
	AssertWriteAccess(in_teamroom_sid);

	INSERT INTO calendar_event (calendar_event_id, description, start_dtm, end_dtm, location, created_by_sid, created_dtm)
		VALUES (csr.calendar_event_id_seq.nextval, in_description, in_start_dtm, in_end_dtm, in_location, SYS_CONTEXT('SECURITY','SID'), SYSDATE)
		RETURNING calendar_event_id INTO v_calendar_event_id;

	INSERT INTO teamroom_event (calendar_event_id, teamroom_sid)
		VALUES (v_calendar_event_id, in_teamroom_sid);
	
	-- owners
	v_sid_table := security_pkg.SidArrayToTable(in_owner_ids);
	
	FOR r IN (SELECT COLUMN_VALUE FROM TABLE(v_sid_table) WHERE COLUMN_VALUE != -1)
	LOOP
		INSERT INTO calendar_event_owner (calendar_event_id, user_sid)
			 VALUES (v_calendar_event_id,r.COLUMN_VALUE);
	END LOOP;
	
	-- invites
	v_sid_table := security_pkg.SidArrayToTable(in_invited_ids);
	
	FOR r IN (SELECT COLUMN_VALUE FROM TABLE(v_sid_table) WHERE COLUMN_VALUE != -1)
	LOOP
		INSERT INTO calendar_event_invite (calendar_event_id, user_sid)
			 VALUES (v_calendar_event_id,r.COLUMN_VALUE);
	END LOOP;
END;

PROCEDURE AmendEvent(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	in_calendar_event_id 	IN  teamroom_event.calendar_event_id%TYPE,
	in_description			IN  calendar_event.description%TYPE,
	in_start_dtm			IN	calendar_event.start_dtm%TYPE,
	in_end_dtm				IN	calendar_event.end_dtm%TYPE,
	in_location				IN  calendar_event.location%TYPE,
	in_owner_ids			IN	security.security_pkg.T_SID_IDS,
	in_invited_ids			IN	security.security_pkg.T_SID_IDS
)
AS
	v_sid_table			security.T_SID_TABLE;
BEGIN
	AssertWriteAccess(in_teamroom_sid);

	UPDATE calendar_event
	   SET description = in_description,
		   start_dtm = in_start_dtm,
		   end_dtm = in_end_dtm,
		   location = in_location
	 WHERE calendar_event_id IN (
	 	SELECT calendar_event_id 
	 	  FROM teamroom_event 
	 	 WHERE teamroom_sid = in_teamroom_sid
	   	   AND calendar_event_id = in_calendar_event_id
	 );
	 
	 v_sid_table := security_pkg.SidArrayToTable(in_owner_ids);
	 
	 -- owners
	FOR r IN (SELECT t.COLUMN_VALUE 
				FROM TABLE(v_sid_table) t 
			   WHERE t.COLUMN_VALUE NOT IN (SELECT user_sid FROM calendar_event_owner WHERE calendar_event_id = in_calendar_event_id) AND t.COLUMN_VALUE != -1)
	LOOP
		BEGIN
		INSERT INTO calendar_event_owner (calendar_event_id, user_sid)
			 VALUES (in_calendar_event_id,r.COLUMN_VALUE);
		END;
	END LOOP;
	
	DELETE FROM calendar_event_owner
	      WHERE user_sid NOT IN (SELECT COLUMN_VALUE FROM TABLE(v_sid_table));
		  
	v_sid_table := security_pkg.SidArrayToTable(in_invited_ids);
	 
	 -- invites
	FOR r IN (SELECT t.COLUMN_VALUE 
				FROM TABLE(v_sid_table) t 
			   WHERE t.COLUMN_VALUE NOT IN (SELECT user_sid FROM calendar_event_invite WHERE calendar_event_id = in_calendar_event_id) AND t.COLUMN_VALUE != -1)
	LOOP
		BEGIN
		INSERT INTO calendar_event_invite (calendar_event_id, user_sid)
			 VALUES (in_calendar_event_id,r.COLUMN_VALUE);
		END;
	END LOOP;
	
	DELETE FROM calendar_event_invite
	      WHERE user_sid NOT IN (SELECT COLUMN_VALUE FROM TABLE(v_sid_table));
	
	DELETE FROM calendar_event_owner
	      WHERE user_sid NOT IN (SELECT COLUMN_VALUE FROM TABLE(v_sid_table));	-- if removed from event, remove as 'event owner' as well.
END;

PROCEDURE DeleteEvent(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	in_calendar_event_id 	IN  teamroom_event.calendar_event_id%TYPE
)
AS
BEGIN	
	AssertWriteAccess(in_teamroom_sid);

	DELETE FROM calendar_event
	   WHERE calendar_event_id IN (
	     		-- check the right teamroom_sid + event_id have been passed in (surely we should work out teamroom_sid from event_id?)
	     		SELECT calendar_event_id
	     		  FROM teamroom_event
	     		 WHERE teamroom_sid = in_teamroom_sid
	     		   AND calendar_event_id = in_calendar_event_id
	     );
END;

-- pointless...?
PROCEDURE DeleteTeamroom(
	in_teamroom_sid			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, csr_data_pkg.PERMISSION_ADMINISTER_TEAMROOM) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to administer to teamroom sid'||in_teamroom_sid);
	END IF;
	
	DeleteObject(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid);
END;

PROCEDURE LinkInitiative(
	in_teamroom_sid			IN  security_pkg.T_SID_ID,
	in_initiative_sid		IN  security_pkg.T_SID_ID
)
AS
	v_helper_pkg				initiative_project.helper_pkg%TYPE;
BEGIN
	-- XXX: what permission does the user really need here?
	AssertReadAccess(in_teamroom_sid);

	SELECT ip.helper_pkg
	  INTO v_helper_pkg
	  FROM initiative i
	  JOIN initiative_project ip ON i.project_sid = ip.project_sid AND i.app_sid = ip.app_sid
	 WHERE i.initiative_sid = in_initiative_sid;
	
	BEGIN
		INSERT INTO teamroom_initiative (teamroom_sid, initiative_sid)
			VALUES (in_teamroom_sid, in_initiative_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	-- call helper?
	IF v_helper_pkg IS NOT NULL THEN
	    EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.LinkInitiativeToTeamroom(:1, :2);end;'
			USING in_initiative_sid, in_teamroom_sid;
	END IF;
END;

PROCEDURE GetUserMsgReplies(
	in_reply_to_msg_id			IN  user_msg.user_msg_id%TYPE,
	in_no_of_replies			IN	NUMBER DEFAULT NULL,
	out_msgs_cur 				OUT SYS_REFCURSOR,
	out_files_cur  				OUT SYS_REFCURSOR,
	out_likes_cur				OUT SYS_REFCURSOR
)
AS
	v_msgs_sql					VARCHAR2(1000);
	v_files_sql					VARCHAR2(1000);
	v_likes_sql					VARCHAR2(1000);
BEGIN
	-- err... why is this concatenting SQL...? 
	-- It should probably just select some IDs into a temporary table and then run some bog
	-- standard SQL statements. This kind of thing without bind paramteres is very bad news for Oracle!!
	v_msgs_sql := '
		SELECT user_msg_id, user_sid, full_name, email, msg_dtm, msg_text FROM (
		SELECT um.user_msg_id, um.user_sid, um.full_name, um.email, um.msg_dtm, um.msg_text, ROWNUM AS rn
		  FROM v$user_msg um
		 WHERE um.reply_to_msg_id = ' || in_reply_to_msg_id || ' ORDER BY um.msg_dtm DESC) rply';

	IF in_no_of_replies IS NOT NULL THEN
		v_msgs_sql := v_msgs_sql || ' WHERE ROWNUM <= ' || in_no_of_replies;
	END IF;
	v_msgs_sql := v_msgs_sql || ' ORDER BY msg_dtm ASC';
	
	OPEN out_msgs_cur FOR v_msgs_sql;

	v_files_sql := '
		SELECT umf.user_msg_file_id, umf.user_msg_id, umf.sha1, umf.mime_type
		  FROM v$user_msg_file umf
		  JOIN ( ' || v_msgs_sql || ') msg_reply ON umf.user_msg_id = msg_reply.user_msg_id';
	OPEN out_files_cur FOR v_files_sql;

	v_likes_sql := '
		SELECT uml.user_msg_id, uml.liked_by_user_sid, uml.liked_dtm, uml.full_name, uml.email
		  FROM v$user_msg_like uml
		  JOIN ( ' || v_msgs_sql || ') msg_reply ON uml.user_msg_id = msg_reply.user_msg_id';
	OPEN out_likes_cur FOR v_likes_sql;
END;

PROCEDURE AddUserMsgReply(
	in_reply_to_msg_id 		IN  user_msg.user_msg_id%TYPE,
	in_msg_text				IN  user_msg.msg_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_msg_cur 			OUT SYS_REFCURSOR,
	out_files_cur  			OUT SYS_REFCURSOR
)
AS
	v_teamroom_sid				security_pkg.T_SID_ID; 
	v_user_msg_id  				user_msg.user_msg_id%TYPE;
BEGIN
	SELECT teamroom_sid 
	  INTO v_teamroom_sid
	  FROM teamroom_user_msg
	 WHERE user_msg_id = in_reply_to_msg_id;

	AssertWriteAccess(v_teamroom_sid);

	INSERT INTO user_msg (user_msg_Id, user_sid, msg_text, msg_dtm, reply_to_msg_id)
		VALUES (user_msg_id_seq.nextval, SYS_CONTEXT('SECURITY','SID'), in_msg_text, SYSDATE, in_reply_to_msg_id)
		RETURNING user_msg_id INTO v_user_msg_id;

	DoAddUserMsg(in_cache_keys, v_user_msg_id, out_msg_cur, out_files_cur);
END;

PROCEDURE GetIssueAssignables(  
	in_issue_id					IN  teamroom_issue.issue_id%TYPE,
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	out_cur						OUT SYS_REFCURSOR,
	out_total_num_users			OUT SYS_REFCURSOR
)      
IS
	v_table							T_USER_FILTER_TABLE;
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_max_size						NUMBER := csr_user_pkg.MAX_USERS;
	v_show_email					NUMBER;
	v_show_user_name				NUMBER;
	v_show_user_ref					NUMBER;
BEGIN	
	csr_user_pkg.FilterUsersToTable(in_filter, in_include_inactive, v_table);
	
	SELECT CASE WHEN INSTR(user_picker_extra_fields, 'email', 1) != 0 THEN 1 ELSE 0 END show_email,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_name', 1) != 0 THEN 1 ELSE 0 END show_user_name,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_ref', 1) != 0 THEN 1 ELSE 0 END show_user_ref
	  INTO v_show_email, v_show_user_name, v_show_user_ref
	  FROM customer
	 WHERE app_sid = v_app_sid;

	OPEN out_total_num_users FOR
		SELECT COUNT(*) total_num_users, v_max_size max_size
		  FROM (
			SELECT DISTINCT cu.csr_user_sid
			  FROM csr_user cu, TABLE(v_table) t
			 WHERE cu.app_sid =  v_app_sid
			   AND cu.csr_user_sid = t.csr_user_sid
			   AND cu.app_sid = v_app_sid
			   AND cu.csr_user_sid IN (
				-- limit to teamroom members only
				SELECT tm.user_sid
				  FROM teamroom_issue ti
				  JOIN teamroom_member tm ON tm.teamroom_sid = ti.teamroom_sid AND tm.app_sid = ti.app_sid
				 WHERE ti.issue_id = in_issue_id
				   --AND tm.accepted_dtm IS NOT NULL
				   AND tm.deactivated_dtm IS NULL
		   )
		  );

	OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT x.*, rownum rn
			  FROM (
				SELECT cu.csr_user_sid user_sid, cu.full_name, cu.email, cu.user_name, cu.user_ref, t.account_enabled,
					   cu.csr_user_sid csr_user_sid, cu.csr_user_sid sid,
					   v_show_email show_email, v_show_user_name show_user_name, v_show_user_ref show_user_ref
				  FROM csr_user cu, TABLE(v_table) t
				  -- first name, or last name (space separator)
				 WHERE cu.app_sid = v_app_sid
				   AND cu.csr_user_sid = t.csr_user_sid
				   AND cu.app_sid = v_app_sid
				   AND cu.csr_user_sid IN (
						-- limit to teamroom members only
						SELECT tm.user_sid
						  FROM teamroom_issue ti
						  JOIN teamroom_member tm ON tm.teamroom_sid = ti.teamroom_sid AND tm.app_sid = ti.app_sid
						 WHERE ti.issue_id = in_issue_id
						   --AND tm.accepted_dtm IS NOT NULL
						   AND tm.deactivated_dtm IS NULL
				       )
				 ORDER BY t.account_enabled DESC, 
					   CASE WHEN in_filter IS NULL OR LOWER(TRIM(cu.full_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END, -- Favour names that start with the provided filter.
					   CASE WHEN in_filter IS NULL OR LOWER(TRIM(cu.full_name)) || ' ' LIKE '% ' || LOWER(in_filter) || ' %' THEN 0 ELSE 1 END, -- Favour whole words over prefixes.
					   LOWER(TRIM(cu.full_name))
			       ) x
		       )
		 WHERE rn <= v_max_size
		 ORDER BY rn;
END;

PROCEDURE FilterMembers(
	in_teamroom_sid				IN  security_pkg.T_SID_ID,
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	AssertReadAccess(in_teamroom_sid);

	OPEN out_cur FOR
		SELECT cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, ut.account_enabled,
			   cu.csr_user_sid user_sid, cu.csr_user_sid sid  -- yes I know! but we use csr_user_sid in some legacy things
		  FROM teamroom_member tm
          JOIN csr_user cu ON tm.user_sid = cu.csr_user_sid AND tm.app_sid = cu.app_sid
          JOIN security.user_table ut on cu.csr_user_sid = ut.sid_id
		  -- first name, or last name (space separator)
		 WHERE teamroom_sid = in_teamroom_Sid
           AND (LOWER(TRIM(cu.full_name)) LIKE LOWER(in_filter) || '%' OR LOWER(TRIM(cu.full_name)) LIKE '% ' || LOWER(in_filter) || '%') 
		   AND tm.deactivated_dtm IS NULL
	  ORDER BY ut.account_enabled DESC,
      			CASE WHEN in_filter IS NULL OR LOWER(TRIM(cu.full_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END, -- Favour names that start with the provided filter.
			   CASE WHEN in_filter IS NULL OR LOWER(TRIM(cu.full_name)) || ' ' LIKE '% ' || LOWER(in_filter) || ' %' THEN 0 ELSE 1 END, -- Favour whole words over prefixes.
			   LOWER(TRIM(cu.full_name));
END;

FUNCTION IsChainEnabled
RETURN NUMBER
AS
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.company_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	RETURN v_count;
END;

PROCEDURE GetDefaultTeamroomCompanies(
	out_cur 				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT teamroom_type_id, c.company_sid, c.name
		  FROM teamroom_type tt
		  JOIN chain.company c on c.app_sid = tt.app_sid and c.company_sid = tt.default_company_sid;
END;

PROCEDURE GetTeamroomCompanies(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	out_cur 				OUT SYS_REFCURSOR
)
AS
BEGIN
	AssertReadAccess(in_teamroom_sid);

	OPEN out_cur FOR
		SELECT c.company_sid, c.name
		  FROM teamroom_company tc
		  JOIN chain.company c on c.app_sid = tc.app_sid and c.company_sid = tc.company_sid
		 WHERE tc.teamroom_sid = in_teamroom_sid;
END;

PROCEDURE SetTeamroomCompanies(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID, 
	in_company_sids			IN	security_pkg.T_SID_IDS
)
AS
	t 						security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_teamroom_sid, csr_data_pkg.PERMISSION_ADMINISTER_TEAMROOM) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to administer to teamroom sid'||in_teamroom_sid);
	END IF;

	t := security_pkg.SidArrayToTable(in_company_sids);
	
	DELETE FROM teamroom_company 
	 WHERE teamroom_sid = in_teamroom_sid;
	
	FOR r IN (SELECT column_value company_sid FROM TABLE(t))
	LOOP	
		INSERT INTO teamroom_company(teamroom_sid, company_sid, added_by_sid, added_dtm)
		VALUES (in_teamroom_sid, r.company_sid, SYS_CONTEXT('SECURITY','SID'), SYSDATE);
	END LOOP;
END;

PROCEDURE GetTeamroomSuppliers(
	in_teamroom_sid 		IN  security_pkg.T_SID_ID,
	out_cur 				OUT SYS_REFCURSOR
)
AS
BEGIN
	AssertReadAccess(in_teamroom_sid);

	OPEN out_cur FOR
		SELECT s.region_sid
		  FROM teamroom_company tc
		  JOIN chain.company c on c.app_sid = tc.app_sid AND c.company_sid = tc.company_sid
		  JOIN csr.supplier s ON c.app_sid = s.app_sid AND c.company_sid = s.company_sid
		 WHERE tc.teamroom_sid = in_teamroom_sid;
END;

PROCEDURE FilterUsersToTable (
	in_teamroom_sid		IN  security_pkg.T_SID_ID,
	in_filter			IN	VARCHAR2,
	in_include_inactive	IN	NUMBER DEFAULT 0,
	out_table			OUT T_USER_FILTER_TABLE
)
AS
	v_sa_cnt 			NUMBER(10);
	v_chain_enabled		NUMBER(10);
BEGIN
	v_chain_enabled := IsChainEnabled;
	
	SELECT COUNT(*) 
	  INTO v_sa_cnt
	  FROM superadmin
	 WHERE csr_user_sid = SYS_CONTEXT('SECURITY','SID');

	SELECT T_USER_FILTER_ROW(cu.csr_user_sid, ut.account_enabled, CASE WHEN sa.csr_user_sid IS NOT NULL THEN 1 ELSE 0 END)
	  BULK COLLECT INTO out_table
	  FROM csr_user cu, security.user_table ut, customer c, superadmin sa
	  -- first name, or last name (space separator)
	 WHERE ((LOWER(TRIM(cu.full_name)) LIKE LOWER(in_filter) || '%' OR LOWER(TRIM(cu.full_name)) LIKE '% ' || LOWER(in_filter) || '%')
 	    OR (LOWER(TRIM(cu.email)) LIKE LOWER(in_filter) || '%')
	    OR (LOWER(TRIM(cu.user_name)) LIKE LOWER(in_filter) || '%')
		OR (LOWER(TRIM(cu.user_ref)) LIKE LOWER(in_filter) || '%'))
	   AND cu.app_sid = c.app_sid
	   AND ut.sid_id = cu.csr_user_sid 
	   AND cu.csr_user_sid = sa.csr_user_sid(+)
	   AND (ut.account_enabled = 1 OR in_include_inactive = 1) -- Only show active users.
	   AND (sa.csr_user_sid IS NULL OR v_sa_cnt > 0)
	   AND c.app_sid = security_pkg.GetApp() 
	   AND cu.hidden = 0  -- hidden is for excluding things like UserCreatorDaemon
	   AND cu.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND (
			v_chain_enabled = 0 OR cu.csr_user_sid IN (
				SELECT user_sid 
				  FROM chain.v$company_user ccu
				  JOIN teamroom_company tc ON tc.app_sid = ccu.app_sid AND tc.company_sid = ccu.company_sid
				 WHERE teamroom_sid = in_teamroom_sid				
			)
	   );
END;

PROCEDURE FilterUsers(  
	in_teamroom_sid				IN  security_pkg.T_SID_ID,
	in_filter					IN	VARCHAR2,
	in_include_inactive			IN	NUMBER DEFAULT 0,
	in_exclude_user_sids		IN  security_pkg.T_SID_IDS, -- mainly for finding users except user X - e.g. on a user edit page.	
	out_cur						OUT Security_Pkg.T_OUTPUT_CUR,
	out_total_num_users			OUT Security_Pkg.T_OUTPUT_CUR
)
IS
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_table					T_USER_FILTER_TABLE;
	v_exclude_user_sids		security.T_SID_TABLE;
	v_max_size				NUMBER DEFAULT csr.csr_user_pkg.MAX_USERS;
	v_show_email			NUMBER;
	v_show_user_name		NUMBER;
	v_show_user_ref			NUMBER;
BEGIN
	AssertReadAccess(in_teamroom_sid);

	v_exclude_user_sids := security_pkg.SidArrayToTable(in_exclude_user_sids);
	FilterUsersToTable(in_teamroom_sid, in_filter, in_include_inactive, v_table);

	SELECT CASE WHEN INSTR(user_picker_extra_fields, 'email', 1) != 0 THEN 1 ELSE 0 END show_email,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_name', 1) != 0 THEN 1 ELSE 0 END show_user_name,
		   CASE WHEN INSTR(user_picker_extra_fields, 'user_ref', 1) != 0 THEN 1 ELSE 0 END show_user_ref
	  INTO v_show_email, v_show_user_name, v_show_user_ref
	  FROM customer
	 WHERE app_sid = v_app_sid;
	 
	OPEN out_total_num_users FOR
		SELECT COUNT(*) total_num_users, v_max_size max_size
		  FROM csr_user cu, TABLE(v_table) t
		 WHERE cu.app_sid = v_app_sid
		   AND cu.csr_user_sid = t.csr_user_sid
		   AND cu.csr_user_sid NOT IN (SELECT column_value FROM TABLE(v_exclude_user_sids));
	
	OPEN out_cur FOR
		SELECT csr_user_sid, full_name, email, user_name, user_ref, account_enabled, user_sid, sid,
			   v_show_email show_email, v_show_user_name show_user_name, v_show_user_ref show_user_ref
		  FROM (
			SELECT x.csr_user_sid, x.full_name, x.email, x.user_name, x.user_ref, x.account_enabled, x.user_sid, x.sid
			   FROM (
				SELECT cu.csr_user_sid, cu.full_name, cu.email, cu.user_name, cu.user_ref, t.account_enabled,
					   cu.csr_user_sid user_sid, cu.csr_user_sid sid  -- yes I know! but we use csr_user_sid AND sid in some legacy things
				  FROM csr_user cu, TABLE(v_table) t
				 WHERE cu.app_sid = v_app_sid
				   AND cu.csr_user_sid = t.csr_user_sid
				   AND cu.csr_user_sid NOT IN (SELECT column_value FROM TABLE(v_exclude_user_sids))
			)x
		  ORDER BY x.account_enabled DESC,
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.full_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END, -- Favour names that start with the provided filter.
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.full_name)) || ' ' LIKE '% ' || LOWER(in_filter) || ' %' THEN 0 ELSE 1 END, -- Favour whole words over prefixes.
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.email)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.user_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				   CASE WHEN in_filter IS NULL OR LOWER(TRIM(x.user_ref)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END,
				   LOWER(TRIM(x.full_name))
		)
		WHERE ROWNUM <= v_max_size;
END;

PROCEDURE CreateUserForApproval(
  	in_user_name				IN	CSR_USER.user_NAME%TYPE,
	in_password 				IN	VARCHAR2, -- nullable
   	in_full_name				IN	CSR_USER.full_NAME%TYPE,
	in_email		 			IN	CSR_USER.email%TYPE,
	in_job_title				IN	CSR_USER.job_title%TYPE,
	in_phone_number				IN	CSR_USER.phone_number%TYPE,
	in_chain_company_sid 		IN	security_pkg.T_SID_ID,
	in_redirect_to_url			IN	autocreate_user.redirect_to_url%TYPE,
	in_teamroom_sid				IN	security_pkg.T_SID_ID,
	out_sid_id					OUT	security_pkg.T_SID_ID,
	out_guid					OUT	security_pkg.T_ACT_ID
)
AS
	v_helper_pkg				initiative_project.helper_pkg%TYPE;
BEGIN
	BEGIN
		SELECT tt.helper_pkg 
		  INTO v_helper_pkg
		  FROM teamroom_type tt
		  JOIN teamroom t ON t.teamroom_type_id = tt.teamroom_type_id
		 WHERE t.teamroom_sid = in_teamroom_sid;
	END;

	BEGIN
		csr.csr_user_pkg.CreateUserForApproval(
			in_user_name			=> in_user_name,
			in_password				=> in_password,
			in_full_name			=> in_full_name,
			in_email				=> in_email,
			in_job_title			=> in_job_title,
			in_phone_number			=> in_phone_number,
			in_chain_company_sid	=> in_chain_company_sid,
			in_redirect_to_url		=> in_redirect_to_url,
			out_sid_id				=> out_sid_id,
			out_guid				=> out_guid
		);
		
		IF v_helper_pkg IS NOT NULL THEN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.UserCreatedViaInvite(:1, :2);end;'
				USING out_sid_id, in_chain_company_sid;
		END IF;
	END;
END;

END;
/
