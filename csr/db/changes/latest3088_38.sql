-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=38
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE SURVEYS.QUESTION_OPTION_TAG DROP PRIMARY KEY DROP INDEX;

BEGIN
	security.user_pkg.LogonAdmin;
	DELETE FROM SURVEYS.QUESTION_OPTION_TAG;
END;
/

ALTER TABLE SURVEYS.QUESTION_OPTION_TAG ADD (
	QUESTION_ID				 	NUMBER(10, 0)	 NOT NULL,
	QUESTION_VERSION		 	NUMBER(10, 0) 	NOT NULL,
	QUESTION_DRAFT			 	NUMBER(1)	 	NOT NULL,
	CONSTRAINT PK_QUESTION_OPTION_TAG PRIMARY KEY (APP_SID, QUESTION_OPTION_ID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT, TAG_ID),
	CONSTRAINT FK_QUESTION_OPTION_TAG_OPTION FOREIGN KEY (APP_SID, QUESTION_OPTION_ID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT) REFERENCES SURVEYS.QUESTION_OPTION (APP_SID, QUESTION_OPTION_ID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
);

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
--@../surveys/question_library_body

@update_tail
