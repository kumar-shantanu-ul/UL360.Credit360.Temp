CREATE OR REPLACE PACKAGE CSR.Job_Pkg IS


/**
 * AddJob
 * 
 * @param in_act_id				Access token
 * @param in_prog_id			.
 * @param in_start_after_dtm	.
 * @param in_param_dic_blob		.
 */
PROCEDURE AddJob(
    in_act_id				IN  security_pkg.T_ACT_ID,
	in_prog_id				IN  JOB.prog_id%TYPE,
	in_start_after_dtm		IN  JOB.start_after_dtm%TYPE,
	in_param_dic_blob		in	JOB.param_dic_blob%TYPE
);


/**
 * GetAndStartNextJob
 * 
 * @param out_cur		The rowset
 */
PROCEDURE GetAndStartNextJob(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);



/**
 * GetJobList
 * 
 * @param in_act_id				Access token
 * @param in_filter_status		.
 * @param in_order_by			.
 * @param out_cur				The rowset
 */
PROCEDURE GetJobList(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_filter_status		IN  VARCHAR2,
	in_order_by				IN	VARCHAR2,
	out_cur					OUT Security_Pkg.T_OUTPUT_CUR
);



/**
 * MarkCompleted
 * 
 * @param in_job_id				.
 * @param in_result_code		.
 * @param in_result_message		.
 */
PROCEDURE MarkCompleted(
	in_job_id				IN JOB.JOB_ID%TYPE,
	in_result_code			IN JOB.RESULT_CODE%TYPE,
	in_result_message		IN JOB.RESULT_MESSAGE%TYPE
);


/**
 * DeleteJob
 * 
 * @param in_job_id		.
 */
PROCEDURE DeleteJob(
	in_job_id				IN JOB.JOB_ID%TYPE
);


END Job_Pkg;
/
