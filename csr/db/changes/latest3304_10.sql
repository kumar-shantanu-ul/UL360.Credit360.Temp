-- Please update version.sql too -- this keeps clean builds in sync
define version=3304
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

DELETE FROM csr.module_param WHERE module_id = 80 AND pos = 1;
DELETE FROM csr.module_param WHERE module_id = 80 AND pos = 2;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
