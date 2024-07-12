-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=24
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
-- Update all non compliances raised from a survey question to have a survey_response_id
BEGIN
	security.user_pkg.logonadmin;

	FOR r IN (
		SELECT nc.non_compliance_id, NVL(ias.survey_sid, qsr.survey_sid) survey_sid, NVL(ias.survey_response_id, qsr.survey_response_id) survey_response_id
		  FROM csr.non_compliance nc
		  JOIN csr.internal_audit ia ON ia.internal_audit_sid = nc.created_in_audit_sid AND ia.app_sid = nc.app_sid
		  JOIN csr.quick_survey_question qsq ON qsq.question_id = nc.question_id AND qsq.app_sid = nc.app_sid
		  LEFT JOIN csr.quick_survey_response qsr ON ia.survey_response_id = qsr.survey_response_id AND qsr.survey_sid = qsq.survey_sid AND qsr.app_sid = ia.app_sid
	      LEFT JOIN csr.internal_audit_survey ias ON ias.internal_audit_sid = nc.created_in_audit_sid AND qsq.survey_sid = ias.survey_sid AND ias.app_sid = nc.app_sid
	     WHERE NVL(ias.survey_response_id, qsr.survey_response_id) IS NOT NULL
	       AND NVL(ias.survey_sid, qsr.survey_sid) IS NOT NULL
	     GROUP BY non_compliance_id, NVL(ias.survey_sid, qsr.survey_sid), NVL(ias.survey_response_id, qsr.survey_response_id)
	     ORDER BY non_compliance_id
	) LOOP
		UPDATE csr.non_compliance
		   SET survey_response_id = r.survey_response_id
		 WHERE non_compliance_id = r.non_compliance_id;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../audit_body
@../quick_survey_body

@update_tail
