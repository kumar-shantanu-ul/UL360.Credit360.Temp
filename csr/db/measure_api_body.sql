CREATE OR REPLACE PACKAGE BODY csr.measure_api_pkg AS

PROCEDURE GetMeasuresBySids(
	in_measure_sids				IN	security.T_SID_TABLE,
	out_measure_cur				OUT	SYS_REFCURSOR,
	out_measure_conv_cur		OUT	SYS_REFCURSOR,
	out_measure_conv_date_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_measure_cur FOR
		SELECT m.measure_sid, m.format_mask, m.scale, m.name, m.description, m.custom_field,
			   m.pct_ownership_applies, m.std_measure_conversion_id, m.divisibility,
			   NVL(m.factor, smc.a) factor, NVL(m.m, sm.m) m, NVL(m.kg, sm.kg) kg, 
			   NVL(m.s, sm.s) s, NVL(m.a, sm.a) a, NVL(m.k, sm.k) k, NVL(m.mol, sm.mol) mol,
			   NVL(m.cd, sm.cd) cd,
			   CASE WHEN m.description IS NULL THEN '('||m.name||')' ELSE m.description END label,
			   m.option_set_id, smc.description std_measure_description,
			   m.lookup_key
		  FROM measure m
		  LEFT JOIN std_measure_conversion smc ON m.std_measure_conversion_id = smc.std_measure_conversion_id
		  LEFT JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.measure_sid IN (SELECT column_value FROM TABLE(in_measure_sids))
		 ORDER BY m.description;

	OPEN out_measure_conv_cur FOR
		SELECT measure_conversion_id, measure_sid, std_measure_conversion_id, description, a, b, c, lookup_key
		  FROM measure_conversion
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND measure_sid IN (SELECT column_value FROM TABLE(in_measure_sids));

	OPEN out_measure_conv_date_cur FOR
		SELECT measure_conversion_id, start_dtm, end_dtm, a, b, c
		  FROM measure_conversion_period
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND measure_conversion_id IN 
		   (
			SELECT measure_conversion_id
			  FROM measure_conversion
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND measure_sid IN (SELECT column_value FROM TABLE(in_measure_sids))
		   );
END;

PROCEDURE GetMeasuresBySids(
	in_sids				        IN	security.security_pkg.T_SID_IDS,
	out_measure_cur	        	OUT	SYS_REFCURSOR,
	out_measure_conv_cur		OUT	SYS_REFCURSOR,
	out_measure_conv_date_cur	OUT	SYS_REFCURSOR
)
AS
v_sids					security.T_SID_TABLE DEFAULT security.security_pkg.SidArrayToTable(in_sids);
v_measure_sids			security_pkg.T_SID_IDS;
v_allowed_measure_sids	security.T_SO_TABLE;
v_allowed_sids			security.T_SID_TABLE;
BEGIN
	SELECT m.measure_sid
	  BULK COLLECT INTO v_measure_sids
	  FROM measure m
  	  JOIN TABLE(v_sids) v ON m.measure_sid = v.column_value
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	v_allowed_measure_sids := securableObject_pkg.GetSIDsWithPermAsTable(
		SYS_CONTEXT('SECURITY', 'ACT'), 
		security_pkg.SidArrayToTable(v_measure_sids), 
		security_pkg.PERMISSION_READ
	);	

	SELECT sid_id
	BULK COLLECT INTO v_allowed_sids
	FROM TABLE(v_allowed_measure_sids);

	GetMeasuresBySids(
		in_measure_sids				=>	v_allowed_sids,
		out_measure_cur				=>	out_measure_cur,
		out_measure_conv_cur		=>	out_measure_conv_cur,
		out_measure_conv_date_cur	=>	out_measure_conv_date_cur
	);
END;

PROCEDURE GetMeasures(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_include_all				IN	NUMBER,
	in_include_null_lookup_keys	IN	NUMBER,
	in_lookup_keys				IN	security.T_VARCHAR2_TABLE,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_measure_cur				OUT	SYS_REFCURSOR,
	out_measure_conv_cur		OUT	SYS_REFCURSOR,
	out_measure_conv_date_cur	OUT SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
)
AS
	v_measure_sids			security.T_SID_TABLE;
	v_lookup_keys			security.T_VARCHAR2_TABLE;
BEGIN
	v_lookup_keys := in_lookup_keys;

	SELECT measure_sid
	  BULK COLLECT INTO v_measure_sids
	  FROM (
		SELECT measure_sid, rownum rn
		  FROM (
				SELECT m.measure_sid
				  FROM measure m
				 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND (in_include_all = 1 OR (LOWER(m.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (m.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
				   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, m.measure_sid, security_Pkg.PERMISSION_READ) = 1
				ORDER BY m.measure_sid
				)
			)
		WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;

	OPEN out_total_rows_cur FOR
		SELECT COUNT(m.measure_sid) total_rows
		  FROM measure m
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (in_include_all = 1 OR (LOWER(m.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (m.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, m.measure_sid, security_Pkg.PERMISSION_READ) = 1;

	GetMeasuresBySids(
		in_measure_sids				=>	v_measure_sids,
		out_measure_cur				=>	out_measure_cur,
		out_measure_conv_cur		=>	out_measure_conv_cur,
		out_measure_conv_date_cur	=>	out_measure_conv_date_cur
	);
END;

PROCEDURE GetMeasures(
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_measure_cur				OUT SYS_REFCURSOR,
	out_measure_conv_cur		OUT SYS_REFCURSOR,
	out_measure_conv_date_cur	OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetMeasures(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_include_all				=> 1,
		in_include_null_lookup_keys	=> 0,
		in_lookup_keys				=> security.T_VARCHAR2_TABLE(),
		in_skip						=> in_skip,
		in_take						=> in_take,
		out_measure_cur				=> out_measure_cur,
		out_measure_conv_cur		=> out_measure_conv_cur,
		out_measure_conv_date_cur	=> out_measure_conv_date_cur,
		out_total_rows_cur			=> out_total_rows_cur
	);
END;

PROCEDURE GetMeasuresByLookupKey(
	in_lookup_keys				IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_measure_cur				OUT SYS_REFCURSOR,
	out_measure_conv_cur		OUT SYS_REFCURSOR,
	out_measure_conv_date_cur	OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
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

	GetMeasures(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_include_all				=> 0,
		in_include_null_lookup_keys	=> v_lookup_contains_null,
		in_lookup_keys				=> v_lookup_keys,
		in_skip						=> in_skip,
		in_take						=> in_take,
		out_measure_cur				=> out_measure_cur,
		out_measure_conv_cur		=> out_measure_conv_cur,
		out_measure_conv_date_cur	=> out_measure_conv_date_cur,
		out_total_rows_cur			=> out_total_rows_cur
	);
END;

END;
/
