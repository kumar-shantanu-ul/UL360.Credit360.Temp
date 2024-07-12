CREATE OR REPLACE PACKAGE BODY CSR.initiative_project_pkg
IS

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE MoveObject(
	in_act					IN security_pkg.T_ACT_ID,
	in_task_sid				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE TrashObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_task_sid		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM project_initiative_period_stat
	 WHERE project_sid = in_sid_id;

	DELETE FROM project_init_metric_flow_state
	 WHERE project_sid = in_sid_id;

	DELETE FROM project_tag_group
	 WHERE project_sid = in_sid_id;

	DELETE FROM initiative_metric_assoc
	 WHERE project_sid = in_sid_id;

	DELETE FROM project_initiative_metric
	 WHERE project_sid = in_sid_id;

	DELETE FROM initiative_metric_group
	 WHERE project_sid = in_sid_id;

	DELETE FROM initiative_import_template
	 WHERE project_sid = in_sid_id;
	 
	DELETE FROM initiative_project_tab_group
	 WHERE project_sid = in_sid_id;
	 
	DELETE FROM initiative_project_tab
	 WHERE project_sid = in_sid_id;
	  

	-- Initiatives will  be removed by the security sub-system as they
	-- are always chikd nodes of of projects or other initiatives

	DELETE FROM initiative_project
	 WHERE project_sid = in_sid_id;
END;

PROCEDURE CreateProject (
	in_name					IN	initiative_project.name%TYPE,
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_live_flow_state_id	IN	initiative_project.live_flow_state_id%TYPE DEFAULT NULL,
	in_start_dtm			IN	initiative_project.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm				IN	initiative_project.end_dtm%TYPE DEFAULT NULL,
	in_icon					IN	initiative_project.icon%TYPE DEFAULT NULL,
	in_abbreviation			IN	initiative_project.abbreviation%TYPE DEFAULT NULL,
	in_fields_xml			IN	initiative_project.fields_xml%TYPE DEFAULT XMLType('<fields/>'),
	in_period_fields_xml	IN	initiative_project.period_fields_xml%TYPE DEFAULT XMLType('<fields/>'),
	in_pos_group			IN	initiative_project.pos_group%TYPE DEFAULT NULL,
	in_pos					IN	initiative_project.pos%TYPE DEFAULT NULL,
	out_project_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_flow_state_id			initiative_project.live_flow_state_id%TYPE;
	v_parent_sid			security_pkg.T_SID_ID;
BEGIN
	-- Get the live flow state id
	SELECT NVL(in_live_flow_state_id, default_state_id)
	  INTO v_flow_state_id
	  FROM flow
	 WHERE flow_sid = in_flow_sid;

	-- Create the SO
	v_parent_sid := securableobject_pkg.GetSIDFromPath(
		security_pkg.GetACT,
		security_pkg.GetAPP,
		'Initiatives'
	);

	SecurableObject_Pkg.CreateSO(
		security_pkg.GetACT,
		v_parent_sid,
		class_pkg.getClassID('InitiativeProject'),
		NULL,
		out_project_sid
	);

	utils_pkg.UniqueSORename(
		security_pkg.GetACT,
		out_project_sid,
		SUBSTR(Replace(in_name,'/','\'), 0, 255) --'
	);

	-- Insert initiative project table entry
	INSERT INTO initiative_project (project_sid, name, start_dtm, end_dtm, fields_xml, period_fields_xml, icon, abbreviation, pos_group, pos, flow_sid, live_flow_state_id)
	VALUES (out_project_sid, in_name, in_start_dtm, in_end_dtm, in_fields_xml, in_period_fields_xml, in_icon, in_abbreviation, in_pos_group, in_pos, in_flow_sid, v_flow_state_id);
	
	initiative_pkg.InsertTab(out_project_sid, 'Credit360.Initiatives.Plugins.InitiativeDetailsPanel', 'Details', 1);
	initiative_pkg.InsertTab(out_project_sid, 'Credit360.Initiatives.DocumentsPanel', 'Documents', 2);
	initiative_pkg.InsertTab(out_project_sid, 'Credit360.Initiatives.IssuesPanel', 'Actions', 3);
	initiative_pkg.InsertTab(out_project_sid, 'Credit360.Initiatives.AuditLogPanel', 'Audit log', 4);
END;

PROCEDURE SetProject (
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_name					IN	initiative_project.name%TYPE,
	in_flow_sid				IN	security_pkg.T_SID_ID,
	in_icon					IN	initiative_project.icon%TYPE DEFAULT NULL,
	in_abbreviation			IN	initiative_project.abbreviation%TYPE DEFAULT NULL,
	in_fields_xml			IN	initiative_project.fields_xml%TYPE DEFAULT XMLType('<fields/>'),
	in_pos					IN	initiative_project.pos%TYPE DEFAULT NULL,
	out_project_sid			OUT	security_pkg.T_SID_ID
)
AS
v_flow_state_id				initiative_project.live_flow_state_id%TYPE;
v_project_sid_used			NUMBER := 0;
BEGIN
	IF NOT ((security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) AND
		(in_project_sid IS NULL OR 
		 security_pkg.IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), in_project_sid, security_pkg.PERMISSION_WRITE))) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify projects');
	END IF;

	IF in_project_sid IS NULL THEN
		CreateProject(
			in_name					=> in_name,
			in_flow_sid				=> in_flow_sid,
			in_icon					=> in_icon,
			in_abbreviation			=> in_abbreviation,
			in_fields_xml			=> NVL(in_fields_xml, XMLType('<fields/>')),
			in_pos					=> in_pos,
			out_project_sid			=> out_project_sid
		);
		
		INSERT INTO initiative_project_user_group (project_sid, initiative_user_group_id)
			 SELECT out_project_sid, initiative_user_group_id
			   FROM initiative_user_group
			  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	ELSE	
		out_project_sid := in_project_sid;

		SELECT COUNT(*)
   		  INTO v_project_sid_used
		  FROM initiative_project ip
		  JOIN initiative i ON ip.project_sid = i.project_sid 
		 WHERE ip.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = ip.app_sid
		   AND ip.project_sid = in_project_sid;

		IF v_project_sid_used = 0 THEN
			SELECT default_state_id
			  INTO v_flow_state_id
			  FROM flow
			  WHERE flow_sid = in_flow_sid;
			
			UPDATE project_initiative_metric
			   SET flow_sid = in_flow_sid
			 WHERE project_sid = in_project_sid;
			
			UPDATE initiative_project 
			   SET name = in_name, 
				   fields_xml = NVL(in_fields_xml, XMLType('<fields/>')), 
				   icon = in_icon, 
				   abbreviation = in_abbreviation, 
				   pos = in_pos, 
				   flow_sid = in_flow_sid,
				   live_flow_state_id = v_flow_state_id
			 WHERE project_sid = in_project_sid;			
		ELSE
			UPDATE initiative_project 
			   SET name = in_name, 
				   fields_xml = NVL(in_fields_xml, XMLType('<fields/>')), 
				   icon = in_icon, 
				   abbreviation = in_abbreviation, 
				   pos = in_pos
			 WHERE project_sid = in_project_sid;					
		END IF;
	END IF;
END;

PROCEDURE TryDeleteProject( 
	in_project_sid					IN  security_pkg.T_SID_ID
)
AS
	v_count							NUMBER;
BEGIN
	-- security check handled by securableobject_pkg
	SELECT COUNT(*)
	  INTO v_count
	  FROM initiative
	 WHERE project_sid = in_project_sid;
	 
	IF v_count > 0 THEN		
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 
			'Project is already in use by some existing initiatives.');
	END IF;
	
	securableobject_pkg.DeleteSO(security_pkg.GetAct, in_project_sid);
END;

PROCEDURE UNSEC_DeleteProjectInitMetrics (
	in_project_sid					IN  security_pkg.T_SID_ID,
	in_pos_group					IN  initiative_metric_group.pos_group%TYPE,
	in_proj_metrics_to_delete		IN  security.T_SID_TABLE
)
AS
BEGIN
	-- don't delete from INITIATIVE_METRIC_VAL, we want it to blow up if values will be deleted
	DELETE FROM initiative_metric_assoc
     WHERE app_sid = security_pkg.GetApp
	   AND project_sid = in_project_sid
	   AND proposed_metric_id IN (
		SELECT column_value FROM TABLE(in_proj_metrics_to_delete)
	   );
	   
	DELETE FROM initiative_metric_assoc
     WHERE app_sid = security_pkg.GetApp
	   AND project_sid = in_project_sid
	   AND measured_metric_id IN (
		SELECT column_value FROM TABLE(in_proj_metrics_to_delete)
	   );
	   
	DELETE FROM project_init_metric_flow_state
     WHERE app_sid = security_pkg.GetApp
	   AND project_sid = in_project_sid
	   AND initiative_metric_id IN (
		SELECT column_value FROM TABLE(in_proj_metrics_to_delete)
	   );
	
	BEGIN
		DELETE FROM project_initiative_metric
		 WHERE app_sid = security_pkg.GetApp
		   AND pos_group = NVL(in_pos_group, pos_group)
		   AND project_sid = in_project_sid
		   AND initiative_metric_id IN (
			SELECT column_value FROM TABLE(in_proj_metrics_to_delete)
		   );
	EXCEPTION
		WHEN csr_data_pkg.CHILD_RECORD_FOUND THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 
				'Project initiative metric is already in use.');
	END;
