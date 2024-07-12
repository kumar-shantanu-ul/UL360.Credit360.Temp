define version=3001
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
CREATE TABLE csr.internal_audit_report_guid (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	guid							VARCHAR2(36) NOT NULL,
	expiry_dtm						DATE NOT NULL,
	document						BLOB NULL,
	filename						VARCHAR2(255) NOT NULL,
	doc_type						VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_audit_report_guid PRIMARY KEY (app_sid, guid)
);
CREATE OR REPLACE TYPE CSR.T_REGION_METRIC_AUDIT_ROW AS 
  OBJECT ( 
	REGION_METRIC_VAL_ID	NUMBER(10),
	IND_SID					NUMBER(10),
	CONVERSION_ID			NUMBER(10),
	VAL						NUMBER(24, 10),
	EFFECTIVE_DTM			DATE
);
/
CREATE OR REPLACE TYPE CSR.T_REGION_METRIC_AUDIT_TABLE AS 
  TABLE OF CSR.T_REGION_METRIC_AUDIT_ROW;
/
CREATE GLOBAL TEMPORARY TABLE csr.temp_question_option_show_q (
	question_id				NUMBER(10),
	question_option_id		NUMBER(10),
	show_question_id		NUMBER(10)
) ON COMMIT DELETE ROWS;
CREATE TABLE CSR.FORECASTING_SCENARIO_ALERT(
	APP_SID						NUMBER(10, 0) 	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	FORECASTING_SID				NUMBER(10, 0) 	NOT NULL,
	CSR_USER_SID				NUMBER(10, 0) 	NOT NULL,
	CALC_JOB_ID					NUMBER(10, 0) 	NOT NULL,
	CALC_JOB_COMPLETION_DTM		DATE 			NOT NULL,
	CONSTRAINT PK_FRCAST_SCEN_ALERT PRIMARY KEY (APP_SID, FORECASTING_SID, CSR_USER_SID, CALC_JOB_ID)
)
;
DECLARE
	v_count NUMBER;
BEGIN
	-- drop table, can't find a reference to this anywhere
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tables
	 WHERE owner = 'CHAIN'
	   AND table_name = 'APPROVED_COMPANY_USER';
	   
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE CHAIN.APPROVED_COMPANY_USER';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'UPD'
	   AND index_name = 'IDX_SV_CHANGE_SVID';
	   
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'DROP INDEX UP'||'D.IDX_SV_CHANGE_SVID';
	END IF;
END;
/

DECLARE
	v_count		NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'EST_BUILDING'
	   AND column_name = 'PREV_REGION_SID';
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.EST_BUILDING ADD (PREV_REGION_SID NUMBER(10))';
	END IF;
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'EST_SPACE'
	   AND column_name = 'PREV_REGION_SID';
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.EST_SPACE ADD (PREV_REGION_SID NUMBER(10))';
	END IF;
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'FK_EST_BLDNG_PRGN';
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.EST_BUILDING ADD CONSTRAINT FK_EST_BLDNG_PRGN FOREIGN KEY (APP_SID, PREV_REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID)';
	END IF;
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_constraints
	 WHERE constraint_name = 'FK_EST_SPACE_PRGN';
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.EST_SPACE ADD CONSTRAINT FK_EST_SPACE_PRGN FOREIGN KEY (APP_SID, PREV_REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID)';
	END IF;
END;
/

DECLARE
	index_already_exists EXCEPTION;
	PRAGMA exception_init(index_already_exists, -955);
	table_doesnt_exists EXCEPTION;
	PRAGMA exception_init(table_doesnt_exists, -942);
	already_indexed EXCEPTION;
	PRAGMA exception_init(already_indexed, -1408);
	TYPE t_indexes IS TABLE OF VARCHAR2(2000);
	v_indexes t_indexes;
