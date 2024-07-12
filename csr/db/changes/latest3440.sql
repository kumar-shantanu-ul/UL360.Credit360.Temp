define version=3440
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

CREATE TABLE CSR.PACKAGED_CONTENT_SITE(
	APP_SID					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	VERSION					VARCHAR2(100) NOT NULL,
	PACKAGE_NAME			VARCHAR2(1024) NOT NULL,
	ENABLED_MODULES_JSON	CLOB,
	CONSTRAINT PK_PACKAGED_CONTENT_SITE PRIMARY KEY (APP_SID)
);
CREATE TABLE CSR.PACKAGED_CONTENT_OBJECT_MAP(
	APP_SID					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	OBJECT_REF				VARCHAR2(1024) NOT NULL,
	CREATED_OBJECT_ID		NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_PACKAGED_CONTENT_OBJECT_MAP PRIMARY KEY (APP_SID, OBJECT_REF, CREATED_OBJECT_ID)
);


ALTER TABLE CSR.AUTHENTICATION_SCOPE ADD (AUTH_TYPE_ID NUMBER(10, 0));
ALTER TABLE CSR.AUTHENTICATION_SCOPE ADD CONSTRAINT FK_AUTH_SCOPE_AUTH_TYPE_ID
	FOREIGN KEY (AUTH_TYPE_ID)
	REFERENCES CSR.AUTHENTICATION_TYPE(AUTH_TYPE_ID);
ALTER TABLE CSR.CREDENTIAL_MANAGEMENT MODIFY (AUTH_SCOPE_ID NULL);
create index csr.ix_authenticatio_auth_type_id on csr.authentication_scope (auth_type_id);


GRANT EXECUTE ON csr.capability_pkg to TOOL_USER;
GRANT EXECUTE ON csr.util_script_pkg to TOOL_USER;








BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (126, 'Delegation status overview', 'EnableDelegStatusOverview', 'Enables the delegation status overview page.');
END;
/
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (127, 'Measure conversions page', 'EnableMeasureConversionsPage', 'Enable the measure conversions page.');
END;
/
BEGIN
	INSERT INTO csr.packaged_content_site
		(app_sid, version, enabled_modules_json, package_name)
	SELECT app_sid, version, enabled_modules_json, 'SustainabilityEssentials'
	  FROM csr.sustainability_essentials_enable;
END;
/
BEGIN
	INSERT INTO csr.packaged_content_object_map
		(app_sid, object_ref, created_object_id)
	SELECT app_sid, object_ref, created_object_id
	  FROM csr.sustainability_essentials_object_map;
END;
/
DROP TABLE csr.sustainability_essentials_object_map;
DROP TABLE csr.sustainability_essentials_enable;
INSERT INTO CSR.AUTHENTICATION_TYPE (AUTH_TYPE_ID, AUTH_TYPE_NAME) VALUES (2, 'API Key/Access Token');
UPDATE CSR.AUTHENTICATION_SCOPE
   SET auth_type_id = 1;
ALTER TABLE CSR.AUTHENTICATION_SCOPE MODIFY (AUTH_TYPE_ID NOT NULL);




create or replace package csr.packaged_content_pkg as
procedure dummy;
end;
/
create or replace package body csr.packaged_content_pkg as
procedure dummy
as
begin
	null;
end;
end;
/
GRANT EXECUTE ON csr.packaged_content_pkg to TOOL_USER;
DROP PACKAGE csr.sustain_essentials_pkg;


@..\unit_test_pkg
@..\enable_pkg
@..\issue_pkg
@..\util_script_pkg
@..\packaged_content_pkg
@..\baseline_pkg


@..\unit_test_body
@..\enable_body
@..\issue_body
@..\util_script_body
@..\packaged_content_body
@..\calc_body
@..\baseline_body
@..\region_certificate_body
@..\credentials_body



@update_tail
