define version=3488
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



ALTER TABLE CSRIMP.user_table ADD (
	JAVA_LOGIN_PASSWORD		 VARCHAR(1024),
	JAVA_AUTH_ENABLED		 NUMBER(1) DEFAULT 0 CHECK (JAVA_AUTH_ENABLED IN (0,1))
);
ALTER TABLE csr.internal_audit_listener_last_update ADD correlation_id VARCHAR2(64);
ALTER TABLE csrimp.internal_audit_listener_last_update ADD correlation_id VARCHAR2(64);
ALTER TABLE chain.integration_request ADD correlation_id VARCHAR2(64);










INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (29,'Anonymised',1);
UPDATE csr.audit_log
   SET audit_type_id = 29
 WHERE audit_type_id = 5
   AND description = 'Anonymised';
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (84, 'Recalc one Restricted', 'Resets the calc dates and queues recalc jobs for the current site/app.', 'RecalcOneRestricted', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (84, 'Start Year',' The start year.', 0, NULL, 0);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN)
VALUES (84, 'End Year', 'The end year.', 1, NULL, 0);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (26, 'Client Termination Dsv', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientXmlMappableDsvOutputter', 1, 1);
INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article) 
VALUES (77, 'Client Termination Export', 'Export terminating client data', 'TerminatedClientData', NULL);
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos, param_value)
VALUES (77, 'Setup/TearDown', '(1 Setup, 0 TearDown)', 0, '1');






@..\automated_import_pkg
@..\csr_data_pkg
@..\csr_user_pkg
@..\util_script_pkg
@..\chain\integration_pkg
@..\internal_audit_listener_pkg
@..\unit_test_pkg


@..\automated_import_body
@..\csr_user_body
@..\util_script_body
@..\schema_body
@..\csrimp\imp_body
@..\internal_audit_listener_body
@..\chain\integration_body
@..\region_api_body
@..\deleg_plan_body
@..\unit_test_body
@..\csr_data_body



@update_tail
