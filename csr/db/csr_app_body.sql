CREATE OR REPLACE PACKAGE BODY CSR.csr_app_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
	v_class_id				security_pkg.T_CLASS_ID;
BEGIN
	v_class_id := class_pkg.getclassid('CSRUserGroup');
	aspen2.aspenapp_pkg.CreateObjectSpecificClasses(in_act_id, in_sid_id, in_class_id, in_name, in_parent_sid_id, v_class_id);	
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	aspen2.aspenapp_pkg.RenameObject(in_act_id, in_sid_id, in_new_name);
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
	aspen2.aspenapp_pkg.DeleteObject(in_act_id, in_sid_id);
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS   
BEGIN
	aspen2.aspenapp_pkg.MoveObject(in_act_id, in_sid_id, in_new_parent_sid_id, in_old_parent_sid_id);
END;

/*
Generates delete statements -- circular RI still needs to be handled manually

select 'DELETE FROM '||lower(decode(x.child_owner, 'CSR', '', x.child_owner||'.')||x.child_table_name)||chr(10)||
       ' WHERE app_sid = v_app_sid;'
  from (
    select max(level) lvl, child_owner, child_table_name
      from (select p.owner parent_owner, p.table_name parent_table_name, c.owner child_owner, c.table_name child_table_name
              from all_constraints p, all_constraints c
             where c.constraint_type = 'R' and p.constraint_type in ('U', 'P') and 
                   p.owner = c.r_owner and p.constraint_name = c.r_constraint_name) pc
            start with pc.parent_owner = 'CSR' and pc.parent_table_name = 'CUSTOMER'
            connect by nocycle prior pc.child_owner = pc.parent_owner and prior pc.child_table_name = pc.parent_table_name
    group by child_owner, child_table_name) x, all_tab_columns atc
 where atc.owner = x.child_owner and atc.table_name = x.child_table_name and atc.column_name = 'APP_SID'
order by x.lvl desc, x.child_owner, x.child_table_name;
*/
PROCEDURE DeleteApp(
	in_reduce_contention			IN	NUMBER	DEFAULT 0,
	in_debug_log_deletes			IN	NUMBER	DEFAULT 0,
	in_logoff_before_delete_so		IN	NUMBER	DEFAULT 0
)
AS
	v_app_sid						security_pkg.T_SID_ID;
	v_act_id						security_pkg.T_ACT_ID;
	v_account_sid					security_pkg.T_SID_ID;
	v_trash_sid						security_pkg.T_SID_ID;
	v_region_sid					security_pkg.T_SID_ID;

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

	PROCEDURE DeleteFromIfNPTableExists(
		in_table_name					IN	VARCHAR2
	)
	AS
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM ' || in_table_name || ' WHERE product_part_id IN (' ||
			'SELECT product_part_id FROM supplier.product_part WHERE product_id IN (' ||
				'SELECT product_id FROM supplier.all_product WHERE app_sid = ' || v_app_sid || '))';
		IF in_reduce_contention = 1 THEN
			COMMIT;
		END IF;
		IF in_debug_log_deletes = 1 THEN
			security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - Deleted ' || in_table_name);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - trying to delete ' || in_table_name || ' - Error ' || SQLERRM);
			-- ORA-00942: table or view does not exist
			IF SQLCODE != -942 THEN
				RAISE;
			END IF;
	END;

	PROCEDURE DeleteFromIfAPTableExists(
		in_table_name					IN	VARCHAR2
	)
	AS
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM ' || in_table_name || ' WHERE product_id IN (' ||
			'SELECT product_id FROM supplier.all_product WHERE app_sid = ' || v_app_sid || ')';
		IF in_reduce_contention = 1 THEN
			COMMIT;
		END IF;
		IF in_debug_log_deletes = 1 THEN
			security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - Deleted ' || in_table_name);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - trying to delete ' || in_table_name || ' - Error ' || SQLERRM);
			-- ORA-00942: table or view does not exist
			IF SQLCODE != -942 THEN
				RAISE;
			END IF;
	END;

	PROCEDURE DeleteFromIfACTableExists(
		in_table_name					IN	VARCHAR2
	)
	AS
	BEGIN
		EXECUTE IMMEDIATE 'DELETE FROM ' || in_table_name || ' WHERE company_sid IN (' ||
			'SELECT company_sid FROM supplier.all_company WHERE app_sid = ' || v_app_sid || ')';
		IF in_reduce_contention = 1 THEN
			COMMIT;
		END IF;
		IF in_debug_log_deletes = 1 THEN
			security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - Deleted ' || in_table_name);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - trying to delete ' || in_table_name || ' - Error ' || SQLERRM);
			-- ORA-00942: table or view does not exist
			IF SQLCODE != -942 THEN
				RAISE;
			END IF;
	END;


BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	If v_app_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'The current application in SYS_CONTEXT is not set to the application being deleted');
	END IF;

	-- clean up any snapshots (may run DDL)
	snapshot_pkg.DropAllSnapshots;

	-- ethics is an optional module, so check that it's installed
	FOR r IN (
		SELECT 1
		  FROM all_procedures
		 WHERE owner = 'ETHICS'
		   AND object_name = 'ETHICS_PKG'
		   AND procedure_name = 'DELETEALLDATA') LOOP
		EXECUTE IMMEDIATE 'BEGIN ethics.ethics_pkg.DeleteAllData; END;';
	END LOOP;
	IF in_reduce_contention = 1 THEN
		COMMIT;
	END IF;

	-- scenario values have no dependencies so can go first
	DeleteFromIfTableExists(in_table_name => 'scenario_run_val');

	-- more tables with no dependencies
	DeleteFromIfTableExists(in_table_name => 'group_user_cover');

	DeleteFromIfTableExists(in_table_name => 'role_user_cover');

	DeleteFromIfTableExists(in_table_name => 'flow_involvement_cover');

	DeleteFromIfTableExists(in_table_name => 'imp_conflict_val', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'imp_val', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'val_file');

	DeleteFromIfTableExists(in_table_name => 'val_note');

	DeleteFromIfTableExists(in_table_name => 'val', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'val_change', in_loop_count => 10000);

	--DeleteFromIfTableExists(in_table_name => 'auto_imp_mail_attach_filter');
	--DeleteFromIfTableExists(in_table_name => 'auto_imp_mailbox');

	-- delete mail accounts, but don't worry if they don't exist
	SELECT MIN(account_sid)
	  INTO v_account_sid
	  FROM mail.account a, customer c
	 WHERE c.app_sid = v_app_sid
	   AND LOWER(c.system_mail_address) = LOWER(a.email_address);
	   
	IF v_account_sid IS NOT NULL THEN
		mail.mail_pkg.deleteAccount(v_account_sid);
		CommitAndLogIfRequired(in_table_name => 'system_mail_address');
	END IF;

	SELECT MIN(account_sid)
	  INTO v_account_sid
	  FROM mail.account a, customer c
	 WHERE c.app_sid = v_app_sid
	   AND LOWER(c.tracker_mail_address) = LOWER(a.email_address);
	   
	IF v_account_sid IS NOT NULL THEN
		mail.mail_pkg.deleteAccount(v_account_sid);
		CommitAndLogIfRequired(in_table_name => 'tracker_mail_address');
	END IF;

	-- general clean up of irritating constraints
	UPDATE region
	   SET link_to_region_sid = null
	 WHERE app_sid = v_app_sid;

	IF in_reduce_contention = 1 THEN
		COMMIT;
	END IF;

	DeleteFromIfTableExists(in_table_name => 'osha_mapping');

	DeleteFromIfTableExists(in_table_name => 'degreeday_settings');

	DeleteFromIfTableExists(in_table_name => 'degreeday_region');

	DeleteFromIfTableExists(in_table_name => 'mgt_company_tree_sync_job');

	DeleteFromIfTableExists(in_table_name => 'lookup_table_entry');

	DeleteFromIfTableExists(in_table_name => 'lookup_table');

	DeleteFromIfTableExists(in_table_name => 'model_instance_chart');

	DeleteFromIfTableExists(in_table_name => 'model_instance_map');

	DeleteFromIfTableExists(in_table_name => 'model_instance_region');

	DeleteFromIfTableExists(in_table_name => 'model_instance_sheet');

	DeleteFromIfTableExists(in_table_name => 'model_instance');

	DeleteFromIfTableExists(in_table_name => 'model_validation');

	DeleteFromIfTableExists(in_table_name => 'model_map');

	DeleteFromIfTableExists(in_table_name => 'model_range_cell');

	DeleteFromIfTableExists(in_table_name => 'model_region_range');

	DeleteFromIfTableExists(in_table_name => 'model_range');

	DeleteFromIfTableExists(in_table_name => 'model_sheet');

	DeleteFromIfTableExists(in_table_name => 'approval_step_model');	

	DeleteFromIfTableExists(in_table_name => 'model');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_tag_eval_cond');


	DeleteFromIfTableExists(in_table_name => 'tpl_report_tag_dv_region');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_tag');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_tag_eval');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_tag_dataview');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_non_compl');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_tag_reg_data');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_tag_qchart');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_tag_approval_matrix');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_tag_qchart');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_tag_ind');

	DeleteFromIfTableExists(in_table_name => 'actions.task_period_override');

	DeleteFromIfTableExists(in_table_name => 'donations.budget_constant');

	DeleteFromIfTableExists(in_table_name => 'donations.user_fieldset_field');

	DeleteFromIfTableExists(in_table_name => 'donations.user_fieldset');

	DeleteFromIfTableExists(in_table_name => 'actions.aggr_task_period_override');

	DeleteFromIfTableExists(in_table_name => 'actions.aggr_task_task_dependency');

	DeleteFromIfTableExists(in_table_name => 'actions.initiative_extra_info');

	DeleteFromIfTableExists(in_table_name => 'actions.initiative_project_team');

	DeleteFromIfTableExists(in_table_name => 'actions.task_role_member');

	DeleteFromIfTableExists(in_table_name => 'actions.project_role_member');

	DeleteFromIfTableExists(in_table_name => 'actions.task_budget_history');

	DeleteFromIfTableExists(in_table_name => 'actions.task_budget_period');

	DeleteFromIfTableExists(in_table_name => 'actions.task_comment');

	DeleteFromIfTableExists(in_table_name => 'actions.task_instance');

	DeleteFromIfTableExists(in_table_name => 'actions.task_period_file_upload');

	DeleteFromIfTableExists(in_table_name => 'actions.task_period');

	DeleteFromIfTableExists(in_table_name => 'actions.task_recalc_region');

	DeleteFromIfTableExists(in_table_name => 'actions.task_recalc_period');

	DeleteFromIfTableExists(in_table_name => 'actions.task_recalc_job');

	DeleteFromIfTableExists(in_table_name => 'actions.task_task_dependency');

	DeleteFromIfTableExists(in_table_name => 'actions.file_upload_group_member');

	DeleteFromIfTableExists(in_table_name => 'actions.file_upload_group');

	DeleteFromIfTableExists(in_table_name => 'map_shpfile');

	DeleteFromIfTableExists(in_table_name => 'customer_map ');

	DeleteFromIfTableExists(in_table_name => 'attachment_history');

	DeleteFromIfTableExists(in_table_name => 'doc_download');

	DeleteFromIfTableExists(in_table_name => 'doc_notification');

	DeleteFromIfTableExists(in_table_name => 'doc_subscription');

	DeleteFromIfTableExists(in_table_name => 'factor_history');

	DeleteFromIfTableExists(in_table_name => 'form_allocation_item');

	DeleteFromIfTableExists(in_table_name => 'form_allocation_user');

	DeleteFromIfTableExists(in_table_name => 'postit');

	DeleteFromIfTableExists(in_table_name => 'comp_item_region_sched_issue');

	DeleteFromIfTableExists(in_table_name => 'comp_permit_sched_issue');

	DeleteFromIfTableExists(in_table_name => 'issue_scheduled_task');

	UPDATE issue
	   SET issue_pending_val_id = NULL,
	   	   issue_sheet_value_id = NULL,
		   issue_survey_answer_id = NULL,
		   issue_non_compliance_id = NULL,
		   issue_meter_id = NULL,
		   issue_meter_alarm_id = NULL,
		   issue_action_id = NULL,
		   issue_meter_raw_data_id = NULL,
		   issue_meter_data_source_id = NULL,
		   issue_compliance_region_id = NULL,
		   issue_supplier_id = NULL
     WHERE app_sid = v_app_sid;

	IF in_reduce_contention = 1 THEN
		COMMIT;
	END IF;

	DeleteFromIfTableExists(in_table_name => 'issue_action');

	DeleteFromIfTableExists(in_table_name => 'issue_compliance_region');

	DeleteFromIfTableExists(in_table_name => 'issue_meter_data_source');

	DeleteFromIfTableExists(in_table_name => 'issue_meter_raw_data');

	DeleteFromIfTableExists(in_table_name => 'issue_meter_alarm');

	DeleteFromIfTableExists(in_table_name => 'issue_meter');

	DeleteFromIfTableExists(in_table_name => 'issue_pending_val');

	DeleteFromIfTableExists(in_table_name => 'issue_non_compliance');

	DeleteFromIfTableExists(in_table_name => 'issue_survey_answer');

	DeleteFromIfTableExists(in_table_name => 'issue_sheet_value');

	DeleteFromIfTableExists(in_table_name => 'issue_action_log');

	DeleteFromIfTableExists(in_table_name => 'measure_conversion_period');

	DeleteFromIfTableExists(in_table_name => 'supplier_survey_response');

	DeleteFromIfTableExists(in_table_name => 'current_supplier_score');

	DeleteFromIfTableExists(in_table_name => 'supplier_score_log');

	DeleteFromIfTableExists(in_table_name => 'issue_supplier');

	-- Moved up from Property zaps below due to FKs on supplier
	-- Avoid dependancy
	UPDATE mgmt_company
	   SET company_sid = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'mgmt_company_fund_contact');

	DeleteFromIfTableExists(in_table_name => 'fund_form_plugin');

	DeleteFromIfTableExists(in_table_name => 'fund_mgmt_contact');

	DeleteFromIfTableExists(in_table_name => 'property_fund_ownership');

	DeleteFromIfTableExists(in_table_name => 'property_fund');

	DeleteFromIfTableExists(in_table_name => 'property_gresb');

	DeleteFromIfTableExists(in_table_name => 'property_mandatory_roles');

	-- FK on company_sid references supplier
	DeleteFromIfTableExists(in_table_name => 'fund');

	DeleteFromIfTableExists(in_table_name => 'supplier_delegation');

	UPDATE internal_audit
	   SET auditor_company_sid = NULL
	 WHERE app_sid = v_app_sid;

	UPDATE batch_job
	   SET requested_by_company_sid = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'issue_involvement');

	DeleteFromIfTableExists(in_table_name => 'batch_job_structure_import ');

	DeleteFromIfTableExists(in_table_name => 'supplier');

	DeleteFromIfTableExists(in_table_name => 'property_options');

	-- Disengage plugins from chain saved_filter records to avoid cross schema constraints.
	UPDATE csr.plugin
	   SET pre_filter_sid = NULL,
		   saved_filter_sid = NULL,
		   result_mode = dbms_random.value(1,1000000000)
	 WHERE app_sid = v_app_sid;

	-- Remove circular reference: "properties" requires "chain" but app_property.company_sid refers to chain.company
	-- See cross_schema_constraints
	UPDATE all_property
	   SET company_sid = NULL
	 WHERE app_sid = v_app_sid;

	 UPDATE doc_folder
		SET company_sid = NULL
	  WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'qs_filter_condition');

	chain.chain_pkg.DeleteChainData(in_app_sid => v_app_sid,
									in_reduce_contention => in_reduce_contention,
									in_debug_log_deletes => in_debug_log_deletes);

	DeleteFromIfTableExists(in_table_name => 'urjanet_service_type');

	DeleteFromIfTableExists(in_table_name => 'urjanet_import_instance');

	DeleteFromIfTableExists(in_table_name => 'utility_invoice');

	DeleteFromIfTableExists(in_table_name => 'meter_utility_contract');

	DeleteFromIfTableExists(in_table_name => 'utility_contract');

	DeleteFromIfTableExists(in_table_name => 'utility_supplier');

	DeleteFromIfTableExists(in_table_name => 'meter_list_cache');

	DeleteFromIfTableExists(in_table_name => 'meter_reading');

	DeleteFromIfTableExists(in_table_name => 'meter_source_data');

	DeleteFromIfTableExists(in_table_name => 'meter_reading_data');

	DeleteFromIfTableExists(in_table_name => 'meter_aggregate_type');

	DeleteFromIfTableExists(in_table_name => 'metering_options');

	DeleteFromIfTableExists(in_table_name => 'meter_live_data', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'meter_orphan_data');

	DeleteFromIfTableExists(in_table_name => 'meter_raw_data_error');

	DeleteFromIfTableExists(in_table_name => 'meter_import_revert_batch_job');

	DeleteFromIfTableExists(in_table_name => 'meter_raw_data_log');

	DeleteFromIfTableExists(in_table_name => 'meter_raw_data', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'meter_excel_mapping');

	DeleteFromIfTableExists(in_table_name => 'meter_excel_option');

	DeleteFromIfTableExists(in_table_name => 'meter_data_source_hi_res_input');

	DeleteFromIfTableExists(in_table_name => 'meter_xml_option');

	DeleteFromIfTableExists(in_table_name => 'meter_raw_data_source');

	DeleteFromIfTableExists(in_table_name => 'meter_input_aggr_ind');

	DeleteFromIfTableExists(in_table_name => 'meter_photo');

	DeleteFromIfTableExists(in_table_name => 'meter_alarm_statistic_job');

	DeleteFromIfTableExists(in_table_name => 'meter_alarm_stat_run');

	DeleteFromIfTableExists(in_table_name => 'meter_alarm_event');

	DeleteFromIfTableExists(in_table_name => 'meter_meter_alarm_statistic');

	DeleteFromIfTableExists(in_table_name => 'meter_alarm_statistic_period');

	DeleteFromIfTableExists(in_table_name => 'region_meter_alarm');

	DeleteFromIfTableExists(in_table_name => 'meter_patch_data');

	DeleteFromIfTableExists(in_table_name => 'meter_patch_batch_data');

	DeleteFromIfTableExists(in_table_name => 'meter_patch_batch_job');

	DeleteFromIfTableExists(in_table_name => 'all_meter');

	DeleteFromIfTableExists(in_table_name => 'meter_element_layout');

	DeleteFromIfTableExists(in_table_name => 'meter_type_input');

	DeleteFromIfTableExists(in_table_name => 'est_conv_mapping');

	DeleteFromIfTableExists(in_table_name => 'est_meter_type_mapping');

	DeleteFromIfTableExists(in_table_name => 'meter_type');

	DeleteFromIfTableExists(in_table_name => 'meter_source_type');

	DeleteFromIfTableExists(in_table_name => 'worksheet_row');

	DeleteFromIfTableExists(in_table_name => 'worksheet_column');

	DeleteFromIfTableExists(in_table_name => 'worksheet');

	DeleteFromIfTableExists(in_table_name => 'audit_non_compliance');

	DeleteFromIfTableExists(in_table_name => 'non_compliance_tag');

	DeleteFromIfTableExists(in_table_name => 'non_compliance_file');

	DeleteFromIfTableExists(in_table_name => 'non_compliance_expr_action');

	DeleteFromIfTableExists(in_table_name => 'non_compliance');

	DeleteFromIfTableExists(in_table_name => 'non_comp_type_audit_type');

	DeleteFromIfTableExists(in_table_name => 'non_comp_type_rpt_audit_type');

	DeleteFromIfTableExists(in_table_name => 'region_internal_audit');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_postit');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_file');

	DeleteFromIfTableExists(in_table_name => 'audit_alert');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_file_data');

	DeleteFromIfTableExists(in_table_name => 'audit_user_cover');

	DeleteFromIfTableExists(in_table_name => 'audit_iss_all_closed_alert');

	DeleteFromIfTableExists(in_table_name => 'audit_type_flow_inv_type');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_tag');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_survey');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_locked_tag');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_score');

	DeleteFromIfTableExists(in_table_name => 'internal_audit');

	DeleteFromIfTableExists(in_table_name => 'quick_survey_expr_action');

	DeleteFromIfTableExists(in_table_name => 'qs_expr_msg_action');

	DeleteFromIfTableExists(in_table_name => 'qs_expr_non_compl_action');

	DeleteFromIfTableExists(in_table_name => 'qs_expr_nc_action_involve_role');

	DeleteFromIfTableExists(in_table_name => 'audit_type_closure_type');

	DeleteFromIfTableExists(in_table_name => 'audit_closure_type');

	DeleteFromIfTableExists(in_table_name => 'audit_type_non_comp_default');

	DeleteFromIfTableExists(in_table_name => 'audit_type_tab');

	DeleteFromIfTableExists(in_table_name => 'audit_type_header');

	DeleteFromIfTableExists(in_table_name => 'audit_type_expiry_alert_role');

	DeleteFromIfTableExists(in_table_name => 'flow_state_audit_ind');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_type_tag_group');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_type_carry_fwd');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_type_tag_group');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_type_survey');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_type_report');

	DeleteFromIfTableExists(in_table_name => 'score_type_audit_type');

	UPDATE quick_survey
	   SET auditing_audit_type_id = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'internal_audit_type');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_type_group');

	DeleteFromIfTableExists(in_table_name => 'non_comp_default_issue');

	DeleteFromIfTableExists(in_table_name => 'non_comp_default_tag');

	DeleteFromIfTableExists(in_table_name => 'QS_QUESTION_OPTION_NC_TAG');

	DeleteFromIfTableExists(in_table_name => 'quick_survey_expr');

	DeleteFromIfTableExists(in_table_name => 'qs_submission_file');

	DeleteFromIfTableExists(in_table_name => 'qs_answer_file');

	DeleteFromIfTableExists(in_table_name => 'qs_response_file');

	DeleteFromIfTableExists(in_table_name => 'qs_answer_log');

	DeleteFromIfTableExists(in_table_name => 'quick_survey_answer', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'QS_QUESTION_OPTION');

	DeleteFromIfTableExists(in_table_name => 'non_comp_default');

	DeleteFromIfTableExists(in_table_name => 'non_comp_default_folder');

	DeleteFromIfTableExists(in_table_name => 'non_compliance_type_tag_group');

	DeleteFromIfTableExists(in_table_name => 'non_compliance_type_flow_cap');

	DeleteFromIfTableExists(in_table_name => 'non_compliance_type');

	UPDATE quick_survey_response
	   SET last_submission_id = null
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'quick_survey_submission');

	DeleteFromIfTableExists(in_table_name => 'region_survey_response');

	DeleteFromIfTableExists(in_table_name => 'region_score');

	DeleteFromIfTableExists(in_table_name => 'region_score_log');

	UPDATE flow_item
	   SET survey_response_id = NULL
	 WHERE app_sid = v_app_sid
	   AND survey_response_id IS NOT NULL;

	DeleteFromIfTableExists(in_table_name => 'quick_survey_response');

	DeleteFromIfTableExists(in_table_name => 'qs_question_option_nc_tag');

	DeleteFromIfTableExists(in_table_name => 'qs_question_option');

	DeleteFromIfTableExists(in_table_name => 'quick_survey_question_tag');

	DeleteFromIfTableExists(in_table_name => 'quick_survey_question');

	DeleteFromIfTableExists(in_table_name => 'quick_survey_lang');

	DeleteFromIfTableExists(in_table_name => 'deleg_plan_date_schedule');

	DeleteFromIfTableExists(in_table_name => 'deleg_plan_deleg_region_deleg');

	DeleteFromIfTableExists(in_table_name => 'deleg_plan_deleg_region');

	DeleteFromIfTableExists(in_table_name => 'deleg_plan_col_deleg');

	-- WTF is this shit?
	DeleteFromIfTableExists(in_table_name => 'XX_DELEG_PLAN_SURVEY_REGION ');

	DeleteFromIfTableExists(in_table_name => 'deleg_plan_col_survey');

	DeleteFromIfTableExists(in_table_name => 'deleg_plan_col');

	campaigns.campaign_pkg.DeleteForApp(v_app_sid);

	DeleteFromIfTableExists(in_table_name => 'qs_expr_msg_action');

	UPDATE csr.quick_survey
	   SET current_version = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'quick_survey_version');

	DeleteFromIfTableExists(in_table_name => 'quick_survey_score_threshold');

	DeleteFromIfTableExists(in_table_name => 'question_tag');

	DeleteFromIfTableExists(in_table_name => 'question_option_nc_tag');

	DeleteFromIfTableExists(in_table_name => 'question_option');

	-- stupid circular dependencies mean we can't commit this next one until after question is also deleted
	DeleteFromIfTableExists(in_table_name => 'question_version', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'question');

	DeleteFromIfTableExists(in_table_name => 'quick_survey');

	UPDATE compliance_options
	   SET permit_doc_lib_sid = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'compliance_options');

	DeleteFromIfTableExists(in_table_name => 'quick_survey_type');

	DeleteFromIfTableExists(in_table_name => 'score_type_agg_type');

	DeleteFromIfTableExists(in_table_name => 'compliance_permit_score');

	DeleteFromIfTableExists(in_table_name => 'score_threshold');

	DeleteFromIfTableExists(in_table_name => 'score_type');

	DeleteFromIfTableExists(in_table_name => 'section_comment');

	DeleteFromIfTableExists(in_table_name => 'section_trans_comment');

	DeleteFromIfTableExists(in_table_name => 'section_alert');

	DeleteFromIfTableExists(in_table_name => 'sheet_inherited_value');

	DeleteFromIfTableExists(in_table_name => 'sheet_value_var_expl');

	DeleteFromIfTableExists(in_table_name => 'sheet_value_accuracy');

	DeleteFromIfTableExists(in_table_name => 'tab_portlet_rss_feed');

	DeleteFromIfTableExists(in_table_name => 'scenario_options');

	DeleteFromIfTableExists(in_table_name => 'actions.aggr_task_ind_dependency');

	DeleteFromIfTableExists(in_table_name => 'actions.aggr_task_period');

	DeleteFromIfTableExists(in_table_name => 'actions.task_status_role');

	DeleteFromIfTableExists(in_table_name => 'actions.allow_transition');

	DeleteFromIfTableExists(in_table_name => 'actions.task_status_transition');

	DeleteFromIfTableExists(in_table_name => 'actions.root_ind_template_instance');

	DeleteFromIfTableExists(in_table_name => 'actions.instance_gas_ind');

	DeleteFromIfTableExists(in_table_name => 'actions.task_ind_template_instance');

	DeleteFromIfTableExists(in_table_name => 'actions.project_ind_template');

	DeleteFromIfTableExists(in_table_name => 'actions.project_ind_template_instance');

	DeleteFromIfTableExists(in_table_name => 'actions.ind_template');

	DeleteFromIfTableExists(in_table_name => 'actions.ind_template_group ');

	DeleteFromIfTableExists(in_table_name => 'actions.project_role');

	DeleteFromIfTableExists(in_table_name => 'actions.reckoner_tag');

	DeleteFromIfTableExists(in_table_name => 'actions.reckoner_tag_group');

	DeleteFromIfTableExists(in_table_name => 'actions.project_tag_group');

	DeleteFromIfTableExists(in_table_name => 'actions.tag_group_member');

	DeleteFromIfTableExists(in_table_name => 'actions.project_task_period_status');

	DeleteFromIfTableExists(in_table_name => 'actions.task_period_status');

	DeleteFromIfTableExists(in_table_name => 'actions.task_file_upload');

	DeleteFromIfTableExists(in_table_name => 'actions.task_indicator');

	DeleteFromIfTableExists(in_table_name => 'actions.task_ind_dependency');

	DeleteFromIfTableExists(in_table_name => 'actions.task_region');

	DeleteFromIfTableExists(in_table_name => 'actions.task_status_history');

	DeleteFromIfTableExists(in_table_name => 'actions.periodic_report_template');

	DeleteFromIfTableExists(in_table_name => 'actions.task_tag');

	DeleteFromIfTableExists(in_table_name => 'actions.initiative_sponsor');

	DeleteFromIfTableExists(in_table_name => 'actions.csr_task_role_member');

	DeleteFromIfTableExists(in_table_name => 'actions.task');

	DeleteFromIfTableExists(in_table_name => 'alert_template_body');

	DeleteFromIfTableExists(in_table_name => 'alert_template');

	DeleteFromIfTableExists(in_table_name => 'alert_frame_body');

	DeleteFromIfTableExists(in_table_name => 'alert_frame');

	DeleteFromIfTableExists(in_table_name => 'section_fact_attach');

	DeleteFromIfTableExists(in_table_name => 'attachment');

	DeleteFromIfTableExists(in_table_name => 'calc_dependency');

	DeleteFromIfTableExists(in_table_name => 'calc_tag_dependency');

	DeleteFromIfTableExists(in_table_name => 'calc_baseline_config_dependency');

	DeleteFromIfTableExists(in_table_name => 'dashboard_item');

	DeleteFromIfTableExists(in_table_name => 'img_chart_ind');

	DeleteFromIfTableExists(in_table_name => 'img_chart_region');

	DeleteFromIfTableExists(in_table_name => 'img_chart');

	DeleteFromIfTableExists(in_table_name => 'dataview_zone');

	DeleteFromIfTableExists(in_table_name => 'delegation_ind_cond_action ');

	DeleteFromIfTableExists(in_table_name => 'delegation_ind_cond ');

	DeleteFromIfTableExists(in_table_name => 'delegation_ind_tag ');

	DeleteFromIfTableExists(in_table_name => 'delegation_ind_tag_list ');

	DeleteFromIfTableExists(in_table_name => 'deleg_ind_form_expr');

	DeleteFromIfTableExists(in_table_name => 'form_expr ');

	DeleteFromIfTableExists(in_table_name => 'deleg_ind_group_member');

	DeleteFromIfTableExists(in_table_name => 'deleg_ind_group ');

	DeleteFromIfTableExists(in_table_name => 'delegation_description');

	DeleteFromIfTableExists(in_table_name => 'delegation_ind_description');

	DeleteFromIfTableExists(in_table_name => 'delegation_ind');

	DeleteFromIfTableExists(in_table_name => 'delegation_grid_aggregate_ind ');

	DeleteFromIfTableExists(in_table_name => 'deleg_grid_variance');

	DeleteFromIfTableExists(in_table_name => 'delegation_grid');

	DeleteFromIfTableExists(in_table_name => 'delegation_region_description');

	DeleteFromIfTableExists(in_table_name => 'delegation_region');

	DeleteFromIfTableExists(in_table_name => 'doc_current');

	DeleteFromIfTableExists(in_table_name => 'doc_version');

	DeleteFromIfTableExists(in_table_name => 'factor');

	DeleteFromIfTableExists(in_table_name => 'feed_request');

	DeleteFromIfTableExists(in_table_name => 'form_comment');

	DeleteFromIfTableExists(in_table_name => 'form_allocation');

	DeleteFromIfTableExists(in_table_name => 'imp_conflict');

	DeleteFromIfTableExists(in_table_name => 'est_space_attr');

	DeleteFromIfTableExists(in_table_name => 'region_metric_val');

	DeleteFromIfTableExists(in_table_name => 'region_start_point');

	DeleteFromIfTableExists(in_table_name => 'imp_measure');

	DeleteFromIfTableExists(in_table_name => 'imp_ind');

	DeleteFromIfTableExists(in_table_name => 'imp_region');

	DeleteFromIfTableExists(in_table_name => 'ind_accuracy_type');

	DeleteFromIfTableExists(in_table_name => 'ind_start_point');

	DeleteFromIfTableExists(in_table_name => 'ind_validation_rule');

	DeleteFromIfTableExists(in_table_name => 'ind_tag');

	DeleteFromIfTableExists(in_table_name => 'ind_window');

	DeleteFromIfTableExists(in_table_name => 'instance_dataview');

	DeleteFromIfTableExists(in_table_name => 'objective_status');

	DeleteFromIfTableExists(in_table_name => 'pct_ownership');

	DeleteFromIfTableExists(in_table_name => 'pvc_stored_calc_job');

	DeleteFromIfTableExists(in_table_name => 'pvc_region_recalc_job');

	DeleteFromIfTableExists(in_table_name => 'pending_val_file_upload');

	DeleteFromIfTableExists(in_table_name => 'pending_ind_accuracy_type');

	DeleteFromIfTableExists(in_table_name => 'pending_val_accuracy_type_opt');

	DeleteFromIfTableExists(in_table_name => 'pending_val_log');

	DeleteFromIfTableExists(in_table_name => 'pending_val_variance');

	DeleteFromIfTableExists(in_table_name => 'pending_val');

	DeleteFromIfTableExists(in_table_name => 'pending_val_cache');

	DeleteFromIfTableExists(in_table_name => 'approval_step_ind');

	DeleteFromIfTableExists(in_table_name => 'pending_ind');

	DeleteFromIfTableExists(in_table_name => 'approval_step_sheet_log');

	DeleteFromIfTableExists(in_table_name => 'approval_step_sheet_alert');

	DeleteFromIfTableExists(in_table_name => 'approval_step_sheet');

	DeleteFromIfTableExists(in_table_name => 'pending_period');

	DeleteFromIfTableExists(in_table_name => 'approval_step_region');

	DeleteFromIfTableExists(in_table_name => 'pending_region');

	DeleteFromIfTableExists(in_table_name => 'approval_step_role');

	DeleteFromIfTableExists(in_table_name => 'approval_step_template');

	DeleteFromIfTableExists(in_table_name => 'approval_step_user_template');

	DeleteFromIfTableExists(in_table_name => 'approval_step_user');

	DeleteFromIfTableExists(in_table_name => 'approval_step');

	DeleteFromIfTableExists(in_table_name => 'dataview_ind_description');

	DeleteFromIfTableExists(in_table_name => 'dataview_ind_member');

	DeleteFromIfTableExists(in_table_name => 'dataview_region_description');

	DeleteFromIfTableExists(in_table_name => 'dataview_region_member');

	DeleteFromIfTableExists(in_table_name => 'form_ind_member');

	DeleteFromIfTableExists(in_table_name => 'form_region_member');

	DeleteFromIfTableExists(in_table_name => 'region_owner');

	DeleteFromIfTableExists(in_table_name => 'region_role_member', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'region_tag');

	DeleteFromIfTableExists(in_table_name => 'property_division');

	DeleteFromIfTableExists(in_table_name => 'division');

	DeleteFromIfTableExists(in_table_name => 'rss_feed_item');

	DeleteFromIfTableExists(in_table_name => 'section_cart_member');

	DeleteFromIfTableExists(in_table_name => 'section_cart');

	DeleteFromIfTableExists(in_table_name => 'route_step_user');

	DeleteFromIfTableExists(in_table_name => 'route_step_vote');

	UPDATE section
	   SET current_route_step_id = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'route_step');

	DeleteFromIfTableExists(in_table_name => 'route');

	DeleteFromIfTableExists(in_table_name => 'section_routed_flow_state');

	UPDATE section_module
	   SET flow_sid = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'section_flow');

	DeleteFromIfTableExists(in_table_name => 'section_tag_member');

	DeleteFromIfTableExists(in_table_name => 'section_tag');

	DeleteFromIfTableExists(in_table_name => 'section_attach_log');

	DeleteFromIfTableExists(in_table_name => 'section_fact_enum');

	DeleteFromIfTableExists(in_table_name => 'section_val');

	DeleteFromIfTableExists(in_table_name => 'section_fact');

	DeleteFromIfTableExists(in_table_name => 'section_content_doc_wait');

	DeleteFromIfTableExists(in_table_name => 'section_content_doc');

	UPDATE section
	   SET visible_version_number = NULL, checked_out_version_number = null
	 WHERE app_sid = v_app_sid;

	-- stupid circular dependencies mean we can't commit this next one until after question is also deleted
	DeleteFromIfTableExists(in_table_name => 'section_version', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'section');

	UPDATE sheet_value
	   SET last_sheet_value_change_id = null
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'sheet_value_change_file');

	DeleteFromIfTableExists(in_table_name => 'sheet_value_change', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'sheet_value_file');
	
	DeleteFromIfTableExists(in_table_name => 'sheet_value_file_hidden_cache');

	DeleteFromIfTableExists(in_table_name => 'sheet_value_hidden_cache');
	
	DeleteFromIfTableExists(in_table_name => 'sheet_potential_orphan_files');

	DeleteFromIfTableExists(in_table_name => 'sheet_value', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'sheet_alert');

	UPDATE sheet
	   SET last_sheet_history_id = null
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'sheet_history');

	DeleteFromIfTableExists(in_table_name => 'sheet_date_schedule');

	UPDATE delegation
	   SET delegation_date_schedule_id = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'deleg_data_change_alert');

	DeleteFromIfTableExists(in_table_name => 'delegation_date_schedule');

	DeleteFromIfTableExists(in_table_name => 'delegation_change_alert');

	DeleteFromIfTableExists(in_table_name => 'delegation_edited_alert');

	DeleteFromIfTableExists(in_table_name => 'sheet_completeness_sheet');

	DeleteFromIfTableExists(in_table_name => 'sheet_change_req_alert');

	DeleteFromIfTableExists(in_table_name => 'new_delegation_alert');

	DeleteFromIfTableExists(in_table_name => 'new_planned_deleg_alert');

	DeleteFromIfTableExists(in_table_name => 'sheet_created_alert');

	DeleteFromIfTableExists(in_table_name => 'sheet_change_req');

	DeleteFromIfTableExists(in_table_name => 'sheet_automatic_approval');

	DeleteFromIfTableExists(in_table_name => 'sheet_change_log');

	DeleteFromIfTableExists(in_table_name => 'sheet');

	DeleteFromIfTableExists(in_table_name => 'delegation_user');

	DeleteFromIfTableExists(in_table_name => 'deleg_plan_role');

	DeleteFromIfTableExists(in_table_name => 'deleg_plan_region');

	DeleteFromIfTableExists(in_table_name => 'deleg_plan_job');

	DeleteFromIfTableExists(in_table_name => 'deleg_report_deleg_plan');

	DeleteFromIfTableExists(in_table_name => 'deleg_plan');

	DeleteFromIfTableExists(in_table_name => 'delegation_role');

	DeleteFromIfTableExists(in_table_name => 'master_deleg');

	DeleteFromIfTableExists(in_table_name => 'deleg_meta_role_ind_selection');

	DeleteFromIfTableExists(in_table_name => 'delegation_user_cover');

	DeleteFromIfTableExists(in_table_name => 'delegation_policy');

	DeleteFromIfTableExists(in_table_name => 'delegation_tag');

	DeleteFromIfTableExists(in_table_name => 'delegation');

	DeleteFromIfTableExists(in_table_name => 'delegation_layout');

	DeleteFromIfTableExists(in_table_name => 'deleted_delegation');

	DeleteFromIfTableExists(in_table_name => 'snapshot_ind');

	DeleteFromIfTableExists(in_table_name => 'app_lock');

	DeleteFromIfTableExists(in_table_name => 'val_change_log');

	DeleteFromIfTableExists(in_table_name => 'sheet_val_change_log');

	DeleteFromIfTableExists(in_table_name => 'tab_group');

	DeleteFromIfTableExists(in_table_name => 'user_setting_entry');

	DeleteFromIfTableExists(in_table_name => 'approval_note_portlet_note');

	DeleteFromIfTableExists(in_table_name => 'tab_portlet_user_region');

	DeleteFromIfTableExists(in_table_name => 'tab_portlet');

	DeleteFromIfTableExists(in_table_name => 'tab_user');

	DeleteFromIfTableExists(in_table_name => 'tab_description');

	DeleteFromIfTableExists(in_table_name => 'project_tag_filter');

	DeleteFromIfTableExists(in_table_name => 'project_tag_group');

	DeleteFromIfTableExists(in_table_name => 'tag_group_member');

	DeleteFromIfTableExists(in_table_name => 'target_dashboard_ind_member');

	DeleteFromIfTableExists(in_table_name => 'target_dashboard_reg_member');

	DeleteFromIfTableExists(in_table_name => 'target_dashboard_value');

	DeleteFromIfTableExists(in_table_name => 'metric_dashboard_plugin');

	DeleteFromIfTableExists(in_table_name => 'metric_dashboard_ind');

	DeleteFromIfTableExists(in_table_name => 'benchmark_dashboard_plugin');

	DeleteFromIfTableExists(in_table_name => 'benchmark_dashboard_ind');

	DeleteFromIfTableExists(in_table_name => 'benchmark_dashboard_char');

	-- does not exist for clean build
	DeleteFromIfTableExists(in_table_name => 'est_error_legacy');

	DeleteFromIfTableExists(in_table_name => 'est_error');

	DeleteFromIfTableExists(in_table_name => 'est_job_attr');

	DeleteFromIfTableExists(in_table_name => 'est_job_reading');

	DeleteFromIfTableExists(in_table_name => 'est_job');

	DeleteFromIfTableExists(in_table_name => 'est_attr_measure_conv');

	DeleteFromIfTableExists(in_table_name => 'est_attr_measure');

	DeleteFromIfTableExists(in_table_name => 'est_building_change_log');

	DeleteFromIfTableExists(in_table_name => 'est_building_metric_mapping');

	DeleteFromIfTableExists(in_table_name => 'est_building_metric');

	-- should go at some point; see latest2503
	DeleteFromIfTableExists(in_table_name => 'est_energy_conv_mapping');

	DeleteFromIfTableExists(in_table_name => 'est_conv_mapping');

	-- should go at some point; see latest2503
	DeleteFromIfTableExists(in_table_name => 'est_energy_type_mapping');

	-- should go at some point; see latest2503
	DeleteFromIfTableExists(in_table_name => 'est_energy_meter');

	DeleteFromIfTableExists(in_table_name => 'est_meter_change_log');

	DeleteFromIfTableExists(in_table_name => 'est_meter_reading_change_log');

	DeleteFromIfTableExists(in_table_name => 'est_meter_type_mapping');

	DeleteFromIfTableExists(in_table_name => 'est_mismatched_esp_id');

	DeleteFromIfTableExists(in_table_name => 'est_meter');

	DeleteFromIfTableExists(in_table_name => 'est_other_mapping');

	DeleteFromIfTableExists(in_table_name => 'est_property_type_map');

	DeleteFromIfTableExists(in_table_name => 'est_region_change_log');

	DeleteFromIfTableExists(in_table_name => 'est_space_attr_change_log');

	DeleteFromIfTableExists(in_table_name => 'est_space_attr_legacy');

	DeleteFromIfTableExists(in_table_name => 'est_space_attr_mapping');

	DeleteFromIfTableExists(in_table_name => 'est_space_change_log');

	DeleteFromIfTableExists(in_table_name => 'est_space_type_map');

	DeleteFromIfTableExists(in_table_name => 'est_space');

	DeleteFromIfTableExists(in_table_name => 'est_building');

	-- should go at some point; see latest2503
	DeleteFromIfTableExists(in_table_name => 'est_water_conv_mapping');

	-- should go at some point; see latest2503
	DeleteFromIfTableExists(in_table_name => 'est_water_use_mapping');

	-- should go at some point; see latest2503
	DeleteFromIfTableExists(in_table_name => 'est_water_meter');

	DeleteFromIfTableExists(in_table_name => 'est_customer');

	DeleteFromIfTableExists(in_table_name => 'est_options');

	DeleteFromIfTableExists(in_table_name => 'outstanding_requests_job');

	DeleteFromIfTableExists(in_table_name => 'est_account');

	DeleteFromIfTableExists(in_table_name => 'user_measure_conversion');

	DeleteFromIfTableExists(in_table_name => 'initiative_metric_val');

	DeleteFromIfTableExists(in_table_name => 'gresb_indicator_mapping');

	--DeleteFromIfTableExists(in_table_name => 'measure_conversion');

	DeleteFromIfTableExists(in_table_name => 'donations.customer_options');

	DeleteFromIfTableExists(in_table_name => 'donations.scheme_field');

	DeleteFromIfTableExists(in_table_name => 'donations.custom_field_dependency');

	DeleteFromIfTableExists(in_table_name => 'donations.custom_field');

	DeleteFromIfTableExists(in_table_name => 'donations.donation_doc');

	DeleteFromIfTableExists(in_table_name => 'donations.donation_tag');

	DeleteFromIfTableExists(in_table_name => 'donations.donation');

	DeleteFromIfTableExists(in_table_name => 'donations.budget');

	DeleteFromIfTableExists(in_table_name => 'donations.letter_body_region_group');

	DeleteFromIfTableExists(in_table_name => 'donations.region_group_recipient');

	DeleteFromIfTableExists(in_table_name => 'donations.letter_body_text');

	DeleteFromIfTableExists(in_table_name => 'donations.recipient_tag');

	DeleteFromIfTableExists(in_table_name => 'donations.recipient_tag_group');

	DeleteFromIfTableExists(in_table_name => 'donations.fc_upload');

	DeleteFromIfTableExists(in_table_name => 'donations.fc_budget');

	DeleteFromIfTableExists(in_table_name => 'donations.fc_donation');

	DeleteFromIfTableExists(in_table_name => 'donations.fc_tag');

	DeleteFromIfTableExists(in_table_name => 'donations.funding_commitment');

	DeleteFromIfTableExists(in_table_name => 'donations.region_group_member');

	DeleteFromIfTableExists(in_table_name => 'donations.region_group');

	DeleteFromIfTableExists(in_table_name => 'donations.scheme_tag_group');

	DeleteFromIfTableExists(in_table_name => 'donations.tag_group_member');

	DeleteFromIfTableExists(in_table_name => 'donations.transition');

	DeleteFromIfTableExists(in_table_name => 'supplier.invite_questionnaire');

	DeleteFromIfTableExists(in_table_name => 'supplier.invite');

	DeleteFromIfTableExists(in_table_name => 'supplier.message_contact');

	DeleteFromIfTableExists(in_table_name => 'supplier.contact');

	DeleteFromIfTableExists(in_table_name => 'supplier.message_procurer_supplier');

	DeleteFromIfTableExists(in_table_name => 'supplier.message_user');

	DELETE FROM supplier.message_questionnaire
	 WHERE message_id IN (
			SELECT message_id
			  FROM supplier.message
			 WHERE app_sid = v_app_sid);
	CommitAndLogIfRequired(in_table_name => 'supplier.message_questionnaire');

	DeleteFromIfTableExists(in_table_name => 'supplier.message');

	DeleteFromIfTableExists(in_table_name => 'supplier.questionnaire_request');

	DeleteFromIfTableExists(in_table_name => 'supplier.all_procurer_supplier');

	DeleteFromIfTableExists(in_table_name => 'supplier.company_questionnaire_response');

	DeleteFromIfTableExists(in_table_name => 'supplier.chain_questionnaire');

	DELETE FROM supplier.product_questionnaire_group
	 WHERE group_id IN (
			SELECT group_id
			  FROM supplier.questionnaire_group
			 WHERE app_sid = v_app_sid);
	CommitAndLogIfRequired(in_table_name => 'supplier.product_questionnaire_group');

	DELETE FROM supplier.questionnaire_group_membership
	 WHERE group_id IN (
			SELECT group_id
			  FROM supplier.questionnaire_group
			 WHERE app_sid = v_app_sid);
	CommitAndLogIfRequired(in_table_name => 'supplier.questionnaire_group_membership');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.product_revision_tag');

	DeleteFromIfTableExists(in_table_name => 'supplier.questionnaire_group');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.product_tag');

	DeleteFromIfNPTableExists(in_table_name => 'supplier.np_part_description');

	DeleteFromIfNPTableExists(in_table_name => 'supplier.np_component_description');

	DeleteFromIfNPTableExists(in_table_name => 'supplier.np_part_evidence');

	DeleteFromIfNPTableExists(in_table_name => 'supplier.wood_part_description');

	DeleteFromIfNPTableExists(in_table_name => 'supplier.wood_part_wood');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.all_product_questionnaire');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.np_product_answers');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_fa_wsr');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_fa_anc_mat');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_fa_haz_chem');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_fa_palm_ind');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_fa_endangered_sp');
	
	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_formulation_answers');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_pack_item');
	
	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_packaging_answers');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_link_product');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_country_sold_in');
	
	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_product_answers');
	
	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_profile');
	
	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_scores');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_supplier_answers');
	
	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_country_made_in');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_transport_answers');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_scores_combined');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_pda_hc_item');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_pda_material_item');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_pda_anc_mat');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_pda_endangered_sp');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_pda_main_power');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_pda_palm_ind');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_pda_battery');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_pdesign_answers');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_trans_item');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_fd_answer_scheme');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_fd_endangered_sp');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_fd_ingredient');
	
	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_fd_palm_ind');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_food_anc_mat');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_food_sa_q');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.gt_food_answers');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.product_revision');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.product_sales_volume');

	DeleteFromIfTableExists(in_table_name => 'supplier.gt_product_user');

	DeleteFromIfAPTableExists(in_table_name => 'supplier.product_part');

	DeleteFromIfTableExists(in_table_name => 'supplier.all_product');

	DeleteFromIfTableExists(in_table_name => 'supplier.company_user');

	DeleteFromIfTableExists(in_table_name => 'actions.customer_options');

	DeleteFromIfTableExists(in_table_name => 'actions.file_upload');

	DeleteFromIfTableExists(in_table_name => 'actions.project_task_status');

	DeleteFromIfTableExists(in_table_name => 'actions.project_region_role_member');

	DeleteFromIfTableExists(in_table_name => 'actions.import_template_mapping');

	DeleteFromIfTableExists(in_table_name => 'actions.import_template');

	DeleteFromIfTableExists(in_table_name => 'actions.project');

	DeleteFromIfTableExists(in_table_name => 'actions.role');

	DeleteFromIfTableExists(in_table_name => 'actions.script');

	DeleteFromIfTableExists(in_table_name => 'actions.tag');

	DeleteFromIfTableExists(in_table_name => 'actions.tag_group');

	DeleteFromIfTableExists(in_table_name => 'actions.task_status');

	DeleteFromIfTableExists(in_table_name => 'delegation_terminated_alert');

	DeleteFromIfTableExists(in_table_name => 'user_inactive_man_alert');

	DeleteFromIfTableExists(in_table_name => 'user_inactive_rem_alert');

	DeleteFromIfTableExists(in_table_name => 'user_message_alert');

	DeleteFromIfTableExists(in_table_name => 'autocreate_user');

	DeleteFromIfTableExists(in_table_name => 'alert_batch_run');

	DeleteFromIfTableExists(in_table_name => 'cms_tab_alert_type');

	DeleteFromIfTableExists(in_table_name => 'flow_transition_alert_role');

	DeleteFromIfTableExists(in_table_name => 'flow_transition_alert_cc_role');

	DeleteFromIfTableExists(in_table_name => 'flow_transition_alert_inv');

	DeleteFromIfTableExists(in_table_name => 'flow_item_generated_alert');

	DeleteFromIfTableExists(in_table_name => 'flow_item_gen_alert_archive');

	DeleteFromIfTableExists(in_table_name => 'flow_transition_alert');

	DeleteFromIfTableExists(in_table_name => 'approval_dashboard_alert_type');

	DeleteFromIfTableExists(in_table_name => 'flow_state_alert_role');

	DeleteFromIfTableExists(in_table_name => 'flow_state_alert_run');

	DeleteFromIfTableExists(in_table_name => 'flow_state_alert_user');

	DeleteFromIfTableExists(in_table_name => 'flow_state_alert');

	DeleteFromIfTableExists(in_table_name => 'flow_alert_type');

	DeleteFromIfTableExists(in_table_name => 'cms_alert_type');

	DeleteFromIfTableExists(in_table_name => 'cms_alert_helper');

	DeleteFromIfTableExists(in_table_name => 'customer_alert_type_param');

	DeleteFromIfTableExists(in_table_name => 'cms_field_change_alert');

	DeleteFromIfTableExists(in_table_name => 'alert_batch_run'); -- delete again in case more have appeared
	DeleteFromIfTableExists(in_table_name => 'customer_alert_type');

	DeleteFromIfTableExists(in_table_name => 'customer_help_lang');

	DeleteFromIfTableExists(in_table_name => 'customer_portlet');

	DeleteFromIfTableExists(in_table_name => 'dashboard');

	DeleteFromIfTableExists(in_table_name => 'excel_export_options_tag_group');

	DeleteFromIfTableExists(in_table_name => 'excel_export_options');

	DeleteFromIfTableExists(in_table_name => 'import_feed_request');

	DeleteFromIfTableExists(in_table_name => 'import_feed');

	DeleteFromIfTableExists(in_table_name => 'export_feed_dataview');

	DeleteFromIfTableExists(in_table_name => 'export_feed_cms_form');
	
	DeleteFromIfTableExists(in_table_name => 'export_feed_stored_proc');

	DeleteFromIfTableExists(in_table_name => 'export_feed');

	DeleteFromIfTableExists(in_table_name => 'dataview_trend');

	DeleteFromIfTableExists(in_table_name => 'dataview_scenario_run');

	DeleteFromIfTableExists(in_table_name => 'dataview_arbitrary_period');

	DeleteFromIfTableExists(in_table_name => 'dataview_arbitrary_period_hist');

	DeleteFromIfTableExists(in_table_name => 'dataview_history');

	-- Early delete, as references dataview
	DeleteFromIfTableExists(in_table_name => 'auto_exp_retrieval_dataview');

	DeleteFromIfTableExists(in_table_name => 'dataview');

	DeleteFromIfTableExists(in_table_name => 'default_rss_feed');

	DeleteFromIfTableExists(in_table_name => 'region_proc_doc');

	DeleteFromIfTableExists(in_table_name => 'calendar_event');

	DeleteFromIfTableExists(in_table_name => 'teamroom_issue');

	DeleteFromIfTableExists(in_table_name => 'teamroom_member');

	DeleteFromIfTableExists(in_table_name => 'teamroom_initiative');

	DeleteFromIfTableExists(in_table_name => 'teamroom_user_msg');

	DeleteFromIfTableExists(in_table_name => 'teamroom');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_sched_saved_doc');

	DeleteFromIfTableExists(in_table_name => 'batch_job_templated_report');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_schedule_region');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_schedule');

	DeleteFromIfTableExists(in_table_name => 'doc');

	DeleteFromIfTableExists(in_table_name => 'doc_type');

	DeleteFromIfTableExists(in_table_name => 'doc_data');

	UPDATE initiative
	   SET doc_library_sid = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'doc_library');

