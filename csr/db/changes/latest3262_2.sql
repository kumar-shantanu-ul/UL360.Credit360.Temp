-- Please update version.sql too -- this keeps clean builds in sync
define version=3262
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

INSERT INTO chain.grid_extension (grid_extension_id, base_card_group_id, extension_card_group_id, record_name)
VALUES (14, 25, 42, 'nonCompliance');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../issue_report_body

@update_tail
