-- Please update version.sql too -- this keeps clean builds in sync
define version=3111
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE SURVEYS.CLAUSE
	ADD	(VALUE_TYPE NUMBER(10, 0),
		 TEXT_VALUE NUMBER(10, 0)
	);

ALTER TABLE SURVEYS.CLAUSE
	MODIFY TEXT_VALUE VARCHAR2(4000);

ALTER TABLE SURVEYS.CLAUSE
	MODIFY NUMERIC_VALUE NUMBER;

ALTER TABLE SURVEYS.CONDITION_LINK
	ADD	(SURVEY_SID NUMBER(10,0),
	 	 SURVEY_VERSION NUMBER(10,0),
	 	 SECTION_ID NUMBER(10, 0)
		);

ALTER TABLE SURVEYS.CONDITION_LINK ADD CONSTRAINT fk_condition_link_survey_sec
	FOREIGN KEY (app_sid, survey_sid, survey_version, section_id)
	REFERENCES surveys.survey_section (app_sid, survey_sid, survey_version, section_id);

/* US9220 */
ALTER TABLE SURVEYS.ANSWER ADD COMMENT_TEXT VARCHAR2(1000);

/* US10200*/
ALTER TABLE SURVEYS.ANSWER DROP CONSTRAINT FK_ANSWER_Q_OPTION;

ALTER TABLE SURVEYS.ANSWER DROP COLUMN QUESTION_OPTION_ID;

ALTER TABLE SURVEYS.ANSWER DROP CONSTRAINT PK_SURVEY_ANSWER;
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT PK_SURVEY_ANSWER PRIMARY KEY (APP_SID, ANSWER_ID);

ALTER TABLE SURVEYS.ANSWER DROP CONSTRAINT CHK_SURVEY_ANSWER_VALUE;
ALTER TABLE SURVEYS.ANSWER ADD CONSTRAINT CHK_SURVEY_ANSWER_VALUE CHECK ((
	CASE WHEN TEXT_VALUE_SHORT	IS NOT NULL THEN 1 ELSE 0 END +
	CASE WHEN TEXT_VALUE_LONG	IS NOT NULL THEN 1 ELSE 0 END +
	CASE WHEN BOOLEAN_VALUE		IS NOT NULL THEN 1 ELSE 0 END +
	CASE WHEN NUMERIC_VALUE		IS NOT NULL THEN 1 ELSE 0 END +
	CASE WHEN DATE_VALUE		IS NOT NULL THEN 1 ELSE 0 END
) <= 1);

CREATE TABLE SURVEYS.ANSWER_OPTION(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ANSWER_ID				NUMBER(10, 0)	NOT NULL,
	QUESTION_ID				NUMBER(10, 0)	NOT NULL,
	QUESTION_OPTION_ID		NUMBER(10, 0)	NOT NULL,
	QUESTION_VERSION		NUMBER(10, 0)	NOT NULL,
	QUESTION_DRAFT			NUMBER(1)		NOT NULL,
	CONSTRAINT PK_ANSWER_OPTION PRIMARY KEY (APP_SID, ANSWER_ID, QUESTION_OPTION_ID)
);

ALTER TABLE SURVEYS.ANSWER_OPTION ADD CONSTRAINT FK_ANSWER_OPTION_Q_OPT
	FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_OPTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_OPTION (APP_SID, QUESTION_ID, QUESTION_OPTION_ID, QUESTION_VERSION, QUESTION_DRAFT);

ALTER TABLE SURVEYS.ANSWER_OPTION ADD CONSTRAINT FK_ANSWER_OPTION_ANSWER
	FOREIGN KEY (APP_SID, ANSWER_ID)
	REFERENCES SURVEYS.ANSWER (APP_SID, ANSWER_ID);

ALTER TABLE SURVEYS.QUESTION_OPTION ADD CONSTRAINT FK_QUESTION_OPTION_QUESTION
	FOREIGN KEY (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT)
	REFERENCES SURVEYS.QUESTION_VERSION (APP_SID, QUESTION_ID, QUESTION_VERSION, QUESTION_DRAFT);
/* end of US10200 */

ALTER TABLE SURVEYS.QUESTION_VERSION_TR ADD DETAILED_HELP_LINK	VARCHAR2(4000);
 UPDATE SURVEYS.QUESTION_VERSION_TR tr
	SET (DETAILED_HELP_LINK) = (SELECT qv.DETAILED_HELP_LINK
								 FROM SURVEYS.QUESTION_VERSION qv
								WHERE qv.question_id = tr.QUESTION_ID
								  AND qv.QUESTION_VERSION = tr.QUESTION_VERSION
								  AND qv.QUESTION_DRAFT = tr.QUESTION_DRAFT)
  WHERE EXISTS (
	SELECT 1
	  FROM SURVEYS.QUESTION_VERSION qv
	 WHERE qv.question_id = tr.QUESTION_ID
	   AND qv.QUESTION_VERSION = tr.QUESTION_VERSION
	   AND qv.QUESTION_DRAFT = tr.QUESTION_DRAFT );

ALTER TABLE SURVEYS.QUESTION_VERSION DROP COLUMN DETAILED_HELP_LINK;

-- US10212
ALTER TABLE SURVEYS.QUESTION DROP (MATRIX_PARENT_VERSION, MATRIX_PARENT_DRAFT);
-- end US10212

-- US10387
ALTER TABLE SURVEYS.CONDITION_LINK ADD QUESTION_OPTION_ID NUMBER(10, 0);
-- end US10387

-- *** Grants ***
grant execute on csr.trash_pkg to surveys;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.action, q.matrix_parent_id, q.matrix_row_id, qv.matrix_child_pos
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;

CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, sq.deleted
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft
	 UNION
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.remember_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, sq.deleted
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.matrix_parent_id
	   AND sq.question_version = qv.question_version
	   AND sq.question_draft = qv.question_draft;

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_act 				security.security_pkg.T_ACT_ID;
	v_class_id 			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);

	BEGIN
		v_class_id := security.class_pkg.GetClassID('Surveys');
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;

	BEGIN
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> v_class_id,
			in_permission			=> 131072, -- question_library_pkg.PERMISSION_PUBLISH_SURVEY
			in_permission_name		=> 'Publish survey'
		);
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;

	BEGIN
		v_class_id := security.class_pkg.GetClassID('Webresource');
	
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> v_class_id,
			in_permission			=> 131072, -- question_library_pkg.PERMISSION_PUBLISH_SURVEY
			in_permission_name		=> 'Publish survey'
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	security.user_pkg.LogOff(v_act);
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
--@..\surveys\condition_pkg
--@..\surveys\question_library_pkg
--@..\surveys\survey_pkg
@..\doc_folder_pkg

--@..\surveys\condition_body
--@..\surveys\question_library_body
--@..\surveys\survey_body
@..\enable_body
@..\doc_folder_body

@update_tail
