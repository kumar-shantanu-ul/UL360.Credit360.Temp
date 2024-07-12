-- Please update version.sql too -- this keeps clean builds in sync
define version=2821
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
	EXECUTE IMMEDIATE 'DROP SEQUENCE csr.STD_MEASURE_CONVERSION_ID_SEQ';
EXCEPTION WHEN OTHERS THEN
	IF (SQLCODE = -2289) THEN
		NULL; -- sequence already deleted
	ELSE
		RAISE;
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\cms_tab_body
@..\..\..\aspen2\cms\db\tab_body
@..\audit_report_body
@..\certificate_body
@..\chain\business_relationship_body
@..\delegation_body
@..\doc_body
@..\factor_body
@..\indicator_body
@..\issue_body
@..\issue_report_body
@..\non_compliance_report_body
@..\property_report_body
@..\quick_survey_body
@..\region_body
@..\region_tree_body

@update_tail
