-- Please update version.sql too -- this keeps clean builds in sync
define version=3197
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.tpl_report_variant(
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	master_template_sid				NUMBER(10, 0)	NOT NULL,
	language_code					VARCHAR2(10)	NOT NULL,
	filename						VARCHAR2(256)	NOT NULL,
	word_doc						BLOB			NOT NULL,
	CONSTRAINT pk_tpl_report_variant PRIMARY KEY (app_sid, master_template_sid, language_code)
)
;

ALTER TABLE csr.tpl_report_variant ADD CONSTRAINT fk_tpl_rep_variant_tpl_rep
	FOREIGN KEY (app_sid, master_template_sid)
	REFERENCES csr.tpl_report(app_sid, tpl_report_sid) ON DELETE CASCADE
;

ALTER TABLE csr.tpl_report_variant ADD CONSTRAINT fk_tpl_rep_variant_lang
	FOREIGN KEY (language_code)
	REFERENCES aspen2.lang(lang)
;

CREATE INDEX csr.ix_tpl_report_va_language_code ON csr.tpl_report_variant(language_code);

CREATE TABLE csrimp.tpl_report_variant(
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	master_template_sid				NUMBER(10, 0)	NOT NULL,
	language_code					VARCHAR2(10)	NOT NULL,
	filename						VARCHAR2(256)	NOT NULL,
	word_doc						BLOB			NOT NULL,
	CONSTRAINT pk_tpl_report_variant PRIMARY KEY (csrimp_session_id, master_template_sid, language_code),
	CONSTRAINT fk_tpl_report_variant_is FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session(csrimp_session_id) ON DELETE CASCADE
)
;

-- Alter tables

-- *** Grants ***

GRANT INSERT ON csr.tpl_report_variant TO csrimp;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.tpl_report_variant TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\templated_report_pkg
@..\schema_pkg

@..\templated_report_body
@..\csr_app_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
