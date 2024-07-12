-- Please update version.sql too -- this keeps clean builds in sync
define version=3456
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSRIMP.APPLICATION
  ADD BLOCK_SA_LOGON NUMBER(1) DEFAULT 0 NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
VALUES (76, 'Block non-SSO superadmin logon', 'Block superadmin logons from login page. Use with caution!', 'BlockSaLogon', NULL);

INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS, PARAM_VALUE)
VALUES (76, 'Block/unblock', '(1 block, 0 unblock)', 0, '1');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg
@..\util_script_body
@..\schema_body

@update_tail
