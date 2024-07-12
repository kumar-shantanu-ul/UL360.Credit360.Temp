CREATE OR REPLACE PACKAGE BODY CSR.ssp_Pkg AS

FUNCTION GetNextScheduleRunDtm(
	in_schedule_run_dtm				IN scheduled_stored_proc.schedule_run_dtm%TYPE,
	in_freq							IN scheduled_stored_proc.frequency%TYPE,
	in_intrval						IN scheduled_stored_proc.intrval%TYPE
) RETURN TIMESTAMP
AS
	v_new_dtm						scheduled_stored_proc.schedule_run_dtm%TYPE;
	v_cnt							NUMBER;
	v_start							TIMESTAMP;
BEGIN
	v_new_dtm := in_schedule_run_dtm;
	v_cnt := 0;
	v_start := SYSTIMESTAMP;
	WHILE v_new_dtm < v_start AND v_cnt < 100000 LOOP
		v_new_dtm := CASE UPPER(in_intrval) WHEN 'Y' THEN ADD_MONTHS(trunc(v_new_dtm, 'MI'), 12 * in_freq) --Yearly
								  WHEN 'M' THEN ADD_MONTHS(trunc(v_new_dtm, 'MI'), in_freq) --Monthly
								  WHEN 'D' THEN trunc(v_new_dtm, 'MI') + in_freq --Daily
								  WHEN 'H' THEN trunc(v_new_dtm, 'MI') + in_freq/24 --Hourly
								  WHEN 'Q' THEN trunc(v_new_dtm, 'MI') + in_freq/96 --Quarter Hourly
					  END;
		v_cnt := v_cnt + 1;
	END LOOP;
	
	RETURN CASE WHEN v_cnt = 100000 THEN SYSDATE ELSE v_new_dtm END;
END;	

PROCEDURE MarkSSPRun (
	in_app_sid		IN scheduled_stored_proc.app_sid%TYPE,
	in_ssp_id		IN scheduled_stored_proc.ssp_id%TYPE,
	in_result		IN scheduled_stored_proc_log.result_code%TYPE,
	in_result_msg	IN scheduled_stored_proc_log.result_msg%TYPE,
	in_result_ex	IN scheduled_stored_proc_log.result_ex%TYPE,
	in_one_off		IN scheduled_stored_proc_log.one_off%TYPE DEFAULT 0,
	in_one_off_user	IN scheduled_stored_proc_log.one_off_user%TYPE DEFAULT NULL,
	in_one_off_date IN scheduled_stored_proc_log.one_off_date%TYPE DEFAULT NULL
)
AS
	v_ssp_log_id					scheduled_stored_proc_log.ssp_log_id%TYPE;
	v_new_dtm						scheduled_stored_proc.schedule_run_dtm%TYPE;
	v_retries						NUMBER;
BEGIN
	INSERT INTO scheduled_stored_proc_log (ssp_log_id, ssp_id, run_dtm, result_code, result_msg, result_ex, one_off, one_off_user, one_off_date)
	VALUES (sspl_id_seq.NEXTVAL, in_ssp_id, trunc(SYS_EXTRACT_UTC(SYSTIMESTAMP), 'MI'), in_result, in_result_msg, in_result_ex, in_one_off, in_one_off_user, in_one_off_date) 
	RETURNING ssp_log_id INTO v_ssp_log_id;
	
	v_retries := -1 * in_result;-- in_result is negative if last run failed
	
	UPDATE scheduled_stored_proc
	   SET one_off = 0, one_off_user = null, one_off_date = null,
		   last_ssp_log_id = v_ssp_log_id,
		   schedule_run_dtm = GetNextScheduleRunDtm(schedule_run_dtm, frequency, intrval),
		   next_run_dtm = CASE WHEN in_one_off = 1 AND next_run_dtm > SYSTIMESTAMP THEN trunc(next_run_dtm, 'MI')
							   WHEN v_retries > 10 THEN null
							   WHEN v_retries > 0 THEN trunc(SYS_EXTRACT_UTC(SYSTIMESTAMP), 'MI') + 1/96 * power(2, v_retries)
							   ELSE GetNextScheduleRunDtm(schedule_run_dtm, frequency, intrval)
						   END
	 WHERE app_sid = in_app_sid
	   AND ssp_id = in_ssp_id;
