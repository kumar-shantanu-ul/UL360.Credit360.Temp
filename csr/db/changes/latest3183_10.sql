-- Please update version.sql too -- this keeps clean builds in sync
define version=3183
define minor_version=10
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

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/type_capability_pkg

@../chain/capability_body
@../chain/type_capability_body

@update_tail