/*
TODO:

ORA-02292: integrity constraint (CSR.FK_DOC_FOLD_DOC_FOLD_SUB) violated - child record found
ORA-06512: at "CSR.CSR_DATA_PKG", line 752
ORA-06512: at line 1
ORA-06512: at "SECURITY.SECURABLEOBJECT_PKG", line 202
ORA-06512: at line 26
*/
	DELETE FROM doc_folder_subscription
	 WHERE doc_folder_sid IN (
		SELECT doc_folder_sid FROM doc_folder WHERE app_sid = v_app_sid
	 );
	CommitAndLogIfRequired(in_table_name => 'doc_folder_subscription');

	DeleteFromIfTableExists(in_table_name => 'section_module');

	DELETE FROM doc_folder_name_translation
	 WHERE doc_folder_sid IN (
		SELECT doc_folder_sid FROM doc_folder WHERE app_sid = v_app_sid
	 );
	CommitAndLogIfRequired(in_table_name => 'doc_folder_name_translation');

	DeleteFromIfTableExists(in_table_name => 'doc_folder');

	DeleteFromIfTableExists(in_table_name => 'feed');

	DeleteFromIfTableExists(in_table_name => 'file_upload');

	DeleteFromIfTableExists(in_table_name => 'form');

	DeleteFromIfTableExists(in_table_name => 'scenario_run_snapshot_region');

	DeleteFromIfTableExists(in_table_name => 'scenario_run_snapshot_ind');

	UPDATE scenario_run_snapshot
	   SET version = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'scenario_run_snapshot_file');

	DeleteFromIfTableExists(in_table_name => 'scenario_run_snapshot');

	UPDATE scenario_run
	   SET version = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'scenario_run_version_file');

	DeleteFromIfTableExists(in_table_name => 'scenario_run_version');

	UPDATE scenario
	   SET auto_update_run_sid = NULL
	 WHERE app_sid = v_app_sid;

	-- no constraints
	UPDATE customer
	   SET self_reg_approver_sid = NULL,
		   unmerged_scenario_run_sid = NULL,
		   merged_scenario_run_sid = NULL,
	   	   reporting_ind_root_sid = NULL,
		   chemical_flow_sid = NULL,
		   property_flow_sid = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'calc_job_ind');

	DeleteFromIfTableExists(in_table_name => 'calc_job_aggregate_ind_group');

	DeleteFromIfTableExists(in_table_name => 'aggregate_ind_calc_job');

	DeleteFromIfTableExists(in_table_name => 'calc_job');

	DeleteFromIfTableExists(in_table_name => 'calc_job_fetch_stat');

	DeleteFromIfTableExists(in_table_name => 'calc_job_stat');

	DeleteFromIfTableExists(in_table_name => 'batch_job_like_for_like');

	DeleteFromIfTableExists(in_table_name => 'like_for_like_email_sub');

	DeleteFromIfTableExists(in_table_name => 'like_for_like_scenario_alert');

	DeleteFromIfTableExists(in_table_name => 'like_for_like_excluded_regions');

	DeleteFromIfTableExists(in_table_name => 'like_for_like_slot');

	UPDATE csr.flow_item
	   SET dashboard_instance_id = null
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'approval_dashboard_val_src');

	DeleteFromIfTableExists(in_table_name => 'approval_dashboard_val');

	DeleteFromIfTableExists(in_table_name => 'approval_dashboard_instance');

	DeleteFromIfTableExists(in_table_name => 'approval_dashboard_region');

	DeleteFromIfTableExists(in_table_name => 'approval_dashboard_tab');

	DeleteFromIfTableExists(in_table_name => 'approval_dashboard_ind');

	DeleteFromIfTableExists(in_table_name => 'approval_dashboard');

	DeleteFromIfTableExists(in_table_name => 'approval_dashboard');

	DeleteFromIfTableExists(in_table_name => 'forecasting_rule');

	DeleteFromIfTableExists(in_table_name => 'scenario_like_for_like_rule');

	DeleteFromIfTableExists(in_table_name => 'scenario_rule_like_contig_ind');

	DeleteFromIfTableExists(in_table_name => 'scenario_rule_ind');

	DeleteFromIfTableExists(in_table_name => 'scenario_rule_region');

	DeleteFromIfTableExists(in_table_name => 'scenario_rule');

	DeleteFromIfTableExists(in_table_name => 'scenario_region');

	DeleteFromIfTableExists(in_table_name => 'scenario_ind');

	DeleteFromIfTableExists(in_table_name => 'scenario_run');

	DeleteFromIfTableExists(in_table_name => 'scenario_auto_run_request');

	DeleteFromIfTableExists(in_table_name => 'scenario');

	DeleteFromIfTableExists(in_table_name => 'imp_session');

	DeleteFromIfTableExists(in_table_name => 'aggregate_ind_val_detail');

	DeleteFromIfTableExists(in_table_name => 'ind_flag');

	DeleteFromIfTableExists(in_table_name => 'ind_description');

	DeleteFromIfTableExists(in_table_name => 'ind_sel_group_member_desc');

	DeleteFromIfTableExists(in_table_name => 'ind_selection_group_member');

	DeleteFromIfTableExists(in_table_name => 'ind_selection_group');

	DeleteFromIfTableExists(in_table_name => 'issue_type_aggregate_ind_grp');

	DeleteFromIfTableExists(in_table_name => 'batch_job_data_bucket_agg_ind');

	UPDATE flow
	   SET aggregate_ind_group_id = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'aggregate_ind_group_audit_log');
	
	DeleteFromIfTableExists(in_table_name => 'aggregate_ind_group_member');

	DeleteFromIfTableExists(in_table_name => 'aggregate_ind_group');

	DeleteFromIfTableExists(in_table_name => 'ind_set_ind');

	DeleteFromIfTableExists(in_table_name => 'duff_meter_region');

	DeleteFromIfTableExists(in_table_name => 'issue_custom_field_opt_sel');

	DeleteFromIfTableExists(in_table_name => 'issue_custom_field_str_val');

	DeleteFromIfTableExists(in_table_name => 'issue_log_read');

	DeleteFromIfTableExists(in_table_name => 'issue_log_file');

	UPDATE issue
	   SET first_issue_log_id = NULL,
	       last_issue_log_id = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'issue_log');

	DeleteFromIfTableExists(in_table_name => 'issue_involvement');

	DeleteFromIfTableExists(in_table_name => 'issue_user_cover');

	DeleteFromIfTableExists(in_table_name => 'issue_custom_field_date_val');

	DeleteFromIfTableExists(in_table_name => 'issue_raise_alert');

	DeleteFromIfTableExists(in_table_name => 'issue_alert');

	DeleteFromIfTableExists(in_table_name => 'issue');

	DeleteFromIfTableExists(in_table_name => 'issue_template_cust_field_opt');

	DeleteFromIfTableExists(in_table_name => 'issue_template_custom_field');
	
	DeleteFromIfTableExists(in_table_name => 'issue_custom_field_option');

	DeleteFromIfTableExists(in_table_name => 'issue_custom_field');

	DeleteFromIfTableExists(in_table_name => 'inbound_issue_account');

	DeleteFromIfTableExists(in_table_name => 'issue_due_source');

	DeleteFromIfTableExists(in_table_name => 'issue_template');

	DeleteFromIfTableExists(in_table_name => 'issue_type');

	DeleteFromIfTableExists(in_table_name => 'issue_meter_missing_data');

	DeleteFromIfTableExists(in_table_name => 'correspondent');

	DeleteFromIfTableExists(in_table_name => 'pct_ownership_change');

	DeleteFromIfTableExists(in_table_name => 'objective');

	DeleteFromIfTableExists(in_table_name => 'option_item');

	DeleteFromIfTableExists(in_table_name => 'pending_dataset');

	DeleteFromIfTableExists(in_table_name => 'scenario_region');

	DeleteFromIfTableExists(in_table_name => 'property_tab_group');

	DeleteFromIfTableExists(in_table_name => 'property_tab');

	DeleteFromIfTableExists(in_table_name => 'lease_property ');

	UPDATE all_space
	   SET current_lease_id = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'lease_space');

	DeleteFromIfTableExists(in_table_name => 'lease');

	DeleteFromIfTableExists(in_table_name => 'property_photo');

	DeleteFromIfTableExists(in_table_name => 'all_space');

	DeleteFromIfTableExists(in_table_name => 'all_property');

	DeleteFromIfTableExists(in_table_name => 'property_element_layout');

	DeleteFromIfTableExists(in_table_name => 'property_character_layout');

	DeleteFromIfTableExists(in_table_name => 'property_address_options');

	DeleteFromIfTableExists(in_table_name => 'mgmt_company_contact');

	DeleteFromIfTableExists(in_table_name => 'mgmt_company');

	DeleteFromIfTableExists(in_table_name => 'property_options');

	DeleteFromIfTableExists(in_table_name => 'geo_map_region');

	DeleteFromIfTableExists(in_table_name => 'geo_map_tab_chart');

	DeleteFromIfTableExists(in_table_name => 'geo_map_tab');

	DeleteFromIfTableExists(in_table_name => 'geo_map');

	DeleteFromIfTableExists(in_table_name => 'customer_geo_map_tab_type');

	DeleteFromIfTableExists(in_table_name => 'meter_tab_group');

	DeleteFromIfTableExists(in_table_name => 'meter_tab');

	DeleteFromIfTableExists(in_table_name => 'meter_header_element');

	DeleteFromIfTableExists(in_table_name => 'compliance_permit_tab_group ');

	DeleteFromIfTableExists(in_table_name => 'compliance_permit_tab');

	DeleteFromIfTableExists(in_table_name => 'teamroom_type_tab_group');

	DeleteFromIfTableExists(in_table_name => 'teamroom_type_tab');

	DeleteFromIfTableExists(in_table_name => 'initiative_project_tab_group');

	DeleteFromIfTableExists(in_table_name => 'initiative_project_tab');

	DeleteFromIfTableExists(in_table_name => 'plugin');

	DeleteFromIfTableExists(in_table_name => 'region_description');

	DeleteFromIfTableExists(in_table_name => 'region_set_region');

	DeleteFromIfTableExists(in_table_name => 'region_event');

	DeleteFromIfTableExists(in_table_name => 'snapshot_region');

	DeleteFromIfTableExists(in_table_name => 'project_init_metric_flow_state');

	DeleteFromIfTableExists(in_table_name => 'initiative_metric_assoc');

	DeleteFromIfTableExists(in_table_name => 'project_initiative_metric');

	DeleteFromIfTableExists(in_table_name => 'project_initiative_period_stat');

	DeleteFromIfTableExists(in_table_name => 'project_tag_filter');

	DeleteFromIfTableExists(in_table_name => 'project_tag_group');

	DeleteFromIfTableExists(in_table_name => 'initiative_comment');

	DeleteFromIfTableExists(in_table_name => 'initiative_group_member');

	DeleteFromIfTableExists(in_table_name => 'initiative_period');

	DeleteFromIfTableExists(in_table_name => 'initiative_project_team');

	DeleteFromIfTableExists(in_table_name => 'initiative_sponsor');

	DeleteFromIfTableExists(in_table_name => 'initiative_region');

	DeleteFromIfTableExists(in_table_name => 'initiative_tag');

	DeleteFromIfTableExists(in_table_name => 'initiative_user_msg');

	DeleteFromIfTableExists(in_table_name => 'initiative_user');

	UPDATE issue
	   SET issue_initiative_id = null
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'issue_initiative');

	DeleteFromIfTableExists(in_table_name => 'initiative_event');

	DeleteFromIfTableExists(in_table_name => 'initiative_metric_state_ind');
	
	DeleteFromIfTableExists(in_table_name => 'initiative_metric_tag_ind');

	DeleteFromIfTableExists(in_table_name => 'initiative_metric');

	DeleteFromIfTableExists(in_table_name => 'initiative');

	DeleteFromIfTableExists(in_table_name => 'chem.substance_process_use_file');

	DeleteFromIfTableExists(in_table_name => 'chem.subst_process_cas_dest_change');

	DeleteFromIfTableExists(in_table_name => 'chem.process_cas_default');

	DeleteFromIfTableExists(in_table_name => 'chem.substance_process_cas_dest');

	DeleteFromIfTableExists(in_table_name => 'chem.substance_process_use');

	DeleteFromIfTableExists(in_table_name => 'chem.substance_process_use_change');

	DeleteFromIfTableExists(in_table_name => 'chem.substance_audit_log');

	DeleteFromIfTableExists(in_table_name => 'chem.substance_cas');

	DeleteFromIfTableExists(in_table_name => 'chem.substance_file');

	DeleteFromIfTableExists(in_table_name => 'chem.substance_region_process');

	DeleteFromIfTableExists(in_table_name => 'chem.usage_audit_log');

	DeleteFromIfTableExists(in_table_name => 'chem.substance_region');

	DeleteFromIfTableExists(in_table_name => 'chem.substance');

	DeleteFromIfTableExists(in_table_name => 'chem.cas_group_member');

	DeleteFromIfTableExists(in_table_name => 'chem.cas_restricted');

	DeleteFromIfTableExists(in_table_name => 'chem.cas');

	DeleteFromIfTableExists(in_table_name => 'chem.chem_options');

		-- Compliance
	DeleteFromIfTableExists(in_table_name => 'compliance_alert');

	DeleteFromIfTableExists(in_table_name => 'compliance_audit_log');

	DeleteFromIfTableExists(in_table_name => 'compliance_item_region');

	DeleteFromIfTableExists(in_table_name => 'compliance_req_reg');

	DeleteFromIfTableExists(in_table_name => 'compliance_regulation');

	DeleteFromIfTableExists(in_table_name => 'compliance_requirement');

	DeleteFromIfTableExists(in_table_name => 'compl_permit_application_pause');

	DeleteFromIfTableExists(in_table_name => 'compliance_permit_application');

	UPDATE internal_audit
	   SET permit_id = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'compliance_item_rollout');

	DeleteFromIfTableExists(in_table_name => 'compliance_permit_condition');

	DeleteFromIfTableExists(in_table_name => 'compliance_item_tag');

	DeleteFromIfTableExists(in_table_name => 'compliance_item_version_log');

	DeleteFromIfTableExists(in_table_name => 'compliance_item_description');

	DeleteFromIfTableExists(in_table_name => 'compliance_item_desc_hist');

	DeleteFromIfTableExists(in_table_name => 'compliance_rollout_regions');
	
	DeleteFromIfTableExists(in_table_name => 'compliance_item');

	DeleteFromIfTableExists(in_table_name => 'compliance_root_regions');

	DeleteFromIfTableExists(in_table_name => 'compliance_permit_history ');

	DeleteFromIfTableExists(in_table_name => 'compliance_permit');

	DeleteFromIfTableExists(in_table_name => 'compliance_permit_sub_type');

	DeleteFromIfTableExists(in_table_name => 'compliance_permit_type ');

	DeleteFromIfTableExists(in_table_name => 'compliance_condition_sub_type');

	DeleteFromIfTableExists(in_table_name => 'compliance_condition_type');

	DeleteFromIfTableExists(in_table_name => 'compliance_activity_sub_type');

	DeleteFromIfTableExists(in_table_name => 'compliance_activity_type');

	DeleteFromIfTableExists(in_table_name => 'compliance_application_type');

	DeleteFromIfTableExists(in_table_name => 'compliance_region_tag');

	DeleteFromIfTableExists(in_table_name => 'compliance_language');

	DeleteFromIfTableExists(in_table_name => 'enhesa_options');

	DeleteFromIfTableExists(in_table_name => 'enhesa_error_log');

	DeleteFromIfTableExists(in_table_name => 'flow_item_audit_log');

	DeleteFromIfTableExists(in_table_name => 'flow_item_subscription');

	DeleteFromIfTableExists(in_table_name => 'activity_post');

	DeleteFromIfTableExists(in_table_name => 'activity_member');

	DeleteFromIfTableExists(in_table_name => 'activity');

	DeleteFromIfTableExists(in_table_name => 'flow_state_log_file');

	DeleteFromIfTableExists(in_table_name => 'flow_item_involvement');

	DeleteFromIfTableExists(in_table_name => 'flow_item_region');

	UPDATE flow_item
	   SET survey_response_id = NULL,
	       dashboard_instance_id = NULL,
	       last_flow_state_log_id = NULL,
	       last_flow_state_transition_id = NULL
	 WHERE app_sid = v_app_sid;

	-- stupid circular dependencies mean we can't commit this next one until after flow item is also deleted
	DeleteFromIfTableExists(in_table_name => 'flow_state_log', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'flow_item');

	DeleteFromIfTableExists(in_table_name => 'event');

	DeleteFromIfTableExists(in_table_name => 'region_proc_file');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_schedule_region');

	DeleteFromIfTableExists(in_table_name => 'aggr_region');

	DeleteFromIfTableExists(in_table_name => 'aggr_tag_group_member');

	DeleteFromIfTableExists(in_table_name => 'aggr_tag_group');

	UPDATE csr_user
	   SET primary_region_sid = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'core_working_hours_region');

	DeleteFromIfTableExists(in_table_name => 'secondary_region_tree_log');

	DeleteFromIfTableExists(in_table_name => 'secondary_region_tree_ctrl');

	DeleteFromIfTableExists(in_table_name => 'user_profile');

	DeleteFromIfTableExists(in_table_name => 'auto_imp_region_map');

	DeleteFromIfTableExists(in_table_name => 'deleg_report_region');

	DeleteFromIfTableExists(in_table_name => 'deleg_report');

	DeleteFromIfTableExists(in_table_name => 'ruleset_run_finding');

	DeleteFromIfTableExists(in_table_name => 'ruleset_run');

	-- Data buckets
	UPDATE data_bucket
	   SET active_instance_id = null
	 WHERE app_sid = v_app_sid;
	
	DeleteFromIfTableExists(in_table_name => 'data_bucket_val');
	DeleteFromIfTableExists(in_table_name => 'data_bucket_source_detail');
	DeleteFromIfTableExists(in_table_name => 'data_bucket_instance');
	DeleteFromIfTableExists(in_table_name => 'data_bucket');

	DeleteFromIfTableExists(in_table_name => 'internal_audit_listener_last_update');

	DeleteFromIfTableExists(in_table_name => 'initiative_import_template_map');

	DeleteFromIfTableExists(in_table_name => 'initiative_import_template');

	DeleteFromIfTableExists(in_table_name => 'integration_question_answer');

	DeleteFromIfTableExists(in_table_name => 'ruleset_member');

	DeleteFromIfTableExists(in_table_name => 'ruleset');
	
	DeleteFromIfTableExists(in_table_name => 'module_history');

	-- region certificates and ratings
	DeleteFromIfTableExists(in_table_name => 'region_certificate');
	DeleteFromIfTableExists(in_table_name => 'region_energy_rating');

	
	DeleteFromIfTableExists(in_table_name => 'emission_factor_profile_factor');

	DeleteFromIfTableExists(in_table_name => 'emission_factor_profile');

	DeleteFromIfTableExists(in_table_name => 'custom_factor');

	DeleteFromIfTableExists(in_table_name => 'custom_factor_set');


	DeleteFromIfTableExists(in_table_name => 'function_course');
	
	DeleteFromIfTableExists(in_table_name => 'function');
	

	DeleteFromIfTableExists(in_table_name => 'course_type_region');

	DeleteFromIfTableExists(in_table_name => 'course');

	DeleteFromIfTableExists(in_table_name => 'course_type');

	DeleteFromIfTableExists(in_table_name => 'user_relationship');

	DeleteFromIfTableExists(in_table_name => 'user_relationship_type');

	DeleteFromIfTableExists(in_table_name => 'auto_imp_core_data_val_fail');

	IF in_reduce_contention = 1 THEN
		FOR r IN (
			SELECT * FROM (
				SELECT region_sid, level lvl, rowid rid
				  FROM region
					   START WITH app_sid = v_app_sid AND parent_sid IN (
							SELECT region_root_sid
							  FROM customer
							 WHERE app_sid = v_app_sid
							 UNION
							SELECT trash_sid
							  FROM customer
							 WHERE app_sid = v_app_sid
						)
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
				)
			ORDER BY lvl DESC
		) LOOP
			v_region_sid := r.region_sid;
			DELETE FROM region
			 WHERE rowid = r.rid;
			COMMIT;
			IF in_debug_log_deletes = 1 THEN
				security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - Deleted region :' || v_region_sid);
			END IF;

		END LOOP;
	END IF;

	DeleteFromIfTableExists(in_table_name => 'audit_log', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'flow_state_transition_role');

	DeleteFromIfTableExists(in_table_name => 'flow_state_transition_inv');

	DeleteFromIfTableExists(in_table_name => 'flow_state_transition');

	DeleteFromIfTableExists(in_table_name => 'flow_state_trans_helper');

	DeleteFromIfTableExists(in_table_name => 'flow_state_role_capability');

	DeleteFromIfTableExists(in_table_name => 'flow_state_role');

	DeleteFromIfTableExists(in_table_name => 'flow_state_involvement');

	DeleteFromIfTableExists(in_table_name => 'flow_state_group_member');

	DeleteFromIfTableExists(in_table_name => 'flow_state_group');

	DeleteFromIfTableExists(in_table_name => 'flow_state_survey_tag');

	DeleteFromIfTableExists(in_table_name => 'project_init_metric_flow_state');

	DeleteFromIfTableExists(in_table_name => 'init_tab_element_layout');

	DeleteFromIfTableExists(in_table_name => 'init_create_page_el_layout ');

	DeleteFromIfTableExists(in_table_name => 'initiative_header_element ');

	DeleteFromIfTableExists(in_table_name => 'initiative_metric_assoc');

	DeleteFromIfTableExists(in_table_name => 'project_initiative_metric');

	DeleteFromIfTableExists(in_table_name => 'initiative_metric_group');

	DeleteFromIfTableExists(in_table_name => 'project_doc_folder');

	DeleteFromIfTableExists(in_table_name => 'initiative_project_rag_status');

	DeleteFromIfTableExists(in_table_name => 'initiative_project');

	DeleteFromIfTableExists(in_table_name => 'flow_inv_type_alert_class');

	DeleteFromIfTableExists(in_table_name => 'flow_involvement_type');

	DeleteFromIfTableExists(in_table_name => 'delegation_plugin');

	DeleteFromIfTableExists(in_table_name => 'space_type_region_metric');

	DeleteFromIfTableExists(in_table_name => 'region_type_metric');

	DeleteFromIfTableExists(in_table_name => 'region_metric');

	DeleteFromIfTableExists(in_table_name => 'activity_sub_type');

	DeleteFromIfTableExists(in_table_name => 'activity_type');

	DeleteFromIfTableExists(in_table_name => 'training_options');

	DeleteFromIfTableExists(in_table_name => 'r_report_file');

	DeleteFromIfTableExists(in_table_name => 'r_report');

	DeleteFromIfTableExists(in_table_name => 'r_report_job');

	DeleteFromIfTableExists(in_table_name => 'r_report_type');

	DeleteFromIfTableExists(in_table_name => 'role_grant');

	DeleteFromIfTableExists(in_table_name => 'user_profile_default_role');

	DeleteFromIfTableExists(in_table_name => 'role');

	DeleteFromIfTableExists(in_table_name => 'rss_feed');

	DeleteFromIfTableExists(in_table_name => 'section_transition');

	DeleteFromIfTableExists(in_table_name => 'section_status');

	DeleteFromIfTableExists(in_table_name => 'session_extra');

	UPDATE customer
	   SET trucost_portlet_tab_id = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'snapshot');

	DeleteFromIfTableExists(in_table_name => 'tab');

	DeleteFromIfTableExists(in_table_name => 'tag_description');

	DeleteFromIfTableExists(in_table_name => 'tag');

	DeleteFromIfTableExists(in_table_name => 'region_type_tag_group	');

	DeleteFromIfTableExists(in_table_name => 'tag_group_description');

	DeleteFromIfTableExists(in_table_name => 'tag_group');

	DeleteFromIfTableExists(in_table_name => 'target_dashboard');

	DeleteFromIfTableExists(in_table_name => 'metric_dashboard');

	DeleteFromIfTableExists(in_table_name => 'benchmark_dashboard');

	DeleteFromIfTableExists(in_table_name => 'template');

	DeleteFromIfTableExists(in_table_name => 'tpl_img');

	DeleteFromIfTableExists(in_table_name => 'batch_job_templated_report');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_schedule');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_variant_tag');

	DeleteFromIfTableExists(in_table_name => 'tpl_report_variant');

	DeleteFromIfTableExists(in_table_name => 'tpl_report');

	DeleteFromIfTableExists(in_table_name => 'tpl_rep_cust_tag_type');

	DeleteFromIfTableExists(in_table_name => 'trash');

	DeleteFromIfTableExists(in_table_name => 'donations.customer_filter_flag');

	DeleteFromIfTableExists(in_table_name => 'donations.scheme_donation_status');

	DeleteFromIfTableExists(in_table_name => 'donations.donation_status');

	DeleteFromIfTableExists(in_table_name => 'donations.filter');

	DeleteFromIfTableExists(in_table_name => 'donations.letter_template');

	DeleteFromIfTableExists(in_table_name => 'donations.tag');

	DeleteFromIfTableExists(in_table_name => 'donations.tag_group');

	DeleteFromIfTableExists(in_table_name => 'supplier.alert_batch');

	DeleteFromIfACTableExists(in_table_name => 'supplier.supplier_answers');

	DeleteFromIfACTableExists(in_table_name => 'supplier.supplier_answers_wood');

	DeleteFromIfACTableExists(in_table_name => 'supplier.fsc_member');

	DeleteFromIfTableExists(in_table_name => 'supplier.all_company');

	DeleteFromIfTableExists(in_table_name => 'supplier.customer_period');

	DeleteFromIfTableExists(in_table_name => 'imp_vocab');

	DeleteFromIfTableExists(in_table_name => 'user_cover ');

	DeleteFromIfTableExists(in_table_name => 'flow_transition_alert_user');

	DeleteFromIfTableExists(in_table_name => 'flow_transition_alert_cc_user');

	DeleteFromIfTableExists(in_table_name => 'region_set');
