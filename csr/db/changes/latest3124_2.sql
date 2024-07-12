-- Please update version.sql too -- this keeps clean builds in sync
define version=3124
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- Update all clients to use the new folders import page.
UPDATE security.menu 
   SET action = '/csr/site/imp/foldered/sessions2.acds'
 WHERE action = '/csr/site/imp/sessions.acds';


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
