CREATE OR REPLACE PACKAGE BODY ct.util_pkg AS

FUNCTION GetRegionIdFromName (
    in_description                   IN region.description%TYPE
) RETURN region.region_id%TYPE
AS
	v_region_id		region.region_id%TYPE;
BEGIN
	SELECT region_id INTO v_region_id FROM region WHERE LOWER(description) = LOWER(in_description); 
	
	RETURN v_region_id;
END;

FUNCTION GetRegionIdFromCode (
    in_country_code                   IN region.country%TYPE
) RETURN region.region_id%TYPE
AS
	v_region_id		region.region_id%TYPE;
BEGIN
	SELECT region_id INTO v_region_id FROM region WHERE LOWER(country) = LOWER(in_country_code); 
	
	RETURN v_region_id;
END;

FUNCTION GetEioIdFromName (
    in_description                   IN eio.description%TYPE
) RETURN eio.eio_id%TYPE
AS
	v_eio_id		eio.eio_id%TYPE;
BEGIN
	SELECT eio_id INTO v_eio_id FROM eio WHERE LOWER(description) = LOWER(in_description); 
	
	RETURN v_eio_id;
END;

FUNCTION GetEioGroupIdFromName (
    in_description                   IN eio.description%TYPE
) RETURN eio_group.eio_group_id%TYPE
AS
	v_eio_group_id		eio_group.eio_group_id%TYPE;
BEGIN
	SELECT eio_group_id INTO v_eio_group_id FROM eio_group WHERE LOWER(description) = LOWER(in_description); 
	
	RETURN v_eio_group_id;
END;

FUNCTION GetScope3CatIdFromName (
    in_description                   IN scope_3_category.description%TYPE
) RETURN scope_3_category.scope_category_id%TYPE
AS
	v_scope_category_id		scope_3_category.scope_category_id%TYPE;
BEGIN
	SELECT scope_category_id INTO v_scope_category_id FROM scope_3_category WHERE LOWER(description) = LOWER(in_description); 
	
	RETURN v_scope_category_id;
END;

FUNCTION GetScope3CatNameFromId (
    in_scope_category_id                   IN scope_3_category.scope_category_id%TYPE
) RETURN scope_3_category.description%TYPE
AS
	v_description		scope_3_category.description%TYPE;
BEGIN
	SELECT description INTO v_description FROM scope_3_category WHERE scope_category_id = in_scope_category_id; 
	
	RETURN v_description;
END;

FUNCTION GetScopeInputTypeId  RETURN ct.company.scope_input_type_id%TYPE
AS
	v_id		ct.company.scope_input_type_id%TYPE;
BEGIN
	SELECT scope_input_type_id
	  INTO v_id
	  FROM ct.company
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	RETURN v_id;
END;

FUNCTION GetConversionToDollar (
	in_currency_id					IN  currency_period.currency_id%TYPE,
	in_period_id					IN  period.period_id%TYPE
) RETURN currency_period.conversion_to_dollar%TYPE
AS
	v_conversion_to_dollar			currency_period.conversion_to_dollar%TYPE;
BEGIN
	SELECT conversion_to_dollar
	  INTO v_conversion_to_dollar
	  FROM (
		SELECT conversion_to_dollar, ROW_NUMBER() over (ORDER BY period_id DESC) rn
		  FROM currency_period
		 WHERE currency_id = in_currency_id
		   AND period_id <= in_period_id 
	)x
	WHERE x.rn = 1;
	
	RETURN v_conversion_to_dollar;

END;

FUNCTION GetConversionToDollar (
	in_currency_id					IN  currency_period.currency_id%TYPE,
	in_date							IN  DATE
) RETURN currency_period.conversion_to_dollar%TYPE
AS
	v_period_id			period.period_id%TYPE;
BEGIN
    SELECT period_id
	  INTO v_period_id
	  FROM (
		SELECT period_id 
		  FROM period 
		 ORDER BY ABS(TO_DATE(description, 'YYYY') - in_date))
	 WHERE rownum = 1;
	 
	RETURN GetConversionToDollar(in_currency_id, v_period_id);		
	