END;

PROCEDURE RunSP(
	in_app_sid						IN NUMBER,	
	in_ssp_id						IN NUMBER
)
AS
	v_sp				VARCHAR2(255);
	v_args				VARCHAR2(1024);
	v_result_code		NUMBER;
	v_one_off			NUMBER;
	v_one_off_user		NUMBER;
	v_one_off_date		DATE;
	
	v_res		scheduled_stored_proc_log.result_code%TYPE := 1;
	v_msg		scheduled_stored_proc_log.result_msg%TYPE := 'Success';
	v_ex		scheduled_stored_proc_log.result_ex%TYPE;
	v_act_id	security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 172800, in_app_sid, v_act_id);
	
	SELECT ssp.sp, ssp.args, ssp.one_off, ssp.one_off_user, ssp.one_off_date, NVL(sspl.result_code, 0) result_code
	  INTO v_sp, v_args, v_one_off, v_one_off_user, v_one_off_date, v_result_code 
	  FROM scheduled_stored_proc ssp
	  LEFT JOIN scheduled_stored_proc_log sspl ON ssp.app_sid = sspl.app_sid AND ssp.last_ssp_log_id = sspl.ssp_log_id
	 WHERE ssp.app_sid = in_app_sid
	   AND ssp.ssp_id = in_ssp_id;
	
	BEGIN
		EXECUTE IMMEDIATE 'BEGIN '||v_sp||'('||v_args||'); END;';
	EXCEPTION
		WHEN OTHERS THEN 
			v_msg := 'Failed';
			v_ex := sqlerrm ||chr(13)||chr(10)|| dbms_utility.format_error_backtrace;
			v_res := v_result_code - 1;
	END;
	
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 172800, in_app_sid, v_act_id);
	
	MarkSSPRun(in_app_sid, in_ssp_id, v_res, v_msg, v_ex, v_one_off, v_one_off_user, v_one_off_date);
END;

PROCEDURE RunScheduledStoredProcs
AS
	v_job_num NUMBER := 1;
BEGIN
	FOR R IN (
		SELECT ssp.app_sid,
			   ssp.ssp_id,
			   ssp.sp,
			   ssp.args,
			   ssp.one_off,
			   ssp.one_off_user,
			   ssp.one_off_date,
			   NVL(sspl.result_code, 0) result_code
		  FROM scheduled_stored_proc ssp
		  LEFT JOIN scheduled_stored_proc_log sspl ON ssp.app_sid = sspl.app_sid AND ssp.last_ssp_log_id = sspl.ssp_log_id
		 WHERE (ssp.next_run_dtm <= SYSDATE AND ssp.enabled = 1)
		    OR ssp.one_off = 1
	) LOOP
		UPDATE scheduled_stored_proc SET next_run_dtm = NULL WHERE app_sid = r.app_sid AND ssp_id = r.ssp_id;
		DBMS_JOB.SUBMIT(
			v_job_num,
			'BEGIN CSR.SSP_PKG.RUNSP('||r.app_sid||','||r.ssp_id||'); END;',
			SYSDATE
		);
		COMMIT;
	END LOOP;
END;


