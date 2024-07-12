CREATE OR REPLACE PACKAGE BODY CSR.data_bucket_pkg IS

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
) AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_cnt	NUMBER;
BEGIN
	
	-- You can't delete a bucket that is still associated with an aggregate 
	-- ind group
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM csr.aggregate_ind_group
	 WHERE data_bucket_sid = in_sid_id;
	
	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_IN_USE, 'Cannot delete data bucket '
		||in_sid_id||' as it is assigned to an aggregate ind group.');
	END IF;
	
	DELETE FROM csr.data_bucket_val
	 WHERE data_bucket_sid = in_sid_id;
	
	DELETE FROM csr.data_bucket_source_detail
	 WHERE data_bucket_sid = in_sid_id;
	
	UPDATE csr.data_bucket
	   SET active_instance_id = NULL
	 WHERE data_bucket_sid = in_sid_id;
	
	DELETE FROM csr.data_bucket_instance
	 WHERE data_bucket_sid = in_sid_id;
	
	DELETE FROM csr.batch_job_data_bucket_agg_ind
	 WHERE data_bucket_sid = in_sid_id;
	
	DELETE FROM csr.data_bucket
	 WHERE data_bucket_sid = in_sid_id;
	
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;

PROCEDURE CreateBucket(
	in_description			IN	csr.data_bucket.description%TYPE,
	in_enabled				IN	csr.data_bucket.enabled%TYPE DEFAULT 1,
	out_data_bucket_sid		OUT	csr.data_bucket.data_bucket_sid%TYPE
)
AS
	v_parent_sid	NUMBER(10);
