-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.quick_survey_version RENAME COLUMN question_xml TO xxx_question_xml;
ALTER TABLE csr.quick_survey_version ADD question_xml CLOB;
UPDATE csr.quick_survey_version
   SET question_xml = xmltype.getClobVal(xxx_question_xml)
 WHERE question_xml IS NULL;
ALTER TABLE csr.quick_survey_version MODIFY question_xml NOT NULL;
ALTER TABLE csr.quick_survey_version MODIFY xxx_question_xml NULL;

ALTER TABLE csr.quick_survey_response RENAME COLUMN question_xml_override TO xxx_question_xml_override;
ALTER TABLE csr.quick_survey_response ADD question_xml_override CLOB;
UPDATE csr.quick_survey_response
   SET question_xml_override = xmltype.getClobVal(xxx_question_xml_override)
 WHERE question_xml_override IS NULL
   AND xxx_question_xml_override IS NOT NULL;

ALTER TABLE csrimp.quick_survey_version RENAME COLUMN question_xml TO xxx_question_xml;
ALTER TABLE csrimp.quick_survey_version ADD question_xml CLOB;
UPDATE csrimp.quick_survey_version
   SET question_xml = xmltype.getClobVal(xxx_question_xml)
 WHERE question_xml IS NULL;
ALTER TABLE csrimp.quick_survey_version MODIFY question_xml NOT NULL;
ALTER TABLE csrimp.quick_survey_version MODIFY xxx_question_xml NULL;

ALTER TABLE csrimp.quick_survey_response RENAME COLUMN question_xml_override TO xxx_question_xml_override;
ALTER TABLE csrimp.quick_survey_response ADD question_xml_override CLOB;
UPDATE csrimp.quick_survey_response
   SET question_xml_override = xmltype.getClobVal(xxx_question_xml_override)
 WHERE question_xml_override IS NULL
   AND xxx_question_xml_override IS NOT NULL;

-- *** Grants ***
grant select,insert,update,delete on csrimp.internal_audit_type_report to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\quick_survey_pkg
@..\quick_survey_body
@..\csr_app_body
@..\csrimp\imp_body

@update_tail
