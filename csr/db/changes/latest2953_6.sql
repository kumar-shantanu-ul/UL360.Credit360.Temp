-- Please update version.sql too -- this keeps clean builds in sync
define version=2953
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.aggregate_type_config (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	card_group_id			NUMBER(10) NOT NULL,
	aggregate_type_id		NUMBER(10) NOT NULL,
	label					VARCHAR2(1024) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	enabled					NUMBER(1) DEFAULT 1 NOT NULL,
	group_sid				NUMBER(10),
	company_tab_id			NUMBER(10),
	path					VARCHAR2(1024),
	CONSTRAINT chk_agg_typ_cfg_enbld_1_0 CHECK (enabled IN (1, 0))
);

CREATE UNIQUE INDEX chain.uk_aggregate_type_config ON chain.aggregate_type_config(app_sid, card_group_id, aggregate_type_id, company_tab_id, path);

CREATE SEQUENCE CSR.SCORE_TYPE_AGG_TYPE_ID_SEQ;
CREATE TABLE CSR.SCORE_TYPE_AGG_TYPE (
	APP_SID							NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	SCORE_TYPE_AGG_TYPE_ID			NUMBER(10)	NOT NULL,
	ANALYTIC_FUNCTION				NUMBER(10)	NOT NULL,
	SCORE_TYPE_ID					NUMBER(10)	NOT NULL,
	APPLIES_TO_NC_SCORE				NUMBER(1)	DEFAULT 0 NOT NULL,
	APPLIES_TO_PRIMARY_AUDIT_SURVY	NUMBER(1)	DEFAULT 0 NOT NULL,
	IA_TYPE_SURVEY_GROUP_ID			NUMBER(10),
	CONSTRAINT PK_SCORE_TYPE_AGG_TYPE PRIMARY KEY (APP_SID, SCORE_TYPE_AGG_TYPE_ID),
	CONSTRAINT CHK_SCORE_TYPE_AGG_TYPE CHECK (
		(APPLIES_TO_NC_SCORE = 1 AND APPLIES_TO_PRIMARY_AUDIT_SURVY = 0 AND IA_TYPE_SURVEY_GROUP_ID IS NULL) OR
		(APPLIES_TO_NC_SCORE = 0 AND APPLIES_TO_PRIMARY_AUDIT_SURVY = 1 AND IA_TYPE_SURVEY_GROUP_ID IS NULL) OR
		(APPLIES_TO_NC_SCORE = 0 AND APPLIES_TO_PRIMARY_AUDIT_SURVY = 0 AND IA_TYPE_SURVEY_GROUP_ID IS NOT NULL)
	)
);

CREATE TABLE csrimp.chain_aggregate_type_config (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	card_group_id			NUMBER(10) NOT NULL,
	aggregate_type_id		NUMBER(10) NOT NULL,
	label					VARCHAR2(1024) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	enabled					NUMBER(1) NOT NULL,
	group_sid				NUMBER(10),
	company_tab_id			NUMBER(10),
	path					VARCHAR2(1024),
	CONSTRAINT chk_agg_typ_cfg_enbld_1_0 CHECK (enabled IN (1, 0)),
	CONSTRAINT FK_CHAIN_AGG_TYP_CFG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE UNIQUE INDEX csrimp.uk_chain_agg_type_config ON csrimp.chain_aggregate_type_config(csrimp_session_id, card_group_id, aggregate_type_id, company_tab_id, path);

CREATE TABLE CSRIMP.SCORE_TYPE_AGG_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SCORE_TYPE_AGG_TYPE_ID			NUMBER(10)	NOT NULL,
	ANALYTIC_FUNCTION				NUMBER(10)	NOT NULL,
	SCORE_TYPE_ID					NUMBER(10)	NOT NULL,
	APPLIES_TO_NC_SCORE				NUMBER(1)	NOT NULL,
	APPLIES_TO_PRIMARY_AUDIT_SURVY	NUMBER(1)	NOT NULL,
	IA_TYPE_SURVEY_GROUP_ID			NUMBER(10),
	CONSTRAINT PK_SCORE_TYPE_AGG_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, SCORE_TYPE_AGG_TYPE_ID),
	CONSTRAINT CHK_SCORE_TYPE_AGG_TYPE CHECK (
		(APPLIES_TO_NC_SCORE = 1 AND APPLIES_TO_PRIMARY_AUDIT_SURVY = 0 AND IA_TYPE_SURVEY_GROUP_ID IS NULL) OR
		(APPLIES_TO_NC_SCORE = 0 AND APPLIES_TO_PRIMARY_AUDIT_SURVY = 1 AND IA_TYPE_SURVEY_GROUP_ID IS NULL) OR
		(APPLIES_TO_NC_SCORE = 0 AND APPLIES_TO_PRIMARY_AUDIT_SURVY = 0 AND IA_TYPE_SURVEY_GROUP_ID IS NOT NULL)
	),
	CONSTRAINT FK_SCORE_TYPE_AGG_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_SCORE_TYPE_AGG_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SCORE_TYPE_AGG_TYPE_ID			NUMBER(10)	NOT NULL,
	NEW_SCORE_TYPE_AGG_TYPE_ID			NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_SCORE_TYPE_AGG_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SCORE_TYPE_AGG_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_SCORE_TYPE_AGG_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_SCORE_TYPE_AGG_TYPE_ID) USING INDEX,
    CONSTRAINT FK_MAP_SCORE_TYPE_AGG_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CHAIN.CUSTOMER_AGGREGATE_TYPE ADD SCORE_TYPE_AGG_TYPE_ID NUMBER(10);