BEGIN	
	v_indexes := t_indexes(
		'create index aspen2.ix_filecache_upl_act_id_upload on aspen2.filecache_upload_progress (act_id, upload_key, app_sid)',
		'create index aspen2.pk_poll_option on aspen2.poll_option (poll_sid, option_pos)',
		'create index aspen2.pk_translated on aspen2.translated (original_hash, application_sid, lang)',
		'create index aspen2.pk_translation on aspen2.translation (original_hash, application_sid)',
		'create index chain.ix_bsci_associat_audit_ref on chain.bsci_associate (app_sid, audit_ref)',
		'create index chain.ix_bsci_audit_audit_type_id on chain.bsci_audit (app_sid, audit_type_id)',
		'create index chain.ix_bsci_audit_internal_audi on chain.bsci_audit (app_sid, internal_audit_sid)',
		'create index chain.ix_bsci_finding_audit_ref on chain.bsci_finding (app_sid, audit_ref)',
		'create index chain.ix_bsci_finding_audit_type_id on chain.bsci_finding (app_sid, audit_type_id)',
		'create index chain.ix_bsci_import_batch_job_id on chain.bsci_import (app_sid, batch_job_id)',
		'create index chain.ix_bsci_options_aud_type_2009 on chain.bsci_options (app_sid, audit_type_2009_id)',
		'create index chain.ix_bsci_options_aud_type_2014 on chain.bsci_options (app_sid, audit_type_2014_id)',
		'create index chain.ix_bsci_supplier_company_sid on chain.bsci_supplier (app_sid, company_sid)',
		'create index chain.ix_bsci_supplier_rsp_id on chain.bsci_supplier (rsp_id)',
		'create index chain.ix_company_type__follower_role on chain.company_type_relationship (app_sid, follower_role_sid)',
		'create index chain.ix_customer_grid_grid_extensio on chain.customer_grid_extension (grid_extension_id)',
		'create index chain.ix_dedupe_mappin_dedupe_field_ on chain.dedupe_mapping (dedupe_field_id)',
		'create index chain.ix_dedupe_mappin_reference_id on chain.dedupe_mapping (app_sid, reference_id)',
		'create index chain.ix_dedupe_mappin_tab_sid_col_s on chain.dedupe_mapping (app_sid, tab_sid, col_sid)',
		'create index chain.ix_dedupe_mappin_tag_group_id on chain.dedupe_mapping (app_sid, tag_group_id)',
		'create index chain.ix_dedupe_match_dedupe_rule_i on chain.dedupe_match (app_sid, dedupe_rule_id)',
		'create index chain.ix_dedupe_match_matched_to_co on chain.dedupe_match (app_sid, matched_to_company_sid)',
		'create index chain.ix_dedupe_merge__dedupe_field_ on chain.dedupe_merge_log (dedupe_field_id)',
		'create index chain.ix_dedupe_proces_dedupe_match_ on chain.dedupe_processed_record (dedupe_match_type_id)',
		'create index chain.ix_dedupe_proces_matched_by_us on chain.dedupe_processed_record (app_sid, matched_by_user_sid)',
		'create index chain.ix_dedupe_rule_m_dedupe_mappin on chain.dedupe_rule_mapping (app_sid, dedupe_mapping_id)',
		'create index chain.ix_filter_export_card_group_id on chain.filter_export_batch (card_group_id)',
		'create index chain.ix_filter_export_compound_filt on chain.filter_export_batch (app_sid, compound_filter_id)',
		'create index chain.ix_grid_extensio_extension_car on chain.grid_extension (extension_card_group_id)',
		'create index chain.ix_task_company_sid on chain.task (app_sid, supplier_company_sid)',
		'create index chain.pk181 on chain.product_metric_type (product_metric_type_id, app_sid)',
		'create index chain.pk285 on chain.amount_unit (amount_unit_id, app_sid)',
		'create index chain.pk63 on chain.task (task_id, app_sid)',
		'create index chain.pk88 on chain.task_type (task_type_id, app_sid)',
		'create index chain.pk88_1 on chain.task_scheme (task_scheme_id, app_sid)',
		'create index cms.ix_doc_template__doc_template_ on cms.doc_template_version (app_sid, doc_template_file_id)',
		'create index cms.ix_doc_template_lang on cms.doc_template (app_sid, lang)',
		'create index cms.ix_form_form_sid_curr on cms.form (app_sid, form_sid, current_version)',
		'create index csr.form_expr_id_unq on csr.form_expr (form_expr_id)',
		'create index csr.idx_deleg_ind_cond on csr.delegation_ind_cond_action (delegation_ind_cond_id)',
		'create index csr.idx_http_req_cache on csr.http_request_cache (request_hash, url)',
		'create index csr.idx_meter_source_data_region on csr.meter_source_data (app_sid, region_sid, priority)',
		'create index csr.idx_sheet_end on csr.sheet (app_sid, end_dtm)',
		'create index csr.idx_sheet_history_sheet on csr.sheet_history (app_sid, sheet_id)',
		'create index csr.idx_sheet_value on csr.sheet_value (app_sid, ind_sid, region_sid, status)',
		'create index csr.idx_sv_change_svid on csr.sheet_value_change (app_sid, sheet_value_id)',
		'create index csr.ix_aggregate_ind_aggregate_ind on csr.aggregate_ind_val_detail (app_sid, aggregate_ind_group_id)',
		'create index csr.ix_aggregate_ind_ind_sid on csr.aggregate_ind_val_detail (app_sid, ind_sid)',
		'create index csr.ix_aggregate_ind_region_sid on csr.aggregate_ind_val_detail (app_sid, region_sid)',
		'create index csr.ix_alert_batch_run_user on csr.alert_batch_run (app_sid, csr_user_sid)',
		'create index csr.ix_alert_type_parent on csr.std_alert_type (parent_alert_type_id)',
		'create index csr.ix_appr_dash_appr_dash_ind on csr.approval_dashboard_val (app_sid, approval_dashboard_sid, ind_sid)',
		'create index csr.ix_approval_dash_dashboard_ins on csr.approval_dashboard_val (app_sid, dashboard_instance_id, approval_dashboard_sid)',
		'create index csr.ix_approval_dash_ind_sid on csr.approval_dashboard_ind (app_sid, ind_sid)',
		'create index csr.ix_approval_dash_note_added_by on csr.approval_dashboard_val (app_sid, note_added_by_sid)',
		'create index csr.ix_approval_dash_period_set_id on csr.approval_dashboard (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_approval_dash_publish_doc_f on csr.approval_dashboard (app_sid, publish_doc_folder_sid)',
		'create index csr.ix_approval_note_added_by_sid on csr.approval_note_portlet_note (app_sid, added_by_sid)',
		'create index csr.ix_approval_note_approval_dash on csr.approval_note_portlet_note (app_sid, approval_dashboard_sid)',
		'create index csr.ix_approval_note_dashboard_ins on csr.approval_note_portlet_note (app_sid, dashboard_instance_id, approval_dashboard_sid)',
		'create index csr.ix_approval_note_region_sid on csr.approval_note_portlet_note (app_sid, region_sid)',
		'create index csr.ix_approval_note_tab_portlet_i on csr.approval_note_portlet_note (app_sid, tab_portlet_id)',
		'create index csr.ix_approval_step_model_sid on csr.approval_step_model (app_sid, model_sid)',
		'create index csr.ix_audit_iss_all_csr_user_sid on csr.audit_iss_all_closed_alert (app_sid, csr_user_sid)',
		'create index csr.ix_audit_type_cl_audit_closure on csr.audit_type_closure_type (app_sid, audit_closure_type_id)',
		'create index csr.ix_auto_imp_core_automated_imp on csr.auto_imp_core_data_settings (automated_import_file_type_id)',
		'create index csr.ix_auto_imp_core_date_format_t on csr.auto_imp_core_data_settings (date_format_type_id)',
		'create index csr.ix_auto_imp_core_first_col_dat on csr.auto_imp_core_data_settings (first_col_date_format_id)',
		'create index csr.ix_auto_imp_core_ind_mapping_t on csr.auto_imp_core_data_settings (ind_mapping_type_id)',
		'create index csr.ix_auto_imp_core_region_mappin on csr.auto_imp_core_data_settings (region_mapping_type_id)',
		'create index csr.ix_auto_imp_core_second_col_da on csr.auto_imp_core_data_settings (second_col_date_format_id)',
		'create index csr.ix_auto_imp_core_unit_mapping_ on csr.auto_imp_core_data_settings (unit_mapping_type_id)',
		'create index csr.ix_auto_imp_indi_ind_sid on csr.auto_imp_indicator_map (app_sid, ind_sid)',
		'create index csr.ix_auto_imp_regi_region_sid on csr.auto_imp_region_map (app_sid, region_sid)',
		'create index csr.ix_auto_imp_unit_measure_conve on csr.auto_imp_unit_map (app_sid, measure_conversion_id)',
		'create index csr.ix_auto_imp_zip__matched_impor on csr.auto_imp_zip_filter (app_sid, matched_import_class_sid)',
		'create index csr.ix_automated_imp_parent_instan on csr.automated_import_instance (app_sid, parent_instance_id)',
		'create index csr.ix_batch_job_app_batch_job_id on csr.batch_job_approval_dash_vals (app_sid, batch_job_id)',
		'create index csr.ix_batch_job_bat_batch_export_ on csr.batch_job_batched_export (batch_export_type_id)',
		'create index csr.ix_batch_job_bat_batch_import_ on csr.batch_job_batched_import (batch_import_type_id)',
		'create index csr.ix_batch_job_lik_batch_job_id on csr.batch_job_like_for_like (app_sid, batch_job_id)',
		'create index csr.ix_batch_job_log_event_type_id on csr.batch_job_log (event_type_id)',
		'create index csr.ix_batch_job_met_period_set_id on csr.batch_job_meter_extract (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_batch_job_requested_by_ on csr.batch_job (app_sid, requested_by_company_sid)',
		'create index csr.ix_benchmark_das_period_set_id on csr.benchmark_dashboard (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_cms_imp_insta_batch_job_id on csr.automated_import_instance (app_sid, batch_job_id)',
		'create index csr.ix_cms_imp_insta_cms_imp_class on csr.automated_import_instance (app_sid, automated_import_class_sid)',
		'create index csr.ix_cms_imp_insta_cms_imp_insta on csr.automated_import_instance_step (app_sid, automated_import_instance_id, automated_import_class_sid)',
		'create index csr.ix_cms_imp_insta_result on csr.automated_import_instance_step (result)',
		'create index csr.ix_cms_tab_alert_tab_sid on csr.cms_tab_alert_type (app_sid, tab_sid)',
		'create index csr.ix_compliance_op_quick_survey_ on csr.compliance_options (app_sid, quick_survey_type_id)',
		'create index csr.ix_compliance_op_regulation_fl on csr.compliance_options (app_sid, regulation_flow_sid)',
		'create index csr.ix_compliance_op_requirement_f on csr.compliance_options (app_sid, requirement_flow_sid)',
		'create index csr.ix_course_course_type_i on csr.course (app_sid, course_type_id)',
		'create index csr.ix_course_default_place on csr.course (app_sid, default_place_id)',
		'create index csr.ix_course_default_train on csr.course (app_sid, default_trainer_id)',
		'create index csr.ix_course_delivery_meth on csr.course (delivery_method_id)',
		'create index csr.ix_course_provision_id on csr.course (provision_id)',
		'create index csr.ix_course_quiz_sid on csr.course (app_sid, quiz_sid)',
		'create index csr.ix_course_region_sid on csr.course (app_sid, region_sid)',
		'create index csr.ix_course_schedu_calendar_even on csr.course_schedule (app_sid, calendar_event_id)',
		'create index csr.ix_course_schedu_course_id on csr.course_schedule (app_sid, course_id)',
		'create index csr.ix_course_schedu_place_id on csr.course_schedule (app_sid, place_id)',
		'create index csr.ix_course_schedu_trainer_id on csr.course_schedule (app_sid, trainer_id)',
		'create index csr.ix_course_status_id on csr.course (status_id)',
		'create index csr.ix_course_survey_sid on csr.course (app_sid, survey_sid)',
		'create index csr.ix_course_type_r_region_sid on csr.course_type_region (app_sid, region_sid)',
		'create index csr.ix_course_type_user_relation on csr.course_type (app_sid, user_relationship_type_id)',
		'create index csr.ix_custom_factor_created_by_si on csr.custom_factor_set (app_sid, created_by_sid)',
		'create index csr.ix_custom_factor_custom_factor on csr.custom_factor (app_sid, custom_factor_set_id)',
		'create index csr.ix_custom_factor_egrid_ref on csr.custom_factor (egrid_ref)',
		'create index csr.ix_custom_factor_factor_set_gr on csr.custom_factor_set (factor_set_group_id)',
		'create index csr.ix_custom_factor_factor_type_i on csr.custom_factor (factor_type_id)',
		'create index csr.ix_custom_factor_gas_type_id on csr.custom_factor (gas_type_id)',
		'create index csr.ix_custom_factor_std_measure_c on csr.custom_factor (std_measure_conversion_id)',
		'create index csr.ix_customer_alert_type_type on csr.customer_alert_type (std_alert_type_id)',
		'create index csr.ix_dataview_aggregation_p on csr.dataview (app_sid, aggregation_period_id)',
		'create index csr.ix_dataview_period_set_id on csr.dataview (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_deleg_grid_aggr_ind_agg_to on csr.delegation_grid_aggregate_ind (app_sid, aggregate_to_ind_sid)',
		'create index csr.ix_deleg_plan_period_set_id on csr.deleg_plan (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_deleg_report_period_set_id on csr.deleg_report (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_delegation_gr_form_sid on csr.delegation_grid (app_sid, form_sid)',
		'create index csr.ix_delegation_period_set_id on csr.delegation (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_delegation_tag_visibilit on csr.delegation (app_sid, tag_visibility_matrix_group_id)',
		'create index csr.ix_emission_fact_custom_factor on csr.emission_factor_profile_factor (app_sid, custom_factor_set_id)',
		'create index csr.ix_emission_fact_egrid_ref on csr.emission_factor_profile_factor (egrid_ref)',
		'create index csr.ix_emission_fact_factor_type_i on csr.emission_factor_profile_factor (factor_type_id)',
		'create index csr.ix_emission_fact_std_factor_se on csr.emission_factor_profile_factor (std_factor_set_id)',
		'create index csr.ix_enhesa_countr_lang on csr.enhesa_country_name (lang)',
		'create index csr.ix_enhesa_ctrgn_lang on csr.enhesa_country_region_name (lang)',
		'create index csr.ix_enhesa_headin_lang on csr.enhesa_heading_text (lang)',
		'create index csr.ix_enhesa_intro__lang on csr.enhesa_intro_text (lang)',
		'create index csr.ix_enhesa_intro_country_code on csr.enhesa_intro (country_code)',
		'create index csr.ix_enhesa_intro_country_code_ on csr.enhesa_intro (country_code, region_code)',
		'create index csr.ix_enhesa_keywor_lang on csr.enhesa_keyword_text (lang)',
		'create index csr.ix_enhesa_reg_country_code on csr.enhesa_reg (country_code)',
		'create index csr.ix_enhesa_reg_re_country_code_ on csr.enhesa_reg_region (country_code, region_code)',
		'create index csr.ix_enhesa_rqmt_country_code on csr.enhesa_rqmt (country_code)',
		'create index csr.ix_enhesa_rqmt_country_code_ on csr.enhesa_rqmt (country_code, region_code)',
		'create index csr.ix_enhesa_rqmt_t_lang on csr.enhesa_rqmt_text (lang)',
		'create index csr.ix_enhesa_scrngq_lang on csr.enhesa_scrngqn_text (lang)',
		'create index csr.ix_enhesa_status_lang on csr.enhesa_status_name (lang)',
		'create index csr.ix_enhesa_sup_do_country_code on csr.enhesa_sup_doc (country_code)',
		'create index csr.ix_enhesa_sup_do_country_code_ on csr.enhesa_sup_doc (country_code, region_code)',
		'create index csr.ix_enhesa_sup_do_lang on csr.enhesa_sup_doc_item_text (lang)',
		'create index csr.ix_enhesa_topic__country_code_ on csr.enhesa_topic_region (country_code, region_code)',
		'create index csr.ix_enhesa_topic_country_code on csr.enhesa_topic (country_code)',
		'create index csr.ix_enhesa_topic_status_id on csr.enhesa_topic (status_id)',
		'create index csr.ix_est_building_prev_region_s on csr.est_building (app_sid, prev_region_sid)',
		'create index csr.ix_est_energy_me_prev_region_s on csr.est_energy_meter (app_sid, prev_region_sid)',
		'create index csr.ix_est_space_prev_region_s on csr.est_space (app_sid, prev_region_sid)',
		'create index csr.ix_est_water_met_prev_region_s on csr.est_water_meter (app_sid, prev_region_sid)',
		'create index csr.ix_factor_custom_factor on csr.factor (app_sid, custom_factor_id)',
		'create index csr.ix_flow_st_ro_cap_role_sid on csr.flow_state_role_capability (app_sid, role_sid)',
		'create index csr.ix_flow_state_au_flow_state_au on csr.flow_state_audit_ind (flow_state_audit_ind_type_id)',
		'create index csr.ix_flow_state_au_internal_audi on csr.flow_state_audit_ind (app_sid, internal_audit_type_id)',
		'create index csr.ix_flow_state_flow_state_na on csr.flow_state (flow_state_nature_id)',
		'create index csr.ix_flow_state_na_flow_alert_cl on csr.flow_state_nature (flow_alert_class)',
		'create index csr.ix_form_period_set_id on csr.form (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_function_cour_course_id on csr.function_course (app_sid, course_id)',
		'create index csr.ix_function_cour_training_prio on csr.function_course (training_priority_id)',
		'create index csr.ix_ind_gas_type on csr.ind (app_sid, gas_type_id)',
		'create index csr.ix_ind_period_set_id on csr.ind (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_initiative_us_initiative_si on csr.initiative_user (app_sid, initiative_sid, project_sid)',
		'create index csr.ix_internal_audi_form_sid on csr.internal_audit_type (app_sid, form_sid)',
		'create index csr.ix_internal_audi_nc_score_thrs on csr.internal_audit (app_sid, nc_score_thrsh_id)',
		'create index csr.ix_internal_audi_ovw_nc_score_ on csr.internal_audit (app_sid, ovw_nc_score_thrsh_id)',
		'create index csr.ix_issue_meter_m_region on csr.issue_meter_missing_data (app_sid, region_sid)',
		'create index csr.ix_like_for_like_created_by_us on csr.like_for_like_slot (app_sid, created_by_user_sid)',
		'create index csr.ix_like_for_like_csr_user_sid on csr.like_for_like_email_sub (app_sid, csr_user_sid)',
		'create index csr.ix_like_for_like_csr_user_sid2 on csr.like_for_like_scenario_alert (app_sid, csr_user_sid)',
		'create index csr.ix_like_for_like_ind_sid on csr.like_for_like_slot (app_sid, ind_sid)',
		'create index csr.ix_like_for_like_last_refresh_ on csr.like_for_like_slot (app_sid, last_refresh_user_sid)',
		'create index csr.ix_like_for_like_period_set_id on csr.like_for_like_slot (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_like_for_like_region_sid on csr.like_for_like_excluded_regions (app_sid, region_sid)',
		'create index csr.ix_like_for_like_region_sid2 on csr.like_for_like_slot (app_sid, region_sid)',
		'create index csr.ix_like_for_like_scenario_run_ on csr.like_for_like_slot (app_sid, scenario_run_sid)',
		'create index csr.ix_location_name on csr.location (location_type_id, name)',
		'create index csr.ix_meter_raw_dat_automated_imp on csr.meter_raw_data_source (app_sid, automated_import_class_sid)',
		'create index csr.ix_metld_inagpr on csr.meter_live_data (app_sid, meter_input_id, aggregator, priority)',
		'create index csr.ix_metric_dashbo_period_set_id on csr.metric_dashboard (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_non_comp_t_rpt_aud_typ on csr.non_comp_type_rpt_audit_type (app_sid, internal_audit_type_id)',
		'create index csr.ix_period_intrvl_end_period on csr.period_interval_member (app_sid, period_set_id, end_period_id)',
		'create index csr.ix_period_intrvl_st_period on csr.period_interval_member (app_sid, period_set_id, start_period_id)',
		'create index csr.ix_plugin_form_sid on csr.plugin (app_sid, form_sid)',
		'create index csr.ix_qs_ansfil_svy_respon_fil on csr.qs_answer_file (app_sid, survey_response_id, sha1, filename, mime_type)',
		'create index csr.ix_qs_expr_non_c_non_complianc on csr.qs_expr_non_compl_action (app_sid, non_compliance_type_id)',
		'create index csr.ix_region_postit_postit_id on csr.region_postit (app_sid, postit_id)',
		'create index csr.ix_ruleset_period_set_id on csr.ruleset (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_scenario_period_set_id on csr.scenario (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_section_fact__attachment_id on csr.section_fact_attach (app_sid, attachment_id)',
		'create index csr.ix_section_fact_map_to_ind_si on csr.section_fact (app_sid, map_to_ind_sid)',
		'create index csr.ix_section_fact_map_to_region on csr.section_fact (app_sid, map_to_region_sid)',
		'create index csr.ix_section_fact_std_measure_c on csr.section_fact (std_measure_conversion_id)',
		'create index csr.ix_snapshot_period_set_id on csr.snapshot (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_ss_imi_monthl_period_id on csr.ss_imi_monthly_hours (period_id)',
		'create index csr.ix_std_factor_se_factor_set_gr on csr.std_factor_set (factor_set_group_id)',
		'create index csr.ix_std_factor_se_std_factor_se on csr.std_factor_set_active (std_factor_set_id)',
		'create index csr.ix_supplier_scor_changed_by_us on csr.supplier_score_log (app_sid, changed_by_user_sid)',
		'create index csr.ix_supplier_scor_score_type_id on csr.supplier_score_log (app_sid, score_type_id)',
		'create index csr.ix_target_dashbo_period_set_id on csr.target_dashboard (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_tpl_report_no_period_set_id on csr.tpl_report_non_compl (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_tpl_report_period_set_id on csr.tpl_report (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_tpl_report_sc_scenario_run_ on csr.tpl_report_schedule (app_sid, scenario_run_sid)',
		'create index csr.ix_tpl_report_ta_ind_tag on csr.tpl_report_tag_dataview (app_sid, ind_tag)',
		'create index csr.ix_tpl_report_ta_measure_conve on csr.tpl_report_tag_ind (app_sid, measure_conversion_id)',
		'create index csr.ix_tpl_report_ta_period_set_id on csr.tpl_report_tag_dataview (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_tpl_report_ta_saved_filter_ on csr.tpl_report_tag_dataview (app_sid, saved_filter_sid)',
		'create index csr.ix_tpl_report_ta_tab_portlet_i on csr.tpl_report_tag_approval_note (app_sid, tab_portlet_id)',
		'create index csr.ix_tpl_reptgev_period_set_id on csr.tpl_report_tag_eval (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_tpl_reptgind_period_set_id on csr.tpl_report_tag_ind (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_tpl_reptglog_period_set_id on csr.tpl_report_tag_logging_form (app_sid, period_set_id, period_interval_id)',
		'create index csr.ix_tpl_rettag_ta_approval_dash on csr.tpl_report_tag_approval_note (app_sid, approval_dashboard_sid)',
		'create index csr.ix_tpl_rptmat_ta_approval_dash on csr.tpl_report_tag_approval_matrix (app_sid, approval_dashboard_sid)',
		'create index csr.ix_tpl_rpttag_ta_approval_dash on csr.tpl_report_tag_dataview (app_sid, approval_dashboard_sid)',
		'create index csr.ix_trainer_user_sid on csr.trainer (app_sid, user_sid)',
		'create index csr.ix_training_opti_calendar_sid on csr.training_options (app_sid, calendar_sid)',
		'create index csr.ix_training_opti_flow_sid on csr.training_options (app_sid, flow_sid)',
		'create index csr.ix_urjanet_servi_raw_data_sour on csr.urjanet_service_type (app_sid, raw_data_source_id)',
		'create index csr.ix_user_course_course_id on csr.user_course (app_sid, course_id)',
		'create index csr.ix_user_course_l_user_sid_cour on csr.user_course_log (app_sid, user_sid, course_id)',
		'create index csr.ix_user_course_user_sid_cour on csr.user_course (app_sid, user_sid, course_schedule_id, course_id)',
		'create index csr.ix_user_function_function_id on csr.user_function (app_sid, function_id)',
		'create index csr.ix_user_mess_alrt_raised_user on csr.user_message_alert (app_sid, raised_by_user_sid)',
		'create index csr.ix_user_relation_parent_user_s on csr.user_relationship (app_sid, parent_user_sid)',
		'create index csr.ix_user_relation_user_relation on csr.user_relationship (app_sid, user_relationship_type_id)',
		'create index csr.ix_user_train_course_schedule on csr.user_training (app_sid, course_schedule_id, course_id)',
		'create index csr.ix_user_training_course_schedu on csr.user_training (app_sid, course_schedule_id)',
		'create index csr.ix_user_training_flow_item_id on csr.user_training (app_sid, flow_item_id)',
		'create index csr.ix_util_script_r_client_util_s on csr.util_script_run_log (app_sid, client_util_script_id)',
		'create index csr.ref2253 on csr.imp_conflict_val (imp_val_id)',
		'create index csr.uk_quick_survey_response on csr.quick_survey_response (app_sid, survey_response_id, survey_sid)',
		'create index donations.pk102 on donations.scheme_donation_status (app_sid, scheme_sid, donation_status_sid)',
		'create index mail.ix_log_entry_log_category_ on mail.log_entry (log_category_id)',
		'create index mail.ix_log_entry_log_program_i on mail.log_entry (log_program_id)',
		
		'create index csr.ix_automated_imp_mailbox_sid_m on csr.automated_import_instance (app_sid, mailbox_sid, mail_message_uid)',
		'create index csr.ix_auto_imp_mail_mailbox_sid on csr.auto_imp_mail (mailbox_sid)',
		'create index csr.ix_auto_imp_mail_matched_imp_c on csr.auto_imp_mailbox (app_sid, matched_imp_class_sid_for_body)',
		'create index csr.ix_auto_imp_mailbox_sid on csr.auto_imp_mailbox (mailbox_sid)',
		'create index csr.ix_auto_imp_mail_matched_impor on csr.auto_imp_mail_attach_filter (app_sid, matched_import_class_sid)',
		'create index csr.ix_auto_imp_mail_at_f_mail_sid on csr.auto_imp_mail_attach_filter (mailbox_sid)',
		'create index csr.ix_auto_imp_mail_file_mail_sid on csr.auto_imp_mail_file (mailbox_sid)',
		'create index csr.ix_auto_imp_mail_msg_mail_sid on csr.auto_imp_mail_msg (mailbox_sid)',
		'create index csr.ix_auto_imp_mail_sd_f_mail_sid on csr.auto_imp_mail_sender_filter (mailbox_sid)',
		'create index csr.ix_auto_imp_mail_sj_f_mail_sid on csr.auto_imp_mail_subject_filter (mailbox_sid)',
		'create index aspen2.ix_filecache_upl_act_id_up_app on aspen2.filecache_upload_progress (act_id, upload_key, app_sid)',
		'create index aspen2.ix_poll_option_poll_sid on aspen2.poll_option (poll_sid)',
		'create index aspen2.ix_poll_vote_poll_option_i on aspen2.poll_vote (poll_option_id)',
		'create index aspen2.ix_poll_vote_poll_sid on aspen2.poll_vote (poll_sid)',
		'create index chain.ix_component_sou_comp_typ_2 on chain.component_source (app_sid, component_type_id)',
		'create index chain.ix_component_typ_child_comp_2 on chain.component_type_containment (app_sid, child_component_type_id)',
		'create index chain.ix_dedupe_mappin_destination_t on chain.dedupe_mapping (app_sid, destination_tab_sid, destination_col_sid)',
		'create index chain.ix_email_stub_bl_stub_comparat on chain.email_stub_blacklist (stub_comparator_id)',
		'create index chain.ix_file_upload_company_sid on chain.file_upload (app_sid, company_sid)',
		'create index chain.ix_purchase_amount_unit_i2 on chain.purchase (app_sid, amount_unit_id)',
		'create index chain.ix_task_action_t_task_type_id on chain.task_action_trigger (app_sid, task_type_id)',
		'create index chain.ix_task_type_parent_task_t_2 on chain.task_type (app_sid, parent_task_type_id)',
		'create index chain.ix_task_type_task_scheme_i_2 on chain.task_type (app_sid, task_scheme_id)',
		'create index cms.ix_tab_enum_translat on cms.tab (app_sid, enum_translation_tab_sid)',
		'create index csr.ix_audit_log_audit_type_id on csr.audit_log (audit_type_id)',
		'create index csr.ix_calc_job_fetc_calc_job_id on csr.calc_job_fetch_stat (app_sid, calc_job_id)',
		'create index csr.ix_calc_job_stat_scenario_run_ on csr.calc_job_stat (app_sid, scenario_run_sid)',
		'create index csr.ix_deleg_plan_da_deleg_pl_co_2 on csr.deleg_plan_date_schedule (deleg_plan_col_id, app_sid)',
		'create index csr.ix_help_topic_fi_help_topic_id on csr.help_topic_file (help_topic_id, help_lang_id)',
		'create index csr.ix_measure_conve_measure_sid on csr.measure_conversion_set (app_sid, measure_sid)',
		'create index csr.ix_measure_conve_measure_conve on csr.measure_conversion_set_entry (app_sid, measure_conversion_id)',
		'create index csr.ix_model_instanc_map_to_region on csr.model_instance_map (app_sid, map_to_region_sid)',
		'create index csr.ix_model_validat_model_sid_she on csr.model_validation (app_sid, model_sid, sheet_id, cell_name)',
		'create index csr.ix_property_divi_division_id_a on csr.property_division (division_id, app_sid)',
		'create index csr.ix_quick_survey_root_ind_sid on csr.quick_survey (app_sid, root_ind_sid)',
		'create index csr.ix_region_proc_f_meter_documen on csr.region_proc_file (app_sid, meter_document_id)',
		'create index csr.ix_route_log_route_id on csr.route_log (app_sid, route_id)',
		'create index csr.ix_route_log_route_step_id on csr.route_log (app_sid, route_step_id)',
		'create index csr.ix_sheet_value_v_var_expl_id on csr.sheet_value_var_expl (app_sid, var_expl_id)',
		'create index csr.ix_supplier_surv_survey_sid_su on csr.supplier_survey_response (app_sid, survey_sid, survey_response_id)',
		'create index csr.ix_tpl_report_ta_tpl_ind_id on csr.tpl_report_tag (app_sid, tpl_report_tag_ind_id)',
		'create index csr.ix_tpl_report_ta_tpl_eval_id on csr.tpl_report_tag (app_sid, tpl_report_tag_eval_id)',
		'create index csr.ix_tpl_report_ta_dataview_sid_ on csr.tpl_report_tag_dv_region (app_sid, dataview_sid, region_sid)',
		'create index csr.ix_tpl_report_ta_ev_tpl_ev_id on csr.tpl_report_tag_eval_cond (app_sid, tpl_report_tag_eval_id)',
		'create index donations.ix_scheme_donati_scheme_sid on donations.scheme_donation_status (app_sid, scheme_sid)'
	);
	
	FOR i IN 1 .. v_indexes.COUNT LOOP
		BEGIN
			EXECUTE IMMEDIATE v_indexes(i);
		EXCEPTION
			WHEN index_already_exists THEN
				NULL;
			WHEN table_doesnt_exists THEN
				NULL;
			WHEN already_indexed THEN
				NULL;
		END;	
	END LOOP;
