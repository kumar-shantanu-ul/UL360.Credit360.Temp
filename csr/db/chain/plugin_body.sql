CREATE OR REPLACE PACKAGE BODY CHAIN.plugin_pkg
IS

PROCEDURE AddCompanyTab(
	in_plugin_id					IN	company_tab.plugin_id%TYPE,
	in_pos							IN	company_tab.pos%TYPE,
	in_label						IN  company_tab.label%TYPE,
	in_page_company_type_id			IN	company_tab.page_company_type_id%TYPE,
	in_user_company_type_id			IN  company_tab.user_company_type_id%TYPE,	
	in_viewing_own_company			IN  company_tab.viewing_own_company%TYPE DEFAULT 0,
	in_options						IN  company_tab.options%TYPE DEFAULT NULL,
	in_page_company_col_name		IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_flow_capability_id			IN	company_tab.flow_capability_id%TYPE,
	in_bus_rel_type_id				IN	company_tab.business_relationship_type_id%TYPE DEFAULT NULL,
	in_supplier_restriction			IN 	NUMBER DEFAULT 0
)
AS
	v_pos 							company_tab.pos%TYPE;
	v_page_company_col_sid			company_tab.page_company_col_sid%TYPE DEFAULT NULL;
	v_user_company_col_sid			company_tab.user_company_col_sid%TYPE DEFAULT NULL;	
BEGIN
	v_pos := in_pos;
	
	IF in_pos < 0 THEN
		SELECT NVL(max(pos) + 1, 1) 
		  INTO v_pos 
		  FROM company_tab
		 WHERE page_company_type_id = in_page_company_type_id
		   AND user_company_type_id = in_user_company_type_id
		   AND viewing_own_company = in_viewing_own_company;
	END IF;
	
	BEGIN
		SELECT tc.column_sid
		  INTO v_page_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_page_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_page_company_col_sid := NULL;
	END;
	
	BEGIN
		SELECT tc.column_sid
		  INTO v_user_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_user_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_user_company_col_sid := NULL;
	END;
	
	INSERT INTO chain.company_tab (company_tab_id, plugin_id, plugin_type_id, pos, label, 
	                               page_company_type_id, user_company_type_id, viewing_own_company,
								   options, page_company_col_sid, user_company_col_sid, flow_capability_id,
								   business_relationship_type_id, supplier_restriction)
	     VALUES (chain.company_tab_id_seq.nextval, in_plugin_id, csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB, v_pos, in_label,
				 in_page_company_type_id, in_user_company_type_id, in_viewing_own_company,
				 in_options, v_page_company_col_sid, v_user_company_col_sid, in_flow_capability_id,
				 in_bus_rel_type_id, in_supplier_restriction);  
END;

PROCEDURE AddCompanyHeader(
	in_plugin_id					IN	company_header.plugin_id%TYPE,
	in_pos							IN	company_header.pos%TYPE,
	in_page_company_type_id			IN	company_header.page_company_type_id%TYPE,
	in_user_company_type_id			IN  company_header.user_company_type_id%TYPE,	
	in_viewing_own_company			IN  company_header.viewing_own_company%TYPE DEFAULT 0,
	in_page_company_col_name		IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL
)
AS
	v_pos 							company_header.pos%TYPE;
	v_page_company_col_sid			company_tab.page_company_col_sid%TYPE DEFAULT NULL;
	v_user_company_col_sid			company_tab.user_company_col_sid%TYPE DEFAULT NULL;	
BEGIN
	v_pos := in_pos;
	
	IF in_pos < 0 THEN
		SELECT NVL(max(pos) + 1, 1) 
		  INTO v_pos 
		  FROM company_header
		 WHERE page_company_type_id = in_page_company_type_id
		   AND user_company_type_id = in_user_company_type_id
		   AND viewing_own_company = in_viewing_own_company;
	END IF;

	BEGIN
		SELECT tc.column_sid
		  INTO v_page_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_page_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_page_company_col_sid := NULL;
	END;
	
	BEGIN
		SELECT tc.column_sid
		  INTO v_user_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_user_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_user_company_col_sid := NULL;
	END;
	
	INSERT INTO chain.company_header (company_header_id, plugin_id, plugin_type_id, pos, 
	                                  page_company_type_id, user_company_type_id, viewing_own_company,
									  page_company_col_sid, user_company_col_sid)
	     VALUES (chain.company_header_id_seq.nextval, in_plugin_id, csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_HEAD, 
	            v_pos, in_page_company_type_id, in_user_company_type_id, in_viewing_own_company,
				v_page_company_col_sid, v_user_company_col_sid);  
END;

PROCEDURE INTERNAL_GetCompanyTabs (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_page_company_type_id			IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_company			IN  company_tab.viewing_own_company%TYPE,
	in_company_tab_id				IN  company_tab.company_tab_id%TYPE DEFAULT NULL,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_related_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_comp_tab_comp_type_rl_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_cms_sid							security_pkg.T_SID_ID;
	v_available_tabs					security.T_SO_TABLE := security.T_SO_TABLE();
	v_user_sid							security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
	v_chain_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_company_type_id					NUMBER := company_type_pkg.GetCompanyTypeId;
	v_permissible_tab_ids				security.T_SID_TABLE;
BEGIN
	
	BEGIN
		v_cms_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'cms');
		v_available_tabs := securableobject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_cms_sid, security_pkg.PERMISSION_READ);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	type_capability_pkg.FillUserGroups;

	SELECT ctb.company_tab_id
	  BULK COLLECT INTO v_permissible_tab_ids
	  FROM csr.plugin p
	  JOIN company_tab ctb ON p.plugin_id = ctb.plugin_id
 LEFT JOIN v$supplier_capability sc ON sc.supplier_company_sid = in_company_sid AND sc.flow_capability_id = ctb.flow_capability_id
 LEFT JOIN csr.portal_dashboard pd ON pd.portal_sid = p.portal_sid
 LEFT JOIN business_relationship_type brt ON brt.business_relationship_type_id = ctb.business_relationship_type_id
	 WHERE (in_page_company_type_id IS NULL OR ctb.page_company_type_id = in_page_company_type_id)
	   AND (in_user_company_type_id IS NULL OR ctb.user_company_type_id = in_user_company_type_id)
	   AND viewing_own_company = in_viewing_own_company
	   AND (p.tab_sid IS NULL OR p.tab_sid IN (SELECT sid_id FROM TABLE(v_available_tabs)))
	   AND (in_company_sid IS NULL OR ctb.flow_capability_id IS NULL OR sc.permission_set > 0)
	   AND (in_company_tab_id IS NULL OR ctb.company_tab_id = in_company_tab_id)
	   AND (
			in_company_sid IS NULL
			OR NOT EXISTS (
				SELECT comp_tab_comp_type_role_id
				  FROM company_tab_company_type_role
				 WHERE company_tab_id = ctb.company_tab_id
			)
			OR EXISTS (
				SELECT ctctr.comp_tab_comp_type_role_id
				  FROM company_type_role ctp
				  JOIN csr.region_role_member rrm ON ctp.role_sid = rrm.role_sid AND rrm.user_sid = v_user_sid
				  JOIN csr.supplier s ON rrm.region_sid = s.region_sid AND s.company_sid = v_chain_company_sid
				  JOIN company_tab_company_type_role ctctr ON ctp.company_type_role_id = ctctr.company_type_role_id
				 WHERE ctp.company_type_id = v_company_type_id
				   AND ctctr.company_tab_id = ctb.company_tab_id
			)
			OR EXISTS (
				SELECT ctctr.comp_tab_comp_type_role_id
				  FROM tt_user_groups tug
				  JOIN company_group cg ON tug.company_sid = cg.company_sid AND tug.group_sid = cg.group_sid
				  JOIN company_tab_company_type_role ctctr ON cg.company_group_type_id = ctctr.company_group_type_id
				 WHERE ctctr.company_tab_id = ctb.company_tab_id
			)
	   )
	 GROUP BY ctb.company_tab_id;
				  
	OPEN out_tabs_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description, 
			   p.details, p.preview_image_path, ctb.label, ctb.pos, ctb.page_company_type_id, ctb.user_company_type_id,
			   ctb.viewing_own_company, p.tab_sid, p.form_path, p.group_key, p.control_lookup_keys, ctb.options,
			   p.saved_filter_sid, p.result_mode, p.pre_filter_sid, p.portal_sid, pd.portal_group, ctb.page_company_col_sid, ctb.user_company_col_sid, 
			   ctb.company_tab_id, ctb.flow_capability_id, CASE
				   WHEN ctb.flow_capability_id IS NULL THEN security_pkg.PERMISSION_READ + security_pkg.PERMISSION_WRITE
				   ELSE NVL(sc.permission_set, 0)
			   END permission_set, p.form_sid, brt.business_relationship_type_id, brt.lookup_key business_relationship_type_lk, ctb.default_saved_filter_sid, ctb.supplier_restriction
		  FROM csr.plugin p
		  JOIN company_tab ctb ON p.plugin_id = ctb.plugin_id
		  JOIN TABLE(v_permissible_tab_ids) pt ON ctb.company_tab_id = pt.column_value
	 LEFT JOIN v$supplier_capability sc ON sc.supplier_company_sid = in_company_sid AND sc.flow_capability_id = ctb.flow_capability_id
	 LEFT JOIN csr.portal_dashboard pd ON pd.portal_sid = p.portal_sid
	 LEFT JOIN business_relationship_type brt ON brt.business_relationship_type_id = ctb.business_relationship_type_id
		 GROUP BY p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description, 
		          p.details, p.preview_image_path, ctb.label, ctb.pos, ctb.page_company_type_id, ctb.user_company_type_id,
				  ctb.viewing_own_company, p.tab_sid, p.form_path, p.group_key, p.control_lookup_keys, ctb.options,
				  p.saved_filter_sid, p.result_mode, p.pre_filter_sid, p.portal_sid, pd.portal_group, ctb.page_company_col_sid, ctb.user_company_col_sid,
				  ctb.company_tab_id, ctb.flow_capability_id, sc.permission_set, p.form_sid, brt.business_relationship_type_id, brt.lookup_key, ctb.default_saved_filter_sid, ctb.supplier_restriction
		 ORDER BY ctb.pos;	

	OPEN out_related_cur FOR
		SELECT ctb.company_tab_id, rct.company_type_id
		  FROM company_tab ctb
		  JOIN TABLE(v_permissible_tab_ids) pt ON ctb.company_tab_id = pt.column_value
		  JOIN company_tab_related_co_type rct ON ctb.company_tab_id = rct.company_tab_id;

	OPEN out_comp_tab_comp_type_rl_cur FOR
		SELECT ctb.company_tab_id, 
			   CASE WHEN ctctr.company_type_role_id IS NULL THEN 0 ELSE 1 END AS is_role,
			   NVL(ctctr.company_type_role_id, ctctr.company_group_type_id) AS company_type_role_id
		  FROM company_tab ctb
		  JOIN TABLE(v_permissible_tab_ids) pt ON ctb.company_tab_id = pt.column_value
		  JOIN company_tab_company_type_role ctctr ON ctb.company_tab_id = ctctr.company_tab_id;
