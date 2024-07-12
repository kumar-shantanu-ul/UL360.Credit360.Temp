-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_response_ids		security.T_SID_TABLE;
BEGIN
	
	FOR r IN (
		SELECT host, app_sid FROM csr.customer WHERE app_sid IN (
		    SELECT DISTINCT app_sid FROM (
				SELECT qsr.app_sid, qsr.survey_version old_survey_version,
					   MAX(qsv.survey_version) new_survey_version
				  FROM csr.quick_survey_response qsr
				  JOIN csr.quick_survey_version qsv
					ON qsr.app_sid = qsv.app_sid 
				   AND qsr.survey_sid = qsv.survey_sid
				   AND qsr.created_dtm > qsv.published_dtm
				 WHERE qsr.question_xml_override IS NOT NULL
				 GROUP BY qsr.app_sid, qsr.survey_response_id, qsr.survey_version
			  ) p
			 WHERE p.old_survey_version > p.new_survey_version
		)
	) LOOP

		security.user_pkg.logonadmin(r.host);	
		
		SELECT survey_response_id
		  BULK COLLECT INTO v_response_ids
		  FROM (
			SELECT qsr.survey_response_id, qsr.survey_version old_survey_version,
				   MAX(qsv.survey_version) new_survey_version
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey_version qsv
				ON qsr.app_sid = qsv.app_sid 
			   AND qsr.survey_sid = qsv.survey_sid
			   AND qsr.created_dtm > qsv.published_dtm
			 WHERE qsr.question_xml_override IS NOT NULL
			 GROUP BY qsr.survey_response_id, qsr.survey_version
		  ) p
		 WHERE p.old_survey_version > p.new_survey_version;
		 

		UPDATE csr.quick_survey_response u
		  SET u.survey_version = (
			SELECT MAX(qsv.survey_version) new_survey_version
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey_version qsv
				ON qsr.app_sid = qsv.app_sid 
			  AND qsr.survey_sid = qsv.survey_sid
			  AND qsr.created_dtm > qsv.published_dtm
			 WHERE qsr.survey_response_id = u.survey_response_id
		  )
		  WHERE u.survey_response_id IN (
			SELECT column_value FROM TABLE(v_response_ids)
		  );
		  
		UPDATE csr.quick_survey_submission u
			SET u.survey_version = (
			SELECT MAX(qsv.survey_version) new_survey_version
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey_version qsv
				ON qsr.app_sid = qsv.app_sid 
			  AND qsr.survey_sid = qsv.survey_sid
			  AND qsr.created_dtm > qsv.published_dtm
			 WHERE qsr.survey_response_id = u.survey_response_id
		  )
		  WHERE submission_id = 0
			AND u.survey_response_id IN (
			SELECT column_value FROM TABLE(v_response_ids)
		  );
		  
		UPDATE csr.quick_survey_answer u
			SET u.survey_version = (
			SELECT MAX(qsv.survey_version) new_survey_version
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey_version qsv
				ON qsr.app_sid = qsv.app_sid 
			  AND qsr.survey_sid = qsv.survey_sid
			  AND qsr.created_dtm > qsv.published_dtm
			 WHERE qsr.survey_response_id = u.survey_response_id
		  )
		  WHERE submission_id = 0
			AND u.survey_response_id IN (
			SELECT column_value FROM TABLE(v_response_ids)
		  );
		  
		  UPDATE csr.qs_submission_file u
			SET u.survey_version = (
			SELECT MAX(qsv.survey_version) new_survey_version
			  FROM csr.quick_survey_response qsr
			  JOIN csr.quick_survey_version qsv
				ON qsr.app_sid = qsv.app_sid 
			  AND qsr.survey_sid = qsv.survey_sid
			  AND qsr.created_dtm > qsv.published_dtm
			 WHERE qsr.survey_response_id = u.survey_response_id
		  )
		  WHERE submission_id = 0
			AND u.survey_response_id IN (
			SELECT column_value FROM TABLE(v_response_ids)
		  );
	END LOOP;
	
	security.user_pkg.logonadmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\quick_survey_pkg
@..\quick_survey_body
@update_tail