END;

PROCEDURE DeleteRemainingMetricGroups (
	in_project_sid					IN	security_pkg.T_SID_ID,
	in_pos_groups_to_keep			IN	security_pkg.T_SID_IDS
)
AS
	v_pos_groups_to_keep			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_pos_groups_to_keep);
	v_pos_groups_to_delete			security.T_SID_TABLE;
	v_proj_metrics_to_delete		security.T_SID_TABLE;
BEGIN
	IF NOT ((security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) AND
		security_pkg.IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), in_project_sid, security_pkg.PERMISSION_WRITE)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify projects');
	END IF;
		
	SELECT pos_group
	  BULK COLLECT INTO v_pos_groups_to_delete
	  FROM initiative_metric_group
	 WHERE app_sid = security_pkg.GetApp
	   AND project_sid = in_project_sid
	   AND pos_group NOT IN (
			SELECT column_value FROM TABLE(v_pos_groups_to_keep)
	   );
	   
	SELECT initiative_metric_id
	  BULK COLLECT INTO v_proj_metrics_to_delete
	  FROM project_initiative_metric 
	 WHERE app_sid = security_pkg.GetApp
	   AND project_sid = in_project_sid
	   AND pos_group IN (
		SELECT column_value FROM TABLE(v_pos_groups_to_delete)
	   );
	
	UNSEC_DeleteProjectInitMetrics(in_project_sid, NULL, v_proj_metrics_to_delete);
	
	DELETE FROM initiative_metric_group
	 WHERE app_sid = security_pkg.GetApp
	   AND project_sid = in_project_sid
	   AND pos_group IN (
		SELECT column_value FROM TABLE(v_pos_groups_to_delete)
	   );
