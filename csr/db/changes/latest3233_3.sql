-- Please update version.sql too -- this keeps clean builds in sync
define version=3233
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CSR.COMPLIANCE_AUDIT_LOG (
	APP_SID							NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	COMPLIANCE_AUDIT_LOG_ID			NUMBER(10, 0)	NOT NULL,
	COMPLIANCE_ITEM_ID				NUMBER(10, 0)	NOT NULL,
	DATE_TIME						DATE			NOT NULL,
	RESPONSIBLE_USER				NUMBER(10, 0)	NOT NULL,
	USER_LANG_ID					NUMBER(10, 0),
	SYS_LANG_ID						NUMBER(10, 0)	NOT NULL,
	LANG_ID							NUMBER(10, 0),
	TITLE							VARCHAR2(1024)	NOT NULL, 
	SUMMARY							VARCHAR2(4000),
	DETAILS							CLOB,
	CITATION						VARCHAR2(4000),
	CONSTRAINT PK_COMPLIANCE_AUDIT_LOG PRIMARY KEY (APP_SID, COMPLIANCE_AUDIT_LOG_ID)
);

-- Alter tables

CREATE SEQUENCE CSR.COMPLIANCE_AUDIT_LOG_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

ALTER TABLE CSR.COMPLIANCE_AUDIT_LOG ADD CONSTRAINT FK_CAL_CI
	FOREIGN KEY (APP_SID, COMPLIANCE_ITEM_ID)
	REFERENCES CSR.COMPLIANCE_ITEM(APP_SID, COMPLIANCE_ITEM_ID)
;

CREATE INDEX csr.ix_compliance_au_compliance_it ON csr.compliance_audit_log (app_sid, compliance_item_id);

CREATE TABLE csrimp.compliance_audit_log (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	compliance_audit_log_id			NUMBER(10, 0)	NOT NULL,
	compliance_item_id				NUMBER(10, 0)	NOT NULL,
	date_time						DATE			NOT NULL,
	responsible_user				NUMBER(10, 0)	NOT NULL,
	user_lang_id					NUMBER(10, 0),
	sys_lang_id						NUMBER(10, 0)	NOT NULL,
	lang_id							NUMBER(10, 0),
	title							VARCHAR2(1024)	NOT NULL, 
	summary							VARCHAR2(4000),
	details							CLOB,
	citation						VARCHAR2(4000),
	CONSTRAINT pk_compliance_audit_log PRIMARY KEY (csrimp_session_id, compliance_audit_log_id),
	CONSTRAINT fk_cal_ci FOREIGN KEY (csrimp_session_id, compliance_item_id)
		REFERENCES csrimp.compliance_item (csrimp_session_id, compliance_item_id)
);

CREATE TABLE csrimp.map_compliance_audit_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_compliance_audit_log_id		NUMBER(10, 0)	NOT NULL,
	new_compliance_audit_log_id		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_compliance_audit_log_id PRIMARY KEY (csrimp_session_id, old_compliance_audit_log_id),
	CONSTRAINT uk_compliance_audit_log_id UNIQUE (csrimp_session_id, new_compliance_audit_log_id),
    CONSTRAINT fk_compliance_audit_log_id FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- *** Grants ***

GRANT SELECT, INSERT, UPDATE ON csr.compliance_audit_log TO csrimp;
GRANT SELECT ON csr.compliance_audit_log_id_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_audit_log TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
VALUES (89, 'Compliance item variant import', 'batch-importer', 0, 'support@credit360.com', 3, 120);

INSERT INTO csr.batched_import_type (batch_job_type_id, label, assembly)
VALUES (89, 'Compliance variant import', 'Credit360.ExportImport.Batched.Import.Importers.ComplianceVariantImporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\compliance_pkg
@..\compliance_body

@..\csr_app_body
@..\schema_pkg
@..\schema_body
@..\csrimp\imp_body

@update_tail
