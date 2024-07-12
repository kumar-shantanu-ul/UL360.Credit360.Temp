-- Please update version.sql too -- this keeps clean builds in sync
define version=2107
@update_header


CREATE SEQUENCE CSR.INITIATIVE_COMMENT_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER;


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
  -- remove the hard-coded plugin stuff
  security.user_pkg.logonadmin;
  
    v_plugin_id := csr.SetPlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'MarksAndSpencer.Teamroom.InitiativesPanel',
        in_description      => 'Projects',
        in_js_include       => '/marksandspencer/site/teamroom/controls/InitiativesPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );

  INSERT INTO csr.teamroom_type_tab (app_sid, teamroom_type_id, plugin_id, plugin_type_id, pos, tab_label)
    SELECT app_sid, teamroom_type_id, v_plugin_id, 5, 5, 'Projects'
      FROM csr.teamroom_type
     WHERE app_sid IN (
      SELECT app_sid 
        FROM csr.customer 
       WHERE host IN ('vo-test.credit360.com', 'rk.credit360.com', 'marcin.credit360.com', 'mands-valueoptimisation.credit360.com', 'marksandspencer.credit360.com')
     );
      
  INSERT INTO csr.teamroom_type_tab_group (app_sid, teamroom_type_id, plugin_id, group_sid)
    SELECT app_sid, teamroom_type_id, v_plugin_id, group_sid
      FROM csr.teamroom_type_tab_group
     WHERE app_sid IN (
      SELECT app_sid 
        FROM csr.customer 
       WHERE host IN ('vo-test.credit360.com', 'rk.credit360.com', 'marcin.credit360.com', 'mands-valueoptimisation.credit360.com', 'marksandspencer.credit360.com')
     )
       AND plugin_id IN (
      SELECT plugin_Id FROM csr.plugin WHERE js_class = 'Teamroom.InitiativesPanel'
     );
  
  
  DELETE FROM csr.teamroom_type_tab_group
   WHERE app_sid IN (
    SELECT app_sid 
      FROM csr.customer 
     WHERE host IN ('vo-test.credit360.com', 'rk.credit360.com', 'marcin.credit360.com', 'mands-valueoptimisation.credit360.com', 'marksandspencer.credit360.com')
     )
     AND plugin_id IN (
    SELECT plugin_Id FROM csr.plugin WHERE js_class = 'Teamroom.InitiativesPanel'
     );
  DELETE FROM csr.teamroom_type_tab
   WHERE app_sid IN (
    SELECT app_sid 
      FROM csr.customer 
     WHERE host IN ('vo-test.credit360.com', 'rk.credit360.com', 'marcin.credit360.com', 'mands-valueoptimisation.credit360.com', 'marksandspencer.credit360.com')
     )
     AND plugin_id IN (
    SELECT plugin_Id FROM csr.plugin WHERE js_class = 'Teamroom.InitiativesPanel'
     );
     
  COMMIT;
END;
/

drop function csr.setplugin;

@..\initiative_pkg
@..\initiative_grid_pkg

@..\initiative_body
@..\initiative_grid_body



@update_tail
