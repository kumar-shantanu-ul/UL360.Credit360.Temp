define version=3426
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



alter table csr.automated_export_class drop column last_fetched_date;
alter table csr.automated_export_class drop column fetched_count;
alter table csr.automated_export_instance add last_fetched_date date;
alter table csr.automated_export_instance add fetched_count number(10) default 0 not null;










INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('HAProxyTest', 0, 'Use the test HAProxy IP address (internal use only).');






@..\csr_data_pkg
@..\automated_export_pkg


@..\region_metric_body
@..\meter_body
@..\chain\company_user_body
@..\chain\company_body
@..\automated_export_body
@..\audit_body



@update_tail