END;

PROCEDURE GetCompanyTabs (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_company_tab_id				IN  company_tab.company_tab_id%TYPE DEFAULT NULL,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_related_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_comp_tab_comp_type_rl_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_page_company_type_id	company.company_type_id%TYPE;
	v_user_company_type_id	company.company_type_id%TYPE;
	v_viewing_own_company	company_tab.viewing_own_company%TYPE;
BEGIN
	SELECT company_type_id
	  INTO v_user_company_type_id
	  FROM v$company
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	 
	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		v_viewing_own_company := 1;
		v_page_company_type_id := v_user_company_type_id;
	ELSE
		v_viewing_own_company := 0;
		
		SELECT company_type_id
		  INTO v_page_company_type_id
		  FROM v$company
		 WHERE company_sid = in_company_sid;
	END IF;
	 
	INTERNAL_GetCompanyTabs(
		in_company_sid					=>	in_company_sid,
		in_page_company_type_id			=>	v_page_company_type_id,
		in_user_company_type_id			=>	v_user_company_type_id,
		in_viewing_own_company			=>	v_viewing_own_company,
		in_company_tab_id				=>  in_company_tab_id,
		out_tabs_cur					=>	out_tabs_cur,
		out_related_cur					=>	out_related_cur,
		out_comp_tab_comp_type_rl_cur	=>	out_comp_tab_comp_type_rl_cur
	);
END;

PROCEDURE GetCompanyTabs (
	in_page_company_type_id			IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_company			IN  company_tab.viewing_own_company%TYPE,
	in_company_tab_id				IN  company_tab.company_tab_id%TYPE DEFAULT NULL,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_related_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_comp_tab_comp_type_rl_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	INTERNAL_GetCompanyTabs(
		in_company_sid					=>	NULL,
		in_page_company_type_id			=>	in_page_company_type_id,
		in_user_company_type_id			=>	in_user_company_type_id,
		in_viewing_own_company			=>	in_viewing_own_company,
		in_company_tab_id				=>  in_company_tab_id,
		out_tabs_cur					=>	out_tabs_cur,
		out_related_cur					=>	out_related_cur,
		out_comp_tab_comp_type_rl_cur	=>	out_comp_tab_comp_type_rl_cur
	);
END;

FUNCTION HasCompanyTabs(
	in_company_sid 					IN company.company_sid%TYPE
) RETURN NUMBER
AS
	v_page_company_type_count		NUMBER;
	v_return_val 					NUMBER:=0;
	v_user_company_sid 				company.company_sid%TYPE;
	v_viewing_own_company 			company.company_sid%TYPE :=0;
	v_page_company_type_id 			company.company_type_id%TYPE;
	v_user_company_type_id 			company.company_type_id%TYPE;
BEGIN
	v_user_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');

	IF v_user_company_sid IS NULL OR NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security.security_pkg.PERMISSION_READ) THEN
		RETURN v_return_val;
	END IF;

	IF in_company_sid = v_user_company_sid THEN
		v_viewing_own_company := 1;
	END IF;

	v_page_company_type_id := chain.company_type_pkg.getCompanyTypeId(in_company_sid);
	v_user_company_type_id := chain.company_type_pkg.getCompanyTypeId(v_user_company_sid);

	BEGIN
		SELECT COUNT(DISTINCT page_company_type_id)
		  INTO v_page_company_type_count
		  FROM company_tab
		 WHERE page_company_type_id = v_page_company_type_id
		   AND user_company_type_id = v_user_company_type_id
		   AND viewing_own_company = v_viewing_own_company;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN v_return_val;
	END;

	IF v_page_company_type_count > 0 THEN
		v_return_val := 1;
	END IF;

	RETURN v_return_val;
END;

PROCEDURE GetCompanyTabsForExport (
	out_plugins_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_headers_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_plugins_cur FOR
		 SELECT p.plugin_type_id, p.description, p.js_include, p.js_class, p.cs_class, p.details, p.preview_image_path, 
			t.oracle_table, p.form_path, p.group_key, p.control_lookup_keys
		   FROM csr.plugin p
		   LEFT JOIN cms.tab t ON t.tab_sid = p.tab_sid
		  WHERE p.app_sid = security_pkg.getapp;

	OPEN out_tabs_cur FOR
		 SELECT ctb.label, ctb.pos, ctb.page_company_type_id, ctb.user_company_type_id, ctb.viewing_own_company,
				ctp.lookup_key page_company_type_lookup, ctu.lookup_key user_company_type_lookup, 
				p.plugin_id, p.js_class, p.form_path, p.group_key, p.plugin_type_id, ctb.options,
				c.oracle_column page_company_col_name, s.oracle_column user_company_col_name,
				cfc.description flow_capability_description
		   FROM chain.company_tab ctb
		   JOIN chain.company_type ctp ON ctp.company_type_id = ctb.page_company_type_id
		   JOIN chain.company_type ctu ON ctu.company_type_id = ctb.user_company_type_id
		   JOIN csr.plugin p ON p.plugin_id = ctb.plugin_id
		   LEFT JOIN cms.tab_column c ON c.tab_sid = p.tab_sid AND c.column_sid = ctb.page_company_col_sid
		   LEFT JOIN cms.tab_column s ON c.tab_sid = p.tab_sid AND c.column_sid = ctb.user_company_col_sid
		   LEFT JOIN csr.customer_flow_capability cfc ON cfc.flow_capability_id = ctb.flow_capability_id
		  ORDER BY ctb.user_company_type_id, ctb.page_company_type_id, ctb.pos;

	OPEN out_headers_cur FOR
		SELECT ch.pos, ch.viewing_own_company,
			ctp.lookup_key page_company_type_lookup, ctu.lookup_key user_company_type_lookup, 
			p.plugin_id, p.js_class, p.form_path, p.group_key, p.plugin_type_id
		  FROM chain.company_header ch
		  JOIN chain.company_type ctp ON ctp.company_type_id = ch.page_company_type_id
		  JOIN chain.company_type ctu ON ctu.company_type_id = ch.user_company_type_id
		  JOIN csr.plugin p ON p.plugin_id = ch.plugin_id
		 ORDER BY ch.user_company_type_id, ch.page_company_type_id, ch.pos;
END;

PROCEDURE SetCompanyTab (
	in_page_company_type_id			IN	company.company_type_id%TYPE,
	in_user_company_type_id			IN	company.company_type_id%TYPE,
	in_viewing_own_company			IN	company_tab.viewing_own_company%TYPE,
	in_plugin_id					IN	company_tab.plugin_id%TYPE,
	in_pos							IN	company_tab.pos%TYPE,
	in_label						IN	company_tab.label%TYPE,
	in_options						IN	company_tab.options%TYPE,
	in_page_company_col_sid			IN	company_tab.page_company_col_sid%TYPE DEFAULT NULL,
	in_user_company_col_sid			IN	company_tab.user_company_col_sid%TYPE DEFAULT NULL,
	in_flow_capability_id			IN	company_tab.flow_capability_id%TYPE DEFAULT NULL,
	in_bus_rel_type_id				IN	company_tab.business_relationship_type_id%TYPE DEFAULT NULL,
	in_default_saved_filter_sid		IN	company_tab.default_saved_filter_sid%TYPE DEFAULT NULL,
	in_related_company_type_ids		IN	security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_company_tab_id				IN	company_tab.company_tab_id%TYPE DEFAULT 0,
	in_supplier_restriction 		IN	NUMBER DEFAULT 0,
	in_company_type_role_ids		IN	security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_company_type_is_role_ids		IN	security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt							NUMBER;
	v_pos 							company_tab.pos%TYPE;
	v_tab_sid						security_pkg.T_SID_ID;
	v_js_class						csr.plugin.js_class%TYPE;
	v_page_company_col_sid			company_tab.page_company_col_sid%TYPE := in_page_company_col_sid;
	v_user_company_col_sid			company_tab.user_company_col_sid%TYPE := in_user_company_col_sid;
	v_company_tab_id				company_tab.company_tab_id%TYPE := in_company_tab_id;
	v_related_company_type_tab		security.T_SID_TABLE;
	v_company_type_role_ids			security.T_SID_TABLE;
	v_company_type_is_role_ids		security.T_SID_TABLE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify company plugins');
	END IF;
	
	v_pos := in_pos;
	
	IF in_pos < 0 THEN
		SELECT NVL(max(pos) + 1, 1) 
		  INTO v_pos 
		  FROM company_tab
		 WHERE page_company_type_id = in_page_company_type_id
		   AND user_company_type_id = in_user_company_type_id
		   AND viewing_own_company = in_viewing_own_company;
	END IF;
	
	IF in_page_company_col_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid
		 WHERE tc.column_sid = in_page_company_col_sid
		   AND tc.app_sid = security_pkg.getapp;
		   
		IF v_cnt != 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The column with SID: '||in_page_company_col_sid||' does not belong to table used by plugin with ID: '||in_plugin_id);
		END IF;
	END IF;
	
	IF in_user_company_col_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid
		 WHERE tc.column_sid = in_user_company_col_sid
		   AND tc.app_sid = security_pkg.getapp;
		   
		IF v_cnt != 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The column with SID: '||in_user_company_col_sid||' does not belong to table used by plugin with ID: '||in_plugin_id);
		END IF;
	END IF;

	v_related_company_type_tab := security_pkg.SidArrayToTable(in_related_company_type_ids);

	IF in_company_tab_id = 0 THEN
		INSERT INTO company_tab (company_tab_id, page_company_type_id, user_company_type_id,
								 plugin_type_id, plugin_id, pos, label, 
								 viewing_own_company, options, page_company_col_sid, user_company_col_sid,
								 flow_capability_id, business_relationship_type_id, default_saved_filter_sid, supplier_restriction)
			VALUES (company_tab_id_seq.NEXTVAL, in_page_company_type_id, in_user_company_type_id, 
			        csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB, in_plugin_id, v_pos, in_label, 
					in_viewing_own_company, in_options, v_page_company_col_sid, v_user_company_col_sid,
					in_flow_capability_id, in_bus_rel_type_id, in_default_saved_filter_sid, in_supplier_restriction)
			RETURNING company_tab_id INTO v_company_tab_id;

			--the first time we set the tab to a cms plugin, enable the FILTER_ON_CMS_COMPANIES capability 	
		SELECT tab_sid, js_class 
		  INTO v_tab_sid, v_js_class
		  FROM csr.plugin
		 WHERE plugin_id = in_plugin_id;

		IF v_tab_sid IS NOT NULL AND LOWER(v_js_class) = LOWER('Chain.ManageCompany.CmsTab') THEN
			chain.type_capability_pkg.SetPermission(company_type_pkg.GetLookupKey(in_user_company_type_id), chain_pkg.USER_GROUP, chain_pkg.FILTER_ON_CMS_COMPANIES);
		END IF;
		
	ELSE
		v_company_tab_id := in_company_tab_id;

		UPDATE company_tab
		   SET pos = v_pos,
			   label = in_label,
			   options = in_options,
			   page_company_col_sid = v_page_company_col_sid,
			   user_company_col_sid = v_user_company_col_sid,
			   flow_capability_id = in_flow_capability_id,
			   business_relationship_type_id = in_bus_rel_type_id,
			   default_saved_filter_sid = in_default_saved_filter_sid,
			   supplier_restriction = in_supplier_restriction
		 WHERE company_tab_id = v_company_tab_id;

		 DELETE FROM company_tab_related_co_type
		  WHERE company_tab_id = v_company_tab_id;
	END IF;
		 
	FOR r IN (
		SELECT column_value 
		  FROM TABLE(v_related_company_type_tab) rct
		  JOIN company_type ct ON ct.company_type_id = rct.column_value
	) LOOP
		INSERT INTO company_tab_related_co_type (company_tab_id, company_type_id)
		VALUES (v_company_tab_id, r.column_value);
	END LOOP;

	v_company_type_role_ids := security_pkg.SidArrayToTable(in_company_type_role_ids);
	v_company_type_is_role_ids := security_pkg.SidArrayToTable(in_company_type_is_role_ids);

	DELETE FROM company_tab_company_type_role ctctr
	 WHERE ctctr.company_tab_id = v_company_tab_id
	   AND NOT EXISTS (
		SELECT t.company_group_type_id, t.company_type_role_id
		  FROM (
			SELECT CASE WHEN t2.is_role = 0 THEN t1.company_type_role_id ELSE NULL END company_group_type_id,
				   CASE WHEN t2.is_role = 1 THEN t1.company_type_role_id ELSE NULL END company_type_role_id
			  FROM (SELECT ROWNUM rn, column_value company_type_role_id FROM TABLE(v_company_type_role_ids)) t1
			  JOIN (SELECT ROWNUM rn, column_value is_role FROM TABLE(v_company_type_is_role_ids)) t2
			    ON t1.rn = t2.rn
			) t
		 WHERE (t.company_group_type_id IS NULL OR ctctr.company_group_type_id = t.company_group_type_id)
		   AND (t.company_type_role_id IS NULL OR ctctr.company_type_role_id = t.company_type_role_id)
	);

	INSERT INTO company_tab_company_type_role (comp_tab_comp_type_role_id, company_tab_id, company_group_type_id, company_type_role_id)
	SELECT comp_tab_comp_type_role_id_seq.NEXTVAL, v_company_tab_id, company_group_type_id, company_type_role_id
	  FROM (
		SELECT company_group_type_id, company_type_role_id
		  FROM (
			SELECT CASE WHEN t2.is_role = 0 THEN t1.company_type_role_id ELSE NULL END company_group_type_id,
				   CASE WHEN t2.is_role = 1 THEN t1.company_type_role_id ELSE NULL END company_type_role_id
			  FROM (SELECT ROWNUM rn, column_value company_type_role_id FROM TABLE(v_company_type_role_ids)) t1
			  JOIN (SELECT ROWNUM rn, column_value is_role FROM TABLE(v_company_type_is_role_ids)) t2
				ON t1.rn = t2.rn
		  ) t
		 WHERE NOT EXISTS (
			SELECT company_group_type_id, company_type_role_id
			  FROM chain.company_tab_company_type_role ctctr
			 WHERE ctctr.company_tab_id = v_company_tab_id
			   AND (ctctr.company_group_type_id IS NULL OR t.company_group_type_id = ctctr.company_group_type_id)
			   AND (ctctr.company_type_role_id IS NULL OR t.company_type_role_id = ctctr.company_type_role_id)
		)
	);

	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description, 
		       p.details, p.preview_image_path, ctb.label, ctb.pos, ctb.page_company_type_id, 
			   ctb.user_company_type_id, ctb.viewing_own_company, p.tab_sid, p.form_path, p.group_key, p.control_lookup_keys,
			   ctb.options, ctb.page_company_col_sid, ctb.user_company_col_sid, ctb.flow_capability_id,
			   ctb.company_tab_id, business_relationship_type_id
		  FROM csr.plugin p
		  JOIN company_tab ctb 
		    ON p.plugin_id = ctb.plugin_id
		 WHERE ctb.company_tab_id = v_company_tab_id;
END;

PROCEDURE SetCompanyTab (
	in_page_company_type_lookup			IN  company_type.lookup_key%TYPE,
	in_user_company_type_lookup			IN  company_type.lookup_key%TYPE,
	in_viewing_own_company				IN  company_tab.viewing_own_company%TYPE,
	in_js_class							IN  csr.plugin.js_class%TYPE,
	in_form_path						IN  csr.plugin.form_path%TYPE,
	in_group_key						IN  csr.plugin.group_key%TYPE,
	in_pos								IN  company_tab.pos%TYPE,
	in_label							IN  company_tab.label%TYPE,
	in_options							IN  company_tab.options%TYPE,
	in_page_company_col_name			IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_user_company_col_name			IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_flow_capability_id				IN	company_tab.flow_capability_id%TYPE DEFAULT NULL,
	in_bus_rel_type_lookup				IN	business_relationship_type.lookup_key%TYPE DEFAULT NULL,
	in_supplier_restriction				IN  NUMBER DEFAULT 0
)
AS
	v_plugin_id					csr.plugin.plugin_id%TYPE;
	v_page_company_type_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_page_company_type_lookup);
	v_user_company_type_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_user_company_type_lookup);
	v_page_company_col_sid		company_tab.page_company_col_sid%TYPE DEFAULT NULL;
	v_user_company_col_sid		company_tab.user_company_col_sid%TYPE DEFAULT NULL;
	v_bus_rel_type_id			company_tab.business_relationship_type_id%TYPE DEFAULT NULL;
	v_cur			security_pkg.T_OUTPUT_CUR;
BEGIN
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM csr.plugin
	 WHERE lower(js_class) = lower(in_js_class)
	   AND (form_path = in_form_path OR in_form_path IS NULL)
	   AND (group_key = in_group_key OR in_group_key IS NULL);

	BEGIN
		SELECT tc.column_sid
		  INTO v_page_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_page_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_page_company_col_sid := NULL;
	END;
	
	BEGIN
		SELECT tc.column_sid
		  INTO v_user_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_user_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_user_company_col_sid := NULL;
	END;

	BEGIN
		SELECT business_relationship_type_id
		  INTO v_bus_rel_type_id
		  FROM business_relationship_type
		 WHERE UPPER(lookup_key) = UPPER(in_bus_rel_type_lookup);
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_bus_rel_type_id := NULL;
	END;
	
	SetCompanyTab (
		in_page_company_type_id		=> v_page_company_type_id,
		in_user_company_type_id		=> v_user_company_type_id,
		in_viewing_own_company		=> in_viewing_own_company,
		in_plugin_id				=> v_plugin_id,
		in_pos						=> in_pos,
		in_label					=> in_label,
		in_options					=> in_options,
		in_page_company_col_sid		=> v_page_company_col_sid,
		in_user_company_col_sid		=> v_user_company_col_sid,
		in_flow_capability_id		=> in_flow_capability_id,
		in_bus_rel_type_id			=> v_bus_rel_type_id,
		in_supplier_restriction		=> in_supplier_restriction,
		out_cur						=> v_cur
	);
END;


PROCEDURE RemoveCompanyTab (
	in_company_tab_id				IN  company_tab.company_tab_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify company plugins');
	END IF;

	DELETE FROM company_tab_related_co_type
	 WHERE company_tab_id = in_company_tab_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM company_tab_company_type_role
	 WHERE company_tab_id = in_company_tab_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM company_tab
	 WHERE company_tab_id = in_company_tab_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE GetCompanyHeaders (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_headers_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_page_company_type_id	company.company_type_id%TYPE;
	v_user_company_type_id	company.company_type_id%TYPE;
	v_viewing_own_company	company_header.viewing_own_company%TYPE;
BEGIN	 
	SELECT company_type_id
	  INTO v_user_company_type_id
	  FROM v$company
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	 
	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		v_viewing_own_company := 1;
		v_page_company_type_id := v_user_company_type_id;
	ELSE
		v_viewing_own_company := 0;
		
		SELECT company_type_id
		  INTO v_page_company_type_id
		  FROM v$company
		 WHERE company_sid = in_company_sid;
	END IF;
	 
	GetCompanyHeaders(v_page_company_type_id, v_user_company_type_id, v_viewing_own_company, out_headers_cur);
END;
	 
PROCEDURE GetCompanyHeaders (	
	in_page_company_type_id			IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_company			IN  company_header.viewing_own_company%TYPE,
	out_headers_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	OPEN out_headers_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description, 
		       p.details, p.preview_image_path, ch.pos, ch.page_company_type_id, ch.user_company_type_id,
			   ch.viewing_own_company, p.tab_sid, p.form_path, p.group_key, p.control_lookup_keys,
			   ch.page_company_col_sid, ch.user_company_col_sid, p.form_sid, ch.company_header_id
		  FROM csr.plugin p
		  JOIN company_header ch
		    ON p.plugin_id = ch.plugin_id
		 WHERE (in_page_company_type_id IS NULL OR ch.page_company_type_id = in_page_company_type_id)
		   AND (in_user_company_type_id IS NULL OR ch.user_company_type_id = in_user_company_type_id)
		   AND viewing_own_company = in_viewing_own_company
		 ORDER BY ch.pos;
	
END;

PROCEDURE SetCompanyHeader (
	in_page_company_type_id			IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_company			IN  company_header.viewing_own_company%TYPE,
	in_plugin_id					IN  company_header.plugin_id%TYPE,
	in_pos							IN  company_header.pos%TYPE,
	in_page_company_col_sid			IN	company_tab.page_company_col_sid%TYPE DEFAULT NULL,
	in_user_company_col_sid			IN	company_tab.user_company_col_sid%TYPE DEFAULT NULL,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt							NUMBER;
	v_pos							company_header.pos%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify company plugins');
	END IF;
	
	v_pos := in_pos;
	
	IF in_pos < 0 THEN
		SELECT NVL(max(pos) + 1, 1) 
		  INTO v_pos 
		  FROM company_header
		 WHERE page_company_type_id = in_page_company_type_id
		   AND user_company_type_id = in_user_company_type_id
		   AND viewing_own_company = in_viewing_own_company;
	END IF;

	IF in_page_company_col_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid
		 WHERE tc.column_sid = in_page_company_col_sid
		   AND tc.app_sid = security_pkg.getapp;
		   
		IF v_cnt != 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The column with SID: '||in_page_company_col_sid||' does not belong to table used by plugin with ID: '||in_plugin_id);
		END IF;
	END IF;
	
	IF in_user_company_col_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid
		 WHERE tc.column_sid = in_user_company_col_sid
		   AND tc.app_sid = security_pkg.getapp;
		   
		IF v_cnt != 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The column with SID: '||in_user_company_col_sid||' does not belong to table used by plugin with ID: '||in_plugin_id);
		END IF;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM company_header
	 WHERE page_company_type_id = in_page_company_type_id
	   AND user_company_type_id = in_user_company_type_id
	   AND plugin_id = in_plugin_id
	   AND viewing_own_company = in_viewing_own_company;
	
	IF v_cnt = 0 THEN
		INSERT INTO company_header (company_header_id, page_company_type_id, user_company_type_id,
		                            plugin_type_id, plugin_id, pos, viewing_own_company,
									page_company_col_sid, user_company_col_sid)
			VALUES (company_header_id_seq.NEXTVAL, in_page_company_type_id, in_user_company_type_id, 
			        csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_HEAD, in_plugin_id, v_pos, in_viewing_own_company,
					in_page_company_col_sid, in_user_company_col_sid);
	ELSE
		UPDATE company_header
		   SET pos = v_pos,
			   page_company_col_sid = in_page_company_col_sid,
			   user_company_col_sid = in_user_company_col_sid
		 WHERE page_company_type_id = in_page_company_type_id
		   AND user_company_type_id = in_user_company_type_id
		   AND plugin_id = in_plugin_id
		   AND viewing_own_company = in_viewing_own_company;
	END IF;
		 
	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description, 
		       p.details, p.preview_image_path, ch.pos, ch.page_company_type_id, ch.user_company_type_id,
			   viewing_own_company, p.tab_sid, p.form_path, p.group_key, p.control_lookup_keys,
			   ch.page_company_col_sid, ch.user_company_col_sid
		  FROM csr.plugin p
		  JOIN company_header ch
		    ON p.plugin_id = ch.plugin_id
		 WHERE ch.page_company_type_id = in_page_company_type_id
		   AND ch.user_company_type_id = in_user_company_type_id
		   AND ch.viewing_own_company = in_viewing_own_company
		   AND ch.plugin_id = in_plugin_id;
END;


PROCEDURE SetCompanyHeader (
	in_page_company_type_lookup			IN  company_type.lookup_key%TYPE,
	in_user_company_type_lookup			IN  company_type.lookup_key%TYPE,
	in_viewing_own_company				IN  company_tab.viewing_own_company%TYPE,
	in_js_class							IN  csr.plugin.js_class%TYPE,
	in_form_path						IN  csr.plugin.form_path%TYPE,
	in_group_key						IN  csr.plugin.group_key%TYPE,
	in_pos								IN  company_tab.pos%TYPE,
	in_page_company_col_name			IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL,
	in_user_company_col_name			IN	cms.tab_column.oracle_column%TYPE DEFAULT NULL
)
AS
	v_plugin_id					csr.plugin.plugin_id%TYPE;
	v_page_company_type_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_page_company_type_lookup);
	v_user_company_type_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_user_company_type_lookup);
	v_page_company_col_sid		company_tab.page_company_col_sid%TYPE DEFAULT NULL;
	v_user_company_col_sid		company_tab.user_company_col_sid%TYPE DEFAULT NULL;
	v_cur			security_pkg.T_OUTPUT_CUR;
BEGIN
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM csr.plugin
	 WHERE lower(js_class) = lower(in_js_class)
	   AND (form_path = in_form_path OR in_form_path IS NULL)
	   AND (group_key = in_group_key OR in_group_key IS NULL);

	BEGIN
		SELECT tc.column_sid
		  INTO v_page_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_page_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_page_company_col_sid := NULL;
	END;
	
	BEGIN
		SELECT tc.column_sid
		  INTO v_user_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_user_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_user_company_col_sid := NULL;
	END;

	SetCompanyHeader (
		in_page_company_type_id		=> v_page_company_type_id,
		in_user_company_type_id		=> v_user_company_type_id,
		in_viewing_own_company		=> in_viewing_own_company,
		in_plugin_id				=> v_plugin_id,
		in_pos						=> in_pos,
		in_page_company_col_sid		=> v_page_company_col_sid,
		in_user_company_col_sid		=> v_user_company_col_sid,
		out_cur						=> v_cur
	);
END;

PROCEDURE RemoveCompanyHeader (
	in_company_header_id				IN  company_header.company_header_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify company plugins');
	END IF;
	
	DELETE FROM company_header
	 WHERE company_header_id = in_company_header_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE RemoveCompanyPlugin (	
	in_plugin_id					IN  csr.plugin.plugin_id%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT company_tab_id
		  FROM company_tab
		 WHERE plugin_id = in_plugin_id
	) LOOP
		RemoveCompanyTab(r.company_tab_id);
	END LOOP;
	
	FOR r IN (
		SELECT company_header_id
		  FROM company_header
		 WHERE plugin_id = in_plugin_id
	) LOOP
		RemoveCompanyHeader(r.company_header_id);
	END LOOP;
END;

PROCEDURE GetProductHeaders (
	in_product_id					IN  company_product.product_id%TYPE,
	out_headers_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_product_company_sid			company_product.company_sid%TYPE;
	v_product_type_id				company_product.product_type_id%TYPE;
	v_product_company_type_id		company.company_type_id%TYPE;
	v_user_company_type_id			company.company_type_id%TYPE;
	v_viewing_own_product			product_header.viewing_own_product%TYPE := 0;
	v_viewing_as_supplier			product_header.viewing_as_supplier%TYPE := 1;
BEGIN	 
	SELECT product_type_id, company_sid
	  INTO v_product_type_id, v_product_company_sid
	  FROM company_product
	 WHERE product_id = in_product_id;

	SELECT company_type_id
	  INTO v_product_company_type_id
	  FROM v$company
	 WHERE company_sid = v_product_company_sid;

	SELECT company_type_id
	  INTO v_user_company_type_id
	  FROM v$company
	 WHERE company_sid = v_company_sid;
	 
	IF v_product_company_sid = v_company_sid THEN
		v_viewing_own_product := 1;

		IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
			v_viewing_as_supplier := 0;
		END IF;
	ELSE
		v_viewing_own_product := 0;

		IF type_capability_pkg.CheckCapability(v_company_sid, v_product_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
			v_viewing_as_supplier := 0;
		END IF;
	END IF;
 
	GetProductHeaders(v_product_type_id, v_product_company_type_id, v_user_company_type_id, v_viewing_own_product, v_viewing_as_supplier, out_headers_cur, out_product_types_cur);
END;
	 
PROCEDURE GetProductHeaders (	
	in_product_type_id				IN  company_product.product_type_id%TYPE,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_header.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_header.viewing_as_supplier%TYPE,
	out_headers_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_header_ids			security.T_SID_TABLE;
BEGIN
	SELECT DISTINCT ph.product_header_id
	  BULK COLLECT into v_product_header_ids
	  FROM product_header ph
	  LEFT JOIN (
			SELECT phpt.product_header_id, pt_tree.product_type_id
			  FROM product_header_product_type phpt
			  JOIN (
			  		SELECT product_type_id
					  FROM product_type
					 START WITH product_type_id = in_product_type_id
				   CONNECT BY product_type_id = PRIOR parent_product_type_id
			  ) pt_tree ON pt_tree.product_type_id = phpt.product_type_id
		   ) phpt_t ON phpt_t.product_header_id = ph.product_header_id
	 WHERE (in_viewing_own_product IS NULL OR ph.viewing_own_product IS NULL OR ph.viewing_own_product = in_viewing_own_product)
	   AND (in_viewing_as_supplier IS NULL OR ph.viewing_as_supplier IS NULL OR ph.viewing_as_supplier = in_viewing_as_supplier)
	   AND (in_product_type_id IS NULL OR phpt_t.product_type_id IS NOT NULL)
	   AND (in_product_company_type_id IS NULL OR ph.product_company_type_id = in_product_company_type_id)
	   AND (in_user_company_type_id IS NULL OR ph.user_company_type_id = in_user_company_type_id);

	OPEN out_headers_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, 
			   p.description, p.details, p.preview_image_path,
			   p.tab_sid, p.form_sid, p.form_path, p.group_key, p.control_lookup_keys,
			   ph.product_header_id, ph.pos,
			   ph.product_company_type_id, ph.user_company_type_id,
			   ph.viewing_own_product, ph.viewing_as_supplier, 
			   ph.product_col_sid, ph.user_company_col_sid
		  FROM csr.plugin p
		  JOIN product_header ph ON ph.plugin_id = p.plugin_id
		  JOIN TABLE(v_product_header_ids) t ON t.column_value = ph.product_header_id
		 ORDER BY ph.pos;

	OPEN out_product_types_cur FOR
		SELECT product_header_id, product_type_id
		  FROM product_header_product_type
		  JOIN TABLE(v_product_header_ids) t ON t.column_value = product_header_id;
END;

PROCEDURE SetProductHeader (
	in_product_header_id			IN  product_header.product_header_id%TYPE,
	in_plugin_id					IN  product_header.plugin_id%TYPE,
	in_product_type_ids				IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_header.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_header.viewing_as_supplier%TYPE,
	in_pos							IN  product_header.pos%TYPE,
	in_product_col_sid				IN	product_header.product_col_sid%TYPE DEFAULT NULL,
	in_user_company_col_sid			IN	product_header.user_company_col_sid%TYPE DEFAULT NULL,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt							NUMBER;
	v_pos							company_header.pos%TYPE;
	v_product_header_id				product_header.product_header_id%TYPE;
	v_product_type_ids				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_product_type_ids);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify product plugins');
	END IF;
	
	v_pos := in_pos;
	
	IF in_pos < 0 THEN
		SELECT NVL(max(pos) + 1, 1) 
		  INTO v_pos 
		  FROM company_header;
	END IF;

	IF in_product_col_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid
		 WHERE tc.column_sid = in_product_col_sid
		   AND tc.app_sid = security_pkg.getapp;
		   
		IF v_cnt != 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The column with SID: '||in_product_col_sid||' does not belong to table used by plugin with ID: '||in_plugin_id);
		END IF;
	END IF;
	
	IF in_user_company_col_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid
		 WHERE tc.column_sid = in_user_company_col_sid
		   AND tc.app_sid = security_pkg.getapp;
		   
		IF v_cnt != 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The column with SID: '||in_user_company_col_sid||' does not belong to table used by plugin with ID: '||in_plugin_id);
		END IF;
	END IF;

	IF in_product_header_id IS NULL THEN
		INSERT INTO product_header (
			product_header_id, plugin_type_id, 
			plugin_id, pos,
			product_company_type_id, user_company_type_id,
			viewing_own_product, viewing_as_supplier,
			product_col_sid, user_company_col_sid
		) VALUES (
			product_header_id_seq.NEXTVAL, csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_PRODUCT_HEAD, 
			in_plugin_id, v_pos,
			in_product_company_type_id, in_user_company_type_id,
			in_viewing_own_product, in_viewing_as_supplier,
			in_product_col_sid, in_user_company_col_sid
		) RETURNING product_header_id INTO v_product_header_id;
	ELSE
		UPDATE product_header
		   SET pos = v_pos,
			   product_company_type_id = in_product_company_type_id,
			   user_company_type_id = in_user_company_type_id,
			   viewing_own_product = in_viewing_own_product,
			   viewing_as_supplier = in_viewing_as_supplier,
			   product_col_sid = in_product_col_sid,
			   user_company_col_sid = in_user_company_col_sid
		 WHERE product_header_id = in_product_header_id;

		 v_product_header_id := in_product_header_id;
	END IF;
	
	DELETE FROM product_header_product_type WHERE product_header_id = v_product_header_id;

	INSERT INTO product_header_product_type (product_header_id, product_type_id)
		 SELECT v_product_header_id, column_value
		   FROM TABLE(v_product_type_ids);

	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, 
			   p.description, p.details, p.preview_image_path,
			   p.tab_sid, p.form_sid, p.form_path, p.group_key, p.control_lookup_keys,
			   ph.product_header_id, ph.pos, 
			   ph.product_company_type_id, ph.user_company_type_id,
			   ph.viewing_own_product, ph.viewing_as_supplier,
			   ph.product_col_sid, ph.user_company_col_sid
		  FROM csr.plugin p
		  JOIN product_header ph ON ph.plugin_id = p.plugin_id
		 WHERE ph.product_header_id = v_product_header_id;
END;

PROCEDURE SetProductHeader (
	in_product_type_keys			IN  VARCHAR2,
	in_product_company_type_key		IN  company_type.lookup_key%TYPE,
	in_user_company_type_key		IN  company_type.lookup_key%TYPE,
	in_viewing_own_product			IN  product_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_tab.viewing_as_supplier%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_form_path					IN  csr.plugin.form_path%TYPE,
	in_group_key					IN  csr.plugin.group_key%TYPE,
	in_pos							IN  company_tab.pos%TYPE,
	in_product_col_name				IN	cms.tab_column.oracle_column%TYPE,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE
)
AS
	v_plugin_id						csr.plugin.plugin_id%TYPE;
	v_product_company_type_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_product_company_type_key);
	v_user_company_type_id			company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_user_company_type_key);
	v_product_col_sid				security.security_pkg.T_SID_ID;
	v_user_company_col_sid			security.security_pkg.T_SID_ID;
	v_product_type_ids				security_pkg.T_SID_IDS;
	v_cur							security_pkg.T_OUTPUT_CUR;
BEGIN
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM csr.plugin
	 WHERE lower(js_class) = lower(in_js_class)
	   AND (form_path = in_form_path OR in_form_path IS NULL)
	   AND (group_key = in_group_key OR in_group_key IS NULL);

	BEGIN
		SELECT tc.column_sid
		  INTO v_product_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_product_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_product_col_sid := NULL;
	END;
	
	BEGIN
		SELECT tc.column_sid
		  INTO v_user_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_user_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_user_company_col_sid := NULL;
	END;
	
	SELECT pt.product_type_id
	  BULK COLLECT INTO v_product_type_ids
	  FROM product_type pt
	  JOIN TABLE(aspen2.utils_pkg.SplitString(in_product_type_keys, ',')) t ON UPPER(t.item) = UPPER(pt.lookup_key);
	
	SetProductHeader (
		in_product_header_id			=> NULL,
		in_plugin_id					=> v_plugin_id,
		in_product_type_ids				=> v_product_type_ids,
		in_product_company_type_id		=> v_product_company_type_id,
		in_user_company_type_id			=> v_user_company_type_id,
		in_viewing_own_product			=> in_viewing_own_product,
		in_viewing_as_supplier			=> in_viewing_as_supplier,
		in_pos							=> in_pos,
		in_product_col_sid				=> v_product_col_sid,
		in_user_company_col_sid			=> v_user_company_col_sid,
		out_cur							=> v_cur
	);
END;

PROCEDURE RemoveProductHeader (
	in_product_header_id			IN  product_header.product_header_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify product plugins');
	END IF;
	
	DELETE FROM product_header_product_type
	 WHERE product_header_id = in_product_header_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM product_header
	 WHERE product_header_id = in_product_header_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE GetProductTabs (
	in_product_id					IN  company_product.product_id%TYPE,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_product_company_sid			company_product.company_sid%TYPE;
	v_product_type_id				company_product.product_type_id%TYPE;
	v_product_company_type_id		company.company_type_id%TYPE;
	v_user_company_type_id			company.company_type_id%TYPE;
	v_viewing_own_product			product_tab.viewing_own_product%TYPE := 0;
	v_viewing_as_supplier			product_tab.viewing_own_product%TYPE := 1;
BEGIN	 
	SELECT product_type_id, company_sid
	  INTO v_product_type_id, v_product_company_sid
	  FROM company_product
	 WHERE product_id = in_product_id;

	SELECT company_type_id
	  INTO v_product_company_type_id
	  FROM v$company
	 WHERE company_sid = v_product_company_sid;

	SELECT company_type_id
	  INTO v_user_company_type_id
	  FROM v$company
	 WHERE company_sid = v_company_sid;
	
	IF v_product_company_sid = v_company_sid THEN
		v_viewing_own_product := 1;

		IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
			v_viewing_as_supplier := 0;
		END IF;
	ELSE
		v_viewing_own_product := 0;

		IF type_capability_pkg.CheckCapability(v_company_sid, v_product_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
			v_viewing_as_supplier := 0;
		END IF;
	END IF;
	 
	GetProductTabs(v_product_type_id, v_product_company_type_id, v_user_company_type_id, v_viewing_own_product, v_viewing_as_supplier, out_tabs_cur, out_product_types_cur);
END;
	 
PROCEDURE GetProductTabs (
	in_product_type_id				IN  company_product.product_type_id%TYPE,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_tab.viewing_as_supplier%TYPE,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_tab_ids				security.T_SID_TABLE;
BEGIN	
	SELECT DISTINCT pt.product_tab_id
	  BULK COLLECT into v_product_tab_ids
	  FROM product_tab pt
	  LEFT JOIN (
			SELECT ptpt.product_tab_id, pt_tree.product_type_id
			  FROM product_tab_product_type ptpt
			  JOIN (
			  		SELECT product_type_id
					  FROM product_type
					 START WITH product_type_id = in_product_type_id
				   CONNECT BY product_type_id = PRIOR parent_product_type_id
			  ) pt_tree ON pt_tree.product_type_id = ptpt.product_type_id
		   ) ptpt_t ON ptpt_t.product_tab_id = pt.product_tab_id
	 WHERE (in_viewing_own_product IS NULL OR pt.viewing_own_product IS NULL OR pt.viewing_own_product = in_viewing_own_product)
	   AND (in_viewing_as_supplier IS NULL OR pt.viewing_as_supplier IS NULL OR pt.viewing_as_supplier = in_viewing_as_supplier)
	   AND (in_product_type_id IS NULL OR ptpt_t.product_type_id IS NOT NULL)
	   AND (in_product_company_type_id IS NULL OR pt.product_company_type_id = in_product_company_type_id)
	   AND (in_user_company_type_id IS NULL OR pt.user_company_type_id = in_user_company_type_id);

	OPEN out_tabs_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, 
			   p.description, p.details, p.preview_image_path,
			   p.tab_sid, p.form_sid, p.form_path, p.group_key, p.control_lookup_keys,
			   pt.product_tab_id, pt.pos,
			   pt.product_company_type_id, pt.user_company_type_id,
			   pt.viewing_own_product, pt.viewing_as_supplier,
			   pt.label, pt.product_col_sid, pt.user_company_col_sid,
			   p.saved_filter_sid, p.result_mode, p.pre_filter_sid
		  FROM csr.plugin p
		  JOIN product_tab pt ON pt.plugin_id = p.plugin_id
		  JOIN TABLE(v_product_tab_ids) t ON pt.product_tab_id = t.column_value
		 ORDER BY pt.pos;
	
	OPEN out_product_types_cur FOR
		SELECT product_tab_id, product_type_id
		  FROM product_tab_product_type
		  JOIN TABLE(v_product_tab_ids) t ON t.column_value = product_tab_id;
END;

PROCEDURE SetProductTab (
	in_product_tab_id				IN  product_tab.product_tab_id%TYPE,
	in_plugin_id					IN  product_tab.plugin_id%TYPE,
	in_product_type_ids				IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_tab.viewing_as_supplier%TYPE,
	in_pos							IN  product_tab.pos%TYPE,
	in_label						IN  product_tab.label%TYPE,
	in_product_col_sid				IN	product_tab.product_col_sid%TYPE DEFAULT NULL,
	in_user_company_col_sid			IN	product_tab.user_company_col_sid%TYPE DEFAULT NULL,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt							NUMBER;
	v_pos							company_tab.pos%TYPE;
	v_product_tab_id				product_tab.product_tab_id%TYPE;
	v_product_type_ids				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_product_type_ids);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify product plugins');
	END IF;
	
	v_pos := in_pos;
	
	IF in_pos < 0 THEN
		SELECT NVL(max(pos) + 1, 1) 
		  INTO v_pos 
		  FROM company_tab;
	END IF;

	IF in_product_col_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid
		 WHERE tc.column_sid = in_product_col_sid
		   AND tc.app_sid = security_pkg.getapp;
		   
		IF v_cnt != 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The column with SID: '||in_product_col_sid||' does not belong to table used by plugin with ID: '||in_plugin_id);
		END IF;
	END IF;
	
	IF in_user_company_col_sid IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = in_plugin_id AND p.tab_sid = tc.tab_sid
		 WHERE tc.column_sid = in_user_company_col_sid
		   AND tc.app_sid = security_pkg.getapp;
		   
		IF v_cnt != 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The column with SID: '||in_user_company_col_sid||' does not belong to table used by plugin with ID: '||in_plugin_id);
		END IF;
	END IF;

	IF in_product_tab_id IS NULL THEN
		INSERT INTO product_tab (
			product_tab_id, plugin_type_id, 
			plugin_id, pos, label, 
			product_company_type_id, user_company_type_id,
			viewing_own_product, viewing_as_supplier,
			product_col_sid, user_company_col_sid
		) VALUES (
			product_tab_id_seq.NEXTVAL, csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_PRODUCT_TAB, 
			in_plugin_id, v_pos, in_label,
			in_product_company_type_id, in_user_company_type_id,
			in_viewing_own_product, in_viewing_as_supplier,
			in_product_col_sid, in_user_company_col_sid
		) RETURNING product_tab_id INTO v_product_tab_id;
	ELSE
		UPDATE product_tab
		   SET pos = v_pos,
			   label = in_label,
			   product_company_type_id = in_product_company_type_id,
			   user_company_type_id = in_user_company_type_id,
			   viewing_own_product = in_viewing_own_product,
			   viewing_as_supplier = in_viewing_as_supplier,
			   product_col_sid = in_product_col_sid,
			   user_company_col_sid = in_user_company_col_sid
		 WHERE product_tab_id = in_product_tab_id;

		v_product_tab_id := in_product_tab_id;
	END IF;
	
	DELETE FROM product_tab_product_type WHERE product_tab_id = v_product_tab_id;

	INSERT INTO product_tab_product_type (product_tab_id, product_type_id)
		 SELECT v_product_tab_id, column_value
		   FROM TABLE(v_product_type_ids);

	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, 
			   p.description, p.details, p.preview_image_path,
			   p.tab_sid, p.form_sid, p.form_path, p.group_key, p.control_lookup_keys,
			   pt.product_tab_id, pt.pos, pt.label,
			   pt.product_company_type_id, pt.user_company_type_id,
			   pt.viewing_own_product, pt.viewing_as_supplier,
			   pt.product_col_sid, pt.user_company_col_sid
		  FROM csr.plugin p
		  JOIN product_tab pt ON pt.plugin_id = p.plugin_id
		 WHERE pt.product_tab_id = v_product_tab_id;
END;

PROCEDURE SetProductTab (
	in_product_type_keys			IN  VARCHAR2,
	in_product_company_type_key		IN  company_type.lookup_key%TYPE,
	in_user_company_type_key		IN  company_type.lookup_key%TYPE,
	in_viewing_own_product			IN  product_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_tab.viewing_as_supplier%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_form_path					IN  csr.plugin.form_path%TYPE,
	in_group_key					IN  csr.plugin.group_key%TYPE,
	in_pos							IN  company_tab.pos%TYPE,
	in_label						IN  company_tab.label%TYPE,
	in_product_col_name				IN	cms.tab_column.oracle_column%TYPE,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE
)
AS
	v_plugin_id						csr.plugin.plugin_id%TYPE;
	v_product_company_type_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_product_company_type_key);
	v_user_company_type_id			company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_user_company_type_key);
	v_product_col_sid				security.security_pkg.T_SID_ID;
	v_user_company_col_sid			security.security_pkg.T_SID_ID;
	v_product_type_ids				security_pkg.T_SID_IDS;
	v_cur							security_pkg.T_OUTPUT_CUR;
BEGIN
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM csr.plugin
	 WHERE lower(js_class) = lower(in_js_class)
	   AND (form_path = in_form_path OR in_form_path IS NULL)
	   AND (group_key = in_group_key OR in_group_key IS NULL);

	BEGIN
		SELECT tc.column_sid
		  INTO v_product_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_product_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_product_col_sid := NULL;
	END;
	
	BEGIN
		SELECT tc.column_sid
		  INTO v_user_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_user_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_user_company_col_sid := NULL;
	END;
	
	SELECT pt.product_type_id
	  BULK COLLECT INTO v_product_type_ids
	  FROM product_type pt
	  JOIN TABLE(aspen2.utils_pkg.SplitString(in_product_type_keys, ',')) t ON UPPER(t.item) = UPPER(pt.lookup_key);
	
	SetProductTab (
		in_product_tab_id				=> NULL,
		in_plugin_id					=> v_plugin_id,
		in_product_type_ids				=> v_product_type_ids,
		in_product_company_type_id		=> v_product_company_type_id,
		in_user_company_type_id			=> v_user_company_type_id,
		in_viewing_own_product			=> in_viewing_own_product,
		in_viewing_as_supplier			=> in_viewing_as_supplier,
		in_pos							=> in_pos,
		in_label						=> in_label,
		in_product_col_sid				=> v_product_col_sid,
		in_user_company_col_sid			=> v_user_company_col_sid,
		out_cur							=> v_cur
	);
END;

PROCEDURE RemoveProductTab (
	in_product_tab_id			IN  product_tab.product_tab_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify product plugins');
	END IF;
	
	DELETE FROM product_tab_product_type
	 WHERE product_tab_id = in_product_tab_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM product_tab
	 WHERE product_tab_id = in_product_tab_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE GetProductSupplierTabs (
	in_product_id					IN  company_product.product_id%TYPE,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_product_company_sid			company_product.company_sid%TYPE;
	v_product_type_id				company_product.product_type_id%TYPE;
	v_product_company_type_id		company.company_type_id%TYPE;
	v_user_company_type_id			company.company_type_id%TYPE;
	v_viewing_own_product			product_supplier_tab.viewing_own_product%TYPE := 0;
	v_viewing_as_supplier			product_supplier_tab.viewing_own_product%TYPE := 1;
BEGIN	 
	SELECT product_type_id, company_sid
	  INTO v_product_type_id, v_product_company_sid
	  FROM company_product
	 WHERE product_id = in_product_id;

	SELECT company_type_id
	  INTO v_product_company_type_id
	  FROM v$company
	 WHERE company_sid = v_product_company_sid;

	SELECT company_type_id
	  INTO v_user_company_type_id
	  FROM v$company
	 WHERE company_sid = v_company_sid;
	
	IF v_product_company_sid = v_company_sid THEN
		v_viewing_own_product := 1;

		IF type_capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
			v_viewing_as_supplier := 0;
		END IF;
	ELSE
		v_viewing_own_product := 0;

		IF type_capability_pkg.CheckCapability(v_company_sid, v_product_company_sid, chain_pkg.PRODUCTS, security.security_pkg.PERMISSION_READ) THEN
			v_viewing_as_supplier := 0;
		END IF;
	END IF;
	 
	GetProductSupplierTabs(v_product_type_id, v_product_company_type_id, v_user_company_type_id, v_viewing_own_product, v_viewing_as_supplier, out_tabs_cur, out_product_types_cur);
END;
	 
PROCEDURE GetProductSupplierTabs (
	in_product_type_id				IN  company_product.product_type_id%TYPE,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_supplier_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_supplier_tab.viewing_as_supplier%TYPE,
	out_tabs_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_product_types_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_supplier_tab_ids				security.T_SID_TABLE;
BEGIN	
	SELECT DISTINCT pt.product_supplier_tab_id
	  BULK COLLECT into v_product_supplier_tab_ids
	  FROM product_supplier_tab pt
	  LEFT JOIN (
			SELECT ptpt.product_supplier_tab_id, pt_tree.product_type_id
			  FROM prod_supp_tab_product_type ptpt
			  JOIN (
			  		SELECT product_type_id
					  FROM product_type
					 START WITH product_type_id = in_product_type_id
				   CONNECT BY product_type_id = PRIOR parent_product_type_id
			  ) pt_tree ON pt_tree.product_type_id = ptpt.product_type_id
		   ) ptpt_t ON ptpt_t.product_supplier_tab_id = pt.product_supplier_tab_id
	 WHERE (in_viewing_own_product IS NULL OR pt.viewing_own_product IS NULL OR pt.viewing_own_product = in_viewing_own_product)
	   AND (in_viewing_as_supplier IS NULL OR pt.viewing_as_supplier IS NULL OR pt.viewing_as_supplier = in_viewing_as_supplier)
	   AND (in_product_type_id IS NULL OR ptpt_t.product_type_id IS NOT NULL)
	   AND (in_product_company_type_id IS NULL OR pt.product_company_type_id = in_product_company_type_id)
	   AND (in_user_company_type_id IS NULL OR pt.user_company_type_id = in_user_company_type_id);

	OPEN out_tabs_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, 
			   p.description, p.details, p.preview_image_path,
			   p.tab_sid, p.form_sid, p.form_path, 
			   p.group_key, p.control_lookup_keys,
			   p.saved_filter_sid, p.result_mode, p.pre_filter_sid,
			   pt.product_supplier_tab_id, pt.pos, pt.label,
			   pt.product_company_type_id, pt.user_company_type_id,
			   pt.viewing_own_product, pt.viewing_as_supplier, pt.purchaser_company_col_sid,
			   pt.supplier_company_col_sid, pt.user_company_col_sid, pt.product_col_sid
		  FROM csr.plugin p
		  JOIN product_supplier_tab pt ON pt.plugin_id = p.plugin_id
		  JOIN TABLE(v_product_supplier_tab_ids) t ON pt.product_supplier_tab_id = t.column_value
		 ORDER BY pt.pos;
	
	OPEN out_product_types_cur FOR
		SELECT product_supplier_tab_id, product_type_id
		  FROM prod_supp_tab_product_type
		  JOIN TABLE(v_product_supplier_tab_ids) t ON t.column_value = product_supplier_tab_id;
END;

PROCEDURE SetProductSupplierTab (
	in_product_supplier_tab_id		IN  product_supplier_tab.product_supplier_tab_id%TYPE,
	in_plugin_id					IN  product_supplier_tab.plugin_id%TYPE,
	in_product_type_ids				IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_product_company_type_id		IN  company.company_type_id%TYPE,
	in_user_company_type_id			IN  company.company_type_id%TYPE,
	in_viewing_own_product			IN  product_supplier_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_supplier_tab.viewing_as_supplier%TYPE,
	in_pos							IN  product_supplier_tab.pos%TYPE,
	in_label						IN  product_supplier_tab.label%TYPE,
	in_purchaser_company_col_sid	IN  product_supplier_tab.purchaser_company_col_sid%TYPE,
	in_supplier_company_col_sid		IN  product_supplier_tab.supplier_company_col_sid%TYPE,
	in_user_company_col_sid			IN  product_supplier_tab.user_company_col_sid%TYPE,
	in_product_col_sid				IN  product_supplier_tab.product_col_sid%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt							NUMBER;
	v_pos							company_tab.pos%TYPE;
	v_product_supplier_tab_id		product_supplier_tab.product_supplier_tab_id%TYPE;
	v_product_type_ids				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_product_type_ids);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify product plugins');
	END IF;
	
	v_pos := in_pos;
	
	IF in_pos < 0 THEN
		SELECT NVL(max(pos) + 1, 1) 
		  INTO v_pos 
		  FROM company_tab;
	END IF;

	IF in_product_supplier_tab_id IS NULL THEN
		INSERT INTO product_supplier_tab (
			product_supplier_tab_id, plugin_type_id, 
			plugin_id, pos, label,
			product_company_type_id, user_company_type_id,
			viewing_own_product, viewing_as_supplier, purchaser_company_col_sid,
			supplier_company_col_sid, user_company_col_sid, product_col_sid
		) VALUES (
			product_supplier_tab_id_seq.NEXTVAL, csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_PROD_SUP_TAB, 
			in_plugin_id, v_pos, in_label,
			in_product_company_type_id, in_user_company_type_id,
			in_viewing_own_product, in_viewing_as_supplier, in_purchaser_company_col_sid,
			in_supplier_company_col_sid, in_user_company_col_sid, in_product_col_sid
		) RETURNING product_supplier_tab_id INTO v_product_supplier_tab_id;
	ELSE
		UPDATE product_supplier_tab
		   SET pos = v_pos,
			   label = in_label,
			   product_company_type_id = in_product_company_type_id,
			   user_company_type_id = in_user_company_type_id,
			   viewing_own_product = in_viewing_own_product,
			   viewing_as_supplier = in_viewing_as_supplier,
			   purchaser_company_col_sid = in_purchaser_company_col_sid,
			   supplier_company_col_sid = in_supplier_company_col_sid,
			   user_company_col_sid = in_user_company_col_sid,
			   product_col_sid = in_product_col_sid
		 WHERE product_supplier_tab_id = in_product_supplier_tab_id;

		v_product_supplier_tab_id := in_product_supplier_tab_id;
	END IF;
	
	DELETE FROM prod_supp_tab_product_type WHERE product_supplier_tab_id = v_product_supplier_tab_id;

	INSERT INTO prod_supp_tab_product_type (product_supplier_tab_id, product_type_id)
		 SELECT v_product_supplier_tab_id, column_value
		   FROM TABLE(v_product_type_ids);
		 
	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, 
			   p.description, p.details, p.preview_image_path,
			   p.tab_sid, p.form_sid, p.form_path, p.group_key, p.control_lookup_keys,
			   pt.product_supplier_tab_id, pt.pos, pt.label,
			   pt.product_company_type_id, pt.user_company_type_id,
			   pt.viewing_own_product, pt.viewing_as_supplier,
			   pt.purchaser_company_col_sid, pt.supplier_company_col_sid,
			   pt.user_company_col_sid, pt.product_col_sid
		  FROM csr.plugin p
		  JOIN product_supplier_tab pt ON pt.plugin_id = p.plugin_id
		 WHERE pt.product_supplier_tab_id = v_product_supplier_tab_id;
END;

PROCEDURE SetProductSupplierTab (
	in_product_type_keys			IN  VARCHAR2,
	in_product_company_type_key		IN  company_type.lookup_key%TYPE,
	in_user_company_type_key		IN  company_type.lookup_key%TYPE,
	in_viewing_own_product			IN  product_tab.viewing_own_product%TYPE,
	in_viewing_as_supplier			IN  product_tab.viewing_as_supplier%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_form_path					IN  csr.plugin.form_path%TYPE,
	in_group_key					IN  csr.plugin.group_key%TYPE,
	in_pos							IN  company_tab.pos%TYPE,
	in_label						IN  company_tab.label%TYPE,
	in_product_col_name				IN	cms.tab_column.oracle_column%TYPE,
	in_user_company_col_name		IN	cms.tab_column.oracle_column%TYPE,
	in_purchaser_company_col_name	IN	cms.tab_column.oracle_column%TYPE,
	in_supplier_company_col_name		IN	cms.tab_column.oracle_column%TYPE
)
AS
	v_plugin_id						csr.plugin.plugin_id%TYPE;
	v_product_company_type_id		company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_product_company_type_key);
	v_user_company_type_id			company_type.company_type_id%TYPE DEFAULT company_type_pkg.GetCompanyTypeId(in_user_company_type_key);
	v_product_col_sid				security.security_pkg.T_SID_ID;
	v_user_company_col_sid			security.security_pkg.T_SID_ID;
	v_purchaser_company_col_sid		security.security_pkg.T_SID_ID;
	v_supplier_company_col_sid		security.security_pkg.T_SID_ID;
	v_product_type_ids				security_pkg.T_SID_IDS;
	v_cur							security_pkg.T_OUTPUT_CUR;
BEGIN
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM csr.plugin
	 WHERE lower(js_class) = lower(in_js_class)
	   AND (form_path = in_form_path OR in_form_path IS NULL)
	   AND (group_key = in_group_key OR in_group_key IS NULL);

	BEGIN
		SELECT tc.column_sid
		  INTO v_product_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_product_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_product_col_sid := NULL;
	END;
	
	BEGIN
		SELECT tc.column_sid
		  INTO v_user_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_user_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_user_company_col_sid := NULL;
	END;
	
	BEGIN
		SELECT tc.column_sid
		  INTO v_purchaser_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_purchaser_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_purchaser_company_col_sid := NULL;
	END;
	
	BEGIN
		SELECT tc.column_sid
		  INTO v_supplier_company_col_sid
		  FROM cms.tab_column tc
		  JOIN csr.plugin p ON p.plugin_id = v_plugin_id AND p.tab_sid = tc.tab_sid AND p.app_sid = tc.app_sid
		 WHERE UPPER(tc.oracle_column) = UPPER(in_supplier_company_col_name)
		   AND tc.app_sid = security_pkg.GetApp;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_supplier_company_col_sid := NULL;
	END;
	
	SELECT pt.product_type_id
	  BULK COLLECT INTO v_product_type_ids
	  FROM product_type pt
	  JOIN TABLE(aspen2.utils_pkg.SplitString(in_product_type_keys, ',')) t ON UPPER(t.item) = UPPER(pt.lookup_key);
	
	SetProductSupplierTab (
		in_product_supplier_tab_id		=> NULL,
		in_plugin_id					=> v_plugin_id,
		in_product_type_ids				=> v_product_type_ids,
		in_product_company_type_id		=> v_product_company_type_id,
		in_user_company_type_id			=> v_user_company_type_id,
		in_viewing_own_product			=> in_viewing_own_product,
		in_viewing_as_supplier			=> in_viewing_as_supplier,
		in_pos							=> in_pos,
		in_label						=> in_label,
		in_product_col_sid				=> v_product_col_sid,
		in_user_company_col_sid			=> v_user_company_col_sid,
		in_purchaser_company_col_sid	=> v_purchaser_company_col_sid,
		in_supplier_company_col_sid		=> v_supplier_company_col_sid,
		out_cur							=> v_cur
	);
END;

PROCEDURE RemoveProductSupplierTab (
	in_product_supplier_tab_id			IN  product_supplier_tab.product_supplier_tab_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify product plugins');
	END IF;
	
	DELETE FROM prod_supp_tab_product_type
	 WHERE product_supplier_tab_id = in_product_supplier_tab_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM product_supplier_tab
	 WHERE product_supplier_tab_id = in_product_supplier_tab_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE RemovePlugin (	
	in_plugin_id					IN  csr.plugin.plugin_id%TYPE
)
AS
BEGIN
	RemoveCompanyPlugin(in_plugin_id);
END;

PROCEDURE GetProductTabsForExport(
	out_customer_plugins			OUT	security_pkg.T_OUTPUT_CUR,
	out_product_tabs				OUT	security_pkg.T_OUTPUT_CUR,
	out_product_headers				OUT	security_pkg.T_OUTPUT_CUR,
	out_prod_supplier_tabs			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_customer_plugins FOR
		SELECT p.plugin_type_id, p.description, p.js_include, p.js_class, p.cs_class, p.details, p.preview_image_path, 
			t.oracle_table, p.form_path, p.group_key, p.control_lookup_keys, f.lookup_key form_lookup_key
		  FROM csr.plugin p
		  LEFT JOIN cms.tab t ON t.tab_sid = p.tab_sid
		  LEFT JOIN cms.v$form f ON f.form_sid = p.form_sid
		 WHERE p.app_sid = security_pkg.GetApp;
	
	OPEN out_product_tabs FOR
		SELECT product_type_lookup_keys, pct.lookup_key product_company_type_lookup, uct.lookup_key user_company_type_lookup, t.viewing_own_product, t.viewing_as_supplier, p.js_class, p.form_path, p.group_key, t.pos, t.label, pcn.oracle_column product_col_name, ucn.oracle_column user_company_col_name
		  FROM product_tab t
		  JOIN csr.plugin p ON p.plugin_id = t.plugin_id
		  JOIN company_type pct ON pct.company_type_id = t.product_company_type_id
		  JOIN company_type uct ON uct.company_type_id = t.user_company_type_id
		  LEFT JOIN cms.tab_column pcn ON pcn.column_sid = t.product_col_sid
		  LEFT JOIN cms.tab_column ucn ON ucn.column_sid = t.user_company_col_sid
		  JOIN (
			SELECT ptpt.product_tab_id, LISTAGG(pt.lookup_key, ',') WITHIN GROUP (ORDER BY ptpt.product_type_id) product_type_lookup_keys
			  FROM product_tab_product_type ptpt
			  JOIN product_type pt ON pt.product_type_id = ptpt.product_type_id
			 GROUP BY ptpt.product_tab_id
		  ) types ON types.product_tab_id = t.product_tab_id;
		  
	OPEN out_product_headers FOR
		SELECT product_type_lookup_keys, pct.lookup_key product_company_type_lookup, uct.lookup_key user_company_type_lookup, t.viewing_own_product, t.viewing_as_supplier, p.js_class, p.form_path, p.group_key, t.pos, pcn.oracle_column product_col_name, ucn.oracle_column user_company_col_name
		  FROM product_header t
		  JOIN csr.plugin p ON p.plugin_id = t.plugin_id
		  JOIN company_type pct ON pct.company_type_id = t.product_company_type_id
		  JOIN company_type uct ON uct.company_type_id = t.user_company_type_id
		  LEFT JOIN cms.tab_column pcn ON pcn.column_sid = t.product_col_sid
		  LEFT JOIN cms.tab_column ucn ON ucn.column_sid = t.user_company_col_sid
		  JOIN (
			SELECT ptpt.product_header_id, LISTAGG(pt.lookup_key, ',') WITHIN GROUP (ORDER BY ptpt.product_type_id) product_type_lookup_keys
			  FROM product_header_product_type ptpt
			  JOIN product_type pt ON pt.product_type_id = ptpt.product_type_id
			 GROUP BY ptpt.product_header_id
		  ) types ON types.product_header_id = t.product_header_id;
		
	OPEN out_prod_supplier_tabs FOR
		SELECT product_type_lookup_keys, pct.lookup_key product_company_type_lookup, uct.lookup_key user_company_type_lookup, t.viewing_own_product, t.viewing_as_supplier, p.js_class, p.form_path, p.group_key, t.pos, t.label, pcn.oracle_column product_col_name, ucn.oracle_column user_company_col_name, pccn.oracle_column purchaser_company_col_name, sccn.oracle_column supplier_company_col_name
		  FROM product_supplier_tab t
		  JOIN csr.plugin p ON p.plugin_id = t.plugin_id
		  JOIN company_type pct ON pct.company_type_id = t.product_company_type_id
		  JOIN company_type uct ON uct.company_type_id = t.user_company_type_id
		  LEFT JOIN cms.tab_column pcn ON pcn.column_sid = t.product_col_sid
		  LEFT JOIN cms.tab_column ucn ON ucn.column_sid = t.user_company_col_sid
		  LEFT JOIN cms.tab_column pccn ON pcn.column_sid = t.purchaser_company_col_sid
		  LEFT JOIN cms.tab_column sccn ON ucn.column_sid = t.supplier_company_col_sid
		  JOIN (
			SELECT ptpt.product_supplier_tab_id, LISTAGG(pt.lookup_key, ',') WITHIN GROUP (ORDER BY ptpt.product_type_id) product_type_lookup_keys
			  FROM prod_supp_tab_product_type ptpt
			  JOIN product_type pt ON pt.product_type_id = ptpt.product_type_id
			 GROUP BY ptpt.product_supplier_tab_id
		  ) types ON types.product_supplier_tab_id = t.product_supplier_tab_id;
END;

END plugin_pkg;
/
