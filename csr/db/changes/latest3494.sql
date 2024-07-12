define version=3494
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



BEGIN
	FOR r IN (
		SELECT il.issue_id, ial.issue_action_log_id
		  FROM csr.issue_action_log ial
		  JOIN csr.issue_log il ON ial.issue_log_id = il.issue_log_id
		 WHERE il.issue_id <> ial.issue_id
	)
	LOOP
		UPDATE csr.issue_action_log
		   SET issue_id = r.issue_id
		 WHERE issue_action_log_id = r.issue_action_log_id;
	END LOOP;
END;
/
ALTER TABLE CSR.ISSUE_LOG ADD CONSTRAINT UK_ISSUE_LOG_ISSUE UNIQUE (APP_SID, ISSUE_LOG_ID, ISSUE_ID);
CREATE INDEX csr.ix_issue_action__issue_log_id_ on csr.issue_action_log (app_sid, issue_log_id, issue_id);
ALTER TABLE CSR.ISSUE_ACTION_LOG ADD CONSTRAINT FK_ILI_IALI
	FOREIGN KEY (APP_SID, ISSUE_LOG_ID, ISSUE_ID)
	REFERENCES CSR.ISSUE_LOG(APP_SID, ISSUE_LOG_ID, ISSUE_ID);
BEGIN
	FOR r IN (
		SELECT *
		  FROM all_tab_columns
		 WHERE owner = 'POSTCODE'
		   AND table_name = 'COUNTRY'
		   AND column_name IN ('AREA_IN_SQKM','CONTINENT')
		   AND nullable = 'N'
	)
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE postcode.country MODIFY('||r.column_name||' NULL)';
	END LOOP;
END;
/










UPDATE csr.automated_export_instance
   SET file_generated = 1
 WHERE file_generated = 0
   AND payload is not null;






@..\automated_export_pkg
@..\automated_import_pkg
@..\unit_test_pkg


@..\enable_body
@..\automated_export_body
@..\automated_import_body
@..\meter_monitor_body
@..\util_script_body
@..\user_report_body
@..\deleg_plan_body
@..\csr_user_body
@..\dataset_legacy_body
@..\csr_app_body
@..\..\..\aspen2\cms\db\zap_body
@..\indicator_api_body
@..\unit_test_body



@update_tail
