define version=3228
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE TABLE csr.flow_editor_beta (
	app_sid				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CONSTRAINT pk_flow_editor_beta PRIMARY KEY (app_sid)
);


ALTER TABLE chain.saved_filter ADD (
	map_cluster_bias				NUMBER(2)
);
ALTER TABLE csrimp.chain_saved_filter ADD (
	map_cluster_bias				NUMBER(2)
);
ALTER TABLE csr.ftp_profile
ADD use_username_password_auth NUMBER(1) default 0 NOT NULL;










DECLARE
	v_workflow_module_id 			NUMBER(10);
BEGIN
	security.user_pkg.LogonAdmin;
	BEGIN
		SELECT module_id
		  INTO v_workflow_module_id
		  FROM csr.module
		 WHERE enable_sp = 'EnableWorkflow';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;
	
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos, allow_blank)
	VALUES (v_workflow_module_id, 'Use new editor (beta)?', 'y/n', 0, 1);
END;
/






@..\chain\filter_pkg
@..\enable_pkg
@..\flow_pkg
@..\automated_export_import_pkg


@..\integration_api_body
@..\chain\company_dedupe_body
@..\chain\setup_body
@..\schema_body
@..\csrimp\imp_body
@..\chain\filter_body
@..\enable_body
@..\flow_body
@..\campaigns\campaign_body
@..\automated_export_import_body
@..\automated_import_body
@..\automated_export_body



@update_tail
