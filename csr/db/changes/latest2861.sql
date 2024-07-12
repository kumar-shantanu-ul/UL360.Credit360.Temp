define version=2861
define minor_version=0
define is_combined=1
@update_header

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
CREATE TABLE CSR.QUICK_SURVEY_CSS (
    APP_SID						NUMBER(10)		DEFAULT sys_context('security','app') NOT NULL,
    CLASS_NAME		 			VARCHAR2(1024)	NOT NULL,
    DESCRIPTION		 			VARCHAR2(1024)	NOT NULL,
    TYPE						NUMBER(1)		NOT NULL,
	POSITION					NUMBER(10)    	DEFAULT 0 NOT NULL,
    CONSTRAINT PK_QUICK_SURVEY_CSS PRIMARY KEY (APP_SID, CLASS_NAME)
);
CREATE TABLE csr.customer_file_upload_type_opt (
	app_sid				NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	file_extension		VARCHAR2(255)		NOT NULL,
	is_allowed			NUMBER(1,0)			DEFAULT 0 NOT NULL,
	CONSTRAINT pk_customer_file_upld_type_opt PRIMARY KEY (app_sid, file_extension),
	CONSTRAINT chk_file_upld_type_is_allowed CHECK (is_allowed IN (0, 1)),
	CONSTRAINT chk_file_upld_type_file_ext CHECK (file_extension = LOWER(TRIM(file_extension)))
);
CREATE TABLE csr.customer_file_upload_mime_opt (
	app_sid				NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	mime_type			VARCHAR2(255)		NOT NULL,
	is_allowed			NUMBER(1,0)			DEFAULT 0 NOT NULL,
	CONSTRAINT pk_customer_file_upld_mime_opt PRIMARY KEY (app_sid, mime_type),
	CONSTRAINT chk_file_upld_mime_is_allowed CHECK (is_allowed IN (0, 1)),
	CONSTRAINT chk_file_upld_mime_file_ext CHECK (mime_type = LOWER(TRIM(mime_type)))
);
CREATE TABLE csrimp.customer_file_upload_type_opt (
	csrimp_session_id	NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	file_extension		VARCHAR2(255)		NOT NULL,
	is_allowed			NUMBER(1,0)			NOT NULL,
	CONSTRAINT pk_customer_file_upld_type_opt PRIMARY KEY (csrimp_session_id, file_extension),
	CONSTRAINT chk_file_upld_type_is_allowed CHECK (is_allowed IN (0, 1)),
	CONSTRAINT chk_file_upld_type_file_ext CHECK (file_extension = LOWER(TRIM(file_extension)))
);
CREATE TABLE csrimp.customer_file_upload_mime_opt (
	csrimp_session_id	NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	mime_type			VARCHAR2(255)		NOT NULL,
	is_allowed			NUMBER(1,0)			NOT NULL,
	CONSTRAINT pk_customer_file_upld_mime_opt PRIMARY KEY (csrimp_session_id, mime_type),
	CONSTRAINT chk_file_upld_mime_is_allowed CHECK (is_allowed IN (0, 1)),
	CONSTRAINT chk_file_upld_mime_file_ext CHECK (mime_type = LOWER(TRIM(mime_type)))
);

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
ALTER TABLE csrimp.cms_tab_issue_aggregate_ind ADD (
    closed_ind_sid					NUMBER(10),
    open_ind_sid 					NUMBER(10),
    closed_td_ind_sid 				NUMBER(10),
    rejected_td_ind_sid 			NUMBER(10),
    open_od_ind_sid 				NUMBER(10),
    open_nod_ind_sid 				NUMBER(10),
    open_od_u30_ind_sid 			NUMBER(10),
    open_od_u60_ind_sid 			NUMBER(10),
    open_od_u90_ind_sid 			NUMBER(10),
    open_od_o90_ind_sid 			NUMBER(10)
);
ALTER TABLE cms.fk_cons ADD (
	CONSTRAINT uk_fk_cons_tab UNIQUE (app_sid, fk_cons_id, tab_sid)
);
ALTER TABLE cms.tab ADD (
	securable_fk_cons_id		NUMBER(10),
	CONSTRAINT fk_tab_sec_fk_cons 
		FOREIGN KEY (app_sid, securable_fk_cons_id, tab_sid) 
		REFERENCES cms.fk_cons (app_sid, fk_cons_id, tab_sid)
);
CREATE INDEX cms.ix_tab_sec_fk_cons ON cms.tab (app_sid, securable_fk_cons_id, tab_sid);
ALTER TABLE csrimp.cms_tab ADD (
	securable_fk_cons_id		NUMBER(10)
);
	
