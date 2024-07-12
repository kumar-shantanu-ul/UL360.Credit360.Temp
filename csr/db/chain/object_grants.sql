grant select, references on csr.audit_type_closure_type to chain;
grant select, references on csr.csr_user to chain with grant option;
grant insert, update on csr.csr_user to chain;
grant select, delete on csr.user_profile to chain;
grant select on csr.customer to chain with grant option;
grant update, references on csr.customer to chain;
grant references on csr.customer_region_type to chain;
grant select, references on csr.capability to chain;
grant select, references on csr.batch_job to chain;
grant select, references on csr.doc_version to chain;
grant select, references on csr.region to chain with grant option;
grant select, insert, update, delete on csr.temp_region_sid to chain;
grant select, references on csr.std_alert_type to chain;
grant select, references on csr.std_alert_type_param to chain;
grant select, update, references on csr.role to chain with grant option;
grant select on csr.superadmin to chain;
grant select, delete on csr.tab_portlet_rss_feed to chain;
grant select, delete on csr.user_setting_entry to chain;
grant select, delete on csr.tab_portlet to chain;
grant select, delete on csr.tab_user to chain;
grant select, delete on csr.tab_group to chain;
grant select, delete on csr.tab to chain;
grant select, references on csr.tag_group to chain with grant option;
grant select on csr.tag_group_member to chain with grant option;
grant select, references on csr.tag_group_member to chain;
grant select, references on csr.tag to chain with grant option;
grant select on csr.portlet to chain;
grant select, delete, insert on csr.customer_portlet to chain;
grant select on csr.alert_frame to chain;
grant select, insert, update, delete on csr.alert_template to chain;
grant select, insert, update, delete on csr.alert_template_body to chain;
grant select, delete on csr.alert_batch_run to chain;
grant select, insert, update, delete, references on csr.customer_alert_type to chain;
grant select on csr.default_alert_template_body to chain;
grant select, insert, update, delete on csr.customer_alert_type_param to chain;
grant select on csr.region_tree to chain;
grant select, insert on csr.customer_region_type to chain;
grant select, insert on csr.issue_type to chain;
grant select on csr.temp_alert_batch_run to chain;
grant select on csr.quick_survey_submission to chain;
grant select on csr.internal_audit to chain with grant option;
grant update, references on csr.internal_audit to chain;


grant select on csr.internal_audit_survey to chain;
grant select, insert, update, references on csr.internal_audit_type to chain;
grant select on csr.internal_audit_type_id_seq to chain;
grant select, references on csr.ind to chain;
GRANT SELECT, UPDATE, REFERENCES ON csr.measure TO chain;
GRANT SELECT, REFERENCES ON csr.meter_aggregate_type TO chain;
grant select, references on csr.initiative_metric to chain;
grant select, delete on csr.region_role_member to chain with grant option;
grant select, references on csr.quick_survey to chain;
grant select, references on csr.flow_item to chain;
grant select on csr.flow_state to chain;
grant select on csr.flow_state_log to chain;
grant select, references on csr.flow to chain;
grant select on csr.flow_state_role to chain;
grant select on csr.region_tag to chain with grant option;
grant select on csr.flow_capability to chain;
grant select, references on csr.customer_flow_capability to chain;
grant select on csr.flow_state_role_capability to chain;
grant select, insert, delete on csr.customer_flow_alert_class to chain;
grant select on csr.calc_tag_dependency to chain;
GRANT SELECT ON csr.period_set TO chain;
GRANT SELECT, REFERENCES ON csr.period_interval TO chain;
GRANT SELECT ON csr.period TO chain;
GRANT SELECT ON csr.period_dates TO chain;
GRANT SELECT, REFERENCES ON csr.period_interval_member TO chain;
GRANT SELECT, UPDATE ON csr.tpl_report_tag_dataview TO chain;
GRANT SELECT, UPDATE ON csr.tpl_report_tag_logging_form TO chain;
GRANT SELECT, REFERENCES ON csr.quick_survey_question TO chain;
GRANT SELECT ON csr.question_type TO chain;
GRANT SELECT, REFERENCES ON csr.qs_question_option TO chain;
GRANT SELECT ON csr.automated_import_class TO chain;
GRANT SELECT, INSERT, REFERENCES ON csr.ftp_profile TO chain;
GRANT SELECT ON csr.ftp_profile_id_seq TO chain;
GRANT SELECT ON csr.quick_survey_type TO chain;
GRANT REFERENCES, SELECT ON CSR.measure_conversion TO chain;
GRANT SELECT, UPDATE, INSERT, DELETE ON csr.temp_response_region TO chain;
GRANT UPDATE ON csr.quick_survey_question TO chain;
GRANT SELECT ON csr.quick_survey_version TO chain;
grant select on csr.audit_non_compliance to chain;
grant select on csr.non_compliance to chain;

