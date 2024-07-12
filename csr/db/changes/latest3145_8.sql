-- Please update version.sql too -- this keeps clean builds in sync
define version=3145
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE SURVEYS.RESPONSE_SUBMISSION ADD (
	SURVEY_SID		NUMBER(10),
	SURVEY_VERSION	NUMBER(10)
);

BEGIN
	FOR roe IN (
		SELECT r.survey_sid, r.survey_version, rs.submission_id
		  FROM surveys.response_submission rs
		  JOIN surveys.response r ON rs.response_id = r.response_id 
	)
	LOOP
		UPDATE surveys.response_submission
		   SET survey_sid = roe.survey_sid, survey_version = roe.survey_version
		 WHERE submission_id = roe.submission_id;
	END LOOP;
END;
/

ALTER TABLE SURVEYS.RESPONSE_SUBMISSION MODIFY (
	SURVEY_SID		NOT NULL,
	SURVEY_VERSION	NOT NULL
);

ALTER TABLE SURVEYS.RESPONSE_SUBMISSION ADD (
	CONSTRAINT FK_RESPONSE_SUB_SURVEY_VERSION FOREIGN KEY (APP_SID, SURVEY_SID, SURVEY_VERSION) 
		REFERENCES SURVEYS.SURVEY_VERSION (APP_SID, SURVEY_SID, SURVEY_VERSION)
);

CREATE INDEX SURVEYS.IX_RESPONSE_SUB_SURVEY_VERSION ON SURVEYS.RESPONSE_SUBMISSION (APP_SID, SURVEY_SID, SURVEY_VERSION);

ALTER TABLE SURVEYS.RESPONSE RENAME COLUMN SURVEY_VERSION TO X_SURVEY_VERSION;

ALTER TABLE SURVEYS.RESPONSE RENAME CONSTRAINT FK_RESPONSE_SURVEY TO FK_RESPONSE_SURVEY_VERSION;

ALTER TABLE SURVEYS.RESPONSE ADD (
	CONSTRAINT FK_RESPONSE_SURVEY FOREIGN KEY (APP_SID, SURVEY_SID) 
		REFERENCES SURVEYS.SURVEY (APP_SID, SURVEY_SID)
);

CREATE INDEX SURVEYS.IX_RESPONSE_SURVEY ON SURVEYS.RESPONSE_SUBMISSION (APP_SID, SURVEY_SID);

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

--@../surveys/survey_body
--@../surveys/integration_body

@update_tail
