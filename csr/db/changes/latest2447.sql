-- Please update version.sql too -- this keeps clean builds in sync
define version=2447
@update_header


CREATE OR REPLACE FUNCTION csr.TEMP_SetCorePlugin(
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
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION WHEN dup_val_on_index THEN
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
/
 
DECLARE
    v_plugin_id     csr.plugin.plugin_id%TYPE;
BEGIN
	/*Property*/
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 1, --csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
		in_js_class				=> 'Controls.EnhesaTopicsTab',
		in_cs_class				=> 'Credit360.Property.Plugins.EnhesaTopicsTab',
		in_description			=> 'Enhesa Regulatory Monitoring',
		in_js_include			=> '/csr/site/property/properties/controls/EnhesaTopicsTab.js',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/property_tab_enhesa_topics.png',
		in_details				=> 'This tab shows a list of Enhesa Regulatory Monitoring topics for a property.'
	);

END;
/

DROP FUNCTION csr.TEMP_SetCorePlugin;



@update_tail