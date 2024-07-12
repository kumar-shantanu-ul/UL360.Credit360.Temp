-- Please update version.sql too -- this keeps clean builds in sync
define version=3206
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.issue_raise_alert ADD (issue_comment_clob CLOB);
UPDATE csr.issue_raise_alert SET issue_comment_clob = issue_comment, issue_comment = null;
ALTER TABLE csr.issue_raise_alert DROP COLUMN issue_comment;
ALTER TABLE csr.issue_raise_alert RENAME COLUMN issue_comment_clob TO issue_comment;

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
@../issue_pkg
@../issue_body

@update_tail
