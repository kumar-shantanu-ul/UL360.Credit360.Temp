-- Please update version.sql too -- this keeps clean builds in sync
define version=1968
@update_header

DECLARE
    v_plugin_id     csr.plugin.plugin_id%TYPE;
BEGIN
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (6, 'Teamroom edit page');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (7, 'Teamroom main tab');
    -- now added specific plugins
    v_plugin_id := csr.plugin_pkg.SetPlugin(
        in_plugin_type_id   => 6, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_EDIT_PAGE
        in_js_class         => 'MarksAndSpencer.Teamroom.Edit.SettingsPanel',
        in_description      => 'Settings',
        in_js_include       => '/csr/site/teamroom/controls/edit/SettingsPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.plugin_pkg.SetPlugin(
        in_plugin_type_id   => 7, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_MAIN_TAB
        in_js_class         => 'MarksAndSpencer.Teamroom.MainTab.SettingsPanel',
        in_description      => 'Settings',
        in_js_include       => '/csr/site/teamroom/controls/mainTab/SettingsPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
END;
/

ALTER TABLE CSR.TEAMROOM_TYPE_TAB DROP CONSTRAINT CHK_TEAMROOM_TAB_PLUGIN_TYPE;
ALTER TABLE CSR.TEAMROOM_TYPE_TAB ADD CONSTRAINT CHK_TEAMROOM_TAB_PLUGIN_TYPE CHECK (PLUGIN_TYPE_ID=5 OR PLUGIN_TYPE_ID=6 OR PLUGIN_TYPE_ID=7);

@..\csr_data_pkg
@..\teamroom_pkg
@..\teamroom_body

@update_tail
