-- Please update version.sql too -- this keeps clean builds in sync
define version=3472
define minor_version=5
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
DELETE FROM csr.capability 
 WHERE name = 'HAProxyTest';


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