END;
/
CREATE TABLE CSR.CALC_JOB_STAT (
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CALC_JOB_ID               NUMBER(10, 0)    NOT NULL,
    SCENARIO_RUN_SID          NUMBER(10, 0),
    VERSION					  NUMBER(10, 0),
    START_DTM                 DATE             NOT NULL,
    END_DTM                   DATE             NOT NULL,
    CALC_JOB_INDS			  NUMBER(10, 0)	   NOT NULL,
    ATTEMPTS                  NUMBER(10, 0)    NOT NULL,
    CALC_JOB_TYPE             NUMBER(10, 0)    NOT NULL,
    PRIORITY                  NUMBER(10, 0)    NOT NULL,
    FULL_RECOMPUTE            NUMBER(1, 0)     NOT NULL,       
    CREATED_DTM				  DATE			   NOT NULL,
    RAN_DTM					  DATE			   NOT NULL,
    RAN_ON					  VARCHAR2(256)	   NOT NULL,
    SCENARIO_FILE_SIZE		  NUMBER(20)	   NOT NULL,
    HEAP_ALLOCATED			  NUMBER(20)	   NOT NULL,
    TOTAL_TIME				  NUMBER(10, 2)	   NOT NULL,
    FETCH_TIME				  NUMBER(10, 2)	   NOT NULL,
    CALC_TIME				  NUMBER(10, 2)	   NOT NULL,
    LOAD_FILE_TIME			  NUMBER(10, 2)	   NOT NULL,
    LOAD_METADATA_TIME		  NUMBER(10, 2)	   NOT NULL,
    LOAD_VALUES_TIME	  	  NUMBER(10, 2)	   NOT NULL,
    LOAD_AGGREGATES_TIME	  NUMBER(10, 2)	   NOT NULL,
    SCENARIO_RULES_TIME		  NUMBER(10, 2)	   NOT NULL,
    SAVE_FILE_TIME			  NUMBER(10, 2)	   NOT NULL,    
    TOTAL_VALUES			  NUMBER(20)	   NOT NULL,    
    AGGREGATE_VALUES		  NUMBER(20)	   NOT NULL,
    CALC_VALUES				  NUMBER(20)	   NOT NULL,
    NORMAL_VALUES		  	  NUMBER(20)	   NOT NULL,
    EXTERNAL_AGGREGATE_VALUES NUMBER(20)	   NOT NULL,
    CALCS_RUN				  NUMBER(10)	   NOT NULL,
	INDS					  NUMBER(10)	   NOT NULL,
	REGIONS					  NUMBER(10)	   NOT NULL,
    CONSTRAINT CK_CALC_JOB_STAT_DATES CHECK(END_DTM > START_DTM AND TRUNC(END_DTM,'DD') = END_DTM AND TRUNC(START_DTM,'DD') = START_DTM),
    CONSTRAINT CK_CALC_JOB_ST_FULL_RECOMPUTE CHECK (FULL_RECOMPUTE IN (0,1)),
    CONSTRAINT PK_CALC_JOB_STAT PRIMARY KEY (APP_SID, CALC_JOB_ID)
)
;
CREATE TABLE CSR.CALC_JOB_FETCH_STAT (
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CALC_JOB_ID               NUMBER(10, 0)    NOT NULL,
    FETCH_SP				  VARCHAR2(256),
    FETCH_TIME				  NUMBER(10, 2)	   NOT NULL
);
CREATE TABLE CSR.IA_TYPE_REPORT_GROUP (
	APP_SID 						NUMBER(10) DEFAULT SYS_CONTEXT('APP', 'SECURITY') NOT NULL,
	IA_TYPE_REPORT_GROUP_ID 		NUMBER(10) NOT NULL,
	LABEL 							VARCHAR(255) NOT NULL,
	CONSTRAINT PK_IA_TYPE_REPORT_GROUP PRIMARY KEY (APP_SID, IA_TYPE_REPORT_GROUP_ID)
);
CREATE SEQUENCE CSR.IA_TYPE_REPORT_GROUP_ID_SEQ CACHE 5;
CREATE TABLE CSRIMP.IA_TYPE_REPORT_GROUP (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	IA_TYPE_REPORT_GROUP_ID			NUMBER(10) NOT NULL,
	LABEL							VARCHAR(255) NOT NULL,
	CONSTRAINT PK_IA_TYPE_REPORT_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, IA_TYPE_REPORT_GROUP_ID),
	CONSTRAINT FK_IA_TYPE_REPORT_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_IA_TYPE_REPORT_GROUP (
	CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IA_TYPE_REPORT_GROUP_ID			NUMBER(10)	NOT NULL,
	NEW_IA_TYPE_REPORT_GROUP_ID			NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_IA_TYPE_REPORT_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_IA_TYPE_REPORT_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_IA_TYPE_REPORT_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_IA_TYPE_REPORT_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_IA_TYPE_REPORT_GROUP FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);


