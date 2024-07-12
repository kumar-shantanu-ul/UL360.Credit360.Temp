-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
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
INSERT INTO csr.user_setting (category, setting, description, data_type)
VALUES ('CREDIT360.METER', 'activeTab', 'Stores the last active plugin tab', 'STRING');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
