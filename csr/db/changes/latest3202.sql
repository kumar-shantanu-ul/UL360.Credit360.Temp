define version=3202
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
CREATE TABLE CSR.TPL_REPORT_VARIANT_TAG (
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TPL_REPORT_SID		NUMBER(10, 0)	NOT NULL,
	LANGUAGE_CODE		VARCHAR2(10)	NOT NULL,
	TAG					VARCHAR2(256)	NOT NULL,
	CONSTRAINT PK_TPL_REPORT_VARIANT_TAG PRIMARY KEY (APP_SID, TPL_REPORT_SID, LANGUAGE_CODE, TAG)
);
CREATE TABLE CSRIMP.TPL_REPORT_VARIANT_TAG (
	CSRIMP_SESSION_ID	NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TPL_REPORT_SID		NUMBER(10, 0)	NOT NULL,
	LANGUAGE_CODE		VARCHAR2(10)	NOT NULL,
	TAG					VARCHAR2(256)	NOT NULL,
	CONSTRAINT PK_TPL_REPORT_VARIANT_TAG PRIMARY KEY (CSRIMP_SESSION_ID, TPL_REPORT_SID, LANGUAGE_CODE),
	CONSTRAINT FK_TPL_REPORT_VARIANT_TAG_IS FOREIGN KEY (CSRIMP_SESSION_ID)
		REFERENCES CSRIMP.CSRIMP_SESSION(CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE SEQUENCE csr.scndry_region_tree_log_id_seq;
CREATE TABLE CSR.SECONDARY_REGION_TREE_LOG
(
	APP_SID 			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	LOG_ID				NUMBER(10,0) NOT NULL,
	REGION_SID			NUMBER(10, 0) NOT NULL,
	USER_SID			NUMBER(10, 0) NOT NULL,
	LOG_DTM				DATE NOT NULL,
	PRESYNC_TREE		BLOB,
	POSTSYNC_TREE		BLOB,
	CONSTRAINT PK_SCNDRY_REGION_TREE_LOG PRIMARY KEY (APP_SID, LOG_ID, REGION_SID)
);
CREATE TABLE CSRIMP.SECONDARY_REGION_TREE_LOG
(
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LOG_ID				NUMBER(10,0) NOT NULL,
	REGION_SID			NUMBER(10, 0) NOT NULL,
	USER_SID			NUMBER(10, 0) NOT NULL,
	LOG_DTM				DATE NOT NULL,
	PRESYNC_TREE		BLOB,
	POSTSYNC_TREE		BLOB,
	CONSTRAINT PK_SCNDRY_REGION_TREE_LOG PRIMARY KEY (CSRIMP_SESSION_ID, LOG_ID, REGION_SID)
);
CREATE TABLE CSRIMP.MAP_SECONDARY_REGION_TREE_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_LOG_ID NUMBER(10) NOT NULL,
	NEW_LOG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_SCNDRY_RGN_TREE_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_LOG_ID) USING INDEX,
	CONSTRAINT UK_MAP_SCNDRY_RGN_TREE_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_LOG_ID) USING INDEX,
	CONSTRAINT FK_MAP_SCNDRY_RGN_TREE_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE SEQUENCE CSR.SYS_TRANS_AUDIT_LOG_SEQ