ALTER TABLE csr.internal_audit_type_report ADD (
	use_merge_field_guid			NUMBER(1) DEFAULT 0 NOT NULL,
	guid_expiration_days			NUMBER(10) NULL,
	CONSTRAINT chk_use_merge_fld_guid CHECK (use_merge_field_guid IN (0,1)),
	CONSTRAINT chk_has_expiration CHECK (use_merge_field_guid = 0 OR guid_expiration_days IS NOT NULL)
);
ALTER TABLE csrimp.internal_audit_type_report ADD (
	use_merge_field_guid			NUMBER(1) DEFAULT 0 NOT NULL,
	guid_expiration_days			NUMBER(10) NULL
);
ALTER TABLE csr.automated_import_class
  ADD process_all_pending_files NUMBER (1) DEFAULT 0 NOT NULL;
 
ALTER TABLE csr.automated_import_class
  ADD CONSTRAINT ck_auto_imp_cls_process_all CHECK (process_all_pending_files IN (0, 1));
ALTER TABLE csr.automated_import_class_step
  ADD on_failure_sp VARCHAR2(255);

-- I think this is a duff import and could probably be deleted.
UPDATE csr.automated_import_class
   SET label = 'Otto Monthly Import 2'
 WHERE automated_import_class_sid = 28628461;