END;

PROCEDURE EmptyTempMetricTables
AS
BEGIN
	DELETE FROM temp_project_initiative_metric;
	DELETE FROM temp_init_metric_flow_state;
END;

PROCEDURE AddTempInitiativeMetric (
	in_initiative_metric_id			IN  temp_project_initiative_metric.initiative_metric_id%TYPE,
	in_pos							IN  temp_project_initiative_metric.pos%TYPE,
	in_input_dp						IN  temp_project_initiative_metric.input_dp	%TYPE,
	in_info_text					IN  temp_project_initiative_metric.info_text%TYPE
)
AS
BEGIN
	INSERT INTO temp_project_initiative_metric (initiative_metric_id, pos, input_dp, info_text)
	     VALUES (in_initiative_metric_id, in_pos, in_input_dp, in_info_text);
END;

PROCEDURE AddTempInitiativeMetricState (
	in_initiative_metric_id			IN  temp_init_metric_flow_state.initiative_metric_id%TYPE,
	in_flow_state_id				IN  temp_init_metric_flow_state.flow_state_id%TYPE,
	in_mandatory					IN  temp_init_metric_flow_state.mandatory%TYPE,
	in_visible						IN  temp_init_metric_flow_state.visible%TYPE
)
AS
BEGIN
	INSERT INTO temp_init_metric_flow_state (initiative_metric_id, flow_state_id, mandatory, visible)
	     VALUES (in_initiative_metric_id, in_flow_state_id, in_mandatory, in_visible);
