-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=11
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
INSERT INTO csr.compliance_item_change_type (compliance_item_change_type_id, description, source, change_type_index)
	VALUES (15, 'Retired', 0, 8);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../compliance_body

@update_tail
