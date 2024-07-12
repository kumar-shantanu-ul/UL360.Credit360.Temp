CREATE OR REPLACE PACKAGE BODY CSR.portlet_pkg IS

MAX_PORTLETS_PER_TAB 		CONSTANT NUMBER(2) := 50;
DASHBOARD_ONLY				CONSTANT NUMBER(1) := -1;
DASHBOARD_HOME				CONSTANT NUMBER(1) := -1;

FUNCTION GetDashboardSid(
	in_app_sid				IN security.security_pkg.T_SID_ID,
	in_tab_id				IN tab.tab_id%TYPE
) RETURN security.security_pkg.T_SID_ID
AS
	v_db_sid				security.security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(portal_sid)
	  INTO v_db_sid
	  FROM tab t
	  LEFT JOIN portal_dashboard pd ON t.portal_group = pd.portal_group
	 WHERE t.tab_id = in_tab_id
	   AND t.app_sid = in_app_sid;
	   
	RETURN v_db_sid;
END;

PROCEDURE CreateAuditLogEntry(
	in_msg					IN audit_log.description%TYPE,
	in_tab_id				IN tab.tab_id%TYPE,
	in_tab_portlet_id		IN tab_portlet.tab_portlet_Id%TYPE DEFAULT NULL,
	in_param_1				IN audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2				IN audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3				IN audit_log.param_3%TYPE DEFAULT NULL
)
AS
	v_customer_portlet_sid	security.security_pkg.T_SID_ID;
	v_app					security.security_pkg.T_SID_ID;
	v_act					security.security_pkg.T_ACT_ID;
BEGIN
	
	v_act := security.security_pkg.getACT;
	v_app := security.security_pkg.getApp;
	
	IF in_tab_portlet_id IS NOT NULL THEN
		
		csr_data_pkg.WriteAuditLogEntry(
			in_act_id			=> v_act,
			in_app_sid			=> v_app,
			in_audit_type_id	=> csr_data_pkg.AUDIT_TYPE_PORTLET,
			in_object_sid		=> in_tab_portlet_id,
			in_description		=> in_msg,
			in_sub_object_id	=> NVL(GetDashboardSid(v_app, in_tab_id), DASHBOARD_HOME),
			in_param_1			=> in_param_1,
			in_param_2			=> in_param_2,
			in_param_3			=> in_param_3
		);
	ELSE		
	
		csr_data_pkg.WriteAuditLogEntry(
			in_act_id			=> v_act,
			in_app_sid			=> v_app,
			in_audit_type_id	=> csr_data_pkg.AUDIT_TYPE_DASHBOARD,
			in_object_sid		=> in_tab_id,
			in_description		=> in_msg,
			in_sub_object_id	=> NVL(GetDashboardSid(v_app, in_tab_id), DASHBOARD_HOME),
			in_param_1			=> in_param_1,
			in_param_2			=> in_param_2,
			in_param_3			=> in_param_3
		);
	END IF;
	
END;

FUNCTION GetPortletNameFromTabPortletId (
	in_tab_portlet_id	IN	tab_portlet.tab_portlet_id%TYPE
) RETURN VARCHAR2
AS
	v_rtn				VARCHAR2(1024);
BEGIN
	SELECT MIN(p.type)
	  INTO v_rtn
	  FROM tab_portlet tp
	  JOIN customer_portlet cp ON tp.customer_portlet_sid = cp.customer_portlet_sid
	  JOIN portlet p ON cp.portlet_id = p.portlet_id
	 WHERE tp.tab_portlet_id = in_tab_portlet_id;

	RETURN NVL(v_rtn, 'unknown');
END;
/**
 * Barf if the user isn't a user of this tab portlet
 *
 * @param		in_tab_portlet_Id		Tab Portlet ID
 */
PROCEDURE CheckTabPortletUser(
	in_tab_portlet_id	IN	tab_portlet.tab_portlet_id%TYPE
)
AS
	v_cnt	NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM (
		SELECT tab_id
		  FROM tab_user tu
		 WHERE tu.user_sid = security_pkg.GetSID()
		 UNION
		SELECT tab_id
		  FROM TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT))x, TAB_GROUP tg
		 WHERE tg.group_sid = x.column_value
			) x, tab_portlet tp
	 WHERE x.tab_id = tp.tab_id
	   AND tp.tab_portlet_id = in_tab_portlet_id;
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Tab_portlet_id '||in_tab_portlet_id||' does not belong to user sid '||security_pkg.GetSID());
	END IF;
END;

/**
 * Barf if the user isn't a user of this tab
 *
 * @param		in_tab_Id		TabID
 */
PROCEDURE CheckTabUser(
	in_tab_id	IN	tab.tab_id%TYPE
)
AS
	v_cnt	NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM (
		SELECT tab_id
		  FROM tab_user tu
		 WHERE tu.user_sid = security_pkg.GetSID()
		 UNION
		SELECT tab_id
		  FROM TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT))x, TAB_GROUP tg
		 WHERE tg.group_sid = x.column_value
		)
	 WHERE tab_id = in_tab_id;
		
	IF v_cnt = 0 THEN
		-- TODO: further app specific checks, e.g. check approval_dashboard_tab table
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Tab_id '||in_tab_id||' does not belong to user sid '||security_pkg.GetSID());
	END IF;
END;
/**
 * Barf if the user isn't the owner of this tab portlet
 *
 * @param		in_tab_portlet_Id		Tab Portlet ID
 */
PROCEDURE CheckTabPortletOwner(
	in_tab_portlet_id	IN	tab_portlet.tab_portlet_id%TYPE
)
AS
	v_cnt	NUMBER(10);
BEGIN
	IF csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Manage any portal') THEN
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM tab_user tu
	  JOIN tab_portlet tp ON tu.tab_id = tp.tab_id
	 WHERE tp.tab_portlet_id = in_tab_portlet_id
	   AND tu.user_sid = security_pkg.GetSID()
	   AND tu.is_owner = 1;
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Tab_portlet_id '||in_tab_portlet_id||' does not belong to user sid '||security_pkg.GetSID());
	END IF;
END;

/**
 * Barf if the user isn't the owner of this tab
 *
 * @param		in_tab_Id		TabID
 */
PROCEDURE CheckTabOwner(
	in_tab_id	IN	tab.tab_id%TYPE
)
AS
	v_cnt	NUMBER(10);
BEGIN
	IF csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Manage any portal') THEN
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM tab_user tu
	 WHERE tab_id = in_tab_id
	   AND tu.user_sid = security_pkg.GetSID()
	   AND tu.is_owner = 1;
		
	IF v_cnt = 0 THEN
		-- TODO: further app specific checks, e.g. check approval_dashboard_tab table
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Tab_id '||in_tab_id||' does not belong to user sid '||security_pkg.GetSID());
	END IF;
END;

/**
 * Get our tabs
 *
 * @return		out_cur						 Tab details
 *
 */

