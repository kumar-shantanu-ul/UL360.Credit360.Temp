grant select, delete on actions.import_template to csr;
grant select, delete on actions.import_template_mapping to csr;
grant select, delete on actions.instance_gas_ind to csr;
grant select, delete on actions.import_mapping_mru to csr;
grant select, delete on actions.csr_task_role_member to csr;
grant select, references on actions.task to csr;
grant select, insert, update, delete, references on actions.project_region_role_member to csr;
grant select on actions.scenario_filter_status to csr;
grant select, references on actions.task_tag to csr;
grant select, references on actions.tag to csr;
grant select, references on actions.tag_group to csr;
grant select, insert, update, delete on actions.task_recalc_job to csr;
grant select, insert, update, delete on actions.task_recalc_period to csr;
grant select, insert, update, delete on actions.task_recalc_region to csr;
grant select on actions.task_region to csr;
grant select on actions.task_ind_dependency to csr;
grant select on actions.task_ind_template_instance to csr;
GRANT SELECT ON actions.ind_template_id_seq TO csr;
GRANT INSERT, UPDATE ON actions.customer_options TO csr;
GRANT INSERT, UPDATE ON actions.ind_template TO csr;

grant select, references on chain.invitation to csr;
grant select, references on chain.questionnaire to csr;
grant select, references on chain.questionnaire_type to csr;
grant select, references on chain.company to csr with grant option;
grant select, references on chain.compound_filter to csr;
grant select, references on chain.supplier_follower to csr;
grant select, references, insert, update, delete on chain.company_type to csr;
grant select, references on chain.company_group to csr;
grant select, references on chain.company_group_type to csr;
grant select, references on chain.company_type_relationship to csr;
grant select, references on chain.component to csr;
GRANT SELECT, REFERENCES ON chain.debug_log TO csr;
grant delete on chain.supplier_audit to csr;
grant select, insert, update, delete on chain.tt_company_user to csr;
GRANT ALL ON CHAIN.TT_FILTER_OBJECT_DATA TO csr;
grant select on chain.supplier_relationship_source to csr;
grant select, insert, update on chain.supplier_relationship_score to CSR;
grant select on chain.business_unit_supplier to csr;
grant select on chain.business_unit to csr;
GRANT SELECT ON chain.tt_filter_date_range TO csr;
GRANT ALL ON CHAIN.COMPANY_TYPE_TAG_GROUP TO CSR;
grant select on chain.bsci_supplier to csr;
grant select on chain.bsci_supplier_det to csr;
grant select on chain.bsci_audit to csr;
grant select on chain.bsci_2009_audit to csr;
grant select on chain.bsci_2014_audit to csr;
grant select on chain.bsci_ext_audit to csr;
grant select on chain.bsci_2009_audit_finding to csr;
grant select on chain.bsci_2009_audit_associate to csr;
grant select on chain.bsci_2014_audit_finding to csr;
grant select on chain.bsci_2014_audit_associate to csr;
grant select on chain.bsci_import to csr;
GRANT SELECT ON chain.reference_id_seq TO csr;
GRANT SELECT ON chain.company_reference_id_seq TO csr;
GRANT SELECT ON chain.company_request_action TO csr;
GRANT SELECT ON chain.supplier_involvement_type TO csr;

GRANT SELECT ON cms.display_template TO csr;
GRANT SELECT, DELETE ON cms.image TO csr;
GRANT SELECT, REFERENCES ON cms.web_publication TO csr;
GRANT SELECT, REFERENCES ON cms.tab TO csr;
GRANT SELECT, REFERENCES ON cms.form TO csr;
GRANT SELECT, REFERENCES ON cms.filter TO csr;
GRANT SELECT ON cms.item_id_seq TO csr;
GRANT SELECT, UPDATE ON cms.tab TO csr;
GRANT SELECT, REFERENCES ON cms.form TO csr;
GRANT SELECT, UPDATE, REFERENCES ON cms.tab_column TO csr;
GRANT SELECT, DELETE ON cms.flow_tab_column_cons TO csr;
GRANT SELECT, DELETE ON cms.tag TO csr;
GRANT SELECT ON cms.app_schema TO csr;

GRANT SELECT, UPDATE ON aspen2.application TO csr;
GRANT SELECT ON aspen2.filecache TO csr;
GRANT SELECT, DELETE ON aspen2.translation TO csr;
GRANT SELECT, UPDATE, DELETE ON aspen2.translated TO csr;
GRANT SELECT,REFERENCES ON aspen2.translation_set TO csr WITH GRANT OPTION;
GRANT SELECT ON aspen2.translation_set_include TO csr;
GRANT SELECT,REFERENCES ON aspen2.translation_application TO csr;
GRANT SELECT,REFERENCES ON aspen2.lang TO csr;
GRANT SELECT, REFERENCES ON aspen2.culture TO csr;