/*

	DeleteFromIfTableExists(in_table_name => 'cms.app_schema');

	DeleteFromIfTableExists(in_table_name => 'cms.app_schema_table');
*/

	DeleteFromIfTableExists(in_table_name => 'accuracy_type_option');

	DeleteFromIfTableExists(in_table_name => 'accuracy_type');

	DeleteFromIfTableExists(in_table_name => 'logistics_error_log');

	DeleteFromIfTableExists(in_table_name => 'logistics_tab_mode');

	DeleteFromIfTableExists(in_table_name => 'custom_location');

	DeleteFromIfTableExists(in_table_name => 'custom_distance');

	DeleteFromIfTableExists(in_table_name => 'logistics_default');

	DeleteFromIfTableExists(in_table_name => 'cms.image ');

	DeleteFromIfTableExists(in_table_name => 'issue_priority');

	DeleteFromIfTableExists(in_table_name => 'var_expl');

	DeleteFromIfTableExists(in_table_name => 'var_expl_group');

	DeleteFromIfTableExists(in_table_name => 'meter_document');

	DeleteFromIfTableExists(in_table_name => 'alert_bounce');

	DeleteFromIfTableExists(in_table_name => 'alert', in_loop_count => 10000);

	DeleteFromIfTableExists(in_table_name => 'calendar');

	DeleteFromIfTableExists(in_table_name => 'batch_job_cms_import');

	DeleteFromIfTableExists(in_table_name => 'batch_job_approval_dash_vals');

	DeleteFromIfTableExists(in_table_name => 'supplier.gt_target_scores_log');

	DeleteFromIfTableExists(in_table_name => 'supplier.customer_options');

	DeleteFromIfTableExists(in_table_name => 'ind_set');

	DeleteFromIfTableExists(in_table_name => 'actions.import_mapping_mru');

	DeleteFromIfTableExists(in_table_name => 'route_log');

	DeleteFromIfTableExists(in_table_name => 'util_script_run_log');

	DeleteFromIfTableExists(in_table_name => 'user_profile_staged_record');

	-- *** automated_import_class ***

	-- fk's to automated_import_instance
	DeleteFromIfTableExists(in_table_name => 'automated_import_manual_file');
	DeleteFromIfTableExists(in_table_name => 'auto_import_message_map');

	--fk's to automated_import_class_step
	DeleteFromIfTableExists(in_table_name => 'auto_imp_core_data_settings');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_importer_settings');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_user_imp_settings');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_zip_settings');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_product_settings');
	DeleteFromIfTableExists(in_table_name => 'automated_import_instance_step');
	DeleteFromIfTableExists(in_table_name => 'user_profile_default_group');

	-- fk's to automated_import_class
	DeleteFromIfTableExists(in_table_name => 'auto_imp_mail_file');
	DeleteFromIfTableExists(in_table_name => 'automated_import_class_step');
	DeleteFromIfTableExists(in_table_name => 'automated_import_instance');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_indicator_map');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_region_map');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_unit_map');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_zip_filter');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_mail');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_mail_sender_filter');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_mail_attach_filter');
	DeleteFromIfTableExists(in_table_name => 'auto_imp_mailbox');
	-- meter_raw_data_source

	DeleteFromIfTableExists(in_table_name => 'automated_import_class');

	--fk's to auto_imp_importer_cms
	-- automated_import_file_type
	DeleteFromIfTableExists(in_table_name => 'auto_imp_importer_cms');

	--fk's to auto_imp_fileread_ftp
	-- automated_import_class_step
	DeleteFromIfTableExists(in_table_name => 'auto_imp_fileread_ftp');

	--fk's to auto_imp_fileread_db
	-- automated_import_class_step
	DeleteFromIfTableExists(in_table_name => 'auto_imp_fileread_db');

	
	
	-- *** automated_export_class ***

	DeleteFromIfTableExists(in_table_name => 'auto_export_message_map');

	-- fk's to automated_export_class
	DeleteFromIfTableExists(in_table_name => 'auto_exp_batched_exp_settings');
	DeleteFromIfTableExists(in_table_name => 'automated_export_instance');

	DeleteFromIfTableExists(in_table_name => 'automated_export_class');

	DeleteFromIfTableExists(in_table_name => 'auto_exp_filecreate_dsv');

	-- fk's to auto_exp_filewrite_ftp
	-- automated_export_class
	DeleteFromIfTableExists(in_table_name => 'auto_exp_filewrite_ftp');

	-- fk's to ftp_profile
	-- auto_imp_fileread_ftp
	-- auto_exp_filewrite_ftp
	DeleteFromIfTableExists(in_table_name => 'ftp_profile');

	-- fk's to 30 records
	-- auto_imp_unit_map
	DeleteFromIfTableExists(in_table_name => 'measure_conversion');


	DeleteFromIfTableExists(in_table_name => 'batch_job_batched_export');

	DeleteFromIfTableExists(in_table_name => 'batch_job_meter_extract');

	DeleteFromIfTableExists(in_table_name => 'batch_job_srt_refresh');

	DeleteFromIfTableExists(in_table_name => 'batch_job_batched_import');

	DeleteFromIfTableExists(in_table_name => 'batch_job');

	DeleteFromIfTableExists(in_table_name => 'batch_job_type_app_cfg');

	DeleteFromIfTableExists(in_table_name => 'batch_job_type_app_stat');


	DeleteFromIfTableExists(in_table_name => 'std_factor_set_active');

	DeleteFromIfTableExists(in_table_name => 'user_msg_file');

	DeleteFromIfTableExists(in_table_name => 'user_msg_like');

	DeleteFromIfTableExists(in_table_name => 'initiative_user_msg');

	DeleteFromIfTableExists(in_table_name => 'user_msg');

	DeleteFromIfTableExists(in_table_name => 'initiative_import_map_mru');

	DeleteFromIfTableExists(in_table_name => 'cookie_policy_consent');

	DeleteFromIfTableExists(in_table_name => 'user_inactive_sys_alert');
	
	DeleteFromIfTableExists(in_table_name => 'external_target_profile');
	
	DeleteFromIfTableExists(in_table_name => 'credential_management');

	DeleteFromIfTableExists(in_table_name => 'baseline_config_period');

	DeleteFromIfTableExists(in_table_name => 'baseline_config');

	UPDATE csr_user
	   SET line_manager_sid = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'site_audit_details_expiry');
	DeleteFromIfTableExists(in_table_name => 'site_audit_details_client_name');
	DeleteFromIfTableExists(in_table_name => 'site_audit_details_reason');
	DeleteFromIfTableExists(in_table_name => 'site_audit_details_contract_ref');

	DeleteFromIfTableExists(in_table_name => 'csr_user', in_loop_count => 1000);

	-- zap the trash first to account for web resources in the trash
	-- (they aren't supposed to live outside the tree rooted at web_root_sid_id)
	BEGIN
		SELECT trash_sid
		INTO v_trash_sid
		FROM customer
		WHERE app_sid = v_app_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	DeleteFromIfTableExists(in_table_name => 'cms.tag');

	DeleteFromIfTableExists(in_table_name => 'qs_custom_question_type');

	DeleteFromIfTableExists(in_table_name => 'period_span_pattern');

	DeleteFromIfTableExists(in_table_name => 'period_interval_member');

	DeleteFromIfTableExists(in_table_name => 'period_dates');

	DeleteFromIfTableExists(in_table_name => 'period');

	DeleteFromIfTableExists(in_table_name => 'meter_alarm');

	DeleteFromIfTableExists(in_table_name => 'meter_alarm_comparison');

	DeleteFromIfTableExists(in_table_name => 'meter_alarm_issue_period');

	DeleteFromIfTableExists(in_table_name => 'meter_alarm_statistic');

	DeleteFromIfTableExists(in_table_name => 'meter_alarm_test_time');

	DeleteFromIfTableExists(in_table_name => 'meter_bucket');

	DeleteFromIfTableExists(in_table_name => 'meter_data_priority');

	DeleteFromIfTableExists(in_table_name => 'meter_patch_data');

	DeleteFromIfTableExists(in_table_name => 'meter_input_aggregator');

	DeleteFromIfTableExists(in_table_name => 'meter_input');

	DeleteFromIfTableExists(in_table_name => 'alert_image');

	DeleteFromIfTableExists(in_table_name => 'initiatives_options');

	DeleteFromIfTableExists(in_table_name => 'customer_init_saving_type');

	DeleteFromIfTableExists(in_table_name => 'period_span_pattern');

	DeleteFromIfTableExists(in_table_name => 'initiative_metric');

	DeleteFromIfTableExists(in_table_name => 'customer_file_upload_type_opt');

	DeleteFromIfTableExists(in_table_name => 'customer_file_upload_mime_opt');

	DeleteFromIfTableExists(in_table_name => 'aggregation_period');

	DeleteFromIfTableExists(in_table_name => 'flow_alert_helper');

	DeleteFromIfTableExists(in_table_name => 'plugin_indicator');

	DeleteFromIfTableExists(in_table_name => 'worksheet_value_map_value');

	DeleteFromIfTableExists(in_table_name => 'worksheet_value_map');

	DeleteFromIfTableExists(in_table_name => 'teamroom_type');

	DeleteFromIfTableExists(in_table_name => 'core_working_hours_day');

	DeleteFromIfTableExists(in_table_name => 'core_working_hours');

	DeleteFromIfTableExists(in_table_name => 'default_initiative_user_state');

	UPDATE flow
	   SET default_state_id = NULL
	 WHERE app_sid = v_app_sid;
	
  	-- stupid circular dependencies mean we can't commit this next one until after flow is also deleted
	DeleteFromIfTableExists(in_table_name => 'flow_state', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'flow');

	DeleteFromIfTableExists(in_table_name => 'customer_flow_alert_class');

	DeleteFromIfTableExists(in_table_name => 'image_upload_portlet');

	DeleteFromIfTableExists(in_table_name => 'gresb_submission_log');

	DeleteFromIfTableExists(in_table_name => 'compliance_rollout_regions');

	DeleteFromIfTableExists(in_table_name => 'intapi_company_user_group');

	UPDATE scheduled_stored_proc
	   SET last_ssp_log_id = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'scheduled_stored_proc_log');

	DeleteFromIfTableExists(in_table_name => 'scheduled_stored_proc');

	DeleteFromIfTableExists(in_table_name => 'osha_mapping');

	DeleteFromIfTableExists(in_table_name => 'sys_translations_audit_log');
	DeleteFromIfTableExists(in_table_name => 'sys_translations_audit_data');