END;

PROCEDURE SetProjectMetricGroup (
	in_project_sid					IN	security_pkg.T_SID_ID,
	in_pos_group					IN  initiative_metric_group.pos_group%TYPE,
	in_is_group_mandatory			IN  initiative_metric_group.is_group_mandatory%TYPE,
	in_label						IN  initiative_metric_group.label%TYPE,
	in_info_text					IN  initiative_metric_group.info_text%TYPE,
	out_pos_group					OUT initiative_metric_group.pos_group%TYPE
)
AS
	v_flow_sid						security_pkg.T_SID_ID;
	v_proj_metrics_to_delete		security.T_SID_TABLE;
	v_count							NUMBER;
BEGIN
	IF NOT ((security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) AND
		security_pkg.IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), in_project_sid, security_pkg.PERMISSION_WRITE)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify projects');
	END IF;
	
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM initiative_project
	 WHERE project_sid = in_project_sid;
	
	IF in_pos_group IS NULL THEN
		-- urgh, it looks like an pos_group is being used as an id in pk/fks and to do the ordering
		-- should probably split it to have a proper id and a pos column, would need to be careful
		-- about child tables using the column to do ordering though
		SELECT NVL(MAX(pos_group)+1, 1)
		  INTO out_pos_group
		  FROM initiative_metric_group
		 WHERE project_sid = in_project_sid;
	
		INSERT INTO initiative_metric_group (project_sid, pos_group, is_group_mandatory, label, info_text)
		     VALUES (in_project_sid, out_pos_group, in_is_group_mandatory, in_label, in_info_text);
	ELSE
		UPDATE initiative_metric_group
		   SET is_group_mandatory = in_is_group_mandatory,
		       label = in_label,
		       info_text = in_info_text
		 WHERE project_sid = in_project_sid
		   AND pos_group = in_pos_group;
		   
		out_pos_group := in_pos_group;
	END IF;
	
	SELECT pim.initiative_metric_id
	  BULK COLLECT INTO v_proj_metrics_to_delete
	  FROM project_initiative_metric pim
	  LEFT JOIN temp_project_initiative_metric tpim ON pim.initiative_metric_id = tpim.initiative_metric_id
	 WHERE pim.app_sid = security_pkg.GetApp
	   AND project_sid = in_project_sid
	   AND pos_group = out_pos_group
	   AND tpim.initiative_metric_id IS NULL;
	   
	UNSEC_DeleteProjectInitMetrics(in_project_sid, out_pos_group, v_proj_metrics_to_delete);
	
	FOR r IN (
		SELECT initiative_metric_id, pos, input_dp, info_text
	      FROM temp_project_initiative_metric
	) LOOP
		BEGIN
			INSERT INTO project_initiative_metric (project_sid, pos_group, flow_sid, initiative_metric_id, pos, 
						input_dp, info_text)
				 VALUES (in_project_sid, out_pos_group, v_flow_sid, r.initiative_metric_id, r.pos,
						 r.input_dp, r.info_text);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE project_initiative_metric
				   SET pos_group = out_pos_group,
				       flow_sid = v_flow_sid,
					   pos = r.pos,
					   input_dp = r.input_dp,
					   info_text = r.info_text
				 WHERE project_sid = in_project_sid
				   AND initiative_metric_id = r.initiative_metric_id;
		END;
		
		-- if there aren't any flow states specified, default to adding all flow states
		-- this saves a load of clicks on the UI for the normal use-case
		SELECT COUNT(*) 
		  INTO v_count
		  FROM temp_init_metric_flow_state
		 WHERE initiative_metric_id = r.initiative_metric_id;
		 
		IF v_count = 0 THEN
			INSERT INTO temp_init_metric_flow_state (initiative_metric_id, flow_state_id, mandatory, visible)
			     SELECT r.initiative_metric_id, flow_state_id, 0, 1
				   FROM flow_state
				  WHERE flow_sid = v_flow_sid;
		END IF;
	END LOOP;

	DELETE FROM project_init_metric_flow_state pimfs
	      WHERE pimfs.project_sid = in_project_sid
			AND EXISTS (
				SELECT null
				  FROM project_initiative_metric pim
				 WHERE pim.project_sid = in_project_sid
				   AND pim.pos_group = out_pos_group
				   AND pim.initiative_metric_id = pimfs.initiative_metric_id
			)
	        AND (initiative_metric_id, flow_state_id) NOT IN (
				SELECT initiative_metric_id, flow_state_id
				  FROM temp_init_metric_flow_state
			);

	FOR r IN (
		SELECT initiative_metric_id, flow_state_id, mandatory, visible
	      FROM temp_init_metric_flow_state
	) LOOP
		BEGIN
			INSERT INTO project_init_metric_flow_state (project_sid, flow_sid, initiative_metric_id, flow_state_id, 
														mandatory, visible)
				 VALUES (in_project_sid, v_flow_sid, r.initiative_metric_id, r.flow_state_id, r.mandatory, r.visible);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE project_init_metric_flow_state
				   SET mandatory = r.mandatory,
				       visible = r.visible
				 WHERE project_sid = in_project_sid
				   AND flow_state_id = r.flow_state_id
				   AND initiative_metric_id = r.initiative_metric_id;
		END;
	END LOOP;

	EmptyTempMetricTables;
