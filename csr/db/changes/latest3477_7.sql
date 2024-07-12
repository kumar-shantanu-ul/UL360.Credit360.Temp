-- Please update version.sql too -- this keeps clean builds in sync
define version=3477
define minor_version=7
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
INSERT INTO csr.capability (name, allow_by_default, description)
 VALUES ('Can manage notification failures', 0, 'Enables resending or deleting failed notifications');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../notification_pkg
@../notification_body

@update_tail
