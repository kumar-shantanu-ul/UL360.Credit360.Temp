-- Please update version.sql too -- this keeps clean builds in sync
define version=2934
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
DELETE FROM csr.branding_availability
 WHERE LOWER(client_folder_name) IN ('carnstone', 'greatforest');

DELETE FROM csr.branding
 WHERE LOWER(client_folder_name) IN ('carnstone', 'greatforest');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
