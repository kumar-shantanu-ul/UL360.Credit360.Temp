-- Please update version.sql too -- this keeps clean builds in sync
define version=3498
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT, UPDATE, REFERENCES ON cms.tab_column TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_pkg

@../core_access_pkg
@../core_access_body

@update_tail

