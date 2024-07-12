-- Please update version.sql too -- this keeps clean builds in sync
define version=3188
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_QS_INC_FIELD_ROW AS 
  OBJECT ( 
	ORACLE_COLUMN	VARCHAR2(30),
	BIND_TYPE		VARCHAR2(4),
	TEXT_VALUE		CLOB,
	NUM_VALUE		NUMBER(24,10),
	DATE_VALUE		DATE
  );
/
CREATE OR REPLACE TYPE CSR.T_QS_INC_FIELD_TABLE AS 
  TABLE OF CSR.T_QS_INC_FIELD_ROW;
/

-- Alter tables
ALTER TABLE csr.quick_survey ADD lookup_key VARCHAR2(256);
ALTER TABLE csrimp.quick_survey ADD lookup_key VARCHAR2(256);

CREATE UNIQUE INDEX csr.ix_quick_survey_lk ON csr.quick_survey(app_sid, NVL(UPPER(lookup_key), 'QS:' || survey_sid));

-- *** Grants ***
GRANT SELECT, REFERENCES ON cms.fk_cons TO csr;
GRANT SELECT, REFERENCES ON cms.fk_cons_col TO csr;
GRANT SELECT, REFERENCES ON cms.uk_cons TO csr;
GRANT SELECT, REFERENCES ON cms.uk_cons_col TO csr;

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
		   qs.from_question_library, qs.lookup_key
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
@../qs_incident_helper_pkg

@../quick_survey_body
@../qs_incident_helper_body
@../schema_body
@../csrimp/imp_body

@update_tail
