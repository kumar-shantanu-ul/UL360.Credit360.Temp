-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE surveys.question_version RENAME COLUMN remember_answer TO allow_copy_answer;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- /cvs/csr/db/surveys/create_views.sql
CREATE OR REPLACE VIEW surveys.v$question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, q.question_type,
			qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
			qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
			qv.allow_file_uploads, qv.allow_user_comments, qv.action, q.matrix_parent_id, q.matrix_row_id, qv.matrix_child_pos, q.measure_sid,
			q.deleted_dtm question_deleted_dtm, q.default_lang, qv.option_data_source_id
	  FROM question_version qv
	  JOIN question q ON q.question_id = qv.question_id AND q.app_sid = qv.app_sid;

-- /cvs/csr/db/surveys/create_views.sqls
CREATE OR REPLACE VIEW surveys.v$survey_question AS
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.question_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft
	 UNION
	SELECT qv.question_id, qv.question_version, qv.question_draft, qv.mandatory, qv.default_numeric_value, qv.default_date_value, qv.question_type,
		qv.character_limit, qv.min_numeric_value, qv.max_numeric_value, qv.numeric_value_tolerance, qv.decimal_places, qv.min_selections,
		qv.max_selections, qv.display_type, qv.value_validation_type, qv.allow_copy_answer, qv.count_towards_progress,
		qv.allow_file_uploads, qv.allow_user_comments, qv.matrix_parent_id, qv.matrix_row_id, qv.matrix_child_pos,
		qv.action, sq.survey_sid, sq.survey_version, sq.section_id, sq.pos, NVL2(qv.question_deleted_dtm, 1, sq.deleted) deleted, qv.measure_sid,
		qv.default_lang, qv.option_data_source_id AS data_source_id
	  FROM survey_section_question sq
	  JOIN v$question qv ON sq.question_id = qv.matrix_parent_id AND sq.question_version = qv.question_version AND sq.question_draft = qv.question_draft
  ORDER BY matrix_parent_id, matrix_row_id, matrix_child_pos;


-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;

	DELETE FROM surveys.answer_option
	 WHERE answer_id IN (
		SELECT answer_id
		  FROM surveys.answer
		 WHERE repeat_index IS NULL
		   AND question_id IN (
	  		SELECT question_id
	  		  FROM surveys.question
	  		 WHERE matrix_parent_id IN(
				SELECT question_id
				  FROM surveys.question
				 WHERE question_type = 'matrixdynamic' 
			)
		)
	);

	DELETE FROM surveys.answer
	 WHERE repeat_index IS NULL
	   AND question_id IN (
  		SELECT question_id
  		  FROM surveys.question
  		 WHERE matrix_parent_id IN(
				SELECT question_id
				  FROM surveys.question
				 WHERE question_type = 'matrixdynamic' 
			)
		);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

--@../surveys/survey_pkg
--@../surveys/question_library_pkg

--@../surveys/survey_body
--@../surveys/question_library_body

@update_tail
