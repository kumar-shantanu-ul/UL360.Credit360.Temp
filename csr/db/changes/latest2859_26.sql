-- Please update version.sql too -- this keeps clean builds in sync
define version=2859
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csrimp.chain_filter_page_cms_table (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	filter_page_cms_table_id		NUMBER(10) NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	column_sid						NUMBER(10) NOT NULL,
	CONSTRAINT pk_filter_page_cms_table PRIMARY KEY (csrimp_session_id, filter_page_cms_table_id),
	CONSTRAINT fk_chain_filtr_page_cms_tab_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FILTER_PAGE_CMS_TAB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_PAGE_CMS_TABLE_ID NUMBER(10) NOT NULL,
	NEW_FILTER_PAGE_CMS_TABLE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FLTR_PAGE_CMS_TAB PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_PAGE_CMS_TABLE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FLTR_PAGE_CMS_TAB UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_PAGE_CMS_TABLE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHN_FLTR_PG_CMS_TAB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


-- Alter tables
ALTER TABLE chain.filter_page_column ADD (
	include_in_export		NUMBER(1) DEFAULT 0 NOT NULL,
	company_tab_id			NUMBER(10),
	CONSTRAINT chk_fltr_pg_col_export_1_0 CHECK (include_in_export IN (1, 0)),
	CONSTRAINT fk_fltr_pg_col_plugin FOREIGN KEY (app_sid, company_tab_id)
		REFERENCES chain.company_tab(app_sid, company_tab_id)
);

ALTER TABLE chain.filter_page_column DROP PRIMARY KEY DROP INDEX;

CREATE UNIQUE INDEX chain.uk_filter_table_column ON chain.filter_page_column(app_sid, card_group_id, column_name, company_tab_id);

DROP INDEX chain.ix_filter_page_cms_table_col;
ALTER TABLE chain.filter_page_cms_table ADD CONSTRAINT uk_filter_page_cms_table_col UNIQUE (app_sid, column_sid);

ALTER TABLE csrimp.chain_filter_page_column ADD (
	include_in_export		NUMBER(1) NOT NULL,
	company_tab_id			NUMBER(10),
	CONSTRAINT chk_fltr_pg_col_export_1_0 CHECK (include_in_export IN (1, 0))
);

ALTER TABLE csrimp.chain_filter_page_column DROP PRIMARY KEY DROP INDEX;

CREATE UNIQUE INDEX csrimp.uk_filter_table_column ON csrimp.chain_filter_page_column(csrimp_session_id, card_group_id, column_name, company_tab_id);


ALTER TABLE csrimp.chain_filter_page_column MODIFY width DEFAULT NULL;
ALTER TABLE csrimp.chain_filter_page_column MODIFY fixed_width DEFAULT NULL;
ALTER TABLE csrimp.chain_filter_page_column MODIFY hidden DEFAULT NULL;

DROP INDEX CHAIN.UK_BU_IS_PRIMARY;
CREATE UNIQUE INDEX CHAIN.UK_BU_IS_PRIMARY ON CHAIN.BUSINESS_UNIT_MEMBER(
	CASE WHEN IS_PRIMARY_BU=1 THEN APP_SID END,
	CASE WHEN IS_PRIMARY_BU=1 THEN USER_SID END
)
;

DROP INDEX CHAIN.UK_BU_SUP_IS_PRIMARY;
CREATE UNIQUE INDEX CHAIN.UK_BU_SUP_IS_PRIMARY ON CHAIN.BUSINESS_UNIT_SUPPLIER(
	CASE WHEN IS_PRIMARY_BU=1 THEN APP_SID END,
	CASE WHEN IS_PRIMARY_BU=1 THEN SUPPLIER_COMPANY_SID END
);

BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE chain.company
	   SET city = town
	 WHERE city IS NULL
	   AND town IS NOT NULL;
	
	
	UPDATE chain.company
	   SET city = NULL
	 WHERE city IS NOT NULL
	   AND city_id IS NOT NULL;
	
	UPDATE chain.company
	   SET state = NULL
	 WHERE state IS NOT NULL
	   AND state_id IS NOT NULL;
END;
/

ALTER TABLE chain.company RENAME COLUMN town TO xxx_town;
ALTER TABLE chain.company ADD (
	CONSTRAINT chk_company_city CHECK (city IS NULL OR city_id IS NULL),
	CONSTRAINT chk_company_state CHECK (state IS NULL OR state_id IS NULL)
);

ALTER TABLE CSRIMP.FUND MODIFY COMPANY_SID DEFAULT NULL;

ALTER TABLE CSRIMP.CHAIN_COMPANY ADD (
	CITY VARCHAR2(255),
	CITY_ID NUMBER(10),
	STATE_ID VARCHAR2(2)
);

ALTER TABLE CSRIMP.CHAIN_COMPANY DROP COLUMN TOWN;
ALTER TABLE CSRIMP.CHAIN_COMPANY DROP COLUMN XXX_REFERENCE_ID_1;
ALTER TABLE CSRIMP.CHAIN_COMPANY DROP COLUMN XXX_REFERENCE_ID_2;
ALTER TABLE CSRIMP.CHAIN_COMPANY DROP COLUMN XXX_REFERENCE_ID_3;

-- *** Grants ***
GRANT SELECT ON chain.filter_page_cms_table TO csr;
grant select, insert, update, delete on csrimp.chain_filter_page_cms_table to web_user;
grant select, insert, update on chain.filter_page_cms_table to csrimp;
grant select on chain.filter_page_cms_table_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- /csr/db/chain/create_views.sql
CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm,
		   c.address_1, c.address_2, c.address_3, c.address_4, c.state, 
		   NVL(pr.name, c.state) state_name, c.state_id, c.city, NVL(pc.city_name, c.city) city_name,
		   c.city_id, c.postcode, c.country_code,
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, ct.singular company_type_description, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_country_name,
		   c.country_is_hidden, cs.region_sid
	  FROM company c
	  JOIN customer_options co ON co.app_sid = c.app_sid
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
	  LEFT JOIN v$country pcou ON p.country_code = pcou.country_code
	  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
	  LEFT JOIN postcode.city pc ON c.city_id = pc.city_id AND c.country_code = pc.country
	  LEFT JOIN postcode.region pr ON c.state_id = pr.region AND c.country_code = pr.country
	 WHERE c.deleted = 0
;

-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.interactive audit_type_interactive,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, NVL(cu.email, au.email) auditor_email,
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label int_audit_type_group_label, atg.internal_audit_type_group_id, atg.group_coordinator_noun,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score,
		   sst.score_type_id survey_score_type_id, sr.score_threshold_id survey_score_thrsh_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label,
		   ncst.format_mask nc_score_format_mask,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm END next_audit_due_dtm
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  JOIN csr.csr_user au ON ia.auditor_user_sid = au.csr_user_sid AND ia.app_sid = au.app_sid
	  LEFT JOIN csr.csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON iat.summary_survey_sid = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
			  LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
			  LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE ((nnc.is_closed IS NULL 
			   AND i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0)
			    OR nnc.is_closed = 0)
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id AND ia.internal_audit_type_id = atct.internal_audit_type_id AND ia.app_sid = atct.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	  LEFT JOIN score_type ncst ON ncst.app_sid = iat.app_sid AND ncst.score_type_id = iat.nc_score_type_id
	  LEFT JOIN score_type sst ON sst.app_sid = qs.app_sid AND sst.score_type_id = qs.score_type_id
	 WHERE ia.deleted = 0;

-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$audit_validity AS --more basic version of v$audit_next_due that returns all audits carried out and their validity instead of just the most recent of each type
SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
CASE (atct.re_audit_due_after_type)
	WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
	WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
	WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
	WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
	ELSE ia.ovw_validity_dtm
END next_audit_due_dtm, atct.reminder_offset_days, act.label closure_label,
act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
  FROM csr.internal_audit ia
  JOIN csr.audit_type_closure_type atct
	ON ia.audit_closure_type_id = atct.audit_closure_type_id
   AND ia.app_sid = atct.app_sid
  JOIN csr.audit_closure_type act
	ON atct.audit_closure_type_id = act.audit_closure_type_id
   AND atct.app_sid = act.app_sid
 WHERE ia.deleted = 0;

-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$audit_next_due AS
SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
	   ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
	   CASE (atct.re_audit_due_after_type)
			WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
			WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
			WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
			WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
			ELSE ia.ovw_validity_dtm
	   END next_audit_due_dtm, atct.reminder_offset_days, act.label closure_label,
	   act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
	   ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
  FROM (
	SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
		   ROW_NUMBER() OVER (
				PARTITION BY internal_audit_type_id, region_sid
				ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
		   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted, ovw_validity_dtm
	  FROM csr.internal_audit
	 WHERE deleted = 0
	   ) ia
  JOIN csr.audit_type_closure_type atct
	ON ia.audit_closure_type_id = atct.audit_closure_type_id
   AND ia.app_sid = atct.app_sid
  JOIN csr.audit_closure_type act
	ON atct.audit_closure_type_id = act.audit_closure_type_id
   AND atct.app_sid = act.app_sid
  JOIN csr.region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
 WHERE rn = 1
   AND atct.re_audit_due_after IS NOT NULL
   AND r.active=1
   AND ia.audit_closure_type_id IS NOT NULL
   AND ia.deleted = 0;


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
-- This were never granted in a change script, but we've had them since 2013 so no need for a dummy package
grant execute on csr.initiative_grid_pkg to web_user;
grant execute on csr.initiative_pkg to security;
grant execute on csr.initiative_project_pkg to security;

-- *** Packages ***
@..\schema_pkg
@..\audit_pkg
@..\audit_report_pkg
@..\issue_report_pkg
@..\chain\company_filter_pkg
@..\chain\company_pkg
@..\chain\report_pkg
@..\chain\filter_pkg

@..\schema_body
@..\chain\chain_body
@..\chain\company_filter_body
@..\chain\company_body
@..\chain\company_type_body
@..\chain\report_body
@..\chain\filter_body
@..\chain\plugin_body
@..\chain\scheduled_alert_body
@..\csrimp\imp_body
@..\audit_body
@..\audit_report_body
@..\non_compliance_report_body
@..\enable_body
@..\issue_body
@..\issue_report_body
@..\supplier_body

@update_tail
