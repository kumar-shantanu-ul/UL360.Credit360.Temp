define version=3314
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





grant select on csr.v$csr_user to campaigns;








INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_ID, LABEL, AUDIT_TYPE_GROUP_ID ) VALUES (203, 'Chain Filter', 4);
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	 VALUES (111, 'Audits API', 'EnableAuditsApi', 'Enable Audits API');
UPDATE csr.initiatives_options
  SET metrics_end_year = 2030
 WHERE metrics_end_year < 2030;






@..\csr_data_pkg
@..\compliance_pkg
@..\enable_pkg


@..\chain\filter_body
@..\compliance_body
@..\deleg_plan_body
@..\campaigns\campaign_body
@..\chem\report_body.sql
@..\automated_export_body
@..\enable_body



@update_tail