CREATE UNIQUE INDEX CSR.UK_CMS_IMP_CLASS_LABEL ON CSR.AUTOMATED_IMPORT_CLASS(APP_SID, UPPER(LABEL));
ALTER TABLE csr.all_space
 DROP CONSTRAINT FK_PRP_TYP_SPC_TYP_SPC DROP INDEX;
ALTER TABLE csr.all_space
  ADD CONSTRAINT FK_ALL_SPC_TYP_SPC_TYP
FOREIGN KEY (app_sid, space_type_id)
REFERENCES csr.space_type(app_sid, space_type_id);
ALTER TABLE csr.all_space
  ADD CONSTRAINT FK_ALL_SPC_TYP_PROP_TYP
FOREIGN KEY (app_sid, property_type_id)
REFERENCES csr.property_type(app_sid, property_type_id);
CREATE INDEX csr.ix_space_type ON csr.all_space(app_sid, space_type_id);
CREATE INDEX csr.ix_space_type_prop_type ON csr.all_space(app_sid, property_type_id);
ALTER TABLE CHAIN.HIGG_CONFIG ADD (COPY_SCORE_ON_SURVEY_SUBMIT NUMBER(1) DEFAULT 0 NOT NULL);
ALTER TABLE CHAIN.HIGG_CONFIG ADD CONSTRAINT CHK_COPY_SCORE_0_OR_1 CHECK (COPY_SCORE_ON_SURVEY_SUBMIT IN (0,1));
ALTER TABLE CSRIMP.HIGG_CONFIG ADD (COPY_SCORE_ON_SURVEY_SUBMIT NUMBER(1));
ALTER TABLE CSR.CUSTOMER ADD (
	REST_API_GUEST_ACCESS						NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CUST_REST_API_GUEST_ACCESS CHECK (REST_API_GUEST_ACCESS IN (0,1))
);
ALTER TABLE CSRIMP.CUSTOMER ADD (
	REST_API_GUEST_ACCESS						NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CUST_REST_API_GUEST_ACCESS CHECK (REST_API_GUEST_ACCESS IN (0,1))
);
ALTER TABLE csr.doc_folder ADD (
	property_sid					NUMBER(10) NULL,
	CONSTRAINT fk_doc_folder_property 
		FOREIGN KEY (app_sid, property_sid) 
		REFERENCES csr.all_property (app_sid, region_sid)
);
ALTER TABLE csrimp.doc_folder ADD (
	property_sid					NUMBER(10) NULL
);
CREATE INDEX csr.ix_doc_folder_property ON csr.doc_folder (app_sid, property_sid);
ALTER TABLE csr.delegation_description
ADD last_changed_dtm DATE;
ALTER TABLE csrimp.delegation_description
ADD last_changed_dtm DATE;
ALTER TABLE CSR.DATAVIEW ADD SHOW_LAYER_VARIANCE_PCT_BASE NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW ADD SHOW_LAYER_VARIANCE_ABS_BASE NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_PCT_BASE NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_ABS_BASE NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW ADD SHOW_LAYER_VARIANCE_PCT_BASE NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW ADD SHOW_LAYER_VARIANCE_ABS_BASE NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_PCT_BASE NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD SHOW_LAYER_VARIANCE_ABS_BASE NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.quick_survey_expr MODIFY expr NULL;
ALTER TABLE csr.quick_survey_expr ADD (
	question_id						NUMBER(10),
	question_option_id				NUMBER(10),
	CONSTRAINT fk_quick_survey_expr_quest_opt 
		FOREIGN KEY (app_sid, question_id, question_option_id, survey_version)
		REFERENCES csr.qs_question_option (app_sid, question_id, question_option_id, survey_version),
	CONSTRAINT chk_qs_expr_or_question CHECK (
		(expr IS NOT NULL AND question_id IS NULL AND question_option_id IS NULL) OR 
		(expr IS NULL AND question_id IS NOT NULL AND question_option_id IS NOT NULL))	
);
CREATE UNIQUE INDEX csr.uk_quick_survey_expr_question ON csr.quick_survey_expr (app_sid, survey_sid, survey_version, NVL2(expr, expr_id, NULL), question_id, question_option_id);
CREATE INDEX csr.ix_quick_survey_expr_ques_o_id ON csr.quick_survey_expr (app_sid, question_id, question_option_id, survey_version); 
ALTER TABLE csrimp.quick_survey_expr MODIFY expr NULL;
ALTER TABLE csrimp.quick_survey_expr ADD (
	question_id						NUMBER(10),
	question_option_id				NUMBER(10),
	CONSTRAINT chk_qs_expr_or_question CHECK (
		(expr IS NOT NULL AND question_id IS NULL AND question_option_id IS NULL) OR 
		(expr IS NULL AND question_id IS NOT NULL AND question_option_id IS NOT NULL))	
);
CREATE UNIQUE INDEX csrimp.uk_quick_survey_expr_question ON csrimp.quick_survey_expr (csrimp_session_id, survey_sid, survey_version, NVL2(expr, expr_id, NULL), question_id, question_option_id);
DROP INDEX CSR.PLUGIN_JS_CLASS;
CREATE UNIQUE INDEX CSR.PLUGIN_JS_CLASS ON CSR.PLUGIN(APP_SID, JS_CLASS, FORM_PATH, GROUP_KEY, SAVED_FILTER_SID, RESULT_MODE, PORTAL_SID, R_SCRIPT_PATH, FORM_SID);
ALTER TABLE CSR.INCIDENT_TYPE RENAME COLUMN mobile_list_path TO mobile_form_path;
ALTER TABLE CSR.INCIDENT_TYPE DROP COLUMN mobile_edit_path;
ALTER TABLE CSR.INCIDENT_TYPE DROP COLUMN mobile_new_case_path;
ALTER TABLE CSR.INCIDENT_TYPE ADD ( 
	mobile_form_sid NUMBER(10, 0),
	CONSTRAINT ck_incident_mobile_form CHECK ( mobile_form_path IS NULL OR mobile_form_sid IS NULL )
);
ALTER TABLE csr.quick_survey_version RENAME COLUMN question_xml TO xxx_question_xml;
ALTER TABLE csr.quick_survey_version ADD question_xml CLOB;
UPDATE csr.quick_survey_version
   SET question_xml = xmltype.getClobVal(xxx_question_xml)
 WHERE question_xml IS NULL;
