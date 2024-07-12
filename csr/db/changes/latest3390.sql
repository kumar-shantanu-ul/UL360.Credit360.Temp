define version=3390
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

CREATE TABLE CSR.EXCEL_EXPORT_OPTIONS_TAG_GROUP(
	APP_SID			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP'),
	DATAVIEW_SID	NUMBER(10, 0)	NOT NULL,
	APPLIES_TO		NUMBER			NOT NULL,
	TAG_GROUP_ID	NUMBER			NOT NULL,
	CONSTRAINT PK_EXCEL_EXPORT_OPTIONS_TG PRIMARY KEY (APP_SID, DATAVIEW_SID, APPLIES_TO, TAG_GROUP_ID),
	CONSTRAINT CHK_EXCEL_EXPORT_OPTIONS_AT CHECK (APPLIES_TO IN (1,2))
)
;
CREATE TABLE CSRIMP.EXCEL_EXPORT_OPTIONS_TAG_GROUP(
	CSRIMP_SESSION_ID			NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DATAVIEW_SID				NUMBER(10, 0)	NOT NULL,
	APPLIES_TO					NUMBER			NOT NULL,
	TAG_GROUP_ID				NUMBER			NOT NULL,
	CONSTRAINT PK_EXCEL_EXPORT_OPTIONS_TG PRIMARY KEY (CSRIMP_SESSION_ID, DATAVIEW_SID, APPLIES_TO, TAG_GROUP_ID),
	CONSTRAINT CHK_EXCEL_EXPORT_OPTIONS_AT CHECK (APPLIES_TO IN (1,2)),
	CONSTRAINT FK_EXCEL_EXPORT_OPTIONS_TAG_GROUP_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);


ALTER TABLE csr.flow_item ADD (
	auto_failure_count	NUMBER(4) DEFAULT 0 NOT NULL
);
ALTER TABLE cms.form_response ADD info_msg CLOB;
ALTER TABLE CSR.EXCEL_EXPORT_OPTIONS_TAG_GROUP ADD CONSTRAINT FK_EE_OPTIONS_TG_EE_OPTIONS
	FOREIGN KEY (APP_SID, DATAVIEW_SID)
	REFERENCES CSR.EXCEL_EXPORT_OPTIONS(APP_SID, DATAVIEW_SID)
;
ALTER TABLE CSR.EXCEL_EXPORT_OPTIONS_TAG_GROUP ADD CONSTRAINT FK_EE_OPTIONS_TG_TAG_GROUP
	FOREIGN KEY (APP_SID, TAG_GROUP_ID)
	REFERENCES CSR.TAG_GROUP(APP_SID, TAG_GROUP_ID)
;
ALTER TABLE CSRIMP.REGION_ENERGY_RATING MODIFY (ISSUED_DTM NULL);
CREATE INDEX csr.ix_excel_export__tag_group_id ON csr.excel_export_options_tag_group (app_sid, tag_group_id);


grant insert on csr.excel_export_options_tag_group to csrimp;
grant select,insert,update,delete on csrimp.excel_export_options_tag_group to tool_user;








INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(3001, 'disclosure', 'Disclosure response', 0 /*Specific*/, 1 /*READ*/);






@..\audit_pkg
@..\issue_pkg
@..\flow_pkg
@..\..\..\aspen2\cms\db\form_response_import_pkg
@..\csr_data_pkg
@..\excel_export_pkg
@..\schema_pkg


@..\audit_body
@..\issue_body
@..\quick_survey_body
@..\flow_body
@..\..\..\aspen2\cms\db\form_response_import_body
@..\delegation_body
@..\enable_body
@..\deleg_plan_body
@..\csr_app_body
@..\excel_export_body
@..\dataview_body
@..\schema_body
@..\csrimp\imp_body
@..\automated_export_body



@update_tail
