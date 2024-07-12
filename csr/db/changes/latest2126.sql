-- Please update version.sql too -- this keeps clean builds in sync
define version=2126
@update_header

INSERT INTO CSR.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('rtquestion', 'Rich text question', null);

-- extracts unanswered questions from quick survey responses
CREATE OR REPLACE VIEW csr.v$quick_survey_unans_quest AS
    SELECT qsr.app_sid, qsr.survey_sid, qsr.survey_response_id, qsq.question_id, qsq.pos AS question_pos, qsq.question_type, qsq.label AS question_label
	  FROM csr.v$quick_survey_response qsr
	  JOIN csr.quick_survey_question qsq ON qsq.app_sid = qsr.app_sid AND qsq.survey_sid = qsr.survey_sid
	 WHERE qsq.parent_id IS NULL
	   AND qsq.is_visible = 1
	   AND qsq.question_type NOT IN ('section', 'pagebreak', 'files', 'richtext')      
	   AND ( -- questions without nested answers
	    (qsq.question_type IN ('note', 'number', 'slider', 'date', 'regionpicker', 'radio', 'rtquestion')
		 AND (qsq.question_id IN (
		   SELECT question_id 
		     FROM csr.v$quick_survey_answer
		    WHERE app_sid = qsr.app_sid
		     AND survey_response_id = qsr.survey_response_id
			 AND (answer IS NULL AND question_option_id IS NULL AND val_number IS NULL AND region_sid IS NULL))))
		-- questions with nested answers
		OR (qsq.question_type = 'checkboxgroup'
		 AND NOT EXISTS ( -- consider as unanswered if none of the options are ticked
		   SELECT qsq1.question_id 
		     FROM csr.quick_survey_question qsq1, csr.v$quick_survey_answer qsa1           
		    WHERE qsa1.app_sid = qsr.app_sid
			  AND qsa1.survey_response_id = qsr.survey_response_id 
			  AND qsq1.parent_id = qsq.question_id
			  AND qsq1.question_id = qsa1.question_id
			  AND qsq1.is_visible = 1
			  AND qsa1.val_number = 1))
		OR (qsq.question_type = 'matrix'
		 AND EXISTS ( -- consider as unanswered if any of the options/matrix-rows are not filled
		   SELECT qsq1.question_id 
		     FROM csr.quick_survey_question qsq1, csr.quick_survey_answer qsa1           
			WHERE qsa1.app_sid = qsr.app_sid
			  AND qsa1.survey_response_id = qsr.survey_response_id
			  AND qsq1.parent_id = qsq.question_id
			  AND qsq1.question_id = qsa1.question_id
			  AND qsq1.is_visible = 1
			  AND qsa1.question_option_id IS NULL))
		);
		
@update_tail
