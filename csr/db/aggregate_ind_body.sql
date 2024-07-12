CREATE OR REPLACE PACKAGE BODY csr.aggregate_ind_pkg AS

PROCEDURE WriteToAuditLog(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_msg						IN	VARCHAR2
)
AS
BEGIN

	INSERT INTO csr.aggregate_ind_group_audit_log
		(aggregate_ind_group_id, change_dtm, changed_by_user_sid, change_description)
	VALUES
		(in_aggregate_ind_group_id, SYSDATE, SYS_CONTEXT('SECURITY', 'SID'), in_msg);

END;

PROCEDURE AuditChange(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_field_name				IN	VARCHAR2,
	in_current_value			IN	VARCHAR2,
	in_new_value				IN	VARCHAR2
)
AS
BEGIN
	IF in_current_value IS NULL AND in_new_value IS NOT NULL THEN
		WriteToAuditLog(
			in_aggregate_ind_group_id => in_aggregate_ind_group_id,
			in_msg => in_field_name || ' set to "' || in_new_value || '"'
		);
	ELSIF in_current_value IS NOT NULL AND in_new_value IS NULL THEN
		WriteToAuditLog(
			in_aggregate_ind_group_id => in_aggregate_ind_group_id,
			in_msg => in_field_name || ' cleared'
		);
	ELSIF in_current_value != in_new_value THEN
		WriteToAuditLog(
			in_aggregate_ind_group_id => in_aggregate_ind_group_id,
			in_msg => in_field_name || ' changed from "' ||
					  in_current_value || '" to "' || in_new_value || '"'
		);
	END IF;

END;

PROCEDURE INTERNAL_CreateGroup(
	in_name						IN	aggregate_ind_group.name%TYPE,
	in_label					IN	aggregate_ind_group.label%TYPE,
	in_helper_proc				IN	aggregate_ind_group.helper_proc%TYPE, -- e.g. 'csr.audit_pkg.GetIndicatorValues'
	in_helper_proc_args			IN	aggregate_ind_group.helper_proc_args%TYPE DEFAULT 'vals',
	in_source_url				IN	aggregate_ind_group.source_url%TYPE DEFAULT NULL,
	in_lookup_key				IN	aggregate_ind_group.lookup_key%TYPE DEFAULT NULL,
	in_run_daily				IN	aggregate_ind_group.run_daily%TYPE DEFAULT 0,
	in_run_for_current_month	IN	aggregate_ind_group.run_for_current_month%TYPE DEFAULT 0,
	out_aggregate_ind_group_id	OUT	aggregate_ind_group.aggregate_ind_group_id%TYPE
)
AS
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading aggregate indicator groups.');
	END IF;
	
	INSERT INTO aggregate_ind_group 
		(aggregate_ind_group_id, helper_proc, helper_proc_args, name, label, source_url, 
		 lookup_key, run_daily, run_for_current_month)
	VALUES (aggregate_ind_group_id_seq.NEXTVAL, in_helper_proc, in_helper_proc_args, in_name, 
		 in_label, in_source_url, in_lookup_key, in_run_daily, in_run_for_current_month)
	RETURNING aggregate_ind_group_id INTO out_aggregate_ind_group_id;

	WriteToAuditLog(
		in_aggregate_ind_group_id => out_aggregate_ind_group_id,
		in_msg => 'Group created'
	);
	
END;

PROCEDURE CreateGroup(
	in_name						IN	aggregate_ind_group.name%TYPE,
	in_label					IN	aggregate_ind_group.label%TYPE,
	in_helper_proc				IN	aggregate_ind_group.helper_proc%TYPE, -- e.g. 'csr.audit_pkg.GetIndicatorValues'
	in_helper_proc_args			IN	aggregate_ind_group.helper_proc_args%TYPE DEFAULT 'vals',
	in_source_url				IN	aggregate_ind_group.source_url%TYPE DEFAULT NULL,
	in_lookup_key				IN	aggregate_ind_group.lookup_key%TYPE DEFAULT NULL,
	in_run_daily				IN	aggregate_ind_group.run_daily%TYPE DEFAULT 0,
	in_run_for_current_month	IN	aggregate_ind_group.run_for_current_month%TYPE DEFAULT 0,
	out_aggregate_ind_group_id	OUT	aggregate_ind_group.aggregate_ind_group_id%TYPE
)
AS
BEGIN

	BEGIN
		INTERNAL_CreateGroup(
			in_name						=> in_name,
			in_label					=> in_label,
			in_helper_proc				=> in_helper_proc,
			in_helper_proc_args			=> in_helper_proc_args,
			in_source_url				=> in_source_url,
			in_lookup_key				=> in_lookup_key,
			in_run_daily				=> in_run_daily,
			in_run_for_current_month	=> in_run_for_current_month,
			out_aggregate_ind_group_id	=> out_aggregate_ind_group_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'A group with that name or key already exists.');
	END;

