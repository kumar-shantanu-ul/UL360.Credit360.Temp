-- Please update version.sql too -- this keeps clean builds in sync
define version=3404
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant select, insert, update on csr.doc_folder to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\schema_pkg
@..\schema_body

@update_tail
