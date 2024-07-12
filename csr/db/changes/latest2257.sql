-- Please update version.sql too -- this keeps clean builds in sync
define version=2257
@update_header

DECLARE
	v_plugin_id		csr.plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
			 VALUES (csr.plugin_id_seq.nextval, 1, 'Portlets',  '/csr/site/property/properties/controls/PortalTab.js', 
				'Portlets', 'Credit360.Property.Plugins.PortalDto')
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE csr.plugin 
		   SET description = 'Portlets',
		   	   js_include = '/csr/site/property/properties/controls/PortalTab.js',
		   	   cs_class = 'Credit360.Property.Plugins.PortalDto'
		 WHERE plugin_type_id = 1
		   AND js_class = 'Portlets'
	 		   RETURNING plugin_id INTO v_plugin_id;
	END;
END;
/

@update_tail