END;

PROCEDURE UpdateGroup(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_name						IN	aggregate_ind_group.name%TYPE,
	in_label					IN	aggregate_ind_group.label%TYPE,
	in_helper_proc				IN	aggregate_ind_group.helper_proc%TYPE,
	in_helper_proc_args			IN	aggregate_ind_group.helper_proc_args%TYPE,
	in_source_url				IN	aggregate_ind_group.source_url%TYPE DEFAULT NULL,
	in_lookup_key				IN	aggregate_ind_group.lookup_key%TYPE DEFAULT NULL,
	in_run_daily				IN	aggregate_ind_group.run_daily%TYPE DEFAULT 0,
	in_run_for_current_month	IN	aggregate_ind_group.run_for_current_month%TYPE DEFAULT 0,
	in_data_bucket_sid			IN	aggregate_ind_group.data_bucket_sid%TYPE DEFAULT NULL,
	in_data_bucket_fetch_sp		IN	aggregate_ind_group.data_bucket_fetch_sp%TYPE DEFAULT NULL
)
AS
	v_name						aggregate_ind_group.name%TYPE;
	v_label						aggregate_ind_group.label%TYPE;
	v_helper_proc				aggregate_ind_group.helper_proc%TYPE;
	v_helper_proc_args			aggregate_ind_group.helper_proc_args%TYPE;
	v_source_url				aggregate_ind_group.source_url%TYPE;
	v_lookup_key				aggregate_ind_group.lookup_key%TYPE;
	v_run_daily					aggregate_ind_group.run_daily%TYPE;
	v_run_for_current_month		aggregate_ind_group.run_for_current_month%TYPE;
	v_data_bucket_sid			aggregate_ind_group.data_bucket_sid%TYPE;
	v_data_bucket_fetch_sp		aggregate_ind_group.data_bucket_fetch_sp%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading aggregate indicator groups.');
	END IF;

	BEGIN
		SELECT name, label, helper_proc, helper_proc_args, source_url, lookup_key, 
			   run_daily, run_for_current_month, data_bucket_sid, data_bucket_fetch_sp
		  INTO v_name, v_label, v_helper_proc, v_helper_proc_args, v_source_url, v_lookup_key,
			   v_run_daily, v_run_for_current_month, v_data_bucket_sid, v_data_bucket_fetch_sp
		  FROM aggregate_ind_group
		 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Aggregate ind group "'||in_aggregate_ind_group_id||'" not found');
	END;

	UPDATE aggregate_ind_group
	   SET name = in_name,
		   label = in_label,
		   helper_proc = in_helper_proc,
		   helper_proc_args = in_helper_proc_args,
		   source_url = in_source_url,
		   lookup_key = in_lookup_key,
		   run_daily = in_run_daily,
		   run_for_current_month = in_run_for_current_month,
		   data_bucket_sid = in_data_bucket_sid,
		   data_bucket_fetch_sp = in_data_bucket_fetch_sp
	 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	AuditChange(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_field_name				=> 'name',
		in_current_value			=> v_name,
		in_new_value				=> in_name
	);
	AuditChange(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_field_name				=> 'label',
		in_current_value			=> v_label,
		in_new_value				=> in_label
	);
	AuditChange(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_field_name				=> 'helper proc',
		in_current_value			=> v_helper_proc,
		in_new_value				=> in_helper_proc
	);
	AuditChange(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_field_name				=> 'helper proc args',
		in_current_value			=> v_helper_proc_args,
		in_new_value				=> in_helper_proc_args
	);
	AuditChange(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_field_name				=> 'source URL',
		in_current_value			=> v_source_url,
		in_new_value				=> in_source_url
	);
	AuditChange(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_field_name				=> 'lookup key',
		in_current_value			=> v_lookup_key,
		in_new_value				=> in_lookup_key
	);
	AuditChange(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_field_name				=> 'run daily',
		in_current_value			=> v_run_daily,
		in_new_value				=> in_run_daily
	);
	AuditChange(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_field_name				=> 'run for current month',
		in_current_value			=> v_run_for_current_month,
		in_new_value				=> in_run_for_current_month
	);
	AuditChange(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_field_name				=> 'data bucket sid',
		in_current_value			=> v_data_bucket_sid,
		in_new_value				=> in_data_bucket_sid
	);
	AuditChange(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		in_field_name				=> 'data bucket fetch sp',
		in_current_value			=> v_data_bucket_fetch_sp,
		in_new_value				=> in_data_bucket_fetch_sp
	);
