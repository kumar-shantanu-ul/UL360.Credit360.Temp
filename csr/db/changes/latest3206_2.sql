-- Please update version.sql too -- this keeps clean builds in sync
define version=3206
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant insert,update on security.home_page to csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.site_name_management_pkg AS
	PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.site_name_management_pkg AS
	PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/

GRANT EXECUTE ON csr.site_name_management_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@..\site_name_management_pkg
@..\site_name_management_body

@update_tail