;
CREATE TABLE CSR.SYS_TRANSLATIONS_AUDIT_LOG(
	SYS_TRANSLATIONS_AUDIT_LOG_ID	NUMBER(10)        NOT NULL,
	AUDIT_DATE						DATE DEFAULT      SYSDATE NOT NULL,
	APP_SID							NUMBER(10,0)      DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TRANSLATED_ID					NUMBER(10,0)      NOT NULL,
	USER_SID						NUMBER(10,0)      NOT NULL,
	DESCRIPTION						VARCHAR2(4000)    NOT NULL,
	CONSTRAINT PK_SYS_TRANS_AUDIT_LOG PRIMARY KEY (SYS_TRANSLATIONS_AUDIT_LOG_ID)
)
;
CREATE TABLE CSRIMP.SYS_TRANSLATIONS_AUDIT_LOG(
	CSRIMP_SESSION_ID				NUMBER(10)			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SYS_TRANSLATIONS_AUDIT_LOG_ID	NUMBER(10)			NOT NULL,
	AUDIT_DATE						DATE DEFAULT		SYSDATE NOT NULL,
	APP_SID							NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	TRANSLATED_ID					NUMBER(10,0)		NOT NULL,
	USER_SID						NUMBER(10,0)		NOT NULL,
	DESCRIPTION						VARCHAR2(4000)		NOT NULL,
	CONSTRAINT PK_SYS_TRANS_AUDIT_LOG PRIMARY KEY (CSRIMP_SESSION_ID, SYS_TRANSLATIONS_AUDIT_LOG_ID),
	CONSTRAINT FK_SYS_TRANS_AUDIT_LOG FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;
CREATE TABLE CSRIMP.MAP_SYS_TRANS_AUDIT_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SYS_TRANS_AUDIT_LOG_ID NUMBER(10) NOT NULL,
	NEW_SYS_TRANS_AUDIT_LOG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_SYS_TRANS_AUDIT_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SYS_TRANS_AUDIT_LOG_ID) USING INDEX,
	CONSTRAINT UK_MAP_SYS_TRANS_AUDIT_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_SYS_TRANS_AUDIT_LOG_ID) USING INDEX,
	CONSTRAINT FK_MAP_SYS_TRANS_AUDIT_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
)
;


ALTER TABLE CSRIMP.METER_RAW_DATA_LOG MODIFY (USER_SID NULL);
ALTER TABLE CSR.TPL_REPORT_VARIANT_TAG ADD CONSTRAINT FK_TPL_REPORT_VARIANT 
	FOREIGN KEY (APP_SID, TPL_REPORT_SID, LANGUAGE_CODE) 
	REFERENCES CSR.TPL_REPORT_VARIANT(APP_SID, MASTER_TEMPLATE_SID, LANGUAGE_CODE)
	ON DELETE CASCADE;
ALTER TABLE CSR.TPL_REPORT_VARIANT ADD (
	MIME_TYPE			VARCHAR2(255)
);
ALTER TABLE CSRIMP.TPL_REPORT_VARIANT ADD (
	MIME_TYPE			VARCHAR2(255)
);
ALTER TABLE csr.secondary_region_tree_ctrl DROP CONSTRAINT pk_secondary_region_tree_log DROP INDEX;
ALTER TABLE csr.secondary_region_tree_ctrl ADD CONSTRAINT pk_secondary_region_tree_ctrl
	PRIMARY KEY (app_sid, region_sid)
;
ALTER TABLE csrimp.secondary_region_tree_ctrl DROP CONSTRAINT pk_secondary_region_tree_log DROP INDEX;
ALTER TABLE csrimp.secondary_region_tree_ctrl ADD CONSTRAINT pk_secondary_region_tree_ctrl
	PRIMARY KEY (csrimp_session_id, region_sid)
;
ALTER TABLE csr.secondary_region_tree_log ADD CONSTRAINT fk_scndry_rgn_tree_log_region
	FOREIGN KEY (app_sid, region_sid)
	REFERENCES csr.region(app_sid, region_sid)
;
ALTER TABLE csr.secondary_region_tree_log ADD CONSTRAINT fk_scndry_rgn_tree_log_user
	FOREIGN KEY (app_sid, user_sid)
	REFERENCES csr.csr_user (app_sid, csr_user_sid)
