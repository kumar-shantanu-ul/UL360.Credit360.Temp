-- Please update version.sql too -- this keeps clean builds in sync
define version=3391
define minor_version=2
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

INSERT INTO csr.service_user_map(service_identifier, user_sid, full_name, can_impersonate)
		VALUES	('disclosures', 3, 'Disclosures Service user', 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
