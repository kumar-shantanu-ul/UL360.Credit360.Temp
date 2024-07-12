define version=3452
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













INSERT INTO csr.capability (name, allow_by_default, description)
VALUES ('Prioritise sheet values in sheets', 0, 'When allowed: Use and show value from sheet if available, otherwise value from scrag. When not allowed: use scrag value first, if available');






@..\factor_pkg
@..\factor_set_group_pkg
 
@..\energy_star_pkg


@..\factor_body
@..\factor_set_group_body
@..\meter_body
@..\energy_star_body
@..\csr_app_body
@..\csrimp\imp_body
@..\csr_user_body



@update_tail
