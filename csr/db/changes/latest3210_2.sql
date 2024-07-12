-- Please update version.sql too -- this keeps clean builds in sync
define version=3210
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW csr.v$quick_survey_response AS
	SELECT qsr.app_sid, qsr.survey_response_id, qsr.survey_sid, qsr.user_sid, qsr.user_name,
		   qsr.created_dtm, qsr.guid, qss.submitted_dtm, qsr.qs_campaign_sid, qss.overall_score,
		   qss.overall_max_score, qss.score_threshold_id, qss.submission_id, qss.survey_version, qss.submitted_by_user_sid,
		   qss.geo_latitude, qss.geo_longitude, qss.geo_h_accuracy, qss.geo_altitude, qss.geo_v_accuracy
	  FROM quick_survey_response qsr
	  JOIN quick_survey_submission qss ON qsr.app_sid = qss.app_sid
	   AND qsr.survey_response_id = qss.survey_response_id
	   AND NVL(qsr.last_submission_id, 0) = qss.submission_id
	   AND qsr.survey_version > 0 -- filter out draft submissions
	   AND qsr.hidden = 0 -- filter out hidden responses
;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../quick_survey_report_body

@update_tail
