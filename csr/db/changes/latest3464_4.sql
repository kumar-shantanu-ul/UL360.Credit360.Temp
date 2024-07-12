-- Please update version.sql too -- this keeps clean builds in sync
define version=3464
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.ISSUE_LOG_FILE ADD ARCHIVE_FILE_ID VARCHAR2(50);
ALTER TABLE CSR.ISSUE_LOG_FILE ADD ARCHIVE_FILE_SIZE NUMBER(10);
ALTER TABLE CSR.ISSUE_LOG_FILE MODIFY SHA1 NULL;

ALTER TABLE CSRIMP.ISSUE_LOG_FILE ADD ARCHIVE_FILE_ID VARCHAR2(50);
ALTER TABLE CSRIMP.ISSUE_LOG_FILE ADD ARCHIVE_FILE_SIZE NUMBER(10);
ALTER TABLE CSRIMP.ISSUE_LOG_FILE MODIFY SHA1 NULL;

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
@../schema_pkg
@../schema_body
@../csrimp/imp_body

@update_tail