PROCEDURE GetTabs(
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_portal_group	IN	tab.portal_group%TYPE,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_is_owner	NUMBER := 0;
BEGIN
	v_user_sid := security_pkg.GetSID();
	
	
	IF csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Manage any portal') THEN
		v_is_owner := 1;
	END IF;
	
	-- return cursor
	OPEN out_cur FOR
		-- gets all the tabs I'm entitled to see where there's
		-- a row for me in tab_user
			SELECT DISTINCT tab_id, layout, name, is_shared, NVL(override_pos,NVL(pos,99)) pos, override_pos,
				CASE WHEN v_is_owner = 1 THEN 1 ELSE is_owner END is_owner, -- pretend we're the owner if we've got 'manage any portal' capability
				is_hideable
				FROM v$TAB_USER
			 WHERE user_sid = security_pkg.GetSID
			 AND app_sid = SYS_CONTEXT('SECURITY','APP')
				 AND is_hidden = 0
				 AND (
					is_owner = 1 OR
					tab_id IN (
							-- ensure the user is still in the group
							SELECT tab_id
								FROM TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT))x, TAB_GROUP tg
							 WHERE tg.group_sid = x.column_value
					)
				)
			    AND (portal_group = in_portal_group OR (portal_group IS NULL AND in_portal_group IS NULL))
			UNION
			-- gets all the tabs I'm entitled to see where there's
			-- no row for me in tab_user
			-- the pos is taken from tag_group table, however there is no UI currently to set this
			SELECT DISTINCT x.tab_id, layout, NVL(td.description, t.name) name, 1 is_shared, NVL(t.override_pos,NVL(tu.pos,99)) pos, t.override_pos, v_is_owner is_owner, is_hideable
				FROM (
					SELECT tab_id
						FROM TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT))y, TAB_GROUP tg
					 WHERE tg.group_sid = y.column_value
					   AND tg.app_sid = SYS_CONTEXT('SECURITY','APP')
					 MINUS
					SELECT tab_id
						FROM tab_user
					 WHERE user_sid = security_pkg.GetSID
			)x 
			 JOIN TAB t ON x.tab_id = t.tab_id
			 LEFT JOIN tab_user tu ON t.tab_id = tu.tab_id AND tu.user_sid = security_pkg.GetSID
			 LEFT JOIN tab_group tg ON t.tab_id = tg.tab_id
			 LEFT JOIN tab_description td ON t.tab_id = td.tab_id AND td.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
			 WHERE t.portal_group = in_portal_group OR (t.portal_group IS NULL AND in_portal_group IS NULL)
		ORDER BY pos, name;
END;

PROCEDURE CreateTabDescriptions(
	in_tab_id		IN tab_description.tab_id%TYPE
)
AS
	v_description	csr.tab.name%TYPE;
BEGIN
	FOR r IN
	(SELECT lang
	   FROM csr.v$customer_lang l
	  WHERE NOT EXISTS (SELECT 1 FROM csr.tab_description WHERE lang = l.lang AND tab_id = in_tab_id)
	)
	LOOP
		SELECT name
		  INTO v_description
		  FROM csr.tab t
		 WHERE tab_id = in_tab_id;
		
		INSERT INTO csr.tab_description(tab_id, lang, description, last_changed_dtm)
		VALUES(in_tab_id, r.lang, v_description, SYSDATE);
		
		CreateAuditLogEntry(
		in_msg			=> 'Created tab_description "{0}" for tab_id "{1}" for language "{2}"',
		in_tab_id		=> DASHBOARD_ONLY,
		in_param_1		=> v_description,
		in_param_2		=> in_tab_id,
		in_param_3		=> r.lang
		);
		
	END LOOP;
END;

