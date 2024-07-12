-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=24
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
UPDATE csr.module
   SET license_warning = 1
 WHERE module_id in (20, 58, 60, 68, 69, 70);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
