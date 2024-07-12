CREATE OR REPLACE PACKAGE BODY CSR.Job_Pkg IS

-- if start_after_dtm is null then assume sysdate
PROCEDURE AddJob(
    in_act_id				IN  security_pkg.T_ACT_ID,
	in_prog_id				IN  JOB.prog_id%TYPE,
	in_start_after_dtm		IN  JOB.start_after_dtm%TYPE,
	in_param_dic_blob		in	JOB.param_dic_blob%TYPE
)
IS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	 user_pkg.getsid(in_act_id, v_user_sid);
	INSERT INTO JOB (job_id, prog_id, requested_by_user_sid, requested_dtm, start_after_dtm, param_dic_blob)
		   VALUES (job_id_seq.nextval, lower(in_prog_id), v_user_sid, sysdate, NVL(in_start_after_dtm, SYSDATE), in_param_dic_blob);
		   
END;


PROCEDURE GetAndStartNextJob(
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
IS
	CURSOR c IS
	  	SELECT job_id, prog_id, requested_by_user_sid, requested_dtm, param_dic_blob, start_after_dtm, started_dtm, completed_dtm 
		  FROM JOB
	     WHERE SYSDATE >= start_after_dtm 
		   AND started_dtm IS NULL FOR UPDATE;
	r	c%ROWTYPE;
BEGIN
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		-- no records found in cursor so exit with blank cursor
		OPEN out_cur FOR
			SELECT 0 job_id, null prog_id, 0 requested_by_user_sid, null param_dic_blob 
			  FROM DUAL
			 WHERE 1=0;
	ELSE
		-- records found, so mark as updated
		UPDATE JOB SET started_dtm = SYSDATE
		 WHERE CURRENT OF c;
		OPEN out_cur FOR
			SELECT r.job_id job_id, r.prog_id prog_id, r.requested_by_user_sid requested_by_user_sid, r.param_dic_blob param_dic_blob FROM DUAL;
	END IF;
	CLOSE c;
END; 


PROCEDURE GetJobList(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_filter_status		IN  VARCHAR2,
	in_order_by				IN	VARCHAR2,
	out_cur					OUT Security_Pkg.T_OUTPUT_CUR
)
AS
	v_req_user_sid		JOB.REQUESTED_BY_USER_SID%TYPE;
	v_order_by			VARCHAR2(1000);
	v_condition			VARCHAR2(200);
BEGIN
	user_pkg.GetSid(in_act_id, v_req_user_sid);

	IF in_order_by IS NOT NULL THEN
		utils_pkg.ValidateOrderBy(in_order_by, 'job_id,requested_dtm,start_after_or_started_dtm,status,result_code');
		v_order_by := ' ORDER BY ' || in_order_by;
	END IF;

	
	-- number=0 full list   number=1 completed    number=2 pending
	IF in_filter_status = 'pending' then
		v_condition := ' AND completed_dtm IS NULL AND started_dtm IS NULL ';
	ELSIF in_filter_status = 'running' THEN
		v_condition := ' AND completed_dtm IS NULL AND started_dtm IS NOT NULL ';	
	ELSIF in_filter_status = 'completed' THEN
		v_condition := ' AND completed_dtm IS NOT NULL ';
	ELSE	
		v_condition := '';
	END IF;
	
	OPEN out_cur FOR
		'SELECT job_id, requested_dtm, ' 
			||'CASE WHEN started_dtm IS NOT NULL THEN started_dtm ELSE start_after_dtm END start_after_or_started_dtm, ' 
			||'CASE WHEN TRUNC(requested_dtm)= TRUNC(SYSDATE) THEN to_char(requested_dtm,''HH24:MI'')||'' GMT'' ELSE to_char(requested_dtm, ''DD Mon yyyy HH24:MI'')||'' GMT'' END requested_dtm_fmt, '
			||'CASE WHEN started_dtm IS NOT NULL THEN '
				||'CASE WHEN TRUNC(started_dtm)= TRUNC(SYSDATE) THEN to_char(started_dtm,''HH24:MI'')||'' GMT'' ELSE to_char(started_dtm, ''DD Mon yyyy HH24:MI'')||'' GMT'' END ' 
			||'ELSE '
				||'CASE WHEN TRUNC(start_after_dtm)= TRUNC(SYSDATE) THEN to_char(start_after_dtm,''HH24:MI'')||'' GMT'' ELSE to_char(start_after_dtm, ''DD Mon yyyy HH24:MI'')||'' GMT'' END '
			||'END	start_after_or_started_dtm_fmt, '
			||'CASE WHEN TRUNC(started_dtm)= TRUNC(SYSDATE) THEN to_char(started_dtm,''HH24:MI'')||'' GMT'' ELSE to_char(started_dtm, ''DD Mon yyyy HH24:MI'')||'' GMT'' END started_dtm_fmt, '
			||'CASE WHEN completed_dtm IS NOT NULL THEN ''Completed'' WHEN started_dtm IS NOT NULL THEN ''Running'' ELSE ''Pending'' END status, '
			||'job_prog_id.description, result_code, result_message '
		  ||'FROM JOB, job_prog_id '
		  ||'WHERE requested_by_user_sid = :v_req_user_sid '||v_condition||' AND job.prog_id = job_prog_id.prog_id(+)'||v_order_by USING v_req_user_sid;
END;		 


PROCEDURE MarkCompleted(
	in_job_id				IN JOB.JOB_ID%TYPE,
	in_result_code			IN JOB.RESULT_CODE%TYPE,
	in_result_message		IN JOB.RESULT_MESSAGE%TYPE
)
IS
	CURSOR cur_job IS
		SELECT completed_dtm, result_code, result_message FROM JOB
		 WHERE job_id = in_job_id FOR UPDATE;
	rec_job		cur_job%ROWTYPE;
BEGIN
	OPEN cur_job;
	FETCH cur_job INTO rec_job;
	
	IF cur_job%NOTFOUND THEN 
	   RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_JOB_NOT_FOUND, 'Job does not exist' );
	END IF;
	
	IF rec_job.completed_dtm IS NOT NULL OR
	   rec_job.result_code IS NOT NULL THEN 
	   RAISE_APPLICATION_ERROR(-20001, 'Job already ended' );
	END IF;
	
	UPDATE JOB
		SET completed_dtm = SYSDATE,
			result_code = in_result_code,
			result_message = in_result_message
		WHERE CURRENT OF cur_job;
	CLOSE cur_job;
		
END;


PROCEDURE DeleteJob(
	in_job_id				IN JOB.JOB_ID%TYPE
)
IS
	CURSOR cur_job IS
		SELECT * FROM JOB
		 WHERE job_id = in_job_id FOR UPDATE;
	rec_job		cur_job%ROWTYPE;
BEGIN
	OPEN cur_job;
	FETCH cur_job INTO rec_job;
	
	IF cur_job%NOTFOUND THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_JOB_NOT_FOUND, 'Job does not exist');
	ELSIF rec_job.completed_dtm IS NULL AND rec_job.started_dtm IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_JOB_ALREADY_RUNNING, 'Selected job is currently running, Only Pending/Completed jobs can be deleted');
	ELSE
		DELETE FROM JOB WHERE job_id = in_job_id;
	END IF;
	CLOSE cur_job;
END;		

END;
/
