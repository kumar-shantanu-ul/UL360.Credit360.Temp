CREATE OR REPLACE PACKAGE BODY CSR.section_root_Pkg
IS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
	v_status_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT section_status_sid
	  INTO v_status_sid
	  FROM (
		SELECT section_status_sid, ROWNUM rn
		  FROM section_status
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	  )
	  WHERE rn = 1;

	INSERT INTO SECTION_MODULE (MODULE_ROOT_SID, app_sid, LABEL, default_status_sid, show_summary_tab)
		VALUES (in_sid_id, SYS_CONTEXT('SECURITY','APP'), in_name, v_status_sid, 1);
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	null;
END;

PROCEDURE TrashObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_section_sid		IN security_pkg.T_SID_ID
)
AS
BEGIN
	null;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT section_Sid
		  FROM section
		 WHERE parent_sid IS NULL
		   AND module_root_sid = in_sid_id
	)
	LOOP
		securableobject_pkg.deleteSO(in_act_id, r.section_sid);
	END LOOP;

	-- Clear any previous links to this module (done automatically in sections)
	UPDATE section_module SET previous_module_sid = NULL WHERE previous_module_sid = in_sid_id;

	DELETE FROM section_module
	 WHERE module_root_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE CloneRoot(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_app_sid_id			IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_new_name				IN	security_pkg.T_SO_NAME,
	in_flow_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_flow_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_include_responses	IN	NUMBER DEFAULT 1,
	in_incr_due_dates		IN	NUMBER DEFAULT 0,
	in_include_routes		IN	NUMBER DEFAULT 0,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_default_start		IN	DATE,
	in_default_end			IN	DATE,
	out_sid_id				OUT security_pkg.T_SID_ID
)
AS
	v_flow_match			NUMBER(1);
	v_flow_sid				section_module.flow_sid%TYPE;
	v_version_number		section_version.version_number%TYPE;
	v_attachment_Id			attachment.attachment_id%TYPE;
	v_new_section_sid		security_pkg.T_SID_ID;
	v_new_route_id			security_pkg.T_SID_ID; --Not a sid but will do
	v_new_route_step_id		security_pkg.T_SID_ID; --Not a sid but will do
	parentStack				Stack := Stack(null,null,null);
	v_parent_sid			Integer := null;
	v_previous_level		Integer := null;
	CURSOR c_acl(v_sid	security_pkg.T_SID_ID) IS
		SELECT permission_set
		  FROM security.ACL
		 WHERE acl_id = acl_pkg.GetDACLIDForSID(v_Sid)
		   AND sid_Id = v_sid;
	v_permission			security_pkg.T_PERMISSION;
	v_route_step_id			security_pkg.T_SID_ID;