;
ALTER TABLE csr.secondary_region_tree_ctrl ADD active_only NUMBER(1) DEFAULT NULL;
ALTER TABLE csr.secondary_region_tree_ctrl ADD CONSTRAINT ck_srt_active_only CHECK (active_only IN (1,0));
ALTER TABLE csrimp.secondary_region_tree_ctrl ADD active_only NUMBER(1);
ALTER TABLE csrimp.secondary_region_tree_ctrl ADD CONSTRAINT ck_srt_active_only CHECK (active_only IN (1,0));
ALTER TABLE csr.secondary_region_tree_ctrl ADD ignore_sids CLOB DEFAULT NULL;
ALTER TABLE csrimp.secondary_region_tree_ctrl ADD ignore_sids CLOB DEFAULT NULL;
create index csr.ix_scndry_reg_log_user_sid on csr.secondary_region_tree_log (app_sid, user_sid);
create index csr.ix_scndry_reg_log_region_sid on csr.secondary_region_tree_log (app_sid, region_sid);


GRANT INSERT ON csr.tpl_report_variant_tag TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.tpl_report_variant_tag TO tool_user;
GRANT INSERT ON csr.secondary_region_tree_log TO csrimp;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.secondary_region_tree_log TO tool_user;
CREATE TABLE CSR.BATCH_JOB_SRT_REFRESH
(
	APP_SID 			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BATCH_JOB_ID		NUMBER(10,0)	NOT NULL,
	REGION_SID			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_BATCH_JOB_SRT_REFRESH PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);
GRANT SELECT ON csr.scndry_region_tree_log_id_seq TO csrimp;
GRANT SELECT, UPDATE, DELETE ON aspen2.translated TO csr;
GRANT SELECT, DELETE ON aspen2.translation TO csr;
GRANT SELECT ON csr.sys_trans_audit_log_seq to csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.sys_translations_audit_log TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.sys_translations_audit_log TO tool_user;








BEGIN
	-- For all sites...
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
		security.user_pkg.logonadmin(r.host);
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID;
			v_app_sid 					security.security_pkg.T_SID_ID;
			v_menu						security.security_pkg.T_SID_ID;
			v_clientconnect_menu		security.security_pkg.T_SID_ID;
			v_support_menu				security.security_pkg.T_SID_ID;
			v_other_menu				security.security_pkg.T_SID_ID;
			v_admin_menu				security.security_pkg.T_SID_ID;
		BEGIN
			v_act_id := security.security_pkg.GetAct;
			v_app_sid := security.security_pkg.GetApp;
			v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			BEGIN
				v_clientconnect_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'client_connect');
				security.securableobject_pkg.DeleteSO(v_act_id, v_clientconnect_menu);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
			BEGIN
				-- client_connect on these sites is not at the top level menu
				--crdemo.credit360.com (other)
				--cr360.credit360.com (other)
				--techsupport.credit360.com (other)
				--tsupport.credit360.com (other)
				v_other_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'other');
				v_clientconnect_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_other_menu, 'client_connect');
				security.securableobject_pkg.DeleteSO(v_act_id, v_clientconnect_menu);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
			BEGIN
				v_support_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'support');
				security.securableobject_pkg.DeleteSO(v_act_id, v_support_menu);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
			BEGIN
				-- support (/owl/support/overview.acds) on these sites is not at the top level menu
				--mcdonalds-nalc.credit360.com (admin)
				v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'admin');
				v_support_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'support');
				security.securableobject_pkg.DeleteSO(v_act_id, v_support_menu);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			END;
		END;
	END LOOP;
	-- clear the app_sid
	security.user_pkg.logonadmin;
END;
/
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (84, 'Secondary Region Tree Refresh', null, 'secondary-region-tree-refresh', 0, null, 120);
END;
/






@..\customer_pkg
@..\..\..\aspen2\cms\db\upload_pkg
@..\csrimp\imp_pkg
@..\schema_pkg
@..\templated_report_pkg
@..\batch_job_pkg
@..\region_tree_pkg


@..\property_body
@..\user_profile_body
@..\customer_body
@..\..\..\aspen2\cms\db\upload_body
@..\csr_app_body
@..\schema_body
@..\templated_report_body
@..\csrimp\imp_body
@..\factor_body
@..\enable_body
@..\region_tree_body
@..\region_body
@..\delegation_body



@update_tail
