-- Please update version.sql too -- this keeps clean builds in sync
define version=2751
define minor_version=0
define is_combined=1
@update_header

-- Clean
--ALTER TABLE csr.dataview DROP COLUMN version_num;
--ALTER TABLE csrimp.dataview DROP COLUMN version_num;
--DROP TABLE csr.dataview_history;
--DROP TABLE csrimp.dataview_history;
--ALTER TABLE csr.customer DROP COLUMN max_dataview_history;
--ALTER TABLE csrimp.customer DROP COLUMN max_dataview_history;

-- *** DDL ***
-- Create tables
CREATE TABLE csr.dataview_history (
    app_sid NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL, 
    dataview_sid NUMBER(10,0) NOT NULL,    
    version_num NUMBER(10,0) NOT NULL,
    name VARCHAR2(256) NOT NULL,
    start_dtm DATE NOT NULL, 
	end_dtm DATE, 
	group_by VARCHAR2(128) NOT NULL, 
	chart_config_xml CLOB, 
	chart_style_xml CLOB, 
	pos NUMBER(10,0) NOT NULL, 
	description VARCHAR2(2048), 
	dataview_type_id NUMBER(6,0) NOT NULL, 
	use_unmerged NUMBER(1,0) NOT NULL, 
	use_backfill NUMBER(1,0) NOT NULL, 
	use_pending NUMBER(1,0) NOT NULL, 
	show_calc_trace NUMBER(1,0) NOT NULL, 
	show_variance NUMBER(1,0) NOT NULL, 
	sort_by_most_recent NUMBER(1,0) NOT NULL, 
	include_parent_region_names NUMBER(10,0) NOT NULL, 
	last_updated_dtm DATE NOT NULL, 
	last_updated_sid NUMBER(10,0), 
	rank_filter_type NUMBER(10,0) NOT NULL, 
	rank_limit_left NUMBER(10,0) NOT NULL, 
	rank_ind_sid NUMBER(10,0), 
	rank_limit_right NUMBER(10,0) NOT NULL, 
	rank_limit_left_type NUMBER(10,0) NOT NULL, 
	rank_limit_right_type NUMBER(10,0) NOT NULL, 
	rank_reverse NUMBER(1,0) NOT NULL, 
	region_grouping_tag_group NUMBER(10,0), 
	anonymous_region_names NUMBER(1,0) NOT NULL, 
	include_notes_in_table NUMBER(1,0) NOT NULL, 
	show_region_events NUMBER(1,0) NOT NULL, 
	suppress_unmerged_data_message NUMBER(1,0) NOT NULL, 
	period_set_id NUMBER(10,0) NOT NULL, 
	period_interval_id NUMBER(10,0) NOT NULL, 
    CONSTRAINT pk_dataview_history PRIMARY KEY (app_sid, dataview_sid, version_num),
    CONSTRAINT fk_dataview_hst_user FOREIGN KEY (app_sid, last_updated_sid) 
        REFERENCES csr.csr_user (app_sid, csr_user_sid),
    CONSTRAINT fk_dataview_hst_cmr FOREIGN KEY (app_sid) 
        REFERENCES csr.customer (app_sid)
    -- no other constraints (this is just a history table, orphaning is okay)
);

