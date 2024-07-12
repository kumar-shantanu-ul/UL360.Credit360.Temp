CREATE OR REPLACE PACKAGE BODY CSR.plugin_pkg IS

PROCEDURE DeleteCmsPlugins(
	in_tab_sid						IN  security.security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT plugin_id
		  FROM plugin
		 WHERE tab_sid = in_tab_sid
	) LOOP
		DeletePlugin(r.plugin_id);
	END LOOP;
END;

PROCEDURE DeletePlugin(
	in_plugin_id					IN  plugin.plugin_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can delete plugins');
	END IF;

	property_pkg.RemovePropertyTab(in_plugin_id);
	meter_pkg.RemoveMeterTab(in_plugin_id);
	
	FOR r IN (
		SELECT internal_audit_type_id
		  FROM audit_type_header
		 WHERE plugin_id = in_plugin_id
	) LOOP
		audit_pkg.RemoveAuditHeader(r.internal_audit_type_id, in_plugin_id);
	END LOOP;
	
	FOR r IN (
		SELECT internal_audit_type_id
		  FROM audit_type_tab
		 WHERE plugin_id = in_plugin_id
	) LOOP
		audit_pkg.RemoveAuditTab(r.internal_audit_type_id, in_plugin_id);
	END LOOP;
	
	chain.plugin_pkg.RemovePlugin(in_plugin_id);
	
	DELETE FROM plugin
		  WHERE plugin_id = in_plugin_id;
END;


FUNCTION SetCorePlugin(
	in_plugin_type_id				IN 	plugin.plugin_type_id%TYPE,
	in_js_class						IN  plugin.js_class%TYPE,
	in_description					IN  plugin.description%TYPE,
	in_js_include					IN  plugin.js_include%TYPE,
	in_cs_class						IN  plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  plugin.preview_image_path%TYPE DEFAULT NULL,
	in_tab_sid						IN  plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  plugin.form_path%TYPE DEFAULT NULL
) RETURN plugin.plugin_id%TYPE
AS
	v_plugin_id		plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, 
			         in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE plugin 
			   SET description = in_description,
			   	   js_include = in_js_include,
			   	   cs_class = in_cs_class,
			   	   details = in_details,
			   	   preview_image_path = in_preview_image_path,
			   	   form_path = in_form_path
			 WHERE plugin_type_id = in_plugin_type_id
			   AND js_class = in_js_class
			   AND app_sid IS NULL
			   AND ((tab_sid IS NULL AND in_tab_sid IS NULL) OR (tab_sid = in_tab_sid))
		 	RETURNING plugin_id INTO v_plugin_id;
	END;

	RETURN v_plugin_id;
END;

FUNCTION SetCustomerPlugin(
	in_plugin_type_id				IN 	plugin.plugin_type_id%TYPE,
	in_js_class						IN  plugin.js_class%TYPE,
	in_description					IN  plugin.description%TYPE,
	in_js_include					IN  plugin.js_include%TYPE,
	in_cs_class						IN  plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  plugin.preview_image_path%TYPE DEFAULT NULL,
	in_tab_sid						IN  plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  plugin.form_path%TYPE DEFAULT NULL,
	in_group_key					IN  plugin.group_key%TYPE DEFAULT NULL,
	in_control_lookup_keys			IN  plugin.control_lookup_keys%TYPE DEFAULT NULL
) RETURN plugin.plugin_id%TYPE
AS
	v_plugin_id		plugin.plugin_id%TYPE;
	v_app_sid		security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can create customer plugins');
	END IF;
	
	BEGIN
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path, group_key, control_lookup_keys)
			 VALUES (v_app_sid, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, 
			         in_js_class, in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path, 
					 in_group_key, in_control_lookup_keys)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE plugin 
			   SET description = in_description,
			   	   js_include = in_js_include,
			   	   cs_class = in_cs_class,
			   	   details = in_details,
			   	   preview_image_path = in_preview_image_path,
			   	   form_path = in_form_path,
			   	   group_key = in_group_key,
			   	   control_lookup_keys = in_control_lookup_keys
			 WHERE plugin_type_id = in_plugin_type_id
			   AND js_class = in_js_class
			   AND app_sid = v_app_sid
			   AND ((form_path IS NULL AND in_form_path IS NULL AND group_key IS NULL AND in_group_key IS NULL)
			    OR (form_path = in_form_path AND in_group_key IS NULL)
				OR (group_key = in_group_key AND in_form_path IS NULL))
		 	RETURNING plugin_id INTO v_plugin_id;
	END;

	RETURN v_plugin_id;