BEGIN
	v_parent_sid := securableobject_pkg.getSIDFromPath(security_pkg.getACT, security_pkg.getApp, 'DataBuckets');

	securableobject_pkg.CreateSO(security_pkg.getACT,
		v_parent_sid,
		class_pkg.getClassID('CSRDataBucket'),
		REPLACE(in_description,'/','\'), --'
		out_data_bucket_sid);

	INSERT INTO data_bucket
		(data_bucket_sid, description, enabled)
	VALUES
		(out_data_bucket_sid, in_description, in_enabled);

END;

PROCEDURE CreateInstance(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_job_id				IN	csr.data_bucket_instance.job_id%TYPE DEFAULT NULL,
	out_instance_id			OUT	csr.data_bucket_instance.data_bucket_instance_id%TYPE
)
AS
BEGIN
	INSERT INTO data_bucket_instance
		(data_bucket_sid, data_bucket_instance_id, job_id)
	VALUES
		(in_data_bucket_sid, DATA_BUCKET_INSTANCE_ID_SEQ.nextval, in_job_id)
	RETURNING data_bucket_instance_id INTO out_instance_id;
END;

PROCEDURE FinaliseInstance(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE
)
AS
BEGIN
	
	UPDATE data_bucket_instance
	   SET completed_dtm = SYSDATE
	 WHERE data_bucket_sid = in_data_bucket_sid
	   AND data_bucket_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	UPDATE data_bucket
	   SET active_instance_id = in_instance_id
	 WHERE data_bucket_sid = in_data_bucket_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE WriteInstanceStats(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	in_fetch_time			IN	csr.data_bucket_instance.fetch_time%TYPE,
	in_write_time			IN	csr.data_bucket_instance.write_time%TYPE
)
AS
BEGIN
	
	UPDATE data_bucket_instance
	   SET fetch_time = in_fetch_time,
		   write_time = in_write_time
	 WHERE data_bucket_sid = in_data_bucket_sid
	   AND data_bucket_instance_id = in_instance_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetBucket(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT data_bucket_sid, description, enabled, active_instance_id
		  FROM data_bucket
		 WHERE data_bucket_sid = in_data_bucket_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetBuckets(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT data_bucket_sid, description, enabled, active_instance_id
		  FROM data_bucket
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetInstance(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT data_bucket_sid, data_bucket_instance_id, completed_dtm, job_id
		  FROM data_bucket_instance
		 WHERE data_bucket_sid = in_data_bucket_sid
		   AND data_bucket_instance_id = in_instance_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
END;

PROCEDURE WriteSourceDetail(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	in_id					IN	csr.data_bucket_source_detail.id%TYPE,
	in_detail1				IN	csr.data_bucket_source_detail.detail_one%TYPE,
	in_detail2				IN	csr.data_bucket_source_detail.detail_two%TYPE,
	in_val_key				IN	csr.data_bucket_source_detail.val_key%TYPE
)
AS
BEGIN

	INSERT INTO data_bucket_source_detail
		(data_bucket_sid, data_bucket_instance_id, data_bucket_source_detail_id, 
		 id, detail_one, detail_two, val_key)
	VALUES
		(in_data_bucket_sid, in_instance_id, data_bucket_source_detail_id_seq.nextval, 
		 in_id, in_detail1, in_detail2, in_val_key);

END;

PROCEDURE WriteValue(
	in_data_bucket_sid			IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id				IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	in_ind_sid					IN	csr.data_bucket_val.ind_sid%TYPE,
	in_region_sid				IN	csr.data_bucket_val.region_sid%TYPE,
	in_period_start_dtm			IN	csr.data_bucket_val.period_start_dtm%TYPE,
	in_period_end_dtm			IN	csr.data_bucket_val.period_end_dtm%TYPE,
	in_source_type_id			IN	csr.data_bucket_val.source_type_id%TYPE,
	in_val_number				IN	csr.data_bucket_val.val_number%TYPE,
	in_val_key					IN	csr.data_bucket_val.val_key%TYPE,
	in_error_on_fk_violation	IN	NUMBER DEFAULT 0
)
AS
BEGIN
	
	BEGIN
		INSERT INTO data_bucket_val
			(data_bucket_sid, data_bucket_instance_id, data_bucket_val_id, ind_sid,
			 region_sid, period_start_dtm, period_end_dtm, source_type_id,
			 val_number, val_key)
		VALUES
			(in_data_bucket_sid, in_instance_id, data_bucket_val_id_seq.nextval, in_ind_sid,
			 in_region_sid, in_period_start_dtm, in_period_end_dtm, in_source_type_id, 
			 in_val_number, in_val_key);
	EXCEPTION
		WHEN OTHERS THEN
			IF in_error_on_fk_violation = 0 AND SQLCODE = -2291 THEN
					NULL;
				ELSE
					RAISE;
				END IF;
	END;
END;

PROCEDURE GetValsData(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT ind_sid, region_sid, period_start_dtm, period_end_dtm, 
			   csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, val_number, 
			   null error_code, val_key 
		  FROM data_bucket_val
		 WHERE data_bucket_sid = in_data_bucket_sid
		   AND data_bucket_instance_id = in_instance_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY ind_sid, region_sid, period_start_dtm;

END;

PROCEDURE GetEmptyValsData(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT NULL ind_sid, NULL region_sid, NULL period_start_dtm, NULL period_end_dtm, 
			   NULL source_type_id, NULL val_number, NULL error_code, NULL val_key 
		  FROM DUAL
		 WHERE 1 = 0; -- We want a cursor with no rows, not a row with nulls
END;

PROCEDURE GetSourceDetailsData(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		select id, detail_one detail1, detail_two detail2, val_key
		  FROM data_bucket_source_detail
		 WHERE data_bucket_sid = in_data_bucket_sid
		   AND data_bucket_instance_id = in_instance_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY val_key;

END;

PROCEDURE GetEmptySourceDetailsData(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT NULL id, NULL detail1, NULL detail2, NULL val_key
		  FROM DUAL
		 WHERE 1 = 0; -- We want a cursor with no rows, not a row with nulls

END;

FUNCTION DataBucketsEnabled
RETURN NUMBER
AS
	v_dashbuckets_container_sid		security.security_pkg.T_SID_ID;
BEGIN

	BEGIN
		v_dashbuckets_container_sid := security.securableobject_pkg.GetSidFromPath(
			in_act				=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_parent_sid_id	=> SYS_CONTEXT('SECURITY', 'APP'),
			in_path				=> 'DataBuckets'
		);
		RETURN CASE WHEN v_dashbuckets_container_sid IS NULL THEN 0 ELSE 1 END;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			RETURN 0;
	END;

END;

END data_bucket_pkg;
/