CREATE TABLE csrimp.dataview_history (
	csrimp_session_id NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    dataview_sid NUMBER(10,0) NOT NULL,    
    version_num NUMBER(10,0) NOT NULL,
    name VARCHAR2(256) NOT NULL,
    start_dtm DATE NOT NULL, 
	end_dtm DATE, 
	group_by VARCHAR2(128) NOT NULL, 
	chart_config_xml CLOB, 
	chart_style_xml CLOB, 
	pos NUMBER(10,0) NOT NULL, 
	description VARCHAR2(2048), 
	dataview_type_id NUMBER(6,0) NOT NULL, 
	use_unmerged NUMBER(1,0) NOT NULL, 
	use_backfill NUMBER(1,0) NOT NULL, 
	use_pending NUMBER(1,0) NOT NULL, 
	show_calc_trace NUMBER(1,0) NOT NULL, 
	show_variance NUMBER(1,0) NOT NULL, 
	sort_by_most_recent NUMBER(1,0) NOT NULL, 
	include_parent_region_names NUMBER(10,0) NOT NULL, 
	last_updated_dtm DATE NOT NULL, 
	last_updated_sid NUMBER(10,0), 
	rank_filter_type NUMBER(10,0) NOT NULL, 
	rank_limit_left NUMBER(10,0) NOT NULL, 
	rank_ind_sid NUMBER(10,0), 
	rank_limit_right NUMBER(10,0) NOT NULL, 
	rank_limit_left_type NUMBER(10,0) NOT NULL, 
	rank_limit_right_type NUMBER(10,0) NOT NULL, 
	rank_reverse NUMBER(1,0) NOT NULL, 
	region_grouping_tag_group NUMBER(10,0), 
	anonymous_region_names NUMBER(1,0) NOT NULL, 
	include_notes_in_table NUMBER(1,0) NOT NULL, 
	show_region_events NUMBER(1,0) NOT NULL, 
	suppress_unmerged_data_message NUMBER(1,0) NOT NULL, 
	period_set_id NUMBER(10,0) NOT NULL, 
	period_interval_id NUMBER(10,0) NOT NULL, 
    CONSTRAINT pk_dataview_history PRIMARY KEY (csrimp_session_id, dataview_sid, version_num),
    CONSTRAINT fk_dataview_history_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE CSR.PORTAL_DASHBOARD (
  APP_SID               NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
  PORTAL_SID            NUMBER(10, 0)     NOT NULL,
  PORTAL_GROUP          VARCHAR2(50)      NOT NULL,
  MENU_SID              NUMBER(10, 0),
  MESSAGE               VARCHAR2(2048),
  CONSTRAINT PK_PORTAL_DASHBOARD_SID PRIMARY KEY (APP_SID, PORTAL_SID),
  CONSTRAINT UK_PORTAL_DASHBOARD_GROUP UNIQUE (APP_SID, PORTAL_GROUP),
  CONSTRAINT UK_PORTAL_MENU_SID UNIQUE (APP_SID, MENU_SID)
);

CREATE TABLE CSR.SCHEDULED_STORED_PROC (
	APP_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	SP					VARCHAR2(255)     NOT NULL,
	ARGS				VARCHAR2(1024),
	DESCRIPTION			VARCHAR2(1024),
	INTRVAL				CHAR NOT NULL,
	FREQUENCY			NUMBER(10, 0)	NOT NULL,
	LAST_RUN_DTM		TIMESTAMP,
	LAST_RESULT			NUMBER(10, 0),
	LAST_RESULT_MSG		VARCHAR2(1024),
	LAST_RESULT_EX		CLOB,
	NEXT_RUN_DTM		TIMESTAMP	DEFAULT TRUNC(SYSDATE, 'MI') NOT NULL,
	CONSTRAINT PK_SSP PRIMARY KEY (APP_SID, SP, ARGS)
);

CREATE TABLE CSRIMP.SCHEDULED_STORED_PROC (
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SP					VARCHAR2(255)     NOT NULL,
	ARGS				VARCHAR2(1024),
	DESCRIPTION			VARCHAR2(1024),
	INTRVAL				CHAR NOT NULL, 
	FREQUENCY			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_SSP PRIMARY KEY (CSRIMP_SESSION_ID, SP, ARGS)
);

CREATE GLOBAL TEMPORARY TABLE CMS.TEMP_TREE_PATH
(
	T_NAME			VARCHAR2(256),
	ID				NUMBER(10),
	DESCRIPTION		VARCHAR2(1023),
	PATH			VARCHAR2(4000)
) ON COMMIT DELETE ROWS;

-- Alter tables
ALTER TABLE csr.dataview ADD version_num NUMBER(10,0) NULL;
ALTER TABLE csrimp.dataview ADD version_num NUMBER(10, 0) NULL;
ALTER TABLE csr.customer ADD max_dataview_history NUMBER(10, 0) DEFAULT 0 NULL;
ALTER TABLE csrimp.customer ADD max_dataview_history NUMBER(10, 0) DEFAULT 0 NULL;

alter table csr.temp_delegation_detail add rid number(10);
alter table csr.temp_delegation_detail add root_delegation_sid number(10);
alter table csr.temp_delegation_detail add parent_sid number(10);

ALTER TABLE csr.quick_survey_question ADD count_question NUMBER(1) NULL;
UPDATE csr.quick_survey_question SET count_question = 0 WHERE count_question IS NULL;
ALTER TABLE csr.quick_survey_question MODIFY count_question DEFAULT 0 NOT NULL;
ALTER TABLE csr.quick_survey_question ADD CONSTRAINT chk_qsq_count_question CHECK (count_question=0 OR (count_question=1 AND question_type 
	IN('note', 'date', 'number', 'radio', 'radiorow', 'regionpicker', 'files', 'rtquestion', 'slider')));

ALTER TABLE csr.quick_survey_type ADD enable_question_count NUMBER(1) NULL;
UPDATE csr.quick_survey_type SET enable_question_count = 0 WHERE enable_question_count IS NULL;
ALTER TABLE csr.quick_survey_type MODIFY enable_question_count DEFAULT 0 NOT NULL;
ALTER TABLE csr.quick_survey_type ADD CONSTRAINT chk_qst_enable_question_count CHECK (enable_question_count IN (0,1));

ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION ADD REMEMBER_ANSWER NUMBER(1) NULL;
UPDATE CSRIMP.QUICK_SURVEY_QUESTION SET REMEMBER_ANSWER = 0;
ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION MODIFY REMEMBER_ANSWER NOT NULL;

ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION ADD COUNT_QUESTION NUMBER(1);
UPDATE CSRIMP.QUICK_SURVEY_QUESTION SET COUNT_QUESTION = 0;
ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION MODIFY COUNT_QUESTION NOT NULL;

ALTER TABLE CSRIMP.QUICK_SURVEY_TYPE ADD enable_question_count NUMBER(1);
UPDATE CSRIMP.QUICK_SURVEY_TYPE SET enable_question_count = 0;
ALTER TABLE CSRIMP.QUICK_SURVEY_TYPE MODIFY enable_question_count NOT NULL;

--rename temp_table to avoid open session issues
CREATE GLOBAL TEMPORARY TABLE CSR.TEMPOR_QUESTION (
	QUESTION_ID				NUMBER(10),
	PARENT_ID				NUMBER(10),
	POS						NUMBER(10),
	LABEL					VARCHAR2(4000),
	QUESTION_TYPE			VARCHAR2(40),
	SCORE					NUMBER(13,3),
	MAX_SCORE				NUMBER(13,3),
	UPLOAD_SCORE			NUMBER(13,3),
	LOOKUP_KEY				VARCHAR2(255),
	INVERT_SCORE			VARCHAR2(255),
	CUSTOM_QUESTION_TYPE_ID	NUMBER(10),
	WEIGHT					NUMBER(15,5),
	DONT_NORMALISE_SCORE	NUMBER(1),
	HAS_SCORE_EXPRESSION	NUMBER(1),
	HAS_MAX_SCORE_EXPR		NUMBER(1),
	REMEMBER_ANSWER			NUMBER(1),
	COUNT_QUESTION			NUMBER(1)
) ON COMMIT DELETE ROWS;

ALTER TABLE CHAIN.CARD_GROUP_CARD DROP CONSTRAINT RefCUSTOMER_OPTIONS224;
ALTER TABLE CHAIN.CARD_INIT_PARAM DROP CONSTRAINT RefCUSTOMER_OPTIONS1159;
ALTER TABLE CHAIN.COMPOUND_FILTER DROP CONSTRAINT FK_CMP_FIL_APP_SID;
ALTER TABLE CHAIN.FILTER_FIELD DROP CONSTRAINT FK_FLT_FLD_APP_SID;
ALTER TABLE CHAIN.FILTER_VALUE DROP CONSTRAINT FK_FLT_VAL_APP_SID;

ALTER TABLE CSR.TPL_REPORT_TAG_LOGGING_FORM ADD SAVED_FILTER_SID NUMBER(10);
ALTER TABLE CSR.TPL_REPORT_TAG_LOGGING_FORM DROP CONSTRAINT CHK_TPL_REP_LGN_FORM_FILTER;
ALTER TABLE CSR.TPL_REPORT_TAG_LOGGING_FORM ADD CONSTRAINT CHK_TPL_REP_LGN_FORM_FILTER CHECK 
	((form_sid IS NULL AND filter_sid IS NULL) OR (form_sid IS NULL AND saved_filter_sid IS NULL) OR (saved_filter_sid IS NULL AND filter_sid IS NULL))
;

ALTER TABLE CSRIMP.TPL_REPORT_TAG_LOGGING_FORM ADD SAVED_FILTER_SID NUMBER(10);
ALTER TABLE CSRIMP.TPL_REPORT_TAG_LOGGING_FORM DROP CONSTRAINT CHK_TPL_REP_LGN_FORM_FILTER;
ALTER TABLE CSRIMP.TPL_REPORT_TAG_LOGGING_FORM ADD CONSTRAINT CHK_TPL_REP_LGN_FORM_FILTER CHECK 
	((form_sid IS NULL AND filter_sid IS NULL) OR (form_sid IS NULL AND saved_filter_sid IS NULL) OR (saved_filter_sid IS NULL AND filter_sid IS NULL))
;

ALTER TABLE cms.cms_aggregate_type ADD (
	score_type_id			NUMBER(10)
);

ALTER TABLE csrimp.cms_aggregate_type ADD (
	score_type_id			NUMBER(10)
);

ALTER TABLE cms.cms_aggregate_type ADD (
	format_mask				VARCHAR2(50)
);

ALTER TABLE csrimp.cms_aggregate_type ADD (
	format_mask				VARCHAR2(50)
);

ALTER TABLE chain.saved_filter_alert_subscriptn ADD (
	error_message			VARCHAR2(4000)
);

ALTER TABLE csrimp.chain_saved_fltr_alrt_sbscrptn ADD (
	error_message			VARCHAR2(4000)
);

ALTER TABLE chain.saved_filter ADD (
	company_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
	CONSTRAINT fk_saved_filter_company FOREIGN KEY (app_sid, company_sid)
		REFERENCES chain.company (app_sid, company_sid)
);

ALTER TABLE csrimp.chain_saved_filter ADD (
	company_sid				NUMBER(10)
);

ALTER TABLE chain.filter_field ADD (
	period_set_id			NUMBER(10),
	period_interval_id		NUMBER(10)
);

ALTER TABLE csrimp.chain_filter_field ADD (
	period_set_id			NUMBER(10),
	period_interval_id		NUMBER(10)
);

ALTER TABLE chain.filter_value ADD (
	period_set_id			NUMBER(10),
	period_interval_id		NUMBER(10),
	start_period_id			NUMBER(10)
);

ALTER TABLE csrimp.chain_filter_value ADD (
	period_set_id			NUMBER(10),
	period_interval_id		NUMBER(10),
	start_period_id			NUMBER(10)
);

create index chain.ix_fltr_field_period_set on chain.filter_field (app_sid, period_set_id, period_interval_id);
create index chain.ix_fltr_value_period_interval on chain.filter_value (app_sid, period_set_id, period_interval_id, start_period_id);

alter table csr.trainer add company varchar2(255);
alter table csr.trainer add address varchar2(2000);
alter table csr.trainer add contact_details varchar2(255);
alter table csr.trainer add notes varchar2(2000);
-- *** Grants ***
create or replace package csr.ssp_pkg as
procedure dummy;
end;
/
create or replace package body csr.ssp_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.dataview_history TO web_user;
GRANT INSERT ON csr.dataview_history TO csrimp;
grant select on csr.calc_tag_dependency to chain;
grant execute on csr.calc_pkg to chain;
GRANT SELECT, REFERENCES ON csr.score_type TO cms;
GRANT SELECT ON csr.score_threshold TO cms;
GRANT SELECT ON csr.period_set TO chain;
GRANT SELECT, REFERENCES ON csr.period_interval TO chain;
GRANT SELECT ON csr.period TO chain;
GRANT SELECT ON csr.period_dates TO chain;
GRANT SELECT, REFERENCES ON csr.period_interval_member TO chain;
GRANT EXECUTE ON csr.period_pkg TO chain;
GRANT EXECUTE ON csr.ssp_pkg TO web_user;
grant select, insert on csr.scheduled_stored_proc to csrimp;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.CARD_GROUP_CARD ADD CONSTRAINT FK_CARD_GROUP_CARD_APP FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER(APP_SID);
ALTER TABLE CHAIN.CARD_INIT_PARAM ADD CONSTRAINT FK_CARD_INIT_PARAM_APP FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER(APP_SID);
ALTER TABLE CHAIN.COMPOUND_FILTER ADD CONSTRAINT FK_CMP_FIL_APP_SID  FOREIGN KEY (APP_SID) REFERENCES CSR.CUSTOMER(APP_SID);
ALTER TABLE csr.tpl_report_tag_logging_form ADD CONSTRAINT fk_tpl_rprt_tag_lf_saved_fltr 
	FOREIGN KEY (app_sid, saved_filter_sid)
	REFERENCES chain.saved_filter (app_sid, saved_filter_sid);
ALTER TABLE CMS.CMS_AGGREGATE_TYPE ADD CONSTRAINT FK_CMS_AGG_TYPE_SCORE_TYPE
	FOREIGN KEY (APP_SID, SCORE_TYPE_ID)
	REFERENCES CSR.SCORE_TYPE (APP_SID, SCORE_TYPE_ID);

ALTER TABLE chain.filter_field ADD CONSTRAINT fk_fltr_field_period_set
	FOREIGN KEY (app_sid, period_set_id, period_interval_id)
	REFERENCES csr.period_interval(app_sid, period_set_id, period_interval_id);

ALTER TABLE chain.filter_value ADD CONSTRAINT fk_fltr_value_period_interval
	FOREIGN KEY (app_sid, period_set_id, period_interval_id, start_period_id)
	REFERENCES csr.period_interval_member(app_sid, period_set_id, period_interval_id, start_period_id);

-- *** Views ***
CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		   fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		   fv.compound_filter_id_value, fv.saved_filter_sid_value, fv.pos,
		   NVL(NVL(fv.description, CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' ELSE
		   NVL(NVL(r.description, cu.full_name), cr.name) END), fv.str_value) description, ff.group_by_index,
		   f.compound_filter_id, ff.show_all, ff.period_set_id, ff.period_interval_id, fv.start_period_id
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;

CREATE OR REPLACE VIEW CHAIN.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, ff.show_all, ff.group_by_index,
		   f.compound_filter_id, ff.top_n, ff.bottom_n, ff.column_sid, ff.period_set_id,
		   ff.period_interval_id
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id;
	  
-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (49, 'Delegation Reports', 'EnableDelegationReports', 'Enables delegation reporting. Adds a menu item to the admin menu.', 0);
EXCEPTION WHEN dup_val_on_index THEN 
	NULL;
END;
/

BEGIN
	FOR r in (
		SELECT app_sid
		  FROM csr.customer
		 WHERE app_sid NOT IN (
			SELECT app_sid
			  FROM csr.issue_type
			 WHERE issue_type_id = 1
			)
	) LOOP
		INSERT INTO csr.issue_type 
			(app_sid, issue_type_id, label)
		VALUES
			(r.app_sid, 1, 'Data entry form');
	END LOOP;
END;
/

DECLARE
    v_id    NUMBER(10);
BEGIN   
    security.user_pkg.logonadmin;
    security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRPortalDashboard', 'csr.portal_dashboard_pkg', null, v_Id);
EXCEPTION
    WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
        NULL;
END;
/

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (48, 'Multiple dashboards', 'EnableMultipleDashboards', 'Enables the ability to create multiple dashboards. Adds a menu item to the admin menu.', 0);

DELETE FROM csr.module
 WHERE module_id = 18;

BEGIN
	-- set up card groups for filtering of core modules where these aren't set up already
	
	-- Actions
	FOR r IN (
		SELECT app_sid
		  FROM csr.customer c
		 WHERE NOT EXISTS (SELECT * FROM chain.card_group_card cgc WHERE cgc.app_sid = c.app_sid AND cgc.card_group_id = 25)
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		SELECT r.app_sid, 25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, card_id, 0
		  FROM chain.card
		  WHERE js_class_type = 'Credit360.Filters.Issues.StandardIssuesFilter'
		 UNION
		SELECT r.app_sid, 25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, card_id, 1
		  FROM chain.card
		 WHERE js_class_type = 'Credit360.Filters.Issues.IssuesCustomFieldsFilter'
		 UNION
		SELECT r.app_sid, 25/*chain.filter_pkg.FILTER_TYPE_ISSUES*/, card_id, 2
		  FROM chain.card
		 WHERE js_class_type = 'Credit360.Filters.Issues.IssuesFilterAdapter';
	END LOOP;
	
	-- CMS
	FOR r IN (
		SELECT app_sid
		  FROM csr.customer c
		 WHERE NOT EXISTS (SELECT * FROM chain.card_group_card cgc WHERE cgc.app_sid = c.app_sid AND cgc.card_group_id = 43)
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		SELECT r.app_sid, 43/*chain.filter_pkg.FILTER_TYPE_CMS*/, card_id, 0
		  FROM chain.card
		  WHERE js_class_type = 'NPSL.Cms.Filters.CmsFilter';
	END LOOP;
END;
/

-- set company sid on chain filters
UPDATE chain.saved_filter sf
   SET company_sid = ( 
		SELECT company_sid 
		  FROM (
			SELECT company_sid, saved_filter_sid
			  FROM (
			   SELECT saved_filter_sid, c.company_sid, ROW_NUMBER() OVER(PARTITION BY saved_filter_sid ORDER BY lvl) rn
				 FROM (-- look up the SO tree to find what company we're sitting under if any
				  SELECT connect_by_root sid_id saved_filter_sid, sid_id parent_sid, level lvl
					FROM security.securable_object
				   START WITH sid_id IN (SELECT saved_filter_sid FROM chain.saved_filter WHERE card_group_id = 23)
				  CONNECT BY PRIOR parent_sid_id = sid_id -- going up
				  ) so 
				  JOIN chain.company c on so.parent_sid = c.company_sid
				)
			 WHERE rn = 1 -- choose the first company
			 UNION 
			SELECT cu.default_company_sid company_sid, saved_filter_sid
			 FROM (-- look up the SO tree to find what user we're sitting under if any
			  SELECT connect_by_root sid_id saved_filter_sid, sid_id parent_sid, level lvl
				FROM security.securable_object
			   START WITH sid_id IN (SELECT saved_filter_sid FROM chain.saved_filter WHERE card_group_id = 23)
			  CONNECT BY PRIOR parent_sid_id = sid_id -- going up
			  ) so 
			  JOIN chain.chain_user cu on so.parent_sid = cu.user_sid
			 WHERE cu.default_company_sid IS NOT NULL
			) x
		 WHERE x.saved_filter_sid = sf.saved_filter_sid
	)
 WHERE card_group_id = 23
   AND company_sid IS NULL;

BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		  job_name            => 'csr.RunClientSPs',
		  job_type            => 'PLSQL_BLOCK',
		  job_action          => 'BEGIN csr.ssp_pkg.RunScheduledStoredProcs(); END;',
		  job_class           => 'low_priority_job',
		  repeat_interval     => 'FREQ=MINUTELY;INTERVAL=15;',
		  enabled             => TRUE,
		  auto_drop           => FALSE,
		  start_date          => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		  comments            => 'Run client store procedures');
END;
/

-- ** New package grants **
create or replace package csr.portal_dashboard_pkg as
procedure dummy;
end;
/
create or replace package body csr.portal_dashboard_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on csr.portal_dashboard_pkg to web_user;
grant execute on CSR.portal_dashboard_pkg to security;

-- *** Packages ***
@..\..\..\aspen2\cms\db\filter_pkg
@..\automated_export_import_pkg
@..\chain\filter_pkg
@../delegation_pkg
@../pending_pkg
@../enable_pkg
@../quick_survey_pkg
@../chain/company_pkg
@..\portal_dashboard_pkg
@../csrimp/imp_pkg
@../schema_pkg
@../ssp_pkg
@../region_tree_pkg

@..\..\..\aspen2\cms\db\filter_body
@..\chain\filter_body
@../csrimp/imp_body
@../schema_body
@../ssp_body
@../imp_body
@../region_tree_body
@..\portal_dashboard_body
@..\portlet_body
@..\chain\company_filter_body
@../chain/company_body
@../quick_survey_body
@../enable_body
@../delegation_body
@../pending_body
@..\automated_export_import_body
@../dataview_body
@../templated_report_body
@../csr_app_body

@update_tail
