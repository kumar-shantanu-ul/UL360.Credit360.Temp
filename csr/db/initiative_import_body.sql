CREATE OR REPLACE PACKAGE BODY CSR.initiative_import_pkg
IS

PROCEDURE GetMappingMRU(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT from_name, to_name
		  FROM initiative_import_map_mru
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
			INSERT INTO initiative_import_map_mru
			  	(csr_user_sid, from_name, to_name, pos)
			  VALUES (security_pkg.GetSID, r.from_name, r.to_name, init_import_mapping_pos_seq.NEXTVAL);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE initiative_import_map_mru
				   SET pos = init_import_mapping_pos_seq.NEXTVAL
				 WHERE csr_user_sid = security_pkg.GetSID
				   AND from_name = r.from_name
				   AND to_name = r.to_name;
		END;
	END LOOP;
END;


PROCEDURE GetTemplateList(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT it.name, it.import_template_id, it.heading_row_idx, it.worksheet_name, it.project_sid, p.name project_name, it.is_default
		  FROM initiative_import_template it, initiative_project p
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
	v_template_id			initiative_import_template.import_template_id%TYPE;
BEGIN
	BEGIN
		SELECT import_template_id
		  INTO v_template_id
		  FROM initiative_import_template
		 WHERE is_default = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_template_id := NULL;
	END;

	GetTemplate(v_template_id, out_tpl, out_map);

END;

PROCEDURE GetTemplate(
	in_template_id			IN	initiative_import_template.import_template_id%TYPE,
	out_tpl					OUT	security_pkg.T_OUTPUT_CUR,
	out_map					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_tpl FOR
		SELECT it.name, it.import_template_id, it.heading_row_idx, it.worksheet_name, it.project_sid, p.name project_name, it.is_default, it.workbook
		  FROM initiative_import_template it, initiative_project p
		 WHERE it.app_sid = security_pkg.GetAPP
		   AND import_template_id = in_template_id
		   AND p.project_sid(+) = it.project_sid;

	OPEN out_map FOR
		SELECT import_template_id, to_name, from_idx, from_name
		  FROM initiative_import_template_map
		 WHERE app_sid = security_pkg.GetAPP
		   AND import_template_id = in_template_id;
END;

PROCEDURE AddTemplate(
	in_name					IN	initiative_import_template.name%TYPE,
	in_heading_row_idx		IN	initiative_import_template.heading_row_idx%TYPE,
	in_worksheet_name		IN	initiative_import_template.worksheet_name%TYPE,
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_is_default			IN	initiative_import_template.is_default%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_from_idxs			IN	security_pkg.T_SID_IDS,
	in_from_names			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_to_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	out_template_id			OUT	initiative_import_template.import_template_id%TYPE
)
AS
	t_from_idx				security.T_ORDERED_SID_TABLE;
	t_from					security.T_VARCHAR2_TABLE;
	t_to					security.T_VARCHAR2_TABLE;
BEGIN

	IF NOT csr.csr_data_pkg.CheckCapability('Manage import templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'This user does not have the "Manage import templates" capability.');
	END IF;

	SELECT init_import_template_id_seq.NEXTVAL
	  INTO out_template_id
	  FROM DUAL;

	IF in_is_default = 1 THEN
		UPDATE initiative_import_template
		  SET is_default = 0
		WHERE app_sid = security_pkg.GetAPP;
	END IF;

	-- Insert template entry
	IF in_cache_key IS NULL THEN
		INSERT INTO initiative_import_template
			(import_template_id, name, heading_row_idx, worksheet_name, project_sid, is_default)
		VALUES (out_template_id, in_name, in_heading_row_idx, in_worksheet_name, in_project_sid, in_is_default);
	ELSE
		INSERT INTO initiative_import_template
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

	INSERT INTO initiative_import_template_map
		(import_template_id, from_idx, from_name, to_name) (
			SELECT out_template_id, i.sid_id, f.value from_name, t.value to_name
			  FROM TABLE(t_from_idx) i, TABLE(t_from) f, TABLE(t_to) t
			 WHERE i.pos = f.pos
			   AND f.pos = t.pos
		);

END;

PROCEDURE AmendTemplate(
	in_template_id			IN	initiative_import_template.import_template_id%TYPE,
	in_name					IN	initiative_import_template.name%TYPE,
	in_heading_row_idx		IN	initiative_import_template.heading_row_idx%TYPE,
	in_worksheet_name		IN	initiative_import_template.worksheet_name%TYPE,
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_is_default			IN	initiative_import_template.is_default%TYPE,
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
		UPDATE initiative_import_template
		  SET is_default = 0
		WHERE app_sid = security_pkg.GetAPP;
	END IF;

	-- Insert template entry
	IF in_cache_key IS NULL THEN
		UPDATE initiative_import_template
		   SET name = in_name,
		   	   import_template_id = in_template_id,
			   heading_row_idx = in_heading_row_idx,
			   worksheet_name = in_worksheet_name,
			   project_sid = in_project_sid,
			   is_default = in_is_default
		 WHERE import_template_id = in_template_id;
	ELSE
		UPDATE initiative_import_template
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
	DELETE FROM initiative_import_template_map
	 WHERE import_template_id = in_template_id;

	-- Extract column mapping dta ino usefl table format
	t_from_idx := security_pkg.SidArrayToOrderedTable(in_from_idxs);
	t_from := security_pkg.Varchar2ArrayToTable(in_from_names);
	t_to := security_pkg.Varchar2ArrayToTable(in_to_names);

	-- Insert new mappings
	INSERT INTO initiative_import_template_map
		(import_template_id, from_idx, from_name, to_name) (
			SELECT in_template_id, i.sid_id, f.value from_name, t.value to_name
			  FROM TABLE(t_from_idx) i, TABLE(t_from) f, TABLE(t_to) t
			 WHERE i.pos = f.pos
			   AND f.pos = t.pos
		);

END;

PROCEDURE AmendTemplateData (
	in_template_id			IN	initiative_import_template.import_template_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE
)
AS
BEGIN

	IF NOT csr.csr_data_pkg.CheckCapability('Manage import templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'This user does not have the "Manage import templates" capability.');
	END IF;

	UPDATE initiative_import_template
	   SET workbook = (
	    	SELECT object
			  FROM aspen2.filecache
			 WHERE cache_key = in_cache_key
		 )
	 WHERE import_template_id = in_template_id;
END;

PROCEDURE SetDefaultTemplate (
	in_template_id			IN	initiative_import_template.import_template_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('Manage import templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'This user does not have the "Manage import templates" capability.');
	END IF;

	UPDATE initiative_import_template
	   SET is_default = 0
	 WHERE is_default = 1
	   AND app_sid = security_pkg.GetAPP;

	UPDATE initiative_import_template
	   SET is_default = 1
	 WHERE import_template_id = in_template_id;

END;

PROCEDURE DeleteTemplate (
	in_template_id			IN	initiative_import_template.import_template_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability('Manage import templates') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'This user does not have the "Manage import templates" capability.');
	END IF;

	DELETE FROM initiative_import_template_map
	 WHERE import_template_id = in_template_id
	   AND app_sid = security_pkg.GetAPP;

	DELETE FROM initiative_import_template
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
		SELECT cu.csr_user_sid, cu.csr_user_sid user_sid, cu.user_name, cu.full_name, cu.email
		  FROM csr.csr_user cu, security.user_table ut
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ut.sid_id = cu.csr_user_sid
		   AND cu.hidden = 0
		   AND ut.account_enabled = 1;
END;

PROCEDURE RegionSidsFromRefs (
	in_dummy		IN	NUMBER,
	in_refs			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_table			security.T_VARCHAR2_TABLE;
BEGIN
	v_table := security_pkg.Varchar2ArrayToTable(in_refs);

	OPEN out_cur FOR
		SELECT r.region_sid
		  FROM csr.region r, TABLE(v_table) t
		 WHERE (TRIM(r.lookup_key) = t.value OR TRIM(region_ref) = t.value) -- t.value already trimmed
		    AND r.active = 1
		    AND r.region_type != csr_data_pkg.REGION_TYPE_AGGR_REGION;
END;

PROCEDURE RegionSidsFromNames (
	in_dummy		IN	NUMBER,
	in_names		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_table			security.T_VARCHAR2_TABLE;
	v_region_root	security_pkg.T_SID_ID;
BEGIN
	v_table := security_pkg.Varchar2ArrayToTable(in_names);

	SELECT region_tree_root_sid
	  INTO v_region_root
	   FROM csr.region_tree
	 WHERE is_primary = 1;

	OPEN out_cur FOR
		SELECT r.region_sid
		  FROM (
		  	SELECT region_sid, description
		  	  FROM csr.v$region
		  	 WHERE active = 1
		  	   AND region_type != csr_data_pkg.REGION_TYPE_AGGR_REGION
		  		START WITH region_sid = v_region_root
		 		CONNECT BY PRIOR region_sid = parent_sid
		  ) r, TABLE(v_table) t
		 WHERE LOWER(TRIM(r.description)) = LOWER(t.value); -- t.value already trimmed
END;

END initiative_import_pkg;
/