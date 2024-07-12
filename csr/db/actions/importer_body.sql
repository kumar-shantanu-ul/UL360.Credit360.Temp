CREATE OR REPLACE PACKAGE BODY ACTIONS.importer_pkg
IS


PROCEDURE GetMappingMRU(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT from_name, to_name
		  FROM import_mapping_mru
		 WHERE app_sid = security_pkg.GetAPP
		   AND csr_user_sid = security_pkg.GetSID
		   	ORDER BY pos DESC;
END;


PROCEDURE UpdateMappingMRU(
	in_dummy			IN	NUMBER,
	in_from_headings	IN	security_pkg.T_VARCHAR2_ARRAY,
	in_to_headings		IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_from				security.T_VARCHAR2_TABLE;
	v_to				security.T_VARCHAR2_TABLE;
BEGIN
	
	v_from := security_pkg.Varchar2ArrayToTable(in_from_headings);
	v_to := security_pkg.Varchar2ArrayToTable(in_to_headings);
	
	FOR r IN (
		SELECT f.value from_name, t.value to_name
		  FROM TABLE(v_from) f, TABLE(v_to) t
		 WHERE f.pos = t.pos
	) LOOP
		BEGIN
			INSERT INTO import_mapping_mru
			  	(csr_user_sid, from_name, to_name, pos)
			  VALUES (security_pkg.GetSID, r.from_name, r.to_name, import_mapping_pos_seq.NEXTVAL);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE import_mapping_mru
				   SET pos = import_mapping_pos_seq.NEXTVAL
				 WHERE csr_user_sid = security_pkg.GetSID
				   AND from_name = r.from_name
				   AND to_name = r.to_name;
		END;
	END LOOP;
END;

PROCEDURE PrepExportViewAll
AS
BEGIN
	DELETE FROM temp_task_sids;
	INSERT INTO temp_task_sids (task_sid) (
		SELECT task_sid
		  FROM task
	);
END;

PROCEDURE PrepExportViewUser
AS
BEGIN
	DELETE FROM temp_task_sids;
	INSERT INTO temp_task_sids (task_sid) (
		SELECT DISTINCT task_sid
		  FROM v$user_initiatives
	);
END;

-- private
PROCEDURE DoPrepExportViewFilter (
	in_region_sid			security_pkg.T_SID_ID,
	in_project_sids			security_pkg.T_SID_IDS,
	in_status_ids			security_pkg.T_SID_IDS,
	in_progress_ids			security_pkg.T_SID_IDS,
	in_start_dtm			task.start_dtm%TYPE,
	in_end_dtm				task.end_dtm%TYPE,
	in_starting_task_sids	security_pkg.T_SID_IDS
)
AS
	v_result_count		NUMBER;
	v_project_count		NUMBER;
	v_status_count		NUMBER;
	v_progress_count	NUMBER;
	v_root_region_sid	security_pkg.T_SID_ID;
	t_project			security.T_SID_TABLE;
	t_status			security.T_SID_TABLE;
	t_progress			security.T_SID_TABLE;
	t_starting_task_ids	security.T_SID_TABLE;
BEGIN
	
	t_project := security_pkg.SidArrayToTable(in_project_sids);	
	t_status := security_pkg.SidArrayToTable(in_status_ids);
	t_progress := security_pkg.SidArrayToTable(in_progress_ids);
	t_starting_task_ids := security_pkg.SidArrayToTable(in_starting_task_sids);

	SELECT COUNT(*)
	  INTO v_project_count
	  FROM TABLE(t_project);
	
	SELECT COUNT(*)
	  INTO v_status_count
	  FROM TABLE(t_status);
	  
	SELECT COUNT(*)
	  INTO v_progress_count
	  FROM TABLE(t_progress);
	
	SELECT NVL(in_region_sid, region_tree_root_sid)
	  INTO v_root_region_sid
	  FROM csr.region_tree
	 WHERE app_sid = security_pkg.GetAPP
	   AND is_primary = 1;
	
	
	DELETE FROM temp_task_sids;
	INSERT INTO temp_task_sids (task_sid)	
		SELECT t.task_sid
		  FROM task t, task_region tr
		   WHERE tr.task_sid(+) = t.task_sid
		  	START WITH 
				t.task_sid IN (SELECT column_value FROM TABLE(t_starting_task_ids))
			AND
		  		t.start_dtm < NVL(in_end_dtm, t.end_dtm)
	   		AND t.end_dtm > NVL(in_start_dtm, t.start_dtm)
	   		AND (
	   			t.task_sid = DECODE(in_region_sid, NULL, t.task_sid, NULL)
	   			 OR tr.region_sid IN (
				   	SELECT /*+ALL_ROWS*/ region_sid
					  FROM csr.region
					 	START WITH region_sid = v_root_region_sid
					 	CONNECT BY PRIOR region_sid = parent_sid
	   			 )
		  	) AND (
		  		t.task_sid = DECODE(v_project_count, 0, t.task_sid, NULL) 
		  		 OR project_sid IN (SELECT column_value FROM TABLE(t_project))
		  	) AND (
		  		t.task_sid = DECODE(v_status_count, 0, t.task_sid, NULL) 
		  		 OR task_status_id IN (SELECT column_value FROM TABLE(t_status))
		  	) AND (
		  		t.task_sid = DECODE(v_progress_count, 0, t.task_sid, NULL) 
		  		 OR t.task_sid IN (
		  		 	SELECT t.task_sid
		  		 	  FROM TABLE(t_progress) pr, task t, task_period tp
		  		 	 WHERE tp.task_sid = t.task_sid
		  		 	   AND tp.start_dtm = t.last_task_period_dtm
		  		 	   AND tp.task_period_status_id = pr.column_value
		  		 )
		  	)
			CONNECT BY PRIOR t.parent_task_sid = t.task_sid;
	
	-- Prevent the default behaviour of the get data 
	-- procedure from filling in the temp_task_sids table
	SELECT COUNT(*)
	  INTO v_result_count
	  FROM temp_task_sids;
	
	IF v_result_count = 0 THEN
		INSERT INTO temp_task_sids (task_sid)
		 VALUES (-1);
	END IF;
	
END;

PROCEDURE PrepExportViewFilter (
	in_region_sid		security_pkg.T_SID_ID,
	in_project_sids		security_pkg.T_SID_IDS,
	in_status_ids		security_pkg.T_SID_IDS,
	in_progress_ids		security_pkg.T_SID_IDS,
	in_start_dtm		task.start_dtm%TYPE,
	in_end_dtm			task.end_dtm%TYPE
)
AS
	v_starting_task_sids		security_pkg.T_SID_IDS;
BEGIN
	SELECT task_sid
	  BULK COLLECT INTO v_starting_task_sids
	  FROM task
	 WHERE start_dtm < NVL(in_end_dtm, end_dtm)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DoPrepExportViewFilter(in_region_sid, in_project_sids, in_status_ids, in_progress_ids, in_start_dtm, in_end_dtm, v_starting_task_sids);
END;

PROCEDURE PrepExportViewFilterUser (
	in_region_sid		security_pkg.T_SID_ID,
	in_project_sids		security_pkg.T_SID_IDS,
	in_status_ids		security_pkg.T_SID_IDS,
	in_progress_ids		security_pkg.T_SID_IDS,
	in_start_dtm		task.start_dtm%TYPE,
	in_end_dtm			task.end_dtm%TYPE
)
AS
	v_starting_task_sids		security_pkg.T_SID_IDS;
BEGIN
	SELECT task_sid
	  BULK COLLECT INTO v_starting_task_sids
	  FROM v$user_initiatives;

	DoPrepExportViewFilter(in_region_sid, in_project_sids, in_status_ids, in_progress_ids, in_start_dtm, in_end_dtm, v_starting_task_sids);
END;

PROCEDURE GetDataForExport (
	out_data				OUT	security_pkg.T_OUTPUT_CUR,
	out_tasks				OUT security_pkg.T_OUTPUT_CUR,
	out_regions				OUT	security_pkg.T_OUTPUT_CUR,
	out_csr_task_roles		OUT security_pkg.T_OUTPUT_CUR,
	out_status_history		OUT security_pkg.T_OUTPUT_CUR,
	out_project_team		OUT security_pkg.T_OUTPUT_CUR,
	out_project_sponsor		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_count		NUMBER(10);
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_task_sids;
	
	IF v_count = 0 THEN
		INSERT INTO temp_task_sids (task_sid) (
			SELECT task_sid
			  FROM task
		);
	END IF;
	
	OPEN out_data FOR
		SELECT
			init.lvl, MAX(init.lvl) OVER () max_lvl,
			init.task_sid, init.project_sid, init.initiative_name, init.initiative_reference,
			init.initiative_start_dtm, init.initiative_end_dtm, init.period_duration, init.owner_name,
			init.created_dtm, init.prop_sid, init.prop_desc, init.prop_ref,
			init.task_status_id, init.task_status_name,
		    static.ind_template_id static_metric_id,
		    static.name static_metric_name,
		    static.description static_metric_desc,
		    static.val static_metric_val,
		    static.entry_val static_metric_entry_val,
		    static.measure_sid static_metric_measure,
		    static.entry_measure_conversion_id static_metric_conversion,
		    static.is_calculated_value,
		    static.ind_sid
	  	 FROM (
			SELECT ROWNUM rn, LEVEL lvl,
				t.task_sid, t.project_sid, t.name initiative_name, t.internal_ref initiative_reference,
				t.start_dtm initiative_start_dtm, t.end_dtm initiative_end_dtm, t.period_duration,
	        	t.owner_sid, t.created_dtm, usr.full_name owner_name, t.task_status_id, ts.label task_status_name,
	        	prop.region_sid prop_sid, prop.description prop_desc, prop.lookup_key prop_ref
		      FROM task t, csr.csr_user usr, task_region tr, csr.v$region prop, task_status ts
		     WHERE usr.csr_user_sid = t.owner_sid
		       AND tr.task_sid(+) = t.task_sid
		       AND prop.region_sid(+) = tr.region_sid
		       AND ts.task_status_id = t.task_status_id
		       	START WITH t.parent_task_sid IS NULL
            	CONNECT BY PRIOR t.task_sid = t.parent_task_sid
            		ORDER SIBLINGS BY t.task_sid, prop.region_sid
			) init, (
			    SELECT t.task_sid, it.ind_template_id, it.name, it.description, inst.ind_sid, inst.val,
			    	DECODE(NVL(it.calculation, '<isnull/>'), '<isnull/>', it.is_npv, 1) is_calculated_value,
			    	it.measure_sid, inst.entry_val, inst.entry_measure_conversion_id
		          FROM task t, ind_template it, project_ind_template pit, task_ind_template_instance inst
		         WHERE it.ind_template_id = pit.ind_template_id
		           AND pit.project_sid = t.project_sid
		           AND pit.update_per_period = 0
				   AND inst.from_ind_template_id = it.ind_template_id
				   AND t.task_sid = inst.task_sid
			) static, (
				SELECT DISTINCT t.task_sid
				  FROM task t, temp_task_sids f
				 	START WITH t.task_sid = f.task_sid
				 	CONNECT BY PRIOR t.parent_task_sid = t.task_sid
			) filter
			WHERE init.task_sid = static.task_sid
			  AND init.task_sid = filter.task_sid
			    ORDER BY init.rn
			;
	
	OPEN out_tasks FOR
		SELECT t.parent_task_sid, tparent.name parent_task_name, 
	        p.name project_name,
	      	t.project_sid, t.name, t.short_name, t.start_dtm, t.end_dtm,
	      	t.internal_ref, t.period_duration, t.budget, t.task_status_id,
	      	t.fields_xml, p.task_fields_xml, p.task_period_fields_xml,
	      	t.task_sid, t.input_ind_sid, t.output_ind_sid, t.target_ind_sid, t.weighting, t.action_type,
	  		task_pkg.ConcatRoleIds(t.task_sid) role_ids, 
	  		task_pkg.ConcatTagIds(t.task_sid) tag_ids,  
	  		task_pkg.FormatPeriod(t.start_dtm, t.end_dtm) period, 
			tp.task_period_status_id, 
			tp.start_dtm task_period_start_dtm, tp.end_dtm task_period_end_dtm
		  FROM temp_task_sids tmp, task t, task tparent, project p, task_period tp
		 WHERE t.task_sid = tmp.task_sid
		   AND tp.task_sid(+) = t.task_sid
		   AND tp.start_dtm(+) = t.last_task_period_dtm 
	       AND t.parent_task_sid = tparent.task_sid(+)
	       AND t.project_sid = p.project_sid
		;

	OPEN out_regions FOR
		SELECT tr.task_sid, r.region_sid, r.parent_sid, r.name, r.description, r.info_xml, r.pos, r.active
		  FROM csr.v$region r, task_region tr, temp_task_sids tmp
		 WHERE r.region_sid = tr.region_sid
		   AND tr.task_sid = tmp.task_sid
		;
		
	OPEN out_csr_task_roles FOR
		SELECT trm.task_sid, trm.role_sid, trm.user_sid, r.name, u.user_name, u.full_name
		  FROM temp_task_sids tmp, csr_task_role_member trm, csr.role r, csr.csr_user u
		 WHERE trm.task_sid = tmp.task_sid
		   AND r.role_sid = trm.role_sid
		   AND u.csr_user_sid = trm.user_sid
		   	ORDER BY role_sid
		;
		
	OPEN out_status_history FOR
		SELECT x.task_sid, x.dtm set_dtm, x.comment_text, x.task_status_id, x.task_status_label, x.user_sid, u.full_name
		  FROM csr.csr_user u, (
			SELECT h.task_sid, h.set_dtm dtm, h.set_by_user_sid user_sid, h.comment_text, h.task_status_id, ts.label task_status_label
			  FROM temp_task_sids tmp, task_status_history h, task_status ts
			 WHERE h.task_sid = tmp.task_sid
			   AND ts.task_status_id = h.task_status_id
			UNION ALL
			SELECT tc.task_sid, tc.posted_dtm dtm, tc.user_sid, tc.comment_text, NULL task_status_id, NULL task_status_label
			  FROM temp_task_sids tmp, task_comment tc
			 WHERE tc.task_sid = tmp.task_sid
		 ) x
		 WHERE u.csr_user_sid = x.user_sid
		 	ORDER BY x.dtm DESC
		;

	OPEN out_project_team FOR
		SELECT pt.task_sid, pt.name, pt.email
		  FROM initiative_project_team pt, temp_task_sids tmp
		 WHERE pt.task_sid = tmp.task_sid;
		 
	OPEN out_project_sponsor FOR
		SELECT sp.task_sid, sp.name, sp.email
		  FROM initiative_sponsor sp, temp_task_sids tmp
		 WHERE sp.task_sid = tmp.task_sid;
END;

PROCEDURE GetTemplateList(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT it.name, it.import_template_id, it.heading_row_idx, it.worksheet_name, it.project_sid, p.name project_name, it.is_default
		  FROM import_template it, project p
		 WHERE it.app_sid = security_pkg.GetAPP
		   AND p.project_sid(+) = it.project_sid
		   AND (it.project_sid IS NULL 
		   	 OR security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT, it.project_sid, 1) = 1)
		 	ORDER BY name;
END;

PROCEDURE GetDefaultTemplate(
	out_tpl					OUT	security_pkg.T_OUTPUT_CUR,
	out_map					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_template_id			import_template.import_template_id%TYPE;
BEGIN
	BEGIN
		SELECT import_template_id
		  INTO v_template_id
		  FROM import_template
		 WHERE is_default = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_template_id := NULL;
	END;
	
	GetTemplate(v_template_id, out_tpl, out_map);
	
END;

PROCEDURE GetTemplate(
	in_template_id			IN	import_template.import_template_id%TYPE,
	out_tpl					OUT	security_pkg.T_OUTPUT_CUR,
	out_map					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_tpl FOR
		SELECT it.name, it.import_template_id, it.heading_row_idx, it.worksheet_name, it.project_sid, p.name project_name, it.is_default, it.workbook
		  FROM import_template it, project p
		 WHERE it.app_sid = security_pkg.GetAPP
		   AND import_template_id = in_template_id
		   AND p.project_sid(+) = it.project_sid;
		 
	OPEN out_map FOR
		SELECT import_template_id, to_name, from_idx, from_name
		  FROM import_template_mapping
		 WHERE app_sid = security_pkg.GetAPP
		   AND import_template_id = in_template_id;
END;

PROCEDURE AddTemplate(
	in_name					IN	import_template.name%TYPE,
	in_heading_row_idx		IN	import_template.heading_row_idx%TYPE,
	in_worksheet_name		IN	import_template.worksheet_name%TYPE,
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_is_default			IN	import_template.is_default%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_from_idxs			IN	security_pkg.T_SID_IDS,
	in_from_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_to_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	out_template_id			OUT	import_template.import_template_id%TYPE
)
AS
	t_from_idx				security.T_ORDERED_SID_TABLE;
	t_from					security.T_VARCHAR2_TABLE;
	t_to					security.T_VARCHAR2_TABLE;
BEGIN
	
	IF NOT csr.csr_data_pkg.CheckCapability('Manage import templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'This user does not have the "Manage import templates" capability.');
	END IF;
	
	SELECT import_template_id_seq.NEXTVAL
	  INTO out_template_id
	  FROM DUAL;
	
	IF in_is_default = 1 THEN
		UPDATE import_template
		  SET is_default = 0
		WHERE app_sid = security_pkg.GetAPP;
	END IF;
	
	-- Insert template entry
	IF in_cache_key IS NULL THEN
		INSERT INTO import_template
			(import_template_id, name, heading_row_idx, worksheet_name, project_sid, is_default) 
		VALUES (out_template_id, in_name, in_heading_row_idx, in_worksheet_name, in_project_sid, in_is_default);
	ELSE
		INSERT INTO import_template
		(import_template_id, name, heading_row_idx, worksheet_name, project_sid, is_default, workbook) (
			SELECT out_template_id, in_name, in_heading_row_idx, in_worksheet_name, in_project_sid, in_is_default, object
			  FROM aspen2.filecache 
			 WHERE cache_key = in_cache_key
		);
	END IF;
		
	-- Insert column mappings
	t_from_idx := security_pkg.SidArrayToOrderedTable(in_from_idxs);
	t_from := security_pkg.Varchar2ArrayToTable(in_from_names);
	t_to := security_pkg.Varchar2ArrayToTable(in_to_names);
	
	INSERT INTO import_template_mapping
		(import_template_id, from_idx, from_name, to_name) (
			SELECT out_template_id, i.sid_id, f.value from_name, t.value to_name
			  FROM TABLE(t_from_idx) i, TABLE(t_from) f, TABLE(t_to) t
			 WHERE i.pos = f.pos
			   AND f.pos = t.pos
		);
	
END;

PROCEDURE AmendTemplate(
	in_template_id			IN	import_template.import_template_id%TYPE,
	in_name					IN	import_template.name%TYPE,
	in_heading_row_idx		IN	import_template.heading_row_idx%TYPE,
	in_worksheet_name		IN	import_template.worksheet_name%TYPE,
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_is_default			IN	import_template.is_default%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_from_idxs			IN	security_pkg.T_SID_IDS,
	in_from_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_to_names				IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	t_from_idx				security.T_ORDERED_SID_TABLE;
	t_from					security.T_VARCHAR2_TABLE;
	t_to					security.T_VARCHAR2_TABLE;
BEGIN
	
	IF NOT csr.csr_data_pkg.CheckCapability('Manage import templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'This user does not have the "Manage import templates" capability.');
	END IF;
	
	IF in_is_default = 1 THEN
		UPDATE import_template
		  SET is_default = 0
		WHERE app_sid = security_pkg.GetAPP;
	END IF;
	
	-- Insert template entry
	IF in_cache_key IS NULL THEN
		UPDATE import_template
		   SET name = in_name, 
		   	   import_template_id = in_template_id,
			   heading_row_idx = in_heading_row_idx, 
			   worksheet_name = in_worksheet_name, 
			   project_sid = in_project_sid,
			   is_default = in_is_default
		 WHERE import_template_id = in_template_id;
	ELSE
		UPDATE import_template
		   SET name = in_name, 
		       import_template_id = in_template_id,
			   heading_row_idx = in_heading_row_idx, 
			   worksheet_name = in_worksheet_name, 
			   project_sid = in_project_sid,
			   is_default = in_is_default,
			   workbook = (
			   		SELECT object
					  FROM aspen2.filecache 
					 WHERE cache_key = in_cache_key
				)
		 WHERE import_template_id = in_template_id;
	END IF;
		
	-- Remove old column mappings
	DELETE FROM import_template_mapping
	 WHERE import_template_id = in_template_id;
	
	-- Extract column mapping dta ino usefl table format
	t_from_idx := security_pkg.SidArrayToOrderedTable(in_from_idxs);
	t_from := security_pkg.Varchar2ArrayToTable(in_from_names);
	t_to := security_pkg.Varchar2ArrayToTable(in_to_names);

	-- Insert new mappings
	INSERT INTO import_template_mapping
		(import_template_id, from_idx, from_name, to_name) (
			SELECT in_template_id, i.sid_id, f.value from_name, t.value to_name
			  FROM TABLE(t_from_idx) i, TABLE(t_from) f, TABLE(t_to) t
			 WHERE i.pos = f.pos
			   AND f.pos = t.pos
		);
	
END;

PROCEDURE AmendTemplateData (
	in_template_id			IN	import_template.import_template_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE
)
AS
BEGIN
	
	IF NOT csr.csr_data_pkg.CheckCapability('Manage import templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'This user does not have the "Manage import templates" capability.');
	END IF;
	
	UPDATE import_template
	   SET workbook = (
	    	SELECT object
			  FROM aspen2.filecache 
			 WHERE cache_key = in_cache_key
		 )
	 WHERE import_template_id = in_template_id;
END;

PROCEDURE SetDefaultTemplate (
	in_template_id			IN	import_template.import_template_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('Manage import templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'This user does not have the "Manage import templates" capability.');
	END IF;
	
	UPDATE import_template
	   SET is_default = 0
	 WHERE is_default = 1
	   AND app_sid = security_pkg.GetAPP;
	 
	UPDATE import_template
	   SET is_default = 1
	 WHERE import_template_id = in_template_id;
	
END;

PROCEDURE DeleteTemplate (
	in_template_id			IN	import_template.import_template_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('Manage import templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'This user does not have the "Manage import templates" capability.');
	END IF;
	
	DELETE FROM import_template_mapping
	 WHERE import_template_id = in_template_id
	   AND app_sid = security_pkg.GetAPP;
	   
	DELETE FROM import_template
	 WHERE import_template_id = in_template_id
	   AND app_sid = security_pkg.GetAPP;
	
END;

PROCEDURE GetActiveUsers(
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
IS
	v_users_sid	security_pkg.T_SID_ID;
BEGIN
	-- find /users
	v_users_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetAPP, 'Users');

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_users_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading users');
	END IF;
	
	OPEN out_cur FOR
		SELECT cu.csr_user_sid, cu.user_name, cu.full_name, cu.email
		  FROM csr.csr_user cu, security.user_table ut
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND ut.sid_id = cu.csr_user_sid 
		   AND cu.hidden = 0
		   AND ut.account_enabled = 1;
END;

END importer_pkg;
/
