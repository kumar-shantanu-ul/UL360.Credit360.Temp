define version=3481
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

CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm,
		   ut.language, ut.culture, ut.timezone, so.parent_sid_id, cu.last_modified_dtm, cu.last_logon_type_Id, cu.line_manager_sid, cu.primary_region_sid,
		   cu.enable_aria, cu.user_ref, cu.anonymised
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;
	   












DECLARE
v_anonymise_capability				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_anonymise_capability
	  FROM csr.capability
	 WHERE name = 'Anonymise PII data';
	
	IF v_anonymise_capability = 0 THEN
		INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Anonymise PII data', 1, 'When enabled, this capability will be granted to the Admin group. Subsequently, please run the existing utilscript to grant this capability to Superadmins instead.');
	ELSE
		UPDATE csr.capability 
		   SET description = 'When enabled, this capability will be granted to the Admin group. Subsequently, please run the existing utilscript to grant this capability to Superadmins instead.'
		 WHERE name = 'Anonymise PII data';
	END IF;
END;
/
BEGIN
    INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
    VALUES (13, 'Stored Procedure - Dsv', 'Credit360.ExportImport.Automated.Export.Exporters.StoredProcedure.StoredProcedureExporter', 'Credit360.ExportImport.Automated.Export.Exporters.StoredProcedure.StoredProcedureDsvOutputter', 1, 4);
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
DELETE FROM csr.auto_imp_fileread_ftp
 WHERE auto_imp_fileread_ftp_id IN (
    SELECT f.auto_imp_fileread_ftp_id FROM csr.auto_imp_fileread_ftp f
      LEFT JOIN csr.automated_import_class_step s ON s.auto_imp_fileread_ftp_id = f.auto_imp_fileread_ftp_id
     WHERE s.auto_imp_fileread_ftp_id IS NULL
)
;






@..\csr_user_pkg
@..\indicator_pkg


@..\automated_Import_body
@..\zap_body
@..\schema_body
@..\enable_body
@..\meter_monitor_body
@..\like_for_like_body
@..\chain\company_filter_body
@..\csr_user_body
@..\user_report_body
@..\indicator_body
@..\factor_body



@update_tail
