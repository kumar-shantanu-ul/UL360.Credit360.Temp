-- Please update version.sql too -- this keeps clean builds in sync
define version=3175
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.workflow_api_pkg AS
	PROCEDURE dummy;
END;
/

GRANT EXECUTE ON csr.workflow_api_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***

@..\workflow_api_pkg
@..\workflow_api_body
@..\unit_test_pkg
@..\unit_test_body
@..\tests\test_user_cover_pkg
@..\enable_body
@..\csr_app_body

@update_tail