END;

PROCEDURE GetProject(
	in_project_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT project_sid, name, start_dtm, end_dtm, fields_xml, period_fields_xml,
			icon, abbreviation, pos_group, pos, flow_sid, live_flow_state_id, tab_sid
		  FROM initiative_project
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND project_sid = in_project_sid
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), project_sid, security_pkg.PERMISSION_READ) = 1
		;
END;

PROCEDURE GetProjects(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app							security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN
	OPEN out_cur FOR
		SELECT project_sid, name, start_dtm, end_dtm, fields_xml, period_fields_xml,
			icon, abbreviation, pos_group, pos, flow_sid, live_flow_state_id, tab_sid,
			security_pkg.SQL_IsAccessAllowedSid(
				v_act, 
				project_sid, 
				security_pkg.PERMISSION_WRITE + security_pkg.PERMISSION_ADD_CONTENTS) 
			can_create_children
		  FROM initiative_project
		 WHERE app_sid = v_app
		   AND security_pkg.SQL_IsAccessAllowedSid(
				v_act, 
				project_sid, 
				security_pkg.PERMISSION_READ) = 1
		 ORDER BY pos;
END;

PROCEDURE GetProjectSidsUsedForInitiatives(
	out_projectsids_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	
	OPEN out_projectsids_cur FOR 
	SELECT DISTINCT ip.project_sid
	  FROM initiative_project ip
	  JOIN initiative i ON ip.project_sid = i.project_sid 
	 WHERE ip.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND i.app_sid = ip.app_sid
	 ORDER BY ip.project_sid;
END;

PROCEDURE GetProjectsAndMetrics(
	out_projects_cur				OUT SYS_REFCURSOR,
	out_metric_group_cur			OUT SYS_REFCURSOR,
	out_metric_cur					OUT SYS_REFCURSOR,
	out_metric_flow_state_cur		OUT SYS_REFCURSOR
)
AS
	v_project_sids					security.T_SID_TABLE;
BEGIN
	-- permission check carried out in selects
	GetProjects(out_projects_cur);
	
	SELECT project_sid
	  BULK COLLECT INTO v_project_sids
	  FROM initiative_project
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), project_sid, security_pkg.PERMISSION_READ) = 1;
	
	OPEN out_metric_group_cur FOR
		SELECT project_sid, pos_group, is_group_mandatory, label, info_text
		  FROM initiative_metric_group m
		  JOIN TABLE(v_project_sids) p ON m.project_sid = p.column_value
		 ORDER BY pos_group;
	
	OPEN out_metric_cur FOR
		SELECT project_sid, pos, pos_group, update_per_period, default_value, input_dp, 
		       display_context, initiative_metric_id, flow_sid, info_text
		  FROM project_initiative_metric m
		  JOIN TABLE(v_project_sids) p ON m.project_sid = p.column_value
		 ORDER BY pos_group, pos;
		 
	OPEN out_metric_flow_state_cur FOR
		SELECT project_sid, initiative_metric_id, flow_state_id, mandatory, visible, flow_sid
		  FROM project_init_metric_flow_state m
		  JOIN TABLE(v_project_sids) p ON m.project_sid = p.column_value;
