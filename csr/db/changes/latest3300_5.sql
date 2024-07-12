-- Please update version.sql too -- this keeps clean builds in sync
define version=3300
define minor_version=5
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
VALUES (15, 54 /* chain.filter_pkg.FILTER_TYPE_QS_RESPONSE */, 23 /* chain.filter_pkg.FILTER_TYPE_COMPANIES */, 'company');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../quick_survey_report_body

@update_tail
