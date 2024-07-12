define version=3470
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

/*CREATE TABLE CSR.UPDATE_ISSUES_ERROR_TABLE (
  PROCESS_ID  VARCHAR2(38) NOT NULL,
  ISSUE_ID  NUMBER NOT NULL,
  MESSAGE  VARCHAR2(4000) NOT NULL
);*/
CREATE GLOBAL TEMPORARY TABLE CSR.TT_UPDATE_ISSUES_ERROR (
	ISSUE_ID				NUMBER NOT NULL,
	MESSAGE					VARCHAR2(4000) NOT NULL
) ON COMMIT DELETE ROWS;


ALTER TABLE CSR.AUTO_EXP_FILECREATE_DSV ADD encode_newline NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.AUTO_EXP_FILECREATE_DSV ADD CONSTRAINT CK_AUTO_EXP_FILECREATE_DSV_ENCODE_NEWLINE CHECK (ENCODE_NEWLINE IN (0, 1, 2));










INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable Actions Bulk Update', 0, 'Enable multi select and bulk update on Actions page');
INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article) 
VALUES (77, 'Client Termination Export', 'Export terminated client data', 'TerminatedClientData', NULL);
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos, param_value)
VALUES (77, 'Setup/TearDown', '(1 Setup, 0 TearDown)', 0, '1');
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos)
VALUES (77, 'Dataview sid', 'The sid of the dataview', 1);
INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id)
VALUES (26, 'Dataview - Client Termination Dsv', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.TerminatedClientExporter', 'Credit360.ExportImport.Automated.Export.Exporters.PeriodicData.DsvOutputter', 1, 1);
BEGIN
	security.user_pkg.logonadmin('sso.credit360.com');
	UPDATE aspen2.application
	   SET default_url = '/csr/sasso/login/superadminlogin.acds'
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	security.user_pkg.LogonAdmin('');
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/
BEGIN
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION)
	VALUES ('Adjust period labels to start month', 0, 'Fix period labels for default period set with non January start month');
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	security.user_pkg.logonadmin('sso-sharky.credit360.com');
	UPDATE aspen2.application
	   SET default_url = '/csr/sasso/login/superadminlogin.acds'
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	security.user_pkg.LogonAdmin('');
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/
BEGIN
	security.user_pkg.logonadmin('sso.cr360-refresh.com');
	UPDATE aspen2.application
	   SET default_url = '/csr/sasso/login/superadminlogin.acds'
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	security.user_pkg.LogonAdmin('');
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/
BEGIN
	security.user_pkg.logonadmin('sso.cat-cr360.com');
	UPDATE aspen2.application
	   SET default_url = '/csr/sasso/login/superadminlogin.acds'
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	security.user_pkg.LogonAdmin('');
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/






@..\automated_export_pkg
@..\issue_pkg
@..\chain\helper_pkg
@..\flow_pkg


@..\automated_export_body
@..\issue_body
@..\chain\helper_body
@..\delegation_body
@..\indicator_body
@..\enable_body
@..\flow_body
@..\chain\chain_body
@..\period_body



@update_tail
