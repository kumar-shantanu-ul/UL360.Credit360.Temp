-- Please update version.sql too -- this keeps clean builds in sync
define version=3381
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

UPDATE csr.authentication_scope
   SET auth_scope = 'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Sites.ReadWrite.All'
 WHERE auth_scope_id = 2;
 
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