BEGIN
	-- Cannot roll forward workflow if it doesn't match existing flow
	SELECT DECODE(flow_sid, in_flow_sid, 1, 0) is_match, flow_sid
	  INTO v_flow_match, v_flow_sid
	  FROM section_module
	 WHERE module_root_sid = in_module_root_sid;

	IF v_flow_match = 0 AND in_include_routes = 1 THEN
		RAISE_APPLICATION_ERROR(ERR_FLOW_MISMATCH, 'Cannot clone section module when workflow ('||in_flow_sid||') does not match previous workflow ('|| v_flow_sid || ')');
	END IF;

	CreateRoot(in_act_id, in_app_sid_id, in_new_name, in_flow_sid, in_flow_region_sid, in_parent_sid, in_default_start, in_default_end, out_sid_id);

	UPDATE section_module
	   SET previous_module_sid = in_module_root_sid
	 WHERE module_root_sid = out_sid_id;

	parentStack.initialize;

	FOR r IN (
		SELECT section_sid, parent_Sid, version_number, section_position, active,
			title_only, REF, plugin, plugin_config, section_status_sid, further_info_url,
			title, body, help_text, level lvl
		  FROM v$visible_version
		 WHERE module_root_sid = in_module_root_Sid
		 AND active = 1 -- exclude 'deleted' sections from the clone
		 START WITH parent_sid IS NULL
		CONNECT BY PRIOR section_sid = parent_sid
		 ORDER SIBLINGS BY section_position
	)
	LOOP
		IF r.lvl < v_previous_level THEN
			-- we've gone up, but how far? (or on same level, so just pops one off)
			FOR i IN r.lvl..v_previous_level-1
			LOOP
				parentStack.pop(v_parent_sid);
			END LOOP;
		ELSIF r.lvl > v_previous_level THEN
			-- we've gone deeper np...
			parentStack.push(v_parent_sid);
			v_parent_sid := v_new_section_sid;
		END IF;

		OPEN c_acl(r.section_sid);
		FETCH c_acl INTO v_permission;
		IF c_acl%NOTFOUND THEN
			-- some defaults that I found in section_body
			v_permission := security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_DELETE +
				security_pkg.PERMISSION_ADD_CONTENTS + csr_data_pkg.PERMISSION_CHANGE_TITLE + security_pkg.PERMISSION_WRITE;
		END IF;
		CLOSE c_acl;

		section_pkg.CreateSectionWithPerms(in_act_Id, in_app_sid_id, out_sid_id, v_permission, v_parent_sid,
			r.title, r.title_only,
			CASE WHEN in_include_responses != 0 OR r.plugin = 'Credit360.Text.FormPlugin' THEN r.body ELSE NULL END,
			r.help_text,
			r.ref, r.further_info_url, r.plugin, 0, v_new_section_sid);

		UPDATE section
		   SET plugin = r.plugin,
				plugin_config = r.plugin_config,
				previous_section_sid = r.section_sid
		 WHERE section_sid = v_new_section_sid
		 RETURNING visible_version_number INTO v_version_number;

		-- copy tags
		INSERT INTO section_tag_member (section_sid, section_tag_id)
			SELECT v_new_section_sid, section_tag_id FROM section_tag_member WHERE section_sid = r.section_sid;

		IF in_include_routes = 1 THEN
			FOR nr IN (
				  SELECT rt.route_id, rt.section_sid, rt.flow_state_id, rt.flow_sid, rt.due_dtm
					FROM route rt
					JOIN flow f ON rt.flow_sid = f.flow_sid AND rt.app_sid = f.app_sid
				   WHERE rt.section_sid = r.section_sid
			)
			LOOP
				INSERT INTO route (app_sid, route_id, section_sid, flow_state_id, flow_sid, due_dtm)
				VALUES (in_app_sid_id, route_id_seq.nextval, v_new_section_sid, nr.flow_state_id, nr.flow_sid, add_months(nr.due_dtm, in_incr_due_dates))
				RETURNING route_id INTO v_new_route_id;

				FOR nnr IN (SELECT app_sid, route_step_id, work_days_offset, step_due_dtm, pos
						  FROM route_step
						 WHERE route_id = nr.route_id)
				LOOP
					INSERT INTO route_step (app_sid, route_step_id, route_id, work_days_offset, step_due_dtm, pos)
					VALUES (nnr.app_sid, route_step_id_seq.nextval, v_new_route_id, nnr.work_days_offset, add_months(nnr.step_due_dtm, in_incr_due_dates), nnr.pos)
					RETURNING route_step_id INTO v_new_route_step_id;

					INSERT INTO route_step_user (app_sid, route_step_id, csr_user_sid)
						SELECT rs.app_sid, v_new_route_step_id, csr_user_sid
						  FROM route_step rs JOIN route_step_user rsu ON rs.route_step_id = rsu.route_step_id
						 WHERE rs.route_step_id = nnr.route_step_id;
				END LOOP;
			END LOOP;

			FOR rec IN (SELECT section_sid from section WHERE module_root_sid = out_sid_id)
			LOOP
				SELECT MIN(rs.route_step_id)
				  INTO v_route_step_id
				  FROM section_module sm
				  JOIN flow f ON f.flow_sid = sm.flow_sid
				  JOIN section_routed_flow_state srfs ON srfs.flow_state_id = f.default_state_id
				  JOIN route r ON r.flow_state_id = f.default_state_id
				  JOIN route_step rs ON rs.route_id = r.route_id
				 WHERE sm.flow_sid = in_flow_sid
				   AND sm.module_root_sid = out_sid_id
				   AND r.section_sid = rec.section_sid
				   AND rs.pos = 0;

				IF v_route_step_id IS NOT NULL THEN
					UPDATE section
					   SET current_route_step_id = v_route_step_id
					 WHERE section_sid = rec.section_sid;
				END IF;
			END LOOP;
		END IF;

		IF in_include_responses != 0 OR r.plugin = 'Credit360.Text.FormPlugin' THEN
			UPDATE section
			   SET section_status_sid = r.section_status_sid
			 WHERE section_sid = v_new_section_sid;

			-- copy section_fact
			INSERT INTO section_fact (section_sid, fact_id, map_to_ind_sid, map_to_region_sid, std_measure_conversion_id, data_type, max_length)
				SELECT v_new_section_sid, fact_id, map_to_ind_sid, map_to_region_sid, std_measure_conversion_id, data_type, max_length
				  FROM section_fact
				 WHERE section_sid = r.section_sid
				   AND is_active = 1;

			-- copy section_val PERIOD_SET_ID      NOT NULL NUMBER(10)    PERIOD_INTERVAL_ID NOT NULL NUMBER(10) 
			INSERT INTO section_val (section_val_id, section_sid, fact_id, idx, start_dtm, end_dtm, val_number, note, period_set_id, period_interval_id)
				SELECT section_val_id_seq.NEXTVAL, v_new_section_sid, sv.fact_id, sv.idx, sv.start_dtm, sv.end_dtm, sv.val_number, sv.note,
					sv.period_set_id, sv.period_interval_id
				  FROM section_val sv
				  JOIN section_fact sf ON sv.section_sid = sf.section_sid AND sv.fact_id = sf.fact_id
				 WHERE sv.section_sid = r.section_sid
				   AND sf.is_active = 1;

			-- copy attachments
			FOR ra IN (
				SELECT a.attachment_id, filename, mime_type, data, embed, dataview_sid, last_updated_from_dataview, view_as_table, indicator_sid, doc_id, url
				  FROM attachment_history ah, attachment a
				 WHERE ah.section_sid = r.section_sid
				   --AND ah.version_number = r.version_number -- this seems broken, i.e. attachments aren't linked to versions
				   AND a.attachment_id = ah.attachment_id
			)
			LOOP
				INSERT INTO attachment (
					attachment_id, filename, mime_type, data, embed, dataview_sid, last_updated_from_dataview, view_as_table, indicator_sid, doc_id, url
				) VALUES (
					attachment_id_seq.nextval, ra.filename, ra.mime_type, ra.data, ra.embed, ra.dataview_sid, ra.last_updated_from_dataview,
						ra.view_as_table, ra.indicator_sid, ra.doc_id, ra.url
				) RETURNING attachment_id INTO v_attachment_Id;

				INSERT INTO attachment_history (
					section_sid, version_number, attachment_id
				) VALUES (
					v_new_section_sid, v_version_number, v_attachment_Id
				);

				-- copy section fact attachments
				INSERT INTO section_fact_attach (section_sid, fact_id, fact_idx, attachment_id)
					SELECT v_new_section_sid, fact_id, fact_idx, v_attachment_Id
					  FROM section_fact_attach
					 WHERE section_sid = r.section_sid
					   AND attachment_id = ra.attachment_id;
			END LOOP;

			-- copy promoted documents
			INSERT INTO section_content_doc (section_sid, doc_id)
				SELECT v_new_section_sid, doc_id FROM section_content_doc WHERE section_sid = r.section_sid;
		END IF;

		v_previous_level := r.lvl;
	END LOOP;