ALTER TABLE csr.quick_survey_version MODIFY question_xml NOT NULL;
ALTER TABLE csr.quick_survey_version MODIFY xxx_question_xml NULL;
ALTER TABLE csr.quick_survey_response RENAME COLUMN question_xml_override TO xxx_question_xml_override;
ALTER TABLE csr.quick_survey_response ADD question_xml_override CLOB;
UPDATE csr.quick_survey_response
   SET question_xml_override = xmltype.getClobVal(xxx_question_xml_override)
 WHERE question_xml_override IS NULL
   AND xxx_question_xml_override IS NOT NULL;
ALTER TABLE csrimp.quick_survey_version RENAME COLUMN question_xml TO xxx_question_xml;
ALTER TABLE csrimp.quick_survey_version ADD question_xml CLOB;
UPDATE csrimp.quick_survey_version
   SET question_xml = xmltype.getClobVal(xxx_question_xml)
 WHERE question_xml IS NULL;
ALTER TABLE csrimp.quick_survey_version MODIFY question_xml NOT NULL;
ALTER TABLE csrimp.quick_survey_version MODIFY xxx_question_xml NULL;
ALTER TABLE csrimp.quick_survey_response RENAME COLUMN question_xml_override TO xxx_question_xml_override;
ALTER TABLE csrimp.quick_survey_response ADD question_xml_override CLOB;
UPDATE csrimp.quick_survey_response
   SET question_xml_override = xmltype.getClobVal(xxx_question_xml_override)
 WHERE question_xml_override IS NULL
   AND xxx_question_xml_override IS NOT NULL;
