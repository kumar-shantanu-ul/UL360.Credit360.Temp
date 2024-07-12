CREATE OR REPLACE PACKAGE BODY CSR.system_status_pkg AS

PROCEDURE GetCalcJobs(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('System management') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "System management" capability');
	END IF;

	OPEN out_cur FOR
		SELECT cj.calc_job_id, cj.phase, cj.phase_description, cj.work_done, cj.total_work, cj.calc_job_type, 
			   sr.description scenario_run_description, cj.updated_dtm
		  FROM csr.v$calc_job cj
		  LEFT JOIN csr.scenario_run sr ON cj.app_sid = sr.app_Sid AND cj.scenario_run_sid = sr.scenario_run_sid
		 WHERE cj.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 UNION ALL
		SELECT 0 calc_job_id, 0 phase, 'Pending job creation', 0 work_done, COUNT(*) total_work, 0 data_source,
			   null scenario_run_description, SYSDATE updated_dtm
		  FROM (SELECT 1
				  FROM val_change_log
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION ALL
				SELECT 1
				  FROM aggregate_ind_calc_job
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION ALL
				SELECT 1
				  FROM sheet_val_change_log
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION ALL
				SELECT 1
				  FROM scenario_man_run_request
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION ALL
				SELECT 1
				  FROM scenario_auto_run_request
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'))
		 ORDER BY calc_job_id;
END;

END system_status_pkg;
/
