--Please update version.sql too -- this keeps clean builds in sync
define version=2737
@update_header

create index csr.ix_aggregate_ind_ind_sid on csr.aggregate_ind_val_detail (app_sid, ind_sid);
create index csr.ix_aggregate_ind_aggregate_ind on csr.aggregate_ind_val_detail (app_sid, aggregate_ind_group_id);
create index csr.ix_aggregate_ind_region_sid on csr.aggregate_ind_val_detail (app_sid, region_sid);
create index csr.ix_approval_dash_period_set_id on csr.approval_dashboard (app_sid, period_set_id, period_interval_id);
create index csr.ix_approval_dash_publish_doc_f on csr.approval_dashboard (app_sid, publish_doc_folder_sid);
create index csr.ix_approval_dash_ind_sid on csr.approval_dashboard_ind (app_sid, ind_sid);
create index csr.ix_appr_dash_appr_dash_ind on csr.approval_dashboard_val (app_sid, approval_dashboard_sid, ind_sid);
create index csr.ix_approval_dash_dashboard_ins on csr.approval_dashboard_val (app_sid, dashboard_instance_id, approval_dashboard_sid);
create index csr.ix_approval_dash_note_added_by on csr.approval_dashboard_val (app_sid, note_added_by_sid);
create index csr.ix_approval_note_dashboard_ins on csr.approval_note_portlet_note (app_sid, dashboard_instance_id, approval_dashboard_sid);
create index csr.ix_approval_note_approval_dash on csr.approval_note_portlet_note (app_sid, approval_dashboard_sid);
create index csr.ix_approval_note_tab_portlet_i on csr.approval_note_portlet_note (app_sid, tab_portlet_id);
create index csr.ix_approval_note_added_by_sid on csr.approval_note_portlet_note (app_sid, added_by_sid);
create index csr.ix_approval_note_region_sid on csr.approval_note_portlet_note (app_sid, region_sid);
create index csr.ix_audit_iss_all_csr_user_sid on csr.audit_iss_all_closed_alert (app_sid, csr_user_sid);
create index csr.ix_audit_type_cl_audit_closure on csr.audit_type_closure_type (app_sid, audit_closure_type_id);
create index csr.ix_batch_job_app_batch_job_id on csr.batch_job_approval_dash_vals (app_sid, batch_job_id);
create index csr.ix_batch_job_met_period_set_id on csr.batch_job_meter_extract (app_sid, period_set_id, period_interval_id);
create index csr.ix_benchmark_das_period_set_id on csr.benchmark_dashboard (app_sid, period_set_id, period_interval_id);
create index csr.ix_cms_imp_class_cms_imp_file_ on csr.cms_imp_class_step (cms_imp_file_type_id);
create index csr.ix_cms_imp_class_cms_imp_proto on csr.cms_imp_class_step (cms_imp_protocol_id);
create index csr.ix_cms_imp_insta_cms_imp_class on csr.cms_imp_instance (app_sid, cms_imp_class_sid);
create index csr.ix_cms_imp_insta_batch_job_id on csr.cms_imp_instance (app_sid, batch_job_id);
create index csr.ix_cms_imp_insta_cms_imp_insta on csr.cms_imp_instance_step (app_sid, cms_imp_instance_id, cms_imp_class_sid);
create index csr.ix_cms_imp_insta_result on csr.cms_imp_instance_step (result);
create index csr.ix_cms_imp_istp_cms_imp_insta on csr.cms_imp_instance_step_msg (app_sid, cms_imp_instance_step_id);
create index csr.ix_course_status_id on csr.course (status_id);
create index csr.ix_course_region_sid on csr.course (app_sid, region_sid);
create index csr.ix_course_quiz_sid on csr.course (app_sid, quiz_sid);
create index csr.ix_course_default_place on csr.course (app_sid, default_place_id);
create index csr.ix_course_delivery_meth on csr.course (delivery_method_id);
create index csr.ix_course_survey_sid on csr.course (app_sid, survey_sid);
create index csr.ix_course_course_type_i on csr.course (app_sid, course_type_id);
create index csr.ix_course_provision_id on csr.course (provision_id);
create index csr.ix_course_default_train on csr.course (app_sid, default_trainer_id);
create index csr.ix_course_schedu_trainer_id on csr.course_schedule (app_sid, trainer_id);
create index csr.ix_course_schedu_course_id on csr.course_schedule (app_sid, course_id);
create index csr.ix_course_schedu_place_id on csr.course_schedule (app_sid, place_id);
create index csr.ix_course_schedu_calendar_even on csr.course_schedule (app_sid, calendar_event_id);
create index csr.ix_course_type_user_relation on csr.course_type (app_sid, user_relationship_type_id);
create index csr.ix_course_type_r_region_sid on csr.course_type_region (app_sid, region_sid);
create index csr.ix_dataview_period_set_id on csr.dataview (app_sid, period_set_id, period_interval_id);
create index csr.ix_delegation_period_set_id on csr.delegation (app_sid, period_set_id, period_interval_id);
create index csr.ix_delegation_tag_visibilit on csr.delegation (app_sid, tag_visibility_matrix_group_id);
create index csr.ix_deleg_plan_period_set_id on csr.deleg_plan (app_sid, period_set_id, period_interval_id);
create index csr.ix_deleg_report_period_set_id on csr.deleg_report (app_sid, period_set_id, period_interval_id);
create index csr.ix_enhesa_countr_lang on csr.enhesa_country_name (lang);
create index csr.ix_enhesa_ctrgn_lang on csr.enhesa_country_region_name (lang);
create index csr.ix_enhesa_headin_lang on csr.enhesa_heading_text (lang);
create index csr.ix_enhesa_intro_country_code_ on csr.enhesa_intro (country_code, region_code);
create index csr.ix_enhesa_intro_country_code on csr.enhesa_intro (country_code);
create index csr.ix_enhesa_intro_protocol_head on csr.enhesa_intro (app_sid, protocol, heading_code);
create index csr.ix_enhesa_intro__lang on csr.enhesa_intro_text (lang);
create index csr.ix_enhesa_keywor_lang on csr.enhesa_keyword_text (lang);
create index csr.ix_enhesa_reg_country_code on csr.enhesa_reg (country_code);
create index csr.ix_enhesa_reg_he_protocol_head on csr.enhesa_reg_heading (app_sid, protocol, heading_code);
create index csr.ix_enhesa_reg_re_country_code_ on csr.enhesa_reg_region (country_code, region_code);
create index csr.ix_enhesa_rqmt_protocol_head on csr.enhesa_rqmt (app_sid, protocol, heading_code);
create index csr.ix_enhesa_rqmt_country_code on csr.enhesa_rqmt (country_code);
create index csr.ix_enhesa_rqmt_country_code_ on csr.enhesa_rqmt (country_code, region_code);
create index csr.ix_enhesa_rqmt_t_lang on csr.enhesa_rqmt_text (lang);
create index csr.ix_enhesa_scrngq_protocol_base on csr.enhesa_scrngqn (app_sid, protocol, base_heading_code);
create index csr.ix_enhesa_scrngq_protocol_head on csr.enhesa_scrngqn_heading (app_sid, protocol, heading_code);
create index csr.ix_enhesa_scrngq_lang on csr.enhesa_scrngqn_text (lang);
create index csr.ix_enhesa_status_lang on csr.enhesa_status_name (lang);
create index csr.ix_enhesa_sup_do_country_code_ on csr.enhesa_sup_doc (country_code, region_code);
create index csr.ix_enhesa_sup_do_country_code on csr.enhesa_sup_doc (country_code);
create index csr.ix_enhesa_sup_do_lang on csr.enhesa_sup_doc_item_text (lang);
create index csr.ix_enhesa_topic_status_id on csr.enhesa_topic (status_id);
create index csr.ix_enhesa_topic_country_code on csr.enhesa_topic (country_code);
create index csr.ix_enhesa_topic__protocol_head on csr.enhesa_topic_heading (app_sid, protocol, heading_code);
create index csr.ix_enhesa_topic__protocol_keyw on csr.enhesa_topic_keyword (app_sid, protocol, keyword_id);
create index csr.ix_enhesa_topic__protocol_reg_ on csr.enhesa_topic_reg (app_sid, protocol, reg_id);
create index csr.ix_enhesa_topic__country_code_ on csr.enhesa_topic_region (country_code, region_code);
create index csr.ix_flow_state_au_flow_state_au on csr.flow_state_audit_ind (flow_state_audit_ind_type_id);
create index csr.ix_flow_state_au_internal_audi on csr.flow_state_audit_ind (app_sid, internal_audit_type_id);
create index csr.ix_form_period_set_id on csr.form (app_sid, period_set_id, period_interval_id);
create index csr.ix_function_cour_training_prio on csr.function_course (training_priority_id);
create index csr.ix_function_cour_course_id on csr.function_course (app_sid, course_id);
create index csr.ix_ind_period_set_id on csr.ind (app_sid, period_set_id, period_interval_id);
create index csr.ix_internal_audi_ovw_nc_score_ on csr.internal_audit (app_sid, ovw_nc_score_thrsh_id);
create index csr.ix_internal_audi_nc_score_thrs on csr.internal_audit (app_sid, nc_score_thrsh_id);
create index csr.ix_metric_dashbo_period_set_id on csr.metric_dashboard (app_sid, period_set_id, period_interval_id);
create index csr.ix_qs_ansfil_svy_respon_fil on csr.qs_answer_file (app_sid, survey_response_id, sha1, filename, mime_type);
create index csr.ix_qs_expr_non_c_non_complianc on csr.qs_expr_non_compl_action (app_sid, non_compliance_type_id);
create index csr.ix_region_postit_postit_id on csr.region_postit (app_sid, postit_id);
create index csr.ix_ruleset_period_set_id on csr.ruleset (app_sid, period_set_id, period_interval_id);
create index csr.ix_scenario_period_set_id on csr.scenario (app_sid, period_set_id, period_interval_id);
--create index csr.ix_scenario_run__source_type_i on csr.scenario_run_val (source_type_id);
create index csr.ix_section_fact_map_to_region on csr.section_fact (app_sid, map_to_region_sid);
create index csr.ix_section_fact_std_measure_c on csr.section_fact (std_measure_conversion_id);
create index csr.ix_section_fact_map_to_ind_si on csr.section_fact (app_sid, map_to_ind_sid);
create index csr.ix_section_fact__attachment_id on csr.section_fact_attach (app_sid, attachment_id);
create index csr.ix_snapshot_period_set_id on csr.snapshot (app_sid, period_set_id, period_interval_id);
create index csr.ix_supplier_scor_score_type_id on csr.supplier_score_log (app_sid, score_type_id);
create index csr.ix_supplier_scor_changed_by_us on csr.supplier_score_log (app_sid, changed_by_user_sid);
create index csr.ix_target_dashbo_period_set_id on csr.target_dashboard (app_sid, period_set_id, period_interval_id);
create index csr.ix_tpl_report_period_set_id on csr.tpl_report (app_sid, period_set_id, period_interval_id);
create index csr.ix_tpl_report_no_period_set_id on csr.tpl_report_non_compl (app_sid, period_set_id, period_interval_id);
create index csr.ix_tpl_rptmat_ta_approval_dash on csr.tpl_report_tag_approval_matrix (app_sid, approval_dashboard_sid);
create index csr.ix_tpl_rettag_ta_approval_dash on csr.tpl_report_tag_approval_note (app_sid, approval_dashboard_sid);
create index csr.ix_tpl_report_ta_tab_portlet_i on csr.tpl_report_tag_approval_note (app_sid, tab_portlet_id);
create index csr.ix_tpl_report_ta_saved_filter_ on csr.tpl_report_tag_dataview (app_sid, saved_filter_sid);
create index csr.ix_tpl_report_ta_ind_tag on csr.tpl_report_tag_dataview (app_sid, ind_tag);
create index csr.ix_tpl_rpttag_ta_approval_dash on csr.tpl_report_tag_dataview (app_sid, approval_dashboard_sid);
create index csr.ix_tpl_report_ta_period_set_id on csr.tpl_report_tag_dataview (app_sid, period_set_id, period_interval_id);
create index csr.ix_tpl_reptgev_period_set_id on csr.tpl_report_tag_eval (app_sid, period_set_id, period_interval_id);
create index csr.ix_tpl_reptgind_period_set_id on csr.tpl_report_tag_ind (app_sid, period_set_id, period_interval_id);
create index csr.ix_tpl_report_ta_measure_conve on csr.tpl_report_tag_ind (app_sid, measure_conversion_id);
create index csr.ix_tpl_reptglog_period_set_id on csr.tpl_report_tag_logging_form (app_sid, period_set_id, period_interval_id);
create index csr.ix_trainer_user_sid on csr.trainer (app_sid, user_sid);
create index csr.ix_training_opti_flow_sid on csr.training_options (app_sid, flow_sid);
create index csr.ix_training_opti_calendar_sid on csr.training_options (app_sid, calendar_sid);
create index csr.ix_user_function_function_id on csr.user_function (app_sid, function_id);
create index csr.ix_user_relation_parent_user_s on csr.user_relationship (app_sid, parent_user_sid);
create index csr.ix_user_relation_user_relation on csr.user_relationship (app_sid, user_relationship_type_id);
create index csr.ix_user_training_course_schedu on csr.user_training (app_sid, course_schedule_id);
create index csr.ix_user_training_flow_item_id on csr.user_training (app_sid, flow_item_id);
create index csr.ix_issue_meter_m_region on csr.issue_meter_missing_data (app_sid, region_sid);
create index csr.ix_period_intrvl_st_period on csr.period_interval_member (app_sid, period_set_id, start_period_id);
create index csr.ix_period_intrvl_end_period on csr.period_interval_member (app_sid, period_set_id, end_period_id);

@../meter_monitor_body

@update_tail