END;

PROCEDURE CloneRoot(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_app_sid_id			IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_new_name				IN	security_pkg.T_SO_NAME,
	in_flow_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_flow_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_include_responses	IN	NUMBER DEFAULT 1,
	in_incr_due_dates		IN	NUMBER DEFAULT 0,
	in_include_routes		IN	NUMBER DEFAULT 0,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	out_sid_id				OUT security_pkg.T_SID_ID
)
AS
BEGIN
	CloneRoot(in_act_Id, in_app_sid_id, in_module_root_sid, in_new_name, in_flow_sid, in_flow_region_sid,
		in_include_responses, in_incr_due_dates, in_include_routes, in_parent_sid, NULL, NULL, out_sid_id);
END;

PROCEDURE CreateRoot(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid_id		IN	security_pkg.T_SID_ID,
	in_name				IN	security_pkg.T_SO_NAME,
	in_flow_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_flow_region_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_parent_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_default_start	IN	DATE DEFAULT NULL,
	in_default_end		IN	DATE DEFAULT NULL,
	out_sid_id			OUT security_pkg.T_SID_ID
)
AS
	v_id						number(10);
	v_admins					security_pkg.T_SID_ID;
	v_reg_users					security_pkg.T_SID_ID;
	v_new_sid_acl_id			security_pkg.T_ACL_ID;
	v_indexes_sid				security_pkg.T_ACL_ID;
	v_corp_lib_folder_sid		security_pkg.T_SID_ID;
	v_doclib_sid				security_pkg.T_SID_ID;
