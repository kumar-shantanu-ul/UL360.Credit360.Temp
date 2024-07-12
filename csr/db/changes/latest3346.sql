define version=3346
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

CREATE TABLE CSR.MANAGED_CONTENT_MAP(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SID                 NUMBER(10, 0)    NOT NULL,
    UNIQUE_REF          VARCHAR2(1024)    NOT NULL,
    PACKAGE_REF          VARCHAR2(1024)    NOT NULL,
    CONSTRAINT PK_MANAGED_CONTENT_MAP PRIMARY KEY (APP_SID, SID, UNIQUE_REF)
)
;
CREATE TABLE CSR.MANAGED_PACKAGE (
	APP_SID                 NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	PACKAGE_REF				VARCHAR2(1024) NOT NULL,
	PACKAGE_NAME			VARCHAR2(1024) NOT NULL,
	CONSTRAINT PK_MANAGED_PACKAGE PRIMARY KEY (APP_SID)
)
;
CREATE UNIQUE INDEX CSR.IDX_PACKAGE_REF ON CSR.MANAGED_PACKAGE(PACKAGE_REF)
;
CREATE INDEX CSR.IX_EXTERNAL_TARG_CREDENTIAL_PR ON CSR.EXTERNAL_TARGET_PROFILE (APP_SID, CREDENTIAL_PROFILE_ID);


ALTER TABLE csr.msal_user_consent_flow
DROP CONSTRAINT UK_MSAL_USR_CF_ACT_RED DROP INDEX;
DELETE FROM csr.msal_user_consent_flow;
ALTER TABLE csr.msal_user_consent_flow
ADD CONSTRAINT UK_MSAL_USR_CF_ACT UNIQUE (ACT_ID);
ALTER TABLE CSR.EXTERNAL_TARGET_PROFILE ADD CONSTRAINT FK_CREDENTIAL_ID
FOREIGN KEY (APP_SID, CREDENTIAL_PROFILE_ID)
 REFERENCES CSR.CREDENTIAL_MANAGEMENT (APP_SID, CREDENTIAL_ID);










BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (116, 'Managed Packaged Content', 'EnableManagedPackagedContent', 'Enables managed packaged content.');
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (116, 'in_package_name', 'Package name', 0);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (116, 'in_package_ref', 'Package reference', 1);
END;
/
DECLARE
	v_act	security.security_pkg.T_ACT_ID;
	v_sid	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'swagger', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (113, 'Credential Management', 'EnableCredentialManagement', 'Enable Credential Management page.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (113, 'Menu Position', 1, '-1=end, or 1 based position');




CREATE OR REPLACE PACKAGE csr.target_profile_pkg AS PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.target_profile_pkg AS PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/
GRANT EXECUTE ON csr.target_profile_pkg TO web_user;


create or replace package csr.managed_content_pkg as
	procedure dummy;
end;
/
create or replace package body csr.managed_content_pkg as
	as
	begin
		null;
	end;
end;
/
grant execute on csr.managed_content_pkg to web_user;
@..\managed_content_pkg
@..\enable_pkg
@..\automated_export_import_pkg
@..\credentials_pkg
@..\target_profile_pkg


@..\managed_content_body
@..\enable_body
@..\indicator_body
@..\initiative_report_body
@..\portlet_body
@..\automated_export_import_body
@..\credentials_body
@..\target_profile_body
@..\..\..\security\db\oracle\menu_body



@update_tail
