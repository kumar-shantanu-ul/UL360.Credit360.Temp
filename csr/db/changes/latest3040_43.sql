-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=43
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

grant select, insert, update on csr.internal_audit_score to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
