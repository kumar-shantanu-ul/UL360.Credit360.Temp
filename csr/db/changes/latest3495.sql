define version=3495
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



UPDATE CSR.IND 
   SET TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE = NULL
 WHERE TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE IS NOT NULL;
ALTER TABLE CSR.IND MODIFY (TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE NUMBER(10,4));
UPDATE CSRIMP.IND 
   SET TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE = NULL
 WHERE TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE IS NOT NULL;
ALTER TABLE CSRIMP.IND MODIFY (TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE NUMBER(10,4));
















@..\automated_export_pkg
@..\automated_import_pkg
@..\deleg_plan_pkg
@..\csr_user_pkg
@..\region_pkg


@..\automated_export_body
@..\automated_import_body
@..\chain\company_user_body
@..\compliance_body
@..\deleg_plan_body
@..\csr_user_body
@..\user_profile_body
@..\doc_body
@..\region_body



@update_tail