PROCEDURE GetTabTitles(
	in_tab_id 			IN tab_description.tab_id%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN

	CreateTabDescriptions(in_tab_id);

	OPEN out_cur FOR
		SELECT d.lang, l.description lang_full, d.description
		  FROM tab_description d
		  JOIN aspen2.translation_set t ON t.application_sid = SYS_CONTEXT('SECURITY','APP')
		   AND t.lang = d.lang
		   AND t.hidden = 0
		  JOIN aspen2.lang l ON l.lang = t.lang
		 WHERE tab_id = in_tab_id
		 ORDER BY l.description;
END;

PROCEDURE SaveTabTitle(
	in_tab_id 			IN tab_description.tab_id%TYPE,
	in_lang				IN tab_description.lang%TYPE,
	in_description		IN tab_description.description%TYPE
)
AS
BEGIN
	
	UPDATE tab_description
	   SET description = in_description, last_changed_dtm = SYSDATE()
	 WHERE tab_id = in_tab_id
	   AND description != in_description
	   AND lang = in_lang;

	CreateAuditLogEntry(
	in_msg			=> 'Amended tab_description to "{0}" for tab_id "{1}" for language "{2}"',
	in_tab_id		=> DASHBOARD_ONLY,
	in_param_1		=> in_description,
	in_param_2		=> in_tab_id,
	in_param_3		=> in_lang
	);
END;

PROCEDURE GetScriptFiles(
	in_tab_ids		IN	security_pkg.T_SID_IDS,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_tab_ids		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_tab_ids);
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT p.script_path
		  FROM portlet p
		  JOIN customer_portlet cp ON p.portlet_id = cp.portlet_id
		  JOIN tab_portlet tp ON cp.customer_portlet_sid = tp.customer_portlet_sid
		  JOIN TABLE(v_tab_ids) t ON tp.tab_id = t.column_value
		 WHERE cp.app_sid = security_pkg.GetApp
		   AND p.script_path IS NOT NULL;
END;

PROCEDURE GetHiddenTabs(
	out_cur		 OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid	 security_pkg.T_SID_ID;
	v_app_sid		security_pkg.T_SID_ID;
BEGIN
	v_user_sid	:= security_pkg.GetSID();
	v_app_sid	 := security_pkg.GetApp();
	
	OPEN out_cur FOR
		SELECT tab_id, name
		  FROM v$tab_user
		 WHERE app_sid = v_app_sid
		   AND is_hidden = 1
		   AND user_sid = v_user_sid;
END;

PROCEDURE ShowHiddenTab(
	in_tab_id	 IN	security_pkg.T_SID_ID,
	out_cur		 OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	v_user_sid	:= security_pkg.getSid();
	
	UPDATE tab_user
	   SET is_hidden = 0
	 WHERE tab_id = in_tab_id
	   AND user_sid = v_user_sid;

	OPEN out_cur FOR
		SELECT tab_id, layout, name, is_shared, is_hideable, pos, is_owner
	  	  FROM v$tab_user
		 WHERE tab_id = in_tab_id
		   AND user_sid = v_user_sid;
END;

/**
 * Unassociate user from shared tab
 *
 * @param in_tab_id				csr app sid
 */
PROCEDURE RemoveSharedTab(
	in_tab_id	IN	tab.tab_id%TYPE
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	v_user_sid := security_pkg.GetSID();
	/*
				INSERT INTO TAB_USER
					 (tab_id, user_sid, pos, is_owner, is_hidden)
				SELECT tab_id, user_sid, pos, is_owner, 1
					FROM TAB_USER
					WHERE TAB_ID = in_tab_id;
			
		EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
						UPDATE TAB_USER
							 SET is_hidden = 1
						 WHERE tab_id = in_tab_id
							 AND user_sid = v_user_sid;
*/
END;

/**
 * Duplicates shared tab to have writeable copy
 *
 * @param in_tab_id				csr app sid
 */
PROCEDURE CopyTab(
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_tab_id			IN tab.TAB_ID%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_tab_name				tab.name%TYPE;
	v_tab_layout 			tab.layout%TYPE;
	v_tab_portlet_id	tab_portlet.tab_portlet_Id%TYPE;
	v_tab_portal_group	tab.portal_group%TYPE;
	v_new_tab_id 		tab.tab_id%TYPE;
BEGIN
	-- name the new tab like: 	oldName*
	select name || '*', layout, portal_group into v_tab_name, v_tab_layout, v_tab_portal_group from TAB where tab_id = in_tab_id;
	
	-- add new tab with same paramteres
	AddTabReturnTabId(in_app_sid, v_tab_name, 0, 1, v_tab_layout, v_tab_portal_group, v_new_tab_id);
	CreateTabDescriptions(v_new_tab_id);

	-- if this was on an approval dashboard then copy stuff over
	-- XXX: this is broken --> no group by (max is being done on the wrong thing etc)
	INSERT INTO approval_dashboard_tab
		(approval_dashboard_sid, tab_id, pos)
		SELECT approval_dashboard_sid, v_new_tab_id, NVL(MAX(pos),0) + 1
		  FROM approval_dashboard_tab
		 WHERE tab_id = in_tab_id
		 GROUP BY approval_dashboard_sid;

	-- finally copy portlets to new tab
	FOR r IN (
		 SELECT tab_portlet_id, v_new_tab_id, customer_portlet_sid, column_num, pos, state
			 FROM tab_portlet
			WHERE tab_id = in_tab_id
	)
	LOOP
		INSERT INTO TAB_PORTLET
			(tab_portlet_id, tab_id, customer_portlet_sid, column_num, pos, state)
		VALUES
			(tab_portlet_id_seq.nextval, v_new_tab_id, r.customer_portlet_sid, r.column_num, r.pos, r.state)
		RETURNING tab_portlet_id INTO v_tab_portlet_id;
		
		INSERT INTO USER_SETTING_ENTRY
			(app_sid, csr_user_sid, category, setting, tab_portlet_id, value)
			SELECT app_sid, csr_user_sid, category, setting, v_tab_portlet_id, value
			  FROM USER_SETTING_ENTRY
			 WHERE tab_portlet_id = r.tab_portlet_id
			   AND csr_user_sid = security_pkg.getSid;
		
		INSERT INTO TAB_PORTLET_USER_REGION
			(app_sid, csr_user_sid, tab_portlet_id, region_sid)
			SELECT app_sid, csr_user_sid, v_tab_portlet_id, region_sid
			  FROM TAB_PORTLET_USER_REGION
			 WHERE tab_portlet_id = r.tab_portlet_id
			   AND csr_user_sid = security_pkg.getSid;

		-- copy any feeds
		INSERT INTO TAB_PORTLET_RSS_FEED
			(tab_portlet_id, rss_url)
			SELECT v_tab_portlet_id, rss_url
			  FROM tab_portlet_rss_feed
			 WHERE tab_portlet_id = r.tab_portlet_id;
	END LOOP;
			
	-- return cursor
	OPEN out_cur FOR
		SELECT TAB_ID, LAYOUT, NAME, IS_SHARED, IS_HIDEABLE, POS, IS_OWNER
			FROM v$TAB_USER
		 WHERE tab_id = v_new_tab_id;

END;

/**
 * Add new tab, and returns id
 *
 * @param in_app_sid		csr app sid
 * @param in_tab_name		name of tab to create
 * @param in_is_shared 		is it shared tab?
 * @param in_is_hideable 	can users hide the tab
 * @param in_layout			layout enum
 * @param out_tab_id		created Tab id
 */
PROCEDURE AddTabReturnTabId(
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_tab_name		IN	tab.name%TYPE,
	in_is_shared 	IN	tab.is_shared%TYPE,
	in_is_hideable	IN	tab.is_hideable%TYPE,
	in_layout		IN	tab.layout%TYPE,
	in_portal_group	IN	tab.portal_group%TYPE,
	out_tab_id		OUT	tab.tab_id%TYPE
)
AS
	v_user_sid	security_pkg.T_SID_ID;
	v_max_pos 	tab_user.pos%TYPE;
	v_tab_id	tab.tab_id%TYPE;
BEGIN
	v_user_sid := security_pkg.GetSID();

	SELECT NVL(MAX(pos),0)
		INTO v_max_pos
		FROM v$tab_user
	 WHERE user_sid = v_user_sid
		 AND app_sid = in_app_sid;

	-- create a new tab
	INSERT INTO TAB
		(tab_id, layout, name, app_sid, is_shared, is_hideable, portal_group)
	VALUES
		(tab_id_seq.nextval, in_layout, in_tab_name, in_app_sid, in_is_shared, in_is_hideable, in_portal_group)
	RETURNING tab_id INTO v_tab_id;

	-- make user the owner
	INSERT INTO TAB_USER
		(tab_id, user_sid, pos, is_owner)
	VALUES
		(v_tab_id, v_user_sid, v_max_pos+1, 1);
		
	out_tab_id := v_tab_id;
	
	CreateAuditLogEntry(
		in_msg			=> 'Created tab "{0}"',
		in_tab_id		=> DASHBOARD_ONLY,
		in_param_1		=> in_tab_name
	);

END;

/**
 * Add new tab, and returns Tab details
 *
 * @param in_app_sid		csr app sid
 * @param in_tab_name		name of tab to create
 * @param in_is_shared 		is it shared tab?
 * @param in_is_hideable 	can users hide the tab
 * @param in_layout			layout enum
 * @param out_cur		tab details
 */
PROCEDURE AddTab(
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_tab_name		IN	tab.name%TYPE,
	in_is_shared 	IN	tab.is_shared%TYPE,
	in_is_hideable	IN	tab.is_hideable%TYPE,
	in_layout		IN	tab.layout%TYPE,
	in_portal_group	IN	tab.portal_group%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_out_tab_id	tab.tab_id%TYPE;
BEGIN
	AddTabReturnTabId(
		in_app_sid,
		in_tab_name,
		in_is_shared,
		in_is_hideable,
		in_layout,
		in_portal_group,
		v_out_tab_id
	);
	CreateTabDescriptions(v_out_tab_id);
	-- return cursor
	OPEN out_cur FOR
		SELECT TAB_ID, LAYOUT, NAME, IS_SHARED, POS, IS_OWNER
			FROM v$TAB_USER
		 WHERE tab_id = v_out_tab_id;
END;
	
/**
 *	Set layout and name for tab
 *
 *	@param		in_tab_id			tab id
 *	@param		in_layout			layout id
 *	@param		in_name				name of tab
 *	@param		in_is_shared		is it shared tab
 *  @param		in_is_hideable		can users hide the tab
 */
PROCEDURE UpdateTab(	
	in_tab_id			IN security_pkg.T_SID_ID,
	in_layout			IN tab.layout%TYPE,
	in_name 			IN tab.name%TYPE,
	in_is_shared		IN tab.is_shared%TYPE,
	in_is_hideable		IN tab.is_hideable%TYPE,
	in_override_pos IN tab.override_pos%TYPE
)
AS
	v_user_sid		security_pkg.T_SID_ID;
	v_app_sid		security_pkg.T_SID_ID;
	v_act			security_pkg.T_ACT_ID;
	v_layout		tab.layout%TYPE;
	v_name			tab.name%TYPE;
	v_is_shared		tab.is_shared%TYPE;
	v_is_hideable	tab.is_hideable%TYPE;
	v_override_pos	tab.override_pos%TYPE;
BEGIN
	CheckTabOwner(in_tab_id);
	
	v_act := security_pkg.getACT;
	
	SELECT layout, name, is_shared, is_hideable, override_pos, app_sid
	  INTO v_layout, v_name, v_is_shared, v_is_hideable, v_override_pos, v_app_sid
	  FROM tab t
	 WHERE tab_id = in_tab_id;

	UPDATE tab SET layout = in_layout, name = in_name, is_shared = in_is_shared, is_hideable = in_is_hideable, override_pos = in_override_pos
	 WHERE tab_id = in_tab_id;

    -- show hidden tabs, when tab is made unhideable
	IF in_is_hideable = 0 AND v_is_hideable != in_is_hideable THEN
		UPDATE tab_user
		   SET is_hidden = 0
		 WHERE tab_id = in_tab_id;
	END IF;

	IF null_pkg.ne(v_layout, in_layout) OR v_layout != in_layout THEN
		csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_DASHBOARD, v_app_sid, in_tab_id, 'Layout', v_layout, in_layout, NVL(GetDashboardSid(v_app_sid, in_tab_id), DASHBOARD_HOME));
	END IF;
	
	IF null_pkg.ne(v_name, in_name) OR v_name != in_name THEN
		csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_DASHBOARD, v_app_sid, in_tab_id, 'Name', v_name, in_name, NVL(GetDashboardSid(v_app_sid, in_tab_id), DASHBOARD_HOME));
	END IF;

	IF null_pkg.ne(v_is_shared, in_is_shared) OR v_is_shared != in_is_shared THEN
		csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_DASHBOARD, v_app_sid, in_tab_id, 'Is shared', v_is_shared, in_is_shared, NVL(GetDashboardSid(v_app_sid, in_tab_id), DASHBOARD_HOME));
	END IF;

	IF null_pkg.ne(v_is_hideable, in_is_hideable) OR v_is_hideable != in_is_hideable THEN
		csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_DASHBOARD, v_app_sid, in_tab_id, 'Can be hidden', v_is_hideable, in_is_hideable, NVL(GetDashboardSid(v_app_sid, in_tab_id), DASHBOARD_HOME));
	END IF;

	IF null_pkg.ne(v_override_pos, in_override_pos) OR v_override_pos != in_override_pos THEN
		csr_data_pkg.AuditValueChange(v_act, csr_data_pkg.AUDIT_TYPE_DASHBOARD, v_app_sid, in_tab_id, 'Override', v_override_pos, in_override_pos, NVL(GetDashboardSid(v_app_sid, in_tab_id), DASHBOARD_HOME));
	END IF;
END;

PROCEDURE GetAllPortletsForCustomer(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- allow fiddling with portlets only for people with permissions on Capabilities/System management
	IF NOT csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "System management" capability');
	END IF;

	OPEN out_cur FOR
		SELECT p.portlet_id, p.name, CASE WHEN cp.app_sid IS NULL THEN 0 ELSE 1 END IS_ENABLED,
						CASE WHEN t.customer_portlet_sid IS NULL THEN 0 ELSE 1 END IS_USED
			FROM portlet p , customer_portlet cp,(
							SELECT DISTINCT customer_portlet_sid
								FROM tab_portlet
							 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						)t
		 WHERE p.portlet_id = cp.portlet_id(+)
		   AND cp.customer_portlet_sid = t.customer_portlet_sid(+)
		   AND p.portlet_id <> 0 -- Access Denied portlet
		   AND p.portlet_id NOT IN (SELECT portlet_id FROM hide_portlet WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'))
		 ORDER BY name;
END;

PROCEDURE EnablePortletForCustomer(
	in_portlet_id	IN portlet.portlet_id%TYPE
)
AS
	v_customer_portlet_sid		security_pkg.T_SID_ID;
	v_type						portlet.type%TYPE;
BEGIN
	-- allow fiddling with portlets only for people with permissions on Capabilities/System management
	IF NOT csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "System management" capability');
	END IF;
	
	SELECT type
	  INTO v_type
	  FROM portlet
	 WHERE portlet_id = in_portlet_id;
	
	BEGIN
		v_customer_portlet_sid := securableobject_pkg.GetSIDFromPath(
				SYS_CONTEXT('SECURITY','ACT'),
				SYS_CONTEXT('SECURITY','APP'),
				'Portlets/' || v_type);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'),
				securableobject_pkg.GetSIDFromPath(
					SYS_CONTEXT('SECURITY','ACT'),
					SYS_CONTEXT('SECURITY','APP'),
					'Portlets'),
				class_pkg.GetClassID('CSRPortlet'), v_type, v_customer_portlet_sid);
	END;

	BEGIN
		INSERT INTO customer_portlet
				(portlet_id, customer_portlet_sid, app_sid)
		VALUES
				(in_portlet_id, v_customer_portlet_sid, SYS_CONTEXT('SECURITY', 'APP'));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
				NULL;
	END;
END;

PROCEDURE DisablePortletForCustomer(
	in_portlet_id	IN portlet.portlet_id%TYPE
)
AS
BEGIN
	-- allow fiddling with portlets only for people with permissions on Capabilities/System management
	IF NOT csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "System management" capability');
	END IF;
	
	-- Leaving the SO so that we don't lose permissions if we re-enable the portlet.
	
	DELETE FROM customer_portlet
	 WHERE portlet_id = in_portlet_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;
/**
 * Get list of available portlets for a given customer sid
 *
 * @param		in_app_sid				The Csr Root Sid
 * @return		out_cur				Output cursor
 */
PROCEDURE GetPortletsForCustomer(
	in_app_sid			IN 	security_pkg.T_SID_ID,
	in_portal_group		IN  customer_portlet.portal_group%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT cp.customer_portlet_sid, p.portlet_id, p.name, p.type, p.default_state, p.script_path
			FROM portlet p , customer_portlet cp
		 WHERE p.portlet_id = cp.portlet_id
			 AND cp.app_sid = in_app_sid
			 AND (NVL(cp.portal_group, in_portal_group) = in_portal_group OR (cp.portal_group IS NULL AND in_portal_group IS NULL))
			 AND IsAccessAllowedPortlet(cp.customer_portlet_sid) = 1
		 ORDER BY name;
END;

/**
 * Gets a list of portlets filtered by portal type and portal group.
 *
 * @param    in_include_home_portlets		1 to include portlets marked as available on home portal
 * @param    in_include_approval_portlets	1 to include portlets marked as available on approval portals
 * @param    in_include_chain_portlets		1 to include portlets marked as available on chain portal
 * @param    in_portal_group				name of the portal group to filter to
 * @param    out_cur						Output cursor
 *
 */
PROCEDURE GetFilteredCustomerPortlets(
	in_include_home_portlets		IN portlet.available_on_home_portal%TYPE,
	in_include_approval_portlets	IN portlet.available_on_home_portal%TYPE,
	in_include_chain_portlets		IN portlet.available_on_home_portal%TYPE,
	in_portal_group					IN  customer_portlet.portal_group%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT cp.customer_portlet_sid, p.portlet_id, p.name, p.type, p.default_state, p.script_path
		  FROM customer_portlet cp
		  JOIN portlet p on p.portlet_id = cp.portlet_id
		 WHERE cp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (NVL(cp.portal_group, in_portal_group) = in_portal_group OR (cp.portal_group IS NULL AND in_portal_group IS NULL))
		   AND (
		  (in_include_home_portlets 	= 1 AND available_on_home_portal = 1) OR
		  (in_include_approval_portlets = 1 AND available_on_approval_portal = 1) OR
		  (in_include_chain_portlets 	= 1 AND available_on_chain_portal = 1))
		 ORDER BY p.name;

END;

/**
 * Get portlets for a given tab
 *
 * @param		in_app_sid				The Csr Root Sid
 * @param		in_tab_id				Tab ID
 * @return		out_cur					Output cursor
 */
PROCEDURE GetPortletsForTab(
	in_tab_id				IN	tab.tab_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_ad_type				portlet.type%TYPE;
	v_ad_script_path		portlet.script_path%TYPE;
BEGIN
	CheckTabUser(in_tab_id);
	
	v_user_sid := security_pkg.GetSID();
	
	SELECT type, script_path
	  INTO v_ad_type, v_ad_script_path
	  FROM portlet
	 WHERE portlet_id = 0;
	
	OPEN out_cur FOR
		SELECT t.name tab_name, t.layout tab_layout, tp.tab_portlet_Id, tp.column_num, tp.pos,
			   tp.state, p.portlet_id, p.name,
			   CASE WHEN IsAllowed = 1 THEN p.type ELSE v_ad_type END portlet_type,
			   CASE WHEN IsAllowed = 1 THEN p.script_path ELSE v_ad_script_path END script_path,
			   CASE WHEN us.category IS NULL THEN 0 ELSE 1 END has_registered_user_setting
		  FROM tab t, tab_portlet tp, portlet p, customer_portlet cp, (SELECT UNIQUE category FROM user_setting) us,
			   (SELECT DISTINCT customer_portlet_sid, IsAccessAllowedPortlet(customer_portlet_sid) IsAllowed
				  FROM tab_portlet
				 WHERE tab_id = in_tab_id) aa
		 WHERE t.tab_id = in_tab_id
		   AND t.tab_id = tp.tab_id
		   AND tp.customer_portlet_sid = aa.customer_portlet_sid
		   AND cp.customer_portlet_sid = tp.customer_portlet_sid
		   AND p.portlet_id = cp.portlet_id
		   AND UPPER(p.type) = us.category(+)
		 ORDER BY tp.column_num, tp.pos;
END;

PROCEDURE GetTabPortlet(
	in_tab_portlet_id		IN	tab_portlet.tab_portlet_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_tab_id				tab.tab_id%type;
	v_user_sid				security_pkg.T_SID_ID;
	v_ad_type				portlet.type%TYPE;
	v_ad_script_path		portlet.script_path%TYPE;
BEGIN
	SELECT tab_id
	  INTO v_tab_id
	  FROM tab_portlet
	 WHERE tab_portlet_id = in_tab_portlet_id;
	
	CheckTabOwner(v_tab_id);
	
	v_user_sid := security_pkg.GetSID();
	
	SELECT type, script_path
	  INTO v_ad_type, v_ad_script_path
	  FROM portlet
	 WHERE portlet_id = 0;
	
	OPEN out_cur FOR
		SELECT tp.tab_portlet_Id, p.portlet_id, p.name, tp.state,
			CASE WHEN IsAccessAllowedPortlet(tp.customer_portlet_sid) = 1 THEN p.type ELSE v_ad_type END portlet_type,
			CASE WHEN IsAccessAllowedPortlet(tp.customer_portlet_sid) = 1 THEN p.script_path ELSE v_ad_script_path END script_path
		  FROM tab_portlet tp, portlet p, customer_portlet cp
		 WHERE tp.tab_portlet_id = in_tab_portlet_id
		   AND tp.customer_portlet_sid = cp.customer_portlet_sid
		   AND cp.portlet_id = p.portlet_id;
END;

PROCEDURE AddPortletToTab(
	in_tab_id				IN	tab_portlet.tab_id%TYPE,
	in_customer_portlet_sid	IN	tab_portlet.customer_portlet_sid%TYPE,
	in_initial_state		IN	tab_portlet.state%TYPE,
	out_tab_portlet_id		OUT	tab_portlet.tab_portlet_id%TYPE
)
AS
	v_count					NUMBER(10);
BEGIN
	CheckTabOwner(in_tab_id);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM tab_portlet
	 WHERE tab_id = in_tab_id;
	
	IF v_count >= MAX_PORTLETS_PER_TAB THEN
		RAISE_APPLICATION_ERROR(-20001, 'The tab with id '||in_tab_id||' already contains the maximum number of portlets permissible ('||MAX_PORTLETS_PER_TAB||')');
	END IF;
	
	-- move all portlets in first column position below
	UPDATE TAB_PORTLET
		 SET pos = pos + 1
	 WHERE TAB_ID = in_tab_id
		 AND column_num = 0;
	
	INSERT INTO TAB_PORTLET
		(customer_portlet_sid, tab_portlet_id, tab_id, column_num, pos, state)
	VALUES	
		(in_customer_portlet_sid, tab_portlet_id_seq.nextval, in_tab_id, 0, 0, in_initial_state)
	RETURNING tab_portlet_id INTO out_tab_portlet_id;
	
	CreateAuditLogEntry(
		in_msg				=> 'Added portlet "{0}"',
		in_tab_id			=>	in_tab_id,
		in_param_1			=>  GetPortletNameFromTabPortletId(out_tab_portlet_id));
END;

--INTERNAL used in AddPortletToTab and GetPortletsForTab
FUNCTION IsAccessAllowedPortlet(
	in_sid_id			IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
BEGIN
	IF security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), in_sid_id, security_pkg.PERMISSION_READ) THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

/**
 * Add new portlet to given tab
 *
 * @param		in_act_id							Access token
 * @param		in_app_sid				The Csr Root Sid
 * @param		in_tab_Id				Tab ID
 * @param		in_portlet_Id			Portlet ID
 * @return 	 out_cur				Stuff useful to create the tab on the client
 */
PROCEDURE AddPortletToTab(
	in_tab_id						IN	tab_portlet.tab_id%TYPE,
	in_customer_portlet_sid			IN	tab_portlet.customer_portlet_sid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	--v_max_pos			tab_portlet.pos%TYPE;
	v_state				tab_portlet.state%TYPE;
	v_tab_portlet_id	tab_portlet.tab_portlet_id%TYPE;
	v_ad_type			portlet.type%TYPE;
	v_ad_script_path	portlet.script_path%TYPE;
BEGIN

	/*SELECT NVL(MAX(pos),0)
		INTO v_max_pos
		FROM tab_portlet
	 WHERE tab_id = in_tab_id;
	 */
	-- select default state for portlet, using customer_portlet.state in preference to portlet.state
	SELECT NVL(cp.default_state, p.default_state)
		INTO v_state
		FROM portlet p, customer_portlet cp, customer c, tab t
	 WHERE p.portlet_id = cp.portlet_id
		 AND cp.app_sid = c.app_sid
		 AND c.app_sid = t.app_sid
		 AND cp.customer_portlet_sid = in_customer_portlet_sid
		 AND t.tab_id = in_tab_id;
	
	AddPortletToTab(in_tab_id, in_customer_portlet_sid, v_state, v_tab_portlet_id);
	
	-- return a row set so we can do stuff to create the tab on the client
	SELECT type, script_path
	  INTO v_ad_type, v_ad_script_path
	  FROM portlet
	 WHERE portlet_id = 0;
	
	OPEN out_cur FOR
		SELECT t.name tab_name, t.layout, tp.tab_portlet_Id, tp.column_num, tp.pos, tp.state, p.portlet_id,
			p.name, CASE WHEN IsAllowed = 1 THEN p.type ELSE v_ad_type END portlet_type,
			CASE WHEN IsAllowed = 1 THEN p.script_path ELSE v_ad_script_path END script_path,
			0 has_registered_user_setting -- nothing will have been written at this point so who cares
		  FROM tab t
			JOIN tab_portlet tp ON t.tab_id = tp.tab_id
			JOIN customer_portlet cp ON tp.customer_portlet_sid = cp.customer_portlet_sid
			JOIN portlet p ON cp.portlet_id = p.portlet_Id
			JOIN (SELECT DISTINCT customer_portlet_sid, IsAccessAllowedPortlet(customer_portlet_sid) IsAllowed
				    FROM tab_portlet
				   WHERE tab_portlet_id = v_tab_portlet_id) aa ON aa.customer_portlet_sid = tp.customer_portlet_sid
		 WHERE tp.tab_portlet_id = v_tab_portlet_id;
END;

/**
 * remove portlet from given tab
 *
 * @param		in_tab_portlet_Id				Tab portlet ID
 */
PROCEDURE RemovePortlet(
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE
)
AS
	v_tab_id				security.security_pkg.T_SID_ID;
	v_portlet_name			VARCHAR2(1024);
	v_state					tab_portlet.state%TYPE;
BEGIN
	CheckTabPortletOwner(in_tab_portlet_id);
	
	SELECT tab_id, state
	  INTO v_tab_id, v_state
	  FROM tab_portlet
	 WHERE tab_portlet_Id = in_tab_portlet_id;
	
	v_portlet_name := GetPortletNameFromTabPortletId(in_tab_portlet_id);
	
	-- delete feeds if any
	DELETE FROM TAB_PORTLET_RSS_FEED
	 WHERE tab_portlet_id = in_tab_portlet_id;
	DELETE FROM TAB_PORTLET_USER_REGION
	 WHERE tab_portlet_id = in_tab_portlet_id;
	DELETE FROM USER_SETTING_ENTRY
	 WHERE tab_portlet_id = in_tab_portlet_id;
	DELETE FROM TAB_PORTLET
	 WHERE tab_portlet_id = in_tab_portlet_id;

	-- Truncating because WriteAuditLogEntryForSid uses TruncateString and it only admits up to 4000 chars.
	v_state := dbms_lob.SUBSTR(REGEXP_REPLACE(v_state,'[\{\}]',''), 3999);

	CreateAuditLogEntry(
		in_msg				=> 'Removed portlet "{0}" with state {1}',
		in_tab_id			=> v_tab_id,
		in_param_1			=> v_portlet_name,
		in_param_2			=> v_state);
END;

/**
 * Load the state of portlet
 *
 * @param		in_tab_id				Tab ID
 * @param		in_portlet_Id			Portlet ID
 */
PROCEDURE LoadState(
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckTabPortletOwner(in_tab_portlet_id);

	OPEN out_cur FOR
		SELECT state
			FROM tab_portlet
		 WHERE tab_portlet_id = in_tab_portlet_id;
END;

/**
 * Save the state of portlet
 *
 * @param		in_tab_portlet_id		Tab Portlet ID
 * @param		in_state				State JSON
 */
PROCEDURE SaveState(
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	in_state				IN	tab_portlet.STATE%TYPE
)
AS
	v_state					tab_portlet.STATE%TYPE;
	v_tab_id				security.security_pkg.T_SID_ID;
BEGIN
	CheckTabPortletOwner(in_tab_portlet_id);
	
	UPDATE tab_portlet
	   SET state = in_state
	 WHERE tab_portlet_id = in_tab_portlet_id;

	-- Used to audit the state here, but this is now done at the c# level;
END;
	
PROCEDURE SaveUserRegions (
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	in_region_sids			IN	security_pkg.T_SID_IDS
)
AS
	t_region_sids		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN
	CheckTabPortletUser(in_tab_portlet_id);
	
	DELETE FROM tab_portlet_user_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND tab_portlet_id = in_tab_portlet_id;
	  
	INSERT INTO tab_portlet_user_region
	(csr_user_sid, tab_portlet_id, region_sid)
	SELECT SYS_CONTEXT('SECURITY', 'SID'), in_tab_portlet_id, column_value
	  FROM TABLE(t_region_sids);
END;

PROCEDURE GetUserRegions (
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckTabPortletUser(in_tab_portlet_id);
	
	OPEN out_cur FOR
		SELECT region_sid
		  FROM tab_portlet_user_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND csr_user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND tab_portlet_id = in_tab_portlet_id;
END;
	
/**
 * Update the position of portlet in db
 *
 * @param		in_tab_id				Tab ID
 * @param		in_column				New Column
 * @param		in_portlet_ids			Array of tab_portlets ids (ordered from top to down)
 */
PROCEDURE UpdatePortletPosition(
	in_tab_id				IN	tab_portlet.TAB_ID%TYPE,
	in_column				IN	tab_portlet.COLUMN_NUM%TYPE,
	in_tab_portlet_ids		IN	security_pkg.T_SID_IDS
)
AS
	t_tab_portlet_ids		security.T_SID_TABLE;
	v_index					NUMBER(10);
	v_pos					tab_portlet.pos%TYPE;
	v_col					tab_portlet.column_num%TYPE;
	v_tab_name				tab.name%TYPE;
	c_to_base_one			NUMBER(1) := 1;
BEGIN
	CheckTabOwner(in_tab_id);

	t_tab_portlet_ids 	:= security_pkg.SidArrayToTable(in_tab_portlet_ids);
	v_index := 0;
	
	FOR r IN (
		SELECT column_value FROM TABLE(t_tab_portlet_ids)
	)
	LOOP
		SELECT MIN(pos), MIN(column_num)
		  INTO v_pos, v_col
		  FROM tab_portlet
		 WHERE tab_portlet_id = r.column_value;  
		 
		UPDATE TAB_PORTLET
		   SET pos = v_index, column_num = in_column
		 WHERE tab_portlet_id = r.column_value;
		
		IF null_pkg.ne(v_pos, v_index) OR v_pos != v_index OR null_pkg.ne(v_col, in_column) OR v_col != in_column THEN
			SELECT name 
			  INTO v_tab_name
			  FROM tab 
			 WHERE tab_id = in_tab_id;
			
			CreateAuditLogEntry(
				in_msg					=> 'Position changed from {0} to {1} in tab {2}',
				in_tab_id				=> in_tab_id,
				in_tab_portlet_id		=> r.column_value,
				in_param_1				=> 'C'||(v_col + c_to_base_one)||':R'||(v_pos + c_to_base_one),
				in_param_2				=> 'C'||(in_column + c_to_base_one)||':R'||(v_index + c_to_base_one),
				in_param_3				=> v_tab_name
			);
		END IF;
		
		v_index := v_index +1;
	END LOOP;
END;

	
/**
 * Update the position of tabs in db
 *
 * @param		in_tab_ids				Array of tab ids (ordered from top to down)
 */
PROCEDURE UpdateTabPosition(
	in_tab_ids				IN	security_pkg.T_SID_IDS
)
AS
	v_user_sid			security_pkg.T_SID_ID;
	t_tab_ids			security.T_SID_TABLE;
	v_index				NUMBER(10);
	v_pos				NUMBER(10);
	c_to_base_one		NUMBER(1) := 1;
BEGIN
	v_user_sid	:= security_pkg.GetSID();
	t_tab_ids	:= security_pkg.SidArrayToTable(in_tab_ids);
	v_index		:= 0;
	
	FOR r IN (
		SELECT column_value FROM TABLE(t_tab_ids)
 	)
 	LOOP
		BEGIN
				-- we always try and insert first because the tab_id might
				-- have come from the TAB_GROUP table i.e. it's not currently
				-- listed for this user in the TAB_USER table. The risk with this
				-- is that the user is then removed from a group but the row still
				-- remains in the TAB_USER table. We get round this by carefully
				-- excluding tabs when we read all the tabs out for the current user.
				INSERT INTO TAB_USER
					 (tab_id, user_sid, pos, is_owner)
				VALUES
						(r.column_value, v_user_sid, v_index, 0);
								
				csr_data_pkg.AuditValueChange(security.security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_DASHBOARD, security.security_pkg.getApp, r.column_value,
					'Position', NULL, v_index + c_to_base_one, NVL(GetDashboardSid(security.security_pkg.getApp, r.column_value), DASHBOARD_HOME));			
		EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					SELECT MIN(pos)
					  INTO v_pos
					  FROM tab_user
					 WHERE tab_id = r.column_value
					   AND user_sid = v_user_sid;
					   
					IF null_pkg.ne(v_pos, v_index) OR v_pos != v_index THEN
						csr_data_pkg.AuditValueChange(security.security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_DASHBOARD, security.security_pkg.getApp, r.column_value,
							'Position', v_pos + c_to_base_one, v_index + c_to_base_one, NVL(GetDashboardSid(security.security_pkg.getApp, r.column_value), DASHBOARD_HOME));			
					END IF;
					
					UPDATE TAB_USER
					   SET pos = v_index
					 WHERE tab_id = r.column_value
					   AND user_sid = v_user_sid;
		END;
		
		v_index := v_index + 1;
 	END LOOP;
END;

/*============================	STUFF FOR MATRIX	 ====================================================================*/

PROCEDURE GetTabMatrix(
	in_portal_group				IN	tab.portal_group%TYPE,
	out_cur_groups				OUT security_pkg.T_OUTPUT_CUR,
	out_cur_matrix				OUT security_pkg.T_OUTPUT_CUR,
	out_cur_shared_tabs			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_csr_user_group_sid				security_pkg.T_SID_ID;
	v_roles_sid							security_pkg.T_SID_ID;
	v_groups_sid						security_pkg.T_SID_ID;
BEGIN
	v_csr_user_group_sid := class_pkg.GetClassId('csrusergroup');
	v_roles_sid := class_pkg.GetClassId('csrrole');
	v_groups_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetApp,'Groups');
	OPEN out_cur_groups FOR
		SELECT t.sid_id, t.name
			FROM TABLE(securableobject_pkg.GetDescendantsAsTable(security_pkg.GetACT, v_groups_sid)) t
			LEFT JOIN role r on t.sid_id = r.role_sid
		 WHERE t.class_id in (security_pkg.SO_GROUP, v_csr_user_group_sid, v_roles_sid)
		   AND t.NAME NOT IN ('RegisteredUsers')
		   AND NVL(r.is_hidden, 0) = 0;

	OPEN out_cur_matrix FOR
		SELECT tg.group_sid, tg.tab_id	
		  FROM tab_group tg, tab t
		 WHERE tg.tab_id = t.tab_id
		   AND t.app_sid = security_pkg.GetApp
		   AND is_shared = 1
		   AND (t.portal_group = in_portal_group OR t.portal_group IS NULL AND in_portal_group IS NULL);

	OPEN out_cur_shared_tabs FOR
		SELECT t.tab_id, t.name, stragg(full_name) users
		  FROM tab t
		  JOIN tab_user tu ON t.tab_id = tu.tab_id
		  JOIN csr_user cu ON tu.user_sid = cu.csr_user_sid
		 WHERE t.app_sid = security_pkg.GetApp
		   AND is_shared = 1
		   AND is_owner = 1
		   AND (t.portal_group = in_portal_group OR t.portal_group IS NULL AND in_portal_group IS NULL)
		 GROUP BY t.tab_id, t.name;
END;

PROCEDURE SetTabsForGroup(	
	in_portal_group		IN  tab.portal_grouP%TYPE,
	in_group_sid		IN	security_pkg.T_SID_ID,
	in_tab_sids			IN	security_pkg.T_SID_IDS
)
AS
	t_items				security.T_SID_TABLE;
	v_removed_tabs		security.security_pkg.T_SID_IDS;
	v_added_tabs		security.security_pkg.T_SID_IDS;
	t_removed_tabs		security.T_SID_TABLE;
	t_added_tabs		security.T_SID_TABLE;
	v_tab_name			VARCHAR2(1024);
BEGIN
	
	t_items := security_Pkg.SidArrayToTable(in_tab_sids);
	
	SELECT tg.tab_id
	  BULK COLLECT INTO v_removed_tabs
	  FROM tab_group tg
	  JOIN tab t ON tg.tab_id = t.tab_id
	 WHERE group_sid = in_group_sid
	   AND NOT EXISTS (SELECT NULL FROM TABLE(t_items) i WHERE i.column_value = tg.tab_id)
	   AND (portal_group = in_portal_group OR (portal_group IS NULL AND in_portal_group IS NULL));
	
	SELECT t.column_value
	  BULK COLLECT INTO v_added_tabs
	  FROM TABLE(t_items) t
	 WHERE NOT EXISTS (SELECT NULL
						 FROM tab_group tg
						 JOIN tab nt ON tg.tab_id = nt.tab_id
						WHERE t.column_value = tg.tab_id
						  AND group_sid = in_group_sid
						  AND (portal_group = in_portal_group OR (portal_group IS NULL AND in_portal_group IS NULL))
	);
		
	-- delete everything
	DELETE FROM tab_group
	 WHERE GROUP_SID = IN_GROUP_SID
	   AND tab_id IN (
		SELECT tab_id
		  FROM tab
		  WHERE (portal_group = in_portal_group OR (portal_group IS NULL AND in_portal_group IS NULL))
	  );
	
	-- add tabs
	INSERT INTO tab_group (group_sid, tab_id)
	SELECT in_group_sid group_sid, column_value
	  FROM TABLE(t_items);
	
	t_removed_tabs := security_Pkg.SidArrayToTable(v_removed_tabs);
	
	FOR R IN (SELECT column_value id FROM TABLE(t_removed_tabs))
	LOOP
		SELECT name
		  INTO v_tab_name
		  FROM tab
		 WHERE tab_id = r.id;
		
		CreateAuditLogEntry(
			in_msg					=> 'Tab "{0}" removed from group "{1}" ({2})',
			in_tab_id				=> r.id,
			in_param_1				=> v_tab_name,
			in_param_2				=> security.securableobject_pkg.GetName(security.security_pkg.getACT, in_group_sid),
			in_param_3				=> in_group_sid
		);
	END LOOP;
	
	t_added_tabs := security_Pkg.SidArrayToTable(v_added_tabs);
	
	FOR R IN (SELECT column_value id FROM TABLE(t_added_tabs))
	LOOP
		SELECT name
		  INTO v_tab_name
		  FROM tab
		 WHERE tab_id = r.id;
		
		CreateAuditLogEntry(
			in_msg					=> 'Tab "{0}" added to group "{1}" ({2})',
			in_tab_id				=> r.id,
			in_param_1				=> v_tab_name,
			in_param_2				=> security.securableobject_pkg.GetName(security.security_pkg.getACT, in_group_sid),
			in_param_3				=> in_group_sid
		);
	END LOOP;
	
END;

PROCEDURE AddTabForGroup(	
	in_group_sid		IN	security_pkg.T_SID_ID,
	in_tab_id			IN	tab.tab_id%TYPE
)
AS
	t_items				security.T_SID_TABLE;
	v_tab_name			VARCHAR2(1024);
BEGIN
	-- add tabs
	BEGIN
		INSERT INTO tab_group (group_sid, tab_id)
		VALUES (in_group_sid, in_tab_id);
		
		SELECT name
		  INTO v_tab_name
		  FROM tab
		 WHERE tab_id = in_tab_id;
		
		CreateAuditLogEntry(
			in_msg					=> 'Tab "{0}" added to group "{1}" ({2})',
			in_tab_id				=> in_tab_id,
			in_param_1				=> v_tab_name,
			in_param_2				=> security.securableobject_pkg.GetName(security.security_pkg.getACT, in_group_sid),
			in_param_3				=> in_group_sid
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

END;

/*=====================================================================================================================*/
/**
 * Update show info msg on start
 * @param	user_sid		IN csr_user.CSR_USER_SID,
 * @param 	in_show_info 	IN csr_user.SHOW_PORTAL_HELP%TYPE
 */
PROCEDURE ToggleShowHelp(
	in_show_info 	IN csr_user.SHOW_PORTAL_HELP%TYPE
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	v_user_sid := security_pkg.GetSID();
	
	UPDATE csr_user
		 SET show_portal_help = in_show_info
	 WHERE csr_user_sid = v_user_sid;
END;

/**
 * Get value to show or not the help box
 * @return	in_show_info 	IN csr_user.SHOW_PORTAL_HELP%TYPE
 */
PROCEDURE GetShowHelp(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	v_user_sid := security_pkg.GetSID();
	
	OPEN out_cur FOR
		SELECT show_portal_help
			FROM csr_user
		 WHERE csr_user_sid = v_user_sid;
END;

PROCEDURE UNSECURED_DeleteTab(
	in_tab_id	IN	tab.tab_id%TYPE
)
AS
	v_tab_name	VARCHAR2(1024);
BEGIN
	-- we don't delete the users here - kind of sanity check that people are calling DeleteTab.
	-- Then again - what's the point of UNSECURED_DeleteTab?
	DELETE FROM APPROVAL_DASHBOARD_TAB
	 WHERE tab_id = in_tab_id;
	
	DELETE FROM tab_user
	 WHERE tab_id = in_tab_id;
	
	-- delete child constraints if any
	-- feeds
	DELETE FROM tab_portlet_rss_feed WHERE tab_portlet_id IN (
		SELECT tab_portlet_id FROM tab_portlet WHERE tab_id = in_tab_id
	);
	-- group
	DELETE FROM tab_group WHERE tab_id = in_tab_id;

	DELETE FROM tab_portlet_user_region WHERE tab_portlet_id IN (
		SELECT tab_portlet_id FROM tab_portlet WHERE tab_id = in_tab_id
	);
	
	DELETE FROM user_setting_entry WHERE tab_portlet_id IN (
		SELECT tab_portlet_id FROM tab_portlet WHERE tab_id = in_tab_id
	);
	
	DELETE FROM tab_portlet WHERE tab_id = in_tab_id;
	
	SELECT name
	  INTO v_tab_name
	  FROM tab
	 WHERE tab_id = in_tab_id;
	
	DELETE FROM tab_description WHERE tab_id = in_tab_id;
	
	DELETE FROM tab WHERE tab_id = in_tab_id;
	
	CreateAuditLogEntry(
		in_msg					=> 'Tab "{0}" deleted',
		in_tab_id				=> DASHBOARD_ONLY,
		in_param_1				=> v_tab_name
	);
END;

PROCEDURE HideTab(
	in_tab_id			IN	tab.tab_id%TYPE
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	v_user_sid := security_pkg.GetSID();
	CheckTabUser(in_tab_id);

	BEGIN
		INSERT INTO TAB_USER(tab_id, user_sid, pos, is_owner, is_hidden)
			SELECT in_tab_id, v_user_sid, pos, 0, 1
			  FROM TAB_USER 
			 WHERE TAB_ID = in_tab_id 
			   AND is_owner = 1;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE TAB_USER
				   SET is_hidden = 1
				 WHERE tab_id = in_tab_id
				   AND user_sid = v_user_sid;
	END;
END;

PROCEDURE DeleteTab(
	in_tab_id			IN	tab.tab_id%TYPE
)
AS
BEGIN
	DeleteTab(in_tab_id, 0);
END;

PROCEDURE DeleteTab(
	in_tab_id			IN	tab.tab_id%TYPE,
	in_force_delete		IN  NUMBER
)
AS
	v_cnt			NUMBER(10);
	v_user_sid		security_pkg.T_SID_ID;
	v_is_shared		NUMBER(1);
	v_tab_name		VARCHAR2(1024);
BEGIN
	v_user_sid := security_pkg.GetSID();
	
	CheckTabOwner(in_tab_id);
	
	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END is_shared INTO v_is_shared
		FROM TAB_GROUP
	 WHERE tab_id = in_tab_id;

	 -- we actually hide tab if it's shared, so in that case user can show them back when necessary
	 IF v_is_shared = 1 AND in_force_delete = 0 THEN
		-- that means we want to hide the tab
		HideTab(in_tab_id);
			
		SELECT name
		  INTO v_tab_name
		  FROM tab
		 WHERE tab_id = in_tab_id;
		
		CreateAuditLogEntry(
			in_msg					=> 'Tab removed from user',
			in_tab_id				=> in_tab_id
		);
	 ELSE
		-- ok, this isn't shared tab (or we really want to delete it) so just delete it
		UNSECURED_DeleteTab(in_tab_id);
	 END IF;

END;

PROCEDURE GetPortalGroups(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	-- Where the portal_group is backed by a portal dashboard SO, the user must have write access to the dashboard
	OPEN out_cur FOR
		SELECT DISTINCT(t.portal_group), pd.PORTAL_SID,
			CASE WHEN pd.portal_sid IS NOT NULL THEN security_pkg.sql_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), portal_sid, security.security_pkg.PERMISSION_WRITE) ELSE 1 END can_manage_tabs
		  FROM tab t
		  LEFT JOIN portal_dashboard pd ON pd.portal_group = t.portal_group
		WHERE is_shared = 1;
END;

PROCEDURE ChangeRssFeed(
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	in_rss_url				IN 	tab_portlet_rss_feed.RSS_URL%TYPE
)
AS
	v_cnt		NUMBER(10);
	v_rss		tab_portlet_rss_feed.RSS_URL%TYPE;
	v_tab_id	security.security_pkg.T_SID_ID;
BEGIN
	-- check if we need to create new entry or update existing
	SELECT COUNT(*)
		INTO v_cnt
		FROM tab_portlet_rss_feed
	 WHERE tab_portlet_id = in_tab_portlet_id;
	-- then delete it completely
	
	SELECT tab_id
	  INTO v_tab_id
	  FROM tab_portlet tp
	 WHERE tp.tab_portlet_id = in_tab_portlet_id;
	
	IF v_cnt = 0 THEN
		INSERT INTO tab_portlet_rss_feed
				(rss_url, tab_portlet_id)
			 VALUES
				(in_rss_url, in_tab_portlet_id);
	ELSE		
		SELECT rss_url
		  INTO v_rss
		  FROM tab_portlet_rss_feed tprf
		 WHERE tprf.tab_portlet_id = in_tab_portlet_id;
	
		UPDATE tab_portlet_rss_feed
			 SET rss_url = in_rss_url
		 WHERE tab_portlet_id = in_tab_portlet_id;
	END IF;
	
	IF null_pkg.ne(v_rss, in_rss_url) OR v_rss != in_rss_url THEN
		csr_data_pkg.AuditValueChange(
			security.security_pkg.getACT,
			csr_data_pkg.AUDIT_TYPE_PORTLET,
			security.security_pkg.getApp,
			in_tab_portlet_id,
			'RSS URL',
			v_rss,
			in_rss_url,
			NVL(GetDashboardSid(security.security_pkg.getApp, v_tab_id), DASHBOARD_HOME)
		);
	END IF;
END;

PROCEDURE GetRssFeed(
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT rc.xml, rc.last_updated, rc.rss_url
			FROM rss_cache rc, tab_portlet_rss_feed tprs
		 WHERE rc.rss_url = tprs.rss_url
			 AND tab_portlet_id = in_tab_portlet_id;
END;

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
) AS	
BEGIN
	DELETE FROM user_setting_entry
	 WHERE tab_portlet_id in (
		SELECT tab_portlet_id
		  FROM tab_portlet
	     WHERE customer_portlet_sid = in_sid_id
	 );
	
	DELETE FROM tab_portlet
	 WHERE customer_portlet_sid = in_sid_id;
	
	DELETE FROM customer_portlet
	 WHERE customer_portlet_sid = in_sid_id;
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

PROCEDURE DashboardAuditLogReport(
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can generate audit log reports') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can generate audit log reports" capability');
	END IF;
	
	OPEN out_cur FOR
		SELECT NVL(pd.portal_group, 'Home') dashboard, al.audit_date action_date, aut.label action_type, NVL(csru.full_name, 'Unknown') username,
			   CASE 
				   WHEN al.object_sid = DASHBOARD_ONLY THEN 'Dashboard'
				   WHEN tp.state IS NOT NULL THEN JSON_VALUE(tp.state, '$.portletTitle')||' ('||so.name||')'
				   ELSE NVL(t.name, 'Unknown')
			   END action_target,
			   REPLACE(REPLACE(REPLACE(al.description, '{0}', al.param_1), '{1}', al.param_2), '{2}', al.param_3) action_desc
		  FROM audit_log al
		  JOIN audit_type aut ON al.audit_type_id = aut.audit_type_id	  
		  LEFT JOIN tab t ON al.object_sid = t.tab_id
		  LEFT JOIN portal_dashboard pd ON al.sub_object_id = pd.portal_sid
		  LEFT JOIN csr_user csru ON al.user_sid = csru.csr_user_sid
		  LEFT JOIN tab_portlet tp ON tp.tab_portlet_id = al.object_sid
		  LEFT JOIN SECURITY.securable_object so ON tp.customer_portlet_sid = so.sid_id
		 WHERE al.audit_date >= in_start_dtm
		   AND al.audit_date < in_end_dtm
		   AND al.app_sid = security.security_pkg.GetApp
		   AND al.audit_type_id IN (csr_data_pkg.AUDIT_TYPE_PORTLET, csr_data_pkg.AUDIT_TYPE_DASHBOARD)
		 ORDER BY audit_date DESC;
END;

PROCEDURE UNSEC_AuditPortletState(
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	in_name					IN	VARCHAR2,
	in_oldval				IN	VARCHAR2,
	in_newval				IN	VARCHAR2
)
AS
	v_tab_id				security.security_pkg.T_SID_ID;
BEGIN
	SELECT tab_id
	  INTO v_tab_id
 	  FROM tab_portlet
	 WHERE tab_portlet_Id = in_tab_portlet_id;

	csr_data_pkg.AuditValueChange(
		security.security_pkg.getACT,
		csr_data_pkg.AUDIT_TYPE_PORTLET,
		security.security_pkg.getApp,
		in_tab_portlet_Id,
		in_name,
		in_oldval,
		in_newval,
		NVL(GetDashboardSid(security.security_pkg.getApp, v_tab_id), DASHBOARD_HOME)
	);	
END;

END portlet_pkg;
/
