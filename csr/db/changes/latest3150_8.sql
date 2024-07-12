-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

TRUNCATE TABLE surveys.answer_file;
ALTER TABLE surveys.answer_file DISABLE CONSTRAINT FK_ANSWER_FILE_FILE;
TRUNCATE TABLE surveys.submission_file;
ALTER TABLE surveys.answer_file ENABLE CONSTRAINT FK_ANSWER_FILE_FILE;

ALTER TABLE surveys.submission_file DROP COLUMN URI;
ALTER TABLE surveys.submission_file ADD FILE_PATH VARCHAR2(2000) NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

--@..\surveys\survey_pkg
--@..\surveys\survey_body

@update_tail
