-- Please update version.sql too -- this keeps clean builds in sync
define version=2915
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- remove defaults from csrimp tables
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
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\pivot_body
@..\..\..\aspen2\db\mdComment_pkg
@..\..\..\aspen2\db\mdComment_body
@..\..\..\aspen2\db\utils_body
@..\actions\ind_template_body
@..\actions\initiative_body
@..\actions\task_body
@..\chain\activity_body
@..\chain\company_body
@..\chain\component_body
@..\chain\helper_body
@..\chain\plugin_body
@..\chain\questionnaire_body
@..\chain\type_capability_body
@..\chem\substance_body
@..\ct\breakdown_body
@..\donations\browse_settings_body
@..\audit_body
@..\branding_body
@..\delegation_body
@..\flow_body
@..\geo_map_body
@..\help_body
@..\incident_body
@..\indicator_body
@..\initiative_body
@..\initiative_export_body
@..\issue_body
@..\measure_body
@..\model_body
@..\postit_body
@..\property_body
@..\quick_survey_body
@..\scenario_body
@..\section_body
@..\section_search_body
@..\sheet_body
@..\sqlreport_body
@..\target_dashboard_body
@..\teamroom_body
@..\templated_report_body

@update_tail
