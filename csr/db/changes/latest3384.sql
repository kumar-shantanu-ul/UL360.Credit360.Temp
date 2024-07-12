define version=3384
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



ALTER TABLE CSR.REGION_ENERGY_RATINGS DROP COLUMN CERTIFICATE_NUMBER;
ALTER TABLE CSRIMP.REGION_ENERGY_RATINGS DROP COLUMN CERTIFICATE_NUMBER;
ALTER TABLE CSR.REGION_CERTIFICATES DROP CONSTRAINT PK_REGION_CERTS DROP INDEX;
ALTER TABLE CSR.REGION_CERTIFICATES ADD CONSTRAINT PK_REGION_CERTS PRIMARY KEY (APP_SID, REGION_SID, CERTIFICATION_ID, ISSUED_DTM, EXPIRY_DTM);
ALTER TABLE CSR.REGION_CERTIFICATES ADD CONSTRAINT FK_REG_CERT_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
ALTER TABLE CSR.REGION_ENERGY_RATINGS ADD CONSTRAINT FK_REG_ENE_RAT_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID)
;










UPDATE CSR.PLUGIN 
   SET CS_CLASS = 'Credit360.Property.Plugins.CertificationsTab'
 WHERE JS_INCLUDE = '/csr/site/property/properties/controls/CertificationsTab.js';
ALTER TABLE CSR.REGION_CERTIFICATES MODIFY FLOOR_AREA NUMBER(10,2);
ALTER TABLE CSR.REGION_ENERGY_RATINGS MODIFY FLOOR_AREA NUMBER(10,2);
ALTER TABLE CSRIMP.REGION_CERTIFICATES MODIFY FLOOR_AREA NUMBER(10,2);
ALTER TABLE CSRIMP.REGION_ENERGY_RATINGS MODIFY FLOOR_AREA NUMBER(10,2);
ALTER TABLE CSR.REGION_CERTIFICATES DROP CONSTRAINT PK_REGION_CERTS DROP INDEX;
ALTER TABLE CSR.REGION_CERTIFICATES MODIFY CERTIFICATE_NUMBER NULL;
ALTER TABLE CSR.REGION_CERTIFICATES MODIFY ISSUED_DTM NOT NULL;
ALTER TABLE CSR.REGION_CERTIFICATES ADD CONSTRAINT PK_REGION_CERTS PRIMARY KEY (APP_SID, REGION_SID, CERTIFICATION_ID, ISSUED_DTM);
ALTER TABLE CSR.REGION_ENERGY_RATINGS DROP CONSTRAINT PK_REGION_ENERGY_RAT DROP INDEX;
ALTER TABLE CSR.REGION_ENERGY_RATINGS MODIFY ISSUED_DTM NOT NULL;
ALTER TABLE CSR.REGION_ENERGY_RATINGS ADD CONSTRAINT PK_REGION_ENERGY_RAT PRIMARY KEY (APP_SID, REGION_SID);






@..\..\..\aspen2\cms\db\form_response_import_pkg
@..\chain\company_pkg
@..\sheet_pkg
@..\region_certificate_pkg


@..\..\..\aspen2\cms\db\form_response_import_body
@..\chain\company_body
@..\enable_body
@..\sheet_body
@..\delegation_body
@..\factor_set_group_body
@..\indicator_body
@..\region_body
@..\region_picker_body
@..\region_tree_body
@..\csrimp\imp_body
@..\region_certificate_body
@..\schema_body
@..\non_compliance_report_body
@..\chain\card_body



@update_tail