GRANT SELECT ON security.account_policy TO csr;
GRANT SELECT ON security.acc_policy_pwd_regexp TO csr;
GRANT SELECT ON security.acl TO csr;
GRANT SELECT ON security.act TO csr;
GRANT SELECT ON security.application TO csr WITH GRANT OPTION;
GRANT SELECT ON security.act_timeout TO csr;
GRANT SELECT ON security.attributes TO csr;
GRANT SELECT ON security.group_members TO csr WITH GRANT OPTION;
GRANT SELECT,REFERENCES ON security.group_table TO csr;
GRANT SELECT, INSERT, UPDATE ON security.home_page TO csr;
GRANT SELECT ON security.ip_rule TO csr;
GRANT SELECT ON security.ip_rule_entry TO csr;
GRANT SELECT, UPDATE, REFERENCES ON security.menu TO csr;
GRANT SELECT ON security.password_regexp TO csr;
GRANT SELECT ON security.permission_mapping TO csr;
GRANT SELECT ON security.permission_name TO csr;
GRANT SELECT, UPDATE, REFERENCES ON security.securable_object TO csr WITH GRANT OPTION;
GRANT SELECT ON security.securable_object_attributes TO csr;
GRANT SELECT ON security.securable_object_class TO csr;
GRANT SELECT ON security.securable_object_keyed_acl TO csr;
GRANT SELECT ON security.user_password_history TO csr;
GRANT SELECT ON security.user_certificates TO csr;
GRANT SELECT, REFERENCES ON security.user_table TO csr WITH GRANT OPTION;
GRANT SELECT, INSERT, REFERENCES ON security.web_resource TO csr;
GRANT SELECT ON security.website TO csr;
GRANT SELECT ON security.password_regexp TO csr;

REM NPSL.Security needs these -- inline SQL
grant SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.group_members TO csr;
grant SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.user_certificates TO csr;
grant SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.securable_object_attributes TO csr;
grant SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.acl TO csr;
grant SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.website TO csr;
grant SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.attributes TO csr;
grant SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.acc_policy_pwd_regexp TO csr;

GRANT SELECT, REFERENCES ON postcode.country TO csr WITH GRANT OPTION;
GRANT SELECT, REFERENCES ON postcode.region TO csr;
GRANT SELECT, REFERENCES ON postcode.city TO csr;
GRANT SELECT, REFERENCES ON postcode.city_full TO csr;
GRANT SELECT, REFERENCES ON POSTCODE.CONTINENT TO CSR;
GRANT SELECT, REFERENCES ON POSTCODE.COUNTRY_ALIAS TO CSR;
GRANT SELECT, REFERENCES ON POSTCODE.POSTCODE TO CSR;
GRANT SELECT, REFERENCES ON POSTCODE.POSTCODE_PLACE TO CSR;

GRANT SELECT, REFERENCES ON mail.account TO csr;
grant select, references on mail.mailbox to csr;
grant select on mail.mailbox_message to csr;
GRANT SELECT, REFERENCES ON mail.message TO csr;
grant select on mail.message_header to csr;
grant select on mail.message_address_field to csr;

GRANT SELECT, DELETE ON ACTIONS.AGGR_TASK_IND_DEPENDENCY TO CSR;
GRANT SELECT, DELETE ON ACTIONS.AGGR_TASK_PERIOD TO CSR;
GRANT SELECT, DELETE ON ACTIONS.AGGR_TASK_PERIOD_OVERRIDE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.AGGR_TASK_TASK_DEPENDENCY TO CSR;
GRANT SELECT, DELETE ON ACTIONS.ALLOW_TRANSITION TO CSR;
GRANT SELECT, DELETE ON ACTIONS.CUSTOMER_OPTIONS TO CSR;
GRANT SELECT, DELETE ON ACTIONS.FILE_UPLOAD TO CSR;
GRANT SELECT, DELETE ON ACTIONS.FILE_UPLOAD_GROUP TO CSR;
GRANT SELECT, DELETE ON ACTIONS.FILE_UPLOAD_GROUP_MEMBER TO CSR;
GRANT SELECT, DELETE ON ACTIONS.IND_TEMPLATE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.IND_TEMPLATE_GROUP TO CSR;
GRANT SELECT, DELETE ON ACTIONS.INITIATIVE_EXTRA_INFO TO CSR;
GRANT SELECT, DELETE ON ACTIONS.INITIATIVE_PROJECT_TEAM TO CSR;
GRANT SELECT, DELETE ON ACTIONS.INITIATIVE_SPONSOR TO CSR;
GRANT SELECT, DELETE ON ACTIONS.PROJECT TO CSR;
GRANT SELECT, DELETE ON ACTIONS.PERIODIC_REPORT_TEMPLATE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.PROJECT_IND_TEMPLATE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.PROJECT_IND_TEMPLATE_INSTANCE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.PROJECT_REGION_ROLE_MEMBER TO CSR;
GRANT SELECT, DELETE ON ACTIONS.PROJECT_ROLE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.PROJECT_ROLE_MEMBER TO CSR;
GRANT SELECT, DELETE ON ACTIONS.PROJECT_TAG_GROUP TO CSR;
GRANT SELECT, DELETE ON ACTIONS.PROJECT_TASK_PERIOD_STATUS TO CSR;
GRANT SELECT, DELETE ON ACTIONS.PROJECT_TASK_STATUS TO CSR;
GRANT SELECT, DELETE ON ACTIONS.ROLE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.ROOT_IND_TEMPLATE_INSTANCE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.SCRIPT TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TAG TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TAG_GROUP TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TAG_GROUP_MEMBER TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_BUDGET_HISTORY TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_BUDGET_PERIOD TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_COMMENT TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_FILE_UPLOAD TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_INDICATOR TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_IND_DEPENDENCY TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_IND_TEMPLATE_INSTANCE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_INSTANCE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_PERIOD TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_PERIOD_FILE_UPLOAD TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_PERIOD_OVERRIDE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_PERIOD_STATUS TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_RECALC_JOB TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_RECALC_REGION TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_REGION TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_ROLE_MEMBER TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_STATUS TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_STATUS_ROLE TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_STATUS_TRANSITION TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_STATUS_HISTORY TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_TAG TO CSR;
GRANT SELECT, DELETE ON ACTIONS.TASK_TASK_DEPENDENCY TO CSR;
GRANT SELECT, DELETE ON ACTIONS.SCENARIO_FILTER TO CSR;
GRANT SELECT, DELETE ON ACTIONS.SCENARIO_FILTER_STATUS TO CSR;
GRANT SELECT, DELETE ON ACTIONS.RECKONER_TAG_GROUP TO CSR;
GRANT SELECT, DELETE ON ACTIONS.RECKONER_TAG TO CSR;

