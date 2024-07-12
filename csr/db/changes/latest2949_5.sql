-- Please update version.sql too -- this keeps clean builds in sync
define version=2949
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- equivalent change already exists in \csr\db\csrimp\object_grants.sql
GRANT UPDATE ON csr.internal_audit TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\csrimp\imp_body

@update_tail