ALTER TABLE CSR.TAB ADD (
  IS_HIDEABLE NUMBER(1) DEFAULT 1 NOT NULL
);
ALTER TABLE csr.customer_file_upload_type_opt
  ADD CONSTRAINT fk_file_upld_type_opt_customer FOREIGN KEY (app_sid) REFERENCES csr.customer (app_sid);
ALTER TABLE csr.customer_file_upload_mime_opt
  ADD CONSTRAINT fk_file_upld_mime_opt_customer FOREIGN KEY (app_sid) REFERENCES csr.customer (app_sid);
ALTER TABLE csrimp.customer_file_upload_type_opt
  ADD CONSTRAINT fk_file_upld_type_opt_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
ALTER TABLE csrimp.customer_file_upload_mime_opt
  ADD CONSTRAINT fk_file_upld_mime_opt_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
  
ALTER TABLE csr.pct_ownership MODIFY (
	PCT		NUMBER
);

GRANT SELECT ON chain.filter_page_cms_table TO csr;
grant select, insert, update, delete on csrimp.chain_filter_page_cms_table to web_user;
grant select, insert, update on chain.filter_page_cms_table to csrimp;
grant select on chain.filter_page_cms_table_id_seq to csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.customer_file_upload_type_opt TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.customer_file_upload_mime_opt TO web_user;
GRANT SELECT, INSERT ON csr.customer_file_upload_type_opt TO csrimp;
GRANT SELECT, INSERT ON csr.customer_file_upload_mime_opt TO csrimp;


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
CREATE OR REPLACE FORCE VIEW CSR.V$TAB_USER (TAB_ID, APP_SID, LAYOUT, NAME, IS_SHARED, IS_HIDEABLE, OVERRIDE_POS, USER_SID, POS, IS_OWNER, IS_HIDDEN, PORTAL_GROUP) AS 
	SELECT t.TAB_ID, t.APP_SID, t.LAYOUT, t.NAME, t.IS_SHARED, t.IS_HIDEABLE, t.OVERRIDE_POS, tu.USER_SID, tu.POS, tu.IS_OWNER, tu.IS_HIDDEN, t.PORTAL_GROUP
	  FROM TAB t, TAB_USER tu
	 WHERE t.TAB_ID = tu.TAB_ID;

DECLARE
	FEATURE_NOT_ENABLED		EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS	EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'CUSTOMER_FILE_UPLOAD_TYPE_OPT',
		policy_name     => 'CUST_FILE_UPLD_TYPE_OPT_POL', 
		function_schema => 'CSR',
		policy_function => 'AppSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive);
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		dbms_output.put_line('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		dbms_output.put_line('RLS policies not applied as feature not enabled');
END;
/
DECLARE
	FEATURE_NOT_ENABLED		EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS	EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'CUSTOMER_FILE_UPLOAD_MIME_OPT',
		policy_name     => 'CUST_FILE_UPLD_MIME_OPT_POL', 
		function_schema => 'CSR',
		policy_function => 'AppSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive);
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		dbms_output.put_line('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		dbms_output.put_line('RLS policies not applied as feature not enabled');
END;
/
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'CUSTOMER_FILE_UPLOAD_TYPE_OPT',
		policy_name     => 'CUST_FILE_UPLD_TYPE_OPT_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		dbms_output.put_line('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		dbms_output.put_line('RLS policies not applied as feature not enabled');
END;
/
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSRIMP',
		object_name     => 'CUSTOMER_FILE_UPLOAD_MIME_OPT',
		policy_name     => 'CUST_FILE_UPLD_MIME_OPT_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		dbms_output.put_line('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		dbms_output.put_line('RLS policies not applied as feature not enabled');
END;
/

INSERT INTO csr.util_script (util_script_id, util_script_name, description, util_script_sp, wiki_article)
	 VALUES (10, 'Map Survey Questions to Indicators', 'Will create indicators for anything that has single input values (Radio buttons, dropdown, matrix) under the supply Chain Questionnaires folder for the supplied survey sid', 'MapIndicatorsFromSurvey', 'W1915');
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint , pos)
	 VALUES (10, 'Survey SID', 'Survey sid to map question from', 1);
INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint , pos)
	 VALUES (10, 'Score type', 'The score type of the survey (Optional, defaults to NULL)', 2);
