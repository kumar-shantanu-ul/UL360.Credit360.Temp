-- Please update version.sql too -- this keeps clean builds in sync
define version=3488
define minor_version=4
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
INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Enable multi frequency variance options', 0, 'Delegations:  Enables new multi frequency variance options on delegations');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
