-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.quick_survey_type ADD (
	show_answer_set_dtm		NUMBER(1,0)
);
UPDATE csr.quick_survey_type SET show_answer_set_dtm = 0;
ALTER TABLE csr.quick_survey_type MODIFY (
	show_answer_set_dtm		DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.quick_survey_type ADD (
	show_answer_set_dtm		NUMBER(1,0)
);
UPDATE csrimp.quick_survey_type SET show_answer_set_dtm = 0;
ALTER TABLE csrimp.quick_survey_type MODIFY (
	show_answer_set_dtm		DEFAULT 0 NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\quick_survey_pkg

@..\csrimp\imp_body
@..\quick_survey_body
@..\schema_body

@update_tail
