define version=3342
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

CREATE TABLE CSR.EXTERNAL_TARGET_PROFILE_TYPE (
	PROFILE_TYPE_ID			NUMBER(10,0) NOT NULL,
	LABEL					VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_EXT_TARGET_PROF_TYPE PRIMARY KEY (PROFILE_TYPE_ID)
)
;
CREATE SEQUENCE CSR.EXTERNAL_TARGET_PROFILE_SEQ;
CREATE TABLE CSR.EXTERNAL_TARGET_PROFILE (
	APP_SID					NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	LABEL 					VARCHAR2(255) NOT NULL,
	TARGET_PROFILE_ID		NUMBER(10,0) NOT NULL,
	PROFILE_TYPE_ID			NUMBER(10,0) NOT NULL,
	SHAREPOINT_SITE			VARCHAR2(255),
	GRAPH_API_URL			VARCHAR2(255),
	SHAREPOINT_FOLDER		VARCHAR2(255),
	SHAREPOINT_TENANT_ID	VARCHAR2(255),
	CREDENTIAL_PROFILE_ID	NUMBER(10,0),
	CONSTRAINT PK_EXT_TARGET_PROF PRIMARY KEY (APP_SID, TARGET_PROFILE_ID),
	CONSTRAINT FK_EXT_TARGET_PROF_TYPE FOREIGN KEY (PROFILE_TYPE_ID) REFERENCES CSR.EXTERNAL_TARGET_PROFILE_TYPE (PROFILE_TYPE_ID)
)
;
/* No CSRIMP tables */
CREATE TABLE CSR.AUTHENTICATION_TYPE(
	AUTH_TYPE_ID			NUMBER(10, 0) NOT NULL,
	AUTH_TYPE_NAME			VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_AUTHENTICATION_ID PRIMARY KEY (AUTH_TYPE_ID),
	CONSTRAINT UK_AUTH_TYPE UNIQUE (AUTH_TYPE_NAME)
);
CREATE TABLE CSR.CREDENTIAL_MANAGEMENT (
	APP_SID						NUMBER(10, 0) 		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CREDENTIAL_ID				NUMBER(10, 0)		NOT NULL,
	LABEL						VARCHAR2(255)       NOT NULL,
    AUTH_TYPE_ID                NUMBER(10, 0)		NOT NULL,
    CREATED_DTM                 DATE                DEFAULT SYSDATE NOT NULL,
    UPDATED_DTM                 DATE                DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_CREDENTIAL_MANAGEMENT PRIMARY KEY (APP_SID, CREDENTIAL_ID),
	CONSTRAINT UK_CREDENTIAL_MANAGEMENT_LABEL UNIQUE (LABEL),
    CONSTRAINT FK_AUTH_TYPE_ID FOREIGN KEY (AUTH_TYPE_ID) REFERENCES CSR.AUTHENTICATION_TYPE(AUTH_TYPE_ID)
)
;
CREATE SEQUENCE CSR.CREDENTIAL_MANAGEMENT_ID_SEQ START WITH 1 INCREMENT BY 1 NOCYCLE CACHE 5;
CREATE INDEX csr.ix_credential_ma_auth_type_id ON csr.credential_management (auth_type_id);


ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS ADD (
  AUTO_EXP_EXTERN_TARGET_PROFILE_ID   NUMBER(10,0)
);
ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS ADD CONSTRAINT FK_AUTO_EXP_CLASS_EXT_TARGET 
FOREIGN KEY (APP_SID, AUTO_EXP_EXTERN_TARGET_PROFILE_ID) REFERENCES CSR.EXTERNAL_TARGET_PROFILE (APP_SID, TARGET_PROFILE_ID);
create index csr.ix_automated_exp_auto_exp_exte on csr.automated_export_class (app_sid, auto_exp_extern_target_profile_id);
create index csr.ix_external_targ_profile_type_ on csr.external_target_profile (profile_type_id);










INSERT INTO csr.auto_exp_file_wrtr_plugin_type (plugin_type_id, label)
VALUES (4, 'External Target');
INSERT INTO csr.auto_exp_file_writer_plugin (plugin_id, label, assembly, plugin_type_id)
VALUES (8, 'External Target', 'Credit360.ExportImport.Automated.Export.FileWrite.ExternalTargetWriter', 4);
INSERT INTO csr.external_target_profile_type (profile_type_id, label)
VALUES (1, 'SharePoint Folder (Online)');
INSERT INTO CSR.AUTHENTICATION_TYPE (AUTH_TYPE_ID, AUTH_TYPE_NAME) VALUES (1, 'Placeholder 1');
INSERT INTO CSR.AUDIT_TYPE_GROUP (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES (6, 'Application object');
INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (304,'Credential Management',6);
DECLARE
	v_act		security.security_pkg.T_ACT_ID;
	v_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT cu.app_sid, cu.csr_user_sid, w.web_root_sid_id
		  FROM csr.csr_user cu
		  JOIN security.website w ON w.application_sid_id = cu.app_sid
		 WHERE cu.user_name = 'surveyauthorisedguest'
	)
	LOOP
		BEGIN
			v_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.web_root_sid_id, 'api.regions');
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT, r.csr_user_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;
END;
/






@..\automated_export_import_pkg
@..\automated_export_pkg
@..\schema_pkg
@..\csr_data_pkg
@..\audit_pkg


@..\automated_export_import_body
@..\automated_export_body
@..\csr_app_body
@..\schema_body
@..\csr_data_body
@..\audit_body



@update_tail