END;

FUNCTION GetConversionFromDollar (
	in_currency_id					IN  currency_period.currency_id%TYPE,
	in_date							IN  DATE
) RETURN currency_period.conversion_to_dollar%TYPE
AS
BEGIN
	RETURN 1/GetConversionToDollar(in_currency_id, in_date);
END;

FUNCTION IsValueChain RETURN customer_options.is_value_chain%TYPE
AS
	v_is_value_chain		customer_options.is_value_chain%TYPE;
BEGIN
	SELECT is_value_chain
	  INTO v_is_value_chain
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;
	   
	RETURN v_is_value_chain;
END;

FUNCTION IsAlongsideChain RETURN customer_options.is_alongside_chain%TYPE
AS
	v_is_alongside_chain		customer_options.is_alongside_chain%TYPE;
BEGIN
	SELECT is_alongside_chain
	  INTO v_is_alongside_chain
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;
		   
	RETURN v_is_alongside_chain;
END;

FUNCTION CanCopyToIndicators RETURN customer_options.copy_to_indicators%TYPE
AS
	v_copy_to_indicators		customer_options.copy_to_indicators%TYPE;
BEGIN
	SELECT copy_to_indicators
	  INTO v_copy_to_indicators
	  FROM customer_options
	 WHERE app_sid = security_pkg.getApp;
		   
	RETURN v_copy_to_indicators;
END;

PROCEDURE EnableHotspotterDashboard (
	in_company_sid			IN security_pkg.T_SID_ID
)
AS
	v_group					VARCHAR2(200) DEFAULT 'CT Hotspotter - '||in_company_sid;
	v_sml_state				VARCHAR2(999) DEFAULT '{"pickerName":"'||v_group||'","portletHeight":295}'; -- 10px padding between portlets
	v_lrg_state				VARCHAR2(999) DEFAULT '{"pickerName":"'||v_group||'","portletHeight":600}';
	v_tab_id				csr.tab.tab_id%TYPE;
	v_tp_bp_id				csr.tab_portlet.tab_portlet_id%TYPE;
	v_tp_cp_id				csr.tab_portlet.tab_portlet_id%TYPE;
	v_tp_hc_id				csr.tab_portlet.tab_portlet_id%TYPE;
	v_tp_ad_id				csr.tab_portlet.tab_portlet_id%TYPE;
	v_tp_ids				security_pkg.T_SID_IDS;
	v_exists				NUMBER(10);