END;

PROCEDURE SetCustomerPlugin(
	in_plugin_type_id				IN 	plugin.plugin_type_id%TYPE,
	in_js_class						IN  plugin.js_class%TYPE,
	in_description					IN  plugin.description%TYPE,
	in_js_include					IN  plugin.js_include%TYPE,
	in_cs_class						IN  plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  plugin.preview_image_path%TYPE DEFAULT NULL,
	in_oracle_table					IN  cms.tab.oracle_table%TYPE DEFAULT NULL,
	in_form_path					IN  plugin.form_path%TYPE DEFAULT NULL,
	in_form_lookup_key				IN  cms.form.lookup_key%TYPE DEFAULT NULL,
	in_group_key					IN  plugin.group_key%TYPE DEFAULT NULL,
	in_control_lookup_keys			IN  plugin.control_lookup_keys%TYPE DEFAULT NULL
) 
AS
	v_tab_sid		security_pkg.T_SID_ID;
	v_plugin_id		plugin.plugin_id%TYPE;
	v_plugin_cur	SYS_REFCURSOR;
	v_form_sid		security_pkg.T_SID_ID;
BEGIN
	IF in_oracle_table IS NOT NULL THEN 
		BEGIN
			SELECT tab_sid
			  INTO v_tab_sid
			  FROM cms.tab
			 WHERE oracle_table= UPPER(in_oracle_table);
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Oracle table:'||in_oracle_table||' not registered as CMS table');
		END;
	END IF;
	
	IF in_form_lookup_key IS NOT NULL THEN
		BEGIN
			SELECT form_sid
			  INTO v_form_sid
			  FROM cms.form
			 WHERE lookup_key = in_form_lookup_key;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Form: '||in_form_lookup_key||' does not exist');
		END;
	END IF;
	
	BEGIN
		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE app_sid = security_pkg.getapp
		   AND js_class = in_js_class
		   AND (form_path = in_form_path OR in_form_path IS NULL AND form_path IS NULL)
		   AND (group_key = in_group_key OR in_group_key IS NULL AND group_key IS NULL);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	IF v_plugin_id IS NULL THEN
		CreateCustomerPlugin(
			in_plugin_type_id				=> in_plugin_type_id,
			in_js_class						=> in_js_class,
			in_description					=> in_description,
			in_js_include					=> in_js_include,
			in_cs_class						=> in_cs_class,
			in_details						=> in_details,
			in_preview_image_path			=> in_preview_image_path,
			in_tab_sid						=> v_tab_sid,
			in_form_path					=> in_form_path,
			in_form_sid 					=> v_form_sid,
			in_group_key					=> in_group_key,
			in_control_lookup_keys			=> in_control_lookup_keys,

			out_plugin_cur					=> v_plugin_cur
		);
	ELSE 
		AmendCustomerPlugin(
			in_plugin_id					=> v_plugin_id,
			in_description					=> in_description,
			in_tab_sid						=> v_tab_sid,
			in_form_path					=> in_form_path, 
			in_group_key					=> in_group_key,
			in_control_lookup_keys			=> in_control_lookup_keys,
			out_plugin_cur					=> v_plugin_cur
		);
	END IF;
	
END;

