define version=3392
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
	FOR r IN (SELECT null FROM all_tab_cols WHERE owner = 'CSR' AND TABLE_NAME = 'COMPLIANCE_PERMIT_SCORE' AND COLUMN_NAME = 'LAST_PERMIT_SCORE_LOG_ID')
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.COMPLIANCE_PERMIT_SCORE DROP COLUMN LAST_PERMIT_SCORE_LOG_ID';
	END LOOP;
	
	FOR r IN (SELECT null FROM all_tab_cols WHERE owner = 'CSRIMP' AND TABLE_NAME = 'COMPLIANCE_PERMIT_SCORE' AND COLUMN_NAME = 'LAST_PERMIT_SCORE_LOG_ID')
	LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.COMPLIANCE_PERMIT_SCORE DROP COLUMN LAST_PERMIT_SCORE_LOG_ID';
	END LOOP;
END;
/


GRANT EXECUTE ON csr.dataview_pkg TO TOOL_USER;
GRANT EXECUTE ON csr.region_pkg TO TOOL_USER;
GRANT EXECUTE ON csr.img_chart_pkg TO TOOL_USER;
GRANT EXECUTE ON csr.templated_report_pkg TO TOOL_USER;








INSERT INTO csr.service_user_map(service_identifier, user_sid, full_name, can_impersonate)
		VALUES	('disclosures', 3, 'Disclosures Service user', 0);






@..\delegation_pkg
@..\audit_pkg
@..\enable_pkg
@..\img_chart_pkg
@..\templated_report_pkg


@..\excel_export_body
@..\delegation_body
@..\audit_body
@..\enable_body
@..\img_chart_body
@..\sustain_essentials_body
@..\templated_report_body



@update_tail