BEGIN
	-- sometimes administrators gets renamed. Grr....
	BEGIN
		v_admins := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid_id, 'Groups/Administrators');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			v_admins := null;
	END;

	-- regusers is always regusers though
	v_reg_users := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid_id, 'Groups/RegisteredUsers');

	-- they all go under 'Indexes' now
	BEGIN
		v_indexes_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid_id, 'Indexes');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			SecurableObject_pkg.CreateSO(in_act_id, in_app_sid_id, security_pkg.SO_CONTAINER, 'Indexes', v_indexes_sid);
			-- add ACEs
			v_new_sid_acl_id := acl_pkg.GetDACLIDForSID(v_indexes_sid);

			-- reg users can read
			acl_pkg.AddACE(in_act_id, v_new_sid_acl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);

			-- admins can do everything
			IF v_admins IS NOT NULL THEN
				acl_pkg.AddACE(in_act_id, v_new_sid_acl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_CHANGE_TITLE);
			END IF;
	END;

	-- create node
	securableObject_pkg.CreateSO(in_act_id, NVL(in_parent_sid, v_indexes_sid), class_pkg.GetClassId('CSRSectionRoot'), in_name, out_sid_id);

	-- make sure we have entry in section_flow
	IF in_flow_sid IS NOT NULL THEN
		BEGIN
			INSERT INTO section_flow (flow_sid) VALUES (in_flow_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END IF;

	UPDATE section_module
	  SET flow_sid = in_flow_sid,
		region_sid = in_flow_region_sid,
		 start_dtm = in_default_start,
		   end_dtm = in_default_end
	 WHERE module_root_sid = out_sid_id;

	BEGIN
		v_corp_lib_folder_sid := security.securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid_id, 'IndexLibs');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.SecurableObject_pkg.CreateSO(in_act_id, in_app_sid_id, security.security_pkg.SO_CONTAINER, 'IndexLibs', v_corp_lib_folder_sid);
	END;

	BEGIN
		csr.doc_lib_pkg.CreateLibrary(
			v_corp_lib_folder_sid,
			in_name,
			'Documents',
			'Recycle bin',
			in_app_sid_id,
			v_doclib_sid);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			csr.doc_lib_pkg.CreateLibrary(
				v_corp_lib_folder_sid,
				in_name || out_sid_id,
				'Documents',
				'Recycle bin',
				in_app_sid_id,
				v_doclib_sid);
	END;

	UPDATE csr.section_module
	   SET library_sid = (SELECT documents_sid FROM csr.doc_library WHERE doc_library_sid = v_doclib_sid)
	 WHERE app_sid = in_app_sid_id
	   AND module_root_sid = out_sid_id;
	/*
	-- we'll need this if setting the flow_sid where it's currently unset
	FOR r IN (
		SELECT s.section_sid
		 FROM csr.section_module sm
			JOIN csr.section s ON sm.module_root_sid = s.module_root_sid
		WHERE sm.flow_sid IS NOT NULL
		  AND s.flow_item_id IS NULL
	)
	LOOP
		csr.flow_pkg.AddSectionItem(r.section_sid, v_id);
	END LOOP;
	*/
