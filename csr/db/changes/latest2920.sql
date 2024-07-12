define version=2920
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/

CREATE TABLE CHAIN.RISK_LEVEL (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	RISK_LEVEL_ID					NUMBER(10, 0)	NOT NULL,
	LABEL							VARCHAR2(255)	NOT NULL,
	LOOKUP_KEY				 		VARCHAR2(255)	NULL,
	CONSTRAINT PK_RISK_LEVEL PRIMARY KEY (APP_SID, RISK_LEVEL_ID)
);
CREATE UNIQUE INDEX CHAIN.UK_RISK_LEVEL_LOOKUP_KEY ON CHAIN.RISK_LEVEL (APP_SID, NVL(UPPER(LOOKUP_KEY), TO_CHAR(RISK_LEVEL_ID)));
CREATE SEQUENCE  CHAIN.RISK_LEVEL_ID_SEQ  MINVALUE 1 MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE;
CREATE TABLE CHAIN.COUNTRY_RISK_LEVEL (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	COUNTRY							VARCHAR2(2)		NOT NULL,
	RISK_LEVEL_ID					NUMBER(10, 0)	NOT NULL,
	START_DTM				 		DATE			NOT NULL,
	CONSTRAINT PK_COUNTRY_RISK_LEVEL PRIMARY KEY (APP_SID, COUNTRY, START_DTM),
	CONSTRAINT FK_RISK_LEVEL FOREIGN KEY (APP_SID, RISK_LEVEL_ID) REFERENCES CHAIN.RISK_LEVEL(APP_SID, RISK_LEVEL_ID),
	CONSTRAINT FK_COUNTRY FOREIGN KEY (COUNTRY) REFERENCES POSTCODE.COUNTRY (COUNTRY)
);
CREATE TABLE CSRIMP.CHAIN_RISK_LEVEL (
	CSRIMP_SESSION_ID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	RISK_LEVEL_ID					NUMBER(10, 0)	NOT NULL,
	LABEL							VARCHAR2(255)	NOT NULL,
	LOOKUP_KEY				 		VARCHAR2(255)	NULL,
	CONSTRAINT PK_CHAIN_RISK_LEVEL PRIMARY KEY (CSRIMP_SESSION_ID, RISK_LEVEL_ID),
	CONSTRAINT FK_CHAIN_RISK_LEVEL_SESSION FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE UNIQUE INDEX CSRIMP.UK_CHAIN_RISK_LVL_LKUP_KEY ON CSRIMP.CHAIN_RISK_LEVEL (CSRIMP_SESSION_ID, NVL(UPPER(LOOKUP_KEY), TO_CHAR(RISK_LEVEL_ID)));
CREATE TABLE CSRIMP.CHAIN_COUNTRY_RISK_LEVEL (
	CSRIMP_SESSION_ID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COUNTRY							VARCHAR2(2)		NOT NULL,
	RISK_LEVEL_ID					NUMBER(10, 0)	NOT NULL,
	START_DTM				 		DATE			NOT NULL,
	CONSTRAINT PK_CHAIN_COUNTRY_RISK_LEVEL PRIMARY KEY (CSRIMP_SESSION_ID, COUNTRY, START_DTM),
	CONSTRAINT FK_CHAIN_CNTRY_RSK_LVL_SESSION FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_RISK_LEVEL (
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_RISK_LEVEL_ID 				NUMBER(10) NOT NULL,
	NEW_RISK_LEVEL_ID 				NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_RISK_LEVEL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_RISK_LEVEL_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_RISK_LEVEL_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


ALTER TABLE csr.customer ADD (
	quick_survey_fixed_structure NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_qs_fixed_structure CHECK (quick_survey_fixed_structure IN (0, 1))
);
ALTER TABLE csrimp.customer ADD (
	quick_survey_fixed_structure NUMBER(1),
	CONSTRAINT chk_qs_fixed_structure CHECK (quick_survey_fixed_structure IN (0, 1))
);
UPDATE csrimp.customer
   SET quick_survey_fixed_structure = 0
 WHERE quick_survey_fixed_structure IS NULL;
ALTER TABLE csrimp.customer MODIFY quick_survey_fixed_structure NOT NULL;
ALTER TABLE CSR.EST_JOB ADD (
	CREATED_BY_USER_SID    NUMBER(10, 0)
);
ALTER TABLE CSR.EST_JOB ADD CONSTRAINT FK_CSRUSR_ESTJOB 
    FOREIGN KEY (APP_SID, CREATED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
CREATE INDEX CSR.IX_CSRUSR_ESTJOB ON CSR.EST_JOB(APP_SID, CREATED_BY_USER_SID);
DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_tab_cols
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'INTERNAL_AUDIT_TYPE'
	   AND column_name = 'ACTIVE';
	
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE '
		ALTER TABLE csrimp.internal_audit_type ADD (
			active            NUMBER(1) DEFAULT 1,
			CONSTRAINT chk_audit_type_act_1_0 CHECK (active IN (1, 0))
		)';
	END IF;
END;
/
DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_tab_columns
	 WHERE owner = 'CMS'
	   AND table_name = 'LINK_TRACK'
	   AND column_name = 'APP_SID'
	   AND nullable = 'N';
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE cms.link_track MODIFY app_sid NOT NULL';
	END IF;
END;
/
DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_tab_columns
	 WHERE owner = 'CMS'
	   AND table_name = 'LINK_TRACK'
	   AND column_name = 'COLUMN_SID'
	   AND nullable = 'N';
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE cms.link_track MODIFY column_sid NOT NULL';
	END IF;
END;
/
ALTER TABLE csr.est_building ADD (
	ignored NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_est_building_ignored CHECK (ignored IN (0, 1))
);
ALTER TABLE CHAIN.CUSTOMER_OPTIONS
	ADD COUNTRY_RISK_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.CUSTOMER_OPTIONS
	ADD CONSTRAINT CHK_COUNTRY_RISK_ENABLED CHECK (COUNTRY_RISK_ENABLED IN (0, 1));
ALTER TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS
	ADD COUNTRY_RISK_ENABLED NUMBER(1) NOT NULL;
ALTER TABLE CSRIMP.ISSUE_CUSTOM_FIELD
	DROP CONSTRAINT CHK_ISS_CUST_FLD_TYP;
ALTER TABLE CSRIMP.ISSUE_CUSTOM_FIELD
	ADD CONSTRAINT CHK_ISS_CUST_FLD_TYP CHECK (FIELD_TYPE IN ('T', 'O', 'M', 'D'));
ALTER TABLE CSR.ISSUE_TYPE ADD (
	IS_REGION_EDITABLE	NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_REGION_EDITABLE CHECK(IS_REGION_EDITABLE IN (0,1))
);
ALTER TABLE CSRIMP.CUSTOMER ADD
(
	ADJ_FACTORSET_STARTMONTH		NUMBER(1)		NOT NULL,
	ALLOW_CUSTOM_ISSUE_TYPES		NUMBER(1, 0)	NOT NULL,
	ALLOW_SECTION_IN_MANY_CARTS		NUMBER(1, 0)	NOT NULL,
	CALC_JOB_NOTIFY_ADDRESS			VARCHAR2(512),
	CALC_JOB_NOTIFY_AFTER_ATTEMPTS	NUMBER(10),
	DEFAULT_COUNTRY					VARCHAR2(2),
	DYNAMIC_DELEG_PLANS_BATCHED		NUMBER(1, 0)	NOT NULL,
	EST_JOB_NOTIFY_ADDRESS			VARCHAR2(512),
	EST_JOB_NOTIFY_AFTER_ATTEMPTS	NUMBER(10),
	FAILED_CALC_JOB_RETRY_DELAY		NUMBER(10, 0)	NOT NULL,
	LEGACY_PERIOD_FORMATTING		NUMBER(1,0),
	LIVE_METERING_SHOW_GAPS			NUMBER(1)		NOT NULL,
	LOCK_PREVENTS_EDITING			NUMBER(1, 0)	NOT NULL,
	MAX_CONCURRENT_CALC_JOBS		NUMBER(10),
	METERING_GAPS_FROM_ACQUISITION	NUMBER(1)		NOT NULL,
	RESTRICT_ISSUE_VISIBILITY		NUMBER(1)		NOT NULL,
	SCRAG_QUEUE						VARCHAR2(100),
	STATUS_FROM_PARENT_ON_SUBDELEG	NUMBER(1, 0)	NOT NULL,
	TRANSLATION_CHECKBOX			NUMBER(1)		NOT NULL,
	USER_ADMIN_HELPER_PKG			VARCHAR2(255),
	USER_DIRECTORY_TYPE_ID			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT CHK_CUSTOMER_ALLOW_CUSTOM_IT CHECK (ALLOW_CUSTOM_ISSUE_TYPES IN (0,1)),
	CONSTRAINT CK_CUSTOMER_DYN_DELEG_PLAN CHECK (DYNAMIC_DELEG_PLANS_BATCHED IN (0,1)),
	CONSTRAINT CK_CUSTOMER_ISSUE_VISIBILITY CHECK (RESTRICT_ISSUE_VISIBILITY IN (0,1))
);
ALTER TABLE CSR.CUSTOMER
DROP CONSTRAINT CK_CUSTOMER_ISSUE_VISIBILITY;
ALTER TABLE CSR.CUSTOMER
ADD CONSTRAINT ck_customer_issue_visibility CHECK (restrict_issue_visibility IN (0,1));
ALTER TABLE CSRIMP.DATAVIEW ADD
(
	ANONYMOUS_REGION_NAMES			NUMBER(1)		NOT NULL,
	INCLUDE_NOTES_IN_TABLE			NUMBER(1)		NOT NULL,
	SHOW_REGION_EVENTS				NUMBER(1)		NOT NULL
);
ALTER TABLE csrimp.alert							MODIFY sent_dtm							DEFAULT NULL;
ALTER TABLE csrimp.alert_bounce						MODIFY received_dtm						DEFAULT NULL;
ALTER TABLE csrimp.approval_dashboard_ind			MODIFY allow_estimated_data				DEFAULT NULL;
ALTER TABLE csrimp.approval_dashboard_ind			MODIFY pos								DEFAULT NULL;
ALTER TABLE csrimp.aspen2_application				MODIFY confirm_user_details				DEFAULT NULL;
ALTER TABLE csrimp.aspen2_application				MODIFY logon_autocomplete				DEFAULT NULL;
ALTER TABLE csrimp.audit_log						MODIFY remote_addr						DEFAULT NULL;
ALTER TABLE csrimp.chain_activity					MODIFY share_with_target				DEFAULT NULL;
ALTER TABLE csrimp.chain_activity_type				MODIFY can_share						DEFAULT NULL;
ALTER TABLE csrimp.chain_activit_type_alert			MODIFY send_to_assignee					DEFAULT NULL;
ALTER TABLE csrimp.chain_activit_type_alert			MODIFY send_to_target					DEFAULT NULL;
ALTER TABLE csrimp.chain_activi_type_action			MODIFY copy_assigned_to					DEFAULT NULL;
ALTER TABLE csrimp.chain_activi_type_action			MODIFY copy_tags						DEFAULT NULL;
ALTER TABLE csrimp.chain_activi_type_action			MODIFY copy_target						DEFAULT NULL;
ALTER TABLE csrimp.chain_activi_type_action			MODIFY default_act_date_relative_unit	DEFAULT NULL;
ALTER TABLE csrimp.chain_activi_type_action			MODIFY default_share_with_target		DEFAULT NULL;
ALTER TABLE csrimp.chain_act_outc_type_act			MODIFY copy_assigned_to					DEFAULT NULL;
ALTER TABLE csrimp.chain_act_outc_type_act			MODIFY copy_tags						DEFAULT NULL;
ALTER TABLE csrimp.chain_act_outc_type_act			MODIFY copy_target						DEFAULT NULL;
ALTER TABLE csrimp.chain_act_outc_type_act			MODIFY default_act_date_relative_unit	DEFAULT NULL;
ALTER TABLE csrimp.chain_act_outc_type_act			MODIFY default_share_with_target		DEFAULT NULL;
ALTER TABLE csrimp.chain_company_type				MODIFY create_subsids_under_parent		DEFAULT NULL;
ALTER TABLE csrimp.chain_filter_page_column			MODIFY fixed_width						DEFAULT NULL;
ALTER TABLE csrimp.chain_filter_page_column			MODIFY hidden							DEFAULT NULL;
ALTER TABLE csrimp.chain_filter_page_column			MODIFY width							DEFAULT NULL;
ALTER TABLE csrimp.cms_alert_type					MODIFY deleted							DEFAULT NULL;
ALTER TABLE csrimp.cms_alert_type					MODIFY is_batched						DEFAULT NULL;
ALTER TABLE csrimp.cms_tab							MODIFY is_view							DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY apply_factors_to_child_regions	DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY crc_metering_auto_core			DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY crc_metering_enabled				DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY crc_metering_ind_core			DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY data_explorer_show_gauge			DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY data_explorer_show_markers		DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY data_explorer_show_radar			DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY data_explorer_show_ranking		DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY data_explorer_show_scatter		DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY data_explorer_show_trends		DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY data_explorer_show_waterfall		DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY delegs_always_show_adv_opts		DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY deleg_browser_show_rag			DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY equality_epsilon					DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY incl_inactive_regions			DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY iss_view_src_to_deepest_sheet	DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY max_dataview_history				DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY metering_enabled					DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY show_all_sheets_for_rep_prd		DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY show_region_disposal_date		DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY start_month						DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY tgtdash_colour_text				DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY tgtdash_hide_totals				DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY tgtdash_ignore_estimated			DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY tgtdash_show_chg_from_last_yr	DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY tgtdash_show_flash				DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY tgtdash_show_last_year			DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY tgtdash_show_target_first		DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY tolerance_checker_req_merged		DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY tplreportperiodextension			DEFAULT NULL;
ALTER TABLE csrimp.customer							MODIFY use_region_events				DEFAULT NULL;
ALTER TABLE csrimp.dataview							MODIFY period_interval_id				DEFAULT NULL;
ALTER TABLE csrimp.dataview							MODIFY period_set_id					DEFAULT NULL;
ALTER TABLE csrimp.dataview							MODIFY rank_limit_left					DEFAULT NULL;
ALTER TABLE csrimp.dataview							MODIFY rank_limit_left_type				DEFAULT NULL;
ALTER TABLE csrimp.dataview							MODIFY rank_limit_right					DEFAULT NULL;
ALTER TABLE csrimp.dataview							MODIFY rank_limit_right_type			DEFAULT NULL;
ALTER TABLE csrimp.dataview							MODIFY rank_reverse						DEFAULT NULL;
ALTER TABLE csrimp.dataview							MODIFY suppress_unmerged_data_message	DEFAULT NULL;
ALTER TABLE csrimp.dataview_ind_member				MODIFY show_as_rank						DEFAULT NULL;
ALTER TABLE csrimp.dataview_zone					MODIFY is_target						DEFAULT NULL;
ALTER TABLE csrimp.dataview_zone					MODIFY target_direction					DEFAULT NULL;
ALTER TABLE csrimp.dataview_zone					MODIFY type								DEFAULT NULL;
ALTER TABLE csrimp.delegation						MODIFY period_interval_id				DEFAULT NULL;
ALTER TABLE csrimp.delegation						MODIFY period_set_id					DEFAULT NULL;
ALTER TABLE csrimp.delegation_ind					MODIFY allowed_na						DEFAULT NULL;
ALTER TABLE csrimp.deleg_grid_variance				MODIFY active							DEFAULT NULL;
ALTER TABLE csrimp.deleg_plan						MODIFY period_interval_id				DEFAULT NULL;
ALTER TABLE csrimp.deleg_plan						MODIFY period_set_id					DEFAULT NULL;
ALTER TABLE csrimp.factor_history					MODIFY changed_dtm						DEFAULT NULL;
ALTER TABLE csrimp.flow_alert_type					MODIFY deleted							DEFAULT NULL;
ALTER TABLE csrimp.flow_state						MODIFY pos								DEFAULT NULL;
ALTER TABLE csrimp.flow_transition_alert_cms_col	MODIFY alert_manager_flag				DEFAULT NULL;
ALTER TABLE csrimp.form								MODIFY period_interval_id				DEFAULT NULL;
ALTER TABLE csrimp.form								MODIFY period_set_id					DEFAULT NULL;
ALTER TABLE csrimp.fund								MODIFY company_sid						DEFAULT NULL;
ALTER TABLE csrimp.gresb_indicator_mapping			MODIFY not_applicable					DEFAULT NULL;
ALTER TABLE csrimp.ind								MODIFY period_interval_id				DEFAULT NULL;
ALTER TABLE csrimp.ind								MODIFY period_set_id					DEFAULT NULL;
ALTER TABLE csrimp.internal_audit_type				MODIFY active							DEFAULT NULL;
ALTER TABLE csrimp.internal_audit_type				MODIFY nc_audit_child_region			DEFAULT NULL;
ALTER TABLE csrimp.issue							MODIFY allow_auto_close					DEFAULT NULL;
ALTER TABLE csrimp.issue							MODIFY is_pending_assignment			DEFAULT NULL;
ALTER TABLE csrimp.issue							MODIFY is_public						DEFAULT NULL;
ALTER TABLE csrimp.issue_custom_field				MODIFY is_mandatory						DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY allow_owner_resolve_and_close	DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY allow_pending_assignment			DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY applies_to_audit					DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY can_set_public					DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY create_raw						DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY deletable_by_administrator		DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY deletable_by_owner				DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY deletable_by_raiser				DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY deleted							DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY enable_reject_action				DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY involve_min_users_in_issue		DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY owner_can_be_changed				DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY public_by_default				DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY region_link_type					DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY require_due_dtm_comment			DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY require_var_expl					DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY send_alert_on_issue_raised		DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY show_forecast_dtm				DEFAULT NULL;
ALTER TABLE csrimp.issue_type						MODIFY show_one_issue_popup				DEFAULT NULL;
ALTER TABLE csrimp.issue_type_rag_status			MODIFY pos								DEFAULT NULL;
ALTER TABLE csrimp.linked_meter						MODIFY pos								DEFAULT NULL;
ALTER TABLE csrimp.mail_mailbox_message				MODIFY modseq							DEFAULT NULL;
ALTER TABLE csrimp.metering_options					MODIFY analytics_current_month			DEFAULT NULL;
ALTER TABLE csrimp.meter_bucket						MODIFY high_resolution_only				DEFAULT NULL;
ALTER TABLE csrimp.meter_data_priority				MODIFY is_auto_patch					DEFAULT NULL;
ALTER TABLE csrimp.meter_data_priority				MODIFY is_input							DEFAULT NULL;
ALTER TABLE csrimp.meter_data_priority				MODIFY is_output						DEFAULT NULL;
ALTER TABLE csrimp.meter_data_priority				MODIFY is_patch							DEFAULT NULL;
ALTER TABLE csrimp.meter_input						MODIFY is_consumption_based				DEFAULT NULL;
ALTER TABLE csrimp.meter_input_aggregator			MODIFY is_mandatory						DEFAULT NULL;
ALTER TABLE csrimp.meter_patch_batch_job			MODIFY created_dtm						DEFAULT NULL;
ALTER TABLE csrimp.meter_patch_batch_job			MODIFY is_remove						DEFAULT NULL;
ALTER TABLE csrimp.meter_patch_data					MODIFY updated_dtm						DEFAULT NULL;
ALTER TABLE csrimp.meter_patch_job					MODIFY created_dtm						DEFAULT NULL;
ALTER TABLE csrimp.meter_reading					MODIFY active							DEFAULT NULL;
ALTER TABLE csrimp.meter_reading					MODIFY is_delete						DEFAULT NULL;
ALTER TABLE csrimp.meter_reading					MODIFY req_approval						DEFAULT NULL;
ALTER TABLE csrimp.meter_source_type				MODIFY allow_reset						DEFAULT NULL;
ALTER TABLE csrimp.meter_source_type				MODIFY auto_patch						DEFAULT NULL;
ALTER TABLE csrimp.meter_source_type				MODIFY descending						DEFAULT NULL;
ALTER TABLE csrimp.meter_source_type				MODIFY is_calculated_sub_meter			DEFAULT NULL;
ALTER TABLE csrimp.meter_source_type				MODIFY region_date_clipping				DEFAULT NULL;
ALTER TABLE csrimp.meter_source_type				MODIFY req_approval						DEFAULT NULL;
ALTER TABLE csrimp.non_compliance_type				MODIFY can_have_actions					DEFAULT NULL;
ALTER TABLE csrimp.non_compliance_type				MODIFY closure_behaviour_id				DEFAULT NULL;
ALTER TABLE csrimp.non_compliance_type				MODIFY root_cause_enabled				DEFAULT NULL;
ALTER TABLE csrimp.plugin							MODIFY use_reporting_period				DEFAULT NULL;
ALTER TABLE csrimp.qs_answer_log					MODIFY version_stamp					DEFAULT NULL;
ALTER TABLE csrimp.qs_response_file					MODIFY uploaded_dtm						DEFAULT NULL;
ALTER TABLE csrimp.quick_survey_type				MODIFY show_answer_set_dtm				DEFAULT NULL;
ALTER TABLE csrimp.region_metric					MODIFY show_measure						DEFAULT NULL;
ALTER TABLE csrimp.region_score_log					MODIFY set_dtm							DEFAULT NULL;
ALTER TABLE csrimp.region_score_log					MODIFY changed_by_user_sid				DEFAULT NULL;
ALTER TABLE csrimp.route_step						MODIFY pos								DEFAULT NULL;
ALTER TABLE csrimp.rss_cache						MODIFY error_count						DEFAULT NULL;
ALTER TABLE csrimp.scenario							MODIFY period_interval_id				DEFAULT NULL;
ALTER TABLE csrimp.scenario							MODIFY period_set_id					DEFAULT NULL;
ALTER TABLE csrimp.supplier							MODIFY default_region_mount_sid			DEFAULT NULL;
ALTER TABLE csrimp.target_dashboard					MODIFY period_interval_id				DEFAULT NULL;
ALTER TABLE csrimp.target_dashboard					MODIFY period_set_id					DEFAULT NULL;
ALTER TABLE csrimp.term_cond_doc_log				MODIFY accepted_dtm						DEFAULT NULL;
ALTER TABLE csrimp.tpl_report						MODIFY period_interval_id				DEFAULT NULL;
ALTER TABLE csrimp.tpl_report						MODIFY period_set_id					DEFAULT NULL;
ALTER TABLE csrimp.tpl_report_tag_dataview			MODIFY hide_if_empty					DEFAULT NULL;
ALTER TABLE csrimp.tpl_report_tag_dataview			MODIFY split_table_by_columns			DEFAULT NULL;
ALTER TABLE csrimp.var_expl							MODIFY hidden							DEFAULT NULL;


grant select, insert, update, delete on csrimp.chain_risk_level to web_user;
grant select, insert, update, delete on csrimp.chain_country_risk_level to web_user;
grant select, insert, update on chain.risk_level to csrimp;
grant select, insert, update on chain.country_risk_level to csrimp;
grant select on chain.risk_level_id_seq to csrimp;
grant select on chain.risk_level to csr;
grant select on chain.country_risk_level to csr;

-- Was added to build.sql late and but was not conditional in the latest script!
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

GRANT EXECUTE ON csr.portal_dashboard_pkg TO web_user;


CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action, ist.require_due_dtm_comment,
	   ist.is_region_editable is_issue_type_region_editable, i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
	   issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected,
	   CASE
		WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
		WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
		WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
		ELSE 'Ongoing'
	   END status, CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close,
	   CASE WHEN ist.get_assignables_sp IS NULL THEN 0 ELSE 1 END get_assignables_overridden
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;




BEGIN
	BEGIN
		INSERT INTO csr.est_job_type (est_job_type_id, description) VALUES(6, 'ReadOnly Metric');
	EXCEPTION
		WHEN dup_val_on_index THEN	
			NULL;
	END;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
    INSERT INTO csr.region_type_tag_group (app_sid, region_type, tag_group_id)
	     SELECT DISTINCT tgm.app_sid, r.region_type, tgm.tag_group_id 
		   FROM csr.tag_group_member tgm
		   JOIN csr.region_tag rt ON tgm.app_sid = rt.app_sid AND rt.tag_id = tgm.tag_id
		   JOIN csr.region r ON rt.app_sid = r.app_sid AND r.region_sid = rt.region_sid
		  WHERE (tgm.app_sid, tgm.tag_group_id) IN (
				SELECT DISTINCT app_sid, tag_group_id 
				  FROM csr.region_type_tag_group
			  )
		    AND (tgm.app_sid,r.region_type,tgm.tag_group_id) NOT IN (
				SELECT DISTINCT app_sid,region_type,tag_group_id 
				  FROM csr.region_type_tag_group
			  );
END;
/
BEGIN
	-- Find all region metric values in the est_space_attr table that are for the wrong region
	FOR r IN (
		SELECT sa.app_sid, sa.pm_val_id, sa.est_account_sid, sa.pm_customer_id, sa.pm_building_id
		  FROM csr.est_space_attr sa
		  JOIN csr.est_space s ON s.app_sid = sa.app_sid AND s.est_account_sid = sa.est_account_sid AND s.pm_customer_id = sa.pm_customer_id AND s.pm_building_id = sa.pm_building_id AND s.pm_space_id = sa.pm_space_id
		  JOIN csr.region_metric_val v ON v.app_sid = sa.app_sid AND v.region_metric_val_id = sa.region_metric_val_id
		  JOIN csr.est_building b ON b.app_sid = sa.app_sid AND b.est_account_sid = sa.est_account_sid AND b.pm_customer_id = sa.pm_customer_id AND b.pm_building_id = sa.pm_building_id
		  JOIN csr.property p ON p.app_sid = b.app_sid AND p.region_sid = b.region_sid
		 WHERE p.energy_star_sync = 1
		   AND p.energy_star_push = 0
		   AND v.region_sid != s.region_sid
	) LOOP
		-- Null out incorrect reigon metric val id
		UPDATE csr.est_space_attr
		   SET region_metric_val_id = NULL
		 WHERE app_sid = r.app_sid
		   AND pm_val_id = r.pm_val_id;
		-- Force a new job for the associated property
		UPDATE csr.est_building
		   SET last_job_dtm = NULL
		 WHERE app_sid = r.app_sid
		   AND est_account_sid = r.est_account_sid
		   AND pm_customer_id = r.pm_customer_id
		   AND pm_building_id = r.pm_building_id;
	END LOOP;
END;
/
BEGIN
	-- UPDATE
	UPDATE csr.module
	   SET module_name = 'Metering - base',
	       enable_sp = 'EnableMeteringBase',
	       description = 'Enables the basic metering module'
	 WHERE module_id = 20;
	-- UPDATE
	UPDATE csr.module
	   SET module_name = 'Metering - quick charts',
	       enable_sp = 'EnableMeterReporting',
	       description = 'Enables meter data quick charts'
	 WHERE module_id = 58;
	-- UPDATE
	UPDATE csr.module
	   SET module_name = 'Metering - urjanet',
	       enable_sp = 'EnableUrjanet',
	       description = 'Enables Urjanet integration pages and settings'
	 WHERE module_id = 60;
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (68, 'Metering - data feeds', 'EnableMeteringFeeds', 'Enables pages to set-up meter data feeds');
	
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (69, 'Metering - monitoring', 'EnableMeterMonitoring', 'Enables pages for data feeds and alarms');
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (70, 'Metering - utilities', 'EnableMeterUtilities', 'Enables pages for invoices, contracts and suppliers');
END;
/
BEGIN
	FOR r IN (
		-- Find all est_meters where the parent region sid is actually the region sid of an est_space
		SELECT m.app_sid, m.region_sid, s.pm_space_id,
			m.est_account_sid, m.pm_customer_id, m.pm_building_id, m.pm_meter_id
		  FROM csr.est_meter m
		  JOIN csr.region r
			ON r.app_sid = m.app_sid 
		   AND r.region_sid = m.region_sid
		  JOIN csr.est_space s 
			ON s.app_sid = m.app_sid 
		   AND s.est_account_sid = m.est_account_sid 
		   AND s.pm_customer_id = m.pm_customer_id 
		   AND s.pm_building_id = m.pm_building_id 
		   AND s.region_sid = r.parent_sid
		 ORDER BY app_sid
	) LOOP
		-- Update the space id inthe est_meter table
		UPDATE csr.est_meter
		   SET pm_space_id = r.pm_space_id
		 WHERE app_sid = r.app_sid
		   AND region_sid = r.region_sid
		   AND NVL(pm_space_id, -1) != NVL(r.pm_space_id, -1);
		-- Create change log entries that will kick-off energy star jobs
		BEGIN
			INSERT INTO csr.est_meter_change_log (app_sid, est_account_sid, pm_customer_id, pm_building_id, pm_meter_id)
			VALUES (r.app_sid, r.est_account_sid, r.pm_customer_id, r.pm_building_id, r.pm_meter_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore
		END;
	END LOOP;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT sid_id
		  FROM security.menu 
		 WHERE LOWER(action) ='/csr/site/property/admin/regionmetriclist.acds'
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, r.sid_id);
	END LOOP;
END;
/
DECLARE
	v_act_id						VARCHAR2(36);
	v_admins_sid					NUMBER(10);
	v_menu_sid						NUMBER(10);
	v_www_csr_site					NUMBER(10);
	v_www_sid						NUMBER(10);
	v_wwwroot_sid					NUMBER(10);
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT c.app_sid, c.host
		  FROM security.menu m 
		  JOIN security.securable_object so ON m.sid_id = so.sid_id 
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE LOWER(m.action) = '/csr/site/meter/meterlist.acds'
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		v_act_id := security.security_pkg.GetAct;
		
		BEGIN
			v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups/Administrators');
			BEGIN
				security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'menu/admin'),
					'csr_meter_admin', 'Metering admin', '/csr/site/meter/admin/menu.acds', 20, null, v_menu_sid);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					v_menu_sid := security.securableobject_pkg.GetSidFromPath(
						v_act_id, 
						security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'menu/admin'), 
						'csr_meter_admin'
					);
			END;
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1,
					security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT,
					v_admins_sid,
					security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.PropogateACEs(v_act_id, v_menu_sid);
			/*** ADD WEB RESOURCE ***/
			v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_wwwroot_sid, 'csr/site/meter');
			BEGIN
				security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_www_csr_site, 'admin', v_www_sid);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'admin');
			END;
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_sid), -1,
					security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT,
					v_admins_sid,
					security.security_pkg.PERMISSION_STANDARD_ALL);
		EXCEPTION
			WHEN others THEN
				NULL; -- don't mind if they don't have the normal menu structures/group etc.
		END;
	END LOOP;
	
	security.user_pkg.LogonAdmin;
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	 VALUES (67, 'Country risk', 'EnableChainCountryRisk', 'Enables country risk.');
		 
		 
CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 3 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   		 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
	