ALTER TABLE CSR.CALC_JOB_STAT ADD CONSTRAINT FK_CALC_JOB_STAT_SCN_RUN
	FOREIGN KEY (APP_SID, SCENARIO_RUN_SID)
	REFERENCES CSR.SCENARIO_RUN (APP_SID, SCENARIO_RUN_SID);
ALTER TABLE CSR.CALC_JOB_FETCH_STAT ADD CONSTRAINT FK_CALC_JOB_FTCH_STAT_CALC_JB
	FOREIGN KEY (APP_SID, CALC_JOB_ID)
	REFERENCES CSR.CALC_JOB_STAT (APP_SID, CALC_JOB_ID);
ALTER TABLE CSR.INTERNAL_AUDIT_TYPE_REPORT ADD IA_TYPE_REPORT_GROUP_ID NUMBER(10) NULL;
ALTER TABLE CSR.INTERNAL_AUDIT_TYPE_REPORT ADD CONSTRAINT FK_IA_REPORT_GROUP FOREIGN KEY (APP_SID, IA_TYPE_REPORT_GROUP_ID)
	REFERENCES CSR.IA_TYPE_REPORT_GROUP;
ALTER TABLE CSRIMP.INTERNAL_AUDIT_TYPE_REPORT ADD IA_TYPE_REPORT_GROUP_ID NUMBER(10) NULL;
ALTER TABLE CSR.CUSTOMER ADD DIVISIBILITY_BUG NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_DIVISIBILITY_BUG CHECK (DIVISIBILITY_BUG IN (0,1));
UPDATE CSR.CUSTOMER SET DIVISIBILITY_BUG = 1 WHERE MERGED_SCENARIO_RUN_SID IS NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER ADD DIVISIBILITY_BUG NUMBER(1, 0) NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_CUSTOMER_DIVISIBILITY_BUG CHECK (DIVISIBILITY_BUG IN (0,1));

create index csr.ix_internal_audi_ia_type_repor on csr.internal_audit_type_report (app_sid, ia_type_report_group_id);

grant select on csr.internal_audit_survey to chain;
grant select on csr.v$quick_survey_response to chain;
grant select,insert,update,delete on csrimp.internal_audit_type_report to tool_user;
GRANT INSERT ON CSR.IA_TYPE_REPORT_GROUP TO CSRIMP;
GRANT SELECT ON CSR.IA_TYPE_REPORT_GROUP_ID_SEQ TO CSRIMP;
GRANT SELECT,INSERT,UPDATE,DELETE ON CSRIMP.INTERNAL_AUDIT_TYPE_REPORT TO TOOL_USER;
GRANT SELECT,INSERT,UPDATE,DELETE ON CSRIMP.IA_TYPE_REPORT_GROUP TO TOOL_USER;


ALTER TABLE CSR.INCIDENT_TYPE ADD CONSTRAINT FK_INC_TYPE_CMS_FORM
	FOREIGN KEY (APP_SID, MOBILE_FORM_SID) 
	REFERENCES CMS.FORM (APP_SID, FORM_SID);
	
create index csr.ix_incident_type_mobile_form_s on csr.incident_type (app_sid, mobile_form_sid);


CREATE OR REPLACE VIEW csr.v$space AS
	SELECT s.app_sid, s.region_sid, r.description, r.active, r.parent_sid, s.space_type_id, st.label space_type_label, s.current_lease_id, s.property_region_Sid,
		   l.tenant_name current_tenant_name, r.disposal_dtm
	  FROM csr.space s
	  JOIN v$region r on s.region_sid = r.region_sid
	  JOIN space_type st ON s.space_type_Id = st.space_type_id
	  LEFT JOIN v$lease l ON l.lease_id = s.current_lease_id;




DECLARE
	v_app_sid 					security.security_pkg.T_SID_ID;
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_csr_site				security.security_pkg.T_SID_ID;
	v_www_csr_site_audit		security.security_pkg.T_SID_ID;
	v_audit_report_sid 			security.security_pkg.T_SID_ID;
	v_www_csr_site_public_audit security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM security.securable_object so
		  JOIN csr.customer c ON c.app_sid = so.application_sid_id
		 WHERE so.name = 'Audits'
		   AND so.parent_sid_id = so.application_sid_id
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		v_act_id := SYS_CONTEXT('SECURITY','ACT');
		v_app_sid := SYS_CONTEXT('SECURITY','APP');
		
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
		v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_sid, 'csr/site');
		v_www_csr_site_audit := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'audit');
		BEGIN
			v_www_csr_site_public_audit := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site_audit, 'public');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_sid, v_www_csr_site_audit, 'public', v_www_csr_site_public_audit);
			-- add everyone to public audit report download
			security.acl_pkg.AddACE(
				v_act_id,
				security.acl_pkg.GetDACLIDForSID(v_www_csr_site_public_audit),
				security.security_pkg.ACL_INDEX_LAST,
				security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT,
				security.security_pkg.SID_BUILTIN_EVERYONE,
				security.security_pkg.PERMISSION_STANDARD_READ
			);
		END;
		security.user_pkg.Logoff(v_act_id);
	END LOOP;
END;
/
BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name => '"CSR"."ProcessExpiredAuditReports"',
		job_type => 'PLSQL_BLOCK',
		job_action => 'begin security.user_pkg.LogonAdmin; audit_pkg.ProcessExpiredPublicReports; security.user_pkg.Logoff(SYS_CONTEXT(''SECURITY'',''ACT'')); end;',
		number_of_arguments => 0,
		start_date => to_timestamp_tz('2008/01/01 04:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval => 'FREQ=DAILY',
		enabled => TRUE,
		auto_drop => FALSE,
		comments => 'Clear out expired public audit reports');
