-- Please update version.sql too -- this keeps clean builds in sync
define version=1051
@update_header

create index csr.ix_alert_templat_customer_aler on csr.alert_template_body (app_sid, customer_alert_type_id);
create index csr.ix_all_meter_days_measure_ on csr.all_meter (app_sid, days_measure_conversion_id);
create index csr.ix_all_meter_costdays_ind_ on csr.all_meter (app_sid, costdays_ind_sid);
create index csr.ix_all_meter_costdays_meas on csr.all_meter (app_sid, costdays_measure_conversion_id);
create index csr.ix_all_meter_days_ind_sid on csr.all_meter (app_sid, days_ind_sid);
create index csr.ix_approval_dash_tpl_report_si on csr.approval_dashboard (app_sid, tpl_report_sid);
create index csr.ix_approval_dash_approval_dash on csr.approval_dashboard_alert_type (app_sid, approval_dashboard_sid, flow_sid);
create index csr.ix_approval_dash_customer_aler on csr.approval_dashboard_alert_type (app_sid, customer_alert_type_id, flow_sid);
create index csr.ix_approval_dash_inst_dash on csr.approval_dashboard_instance (app_sid, approval_dashboard_sid, tpl_report_sid);
create index csr.ix_appr_dash_tpl_tag_report_si on csr.approval_dashboard_tpl_tag (app_sid, tpl_report_sid, tag);
create index csr.ix_axis_menu_sid on csr.axis (menu_sid);
create index csr.ix_calc_tag_depe_tag_id on csr.calc_tag_dependency (app_sid, tag_id);
create index csr.ix_customer_port_portlet_id on csr.customer_portlet (portlet_id);
create index csr.ix_delegation_us_user_cover_id on csr.delegation_user_cover (app_sid, user_cover_id, user_giving_cover_sid, user_being_covered_sid);
create index csr.ix_delegation_us_user_giving_c on csr.delegation_user_cover (app_sid, user_giving_cover_sid);
create index csr.ix_delegation_us_user_being_co on csr.delegation_user_cover (app_sid, user_being_covered_sid);
create index csr.ix_deleg_data_ch_sheet_id on csr.deleg_data_change_alert (app_sid, sheet_id);
create index csr.ix_deleg_data_ch_notify_user_s on csr.deleg_data_change_alert (app_sid, notify_user_sid);
create index csr.ix_deleg_data_ch_raised_by_use on csr.deleg_data_change_alert (app_sid, raised_by_user_sid);
create index csr.ix_deleg_ind_del_delegation_si on csr.deleg_ind_deleg_ind_group (app_sid, delegation_sid, deleg_ind_group_id);
create index csr.ix_deleg_ind_for_form_expr_id on csr.deleg_ind_form_expr (app_sid, form_expr_id);
create index csr.ix_deleg_plan_ap_applied_by_us on csr.deleg_plan_applied (app_sid, applied_by_user_sid);
create index csr.ix_deleg_plan_ap_deleg_plan_si on csr.deleg_plan_applied (app_sid, deleg_plan_sid);
create index csr.ix_deleg_plan_de_maps_to_root_ on csr.deleg_plan_deleg_region_deleg (app_sid, maps_to_root_deleg_sid);
create index csr.ix_feed_feed_type_id on csr.feed (feed_type_id);
create index csr.ix_flow_alert_ty_flow_sid on csr.flow_alert_type (app_sid, flow_sid);
create index csr.ix_flow_item_ale_flow_state_lo on csr.flow_item_alert (app_sid, flow_state_log_id, flow_item_id);
create index csr.ix_flow_item_ale_flow_state_tr on csr.flow_item_alert (app_sid, flow_state_transition_id, customer_alert_type_id);
create index csr.ix_flow_state_flow_sid on csr.flow_state (app_sid, flow_sid);
create index csr.ix_flow_transiti_customer_aler on csr.flow_transition_alert (app_sid, customer_alert_type_id);
create index csr.ix_flow_transiti_role_sid on csr.flow_transition_alert_role (app_sid, role_sid);
create index csr.ix_form_expr_delegation_si on csr.form_expr (app_sid, delegation_sid);
create index csr.ix_img_chart_ind_ind_sid on csr.img_chart_ind (app_sid, ind_sid);
create index csr.ix_img_chart_ind_measure_conve on csr.img_chart_ind (app_sid, measure_conversion_id);
create index csr.ix_internal_audi_default_surve on csr.internal_audit_type (app_sid, default_survey_sid);
create index csr.ix_issue_rejected_by_u on csr.issue (app_sid, rejected_by_user_sid);
create index csr.ix_issue_issue_priorit on csr.issue (app_sid, issue_priority_id);
create index csr.ix_issue_last_issue_pr on csr.issue (app_sid, last_issue_priority_id);
create index csr.ix_issue_action__re_role_sid on csr.issue_action_log (app_sid, re_role_sid);
create index csr.ix_issue_action__re_user_sid on csr.issue_action_log (app_sid, re_user_sid);
create index csr.ix_issue_action__old_priority_ on csr.issue_action_log (app_sid, old_priority_id);
create index csr.ix_issue_action__new_priority_ on csr.issue_action_log (app_sid, new_priority_id);
create index csr.ix_issue_meter_d_raw_data_sour on csr.issue_meter_data_source (app_sid, raw_data_source_id);
create index csr.ix_issue_type_default_issue on csr.issue_type (app_sid, default_issue_priority_id);
create index csr.ix_last_used_mea_measure_conve on csr.last_used_measure_conversion (app_sid, measure_conversion_id);
create index csr.ix_last_used_mea_measure_sid on csr.last_used_measure_conversion (app_sid, measure_sid);
create index csr.ix_logistics_def_std_measure_c on csr.logistics_default (std_measure_conversion_id);
create index csr.ix_logistics_err_tab_sid on csr.logistics_error_log (app_sid, tab_sid);
create index csr.ix_logistics_err_tab_sid_proce on csr.logistics_error_log (app_sid, tab_sid, processor_class_id);
create index csr.ix_logistics_tab_processor_cla on csr.logistics_tab_mode (processor_class_id);
create index csr.ix_postcode_egri_egrid_ref on csr.postcode_egrid (egrid_ref);
create index csr.ix_quick_survey__lang on csr.quick_survey_lang (lang);
create index csr.ix_tab_portlet_customer_port on csr.tab_portlet (app_sid, customer_portlet_sid);
create index csr.ix_tab_portlet_u_region_sid on csr.tab_portlet_user_region (app_sid, region_sid);
create index csr.ix_tab_portlet_u_csr_user_sid on csr.tab_portlet_user_region (app_sid, csr_user_sid);
create index csr.ix_tpl_report_ta_tpl_rep_cust_ on csr.tpl_report_tag (app_sid, tpl_rep_cust_tag_type_id);
create index csr.ix_tpl_report_ta_tpl_report_ta on csr.tpl_report_tag (app_sid, tpl_report_tag_text_id);
create index csr.ix_tpl_report_ta_tpl_rep_logn on csr.tpl_report_tag (app_sid, tpl_report_tag_logging_form_id);
create index csr.ix_tpl_report_ta_filter_sid on csr.tpl_report_tag_logging_form (app_sid, filter_sid);
create index csr.ix_tpl_report_ta_tab_sid on csr.tpl_report_tag_logging_form (app_sid, tab_sid);
create index csr.ix_tpl_report_ta_form_sid on csr.tpl_report_tag_logging_form (app_sid, form_sid);
create index csr.ix_tpl_report_ta_tpl_region_ty on csr.tpl_report_tag_logging_form (tpl_region_type_id);
create index csr.ix_user_cover_user_giving_c on csr.user_cover (app_sid, user_giving_cover_sid);
create index csr.ix_user_cover_user_being_co on csr.user_cover (app_sid, user_being_covered_sid);
create index csr.ix_user_setting__tab_portlet_i on csr.user_setting_entry (app_sid, tab_portlet_id);
create index csr.ix_user_setting__category_sett on csr.user_setting_entry (category, setting);


@update_tail
