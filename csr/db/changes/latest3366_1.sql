-- Please update version.sql too -- this keeps clean builds in sync
define version=3366
define minor_version=1
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
UPDATE csr.capability
   SET description = NULL
 WHERE name = 'Context Sensitive Help Management';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