BEGIN
	
	SELECT COUNT(*)
	  INTO v_exists
	  FROM csr.tab
	 WHERE app_sid = security_pkg.GetApp
	   AND portal_group = v_group;
	
	IF v_exists > 0 THEN
		RETURN;
	END IF;
	
	INSERT INTO csr.tab 
	(tab_id, layout, name, app_sid, is_shared, portal_group)
	VALUES 
	(csr.tab_id_seq.nextval, 5, 'Hotspotter', security_pkg.GetApp, 1, v_group)
	RETURNING tab_id INTO v_tab_id;

	csr.portlet_pkg.AddTabForGroup(securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Restricted Hotspot Users'), v_tab_id);
	
	-- BreakdownPicker
	csr.portlet_pkg.AddPortletToTab(v_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.BreakdownPicker'), '', v_tp_bp_id);
	csr.portlet_pkg.SaveState(v_tp_bp_id, v_sml_state);
	
	-- ChartPicker
	csr.portlet_pkg.AddPortletToTab(v_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.ChartPicker'), '', v_tp_cp_id);
	csr.portlet_pkg.SaveState(v_tp_cp_id, v_sml_state);
	
	-- HotspotChart
	csr.portlet_pkg.AddPortletToTab(v_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.HotspotChart'), '', v_tp_hc_id);
	csr.portlet_pkg.SaveState(v_tp_hc_id, v_lrg_state);
	
	-- Advice
	csr.portlet_pkg.AddPortletToTab(v_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.Advice'), '', v_tp_ad_id);
	csr.portlet_pkg.SaveState(v_tp_ad_id, v_lrg_state);
	
	
	-- COLUMN 1
	SELECT id BULK COLLECT INTO v_tp_ids FROM (SELECT v_tp_bp_id id FROM DUAL UNION SELECT v_tp_cp_id FROM DUAL);
	csr.portlet_pkg.UpdatePortletPosition(v_tab_id, 0, v_tp_ids);
	
	-- COLUMN 2
	SELECT v_tp_hc_id BULK COLLECT INTO v_tp_ids FROM DUAL;
	csr.portlet_pkg.UpdatePortletPosition(v_tab_id, 1, v_tp_ids);
		
	-- COLUMN 3
	SELECT v_tp_ad_id BULK COLLECT INTO v_tp_ids FROM DUAL;
	csr.portlet_pkg.UpdatePortletPosition(v_tab_id, 2, v_tp_ids);
END;

FUNCTION EnableModulePortalTab (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_name					IN csr.tab.name%TYPE,
	in_security_group		IN VARCHAR2,
	in_layout				IN csr.tab.layout%TYPE,
	in_position				IN csr.tab.override_pos%TYPE
) RETURN csr.tab.tab_id%TYPE
AS
	v_group					VARCHAR2(200) DEFAULT 'CT Value Chain - '||in_company_sid;	
	v_tab_id				csr.tab.tab_id%TYPE;
BEGIN
	BEGIN
		SELECT tab_id
		  INTO v_tab_id
		  FROM csr.tab
		 WHERE app_sid = security_pkg.GetApp
		   AND portal_group = v_group
		   AND name = in_name;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	IF v_tab_id IS NULL THEN			
		INSERT INTO csr.tab 
		(tab_id, layout, name, app_sid, is_shared, portal_group, override_pos)
		VALUES 
		(csr.tab_id_seq.nextval, in_layout, in_name, security_pkg.GetApp, 1, v_group, in_position)
		RETURNING tab_id INTO v_tab_id;

		csr.portlet_pkg.AddTabForGroup(securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/'||in_security_group), v_tab_id);
	END IF;

	RETURN v_tab_id;
END;

PROCEDURE AddCommonPortletsToVC (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_tab_id				IN csr.tab.tab_id%TYPE,
	in_module_type			IN NUMBER
)
AS
	v_group					VARCHAR2(200) DEFAULT 'CT Value Chain - '||in_module_type||' - '||in_company_sid;	
	v_sml_state				VARCHAR2(999) DEFAULT '{"pickerName":"'||v_group||'", "moduleType":'||in_module_type||', "portletHeight":295}'; -- 10px padding between portlets
	v_lrg_state				VARCHAR2(999) DEFAULT '{"pickerName":"'||v_group||'", "title":"Chart", "portletHeight":600}';
	v_tp_cp_id				csr.tab_portlet.tab_portlet_id%TYPE;
	v_tp_wn_id				csr.tab_portlet.tab_portlet_id%TYPE;
	v_tp_hc_id				csr.tab_portlet.tab_portlet_id%TYPE;
	v_tp_ids				security_pkg.T_SID_IDS;
BEGIN
	-- ChartPicker
	csr.portlet_pkg.AddPortletToTab(in_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.ChartPicker'), '', v_tp_cp_id);
	csr.portlet_pkg.SaveState(v_tp_cp_id, v_sml_state);
	
	-- WhatsNext
	csr.portlet_pkg.AddPortletToTab(in_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.WhatsNext'), '', v_tp_wn_id);
	csr.portlet_pkg.SaveState(v_tp_wn_id, v_sml_state);
	
	-- HotspotChart
	csr.portlet_pkg.AddPortletToTab(in_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.HotspotChart'), '', v_tp_hc_id);
	csr.portlet_pkg.SaveState(v_tp_hc_id, v_lrg_state);
	
	-- column 0
	SELECT id BULK COLLECT INTO v_tp_ids FROM (SELECT v_tp_cp_id id FROM DUAL UNION SELECT v_tp_wn_id id FROM DUAL);
	csr.portlet_pkg.UpdatePortletPosition(in_tab_id, 0, v_tp_ids);

	-- column 1
	SELECT id BULK COLLECT INTO v_tp_ids FROM (SELECT v_tp_hc_id id FROM DUAL);
	csr.portlet_pkg.UpdatePortletPosition(in_tab_id, 1, v_tp_ids);
END;

PROCEDURE EnableValueChainDashboard (
	in_company_sid			IN security_pkg.T_SID_ID
)
AS
	v_tab_id				csr.tab.tab_id%TYPE;
	v_tp_id					csr.tab_portlet.tab_portlet_id%TYPE;
	v_tp_ids				security_pkg.T_SID_IDS;
	v_pos					NUMBER(10) DEFAULT 1;
BEGIN
	
	v_tab_id := EnableModulePortalTab(in_company_sid, 'Value chain', 'Value Chain Users', 1, v_pos); v_pos := v_pos +1;
	AddCommonPortletsToVC(in_company_sid, v_tab_id, 2);
	
	/* - lets leave flash map for now
	v_tab_id := EnableModulePortalTab(in_company_sid, 'Flash map', 'Value Chain Users', 2, v_pos); v_pos := v_pos +1;
	csr.portlet_pkg.AddPortletToTab(v_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.FlashMap'), '', v_tp_id);
	csr.portlet_pkg.SaveState(v_tp_id, '{"portletHeight":600}');
	*/
	
	v_tab_id := EnableModulePortalTab(in_company_sid, 'Employee commuting', 'Employee Commute Users', 1, v_pos); v_pos := v_pos +1;
	AddCommonPortletsToVC(in_company_sid, v_tab_id, 3);
	
	v_tab_id := EnableModulePortalTab(in_company_sid, 'Business travel', 'Business Travel Users', 1, v_pos); v_pos := v_pos +1;
	AddCommonPortletsToVC(in_company_sid, v_tab_id, 4);
	
	v_tab_id := EnableModulePortalTab(in_company_sid, 'Purchased goods', 'Products Services Users', 5, v_pos); v_pos := v_pos +1;
	AddCommonPortletsToVC(in_company_sid, v_tab_id, 5);
	
	csr.portlet_pkg.AddPortletToTab(v_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.Chain.RecentActivity'), '', v_tp_id);
	csr.portlet_pkg.SaveState(v_tp_id, '{"portletHeight":600}');
	SELECT id BULK COLLECT INTO v_tp_ids FROM (SELECT v_tp_id id FROM DUAL);
	csr.portlet_pkg.UpdatePortletPosition(v_tab_id, 2, v_tp_ids);
		
	--v_tab_id := EnableModulePortalTab(in_company_sid, 'Use phase', 'Use Phase Users', 1, 5);
	--AddCommonPortletsToVC(in_company_sid, v_tab_id);
END;

PROCEDURE FillStringTable (
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_values				security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	FillStringTable(in_values_1, v_values);
END;

PROCEDURE FillStringTable (
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY,
	in_values_2				IN  security_pkg.T_VARCHAR2_ARRAY
)
AS
BEGIN
	DELETE FROM STRING_TABLE;
	
	IF in_values_1.COUNT = 0 THEN
		RETURN;
	END IF;
	
	IF in_values_2.COUNT > 0 AND in_values_2.COUNT <> in_values_1.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'If in_values_2 is not empty, it must be the same length as in_values_1');
	END IF;
	
	FOR i IN 1.. in_values_1.COUNT
	LOOP
		INSERT INTO STRING_TABLE (position, value_1) VALUES (i, in_values_1(i));
	END LOOP;
	
	FOR i IN 1.. in_values_2.COUNT
	LOOP
		UPDATE STRING_TABLE SET value_2 = in_values_2(i) WHERE position = i;
	END LOOP;
		
END;


PROCEDURE FillIdMapperTableIds (
	in_ids					IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
	v_count					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM id_mapper_table;
	  
	IF in_ids.COUNT <> v_count THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_ids must be the same length as the values');
	END IF;

	FOR i IN 1.. in_ids.COUNT
	LOOP
		UPDATE id_mapper_table SET id = in_ids(i) WHERE position = i;
	END LOOP;
END;




PROCEDURE FillIdMapperTable (
	in_column_type_id_1		IN  NUMBER,
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY
)
AS
BEGIN
	DELETE FROM id_mapper_table;
	
	IF in_values_1.COUNT = 0 THEN
		RETURN;
	END IF;
	
	FOR i IN 1.. in_values_1.COUNT
	LOOP
		INSERT INTO ID_MAPPER_TABLE (position, column_type_id_1, value_1) VALUES (i, in_column_type_id_1, in_values_1(i));
	END LOOP;
END;

PROCEDURE FillIdMapperTable (
	in_column_type_id_1		IN  NUMBER,
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY,
	in_ids					IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
BEGIN
	FillIdMapperTable(in_column_type_id_1, in_values_1);
	FillIdMapperTableIds(in_ids);
END;

PROCEDURE FillIdMapperTable (
	in_column_type_id_1		IN  NUMBER,
	in_column_type_id_2		IN  NUMBER,
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY,
	in_values_2				IN  security_pkg.T_VARCHAR2_ARRAY
)
AS
BEGIN
	FillIdMapperTable(in_column_type_id_1, in_values_1);
	
	IF in_values_2.COUNT <> in_values_1.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_values_2 is not the same length as in_values_1');
	END IF;
	
	FOR i IN 1.. in_values_2.COUNT
	LOOP
		UPDATE ID_MAPPER_TABLE SET column_type_id_2 = in_column_type_id_2, value_2 = in_values_2(i) WHERE position = i;
	END LOOP;
END;

PROCEDURE FillIdMapperTable (
	in_column_type_id_1		IN  NUMBER,
	in_column_type_id_2		IN  NUMBER,
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY,
	in_values_2				IN  security_pkg.T_VARCHAR2_ARRAY,
	in_ids					IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
BEGIN
	FillIdMapperTable(in_column_type_id_1, in_column_type_id_2, in_values_1, in_values_2);
	FillIdMapperTableIds(in_ids);
END;

PROCEDURE GetTravelMode (
	in_travel_mode_id		IN  travel_mode.travel_mode_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT travel_mode_id, description
		  FROM travel_mode
		 WHERE travel_mode_id = NVL(in_travel_mode_id, travel_mode_id)
		 ORDER BY description;
END;

PROCEDURE GetTravelModes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetTravelMode(null, out_cur);
END;

PROCEDURE GetHideFlags (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT hide_ec, hide_bt
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE ResetAllDashboards
AS
	v_app_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ResetAllDashboards can only be run as BuiltIn/Administrator');
	END IF;

	-- blows up if the app isn't set
	v_app_sid := security_pkg.GetApp; 
	
	DELETE FROM csr.tab_portlet WHERE tab_id IN (
		SELECT tab_id 
		  FROM csr.tab 
		 WHERE portal_group LIKE 'CT Hotspotter%' 
		    OR portal_group LIKE 'CT Value Chain%'
		)
	  AND app_sid = v_app_sid;

	DELETE FROM csr.tab_group WHERE tab_id IN (
		SELECT tab_id 
		  FROM csr.tab 
		 WHERE portal_group LIKE 'CT Hotspotter%' 
		    OR portal_group LIKE 'CT Value Chain%'
		)
	   AND app_sid = v_app_sid;

	DELETE FROM csr.tab 
	 WHERE (portal_group LIKE 'CT Hotspotter%' OR portal_group LIKE 'CT Value Chain%')
	   AND app_sid = v_app_sid;

	FOR r IN (
		SELECT company_sid, top_company_sid
		  FROM ct.company c, chain.customer_options co
		 WHERE c.app_sid = v_app_sid
		   AND c.app_sid = co.app_sid(+)
		   AND c.company_sid = co.top_company_sid(+)
	) LOOP
		ct.util_pkg.EnableHotspotterDashboard(r.company_sid);
		IF r.top_company_sid IS NOT NULL THEN
			ct.util_pkg.EnableValueChainDashboard(r.top_company_sid);
		END IF;
	end loop;
END;

PROCEDURE ResetFull 
AS
	v_builtin_admin_act		security_pkg.T_ACT_ID;
    
	v_stored_user_sid		security_pkg.T_SID_ID;
	v_stored_app_sid		security_pkg.T_SID_ID;
    v_stored_act			security_pkg.T_ACT_ID;
    v_company_sid			security_pkg.T_SID_ID;
    v_top_company_sid		security_pkg.T_SID_ID := chain.helper_pkg.getTopCompanySid;
BEGIN
	v_stored_act := SYS_CONTEXT('SECURITY', 'ACT');
	v_stored_app_sid := SYS_CONTEXT('SECURITY', 'APP'); -- not sure we need to store this but can't hurt
	v_stored_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	/*
	-- delete uploaded worksheet values
	DELETE FROM worksheet_value_map_breakdown
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM worksheet_value_map_currency
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM worksheet_value_map_region
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM worksheet_value_map_supplier
		  WHERE app_sid = v_stored_app_sid;

	-- delete consumption data (linked to regions not breakdowns)
	DELETE FROM ht_consumption_region
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM ht_consumption
		  WHERE app_sid = v_stored_app_sid;

	-- delete Employee Commute Questionnaire answers (not linked to anything)
	DELETE FROM ec_questionnaire_answers
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM ec_questionnaire
		  WHERE app_sid = v_stored_app_sid;

	-- delete other Employee Commute
	DELETE FROM ec_bus_entry
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM ec_car_entry
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM ec_motorbike_entry
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM ec_train_entry
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM ec_profile
		  WHERE app_sid = v_stored_app_sid;

	-- Business Travel
	DELETE FROM bt_profile
		  WHERE app_sid = v_stored_app_sid;

	-- Products and Services
	DELETE FROM ps_level_contributions
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM ps_item
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM ps_spend_breakdown
		  WHERE app_sid = v_stored_app_sid;

	-- delete suppliers
	DELETE FROM supplier_contact
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM supplier
		  WHERE app_sid = v_stored_app_sid;

	-- delete options
	DELETE FROM bt_options
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM ec_options
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM ps_options
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM up_options
		  WHERE app_sid = v_stored_app_sid;
	*/
	-- Snapshot
	UPDATE customer_options
	   SET snapshot_taken = 0
	 WHERE app_sid = v_stored_app_sid;
	
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_builtin_admin_act);
	security_pkg.SetApp(v_stored_app_sid);
	security_pkg.SetACT(v_builtin_admin_act);
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
	
	-- delete suppliers - having this is a workaround for the fact that "supplier_pkg" fires before "ct.link_pkg" - so deleting when deleting a company 
	-- it tries to nuke csr_users bfore ct stuff us cleared up
	DELETE FROM supplier_contact
		  WHERE app_sid = v_stored_app_sid;
	
	FOR r IN (
	    SELECT company_sid
		  FROM chain.company
		 WHERE app_sid = v_stored_app_sid
		   AND company_sid <> v_top_company_sid
	) LOOP
		security.securableobject_pkg.DeleteSO(v_builtin_admin_act, r.company_sid);
	END LOOP;
	
	-- delete top company last
	security.securableobject_pkg.DeleteSO(v_builtin_admin_act, v_top_company_sid);
	
	UPDATE chain.customer_options
	   SET top_company_sid = null
	 WHERE app_sid = v_stored_app_sid;

	security_pkg.SetApp(v_stored_app_sid);
	security_pkg.SetACTAndSID(v_stored_act, v_stored_user_sid);	
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
	/*
	DELETE FROM hotspot_result
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM breakdown_region_eio
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM breakdown_region_group
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM breakdown_region
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM breakdown_group
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM breakdown
		  WHERE app_sid = v_stored_app_sid;

	DELETE FROM breakdown_type
		  WHERE app_sid = v_stored_app_sid;
	*/
END;

PROCEDURE ResetSuppliers 
AS
	v_builtin_admin_act		security_pkg.T_ACT_ID;
    
	v_stored_user_sid		security_pkg.T_SID_ID;
	v_stored_app_sid		security_pkg.T_SID_ID;
    v_stored_act			security_pkg.T_ACT_ID;
    v_company_sid			security_pkg.T_SID_ID;
BEGIN
	v_stored_act := SYS_CONTEXT('SECURITY', 'ACT');
	v_stored_app_sid := SYS_CONTEXT('SECURITY', 'APP'); -- not sure we need to store this but can't hurt
	v_stored_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_builtin_admin_act);
	security_pkg.SetApp(v_stored_app_sid);
	security_pkg.SetACT(v_builtin_admin_act);
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
	
	FOR r IN (
		SELECT company_sid
		  FROM chain.company
		 WHERE app_sid = v_stored_app_sid
		   AND company_sid NOT IN (
		   		SELECT top_company_sid FROM chain.customer_options
		   )
	) LOOP
		security.securableobject_pkg.DeleteSO(v_builtin_admin_act, r.company_sid);
	END LOOP;

	/*UPDATE chain.customer_options
	   SET top_company_sid = null
	 WHERE app_sid = v_stored_app_sid;*/
	 
	UPDATE ct.ps_item SET supplier_id = NULL WHERE app_sid = v_stored_app_sid;

	DELETE FROM ct.ps_supplier_eio_freq WHERE app_sid = v_stored_app_sid;
    DELETE FROM worksheet_value_map_supplier WHERE app_sid = v_stored_app_sid;
    
	FOR r IN (
		SELECT value_map_id FROM worksheet_value_map_supplier WHERE app_sid = v_stored_app_sid
	) LOOP
		csr.excel_pkg.DeleteValueMap(r.value_map_id);
	END LOOP;
	
	DELETE FROM supplier_contact WHERE app_sid = v_stored_app_sid;
	DELETE FROM supplier WHERE app_sid = v_stored_app_sid;

	security_pkg.SetApp(v_stored_app_sid);
	security_pkg.SetACTAndSID(v_stored_act, v_stored_user_sid);	
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
END;

PROCEDURE ResetWorksheets
AS
BEGIN
	FOR r IN (
		SELECT wfu.worksheet_id 
		  FROM chain.file_upload fu, chain.worksheet_file_upload wfu
		 WHERE fu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND fu.app_sid = wfu.app_sid
		   AND fu.file_upload_sid = wfu.file_upload_sid
	) LOOP
		excel_pkg.DeleteWorksheet(r.worksheet_id);
	END LOOP;
	
	excel_pkg.DeleteAllValueMaps();
END;

FUNCTION GetTopCompanyTypeId
RETURN customer_options.top_company_type_id%TYPE
AS
	v_ct_id			customer_options.top_company_type_id%TYPE;
BEGIN
	SELECT top_company_type_id
	  INTO v_ct_id
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	RETURN v_ct_id;
END;

FUNCTION GetSupplierCompanyTypeId
RETURN customer_options.supplier_company_type_id%TYPE
AS
	v_ct_id			customer_options.supplier_company_type_id%TYPE;
BEGIN
	SELECT supplier_company_type_id
	  INTO v_ct_id
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		 
	RETURN v_ct_id;
END;

END util_pkg;
/
