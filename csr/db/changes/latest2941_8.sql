-- Please update version.sql too -- this keeps clean builds in sync
define version=2941
define minor_version=8
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

-- Remove all instances of the capability 'Edit user line manager' (no longer in use).
DELETE FROM security.securable_object
 WHERE name = 'Edit user line manager' AND
       class_id = (SELECT class_id FROM security.securable_object_class
                    WHERE class_name = 'CSRCapability');


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_user_body
@../user_report_body

@update_tail