END;

FUNCTION SetGroup(
	in_name						IN	aggregate_ind_group.name%TYPE,
	in_helper_proc				IN	aggregate_ind_group.helper_proc%TYPE, -- e.g. 'csr.audit_pkg.GetIndicatorValues'
	in_helper_proc_args			IN	aggregate_ind_group.helper_proc_args%TYPE DEFAULT 'vals',
	in_source_url				IN	aggregate_ind_group.source_url%TYPE DEFAULT NULL,
	in_lookup_key				IN	aggregate_ind_group.lookup_key%TYPE DEFAULT NULL
)  RETURN aggregate_ind_group.aggregate_ind_group_id%TYPE
AS
	v_aggregate_ind_group_id	aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
	BEGIN
		INTERNAL_CreateGroup(
			in_name						=> in_name,
			in_label					=> in_name,
			in_helper_proc				=> in_helper_proc,
			in_helper_proc_args			=> in_helper_proc_args,
			in_source_url				=> in_source_url,
			in_lookup_key				=> in_lookup_key,
			out_aggregate_ind_group_id	=> v_aggregate_ind_group_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			v_aggregate_ind_group_id := GetGroupId(in_name);
			UpdateGroup(
				in_aggregate_ind_group_id	=> v_aggregate_ind_group_id,
				in_name						=> in_name,
				in_label					=> in_name,
				in_helper_proc				=> in_helper_proc,
				in_helper_proc_args			=> in_helper_proc_args,
				in_source_url				=> in_source_url,
				in_lookup_key				=> in_lookup_key
			);
	END;
	RETURN v_aggregate_ind_group_id;
END;

FUNCTION GetGroupId(
	in_aggr_group_name	IN	aggregate_ind_group.name%TYPE
) RETURN aggregate_ind_group.aggregate_ind_group_id%TYPE
AS
	v_aggregate_ind_group_id	aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
	BEGIN
		SELECT aggregate_ind_group_id
		  INTO v_aggregate_ind_group_id
		  FROM aggregate_ind_group
		 WHERE UPPER(name) = UPPER(in_aggr_group_name)
		   AND app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Aggregate ind group "'||in_aggr_group_name||'" not found');
	END;
	
	RETURN v_aggregate_ind_group_id;
END;

PROCEDURE RefreshAll
AS
BEGIN
	FOR r in (
		SELECT aggregate_ind_group_Id
		  FROM aggregate_ind_group
		 WHERE app_sid = security_pkg.getApp
	)
	LOOP
		aggregate_ind_pkg.RefreshGroup(r.aggregate_ind_group_id);
	END LOOP;
END;

PROCEDURE RefreshDailyGroups
AS
	v_last_app_sid	security_pkg.T_SID_ID := -1;
	v_start_dtm		DATE := TRUNC(SYSDATE, 'MONTH');
	v_end_dtm		DATE := ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), 1);
BEGIN
	user_pkg.logonadmin(timeout=>600);
	
	FOR r IN (
		SELECT aig.app_sid, aig.aggregate_ind_group_id, aig.run_for_current_month
		  FROM aggregate_ind_group aig
		 WHERE aig.run_daily = 1
		 ORDER BY aig.app_sid
	)
	LOOP
		IF v_last_app_sid != r.app_sid THEN
			security_pkg.SetApp(r.app_sid);
		END IF;
		
		IF r.run_for_current_month = 1 THEN
			RefreshGroup(r.aggregate_ind_group_id, v_start_dtm, v_end_dtm);
		ELSE
			RefreshGroup(r.aggregate_ind_group_id);
		END IF;
		
		v_last_app_sid := r.app_sid;
	END LOOP;
	
	user_pkg.LogOff(security_pkg.GetAct);
