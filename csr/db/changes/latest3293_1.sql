-- Please update version.sql too -- this keeps clean builds in sync
define version=3293
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.SYS_TRANSLATIONS_AUDIT_DATA(
	SYS_TRANSLATIONS_AUDIT_LOG_ID	NUMBER(10)        NOT NULL,
	AUDIT_DATE						DATE DEFAULT      SYSDATE NOT NULL,
	APP_SID							NUMBER(10,0)      DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	IS_DELETE						NUMBER(1,0)       NOT NULL,
	ORIGINAL						VARCHAR2(4000),
	TRANSLATION						VARCHAR2(4000),
	OLD_TRANSLATION					VARCHAR2(4000),
	CONSTRAINT PK_SYS_TRANS_AUDIT_DATA PRIMARY KEY (SYS_TRANSLATIONS_AUDIT_LOG_ID)
)
;

CREATE TABLE CSRIMP.SYS_TRANSLATIONS_AUDIT_DATA(
	CSRIMP_SESSION_ID				NUMBER(10)			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SYS_TRANSLATIONS_AUDIT_LOG_ID	NUMBER(10)			NOT NULL,
	AUDIT_DATE						DATE				NOT NULL,
	APP_SID							NUMBER(10,0)		NOT NULL,
	IS_DELETE						NUMBER(1,0)			NOT NULL,
	ORIGINAL						VARCHAR2(4000),
	TRANSLATION						VARCHAR2(4000),
	OLD_TRANSLATION					VARCHAR2(4000),
	CONSTRAINT PK_SYS_TRANS_AUDIT_DATA PRIMARY KEY (CSRIMP_SESSION_ID, SYS_TRANSLATIONS_AUDIT_LOG_ID),
	CONSTRAINT FK_SYS_TRANS_AUDIT_DATA FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;

-- Alter tables
ALTER TABLE CSRIMP.SYS_TRANSLATIONS_AUDIT_LOG MODIFY AUDIT_DATE DEFAULT NULL;

-- *** Grants ***
grant select,insert, update on csr.sys_translations_audit_data to csrimp;
grant select, insert, update, delete on csrimp.sys_translations_audit_data to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg

@../csrimp/imp_body
@../csr_app_body
@../schema_body

@update_tail
