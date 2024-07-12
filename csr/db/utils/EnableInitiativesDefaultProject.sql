ACCEPT host CHAR     PROMPT 'Host (e.g. clientname.credit360.com)  :  '
ACCEPT flow CHAR     PROMPT 'Workflow Label : '

DECLARE
	v_name						csr.initiative_project.name%TYPE;
	v_flow_sid				    security.security_pkg.T_SID_ID;
	v_live_flow_state_id		csr.initiative_project.live_flow_state_id%TYPE:= NULL;
	v_start_dtm					csr.initiative_project.start_dtm%TYPE:= NULL;
	v_end_dtm					csr.initiative_project.end_dtm%TYPE := NULL;
	v_icon						csr.initiative_project.icon%TYPE := NULL;
	v_abbreviation				csr.initiative_project.abbreviation%TYPE := NULL;
	v_fields_xml				csr.initiative_project.fields_xml%TYPE := XMLType('<fields/>');
	v_period_fields_xml			csr.initiative_project.period_fields_xml%TYPE := XMLType('<fields/>');
	v_pos_group					csr.initiative_project.pos_group%TYPE := NULL;
	v_pos						csr.initiative_project.pos%TYPE := NULL;
	v_project_sid 				security.security_pkg.T_SID_ID;
	v_plugin_id					csr.plugin.plugin_id%TYPE;
BEGIN
	-- log on
	security.user_pkg.logonadmin('&&host');
	
	v_name:= 'Default Initiative Project';
	
	SELECT flow_sid 
	  INTO v_flow_sid
	  FROM CSR.FLOW
	 WHERE Label = '&&flow';
	
	csr.initiative_project_pkg.CreateProject(
		v_name,					--IN	initiative_project.name%TYPE,
		v_flow_sid,				--IN	security.security_pkg.T_SID_ID,
		v_live_flow_state_id,	--IN	initiative_project.live_flow_state_id%TYPE DEFAULT NULL,
		v_start_dtm,			--IN	initiative_project.start_dtm%TYPE DEFAULT NULL,
		v_end_dtm,				--IN	initiative_project.end_dtm%TYPE DEFAULT NULL,
		v_icon,					--IN	initiative_project.icon%TYPE DEFAULT NULL,
		v_abbreviation,			--IN	initiative_project.abbreviation%TYPE DEFAULT NULL,
		v_fields_xml,			--IN	initiative_project.fields_xml%TYPE DEFAULT XMLType('<fields/>'),
		v_period_fields_xml,	--IN	initiative_project.period_fields_xml%TYPE DEFAULT XMLType('<fields/>'),
		v_pos_group,			--IN	initiative_project.pos_group%TYPE DEFAULT NULL,
		v_pos,					--IN	initiative_project.pos%TYPE DEFAULT NULL,
		v_project_sid			--OUT	security.security_pkg.T_SID_ID
		);
	
	INSERT INTO csr.initiative_project_user_group (initiative_user_group_id, project_sid)
	VALUES (1, v_project_sid);

	v_plugin_id := csr.plugin_pkg.GetPluginId('Credit360.Initiatives.SummaryPanel');
	BEGIN
		INSERT INTO csr.initiative_project_tab (project_sid, plugin_id, plugin_type_id, pos, tab_label)
		VALUES (v_project_sid, v_plugin_id, 
				csr.csr_data_pkg.PLUGIN_TYPE_INITIAT_TAB,
				1, 'Summary');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.initiative_project_tab
			   SET pos=1
			 WHERE plugin_id = v_plugin_id;
	END;

	BEGIN
		INSERT INTO csr.initiative_project_tab_group (project_sid, plugin_id, group_sid)
		VALUES (v_project_sid, v_plugin_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/RegisteredUsers'));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	
	--dbms_output.put_line('Created project '||v_project_sid);
	--COMMIT;
END;
/
