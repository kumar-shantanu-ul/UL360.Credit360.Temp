define version=3370
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



ALTER SEQUENCE CSR.METER_DATA_ID_SEQ NOCACHE;
















@..\csr_data_pkg


@..\audit_body
@..\csr_data_body
@..\meter_processing_job_body
@..\enable_body
@..\chain\company_body



@update_tail
