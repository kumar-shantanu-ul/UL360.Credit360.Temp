-- Please update version.sql too -- this keeps clean builds in sync
define version=1320
@update_header

CREATE OR REPLACE VIEW csr.v$quick_survey_response AS
	SELECT qsr.app_sid, qsr.survey_response_id, qsr.survey_sid, qsr.user_sid, qsr.user_name,
		   qsr.created_dtm, qsr.guid, qss.submitted_dtm, qsr.qs_response_status_id,
		   qsr.qs_campaign_sid, qss.overall_score, qss.overall_max_score, qss.score_threshold_id,
		   qss.submission_id
	  FROM quick_survey_response qsr 
	  JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id
	   AND NVL(qsr.last_submission_id, 0) = qss.submission_id;

ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP COLUMN SUBMITTED_DTM;
ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP COLUMN OVERALL_SCORE;
ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP COLUMN OVERALL_MAX_SCORE;
ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP COLUMN SCORE_THRESHOLD_ID;
ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP COLUMN FIRST_RESPONSE_DTM;


@update_tail
