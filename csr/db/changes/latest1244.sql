-- Please update version.sql too -- this keeps clean builds in sync
define version=1244
@update_header

INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'CT VC Before Hotspot', 'Credit360.Portlets.CarbonTrust.VCBeforeHotspot', '/csr/site/portal/portlets/ct/VCBeforeHotspot.js');
INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'CT VC Before Snapshot', 'Credit360.Portlets.CarbonTrust.VCBeforeSnapshot', '/csr/site/portal/portlets/ct/VCBeforeSnapshot.js');
INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'CT VC Before Module Configuration', 'Credit360.Portlets.CarbonTrust.VCBeforeModuleConfiguration', '/csr/site/portal/portlets/ct/VCBeforeModuleConfiguration.js');

DECLARE
	v_tab_id		NUMBER(10);
	v_tab_ids		security.security_pkg.T_SID_IDS;
	v_dummy			NUMBER(10);
BEGIN
	security.user_pkg.Logonadmin();
	
	FOR r in (
		SELECT c.host
		  FROM csr.customer c, ct.customer_options ct
		 WHERE c.app_sid = ct.app_sid
		   AND ct.is_value_chain = 1
	)
	LOOP
		security.user_pkg.Logonadmin(r.host);
		
		FOR r IN (
			SELECT portlet_id 
			  FROM csr.portlet 
			 WHERE type IN (			 
				'Credit360.Portlets.CarbonTrust.VCBeforeHotspot',
				'Credit360.Portlets.CarbonTrust.VCBeforeSnapshot',
				'Credit360.Portlets.CarbonTrust.VCBeforeModuleConfiguration'
			 )
			   AND portlet_id NOT IN (SELECT portlet_id FROM csr.customer_portlet WHERE app_sid = security.security_pkg.GetApp)
		) LOOP
			csr.portlet_pkg.EnablePortletForCustomer(r.portlet_id);
		END LOOP;
		
		v_tab_id := NULL;	
		BEGIN
			SELECT tab_id
			  INTO v_tab_id
			  FROM csr.tab
			 WHERE portal_group = 'CT VC Before Hotspot';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
		END;		
		
		IF v_tab_id IS NULL THEN
			-- create a new tab 
			INSERT INTO csr.tab 
			(tab_id, layout, name, app_sid, is_shared, portal_group)
			VALUES 
			(csr.tab_id_seq.nextval, 2, 'CT VC Before Hotspot', security.security_pkg.GetApp, 1, 'CT VC Before Hotspot')
			RETURNING tab_id INTO v_tab_id;
		
			SELECT v_tab_id BULK COLLECT INTO v_tab_ids FROM DUAL;
			csr.portlet_pkg.SetTabsForGroup('CT VC Before Hotspot', security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Value Chain Users'), v_tab_ids);
		
			csr.portlet_pkg.AddPortletToTab(v_tab_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.VCBeforeHotspot'), '{ height: 300 }', v_dummy);
		END IF;
		
		v_tab_id := NULL;		
		BEGIN
			SELECT tab_id
			  INTO v_tab_id
			  FROM csr.tab
			 WHERE portal_group = 'CT VC Before Snapshot';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
		END;		
		
		IF v_tab_id IS NULL THEN
			-- create a new tab 
			INSERT INTO csr.tab 
			(tab_id, layout, name, app_sid, is_shared, portal_group)
			VALUES 
			(csr.tab_id_seq.nextval, 2, 'CT VC Before Snapshot', security.security_pkg.GetApp, 1, 'CT VC Before Snapshot')
			RETURNING tab_id INTO v_tab_id;
		
			SELECT v_tab_id BULK COLLECT INTO v_tab_ids FROM DUAL;
			csr.portlet_pkg.SetTabsForGroup('CT VC Before Snapshot', security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Value Chain Users'), v_tab_ids);
		
			csr.portlet_pkg.AddPortletToTab(v_tab_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.VCBeforeSnapshot'), '{ height: 300 }', v_dummy);
		END IF;
		
		v_tab_id := NULL;
		BEGIN
			SELECT tab_id
			  INTO v_tab_id
			  FROM csr.tab
			 WHERE portal_group = 'CT VC Before Module Configuration';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
		END;		
		
		IF v_tab_id IS NULL THEN
			-- create a new tab 
			INSERT INTO csr.tab 
			(tab_id, layout, name, app_sid, is_shared, portal_group)
			VALUES 
			(csr.tab_id_seq.nextval, 2, 'CT VC Before Module Configuration', security.security_pkg.GetApp, 1, 'CT VC Before Module Configuration')
			RETURNING tab_id INTO v_tab_id;
		
			SELECT v_tab_id BULK COLLECT INTO v_tab_ids FROM DUAL;
			csr.portlet_pkg.SetTabsForGroup('CT VC Before Module Configuration', security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Value Chain Users'), v_tab_ids);
		
			csr.portlet_pkg.AddPortletToTab(v_tab_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.VCBeforeModuleConfiguration'), '{ height: 300 }', v_dummy);
		END IF;
	END LOOP;
	
	security.user_pkg.Logonadmin();
END;
/

@update_tail
