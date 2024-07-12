-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

COMMENT ON COLUMN CHAIN.HIGG_MODULE_SUB_SECTION.HIGG_SECTION_ID IS 'DESC="Section",SEARCH_ENUM,ENUM_DESC_COL=SECTION_NAME';
COMMENT ON COLUMN CHAIN.HIGG_QUESTION.PARENT_QUESTION_ID IS 'DESC="Parent question",SEARCH_ENUM,ENUM_DESC_COL=QUESTION_TEXT';
COMMENT ON COLUMN CHAIN.HIGG_QUESTION.HIGG_SUB_SECTION_ID IS 'DESC="Sub-section",SEARCH_ENUM,ENUM_DESC_COL=SUB_SECTION_NAME';
COMMENT ON COLUMN CHAIN.HIGG_QUESTION_OPTION.HIGG_QUESTION_ID IS 'desc="Question",SEARCH_ENUM,ENUM_DESC_COL=QUESTION_TEXT';

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

@update_tail
