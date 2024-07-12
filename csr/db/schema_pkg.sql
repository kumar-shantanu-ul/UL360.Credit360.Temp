CREATE OR REPLACE PACKAGE CSR.schema_Pkg AS

PROCEDURE InitExport(
	in_export_everything			IN	NUMBER
);

PROCEDURE GetSuperAdmins(
	out_cur							OUT	SYS_REFCURSOR,
	out_folders_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetSecuritySchema(
	out_soc_cur						OUT SYS_REFCURSOR,
	out_att_cur						OUT SYS_REFCURSOR,
	out_pm_cur						OUT SYS_REFCURSOR,
	out_pn_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetSecurableObjects(
	out_so_cur						OUT SYS_REFCURSOR,
	out_soa_cur						OUT SYS_REFCURSOR,
	out_soka_cur					OUT SYS_REFCURSOR,
	out_acl_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetSecurityAccountPolicies(
	out_pol_cur						OUT SYS_REFCURSOR,
	out_pol_pwdre_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetSecurityGroups(
	out_group_cur					OUT	SYS_REFCURSOR,
	out_group_member_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetSecurityUsers(
	out_user_cur					OUT	SYS_REFCURSOR,
	out_user_pass_hist_cur			OUT	SYS_REFCURSOR,
	out_user_cert_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetSecurityWebInfo(
	out_app_cur						OUT SYS_REFCURSOR,
	out_website_cur					OUT	SYS_REFCURSOR,
	out_web_resource_cur			OUT	SYS_REFCURSOR,
	out_ip_rule_cur					OUT	SYS_REFCURSOR,
	out_ip_rule_entry_cur			OUT	SYS_REFCURSOR,
	out_home_page_cur				OUT SYS_REFCURSOR,
	out_menu_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetKnownSOs(
	out_so_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetMailAccounts(
	out_account_cur					OUT	SYS_REFCURSOR,
	out_mailbox_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetMailMessages(
	out_mailbox_message_cur			OUT	SYS_REFCURSOR,
	out_message_cur					OUT	SYS_REFCURSOR,
	out_message_header_cur			OUT	SYS_REFCURSOR,
	out_message_address_field_cur	OUT	SYS_REFCURSOR,
	out_alert_cur					OUT	SYS_REFCURSOR,
	out_alert_bounce_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetCustomerFields(
	out_aspen2_app_cur				OUT	SYS_REFCURSOR,
    out_customer_cur				OUT	SYS_REFCURSOR,
    out_template_cur				OUT	SYS_REFCURSOR,
    out_trash_cur					OUT	SYS_REFCURSOR,
	out_customer_help_lang_cur		OUT SYS_REFCURSOR,
	out_scragpp_audit_log_cur		OUT SYS_REFCURSOR,
	out_scragpp_status_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetPeriodSets(
	out_period_set_cur				OUT	SYS_REFCURSOR,
	out_period_cur					OUT	SYS_REFCURSOR,
	out_period_dates_cur			OUT	SYS_REFCURSOR,
	out_period_interval_cur			OUT	SYS_REFCURSOR,
	out_period_interval_mem_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetLookupTables(
	out_lookup_table_cur			OUT SYS_REFCURSOR,
	out_lookup_table_entry_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetReportingPeriods(
    out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetRagStatuses(
    out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetAccuracyTypes(
    out_accuracy_type_cur			OUT	SYS_REFCURSOR,
    out_accuracy_type_opt_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetTranslations(
	out_app_cur						OUT	SYS_REFCURSOR,
	out_set_cur						OUT	SYS_REFCURSOR,
	out_set_incl_cur				OUT	SYS_REFCURSOR,
	out_translation_cur				OUT	SYS_REFCURSOR,
	out_translated_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetCustomerAlertTypes(
	out_cat_cur						OUT	SYS_REFCURSOR,
	out_cat_param_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAlerts(
	out_alert_frame_cur				OUT	SYS_REFCURSOR,
	out_alert_frame_body_cur		OUT	SYS_REFCURSOR,
	out_alert_tpl_cur				OUT	SYS_REFCURSOR,
	out_alert_tpl_body_cur			OUT	SYS_REFCURSOR,
	out_cms_tab_alert_type_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRoles(
	out_cur							OUT	SYS_REFCURSOR,
	out_grants						OUT	SYS_REFCURSOR
);

PROCEDURE GetTags(
	out_tag_cur						OUT	SYS_REFCURSOR,
	out_tag_description_cur			OUT	SYS_REFCURSOR,
	out_tag_group_cur				OUT	SYS_REFCURSOR,
	out_tag_group_description_cur	OUT	SYS_REFCURSOR,
	out_tag_group_member_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetMeasures(
	out_measure_cur					OUT	SYS_REFCURSOR,
	out_measure_conv_cur			OUT	SYS_REFCURSOR,
	out_measure_conv_period_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIndicators(
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_ind_description_cur			OUT	SYS_REFCURSOR,
	out_ind_flag_cur				OUT	SYS_REFCURSOR,
	out_calc_dependency_cur			OUT	SYS_REFCURSOR,
	out_ind_tag_cur					OUT	SYS_REFCURSOR,
	out_ind_accuracy_cur			OUT	SYS_REFCURSOR,
	out_validation_rule_cur			OUT	SYS_REFCURSOR,
	out_calc_tag_dep_cur			OUT	SYS_REFCURSOR,
	out_aggr_ind_group_cur			OUT	SYS_REFCURSOR,
	out_aggr_ind_group_member_cur	OUT	SYS_REFCURSOR,
	out_aggr_ind_group_log_cur		OUT	SYS_REFCURSOR,
	out_aivd_cur					OUT SYS_REFCURSOR,
	out_ind_window_cur				OUT SYS_REFCURSOR,
	out_calc_baseline_dep_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIndSelections(
	out_ind_sel_group_cur			OUT	SYS_REFCURSOR,
	out_ind_sel_group_mem_cur		OUT	SYS_REFCURSOR,
	out_ind_sel_grp_mem_dsc_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetFactors(
	out_factor_cur					OUT	SYS_REFCURSOR,
	out_factor_history_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetModels(
	out_model_cur					OUT	SYS_REFCURSOR,
	out_model_instance_cur			OUT	SYS_REFCURSOR,
	out_model_instance_chart_cur	OUT	SYS_REFCURSOR,
	out_model_instance_map_cur		OUT	SYS_REFCURSOR,
	out_model_instance_region_cur	OUT	SYS_REFCURSOR,
	out_model_instance_sheet_cur	OUT	SYS_REFCURSOR,
	out_model_map_cur				OUT	SYS_REFCURSOR,
	out_model_range_cur				OUT	SYS_REFCURSOR,
	out_model_range_cell_cur		OUT	SYS_REFCURSOR,
	out_region_range_cur			OUT	SYS_REFCURSOR,
	out_model_sheet_cur				OUT	SYS_REFCURSOR,
	out_model_validation_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegions(
	out_region_tree_cur				OUT	SYS_REFCURSOR,
	out_region_type_cur				OUT	SYS_REFCURSOR,
	out_region_type_tag_cur			OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_description_cur		OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR,
	out_pct_ownership_cur			OUT	SYS_REFCURSOR,
	out_region_owner_cur			OUT	SYS_REFCURSOR,
	out_mgt_tree_sync_job_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetRegionEventsAndDocs(
	out_event_cur					OUT	SYS_REFCURSOR,
	out_region_event_cur			OUT	SYS_REFCURSOR,
	out_region_proc_doc_cur			OUT	SYS_REFCURSOR,
	out_region_proc_file_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionSets(
	out_region_set_cur				OUT	SYS_REFCURSOR,
	out_region_set_region_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetIndSets(
	out_ind_set_cur					OUT SYS_REFCURSOR,
	out_ind_set_ind_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetUsers(
	out_csr_user_cur				OUT	SYS_REFCURSOR,
	out_user_measure_conv_cur		OUT	SYS_REFCURSOR,
	out_autocreate_user_cur			OUT	SYS_REFCURSOR,
	out_cookie_pol_consent_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetStartPoints(
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetRegionRoleMembers(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPending(
	out_dataset_cur					OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_period_cur					OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_ind_accuracy_type_cur		OUT	SYS_REFCURSOR
);


PROCEDURE PickAllDelegations;

PROCEDURE PickPlanDelegations;

PROCEDURE GetPostits(
	out_postit_cur					OUT	SYS_REFCURSOR,
	out_postit_file_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetDelegations(
	out_deleg_cur					OUT	SYS_REFCURSOR,
	out_deleg_desc_cur				OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_ind_desc_cur				OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_desc_cur				OUT	SYS_REFCURSOR,
	out_user_cur					OUT	SYS_REFCURSOR,
	out_deleg_plugin_cur			OUT	SYS_REFCURSOR, 
	out_deleg_meta_role_is_cur		OUT	SYS_REFCURSOR,
	out_deleg_comment_cur			OUT	SYS_REFCURSOR,
	out_deleg_tag_cur				OUT	SYS_REFCURSOR,
	out_user_cover_cur				OUT	SYS_REFCURSOR,
	out_deleg_user_cover_cur		OUT	SYS_REFCURSOR,
	out_audit_user_cover_cur		OUT	SYS_REFCURSOR,
	out_issue_user_cover_cur		OUT	SYS_REFCURSOR,
	out_role_user_cover_cur			OUT	SYS_REFCURSOR,
	out_group_user_cover_cur		OUT	SYS_REFCURSOR,
	out_flow_inv_cover_cur			OUT	SYS_REFCURSOR,
	out_deleg_date_schedule_cur		OUT	SYS_REFCURSOR,
	out_sheet_date_schedule_cur		OUT SYS_REFCURSOR,
	out_delegation_layout_cur		OUT SYS_REFCURSOR,
    out_delegation_policy_cur       OUT SYS_REFCURSOR
);

PROCEDURE GetDelegationOther(
	out_role_cur					OUT	SYS_REFCURSOR,
	out_grid_cur					OUT	SYS_REFCURSOR,
	out_deleg_grid_var_cur			OUT SYS_REFCURSOR,
	out_ind_tag_cur					OUT	SYS_REFCURSOR,
	out_ind_tag_list_cur			OUT	SYS_REFCURSOR,
	out_ind_cond_cur				OUT	SYS_REFCURSOR,
	out_ind_cond_action_cur			OUT	SYS_REFCURSOR,
	out_form_expr					OUT SYS_REFCURSOR,
	out_deleg_ind_form_expr			OUT SYS_REFCURSOR,
	out_deleg_ind_group				OUT SYS_REFCURSOR,
	out_deleg_ind_group_member		OUT SYS_REFCURSOR,
	out_var_expl_groups				OUT	SYS_REFCURSOR,
	out_var_expl					OUT	SYS_REFCURSOR,	
	out_dlg_pln_survey_reg_cur		OUT SYS_REFCURSOR,
	out_campaign_region_response	OUT SYS_REFCURSOR
);

PROCEDURE GetDelegationPlans(
	out_role						OUT	SYS_REFCURSOR,
	out_region						OUT	SYS_REFCURSOR,
	out_plan						OUT	SYS_REFCURSOR,
	out_col							OUT	SYS_REFCURSOR,
	out_col_deleg					OUT	SYS_REFCURSOR,
	out_deleg_region				OUT	SYS_REFCURSOR,
	out_deleg_region_deleg			OUT	SYS_REFCURSOR,
	out_master_deleg				OUT	SYS_REFCURSOR,
	out_date_schedule				OUT	SYS_REFCURSOR
);

PROCEDURE GetSheets(
	out_sheet_cur					OUT	SYS_REFCURSOR,
	out_sheet_history_cur			OUT	SYS_REFCURSOR,
	out_sheet_alert_cur				OUT SYS_REFCURSOR,
	out_sheet_value_cur				OUT SYS_REFCURSOR,
	out_sheet_inherited_value_cur	OUT SYS_REFCURSOR,
	out_sheet_value_accuracy_cur	OUT	SYS_REFCURSOR,
	out_sheet_value_var_expl_cur	OUT	SYS_REFCURSOR,
	out_sheet_value_file_cur		OUT	SYS_REFCURSOR,
	out_sheet_value_hidden_cac_cur	OUT SYS_REFCURSOR,
	out_sheet_change_req_cur		OUT SYS_REFCURSOR,
	out_sheet_change_req_alert_cur	OUT SYS_REFCURSOR,
	out_sheet_value_change_fil_cur	OUT SYS_REFCURSOR,
	out_svfhc_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetSheetValueChanges(
	out_sheet_value_change_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetForms(
	out_form_cur					OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_allocation_cur				OUT	SYS_REFCURSOR,
	out_allocation_user_cur			OUT	SYS_REFCURSOR,
	out_allocation_item_cur			OUT	SYS_REFCURSOR,
	out_comment_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetDataviews(
	out_dv_cur						OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_ind_description_cur			OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_description_cur		OUT	SYS_REFCURSOR,
	out_excel_export_opts_cur		OUT	SYS_REFCURSOR,
	out_dataview_scenario_run_cur	OUT	SYS_REFCURSOR,
	out_dataview_zone_cur			OUT	SYS_REFCURSOR,
	out_dataview_trend_cur			OUT	SYS_REFCURSOR,
    out_dataview_history_cur        OUT SYS_REFCURSOR,
    out_dataview_arb_per_cur        OUT SYS_REFCURSOR,
    out_dataview_arb_per_hist_cur   OUT SYS_REFCURSOR
);

PROCEDURE GetImgCharts(
	out_chart						OUT	SYS_REFCURSOR,
	out_ind							OUT	SYS_REFCURSOR,
	out_img_chart_region_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetTemplatedReports(
	out_tpl_img_cur					OUT	SYS_REFCURSOR,
	out_tpl_rep_cust_tt_cur			OUT	SYS_REFCURSOR,
	out_tpl_report_cur				OUT	SYS_REFCURSOR,
	out_tpl_report_tag_dv_cur		OUT	SYS_REFCURSOR,
	out_rep_tag_dv_reg_cur			OUT	SYS_REFCURSOR,
	old_tpl_rep_tag_eval_cur		OUT	SYS_REFCURSOR,
	out_tpl_rep_tag_eval_cond_cur	OUT	SYS_REFCURSOR,
	out_tpl_rep_tag_ind_cur			OUT	SYS_REFCURSOR,
	out_tpl_rep_tag_log_frm_cur		OUT	SYS_REFCURSOR,
	out_tpl_rep_tag_text_cur		OUT	SYS_REFCURSOR,
	out_tpl_rep_non_compl_cur		OUT	SYS_REFCURSOR,
	out_tpl_rep_tag_cur				OUT	SYS_REFCURSOR,
	out_tpl_rep_tag_appr_nt_cur		OUT	SYS_REFCURSOR,
	out_tpl_rep_tag_appr_mx_cur		OUT	SYS_REFCURSOR,
	out_tpl_rep_tag_reg_data_cur	OUT	SYS_REFCURSOR,
	out_tpl_rep_tag_qc_cur			OUT	SYS_REFCURSOR,
	out_tpl_rep_variant_cur			OUT	SYS_REFCURSOR,
	out_tpl_rep_variant_tag_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetTargetDashboards(
	out_target_dash_cur				OUT	SYS_REFCURSOR,
	out_tgt_dash_ind_member_cur		OUT	SYS_REFCURSOR,
	out_tgt_dash_reg_member_cur		OUT	SYS_REFCURSOR,
	out_tgt_dash_val_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetMetricDashboards(
	out_metric_dash_cur				OUT	SYS_REFCURSOR,
	out_metric_dash_ind_cur			OUT	SYS_REFCURSOR,
	out_metric_dash_plugin_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetBenchmarkingDashboards(
	out_benchmark_dash_cur			OUT	SYS_REFCURSOR,
	out_benchmark_dash_ind_cur		OUT	SYS_REFCURSOR,
	out_benchmark_dash_plugin_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetApprovalDashboards(
	out_approval_dashboard_cur			OUT	SYS_REFCURSOR,	
	out_appr_dash_alert_type_cur		OUT	SYS_REFCURSOR,
	out_appr_dash_inst_cur				OUT	SYS_REFCURSOR,
	out_appr_dash_region_cur			OUT	SYS_REFCURSOR,
	out_appr_dash_tab_cur				OUT	SYS_REFCURSOR,
	out_appr_dash_tpl_tag_cur			OUT	SYS_REFCURSOR,
	out_appr_dash_val_cur				OUT SYS_REFCURSOR,
	out_appr_dash_ind_cur				OUT SYS_REFCURSOR,
	out_appr_dash_val_src_cur			OUT SYS_REFCURSOR,
	out_appr_dash_batch_job_cur			OUT SYS_REFCURSOR,
	out_appr_note_portlet_note_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetDashboards(
	out_dashboard_cur				OUT	SYS_REFCURSOR,
	out_dashboard_item_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetVals(
	in_include_calc_values			IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetValChanges(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetValMetadata(
	out_val_file_cur OUT SYS_REFCURSOR,
	out_val_note_cur OUT SYS_REFCURSOR
);

PROCEDURE GetSections(
	out_section_status_cur			OUT	SYS_REFCURSOR,
	out_section_module_cur			OUT	SYS_REFCURSOR,
	out_section_cur					OUT	SYS_REFCURSOR,
	out_section_version_cur			OUT	SYS_REFCURSOR,
	out_attachment_cur				OUT	SYS_REFCURSOR,
	out_attachment_history_cur		OUT	SYS_REFCURSOR,
	out_section_comment_cur			OUT	SYS_REFCURSOR,
	out_section_trans_comment_cur 	OUT	SYS_REFCURSOR,
	out_route_cur					OUT	SYS_REFCURSOR,
	out_route_step_cur				OUT	SYS_REFCURSOR,
	out_route_step_user_cur			OUT	SYS_REFCURSOR,
	out_section_cart_folder_cur		OUT	SYS_REFCURSOR,
	out_section_cart_cur			OUT	SYS_REFCURSOR,
	out_section_cart_member_cur		OUT	SYS_REFCURSOR,
	out_section_route_fs_cur		OUT	SYS_REFCURSOR,
	out_section_flow_cur			OUT	SYS_REFCURSOR,
	out_section_tag_cur				OUT	SYS_REFCURSOR,
	out_section_tag_member_cur		OUT	SYS_REFCURSOR,
	out_section_alert 				OUT	SYS_REFCURSOR,
	out_section_transition_cur		OUT SYS_REFCURSOR,
	out_route_log_cur				OUT SYS_REFCURSOR,
	out_route_step_vote_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetFileUploads(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetImports(
	out_imp_session_cur				OUT	SYS_REFCURSOR,
	out_imp_ind_cur					OUT	SYS_REFCURSOR,
	out_imp_region_cur				OUT	SYS_REFCURSOR,
	out_imp_measure_cur				OUT	SYS_REFCURSOR,
	out_imp_val_cur					OUT	SYS_REFCURSOR,
	out_imp_conflict_cur			OUT	SYS_REFCURSOR,
	out_imp_conflict_val_cur		OUT	SYS_REFCURSOR,
	out_imp_vocab_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowCmsAlertData(
	out_alert_type_cur				OUT	SYS_REFCURSOR,
	out_alert_helper_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetFlowData(
	out_flow_cur					OUT	SYS_REFCURSOR,
	out_flow_item_cur				OUT	SYS_REFCURSOR,
	out_flow_item_region_cur		OUT	SYS_REFCURSOR,
	out_flow_state_cur				OUT	SYS_REFCURSOR,
	out_flow_state_log_cur			OUT	SYS_REFCURSOR,
	out_flow_state_log_file_cur		OUT	SYS_REFCURSOR,
	out_flow_state_role_cur			OUT	SYS_REFCURSOR,
	out_flow_state_cms_col_cur		OUT	SYS_REFCURSOR,
	out_flow_state_inv_cur			OUT	SYS_REFCURSOR,
	out_flow_state_inv_cap_cur		OUT	SYS_REFCURSOR,
	out_flow_state_trans_cur		OUT	SYS_REFCURSOR,
	out_flow_state_trans_role_cur	OUT	SYS_REFCURSOR,
	out_flow_state_trans_col_cur	OUT	SYS_REFCURSOR,
	out_flow_state_trans_inv_cur	OUT	SYS_REFCURSOR,
	out_flow_state_trans_help_cur	OUT	SYS_REFCURSOR,
	out_flow_alert_type_cur			OUT	SYS_REFCURSOR,
	out_flow_alert_helper_cur		OUT	SYS_REFCURSOR,
	out_flow_item_gen_alert_cur		OUT	SYS_REFCURSOR,
	out_flow_trans_alert_cur		OUT	SYS_REFCURSOR,
	out_flow_trans_alert_role_cur	OUT	SYS_REFCURSOR,
	out_flow_trans_alrt_cc_rl_cur	OUT	SYS_REFCURSOR,
	out_flow_trans_alert_user_cur	OUT SYS_REFCURSOR,
	out_flow_trans_alrt_cc_usr_cur	OUT SYS_REFCURSOR,
	out_flow_trns_alrt_cms_usr_cur	OUT SYS_REFCURSOR,
	out_flow_trans_alert_inv_cur	OUT SYS_REFCURSOR,
	out_flow_cust_alert_class_cur	OUT SYS_REFCURSOR,
	out_flow_involvement_type_cur	OUT	SYS_REFCURSOR,
	out_flow_item_involvement_cur	OUT	SYS_REFCURSOR,
	out_cust_flow_capability_cur	OUT SYS_REFCURSOR,
	out_flow_state_group_cur		OUT SYS_REFCURSOR,
	out_flow_state_group_membr_cur	OUT SYS_REFCURSOR,
	out_flow_inv_type_alt_cls_cur	OUT	SYS_REFCURSOR,
	out_flow_state_survey_tag_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetMeterData(
	out_meter_source_type_cur		OUT	SYS_REFCURSOR,
	out_all_meter_cur				OUT	SYS_REFCURSOR,
	out_meter_document_cur			OUT	SYS_REFCURSOR,
	out_meter_type_cur				OUT SYS_REFCURSOR,
	out_utility_supplier_cur		OUT	SYS_REFCURSOR,
	out_utility_contract_cur		OUT	SYS_REFCURSOR,
	out_utility_invoice_cur			OUT	SYS_REFCURSOR,
	out_meter_reading_cur			OUT	SYS_REFCURSOR,
	out_meter_util_contract_cur		OUT	SYS_REFCURSOR,
	---
	out_meter_input_cur				OUT SYS_REFCURSOR,
	out_meter_data_priority_cur		OUT SYS_REFCURSOR,
	out_meter_input_aggregator_cur	OUT SYS_REFCURSOR,
	out_meter_input_aggr_ind_cur	OUT SYS_REFCURSOR,
	out_meter_patch_data_cur		OUT SYS_REFCURSOR,
	out_meter_patch_job_cur			OUT SYS_REFCURSOR,
	out_meter_patch_batch_job_cur	OUT SYS_REFCURSOR,
	out_meter_patch_batch_data_cur	OUT SYS_REFCURSOR,
	out_meter_data_covg_ind_cur		OUT SYS_REFCURSOR,
	out_meter_aggregate_type_cur	OUT SYS_REFCURSOR,
	out_metering_options_cur		OUT SYS_REFCURSOR,
	out_meter_element_layout_cur	OUT SYS_REFCURSOR,
	out_meter_type_input_cur		OUT SYS_REFCURSOR,
	out_meter_tab_cur				OUT SYS_REFCURSOR,
	out_meter_tab_group_cur			OUT SYS_REFCURSOR,
	out_meter_header_element_cur	OUT SYS_REFCURSOR,
	out_meter_photo_cur				OUT SYS_REFCURSOR,
	out_meter_data_src_hi_inp_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetMeterAlarmData(
	out_meter_alarm_statistic_cur	OUT	SYS_REFCURSOR,
	out_meter_alarm_compar_cur		OUT	SYS_REFCURSOR,
	out_meter_alrm_iss_period_cur	OUT	SYS_REFCURSOR,
	out_meter_alarm_test_time_cur	OUT	SYS_REFCURSOR,
	out_meter_alarm_cur				OUT	SYS_REFCURSOR,
	out_meter_alarm_event_cur		OUT	SYS_REFCURSOR,
	out_meter_alarm_stat_run_cur	OUT	SYS_REFCURSOR,
	out_meter_alarm_stat_job_cur	OUT	SYS_REFCURSOR,
	out_meter_alarm_stat_period		OUT	SYS_REFCURSOR,
	out_meter_meter_alrm_stat_cur	OUT	SYS_REFCURSOR,
	out_region_meter_alarm_cur		OUT	SYS_REFCURSOR,
	out_core_working_hours_cur		OUT	SYS_REFCURSOR,
	out_core_working_hours_day_cur	OUT	SYS_REFCURSOR,
	out_core_working_hours_rgn_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetRealtimeMeterData(
	out_meter_raw_data_source_cur	OUT	SYS_REFCURSOR,
	out_meter_xml_option			OUT	SYS_REFCURSOR,
	out_meter_excel_mapping_cur		OUT	SYS_REFCURSOR,
	out_meter_excel_option_cur		OUT	SYS_REFCURSOR,
	out_meter_list_cache_cur		OUT	SYS_REFCURSOR,
	out_meter_bucket_cur			OUT	SYS_REFCURSOR,
	out_meter_raw_data_cur			OUT	SYS_REFCURSOR,
	out_meter_live_data_cur			OUT	SYS_REFCURSOR,
	out_meter_orphan_data_cur		OUT	SYS_REFCURSOR,
	out_meter_raw_data_error_cur	OUT	SYS_REFCURSOR,
	out_meter_source_data_cur		OUT	SYS_REFCURSOR,
	out_meter_reading_data_cur		OUT	SYS_REFCURSOR,
	out_meter_raw_data_log_cur		OUT SYS_REFCURSOR,
	out_duff_meter_region_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetIncidentTypes(
	out_incident_types				OUT SYS_REFCURSOR
);

PROCEDURE GetIssues(
	out_correspondent_cur			OUT	SYS_REFCURSOR,
	out_issue_pending_val_cur		OUT	SYS_REFCURSOR,
	out_issue_sheet_value_cur		OUT	SYS_REFCURSOR,
	out_issue_priority_cur			OUT	SYS_REFCURSOR,
	out_issue_type_cur				OUT	SYS_REFCURSOR,
	out_issue_type_agg_ind_grp		OUT SYS_REFCURSOR,
	out_issue_type_rag_status		OUT SYS_REFCURSOR,
	out_issue_cur					OUT	SYS_REFCURSOR,
	out_issue_user_cur				OUT	SYS_REFCURSOR,
	out_issue_scheduled_task_cur	OUT	SYS_REFCURSOR,
	out_issue_survey_ans_cur		OUT	SYS_REFCURSOR,
	out_issue_nc_cur				OUT	SYS_REFCURSOR,
	out_issue_action_cur			OUT	SYS_REFCURSOR,
	out_issue_alert_cur				OUT SYS_REFCURSOR,
	out_issue_cmp_reg_cur			OUT SYS_REFCURSOR,
	out_issue_due_source			OUT SYS_REFCURSOR,
	out_issue_template_cur			OUT SYS_REFCURSOR,
	out_itcf_cur					OUT SYS_REFCURSOR,
	out_itcfo_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetMeterIssues(
	out_issue_meter_cur				OUT	SYS_REFCURSOR,
	out_issue_meter_alarm_cur		OUT	SYS_REFCURSOR,
	out_issue_meter_data_src_cur	OUT	SYS_REFCURSOR,
	out_issue_meter_raw_data_cur	OUT	SYS_REFCURSOR,
	out_immd_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetIssueLogs(
	out_issue_action_log_cur		OUT	SYS_REFCURSOR,
	out_issue_log_cur				OUT	SYS_REFCURSOR,
	out_issue_log_file_cur			OUT	SYS_REFCURSOR,
	out_issue_log_read_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueLogsFiltered(
	in_issue_log_file_filter		IN	NUMBER,
	in_issue_log_file_data			IN  NUMBER,
	out_issue_action_log_cur		OUT	SYS_REFCURSOR,
	out_issue_log_cur				OUT	SYS_REFCURSOR,
	out_issue_log_file_cur			OUT	SYS_REFCURSOR,
	out_issue_log_read_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetIssueCustomFields(
	out_custom_field_id_cur			OUT	SYS_REFCURSOR,
	out_issue_custom_fld_opt_cur	OUT	SYS_REFCURSOR,
	out_iss_cust_fld_opt_sel_cur	OUT	SYS_REFCURSOR,
	out_iss_cust_fld_str_val_cur	OUT	SYS_REFCURSOR,
	out_iss_cust_fld_date_val_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetPortlets(
	out_customer_portlet_cur		OUT	SYS_REFCURSOR,
	out_tab_cur						OUT	SYS_REFCURSOR,
	out_tab_group_cur				OUT	SYS_REFCURSOR,
	out_tab_portlet_cur				OUT	SYS_REFCURSOR,
	out_rss_cache_cur				OUT	SYS_REFCURSOR,
	out_tab_portlet_rss_feed_cur	OUT	SYS_REFCURSOR,
	out_tab_portlet_user_reg_cur	OUT	SYS_REFCURSOR,
	out_tab_user_cur				OUT	SYS_REFCURSOR,
	out_user_setting_cur			OUT	SYS_REFCURSOR,
	out_user_setting_entry_cur		OUT SYS_REFCURSOR,
	out_hide_portlet_cur			OUT SYS_REFCURSOR,
	out_image_upload_portlet_cur 	OUT SYS_REFCURSOR,
	out_tab_description_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetPortalDashboards(
	out_dashboard_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetScenarios(
	out_scenario_cur				OUT	SYS_REFCURSOR,
	out_scenario_ind_cur			OUT	SYS_REFCURSOR,
	out_scenario_region_cur			OUT	SYS_REFCURSOR,
	out_scn_opt_cur					OUT	SYS_REFCURSOR,
	out_scn_sub_cur					OUT	SYS_REFCURSOR,
	out_scn_rule_cur				OUT	SYS_REFCURSOR,
	out_scn_rule_ind_cur			OUT	SYS_REFCURSOR,
	out_scn_rle_like_cntg_ind_cur	OUT	SYS_REFCURSOR,
	out_scn_forecast_rule_cur		OUT	SYS_REFCURSOR,
	out_scn_rule_region_cur			OUT	SYS_REFCURSOR,
	out_scn_run_vers_cur			OUT SYS_REFCURSOR,
	out_scn_run_vers_file_cur		OUT SYS_REFCURSOR,
	out_scn_run_cur					OUT	SYS_REFCURSOR,
	out_scn_run_val_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetDoclib(
	out_doc_cur						OUT	SYS_REFCURSOR,
	out_doc_data_cur				OUT	SYS_REFCURSOR,
	out_doc_version_cur				OUT	SYS_REFCURSOR,
	out_doc_current_cur				OUT	SYS_REFCURSOR,
	out_doc_download_cur			OUT	SYS_REFCURSOR,
	out_doc_folder_cur				OUT	SYS_REFCURSOR,
	out_doc_folder_sub_cur			OUT	SYS_REFCURSOR,
	out_doc_library_cur				OUT	SYS_REFCURSOR,
	out_doc_notification_cur		OUT	SYS_REFCURSOR,
	out_doc_subscription_cur		OUT	SYS_REFCURSOR,
	out_doc_types_cur				OUT	SYS_REFCURSOR,
	out_doc_folder_name_tr_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetQuestionLibrary(
	out_question_cur						OUT	SYS_REFCURSOR,
	out_quest_ver_cur						OUT	SYS_REFCURSOR,
	out_quest_opt_cur						OUT	SYS_REFCURSOR,
	out_q_opt_nc_t_cur						OUT	SYS_REFCURSOR,
	out_quest_tag_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetQuickSurvey(
	out_qs_cur						OUT	SYS_REFCURSOR,
	out_qs_ver_cur					OUT	SYS_REFCURSOR,
	out_qs_campaign_cur				OUT	SYS_REFCURSOR,
	out_qs_type_cur					OUT	SYS_REFCURSOR,
	out_qs_filter_cond_gen_cur		OUT	SYS_REFCURSOR,
	out_qs_lang_cur					OUT	SYS_REFCURSOR,
	out_qs_cust_quest_cur			OUT	SYS_REFCURSOR,
	out_qs_question_cur				OUT	SYS_REFCURSOR,
	out_qs_question_opt_cur			OUT	SYS_REFCURSOR,
	out_qs_question_opt_tag_cur		OUT	SYS_REFCURSOR,
	out_qs_question_tag_cur			OUT	SYS_REFCURSOR,
	out_qs_css_cur					OUT	SYS_REFCURSOR,
	out_score_type_cur				OUT	SYS_REFCURSOR,
	out_score_threshold_cur			OUT	SYS_REFCURSOR,
	out_qs_score_threshold_cur		OUT	SYS_REFCURSOR,
	out_score_type_agg_type_cur		OUT	SYS_REFCURSOR,
	out_score_type_audit_type_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetQuickSurveyResponse(
	out_qs_response_cur				OUT	SYS_REFCURSOR,
	out_qs_resp_postit_cur			OUT	SYS_REFCURSOR,
	out_qs_submission_cur			OUT	SYS_REFCURSOR,
	out_qs_answer_cur				OUT	SYS_REFCURSOR,
	out_qs_response_file_cur		OUT	SYS_REFCURSOR,
	out_qs_answer_file_cur			OUT	SYS_REFCURSOR,
	out_qs_submission_file_cur		OUT	SYS_REFCURSOR,
	out_qs_answer_log_cur			OUT	SYS_REFCURSOR,
	out_reg_survey_resp_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetQuickSurveyExpr(
	out_qs_expr_cur					OUT	SYS_REFCURSOR,
	out_qs_expr_msg_action_cur		OUT	SYS_REFCURSOR,
	out_qs_expr_nc_action_cur		OUT	SYS_REFCURSOR,
	out_qs_expr_action_cur			OUT	SYS_REFCURSOR, 
	out_qs_filter_condition_cur		OUT	SYS_REFCURSOR,
	out_qs_expr_nc_act_role_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetNonCompliances(
	out_nc_cur						OUT	SYS_REFCURSOR,
	out_nc_ea_cur					OUT	SYS_REFCURSOR,
	out_nc_file_upload_cur			OUT	SYS_REFCURSOR,
	out_nc_tag_cur					OUT	SYS_REFCURSOR,
	out_aud_nc_cur					OUT	SYS_REFCURSOR,
	out_nc_type_cur					OUT	SYS_REFCURSOR,
	out_nc_type_tag_group_cur		OUT	SYS_REFCURSOR,
	out_nc_type_audit_type_cur		OUT	SYS_REFCURSOR,
	out_nc_type_rpt_audit_type_cur	OUT	SYS_REFCURSOR,
	out_nc_type_flow_cap			OUT SYS_REFCURSOR
);

PROCEDURE GetNonComplianceDefaults(
	non_comp_default_cur			OUT SYS_REFCURSOR,
	non_comp_default_issue_cur		OUT SYS_REFCURSOR,
	audit_type_non_comp_def_cur		OUT SYS_REFCURSOR,
	non_comp_def_folder_cur			OUT SYS_REFCURSOR,
	non_comp_def_tag_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetInternalAudit(
	out_internal_audit_type_cur		OUT SYS_REFCURSOR,
	out_ia_type_carry_fwd_cur		OUT SYS_REFCURSOR,
	out_ia_type_tag_group_cur		OUT SYS_REFCURSOR,
	out_audit_closure_type_cur		OUT SYS_REFCURSOR,
	out_audit_type_cl_type_cur		OUT SYS_REFCURSOR,
	out_ia_cur						OUT SYS_REFCURSOR,
	out_ia_tag_cur					OUT SYS_REFCURSOR,
	out_ia_postit_cur				OUT SYS_REFCURSOR,
	out_region_ia_cur				OUT SYS_REFCURSOR,
	out_audit_alert_cur				OUT SYS_REFCURSOR,
	out_int_audit_file_data_cur		OUT SYS_REFCURSOR,
	out_audit_type_alert_role_cur	OUT SYS_REFCURSOR,
	out_audit_type_tab_cur			OUT SYS_REFCURSOR,
	out_audit_type_header_cur		OUT SYS_REFCURSOR,
	out_internal_audit_file_cur		OUT SYS_REFCURSOR,
	out_audit_type_group_cur		OUT SYS_REFCURSOR,
	out_flow_state_audit_ind_cur	OUT SYS_REFCURSOR,
	out_adt_tp_flow_inv_tp_cur		OUT SYS_REFCURSOR,
	out_ia_type_survey_group_cur	OUT SYS_REFCURSOR,
	out_ia_type_survey_cur			OUT SYS_REFCURSOR,
	out_internal_audit_survey_cur	OUT SYS_REFCURSOR,
	out_internal_audit_type_re_cur  OUT SYS_REFCURSOR,
	out_ia_type_report_group_cur 	OUT SYS_REFCURSOR,
	out_internal_audit_score_cur	OUT SYS_REFCURSOR,
	out_ia_locked_tag_cur			OUT SYS_REFCURSOR,
	out_ia_listener_last_update		OUT SYS_REFCURSOR
);

PROCEDURE GetRegionMetrics(
	out_region_type_metric_cur		OUT	SYS_REFCURSOR,
	out_region_metric_cur			OUT	SYS_REFCURSOR,
	out_region_metric_val_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetFunds(
	out_mgmt_companies_cur			OUT SYS_REFCURSOR,
	out_mgmt_co_contact_cur			OUT SYS_REFCURSOR,
	out_fund_type_cur				OUT	SYS_REFCURSOR,
	out_funds_cur					OUT	SYS_REFCURSOR,
	out_fund_form_plugin_cur		OUT	SYS_REFCURSOR,
	out_mgmt_co_fund_contact_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetPropertyOptions(
	out_property_options_cur		OUT	SYS_REFCURSOR,
	out_property_el_layout_cur		OUT	SYS_REFCURSOR,
	out_property_addr_options_cur	OUT	SYS_REFCURSOR,
	out_property_tabs_cur			OUT SYS_REFCURSOR,
	out_prop_type_prop_tab_cur		OUT SYS_REFCURSOR,
	out_property_tab_groups_cur		OUT SYS_REFCURSOR,
	out_property_char_layout_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetProperties(
	out_property_type_cur			OUT	SYS_REFCURSOR,
	out_property_sub_type_cur		OUT	SYS_REFCURSOR,
	out_space_type_cur				OUT SYS_REFCURSOR,
	out_space_type_rgn_metric_cur	OUT SYS_REFCURSOR,
	out_prop_type_space_type_cur	OUT SYS_REFCURSOR,
	out_properties_cur				OUT SYS_REFCURSOR,
	out_space_cur					OUT SYS_REFCURSOR,
	out_photos_cur					OUT SYS_REFCURSOR,
	out_property_funds				OUT SYS_REFCURSOR,
	out_reg_score_log_cur			OUT	SYS_REFCURSOR,
	out_reg_score_cur				OUT	SYS_REFCURSOR,
	out_property_mandatory_roles	OUT	SYS_REFCURSOR,
	out_property_fund_ownership		OUT SYS_REFCURSOR
);

PROCEDURE GetPropertiesDashboards(
	out_benchmark_dashb_cur			OUT	SYS_REFCURSOR,
	out_benchmark_dashb_char_cur	OUT	SYS_REFCURSOR,
	out_benchmark_dashb_ind_cur		OUT	SYS_REFCURSOR,
	out_benchmark_dashb_plugin_cur	OUT	SYS_REFCURSOR,
	out_metric_dashb_cur			OUT	SYS_REFCURSOR,
	out_metric_dashb_ind_cur		OUT	SYS_REFCURSOR,
	out_metric_dashb_plugin_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetGresbConfig(
	out_gresb_indicator_map_cur		OUT	SYS_REFCURSOR,
	out_gresb_submission_log_cur	OUT	SYS_REFCURSOR,
	out_property_gresb_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetCurrencies(
	out_currencies_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetLeases(
	out_tenant_cur					OUT SYS_REFCURSOR,
	out_lease_type_cur				OUT SYS_REFCURSOR,
	out_lease_cur					OUT SYS_REFCURSOR,
	out_lease_postit_cur			OUT SYS_REFCURSOR,
	out_lease_property_cur			OUT SYS_REFCURSOR,
	out_lease_space_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetPlugins(
	out_plugin_cur					OUT SYS_REFCURSOR,
	out_plugin_ind_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetSuppliers(
	out_supplier_score_log_cur 		OUT SYS_REFCURSOR,
	out_supplier_score_cur 			OUT SYS_REFCURSOR,
	out_supplier_cur 				OUT SYS_REFCURSOR,
	out_sup_survey_resp_cur			OUT	SYS_REFCURSOR,
	out_issue_supplier_cur			OUT	SYS_REFCURSOR,
	out_supplier_delegation_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetBasicChain(
	out_chain_capability_cur		OUT SYS_REFCURSOR,
	out_chain_capability_flow_cur	OUT SYS_REFCURSOR,
	out_chain_customer_options_cur	OUT SYS_REFCURSOR,
	out_chain_company_type_cur		OUT SYS_REFCURSOR,
	out_chain_company_cur			OUT SYS_REFCURSOR,
	out_cacc_cur					OUT SYS_REFCURSOR,
	out_chain_chain_user_cur		OUT SYS_REFCURSOR,
	out_chain_company_group_cur		OUT SYS_REFCURSOR,
	out_cctr_cur					OUT SYS_REFCURSOR,
	out_cctc_cur					OUT SYS_REFCURSOR,
	out_cgco_cur					OUT SYS_REFCURSOR,
	out_chain_implementation_cur	OUT SYS_REFCURSOR,
	out_chain_sector_cur			OUT SYS_REFCURSOR,
	out_ctr_cur						OUT SYS_REFCURSOR,
	out_chain_ct_role_cur			OUT SYS_REFCURSOR,
	out_chain_suppl_relat_cur		OUT SYS_REFCURSOR,
	out_chain_supp_rel_src_cur		OUT SYS_REFCURSOR,
	out_csrs_cur					OUT SYS_REFCURSOR,
	out_chain_suppl_follower_cur	OUT SYS_REFCURSOR,
	out_chain_risk_level_cur		OUT SYS_REFCURSOR,
	out_chain_country_risk_lvl_cur	OUT SYS_REFCURSOR,
	out_chain_tpl_delegation_cur	OUT SYS_REFCURSOR,
	out_cctsc_cur					OUT SYS_REFCURSOR,
	out_cctscct_cur					OUT SYS_REFCURSOR,
	out_supplier_involvement_type	OUT SYS_REFCURSOR
);

PROCEDURE GetChainCards(
	out_chain_card_cur OUT SYS_REFCURSOR,
	out_chain_card_group_card_cur OUT SYS_REFCURSOR,
	out_chain_card_group_progr_cur OUT SYS_REFCURSOR,
	out_chain_card_init_param_cur OUT SYS_REFCURSOR
);

PROCEDURE GetAuditLog(
	out_audit_log_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetSysTranslationsAudit(
	out_sys_trans_audit_log_cur				OUT	SYS_REFCURSOR,
	out_sys_trans_audit_data_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetExportFeed(
	out_export_feed_cur				OUT	SYS_REFCURSOR,
	out_ef_cms_form_cur				OUT	SYS_REFCURSOR,
	out_ef_dataview_cur				OUT	SYS_REFCURSOR,
	out_ef_stored_proc_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetChainActivities (
	out_chain_project_cur 			OUT SYS_REFCURSOR,
	out_chain_activity_type_cur 	OUT SYS_REFCURSOR,
	out_chain_outcome_type_cur 		OUT SYS_REFCURSOR,
	out_caot_cur 					OUT SYS_REFCURSOR,
	out_chain_activity_cur 			OUT SYS_REFCURSOR,
	out_chain_activity_log_cur 		OUT SYS_REFCURSOR,
	out_chain_act_log_file_cur		OUT SYS_REFCURSOR,
	out_cattg_cur 					OUT SYS_REFCURSOR,
	out_chain_activity_invl_cur 	OUT SYS_REFCURSOR,
	out_chain_activity_tag_cur 		OUT SYS_REFCURSOR,
	out_cata_cur 					OUT SYS_REFCURSOR,
	out_chain_act_out_type_act_cur 	OUT SYS_REFCURSOR,
	out_cata1_cur					OUT SYS_REFCURSOR,
	out_catar_cur					OUT SYS_REFCURSOR,
	out_catdu_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetChainProducts(
	out_chain_product_type_cur 			OUT SYS_REFCURSOR,
	out_chain_product_type_tr_cur 		OUT SYS_REFCURSOR,
	out_chain_comp_prod_type_cur 		OUT SYS_REFCURSOR,
	out_chain_product_type_tag_cur 		OUT SYS_REFCURSOR,
	out_chain_product_metric_cur		OUT SYS_REFCURSOR,
	out_chain_prd_mtrc_prd_typ_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetChainMiscellaneous (
	out_chain_amount_unit_cur OUT SYS_REFCURSOR,
	out_ccueal_cur OUT SYS_REFCURSOR,
	out_cdpct_cur OUT SYS_REFCURSOR,
	out_cdsrcl_cur OUT SYS_REFCURSOR,
	out_chain_email_stub_cur OUT SYS_REFCURSOR,
	out_chain_ucd_logon_cur OUT SYS_REFCURSOR,
	out_chain_url_overrides_cur OUT SYS_REFCURSOR,
	out_chain_certification_cur OUT SYS_REFCURSOR,
	out_chain_cert_aud_type_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainAudits (
	out_chain_audit_request_cur OUT SYS_REFCURSOR,
	out_cara_cur OUT SYS_REFCURSOR,
	out_chain_supplier_audit_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainBusinessUnits (
	out_chain_business_unit_cur OUT SYS_REFCURSOR,
	out_cbum_cur OUT SYS_REFCURSOR,
	out_cbus_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainCompanies (
	out_chain_company_cc_email_cur	OUT SYS_REFCURSOR,
	out_chain_company_header_cur	OUT SYS_REFCURSOR,
	out_ccmt_cur					OUT SYS_REFCURSOR,
	out_chain_company_metric_cur	OUT SYS_REFCURSOR,
	out_chain_reference_cur			OUT SYS_REFCURSOR,
	out_chain_reference_ct_cur		OUT SYS_REFCURSOR,
	out_chain_reference_cap_cur		OUT SYS_REFCURSOR,
	out_chain_company_reference_c	OUT SYS_REFCURSOR,
	out_chain_company_tab_cur		OUT SYS_REFCURSOR,
	out_chain_co_tab_rel_co_tye_c	OUT SYS_REFCURSOR,
	out_chain_company_tag_group_c	OUT SYS_REFCURSOR,
	out_chain_comp_type_tag_group	OUT SYS_REFCURSOR,
	out_chain_product_header_cur	OUT SYS_REFCURSOR,
	out_chain_pro_hd_pro_type_cur	OUT SYS_REFCURSOR,
	out_chain_product_tab_cur		OUT SYS_REFCURSOR,
	out_cptpt_cur					OUT SYS_REFCURSOR,
	out_cpst_cur					OUT SYS_REFCURSOR,
	out_chain_pr_sp_tb_pr_typ_cur	OUT SYS_REFCURSOR,
	out_chain_alt_company_name_cur	OUT SYS_REFCURSOR,
	out_chain_company_request_cur	OUT	SYS_REFCURSOR,
	out_chain_co_tab_co_type_rl_c	OUT SYS_REFCURSOR
);

PROCEDURE GetChainFilesAndFilters (
	out_chain_compound_filter_cur 	OUT SYS_REFCURSOR,
	out_chain_file_upload_cur 		OUT SYS_REFCURSOR,
	out_chain_file_group_cur 		OUT SYS_REFCURSOR,
	out_chain_file_group_file_cur 	OUT SYS_REFCURSOR,
	out_cwfu_cur 					OUT SYS_REFCURSOR,
	out_chain_filter_cur 			OUT SYS_REFCURSOR,
	out_chain_filter_field_cur 		OUT SYS_REFCURSOR,
	out_chain_filter_value_cur 		OUT SYS_REFCURSOR,
	out_cf_cur 						OUT SYS_REFCURSOR,
	out_chain_saved_filter_cur 		OUT SYS_REFCURSOR,
	out_chain_saved_fil_agg_t_cur 	OUT SYS_REFCURSOR,
	out_chain_saved_fil_col_cur		OUT SYS_REFCURSOR,
	out_chain_flow_filter_cur		OUT SYS_REFCURSOR,
	out_chain_svd_fil_alert_cur 	OUT SYS_REFCURSOR,
	out_chain_svd_fl_alrt_sub_cur 	OUT SYS_REFCURSOR,
	out_chain_fltr_itm_config_cur	OUT SYS_REFCURSOR,
	out_chain_filter_page_cols_cur 	OUT SYS_REFCURSOR,
	out_chain_filter_page_inds_cur 	OUT SYS_REFCURSOR,
	out_chain_fltr_pg_ind_itvl_cur 	OUT SYS_REFCURSOR,
	out_chain_custom_agg_type_cur 	OUT SYS_REFCURSOR,
	out_chain_agg_type_config_cur	OUT SYS_REFCURSOR,
	out_chain_svd_fltr_region_cur 	OUT SYS_REFCURSOR,
	out_chain_filter_page_cms_tab	OUT SYS_REFCURSOR,
	out_chain_customer_grid_ext		OUT SYS_REFCURSOR,
	out_ccfc_cur					OUT SYS_REFCURSOR,
	out_ccfi_cur					OUT SYS_REFCURSOR,
	out_ccfiat_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetChainComponents (
	out_chain_component_type_cur OUT SYS_REFCURSOR,
	out_cctc_cur OUT SYS_REFCURSOR,
	out_chain_component_cur OUT SYS_REFCURSOR,
	out_ccd_cur OUT SYS_REFCURSOR,
	out_chain_component_source_cur OUT SYS_REFCURSOR,
	out_chain_component_tag_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainInvitations (
	out_chain_invitation_cur OUT SYS_REFCURSOR,
	out_ciut_cur OUT SYS_REFCURSOR,
	out_cqg_cur OUT SYS_REFCURSOR,
	out_cqt_cur OUT SYS_REFCURSOR,
	out_cfqt_cur OUT SYS_REFCURSOR,
	out_ciqt_cur OUT SYS_REFCURSOR,
	out_ciqtc_cur OUT SYS_REFCURSOR,
	out_chain_message_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainAlerts (
	out_chain_alert_entry_cur OUT SYS_REFCURSOR,
	out_chain_alert_entry_param_c OUT SYS_REFCURSOR,
	out_capt_cur OUT SYS_REFCURSOR,
	out_captp_cur OUT SYS_REFCURSOR,
	out_cuaet_cur OUT SYS_REFCURSOR,
	out_chain_review_alert_cur OUT SYS_REFCURSOR,
	out_chain_scheduled_alert_cur OUT SYS_REFCURSOR,
	out_ccaet_cur OUT SYS_REFCURSOR,
	out_ccaet1_cur OUT SYS_REFCURSOR,
	out_ch_prod_comp_alerts_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainMessages (
	out_cmd_cur OUT SYS_REFCURSOR,
	out_chain_message_param_cur OUT SYS_REFCURSOR,
	out_chain_recipient_cur OUT SYS_REFCURSOR,
	out_chain_message_recipient_c OUT SYS_REFCURSOR,
	out_cmrl_cur OUT SYS_REFCURSOR,
	out_chain_newsflash_cur OUT SYS_REFCURSOR,
	out_chain_newsflash_company_c OUT SYS_REFCURSOR,
	out_cnus_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainProducts (
	out_chain_product_cur OUT SYS_REFCURSOR,
	out_chain_product_code_type_c OUT SYS_REFCURSOR,
	out_cpmt_cur OUT SYS_REFCURSOR,
	out_chain_product_revision_cur OUT SYS_REFCURSOR,
	out_cus_cur OUT SYS_REFCURSOR,
	out_chain_purchase_channel_cur OUT SYS_REFCURSOR,
	out_cpc_cur OUT SYS_REFCURSOR,
	out_chain_purchase_cur OUT SYS_REFCURSOR,
	out_chain_purchase_tag_cur OUT SYS_REFCURSOR,
	out_cpf_cur OUT SYS_REFCURSOR,
	out_cvpc_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainQuestionnaires (
	out_cqsal_cur OUT SYS_REFCURSOR,
	out_cqasm_cur OUT SYS_REFCURSOR,
	out_chain_questionnaire_cur OUT SYS_REFCURSOR,
	out_cqsle_cur OUT SYS_REFCURSOR,
	out_cqsle1_cur OUT SYS_REFCURSOR,
	out_cqea_cur OUT SYS_REFCURSOR,
	out_cqi_cur OUT SYS_REFCURSOR,
	out_cqmt_cur OUT SYS_REFCURSOR,
	out_cqm_cur OUT SYS_REFCURSOR,
	out_cqs_cur OUT SYS_REFCURSOR,
	out_cqu_cur OUT SYS_REFCURSOR,
	out_cqua_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainTasks (
	out_chain_task_cur OUT SYS_REFCURSOR,
	out_ctat_cur OUT SYS_REFCURSOR,
	out_chain_task_entry_cur OUT SYS_REFCURSOR,
	out_chain_task_entry_date_cur OUT SYS_REFCURSOR,
	out_chain_task_entry_file_cur OUT SYS_REFCURSOR,
	out_chain_task_entry_note_cur OUT SYS_REFCURSOR,
	out_chain_task_scheme_cur OUT SYS_REFCURSOR,
	out_chain_task_type_cur OUT SYS_REFCURSOR,
	out_ctiqt_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainUserMessageLog (
	out_chain_user_message_log_cur OUT SYS_REFCURSOR
);

PROCEDURE GetChainBusinessRelationships (
	out_cbrt_cur OUT SYS_REFCURSOR,
	out_cbrt1_cur OUT SYS_REFCURSOR,
	out_cbrtct_cur OUT SYS_REFCURSOR,
	out_cbr_cur OUT SYS_REFCURSOR,
	out_cbrc_cur OUT SYS_REFCURSOR,
	out_cbrp_cur OUT SYS_REFCURSOR
);

PROCEDURE GetWorksheet (
	out_worksheet_cur OUT SYS_REFCURSOR,
	out_worksheet_column_cur OUT SYS_REFCURSOR,
	out_wcvm_cur OUT SYS_REFCURSOR,
	out_worksheet_row_cur OUT SYS_REFCURSOR,
	out_worksheet_value_map_cur OUT SYS_REFCURSOR,
	out_wvmv_cur OUT SYS_REFCURSOR
);

PROCEDURE GetMessageDefinitions (
	out_cdmd_cur OUT SYS_REFCURSOR,
	out_cmdl_cur OUT SYS_REFCURSOR
);

PROCEDURE GetFilterType (
	out_chain_filter_type_cur OUT SYS_REFCURSOR
);

PROCEDURE GetGroupCapability (
	out_chain_group_capability_cur OUT SYS_REFCURSOR
);

PROCEDURE GetCardProgressionAction (
	out_ccpa_cur OUT SYS_REFCURSOR
);

PROCEDURE GetDedupeData (
	out_chain_import_source_cur 	OUT SYS_REFCURSOR,
	out_chain_dedupe_mapping_cur 	OUT SYS_REFCURSOR,
	out_chain_dedupe_rule_set_cur	OUT SYS_REFCURSOR,
	out_chain_dedupe_rule_cur 		OUT SYS_REFCURSOR,
	out_cdpr_cur 					OUT SYS_REFCURSOR,
	out_chain_dedupe_match_cur 		OUT SYS_REFCURSOR,
	out_chain_dedupe_merge_log_cur 	OUT SYS_REFCURSOR,
	out_cdsl_cur 					OUT SYS_REFCURSOR,
	out_cdpc_cur 					OUT SYS_REFCURSOR,
	out_cdpru_cur 					OUT SYS_REFCURSOR,
	out_cdpfc_cur 					OUT SYS_REFCURSOR,
	out_chain_dedupe_sub_cur		OUT SYS_REFCURSOR,
	out_cdpacn_cur 					OUT SYS_REFCURSOR,
	out_pnd_cmpny_sggstd_match_cur	OUT SYS_REFCURSOR,
	out_pending_company_tag_cur		OUT SYS_REFCURSOR,
	out_blcklst_email_domain		OUT SYS_REFCURSOR
);

PROCEDURE GetHigg (
	out_chain_higg OUT SYS_REFCURSOR,
	out_higg_config OUT SYS_REFCURSOR,
	out_higg_module_tag_group OUT SYS_REFCURSOR,
	out_higg_config_module OUT SYS_REFCURSOR,
	out_higg_question_survey OUT SYS_REFCURSOR,
	out_higg_question_op_survey OUT SYS_REFCURSOR,
	out_higg_response OUT SYS_REFCURSOR,
	out_higg_section_score OUT SYS_REFCURSOR,
	out_higg_sub_section_score OUT SYS_REFCURSOR,
	out_higg_question_response OUT SYS_REFCURSOR,
	out_higg_profile OUT SYS_REFCURSOR,
	out_higg_config_profile OUT SYS_REFCURSOR,
	out_higg_question_opt_conv OUT SYS_REFCURSOR
);

PROCEDURE GetChem (
	out_chem_chem_options_cur OUT SYS_REFCURSOR,
	out_chem_cas_cur OUT SYS_REFCURSOR,
	out_chem_cas_group_cur OUT SYS_REFCURSOR,
	out_chem_cas_group_member_cur OUT SYS_REFCURSOR,
	out_chem_cas_restricted_cur OUT SYS_REFCURSOR,
	out_chem_classification_cur OUT SYS_REFCURSOR,
	out_chem_manufacturer_cur OUT SYS_REFCURSOR,
	out_chem_substance_cur OUT SYS_REFCURSOR,
	out_chem_substance_cas_cur OUT SYS_REFCURSOR,
	out_chem_usage_cur OUT SYS_REFCURSOR,
	out_chem_substance_region_cur OUT SYS_REFCURSOR,
	out_csrp_cur OUT SYS_REFCURSOR,
	out_cpcd_cur OUT SYS_REFCURSOR,
	out_cspuc_cur OUT SYS_REFCURSOR,
	out_cspcdc_cur OUT SYS_REFCURSOR,
	out_csal_cur OUT SYS_REFCURSOR,
	out_chem_substance_file_cur OUT SYS_REFCURSOR,
	out_cspu_cur OUT SYS_REFCURSOR,
	out_cspcd_cur OUT SYS_REFCURSOR,
	out_cspuf_cur OUT SYS_REFCURSOR,
	out_chem_usage_audit_log_cur OUT SYS_REFCURSOR
);

PROCEDURE GetScheduledStoredProcs (
	out_ssp_cur OUT SYS_REFCURSOR,
	out_sspl_cur OUT SYS_REFCURSOR
);

PROCEDURE GetFileUploadOptions(
	out_file_type_cur		OUT	SYS_REFCURSOR,
	out_mime_type_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetRReports (
	out_r_report_type_cur	OUT SYS_REFCURSOR,
	out_r_report_cur		OUT SYS_REFCURSOR,
	out_r_report_file_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetLikeForLike(
	out_slot_cur					OUT SYS_REFCURSOR,
	out_email_sub_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetAggregationPeriods(
	out_aggregation_period_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetGeoMaps(
	out_geo_map						OUT SYS_REFCURSOR,
	out_geo_map_region				OUT SYS_REFCURSOR,
	out_cgmtt_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetDegreeDays(
	out_settings					OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR
);

PROCEDURE GetInitiatives (
	out_initiative_cur 				OUT SYS_REFCURSOR,
	out_initiative_metric_cur 		OUT SYS_REFCURSOR,
	out_initiative_project_cur 		OUT SYS_REFCURSOR,
	out_iprs_cur 					OUT SYS_REFCURSOR,
	out_cist_cur 					OUT SYS_REFCURSOR,
	out_initiative_metri_group_cur 	OUT SYS_REFCURSOR,
	out_pim_cur 					OUT SYS_REFCURSOR,
	out_initiative_metri_assoc_cur 	OUT SYS_REFCURSOR,
	out_pimfs_cur 					OUT SYS_REFCURSOR,
	out_imsi_cur 					OUT SYS_REFCURSOR,
	out_aggr_tag_group_cur 			OUT SYS_REFCURSOR,
	out_imti_cur 					OUT SYS_REFCURSOR,
	out_aggr_tag_group_member_cur 	OUT SYS_REFCURSOR,
	out_initiative_comment_cur 		OUT SYS_REFCURSOR,
	out_initiative_event_cur 		OUT SYS_REFCURSOR,
	out_initiative_group_cur 		OUT SYS_REFCURSOR,
	out_igfs_cur 					OUT SYS_REFCURSOR,
	out_initiative_group_mem_cur 	OUT SYS_REFCURSOR,
	out_initiative_group_user_cur 	OUT SYS_REFCURSOR,
	out_iimm_cur 					OUT SYS_REFCURSOR,
	out_iit_cur 					OUT SYS_REFCURSOR,
	out_iitm_cur 					OUT SYS_REFCURSOR,
	out_initiative_metric_val_cur 	OUT SYS_REFCURSOR,
	out_ips_cur 					OUT SYS_REFCURSOR,
	out_initiative_period_cur 		OUT SYS_REFCURSOR,
	out_initiative_project_tab_cur 	OUT SYS_REFCURSOR,
	out_iptg_cur 					OUT SYS_REFCURSOR,
	out_initiative_proj_team_cur 	OUT SYS_REFCURSOR,
	out_initiative_region_cur 		OUT SYS_REFCURSOR,
	out_initiative_sponsor_cur 		OUT SYS_REFCURSOR,
	out_initiative_tag_cur 			OUT SYS_REFCURSOR,
	out_initiative_user_group_cur 	OUT SYS_REFCURSOR,
	out_ipug_cur 					OUT SYS_REFCURSOR,
	out_initiative_user_cur 		OUT SYS_REFCURSOR,
	out_initiative_user_msg_cur 	OUT SYS_REFCURSOR,
	out_initiatives_options_cur 	OUT SYS_REFCURSOR,
	out_user_msg_cur 				OUT SYS_REFCURSOR,
	out_user_msg_file_cur			OUT SYS_REFCURSOR,
	out_pips_cur 					OUT SYS_REFCURSOR,
	out_dius_cur 					OUT SYS_REFCURSOR,
	out_issue_initiative_cur 		OUT SYS_REFCURSOR,
	out_aggr_region_cur 			OUT SYS_REFCURSOR,
	out_project_doc_folder_cur 		OUT SYS_REFCURSOR,
	out_project_tag_group_cur 		OUT SYS_REFCURSOR,
	out_project_tag_filter_cur 		OUT SYS_REFCURSOR,
	out_init_header_element_cur		OUT SYS_REFCURSOR,
	out_init_tab_element_layout		OUT SYS_REFCURSOR,
	out_init_create_el_layout_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetCustomFactors(
	out_custom_factor_set			OUT SYS_REFCURSOR,
	out_custom_factor				OUT SYS_REFCURSOR,
	out_custom_factor_history		OUT SYS_REFCURSOR
);

PROCEDURE GetEmissionFactorProfiles(
	out_emission_factor_profile		OUT SYS_REFCURSOR,
	out_emission_fctr_profile_fctr	OUT SYS_REFCURSOR,
	out_std_factor_set_active		OUT SYS_REFCURSOR
);

PROCEDURE GetCompliance(
	out_options							OUT SYS_REFCURSOR,
	out_compliance_languages			OUT SYS_REFCURSOR,
	out_compliance_item_version_log		OUT SYS_REFCURSOR,
	out_compliance_audit_log			OUT SYS_REFCURSOR,
	out_compliance_item_regions			OUT SYS_REFCURSOR,
	out_compliance_reg_req				OUT SYS_REFCURSOR,
	out_compliance_regulations			OUT SYS_REFCURSOR,
	out_compliance_requirement			OUT SYS_REFCURSOR,
	out_compliance_item_tag				OUT SYS_REFCURSOR,
	out_compliance_item					OUT SYS_REFCURSOR,
	out_compliance_item_desc			OUT SYS_REFCURSOR,
	out_compliance_region_tag			OUT SYS_REFCURSOR,
	out_compliance_root_regions			OUT SYS_REFCURSOR,
	out_enhesa_options					OUT SYS_REFCURSOR,
	out_enhesa_error_log				OUT SYS_REFCURSOR,
	out_compliance_item_sched_iss_cur	OUT SYS_REFCURSOR,
	out_flow_item_audit_log				OUT SYS_REFCURSOR,
	out_compliance_pmt_sub_type			OUT SYS_REFCURSOR,
	out_compliance_permit_type			OUT SYS_REFCURSOR,
	out_compliance_cond_sub_type		OUT SYS_REFCURSOR,
	out_compliance_cond_type			OUT SYS_REFCURSOR,
	out_compliance_activity_type		OUT SYS_REFCURSOR,
	out_compliance_act_sub_type			OUT SYS_REFCURSOR,
	out_compliance_appl_type			OUT SYS_REFCURSOR,
	out_compliance_permit_app			OUT SYS_REFCURSOR,
	out_compliance_permit				OUT SYS_REFCURSOR,
	out_compliance_item_rollout			OUT SYS_REFCURSOR,
	out_compliance_permit_cond			OUT SYS_REFCURSOR,
	out_compliance_permit_tab			OUT SYS_REFCURSOR,
	out_compliance_permit_tab_group		OUT SYS_REFCURSOR,
	out_compliance_permit_history		OUT SYS_REFCURSOR,
	out_compliance_permit_app_pause		OUT SYS_REFCURSOR,
	out_compliance_rollout_regions		OUT SYS_REFCURSOR,
	out_compliance_permit_score			OUT SYS_REFCURSOR,
	out_compliance_permit_hdr			OUT SYS_REFCURSOR,
	out_compliance_permit_hdr_group		OUT SYS_REFCURSOR,
	out_compliance_item_desc_hist		OUT SYS_REFCURSOR
);

PROCEDURE GetCalendars(
	out_calendar_cur				OUT SYS_REFCURSOR,
	out_calendar_event_cur			OUT SYS_REFCURSOR,
	out_calendar_event_invite_cur	OUT SYS_REFCURSOR,
	out_calendar_event_owner_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetClientUtilScripts(
	out_client_util_script_cur		OUT SYS_REFCURSOR,
	out_cusp_cur					OUT SYS_REFCURSOR,
	out_util_script_run_log_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetTextToTranslate(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetDynamicTables(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetDynamicTables(
	in_modules						IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT	SYS_REFCURSOR
);

FUNCTION GetDynamicTablesForImport RETURN security.T_VARCHAR2_TABLE;

PROCEDURE GetDynamicTablesForImport(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetDynamicTableData(
	in_owner						IN	VARCHAR2,
	in_table_name					IN	VARCHAR2,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetIntApiCompanyUserGroups(
	out_company_user_groups			OUT	SYS_REFCURSOR
);

PROCEDURE GetSecondaryRegionTreeCtrl(
	out_secondary_region_tree_ctrl	OUT	SYS_REFCURSOR
);

PROCEDURE GetSecondaryRegionTreeLog(
	out_secondary_region_tree_log	OUT	SYS_REFCURSOR
);

PROCEDURE GetOshaMappings (
	out_osha_mappings 			OUT SYS_REFCURSOR
);

PROCEDURE GetDataBuckets (
	out_data_buckets 			OUT SYS_REFCURSOR
);

PROCEDURE GetCredentialManagement(
	out_credential_management	OUT SYS_REFCURSOR
);

PROCEDURE GetIntegrationQuestionAnswer(
	out_integration_question_answer	OUT SYS_REFCURSOR
);

PROCEDURE GetRegionCertificates(
	out_region_certificates	OUT SYS_REFCURSOR
);

PROCEDURE GetRegionEnergyRatings(
	out_region_energy_ratings	OUT SYS_REFCURSOR
);

PROCEDURE GetModuleHistory(
	out_module_history	OUT SYS_REFCURSOR
);

PROCEDURE GetExcelExportOptionsTagGroup(
	out_cur_ee_options_tg	OUT SYS_REFCURSOR
);

PROCEDURE GetBaselineConfig(
	out_cur_baseline_config	OUT SYS_REFCURSOR,
	out_cur_baseline_config_period	OUT SYS_REFCURSOR
);

END schema_pkg;
/
