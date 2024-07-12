-- Please update version.sql too -- this keeps clean builds in sync
define version=3206
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.quick_survey_type ADD (
	CAPTURE_GEO_LOCATION				NUMBER(1, 0) DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_CAPTURE_GEO_LOCATION CHECK (CAPTURE_GEO_LOCATION IN (0,1))
);

ALTER TABLE csr.quick_survey_submission ADD (
	GEO_LATITUDE						NUMBER(24,10),
	GEO_LONGITUDE						NUMBER(24,10),
	GEO_ALTITUDE						NUMBER(24,10),
	GEO_H_ACCURACY						NUMBER(24,10),
	GEO_V_ACCURACY						NUMBER(24,10),
	CONSTRAINT ck_qss_geolocation CHECK ((
		(GEO_LATITUDE IS NULL AND GEO_LONGITUDE IS NULL AND GEO_H_ACCURACY IS NULL) OR
		(GEO_LATITUDE IS NOT NULL AND GEO_LONGITUDE IS NOT NULL AND GEO_H_ACCURACY IS NOT NULL)
	) AND (
		(GEO_ALTITUDE IS NULL AND GEO_V_ACCURACY IS NULL) OR
		(GEO_ALTITUDE IS NOT NULL AND GEO_V_ACCURACY IS NOT NULL)
	))
);

ALTER TABLE csrimp.quick_survey_type ADD (
	CAPTURE_GEO_LOCATION				NUMBER(1, 0) DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.quick_survey_submission ADD (
	GEO_LATITUDE						NUMBER(24,10),
	GEO_LONGITUDE						NUMBER(24,10),
	GEO_ALTITUDE						NUMBER(24,10),
	GEO_H_ACCURACY						NUMBER(24,10),
	GEO_V_ACCURACY						NUMBER(24,10)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.group_key, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes,
		   qs.score_type_id, st.label score_type_label, st.format_mask score_format_mask,
		   qs.quick_survey_type_id, qst.description quick_survey_type_desc, qs.current_version,
		   qs.from_question_library, qs.lookup_key, qst.capture_geo_location
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.app_sid = d.app_sid AND qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.app_sid = l.app_sid AND qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	  LEFT JOIN csr.score_type st ON st.score_type_id = qs.score_type_id AND st.app_sid = qs.app_sid
	  LEFT JOIN csr.quick_survey_type qst ON qst.quick_survey_type_id = qs.quick_survey_type_id AND qst.app_sid = qs.app_sid
	 WHERE d.survey_version = 0;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../quick_survey_pkg

@../quick_survey_body
@../qs_incident_helper_body
@../schema_body
@../csrimp/imp_body

@update_tail
