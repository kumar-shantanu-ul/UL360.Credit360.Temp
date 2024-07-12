-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=35
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- Make the lookup key big enough to hold all of the excluded tags.
ALTER TABLE csr.temp_question_option MODIFY (lookup_key VARCHAR2(1000));
DROP INDEX csr.ix_qs_question_option;
ALTER TABLE csr.qs_question_option MODIFY (lookup_key VARCHAR2(1000));
CREATE UNIQUE INDEX csr.ix_qs_question_option 
	ON csr.qs_question_option(app_sid, question_id, survey_version, 
							  NVL(UPPER(lookup_key),'QOID_'||TO_CHAR(question_option_id)));

ALTER TABLE csrimp.qs_question_option MODIFY (lookup_key VARCHAR2(1000));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_pkg
@../compliance_body
@../enable_body

@update_tail