GRANT select, references ON cms.tab TO chain;
grant select, references on cms.tab_column to chain;
grant select, references on cms.cms_aggregate_type to chain;
GRANT SELECT ON cms.uk_cons_col TO chain;

grant select, update, references on security.securable_object to chain WITH GRANT OPTION;
grant select, references on security.group_members to chain WITH GRANT OPTION;
grant select, references on security.application to chain;
grant select, references on security.user_table to chain WITH GRANT OPTION;
grant references on security.group_table to chain;
grant all on security.group_members to chain;
GRANT SELECT ON security.sessionstate TO chain;
GRANT SELECT ON security.act TO chain;

grant select, references on postcode.country to chain with grant option;

grant select, update on aspen2.application to chain;
grant select, update, delete, insert, references on aspen2.filecache to chain;
grant references on aspen2.translation_set to chain;
grant select on aspen2.lang to chain;
grant select on aspen2.translation_set to chain;

grant select on csr.supplier_survey_response to chain;
grant select on csr.quick_survey_response to chain;
grant select on csr.quick_survey_answer to chain;
grant select on csr.qs_answer_file to chain;
grant select on csr.qs_response_file to chain;
grant select on csr.qs_answer_log to chain;
grant select, references on csr.customer_alert_type to chain;
grant select, references on csr.supplier to chain WITH GRANT OPTION;
grant select, references on csr.supplier_score_log to chain;
GRANT select, references ON csr.current_supplier_score TO chain;
grant select, references on csr.score_threshold to chain;
grant select, references on csr.score_type to chain;
grant select, references on csr.score_type_agg_type to chain;
grant select on csr.quick_survey_version to chain;

grant select on csr.customer_alert_type_id_seq to chain;
GRANT SELECT, REFERENCES ON CSR.WORKSHEET TO CHAIN;

GRANT SELECT, INSERT, DELETE, UPDATE ON csr.term_cond_doc TO chain;
GRANT SELECT, INSERT, DELETE, UPDATE ON csr.term_cond_doc_log TO chain;
GRANT SELECT ON csr.doc_version TO chain;

grant select, references on csr.plugin to chain;
grant select, references on csr.plugin_type to chain;
grant select on csr.audit_closure_type to chain;

grant delete on csr.approval_dashboard_tpl_tag to chain;
grant select, delete on csr.tpl_report_tag to chain;
grant select, delete on csr.tpl_report_tag_logging_form to chain;
grant delete on csr.tpl_report_tag_dataview to chain;

grant select on csr.flow_state_transition_inv to chain;
grant select on csr.flow_state_transition_role to chain;
grant select on csr.flow_item to chain;
grant select on csr.flow_transition_alert to chain;
grant select, insert, references on csr.flow_involvement_type to chain;
grant select, insert, references on csr.flow_inv_type_alert_class to chain;
grant select on csr.flow_state_log to chain;
grant select, insert on csr.flow_item_generated_alert to chain;
grant select on csr.flow_item_gen_alert_id_seq to chain;
grant select ON csr.portal_dashboard TO chain;
grant SELECT on cms.item_id_seq to chain;

grant select on csr.automated_import_class to chain;
grant select, references on csr.aggregate_ind_group to chain;

grant select on mail.account to chain;

GRANT SELECT ON postcode.city TO CHAIN WITH GRANT OPTION;
GRANT SELECT ON postcode.region TO CHAIN WITH GRANT OPTION;

GRANT SELECT, REFERENCES ON CSR.QUESTION_OPTION TO CHAIN;

GRANT EXECUTE ON csr.T_USER_FILTER_ROW TO chain;
GRANT EXECUTE ON csr.T_USER_FILTER_TABLE TO chain;

GRANT SELECT, UPDATE, DELETE ON csr.tpl_report_tag TO chain;
GRANT SELECT, UPDATE, DELETE ON csr.tpl_report_tag_logging_form TO chain;
GRANT SELECT, UPDATE, DELETE ON csr.approval_dashboard_tpl_tag TO chain;
GRANT SELECT, UPDATE, DELETE ON csr.tpl_report_tag_dataview TO chain;
GRANT SELECT ON csr.region_survey_response TO chain;

grant select on csr.calc_baseline_config_dependency to chain;