INSERT INTO CSR.PORTLET (
     PORTLET_ID, NAME, TYPE, SCRIPT_PATH
 ) VALUES (
     1057,
     'Role List',
     'Credit360.Portlets.RoleList',
     '/csr/site/portal/Portlets/RoleList.js'
 );
DELETE FROM csr.branding_availability
 WHERE client_folder_name = 'halcrow';
DELETE FROM csr.branding
 WHERE client_folder_name = 'halcrow';
INSERT INTO csr.capability (name, allow_by_default) VALUES ('View user details', 0);
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		 VALUES (59, 'Data change requests', 'EnableDataChangeRequests', 'Enables data change requests. Also enables the alerts and sets up their templates.');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

grant execute on csr.initiative_grid_pkg to web_user;
grant execute on csr.initiative_pkg to security;
grant execute on csr.initiative_project_pkg to security;

@..\..\..\aspen2\cms\db\tab_pkg
@..\schema_pkg
@..\audit_pkg
@..\audit_report_pkg
@..\issue_report_pkg
@..\chain\company_filter_pkg
@..\chain\company_pkg
@..\chain\report_pkg
@..\chain\filter_pkg
@..\dataview_pkg
@..\sqlreport_pkg
@..\quick_survey_pkg
@..\section_root_pkg
@..\portlet_pkg
@..\approval_dashboard_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\..\..\aspen2\cms\db\form_pkg
@..\..\..\aspen2\cms\db\pivot_pkg
@..\..\..\aspen2\cms\db\web_publication_pkg
@..\..\..\aspen2\db\aspen_user_pkg
@..\..\..\aspen2\db\aspenapp_pkg
@..\..\..\aspen2\db\aspenredirect_pkg
@..\..\..\aspen2\db\fp_user_pkg
@..\..\..\aspen2\db\job_pkg
@..\..\..\aspen2\db\poll_pkg
@..\..\..\aspen2\db\scheduledtask_pkg
@..\..\..\aspen2\db\trash_pkg
@..\role_pkg
@..\customer_pkg
@..\csr_user_pkg
@..\..\..\aspen2\DynamicTables\db\schema_pkg
@..\accuracy_pkg
@..\activity_pkg
@..\alert_pkg
@..\auto_approve_pkg
@..\calc_pkg
@..\calendar_pkg
@..\csr_data_pkg
@..\delegation_pkg
@..\deleg_plan_pkg
@..\energy_star_pkg
@..\excel_pkg
@..\export_feed_pkg
@..\factor_pkg
@..\flow_pkg
@..\help_pkg
@..\imp_pkg
@..\import_feed_pkg
@..\indicator_pkg
@..\initiative_pkg
@..\initiative_doc_pkg
@..\logistics_pkg
@..\metric_dashboard_pkg
@..\model_pkg
@..\portal_dashboard_pkg
@..\section_pkg
@..\section_search_pkg
@..\section_status_pkg
@..\section_transition_pkg
@..\sheet_pkg
@..\templated_report_pkg
@..\training_pkg
@..\val_datasource_pkg
@..\vb_legacy_pkg
@..\chem\substance_pkg
@..\donations\tag_pkg
@..\actions\project_pkg
@..\actions\task_pkg
@..\automated_export_pkg
@..\automated_import_pkg
@..\benchmarking_dashboard_pkg
@..\campaign_pkg
@..\chain\uninvited_pkg
@..\chain\upload_pkg
@..\csr_app_pkg
@..\dashboard_pkg
@..\deleg_report_pkg
@..\diary_pkg
@..\doc_folder_pkg
@..\doc_lib_pkg
@..\donations\funding_commitment_pkg
@..\donations\recipient_pkg
@..\donations\region_group_pkg
@..\donations\scheme_pkg
@..\donations\status_pkg
@..\donations\transition_pkg
@..\feed_pkg
@..\fileupload_pkg
@..\form_pkg
@..\geo_map_pkg
@..\img_chart_pkg
@..\initiative_project_pkg
@..\measure_pkg
@..\objective_pkg
@..\region_pkg
@..\region_tree_pkg
@..\reporting_period_pkg
@..\rss_pkg
@..\ruleset_pkg
@..\scenario_pkg
@..\scenario_run_pkg
@..\supplier\company_pkg
@..\supplier\supplier_user_pkg
@..\supplier\tag_pkg
@..\target_dashboard_pkg
@..\teamroom_pkg
@..\templated_report_schedule_pkg
@..\trash_pkg
@..\user_container_pkg
@..\enable_pkg
@..\energy_star_job_pkg

