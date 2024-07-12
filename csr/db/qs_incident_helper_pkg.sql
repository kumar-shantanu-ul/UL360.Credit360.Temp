CREATE OR REPLACE PACKAGE csr.qs_incident_helper_pkg AS

PROCEDURE OnSurveySubmitted (
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_response_id		IN	quick_survey_submission.survey_response_id%TYPE,
	in_submission_id	IN	quick_survey_submission.submission_id%TYPE
);

END;
/

