-- Please update version.sql too -- this keeps clean builds in sync
define version=3156
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.AUTO_IMPEXP_PUBLIC_KEY(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	PUBLIC_KEY_ID		NUMBER(10, 0)	NOT NULL,
	LABEL				VARCHAR2(255)	NOT NULL,
	KEY_BLOB			BLOB			NOT NULL,
	CONSTRAINT PK_AUTO_IMP_PUBLIC_KEY_ID PRIMARY KEY (PUBLIC_KEY_ID),
	CONSTRAINT UK_AUTO_IMP_PUBLIC_KEY_LABEL UNIQUE (APP_SID, LABEL)
);

CREATE SEQUENCE CSR.AUTO_IMPEXP_PUBLIC_KEY_ID_SEQ;

CREATE TABLE CSR.PUBLIC_KEY_LOG (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	PUBLIC_KEY_ID			NUMBER(10) 		NOT NULL,
	CHANGED_DTM				DATE 			NOT NULL,
	CHANGED_BY_USER_SID		NUMBER(10) 		NOT NULL,
	MESSAGE					VARCHAR2(1024)	NOT NULL,
	FROM_KEY_BLOB			BLOB,
	TO_KEY_BLOB				BLOB
)
;

CREATE INDEX CSR.IDX_PUBLIC_KEY_LOG ON CSR.PUBLIC_KEY_LOG(APP_SID)
;

-- Alter tables

ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS ADD AUTO_IMPEXP_PUBLIC_KEY_ID NUMBER(10, 0) DEFAULT NULL;
ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS ADD ENABLE_ENCRYPTION NUMBER(1,0) DEFAULT 0;

ALTER TABLE CSR.AUTOMATED_IMPORT_CLASS_STEP ADD ENABLE_DECRYPTION NUMBER(1,0) DEFAULT 0;

ALTER TABLE CSR.AUTOMATED_EXPORT_CLASS ADD CONSTRAINT FK_AUTO_IMPEXP_PUBLIC_KEY_ID
		FOREIGN KEY (AUTO_IMPEXP_PUBLIC_KEY_ID)
		REFERENCES CSR.AUTO_IMPEXP_PUBLIC_KEY (PUBLIC_KEY_ID);

CREATE INDEX csr.ix_automated_exp_auto_impexp_p ON csr.automated_export_class (auto_impexp_public_key_id);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg
@../automated_export_pkg
@../automated_export_import_pkg

@../automated_import_body
@../automated_export_body
@../automated_export_import_body

@update_tail