REM more grants to csr
GRANT SELECT, REFERENCES ON actions.project TO csr;
GRANT SELECT, REFERENCES ON actions.project_tag_group TO csr;
GRANT SELECT, DELETE, INSERT, REFERENCES ON actions.project_region_role_member TO csr;
GRANT SELECT, REFERENCES ON actions.task TO csr;
GRANT SELECT, REFERENCES ON actions.task_tag TO csr;
GRANT SELECT, REFERENCES ON actions.tag TO csr;
GRANT SELECT, REFERENCES ON actions.tag_group_member TO csr;

REM Granting deletes to CSR for cleanup on app deletion
grant select, delete on supplier.alert_batch to csr;
grant select, delete on supplier.all_company to csr;
grant select, delete on supplier.all_procurer_supplier to csr;
grant select, delete on supplier.all_product to csr;
grant select, delete on supplier.all_product_questionnaire to csr;
grant select, delete on supplier.chain_questionnaire to csr;
grant select, delete on supplier.company_questionnaire_response to csr;
grant select, delete on supplier.company_user to csr;
grant select, delete on supplier.contact to csr;
grant select, delete on supplier.customer_options to csr;
grant select, delete on supplier.customer_period to csr;
grant select, delete on supplier.gt_product_user to csr;
grant select, delete on supplier.invite to csr;
grant select, delete on supplier.invite_questionnaire to csr;
grant select, delete on supplier.message to csr;
grant select, delete on supplier.message_contact to csr;
grant select, delete on supplier.message_procurer_supplier to csr;
grant select, delete on supplier.message_questionnaire to csr;
grant select, delete on supplier.message_user to csr;
grant select, delete on supplier.product_revision to csr;
grant select, delete on supplier.product_sales_volume to csr;
grant select, delete on supplier.product_questionnaire_group to csr;
grant select, delete on supplier.product_part to csr;
grant select, delete on supplier.product_tag to csr;
grant select, delete on supplier.questionnaire_group to csr;
grant select, delete on supplier.questionnaire_group_membership to csr;
grant select, delete on supplier.questionnaire_request to csr;
grant select, delete on supplier.tag_group to csr;