END;

PROCEDURE RefreshGroup(
	in_aggregate_ind_group_id	IN		aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_from_dtm					IN		DATE DEFAULT NULL,
	in_to_dtm					IN		DATE DEFAULT NULL
)
AS
BEGIN
	calc_pkg.AddJobsForAggregateIndGroup(in_aggregate_ind_group_id, in_from_dtm, in_to_dtm);
END;

PROCEDURE RefreshGroup(
	in_aggregate_ind_group_name	IN		aggregate_ind_group.name%TYPE,
	in_from_dtm					IN		DATE DEFAULT NULL,
	in_to_dtm					IN		DATE DEFAULT NULL
)
AS
BEGIN
	aggregate_ind_pkg.RefreshGroup(aggregate_ind_pkg.getgroupid(in_aggregate_ind_group_name), in_from_dtm, in_to_dtm);
END;

PROCEDURE CreateAggregateInd (
	in_aggregate_ind_group_id	IN	aggregate_ind_group.name%TYPE,
	in_parent_ind_sid			IN	ind.parent_sid%TYPE,
	in_desc						IN	ind_description.description%TYPE,
	in_lookup_key				IN	ind.lookup_key%TYPE DEFAULT NULL,
	in_name						IN  ind.name%TYPE,
	in_measure_sid				IN	ind.measure_sid%TYPE,
	in_divisibility				IN	ind.divisibility%TYPE DEFAULT NULL,
	in_info_definition			IN	VARCHAR2 DEFAULT NULL,
	in_aggregate				IN	ind.aggregate%TYPE DEFAULT 'SUM',
	out_ind_sid					OUT	ind.ind_sid%TYPE
)
AS
	v_count_existing_lookup_key		NUMBER;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading aggregate indicator groups.');
	END IF;

	SELECT COUNT(*)
	  INTO v_count_existing_lookup_key
	  FROM ind
	 WHERE UPPER(lookup_key) = UPPER(in_lookup_key)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_count_existing_lookup_key > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_ALREADY_EXISTS, 'Lookup key already exists.');
	END IF;

	indicator_pkg.CreateIndicator(
		in_parent_sid_id				=> in_parent_ind_sid,
		in_name 						=> in_name,
		in_description 					=> in_desc,
		in_measure_sid					=> in_measure_sid,
		in_divisibility					=> in_divisibility,
		in_ind_type						=> csr_data_pkg.IND_TYPE_AGGREGATE,
		in_aggregate					=> in_aggregate,
		in_is_system_managed			=> 1,
		in_lookup_key					=> in_lookup_key,
		out_sid_id						=> out_ind_sid
	);
	
	IF in_info_definition IS NOT NULL THEN
		indicator_pkg.SetExtraInfoValue(security_pkg.getACT, out_ind_sid, 'definition', in_info_definition);
	END IF;
	
	INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
		VALUES (in_aggregate_ind_group_id, out_ind_sid);
	
	WriteToAuditLog(
		in_aggregate_ind_group_id => in_aggregate_ind_group_id,
		in_msg => 'Indicator ' || out_ind_sid || ' created and added to group.'
	);
END;

-- Helper proc to reduce dup code
PROCEDURE SetAggregateInd (
	in_aggr_group_name		IN	aggregate_ind_group.name%TYPE,
	in_parent				IN	ind.parent_sid%TYPE,
	in_desc					IN	ind_description.description%TYPE,
	in_lookup_key			IN	ind.lookup_key%TYPE,
	in_name					IN  ind.name%TYPE DEFAULT NULL,
	in_measure_sid			IN	ind.measure_sid%TYPE,
	in_divisibility			IN	ind.divisibility%TYPE DEFAULT NULL,
	in_info_definition		IN  VARCHAR2 DEFAULT NULL,
	in_aggregate			IN	ind.aggregate%TYPE DEFAULT 'SUM',
	out_ind_sid				OUT	ind.ind_sid%TYPE
)
AS
	v_aggregate_ind_group_id	aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
	v_aggregate_ind_group_id := GetGroupId(in_aggr_group_name);
	SetAggregateInd (
		in_aggregate_ind_group_id	=> v_aggregate_ind_group_id,
		in_parent					=> in_parent,
		in_desc						=> in_desc,
		in_lookup_key				=> in_lookup_key,
		in_name						=> in_name,
		in_measure_sid				=> in_measure_sid,
		in_divisibility				=> in_divisibility,
		in_info_definition			=> in_info_definition,
		in_aggregate				=> in_aggregate,
		out_ind_sid					=> out_ind_sid
	);
