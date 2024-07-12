-- Please update version.sql too -- this keeps clean builds in sync
define version=1486
@update_header

ALTER TABLE CSR.QS_ANSWER_FILE ADD(
    CAPTION               VARCHAR2(1023)
)
;

ALTER TABLE CSRIMP.QS_ANSWER_FILE ADD(
    CAPTION               VARCHAR2(1023)
)
;

CREATE OR REPLACE VIEW csr.v$qs_answer_file AS
	SELECT af.app_sid, af.qs_answer_file_id, af.survey_response_id, af.question_id, af.filename,
		   af.mime_type, af.data, af.sha1, af.uploaded_dtm, sf.submission_id, af.caption
	  FROM qs_answer_file af
	  JOIN qs_submission_file sf ON af.qs_answer_file_id = sf.qs_answer_file_id;

@..\quick_survey_pkg
@..\quick_survey_body
@..\schema_body
@..\csrimp\imp_body

@update_tail
