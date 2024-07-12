define version=3471
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
    EXECUTE IMMEDIATE 'ALTER TABLE gt.cost_center_lookup DISABLE CONSTRAINT FK_COST_CENTER_LOOKUP_REGION';
EXCEPTION
    WHEN OTHERS THEN
        -- ORA-00942: table or view does not exist
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/










UPDATE csr.auto_exp_exporter_plugin 
   SET label = 'Client Termination Dsv',
	   exporter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientExporter',
   	   outputter_assembly = 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientXmlMappableDsvOutputter'
 WHERE plugin_id = 26;
DELETE
  FROM csr.util_script_param  
 WHERE util_script_id = 77 
   AND Param_name = 'Dataview sid';
BEGIN
	UPDATE csr.customer SET helper_assembly = NULL WHERE helper_assembly IN ('Centrica.Helper', 'Tyson.Helper');
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP)
VALUES (78, 'Toggle view source to deepest sheet', 'When enabled, viewing an issue source goes the to deepest sheet in the delegation hierarchy.', 'ToggleViewSourceToDeepestSheet');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE)
VALUES (78, 'Enable/Disable', 'Enable = 1, Disable = 0', 0, NULL);
DELETE from csr.ftp_profile
 WHERE app_sid IN (
    SELECT fp.app_sid
      FROM csr.ftp_profile fp
      LEFT JOIN csr.customer c ON c.app_sid = fp.app_sid
     WHERE c.app_sid IS NULL
);






@..\csr_user_pkg
@..\notification_pkg
@..\indicator_pkg
@..\util_script_pkg
@..\automated_export_pkg


@..\csr_user_body
@..\notification_body
@..\indicator_body
@..\util_script_body
@..\automated_export_body
@..\region_body
@..\automated_export_import_body
@..\csr_app_body
@..\flow_body



@update_tail
