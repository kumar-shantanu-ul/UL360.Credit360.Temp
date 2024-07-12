-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.question_tag ADD (SHOW_IN_SURVEY NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csr.question_tag ADD CONSTRAINT CK_QUESTION_TAG_SHOW_IN_SURVEY CHECK (SHOW_IN_SURVEY IN (0,1));

ALTER TABLE csrimp.question_tag ADD (SHOW_IN_SURVEY NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csrimp.question_tag ADD CONSTRAINT CK_QUESTION_TAG_SHOW_IN_SURVEY CHECK (SHOW_IN_SURVEY IN (0,1));

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
@../question_library_pkg
@../question_library_body

@update_tail
