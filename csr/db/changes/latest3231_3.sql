-- Please update version.sql too -- this keeps clean builds in sync
define version=3231
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE CSR.COMPLIANCE_LANG_ID_SEQ;

CREATE TABLE CSR.COMPLIANCE_LANGUAGE (
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	COMPLIANCE_LANGUAGE_ID		NUMBER(10, 0)	NOT NULL,
	LANG_ID						NUMBER(10, 0)	NOT NULL,
	ADDED_DTM					DATE			DEFAULT SYSDATE NOT NULL,
	ACTIVE						NUMBER(1)		DEFAULT 1 NOT NULL,
	CONSTRAINT PK_COMPLIANCE_LANGUAGE PRIMARY KEY (APP_SID, COMPLIANCE_LANGUAGE_ID),
	CONSTRAINT CK_COMPLIANCE_LANGUAGE_ACTIVE CHECK (ACTIVE IN (0,1))
);


CREATE TABLE csrimp.COMPLIANCE_LANGUAGE (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	compliance_language_id		NUMBER(10, 0)	NOT NULL,
	lang_id						NUMBER(10, 0)	NOT NULL,
	added_dtm					DATE			NOT NULL,
	active						NUMBER(1)		NOT NULL,
	CONSTRAINT pk_compliance_language PRIMARY KEY (csrimp_session_id, compliance_language_id),
	CONSTRAINT ck_compliance_language_active CHECK (ACTIVE IN (0,1))
);


CREATE TABLE csrimp.map_compliance_language (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	old_compliance_language_id		NUMBER(10) NOT NULL,
	new_compliance_language_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_compliance_language PRIMARY KEY (csrimp_session_id, old_compliance_language_id),
	CONSTRAINT uk_map_compliance_language UNIQUE (csrimp_session_id, new_compliance_language_id)
);

-- Alter tables
ALTER TABLE CSRIMP.SYS_TRANSLATIONS_AUDIT_LOG MODIFY APP_SID null;

ALTER TABLE CSRIMP.TPL_REPORT_TAG DROP CONSTRAINT CT_TPL_REPORT_TAG;
ALTER TABLE CSRIMP.TPL_REPORT_TAG ADD CONSTRAINT CT_TPL_REPORT_TAG CHECK (
        (TAG_TYPE IN (1,4,5,14) AND TPL_REPORT_TAG_IND_ID IS NOT NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE = 6 AND TPL_REPORT_TAG_EVAL_ID IS NOT NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE IN (2,3,101) AND TPL_REPORT_TAG_DATAVIEW_ID IS NOT NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE = 7 AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NOT NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE = 8 AND TPL_REP_CUST_TAG_TYPE_ID IS NOT NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE = 9 AND TPL_REPORT_TAG_TEXT_ID IS NOT NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE = -1 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE = 10 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE = 11 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NOT NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE = 102 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NOT NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE = 103 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NOT NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
        OR (TAG_TYPE = 12 AND TPL_REPORT_TAG_QC_ID IS NOT NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 13 AND TPL_REPORT_TAG_SUGGESTION_ID IS NOT NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL)
    );


-- *** Grants ***

GRANT SELECT, INSERT, UPDATE ON csr.compliance_language TO csrimp;
GRANT SELECT ON csr.compliance_lang_id_seq to csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_language TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.map_compliance_language TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\compliance_pkg
@..\schema_pkg

@..\compliance_body
@..\csr_app_body
@..\enable_body
@..\schema_body

@..\csrimp\imp_body


@update_tail
