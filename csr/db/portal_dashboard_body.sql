CREATE OR REPLACE PACKAGE BODY CSR.portal_dashboard_pkg AS

-- Securable object callbacks.
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
	v_acl_id				security.SECURABLE_OBJECT.dacl_id%TYPE;
	v_currentuser_sid		security.security_pkg.T_SID_ID;
BEGIN	
	NULL;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
	v_menu_sid				security_pkg.T_SID_ID;
	v_portal_group			portal_dashboard.portal_group%TYPE;
	v_acl_id				security.SECURABLE_OBJECT.dacl_id%TYPE;
	v_currentuser_sid		security.security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_sid_id, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	user_pkg.GetSID(in_act_id, v_currentuser_sid);
	--security_pkg.debugmsg('PD.DeleteObject');
	
	--Delete the menu item, if it exists
	BEGIN
		SELECT menu_sid, portal_group
		  INTO v_menu_sid, v_portal_group
		  FROM portal_dashboard
		 WHERE portal_sid = in_sid_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		IF v_menu_sid >  0 THEN
			v_acl_id := security.acl_pkg.GetDACLIDForSID(v_menu_sid);
			security.acl_pkg.AddACE(in_act_id, v_acl_id, security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_currentuser_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

			security.securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), v_menu_sid);
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT tab_id
		  FROM tab
		 WHERE portal_group = v_portal_group
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		portlet_pkg.UNSECURED_DeleteTab(
			in_tab_id => r.tab_id
		);
	END LOOP;

	DELETE FROM portal_dashboard
	 WHERE portal_sid = in_sid_id;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
	v_menu_sid				security_pkg.T_SID_ID;
BEGIN
	-- Remove the dashboard dacls from the old parent and add the dacls for the new parent.
	
	SELECT menu_sid 
	  INTO v_menu_sid
	  FROM portal_dashboard
	 WHERE portal_sid = in_sid_id AND
		   app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	/*security_pkg.debugmsg(
	'MoveObject '||
	'sid '||in_sid_id||'; '||
	'menu '||v_menu_sid||'; '||
	'in_new_parent_sid_id '||in_new_parent_sid_id||'; '||
	'in_old_parent_sid_id '||in_old_parent_sid_id||'; '||
	'.'
	);*/

	-- There may not be a menu
	IF v_menu_sid > 0 THEN
		RemoveDashboardPerms(in_old_parent_sid_id, v_menu_sid);
		AddDashboardPerms(in_new_parent_sid_id, v_menu_sid);
	END IF;
END;

