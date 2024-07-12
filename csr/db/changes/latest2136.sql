-- Please update version.sql too -- this keeps clean builds in sync
define version=2136
@update_header

BEGIN
	UPDATE csr.plugin
	   SET cs_class = 'Credit360.Plugins.InitiativesPlugin'
	 WHERE plugin_type_id = 5
	   AND js_class like '%Teamroom.InitiativesPanel'
	   AND cs_class = 'Credit360.Plugins.PluginDto';
END;
/

@update_tail
