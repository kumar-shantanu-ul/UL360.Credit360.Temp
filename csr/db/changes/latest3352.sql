define version=3352
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

@../issue_body
@../meter_monitor_body













BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (117, 'Managed Content Registry UI', 'EnableManagedContentRegistryUI', 'Enables managed content registry UI.');
END;
/






@..\automated_export_pkg
@..\enable_pkg


@..\automated_export_body
@..\enable_body



@update_tail