DECLARE
	PROCEDURE AddDeleteGrant(
		in_schema				varchar2,
		in_table				varchar2
	) AS
	BEGIN

		DECLARE
			v_count number;
			v_sql varchar2(2000);
		BEGIN

			v_sql := 'SELECT count(*) from SYS.all_tables where lower(table_name) = '''||in_table ||''' and lower(owner) = '''||in_schema||'''';
			EXECUTE IMMEDIATE v_sql INTO v_count;
			IF v_count = 1 THEN
				EXECUTE IMMEDIATE 'GRANT SELECT, DELETE ON ' || in_schema || '.' || in_table || ' to csr';
			END IF;

		END;
	END;
BEGIN
	AddDeleteGrant('supplier', 'product_revision_tag');
	AddDeleteGrant('supplier', 'gt_formulation_answers');
	AddDeleteGrant('supplier', 'gt_fa_wsr');
	AddDeleteGrant('supplier', 'gt_fa_anc_mat');
	AddDeleteGrant('supplier', 'gt_fa_haz_chem');
	AddDeleteGrant('supplier', 'gt_fa_palm_ind');
	AddDeleteGrant('supplier', 'gt_fa_endangered_sp');
	AddDeleteGrant('supplier', 'gt_packaging_answers');
	AddDeleteGrant('supplier', 'gt_pack_item');
	AddDeleteGrant('supplier', 'gt_product_answers');
	AddDeleteGrant('supplier', 'gt_link_product');
	AddDeleteGrant('supplier', 'gt_country_sold_in');
	AddDeleteGrant('supplier', 'gt_profile');
	AddDeleteGrant('supplier', 'gt_scores');
	AddDeleteGrant('supplier', 'gt_supplier_answers');
	AddDeleteGrant('supplier', 'gt_transport_answers');
	AddDeleteGrant('supplier', 'gt_country_made_in');
	AddDeleteGrant('supplier', 'gt_scores_combined');
	AddDeleteGrant('supplier', 'gt_pdesign_answers');
	AddDeleteGrant('supplier', 'gt_pda_material_item');
	AddDeleteGrant('supplier', 'gt_pda_hc_item');
	AddDeleteGrant('supplier', 'gt_pda_anc_mat');
	AddDeleteGrant('supplier', 'gt_pda_endangered_sp');
	AddDeleteGrant('supplier', 'gt_pda_main_power');
	AddDeleteGrant('supplier', 'gt_pda_palm_ind');
	AddDeleteGrant('supplier', 'gt_pda_battery');
	AddDeleteGrant('supplier', 'gt_trans_item');
	AddDeleteGrant('supplier', 'gt_food_answers');
	AddDeleteGrant('supplier', 'gt_fd_answer_scheme');
	AddDeleteGrant('supplier', 'gt_fd_endangered_sp');
	AddDeleteGrant('supplier', 'gt_fd_ingredient');
	AddDeleteGrant('supplier', 'gt_fd_palm_ind');
	AddDeleteGrant('supplier', 'gt_food_anc_mat');
	AddDeleteGrant('supplier', 'gt_food_sa_q');
	AddDeleteGrant('supplier', 'supplier_answers');
	AddDeleteGrant('supplier', 'supplier_answers_wood');
	AddDeleteGrant('supplier', 'fsc_member');
	AddDeleteGrant('supplier', 'gt_target_scores_log');
END;
/



grant select, references on chain.invitation to csr;
grant select, references on chain.questionnaire to csr;
grant select, references on chain.questionnaire_type to csr;
grant select, references on chain.company to csr;
grant select, references on chain.company to csr;
grant select, references on chain.customer_options to csr;
grant select, references on chain.invitation to csr;
grant select, references on chain.chain_user to csr;
grant select, references on chain.company_metric to csr;
grant select, references on chain.filter to csr;
GRANT SELECT, INSERT, DELETE, UPDATE ON chain.filter_value TO csr;
GRANT SELECT, INSERT, DELETE, UPDATE ON chain.filter_field TO csr;
grant select, references on chain.saved_filter to csr;
grant select, references on chain.saved_filter_aggregation_type to csr;
GRANT SELECT, UPDATE, DELETE ON chain.saved_filter_region TO csr;
grant select, references on chain.saved_filter_alert to csr;
grant select, UPDATE, DELETE, references on chain.saved_filter_alert_subscriptn to csr;
GRANT SELECT ON chain.filter_item_config TO csr;
grant select on chain.task to csr;
grant select on chain.task_type to csr;
grant references on chain.newsflash to csr;
grant select on chain.sector to csr;
grant select on chain.filter_type to csr;
grant select on chain.aggregate_type to csr;
grant update, delete on chain.chain_user to csr;
grant select, delete on chain.customer_options to csr;
grant select, delete on chain.task_scheme to csr;
grant select, delete on chain.alert_entry_template to csr;
grant select, delete on chain.company to csr;
grant select, delete on chain.applied_company_capability to csr;
grant select, delete on chain.product_code_type to csr;
grant select, delete on chain.company_metric_type to csr;
grant select, delete on chain.task_type to csr;
grant select, delete on chain.group_capability_override to csr;
grant select, delete on chain.questionnaire_type to csr;
grant select, delete on chain.card_group_card to csr;
GRANT SELECT ON chain.tt_filter_ind_val TO csr;
GRANT SELECT ON chain.filter_page_ind TO csr;
GRANT SELECT ON chain.filter_page_ind_interval TO csr;
GRANT SELECT ON chain.filter_page_cms_table TO csr;
GRANT SELECT ON chain.tt_filter_id TO csr;
grant select on chain.customer_aggregate_type to csr;
grant select, insert, update on chain.customer_filter_column to CSR;
grant select, insert, update on chain.customer_filter_item to CSR;
grant select, insert, update on chain.cust_filt_item_agg_type to CSR;
grant select, insert, update on chain.capability_flow_capability to csr;
grant select, insert, update on chain.company_type_score_calc to CSR;
grant select, insert, update on chain.comp_type_score_calc_comp_type to CSR;
grant select on chain.customer_filter_column_id_seq to CSR;
grant select on chain.customer_filter_item_id_seq to CSR;
grant select on chain.cust_filt_item_agg_type_id_seq to CSR;

-- utils\enableSurveys.sql requires this
grant insert on chain.customer_options to csr;
grant execute on chain.T_STRING_LIST to csr;

grant select, references on donations.recipient to csr;
grant references on chain.card_group to csr;


REM Granting deletes to CSR for cleanup on app deletion
GRANT SELECT, DELETE ON DONATIONS.BUDGET TO CSR;
GRANT SELECT, DELETE ON DONATIONS.BUDGET_CONSTANT TO CSR;
GRANT SELECT, DELETE ON DONATIONS.CONSTANT TO CSR;
GRANT SELECT, DELETE ON DONATIONS.CUSTOMER_FILTER_FLAG TO CSR;
GRANT SELECT, DELETE ON DONATIONS.CUSTOMER_OPTIONS TO CSR;
GRANT SELECT, DELETE ON DONATIONS.CUSTOM_FIELD TO CSR;
GRANT SELECT, DELETE ON DONATIONS.CUSTOM_FIELD_DEPENDENCY TO CSR;
GRANT SELECT, DELETE ON DONATIONS.DONATION TO CSR;
GRANT SELECT, DELETE ON DONATIONS.DONATION_DOC TO CSR;
GRANT SELECT, DELETE ON DONATIONS.DONATION_STATUS TO CSR;
GRANT SELECT, DELETE ON DONATIONS.DONATION_TAG TO CSR;
GRANT SELECT, DELETE ON DONATIONS.FC_BUDGET  TO CSR;
GRANT SELECT, DELETE ON DONATIONS.FC_DONATION TO CSR;
GRANT SELECT, DELETE ON DONATIONS.FC_TAG TO CSR;
GRANT SELECT, DELETE ON DONATIONS.FC_UPLOAD TO CSR;
GRANT SELECT, DELETE ON DONATIONS.FILTER TO CSR;
GRANT SELECT, DELETE ON DONATIONS.FUNDING_COMMITMENT  TO CSR;
GRANT SELECT, DELETE ON DONATIONS.LETTER_BODY_REGION_GROUP TO CSR;
GRANT SELECT, DELETE ON DONATIONS.LETTER_BODY_TEXT TO CSR;
GRANT SELECT, DELETE ON DONATIONS.LETTER_TEMPLATE TO CSR;
GRANT SELECT, DELETE ON DONATIONS.RECIPIENT TO CSR;
GRANT SELECT, DELETE ON DONATIONS.RECIPIENT_TAG TO CSR;
GRANT SELECT, DELETE ON DONATIONS.RECIPIENT_TAG_GROUP TO CSR;
GRANT SELECT, DELETE ON DONATIONS.REGION_FILTER_TAG_GROUP TO CSR;
GRANT SELECT, DELETE ON DONATIONS.REGION_GROUP TO CSR;
GRANT SELECT, DELETE ON DONATIONS.REGION_GROUP_MEMBER TO CSR;
GRANT SELECT, DELETE ON DONATIONS.REGION_GROUP_RECIPIENT TO CSR;
GRANT SELECT, DELETE ON DONATIONS.SCHEME TO CSR;
GRANT SELECT, DELETE ON DONATIONS.SCHEME_DONATION_STATUS TO CSR;
GRANT SELECT, DELETE ON DONATIONS.SCHEME_FIELD TO CSR;
GRANT SELECT, DELETE ON DONATIONS.SCHEME_TAG_GROUP TO CSR;
GRANT SELECT, DELETE ON DONATIONS.TAG TO CSR;
GRANT SELECT, DELETE ON DONATIONS.TAG_GROUP TO CSR;
GRANT SELECT, DELETE ON DONATIONS.TAG_GROUP_MEMBER TO CSR;
GRANT SELECT, DELETE ON DONATIONS.TRANSITION TO CSR;
GRANT SELECT, DELETE ON DONATIONS.USER_FIELDSET TO CSR;
GRANT SELECT, DELETE ON DONATIONS.USER_FIELDSET_FIELD TO CSR;

/* moved from csrimp object_grants*/
grant select, insert, update on chain.capability to CSR;
grant select, insert, update on chain.customer_options to CSR;
grant select, insert, update on chain.company to CSR;
grant select, insert, update on chain.applied_company_capability to CSR;
grant select, insert, update on chain.chain_user to CSR;
grant select, insert, update on chain.company_group to CSR;
grant select, insert, update on chain.company_type_relationship to CSR;
grant select, insert, update on chain.company_type_capability to CSR;
grant select, insert, update on chain.group_capability_override to CSR;
grant select, insert, update on chain.implementation to CSR;
grant select, insert, update on chain.sector to CSR;
grant select, insert, update on chain.tertiary_relationships to CSR;
grant select, insert, update on chain.company_type_role to CSR;
grant select, references, insert, update, delete on chain.supplier_relationship to CSR;
grant select, insert, update on chain.supplier_follower to CSR;
grant select, insert, update on chain.card_group_progression to CSR;
grant select, insert, update on chain.card_group_card to CSR;
grant select, insert, update on chain.card_init_param to CSR;
grant select on chain.risk_level to csr;
grant select on chain.country_risk_level to csr;
grant select on chain.card to csr;

grant select, insert, update on chain.project to csr;
grant select, insert, update on chain.activity_type to CSR;
grant select, insert, update on chain.outcome_type to CSR;
grant select, insert, update on chain.activity_outcome_type to CSR;
grant select, insert, update on chain.activity to CSR;
grant select, insert, update on chain.activity_log to CSR;
grant select, insert, update on chain.activity_log_file to CSR;
grant select, insert, update on chain.activity_type_tag_group to CSR;
grant select, insert, update on chain.activity_involvement to CSR;
grant select, insert, update on chain.activity_tag to CSR;
grant select, insert, update on chain.activity_type_action to CSR;
grant select, insert, update on chain.activity_outcome_type_action to CSR;
grant select, insert, update on chain.activity_type_alert to CSR;
grant select, insert, update on chain.activity_type_alert_role to CSR;
grant select, insert, update on chain.activity_type_default_user to CSR;
grant select, insert, update on chain.product_type to CSR;
grant select, insert, update on chain.product_type_tr to CSR;
grant select, insert, update on chain.product_type_tag to CSR;
grant select, insert, update on chain.company_product_type to CSR;

grant select on chain.capability_id_seq to CSR;
grant select on chain.group_capability_id_seq to CSR;
grant select on chain.company_type_id_seq to CSR;

grant select on chain.project_id_seq to csr;
grant select on chain.activity_id_seq to CSR;
grant select on chain.activity_type_id_seq to CSR;
grant select on chain.outcome_type_id_seq to CSR;
grant select on chain.activity_log_id_seq to CSR;
grant select on chain.activity_log_file_id_seq to CSR;
grant select on chain.activity_type_action_id_seq to CSR;
grant select on chain.activity_outcm_typ_actn_id_seq to CSR;

grant select, insert, update on chain.alert_partial_template to CSR;
grant select, insert, update on chain.alert_partial_template_param to CSR;
grant select, insert, update on chain.amount_unit to CSR;
grant select, insert, update on chain.applied_company_capability to CSR;
grant select, insert, update on chain.audit_request to CSR;
grant select, insert, update on chain.audit_request_alert to CSR;
grant select, insert, update on chain.business_unit to CSR;
grant select, insert, update on chain.business_unit_member to CSR;
grant select, insert, update on chain.business_unit_supplier to CSR;
grant select, insert, update on chain.card to CSR;
grant select, insert, update on chain.chain_user_email_address_log to CSR;
grant select, insert, update on chain.company_cc_email to CSR;
grant select, insert, update on chain.company_header to CSR;
grant select, insert, update on chain.company_metric_type to CSR;
grant select, insert, update on chain.company_metric to CSR;
grant select, insert, update, delete on chain.company_reference to CSR;
grant select, insert, update on chain.company_tab to CSR;
grant select, insert, update on chain.company_tab_related_co_type to CSR;
grant select, insert, update on chain.company_tab_company_type_role to CSR;
grant select, insert, update on chain.company_tag_group to CSR;
grant select, insert, update on chain.component_type to CSR;
grant select, insert, update on chain.component_type_containment to CSR;
grant select, insert, update on chain.component to CSR;
grant select, insert, update on chain.file_upload to CSR;
grant select, insert, update on chain.component_document to CSR;
grant select, insert, update on chain.component_source to CSR;
grant select, insert, update on chain.component_tag to CSR;
grant select, insert, update on chain.compound_filter to CSR;
grant select, insert, update on chain.customer_alert_entry_template to CSR;
grant select, insert, update on chain.customer_alert_entry_type to CSR;
grant select, insert, update on chain.default_product_code_type to CSR;
grant select, insert, update on chain.default_supp_rel_code_label to CSR;
grant select, insert, update on chain.email_stub to CSR;
grant select, insert, update on chain.file_group to CSR;
grant select, insert, update on chain.file_group_file to CSR;
grant select, insert, update on chain.filter to CSR;
grant select, insert, update on chain.filter_field to CSR;
grant select, insert, update on chain.filter_value to CSR;
grant select, insert, update on chain.filtersupplierreportlinks to CSR;
grant select, insert, update on chain.flow_filter to CSR;
grant select, insert, update on chain.invitation to CSR;
grant select, insert, update on chain.invitation_user_tpl to CSR;
grant select, insert, update on chain.message_definition to CSR;
grant select, insert, update on chain.message_param to CSR;
grant select, insert, update on chain.questionnaire_group to CSR;
grant select, insert, update on chain.questionnaire_type to CSR;
grant select, insert, update on chain.flow_questionnaire_type to CSR;
grant select, insert, update on chain.invitation_qnr_type_component to CSR;
grant select, insert, update on chain.message to CSR;
grant select, insert, update on chain.alert_entry to CSR;
grant select, insert, update on chain.alert_entry_param to CSR;
grant select, insert, update on chain.invitation_qnr_type to CSR;
grant select, insert, update on chain.message_recipient to CSR;
grant select, insert, update on chain.message_refresh_log to CSR;
grant select, insert, update on chain.newsflash to CSR;
grant select, insert, update on chain.newsflash_company to CSR;
grant select, insert, update on chain.newsflash_user_settings to CSR;
grant select, insert, update on chain.product to CSR;
grant select, insert, update on chain.product_code_type to CSR;
grant select, insert, update on chain.product_metric_type to CSR;
grant select, insert, update on chain.product_metric to CSR;
grant select, insert, update on chain.product_metric_product_type to CSR;
grant select, insert, update on chain.product_revision to CSR;
grant select, insert, update on chain.purchase_channel to CSR;
grant select, insert, update on chain.purchased_component to CSR;
grant select, insert, update on chain.purchase to CSR;
grant select, insert, update on chain.purchase_tag to CSR;
grant select, insert, update on chain.purchaser_follower to CSR;
grant select, insert, update on chain.qnnaire_share_alert_log to CSR;
grant select, insert, update on chain.qnr_action_security_mask to CSR;
grant select, insert, update on chain.questionnaire to CSR;
grant select, insert, update on chain.qnr_share_log_entry to CSR;
grant select, insert, update on chain.qnr_status_log_entry to CSR;
grant select, insert, update on chain.questionnaire_expiry_alert to CSR;
grant select, insert, update on chain.questionnaire_invitation to CSR;
grant select, insert, update on chain.questionnaire_metric_type to CSR;
grant select, insert, update on chain.questionnaire_metric to CSR;
grant select, insert, update on chain.questionnaire_share to CSR;
grant select, insert, update on chain.questionnaire_user to CSR;
grant select, insert, update on chain.questionnaire_user_action to CSR;
grant select, insert, update on chain.recipient to CSR;
grant select, insert, update, delete on chain.reference to CSR;
grant select, insert, update, delete on chain.reference_capability to CSR;
grant select on chain.reference_company_type to CSR;
grant select, insert, update on chain.review_alert to CSR;
grant select, insert, update on chain.saved_filter to CSR;
grant select on chain.saved_filter_column to csr;
grant select, insert, update on chain.scheduled_alert to CSR;
grant select, insert, update on chain.supplier_audit to CSR;
grant select, insert, update on chain.task to CSR;
grant select, insert, update on chain.task_action_trigger to CSR;
grant select, insert, update on chain.task_entry to CSR;
grant select, insert, update on chain.task_entry_date to CSR;
grant select, insert, update on chain.task_entry_file to CSR;
grant select, insert, update on chain.task_entry_note to CSR;
grant select, insert, update on chain.task_scheme to CSR;
grant select, insert, update on chain.task_type to CSR;
grant select, insert, update on chain.task_invitation_qnr_type to CSR;
grant select, insert, update on chain.ucd_logon to CSR;
grant select, insert, update on chain.uninvited_supplier to CSR;
grant select, insert, update on chain.url_overrides to CSR;
grant select, insert, update on chain.user_alert_entry_type to CSR;
grant select, insert, update on chain.user_message_log to CSR;
grant select, insert, update on chain.validated_purchased_component to CSR;
grant select, insert, update on chain.worksheet_file_upload to CSR;
grant select, insert, update on chain.default_message_definition to CSR;
grant select, insert, update on chain.message_definition_lookup to CSR;
grant select, insert, update on chain.filter_type to CSR;
grant select, insert, update on chain.group_capability to CSR;
grant select, insert, update on chain.card_progression_action to CSR;
grant select, insert, update on chain.business_relationship_type to CSR;
grant select, insert, update on chain.business_relationship_tier to CSR;
grant select, insert, update on chain.business_rel_tier_company_type to CSR;
grant select, insert, update on chain.business_relationship to CSR;
grant select on chain.business_relationship_period to CSR;
grant select, insert, update on chain.business_relationship_company to CSR;
grant select, insert, update on chain.import_source to CSR;
grant select, insert, update on chain.dedupe_mapping to CSR;
grant select, insert, update on chain.dedupe_rule to CSR;
grant select, insert, update on chain.dedupe_staging_link to CSR;
grant select, insert, update on chain.dedupe_rule_set to CSR;
grant select, insert, update on chain.dedupe_preproc_comp to CSR;
grant select, insert, update on chain.dedupe_preproc_rule to CSR;
grant select, insert, update on chain.dedupe_pp_field_cntry to CSR;
grant select on chain.dedupe_pp_alt_comp_name to csr;
grant select on chain.dedupe_rule_type to CSR;
grant select on chain.dedupe_match_type to CSR;
grant select, insert on chain.higg to csr;
grant select on chain.higg_config to csr;
grant select on chain.higg_module to csr;
grant select, insert on chain.higg_module_tag_group to csr;
grant select on chain.higg_config_module to csr;
grant select on chain.higg_response to csr;
grant select on chain.higg_section_score to csr;
grant select on chain.higg_sub_section_score to csr;
grant select on chain.higg_question_response to csr;
grant select on chain.higg_profile to csr;
grant select on chain.higg_question_survey to csr;
grant select on chain.higg_question_option_survey to csr;
grant select, delete on chain.higg_config_profile to csr;
grant select on chain.higg_question_opt_conversion to csr;
grant select on chain.customer_grid_extension to CSR;
grant select, insert, update on chain.product_header to CSR;
grant select, insert, update on chain.product_header_product_type to CSR;
grant select, insert, update on chain.product_tab to CSR;
grant select, insert, update on chain.product_tab_product_type to CSR;
grant select, insert, update on chain.product_supplier_tab to CSR;
grant select, insert, update on chain.prod_supp_tab_product_type to CSR;
grant select on chain.grid_extension to csr;
grant select, insert, update, delete on chain.temp_grid_extension_map to csr;
grant select, insert, update on chain.product_company_alert to CSR;

grant select on chain.alert_entry_id_seq to CSR;
grant select on chain.card_id_seq to CSR;
grant select on chain.message_id_seq to CSR;
grant select on chain.scheduled_alert_id_seq to CSR;
grant select on chain.audit_request_id_seq to CSR;
grant select on chain.company_header_id_seq to CSR;
grant select on chain.company_tab_id_seq to CSR;
grant select on chain.component_id_seq to CSR;
grant select on chain.compound_filter_id_seq to CSR;
grant select on chain.file_group_id_seq to CSR;
grant select on chain.file_group_file_id_seq to CSR;
grant select on chain.filter_id_seq to CSR;
grant select on chain.filter_type_id_seq to CSR;
grant select on chain.filter_field_id_seq to CSR;
grant select on chain.filter_value_id_seq to CSR;
grant select on chain.questionnaire_type_id_seq to CSR;
grant select on chain.invitation_id_seq to CSR;
grant select on chain.message_definition_id_seq to CSR;
grant select on chain.questionnaire_id_seq to CSR;
grant select on chain.recipient_id_seq to CSR;
grant select on chain.newsflash_id_seq to CSR;
grant select on chain.product_id_seq to CSR;
grant select on chain.purchase_id_seq to CSR;
grant select on chain.questionnaire_share_id_seq to CSR;
grant select on chain.task_id_seq to CSR;
grant select on chain.task_type_id_seq to CSR;
grant select on chain.task_entry_id_seq to CSR;
grant select on chain.business_rel_type_id_seq to CSR;
grant select on chain.business_rel_tier_id_seq to CSR;
grant select on chain.business_relationship_id_seq to CSR;
grant select on chain.import_source_id_seq to CSR;
grant select on chain.dedupe_mapping_id_seq to CSR;
grant select on chain.dedupe_rule_id_seq to CSR;
grant select on chain.dedupe_merge_log_id_seq to CSR;
grant select on chain.dedupe_staging_link_id_seq to CSR;
grant select, insert, update on chain.dedupe_processed_record to CSR;
grant select, insert, update on chain.dedupe_match to CSR;
grant select, insert, update on chain.dedupe_merge_log to CSR;
grant select on chain.dedupe_processed_record_id_seq to CSR;
grant select on chain.dedupe_match_id_seq to CSR;
grant select on chain.dedupe_preproc_rule_id_seq to CSR;
grant select on chain.aggregate_type_config to csr;
grant select on chain.certification_type to csr;
grant select on chain.cert_type_audit_type to csr;
GRANT SELECT ON chain.dedupe_sub TO csr;
grant select on chain.product_header_id_seq to CSR;
grant select on chain.product_tab_id_seq to CSR;
grant select on chain.supplier_rel_score_id_seq to CSR;
grant select on chain.company_type_role_id_seq to CSR;
grant select on chain.comp_tab_comp_type_role_id_seq to CSR;

grant select, insert on chain.product_header to csr;
grant select, insert on chain.product_tab to csr;
grant select on chain.pend_company_suggested_match to csr;
grant select on chain.pending_company_tag to csr;
grant select, insert, update on chain.filter_page_column to csr;
grant select, insert on chain.dd_customer_blcklst_email to csr;
grant select on chain.dd_def_blcklst_email to csr;

grant select, insert, update on chem.chem_options to CSR;
grant select, insert, update on chem.cas to CSR;
grant select, insert, update on chem.cas_group to CSR;
grant select, insert, update on chem.cas_group_member to CSR;
grant select, insert, update on chem.cas_restricted to CSR;
grant select, insert, update on chem.classification to CSR;
grant select, insert, update on chem.manufacturer to CSR;
grant select, insert, update on chem.substance to CSR;
grant select, insert, update on chem.substance_cas to CSR;
grant select, insert, update on chem.usage to CSR;
grant select, insert, update on chem.substance_region to CSR;
grant select, insert, update on chem.substance_region_process to CSR;
grant select, insert, update on chem.process_cas_default to CSR;
grant select, insert, update on chem.substance_process_use_change to CSR;
grant select, insert, update on chem.subst_process_cas_dest_change to CSR;
grant select, insert, update on chem.substance_audit_log to CSR;
grant select, insert, update on chem.substance_file to CSR;
grant select, insert, update on chem.substance_process_use to CSR;
grant select, insert, update on chem.substance_process_cas_dest to CSR;
grant select, insert, update on chem.substance_process_use_file to CSR;
grant select, insert, update on chem.usage_audit_log to CSR;

grant select on chem.cas_group_id_seq to CSR;
grant select on chem.classification_id_seq to CSR;
grant select on chem.manufacturer_id_seq to CSR;
grant select on chem.substance_id_seq to CSR;
grant select on chem.subst_rgn_proc_process_id_seq to CSR;
grant select on chem.usage_id_seq to CSR;
grant select on chem.subst_proc_use_change_id_seq to CSR;
grant select on chem.subst_proc_cas_dest_chg_id_seq to CSR;
grant select on chem.sub_audit_log_id_seq to CSR;
grant select on chem.substance_file_id_seq to CSR;
grant select on chem.substance_process_use_id_seq to CSR;
grant select on chem.subst_proc_use_file_id_seq to CSR;
grant select on chem.usage_audit_log_id_seq to CSR;
/* END of moved from csrimp object_grants*/

GRANT SELECT, DELETE ON chem.substance_process_use_file to csr;
GRANT SELECT, DELETE ON chem.subst_process_cas_dest_change to csr;
GRANT SELECT, DELETE ON chem.process_cas_default to csr;
GRANT SELECT, DELETE ON chem.substance_process_cas_dest to csr;
GRANT SELECT, DELETE ON chem.substance_process_use to csr;
GRANT SELECT, DELETE ON chem.substance_process_use_change to csr;
GRANT SELECT, DELETE ON chem.substance_audit_log to csr;
GRANT SELECT, DELETE ON chem.substance_cas to csr;
GRANT SELECT, DELETE ON chem.substance_file to csr;
GRANT SELECT, DELETE ON chem.substance_region_process to csr;
GRANT SELECT, DELETE ON chem.usage_audit_log to csr;
GRANT SELECT, DELETE ON chem.substance to csr;
GRANT SELECT, DELETE ON chem.substance_region to csr;
GRANT SELECT, DELETE ON chem.cas to csr;
GRANT SELECT, DELETE ON chem.chem_options to csr;
GRANT SELECT, DELETE ON chem.cas_restricted to csr;
GRANT SELECT, DELETE ON chem.cas_group_member to csr;

GRANT SELECT ON CSR.IMAGE_UPLOAD_PORTLET_SEQ to csr;

grant select on campaigns.campaign to csr;
grant select on campaigns.campaign_region to csr;
grant select on campaigns.campaign_region_response to csr;
grant execute on campaigns.t_campaign_table to csr;

-- UD-18840
GRANT CREATE JOB TO CSR;

grant select on cms.sys_schema to csr;
