define version=3469
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





GRANT EXECUTE ON csr.t_split_table TO csrimp;
GRANT EXECUTE ON aspen2.t_split_table TO csrimp;












CREATE OR REPLACE PACKAGE cms.zap_pkg IS END;
/
grant execute on cms.zap_pkg to csr;


@..\core_access_pkg
@..\csr_user_pkg
@..\..\..\aspen2\db\utils_pkg
@..\schema_pkg
@..\..\..\aspen2\cms\db\zap_pkg
@..\zap_pkg
@..\flow_pkg


@..\core_access_body
@..\csr_user_body
@..\audit_body
@..\..\..\aspen2\db\utils_body
@..\csrimp\imp_body
@..\schema_body
@..\..\..\aspen2\cms\db\zap_body
@..\zap_body
@..\factor_set_group_body
@..\audit_report_body
@..\region_body
@..\factor_body
@..\flow_body
@..\ssp_body
@..\csr_app_body



@update_tail
