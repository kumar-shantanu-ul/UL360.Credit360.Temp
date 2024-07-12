-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=37
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DELETE FROM surveys.answer_file;
DELETE FROM surveys.submission_file;

DROP INDEX SURVEYS.IX_ANS_FILE_SUB_ID;
DROP SEQUENCE surveys.SURVEY_ANSWER_FILE_ID_SEQ;

ALTER TABLE surveys.submission_file ADD submission_file_id NUMBER(10) NOT NULL;
ALTER TABLE surveys.answer_file ADD submission_file_id NUMBER(10) NOT NULL;

ALTER TABLE surveys.answer_file DROP CONSTRAINT PK_SURVEY_ANSWER_FILE;
ALTER TABLE surveys.answer_file DROP CONSTRAINT FK_ANS_FILE_SUB_ID;
ALTER TABLE surveys.answer_file DROP CONSTRAINT FK_ANSWER_FILE_FILE;
ALTER TABLE surveys.answer_file DROP CONSTRAINT UK_SURVEY_ANSWER_FILE;
ALTER TABLE surveys.answer_file DROP CONSTRAINT UK_SURVEYS_ANSWER_FILE_A;
ALTER TABLE surveys.submission_file DROP CONSTRAINT PK_SUBMISSION_FILE;

ALTER TABLE surveys.answer_file DROP COLUMN answer_file_id;
ALTER TABLE surveys.answer_file DROP COLUMN submission_id;
ALTER TABLE surveys.answer_file DROP COLUMN filename;
ALTER TABLE surveys.answer_file DROP COLUMN uri;

ALTER TABLE surveys.submission_file ADD CONSTRAINT PK_SUBMISSION_FILE
	PRIMARY KEY (APP_SID, SUBMISSION_FILE_ID);

ALTER TABLE surveys.answer_file ADD CONSTRAINT PK_SURVEY_ANSWER_FILE
	PRIMARY KEY (APP_SID, ANSWER_ID, SUBMISSION_FILE_ID);

ALTER TABLE SURVEYS.ANSWER_FILE ADD CONSTRAINT FK_ANSWER_FILE_FILE
	FOREIGN KEY (APP_SID, SUBMISSION_FILE_ID)
	REFERENCES SURVEYS.SUBMISSION_FILE(APP_SID, SUBMISSION_FILE_ID)
;

CREATE SEQUENCE surveys.survey_submission_file_id_seq;

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
--@../surveys/survey_pkg
--@../surveys/survey_body

@update_tail
