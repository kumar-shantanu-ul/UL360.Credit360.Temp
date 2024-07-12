define version=3422
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



ALTER TABLE CSR.PROJECT_INITIATIVE_METRIC DROP CONSTRAINT FK_PRJ_PRJ_INIT_MET DROP INDEX;
ALTER TABLE CSR.PROJECT_INITIATIVE_METRIC ADD CONSTRAINT FK_PRJ_PRJ_INIT_MET 
    FOREIGN KEY (APP_SID, PROJECT_SID, FLOW_SID)
    REFERENCES CSR.INITIATIVE_PROJECT(APP_SID, PROJECT_SID, FLOW_SID)
    DEFERRABLE INITIALLY DEFERRED;
alter table csr.automated_export_class add lookup_key varchar2(32);
alter table csr.automated_export_class add last_fetched_date date;
alter table csr.automated_export_class add fetched_count number(10) default 0 not null;
alter table csr.automated_export_instance add file_generated number(1,0) default 0 not null;










BEGIN
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (4, 0, 'COMMENT', 'Sheet return comment', 'The comment made on the returned delegation sheet.', 13);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (57, 0, 'COMMENT', 'Sheet return comment', 'The comment made on the returned delegation sheet.', 13);
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (124, 'Scheduled Export API', 'EnableScheduledExportApi', 'Enables/Disables Scheduled Export API');
INSERT INTO CSR.MODULE_PARAM (MODULE_ID, PARAM_NAME, POS, PARAM_HINT)
	VALUES (124, 'Enable/Disable', 1, '0=disable, 1=enable');
DECLARE
	v_act	security.security_pkg.T_ACT_ID;
	v_sid	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.scheduledExport', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/
BEGIN
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (29, 0, 'ACTION_SHEET_URL', 'Action sheet link', 'A hyperlink to the sheet where the data change request was made.', 13);
END;
/
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
VALUES (94, 'Alert bounce export', 'batch-exporter', 0, 'support@credit360.com', 3, 120);
INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (94, 'Alert bounce export', 'Credit360.ExportImport.Export.Batched.Exporters.AlertBounceExporter');
UPDATE chain.capability
   SET description = 'Allows users to promote a company user to a company administrator and (combined with "Remove user from company") remove administrators from the company on the Company users page. Also provides access to the "User''s roles" checkboxes on the page, allowing them to view/assign roles to the user.'
 WHERE capability_name = 'Promote user';
 
UPDATE chain.capability
   SET description = 'Allows users to view and edit the "User account is active" and "Send email alerts" checkboxes when editing user details, controlling whether the user account is active and whether the user receives email alerts.'
 WHERE capability_name = 'Manage user';






@..\deleg_plan_pkg
@..\delegation_pkg
@..\initiative_project_pkg
@..\automated_export_pkg
@..\enable_pkg
@..\indicator_pkg
@..\initiative_report_pkg
@..\alert_pkg


@..\deleg_plan_body
@..\fileupload_body
@..\delegation_body
@..\initiative_project_body
@..\automated_export_body
@..\enable_body
@..\indicator_body
@..\cms_import_body
@..\initiative_report_body
@..\sustain_essentials_body
@..\alert_body



@update_tail
