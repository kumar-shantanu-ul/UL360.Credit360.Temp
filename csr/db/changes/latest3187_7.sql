-- Please update version.sql too -- this keeps clean builds in sync
define version=3187
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

grant select on aspen2.lang to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body
@../schema_body
@../csrimp/imp_body

@update_tail
