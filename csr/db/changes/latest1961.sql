-- Please update version.sql too -- this keeps clean builds in sync
define version=1961
@update_header

CREATE FUNCTION csr.SetPlugin(
    in_plugin_type_id   IN  plugin.plugin_type_id%TYPE,
    in_js_class         IN  plugin.js_class%TYPE,
    in_description      IN  plugin.description%TYPE,
    in_js_include       IN  plugin.js_include%TYPE,
    in_cs_class         IN  plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto'
) RETURN plugin.plugin_id%TYPE
AS
    v_plugin_id     plugin.plugin_id%TYPE;
BEGIN
    BEGIN
        INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
             VALUES (csr.plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, in_cs_class)
          RETURNING plugin_id INTO v_plugin_id;
    EXCEPTION WHEN dup_val_on_index THEN
        UPDATE csr.plugin 
           SET description = in_description,
            js_include = in_js_include,
            cs_class = in_cs_class
         WHERE plugin_type_id = in_plugin_type_id
           AND js_class = in_js_class
        RETURNING plugin_id INTO v_plugin_id;
    END;
      
    RETURN v_plugin_id;
END;
/


DECLARE
    v_plugin_id     csr.plugin.plugin_id%TYPE;
BEGIN
    v_plugin_id := csr.SetPlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'Teamroom.InitiativesPanel',
        in_description      => 'Projects',
        in_js_include       => '/csr/site/teamroom/controls/InitiativesPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
END;
/

drop function csr.setplugin;

DECLARE 
    v_js_class      csr.plugin.js_class%TYPE := 'Teamroom.InitiativesPanel';
    v_tab_label     csr.teamroom_type_tab.tab_label%TYPE := 'Projects';
    v_pos           csr.teamroom_type_tab.pos%TYPE := 5;
    v_plugin_id     csr.plugin.plugin_id%TYPE;
BEGIN
    FOR r IN (
        SELECT c.host, teamroom_type_id FROM csr.teamroom_type tt JOIN csr.customer c ON tt.app_sid = c.app_sid
    )
    LOOP
		security.user_pkg.logonadmin(r.host);
		
        SELECT plugin_id
          INTO v_plugin_id
          FROM csr.plugin 
         WHERE js_class = v_js_class 
           AND plugin_type_id = 5; --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB;
         
        BEGIN
            INSERT INTO csr.teamroom_type_tab (teamroom_type_id, plugin_id, plugin_type_id, pos, tab_label)
                VALUES (r.teamroom_type_id, v_plugin_id, 5, v_pos, v_tab_label);
        EXCEPTION WHEN dup_val_on_index THEN
            UPDATE csr.teamroom_type_tab
               SET pos = v_pos, tab_label = v_tab_label
             WHERE plugin_id = v_plugin_id
               AND teamroom_type_id = r.teamroom_type_id;
        END;
        
        -- assume registered users
        BEGIN
            INSERT INTO csr.teamroom_type_tab_group (teamroom_type_id, plugin_id, group_sid)
                 VALUES (r.teamroom_type_Id, v_plugin_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/RegisteredUsers'));
        EXCEPTION WHEN dup_val_on_index THEN
            NULL;
        END;
        security.user_pkg.logonadmin;
    END LOOP;
END;    
/

-- wasn't set in clean build
alter table csr.batch_job modify requested_by_user_sid default sys_context('SECURITY','SID');

@..\initiative_grid_pkg
@..\initiative_grid_body
@..\teamroom_body


@update_tail