CREATE OR REPLACE PACKAGE CSR.SSP_PKG AS

FUNCTION GetNextScheduleRunDtm(
	in_schedule_run_dtm				IN scheduled_stored_proc.schedule_run_dtm%TYPE,
	in_freq							IN scheduled_stored_proc.frequency%TYPE,
	in_intrval						IN scheduled_stored_proc.intrval%TYPE
) RETURN TIMESTAMP;

PROCEDURE RunSP(
	in_app_sid						IN NUMBER,
	in_ssp_id						IN NUMBER
);

PROCEDURE RunScheduledStoredProcs;

PROCEDURE GetScheduledStoredProcs (
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SetSSPRerun (
	in_app_sid						IN customer.app_sid%TYPE,
	in_ssp_id						IN scheduled_stored_proc.ssp_id%TYPE
);

PROCEDURE SetEnabled (
	in_app_sid						IN customer.app_sid%TYPE,
	in_ssp_id						IN scheduled_stored_proc.ssp_id%TYPE,
	in_enabled						IN NUMBER
);

PROCEDURE AddSSP (
	in_app_sid						IN customer.app_sid%TYPE,
	in_schema						IN VARCHAR2,
	in_package						IN VARCHAR2,
	in_sp							IN scheduled_stored_proc.sp%TYPE,
	in_args							IN scheduled_stored_proc.args%TYPE,
	in_desc							IN scheduled_stored_proc.description%TYPE,
	in_freq							IN scheduled_stored_proc.frequency%TYPE,
	in_intrval						IN scheduled_stored_proc.intrval%TYPE,
	in_schedule_run_dtm				IN scheduled_stored_proc.schedule_run_dtm%TYPE
);

PROCEDURE GetLog (
	in_ssp_id						IN scheduled_stored_proc.ssp_id%TYPE,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

END ssp_Pkg;
/
