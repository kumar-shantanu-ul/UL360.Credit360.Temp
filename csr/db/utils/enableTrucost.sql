PROMPT Insert:
PROMPT 1) Host (e.g. foo.credit360.com)
PROMPT 2) Customer Trucost Company Id
PROMPT 3) Configure portlet tab (y/n)

exec user_pkg.logonadmin('&&1');

DECLARE
	v_trucost_company_id		NUMBER(10) DEFAULT &&2;
	v_enable_portlet_resp		VARCHAR2(100) DEFAULT UPPER(NVL('&&3', 'Y'));
	v_enable_portlet			BOOLEAN DEFAULT v_enable_portlet_resp = 'Y' OR v_enable_portlet_resp = 'YES';
	v_mapped_company_id			NUMBER(10);
	v_act_id					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid					security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_ru_group_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'groups/registeredusers');
	v_admin_group_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'groups/administrators');
	v_sa_group_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.SID_ROOT, 'csr/SuperAdmins');
	v_menu_admin				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/admin');
	v_menu_admin_trucost		security_pkg.T_SID_ID;
	v_wwwroot					security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_www_trucost				security_pkg.T_SID_ID;
	v_www_trucost_site			security_pkg.T_SID_ID;
	v_www_trucost_site_admin	security_pkg.T_SID_ID;
	v_portlet_tab				tab.tab_id%TYPE;
	v_peer_portlet_id			portlet.portlet_id%TYPE;
	v_report_portlet_id			portlet.portlet_id%TYPE;
	v_dummy						NUMBER(10);
	v_dacl_id					security_pkg.T_ACL_ID;
BEGIN
	FOR r IN (SELECT 1
				FROM all_tables
			   WHERE owner = 'OWL' and table_name = 'CLIENT_MODULE') LOOP
		EXECUTE IMMEDIATE 
			'INSERT INTO owl.CLIENT_MODULE (client_module_id, client_sid, credit_module_id, enabled, date_enabled)'||CHR(10)||
				 'SELECT cms.item_id_seq.nextval, security.security_pkg.getApp, credit_module_id, 1, SYSDATE'||CHR(10)||
				   'FROM owl.credit_module'||CHR(10)||
				  'WHERE lookup_Key = ''TRUCOST'' AND EXISTS ('||CHR(10)||
					'SELECT null FROM owl.owl_client WHERE client_sid = security_pkg.getApp'||CHR(10)||
				')';
	END LOOP;

		
	BEGIN
		v_www_trucost := securableobject_pkg.GetSidFromPath(v_act_id, v_wwwroot, 'trucost');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND	THEN
			web_pkg.CreateResource(v_act_id, v_wwwroot, v_wwwroot, 'trucost', v_www_trucost);
	END;
	
	BEGIN
		v_www_trucost_site := securableobject_pkg.GetSidFromPath(v_act_id, v_www_trucost, 'site');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND	THEN
			web_pkg.CreateResource(v_act_id, v_wwwroot, v_www_trucost, 'site', v_www_trucost_site);
			
			security.acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_www_trucost_site), -1, security_pkg.ACE_TYPE_ALLOW, 
				security_pkg.ACE_FLAG_DEFAULT, v_ru_group_sid, security_pkg.PERMISSION_STANDARD_READ);
	END;
    
	BEGIN
		v_www_trucost_site_admin := securableobject_pkg.GetSidFromPath(v_act_id, v_www_trucost_site, 'admin');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND	THEN
			web_pkg.CreateResource(v_act_id, v_wwwroot, v_www_trucost_site, 'admin', v_www_trucost_site_admin);

			Securableobject_Pkg.ClearFlag(v_act_id, v_www_trucost_site_admin, security_pkg.SOFLAG_INHERIT_DACL);
			
			acl_pkg.GetNewID(v_dacl_id);
			security.acl_pkg.SetDACL(v_act_id, v_www_trucost_site_admin, v_dacl_id);
			
			security.acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_www_trucost_site_admin), -1, security_pkg.ACE_TYPE_ALLOW, 
				security_pkg.ACE_FLAG_INHERITABLE, v_sa_group_sid, security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	BEGIN
		v_menu_admin_trucost := securableobject_pkg.GetSidFromPath(v_act_id, v_menu_admin, 'trucost_admin');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND	THEN
			security.menu_pkg.CreateMenu(v_act_id, v_menu_admin,
				'trucost_admin', 'Trucost Reports', '/trucost/site/admin/admin.acds', -1, null, v_menu_admin_trucost);

			security.acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_menu_admin_trucost), 100, security_pkg.ACE_TYPE_ALLOW, 
				security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_sa_group_sid, security_pkg.PERMISSION_STANDARD_READ);
	END;

	SELECT company_id
	  INTO v_mapped_company_id
	  FROM trucost.company
	 WHERE tc_id = v_trucost_company_id;
	 
	UPDATE customer 
	   SET trucost_company_id = v_mapped_company_id 
	 WHERE app_sid = v_app_sid;
	
	IF v_enable_portlet THEN
		portlet_pkg.EnablePortletForCustomer(v_peer_portlet_id);
		portlet_pkg.EnablePortletForCustomer(v_report_portlet_id);
	
		SELECT trucost_portlet_tab_id
		  INTO v_portlet_tab
		  FROM customer
		 WHERE app_sid = v_app_sid;

		IF v_portlet_tab IS NULL THEN
			portlet_pkg.AddTabReturnTabId(v_app_sid, 'Trucost Benchmarking', 1, 6, null, v_portlet_tab);

			INSERT INTO tab_group
			(tab_id, group_sid)
			VALUES
			(v_portlet_tab, v_admin_group_sid);		

			UPDATE customer 
			   SET trucost_portlet_tab_id = v_portlet_tab 
			 WHERE app_sid = v_app_sid;
		END IF;

		-- add the peer portlet if it's not there
		SELECT COUNT(*) 
		  INTO v_dummy
		  FROM tab_portlet
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tab_id = v_portlet_tab
		   AND portlet_id = v_peer_portlet_id;

		IF v_dummy = 0 THEN
			portlet_pkg.AddPortletToTab(v_portlet_tab, v_peer_portlet_id, null, v_dummy);
		END IF;	

		-- add the report portlet if it's not there
		SELECT COUNT(*) 
		  INTO v_dummy
		  FROM tab_portlet
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tab_id = v_portlet_tab
		   AND portlet_id = v_report_portlet_id;

		IF v_dummy = 0 THEN
			portlet_pkg.AddPortletToTab(v_portlet_tab, v_report_portlet_id, null, v_dummy);

			UPDATE tab_portlet o
			   SET (column_num, state) = (
					SELECT 1, default_state
					  FROM portlet i
					 WHERE i.portlet_id = o.portlet_id
					)
			 WHERE o.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND o.tab_id = v_portlet_tab
			   AND o.portlet_id = v_report_portlet_id;
		END IF;	
	END IF;
	
	COMMIT;
END;
/

PROMPT >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
PROMPT >>
PROMPT >> You need to run ISLA->C:\temp\trucost\Uploader.exe
PROMPT >> and sync the skyline charts.
PROMPT >> 
PROMPT >> See https://fogbugz.credit360.com/default.asp?W652
PROMPT >> for more information.
PROMPT >> 
PROMPT >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


EXIT
