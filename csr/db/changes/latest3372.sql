-- Please update version.sql too -- this keeps clean builds in sync
define version=3372
define minor_version=0
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
   SET allow_by_default = 1
WHERE name = 'Context Sensitive Help';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
