-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.question ADD (
	latest_question_version NUMBER(10),
	latest_question_draft NUMBER(1)
);

ALTER TABLE csr.question ADD (
	CONSTRAINT fk_latest_question_version FOREIGN KEY (app_sid, question_id, latest_question_version, latest_question_draft)
	REFERENCES csr.question_version(app_sid, question_id, question_version, question_draft)
	DEFERRABLE INITIALLY DEFERRED
);

CREATE INDEX csr.ix_latest_question_version ON csr.question(app_sid, question_id, latest_question_version, latest_question_draft);

ALTER TABLE csrimp.question ADD (
	latest_question_version NUMBER(10) NOT NULL,
	latest_question_draft NUMBER(1) NOT NULL
);

BEGIN
	security.user_pkg.LogonAdmin;
	
	-- Get the latest question version by question ID
	UPDATE csr.question q
	   SET latest_question_version = (
			SELECT MAX(question_version)
			  FROM csr.question_version qv
			 WHERE q.app_sid = qv.app_sid
			   AND q.question_id = qv.question_id
		);
	
	-- Of that version, get the whether there's a draft version
	UPDATE csr.question q
	   SET latest_question_draft = (
			SELECT MAX(question_draft)
			  FROM csr.question_version qv
			 WHERE q.app_sid = qv.app_sid
			   AND q.question_id = qv.question_id
			   AND q.latest_question_version = qv.question_version
		);
	
END;
/

ALTER TABLE csr.question MODIFY latest_question_version NOT NULL;
ALTER TABLE csr.question MODIFY latest_question_draft NOT NULL;

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

@..\schema_body
@..\question_library_report_body
@..\quick_survey_body

@update_tail
