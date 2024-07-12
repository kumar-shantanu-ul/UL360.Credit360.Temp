-- Please update version.sql too -- this keeps clean builds in sync
define version=3389
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE cms.form_response ADD info_msg CLOB;

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
@../../../aspen2/cms/db/form_response_import_pkg
@../../../aspen2/cms/db/form_response_import_body

@update_tail
