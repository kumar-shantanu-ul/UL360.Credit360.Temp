-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.group_key, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes,
		   qs.score_type_id, st.label score_type_label, st.format_mask score_format_mask,
		   qs.quick_survey_type_id, qst.description quick_survey_type_desc
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	  LEFT JOIN csr.score_type st ON st.score_type_id = qs.score_type_id
	  LEFT JOIN csr.quick_survey_type qst on qst.quick_survey_type_id = qs.quick_survey_type_id
	 WHERE d.survey_version = 0;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../audit_body
@../audit_report_body
@../quick_survey_body

@update_tail
