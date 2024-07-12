-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=30
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

CREATE OR REPLACE PACKAGE cms.testdata_pkg
IS
	NULL;
END;
/

GRANT EXECUTE ON cms.testdata_pkg TO csr;

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_pkg
@..\enable_body
@..\..\..\aspen2\cms\db\testdata_pkg
@..\..\..\aspen2\cms\db\testdata_body
@..\testdata_pkg
@..\testdata_body

@update_tail
