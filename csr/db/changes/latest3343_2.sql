-- Please update version.sql too -- this keeps clean builds in sync
define version=3343
define minor_version=2
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
CREATE OR REPLACE PACKAGE csr.credentials_pkg AS
	PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.credentials_pkg AS
	PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/

GRANT EXECUTE ON csr.credentials_pkg TO web_user;


-- *** Conditional Packages ***

-- *** Packages ***
@..\credentials_pkg
@..\credentials_body

@..\automated_export_import_pkg
@..\automated_export_import_body

@update_tail
