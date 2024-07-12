-- Please update version.sql too -- this keeps clean builds in sync
define version=3469
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
/*CREATE TABLE CSR.UPDATE_ISSUES_ERROR_TABLE (
  PROCESS_ID  VARCHAR2(38) NOT NULL,
  ISSUE_ID  NUMBER NOT NULL,
  MESSAGE  VARCHAR2(4000) NOT NULL
);*/
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Enable Actions Bulk Update', 0, 'Enable multi select and bulk update on Actions page');
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../issue_pkg
@../issue_body


@update_tail
