-- Please update version.sql too -- this keeps clean builds in sync
define version=3227
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	security.user_pkg.logonadmin();
	
	FOR R IN (SELECT host hst FROM csr.enhesa_options eo JOIN csr.customer c ON eo.app_sid = c.app_sid)
	LOOP
		security.user_pkg.logonadmin(r.hst);

		MERGE INTO csr.compliance_region_tag crt
		USING (
		   SELECT DISTINCT rsr.app_sid, rsr.region_sid, tag.tag_id
			 FROM csr.enhesa_options eo 
			 JOIN csr.quick_survey qs ON qs.app_sid = eo.app_sid
			 JOIN csr.quick_survey_version qsv ON qsv.app_sid = qs.app_sid and qs.survey_sid = qsv.survey_sid AND qs.current_version = qsv.survey_version
			 JOIN csr.quick_survey_response qsr ON qsr.app_sid = qs.app_sid and qsr.survey_sid = qs.survey_sid
			 JOIN csr.quick_survey_submission qss ON qss.app_sid = qs.app_sid and qss.submission_id = qsr.last_submission_id
			 JOIN csr.quick_survey_answer qsa ON qsa.app_sid = qs.app_sid and qsa.survey_sid = qsr.survey_sid AND qsa.survey_response_id = qsr.survey_response_id AND qsa.submission_id = qsr.last_submission_id
			 JOIN csr.qs_question_option qsq ON qsq.app_sid = qs.app_sid and qsq.question_id = qsa.question_id AND qsq.question_version = qsa.question_version AND qsq.label = 'No'
			 JOIN csr.region_survey_response rsr ON rsr.app_sid = qs.app_sid and qsr.survey_response_id = rsr.survey_response_id
			 JOIN csr.tag ON tag.app_sid = qs.app_sid AND (qsq.lookup_key = tag.lookup_key OR qsq.lookup_key LIKE ('%,'||tag.lookup_key||',%') OR qsq.lookup_key LIKE (tag.lookup_key||',%') OR qsq.lookup_key LIKE ('%,'||tag.lookup_key)) 
			WHERE qsv.label = 'ENHESA Screening Survey'
			  AND qsa.question_option_id IS NULL
		) t ON (crt.app_sid = t.app_sid AND crt.region_sid = t.region_sid AND crt.tag_id = t.tag_id) 
		WHEN NOT MATCHED THEN 
		   INSERT (app_sid, region_sid, tag_id)
		   VALUES (t.app_sid, t.region_sid, t.tag_id);
	END LOOP;

	security.user_pkg.logonadmin();
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../compliance_register_report_body

@update_tail