-- this section cannot have any commits

	UPDATE ind
	   SET map_to_ind_sid = NULL,
	   	   gas_type_id = NULL,
		   prop_down_region_tree_sid = NULL
	 WHERE app_sid = v_app_sid;

	UPDATE customer
	   SET region_root_sid = null,
	   	   ind_root_sid = null,
		   current_reporting_period_sid = NULL
	 WHERE app_sid = v_app_sid;

	DeleteFromIfTableExists(in_table_name => 'region', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'region_type_tag_group', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'customer_region_type', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'region_tree', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'ind', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'measure', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'period_interval', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'period_set', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'reporting_period', in_commit_after_delete => 0);

	DeleteFromIfTableExists(in_table_name => 'customer', in_commit_after_delete => 0);

	-- won't be a customer row to log in against, so don't until the end. Rollback if it fails shouldn't be too bad.

	aspen2.tr_pkg.DeleteAllTranslations(SYS_CONTEXT('SECURITY', 'APP'));

	-- Now we've killed all the data, make all the CSR objects simple containers
	-- This a) speeds up deletion by not having to invoke loads of PL/SQL code
	-- and  b) stops the PL/SQL code from breaking when it finds the child rows are missing
	UPDATE security.securable_object
	   SET class_id = security_pkg.SO_CONTAINER
	 WHERE sid_id IN (SELECT sid_id
	 					FROM security.securable_object
	 					 	 START WITH parent_sid_id = v_app_sid
	 					 	 CONNECT BY PRIOR sid_id = parent_sid_id);

	IF v_trash_sid IS NOT NULL THEN
		SecurableObject_pkg.DeleteSO(v_act_id, v_trash_sid);
		IF in_debug_log_deletes = 1 THEN
			security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - Trash SO deleted');
		END IF;
	END IF;
	
	IF in_logoff_before_delete_so = 1 THEN
		security.user_pkg.logonAdmin;
		v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	END IF;

	--setting the app to null can get you out of the can't-zap-site-due-to-policy hole
	security.security_pkg.SetContext('APP', NULL);

	SecurableObject_pkg.DeleteSO(v_act_id, v_app_sid);

	-- app deleted, we can now commit if required.
	IF in_reduce_contention = 1 THEN
		COMMIT;
	END IF;
	IF in_debug_log_deletes = 1 THEN
		security.security_pkg.debugmsg('App Sid: '|| v_app_sid || ' - App SO deleted');
	END IF;
