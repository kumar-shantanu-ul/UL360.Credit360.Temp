-- Please update version.sql too -- this keeps clean builds in sync
define version=2791
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	UPDATE CSR.qs_answer_log qal
	   SET qal.version_stamp = (
		SELECT QSa.version_stamp
		  FROM (
			SELECT app_sid, survey_response_id, question_id, version_stamp, ROW_NUMBER() over(PARTITION BY app_sid, survey_response_id, question_id ORDER BY submission_id DESC) rn
			  FROM csr.quick_survey_answer
		) qsa
		WHERE qal.app_sid = qsa.app_sid
		  AND qal.survey_response_id = qsa.survey_response_id
		  AND qal.question_id = qsa.question_id
		  AND qsa.rn = 1
	)
	 WHERE EXISTS (
		SELECT 1
		  FROM (
			SELECT app_sid, QS_ANSWER_LOG_ID, ROW_NUMBER() over(PARTITION BY app_sid, survey_response_id, question_id ORDER BY set_dtm DESC) rn
			  FROM csr.qs_answer_log
		) qal2
		WHERE qal.app_sid = qal2.app_sid
		  AND qal.QS_ANSWER_LOG_ID = qal2.QS_ANSWER_LOG_ID
		  AND qal2.rn = 1
	);
END;
/

-- ** New package grants **

-- *** Packages ***

@..\quick_survey_pkg
@..\quick_survey_body

@update_tail
