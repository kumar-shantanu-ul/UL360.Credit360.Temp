-- Please update version.sql too -- this keeps clean builds in sync
define version=3117
define minor_version=21
@update_header

-- *** DDL ***

-- US10154 start
@..\..\..\filters\db\changes\latest0001
@..\..\..\filters\db\post_migration
-- US10154 stop

-- Create tables
CREATE TABLE SURVEYS.SURVEY(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SURVEY_SID					NUMBER(10, 0)	NOT NULL,
	PARENT_SID					NUMBER(10, 0)	NOT NULL,
	AUDIENCE					VARCHAR2(32) 	NULL,
	LATEST_PUBLISHED_VERSION 	NUMBER(10, 0) 	NULL,
	CONSTRAINT PK_SURVEY PRIMARY KEY (APP_SID, SURVEY_SID)
)
;

CREATE UNIQUE INDEX SURVEYS.IX_SURVEY ON SURVEYS.SURVEY(APP_SID, SURVEY_SID, LATEST_PUBLISHED_VERSION);

-- Alter tables
ALTER TABLE surveys.response ADD (
	FLOW_ITEM_ID		NUMBER(10),
	CAMPAIGN_SID		NUMBER(10),
	REGION_SID			NUMBER(10)
);

ALTER TABLE SURVEYS.SURVEY ADD CONSTRAINT FK_SURVEY_PUBLISHED_VERSION
	FOREIGN KEY (APP_SID, SURVEY_SID, LATEST_PUBLISHED_VERSION)
	REFERENCES SURVEYS.SURVEY_VERSION (APP_SID, SURVEY_SID, SURVEY_VERSION)
;

ALTER TABLE surveys.answer_option
  ADD question_option_others VARCHAR2(4000);
  
-- update all existing survey_version records
BEGIN
	security.user_pkg.LogOnAdmin;

	FOR r IN (
		SELECT app_sid, survey_sid, parent_sid, audience, survey_version
		  FROM surveys.survey_version
	) LOOP
		INSERT INTO surveys.survey(app_sid, survey_sid, parent_sid, audience, latest_published_version)
			 VALUES (r.app_sid, r.survey_sid, r.parent_sid, r.audience, r.survey_version);
	END LOOP;
END;
/

ALTER TABLE surveys.survey_version DROP COLUMN start_dtm;
ALTER TABLE surveys.survey_version DROP COLUMN end_dtm;
ALTER TABLE surveys.survey_version DROP COLUMN parent_sid;
ALTER TABLE surveys.survey_version DROP COLUMN audience;

ALTER TABLE SURVEYS.SURVEY_VERSION ADD CONSTRAINT FK_SURVEY_VERSION
	FOREIGN KEY (APP_SID, SURVEY_SID)
	REFERENCES SURVEYS.SURVEY (APP_SID, SURVEY_SID)
;

ALTER TABLE surveys.condition_link ADD (
	TAG_GROUP_ID		NUMBER(10),
	TAG_ID				NUMBER(10)
);

ALTER TABLE CSR.QS_CAMPAIGN DROP CONSTRAINT FK_QS_CAMP_QS;
ALTER TABLE CSR.DELEG_PLAN_COL_SURVEY DROP CONSTRAINT FK_QUICK_SRV_DLG_PLN_COL_SRV;


CREATE TABLE SURVEYS.QUESTION_OPTION_DATA_SOURCES (
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DATA_SOURCE_ID				NUMBER(10, 0)	NOT NULL,
	DATA_SOURCE_NAME			VARCHAR2(255)	NOT NULL,
	DATA_SOURCE_DESCRIPTION		VARCHAR2(1024)	NOT NULL,
	DATA_SOURCE_HELPER_PKG		VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_DATA_SOURCE PRIMARY KEY (APP_SID, DATA_SOURCE_ID)
);

ALTER TABLE surveys.question_option_data_sources ADD (
	selected					NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_data_source_selected_0_1 CHECK (selected IN (0,1))
);

ALTER TABLE surveys.condition_link ADD (
	sub_type					VARCHAR2(255)
);

ALTER TABLE surveys.question ADD default_lang	VARCHAR2(50);

