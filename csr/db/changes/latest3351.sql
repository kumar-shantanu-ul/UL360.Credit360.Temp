define version=3351
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



















@..\credentials_pkg
@..\meter_monitor_pkg


@..\credentials_body
@..\chain\filter_body
@..\meter_monitor_body
@..\campaigns\campaign_body
@..\csr_app_body
@..\delegation_body
@..\sheet_body
@..\user_cover_body



@update_tail