END;

PROCEDURE SetAggregateInd (
	in_aggregate_ind_group_id	IN	aggregate_ind_group.name%TYPE,
	in_parent					IN	ind.parent_sid%TYPE,
	in_desc						IN	ind_description.description%TYPE,
	in_lookup_key				IN	ind.lookup_key%TYPE,
	in_name						IN  ind.name%TYPE DEFAULT NULL,
	in_measure_sid				IN	ind.measure_sid%TYPE,
	in_divisibility				IN	ind.divisibility%TYPE DEFAULT NULL,
	in_info_definition			IN  VARCHAR2 DEFAULT NULL,
	in_aggregate				IN	ind.aggregate%TYPE DEFAULT 'SUM',
	out_ind_sid					OUT	ind.ind_sid%TYPE
)
AS
BEGIN
	BEGIN
		SELECT ind_sid
		  INTO out_ind_sid
		  FROM ind
		 WHERE lookup_key = in_lookup_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_parent_sid_id 		=> in_parent,
				in_name 				=> NVL(in_name, in_lookup_key),
				in_description 			=> SUBSTR(in_desc,1,1000),
				in_active	 			=> 1,
				in_divisibility			=> in_divisibility,
				in_aggregate			=> in_aggregate,
				in_measure_sid			=> in_measure_sid,
				out_sid_id				=> out_ind_sid
			);
	END; 
	
	UPDATE ind
	   SET lookup_key = in_lookup_key,
		   ind_type = csr_data_pkg.IND_TYPE_AGGREGATE,
		   is_system_managed = 1
	 WHERE ind_sid = out_ind_sid;
	 
	IF in_info_definition IS NOT NULL THEN
		indicator_pkg.SetExtraInfoValue(security_pkg.getACT, out_ind_sid, 'definition', in_info_definition);
	END IF;
	
	BEGIN
		INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
		VALUES (in_aggregate_ind_group_id, out_ind_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- it's already there
			null;
	END;
END;
	 
-- Helper function to gather results of an aggregate indicator group helper_proc
-- into a table (e.g. to help extending an existing helper_proc for a client)
FUNCTION ConvertAggIndCursor(
	in_cur							IN	SYS_REFCURSOR
)
RETURN T_AGGREGATE_VAL_TABLE PIPELINED
AS
	v_region_sid				NUMBER(10);
	v_ind_sid					NUMBER(10);
	v_start_dtm					DATE;
	v_end_dtm					DATE;
	v_source_type_id			NUMBER(10);
	v_val_number				NUMBER(24, 10);
	v_error_code				NUMBER(10);
BEGIN
	LOOP
		FETCH in_cur INTO v_region_sid, v_ind_sid, v_start_dtm, v_end_dtm, v_source_type_id, v_val_number, v_error_code;
		EXIT WHEN in_cur%NOTFOUND;		
		PIPE ROW(T_AGGREGATE_VAL_ROW(v_ind_sid, v_region_sid, v_start_dtm, v_end_dtm, v_val_number));
	END LOOP;
	RETURN;
END;

PROCEDURE GetAggregateIndGroups(
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- Assert super admin. We then skip permission checks
	-- If this super admin check is removed you MUST add additional security
	-- in it's place, eg checking against individual sids. 
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading aggregate indicator groups.');
	END IF;

	OPEN out_cur FOR
		SELECT aggregate_ind_group_id, name, label, helper_proc, helper_proc_args, run_daily,
			   run_for_current_month, source_url, lookup_key, aig.data_bucket_sid, 
			   data_bucket_fetch_sp, db.description data_bucket_description
		  FROM aggregate_ind_group aig
	 LEFT JOIN data_bucket db on db.data_bucket_sid = aig.data_bucket_sid
		 WHERE aig.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetAggregateIndGroup(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	-- Assert super admin. We then skip permission checks
	-- If this super admin check is removed you MUST add additional security
	-- in it's place, eg checking against individual sids. 
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading aggregate indicator groups.');
	END IF;

	OPEN out_cur FOR
		SELECT aggregate_ind_group_id, name, label, helper_proc, helper_proc_args, run_daily,
			   run_for_current_month, source_url, lookup_key, data_bucket_sid, data_bucket_fetch_sp
		  FROM aggregate_ind_group
		 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetIndicatorsInGroup(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN

	-- Assert super admin. We then skip permission checks
	-- If this super admin check is removed you MUST add additional security
	-- in it's place, eg checking against individual sids. 
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading aggregate indicator groups.');
	END IF;

	OPEN out_cur FOR
		SELECT i.ind_sid, i.description, i.lookup_key,
			indicator_pkg.INTERNAL_GetIndPathString(aigm.ind_sid) path
		  FROM aggregate_ind_group_member aigm
		  JOIN v$ind i ON i.ind_sid = aigm.ind_sid
		 WHERE aigm.aggregate_ind_group_id = in_aggregate_ind_group_id
		   AND aigm.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetIndParentDetails(
	in_ind_sid				IN	ind.ind_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading aggregate indicator groups.');
	END IF;

	OPEN out_cur FOR
		SELECT i.description, i.ind_sid
		  FROM v$ind i
		  JOIN ind i2 on i.ind_sid = i2.parent_sid
		 WHERE i2.ind_sid = in_ind_sid
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE AssertIndIsInGroup(
	in_ind_sid					IN	ind.ind_sid%TYPE,
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE
)
AS
	v_exists				NUMBER;
BEGIN

	-- Ensure it's an aggregate indicator and in the specified group
	SELECT COUNT(*)
	  INTO v_exists
	  FROM aggregate_ind_group_member
	 WHERE ind_sid = in_ind_sid
	   AND aggregate_ind_group_id = in_aggregate_ind_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_exists != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Indicator '||in_ind_sid||' not found in group '||in_aggregate_ind_group_id);
	END IF;

END;

PROCEDURE ReparentIndicator(
	in_ind_sid					IN	ind.ind_sid%TYPE,
	in_new_parent_sid			IN	ind.parent_sid%TYPE,
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE
)
AS
	v_existing_parent_sid		ind.parent_sid%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading aggregate indicator groups.');
	END IF;

	AssertIndIsInGroup(
		in_ind_sid					=> in_ind_sid,
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id
	);
	
	SELECT parent_sid
	  INTO v_existing_parent_sid
	  FROM ind
	 WHERE ind_sid = in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF in_new_parent_sid != v_existing_parent_sid THEN
		csr.indicator_pkg.MoveIndicator(
			in_act_id 				=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_ind_sid 				=> in_ind_sid,
			in_parent_sid_id		=> in_new_parent_sid
		);

		WriteToAuditLog(
			in_aggregate_ind_group_id => in_aggregate_ind_group_id,
			in_msg => 'Indicator '||in_ind_sid||' moved parent from '||v_existing_parent_sid||' to '||in_new_parent_sid
		);
	END IF;
END;

PROCEDURE SetIndicatorLookupKey(
	in_ind_sid					IN	ind.ind_sid%TYPE,
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_lookup_key				IN	ind.lookup_key%TYPE
)
AS
	v_existing_lookup_key			ind.lookup_key%TYPE;
	v_count_existing_lookup_key		NUMBER;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading aggregate indicator groups.');
	END IF;
	
	SELECT lookup_key
	  INTO v_existing_lookup_key
	  FROM ind
	 WHERE ind_sid = in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF in_lookup_key = v_existing_lookup_key THEN
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count_existing_lookup_key
	  FROM ind
	 WHERE UPPER(lookup_key) = UPPER(in_lookup_key)
	   AND ind_sid != in_ind_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_count_existing_lookup_key > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_ALREADY_EXISTS, 'Lookup key already exists.');
	END IF;

	AssertIndIsInGroup(
		in_ind_sid					=> in_ind_sid,
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id
	);
	
	indicator_pkg.SetLookupKey(
		in_ind_sid				=> in_ind_sid,
		in_new_lookup_key		=> in_lookup_key
	);
	
	WriteToAuditLog(
		in_aggregate_ind_group_id => in_aggregate_ind_group_id,
		in_msg => 'Indicator '||in_ind_sid||' lookup key changed from '||v_existing_lookup_key||' to '||in_lookup_key
	);
END;

PROCEDURE GetAuditLogForGroup(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading aggregate indicator groups.');
	END IF;

	OPEN out_cur FOR
		SELECT aggregate_ind_group_id, change_dtm, change_description, changed_by_user_sid,
			   cu.full_name changed_by_user_name
		  FROM aggregate_ind_group_audit_log log
		  JOIN csr_user cu ON cu.csr_user_sid = log.changed_by_user_sid
		 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id
		   AND log.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY change_dtm desc;
		
END;

PROCEDURE TriggerDataBucketJob(
	in_aggregate_ind_group_id	IN	batch_job_data_bucket_agg_ind.aggregate_ind_group_id%TYPE,
	out_batch_job_id			OUT	batch_job.batch_job_id%TYPE
)
AS
	v_bucket_sid		data_bucket.data_bucket_sid%TYPE;
BEGIN
	
	SELECT data_bucket_sid
	  INTO v_bucket_sid
	  FROM aggregate_ind_group
	 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_bucket_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot trigger data bucket job for aggregate ind group '||in_aggregate_ind_group_id||' because it does not have a linked data bucket.');
	END IF;
	
	BEGIN
		SELECT batch_job_id
		  INTO out_batch_job_id
		  FROM agg_ind_data_bucket_pending_job
		 WHERE data_bucket_sid = v_bucket_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			batch_job_pkg.Enqueue(
				in_batch_job_type_id	=> batch_job_pkg.JT_DATA_BUCKET_AGG_IND,
				out_batch_job_id		=> out_batch_job_id);

			INSERT INTO batch_job_data_bucket_agg_ind
				(batch_job_id, data_bucket_sid, aggregate_ind_group_id)
			VALUES
				(out_batch_job_id, v_bucket_sid, in_aggregate_ind_group_id);
			
			INSERT INTO agg_ind_data_bucket_pending_job
				(batch_job_id, data_bucket_sid)
			VALUES
				(out_batch_job_id, v_bucket_sid);
	END;
END;

PROCEDURE GetDataBucketJobDetails(
	in_batch_job_id		IN	batch_job.batch_job_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT data_bucket_sid, aggregate_ind_group_id
		  FROM batch_job_data_bucket_agg_ind
		 WHERE batch_job_id = in_batch_job_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

-- We want to avoid building up a backlog of batch jobs needlessly; Eg the data will be
-- fetched as of when the job starts, rather than specifically from when it was created.
-- As such, multiple changes can be picked up by the same job. If every change triggered
-- a batch job, we'd just end up with an epic queue!
-- So, when a job is created, we create an additional "pending" row. This gets deleted 
-- when the batch job begins (commited autonomously). This allows us to only create a new
-- job when there isn't already one pending start. It's difficult to do thing from the batch
-- job table because we don't delete rows like we do with calc jobs, and figuring out whether
-- a job is running/waiting/etc is... unreliable.

PROCEDURE BeginDataBucketJob(
	in_batch_job_id		IN	batch_job.batch_job_id%TYPE
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	DELETE FROM agg_ind_data_bucket_pending_job
	 WHERE batch_job_id = in_batch_job_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	COMMIT;
END;

PROCEDURE GetAggIndGroupBucketAndInstance(
	in_aggregate_ind_group_id		IN	NUMBER,
	out_data_bucket_sid				OUT	csr.data_bucket.data_bucket_sid%TYPE,
	out_instance_id					OUT	csr.data_bucket_instance.data_bucket_instance_id%TYPE
)
AS
BEGIN

	SELECT db.data_bucket_sid, db.active_instance_id
	  INTO out_data_bucket_sid, out_instance_id
	  FROM aggregate_ind_group aig
	  JOIN data_bucket db ON db.data_bucket_sid = aig.data_bucket_sid
	 WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;

	-- Ensure a data bucket has been set for this agg ind group. We don't check
	-- if the instance is null because that is a legitimate case; eg when you first
	-- enable a data bucket for this group, if a calc job gets triggered we don't
	-- want it to fail the calc job. It'll just return no data.
	IF out_data_bucket_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'No data bucket set');
	END IF;

END;

PROCEDURE GetBucketData(
	in_aggregate_ind_group_id		IN	NUMBER,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_data_bucket_sid		csr.data_bucket.data_bucket_sid%TYPE;
	v_instance_id			csr.data_bucket_instance.data_bucket_instance_id%TYPE;
BEGIN
	GetAggIndGroupBucketAndInstance(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		out_data_bucket_sid			=> v_data_bucket_sid,
		out_instance_id				=> v_instance_id
	);

	csr.data_bucket_pkg.GetValsData(
		in_data_bucket_sid		=> v_data_bucket_sid,
		in_instance_id			=> v_instance_id,
		out_cur					=> out_cur
	);
END;

PROCEDURE GetBucketData(
	in_aggregate_ind_group_id		IN	NUMBER,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_scenario_run_sid				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_data_bucket_sid		csr.data_bucket.data_bucket_sid%TYPE;
	v_instance_id			csr.data_bucket_instance.data_bucket_instance_id%TYPE;
BEGIN
	GetAggIndGroupBucketAndInstance(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		out_data_bucket_sid			=> v_data_bucket_sid,
		out_instance_id				=> v_instance_id
	);
	
	csr.data_bucket_pkg.GetValsData(
		in_data_bucket_sid		=> v_data_bucket_sid,
		in_instance_id			=> v_instance_id,
		out_cur					=> out_cur
	);
END;

PROCEDURE GetBucketData(
	in_aggregate_ind_group_id		IN	NUMBER,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_cur							OUT	SYS_REFCURSOR,
	out_source_detail_cur			OUT	SYS_REFCURSOR
)
AS
	v_data_bucket_sid		csr.data_bucket.data_bucket_sid%TYPE;
	v_instance_id			csr.data_bucket_instance.data_bucket_instance_id%TYPE;
BEGIN
	GetAggIndGroupBucketAndInstance(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		out_data_bucket_sid			=> v_data_bucket_sid,
		out_instance_id				=> v_instance_id
	);
	
	csr.data_bucket_pkg.GetValsData(
		in_data_bucket_sid		=> v_data_bucket_sid,
		in_instance_id			=> v_instance_id,
		out_cur					=> out_cur
	);
	
	csr.data_bucket_pkg.GetSourceDetailsData(
		in_data_bucket_sid		=> v_data_bucket_sid,
		in_instance_id			=> v_instance_id,
		out_cur					=> out_source_detail_cur
	);
END;

PROCEDURE GetBucketData(
	in_aggregate_ind_group_id		IN	NUMBER,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	in_scenario_run_sid				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR,
	out_source_detail_cur			OUT	SYS_REFCURSOR
)
AS
	v_data_bucket_sid		csr.data_bucket.data_bucket_sid%TYPE;
	v_instance_id			csr.data_bucket_instance.data_bucket_instance_id%TYPE;
BEGIN
	GetAggIndGroupBucketAndInstance(
		in_aggregate_ind_group_id	=> in_aggregate_ind_group_id,
		out_data_bucket_sid			=> v_data_bucket_sid,
		out_instance_id				=> v_instance_id
	);
	
	csr.data_bucket_pkg.GetValsData(
		in_data_bucket_sid		=> v_data_bucket_sid,
		in_instance_id			=> v_instance_id,
		out_cur					=> out_cur
	);
	
	csr.data_bucket_pkg.GetSourceDetailsData(
		in_data_bucket_sid		=> v_data_bucket_sid,
		in_instance_id			=> v_instance_id,
		out_cur					=> out_source_detail_cur
	);
END;

PROCEDURE RemoveAggIndGroup(
	in_aggregate_ind_group_id	IN	NUMBER
)
AS
BEGIN
	UPDATE csr.batch_job_data_bucket_agg_ind
	   SET aggregate_ind_group_id = NULL
	WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;

	UPDATE csr.quick_survey
	   SET aggregate_ind_group_id = NULL
	WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;

	UPDATE csr.flow
	   SET aggregate_ind_group_id = NULL
	WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;

	UPDATE csr.issue_type_aggregate_ind_grp
	   SET aggregate_ind_group_id = NULL
	WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;

	DELETE FROM csr.aggregate_ind_val_detail
	WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;

	DELETE FROM csr.aggregate_ind_group_audit_log
	WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;

	DELETE FROM csr.calc_job_aggregate_ind_group
	WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;

	DELETE FROM csr.aggregate_ind_calc_job
	WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;

	DELETE FROM csr.aggregate_ind_group_member
	WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;

	DELETE FROM csr.aggregate_ind_group
	WHERE aggregate_ind_group_id = in_aggregate_ind_group_id;
END;

END;
/
