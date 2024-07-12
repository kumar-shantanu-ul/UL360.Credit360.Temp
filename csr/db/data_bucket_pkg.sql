CREATE OR REPLACE PACKAGE CSR.data_bucket_pkg IS

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE CreateBucket(
	in_description			IN	csr.data_bucket.description%TYPE,
	in_enabled				IN	csr.data_bucket.enabled%TYPE DEFAULT 1,
	out_data_bucket_sid		OUT	csr.data_bucket.data_bucket_sid%TYPE
);

PROCEDURE CreateInstance(
	in_data_bucket_sid 		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_job_id				IN	csr.data_bucket_instance.job_id%TYPE DEFAULT NULL,
	out_instance_id			OUT	csr.data_bucket_instance.data_bucket_instance_id%TYPE
);

PROCEDURE FinaliseInstance(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE
);

PROCEDURE WriteInstanceStats(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	in_fetch_time			IN	csr.data_bucket_instance.fetch_time%TYPE,
	in_write_time			IN	csr.data_bucket_instance.write_time%TYPE
);

PROCEDURE GetBucket(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetBuckets(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetInstance(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE WriteSourceDetail(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	in_id					IN	csr.data_bucket_source_detail.id%TYPE,
	in_detail1				IN	csr.data_bucket_source_detail.detail_one%TYPE,
	in_detail2				IN	csr.data_bucket_source_detail.detail_two%TYPE,
	in_val_key				IN	csr.data_bucket_source_detail.val_key%TYPE
);

PROCEDURE WriteValue(
	in_data_bucket_sid 			IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id				IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	in_ind_sid					IN	csr.data_bucket_val.ind_sid%TYPE,
	in_region_sid				IN	csr.data_bucket_val.region_sid%TYPE,
	in_period_start_dtm			IN	csr.data_bucket_val.period_start_dtm%TYPE,
	in_period_end_dtm			IN	csr.data_bucket_val.period_end_dtm%TYPE,
	in_source_type_id			IN	csr.data_bucket_val.source_type_id%TYPE,
	in_val_number				IN	csr.data_bucket_val.val_number%TYPE,
	in_val_key					IN	csr.data_bucket_val.val_key%TYPE,
	in_error_on_fk_violation	IN	NUMBER DEFAULT 0
);

PROCEDURE GetValsData(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetEmptyValsData(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSourceDetailsData(
	in_data_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE,
	in_instance_id			IN	csr.data_bucket_instance.data_bucket_instance_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetEmptySourceDetailsData(
	out_cur					OUT	SYS_REFCURSOR
);

FUNCTION DataBucketsEnabled
RETURN NUMBER;

END data_bucket_pkg;
/
