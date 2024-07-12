define version=3349
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

CREATE TABLE CSR.MANAGED_CONTENT_MEASURE_CONVERSION_MAP(
	APP_SID 				NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL, 
	CONVERSION_ID			NUMBER(10,0) NOT NULL, 
	UNIQUE_REF 				VARCHAR2(1024) NOT NULL, 
	PACKAGE_REF 			VARCHAR2(1024) NOT NULL, 
	CONSTRAINT PK_MANAGED_CONTENT_MC_MAP PRIMARY KEY (APP_SID, CONVERSION_ID, UNIQUE_REF)
);


ALTER TABLE csr.external_target_profile DROP (graph_api_url, sharepoint_tenant_id);
CREATE TABLE csr.external_target_profile_log (
	app_sid						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	target_profile_id			NUMBER(10) 		NOT NULL,
	changed_dtm					DATE 			NOT NULL,
	changed_by_user_sid			NUMBER(10) 		NOT NULL,
	message						VARCHAR2(4000) 	NOT NULL
);
CREATE INDEX csr.idx_ext_target_profile_log ON csr.external_target_profile_log(app_sid);
ALTER TABLE csr.credential_management ADD (
	login_hint	VARCHAR2(500) 
);
ALTER TABLE csr.credential_management DROP CONSTRAINT UK_CREDENTIAL_MANAGEMENT_LABEL DROP INDEX;
ALTER TABLE csr.credential_management ADD CONSTRAINT UK_CREDENTIAL_MANAGEMENT_LABEL UNIQUE (app_sid, label);

@..\indicator_api_pkg
@..\managed_content_pkg
@..\target_profile_pkg
@..\credentials_pkg


@..\measure_body
@..\indicator_api_body
@..\managed_content_body
@..\target_profile_body
@..\issue_body
@..\credentials_body
@..\scrag_pp_body



@update_tail
