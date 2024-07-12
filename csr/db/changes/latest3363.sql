define version=3363
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;













INSERT INTO csr.module (module_id, module_name, enable_sp, description, warning_msg, license_warning)
VALUES (119, 'Framework Disclosures', 'EnableFrameworkDisclosures', 'Enable the new frameworks disclosures module', 'WARNING: Under development. Do not use on customer sites.', 1);
BEGIN
	FOR r IN (
		SELECT app_sid, host, alert_batch_run_time current_interval, 
			-- If the current interval is less than :30 then push it back to the hour. Eg
			-- 10:15 becomes 10:00
			CASE WHEN EXTRACT(MINUTE FROM alert_batch_run_time) < 30 THEN 
				alert_batch_run_time - to_dsinterval('+00 00:'|| EXTRACT(MINUTE FROM ALERT_BATCH_RUN_TIME) ||':00.000000') 
			ELSE
			-- It's after 30, so push back to :30. Eg 10:45 becomes 10:30
				ALERT_BATCH_RUN_TIME - to_dsinterval('+00 00:'|| (EXTRACT(MINUTE FROM ALERT_BATCH_RUN_TIME) - 30) ||':00.000000')
			END new_interval
		  FROM csr.customer
		 WHERE EXTRACT(MINUTE FROM ALERT_BATCH_RUN_TIME) NOT IN (0, 30)
	)
	LOOP
		UPDATE csr.customer
		   SET alert_batch_run_time = r.new_interval
		 WHERE app_sid = r.app_sid;
	END LOOP;
end;
/






@..\enable_pkg


@..\quick_survey_report_body
@..\audit_body
@..\initiative_project_body
@..\enable_body
@..\csr_user_body
@..\util_script_body
@..\issue_body
@..\initiative_body



@update_tail