END;

PROCEDURE AddCalendarMonthPeriodSet
AS
BEGIN
	INSERT INTO period_set (period_set_id, annual_periods, label)
	VALUES (1, 1, 'Calendar months');
	
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 1, 'Jan', date '1900-01-01', date '1900-02-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 2, 'Feb', date '1900-02-01', date '1900-03-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 3, 'Mar', date '1900-03-01', date '1900-04-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 4, 'Apr', date '1900-04-01', date '1900-05-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 5, 'May', date '1900-05-01', date '1900-06-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 6, 'Jun', date '1900-06-01', date '1900-07-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 7, 'Jul', date '1900-07-01', date '1900-08-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 8, 'Aug', date '1900-08-01', date '1900-09-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 9, 'Sep', date '1900-09-01', date '1900-10-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 10, 'Oct', date '1900-10-01', date '1900-11-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 11, 'Nov', date '1900-11-01', date '1900-12-01');
	INSERT INTO period (period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES (1, 12, 'Dec', date '1900-12-01', date '1901-01-01');
	
	-- months
	INSERT INTO period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (1, 1, '{0:PL} {0:YYYY}', '{0:PL} {0:YYYY} - {1:PL} {1:YYYY}', 'Monthly', '{0:PL}');
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 1, 1);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 2, 2);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 3, 3);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 4, 4);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 5, 5);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 6, 6);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 7, 7);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 8, 8);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 9, 9);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 10, 10);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 11, 11);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 1, 12, 12);
		
	-- quarters
	INSERT INTO period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (1, 2, 'Q{0:I} {0:YYYY}', 'Q{0:I} {0:YYYY} - Q{1:I} {1:YYYY}', 'Quarterly', 'Q{0:I}');
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 2, 1, 3);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 2, 4, 6);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 2, 7, 9);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 2, 10, 12);
	
	-- halves
	INSERT INTO period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (1, 3, 'H{0:I} {0:YYYY}', 'H{0:I} {0:YYYY} - H{1:I} {1:YYYY}', 'Half-yearly', 'H{0:I}');
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 3, 1, 6);
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 3, 7, 12);

	-- years
	INSERT INTO period_interval (period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES (1, 4, '{0:YYYY}', '{0:YYYY} - {1:YYYY}', 'Annually', 'Year');
	INSERT INTO period_interval_member (period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES (1, 4, 1, 12);
END;

PROCEDURE AddStandardFramesAndTemplates
AS
BEGIN
	-- get languages that are configured for the site		  
	INSERT INTO temp_lang (lang)
		SELECT lang
		  FROM aspen2.translation_set
		 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND hidden = 0;

	-- add in the default frames
	INSERT INTO temp_alert_frame (default_alert_frame_id, alert_frame_id)
		SELECT daf.default_alert_frame_id, alert_frame_id_seq.NEXTVAL
		  FROM default_alert_frame daf, (
		  		SELECT DISTINCT default_alert_frame_id
		  		  FROM default_alert_frame_body
		  		 WHERE lang IN (SELECT lang FROM temp_lang)) dafb
		 WHERE daf.default_alert_frame_id = dafb.default_alert_frame_id;

	INSERT INTO alert_frame (alert_frame_id, name)
		SELECT taf.alert_frame_id, daf.name
		  FROM default_alert_frame daf, temp_alert_frame taf
		 WHERE daf.default_alert_frame_id = taf.default_alert_frame_id;

	INSERT INTO alert_frame_body (alert_frame_id, lang, html)
		SELECT taf.alert_frame_id, dafb.lang, dafb.html
		  FROM default_alert_frame_body dafb, temp_alert_frame taf
		 WHERE dafb.default_alert_frame_id = taf.default_alert_frame_id 
		   AND dafb.lang IN (SELECT lang FROM temp_lang);

	-- and the default templates
	INSERT INTO alert_template (customer_alert_type_id, alert_frame_id, send_type)
		SELECT cat.customer_alert_type_id, taf.alert_frame_id, dat.send_type
		  FROM default_alert_template dat, customer_alert_type cat, temp_alert_frame taf
		 WHERE cat.std_alert_type_id = dat.std_alert_type_id AND dat.default_alert_frame_id = taf.default_alert_frame_id
		   AND cat.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT cat.customer_alert_type_id, datb.lang, datb.subject, datb.body_html, datb.item_html
		  FROM default_alert_template_body datb, customer_alert_type cat
		 WHERE cat.std_alert_type_id = datb.std_alert_type_id 
		   AND datb.lang IN (SELECT lang FROM temp_lang)
		   AND cat.app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
	UPDATE alert_template alt
	   SET save_in_sent_alerts = 0
	 WHERE EXISTS (
		SELECT NULL
		  FROM customer_alert_type
		 WHERE customer_alert_type_id = alt.customer_alert_type_id
		   AND std_alert_type_id = csr_data_pkg.ALERT_PASSWORD_RESET
	);
	
END;

PROCEDURE AddApplicationTranslation(
	in_application_sid		IN	customer.app_sid%TYPE,
	in_lang_id				IN	aspen2.lang.lang_id%TYPE
)
AS
	v_lang						aspen2.lang.lang%TYPE;
	v_alert_frame_id			alert_frame.alert_frame_id%TYPE;
	v_default_alert_frame_id	default_alert_frame.default_alert_frame_id%TYPE;
BEGIN
	aspen2.tr_pkg.AddApplicationTranslation(in_application_sid, in_lang_id);

	SELECT lang
	  INTO v_lang
	  FROM aspen2.lang
	 WHERE lang_id = in_lang_id;

	-- try and find a frame to add translations for.  if we've got no frames (weird user but possible), just add all defaults.
	BEGIN
		SELECT alert_frame_id
		  INTO v_alert_frame_id
		  FROM (SELECT alert_frame_id, rownum rn
		  		  FROM (SELECT alert_frame_id
		  				  FROM alert_frame
		 				 WHERE app_sid = in_application_sid
		 				 ORDER BY DECODE(name, 'Default', 0, 1)))
		 WHERE rn = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- There are no frames, or templates, so just add the lot
			AddStandardFramesAndTemplates;
			RETURN;
	END;
		
	BEGIN
		-- try and find a default frame to copy translations from
		SELECT MIN(default_alert_frame_id)
		  INTO v_default_alert_frame_id
		  FROM default_alert_frame;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- There are no default frames, so quit
			RETURN;
	END;

	-- got a frame, add in missing translations for it
	INSERT INTO alert_frame_body (alert_frame_id, lang, html)
		SELECT v_alert_frame_id, lang, html
		  FROM default_alert_frame_body
		 WHERE default_alert_frame_id = v_default_alert_frame_id
		   AND lang = v_lang
		   AND lang NOT IN (SELECT lang
		   				 	  FROM alert_frame_body
		   				 	 WHERE alert_frame_id = v_alert_frame_id AND lang = v_lang);

	-- next add any missing templates that we have default config for in the given language
	INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
		SELECT in_application_sid, cat.customer_alert_type_id, v_alert_frame_id, dat.send_type
		  FROM default_alert_template dat
			JOIN customer_alert_type cat ON dat.std_alert_type_id = cat.std_alert_type_id AND cat.app_sid = in_application_sid
		 WHERE dat.default_alert_frame_id = v_default_alert_frame_id
		   AND customer_alert_type_id NOT IN (SELECT customer_alert_type_id 
											     FROM alert_template 
												WHERE app_sid = in_application_sid)
		   AND customer_alert_type_id IN (SELECT customer_alert_type_id
										     FROM customer_alert_type
										    WHERE app_sid = in_application_sid);
		   							  
	-- and finally any missing bodies
	INSERT INTO alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT in_application_sid, cat.customer_alert_type_id, datb.lang, datb.subject, datb.body_html, datb.item_html
		  FROM default_alert_template_body datb
			JOIN customer_alert_type cat ON datb.std_alert_type_id = cat.std_alert_type_id AND cat.app_sid = in_application_sid
		 WHERE datb.std_alert_type_id IN (SELECT std_alert_type_id
		 								     FROM default_alert_template
		 							        WHERE default_alert_frame_id = v_default_alert_frame_id)
		   AND (customer_alert_type_id, lang) NOT IN (SELECT customer_alert_type_id, lang
		   									              FROM alert_template_body
		   									             WHERE app_sid = in_application_sid)
		   AND customer_alert_type_id IN (SELECT customer_alert_type_id
								             FROM customer_alert_type
								            WHERE app_sid = in_application_sid)
		   AND lang = v_lang;

	-- add descriptions for inds/regions in the new language
	INSERT INTO ind_description (ind_sid, lang, description)
		SELECT ind_sid, lang, description
		  FROM (SELECT id.ind_sid, cl.lang, id.description
				  FROM v$customer_lang cl, ind_description id
				 WHERE id.lang = 'en'
				   AND NOT EXISTS (SELECT NULL 
									 FROM ind_description 
									WHERE ind_sid = id.ind_sid 
									  AND lang = cl.lang)
            );

	INSERT INTO region_description (region_sid, lang, description)
		SELECT region_sid, lang, description
		  FROM (SELECT rd.region_sid, cl.lang, rd.description
				  FROM v$customer_lang cl, region_description rd
				 WHERE rd.lang = 'en'
				   AND NOT EXISTS (SELECT NULL 
									 FROM region_description 
									WHERE region_sid = rd.region_sid 
									  AND lang = cl.lang)
            );

	INSERT INTO doc_folder_name_translation (doc_folder_sid, parent_sid, lang, translated)
		SELECT doc_folder_sid, parent_sid, lang, translated
		  FROM (SELECT dfnt.doc_folder_sid, dfnt.parent_sid, cl.lang, dfnt.translated
				  FROM v$customer_lang cl, doc_folder_name_translation dfnt
				 WHERE dfnt.lang = 'en'
				   AND NOT EXISTS (SELECT NULL 
									 FROM doc_folder_name_translation 
									WHERE doc_folder_sid = dfnt.doc_folder_sid 
									  AND lang = cl.lang)
	);

	INSERT INTO tab_description (tab_id, lang, description)
		SELECT tab_id, lang, description
		  FROM (SELECT td.app_sid, td.tab_id, cl.lang, td.description
				  FROM v$customer_lang cl, tab_description td
				 WHERE td.lang = 'en'
				   AND NOT EXISTS (SELECT NULL 
									 FROM tab_description 
									WHERE tab_id = td.tab_id 
									  AND lang = cl.lang) 
				);
END;

PROCEDURE CreateScenario(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_reg_users_sid				IN	security_pkg.T_SID_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	out_scenario_sid				OUT	security_pkg.T_SID_ID,
	out_scenario_run_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN
	securableObject_pkg.CreateSO(in_act_id, in_app_sid,
		class_pkg.GetClassId('CSRScenario'), in_name || ' scenario', out_scenario_sid);
	-- add registered users read on the scenario
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(out_scenario_sid),
		security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, in_reg_users_sid,
		security_pkg.PERMISSION_STANDARD_READ);

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	INSERT INTO scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id, period_interval_id, include_all_inds)
	VALUES (out_scenario_sid, in_name || ' scenario', v_calc_start_dtm, v_calc_end_dtm, 1, 1, 0);

	securableObject_pkg.CreateSO(security_pkg.GetACT(), SYS_CONTEXT('SECURITY', 'APP'), 
		class_pkg.GetClassId('CSRScenarioRun'), in_name || ' scenario run', out_scenario_run_sid);			
	-- add registered users read on the scenario run
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(out_scenario_run_sid),
		security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, in_reg_users_sid,
		security_pkg.PERMISSION_STANDARD_READ);
	INSERT INTO scenario_run (scenario_run_sid, scenario_sid, description)
	VALUES (out_scenario_run_sid, out_scenario_sid, in_name || ' scenario run');    
END;

PROCEDURE CreateApp(
	in_app_name						IN	customer.host%TYPE,
	in_styles_path					IN	VARCHAR2,
	in_start_month					IN	customer.start_month%TYPE,
	out_app_sid						OUT	customer.app_sid%TYPE
)
AS
BEGIN
	CreateApp(
		in_app_name,
		in_styles_path,
		in_start_month,
		csr_data_pkg.SITE_TYPE_CUSTOMER,
		out_app_sid);
END;

PROCEDURE CreateApp(
	in_app_name						IN	customer.host%TYPE,
	in_styles_path					IN	VARCHAR2,
	in_start_month					IN	customer.start_month%TYPE,
	in_site_type					IN  customer.site_type%TYPE,
	out_app_sid						OUT	customer.app_sid%TYPE
)
AS
	-- sids we create
	v_region_root_sid_id		security_pkg.T_SID_ID;
	v_ind_root_sid_id			security_pkg.T_SID_ID;
	v_new_sid_id				security_pkg.T_SID_ID;
	v_new_sid_id2				security_pkg.T_SID_ID;
	v_pending_sid_id			security_pkg.T_SID_ID;
	v_trash_sid_id				security_pkg.T_SID_ID;
	v_policy_sid				security_pkg.T_SID_ID;
	-- groups
	v_admins					security_pkg.T_SID_ID;
	v_reg_users					security_pkg.T_SID_ID;
	v_super_admins				security_pkg.T_SID_ID;
	v_groups					security_pkg.T_SID_ID;
	v_auditors					security_pkg.T_SID_ID;
	v_reporters					security_pkg.T_SID_ID;
	-- mail
	v_email						customer.system_mail_address%TYPE;
	v_tracker_email				customer.tracker_mail_address%TYPE;
	v_root_mailbox_sid			security_pkg.T_SID_ID;
	v_account_sid				security_pkg.T_SID_ID;
	v_outbox_mailbox_sid		security_pkg.T_SID_ID;
	v_sent_mailbox_sid			security_pkg.T_SID_ID;
	v_users_mailbox_sid			security_pkg.T_SID_ID;
	v_user_mailbox_sid			security_pkg.T_SID_ID;
	v_tracker_root_mailbox_sid	security_pkg.T_SID_ID;
	v_tracker_account_sid		security_pkg.T_SID_ID;
	-- reporting periods
	v_period_start_dtm			DATE;
	v_period_sid				security_pkg.T_SID_ID;
	-- user creator
	v_user_creator_daemon_sid   security_pkg.T_SID_ID;
	-- section stuff
	v_status_sid                security_pkg.T_SID_ID;
    v_text_sid                  security_pkg.T_SID_ID;
    v_text_statuses_sid         security_pkg.T_SID_ID;
    v_text_transitions_sid      security_pkg.T_SID_ID;
    v_deleg_plans_sid			security_pkg.T_SID_ID;
	-- en
 	v_lang_id					aspen2.lang.lang_id%TYPE;
 	-- misc
 	v_sid						security_pkg.T_SID_ID;
 	v_app_sid					security_pkg.T_SID_ID;
	-- group and role stuff
	TYPE T_ROLE_NAMES IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;
	v_role_names				T_ROLE_NAMES;
	v_role_sid					security_pkg.T_SID_ID;
	v_data_contributors			security_pkg.T_SID_ID;
	v_act_id					security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_scenarios_sid				security_pkg.T_SID_ID;
    v_scenario_sid				security.security_pkg.T_SID_ID;
    v_merged_scenario_run_sid 	security.security_pkg.T_SID_ID;
    v_unmerged_scenario_run_sid	security.security_pkg.T_SID_ID;
	v_capabilities				security.security_pkg.T_SID_ID;
	v_anonymise_pii				security.security_pkg.T_SID_ID;
 	v_ga4_enabled				aspen2.application.ga4_enabled%TYPE:= 1;
