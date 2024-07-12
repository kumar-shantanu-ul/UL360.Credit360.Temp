-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=9
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
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description) VALUES (41, 8, 'Number of actions closed on time');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description) VALUES (41, 9, 'Number of actions closed overdue');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description) VALUES (42, 8, 'Number of actions closed on time');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description) VALUES (42, 9, 'Number of actions closed overdue');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\audit_report_pkg
@..\audit_report_body
@..\non_compliance_report_pkg
@..\non_compliance_report_body

@update_tail
