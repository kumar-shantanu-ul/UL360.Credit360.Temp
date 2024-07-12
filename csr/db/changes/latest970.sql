-- Please update version.sql too -- this keeps clean builds in sync
define version=970
@update_header


-- junk this
alter table csr.tab_portlet drop column portlet_id_old;

/* PORTLET BODY PACKAGE -- MUST COMPILE FOR THE NEXT BIT TO WORK */

CREATE OR REPLACE PACKAGE BODY CSR.portlet_pkg IS


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
			SELECT DISTINCT tab_id, layout, name, is_shared, pos, null override_pos,
				CASE WHEN v_is_owner = 1 THEN 1 ELSE is_owner END is_owner -- pretend we're the owner if we've got 'manage any portal' capability
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
			SELECT DISTINCT x.tab_id, layout, name, 1 is_shared, NVL(t.override_pos,NVL(tu.pos,99)) pos, t.override_pos, v_is_owner is_owner
				FROM (
					SELECT tab_id
						FROM TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT))y, TAB_GROUP tg
					 WHERE tg.group_sid = y.column_value
					 MINUS
					SELECT tab_id
						FROM tab_user
					 WHERE user_sid = security_pkg.GetSID
			)x, TAB t, tab_user tu, tab_group tg
			 WHERE x.tab_id = t.tab_id
				 AND t.tab_id = tu.tab_id(+)
				 AND t.tab_id = tg.tab_id(+) 
				 AND tu.user_sid(+) = security_pkg.GetSID
				 AND (t.portal_group = in_portal_group OR (t.portal_group IS NULL AND in_portal_group IS NULL))
		ORDER BY POS, NAME;
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
			SELECT TAB_ID, NAME
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
	
	UPDATE TAB_USER
		 SET is_hidden = 0
	 WHERE tab_id = in_tab_id 
		 AND user_sid = v_user_sid;
	 
	OPEN out_cur FOR
		SELECT TAB_ID, LAYOUT, NAME, IS_SHARED, POS, IS_OWNER
			FROM v$TAB_USER
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
	AddTabReturnTabId(in_app_sid, v_tab_name, 0, v_tab_layout, v_tab_portal_group, v_new_tab_id);	

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
		SELECT TAB_ID, LAYOUT, NAME, IS_SHARED, POS, IS_OWNER
			FROM v$TAB_USER
		 WHERE tab_id = v_new_tab_id;
END;


/**
 * Add new tab, and returns id
 *
 * @param in_app_sid		csr app sid
 * @param in_tab_name		name of tab to create
 * @param in_is_shared 		is it shared tab?
 * @param in_layout			layout enum
 * @param out_tab_id		created Tab id
 */