END;
/
DECLARE 
	v_capability_id		NUMBER;
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 1,  								/* CT_COMPANY*/
		in_capability		=> 'View country risk levels' 		/* chain.chain_pkg.VIEW_COUNTRY_RISK_LEVELS */, 
		in_perm_type		=> 1, 								/* BOOLEAN_PERMISSION */
		in_is_supplier 		=> 0
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;
		 
		 
INSERT INTO CSR.QS_QUESTION_TYPE(QUESTION_TYPE, LABEL, ANSWER_TYPE) VALUES ('evidence', 'Evidence question', null);




create or replace package csr.energy_star_account_pkg as end;
/
grant execute on csr.energy_star_account_pkg to web_user;


@..\enable_pkg
@..\energy_star_job_pkg
@..\energy_star_pkg
@..\region_metric_pkg
@..\property_pkg
@..\energy_star_account_pkg
@..\schema_pkg
@..\chain\chain_pkg
@..\chain\helper_pkg
@..\issue_pkg
@..\audit_pkg
@..\csr_data_pkg
@..\portal_dashboard_pkg
@..\deleg_plan_pkg
@..\..\..\aspen2\db\mdComment_pkg


@..\audit_body
@..\quick_survey_body
@..\csrimp\imp_body
@..\schema_body
@..\customer_body
@..\property_body
@..\tag_body
@..\energy_star_body
@..\enable_body
@..\meter_monitor_body
@..\meter_alarm_body
@..\utility_report_body
@..\energy_star_job_body
@..\region_body
@..\meter_body
@..\region_metric_body
@..\indicator_body
@..\dataset_legacy_body
@..\energy_star_account_body
@..\sheet_body
@..\chain\chain_body
@..\chain\company_body
@..\chain\company_filter_body
@..\chain\helper_body
@..\chain\type_capability_body
@..\issue_body
@..\deleg_plan_body
@..\delegation_body
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\pivot_body
@..\..\..\aspen2\db\mdComment_body
@..\..\..\aspen2\db\utils_body
@..\actions\ind_template_body
@..\actions\initiative_body
@..\actions\task_body
@..\chain\activity_body
@..\chain\component_body
@..\chain\plugin_body
@..\chain\questionnaire_body
@..\chem\substance_body
@..\ct\breakdown_body
@..\donations\browse_settings_body
@..\branding_body
@..\flow_body
@..\geo_map_body
@..\help_body
@..\incident_body
@..\initiative_body
@..\initiative_export_body
@..\portal_dashboard_body
@..\measure_body
@..\model_body
@..\postit_body
@..\scenario_body
@..\section_body
@..\section_search_body
@..\sqlreport_body
@..\target_dashboard_body
@..\teamroom_body
@..\templated_report_body



@update_tail
