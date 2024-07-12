-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=34
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
	INSERT INTO chain.card_group (card_group_id, name, description, helper_pkg, list_page_url)
	VALUES (59, 'Question Library Filter', 'Allows filtering of question library questions.', 'csr.question_library_report_pkg', '/csr/site/quickSurvey/library/Library.acds?savedFilterSid=');
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/

-- TODO: card for filtering?
-- TODO: add card to card manager for existing question library customers?

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.question_library_report_pkg AS END;
/

GRANT EXECUTE ON csr.question_library_report_pkg TO web_user;
GRANT EXECUTE ON csr.question_library_report_pkg TO chain;

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\chain_pkg
@..\chain\filter_pkg
@..\question_library_report_pkg

@..\question_library_report_body

@..\chain\filter_body
@..\non_compliance_report_body
@..\audit_report_body
@..\compliance_library_report_body
@..\initiative_report_body
@..\meter_list_body
@..\meter_report_body
@..\property_report_body
@..\region_report_body
@..\supplier_body

@update_tail