END;

PROCEDURE GetModuleByName(
	in_name				IN section_module.label%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT s.module_root_sid, s.label, s.show_summary_tab, s.show_flow_summary_tab,
				s.previous_module_sid, p.label previous_module_label
		  FROM section_module s
		  LEFT JOIN section_module p ON s.previous_module_sid = p.module_root_sid
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND s.label = in_name;
END;

PROCEDURE GetModuleBySid(
	in_module_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT s.module_root_sid, s.label, s.show_summary_tab, s.show_flow_summary_tab,
				s.previous_module_sid, p.label previous_module_label, NVL(s.region_sid,0) linked_region_sid,
				s.start_dtm, s.end_dtm
		  FROM section_module s
		  LEFT JOIN section_module p ON s.previous_module_sid = p.module_root_sid
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND s.module_root_sid = in_module_sid;
END;

PROCEDURE GetModuleBySidWithPerm(
	in_module_sid			IN security.security_pkg.T_SID_ID,
	in_permission_set		IN security.security_pkg.T_PERMISSION,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_module_sid, in_permission_set) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied on index with sid '||in_module_sid);
	END IF;

	GetModuleBySid(in_module_sid, out_cur);
END;

FUNCTION GetRootSidFromName(
	in_label			IN	security_pkg.T_SO_NAME
) RETURN NUMBER
AS
	v_sid	  security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT module_root_sid
		  INTO v_sid
		  FROM section_module
		 WHERE app_sid = SYS_CONTEXT('SYSTEM', 'APP')
		   AND LOWER(label) = LOWER(in_label);

		RETURN v_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- send back a nicer exception
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The module with name '||in_label||' was not found');
	END;
END;

PROCEDURE GetModules(
	in_act_id			IN		security_pkg.T_ACT_ID,
	in_app_sid			IN		security_pkg.T_SID_ID,
	out_cur				OUT		security_pkg.T_OUTPUT_CUR
)
AS
	v_module_root_sids_tbl		security.T_SID_TABLE;
BEGIN
	SELECT module_root_sid
	  BULK COLLECT INTO v_module_root_sids_tbl
	  FROM section_module
	 WHERE app_sid = in_app_sid;

	-- No procedure that returns SO with permission sets (read/write/delete)
	-- Get individual SO set for read, write and delete permission and join
	OPEN out_cur FOR
		SELECT sm.module_root_sid, sm.label, sm.show_summary_tab,
			   CASE WHEN sm_w.sid_id IS NULL THEN 0 ELSE 1 END can_edit,
			   CASE WHEN sm_d.sid_id IS NULL THEN 0 ELSE 1 END can_delete
		  FROM section_module sm
		  JOIN TABLE(security.securableobject_pkg.GetSIDsWithPermAsTable(in_act_id, v_module_root_sids_tbl, security.security_pkg.PERMISSION_READ)) sm_r
			ON sm.module_root_sid = sm_r.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetSIDsWithPermAsTable(in_act_id, v_module_root_sids_tbl, csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE)) sm_w
			ON sm.module_root_sid = sm_w.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetSIDsWithPermAsTable(in_act_id, v_module_root_sids_tbl, security.security_pkg.PERMISSION_DELETE)) sm_d
			ON sm.module_root_sid = sm_d.sid_id
		 ORDER BY label;
END;