PROCEDURE INTERNAL_GetPlugin(
	in_plugin_id					IN	plugin.plugin_id%TYPE,
	out_plugin_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_plugin_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_class, p.js_include,
		       p.description, p.details, p.preview_image_path, p.tab_sid, p.form_path,
			   p.group_key, p.control_lookup_keys, p.saved_filter_sid, p.result_mode,
			   p.portal_sid, sf.name saved_filter_name, pd.portal_group, 
			   p.use_reporting_period, p.r_script_path, p.form_sid, p.card_group_id,
			   p.pre_filter_sid, pf.name pre_filter_name
		  FROM plugin p
		  LEFT JOIN chain.saved_filter sf ON sf.saved_filter_sid = p.saved_filter_sid
		  LEFT JOIN chain.saved_filter pf ON pf.saved_filter_sid = p.pre_filter_sid
		  LEFT JOIN portal_dashboard pd ON pd.portal_sid = p.portal_sid
		 WHERE plugin_id = in_plugin_id;
END;

PROCEDURE CreateCustomerPlugin(
	in_plugin_type_id				IN 	plugin.plugin_type_id%TYPE,
	in_js_class						IN  plugin.js_class%TYPE,
	in_description					IN  plugin.description%TYPE,
	in_js_include					IN  plugin.js_include%TYPE,
	in_cs_class						IN  plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  plugin.preview_image_path%TYPE DEFAULT NULL,
	in_tab_sid						IN  plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  plugin.form_path%TYPE DEFAULT NULL,
	in_group_key					IN  plugin.group_key%TYPE DEFAULT NULL,
	in_control_lookup_keys			IN  plugin.control_lookup_keys%TYPE DEFAULT NULL,
	in_saved_filter_sid				IN	plugin.saved_filter_sid%TYPE DEFAULT NULL,
	in_result_mode					IN	plugin.result_mode%TYPE DEFAULT NULL,
	in_portal_sid					IN	plugin.portal_sid%TYPE DEFAULT NULL,
	in_use_reporting_period			IN  plugin.use_reporting_period%TYPE DEFAULT 0,	
	in_r_script_path				IN	plugin.r_script_path%TYPE DEFAULT NULL,
	in_form_sid						IN	plugin.form_sid%TYPE DEFAULT NULL,
	in_card_group_id				IN	plugin.card_group_id%TYPE DEFAULT NULL,
	in_pre_filter_sid				IN	plugin.pre_filter_sid%TYPE DEFAULT NULL,
	out_plugin_cur					OUT SYS_REFCURSOR
) 
AS
	v_plugin_id		plugin.plugin_id%TYPE;
	v_app_sid		security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can create customer plugins');
	END IF;
	
	BEGIN
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
							details, preview_image_path, tab_sid, form_path, group_key, control_lookup_keys,
							saved_filter_sid, result_mode, portal_sid, use_reporting_period, r_script_path,
							form_sid, card_group_id, pre_filter_sid)
			 VALUES (v_app_sid, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, 
					 in_js_class, in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path, 
					 in_group_key, in_control_lookup_keys, in_saved_filter_sid, in_result_mode, in_portal_sid,
					 in_use_reporting_period, in_r_script_path, in_form_sid, in_card_group_id, in_pre_filter_sid)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME,
				'A plugin with the given configuration already exists');
	END;

	IF LOWER(in_js_class) = LOWER('Chain.ManageCompany.CmsTab') and in_tab_sid IS NOT NULL THEN
		UPDATE cms.tab
		   SET show_in_company_filter = 1
		 WHERE tab_sid = in_tab_sid;
	ELSIF LOWER(in_js_class) = LOWER('Chain.ManageProduct.CmsTab') and in_tab_sid IS NOT NULL THEN
		UPDATE cms.tab
		   SET show_in_product_filter = 1
		 WHERE tab_sid = in_tab_sid;
	END IF;

	INTERNAL_GetPlugin(v_plugin_id, out_plugin_cur);
END;