PROCEDURE AddTabReturnTabId(
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_tab_name		IN	tab.name%TYPE,
	in_is_shared 	IN	tab.is_shared%TYPE,
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
		(tab_id, layout, name, app_sid, is_shared, portal_group)
	VALUES 
		(tab_id_seq.nextval, in_layout, in_tab_name, in_app_sid, in_is_shared, in_portal_group)
	RETURNING tab_id INTO v_tab_id;

	-- make user the owner
	INSERT INTO TAB_USER
		(tab_id, user_sid, pos, is_owner)
	VALUES
		(v_tab_id, v_user_sid, v_max_pos+1, 1);
		
	out_tab_id := v_tab_id;

END;

/**
 * Add new tab, and returns Tab details
 *
 * @param in_app_sid		csr app sid
 * @param in_tab_name		name of tab to create
 * @param in_is_shared 		is it shared tab?
 * @param in_layout			layout enum
 * @param out_cur		tab details
 */
PROCEDURE AddTab(
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_tab_name		IN	tab.name%TYPE,
	in_is_shared 	IN	tab.is_shared%TYPE,
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
		in_layout,
		in_portal_group,
		v_out_tab_id
	);
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
 */
PROCEDURE UpdateTab(	
	in_tab_id			IN security_pkg.T_SID_ID, 
	in_layout			IN tab.layout%TYPE,
	in_name 			IN tab.name%TYPE,
	in_is_shared		IN tab.is_shared%TYPE,
	in_override_pos IN tab.override_pos%TYPE
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	CheckTabOwner(in_tab_id);
	
	UPDATE tab SET layout = in_layout, name = in_name, is_shared = in_is_shared, override_pos = in_override_pos
		WHERE tab_id = in_tab_id;
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
 * Get portlets for a given tab
 *
 * @param		in_app_sid				The Csr Root Sid 
 * @param		in_tab_Id				Tab ID
 * @return		out_cur				Output cursor
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
	CheckTabOwner(in_tab_id);
	
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

PROCEDURE AddPortletToTab(
	in_tab_id				IN	tab_portlet.tab_id%TYPE,
	in_customer_portlet_sid	IN	tab_portlet.customer_portlet_sid%TYPE,
	in_initial_state		IN	tab_portlet.state%TYPE,
	out_tab_portlet_id		OUT	tab_portlet.tab_portlet_id%TYPE
)
AS
BEGIN
	CheckTabOwner(in_tab_id);
	
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
BEGIN
	CheckTabPortletOwner(in_tab_portlet_id);
	
	-- delete feeds if any
	DELETE FROM TAB_PORTLET_RSS_FEED
	 WHERE tab_portlet_id = in_tab_portlet_id;
	DELETE FROM TAB_PORTLET_USER_REGION
	 WHERE tab_portlet_id = in_tab_portlet_id;
	DELETE FROM USER_SETTING_ENTRY 
	 WHERE tab_portlet_id = in_tab_portlet_id;
	DELETE FROM TAB_PORTLET 
	 WHERE tab_portlet_id = in_tab_portlet_id;
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
BEGIN
	CheckTabPortletOwner(in_tab_portlet_id);

	UPDATE tab_portlet 
		 SET state = in_state
	 WHERE tab_portlet_id = in_tab_portlet_id;
	
END;
	
PROCEDURE SaveUserRegions (
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	in_region_sids			IN	security_pkg.T_SID_IDS
)
AS
	t_region_sids		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN
	CheckTabPortletOwner(in_tab_portlet_id);
	
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
	CheckTabPortletOwner(in_tab_portlet_id);
	
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
	in_column							 IN	tab_portlet.COLUMN_NUM%TYPE,
	in_tab_portlet_ids		IN	security_pkg.T_SID_IDS
)
AS
	t_tab_portlet_ids		security.T_SID_TABLE;
	v_index					NUMBER(10);
BEGIN
	CheckTabOwner(in_tab_id);

	t_tab_portlet_ids 	:= security_pkg.SidArrayToTable(in_tab_portlet_ids);
	v_index := 0;
	
	FOR r IN (
		SELECT column_value FROM TABLE(t_tab_portlet_ids)
	)
	LOOP
		UPDATE TAB_PORTLET
			 SET pos = v_index, column_num = in_column
		 WHERE tab_portlet_id = r.column_value;
						
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
		EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
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
		SELECT sid_id, name 
			FROM TABLE(securableobject_pkg.GetDescendantsAsTable(security_pkg.GetACT, v_groups_sid)) 
		 WHERE class_id in (security_pkg.SO_GROUP, v_csr_user_group_sid, v_roles_sid)
				AND NAME NOT IN ('RegisteredUsers');

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
BEGIN
	 
	t_items := security_Pkg.SidArrayToTable(in_tab_sids);
	
	
	-- delete everything
	delete from tab_group
	where group_sid = in_group_sid
	  and tab_id in (
		SELECT tab_id 
		  FROM tab 
		  WHERE (portal_group = in_portal_group OR (portal_group IS NULL AND in_portal_group IS NULL))
	  );
	
	-- add tabs
	insert into tab_group (group_sid, tab_id) 
	select in_group_sid group_sid, column_value from table(t_items);
	
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
BEGIN
	-- we don't delete the users here - kind of sanity check that people are calling DeleteTab.
	-- Then again - what's the point of UNSECURED_DeleteTab?
	DELETE FROM APPROVAL_DASHBOARD_TAB
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
	DELETE FROM tab WHERE tab_id = in_tab_id;
END;

PROCEDURE DeleteTab(
	in_tab_id	IN	tab.tab_id%TYPE
)
AS
	v_cnt		NUMBER(10);
	v_user_sid	security_pkg.T_SID_ID;
	v_is_shared		NUMBER(1);
BEGIN
	v_user_sid := security_pkg.GetSID();
	
	CheckTabOwner(in_tab_id);
	
	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END is_shared INTO v_is_shared
		FROM TAB_GROUP
	 WHERE tab_id = in_tab_id;
	 
	 
	 -- we actually hide tab if it's shared, so in that case user can show them back when necessary
	 IF v_is_shared = 1 THEN
			BEGIN
			-- that means we want to hide the tab
			-- make entry in tab_user if it's not there already, otherwise just update
					INSERT INTO TAB_USER
						 (tab_id, user_sid, pos, is_owner, is_hidden)
					SELECT in_tab_id, v_user_sid, pos, 0, 1
					FROM TAB_USER where TAB_ID = in_tab_id and is_owner = 1;
			EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
							UPDATE TAB_USER
								 SET is_hidden = 1
							 WHERE tab_id = in_tab_id
								 AND user_sid = v_user_sid;	 
			END;
	 ELSE
			-- ok, this isn't shared tab, so just delete it
			DELETE FROM tab_user 
			 WHERE tab_id = in_tab_id;

			UNSECURED_DeleteTab(in_tab_id);
	 END IF;
	
 
END;	

PROCEDURE GetPortalGroups(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no security but there's nothing exciting to be revealed by this list
	OPEN out_cur FOR
		SELECT DISTINCT portal_group
		  FROM tab 
		 WHERE is_shared = 1;
END;



PROCEDURE ChangeRssFeed(
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	in_rss_url				IN 	tab_portlet_rss_feed.RSS_URL%TYPE
)
AS
	v_cnt		NUMBER(10);
BEGIN
	-- check if we need to create new entry or update existing
	SELECT COUNT(*)
		INTO v_cnt
		FROM tab_portlet_rss_feed
	 WHERE tab_portlet_id = in_tab_portlet_id;
	-- then delete it completely
	
	
	IF v_cnt = 0 THEN
		INSERT INTO tab_portlet_rss_feed 
				(rss_url, tab_portlet_id) 
			 VALUES
				(in_rss_url, in_tab_portlet_id);
	ELSE
		UPDATE tab_portlet_rss_feed 
			 SET rss_url = in_rss_url
		 WHERE tab_portlet_id = in_tab_portlet_id;
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
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
) AS   
BEGIN		 
	NULL;
END;

END portlet_pkg;
/



-- on my dev db I had duplicate portlets so sort that out
begin
	for r in (
		select * 
		  from (
			select row_number() over (partition by type order by portlet_id) rn, portlet_id, name,
				min(portlet_id) over (partition by type) keep_portlet_id
			  from csr.portlet 
		  )
		 where rn > 1
	)
	loop
		dbms_output.put_line('cleaning up dupe instance of '||r.name);
		update csr.customer_portlet set portlet_id = r.keep_portlet_id where portlet_id = r.portlet_id;
		delete from csr.portlet where portlet_id = r.portlet_id;
	end loop;
	security.user_pkg.logonadmin;
	for r in (
		select * 
		  from (
			select row_number() over (partition by app_sid, portlet_id order by customer_portlet_sid) rn, customer_portlet_sid
			  from csr.customer_portlet 
		  )
		 where rn > 1
	)
	loop
		dbms_output.put_line('cleaning up sec obj '||r.customer_portlet_sid);
		security.securableobject_pkg.deleteso(security.security_pkg.getact, r.customer_portlet_sid);
	end loop;
end;
/

-- rename the sec objects sensibly
begin
	for r in (
		select portlet_id, type from csr.portlet
	)
	loop
		update security.securable_object 
		   set name = r.type
		  where sid_id in (
			 select customer_portlet_sid from csr.customer_portlet where portlet_id = r.portlet_id
		  );
	end loop;
end;
/

CREATE UNIQUE INDEX CSR.UK_PORTLET ON CSR.PORTLET(UPPER(TYPE));


@update_tail