@..\..\..\aspen2\cms\db\tab_body
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
@..\dataview_body
@..\sqlreport_body
@..\quick_survey_body
@..\..\..\aspen2\cms\db\filter_body
@..\section_root_body
@..\deleg_plan_body
@..\portlet_body
@..\approval_dashboard_body
@..\chain\setup_body
@..\..\..\aspen2\cms\db\form_body
@..\..\..\aspen2\cms\db\pivot_body
@..\..\..\aspen2\cms\db\web_publication_body
@..\..\..\aspen2\db\aspen_user_body
@..\..\..\aspen2\db\aspenapp_body
@..\..\..\aspen2\db\aspenredirect_body
@..\..\..\aspen2\db\fp_user_body
@..\..\..\aspen2\db\job_body
@..\..\..\aspen2\db\poll_body
@..\..\..\aspen2\db\scheduledtask_body
@..\..\..\aspen2\db\trash_body
@..\role_body
@..\customer_body
@..\csr_app_body;
@..\csrimp\imp_body;
@..\csr_user_body
@..\sheet_body
@..\..\..\aspen2\db\filecache_body
@..\..\..\aspen2\db\form_transaction_body
@..\..\..\aspen2\db\mdComment_body
@..\..\..\aspen2\db\supportTicket_body
@..\..\..\aspen2\db\utils_body
@..\..\..\aspen2\cms\db\calc_xml_body
@..\..\..\aspen2\cms\db\col_link_body
@..\..\..\aspen2\cms\db\image_body
@..\..\..\aspen2\cms\db\imp_body
@..\..\..\aspen2\cms\db\menu_body
@..\..\..\aspen2\cms\db\upload_body
@..\..\..\aspen2\DynamicTables\db\schema_body
@..\accuracy_body
@..\activity_body
@..\aggregate_ind_body
@..\alert_body
@..\approval_step_range_body
@..\auto_approve_body
@..\automated_import_body
@..\branding_body
@..\calc_body
@..\calendar_body
@..\campaign_body
@..\csr_data_body
@..\delegation_body
@..\doc_body
@..\doc_helper_body
@..\donations\donation_body
@..\doc_lib_body
@..\energy_star_body
@..\energy_star_job_body
@..\enhesa_body
@..\excel_body
@..\export_feed_body
@..\factor_body
@..\fileupload_body
@..\flow_body
@..\help_body
@..\help_image_body
@..\img_chart_body
@..\imp_body
@..\import_feed_body
@..\indicator_body
@..\indicator_set_body
@..\initiative_body
@..\initiative_doc_body
@..\logistics_body
@..\measure_body
@..\meter_body
@..\meter_monitor_body
@..\metric_dashboard_body
@..\model_body
@..\pending_body
@..\pending_datasource_body
@..\plugin_body
@..\portal_dashboard_body
@..\property_body
@..\region_body
@..\region_metric_body
@..\scenario_body
@..\scenario_run_body
@..\section_body
@..\section_search_body
@..\section_status_body
@..\section_transition_body
@..\session_extra_body
@..\snapshot_body
@..\structure_import_body
@..\tag_body
@..\teamroom_body
@..\templated_report_body
@..\training_body
@..\unit_test_body
@..\user_cover_body
@..\user_setting_body
@..\val_datasource_body
@..\vb_legacy_body
@..\actions\aggr_dependency_body
@..\actions\dependency_body
@..\actions\ind_template_body
@..\actions\setup_body
@..\actions\task_body
@..\chain\admin_helper_body
@..\chain\activity_body
@..\chain\alert_helper_body
@..\chain\audit_request_body
@..\chain\capability_body
@..\chain\card_body
@..\chain\company_user_body
@..\chain\component_body
@..\chain\dev_body
@..\chain\helper_body
@..\chain\invitation_body
@..\chain\newsflash_body
@..\chain\product_body
@..\chain\purchased_component_body
@..\chain\questionnaire_body
@..\chain\supplier_audit_body
@..\chain\task_body
@..\chain\type_capability_body
@..\chain\uninvited_body
@..\chain\upload_body
@..\chem\substance_body
@..\ct\hotspot_body
@..\ct\setup_body
@..\ct\value_chain_report_body
@..\donations\funding_commitment_body
@..\donations\tag_body
@..\donations\helpers\bae_helper_body
@..\donations\transition_body
@..\supplier\audit_body
@..\supplier\company_body
@..\supplier\chain\chain_questionnaire_body
@..\supplier\chain\company_group_body
@..\supplier\chain\company_user_body
@..\supplier\chain\contact_body
@..\supplier\chain\invite_body
@..\supplier\greenTick\gt_packaging_body
@..\supplier\greenTick\product_info_body
@..\supplier\greenTick\report_gt_body
@..\supplier\greenTick\revision_body
@..\supplier\greenTick\score_log_body
@..\supplier\product_body
@..\supplier\supplier_user_body
@..\actions\project_body
@..\automated_export_body
@..\benchmarking_dashboard_body
@..\dashboard_body
@..\deleg_report_body
@..\diary_body
@..\doc_folder_body
@..\donations\recipient_body
@..\donations\region_group_body
@..\donations\scheme_body
@..\donations\status_body
@..\feed_body
@..\form_body
@..\geo_map_body
@..\initiative_project_body
@..\objective_body
@..\region_tree_body
@..\reporting_period_body
@..\rss_body
@..\ruleset_body
@..\supplier\tag_body
@..\target_dashboard_body
@..\templated_report_schedule_body
@..\trash_body
@..\user_container_body

-- conditional compilation if ethics exists
UNDEFINE ex_if
COLUMN ex_if NEW_VALUE ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\company_pkg' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\company_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

UNDEFINE ex_if

-- conditional compilation if the relevant non-client schemas exist
UNDEFINE ex_if
COLUMN ex_if NEW_VALUE ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\..\..\aspen2\WebFerret\db\WebFerret_pkg' END AS ex_if FROM all_users WHERE username = 'WEBFERRET';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\..\..\aspen2\WebFerret\db\WebFerret_body' END AS ex_if FROM all_users WHERE username = 'WEBFERRET';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\company_user_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\demo_pkg' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\demo_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\participant_pkg' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\participant_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

SELECT CASE WHEN COUNT(*) = 0 THEN 'null_script' ELSE '..\ethics\question_body' END AS ex_if FROM all_users WHERE username = 'ETHICS';
@&ex_if

UNDEFINE ex_if

BEGIN
	EXECUTE IMMEDIATE 'DROP PACKAGE csr.gas_pkg';
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'DROP PACKAGE csr.hsbc_pkg';
EXCEPTION
	WHEN OTHERS THEN
		NULL; -- will not exist for on-site installs, for example, because it gets stripped
END;
/

@update_tail
