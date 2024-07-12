-- Please update version.sql too -- this keeps clean builds in sync
define version=3296
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.SHEET_VALUE_FILE_HIDDEN_CACHE(
    APP_SID                        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHEET_VALUE_ID                 NUMBER(10, 0)     NOT NULL,
	FILE_UPLOAD_SID                NUMBER(10,0)      NOT NULL,
    CONSTRAINT PK_SVFHC PRIMARY KEY (APP_SID, SHEET_VALUE_ID, FILE_UPLOAD_SID)
)
;

CREATE TABLE CSRIMP.SHEET_VALUE_FILE_HIDDEN_CACHE(
    APP_SID                        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHEET_VALUE_ID                 NUMBER(10, 0)     NOT NULL,
	FILE_UPLOAD_SID                NUMBER(10,0)      NOT NULL,
    CONSTRAINT PK_SVFHC PRIMARY KEY (APP_SID, SHEET_VALUE_ID, FILE_UPLOAD_SID)
)
;

-- Alter tables
ALTER TABLE CSR.SHEET_VALUE_FILE_HIDDEN_CACHE ADD CONSTRAINT FK_SVFHC_FU
    FOREIGN KEY (APP_SID, FILE_UPLOAD_SID)
    REFERENCES CSR.FILE_UPLOAD(APP_SID, FILE_UPLOAD_SID)
;

ALTER TABLE CSR.SHEET_VALUE_FILE_HIDDEN_CACHE ADD CONSTRAINT FK_SVFHC_SV
    FOREIGN KEY (APP_SID, SHEET_VALUE_ID)
    REFERENCES CSR.SHEET_VALUE(APP_SID, SHEET_VALUE_ID)
;

CREATE INDEX CSR.IX_SVFHC_FU ON CSR.SHEET_VALUE_FILE_HIDDEN_CACHE(APP_SID, FILE_UPLOAD_SID);
CREATE INDEX CSR.IX_SVFHC_SV ON CSR.SHEET_VALUE_FILE_HIDDEN_CACHE(APP_SID, SHEET_VALUE_ID);

-- *** Grants ***
GRANT INSERT ON CSR.SHEET_VALUE_FILE_HIDDEN_CACHE TO CSRIMP;
GRANT INSERT,SELECT,UPDATE,DELETE ON CSRIMP.SHEET_VALUE_FILE_HIDDEN_CACHE TO TOOL_USER;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../delegation_pkg
@../schema_pkg
@../sheet_pkg

@../csr_app_body
@../delegation_body
@../deleg_admin_body
@../schema_body
@../sheet_body
@../csrimp/imp_body

@update_tail