PROCEDURE AmendCustomerPlugin(
	in_plugin_id					IN 	plugin.plugin_id%TYPE,
	in_description					IN  plugin.description%TYPE,
	in_tab_sid						IN  plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  plugin.form_path%TYPE DEFAULT NULL,
	in_group_key					IN  plugin.group_key%TYPE DEFAULT NULL,
	in_control_lookup_keys			IN  plugin.control_lookup_keys%TYPE DEFAULT NULL,
	in_saved_filter_sid				IN	plugin.saved_filter_sid%TYPE DEFAULT NULL,
	in_result_mode					IN	plugin.result_mode%TYPE DEFAULT NULL,
	in_portal_sid					IN	plugin.portal_sid%TYPE DEFAULT NULL,
	in_use_reporting_period			IN  plugin.use_reporting_period%TYPE DEFAULT 0,	
	in_r_script_path				IN	plugin.r_script_path%TYPE DEFAULT NULL,
	in_form_sid						IN	plugin.form_sid%TYPE DEFAULT NULL,	
	in_card_group_id				IN	plugin.card_group_id%TYPE DEFAULT NULL,	
	in_pre_filter_sid				IN	plugin.pre_filter_sid%TYPE DEFAULT NULL,
	out_plugin_cur					OUT SYS_REFCURSOR
) 
AS
	v_plugin_id		plugin.plugin_id%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin can amend customer plugins');
	END IF;
	
	BEGIN
		UPDATE plugin
		   SET description = in_description,
			   tab_sid = in_tab_sid,
			   form_path = in_form_path,
			   group_key = in_group_key,
			   control_lookup_keys = in_control_lookup_keys,
			   saved_filter_sid = in_saved_filter_sid,
			   result_mode = in_result_mode,
			   portal_sid = in_portal_sid,
			   use_reporting_period = in_use_reporting_period,
			   r_script_path = in_r_script_path,
			   form_sid = in_form_sid,
			   card_group_id = in_card_group_id,
			   pre_filter_sid = in_pre_filter_sid
		 WHERE app_sid = security_pkg.GetApp
		   AND plugin_id = in_plugin_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME,
				'A plugin with the given configuration already exists');
	END;
	INTERNAL_GetPlugin(in_plugin_id, out_plugin_cur);
END;

PROCEDURE GetIndicatorPlugin(
	in_plugin_id		IN 	plugin.plugin_id%TYPE,
	out_indicators		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_indicators FOR
		SELECT i.ind_sid, pi.label
		  FROM plugin_indicator pi
		  JOIN ind i ON UPPER(pi.lookup_key) = UPPER(i.lookup_key)
		 WHERE plugin_id = in_plugin_id
		 ORDER BY pi.pos;
END;

FUNCTION GetPluginTypeId(
	in_description		IN	plugin_type.description%TYPE
) RETURN plugin_type.plugin_type_id%TYPE
AS
	v_plugin_type_id	plugin_type.plugin_type_id%TYPE;
	v_max_id			plugin_type.plugin_type_id%TYPE;
BEGIN
	BEGIN
		SELECT plugin_type_id
		  INTO v_plugin_type_id
		  FROM plugin_type
		 WHERE UPPER(description) = UPPER(in_description);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN	
			SELECT MAX(plugin_type_id)
			  INTO v_max_id
			  FROM plugin_type;
			  
			v_plugin_type_id := v_max_id + 1;
		
			INSERT INTO plugin_type(plugin_type_id, description)
			VALUES (v_plugin_type_id, in_description);
	END;
	
	RETURN v_plugin_type_id;
END;

FUNCTION GetPluginId(
	in_js_class						IN	plugin.js_class%TYPE
) RETURN plugin.plugin_id%TYPE
AS
	v_plugin_id						plugin.plugin_id%TYPE;
BEGIN
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM plugin
	 WHERE js_class = in_js_class;
	
	RETURN v_plugin_id;
END;

PROCEDURE GetPluginsForType(
	in_plugin_type_id				IN  plugin.plugin_type_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_class, p.js_include, 
		       p.description, p.details, p.preview_image_path, p.tab_sid, p.form_path,
			   p.group_key, p.control_lookup_keys, p.saved_filter_sid, p.result_mode,
			   p.portal_sid, sf.name saved_filter_name, pd.portal_group,
			   p.use_reporting_period, p.r_script_path, p.form_sid, p.card_group_id,
			   p.pre_filter_sid, pf.name pre_filter_name, p.allow_multiple
		  FROM csr.plugin p
		  LEFT JOIN chain.saved_filter sf ON sf.saved_filter_sid = p.saved_filter_sid
		  LEFT JOIN chain.saved_filter pf ON pf.saved_filter_sid = p.pre_filter_sid
		  LEFT JOIN portal_dashboard pd ON pd.portal_sid = p.portal_sid
		 WHERE p.plugin_type_id = in_plugin_type_id
		 ORDER BY p.app_sid DESC, description;
END;

END;
/
