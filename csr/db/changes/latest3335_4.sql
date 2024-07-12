-- Please update version.sql too -- this keeps clean builds in sync
define version=3335
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
	INSERT INTO csr.service_user_map(service_identifier, user_sid, full_name, can_impersonate)
		VALUES	('amfori', 3, 'Amfori Platform Service user', 1);
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