PROCEDURE GetScheduledStoredProcs (
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM scheduled_stored_proc
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	  
	OPEN out_cur FOR
		SELECT app_sid, ssp_id, sp, args, description, intrval, frequency, last_run_dtm, last_result_msg, next_run_dtm, one_off, enabled, schedule_run_dtm, rn
		  FROM (SELECT app_sid, ssp_id, sp, args, description, intrval, frequency, last_run_dtm, last_result_msg, next_run_dtm, one_off, enabled, schedule_run_dtm, rownum rn
				  FROM (SELECT ssp.app_sid, ssp.ssp_id, ssp.sp, ssp.args, ssp.description, ssp.intrval, ssp.frequency, ssp.one_off, ssp.enabled, ssp.schedule_run_dtm,
								sspl.run_dtm last_run_dtm, sspl.result_msg last_result_msg, ssp.next_run_dtm
						  FROM scheduled_stored_proc ssp
						  LEFT JOIN scheduled_stored_proc_log sspl ON ssp.app_sid = sspl.app_sid AND ssp.last_ssp_log_id = sspl.ssp_log_id
						 WHERE ssp.app_sid = SYS_CONTEXT('SECURITY', 'APP'))
				 WHERE rownum < in_start_row + in_page_size)
		 WHERE rn >= in_start_row;
END;

PROCEDURE SetSSPRerun (
	in_app_sid		IN customer.app_sid%TYPE,
	in_ssp_id		IN scheduled_stored_proc.ssp_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Rerun Scheduled Scripts (SSPs)') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the Rerun Scheduled Scripts (SSPs) capability.');
	END IF;
	
	UPDATE scheduled_stored_proc
	   SET one_off = 1,
		   one_off_user = SYS_CONTEXT('SECURITY', 'SID'),
		   one_off_date = SYS_EXTRACT_UTC(SYSTIMESTAMP)
	 WHERE app_sid = in_app_sid
	   AND ssp_id = in_ssp_id
	   AND one_off = 0;
END;

PROCEDURE SetEnabled (
	in_app_sid		IN customer.app_sid%TYPE,
	in_ssp_id		IN scheduled_stored_proc.ssp_id%TYPE,
	in_enabled		IN NUMBER
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(SYS_CONTEXT('SECURITY','ACT'), 'Disable Scheduled Scripts (SSPs)') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have the Disable Scheduled Scripts (SSPs) capability.');
	END IF;
		
	UPDATE scheduled_stored_proc
	   SET enabled = in_enabled,
		   next_run_dtm = DECODE(in_enabled, 1, GetNextScheduleRunDtm(schedule_run_dtm, frequency, intrval), NULL)
	 WHERE app_sid = in_app_sid
	   AND ssp_id = in_ssp_id;
END;

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
)
AS
BEGIN
	BEGIN
		INSERT INTO scheduled_stored_proc (app_sid, ssp_id, description, frequency, intrval, sp, args, schedule_run_dtm)
		VALUES (in_app_sid, ssp_id_seq.NEXTVAL, in_desc, in_freq, in_intrval, UPPER(in_schema||'.'||in_package||'.'||in_sp), in_args, in_schedule_run_dtm);
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE scheduled_stored_proc 
			   SET description = in_desc,
					frequency = in_freq,
					intrval = in_intrval,
					schedule_run_dtm = in_schedule_run_dtm
			 WHERE app_sid = in_app_sid
			   AND sp = UPPER(in_schema||'.'||in_package||'.'||in_sp)
			   AND DECODE(args, in_args, 1, 0) = 1;
	END;
END;

PROCEDURE GetLog (
	in_ssp_id						IN scheduled_stored_proc.ssp_id%TYPE,
	in_start_row					IN	NUMBER,
	in_page_size					IN	NUMBER,
	out_total_rows					OUT	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_super_admin					NUMBER;
BEGIN
	v_super_admin:= csr_user_pkg.IsSuperAdmin;
	
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM scheduled_stored_proc_log
	 WHERE ssp_id = in_ssp_id;
	
	OPEN out_cur FOR
		SELECT ssp_log_id, ssp_id, run_dtm, result_code, result_msg, result_ex, one_off, one_off_user, one_off_date, rn
		  FROM (SELECT ssp_log_id, ssp_id, run_dtm, result_code, result_msg, result_ex, one_off, one_off_user, one_off_date, rownum rn
				  FROM (SELECT ssp_log_id, ssp_id, run_dtm, result_code, result_msg, DECODE(v_super_admin, 1, result_ex, null) result_ex, one_off,
							NVL(u.full_name, one_off_user) one_off_user, one_off_date
						  FROM scheduled_stored_proc_log sspl
						  LEFT JOIN csr_user u ON sspl.one_off_user = u.csr_user_sid
						 WHERE ssp_id = in_ssp_id
						 ORDER BY run_dtm DESC)
				 WHERE rownum < in_start_row + in_page_size)
		 WHERE rn >= in_start_row;
END;

END;
/
