CREATE OR REPLACE PACKAGE BODY csr.indicator_api_pkg AS

FUNCTION GetTrashedIndSids
RETURN security.T_SID_TABLE
AS
	v_trashed_ind_sids		security.T_SID_TABLE;
BEGIN
	SELECT ind_sid
	  BULK COLLECT INTO v_trashed_ind_sids
	  FROM (
			SELECT ind_sid
			  FROM ind 
			START WITH parent_sid IN (SELECT trash_sid FROM customer WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'))
			CONNECT BY PRIOR ind_sid = parent_sid
		);
	RETURN v_trashed_ind_sids;
END;

PROCEDURE FindIndicatorsByPath(
	in_path					IN	VARCHAR2,
	in_separator			IN	VARCHAR2 DEFAULT '/',
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_row_count			OUT SYS_REFCURSOR,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	TYPE T_PATH IS TABLE OF VARCHAR2(1024) INDEX BY BINARY_INTEGER;
	v_path_parts 			T_PATH;
	v_parents				security.T_SID_TABLE;
	v_new_parents			security.T_SID_TABLE;
	v_indicators_folder		security_pkg.T_SID_ID;
	v_trashed_ind_sids		security.T_SID_TABLE;
BEGIN

	v_indicators_folder := securableobject_pkg.GetSIDFromPath(security_pkg.getAct, security_pkg.getApp, 'indicators');
	v_trashed_ind_sids := GetTrashedIndSids();

	SELECT LOWER(TRIM(item)) 
	  BULK COLLECT INTO v_path_parts 
	  FROM table(utils_pkg.SplitString(in_path, in_separator));

	-- Populate possible parents with the first part of the path
	BEGIN
		SELECT ind_sid
		  BULK COLLECT INTO v_parents
		  FROM v$ind
		 WHERE LOWER(description) = v_path_parts(1)
		   AND app_sid = security_pkg.getApp
		   AND active = 1
		   AND ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
		   AND ind_sid IN (
				SELECT ind_sid
				  FROM ind
				 START WITH ind_sid = v_indicators_folder
			   CONNECT BY PRIOR ind_sid = parent_sid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_cur FOR
				SELECT ind_sid, description
				  FROM v$ind
				 WHERE 1 = 0;
			RETURN;
	END;

	-- Now check each part of the rest of the path
	FOR i IN 2 .. v_path_parts.LAST
	LOOP
		-- Select everything that matches into a set of possible parents
		SELECT ind_sid 
		  BULK COLLECT INTO v_new_parents
		  FROM v$ind
		 WHERE LOWER(description) = TRIM(v_path_parts(i))
		   AND active = 1
		   AND parent_sid IN (SELECT COLUMN_VALUE FROM TABLE(v_parents));

		-- We have to select into a different collection, so copy back on top
		v_parents := v_new_parents;
		IF v_parents.COUNT = 0 THEN
			EXIT;
		END IF;
	END LOOP;

	-- Return the stuff we've found
	OPEN out_cur FOR
	SELECT ind_sid
		FROM(
		SELECT ind_sid, rownum rn
		  FROM v$ind
		 WHERE ind_sid IN (SELECT column_value FROM TABLE(v_parents))
		   AND measure_sid IS NOT NULL
		   AND ind_type = csr_data_pkg.IND_TYPE_NORMAL
		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.getAct, ind_sid, security_pkg.PERMISSION_READ) = 1
		   )
		 WHERE rn > in_skip
		   AND rn < in_skip + in_take + 1;
		   
	OPEN out_row_count FOR
		SELECT COUNT(*) AS total_rows
		  FROM TABLE(v_parents);
END;

PROCEDURE GetIndsBySids(
	in_ind_sids				IN	security.T_SID_TABLE,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_ind_cur FOR
		SELECT i.ind_sid AS ind_id, i.parent_sid AS parent_id, i.ind_type, i.measure_sid AS measure_id, i.lookup_key,
			i.tolerance_type, i.pct_upper_tolerance, i.pct_lower_tolerance,
			--i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			i.multiplier, i.scale, i.format_mask, i.last_modified_dtm, i.active, 
			i.target_direction, i.pos, i.info_xml, i.start_month, i.divisibility, i.null_means_null, i.aggregate, i.period_set_id, i.period_interval_id,
			i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.owner_sid AS owner_id,
			i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid AS map_to_ind_id, i.gas_measure_sid AS gas_measure_id, 
			i.gas_type_id, i.calc_description, i.normalize, i.do_temporal_aggregation, i.prop_down_region_tree_sid AS prop_down_region_tree_id, 
			i.is_system_managed, i.calc_output_round_dp,
			i.name
		  FROM ind i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid IN (SELECT column_value FROM TABLE(in_ind_sids))
		 ORDER BY i.ind_sid;

	OPEN out_description_cur FOR
		SELECT i.ind_sid AS ind_id, d.lang AS "language", d.description
		  FROM ind i
		  JOIN ind_description d ON i.ind_sid = d.ind_sid AND  i.app_sid = d.app_sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid IN (SELECT column_value FROM TABLE(in_ind_sids))
		 ORDER BY i.ind_sid;
		
	OPEN out_measure_cur FOR
		SELECT i.ind_sid AS ind_id, m.measure_sid AS measure_id, m.format_mask, m.scale, m.name, m.description, m.custom_field,
			   m.pct_ownership_applies, m.std_measure_conversion_id, m.divisibility,
			   NVL(m.factor, smc.a) factor, NVL(m.m, sm.m) m, NVL(m.kg, sm.kg) kg, 
			   NVL(m.s, sm.s) s, NVL(m.a, sm.a) a, NVL(m.k, sm.k) k, NVL(m.mol, sm.mol) mol,
			   NVL(m.cd, sm.cd) cd,
			   CASE WHEN m.description IS NULL THEN '('||m.name||')' ELSE m.description END label,
			   m.option_set_id, smc.description std_measure_description,
			   m.lookup_key
		  FROM ind i
		  JOIN csr.measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
		  LEFT JOIN std_measure_conversion smc ON m.std_measure_conversion_id = smc.std_measure_conversion_id
		  LEFT JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.ind_sid IN (SELECT column_value FROM TABLE(in_ind_sids))
		 ORDER BY i.ind_sid;
END;

PROCEDURE GetIndicators(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_include_all				IN	NUMBER,
	in_include_null_lookup_keys	IN	NUMBER,
	in_lookup_keys				IN	security.T_VARCHAR2_TABLE,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_ind_cur					OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR,
	out_measure_cur				OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
)
AS
	v_app_sid					security_pkg.T_SID_ID;
	v_lookup_keys				security.T_VARCHAR2_TABLE;
	v_ind_sids					security.T_SID_TABLE;
	v_trashed_ind_sids			security.T_SID_TABLE;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_lookup_keys := in_lookup_keys;
	v_trashed_ind_sids := GetTrashedIndSids();

	SELECT ind_sid
	  BULK COLLECT INTO v_ind_sids
	  FROM (
		SELECT ind_sid, rownum rn
		  FROM (
				SELECT i.ind_sid
				  FROM ind i
				 WHERE i.app_sid = v_app_sid
				   AND (in_include_all = 1 OR (LOWER(i.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (i.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
				   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
				   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, i.ind_sid, security_Pkg.PERMISSION_READ) = 1
				 ORDER BY i.ind_sid
				)
			)
		WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;

	OPEN out_total_rows_cur FOR
		SELECT COUNT(i.ind_sid) total_rows
		  FROM ind i
		 WHERE i.app_sid = v_app_sid
		   AND (in_include_all = 1 OR (LOWER(i.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (i.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
		   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, i.ind_sid, security_Pkg.PERMISSION_READ) = 1;

		GetIndsBySids(
		in_ind_sids				=>	v_ind_sids,
		out_ind_cur				=>	out_ind_cur,
		out_description_cur		=>	out_description_cur,
		out_measure_cur			=>	out_measure_cur
	);
END;

PROCEDURE GetAllIndicators(
	out_ind_cur					OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR,
	out_measure_cur				OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
)
AS
	v_ind_count 			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_ind_count
	  FROM csr.ind;

	GetIndicators(0, v_ind_count, out_ind_cur, out_description_cur, out_measure_cur, out_total_rows_cur);
END;

PROCEDURE GetIndicators(
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetIndicators(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_include_all				=> 1,
		in_include_null_lookup_keys	=> 0,
		in_lookup_keys				=> security.T_VARCHAR2_TABLE(),
		in_skip						=> in_skip,
		in_take						=> in_take,
		out_ind_cur					=> out_ind_cur,
		out_description_cur			=> out_description_cur,
		out_measure_cur				=> out_measure_cur,
		out_total_rows_cur			=> out_total_rows_cur
	);
END;

PROCEDURE GetIndicatorsByLookupKey(
	in_lookup_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_lookup_keys				security.T_VARCHAR2_TABLE;
	v_lookup_keys_count			NUMBER;
	v_lookup_contains_null		NUMBER(1) := 0;
BEGIN	
	v_lookup_keys := security_pkg.Varchar2ArrayToTable(in_lookup_keys);
	SELECT COUNT(*)
	  INTO v_lookup_keys_count
	  FROM TABLE(v_lookup_keys);
	
	IF in_lookup_keys.COUNT = 1 AND v_lookup_keys_count = 0 THEN
		-- Single null key in the params doesn't turn into a single null table entry for some reason.
		v_lookup_contains_null := 1;
	END IF;
	
	FOR r IN (SELECT value FROM TABLE(v_lookup_keys))
	LOOP
		IF r.value IS NULL OR LENGTH(r.value) = 0 THEN
			v_lookup_contains_null := 1;
			EXIT;
		END IF;
	END LOOP;
	
	GetIndicators(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_include_all				=> 0,
		in_include_null_lookup_keys	=> v_lookup_contains_null,
		in_lookup_keys				=> v_lookup_keys,
		in_skip						=> in_skip,
		in_take						=> in_take,
		out_ind_cur					=> out_ind_cur,
		out_description_cur			=> out_description_cur,
		out_measure_cur				=> out_measure_cur,
		out_total_rows_cur			=> out_total_rows_cur
	);
END;

PROCEDURE GetIndsByDescription(
	in_description			IN	ind_description.description%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_ind_sids				security.T_SID_TABLE;
	v_trashed_ind_sids		security.T_SID_TABLE;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;
	v_trashed_ind_sids := GetTrashedIndSids();

	SELECT ind_sid
	  BULK COLLECT INTO v_ind_sids
	  FROM (
		SELECT ind_sid, rownum rn
		  FROM (
			SELECT DISTINCT i.ind_sid
			  FROM ind i
			  JOIN ind_description d ON i.ind_sid = d.ind_sid AND  i.app_sid = d.app_sid
			 WHERE i.app_sid = v_app_sid
			   AND d.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
			   AND LOWER(d.description) = LOWER(in_description)
			   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
			   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, i.ind_sid, security_Pkg.PERMISSION_READ) = 1
			 ORDER BY i.ind_sid
				)
			)
		 WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;

	OPEN out_total_rows_cur FOR
		SELECT COUNT(DISTINCT(i.ind_sid)) total_rows
		  FROM ind i
		  JOIN ind_description d ON i.ind_sid = d.ind_sid AND  i.app_sid = d.app_sid
		 WHERE i.app_sid = v_app_sid
		   AND LOWER(d.description) = LOWER(in_description)
		   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
		   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, i.ind_sid, security_Pkg.PERMISSION_READ) = 1;

	GetIndsBySids(
		in_ind_sids			=>	v_ind_sids,
		out_ind_cur			=>	out_ind_cur,
		out_description_cur	=>	out_description_cur,
		out_measure_cur		=>	out_measure_cur
	);
END;

PROCEDURE GetIndsByMeasureSid(
	in_measure_sid			IN	ind.measure_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_ind_sids				security.T_SID_TABLE;
	v_trashed_ind_sids		security.T_SID_TABLE;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;
	v_trashed_ind_sids := GetTrashedIndSids();

	SELECT ind_sid
	  BULK COLLECT INTO v_ind_sids
	  FROM (
		SELECT ind_sid, rownum rn
		  FROM (
			SELECT DISTINCT i.ind_sid
			  FROM ind i
			 WHERE i.app_sid = v_app_sid
			   AND i.measure_sid = in_measure_sid
			   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
			   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, i.ind_sid, security_Pkg.PERMISSION_READ) = 1
			 ORDER BY i.ind_sid
				)
			)
		 WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;

	OPEN out_total_rows_cur FOR
		SELECT COUNT(DISTINCT(i.ind_sid)) total_rows
		  FROM ind i
		 WHERE i.app_sid = v_app_sid
		   AND i.measure_sid = in_measure_sid
		   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
		   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, i.ind_sid, security_Pkg.PERMISSION_READ) = 1;

	GetIndsBySids(
		in_ind_sids			=>	v_ind_sids,
		out_ind_cur			=>	out_ind_cur,
		out_description_cur	=>	out_description_cur,
		out_measure_cur		=>	out_measure_cur
	);
END;

PROCEDURE GetIndBySid(
	in_sid					IN	ind.ind_sid%TYPE,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_ind_sids				security.T_SID_TABLE;
	v_trashed_ind_sids		security.T_SID_TABLE;
	v_is_in_trash			NUMBER;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;
	
	IF security_pkg.SQL_IsAccessAllowedSID(v_act_id, in_sid, security_pkg.PERMISSION_READ) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on indicator '||in_sid);
	END IF;

	v_trashed_ind_sids := GetTrashedIndSids();

	SELECT COUNT(*)
	  INTO v_is_in_trash
	  FROM ind i
	  JOIN TABLE(v_trashed_ind_sids) t ON t.column_value = i.ind_sid
	 WHERE i.ind_sid = in_sid
	   AND i.app_sid = v_app_sid;

	IF v_is_in_trash > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_IN_TRASH, 'The requested object is in the trash sid ' || in_sid);
	END IF;

	SELECT ind_sid
	  BULK COLLECT INTO v_ind_sids
	  FROM (
		SELECT DISTINCT i.ind_sid
		  FROM ind i
		 WHERE i.app_sid = v_app_sid
		   AND i.ind_sid = in_sid
		   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
		   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, i.ind_sid, security_Pkg.PERMISSION_READ) = 1);

	GetIndsBySids(
		in_ind_sids			=>	v_ind_sids,
		out_ind_cur			=>	out_ind_cur,
		out_description_cur	=>	out_description_cur,
		out_measure_cur		=>	out_measure_cur
	);
END;

PROCEDURE GetIndicatorsBySid(
	in_ind_sids				IN	security_pkg.T_SID_IDS,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_ind_sids				security.T_SID_TABLE;
	v_ordered_ind_sids		security.T_ORDERED_SID_TABLE;
	v_allowed_ind_sids		security.T_SO_TABLE;
	v_trashed_ind_sids		security.T_SID_TABLE;
	v_requested_count		NUMBER;
	v_allowed_count			NUMBER;
	v_trashed_count			NUMBER;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;

	v_trashed_ind_sids := GetTrashedIndSids();
	v_ordered_ind_sids := security_pkg.SidArrayToOrderedTable(in_ind_sids);
	v_allowed_ind_sids := securableObject_pkg.GetSIDsWithPermAsTable(
		v_act_id,
		security_pkg.SidArrayToTable(in_ind_sids),
		security_pkg.PERMISSION_READ
	);

	SELECT COUNT(*)
	  INTO v_requested_count
	  FROM TABLE(v_ordered_ind_sids);

	SELECT COUNT(*)
	  INTO v_allowed_count
	  FROM ind i
	  JOIN TABLE(v_allowed_ind_sids) ai ON ai.sid_id = i.ind_sid
	 WHERE i.app_sid = v_app_sid;

	IF v_requested_count != v_allowed_count THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on one or more requested indicator');
	END IF;

	SELECT COUNT(*)
	  INTO v_trashed_count
	  FROM ind i
	  JOIN TABLE(v_ordered_ind_sids) ri ON ri.sid_id = i.ind_sid
	 WHERE i.ind_sid IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
	   AND i.app_sid = v_app_sid;

	IF v_trashed_count > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_IN_TRASH, 'One or more of the requested indicators have been deleted');
	END IF;

	SELECT i.ind_sid
	  BULK COLLECT INTO v_ind_sids
	  FROM ind i
	  JOIN TABLE(v_allowed_ind_sids) ai ON ai.sid_id = i.ind_sid
	  JOIN TABLE(v_ordered_ind_sids) ri ON ri.sid_id = i.ind_sid
	 WHERE i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
	   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, i.ind_sid, security_Pkg.PERMISSION_READ) = 1
	   AND i.app_sid = v_app_sid
	 ORDER BY i.ind_sid;

	GetIndsBySids(
		in_ind_sids			=>	v_ind_sids,
		out_ind_cur			=>	out_ind_cur,
		out_description_cur	=>	out_description_cur,
		out_measure_cur		=>	out_measure_cur
	);

END;
PROCEDURE GetIndsByPath(
	in_path					IN	VARCHAR2,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_ind_sids				security.T_SID_TABLE;
	path_cur 				SYS_REFCURSOR;
BEGIN
	FindIndicatorsByPath(
		in_path				=>	LOWER(in_path),
		in_separator		=>	'/',
		in_skip				=>	in_skip,
		in_take				=>	in_take,
		out_row_count		=>	out_total_rows_cur,
		out_cur				=>	path_cur
	);

	IF path_cur%ISOPEN
	THEN
		FETCH path_cur BULK COLLECT INTO v_ind_sids;
		CLOSE path_cur;
	END IF;

	GetIndsBySids(
		in_ind_sids			=>	v_ind_sids,
		out_ind_cur			=>	out_ind_cur,
		out_description_cur	=>	out_description_cur,
		out_measure_cur		=>	out_measure_cur
	);
END;

PROCEDURE GetIndicatorsByType(
	in_indicator_types		IN	security_pkg.T_SID_IDS,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_measure_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_indicator_types		security.T_SID_TABLE;
	v_ind_sids				security.T_SID_TABLE;
	v_trashed_ind_sids		security.T_SID_TABLE;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;
	v_indicator_types := security_pkg.SidArrayToTable(in_indicator_types);
	v_trashed_ind_sids := GetTrashedIndSids();

	SELECT ind_sid
	  BULK COLLECT INTO v_ind_sids
	  FROM (
		SELECT ind_sid, rownum rn
		  FROM (
				SELECT i.ind_sid
				  FROM ind i
				 WHERE i.app_sid = v_app_sid
				   AND i.ind_type IN (SELECT column_value FROM TABLE(v_indicator_types))
				   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
				   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, i.ind_sid, security_Pkg.PERMISSION_READ) = 1
				   AND i.measure_sid IS NOT NULL
				 ORDER BY i.ind_sid
				)
			)
		WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;

	OPEN out_total_rows_cur FOR
		SELECT COUNT(DISTINCT(i.ind_sid)) total_rows
		  FROM ind i
		 WHERE i.app_sid = v_app_sid
		   AND i.ind_type IN (SELECT column_value FROM TABLE(v_indicator_types))
		   AND i.ind_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_ind_sids))
		   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, i.ind_sid, security_Pkg.PERMISSION_READ) = 1;

	GetIndsBySids(
		in_ind_sids			=>	v_ind_sids,
		out_ind_cur			=>	out_ind_cur,
		out_description_cur	=>	out_description_cur,
		out_measure_cur		=>	out_measure_cur
	);
END;

-- Used by the json exporter for moving data between sites.
PROCEDURE GetAllIndsHierarchical(
	in_parent_sid				IN	csr.ind.ind_sid%TYPE,
	out_inds_cur				OUT	SYS_REFCURSOR,
	out_ind_tags_cur			OUT	SYS_REFCURSOR,
	out_ind_descriptions_cur	OUT	SYS_REFCURSOR
)
AS
	v_ind_sids		security.T_SID_TABLE;
BEGIN

	SELECT ind_sid
	  BULK COLLECT INTO v_ind_sids
	  FROM ind
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 START WITH ind_sid = in_parent_sid
   CONNECT BY PRIOR ind_sid = parent_sid;

	OPEN out_inds_cur FOR
		SELECT ind_sid, parent_sid, lookup_key, ind_type, tolerance_type,
			   pct_upper_tolerance, pct_lower_tolerance, measure_sid, format_mask,
			   active, target_direction, pos, start_month, divisibility, aggregate,
			   period_set_id, period_interval_id, calc_xml, core, roll_forward,
			   factor_type_id, map_to_ind_sid, gas_measure_sid, gas_type_id, normalize,
			   do_temporal_aggregation, info_xml, tolerance_number_of_periods, 
			   tolerance_number_of_standard_deviations_from_average
		  FROM ind
		 WHERE ind_sid IN (SELECT column_value FROM TABLE(v_ind_sids));

	OPEN out_ind_tags_cur FOR
		SELECT it.ind_sid, it.tag_id, t.lookup_key tag_lookup_key
		  FROM ind_tag it
		  JOIN tag t ON it.tag_id = t.tag_id
		 WHERE ind_sid IN (SELECT column_value FROM TABLE(v_ind_sids))
		   AND it.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_ind_descriptions_cur FOR
		SELECT ind_sid, lang, description
		  FROM ind_description
		 WHERE ind_sid IN (SELECT column_value FROM TABLE(v_ind_sids))
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

END;
/
