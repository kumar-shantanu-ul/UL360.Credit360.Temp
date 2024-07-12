CREATE OR REPLACE PACKAGE BODY CHAIN.chain_pkg
IS
/********************************************************

	DO NOT ADD METHODS HERE - THIS PKG BODY SHOULD 
	BE KEPT EMPTY TO HELP PREVENT BREAKS IN UPDATE
	SCRIPTS. THE PKG HEADER SHOULD ONLY CONTAIN
	CHAIN CONSTANTS, AND NOT REFERENCE TABLES OR
	OTHER SCHEMAS (except security).

********************************************************/
-- TEMP: back in until scheduler gets fixed up
PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid
		  FROM customer_options;
END;

-- literally deletes everything (called primary by csr_data_pkg)
PROCEDURE DeleteChainData(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_reduce_contention			IN	NUMBER	DEFAULT 0,
	in_debug_log_deletes			IN	NUMBER	DEFAULT 0
)
AS
	v_app_sid						security_pkg.T_SID_ID := in_app_sid;

	PROCEDURE CommitAndLogIfRequired(
		in_table_name					IN	VARCHAR2
	)
	AS
	BEGIN
		IF in_reduce_contention = 1 THEN
			COMMIT;
		END IF;
		IF in_debug_log_deletes = 1 THEN
			security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - Deleted ' || in_table_name);
		END IF;

	END;


	-- helper that is used for all simple deletes
	PROCEDURE DeleteFromIfTableExists(
		in_table_name					IN	VARCHAR2,
		in_commit_after_delete			IN	NUMBER,
		in_log_deletes					IN	NUMBER,
		in_loop_count					IN	NUMBER
	)
	AS
		v_row_count						NUMBER;
	BEGIN
		IF in_loop_count > 0 AND in_commit_after_delete = 1 THEN
			v_row_count := 0;
			LOOP
				EXECUTE IMMEDIATE 'DELETE FROM ' || in_table_name || ' WHERE ROWNUM <= '|| in_loop_count ||' AND app_sid = ' || v_app_sid;
				EXIT WHEN SQL%ROWCOUNT = 0;
				v_row_count := v_row_count + SQL%ROWCOUNT;
				COMMIT;
				IF in_log_deletes = 1 THEN
					security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - Deleted ' || in_table_name || ' - Rows: ' || v_row_count);
				END IF;
			END LOOP;

		ELSE
			EXECUTE IMMEDIATE 'DELETE FROM ' || in_table_name || ' WHERE app_sid = ' || v_app_sid;
			IF in_commit_after_delete = 1 THEN
				COMMIT;
			END IF;
			IF in_log_deletes = 1 THEN
				security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - Deleted ' || in_table_name);
			END IF;
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			-- ORA-00942: table or view does not exist
			IF SQLCODE != -942 THEN
				RAISE;
			END IF;
	END;

	-- helper that is used for all simple deletes
	PROCEDURE DeleteFromIfTableExists(
		in_table_name					IN	VARCHAR2
	)
	AS
	BEGIN
		DeleteFromIfTableExists(in_table_name => in_table_name, 
								in_commit_after_delete => in_reduce_contention, 
								in_log_deletes => in_debug_log_deletes, 
								in_loop_count => 0);
	END;

	-- helper that is used for all simple deletes
	PROCEDURE DeleteFromIfTableExists(
		in_table_name					IN	VARCHAR2,
		in_loop_count					IN	NUMBER
	)
	AS
	BEGIN
		DeleteFromIfTableExists(in_table_name => in_table_name, 
								in_commit_after_delete => in_reduce_contention, 
								in_log_deletes => in_debug_log_deletes, 
								in_loop_count => in_loop_count);
	END;

	-- helper that is used for all simple deletes
	PROCEDURE DeleteFromIfTableExists(
		in_table_name					IN	VARCHAR2,
		in_commit_after_delete			IN	NUMBER
	)
	AS
	BEGIN
		DeleteFromIfTableExists(in_table_name => in_table_name, 
								in_commit_after_delete => in_commit_after_delete, 
								in_log_deletes => in_debug_log_deletes, 
								in_loop_count => 0);
	END;


BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteChainData can only be run as BuiltIn/Administrator');
	END IF;
	
	chain.chain_link_pkg.NukeChain;

	DeleteFromIfTableExists(in_table_name => 'dedupe_pp_alt_comp_name');

	DeleteFromIfTableExists(in_table_name => 'dedupe_preproc_comp');

	DeleteFromIfTableExists(in_table_name => 'prod_supp_tab_product_type');

	DeleteFromIfTableExists(in_table_name => 'product_supplier_tab');

	DeleteFromIfTableExists(in_table_name => 'product_tab_product_type');

	DeleteFromIfTableExists(in_table_name => 'product_tab');

	DeleteFromIfTableExists(in_table_name => 'product_header_product_type');

	DeleteFromIfTableExists(in_table_name => 'product_header');

	DeleteFromIfTableExists(in_table_name => 'product_supplier');

	DeleteFromIfTableExists(in_table_name => 'company_product_tr');

	DeleteFromIfTableExists(in_table_name => 'company_product');

	DeleteFromIfTableExists(in_table_name => 'alt_company_name');

	DeleteFromIfTableExists(in_table_name => 'cert_type_audit_type');

	DeleteFromIfTableExists(in_table_name => 'certification_type');

	DeleteFromIfTableExists(in_table_name => 'higg_question_opt_conversion');

	DeleteFromIfTableExists(in_table_name => 'higg_config_profile');

	DeleteFromIfTableExists(in_table_name => 'higg_question_response');

	DeleteFromIfTableExists(in_table_name => 'higg_sub_section_score');

	DeleteFromIfTableExists(in_table_name => 'higg_section_score');

	DeleteFromIfTableExists(in_table_name => 'higg_response');

	DeleteFromIfTableExists(in_table_name => 'higg_profile');

	DeleteFromIfTableExists(in_table_name => 'higg_question_option_survey');

	DeleteFromIfTableExists(in_table_name => 'higg_question_survey');

	DeleteFromIfTableExists(in_table_name => 'higg_config_module');

	DeleteFromIfTableExists(in_table_name => 'higg_module_tag_group');

	DeleteFromIfTableExists(in_table_name => 'higg_config');

	DeleteFromIfTableExists(in_table_name => 'higg');

	DeleteFromIfTableExists(in_table_name => 'country_risk_level');

	DeleteFromIfTableExists(in_table_name => 'risk_level');

	DeleteFromIfTableExists(in_table_name => 'implementation');

	DeleteFromIfTableExists(in_table_name => 'applied_company_capability');

	DeleteFromIfTableExists(in_table_name => 'qnr_status_log_entry');

	DeleteFromIfTableExists(in_table_name => 'qnr_share_log_entry');

	DeleteFromIfTableExists(in_table_name => 'qnnaire_share_alert_log');

	DeleteFromIfTableExists(in_table_name => 'questionnaire_share');

	DeleteFromIfTableExists(in_table_name => 'questionnaire_metric');

	DeleteFromIfTableExists(in_table_name => 'questionnaire_invitation');

	DeleteFromIfTableExists(in_table_name => 'questionnaire_user_action');

	DeleteFromIfTableExists(in_table_name => 'questionnaire_user');

	DeleteFromIfTableExists(in_table_name => 'questionnaire');

	DeleteFromIfTableExists(in_table_name => 'company_cc_email');

	DeleteFromIfTableExists(in_table_name => 'company_metric');

	DeleteFromIfTableExists(in_table_name => 'invitation_qnr_type_component');

	DeleteFromIfTableExists(in_table_name => 'task_invitation_qnr_type');

	DeleteFromIfTableExists(in_table_name => 'invitation_qnr_type');

	DeleteFromIfTableExists(in_table_name => 'reset_password');
	
	UPDATE chain.message
	   SET re_invitation_id = NULL	   
	 WHERE re_invitation_id IS NOT NULL
	   AND app_sid = in_app_sid;

	DeleteFromIfTableExists(in_table_name => 'invitation');

	DeleteFromIfTableExists(in_table_name => 'invitation_batch');

	DeleteFromIfTableExists(in_table_name => 'task');

	DeleteFromIfTableExists(in_table_name => 'purchase_tag');

	DeleteFromIfTableExists(in_table_name => 'purchase');

	DeleteFromIfTableExists(in_table_name => 'purchase_channel');

	DeleteFromIfTableExists(in_table_name => 'validated_purchased_component');

	DeleteFromIfTableExists(in_table_name => 'purchased_component');

	DeleteFromIfTableExists(in_table_name => 'purchaser_follower');

	DeleteFromIfTableExists(in_table_name => 'supplier_follower');
	
	DeleteFromIfTableExists(in_table_name => 'supplier_relationship_source');

	DeleteFromIfTableExists(in_table_name => 'supplier_relationship_score');

	DeleteFromIfTableExists(in_table_name => 'supplier_relationship');

	DeleteFromIfTableExists(in_table_name => 'newsflash_user_settings');

	DeleteFromIfTableExists(in_table_name => 'newsflash_company');

	DeleteFromIfTableExists(in_table_name => 'product_code_type');

	DeleteFromIfTableExists(in_table_name => 'message_recipient');

	DeleteFromIfTableExists(in_table_name => 'recipient');

	DeleteFromIfTableExists(in_table_name => 'message_refresh_log');

	DeleteFromIfTableExists(in_table_name => 'user_message_log');

	DeleteFromIfTableExists(in_table_name => 'message');

	DeleteFromIfTableExists(in_table_name => 'message_param');

	DeleteFromIfTableExists(in_table_name => 'message_definition');

	DeleteFromIfTableExists(in_table_name => 'worksheet_file_upload');

	DeleteFromIfTableExists(in_table_name => 'file_group_file');

	DeleteFromIfTableExists(in_table_name => 'file_group');

	DeleteFromIfTableExists(in_table_name => 'component_document');

	DeleteFromIfTableExists(in_table_name => 'task_entry_file');

	DeleteFromIfTableExists(in_table_name => 'file_upload');

	DeleteFromIfTableExists(in_table_name => 'product_revision');

	DeleteFromIfTableExists(in_table_name => 'component_tag');

	DeleteFromIfTableExists(in_table_name => 'component');

	DeleteFromIfTableExists(in_table_name => 'component_type');

	DeleteFromIfTableExists(in_table_name => 'product');

	DeleteFromIfTableExists(in_table_name => 'company_product_type');

	DeleteFromIfTableExists(in_table_name => 'product_type_tag');

	DeleteFromIfTableExists(in_table_name => 'product_metric_val');

	DeleteFromIfTableExists(in_table_name => 'product_supplier_metric_val');

	DeleteFromIfTableExists(in_table_name => 'product_metric_product_type');

	DeleteFromIfTableExists(in_table_name => 'product_metric');

	DeleteFromIfTableExists(in_table_name => 'product_type');

	DeleteFromIfTableExists(in_table_name => 'activity_involvement');

	DeleteFromIfTableExists(in_table_name => 'activity_log_file');

	DeleteFromIfTableExists(in_table_name => 'activity_log');

	DeleteFromIfTableExists(in_table_name => 'activity_tag');

	DeleteFromIfTableExists(in_table_name => 'activity');

	DeleteFromIfTableExists(in_table_name => 'activity_outcome_type_action');

	DeleteFromIfTableExists(in_table_name => 'activity_outcome_type');

	DeleteFromIfTableExists(in_table_name => 'activity_type_action');

	DeleteFromIfTableExists(in_table_name => 'activity_type_alert_role');

	DeleteFromIfTableExists(in_table_name => 'activity_type_alert');

	DeleteFromIfTableExists(in_table_name => 'activity_type_default_user');

	DeleteFromIfTableExists(in_table_name => 'activity_type_tag_group');

	DeleteFromIfTableExists(in_table_name => 'activity_type');

	DeleteFromIfTableExists(in_table_name => 'uninvited_supplier');

	DeleteFromIfTableExists(in_table_name => 'card_group_progression');

	DeleteFromIfTableExists(in_table_name => 'card_group_card');

	DeleteFromIfTableExists(in_table_name => 'task_action_trigger');

	DeleteFromIfTableExists(in_table_name => 'task_type');

	DeleteFromIfTableExists(in_table_name => 'task_scheme');

	DeleteFromIfTableExists(in_table_name => 'group_capability_override');

	DeleteFromIfTableExists(in_table_name => 'qnr_action_security_mask');

	DeleteFromIfTableExists(in_table_name => 'flow_questionnaire_type');

	DeleteFromIfTableExists(in_table_name => 'questionnaire_type');

	DeleteFromIfTableExists(in_table_name => 'audit_request_alert');

	DeleteFromIfTableExists(in_table_name => 'audit_request');

	DeleteFromIfTableExists(in_table_name => 'supplier_audit');

	DeleteFromIfTableExists(in_table_name => 'chain_user_email_address_log');

	DeleteFromIfTableExists(in_table_name => 'business_unit_member');

	DeleteFromIfTableExists(in_table_name => 'invitation_user_tpl');

	DeleteFromIfTableExists(in_table_name => 'chain_user');

	DeleteFromIfTableExists(in_table_name => 'company_tag_group');

	DeleteFromIfTableExists(in_table_name => 'company_group');

	DeleteFromIfTableExists(in_table_name => 'company_reference');   

	DeleteFromIfTableExists(in_table_name => 'saved_filter_sent_alert');

	DeleteFromIfTableExists(in_table_name => 'saved_filter_alert_subscriptn');

	DeleteFromIfTableExists(in_table_name => 'saved_filter_alert');

	DeleteFromIfTableExists(in_table_name => 'saved_filter_aggregation_type');

	DeleteFromIfTableExists(in_table_name => 'saved_filter_column');

	DeleteFromIfTableExists(in_table_name => 'saved_filter_region');
	 
	UPDATE chain.compound_filter
	   SET read_only_saved_filter_sid = NULL
	 WHERE app_sid = in_app_sid;
	 
	UPDATE chain.filter_value
	   SET saved_filter_sid_value = NULL
	 WHERE app_sid = in_app_sid;

	DeleteFromIfTableExists(in_table_name => 'saved_filter');

	DeleteFromIfTableExists(in_table_name => 'customer_grid_extension');

	DeleteFromIfTableExists(in_table_name => 'business_relationship_company');

	DeleteFromIfTableExists(in_table_name => 'bsci_supplier_det');

	DeleteFromIfTableExists(in_table_name => 'bsci_supplier');

	DeleteFromIfTableExists(in_table_name => 'bsci_2009_audit_finding');

	DeleteFromIfTableExists(in_table_name => 'bsci_2014_audit_finding');

	DeleteFromIfTableExists(in_table_name => 'bsci_2009_audit_associate');

	DeleteFromIfTableExists(in_table_name => 'bsci_2014_audit_associate');

	DeleteFromIfTableExists(in_table_name => 'bsci_2009_audit');

	DeleteFromIfTableExists(in_table_name => 'bsci_2014_audit');

	DeleteFromIfTableExists(in_table_name => 'bsci_ext_audit');

	DeleteFromIfTableExists(in_table_name => 'bsci_finding');

	DeleteFromIfTableExists(in_table_name => 'bsci_audit');

	--DeleteFromIfTableExists(in_table_name => 'bsci_options');

	DeleteFromIfTableExists(in_table_name => 'business_unit_supplier');

	DeleteFromIfTableExists(in_table_name => 'company_metric_type');

	DeleteFromIfTableExists(in_table_name => 'ucd_logon');

	DeleteFromIfTableExists(in_table_name => 'filter_page_column');

	DeleteFromIfTableExists(in_table_name => 'customer_aggregate_type');

	DeleteFromIfTableExists(in_table_name => 'filter_page_ind_interval');

	DeleteFromIfTableExists(in_table_name => 'filter_page_ind');

	DeleteFromIfTableExists(in_table_name => 'business_relationship_period');

	DeleteFromIfTableExists(in_table_name => 'business_relationship');

	DeleteFromIfTableExists(in_table_name => 'business_rel_tier_company_type');

	DeleteFromIfTableExists(in_table_name => 'business_relationship_tier');

	DeleteFromIfTableExists(in_table_name => 'company_tab_related_co_type');

	DeleteFromIfTableExists(in_table_name => 'company_tab_company_type_role');

	DeleteFromIfTableExists(in_table_name => 'company_tab');

	DeleteFromIfTableExists(in_table_name => 'business_relationship_type');

	DeleteFromIfTableExists(in_table_name => 'business_unit');

    DeleteFromIfTableExists(in_table_name => 'company_type_capability');

	DeleteFromIfTableExists(in_table_name => 'tertiary_relationships');

	DeleteFromIfTableExists(in_table_name => 'supplier_involvement_type');

	DeleteFromIfTableExists(in_table_name => 'company_type_relationship');

	DeleteFromIfTableExists(in_table_name => 'reference_capability');

	DeleteFromIfTableExists(in_table_name => 'reference_company_type');

	DeleteFromIfTableExists(in_table_name => 'reference');

	DeleteFromIfTableExists(in_table_name => 'card_init_param');

	DeleteFromIfTableExists(in_table_name => 'company_header');

	DeleteFromIfTableExists(in_table_name => 'company_type_tag_group');

	DeleteFromIfTableExists(in_table_name => 'company_type_role');

	DeleteFromIfTableExists(in_table_name => 'filter_field_top_n_cache');

	DeleteFromIfTableExists(in_table_name => 'filter_value');

	DeleteFromIfTableExists(in_table_name => 'filter_field');

	DeleteFromIfTableExists(in_table_name => 'filter');

	DeleteFromIfTableExists(in_table_name => 'filter_export_batch');

	DeleteFromIfTableExists(in_table_name => 'compound_filter');

	DeleteFromIfTableExists(in_table_name => 'dedupe_pp_field_cntry');

	DeleteFromIfTableExists(in_table_name => 'dedupe_preproc_rule');

	DeleteFromIfTableExists(in_table_name => 'default_product_code_type');

	DeleteFromIfTableExists(in_table_name => 'amount_unit');

	DeleteFromIfTableExists(in_table_name => 'capability_flow_capability');

	DeleteFromIfTableExists(in_table_name => 'filter_page_cms_table');

	DeleteFromIfTableExists(in_table_name => 'filter_item_config');

	DeleteFromIfTableExists(in_table_name => 'aggregate_type_config');

	DeleteFromIfTableExists(in_table_name => 'dedupe_merge_log');

	DeleteFromIfTableExists(in_table_name => 'dedupe_match');

	DeleteFromIfTableExists(in_table_name => 'dedupe_processed_record');

	DeleteFromIfTableExists(in_table_name => 'dedupe_rule');

	DeleteFromIfTableExists(in_table_name => 'pend_company_suggested_match');

	DeleteFromIfTableExists(in_table_name => 'dedupe_rule_set');

	DeleteFromIfTableExists(in_table_name => 'dedupe_staging_link');

	DeleteFromIfTableExists(in_table_name => 'dedupe_sub');

	DeleteFromIfTableExists(in_table_name => 'import_source_lock');

	DeleteFromIfTableExists(in_table_name => 'import_source');

	DeleteFromIfTableExists(in_table_name => 'company_request_action');

	DeleteFromIfTableExists(in_table_name => 'email_stub');

	DeleteFromIfTableExists(in_table_name => 'company');

	DeleteFromIfTableExists(in_table_name => 'comp_type_score_calc_comp_type');
	DeleteFromIfTableExists(in_table_name => 'company_type_score_calc');

	DeleteFromIfTableExists(in_table_name => 'company_type');

	DeleteFromIfTableExists(in_table_name => 'sector');

	DeleteFromIfTableExists(in_table_name => 'newsflash');

	DeleteFromIfTableExists(in_table_name => 'url_overrides');

	DeleteFromIfTableExists(in_table_name => 'task_entry_note');

	DeleteFromIfTableExists(in_table_name => 'task_entry_date');

	DeleteFromIfTableExists(in_table_name => 'task_entry');

	DeleteFromIfTableExists(in_table_name => 'customer_options');

	DeleteFromIfTableExists(in_table_name => 'alert_partial_template');

	DeleteFromIfTableExists(in_table_name => 'integration_request');

END;

FUNCTION NullSidArray RETURN security_pkg.T_SID_IDS
IS
v_sids security_pkg.T_SID_IDS;
BEGIN
RETURN v_sids;
END;

FUNCTION NullStringArray RETURN chain_pkg.T_STRINGS
IS
v_strings chain_pkg.T_STRINGS;
BEGIN
RETURN v_strings;
END;

END chain_pkg;
/