PROCEDURE GetModules2(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_folder_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_module_root_sids_tbl		security.T_SID_TABLE;
BEGIN
	SELECT module_root_sid
	  BULK COLLECT INTO v_module_root_sids_tbl
	  FROM section_module
	 WHERE app_sid = in_app_sid;

	-- No procedure that returns SO with permission sets (read/write/delete)
	-- Get individual SO set for read, write and delete permission and join
	OPEN out_cur FOR
		SELECT sm.module_root_sid, so.parent_sid_id AS parent_sid, sm.label AS name, '' AS description, sm.label,
			   sm.show_summary_tab, sm.active, sm.flow_sid, sm.reminder_offset,
			   sm.region_sid, r.description region_description, f.label flow_label, sm.show_fact_icon,
			   CASE WHEN sm_w.sid_id IS NULL THEN 0 ELSE 1 END can_edit,
			   CASE WHEN sm_d.sid_id IS NULL THEN 0 ELSE 1 END can_delete
		  FROM section_module sm
		  JOIN security.securable_object so ON sm.module_root_sid = so.sid_id
		  JOIN TABLE(security.securableobject_pkg.GetSIDsWithPermAsTable(in_act_id, v_module_root_sids_tbl, security.security_pkg.PERMISSION_READ)) sm_r
			ON sm.module_root_sid = sm_r.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetSIDsWithPermAsTable(in_act_id, v_module_root_sids_tbl, csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE)) sm_w
			ON sm.module_root_sid = sm_w.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetSIDsWithPermAsTable(in_act_id, v_module_root_sids_tbl, security.security_pkg.PERMISSION_DELETE)) sm_d
			ON sm.module_root_sid = sm_d.sid_id
		  LEFT JOIN v$region r ON sm.region_sid = r.region_sid AND sm.app_sid = r.app_sid
		  LEFT JOIN flow f ON sm.flow_sid = f.flow_sid AND sm.app_sid = f.app_sid
		 WHERE sm.app_sid = in_app_sid
		   AND (in_folder_sid IS NULL OR in_folder_sid = -1 OR so.parent_sid_id = in_folder_sid)
		 ORDER BY sm.label;
END;

PROCEDURE SetModuleActivity(
	in_module_sid		IN security_pkg.T_SID_ID,
	in_active			IN NUMBER
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), in_module_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied writing to index with sid '||in_module_sid);
	END IF;

	UPDATE section_module
	   SET active = in_active
	 WHERE module_root_sid = in_module_sid;
END;

PROCEDURE SetModuleAttribs(
	in_module_sid		IN security_pkg.T_SID_ID,
	in_label			IN section_module.label%TYPE,
	in_reminder_offset	IN section_module.reminder_offset%TYPE,
	in_show_fact_icon	IN NUMBER DEFAULT 0
)
AS
	v_act				security_pkg.T_ACT_ID;
BEGIN
	v_act := security_pkg.GetACT();

	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_module_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied writing to index with sid '||in_module_sid);
	END IF;

	UPDATE section_module
	   SET label = in_label, reminder_offset = in_reminder_offset, show_fact_icon = in_show_fact_icon
	 WHERE module_root_sid = in_module_sid;

	SecurableObject_pkg.RenameSO(v_act, in_module_sid, in_label);
END;