PROCEDURE GetFolderPath(
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sid_id, Name
		  FROM security.securable_object
			START WITH sid_id = in_folder_sid AND class_id = 4	--Container
			CONNECT BY sid_id = PRIOR parent_sid_id AND class_id = 4
		ORDER BY LEVEL DESC;
END;

PROCEDURE GetChildDashboards(
	in_parent_sid	IN security_pkg.T_SID_ID,
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT portal_sid, portal_group label
		  FROM PORTAL_DASHBOARD pd
		  JOIN security.SECURABLE_OBJECT so ON so.sid_id = pd.portal_sid
		 WHERE so.parent_sid_id = in_parent_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), pd.portal_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY label;
END;

PROCEDURE GetDashboardList(
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT portal_sid, portal_group, menu_sid, message
		  FROM csr.portal_dashboard;

END;

PROCEDURE GetDashboard(
	in_portal_sid			IN	PORTAL_DASHBOARD.portal_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_portal_sid				PORTAL_DASHBOARD.portal_sid%TYPE;
BEGIN

	-- Make sure it exists so we can catch the empty cursor
	BEGIN
		SELECT portal_sid
		  INTO v_portal_sid
		  FROM csr.portal_dashboard
		 WHERE portal_sid = in_portal_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 
				'No portal dashboard found with sid '||in_portal_sid);
	END;

	OPEN out_cur FOR
		SELECT portal_sid, portal_group, message, menu_sid
		  FROM csr.portal_dashboard
		 WHERE portal_sid = in_portal_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetGroups(
	in_sid						IN	security_pkg.T_SID_ID,
	out_groups_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_groups_cur FOR
		SELECT sid_id, name
		  FROM security.securable_object
		 WHERE sid_id IN (
				SELECT sid_id
				  FROM security.acl
				 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(in_sid)
			   );
END;

PROCEDURE GetDashboardAndMenu(
	in_portal_sid				IN	PORTAL_DASHBOARD.portal_sid%TYPE,
	out_dashboard_cur			OUT	SYS_REFCURSOR,
	out_menu_cur				OUT	SYS_REFCURSOR,
	out_menu_groups_cur			OUT SYS_REFCURSOR,
	out_dashboard_groups_cur	OUT SYS_REFCURSOR
)
AS
	v_menu_sid					PORTAL_DASHBOARD.menu_sid%TYPE;
BEGIN
	GetDashboard(in_portal_sid, out_dashboard_cur);

	SELECT menu_sid
	  INTO v_menu_sid
	  FROM csr.portal_dashboard
	 WHERE portal_sid = in_portal_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_menu_cur FOR
		select m.sid_id, m.description, so.parent_sid_id
		  FROM security.menu m
		  JOIN security.securable_object so on m.sid_id = so.sid_id
		 WHERE m.sid_id = v_menu_sid
		   AND so.application_sid_id = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_menu_groups_cur FOR
		SELECT sid_id, name
		  FROM security.securable_object
		 WHERE sid_id IN (
				SELECT sid_id 
				  FROM security.acl 
				 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(v_menu_sid)
				   AND application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
			   )
		   AND sid_id NOT IN (
				SELECT sid_id
				  FROM security.acl
				 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(in_portal_sid)
			   );

	OPEN out_dashboard_groups_cur FOR
		SELECT sid_id, name
		  FROM security.securable_object
		 WHERE sid_id IN (
				SELECT sid_id
				  FROM security.acl
				 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(in_portal_sid)
			   );
END;

PROCEDURE CreateDashboard(
	in_dashboard_container_sid		IN	security_pkg.T_SID_ID,
	in_label						IN	PORTAL_DASHBOARD.portal_group%TYPE,
	in_message						IN	PORTAL_DASHBOARD.message%TYPE,
	in_parent_menu_sid				IN	PORTAL_DASHBOARD.menu_sid%TYPE,
	in_menu_label					IN	VARCHAR2,
	in_menu_group_sids				IN	security_pkg.T_SID_IDS,
	in_dashboard_group_sids			IN	security_pkg.T_SID_IDS,
	out_dashboard_sid				OUT	PORTAL_DASHBOARD.portal_sid%TYPE
)
AS
	v_act								security_pkg.T_ACT_ID;
	v_new_menu_sid						security_pkg.T_SID_ID;
BEGIN

	IF in_label = approval_dashboard_pkg.PORTAL_GROUP_NAME THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_INVALID_OBJECT_NAME, 'Invalid dashboard name.');
	END IF;

	v_act := security_pkg.getACT;

	securableobject_pkg.CreateSO(v_act,
		in_dashboard_container_sid, 
		class_pkg.getClassID('CSRPortalDashboard'),
		REPLACE(in_label,'/','\'), --'
		out_dashboard_sid);

	UpdateDashboardContainerPerms(in_dashboard_container_sid, in_dashboard_group_sids);
	
	-- create menu item if label and container given
	IF in_parent_menu_sid IS NOT NULL AND TRIM(in_menu_label) IS NOT NULL THEN
		BEGIN
			security.menu_pkg.CreateMenu(v_act, in_parent_menu_sid, MakeMenuObjectName(in_label), in_menu_label, MakeMenuURL(out_dashboard_sid), 1, null, v_new_menu_sid);			
			-- Remove all the inherited permissions first.
			ClearAllPerms(v_new_menu_sid);
			AddDashboardPerms(out_dashboard_sid, v_new_menu_sid);
			AddGroupPerms(v_new_menu_sid, in_menu_group_sids);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END IF;

	BEGIN
		INSERT INTO csr.PORTAL_DASHBOARD
			(portal_sid, portal_group, menu_sid, message)
		VALUES
			(out_dashboard_sid, in_label, v_new_menu_sid, in_message);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Portal name already used');
	END;
END;

PROCEDURE UpdateDashboard(
	in_dashboard_sid				IN	PORTAL_DASHBOARD.portal_sid%TYPE,
	in_label						IN	PORTAL_DASHBOARD.portal_group%TYPE,
	in_message						IN	PORTAL_DASHBOARD.message%TYPE,
	in_parent_menu_sid				IN	PORTAL_DASHBOARD.menu_sid%TYPE,
	in_menu_label					IN	VARCHAR2,
	in_menu_group_sids				IN	security_pkg.T_SID_IDS,
	in_dashboard_group_sids			IN	security_pkg.T_SID_IDS
)
AS
	v_act							security_pkg.T_ACT_ID;
	v_existing_menu_sid				security_pkg.T_SID_ID;
	v_existing_parent_menu_sid		security_pkg.T_SID_ID;
	v_existing_menu_desc			VARCHAR2(255);
	v_existing_portal_group			csr.portal_dashboard.portal_group%TYPE;
	v_acl_id						security.SECURABLE_OBJECT.dacl_id%TYPE;
	v_currentuser_sid				security_pkg.T_SID_ID;
	v_currentuser_exists			NUMBER := 0;
	v_dashboard_container_sid		security_pkg.T_SID_ID;
BEGIN
	v_act := security_pkg.getACT;

	SELECT parent_sid_id INTO v_dashboard_container_sid
	  FROM security.securable_object
	 WHERE sid_id = in_dashboard_sid AND
		   application_sid_id = SYS_CONTEXT('SECURITY', 'APP');
	UpdateDashboardContainerPerms(v_dashboard_container_sid, in_dashboard_group_sids);
	
	-- case statement to check whether the menu_sid really exists (might have been deleted in secmgr3, there is no FK to sec_obj table, hence manual check)
	SELECT portal_group, CASE WHEN EXISTS (SELECT 1 FROM security.menu WHERE sid_id = pd.menu_sid) THEN pd.menu_sid ELSE NULL END menu_sid, so.parent_sid_id, m.description
	  INTO v_existing_portal_group, v_existing_menu_sid, v_existing_parent_menu_sid, v_existing_menu_desc
	  FROM portal_dashboard pd
	  LEFT JOIN security.securable_object so ON so.sid_id = pd.menu_sid
	  LEFT JOIN security.menu m 			 ON m.sid_id  = pd.menu_sid
	 WHERE portal_sid = in_dashboard_sid
	   AND pd.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	user_pkg.GetSID(v_act, v_currentuser_sid);
	
	-- deal with menu only when parent_sid and label exist
	IF in_parent_menu_sid IS NOT NULL AND TRIM(in_menu_label) IS NOT NULL THEN
		IF v_existing_menu_sid IS NULL THEN
			security.menu_pkg.CreateMenu(v_act, in_parent_menu_sid, MakeMenuObjectName(in_label), in_menu_label, MakeMenuURL(in_dashboard_sid), 1, null, v_existing_menu_sid);
		END IF;

		v_acl_id := security.acl_pkg.GetDACLIDForSID(v_existing_menu_sid);
		SELECT count(SID_ID)
		  INTO v_currentuser_exists
		  FROM SECURITY.ACL 
		 WHERE ACL_ID = v_acl_id
		   AND SID_ID = v_currentuser_sid;
		
		-- Do the permissions first, so any subsequent renames/moves are possible if the permissions are borked.
		ClearMenuPerms(v_existing_menu_sid, in_dashboard_sid, in_menu_group_sids);
		
		-- Then add the actual required permissions back in.
		AddGroupPerms(v_existing_menu_sid, in_menu_group_sids);
		
		-- If not already there, add current user dacl here, so they can manipulate it.
		IF v_currentuser_exists = 0 THEN
			--security_pkg.debugmsg('adding current user to dacl');
			security.acl_pkg.AddACE(v_act, v_acl_id, security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_currentuser_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		END IF;
		
		IF in_parent_menu_sid != v_existing_parent_menu_sid THEN
			-- Re-parent the menu
			security.securableobject_pkg.MoveSO(v_act, v_existing_menu_sid, in_parent_menu_sid);
		END IF;
		
		
		IF v_existing_menu_desc != in_menu_label THEN
			-- Rename the menu
			security.menu_pkg.SetMenuDescription(v_act, v_existing_menu_sid, in_menu_label);
		END IF;
		
		IF v_existing_portal_group != in_label THEN
			security.securableobject_pkg.RenameSO(v_act, v_existing_menu_sid, MakeMenuObjectName(in_label));
		END IF;

		-- Remove the temp CU ACE, if we added it.
		IF v_currentuser_exists = 0 THEN
			security.acl_pkg.RemoveACEsForSid(v_act, v_acl_id, v_currentuser_sid);
		END IF;
	ELSE
		IF v_existing_menu_sid IS NOT NULL THEN
			-- Delete the menu
			v_acl_id := security.acl_pkg.GetDACLIDForSID(v_existing_menu_sid);
			security.acl_pkg.AddACE(v_act, v_acl_id, security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_currentuser_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
			security.securableobject_pkg.DeleteSO(v_act, v_existing_menu_sid);
			v_existing_menu_sid := NULL;
		END IF;
	END IF;

	IF v_existing_portal_group != in_label THEN
		security.securableobject_pkg.RenameSO(v_act, in_dashboard_sid, in_label);
	END IF;

	BEGIN
		UPDATE csr.PORTAL_DASHBOARD
		   SET portal_group = in_label,
			   menu_sid = v_existing_menu_sid,
			   message = in_message
		 WHERE portal_sid = in_dashboard_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
		-- Update any existing tabs
		UPDATE tab
		   SET portal_group = in_label
		 WHERE portal_group = v_existing_portal_group
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Portal name already used');
	END;
END;

PROCEDURE UpdateDashboardContainerPerms(
	in_dashboard_container_sid		IN	security_pkg.T_SID_ID,
	in_dashboard_group_sids			IN	security_pkg.T_SID_IDS
)
AS
	v_act							security_pkg.T_ACT_ID := security_pkg.getACT;
BEGIN
	ClearAllPerms(in_dashboard_container_sid);
	AddGroupPerms(in_dashboard_container_sid, in_dashboard_group_sids);
	
	-- propagate permissions downwards
	acl_pkg.PropogateACEs(v_act, in_dashboard_container_sid);
END;

PROCEDURE ClearMenuPerms(
	in_menu_sid						IN	security_pkg.T_SID_ID,
	in_dashboard_sid				IN	security_pkg.T_SID_ID,
	in_menu_group_sids				IN	security_pkg.T_SID_IDS
)
AS
	v_act							security_pkg.T_ACT_ID := security_pkg.getACT;
	v_acl_id						security.SECURABLE_OBJECT.dacl_id%TYPE;
	v_menu_groups					security.T_SID_TABLE;
BEGIN
	v_acl_id := security.acl_pkg.GetDACLIDForSID(in_menu_sid);
	-- Remove perms we don't want anymore. So, we're looking at the existing item and finding any ACLs (sids) which are NOT 
	-- XXX on the actual dashboard SO or XXX
	-- in the list of groups.
	v_menu_groups := security_pkg.SidArrayToTable(in_menu_group_sids);
	FOR r IN (
		SELECT sid_id 
		  FROM SECURITY.ACL 
		 WHERE ACL_ID = security.acl_pkg.GetDACLIDForSID(in_menu_sid)
			   AND sid_id NOT IN (
			SELECT sid_id group_sid
			  FROM security.acl
			 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(in_dashboard_sid)
			 UNION
			SELECT column_value group_sid
			  FROM TABLE(v_menu_groups)
		   )
	)
	LOOP
		security.acl_pkg.RemoveACEsForSid(v_act, v_acl_id, r.sid_id);
	END LOOP;
END;

PROCEDURE ClearAllPerms(
	in_sid							IN	security_pkg.T_SID_ID
)
AS
	v_act							security_pkg.T_ACT_ID := security_pkg.getACT;
	v_acl_id						security.SECURABLE_OBJECT.dacl_id%TYPE;
BEGIN
	v_acl_id := security.acl_pkg.GetDACLIDForSID(in_sid);
	security.securableobject_pkg.ClearFlag(v_act, in_sid, security.security_pkg.SOFLAG_INHERIT_DACL);
	FOR r IN (
		SELECT sid_id 
		  FROM SECURITY.ACL 
		 WHERE ACL_ID = security.acl_pkg.GetDACLIDForSID(in_sid)
	)
	LOOP
		security.acl_pkg.RemoveACEsForSid(v_act, v_acl_id, r.sid_id);
	END LOOP;
END;

PROCEDURE AddDashboardPerms(
	in_dashboard_sid				IN	PORTAL_DASHBOARD.portal_sid%TYPE,
	v_menu_sid						IN	security_pkg.T_SID_ID
)
AS
	v_act							security_pkg.T_ACT_ID := security_pkg.getACT;
	v_acl_id						security.SECURABLE_OBJECT.dacl_id%TYPE;
BEGIN
	v_acl_id := security.acl_pkg.GetDACLIDForSID(v_menu_sid);
	-- Copy permissions from the dashboard object to the menu. 
	-- Add write permission to the menu in case they try and rename it later.
	FOR r IN (
		SELECT sid_id group_sid
		  FROM security.acl
		 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(in_dashboard_sid)
	)
	LOOP
		security.acl_pkg.AddACE(v_act, v_acl_id, security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, r.group_sid, security.security_pkg.PERMISSION_STANDARD_READ + security.security_pkg.PERMISSION_WRITE);
	END LOOP;
END;

PROCEDURE RemoveDashboardPerms(
	in_dashboard_sid				IN	PORTAL_DASHBOARD.portal_sid%TYPE,
	v_menu_sid						IN	security_pkg.T_SID_ID
)
AS
	v_act							security_pkg.T_ACT_ID := security_pkg.getACT;
	v_acl_id						security.SECURABLE_OBJECT.dacl_id%TYPE;
BEGIN
	v_acl_id := security.acl_pkg.GetDACLIDForSID(v_menu_sid);
	FOR r IN (
		SELECT sid_id group_sid
		  FROM security.acl
		 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(in_dashboard_sid)
	)
	LOOP
		security.acl_pkg.RemoveACEsForSid(v_act, v_acl_id, r.group_sid);
	END LOOP;
END;

PROCEDURE AddGroupPerms(
	in_sid						IN	security_pkg.T_SID_ID,
	in_group_sids				IN	security_pkg.T_SID_IDS
)
AS
	v_act						security_pkg.T_ACT_ID;
	v_groups					security.T_SID_TABLE;
	v_acl_id					security.SECURABLE_OBJECT.dacl_id%TYPE;
	v_superadmins_sid			security.security_pkg.T_SID_ID;
	v_sa_exists					NUMBER := 0;
BEGIN
	v_act := security_pkg.getACT;
	v_groups := security_pkg.SidArrayToTable(in_group_sids);
	v_acl_id := security.acl_pkg.GetDACLIDForSID(in_sid);
	v_superadmins_sid := security.securableobject_pkg.GetSIDFromPath(v_act, 0, 'csr/SuperAdmins');
	security_pkg.debugmsg('v_acl_id' || v_acl_id);
	FOR r IN (
		SELECT column_value sid
		  FROM TABLE(v_groups)
		 WHERE column_value NOT IN (
			SELECT sid_id 
			  FROM SECURITY.ACL 
			 WHERE acl_id = security.acl_pkg.GetDACLIDForSID(in_sid)
		 )
	)
	LOOP
		security.acl_pkg.AddACE(v_act, v_acl_id, security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, r.sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;

	-- If not already there, add SuperAdmin dacl here, so SuperAdmins can manipulate it.
	SELECT count(SID_ID)
	  INTO v_sa_exists
	  FROM SECURITY.ACL 
	 WHERE ACL_ID = security.acl_pkg.GetDACLIDForSID(in_sid)
	   AND SID_ID = v_superadmins_sid;

	IF v_sa_exists = 0 THEN
		security.acl_pkg.AddACE(v_act, v_acl_id, security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_superadmins_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
	END IF;
END;

FUNCTION MakeMenuObjectName(
	in_portal_group				IN	VARCHAR2
) RETURN VARCHAR2
AS
BEGIN
	IF chain.setup_pkg.IsChainEnabled THEN
		RETURN 'chain_dashboard_'||REPLACE(LOWER(in_portal_group),' ','_');
	ELSE
		RETURN 'csr_portal_home_'||REPLACE(LOWER(in_portal_group),' ','_');
	END IF;
END;

FUNCTION MakeMenuURL(
	in_dashboard_sid				IN	PORTAL_DASHBOARD.portal_sid%TYPE
) RETURN VARCHAR2
AS
BEGIN
	IF chain.setup_pkg.IsChainEnabled THEN
		RETURN '/csr/site/chain/dashboard.acds?portalSid='||in_dashboard_sid;
	ELSE
		RETURN '/csr/site/portal/home.acds?portalSid='||in_dashboard_sid;
	END IF;
END;

END;
/