END;

PROCEDURE GetTagGroups(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pg.project_sid, pg.pos, tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tg.lookup_key, pg.default_tag_id
		  FROM initiative_project p, project_tag_group pg, v$tag_group tg
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), p.project_sid, security_pkg.PERMISSION_READ) = 1
		   AND pg.project_sid = p.project_sid
		   AND tg.tag_group_id = pg.tag_group_id
		   	ORDER BY project_sid
		;
END;

PROCEDURE GetTagGroupsForProject(
	in_project_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pg.project_sid, pg.pos, tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tg.lookup_key, pg.default_tag_id
		  FROM initiative_project p, project_tag_group pg, v$tag_group tg
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.project_sid = in_project_sid
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), p.project_sid, security_pkg.PERMISSION_READ) = 1
		   AND pg.project_sid = p.project_sid
		   AND tg.tag_group_id = pg.tag_group_id
		;
END;

PROCEDURE GetTagFilters(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT project_sid, tag_group_id, tag_id
		  FROM project_tag_filter
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), project_sid, security_pkg.PERMISSION_READ) = 1
		   	ORDER BY project_sid
		;
END;

PROCEDURE GetTagGroupMembers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_id				IN	tag_group.tag_group_id%TYPE,
	in_project_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_project_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading project with SID '||in_project_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT *
		FROM (
			SELECT t.tag_id, tag, explanation, pos, t.lookup_key, t.exclude_from_dataview_grouping, tgm.active, tgm.tag_group_id,
				project_sid, count(project_sid) over (partition by tgm.tag_group_id) cnt
			  FROM tag_group_member tgm, v$tag t, project_tag_filter f
			 WHERE tgm.tag_id = t.tag_id
			   AND tgm.tag_group_id = in_tag_group_id
			   AND f.project_sid(+) = in_project_sid
			   AND f.tag_id(+) = tgm.tag_id
		 ) 
		 WHERE NVL(project_sid, -1) = DECODE(cnt, 0, -1, project_sid)
			ORDER BY pos;
END;

END initiative_project_pkg;
/
