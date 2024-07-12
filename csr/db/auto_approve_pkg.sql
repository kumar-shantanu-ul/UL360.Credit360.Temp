CREATE OR REPLACE PACKAGE CSR.auto_approve_pkg AS

PROCEDURE PostSubmit(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	delegation.start_dtm%TYPE,
	in_end_dtm			IN	delegation.end_dtm%TYPE,
	in_name				IN	delegation.name%TYPE,
	in_sheet_Id			IN	sheet.sheet_id%TYPE
);

PROCEDURE PreMerge(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	delegation.start_dtm%TYPE,
	in_end_dtm			IN	delegation.end_dtm%TYPE,
	in_name				IN	delegation.name%TYPE,
	in_sheet_Id			IN	sheet.sheet_id%TYPE
);

PROCEDURE PostReject(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	delegation.start_dtm%TYPE,
	in_end_dtm			IN	delegation.end_dtm%TYPE,
	in_name				IN	delegation.name%TYPE,
	in_sheet_Id			IN	sheet.sheet_id%TYPE
);

PROCEDURE GetDetails(
	in_batch_job_id		IN	batch_job.batch_job_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AutoApprove(
	in_sheet_id		IN 		NUMBER,
	in_user_sid		IN		security_pkg.T_SID_ID,
	in_is_valid		IN		NUMBER
);

PROCEDURE EnqueueAutoApproveSheets;

END auto_approve_pkg;
/
