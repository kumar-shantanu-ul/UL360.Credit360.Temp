-- Please update version.sql too -- this keeps clean builds in sync
define version=3111
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTO_IMP_USER_IMP_SETTINGS ADD DATE_STRING_EXACT_PARSE_FORMAT VARCHAR2(255);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\automated_import_pkg
@..\automated_import_body

@update_tail
