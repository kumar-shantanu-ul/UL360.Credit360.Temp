-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
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

-- *** Grants ***
GRANT SELECT, REFERENCES ON csr.score_type TO cms;
GRANT SELECT ON csr.score_threshold TO cms;
GRANT SELECT ON csr.period_set TO chain;
GRANT SELECT, REFERENCES ON csr.period_interval TO chain;
GRANT SELECT ON csr.period TO chain;
GRANT SELECT ON csr.period_dates TO chain;
GRANT SELECT, REFERENCES ON csr.period_interval_member TO chain;
GRANT EXECUTE ON csr.period_pkg TO chain;

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

-- EnableIssuesFiltering
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

-- ** New package grants **

-- *** Packages ***

@..\enable_pkg
@..\chain\filter_pkg
@..\..\..\aspen2\cms\db\filter_pkg

@..\enable_body
@..\csr_app_body
@..\schema_body
@..\templated_report_body
@..\csrimp\imp_body
@..\chain\company_body
@..\chain\filter_body
@..\chain\company_filter_body
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\tab_body

@update_tail