ALTER TABLE CHAIN.CUSTOMER_AGGREGATE_TYPE DROP CONSTRAINT CHK_CUSTOMER_AGGREGATE_TYPE;
ALTER TABLE CHAIN.CUSTOMER_AGGREGATE_TYPE ADD CONSTRAINT CHK_CUSTOMER_AGGREGATE_TYPE
	CHECK ((cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL AND score_type_agg_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL AND score_type_agg_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL AND score_type_agg_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NOT NULL AND meter_aggregate_type_id IS NULL AND score_type_agg_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NOT NULL AND score_type_agg_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL AND score_type_agg_type_id IS NOT NULL));

create index chain.ix_customer_aggr_scr_typ_agg on chain.customer_aggregate_type (app_sid, score_type_agg_type_id);

ALTER TABLE CSR.SCORE_TYPE_AGG_TYPE ADD CONSTRAINT FK_SCORE_TYP_AGG_TYP_SCORE_TYP
	FOREIGN KEY (APP_SID, SCORE_TYPE_ID)
	REFERENCES CSR.SCORE_TYPE (APP_SID, SCORE_TYPE_ID);

create index csr.ix_score_type_agg_typ_scr_type on csr.score_type_agg_type(app_sid, score_type_id);

DROP INDEX CHAIN.UK_CUSTOMER_AGGREGATE_TYPE;
CREATE UNIQUE INDEX CHAIN.UK_CUSTOMER_AGGREGATE_TYPE ON CHAIN.CUSTOMER_AGGREGATE_TYPE (
		APP_SID, CARD_GROUP_ID, CMS_AGGREGATE_TYPE_ID, INITIATIVE_METRIC_ID, IND_SID, FILTER_PAGE_IND_INTERVAL_ID, METER_AGGREGATE_TYPE_ID, SCORE_TYPE_AGG_TYPE_ID)
;

ALTER TABLE CSRIMP.CHAIN_CUSTOMER_AGGREGATE_TYPE ADD SCORE_TYPE_AGG_TYPE_ID NUMBER(10);
ALTER TABLE CSRIMP.CHAIN_CUSTOMER_AGGREGATE_TYPE DROP CONSTRAINT CHK_CUSTOMER_AGGREGATE_TYPE;
ALTER TABLE CSRIMP.CHAIN_CUSTOMER_AGGREGATE_TYPE ADD CONSTRAINT CHK_CUSTOMER_AGGREGATE_TYPE
	CHECK ((cms_aggregate_type_id IS NOT NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL AND score_type_agg_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NOT NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL AND score_type_agg_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NOT NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL AND score_type_agg_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NOT NULL AND meter_aggregate_type_id IS NULL AND score_type_agg_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NOT NULL AND score_type_agg_type_id IS NULL)
	   OR (cms_aggregate_type_id IS NULL AND initiative_metric_id IS NULL AND ind_sid IS NULL AND filter_page_ind_interval_id IS NULL AND meter_aggregate_type_id IS NULL AND score_type_agg_type_id IS NOT NULL));

DROP INDEX CSRIMP.UK_CUSTOMER_AGGREGATE_TYPE;
CREATE UNIQUE INDEX CSRIMP.UK_CUSTOMER_AGGREGATE_TYPE ON CSRIMP.CHAIN_CUSTOMER_AGGREGATE_TYPE (
		CSRIMP_SESSION_ID, CARD_GROUP_ID, CMS_AGGREGATE_TYPE_ID, INITIATIVE_METRIC_ID, IND_SID, FILTER_PAGE_IND_INTERVAL_ID, METER_AGGREGATE_TYPE_ID, SCORE_TYPE_AGG_TYPE_ID)
;

-- *** Grants ***
grant select, references on csr.score_type_agg_type to chain;
grant select, insert, update, delete on csrimp.chain_aggregate_type_config to web_user;
grant select,insert,update,delete on csrimp.score_type_agg_type to web_user;
grant insert on chain.aggregate_type_config to csrimp;
grant insert on csr.score_type_agg_type to csrimp;
grant select on csr.score_type_agg_type_id_seq to csrimp;

-- missing from a previous change scripts
grant select,insert,update,delete on csrimp.flow_alert_helper to web_user;
grant select,insert,update,delete on csrimp.internal_audit_type_group to web_user;

-- to fix zap
GRANT UPDATE ON csr.tpl_report_tag_dataview TO chain;
GRANT UPDATE ON csr.tpl_report_tag_logging_form TO chain;

GRANT SELECT ON chain.aggregate_type_config TO csr;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.CUSTOMER_AGGREGATE_TYPE ADD CONSTRAINT FK_SCORE_TYPE_AGG_TYPE FOREIGN KEY (APP_SID, SCORE_TYPE_AGG_TYPE_ID)
	REFERENCES CSR.SCORE_TYPE_AGG_TYPE(APP_SID, SCORE_TYPE_AGG_TYPE_ID)
	ON DELETE CASCADE;

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (16, 'Enable audit score type aggregate types', 'Creates aggregate types for all score types used in audits. Can be re-run if additional score types are added.', 'SynchScoreTypeAggTypes', NULL);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (17, 'Enable calculation score survey type', 'Enabled the survey type used to display the calculation summary page on submit.', 'EnableCalculationSurveyScore', NULL);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\filter_pkg
@..\util_script_pkg
@..\quick_survey_pkg
@..\audit_report_pkg
@..\schema_pkg

@..\chain\filter_body
@..\chain\chain_body
@..\util_script_body
@..\quick_survey_body
@..\audit_report_body
@..\schema_body
@..\csr_app_body
@..\csrimp\imp_body

@update_tail
