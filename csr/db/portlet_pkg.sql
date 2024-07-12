CREATE OR REPLACE PACKAGE CSR.portlet_pkg IS

/**
 * Get our tabs
 *
 * @param    in_app_sid      CSR app sid
 * @param    out_cur         Tab details
 *
 */
PROCEDURE GetTabs(
	in_app_sid		IN  security_pkg.T_SID_ID,
	in_portal_group	IN	tab.portal_group%TYPE,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateTabDescriptions(
	in_tab_id 		IN tab_description.tab_id%TYPE
);

PROCEDURE GetTabTitles(
	in_tab_id 		IN tab_description.tab_id%TYPE,
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE SaveTabTitle(
	in_tab_id 		IN tab_description.tab_id%TYPE,
	in_lang			IN tab_description.lang%TYPE,
	in_description	IN tab_description.description%TYPE
);

PROCEDURE GetScriptFiles(
	in_tab_ids		IN	security_pkg.T_SID_IDS,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHiddenTabs(
  out_cur     OUT security_pkg.T_OUTPUT_CUR
);



PROCEDURE ShowHiddenTab(
  in_tab_id   IN  security_pkg.T_SID_ID,
  out_cur     OUT security_pkg.T_OUTPUT_CUR
);
 

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
	in_app_sid		IN  security_pkg.T_SID_ID,
	in_tab_name		IN	tab.name%TYPE,
	in_is_shared 	IN	tab.is_shared%TYPE,
	in_is_hideable	IN	tab.is_hideable%TYPE,
	in_layout		IN  tab.layout%TYPE,
	in_portal_group	IN	tab.portal_group%TYPE,
	out_tab_id		OUT	tab.tab_id%TYPE
);

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
	in_app_sid		IN  security_pkg.T_SID_ID,
	in_tab_name		IN	tab.name%TYPE,
	in_is_shared 	IN	tab.is_shared%TYPE,
	in_is_hideable	IN	tab.is_hideable%TYPE,
	in_layout		IN  tab.layout%TYPE,
	in_portal_group	IN	tab.portal_group%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);


/**
 * Associates user with shared tab  
 * In fact is making readonly copy of tab
 *
 * @param in_tab_id	  		csr app sid
 * @param in_app_sid		name of tab to create
 * @param out_cur		tab details
 */


/**
 * Unassociate user from shared tab  
 *
 * @param in_tab_id	  		csr app sid
 */
PROCEDURE RemoveSharedTab(
	in_tab_id	IN	tab.tab_id%TYPE
);

/**
 * Duplicates shared tab to have writeable copy
 *
 * @param in_tab_id	  		csr app sid
 */
PROCEDURE CopyTab(
	in_app_sid		IN  security_pkg.T_SID_ID,
	in_tab_id	    IN tab.TAB_ID%TYPE,
	out_cur	      OUT	security_pkg.T_OUTPUT_CUR
);

/**
 *  Set layout and name for tab
 *
 *  @param		in_tab_id			tab id
 *  @param		in_layout			layout id 
 *  @param		in_name				name of tab
 *  @param		in_is_shared		is it shared tab
 *	@param 		in_is_hideable		can users hide the tab
 */
PROCEDURE UpdateTab(	
	in_tab_id			IN security_pkg.T_SID_ID, 
	in_layout			IN tab.layout%TYPE,
	in_name 			IN tab.name%TYPE,
	in_is_shared		IN tab.is_shared%TYPE,
	in_is_hideable		IN tab.is_hideable%TYPE,
	in_override_pos IN tab.override_pos%TYPE
);

/**
 * Get portlets that are available for the given customer
 *
 * @param    in_app_sid      CSR root sid
 * @param    out_cur              Tab details
 *
 */
PROCEDURE GetPortletsForCustomer(
	in_app_sid			IN 	security_pkg.T_SID_ID,
	in_portal_group		IN  customer_portlet.portal_group%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/**
 * Get portlets summary for customer, with information
 * if portlets are used and enabled for customer
 *
 * @param    out_cur              details
 *
 */
PROCEDURE GetAllPortletsForCustomer(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Enables specific portlet for customer
 *
 * @param    in_portlet_id		id of portlet to enable
 *
 */
PROCEDURE EnablePortletForCustomer(
	in_portlet_id	IN portlet.portlet_id%TYPE
);

/**
 * Disables specific portlet for customer
 *
 * @param    in_portlet_id		id of portlet to disable
 *
 */
PROCEDURE DisablePortletForCustomer(
	in_portlet_id	IN portlet.portlet_id%TYPE
);

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
);

/**
 * Get portlets for a given tab
 *
 * @param    in_tab_Id				Tab ID
 * @param    out_cur				Output cursor
 */
PROCEDURE GetPortletsForTab(
	in_tab_id				IN	tab.tab_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTabPortlet(
	in_tab_portlet_id		IN	tab_portlet.tab_portlet_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddPortletToTab(
	in_tab_id				IN	tab_portlet.tab_id%TYPE,
	in_customer_portlet_sid	IN	tab_portlet.customer_portlet_sid%TYPE,
	in_initial_state		IN	tab_portlet.state%TYPE,
	out_tab_portlet_id		OUT	tab_portlet.tab_portlet_id%TYPE
);

FUNCTION IsAccessAllowedPortlet(
	in_sid_id			IN security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE AddPortletToTab(
	in_tab_id				IN	tab_portlet.tab_id%TYPE,
	in_customer_portlet_sid	IN	tab_portlet.customer_portlet_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemovePortlet(
	in_tab_portlet_id		IN  tab_portlet.TAB_PORTLET_ID%TYPE
);

PROCEDURE LoadState(
	in_tab_portlet_id		IN  tab_portlet.TAB_PORTLET_ID%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveState(
	in_tab_portlet_id		IN  tab_portlet.TAB_PORTLET_ID%TYPE,
	in_state				IN	tab_portlet.STATE%TYPE
);

PROCEDURE SaveUserRegions (
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	in_region_sids			IN	security_pkg.T_SID_IDS
);

PROCEDURE GetUserRegions (
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);
	
/**
 * Update the position of portlet in db
 *
 * @param    in_tab_id				Tab ID
 * @param    in_column				New Column
 * @param    in_portlet_ids			Array of portlets ids (ordered from top to down)
 */
PROCEDURE UpdatePortletPosition(
	in_tab_id				IN  tab_portlet.TAB_ID%TYPE,
	in_column				IN  tab_portlet.COLUMN_NUM%TYPE,
	in_tab_portlet_ids		IN	security_pkg.T_SID_IDS
);

/**
 * Update the position of tabs in db
 *
 * @param    in_tab_ids				Array of tab ids (ordered from top to down)
 */
PROCEDURE UpdateTabPosition(
	in_tab_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE ToggleShowHelp(
	in_show_info 	IN csr_user.SHOW_PORTAL_HELP%TYPE
);

PROCEDURE GetShowHelp(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE UNSECURED_DeleteTab(
	in_tab_id	IN	tab.tab_id%TYPE
);

PROCEDURE HideTab(
	in_tab_id	IN	tab.tab_id%TYPE
);

PROCEDURE DeleteTab(
	in_tab_id	IN	tab.tab_id%TYPE
);

PROCEDURE DeleteTab(
	in_tab_id			IN	tab.tab_id%TYPE,
	in_force_delete		IN  NUMBER
);

/*============================  STUFF FOR MATRIX   ====================================================================*/

PROCEDURE GetPortalGroups(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTabMatrix(
	in_portal_group				IN	tab.portal_group%TYPE,
	out_cur_groups				OUT security_pkg.T_OUTPUT_CUR,
	out_cur_matrix				OUT security_pkg.T_OUTPUT_CUR,
	out_cur_shared_tabs			OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE SetTabsForGroup(
	in_portal_group		IN  tab.portal_grouP%TYPE,
    in_group_sid      IN	security_pkg.T_SID_ID,
    in_tab_sids       IN	security_pkg.T_SID_IDS
);

PROCEDURE AddTabForGroup(	
	in_group_sid		IN	security_pkg.T_SID_ID,
	in_tab_id			IN	tab.tab_id%TYPE
);
/*=====================================================================================================================*/

PROCEDURE ChangeRssFeed(
	in_tab_portlet_id		IN  tab_portlet.TAB_PORTLET_ID%TYPE,
	in_rss_url				IN 	tab_portlet_rss_feed.RSS_URL%TYPE
);

PROCEDURE GetRssFeed(
	in_tab_portlet_id		IN  tab_portlet.TAB_PORTLET_ID%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE DashboardAuditLogReport(
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE UNSEC_AuditPortletState(
	in_tab_portlet_id		IN	tab_portlet.TAB_PORTLET_ID%TYPE,
	in_name					IN	VARCHAR2,
	in_oldval				IN	VARCHAR2,
	in_newval				IN	VARCHAR2
);

END portlet_pkg;
/