FUNCTION GetModulesRoot(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
BEGIN
	RETURN security.securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Indexes');
END;

PROCEDURE SetPreviousModuleByName(
	in_module_root_sid		IN	section_module.module_root_sid%TYPE,
	in_previous_label		IN	section_module.label%TYPE
)
AS
	v_module_root_sid	section_module.module_root_sid%TYPE;
	CURSOR getModuleSid_cur IS
		SELECT module_root_sid
		  FROM section_module
		 WHERE LOWER(label) = LOWER(in_previous_label)
		   AND active = 1;
BEGIN
	OPEN getModuleSid_cur;
	FETCH getModuleSid_cur INTO v_module_root_sid;

	-- The standard index scripts will contain previous mappings but the client may not have the previous module installed
	-- If not found, don't throw error
	IF getModuleSid_cur%FOUND THEN
		UPDATE section_module
		   SET previous_module_sid = v_module_root_sid
		 WHERE module_root_sid = in_module_root_sid;
	END IF;
END;

PROCEDURE GetModuleBySectionSid(
	in_section_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_module_sid				section_module.module_root_sid%TYPE;
BEGIN
	SELECT module_root_sid
	  INTO v_module_sid
	  FROM csr.section
	 WHERE section_sid = in_section_sid;

	GetModuleBySid(v_module_sid, out_cur);
END;

PROCEDURE GetTreeWithDepth(
	in_act_id						IN	security.security_pkg.T_ACT_ID,
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_app_sid							security.security_pkg.T_SID_ID;
	v_indexes_sid						security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_indexes_sid := GetModulesRoot(in_act_id, v_app_sid);

	OPEN out_cur FOR
		SELECT so.sid_id, so.parent_sid_id, NVL(sm.label, so.name) name, so.class_name,
			   LEVEL so_level, CONNECT_BY_ISLEAF is_leaf, 1 is_match
		  FROM (
			SELECT sid_id, parent_sid_id, name,
				   CASE WHEN class_id = 4 THEN 'Container' ELSE 'CSRSectionRoot' END class_name
			  FROM TABLE(security.securableobject_pkg.GetTreeWithPermAsTable(in_act_id, v_indexes_sid, security.security_pkg.PERMISSION_READ))
			 WHERE class_id IN (class_pkg.GetClassId('CSRSectionRoot'), security.security_pkg.SO_CONTAINER)
		  ) so
		  LEFT JOIN section_module sm ON so.sid_id = sm.module_root_sid
		 WHERE LEVEL <= in_fetch_depth
		 START WITH (in_include_root = 0 AND parent_sid_id = in_parent_sid) OR (in_include_root = 1 AND sid_id = in_parent_sid)
	   CONNECT BY PRIOR sid_id = parent_sid_id
		 ORDER SIBLINGS BY name, sid_id;
END;

PROCEDURE GetTreeWithSelect(
	in_act_id						IN	security.security_pkg.T_ACT_ID,
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	in_select_sid					IN	security.security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_app_sid							security.security_pkg.T_SID_ID;
	v_indexes_sid						security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_indexes_sid := GetModulesRoot(in_act_id, v_app_sid);

	OPEN out_cur FOR
		WITH framework AS (
			SELECT so.sid_id, so.parent_sid_id, NVL(sm.label, so.name) name, so.class_name,
				   LEVEL so_level, CONNECT_BY_ISLEAF is_leaf, 1 is_match
			  FROM (
				SELECT sid_id, parent_sid_id, name,
					   CASE WHEN class_id = 4 THEN 'Container' ELSE 'CSRSectionRoot' END class_name
				  FROM TABLE(security.securableobject_pkg.GetTreeWithPermAsTable(in_act_id, v_indexes_sid, security.security_pkg.PERMISSION_READ))
				 WHERE class_id IN (class_pkg.GetClassId('CSRSectionRoot'), security.security_pkg.SO_CONTAINER)
			  ) so
			  LEFT JOIN section_module sm ON so.sid_id = sm.module_root_sid
			 START WITH (in_include_root = 0 AND parent_sid_id = in_parent_sid) OR (in_include_root = 1 AND sid_id = in_parent_sid)
		   CONNECT BY PRIOR sid_id = parent_sid_id
			 ORDER SIBLINGS BY name, sid_id
		)
		SELECT sid_id, parent_sid_id, name, class_name,
			   so_level, is_leaf, is_match
		  FROM framework
		 WHERE so_level <= in_fetch_depth
			OR sid_id IN (
				SELECT sid_id
				  FROM framework
				 START WITH sid_id = in_select_sid
			   CONNECT BY PRIOR parent_sid_id = sid_id
			   )
			OR parent_sid_id IN (
				SELECT sid_id
				  FROM framework
				 START WITH sid_id = in_select_sid
			   CONNECT BY PRIOR parent_sid_id = sid_id
			   );
END;

PROCEDURE GetTreeTextFiltered(
	in_act_id						IN	security.security_pkg.T_ACT_ID,
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_app_sid							security.security_pkg.T_SID_ID;
	v_indexes_sid						security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_indexes_sid := GetModulesRoot(in_act_id, v_app_sid);

	OPEN out_cur FOR
		WITH framework AS (
			SELECT so.sid_id, so.parent_sid_id, NVL(sm.label, so.name) name, so.class_name,
				   LEVEL so_level, CONNECT_BY_ISLEAF is_leaf, 1 is_match, ROWNUM rn
			  FROM (
				SELECT sid_id, parent_sid_id, name,
					   CASE WHEN class_id = 4 THEN 'Container' ELSE 'CSRSectionRoot' END class_name
				  FROM TABLE(security.securableobject_pkg.GetTreeWithPermAsTable(in_act_id, v_indexes_sid, security.security_pkg.PERMISSION_READ))
				 WHERE class_id IN (class_pkg.GetClassId('CSRSectionRoot'), security.security_pkg.SO_CONTAINER)
			  ) so
			  LEFT JOIN section_module sm ON so.sid_id = sm.module_root_sid
			 START WITH (in_include_root = 0 AND parent_sid_id = in_parent_sid) OR (in_include_root = 1 AND sid_id = in_parent_sid)
		   CONNECT BY PRIOR sid_id = parent_sid_id
			 ORDER SIBLINGS BY name, sid_id
		)
		SELECT framework.sid_id, parent_sid_id, name, class_name,
			   so_level, is_leaf, is_match
		  FROM framework
		  JOIN (
				SELECT DISTINCT sid_id
				  FROM framework
				 START WITH sid_id IN (
					SELECT sid_id
					  FROM framework
					 WHERE (in_search_phrase IS NULL OR LOWER(name) LIKE '%'||LOWER(in_search_phrase)||'%')
						OR (REGEXP_LIKE(in_search_phrase, '^[0-9]+$') AND sid_id = TO_NUMBER(in_search_phrase))
					)
			   CONNECT BY PRIOR parent_sid_id = sid_id
			   ) rslt
			ON framework.sid_id = rslt.sid_id
		 ORDER BY framework.rn;
END;

PROCEDURE GetListTextFiltered(
	in_act_id						IN	security.security_pkg.T_ACT_ID,
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_app_sid							security.security_pkg.T_SID_ID;
	v_indexes_sid						security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_indexes_sid := GetModulesRoot(in_act_id, v_app_sid);

	OPEN out_cur FOR
		WITH framework AS (
			SELECT so.sid_id, so.parent_sid_id, NVL(sm.label, so.name) name, so.class_name,
				   LEVEL so_level, CONNECT_BY_ISLEAF is_leaf, 1 is_match,
				   path
			  FROM (
				SELECT sid_id, parent_sid_id, name,
					   CASE WHEN class_id = 4 THEN 'Container' ELSE 'CSRSectionRoot' END class_name,
					   path
				  FROM TABLE(security.securableobject_pkg.GetTreeWithPermAsTable(in_act_id, v_indexes_sid, security.security_pkg.PERMISSION_READ, NULL, NULL, 1))
				 WHERE class_id IN (class_pkg.GetClassId('CSRSectionRoot'), security.security_pkg.SO_CONTAINER)
			  ) so
			  LEFT JOIN section_module sm ON so.sid_id = sm.module_root_sid
			 WHERE (in_search_phrase IS NULL OR LOWER(name) LIKE '%'||LOWER(in_search_phrase)||'%')
				OR (REGEXP_LIKE(in_search_phrase, '^[0-9]+$') AND sid_id = TO_NUMBER(in_search_phrase))
			 START WITH (in_include_root = 0 AND parent_sid_id = in_parent_sid) OR (in_include_root = 1 AND sid_id = in_parent_sid)
		   CONNECT BY PRIOR sid_id = parent_sid_id
			 ORDER SIBLINGS BY name, sid_id
		)
		SELECT framework.sid_id, parent_sid_id, name, class_name,
			   so_level, is_leaf, is_match, path
		  FROM framework
		 WHERE ROWNUM <= in_fetch_limit;
END;

END section_root_Pkg;
/
