-- Please update version.sql too -- this keeps clean builds in sync
define version=2129
@update_header

BEGIN
	INSERT INTO csr.plugin
		(plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
	VALUES 
		(csr.plugin_id_seq.nextval, 1/*Property tab*/, 'Initiatives', '/csr/site/property/properties/controls/InitiativesPanel.js', 'Controls.InitiativesPanel', 'Credit360.Plugins.InitiativesPlugin');
END;
/

@../initiative_grid_pkg
@../initiative_import_pkg

@../initiative_grid_body
@../initiative_import_body


@update_tail
