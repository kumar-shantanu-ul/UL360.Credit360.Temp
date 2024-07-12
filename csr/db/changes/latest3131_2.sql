-- Please update version.sql too -- this keeps clean builds in sync
define version=3131
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.FLOW_STATE_SURVEY_TAG(
	APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FLOW_STATE_ID          NUMBER(10, 0)    NOT NULL,
	TAG_ID                 NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_FLOW_STATE_SURVEY_TAG PRIMARY KEY (APP_SID, FLOW_STATE_ID, TAG_ID)
);

CREATE INDEX CSR.IX_FLOW_STATE_SURVEY_TAG_TAG ON CSR.FLOW_STATE_SURVEY_TAG(APP_SID, TAG_ID);

CREATE TABLE CSRIMP.FLOW_STATE_SURVEY_TAG(
	CSRIMP_SESSION_ID		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	FLOW_STATE_ID          NUMBER(10, 0)    NOT NULL,
	TAG_ID                 NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_FLOW_STATE_SURVEY_TAG PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_STATE_ID, TAG_ID),
	CONSTRAINT FK_FLOW_STATE_SURVEY_TAG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


-- Alter tables
ALTER TABLE CSR.T_FLOW_STATE ADD
(
	SURVEY_EDITABLE			NUMBER(10) NOT NULL,
	SURVEY_TAG_IDS			VARCHAR2(2000)
);

ALTER TABLE CSR.FLOW_STATE_SURVEY_TAG ADD CONSTRAINT FK_FLST_FLSTSRVTAG
    FOREIGN KEY (APP_SID, FLOW_STATE_ID)
    REFERENCES CSR.FLOW_STATE(APP_SID, FLOW_STATE_ID)
;

ALTER TABLE CSR.FLOW_STATE_SURVEY_TAG ADD CONSTRAINT FK_TAG_FLSTSRVTAG
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID)
;

ALTER TABLE CSR.FLOW_STATE ADD(
    SURVEY_EDITABLE          NUMBER(10, 0)    DEFAULT 1 NOT NULL
)
;

ALTER TABLE CSRIMP.FLOW_STATE ADD(
    SURVEY_EDITABLE          NUMBER(10, 0)    NOT NULL
)
;

ALTER TABLE surveys.audit_log_detail
ADD CONSTRAINT PK_AUDIT_LOG_DETAIL PRIMARY KEY(app_sid, audit_log_detail_id);

CREATE INDEX surveys.ix_audit_log_object ON surveys.audit_log (app_sid, object_id);

ALTER TABLE surveys.survey_section_tr RENAME COLUMN simple_help TO popup_text;
ALTER TABLE surveys.survey_section_tr DROP COLUMN detailed_help;

ALTER TABLE surveys.clause ADD (
	value_question_type		NUMBER(10, 0),
	value_question_id		NUMBER(10, 0)
);

ALTER TABLE SURVEYS.ANSWER ADD (
	MEASURE_CONVERSION_ID	NUMBER(10),
	BASE_NUMERIC_VALUE		NUMBER
);

BEGIN
	security.user_pkg.LogonAdmin;
	
	DELETE FROM surveys.condition c
	 WHERE NOT EXISTS (
		SELECT 1
		  FROM surveys.survey_version sv
		 WHERE sv.app_sid = c.app_sid
		   AND sv.survey_sid = c.survey_sid
		);
	
	UPDATE surveys.condition c
	   SET survey_version = (
		SELECT MIN(survey_version)
		  FROM surveys.survey_version sv
		 WHERE sv.app_sid = c.app_sid
		   AND sv.survey_sid = c.survey_sid
		)
	 WHERE survey_version IS NULL;
END;
/

ALTER TABLE surveys.condition MODIFY survey_version NOT NULL;

ALTER TABLE surveys.condition ADD (
	invalid	VARCHAR2(20) DEFAULT 'valid' NOT NULL
);

ALTER TABLE surveys.clause ADD (
	value_question_sub_type		VARCHAR2(255)
);


ALTER TABLE surveys.clause ADD (
	tag_group_id					NUMBER(10)
);
ALTER TABLE surveys.answer DROP CONSTRAINT uk_answer_submission;
CREATE UNIQUE INDEX surveys.uk_answer_submission ON surveys.answer (APP_SID, SUBMISSION_ID, QUESTION_ID, NVL(REPEAT_INDEX, QUESTION_ID));

ALTER TABLE surveys.survey ADD default_lang	VARCHAR2(50);

UPDATE surveys.survey s
   SET (default_lang) = (SELECT MAX(tr.language_code)
						   FROM surveys.survey_version_tr tr
						  WHERE s.survey_sid = tr.survey_sid
						  GROUP BY tr.survey_sid)
 WHERE EXISTS (
	SELECT 1
	  FROM surveys.survey_version_tr tr
	 WHERE s.survey_sid = tr.survey_sid
	 GROUP BY tr.survey_sid);

UPDATE surveys.survey s
   SET (default_lang) = 'en'
 WHERE s.default_lang IS NULL;

ALTER TABLE surveys.survey MODIFY default_lang	NOT NULL;

-- *** Grants ***

grant insert on csr.flow_state_survey_tag to csrimp;
grant select,insert,update,delete on csrimp.flow_state_survey_tag to tool_user;
grant select on csr.measure to surveys;
grant references on csr.measure_conversion to surveys;

-- ** Cross schema constraints ***

ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT FK_ANSWER_MEASURE_CONVERSION
	FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
	REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID)
;

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- C:\cvs\csr\db\surveys\create_views
CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.action, q.matrix_parent_id, q.matrix_row_id, qv.matrix_child_pos, q.measure_sid,
			q.deleted_dtm question_deleted_dtm, q.default_lang
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;

-- C:\cvs\csr\db\surveys\create_views
CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft
	 UNION
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.matrix_parent_id
	   AND sq.question_version = qv.question_version
	   AND sq.question_draft = qv.question_draft;

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE surveys.question_version
	   SET decimal_places = NULL
	 WHERE decimal_places IS NOT NULL
	   AND question_id IN (SELECT question_id
							 FROM surveys.question
							WHERE measure_sid > 0);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
--@..\surveys\survey_pkg
--@..\surveys\condition_pkg
--@..\surveys\question_library_pkg
@..\measure_pkg
@..\flow_pkg
@..\schema_pkg

--@..\surveys\survey_body
--@..\surveys\campaign_body
--@..\surveys\question_library_body
--@..\surveys\question_library_report_body
--@..\surveys\condition_body
@..\enable_body
@..\measure_body
@..\quick_survey_body
@..\flow_body
@..\csr_app_body
@..\tag_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
