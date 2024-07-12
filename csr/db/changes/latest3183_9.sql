-- Please update version.sql too -- this keeps clean builds in sync
define version=3183
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
 ALTER TABLE csr.customer
MODIFY display_cookie_policy DEFAULT (1);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.customer
   SET display_cookie_policy = 1
 WHERE display_cookie_policy = 0;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