BEGIN

	-- in_app_name can only contain A-Za-z0-9.-
	IF REGEXP_REPLACE(in_app_name, '^[A-Za-z0-9.-]+$', '') IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'The app_name contains invalid characters.');
	END IF;

	-- Create the app object
	securableObject_pkg.CreateSO(
		v_act_id,
		security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security.security_pkg.SID_ROOT, '//aspen/applications'),
		class_pkg.GetClassID('CSRApp'),
		in_app_name,
		v_app_sid);

	/*** default to English **/
	SELECT lang_id
	  INTO v_lang_id
	  FROM aspen2.lang
	 WHERE lang = 'en';
	
	-- use english as the base for the site (rather than en-gb)
	aspen2.tr_pkg.SetBaseLang(SYS_CONTEXT('SECURITY', 'APP'), 'en');
	aspen2.tr_pkg.AddApplicationTranslation(SYS_CONTEXT('SECURITY', 'APP'), v_lang_id);

	/*** GROUPS ***/
	v_groups := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_admins := securableobject_pkg.GetSIDFromPath(v_act_id, v_groups, 'Administrators');
	v_reg_users := securableobject_pkg.GetSIDFromPath(v_act_id, v_groups, 'RegisteredUsers');
	
	-- make superadmins members of both RegisteredUsers and Administrators
	v_super_admins := securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins');
	group_pkg.AddMember(v_act_id, v_super_admins, v_admins);
	group_pkg.AddMember(v_act_id, v_super_admins, v_reg_users);
	-- give superadmins logon as any user on RegisteredUsers
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_reg_users), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_super_admins, security_pkg.PERMISSION_STANDARD_ALL+csr_data_pkg.PERMISSION_LOGON_AS_USER);
	
	-- create a data providers group
	group_pkg.CreateGroupWithClass(
		v_act_id, 
		v_groups, 
		security_pkg.GROUP_TYPE_SECURITY, 
		'Data Contributors', 
		class_pkg.getclassid('CSRUserGroup'), 
		v_data_contributors
	);
	
	-- create auditors group
	group_pkg.CreateGroupWithClass(
		v_act_id, 
		v_groups, 
		security_pkg.GROUP_TYPE_SECURITY, 
		'Auditors', 
		class_pkg.getclassid('CSRUserGroup'), 
		v_auditors
	);
	
	-- create reporters group
	group_pkg.CreateGroupWithClass(
		v_act_id, 
		v_groups, 
		security_pkg.GROUP_TYPE_SECURITY, 
		'Reporters', 
		class_pkg.getclassid('CSRUserGroup'), 
		v_reporters
	);
	
	/*** CSR ***/
	-- grant admins ALL permissions on the app 
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_app_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);
	-- grant admins 'alter schema' on the app node (not inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_app_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins, security_pkg.PERMISSION_STANDARD_ALL+csr_data_pkg.PERMISSION_ALTER_SCHEMA);
	
	/*** INDICATORS ***/	
	-- create as a group so we can add members (for permissions)
	group_pkg.CreateGroupWithClass(v_act_id, v_app_sid, security_pkg.GROUP_TYPE_SECURITY, 'Indicators',
		security_pkg.SO_CONTAINER, v_ind_root_sid_id);
	-- add object to the DACL (the container is a group, so it has permissions on itself)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_ind_root_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_ind_root_sid_id, security_pkg.PERMISSION_STANDARD_READ);
	
	/*** REGIONS ***/
	-- create as a group so we can add members (for permissions)
	group_pkg.CreateGroupWithClass(v_act_id, v_app_sid, security_pkg.GROUP_TYPE_SECURITY, 'Regions',
		security_pkg.SO_CONTAINER, v_region_root_sid_id);
	-- add object to the DACL (the container is a group, so it has permissions on itself)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_region_root_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_region_root_sid_id, security_pkg.PERMISSION_STANDARD_READ);
	
	/*** MEASURES ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Measures', v_new_sid_id);
	-- grant registered users READ on measures (inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);
				
	/*** DATAVIEWS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Dataviews', v_new_sid_id);
	-- grant RegisteredUsers READ on Dataviews
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);
	
	-- Add a public and admin folder below dataviews, with relevant permissions
	AddAdminAndPublicSubFolders(
		in_parent_sid		=> v_new_sid_id
	);
	
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'BatchExportDataviews', v_new_sid_id);
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_ALL);

		/*** PIVOT TABLES ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Pivot tables', v_new_sid_id);
	-- grant RegisteredUsers READ on pivot tables
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);

	/*** DASHBOARDS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Dashboards', v_new_sid_id);
	-- grant RegisteredUsers READ on Dashboards
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);

	/*** IMPORTS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Imports', v_new_sid_id);
	-- grant Auditors READ on Imports (inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_auditors, security_pkg.PERMISSION_STANDARD_READ);
	-- grant Contributors READ / WRITE on Imports (inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_data_contributors, security_pkg.PERMISSION_STANDARD_ALL);
		
	/*** FORMS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Forms', v_new_sid_id);
	-- grant Auditors + Data Contributors READ on Forms (inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_data_contributors, security_pkg.PERMISSION_STANDARD_READ);
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_auditors, security_pkg.PERMISSION_STANDARD_READ);
		
	/*** DELEGATIONS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Delegations', v_new_sid_id);
	-- grant auditors
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_auditors, security_pkg.PERMISSION_STANDARD_READ);
	
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'DelegationPlans', v_deleg_plans_sid);	
	
	/*** PENDING FORMS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Pending', v_pending_sid_id);
	SecurableObject_pkg.CreateSO(v_act_id, v_pending_sid_id, security_pkg.SO_CONTAINER, 'Forms', v_new_sid_id);
	SecurableObject_pkg.CreateSO(v_act_id, v_pending_sid_id, security_pkg.SO_CONTAINER, 'Datasets', v_new_sid_id);
	
	/*** SCENARIOS ***/
	securableobject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Scenarios', v_scenarios_sid);
	-- set permissions on scenarios itself
	securableobject_pkg.ClearFlag(v_act_id, v_scenarios_sid, security_pkg.SOFLAG_INHERIT_DACL);	
	acl_pkg.RemoveACEsForSid(v_act_id, acl_pkg.GetDACLIDForSID(v_scenarios_sid), security_pkg.SID_BUILTIN_EVERYONE);
	-- add administrators
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_scenarios_sid), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, 
		v_admins, security_pkg.PERMISSION_STANDARD_ALL);	
	-- add reg users
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_scenarios_sid), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT, 
		v_reg_users, security_pkg.PERMISSION_STANDARD_READ);
	acl_pkg.PropogateACEs(v_act_id, v_scenarios_sid);
	
	/*** TRASH ***/
	-- create trash 
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, class_pkg.GetClassId('TrashCan'), 'Trash', v_trash_sid_id);
	-- grant admins RESTORE FROM TRASH permissions
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_trash_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_RESTORE_FROM_TRASH);
		
	/*** ACCOUNT POLICY ***/
	-- create an account policy with no options set
	-- give admins write access on it
	security.accountPolicy_pkg.CreatePolicy(v_act_id, v_app_sid, 'AccountPolicy', null, null, null, null, null, 1, v_policy_sid);
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_policy_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins, security_pkg.PERMISSION_STANDARD_ALL);
	
	/*** MAIL ***/
	-- create system mail account and add an Outbox (foo.credit360.com -> foo@credit360.com)
	-- .credit360.com = 14 chars
	IF LOWER(SUBSTR(in_app_name, LENGTH(in_app_name) - 13, 14)) = '.credit360.com' THEN
		-- a standard foo.credit360.com
		v_email := SUBSTR(in_app_name, 1, LENGTH(in_app_name)-14)||'@credit360.com';
		v_tracker_email := SUBSTR(in_app_name, 1, LENGTH(in_app_name)-14)||'_tracker@credit360.com';
	ELSE
		-- not a standard foo.credit360.com, so... www.foo.com@credit360.com
		v_email := in_app_name||'@credit360.com';
		v_tracker_email := in_app_name||'_tracker@credit360.com';
	END IF;

	-- If you get an error here, it's probably because you dropped/recreated the site
	-- You will have to clean up the mailbox manually
	-- This is DELIBERATELY not re-using the mailbox to avoid cross-site mail leaks
	mail.mail_pkg.createAccount(v_email, NULL, 'System mail account for '||in_app_name, v_account_sid, v_root_mailbox_sid);
	-- let admins poke the mailboxes
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_root_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);

	-- create sent/outbox and grant registered users add contents permission so they can be sent alerts
	mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Sent', v_sent_mailbox_sid);
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_sent_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_ADD_CONTENTS);
	mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Outbox', v_outbox_mailbox_sid);	
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_outbox_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_ADD_CONTENTS);
	
	-- create a container for per user mailboxes
	mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Users', v_users_mailbox_sid);

	-- create the tracker account
	mail.mail_pkg.createAccount(v_tracker_email, NULL, 'Tracker mail account for '||in_app_name, v_tracker_account_sid, v_tracker_root_mailbox_sid);
	-- let admins poke the mailboxes
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_tracker_root_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);
		
	/*** REPORTING PERIODS ***/
	SecurableObject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'ReportingPeriods', v_new_sid_id);
	-- grant registered users READ on reporting periods (inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);

	/*** GENERAL CUSTOMER ATTRIBUTES ***/
	-- insert into customer
	INSERT INTO customer (
		app_sid, name, host, system_mail_address, tracker_mail_address, alert_mail_address, alert_mail_name,
		editing_url, account_policy_sid, current_reporting_period_sid,
		ind_info_xml_fields,
		ind_root_sid, region_root_sid, trash_sid,
		start_month, default_admin_css, scenarios_enabled,
		calc_start_dtm, calc_end_dtm, calc_future_window, site_type
	) VALUES (
		v_app_sid, in_app_name, in_app_name, v_email, v_tracker_email, 'no-reply@cr360.com', 'Credit360 support team',
		'/csr/site/delegation/sheet.acds?', v_policy_sid, null,
		XMLType('<ind-metadata><field name="definition" label="Detailed info"/></ind-metadata>'),
		null, null, v_trash_sid_id, in_start_month, in_styles_path || '/includes/credit.css', 1,
		ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), -10*12),ADD_MONTHS(TRUNC(SYSDATE, 'YEAR'), 4*12), 3,
		in_site_type
	);
	-- add default scenario options
	INSERT INTO scenario_options (app_sid)
	VALUES (v_app_sid);
	
	IF LOWER(in_site_type) IN ('staff', 'automationtest')
	THEN
		v_ga4_enabled := 0;
	END IF;

	UPDATE aspen2.application
	   SET default_url = '/csr/site/delegation/myDelegations.acds',
	   	   menu_path = '//aspen/applications/' || in_app_name || '/menu',
	   	   metadata_connection_string = 'Provider=NPSLMDSQL.MDSQL.1;User ID=mtdata;Password=mtdata;Persist Security Info=True;initial catalog=//aspen/applications/' || in_app_name || '/metadata;DATA SOURCE=aspen;',
		   logon_url = '/csr/site/login.acds',
		   default_stylesheet = in_styles_path || '/generic.xsl',
		   commerce_store_path = '//aspen/applications/' || in_app_name || '/store',
		   edit_css = in_styles_path || '/includes/page.css',
		   default_css = in_styles_path || '/includes/all.cssx',
		   ga4_enabled = v_ga4_enabled
	 WHERE app_sid = v_app_sid;
	
	-- locks
	INSERT INTO app_lock
		(app_sid, lock_type)
	VALUES
		(v_app_sid, csr_data_pkg.LOCK_TYPE_CALC);
	INSERT INTO app_lock
		(app_sid, lock_type)
	VALUES
		(v_app_sid, csr_data_pkg.LOCK_TYPE_SHEET_CALC);
	INSERT INTO app_lock
		(app_sid, lock_type)
	VALUES
		(v_app_sid, csr_data_pkg.LOCK_TYPE_FORECASTING);

	-- clone all superadmins for the new app
	INSERT INTO csr_user (app_sid, csr_user_sid, user_name, full_name, email, friendly_name, guid)
		SELECT v_app_sid, s.csr_user_sid, s.user_name, s.full_name, s.email, s.friendly_name, s.guid
		  FROM superadmin s
		  JOIN security.securable_object so ON s.csr_user_sid = so.sid_id;

	-- sometimes we record audit log entries against builtin/administrator and guest
	-- we hard-coded the GUIDs so csrexp will move them nicely
	INSERT INTO csr_user
		(app_sid, csr_user_sid, user_name, full_name, friendly_name, email, guid, hidden)
	VALUES 
		(v_app_sid, security_pkg.SID_BUILTIN_ADMINISTRATOR, 'builtinadministrator', 'Builtin Administrator', 
		 'Builtin Administrator', 'no-reply@cr360.com', 'A3B4FB4B-BC13-53A3-8714-95640E79CA8A', 1);
	INSERT INTO csr_user
		(app_sid, csr_user_sid, user_name, full_name, friendly_name, email, guid, hidden)
	VALUES 
		(v_app_sid, security_pkg.SID_BUILTIN_GUEST, 'guest', 'Guest', 
		 'Guest', 'no-reply@cr360.com', '77646D7A-A70E-E923-2FF6-2FD960873984', 1); 

	-- create a default reporting period
	v_period_start_dtm := TO_DATE('1/'||in_start_month||'/'||EXTRACT(Year FROM SYSDATE),'DD/MM/yyyy');
	reporting_period_pkg.CreateReportingPeriod(v_act_id, v_app_sid, EXTRACT(Year FROM SYSDATE), v_period_start_dtm, ADD_MONTHS(v_period_start_dtm, 12), 0, v_period_sid); 	
	UPDATE customer
 	   SET current_reporting_period_sid = v_period_sid
 	 WHERE app_sid = v_app_sid;

	/*** BOOTSTRAP INDICATORS AND REGIONS ***/
	-- we have to do this once we've put data into the customer table due to FK constraints on APP_SID
	-- Add standard region types to the customer_region_type table for this app
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (v_app_sid, csr_data_pkg.REGION_TYPE_NORMAL);
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (v_app_sid, csr_data_pkg.REGION_TYPE_ROOT);
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (v_app_sid, csr_data_pkg.REGION_TYPE_PROPERTY);
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (v_app_sid, csr_data_pkg.REGION_TYPE_TENANT);
	-- add region root
	INSERT INTO REGION_TREE (
		REGION_TREE_ROOT_SID, app_sid, LAST_RECALC_DTM, IS_PRIMARY
	) VALUES (
		v_region_root_sid_id, v_app_sid, NULL, 1
	);		
	-- insert regions sid (for user start points)
	INSERT INTO region (
		region_sid, parent_sid, app_sid, name, active, pos, info_xml, link_to_region_sid, region_type
	) VALUES (
		v_region_root_sid_id, v_app_sid, v_app_sid, 'regions', 1, 1, null, null, csr_data_pkg.REGION_TYPE_ROOT
	);
	INSERT INTO region_description
		(region_sid, lang, description)
	VALUES
		(v_region_root_sid_id, 'en', 'Regions');
		
	AddCalendarMonthPeriodSet;
	
	INSERT INTO ind (
		ind_sid, parent_sid, name, app_sid, period_set_id, period_interval_id, is_system_managed
	) VALUES (
		v_ind_root_sid_id, v_app_sid, 'indicators', v_app_sid, 1, 1, 1
	);
	INSERT INTO ind_description
		(ind_sid, lang, description)
	VALUES
		(v_ind_root_sid_id, 'en', 'Indicators');

	-- make Indicators and Regions members of themselves 
	group_pkg.AddMember(v_act_id, v_ind_root_sid_id, v_ind_root_sid_id);
	group_pkg.AddMember(v_act_id, v_region_root_sid_id, v_region_root_sid_id);
	
	UPDATE customer
	   SET ind_root_sid = v_ind_root_sid_id, 
	   	   region_root_sid = v_region_root_sid_id
	 WHERE app_sid = v_app_sid;

    -- fiddle with UserCreatorDaemon    
    v_user_creator_daemon_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/UserCreatorDaemon');
    
    INSERT INTO csr_user
        (csr_user_sid, email, guid, app_sid,
        full_name, user_name, friendly_name, info_xml, send_alerts, show_portal_help, hidden)
        SELECT v_user_creator_daemon_sid , 'no-reply@cr360.com',  user_pkg.GenerateACT,
               c.app_sid, 'Automatic User Creator', 'UserCreatorDaemon', 'Automatic User Creator', null, 0, 0, 1
          FROM customer c
         WHERE c.app_sid = v_app_sid;

	-- Grant UserCreatorDaemon add contents permission on the users mailbox folder (non-inheritable)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_users_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		0, v_user_creator_daemon_sid, security_pkg.PERMISSION_ADD_CONTENTS);
	
	-- Grant UserCreatorDaemon all permissions on delegations for when delegation plans roll out
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Delegations')), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_ALTER_SCHEMA);
	
	-- Grant UserCreatorDaemon read permissions on delegation plans for when delegation plans roll out
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_deleg_plans_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security_pkg.PERMISSION_READ);

	-- add UCD to Regions, with write permissions (so they can set region start points, e.g. when self-registering users)
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_region_root_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_user_creator_daemon_sid, security_pkg.PERMISSION_STANDARD_ALL);
		
	-- Make them a member of registered users
	group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_creator_daemon_sid, v_reg_users);

    -- add start points for superadmins
    INSERT INTO ind_start_point (ind_sid, user_sid)
        SELECT v_ind_root_sid_id, s.csr_user_sid
          FROM superadmin s
          JOIN security.securable_object so ON s.csr_user_sid = so.sid_id;

    INSERT INTO region_start_point (region_sid, user_sid)
        SELECT v_region_root_sid_id, s.csr_user_sid
          FROM superadmin s
          JOIN security.securable_object so ON s.csr_user_sid = so.sid_id;

	-- add a mailbox for each user, granting them full control over it
	-- and giving other registered users add contents permission
	FOR r IN (SELECT csr_user_sid
				FROM csr_user
			   WHERE app_sid = v_app_sid
	) LOOP
		mail.mail_pkg.createMailbox(v_users_mailbox_sid, r.csr_user_sid, v_user_mailbox_sid);
		acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_ADD_CONTENTS);
		acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, r.csr_user_sid, security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;

	/*** SECTIONS ***/
	securableobject_pkg.CreateSO(v_act_id, v_app_sid, security_pkg.SO_CONTAINER, 'Text', v_text_sid);
    securableobject_pkg.CreateSO(v_act_id, v_text_sid, security_pkg.SO_CONTAINER, 'Statuses', v_text_statuses_sid);
    securableobject_pkg.CreateSO(v_act_id, v_text_sid, security_pkg.SO_CONTAINER, 'Transitions', v_text_transitions_sid);
    -- make default status (red)
    section_status_pkg.CreateSectionStatus('Editing', 15728640, 0, v_status_sid);

	-- section root relies on a row in the customer table so we create it down here
	securableobject_pkg.CreateSO(v_act_id, v_app_sid, class_pkg.GetClassID('CSRSectionRoot'), 'Sections', v_new_sid_id);
	-- Give the administrators group ALL and CHANGE_TITLE permimssions on it (inheritable)
	-- (We have to do this as the change title permission is unique to a CSRSectionRoot or CSRSection object and so is 
	-- not inherited from the parent)
	acl_pkg.RemoveACEsForSid(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), v_admins);
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), 
		security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, 
		v_admins, security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_CHANGE_TITLE + csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE);
	
	-- Add default roles (moved down as roles have dependencies on customer table)
	v_role_names(1) := 'Data Providers';
	v_role_names(2) := 'Data Approvers';
	FOR i IN v_role_names.FIRST..v_role_names.LAST
	LOOP	
		role_pkg.SetRole(v_role_names(i), v_role_sid);
		-- make the role a member of the Data Contributors groups
		group_pkg.AddMember(security_pkg.getact, v_role_sid, v_data_contributors);
	END LOOP;
	
	-- add Subdelegation capability and other common bits
	csr_data_pkg.enablecapability('Subdelegation');
	csr_data_pkg.enablecapability('System management');
	csr_data_pkg.enablecapability('Issue management');
	csr_data_pkg.enablecapability('Report publication');
	csr_data_pkg.enablecapability('Manage any portal');
	csr_data_pkg.enablecapability('Create users for approval');
	csr_data_pkg.enablecapability('Add portal tabs');
	csr_data_pkg.enablecapability('View Delegation link from Sheet');
	csr_data_pkg.enablecapability('Manage jobs');
	csr_data_pkg.enablecapability('Enable Delegation Sheet changes warning');
	csr_data_pkg.enablecapability('Save shared indicator sets');
	csr_data_pkg.enablecapability('Save shared region sets');
	csr_data_pkg.enablecapability('Can import users and role memberships via structure import');
	csr_data_pkg.enablecapability('Can manage filter alerts');
	csr_data_pkg.enablecapability('Run sheet export report');
	csr_data_pkg.enablecapability('Quick chart management');
	csr_data_pkg.enablecapability('Context Sensitive Help');
	
	csr_data_pkg.enablecapability('Import surveys from Excel');
	acl_pkg.AddACE(
		v_act_id,
		Acl_pkg.GetDACLIDForSID(securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Capabilities/Import surveys from Excel')),
		security_pkg.ACL_INDEX_LAST,
		security_pkg.ACE_TYPE_ALLOW,
		0,
		securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Groups/Everyone'),
		security_pkg.PERMISSION_READ+security_pkg.PERMISSION_WRITE+security_pkg.PERMISSION_READ_PERMISSIONS+security_pkg.PERMISSION_LIST_CONTENTS+security_pkg.PERMISSION_READ_ATTRIBUTES+security_pkg.PERMISSION_WRITE_ATTRIBUTES);

	--Enable anonymisation capability
	csr_data_pkg.enablecapability('Anonymise PII data');
	v_capabilities := securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.GetApp, 'Capabilities');
	v_anonymise_pii := securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities, 'Anonymise PII data');
	securableobject_pkg.SetFlags(v_act_id, v_anonymise_pii, 0);
	acl_pkg.DeleteAllACEs(v_act_id, acl_pkg.GetDACLIDForSID(v_anonymise_pii));
	acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_anonymise_pii), -1, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_super_admins, security_pkg.PERMISSION_STANDARD_ALL);

	/*** HELP **/
	-- insert the first help_lang_id for this customer
	INSERT INTO customer_help_lang (app_sid, help_lang_id, is_default)
		SELECT v_app_sid, MIN(help_lang_id), 1 
		  FROM help_lang;	
	
	region_pkg.createregion(
		in_parent_sid => v_deleg_plans_sid,
		in_name => 'DelegPlansRegion',
		in_description => 'DelegPlansRegion',
		in_geo_type => region_pkg.REGION_GEO_TYPE_OTHER,
		out_region_sid => v_new_sid_id
	);	  
	
	/*** ISSUE BITS ***/
	INSERT INTO issue_type (app_sid, issue_type_Id, label)
	VALUES (v_app_sid, 1, 'Data entry form');
	
	/*** ALERTS AND ALERT TEMPLATES ***/	

	-- now add in standard alerts for all csr customers (1 -> 5) + bulk mailout (20) + password reminder etc (21 -> 26)
	INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT v_app_sid, customer_alert_type_id_seq.nextval, std_alert_type_id
		  FROM std_alert_type 
		 WHERE std_alert_type_id IN (
				csr_data_pkg.ALERT_NEW_USER, 
				csr_data_pkg.ALERT_NEW_DELEGATION,
				csr_data_pkg.ALERT_OVERDUE_SHEET,
				csr_data_pkg.ALERT_SHEET_CHANGED,
				csr_data_pkg.ALERT_REMINDER_SHEET,
				csr_data_pkg.ALERT_DELEG_TERMINATED,
				csr_data_pkg.ALERT_GENERIC_MAILOUT,
				csr_data_pkg.ALERT_SELFREG_VALIDATE,
				csr_data_pkg.ALERT_SELFREG_NOTIFY,
				csr_data_pkg.ALERT_SELFREG_APPROVAL,
				csr_data_pkg.ALERT_SELFREG_REJECT,
				csr_data_pkg.ALERT_PASSWORD_RESET,
				csr_data_pkg.ALERT_ACCOUNT_DISABLED, 
				csr_data_pkg.ALERT_USER_COVER_STARTED,
				csr_data_pkg.ALERT_BATCH_JOB_COMPLETED,
				csr_data_pkg.ALERT_UPDATED_PLANNED_DELEG,
				csr_data_pkg.ALERT_NEW_PLANNED_DELEG,
				csr_data_pkg.ALERT_SHEET_RETURNED,
				csr_data_pkg.ALERT_USER_INACTIVE_REMINDER,
				csr_data_pkg.ALERT_USER_INACTIVE_SYSTEM,
				csr_data_pkg.ALERT_USER_INACTIVE_MANUAL,
				csr_data_pkg.ALERT_ISSUE_REMINDER,
				csr_data_pkg.ALERT_ISSUE_OVERDUE,
				csr_data_pkg.ALERT_SHEET_CREATED
				);
		 
	AddStandardFramesAndTemplates;

	-- some basic units
	measure_pkg.createMeasure(
		in_name 					=> 'fileupload',
		in_description 				=> 'File upload',
		in_custom_field 			=> CHR(38),
		in_pct_ownership_applies	=> 0,
		in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
		out_measure_sid				=> v_sid
	);
	measure_pkg.createMeasure(
		in_name 					=> 'text',
		in_description 				=> 'Text',
		in_custom_field 			=> '|',
		in_pct_ownership_applies	=> 0,
		in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
		out_measure_sid				=> v_sid
	);
	measure_pkg.createMeasure(
		in_name 					=> 'date',
		in_description 				=> 'Date',
		in_custom_field 			=> '$',
		in_pct_ownership_applies	=> 0,
		in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
		out_measure_sid				=> v_sid
	);
		 
	-- delegation submission report
	sqlreport_pkg.EnableReport('csr.delegation_pkg.GetReportSubmissionPromptness');
	sqlreport_pkg.EnableReport('csr.delegation_pkg.GetReportDelegationBlockers');
	
	-- set default filters
	chain.card_pkg.SetGroupCards('Issues Filter', chain.T_STRING_LIST('Credit360.Filters.Issues.StandardIssuesFilter', 'Credit360.Filters.Issues.IssuesCustomFieldsFilter', 'Credit360.Filters.Issues.IssuesFilterAdapter'));
	chain.card_pkg.SetGroupCards('Cms Filter', chain.T_STRING_LIST('NPSL.Cms.Filters.CmsFilter'));
	chain.card_pkg.SetGroupCards('User Data Filter', chain.T_STRING_LIST('Credit360.Users.Filters.UserDataFilter','Credit360.Users.Filters.UserCmsFilterAdapter'));
	chain.card_pkg.SetGroupCards('Sheet Filter', chain.T_STRING_LIST('Credit360.Delegation.Sheet.Filters.DataFilter'));

	-- create merged/unmerged scrag++ scenarios
	CreateScenario(v_act_id, v_app_sid, v_reg_users, 'Merged', v_scenario_sid, v_merged_scenario_run_sid);
	
	UPDATE scenario
	   SET file_based = 1,
	   	   recalc_trigger_type = stored_calc_datasource_pkg.RECALC_TRIGGER_MERGED,
	       data_source = stored_calc_datasource_pkg.DATA_SOURCE_MERGED,
	   	   auto_update_run_sid = v_merged_scenario_run_sid
	 WHERE scenario_sid = v_scenario_sid;
	
	CreateScenario(v_act_id, v_app_sid, v_reg_users, 'Unmerged', v_scenario_sid, v_unmerged_scenario_run_sid);

	UPDATE scenario
	   SET file_based = 1,
	       recalc_trigger_type = csr.stored_calc_datasource_pkg.RECALC_TRIGGER_UNMERGED,
	       data_source = csr.stored_calc_datasource_pkg.DATA_SOURCE_UNMERGED,
	   	   auto_update_run_sid = v_unmerged_scenario_run_sid
	 WHERE scenario_sid = v_scenario_sid;

	UPDATE customer
	   SET merged_scenario_run_sid = v_merged_scenario_run_sid,
	   	   unmerged_scenario_run_sid = v_unmerged_scenario_run_sid
     WHERE app_sid = v_app_sid;
	
	out_app_sid := v_app_sid;
