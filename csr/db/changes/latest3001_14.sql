-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=14
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

DELETE FROM csr.branding_availability
 WHERE client_folder_name = 'bidvest';

DELETE FROM csr.branding
 WHERE client_folder_name = 'bidvest';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
