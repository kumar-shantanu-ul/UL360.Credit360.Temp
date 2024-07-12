-- Please update version.sql too -- this keeps clean builds in sync
define version=3137
define minor_version=7
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
-- Update all latest published versions of surveys to have non draft questions and other versions to be draft (DE6660)
BEGIN
	FOR r IN (
		SELECT s.survey_sid, s.latest_published_version
		  FROM surveys.survey s
		  JOIN surveys.survey_version sv ON s.survey_sid = sv.survey_sid AND s.latest_published_version = sv.survey_version
	) LOOP
		UPDATE surveys.survey_section_question
		   SET question_draft = 0
		 WHERE survey_version = r.latest_published_version
		   AND deleted = 0
		   AND survey_sid = r.survey_sid;

		UPDATE surveys.survey_section_question
		   SET question_draft = 1
		 WHERE survey_version <> r.latest_published_version
		   AND deleted = 0
		   AND survey_sid = r.survey_sid;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