END;

PROCEDURE AddAdminAndPublicSubFolders(
	in_parent_sid		IN	security_pkg.T_SID_ID
)
AS
	v_act_id				security_Pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_new_sid				security_pkg.T_SID_ID;
	v_groups_sid			security.security_pkg.T_SID_ID;
	v_admins_sid			security.security_pkg.T_SID_ID;
	v_reg_users_sid			security.security_pkg.T_SID_ID;
BEGIN
	
	v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	
	
	security.securableObject_pkg.CreateSO(
		in_act_id			=> v_act_id,
		in_parent_sid		=> in_parent_sid,
		in_object_class_id	=> security_pkg.SO_CONTAINER,
		in_object_name		=> 'Public',
		out_sid_id			=> v_new_sid
	);
	security.acl_pkg.AddACE(
		in_act_id			=> v_act_id,
		in_acl_id			=> acl_pkg.GetDACLIDForSID(v_new_sid),
		in_acl_index		=> security_pkg.ACL_INDEX_LAST,
		in_ace_type			=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags		=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id			=> v_reg_users_sid,
		in_permission_set	=> security_pkg.PERMISSION_STANDARD_READ
	);
	
	security.securableObject_pkg.CreateSO(
		in_act_id			=> v_act_id,
		in_parent_sid		=> in_parent_sid,
		in_object_class_id	=> security_pkg.SO_CONTAINER,
		in_object_name		=> 'Admin',
		out_sid_id			=> v_new_sid
	);
	security.securableobject_pkg.ClearFlag(
		in_act_id	=> v_act_id, 
		in_sid_id	=> v_new_sid, 
		in_flag		=> security.security_pkg.SOFLAG_INHERIT_DACL
	);
	security.acl_pkg.DeleteAllACEs(
		in_act_id	=> v_act_id, 
		in_acl_id	=> security.acl_pkg.GetDACLIDForSID(v_new_sid)
	);
	security.acl_pkg.AddACE(
		in_act_id			=> v_act_id,
		in_acl_id			=> security.acl_pkg.GetDACLIDForSID(v_new_sid),
		in_acl_index		=> security_pkg.ACL_INDEX_LAST,
		in_ace_type			=> security_pkg.ACE_TYPE_ALLOW,
		in_ace_flags		=> security_pkg.ACE_FLAG_DEFAULT,
		in_sid_id			=> v_admins_sid,
		in_permission_set	=> security_pkg.PERMISSION_STANDARD_ALL
	);
	
END;

PROCEDURE GetDBVersion(
	out_db_version				OUT	version.db_version%TYPE
)
AS
BEGIN
	SELECT db_version
	  INTO out_db_version
	  FROM version;
END;


PROCEDURE WriteAudit(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_description				IN	audit_log.description%TYPE,
	in_param_1					IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2					IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3					IN  audit_log.param_3%TYPE DEFAULT NULL
)
AS
BEGIN
	csr_data_pkg.WriteAuditLogEntry(
		in_act_id, 
		csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, 
		in_app_sid, 
		NULL, 
		in_description,
		in_param_1,
		in_param_2,
		in_param_3
	);
END;

PROCEDURE WriteNewSiteAuditDetails(
	in_original_sitename		IN	csr.site_audit_details.original_sitename%TYPE,
	in_created_by				IN	csr.site_audit_details.created_by%TYPE,
	in_created_dtm				IN	csr.site_audit_details.created_dtm%TYPE,
	in_client_name				IN	csr.site_audit_details_client_name.client_name%TYPE,
	in_contract_reference		IN	csr.site_audit_details_contract_ref.contract_reference%TYPE,
	in_expiry_dtm				IN	csr.site_audit_details.original_expiry_dtm%TYPE,
	in_reason					IN	csr.site_audit_details_reason.reason%TYPE,
	in_enabled_modules			IN	csr.site_audit_details.enabled_modules%TYPE
)
AS
BEGIN

	INSERT INTO site_audit_details
		(original_sitename, created_by, created_dtm, 
		original_expiry_dtm, active_expiry_dtm, enabled_modules)
	VALUES
		(in_original_sitename, in_created_by, in_created_dtm, 
		in_expiry_dtm, in_expiry_dtm, in_enabled_modules);

	AddClientNameToAuditDetails(
		in_client_name => in_client_name,
		in_user_sid => null
	);
	UpdateReasonOnAuditDetails(
		in_reason => in_reason,
		in_user_sid => null
	);
	IF in_contract_reference IS NOT NULL THEN
		AddContractRefToAuditDetails(
			in_contract_ref => in_contract_reference,
			in_user_sid => null
		);
	END IF;

END;

PROCEDURE WriteSiteAuditDetailsToExisting(
	in_sitename					IN	csr.site_audit_details.original_sitename%TYPE,
	in_created_by				IN	csr.site_audit_details.created_by%TYPE,
	in_client_name				IN	csr.site_audit_details_client_name.client_name%TYPE,
	in_contract_reference		IN	csr.site_audit_details_contract_ref.contract_reference%TYPE,
	in_expiry_dtm				IN	csr.site_audit_details.original_expiry_dtm%TYPE,
	in_reason					IN	csr.site_audit_details_reason.reason%TYPE
)
AS
BEGIN

	INSERT INTO site_audit_details
		(original_sitename, created_by, created_dtm, original_expiry_dtm, 
		active_expiry_dtm, enabled_modules, added_to_existing)
	VALUES
		(in_sitename, in_created_by, null, in_expiry_dtm,
		in_expiry_dtm, '[]', 1);

	AddClientNameToAuditDetails(
		in_client_name => in_client_name
	);
	UpdateReasonOnAuditDetails(
		in_reason => in_reason
	);
	IF in_contract_reference IS NOT NULL THEN
		AddContractRefToAuditDetails(
			in_contract_ref => in_contract_reference
		);
	END IF;

END;

PROCEDURE AddClientNameToAuditDetails(
	in_client_name				IN	csr.site_audit_details_client_name.client_name%TYPE,
	in_user_sid					IN	csr.site_audit_details_client_name.entered_by_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID')
)
AS
BEGIN

	INSERT INTO site_audit_details_client_name 
		(client_name, entered_by_sid)
	VALUES
		(in_client_name, in_user_sid);

END;

PROCEDURE UpdateExpiryDtmOnAuditDetails(
	in_expiry_dtm				IN	csr.site_audit_details_expiry.expiry_dtm%TYPE,
	in_reason					IN	csr.site_audit_details_expiry.reason%TYPE
)
AS
BEGIN

	INSERT INTO site_audit_details_expiry 
		(expiry_dtm, reason)
	VALUES
		(in_expiry_dtm, in_reason);
	
	UPDATE site_audit_details
	   SET active_expiry_dtm = in_expiry_dtm
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE UpdateReasonOnAuditDetails(
	in_reason					IN	csr.site_audit_details_reason.reason%TYPE,
	in_user_sid					IN	csr.site_audit_details_reason.entered_by_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID')
)
AS
BEGIN

	INSERT INTO site_audit_details_reason 
		(reason, entered_by_sid)
	VALUES
		(in_reason, in_user_sid);

END;

PROCEDURE AddContractRefToAuditDetails(
	in_contract_ref				IN	csr.site_audit_details_contract_ref.contract_reference%TYPE,
	in_user_sid					IN	csr.site_audit_details_contract_ref.entered_by_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY','SID')
)
AS
BEGIN

	INSERT INTO site_audit_details_contract_ref 
		(contract_reference, entered_by_sid)
	VALUES
		(in_contract_ref, in_user_sid);

END;

PROCEDURE UpdateSiteType(
	in_site_type				IN	csr.customer.site_type%TYPE
)
AS
	v_existing					csr.customer.site_type%TYPE;
BEGIN

	SELECT site_type
	  INTO v_existing
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	UPDATE customer
	   SET site_type = in_site_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr_data_pkg.WriteAuditLogEntry(
		in_act_id			=>	SYS_CONTEXT('SECURITY', 'ACT'),
		in_audit_type_id	=>	csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		in_app_sid			=>	SYS_CONTEXT('SECURITY', 'APP'),
		in_object_sid		=>	SYS_CONTEXT('SECURITY', 'APP'),
		in_param_1			=>	v_existing,
		in_param_2			=>	in_site_type,
		in_description		=>	'Site type changed from {0} to {1}'
	);

END;

PROCEDURE GetSiteAuditDetails(
	out_details_cur			OUT	SYS_REFCURSOR,
	out_client_names_cur	OUT	SYS_REFCURSOR,
	out_expiry_dates_cur	OUT	SYS_REFCURSOR,
	out_reasons_cur			OUT	SYS_REFCURSOR,
	out_contract_refs_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_details_cur FOR
		SELECT original_sitename, created_by, created_dtm, original_expiry_dtm, 
			active_expiry_dtm, enabled_modules, added_to_existing, c.site_type
		  FROM site_audit_details sad
		  JOIN customer c on sad.app_sid = c.app_sid
		 WHERE sad.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_client_names_cur FOR
		SELECT client_name, entered_by_sid, cu.user_name entered_by_name, entered_at_dtm
		  FROM site_audit_details_client_name sade
	 LEFT JOIN csr_user cu ON sade.entered_by_sid = cu.csr_user_sid
		 WHERE sade.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY entered_at_dtm ASC;
	
	OPEN out_expiry_dates_cur FOR
		SELECT expiry_dtm, entered_by_sid, cu.user_name entered_by_name, entered_at_dtm, reason
		  FROM site_audit_details_expiry sade
		  JOIN csr_user cu ON sade.entered_by_sid = cu.csr_user_sid
		 WHERE sade.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY entered_at_dtm ASC;
	
	OPEN out_reasons_cur FOR
		SELECT reason, entered_by_sid, cu.user_name entered_by_name, entered_at_dtm
		  FROM site_audit_details_reason sadr
	 LEFT JOIN csr_user cu ON sadr.entered_by_sid = cu.csr_user_sid
		 WHERE sadr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY entered_at_dtm ASC;

	OPEN out_contract_refs_cur FOR
		SELECT contract_reference, entered_by_sid, cu.user_name entered_by_name, entered_at_dtm
		  FROM site_audit_details_contract_ref sadcr
	 LEFT JOIN csr_user cu ON sadcr.entered_by_sid = cu.csr_user_sid
		 WHERE sadcr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY entered_at_dtm ASC;


END;

END;
/