UPDATE surveys.question q
   SET (default_lang) = (SELECT MAX(tr.language_code)
						   FROM surveys.question_version_tr tr
						  WHERE q.question_id = tr.question_id
						  GROUP BY tr.question_id)
 WHERE EXISTS (
	SELECT 1
	  FROM surveys.question_version_tr tr
	 WHERE q.question_id = tr.question_id
	 GROUP BY tr.question_id);

UPDATE surveys.question q
   SET (default_lang) = 'en'
 WHERE q.default_lang IS NULL;

ALTER TABLE surveys.question MODIFY default_lang	NOT NULL;

ALTER TABLE surveys.clause ADD (
	question_sub_type			VARCHAR2(255)
);

-- *** Grants ***
GRANT EXECUTE ON security.web_pkg TO surveys;
GRANT SELECT ON security.web_resource TO surveys;
grant select, insert, delete on csr.temp_region_sid to surveys;
grant select on csr.qs_campaign to surveys;
grant select on csr.trash to surveys;
GRANT EXECUTE ON csr.campaign_pkg TO surveys;
grant execute on csr.flow_pkg to surveys;
grant execute on csr.csr_data_pkg to surveys;
grant select on csr.flow to surveys;
grant select on csr.flow_state_role to surveys;
grant select on csr.csr_user to surveys;
grant select on csr.region_role_member to surveys;
grant select on csr.v$region to surveys;
grant select on csr.flow_state_role_capability to surveys;

REVOKE SELECT ON chain.filter_value_id_seq FROM surveys;
REVOKE SELECT ON chain.debug_log FROM surveys;
REVOKE SELECT ON chain.filter FROM surveys;
REVOKE SELECT ON chain.filter_field FROM surveys;
REVOKE SELECT, INSERT ON chain.filter_value FROM surveys;
REVOKE SELECT ON chain.saved_filter FROM surveys;
REVOKE SELECT ON chain.compound_filter FROM surveys;
REVOKE SELECT ON chain.v$filter_field FROM surveys;
REVOKE SELECT, INSERT, delete ON chain.tt_filter_object_data FROM surveys;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (99, 'API FileSharing', 'EnableFileSharingApi', 'Enables the FileSharing Api.');

BEGIN
	security.user_pkg.LogonAdmin;
	-- Create web resources for all surveys that don't already have one
	FOR r IN (
		SELECT DISTINCT survey_sid, w.web_root_sid_id, pwr.path parent_path, so.name
		  FROM surveys.survey s
		  JOIN security.securable_object so ON s.survey_sid = so.sid_id
		  JOIN security.website w ON s.app_sid = w.application_sid_id
		  JOIN security.web_resource pwr ON s.parent_sid = pwr.sid_id
		  LEFT JOIN security.web_resource wr ON s.survey_sid = wr.sid_id
		 WHERE wr.sid_id IS NULL
	) LOOP
		INSERT INTO security.web_resource(sid_id, web_root_sid_id, path, rewrite_path)
		VALUES (r.survey_sid, r.web_root_sid_id, r.parent_path || '/' || r.name,
			'/csr/site/surveys/view.acds?surveySid='||r.survey_sid||'&'||'testMode=false');
	END LOOP;
END;
/

BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE surveys.question_version
	   SET display_type = 'repeater'
	 WHERE question_id IN (
		SELECT question_id
		  FROM surveys.question
		 WHERE question_type = 'matrixset'
	 );
END;
/

-- ** New package grants **

CREATE OR REPLACE PACKAGE surveys.campaign_pkg IS END;
/

grant execute on surveys.campaign_pkg to web_user;


-- *** Conditional Packages ***

-- *** Packages ***
--@..\surveys\survey_pkg
--@..\surveys\campaign_pkg
--@..\surveys\question_library_pkg
--@..\surveys\condition_pkg
@..\enable_pkg
--@..\surveys\question_library_report_pkg

--@..\surveys\condition_body
--@..\surveys\question_library_body
--@..\surveys\survey_body
--@..\surveys\campaign_body
--@..\surveys\question_library_report_body

@..\quick_survey_pkg
@..\campaign_pkg
@..\flow_pkg

@..\integration_api_body
@..\campaign_body
@..\enable_body
@..\quick_survey_body
@..\flow_body

@update_tail