END;
/
BEGIN
	UPDATE csr.automated_import_class_step
	   SET on_failure_sp = on_completion_sp
	 WHERE on_completion_sp IS NOT NULL
	   AND on_failure_sp IS NULL;
END;
/
INSERT INTO csr.audit_type_group (audit_type_group_id, description)
VALUES (5, 'Metric object');
INSERT INTO csr.audit_type (audit_type_id, label, audit_type_group_id)
VALUES (500, 'Region metric change', 5);
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
VALUES (csr.plugin_id_seq.NEXTVAL, 1, 'Property audit log', '/csr/site/property/properties/controls/AuditLogPanel.js', 'Controls.AuditLogPanel', 'Credit360.Plugins.PluginDto', 'This tab shows an audit log of this property and all associated spaces, meters and metrics', '', '');
BEGIN
	INSERT INTO csr.user_setting (category, setting, description, data_type)
	VALUES ('CREDIT360.PROPERTY', 'activeTab', 'stores the last active plugin tab', 'STRING');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	
	security.user_pkg.logonadmin;
	
	UPDATE csr.flow_alert_class
	   SET on_save_helper_sp = 'flow_pkg.OnCreateCampaignFlow'
	 WHERE flow_alert_class = 'campaign';
	FOR t IN (
		SELECT fst.app_sid, fst.flow_sid, fst.flow_state_transition_id, fst.helper_sp, fst.verb
		  FROM csr.flow f
		  JOIN csr.flow_state_transition fst ON f.flow_sid = fst.flow_sid AND f.app_sid = fst.app_sid
		 WHERE fst.lookup_key = 'SUBMIT'
		   AND fst.helper_sp IS NULL
		   AND f.flow_alert_class = 'campaign'
		   AND EXISTS(
			SELECT 1
			  FROM csr.qs_campaign qsc
			  JOIN csr.quick_survey qs ON qsc.survey_sid = qs.survey_sid AND qsc.app_sid = qs.app_sid
			  JOIN csr.score_type st ON qs.score_type_id = st.score_type_id AND qs.app_sid = st.app_sid
			 WHERE qsc.flow_sid = f.flow_sid
			   AND st.applies_to_regions = 1
		  )
	)
	LOOP
		-- Ensure we have the helper sp registered for the flow
		BEGIN
			INSERT INTO csr.flow_state_trans_helper
				(app_sid, flow_sid, helper_sp, label)
			VALUES
				(t.app_sid, t.flow_sid, 'csr.campaign_pkg.ApplyCampaignScoresToProperty','Update property scores from campaign');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		-- Add the helper sp to the state transistion
		UPDATE csr.flow_state_transition
		   SET helper_sp = 'csr.campaign_pkg.ApplyCampaignScoresToProperty'
		 WHERE app_sid = t.app_sid
		   AND flow_state_transition_id = t.flow_state_transition_id;
	END LOOP;
END;
/
BEGIN
	INSERT INTO csr.module_param (
		module_id, param_name, param_hint, pos
	) VALUES (
		41, 'in_enable_guest_access', 'Guest access (y/n)', 0
	);
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (90, 'Properties - document library', 'EnablePropertyDocLib', 'Enables the property document library and document tab.');
BEGIN
	-- For all sites...
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c, security.website w
		 WHERE c.host = w.website_name
	) LOOP
		security.user_pkg.logonadmin(r.host);
		DECLARE
			v_act_id 					security.security_pkg.T_ACT_ID;
			v_app_sid 					security.security_pkg.T_SID_ID;
			v_menu						security.security_pkg.T_SID_ID;
			v_admin_menu				security.security_pkg.T_SID_ID;
			v_translations_menu			security.security_pkg.T_SID_ID;
		BEGIN
			v_act_id := security.security_pkg.GetAct;
			v_app_sid := security.security_pkg.GetApp;
			v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
			BEGIN
				v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Admin');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_menu, 'admin',  'Admin',  '/csr/site/userSettings.acds',  0, null, v_admin_menu);
			END;
			BEGIN
				v_translations_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_admin_translations_import');
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'csr_admin_translations_import',  'Translations import',  '/csr/site/admin/translations/translationsImport.acds',  12, null, v_translations_menu);
			END;
		END; 
	END LOOP;
	-- clear the app_sid
	security.user_pkg.logonadmin;
END;
/
BEGIN
	INSERT INTO csr.batched_export_type
	  (batch_export_type_id, label, assembly)
	VALUES
	  (16, 'Delegation translations', 'Credit360.ExportImport.Export.Batched.Exporters.DelegationTranslationExporter');
END;
/
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28214, 4, 'GBTU (UK)', 1/1055055852620, 1, 0, 1);
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28215, 4, 'GBTU (US)', 1/1054804000000, 1, 0, 1);
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28216, 4, 'GBTU (EC)', 1/1055060000000, 1, 0, 1);
	
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28217, 9, 'kg/GBTU (UK)', 1055055852620, 1, 0, 0);
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28218, 9, 'kg/GBTU (US)', 1054804000000, 1, 0, 0);
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28219, 9, 'kg/GBTU (EC)', 1055060000000, 1, 0, 0);
	
INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, OVERRIDE_USER_SEND_SETTING, STD_ALERT_TYPE_GROUP_ID) VALUES (77, 'Forecasting dataset calculation complete',
	'Calculating the dataset for a forecasting slot has completed.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).', 1, 14
);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'SLOT_NAME', 'Slot name', 'The name of the forecasting slot', 6);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'SCENARIO_RUN_NAME', 'Scenario name', 'The name of the underlying scenario', 7);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'COMPLETION_DTM', 'Completion time', 'The date and time that the dataset completed calculating', 8);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'START_DTM', 'Start date', 'The start date of the forecasting slot', 9);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'NUMBER_OF_YEARS', 'Number of years', 'The number of years covered by the forecasting slot', 10);
INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (77, 0, 'LINK_URL', 'Link to slot', 'A link to the forecasting page for the slot', 11);
DECLARE
	v_daf_id NUMBER(2);
BEGIN
	SELECT MAX(default_alert_frame_id) INTO v_daf_id FROM csr.default_alert_frame;
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (77, v_daf_id, 'inactive');
END;
/






@..\audit_pkg
@..\automated_import_pkg
@..\automated_export_import_pkg
@..\region_metric_pkg
@..\csr_data_pkg
@..\property_pkg
@@..\region_pkg
@@..\space_pkg
@..\flow_pkg
@..\campaign_pkg
@..\role_pkg
@..\chain\higg_setup_pkg
@..\enable_pkg
@..\forecasting_pkg
@..\doc_folder_pkg
@..\delegation_pkg
@..\dataview_pkg
@..\quick_survey_pkg
@..\incident_pkg
@..\stored_calc_datasource_pkg
@..\schema_pkg


@..\meter_body
@..\audit_body
@..\enable_body
@..\schema_body
@..\csrimp\imp_body
@..\delegation_body
@..\automated_import_body
@..\automated_export_import_body
@..\region_metric_body
@..\property_body
@@..\region_body
@@..\property_body
@@..\space_body
@..\flow_body
@..\campaign_body
@..\audit_helper_body
@..\role_body
@..\ssp_body
@..\chain\higg_body
@..\chain\higg_setup_body
@..\customer_body
@..\quick_survey_body
@..\deleg_plan_body
@..\capability_body
@..\forecasting_body
@..\audit_report_body
@..\supplier_body
@..\chain\company_body
@..\chain\purchased_component_body
@..\doc_folder_body
@..\dataview_body
@..\csr_app_body
@..\incident_body
@..\stored_calc_datasource_body.sql
@..\chain\supplier_flow_body
@..\csr_user_body
@..\indicator_body
@..\trash_body



@update_tail
