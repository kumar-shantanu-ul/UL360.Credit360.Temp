define version=3331
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



ALTER TABLE CSR.PLUGIN ADD (ALLOW_MULTIPLE NUMBER(10, 0) DEFAULT 0);
ALTER TABLE CSR.PLUGIN ADD CONSTRAINT CK_ALLOW_MULTIPLE CHECK (ALLOW_MULTIPLE IN (1,0));
ALTER TABLE CSRIMP.PLUGIN ADD (ALLOW_MULTIPLE NUMBER(10, 0));
ALTER TABLE CSRIMP.PLUGIN ADD CONSTRAINT CK_ALLOW_MULTIPLE CHECK (ALLOW_MULTIPLE IN (1,0));










UPDATE CSR.PLUGIN
   SET allow_multiple = 1
 WHERE js_class IN ('Chain.ManageCompany.BusinessRelationshipGraph', 'Chain.ManageCompany.IntegrationSupplierDetailsTab');






@..\Chain\company_pkg
@..\superadmin_api_pkg
@..\chain\integration_pkg
@..\quick_survey_pkg
@..\property_pkg
@..\unit_test_pkg


@..\Chain\company_body
@..\superadmin_api_body
@..\enable_body
@..\plugin_body
@..\chain\integration_body
@..\quick_survey_body
@..\property_body
@..\unit_test_body



@update_tail
