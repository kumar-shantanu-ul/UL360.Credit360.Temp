-- Please update version.sql too -- this keeps clean builds in sync
define version=2996
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables


create index chain.ix_bsci_associat_audit_ref on chain.bsci_associate (app_sid, audit_ref);
create index chain.ix_bsci_audit_audit_type_id on chain.bsci_audit (app_sid, audit_type_id);
create index chain.ix_bsci_audit_internal_audi on chain.bsci_audit (app_sid, internal_audit_sid);
create index chain.ix_bsci_finding_audit_type_id on chain.bsci_finding (app_sid, audit_type_id);
create index chain.ix_bsci_finding_audit_ref on chain.bsci_finding (app_sid, audit_ref);
create index chain.ix_bsci_import_batch_job_id on chain.bsci_import (app_sid, batch_job_id);
create index chain.ix_bsci_options_audit_type_20 on chain.bsci_options (app_sid, audit_type_2009_id);
create index chain.ix_bsci_options_aud_type_2009 on chain.bsci_options (app_sid, audit_type_2009_id);
create index chain.ix_bsci_options_aud_type_2014 on chain.bsci_options (app_sid, audit_type_2014_id);
create index chain.ix_bsci_supplier_rsp_id on chain.bsci_supplier (rsp_id);
create index chain.ix_bsci_supplier_company_sid on chain.bsci_supplier (app_sid, company_sid);
create index chain.ix_company_type__follower_role on chain.company_type_relationship (app_sid, follower_role_sid);
create index chain.ix_customer_grid_grid_extensio on chain.customer_grid_extension (grid_extension_id);
create index chain.ix_dedupe_mappin_reference_id on chain.dedupe_mapping (app_sid, reference_id);
create index chain.ix_dedupe_mappin_tag_group_id on chain.dedupe_mapping (app_sid, tag_group_id);
create index chain.ix_dedupe_match_matched_to_co on chain.dedupe_match (app_sid, matched_to_company_sid);
create index chain.ix_dedupe_match_dedupe_rule_i on chain.dedupe_match (app_sid, dedupe_rule_id);
create index chain.ix_dedupe_merge__dedupe_field_ on chain.dedupe_merge_log (dedupe_field_id);
create index chain.ix_dedupe_proces_dedupe_match_ on chain.dedupe_processed_record (dedupe_match_type_id);
create index chain.ix_dedupe_proces_matched_by_us on chain.dedupe_processed_record (app_sid, matched_by_user_sid);
create index chain.ix_dedupe_proces_created_compa on chain.dedupe_processed_record (app_sid, created_company_sid);
create index chain.ix_filter_export_compound_filt on chain.filter_export_batch (app_sid, compound_filter_id);
create index chain.ix_filter_export_card_group_id on chain.filter_export_batch (card_group_id);
create index chain.ix_grid_extensio_extension_car on chain.grid_extension (extension_card_group_id);
create index cms.ix_doc_template_lang on cms.doc_template (app_sid, lang);
create index cms.ix_doc_template__doc_template_ on cms.doc_template_version (app_sid, doc_template_file_id);
create index cms.ix_form_form_sid_curr on cms.form (app_sid, form_sid, current_version);
create index csr.ix_automated_imp_parent_instan on csr.automated_import_instance (app_sid, parent_instance_id);
create index csr.ix_auto_imp_core_ind_mapping_t on csr.auto_imp_core_data_settings (ind_mapping_type_id);
create index csr.ix_auto_imp_core_region_mappin on csr.auto_imp_core_data_settings (region_mapping_type_id);
create index csr.ix_auto_imp_core_unit_mapping_ on csr.auto_imp_core_data_settings (unit_mapping_type_id);
create index csr.ix_auto_imp_core_first_col_dat on csr.auto_imp_core_data_settings (first_col_date_format_id);
create index csr.ix_auto_imp_core_second_col_da on csr.auto_imp_core_data_settings (second_col_date_format_id);
create index csr.ix_auto_imp_core_date_format_t on csr.auto_imp_core_data_settings (date_format_type_id);
create index csr.ix_auto_imp_core_automated_imp on csr.auto_imp_core_data_settings (automated_import_file_type_id);
create index csr.ix_auto_imp_indi_ind_sid on csr.auto_imp_indicator_map (app_sid, ind_sid);
create index csr.ix_auto_imp_regi_region_sid on csr.auto_imp_region_map (app_sid, region_sid);
create index csr.ix_auto_imp_unit_measure_conve on csr.auto_imp_unit_map (app_sid, measure_conversion_id);
create index csr.ix_auto_imp_zip__matched_impor on csr.auto_imp_zip_filter (app_sid, matched_import_class_sid);
create index csr.ix_batch_job_requested_by_ on csr.batch_job (app_sid, requested_by_company_sid);
create index csr.ix_batch_job_bat_batch_export_ on csr.batch_job_batched_export (batch_export_type_id);
create index csr.ix_batch_job_bat_batch_import_ on csr.batch_job_batched_import (batch_import_type_id);
create index csr.ix_batch_job_log_event_type_id on csr.batch_job_log (event_type_id);
create index csr.ix_compliance_op_requirement_f on csr.compliance_options (app_sid, requirement_flow_sid);
create index csr.ix_compliance_op_regulation_fl on csr.compliance_options (app_sid, regulation_flow_sid);
create index csr.ix_compliance_op_quick_survey_ on csr.compliance_options (app_sid, quick_survey_type_id);
create index csr.ix_custom_factor_std_measure_c on csr.custom_factor (std_measure_conversion_id);
create index csr.ix_custom_factor_factor_type_i on csr.custom_factor (factor_type_id);
create index csr.ix_custom_factor_gas_type_id on csr.custom_factor (gas_type_id);
create index csr.ix_custom_factor_egrid_ref on csr.custom_factor (egrid_ref);
create index csr.ix_custom_factor_custom_factor on csr.custom_factor (app_sid, custom_factor_set_id);
create index csr.ix_custom_factor_factor_set_gr on csr.custom_factor_set (factor_set_group_id);
create index csr.ix_custom_factor_created_by_si on csr.custom_factor_set (app_sid, created_by_sid);
create index csr.ix_dataview_aggregation_p on csr.dataview (app_sid, aggregation_period_id);
create index csr.ix_delegation_gr_form_sid on csr.delegation_grid (app_sid, form_sid);
create index csr.ix_emission_fact_factor_type_i on csr.emission_factor_profile_factor (factor_type_id);
create index csr.ix_emission_fact_custom_factor on csr.emission_factor_profile_factor (app_sid, custom_factor_set_id);
create index csr.ix_emission_fact_egrid_ref on csr.emission_factor_profile_factor (egrid_ref);
create index csr.ix_emission_fact_std_factor_se on csr.emission_factor_profile_factor (std_factor_set_id);
create index csr.ix_factor_custom_factor on csr.factor (app_sid, custom_factor_id);
create index csr.ix_flow_state_flow_state_na on csr.flow_state (flow_state_nature_id);
create index csr.ix_flow_state_na_flow_alert_cl on csr.flow_state_nature (flow_alert_class);
create index csr.ix_flow_st_ro_cap_role_sid on csr.flow_state_role_capability (app_sid, role_sid);
create index csr.ix_forecasting_i_ind_sid on csr.forecasting_indicator (app_sid, ind_sid);
create index csr.ix_forecasting_r_region_sid on csr.forecasting_region (app_sid, region_sid);
create index csr.ix_forecasting_rule_region on csr.forecasting_rule (app_sid, region_sid);
create index csr.ix_forecasting_r_ind_sid on csr.forecasting_rule (app_sid, ind_sid);
create index csr.ix_forecasting_s_last_refresh_ on csr.forecasting_slot (app_sid, last_refresh_user_sid);
create index csr.ix_forecasting_s_scenario_run_ on csr.forecasting_slot (app_sid, scenario_run_sid);
create index csr.ix_forecasting_s_created_by_us on csr.forecasting_slot (app_sid, created_by_user_sid);
create index csr.ix_forecasting_s_period_set_id on csr.forecasting_slot (app_sid, period_set_id, period_interval_id);
create index csr.ix_forecasting_v_region_sid on csr.forecasting_val (app_sid, region_sid);
create index csr.ix_forecasting_v_ind_sid on csr.forecasting_val (app_sid, ind_sid);
create index csr.ix_initiative_us_initiative_si on csr.initiative_user (app_sid, initiative_sid, project_sid);
create index csr.ix_internal_audi_form_sid on csr.internal_audit_type (app_sid, form_sid);
create index csr.ix_meter_raw_dat_automated_imp on csr.meter_raw_data_source (app_sid, automated_import_class_sid);
create index csr.ix_non_comp_t_rpt_aud_typ on csr.non_comp_type_rpt_audit_type (app_sid, internal_audit_type_id);
create index csr.ix_plugin_form_sid on csr.plugin (app_sid, form_sid);
create index csr.ix_std_factor_se_factor_set_gr on csr.std_factor_set (factor_set_group_id);
create index csr.ix_std_factor_se_std_factor_se on csr.std_factor_set_active (std_factor_set_id);
create index csr.ix_tpl_report_sc_scenario_run_ on csr.tpl_report_schedule (app_sid, scenario_run_sid);
create index csr.ix_urjanet_servi_raw_data_sour on csr.urjanet_service_type (app_sid, raw_data_source_id);
create index csr.ix_user_course_course_id on csr.user_course (app_sid, course_id);
create index csr.ix_user_course_user_sid_cour on csr.user_course (app_sid, user_sid, course_schedule_id, course_id);
create index csr.ix_user_course_l_user_sid_cour on csr.user_course_log (app_sid, user_sid, course_id);
create index csr.ix_user_train_course_schedule on csr.user_training (app_sid, course_schedule_id, course_id);
create index csr.ix_util_script_r_client_util_s on csr.util_script_run_log (app_sid, client_util_script_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_pkg
@../chain/filter_body

@update_tail
