CREATE OR REPLACE PACKAGE CSR.plugin_pkg IS

PROCEDURE DeleteCmsPlugins(
	in_tab_sid						IN  security.security_pkg.T_SID_ID
);

PROCEDURE DeletePlugin(
	in_plugin_id					IN  plugin.plugin_id%TYPE
);

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
) RETURN plugin.plugin_id%TYPE;

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
);

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
) RETURN plugin.plugin_id%TYPE;

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
);

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
);

PROCEDURE GetIndicatorPlugin(
	in_plugin_id					IN 	plugin.plugin_id%TYPE,
	out_indicators					OUT SYS_REFCURSOR
);

FUNCTION GetPluginTypeId(
	in_description					IN	plugin_type.description%TYPE
) RETURN plugin_type.plugin_type_id%TYPE;

FUNCTION GetPluginId(
	in_js_class						IN	plugin.js_class%TYPE
) RETURN plugin.plugin_id%TYPE;

PROCEDURE GetPluginsForType(
	in_plugin_type_id				IN  plugin.plugin_type_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
);

END;
/