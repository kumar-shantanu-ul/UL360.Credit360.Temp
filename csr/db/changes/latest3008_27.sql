-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=27
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
BEGIN
  security.user_pkg.logonadmin('');	
  UPDATE csr.ind
     SET IS_SYSTEM_MANAGED = 1
   WHERE parent_sid IN (SELECT app_sid FROM csr.customer);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body

@update_tail
