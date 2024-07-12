CREATE OR REPLACE PACKAGE BODY CSRIMP.imp_pkg AS
/*
Importing into csrimp.issue_custom_field...
Importing failed with:
System.Exception: Failure executing statement: INSERT INTO csrimp.issue_custom_field (ISSUE_CUSTOM_FIELD_ID, ISSUE_TYPE_ID, FIELD_TYPE, LABEL) VALUES (:1, :2, :3, :4) ---> Oracle.DataAccess.Client.OracleException ORA-24381: error(s) in array DML

ORA-02290: check constraint (CSRIMP.CHK_ISS_CUST_FLD_TYP) violated    at Oracle.DataAccess.Client.OracleException.HandleErrorHelper(Int32 errCode, OracleConnection conn, IntPtr opsErrCtx, OpoSqlValCtx* pOpoSqlValCtx, Object src, String procedure, Boolean bCheck)
*/

m_old_host							csr.customer.host%TYPE;
m_new_host							csr.customer.host%TYPE;
m_obfuscate_email_addresses			NUMBER;
m_obfuscate_values					NUMBER;

PROCEDURE BeginCsrImpSession(
	in_host							IN	csrimp.customer.host%TYPE,
	out_csrimp_session_id			OUT	csrimp.csrimp_session.csrimp_session_id%TYPE,
	out_step						OUT	csrimp.csrimp_session.step%TYPE,
	out_table_number				OUT	csrimp.csrimp_session.table_number%TYPE,
	out_table_row					OUT	csrimp.csrimp_session.table_row%TYPE
)
AS
	v_csrimp_session_id				csrimp.csrimp_session.csrimp_session_id%TYPE;
	v_exists						NUMBER;
BEGIN
	-- log on with no application
	user_pkg.LogonAdmin(timeout => 7 * 86400);
	BEGIN
		INSERT INTO csrimp.csrimp_session
			(csrimp_session_id, host)
		VALUES
			(csrimp.csrimp_session_id_seq.nextval, in_host)
		RETURNING
			csrimp_session_id INTO v_csrimp_session_id;

		out_step := 0;
		out_table_number := 0;
		out_table_row := 0;

		-- check if the new host already exists so we can give a more helpful error
		SELECT COUNT(*)
		  INTO v_exists
		  FROM (SELECT 1
		  		  FROM security.website
		  		 WHERE LOWER(website_name) = LOWER(in_host)
		  		 UNION
		  		SELECT 1
		  		  FROM csr.customer
		  		 WHERE LOWER(host) = LOWER(in_host));
		IF v_exists != 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME,
				'The application '||in_host||' already exists.');
		END IF;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT csrimp_session_id, step, table_number, table_row
			  INTO v_csrimp_session_id, out_step, out_table_number, out_table_row
			  FROM csrimp_session
			 WHERE LOWER(host) = LOWER(in_host);
	END;
	security.security_pkg.SetContext('CSRIMP_SESSION_ID', v_csrimp_session_id);
	out_csrimp_session_id := v_csrimp_session_id;
	m_new_host := in_host;
END;

PROCEDURE CompleteImpSession
AS
BEGIN
	DELETE FROM csrimp.csrimp_session
	 WHERE csrimp_session_id = SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID');
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The import session '||SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')||
			'does not exist');
	END IF;
	COMMIT;
END;

PROCEDURE TableDataImported(
	in_obfuscate_email_addresses	IN	NUMBER,
	in_obfuscate_values				IN	NUMBER
)
AS
BEGIN
	-- get the old host for renames
	SELECT host
	  INTO m_old_host
	  FROM csrimp.customer;

	m_obfuscate_email_addresses := in_obfuscate_email_addresses;
	m_obfuscate_values := in_obfuscate_values;
END;

PROCEDURE Step(
	in_step							IN	csrimp.csrimp_session.step%TYPE
)
AS
BEGIN
	UPDATE csrimp.csrimp_session
	   SET step = in_step,
	   	   table_number = 0,
	   	   table_row = 0
	 WHERE step = in_step - 1;
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Moving to step '||in_step||' failed -- out of sequence?');
	END IF;
	COMMIT;
END;

PROCEDURE SetTableProgress(
	in_table_number					IN	csrimp.csrimp_session.table_number%TYPE,
	in_table_row					IN	csrimp.csrimp_session.table_row%TYPE
)
AS
BEGIN
	UPDATE csrimp.csrimp_session
	   SET table_number = in_table_number,
	   	   table_row = in_table_row;
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Setting table number failed for table: '||in_table_number||' and table row: '||in_table_row);
	END IF;
	COMMIT;
END;

FUNCTION GetSIDFromPath(
	in_path							IN	VARCHAR2
) RETURN security.security_pkg.T_SID_ID
AS
BEGIN
	RETURN security.securableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), in_path);
END;

PROCEDURE AddKnownSOs
AS
BEGIN
	-- add all the well known sids so we don't map those away
	INSERT INTO csrimp.map_sid (old_sid, new_sid)
	VALUES (security_pkg.SID_ROOT, security_pkg.SID_ROOT);
	INSERT INTO csrimp.map_sid (old_sid, new_sid)
	VALUES (security_pkg.SID_BUILTIN, security_pkg.SID_BUILTIN);
	INSERT INTO csrimp.map_sid (old_sid, new_sid)
	VALUES (security_pkg.SID_BUILTIN_EVERYONE, security_pkg.SID_BUILTIN_EVERYONE);
	INSERT INTO csrimp.map_sid (old_sid, new_sid)
	VALUES (security_pkg.SID_BUILTIN_ADMINISTRATOR, security_pkg.SID_BUILTIN_ADMINISTRATOR);
	INSERT INTO csrimp.map_sid (old_sid, new_sid)
	VALUES (security_pkg.SID_BUILTIN_ADMINISTRATORS, security_pkg.SID_BUILTIN_ADMINISTRATORS);
	INSERT INTO csrimp.map_sid (old_sid, new_sid)
	VALUES (security_pkg.SID_BUILTIN_GUEST, security_pkg.SID_BUILTIN_GUEST);
	INSERT INTO csrimp.map_sid (old_sid, new_sid)
	VALUES (security_pkg.SID_BUILTIN_WEB_DAEMON, security_pkg.SID_BUILTIN_WEB_DAEMON);

	-- add the probably not variable but technically variable sids like mail / applications
	-- (obviously we exported these)
	INSERT INTO csrimp.map_sid (old_sid, new_sid)
		SELECT sid_id,
		  	   securableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), security_pkg.SID_ROOT, path) new_sid
		  FROM csrimp.known_so;
END;

PROCEDURE AddChildRename(
	in_type							IN	VARCHAR2,
	in_parent_sid					IN	security_pkg.T_SID_ID,
	in_old_name						IN	security_pkg.T_SO_NAME,
	in_new_name						IN	security_pkg.T_SO_NAME
)
AS
BEGIN
	INSERT INTO so_rename (sid_id, name)
		SELECT sid_id, in_new_name
		  FROM csrimp.securable_object
		 WHERE parent_sid_id = in_parent_sid
		   AND LOWER(name) = LOWER(in_old_name);
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing '||in_type||' '||in_old_name||' in export');
	END IF;
END;

PROCEDURE GetMailAccounts(
	in_host							IN	security.website.website_name%TYPE,
	out_system_mail_address			OUT	csr.customer.system_mail_address%TYPE,
	out_tracker_mail_address		OUT	csr.customer.tracker_mail_address%TYPE
)
AS
BEGIN
	-- .credit360.com = 14 chars
	IF LOWER(SUBSTR(in_host, LENGTH(in_host)-13,14)) = '.credit360.com' THEN
		-- a standard foo.credit360.com
		out_system_mail_address := SUBSTR(in_host, 1, LENGTH(in_host)-14)||'@credit360.com';
		out_tracker_mail_address := SUBSTR(in_host, 1, LENGTH(in_host)-14)||'_tracker@credit360.com';
	ELSE
		-- not a standard foo.credit360.com, so... www.foo.com@credit360.com
		out_system_mail_address := in_host||'@credit360.com';
		out_tracker_mail_address := in_host||'_tracker@credit360.com';
	END IF;
END;

PROCEDURE AddRenameMappings
AS
	v_old_system_mail_address		csr.customer.system_mail_address%TYPE;
	v_new_system_mail_address		csr.customer.system_mail_address%TYPE;
	v_old_tracker_mail_address 		csr.customer.tracker_mail_address%TYPE;
	v_new_tracker_mail_address 		csr.customer.tracker_mail_address%TYPE;
	v_accounts_sid					security_pkg.T_SID_ID;
	v_folders_sid					security_pkg.T_SID_ID;
BEGIN
	-- rename mail accounts
	SELECT system_mail_address, tracker_mail_address
	  INTO v_old_system_mail_address, v_old_tracker_mail_address
	  FROM csrimp.customer;
	GetMailAccounts(m_new_host, v_new_system_mail_address, v_new_tracker_mail_address);

	SELECT sid_id
	  INTO v_accounts_sid
	  FROM csrimp.known_so
	 WHERE LOWER(path) = LOWER('/mail/accounts');

	SELECT sid_id
	  INTO v_folders_sid
	  FROM csrimp.known_so
	 WHERE LOWER(path) = LOWER('/mail/folders');

	AddChildRename('mail account', v_accounts_sid, v_old_system_mail_address, v_new_system_mail_address);
	AddChildRename('mail folder', v_folders_sid, v_old_system_mail_address, v_new_system_mail_address);
	AddChildRename('mail account', v_accounts_sid, v_old_tracker_mail_address, v_new_tracker_mail_address);
	AddChildRename('mail folder', v_folders_sid, v_old_tracker_mail_address, v_new_tracker_mail_address);
END;

/**
 * Updates schema names embedded in procedure calls
 *
 * @param	in_old_procedure_call	String representing the SP being called, e.g. 'customerX.ImportData'
 *
 * @return							String representing the remapped SP to be called, e.g. 'customerY.ImportData' or the original string
 */
FUNCTION MapCustomerSchema(
	in_old_procedure_call					IN	VARCHAR2
)
RETURN VARCHAR2
AS
	v_result 						VARCHAR2(4000) := in_old_procedure_call;
BEGIN
	-- fix helper procedures to point at any remapped cms schemas
	FOR r IN (SELECT old_oracle_schema, new_oracle_schema
				FROM csrimp.map_cms_schema) LOOP
		v_result := REGEXP_REPLACE(
	   		v_result,
	   		-- this is ^old_schema. with special characters quoted for the regex
	   		'^'||REGEXP_REPLACE(r.old_oracle_schema,'([.+?*{}^|\$[]|\])','\\\1')||'\.',
	   		-- so replace with new_schema.
	   		r.new_oracle_schema||'.',
	   		-- position (default)
	   		1,
	   		-- occurrence (all)
	   		0);
	END LOOP;
	RETURN v_result;
END;

-- These are done in a big bunch at the start so that GatherStats can
-- run after the tables have been populated.
--
-- Note that there are no stats when this is running, so if the queries
-- do anything that involves a join  shoving a CARDINALITY hint with
-- some representative statistics (which can easily be gathered from real
-- site data) in is wise.  (If there's no join then statistics aren't
-- going to help so mostly this isn't going to be an issue).
PROCEDURE PopulateIDMappings
AS
	v_card_id						chain.card.card_id%TYPE;
	v_filter_type_id				chain.filter_type.filter_type_id%TYPE;
BEGIN
	INSERT INTO csrimp.map_acl (old_acl_id, new_acl_id)
		SELECT dacl_id, security.acl_id_seq.nextval
		  FROM (SELECT DISTINCT dacl_id
		  		  FROM csrimp.securable_object);

	INSERT INTO csrimp.map_sid (old_sid, new_sid)
		SELECT sid_id, security.sid_id_seq.nextval
		  FROM csrimp.securable_object;

	INSERT INTO csrimp.map_delegation_layout (old_delegation_layout_id, new_delegation_layout_id)
		SELECT layout_id, csr.delegation_layout_id_seq.NEXTVAL
		  FROM csrimp.delegation_layout;

	INSERT INTO csrimp.map_ip_rule (old_ip_rule_id, new_ip_rule_id)
		SELECT ir.ip_rule_id, security.ip_rule_id_seq.nextval
		  FROM csrimp.ip_rule ir;

	INSERT INTO csrimp.map_rag_status (old_rag_status_id, new_rag_status_id)
		SELECT /*+CARDINALITY(issue_priority, 1000)*/
			   rag_status_id, csr.rag_status_id_seq.nextval
		  FROM csrimp.rag_status;

	INSERT INTO csrimp.map_tag_group (old_tag_group_id, new_tag_group_id)
		SELECT tag_group_id, csr.tag_group_id_seq.nextval
		  FROM csrimp.tag_group;

	INSERT INTO csrimp.map_tag (old_tag_id, new_tag_id)
		SELECT tag_id, csr.tag_id_seq.nextval
		  FROM csrimp.tag;

	INSERT INTO csrimp.map_baseline_config (old_baseline_config_id, new_baseline_config_id)
		SELECT baseline_config_id, csr.baseline_config_id_seq.nextval
		  FROM csrimp.baseline_config;

	INSERT INTO csrimp.map_baseline_config_period (old_baseline_config_period_id, new_baseline_config_period_id)
		SELECT baseline_config_period_id, csr.baseline_config_period_id_seq.nextval
		  FROM csrimp.baseline_config_period;

	INSERT INTO csrimp.map_accuracy_type (old_accuracy_type_id, new_accuracy_type_id)
		SELECT accuracy_type_id, csr.accuracy_type_id_seq.nextval
		  FROM csrimp.accuracy_type;

	INSERT INTO csrimp.map_accuracy_type_option (old_accuracy_type_option_id, new_accuracy_type_option_id)
		SELECT accuracy_type_option_id, csr.accuracy_type_option_id_seq.nextval
		  FROM csrimp.accuracy_type_option;

	INSERT INTO csrimp.map_customer_alert_type (old_customer_alert_type_id, new_customer_alert_type_id)
		SELECT customer_alert_type_id, csr.customer_alert_type_id_seq.nextval
		  FROM csrimp.customer_alert_type;

	-- frames
	INSERT INTO csrimp.map_alert_frame (old_alert_frame_id, new_alert_frame_id)
		SELECT alert_frame_id, csr.alert_frame_id_seq.nextval
		  FROM csrimp.alert_frame;

	-- now for measure conversion
	INSERT INTO csrimp.map_measure_conversion (old_measure_conversion_id, new_measure_conversion_id)
		SELECT measure_conversion_id, csr.measure_conversion_id_seq.nextval
		  FROM csrimp.measure_conversion;

	INSERT INTO csrimp.map_aggregate_ind_group (old_aggregate_ind_group_id, new_aggregate_ind_group_id)
		SELECT aggregate_ind_group_id, csr.aggregate_ind_group_id_seq.nextval
		  FROM csrimp.aggregate_ind_group;

	INSERT INTO csrimp.map_factor (old_factor_id, new_factor_id)
		SELECT factor_id, csr.factor_id_seq.nextval
		  FROM csrimp.factor;

	INSERT INTO csrimp.map_pending_ind (old_pending_ind_id, new_pending_ind_id)
		SELECT pending_ind_id, csr.pending_ind_id_seq.nextval
		  FROM csrimp.pending_ind;

	INSERT INTO csrimp.map_pending_region (old_pending_region_id, new_pending_region_id)
		SELECT pending_region_id, csr.pending_region_id_seq.nextval
		  FROM csrimp.pending_region;

	INSERT INTO csrimp.map_pending_period (old_pending_period_id, new_pending_period_id)
		SELECT pending_period_id, csr.pending_period_id_seq.nextval
		  FROM csrimp.pending_period;

	INSERT INTO csrimp.map_approval_step_sheet (old_approval_step_id, old_sheet_key,
		new_approval_step_id, new_sheet_key)
		SELECT /*+CARDINALITY(aps, 1000) CARDINALITY(maps, 50000) CARDINALITY(mpi, 10000)
				  CARDINALITY(mpr, 10000) CARDINALITY(mpp, 100)
				*/
			   aps.approval_step_id, aps.sheet_key, maps.new_sid,
			   replace(regexp_replace(mpi.new_pending_ind_id || '_' ||
			   mpr.new_pending_region_id || '_' || mpp.new_pending_period_id, '^_|_$', ''),'__', '_')
		  FROM csrimp.approval_step_sheet aps, csrimp.map_sid maps,
		  	   csrimp.map_pending_ind mpi, csrimp.map_pending_region mpr, csrimp.map_pending_period mpp
		 WHERE aps.approval_step_id = maps.old_sid
		   AND aps.pending_ind_id = mpi.old_pending_ind_id(+)
		   AND aps.pending_region_id = mpr.old_pending_region_id(+)
		   AND aps.pending_period_id = mpp.old_pending_period_id(+);

	INSERT INTO csrimp.map_pending_val (old_pending_val_id, new_pending_val_id)
		SELECT pending_val_id, csr.pending_val_id_seq.nextval
		  FROM csrimp.pending_val;

	INSERT INTO csrimp.map_var_expl_group (old_var_expl_group_id, new_var_expl_group_id)
		SELECT var_expl_group_id, csr.var_expl_group_id_seq.nextval
		  FROM csrimp.var_expl_group;

	INSERT INTO csrimp.map_var_expl (old_var_expl_id, new_var_expl_id)
		SELECT var_expl_id, csr.var_expl_id_seq.nextval
		  FROM csrimp.var_expl;

	-- make a bunch of mappings for delegation_date_schedule
	INSERT INTO csrimp.map_deleg_date_schedule (old_deleg_date_schedule_id, new_deleg_date_schedule_id)
		SELECT delegation_date_schedule_id, csr.delegation_date_schedule_seq.nextval
		  FROM csrimp.delegation_date_schedule;

	-- make a bunch of mappings
	INSERT INTO csrimp.map_delegation_ind_cond (old_delegation_ind_cond_id, new_delegation_ind_cond_id)
		SELECT delegation_ind_cond_id, csr.delegation_ind_cond_id_seq.nextval
		  FROM csrimp.delegation_ind_cond;

	-- make a bunch of mappings for form_expr
	INSERT INTO csrimp.map_deleg_ind_group (old_deleg_ind_group_id, new_deleg_ind_group_id)
		SELECT deleg_ind_group_id, csr.deleg_ind_group_id_seq.nextval
		  FROM csrimp.deleg_ind_group;

	-- make a bunch of mappings for the groups
	INSERT INTO csrimp.map_form_expr (old_form_expr_id, new_form_expr_id)
		SELECT form_expr_id, csr.form_expr_id_seq.nextval
		  FROM csrimp.form_expr;

	-- pre-map deleg_plan_col_ids and deleg_plan_col_deleg_ids
	INSERT INTO csrimp.map_deleg_plan_col (old_deleg_plan_col_id, new_deleg_plan_col_id)
		SELECT deleg_plan_col_id, csr.deleg_plan_col_id_seq.nextval
		  FROM csrimp.deleg_plan_col;

	INSERT INTO csrimp.map_deleg_plan_col_deleg (old_deleg_plan_col_deleg_id, new_deleg_plan_col_deleg_id)
		SELECT deleg_plan_col_deleg_id, csr.deleg_plan_col_deleg_id_seq.nextval
		  FROM csrimp.deleg_plan_col_deleg;

	INSERT INTO csrimp.map_deleg_plan_col_survey (old_deleg_plan_col_survey_id, new_deleg_plan_col_survey_id)
		SELECT deleg_plan_col_survey_id, csr.deleg_plan_col_survey_id_seq.nextval
		  FROM csrimp.deleg_plan_col_survey;

	INSERT INTO csrimp.map_user_cover (old_user_cover_id, new_user_cover_id)
		SELECT user_cover_id, csr.user_cover_id_seq.nextval
		  FROM csrimp.user_cover;

	INSERT INTO csrimp.map_sheet (old_sheet_id, new_sheet_id)
		SELECT s.sheet_id, csr.sheet_id_seq.nextval
		  FROM csrimp.sheet s, csrimp.map_sid md
		 WHERE md.old_sid = s.delegation_sid;

	INSERT INTO csrimp.map_sheet_history (old_sheet_history_id, new_sheet_history_id)
		SELECT sh.sheet_history_id, csr.sheet_history_id_seq.nextval
		  FROM csrimp.map_sheet ms, csrimp.sheet_history sh
		 WHERE ms.old_sheet_id = sh.sheet_id;

	INSERT INTO csrimp.map_sheet_value (old_sheet_value_id, new_sheet_value_id)
		SELECT sv.sheet_value_id, csr.sheet_value_id_seq.nextval
		  FROM csrimp.sheet_value sv, csrimp.map_sheet ms
		 WHERE sv.sheet_id = ms.old_sheet_id;

	INSERT INTO csrimp.map_sheet_value_change (old_sheet_value_change_id, new_sheet_value_change_id)
		SELECT svc.sheet_value_change_id, csr.sheet_value_change_id_seq.nextval
		  FROM csrimp.sheet_value_change svc;

	INSERT INTO csrimp.map_form_allocation (old_form_allocation_id, new_form_allocation_id)
		SELECT form_allocation_id, csr.form_allocation_id_seq.nextval
		  FROM csrimp.form_allocation;

	INSERT INTO csrimp.map_imp_ind (old_imp_ind_id, new_imp_ind_id)
		SELECT ii.imp_ind_id, csr.imp_ind_id_seq.nextval
		  FROM csrimp.imp_ind ii;

	INSERT INTO csrimp.map_imp_region (old_imp_region_id, new_imp_region_id)
		SELECT ir.imp_region_id, csr.imp_region_id_seq.nextval
		  FROM csrimp.imp_region ir;

	INSERT INTO csrimp.map_imp_measure (old_imp_measure_id, new_imp_measure_id)
		SELECT im.imp_measure_id, csr.imp_measure_id_seq.nextval
		  FROM csrimp.imp_measure im;

	INSERT INTO csrimp.map_imp_val (old_imp_val_id, new_imp_val_id)
		SELECT iv.imp_val_id, csr.imp_val_id_seq.nextval
		  FROM csrimp.imp_val iv;

	INSERT INTO csrimp.map_imp_conflict (old_imp_conflict_id, new_imp_conflict_id)
		SELECT ic.imp_conflict_id, csr.imp_conflict_id_seq.nextval
		  FROM csrimp.imp_conflict ic;

	INSERT INTO csrimp.map_val (old_val_id, new_val_id)
		SELECT /*+CARDINALITY(val, 5000000)*/
			   val_id, csr.val_id_seq.nextval
		  FROM csrimp.val;

	INSERT INTO csrimp.map_attachment (old_attachment_id, new_attachment_id)
		SELECT attachment_id, csr.attachment_id_seq.nextval
		  FROM csrimp.attachment;

	INSERT INTO csrimp.map_section_cart_folder (old_section_cart_folder_id, new_section_cart_folder_id)
		SELECT section_cart_folder_id, csr.section_cart_folder_id_seq.nextval
		  FROM csrimp.section_cart_folder;

	INSERT INTO csrimp.map_section_cart (old_section_cart_id, new_section_cart_id)
		SELECT section_cart_id, csr.section_cart_id_seq.nextval
		  FROM csrimp.section_cart;

	INSERT INTO csrimp.map_section_tag (old_section_tag_id, new_section_tag_id)
		SELECT section_tag_id, csr.section_tag_id_seq.nextval
		  FROM csrimp.section_tag;

	INSERT INTO csrimp.map_route (old_route_id, new_route_id)
		SELECT route_id, csr.route_id_seq.nextval
		  FROM csrimp.route;

	INSERT INTO csrimp.map_route_step (old_route_step_id, new_route_step_id)
		SELECT route_step_id, csr.route_step_id_seq.nextval
		  FROM csrimp.route_step;

	INSERT INTO csrimp.map_section_comment (old_section_comment_id, new_section_comment_id)
		SELECT section_comment_id, csr.section_comment_id_seq.nextval
		  FROM csrimp.section_comment;

	INSERT INTO csrimp.map_section_trans_comment (old_section_t_comment_id, new_section_t_comment_id)
		SELECT section_trans_comment_id, csr.section_trans_comment_id_seq.nextval
		  FROM csrimp.section_trans_comment;

	INSERT INTO csrimp.map_section_alert (old_section_alert_id, new_section_alert_id)
		SELECT section_alert_id, csr.section_alert_id_seq.nextval
		  FROM csrimp.section_alert;

	INSERT INTO csrimp.map_customer_flow_cap (old_customer_flow_cap_id, new_customer_flow_cap_id)
		 SELECT flow_capability_id, csr.customer_flow_cap_id_seq.nextval
		   FROM csrimp.customer_flow_capability;

	INSERT INTO csrimp.map_flow_state (old_flow_state_id, new_flow_state_id)
		SELECT flow_state_id, csr.flow_state_id_seq.nextval
		  FROM csrimp.flow_state;

	INSERT INTO csrimp.map_flow_item (old_flow_item_id, new_flow_item_id)
		SELECT /*+CARDINALITY(fi, 50000)*/ fi.flow_item_id, csr.flow_item_id_seq.nextval
		  FROM csrimp.flow_item fi;

	INSERT INTO csrimp.map_flow_state_log (old_flow_state_log_id, new_flow_state_log_id)
		SELECT /*+CARDINALITY(fsl, 50000)*/
			   fsl.flow_state_log_id, csr.flow_state_log_id_seq.nextval
		  FROM csrimp.flow_state_log fsl;

	INSERT INTO csrimp.map_flow_state_rl_cap (old_flow_state_rl_cap_id, new_flow_state_rl_cap_id)
		SELECT /*+CARDINALITY(fsrc, 50000)*/
			   fsrc.flow_state_rl_cap_id, csr.flow_state_rl_cap_id_seq.nextval
		  FROM csrimp.flow_state_role_capability fsrc;

	INSERT INTO csrimp.map_flow_state_transition (old_flow_state_transition_id, new_flow_state_transition_id)
		SELECT /*+CARDINALITY(fst, 50000)*/
			   fst.flow_state_transition_id, csr.flow_state_transition_id_seq.nextval
		  FROM csrimp.flow_state_transition fst;

	INSERT INTO csrimp.map_flow_transition_alert (old_flow_transition_alert_id, new_flow_transition_alert_id)
		SELECT /*+CARDINALITY(fta, 1000)*/
			   fta.flow_transition_alert_id, csr.flow_transition_alert_id_seq.nextval
		  FROM csrimp.flow_transition_alert fta;

	INSERT INTO csrimp.map_cms_aggregate_type (old_cms_aggregate_type_id, new_cms_aggregate_type_id)
		SELECT /*+CARDINALITY(cat, 100)*/
			   cms_aggregate_type_id, cms.cms_aggregate_type_id_seq.nextval
		  FROM csrimp.cms_aggregate_type cat;

	INSERT INTO csrimp.map_cms_tab_column (old_column_id, new_column_id)
		SELECT /*+CARDINALITY(ctc, 50000)*/
			   column_sid, cms.column_id_seq.nextval
		  FROM csrimp.cms_tab_column ctc;

	INSERT INTO csrimp.map_cms_uk_cons (old_uk_cons_id, new_uk_cons_id)
		SELECT /*+CARDINALITY(uk, 2000)*/
			   uk.uk_cons_id, cms.uk_cons_id_seq.nextval
		  FROM csrimp.cms_uk_cons uk;

	INSERT INTO csrimp.map_cms_fk_cons (old_fk_cons_id, new_fk_cons_id)
		SELECT /*+CARDINALITY(mfk, 2000)*/
			   cfk.fk_cons_id, cms.fk_cons_id_seq.nextval
		  FROM csrimp.cms_fk_cons cfk;

	INSERT INTO csrimp.map_cms_ck_cons (old_ck_cons_id, new_ck_cons_id)
		SELECT /*+CARDINALITY(mk, 2000)*/
			   ck.ck_cons_id, cms.ck_cons_id_seq.nextval
		  FROM csrimp.cms_ck_cons ck;

	INSERT INTO csrimp.map_cms_display_template (old_display_template_id, new_display_template_id)
		SELECT /*+CARDINALITY(dt, 1000)*/
			   dt.display_template_id, cms.display_template_id_seq.nextval
		  FROM csrimp.cms_display_template dt;

	INSERT INTO csrimp.map_cms_doc_template (old_doc_template_id, new_doc_template_id)
		SELECT /*+CARDINALITY(dt, 1000)*/
			   dt.doc_template_id, cms.doc_template_id_seq.nextval
		  FROM csrimp.cms_doc_template dt;

	INSERT INTO csrimp.map_cms_doc_template_file (old_doc_template_file_id, new_doc_template_file_id)
		SELECT /*+CARDINALITY(dt, 1000)*/
			   dt.doc_template_file_id, cms.doc_template_file_id_seq.nextval
		  FROM csrimp.cms_doc_template_file dt;

	INSERT INTO csrimp.map_cms_image (old_image_id, new_image_id)
		SELECT /*+CARDINALITY(ci, 5000)*/
			   ci.image_id, cms.item_id_seq.nextval
		  FROM csrimp.cms_image ci;

	INSERT INTO csrimp.map_cms_tag (old_tag_id, new_tag_id)
		SELECT /*+CARDINALITY(ct, 1000)*/
			   tag_id, cms.tag_id_seq.nextval
		  FROM csrimp.cms_tag ct;

	INSERT INTO csrimp.map_cms_tab_column_link (old_column_link_id, new_column_link_id)
		SELECT /*+CARDINALITY(ctclt, 1000)*/
			   ctclt.tab_column_link_id, cms.tab_column_link_seq.nextval
		  FROM csrimp.cms_tab_column_link ctclt;

	INSERT INTO map_cms_enum_group (old_enum_group_id, new_enum_group_id)
		 SELECT /*+CARDINALITY(ct, 1000)*/
			    ct.enum_group_id, cms.enum_group_id_seq.nextval
		   FROM cms_enum_group ct;

	INSERT INTO map_compliance_item (old_compliance_item_id, new_compliance_item_id)
		SELECT /*+CARDINALITY(ci, 10000)*/
		       ci.compliance_item_id, csr.compliance_item_seq.nextval
		  FROM compliance_item ci;

	INSERT INTO map_compliance_item_rollout (old_compliance_item_rollout_id, new_compliance_item_rollout_id)
		SELECT /*+CARDINALITY(ci, 10000)*/
		       ci.compliance_item_rollout_id, csr.compliance_item_rollout_id_seq.nextval
		  FROM compliance_item_rollout ci;

	INSERT INTO map_comp_item_version_log (old_comp_item_version_log_id, new_comp_item_version_log_id)
		SELECT /*+CARDINALITY(civl, 10000)*/
		       civl.compliance_item_version_log_id, csr.comp_item_version_log_seq.nextval
		  FROM compliance_item_version_log civl;

	INSERT INTO map_compliance_item_desc_hist (old_comp_item_desc_hist_id, new_comp_item_desc_hist_id)
		SELECT /*+CARDINALITY(cidh, 10000)*/
		       cidh.compliance_item_desc_hist_id, csr.compliance_item_desc_hist_seq.nextval
		  FROM compliance_item_desc_hist cidh;

	INSERT INTO map_compliance_audit_log (old_compliance_audit_log_id, new_compliance_audit_log_id)
		SELECT /*+CARDINALITY(cal, 10000)*/
			   cal.compliance_audit_log_id, csr.compliance_audit_log_id_seq.nextval
		  FROM compliance_audit_log cal;

	INSERT INTO map_flow_item_audit_log (old_flow_item_audit_log_id, new_flow_item_audit_log_id)
		SELECT /*+CARDINALITY(cirl, 10000)*/
		       fial.flow_item_audit_log_id, csr.flow_item_audit_log_id_seq.nextval
		  FROM flow_item_audit_log fial;

	INSERT INTO csrimp.map_complian_permit_type (old_compliance_permit_type_id, new_compliance_permit_type_id)
		 SELECT /*+CARDINALITY(t, 10000)*/
				permit_type_id, csr.compliance_permit_type_seq.NEXTVAL
		   FROM csrimp.compliance_permit_type t;

	INSERT INTO csrimp.map_complia_conditi_type (old_complian_condition_type_id, new_complian_condition_type_id)
		 SELECT /*+CARDINALITY(t, 10000)*/
				condition_type_id, csr.compliance_condition_type_seq.NEXTVAL
		   FROM csrimp.compliance_condition_type t;

	INSERT INTO csrimp.map_complia_activit_type (old_complianc_activity_type_id, new_complianc_activity_type_id)
		 SELECT /*+CARDINALITY(t, 10000)*/
				activity_type_id, csr.compliance_activity_type_seq.NEXTVAL
		   FROM csrimp.compliance_activity_type t;

	INSERT INTO csrimp.map_compl_activity_sub_type (old_complianc_activity_type_id, new_complianc_activity_type_id, old_compl_activity_sub_type_id, new_compl_activity_sub_type_id)
		 SELECT /*+CARDINALITY(t, 10000)*/
				old_complianc_activity_type_id, new_complianc_activity_type_id, activity_sub_type_id, csr.compliance_activ_sub_type_seq.NEXTVAL
		   FROM csrimp.compliance_activity_sub_type t
		   JOIN csrimp.map_complia_activit_type mat ON t.activity_type_id = mat.old_complianc_activity_type_id;

	INSERT INTO csrimp.map_complian_applicat_tp (old_complianc_applicatio_tp_id, new_complianc_applicatio_tp_id)
		 SELECT /*+CARDINALITY(t, 10000)*/
				application_type_id, csr.compliance_application_tp_seq.NEXTVAL
		   FROM csrimp.compliance_application_type t;

	INSERT INTO csrimp.map_compliance_permit (old_compliance_permit_id, new_compliance_permit_id)
		 SELECT /*+CARDINALITY(t, 10000)*/
				compliance_permit_id, csr.compliance_permit_seq.NEXTVAL
		   FROM csrimp.compliance_permit t;

	INSERT INTO csrimp.map_compliance_permit_score (old_compliance_permit_score_id, new_compliance_permit_score_id)
		 SELECT /*+CARDINALITY(t, 10000)*/
				compliance_permit_score_id, csr.compliance_permit_score_id_seq.NEXTVAL
		   FROM csrimp.compliance_permit_score t;

	INSERT INTO csrimp.map_compl_permi_sub_type (old_compliance_permit_type_id, new_compliance_permit_type_id, old_complia_permit_sub_type_id, new_complia_permit_sub_type_id)
		 SELECT /*+CARDINALITY(t, 10000)*/
				old_compliance_permit_type_id, new_compliance_permit_type_id, permit_sub_type_id, csr.compliance_permit_sub_type_seq.NEXTVAL
		   FROM csrimp.compliance_permit_sub_type t
		   JOIN csrimp.map_complian_permit_type m ON t.permit_type_id = m.old_compliance_permit_type_id;

	INSERT INTO csrimp.map_complia_condition_sub_type (old_complian_condition_type_id, new_complian_condition_type_id, old_comp_condition_sub_type_id, new_comp_condition_sub_type_id)
		 SELECT /*+CARDINALITY(t, 10000)*/
				old_complian_condition_type_id, new_complian_condition_type_id, condition_sub_type_id, csr.compliance_cond_sub_type_seq.NEXTVAL
		   FROM csrimp.compliance_condition_sub_type t
		   JOIN csrimp.map_complia_conditi_type m ON t.condition_type_id = m.old_complian_condition_type_id;

	INSERT INTO csrimp.map_complian_permit_appl (old_compliance_permit_appl_id, new_compliance_permit_appl_id)
		 SELECT /*+CARDINALITY(t, 10000)*/
				permit_application_id, csr.compliance_permit_appl_seq.NEXTVAL
		   FROM csrimp.compliance_permit_application t;
	
	INSERT INTO csrimp.map_enhesa_error_log (old_error_log_id, new_error_log_id)
		SELECT error_log_id, csr.enhesa_error_log_id_seq.NEXTVAL
		  FROM csrimp.enhesa_error_log;

	INSERT INTO csrimp.map_doc (old_doc_id, new_doc_id)
		SELECT doc_id, csr.doc_id_seq.nextval
		  FROM csrimp.doc;

	INSERT INTO csrimp.map_doc_type (old_doc_type_id, new_doc_type_id)
		SELECT doc_type_id, csr.doc_type_id_seq.nextval
		  FROM csrimp.doc_type;

	INSERT INTO csrimp.map_doc_data (old_doc_data_id, new_doc_data_id)
		SELECT doc_data_id, csr.doc_data_id_seq.nextval
		  FROM csrimp.doc_data;

	INSERT INTO csrimp.map_event (old_event_id, new_event_id)
		SELECT /*+CARDINALITY(event, 1000)*/
			   event_id, csr.event_id_seq.nextval
		  FROM csrimp.event;

	INSERT INTO csrimp.map_meter_aggregate_type (old_meter_aggregate_type_id, new_meter_aggregate_type_id)
		SELECT meter_aggregate_type_id, csr.meter_aggregate_type_id_seq.nextval
		  FROM csrimp.meter_aggregate_type;

	INSERT INTO csrimp.map_meter_alarm_statistic (old_statistic_id, new_statistic_id)
		SELECT /*+CARDINALITY(meter_alarm_statistic, 100)*/
			   statistic_id, csr.meter_statistic_id_seq.nextval
		  FROM csrimp.meter_alarm_statistic;

	INSERT INTO csrimp.map_meter_alarm_comparison (old_comparison_id, new_comparison_id)
		SELECT /*+CARDINALITY(meter_alarm_comparison, 100)*/
			   comparison_id, csr.meter_comparison_id_seq.nextval
		  FROM csrimp.meter_alarm_comparison;

	INSERT INTO csrimp.map_meter_alarm_issue_period (old_issue_period_id, new_issue_period_id)
		SELECT /*+CARDINALITY(meter_alarm_issue_period, 100)*/
			   issue_period_id, csr.meter_issue_period_id_seq.nextval
		  FROM csrimp.meter_alarm_issue_period;

	INSERT INTO csrimp.map_meter_alarm_test_time (old_test_time_id, new_test_time_id)
		SELECT /*+CARDINALITY(meter_alarm_test_time, 100)*/
			   test_time_id, csr.meter_test_time_id_seq.nextval
		  FROM csrimp.meter_alarm_test_time;

	INSERT INTO csrimp.map_meter_alarm (old_meter_alarm_id, new_meter_alarm_id)
		SELECT /*+CARDINALITY(meter_alarm, 100)*/
			   meter_alarm_id, csr.meter_alarm_id_seq.nextval
		  FROM csrimp.meter_alarm;

	INSERT INTO csrimp.map_core_working_hours (old_core_working_hours_id, new_core_working_hours_id)
		SELECT core_working_hours_id, csr.core_working_hours_id_seq.nextval
		  FROM csrimp.core_working_hours;

	INSERT INTO csrimp.map_meter_type (old_meter_type_id, new_meter_type_id)
		SELECT meter_type_id, csr.meter_type_id_seq.nextval
		  FROM csrimp.meter_type;

	INSERT INTO csrimp.map_meter_input (old_meter_input_id, new_meter_input_id)
		SELECT meter_input_id, csr.meter_input_id_seq.nextval
		  FROM csrimp.meter_input;

	INSERT INTO csrimp.map_meter_raw_data_source (old_raw_data_source_id, new_raw_data_source_id)
		SELECT /*+CARDINALITY(meter_raw_data_source, 100)*/
			   raw_data_source_id, csr.raw_data_source_id_seq.nextval
		  FROM csrimp.meter_raw_data_source;

	INSERT INTO csrimp.map_meter_bucket (old_meter_bucket_id, new_meter_bucket_id)
		SELECT /*+CARDINALITY(meter_bucket, 100)*/
			   meter_bucket_id, csr.meter_bucket_id_seq.nextval
		  FROM csrimp.meter_bucket;

	INSERT INTO csrimp.map_meter_raw_data (old_meter_raw_data_id, new_meter_raw_data_id)
		SELECT /*+CARDINALITY(meter_raw_data, 500000)*/
			   meter_raw_data_id, csr.meter_raw_data_id_seq.nextval
		  FROM csrimp.meter_raw_data;

	INSERT INTO csrimp.map_meter_document (old_meter_document_id, new_meter_document_id)
		SELECT /*+CARDINALITY(meter_document, 10000)*/
			   meter_document_id, csr.meter_document_id_seq.nextval
		  FROM csrimp.meter_document;

	INSERT INTO csrimp.map_meter_header_element (old_meter_header_element_id, new_meter_header_element_id)
		 SELECT meter_header_element_id, csr.meter_header_element_id_seq.nextval
		   FROM csrimp.meter_header_element;

	INSERT INTO csrimp.map_meter_photo (old_meter_photo_id, new_meter_photo_id)
		 SELECT meter_photo_id, csr.meter_photo_id_seq.nextval
		   FROM csrimp.meter_photo;

	INSERT INTO csrimp.map_utility_supplier (old_utility_supplier_id, new_utility_supplier_id)
		SELECT /*+CARDINALITY(utility_supplier, 100)*/
			   utility_supplier_id, cms.item_id_seq.nextval
		  FROM csrimp.utility_supplier;

	INSERT INTO csrimp.map_utility_contract (old_utility_contract_id, new_utility_contract_id)
		SELECT /*+CARDINALITY(us, 100) CARDINALITY(mus, 100)*/
			   utility_contract_id, cms.item_id_seq.nextval
		  FROM csrimp.utility_contract;

	INSERT INTO csrimp.map_utility_invoice (old_utility_invoice_id, new_utility_invoice_id)
		SELECT /*+CARDINALITY(utility_invoice, 10000)*/
			   utility_invoice_id, cms.item_id_seq.nextval
		  FROM csrimp.utility_invoice;

	INSERT INTO csrimp.map_meter_reading (old_meter_reading_id, new_meter_reading_id)
		SELECT /*+CARDINALITY(meter_reading, 1000000)*/
			   meter_reading_id, csr.meter_reading_id_seq.nextval
		  FROM csrimp.meter_reading;

	INSERT INTO csrimp.map_issue_pending_val (old_issue_pending_val_id, new_issue_pending_val_id)
		SELECT /*+CARDINALITY(issue_pending_val, 10000)*/
			   issue_pending_val_id, csr.issue_pending_val_id_seq.nextval
		  FROM csrimp.issue_pending_val;

	INSERT INTO csrimp.map_issue_sheet_value (old_issue_sheet_value_id, new_issue_sheet_value_id)
		SELECT /*+CARDINALITY(issue_sheet_value, 10000)*/
			   issue_sheet_value_id, csr.issue_sheet_value_id_seq.nextval
		  FROM csrimp.issue_sheet_value;

	INSERT INTO csrimp.map_issue_meter (old_issue_meter_id, new_issue_meter_id)
		SELECT /*+CARDINALITY(issue_meter, 10000)*/
			   issue_meter_id, csr.issue_meter_id_seq.nextval
		  FROM csrimp.issue_meter;

	INSERT INTO csrimp.map_issue_priority (old_issue_priority_id, new_issue_priority_id)
		SELECT /*+CARDINALITY(issue_priority, 1000)*/
			   issue_priority_id, csr.issue_priority_id_seq.nextval
		  FROM csrimp.issue_priority;

/*	INSERT INTO csrimp.map_issue_type (old_issue_type_id, new_issue_type_id)
		SELECT issue_type_id, csr.issue_type_id_seq.nextval
		  FROM csrimp.issue_type;*/

	INSERT INTO csrimp.map_issue_meter_alarm (old_issue_meter_alarm_id, new_issue_meter_alarm_id)
		SELECT /*+CARDINALITY(issue_meter_alarm, 10000)*/
			   issue_meter_alarm_id, csr.issue_meter_alarm_id_seq.nextval
		  FROM csrimp.issue_meter_alarm;

	INSERT INTO csrimp.map_meter_data_id (old_meter_data_id, new_meter_data_id)
		SELECT meter_data_id, csr.meter_data_id_seq.nextval
		  FROM csrimp.meter_live_data;

	INSERT INTO csrimp.map_issue_meter_data_source (old_issue_meter_data_source_id, new_issue_meter_data_source_id)
		SELECT /*+CARDINALITY(issue_meter_data_source, 10000)*/
			   issue_meter_data_source_id, csr.issue_meter_data_source_id_seq.nextval
		  FROM csrimp.issue_meter_data_source;

	INSERT INTO csrimp.map_issue_meter_raw_data (old_issue_meter_raw_data_id, new_issue_meter_raw_data_id)
		SELECT /*+CARDINALITY(issue_meter_raw_data, 10000)*/
			   issue_meter_raw_data_id, csr.issue_meter_raw_data_id_seq.nextval
		  FROM csrimp.issue_meter_raw_data;

	INSERT INTO csrimp.map_issue (old_issue_id, new_issue_id)
		SELECT /*+CARDINALITY(issue, 10000)*/
			   issue_id, csr.issue_id_seq.nextval
		  FROM csrimp.issue;

	INSERT INTO csrimp.map_correspondent (old_correspondent_id, new_correspondent_id)
		SELECT /*+CARDINALITY(correspondent, 1000)*/
			   correspondent_id, csr.correspondent_id_seq.nextval
		  FROM csrimp.correspondent;

	INSERT INTO csrimp.map_issue_survey_answer (old_issue_survey_answer_id, new_issue_survey_answer_id)
		SELECT /*+CARDINALITY(issue_survey_answer, 10000)*/
			   issue_survey_answer_id, csr.issue_survey_answer_id_seq.nextval
		  FROM csrimp.issue_survey_answer;

	INSERT INTO map_issue_scheduled_task (old_issue_scheduled_task_id, new_issue_scheduled_task_id)
		SELECT /*+CARDINALITY(issue_scheduled_task, 1000)*/
			   issue_scheduled_task_id, csr.issue_scheduled_task_id_seq.nextval
		   FROM issue_scheduled_task;

	INSERT INTO csrimp.map_issue_non_compliance (old_issue_non_compliance_id, new_issue_non_compliance_id)
		SELECT /*+CARDINALITY(issue_non_compliance, 10000)*/
			   issue_non_compliance_id, csr.issue_non_compliance_id_seq.nextval
		  FROM csrimp.issue_non_compliance;

	INSERT INTO csrimp.map_issue_log (old_issue_log_id, new_issue_log_id)
		SELECT /*+CARDINALITY(issue_log, 10000)*/ issue_log_id, csr.issue_log_id_seq.nextval
		  FROM csrimp.issue_log;

	INSERT INTO map_issue_compliance_region (old_issue_compliance_region_id, new_issue_compliance_region_id)
		SELECT /*+CARDINALITY(issue_compliance_region, 10000)*/ issue_compliance_region_id, csr.issue_compliance_region_id_seq.nextval
		  FROM issue_compliance_region;

	INSERT INTO csrimp.map_issue_custom_field (old_issue_custom_field_id, new_issue_custom_field_id)
		SELECT /*+CARDINALITY(issue_custom_field, 1000)*/
			   issue_custom_field_id, csr.issue_custom_field_id_seq.nextval
		  FROM csrimp.issue_custom_field;

	INSERT INTO csrimp.map_issue_template (old_issue_template_id, new_issue_template_id)
		 SELECT issue_template_id, csr.issue_template_id_seq.NEXTVAL
		   FROM csrimp.issue_template;

	INSERT INTO csrimp.map_tab (old_tab_id, new_tab_id)
		SELECT tab_id, csr.tab_id_seq.nextval
		  FROM csrimp.tab;

	INSERT INTO csrimp.map_tab_portlet (old_tab_portlet_id, new_tab_portlet_id)
		SELECT tab_portlet_id, csr.tab_portlet_id_seq.nextval
		  FROM csrimp.tab_portlet;

	INSERT INTO csrimp.map_dashboard_instance (old_dashboard_instance_id, new_dashboard_instance_id)
		SELECT dashboard_instance_id, csr.dashboard_instance_id_seq.nextval
		  FROM csrimp.approval_dashboard_instance;

	INSERT INTO csrimp.map_appr_dash_val (old_approval_dashboard_val_id, new_approval_dashboard_val_id)
		SELECT approval_dashboard_val_id, csr.approval_dashboard_val_id_seq.nextval
		  FROM csrimp.approval_dashboard_val;

	INSERT INTO csrimp.map_tpl_report_tag_dv (old_tpl_report_tag_dv_id, new_tpl_report_tag_dv_id)
		SELECT tpl_report_tag_dataview_id, csr.tpl_report_tag_dataview_id_seq.nextval
		  FROM csrimp.tpl_report_tag_dataview;

	INSERT INTO csrimp.map_tpl_report_tag_eval (old_tpl_report_tag_eval_id, new_tpl_report_tag_eval_id)
		SELECT tpl_report_tag_eval_id, csr.tpl_report_tag_eval_id_seq.nextval
		  FROM csrimp.tpl_report_tag_eval;

	INSERT INTO csrimp.map_tpl_report_tag_ind (old_tpl_report_tag_ind_id, new_tpl_report_tag_ind_id)
		SELECT tpl_report_tag_ind_id, csr.tpl_report_tag_ind_id_seq.nextval
		  FROM csrimp.tpl_report_tag_ind;

	INSERT INTO csrimp.map_tpl_report_tag_log_frm (old_tpl_report_tag_log_frm_id, new_tpl_report_tag_log_frm_id)
		SELECT tpl_report_tag_logging_form_id, csr.tpl_report_tag_logging_frm_seq.nextval
		  FROM csrimp.tpl_report_tag_logging_form;

	INSERT INTO csrimp.map_tpl_report_tag_qc (old_tpl_report_tag_qc_id, new_tpl_report_tag_qc_id)
		SELECT tpl_report_tag_qchart_id, csr.tpl_report_tag_qc_id_seq.nextval
		  FROM csrimp.tpl_report_tag_qchart;

	INSERT INTO csrimp.map_tpl_report_non_compl (old_tpl_report_non_compl_id, new_tpl_report_non_compl_id)
		SELECT tpl_report_non_compl_id, csr.tpl_report_non_compl_id_seq.nextval
		  FROM csrimp.tpl_report_non_compl;

	INSERT INTO csrimp.map_tpl_report_tag_text (old_tpl_report_tag_text_id, new_tpl_report_tag_text_id)
		SELECT tpl_report_tag_text_id, csr.tpl_report_tag_text_id_seq.nextval
		  FROM tpl_report_tag_text;

	INSERT INTO csrimp.map_tpl_rep_tag_appr_note (old_tpl_rep_tag_appr_note_id, new_tpl_rep_tag_appr_note_id)
		SELECT tpl_report_tag_app_note_id, csr.tpl_report_tag_app_note_id_seq.nextval
		  FROM csrimp.tpl_report_tag_approval_note;

	INSERT INTO csrimp.map_tpl_report_tag_appr_matr (old_tpl_rep_tag_appr_matr_id, new_tpl_rep_tag_appr_matr_id)
		SELECT tpl_report_tag_app_matrix_id, csr.tpl_rep_tag_app_matrix_id_seq.nextval
		  FROM csrimp.tpl_report_tag_approval_matrix;

	INSERT INTO csrimp.map_dashboard_item (old_dashboard_item_id, new_dashboard_item_id)
		SELECT dashboard_item_id, csr.dashboard_item_id_seq.nextval
		  FROM csrimp.dashboard_item;

	INSERT INTO csrimp.map_model_sheet (old_sheet_id, new_sheet_id)
		SELECT /*+CARDINALITY(model_sheet, 1000)*/
			   sheet_id, csr.sheet_id_seq.nextval
		  FROM csrimp.model_sheet;

	INSERT INTO csrimp.map_model_range (old_range_id, new_range_id)
		SELECT /*+CARDINALITY(model_range, 1000)*/
			   range_id, csr.model_range_id_seq.nextval
		  FROM csrimp.model_range;

	INSERT INTO csrimp.map_ia_type_survey_group (old_ia_type_survey_group_id, new_ia_type_survey_group_id)
		 SELECT ia_type_survey_group_id, csr.ia_type_survey_group_id_seq.nextval
		   FROM csrimp.ia_type_survey_group;

	INSERT INTO csrimp.map_ia_type_survey (old_ia_type_survey_id, new_ia_type_survey_id)
		 SELECT internal_audit_type_survey_id, csr.ia_type_survey_id_seq.nextval
		   FROM csrimp.internal_audit_type_survey;

	INSERT INTO csrimp.map_internal_audit_type (old_internal_audit_type_id, new_internal_audit_type_id)
		SELECT internal_audit_type_id, csr.internal_audit_type_id_seq.nextval
		  FROM csrimp.internal_audit_type;

	INSERT INTO csrimp.map_internal_audit_type_report (old_internal_audit_type_rep_id, new_internal_audit_type_rep_id)
		 SELECT internal_audit_type_report_id, csr.internal_audit_type_report_seq.nextval
		   FROM csrimp.internal_audit_type_report;

    INSERT INTO csrimp.map_internal_audit_type_group (old_inter_audit_type_group_id, new_inter_audit_type_group_id)
		SELECT internal_audit_type_group_id, csr.internal_audit_type_group_seq.nextval
		  FROM csrimp.internal_audit_type_group;

	INSERT INTO csrimp.map_audit_closure_type (old_audit_closure_type_id, new_audit_closure_type_id)
		SELECT audit_closure_type_id, csr.audit_closure_type_id_seq.nextval
		  FROM csrimp.audit_closure_type;

	INSERT INTO csrimp.map_internal_audit_file_data (old_int_audit_file_data_id, new_int_audit_file_data_id)
		SELECT internal_audit_file_data_id, csr.internal_audit_file_id_seq.nextval
		  FROM csrimp.internal_audit_file_data;

	INSERT INTO csrimp.map_non_comp_default (old_non_comp_default_id, new_non_comp_default_id)
		SELECT non_comp_default_id, csr.non_comp_default_id_seq.nextval
		  FROM csrimp.non_comp_default;

	INSERT INTO csrimp.map_non_comp_default_folder (old_non_comp_default_folder_id, new_non_comp_default_folder_id)
		SELECT non_comp_default_folder_id, csr.non_comp_default_folder_id_seq.nextval
		  FROM csrimp.non_comp_default_folder;

	INSERT INTO csrimp.map_non_comp_default_issue (old_non_comp_default_issue_id, new_non_comp_default_issue_id)
		SELECT non_comp_default_issue_id, csr.non_comp_default_issue_id_seq.nextval
		  FROM csrimp.non_comp_default_issue;

	INSERT INTO csrimp.map_non_compliance (old_non_compliance_id, new_non_compliance_id)
		SELECT non_compliance_id, csr.non_compliance_id_seq.nextval
		  FROM csrimp.non_compliance;

	INSERT INTO csrimp.map_non_compliance_type (old_non_compliance_type_id, new_non_compliance_type_id)
		SELECT non_compliance_type_id, csr.non_compliance_type_id_seq.nextval
		  FROM csrimp.non_compliance_type;

	INSERT INTO csrimp.map_audit_non_compliance (old_audit_non_compliance_id, new_audit_non_compliance_id)
		SELECT audit_non_compliance_id, csr.audit_non_compliance_id_seq.nextval
		  FROM csrimp.audit_non_compliance;

	INSERT INTO csrimp.map_score_type (old_score_type_id, new_score_type_id)
		SELECT score_type_id, csr.score_type_id_seq.nextval
		  FROM csrimp.score_type;

	INSERT INTO csrimp.map_score_type_agg_type (old_score_type_agg_type_id, new_score_type_agg_type_id)
		SELECT score_type_agg_type_id, csr.score_type_agg_type_id_seq.nextval
		  FROM csrimp.score_type_agg_type;

	INSERT INTO csrimp.map_qs_survey_response (old_survey_response_id, new_survey_response_id)
		SELECT survey_response_id, csr.survey_response_id_seq.nextval
		  FROM csrimp.quick_survey_response;

	INSERT INTO csrimp.map_qs_custom_question_type (old_custom_question_type_id, new_custom_question_type_id)
		SELECT custom_question_type_id, csr.custom_question_type_id_seq.nextval
		  FROM csrimp.qs_custom_question_type;

	INSERT INTO csrimp.map_qs_question (old_question_id, new_question_id)
		SELECT question_id, csr.question_id_seq.nextval
		  FROM (SELECT DISTINCT question_id
				  FROM csrimp.quick_survey_question);

	INSERT INTO csrimp.map_qs_question_option (old_question_option_id, new_question_option_id)
		SELECT question_option_id, csr.qs_question_option_id_seq.nextval
		  FROM (SELECT DISTINCT question_option_id
				  FROM csrimp.qs_question_option);

	INSERT INTO csrimp.map_score_threshold (old_score_threshold_id, new_score_threshold_id)
		SELECT score_threshold_id, csr.score_threshold_id_seq.nextval
		  FROM csrimp.score_threshold;

	-- this is a fake submission representing 'draft values'
	INSERT INTO csrimp.map_qs_submission (old_submission_id, new_submission_id)
	VALUES (0, 0);

	INSERT INTO csrimp.map_qs_submission (old_submission_id, new_submission_id)
		SELECT submission_id, csr.qs_submission_id_seq.nextval
		  FROM csrimp.quick_survey_submission
		 WHERE submission_id != 0;

	INSERT INTO csrimp.map_qs_answer_file (old_qs_answer_file_id, new_qs_answer_file_id)
		SELECT qs_answer_file_id, csr.qs_answer_file_id_seq.nextval
		  FROM csrimp.qs_answer_file;

	INSERT INTO csrimp.map_qs_expr (old_expr_id, new_expr_id)
		SELECT expr_id, csr.expr_id_seq.nextval
		  FROM (SELECT DISTINCT expr_id
				  FROM csrimp.quick_survey_expr);

	INSERT INTO csrimp.map_qs_expr_msg_action (old_qs_expr_msg_action_id, new_qs_expr_msg_action_id)
		SELECT qs_expr_msg_action_id, csr.qs_expr_msg_action_id_seq.nextval
		  FROM qs_expr_msg_action;

	INSERT INTO csrimp.map_qs_expr_nc_action (old_qs_expr_nc_action_id, new_qs_expr_nc_action_id)
		SELECT qs_expr_non_compl_action_id, csr.qs_expr_nc_action_id_seq.nextval
		  FROM csrimp.qs_expr_non_compl_action;

	INSERT INTO csrimp.map_qs_type (old_quick_survey_type_id, new_quick_survey_type_id)
		SELECT quick_survey_type_id, csr.quick_survey_type_id_seq.nextval
		  FROM csrimp.quick_survey_type;

	INSERT INTO csrimp.map_region_set (old_region_set_id, new_region_set_id)
		SELECT region_set_id, csr.region_set_id_seq.nextval
		  FROM csrimp.region_set;

	INSERT INTO csrimp.map_ind_set (old_ind_set_id, new_ind_set_id)
		 SELECT ind_set_id, csr.ind_set_id_seq.NEXTVAL
		   FROM csrimp.ind_set;

	INSERT INTO csrimp.map_alert (old_alert_id, new_alert_id)
		SELECT alert_id, REPLACE(security.user_pkg.GenerateACT,'-')
		  FROM csrimp.alert;

	INSERT INTO csrimp.map_region_metric_val (old_region_metric_val_id, new_region_metric_val_id)
		SELECT region_metric_val_id, csr.region_metric_val_id_seq.nextval
		  FROM csrimp.region_metric_val;

	INSERT INTO csrimp.map_mgmt_company (old_mgmt_company_id, new_mgmt_company_id)
		 SELECT mgmt_company_id, csr.mgmt_company_id_seq.nextval
		   FROM csrimp.mgmt_company;

	INSERT INTO csrimp.map_mgmt_company_contact (old_mgmt_company_contact_id, new_mgmt_company_contact_id)
		 SELECT mgmt_company_contact_id, csr.mgmt_company_contact_id_seq.nextval
		   FROM csrimp.mgmt_company_contact;

	INSERT INTO csrimp.map_fund_type (old_fund_type_id, new_fund_type_id)
		 SELECT fund_type_id, csr.fund_type_id_seq.nextval
		   FROM csrimp.fund_type;

	INSERT INTO csrimp.map_fund (old_fund_id, new_fund_id)
		 SELECT fund_id, csr.fund_id_seq.nextval
		   FROM csrimp.fund;

	INSERT INTO csrimp.map_tenant (old_tenant_id, new_tenant_id)
		 SELECT tenant_id, csr.tenant_id_seq.nextval
		   FROM csrimp.tenant;

	INSERT INTO csrimp.map_lease_type (old_lease_type_id, new_lease_type_id)
		 SELECT lease_type_id, csr.lease_type_id_seq.nextval
		   FROM csrimp.lease_type;

	INSERT INTO csrimp.map_lease (old_lease_id, new_lease_id)
		 SELECT lease_id, csr.lease_id_seq.nextval
		   FROM csrimp.lease;

	INSERT INTO csrimp.map_property_type (old_property_type_id, new_property_type_id)
		 SELECT property_type_id, csr.property_type_id_seq.nextval
		   FROM csrimp.property_type;

	INSERT INTO csrimp.map_sub_property_type (old_sub_property_type_id, new_sub_property_type_id)
		 SELECT property_sub_type_id, csr.property_sub_type_id_seq.nextval
		   FROM csrimp.property_sub_type;

	INSERT INTO csrimp.map_space_type (old_space_type_id, new_space_type_id)
		 SELECT space_type_id, csr.space_type_id_seq.nextval
		   FROM csrimp.space_type;

	INSERT INTO csrimp.map_property_photo (old_property_photo_id, new_property_photo_id)
		 SELECT property_photo_id, csr.property_photo_id_seq.nextval
		   FROM csrimp.property_photo;

	INSERT INTO csrimp.map_region_score_log (old_region_score_log_id, new_region_score_log_id)
		 SELECT region_score_log_id, csr.region_score_log_id_seq.NEXTVAL
		   FROM csrimp.region_score_log;

	INSERT INTO csrimp.map_supplier_score (old_supplier_score_id, new_supplier_score_id)
		 SELECT supplier_score_id, csr.supplier_score_id_seq.NEXTVAL
		   FROM csrimp.supplier_score_log;

	INSERT INTO csrimp.map_postit (old_postit_id, new_postit_id)
	     SELECT postit_id, csr.postit_id_seq.NEXTVAL
		   FROM csrimp.postit;

	INSERT INTO csrimp.map_non_compliance_file (old_non_compliance_file_id, new_non_compliance_file_id)
		 SELECT non_compliance_file_id, csr.non_compliance_file_id_seq.NEXTVAL
		   FROM csrimp.non_compliance_file;

	INSERT INTO csrimp.map_benchmark_dashboard_char (old_benchmark_das_char_id, new_benchmark_das_char_id)
		SELECT benchmark_dashboard_char_id, csr.benchmark_dashb_char_id_seq.NEXTVAL
		  FROM csrimp.benchmark_dashboard_char;
	
	INSERT INTO csrimp.map_cookie_policy_consen (old_cookie_policy_consent_id, new_cookie_policy_consent_id)
		 SELECT cookie_policy_consent_id, csr.cookie_policy_consent_id_seq.NEXTVAL
		   FROM csrimp.cookie_policy_consent;

	INSERT INTO csrimp.map_chain_company_type (old_company_type_id, new_company_type_id)
		 SELECT company_type_id, chain.company_type_id_seq.NEXTVAL
		   FROM csrimp.chain_company_type;

	INSERT INTO csrimp.map_chain_company_type_role (old_company_type_role_id, new_company_type_role_id)
		 SELECT company_type_role_id, chain.company_type_role_id_seq.NEXTVAL
		   FROM csrimp.chain_company_type_role;

	INSERT INTO csrimp.map_chain_project (old_project_id, new_project_id)
		 SELECT project_id, chain.project_id_seq.NEXTVAL
		   FROM csrimp.chain_project;

	INSERT INTO csrimp.map_chain_activity_type (old_activity_type_id, new_activity_type_id)
		 SELECT activity_type_id, chain.activity_type_id_seq.NEXTVAL
		   FROM csrimp.chain_activity_type;

	INSERT INTO csrimp.map_chain_outcome_type (old_outcome_type_id, new_outcome_type_id)
		 SELECT outcome_type_id, chain.outcome_type_id_seq.NEXTVAL
		   FROM csrimp.chain_outcome_type;

	INSERT INTO csrimp.map_chain_activity (old_activity_id, new_activity_id)
		 SELECT activity_id, chain.activity_id_seq.NEXTVAL
		   FROM csrimp.chain_activity;

	INSERT INTO csrimp.map_chain_activity_log (old_activity_log_id, new_activity_log_id)
		 SELECT activity_log_id, chain.activity_log_id_seq.NEXTVAL
		   FROM csrimp.chain_activity_log;

	INSERT INTO csrimp.map_chain_activ_log_file (old_activity_log_file_id, new_activity_log_file_id)
		 SELECT activity_log_file_id, chain.activity_log_file_id_seq.NEXTVAL
		   FROM csrimp.chain_activity_log_file;

	INSERT INTO csrimp.map_chain_acti_type_acti (old_activity_type_action_id, new_activity_type_action_id)
		 SELECT activity_type_action_id, chain.activity_type_action_id_seq.NEXTVAL
		   FROM csrimp.chain_activi_type_action;

	INSERT INTO csrimp.map_chain_ac_out_typ_ac (old_activity_outcm_typ_actn_id, new_activity_outcm_typ_actn_id)
		 SELECT activity_outcome_typ_action_id, chain.activity_outcm_typ_actn_id_seq.NEXTVAL
		   FROM csrimp.chain_act_outc_type_act;

	INSERT INTO csrimp.map_chain_product_type (old_product_type_id, new_product_type_id)
		 SELECT product_type_id, chain.product_type_id_seq.NEXTVAL
		   FROM csrimp.chain_product_type;

	INSERT INTO csrimp.map_chain_audit_request (old_audit_request_id, new_audit_request_id)
		 SELECT audit_request_id, chain.audit_request_id_seq.NEXTVAL
		   FROM csrimp.chain_audit_request;

	INSERT INTO csrimp.map_chain_company_header (old_company_header_id, new_company_header_id)
		 SELECT company_header_id, chain.company_header_id_seq.NEXTVAL
		   FROM csrimp.chain_company_header;

	INSERT INTO csrimp.map_chain_company_tab (old_company_tab_id, new_company_tab_id)
		 SELECT company_tab_id, chain.company_tab_id_seq.NEXTVAL
		   FROM csrimp.chain_company_tab;

	INSERT INTO csrimp.map_chain_cmp_tab_cmp_typ_role (old_comp_tab_comp_type_role_id, new_comp_tab_comp_type_role_id)
		 SELECT comp_tab_comp_type_role_id, chain.comp_tab_comp_type_role_id_seq.NEXTVAL
		   FROM csrimp.chain_comp_tab_comp_type_role;

	INSERT INTO csrimp.map_chain_product_header (old_product_header_id, new_product_header_id)
		 SELECT product_header_id, chain.product_header_id_seq.NEXTVAL
		   FROM csrimp.chain_product_header;

	INSERT INTO csrimp.map_chain_product_tab (old_product_tab_id, new_product_tab_id)
		 SELECT product_tab_id, chain.product_tab_id_seq.NEXTVAL
		   FROM csrimp.chain_product_tab;

	INSERT INTO csrimp.map_chain_product_supplier_tab (old_product_supplier_tab_id, new_product_supplier_tab_id)
		 SELECT product_supplier_tab_id, chain.product_supplier_tab_id_seq.NEXTVAL
		   FROM csrimp.chain_produc_supplie_tab;

	INSERT INTO csrimp.map_chain_component (old_component_id, new_component_id)
		 SELECT component_id, chain.component_id_seq.NEXTVAL
		   FROM csrimp.chain_component;

	INSERT INTO csrimp.map_chain_compoun_filter (old_compound_filter_id, new_compound_filter_id)
		 SELECT compound_filter_id, chain.compound_filter_id_seq.NEXTVAL
		   FROM csrimp.chain_compound_filter;

	INSERT INTO csrimp.map_chain_file_group (old_file_group_id, new_file_group_id)
		 SELECT file_group_id, chain.file_group_id_seq.NEXTVAL
		   FROM csrimp.chain_file_group;

	INSERT INTO csrimp.map_chain_file_grou_file (old_file_group_file_id, new_file_group_file_id)
		 SELECT file_group_file_id, chain.file_group_file_id_seq.NEXTVAL
		   FROM csrimp.chain_file_group_file;

	INSERT INTO csrimp.map_chain_filter (old_filter_id, new_filter_id)
		 SELECT filter_id, chain.filter_id_seq.NEXTVAL
		   FROM csrimp.chain_filter;

	INSERT INTO csrimp.map_chain_import_source (old_import_source_id, new_import_source_id)
		 SELECT import_source_id, chain.import_source_id_seq.NEXTVAL
		   FROM csrimp.chain_import_source;

	INSERT INTO csrimp.map_chain_dedupe_mapping (old_dedupe_mapping_id, new_dedupe_mapping_id)
		 SELECT dedupe_mapping_id, chain.dedupe_mapping_id_seq.NEXTVAL
		   FROM csrimp.chain_dedupe_mapping;

	INSERT INTO csrimp.map_chain_dedupe_rule_set (old_dedupe_rule_set_id, new_dedupe_rule_set_id)
		 SELECT dedupe_rule_set_id, chain.dedupe_rule_set_id_seq.NEXTVAL
		   FROM csrimp.chain_dedupe_rule_set;

	INSERT INTO csrimp.map_chain_dedupe_rule (old_dedupe_rule_id, new_dedupe_rule_id)
		 SELECT dedupe_rule_id, chain.dedupe_rule_id_seq.NEXTVAL
		   FROM csrimp.chain_dedupe_rule;

	INSERT INTO csrimp.map_chain_dedu_proc_reco (old_dedupe_processed_record_id, new_dedupe_processed_record_id)
		 SELECT dedupe_processed_record_id, chain.dedupe_processed_record_id_seq.NEXTVAL
		   FROM csrimp.chain_dedup_proce_record;

	INSERT INTO csrimp.map_chain_dedupe_match (old_dedupe_match_id, new_dedupe_match_id)
		 SELECT dedupe_match_id, chain.dedupe_match_id_seq.NEXTVAL
		   FROM csrimp.chain_dedupe_match;

	INSERT INTO csrimp.map_chain_dedu_merge_log (old_dedupe_merge_log_id, new_dedupe_merge_log_id)
		 SELECT dedupe_merge_log_id, chain.dedupe_merge_log_id_seq.NEXTVAL
		   FROM csrimp.chain_dedupe_merge_log;

	INSERT INTO csrimp.map_chain_dedu_stag_link (old_chain_dedup_stagin_link_id, new_chain_dedup_stagin_link_id)
		 SELECT dedupe_staging_link_id, chain.dedupe_staging_link_id_seq.NEXTVAL
		   FROM csrimp.chain_dedupe_stagin_link;

	INSERT INTO csrimp.map_chain_dedupe_sub (old_chain_dedupe_sub_id, new_chain_dedupe_sub_id)
		 SELECT dedupe_sub_id, cms.item_id_seq.nextval
		   FROM csrimp.chain_dedupe_sub;

	INSERT INTO csrimp.map_higg_config (old_higg_config_id, new_higg_config_id)
		 SELECT higg_config_id, chain.higg_config_id_seq.NEXTVAL
		   FROM csrimp.higg_config;

	INSERT INTO csrimp.map_chain_cert_type (old_cert_type_id, new_cert_type_id)
		SELECT certification_type_id, chain.certification_type_id_seq.nextval
		  FROM csrimp.chain_certification_type;

	INSERT INTO csrimp.map_chain_alt_company_name (old_alt_company_name_id, new_alt_company_name_id)
		 SELECT alt_company_name_id, chain.alt_company_name_id_seq.NEXTVAL
		   FROM csrimp.chain_alt_company_name;

	INSERT INTO csrimp.map_chain_cust_filt_col (old_chain_cust_filter_colum_id, new_chain_cust_filter_colum_id)
		 SELECT customer_filter_column_id, chain.customer_filter_column_id_seq.NEXTVAL
		   FROM csrimp.chain_cust_filter_column;

	INSERT INTO csrimp.map_chain_cust_filt_item (old_chain_cust_filter_item_id, new_chain_cust_filter_item_id)
		 SELECT customer_filter_item_id, chain.customer_filter_item_id_seq.NEXTVAL
		   FROM csrimp.chain_custom_filter_item;

	INSERT INTO csrimp.map_chain_cu_fi_it_ag_ty (old_chain_cu_fi_ite_agg_typ_id, new_chain_cu_fi_ite_agg_typ_id)
		 SELECT cust_filt_item_agg_type_id, chain.cust_filt_item_agg_type_id_seq.NEXTVAL
		   FROM csrimp.chain_cu_fil_ite_agg_typ;
		   
	INSERT INTO csrimp.map_sys_trans_audit_log (old_sys_trans_audit_log_id, new_sys_trans_audit_log_id)
		 SELECT sys_translations_audit_log_id, csr.sys_trans_audit_log_seq.NEXTVAL
		   FROM csrimp.sys_translations_audit_log;
		   

	INSERT INTO csrimp.map_secondary_region_tree_log (old_log_id, new_log_id)
		 SELECT log_id, csr.scndry_region_tree_log_id_seq.NEXTVAL
		   FROM csrimp.secondary_region_tree_log;

	-- There could be cards in one DB (for example: live) which does not exists in another DB (for example: your local)
	-- Therefore some cards might need to be copied.
	-- Note: this code must be here because of how csrimp.map_chain_filter_type will be filled afterwards.
	FOR c IN (
		SELECT card_id,
			   description,
			   class_type,
			   js_class_type,
			   js_include,
			   css_include
		  FROM csrimp.chain_card
	) LOOP
		BEGIN
			INSERT INTO chain.card (card_id, description, class_type,
										  js_class_type, js_include, css_include)
			VALUES (chain.card_id_seq.NEXTVAL, c.description, c.class_type,
										  c.js_class_type, c.js_include, c.css_include)
			RETURNING card_id INTO v_card_id;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN	-- card is already in target DB
				SELECT cc.card_id
				  INTO v_card_id
				  FROM chain.card cc
				 WHERE UPPER(c.js_class_type) = UPPER(cc.js_class_type);
		END;

		--	If the card was already in the target DB):
		--			old value: csrimp.chain_card.card_id  (id from origin DB)
		--			new value: 	chain.chain_card.card_id  (id from target DB)
		--	If the card was copied
		--			old value: csrimp.chain_card.card_id  (id from origin DB)
		--			new value: newly created ID
		BEGIN
			INSERT INTO csrimp.map_chain_card (old_card_id, new_card_id)
			VALUES (c.card_id, v_card_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	-- Similar stuff to the above to deal with chain_filter_type
	-- This clearly ought to have an app_sid, but for some reason it doesn't
	-- and it mixes up data from different customers.
	FOR r IN (
		SELECT ncft.filter_type_id old_filter_type_id, mcc.new_card_id card_id,
			   ncft.description, ncft.helper_pkg,
			   CASE WHEN ocft.card_id IS NULL THEN 0 ELSE 1 END card_exists,
			   ocft.filter_type_id new_filter_type_id
		  FROM csrimp.chain_filter_type ncft
		  JOIN csrimp.map_chain_card mcc ON mcc.old_card_id = ncft.card_id
		  LEFT JOIN chain.filter_type ocft ON mcc.new_card_id = ocft.card_id
	  )
	LOOP
		IF r.card_exists != 1 THEN
			INSERT INTO chain.filter_type
				(filter_type_id, description, helper_pkg, card_id)
			VALUES
				(chain.filter_type_id_seq.nextval, r.description, MapCustomerSchema(r.helper_pkg), r.card_id)
			RETURNING
				filter_type_id INTO v_filter_type_id;
		ELSE
			v_filter_type_id := r.new_filter_type_id;
		END IF;

		INSERT INTO csrimp.map_chain_filter_type (old_filter_type_id, new_filter_type_id)
		VALUES (r.old_filter_type_id, v_filter_type_id);
	END LOOP;

	INSERT INTO csrimp.map_chain_filter_field (old_filter_field_id, new_filter_field_id)
		 SELECT filter_field_id, chain.filter_field_id_seq.NEXTVAL
		   FROM csrimp.chain_filter_field;

	INSERT INTO csrimp.map_chain_filter_value (old_filter_value_id, new_filter_value_id)
		 SELECT filter_value_id, chain.filter_value_id_seq.NEXTVAL
		   FROM csrimp.chain_filter_value;

	INSERT INTO csrimp.map_chain_filter_page_ind (old_filter_page_ind_id, new_filter_page_ind_id)
		 SELECT filter_page_ind_id, chain.filter_page_ind_id_seq.NEXTVAL
		   FROM csrimp.chain_filter_page_ind;

	INSERT INTO csrimp.map_chain_fltr_page_ind_intrvl (old_filter_page_ind_intrvl_id, new_filter_page_ind_intrvl_id)
		 SELECT filter_page_ind_interval_id, chain.filter_page_ind_intrval_id_seq.NEXTVAL
		   FROM csrimp.chain_filter_page_ind_interval;

	INSERT INTO csrimp.map_chain_filter_page_cms_tab (old_filter_page_cms_table_id, new_filter_page_cms_table_id)
		 SELECT filter_page_cms_table_id, chain.filter_page_cms_table_id_seq.NEXTVAL
		   FROM csrimp.chain_filter_page_cms_table;

	INSERT INTO csrimp.map_chain_custom_agg_type (old_customer_aggregate_type_id, new_customer_aggregate_type_id)
		 SELECT customer_aggregate_type_id, chain.customer_aggregate_type_id_seq.NEXTVAL
		   FROM csrimp.chain_customer_aggregate_type;

	INSERT INTO csrimp.map_chain_invitation (old_invitation_id, new_invitation_id)
		 SELECT invitation_id, chain.invitation_id_seq.NEXTVAL
		   FROM csrimp.chain_invitation;

	INSERT INTO csrimp.map_chain_message (old_message_id, new_message_id)
		 SELECT message_id, chain.message_id_seq.NEXTVAL
		   FROM csrimp.chain_message;

	-- this is weird as CSR assumes that we're using SIDs sometimes (e.g. q'aire type == survey_sid)
	-- use the SID if it matches, else reuse the same ID as Kostas reckoons that some customer sites
	-- rely on static IDs (e.g. Maersk)
	INSERT INTO csrimp.map_chain_questionn_type (old_questionnaire_type_id, new_questionnaire_type_id)
		 SELECT questionnaire_type_id, NVL(ms.new_Sid, cqt.questionnaire_type_id)
		   FROM csrimp.chain_questionnaire_type cqt
		   LEFT JOIN csrimp.map_sid ms ON cqt.questionnaire_type_id = ms.old_sid;

	INSERT INTO csrimp.map_chain_questionnaire (old_questionnaire_id, new_questionnaire_id)
		 SELECT questionnaire_id, chain.questionnaire_id_seq.NEXTVAL
		   FROM csrimp.chain_questionnaire;

	INSERT INTO csrimp.map_chain_alert_entry (old_alert_entry_id, new_alert_entry_id)
		 SELECT alert_entry_id, chain.alert_entry_id_seq.NEXTVAL
		   FROM csrimp.chain_alert_entry;

	INSERT INTO csrimp.map_chain_schedule_alert (old_scheduled_alert_id, new_scheduled_alert_id)
		 SELECT scheduled_alert_id, chain.scheduled_alert_id_seq.NEXTVAL
		   FROM csrimp.chain_scheduled_alert;

	INSERT INTO csrimp.map_chain_recipient (old_recipient_id, new_recipient_id)
		 SELECT recipient_id, chain.recipient_id_seq.NEXTVAL
		   FROM csrimp.chain_recipient;

	INSERT INTO csrimp.map_chain_newsflash (old_newsflash_id, new_newsflash_id)
		 SELECT newsflash_id, chain.newsflash_id_seq.NEXTVAL
		   FROM csrimp.chain_newsflash;

	INSERT INTO csrimp.map_chain_product (old_product_id, new_product_id)
		 SELECT product_id, chain.product_id_seq.NEXTVAL
		   FROM csrimp.chain_product;

	INSERT INTO csrimp.map_chain_purchase (old_purchase_id, new_purchase_id)
		 SELECT purchase_id, chain.purchase_id_seq.NEXTVAL
		   FROM csrimp.chain_purchase;

	INSERT INTO csrimp.map_chain_question_share (old_questionnaire_share_id, new_questionnaire_share_id)
		 SELECT questionnaire_share_id, chain.questionnaire_share_id_seq.NEXTVAL
		   FROM csrimp.chain_questionnair_share;

	INSERT INTO csrimp.map_chain_task (old_task_id, new_task_id)
		 SELECT task_id, chain.task_id_seq.NEXTVAL
		   FROM csrimp.chain_task;

	INSERT INTO csrimp.map_chain_task_type (old_task_type_id, new_task_type_id)
		 SELECT task_type_id, chain.task_type_id_seq.NEXTVAL
		   FROM csrimp.chain_task_type;

	INSERT INTO csrimp.map_chain_task_entry (old_task_entry_id, new_task_entry_id)
		 SELECT task_entry_id, chain.task_entry_id_seq.NEXTVAL
		   FROM csrimp.chain_task_entry;

	INSERT INTO csrimp.map_chain_messag_definit(old_message_definition_id, new_message_definition_id)
		SELECT cdmd.message_definition_id, cmd.message_definition_id
		  FROM csrimp.chain_defau_messa_defini cdmd
		  JOIN chain.default_message_definition cmd ON UPPER(cmd.message_template) = UPPER(cdmd.message_template)
		  JOIN chain.MESSAGE_DEFINITION_LOOKUP chainLOOKUP  ON chainLOOKUP.message_definition_id = cmd.message_definition_id
 	      JOIN csrimp.CHAIN_MESSA_DEFIN_LOOKUP csrimpLOOKUP ON csrimpLOOKUP.message_definition_id = cdmd.message_definition_id
	     WHERE chainLOOKUP.primary_lookup_id = csrimpLOOKUP.primary_lookup_id AND chainLOOKUP.secondary_lookup_id = csrimpLOOKUP.secondary_lookup_id;

	INSERT INTO csrimp.map_chain_busin_rel_type (old_business_rel_type_id, new_business_rel_type_id)
		 SELECT business_relationship_type_id, chain.business_rel_type_id_seq.NEXTVAL
		   FROM csrimp.chain_busine_relati_type;

	INSERT INTO csrimp.map_chain_busin_rel_tier (old_business_rel_tier_id, new_business_rel_tier_id)
		 SELECT business_relationship_tier_id, chain.business_rel_tier_id_seq.NEXTVAL
		   FROM csrimp.chain_busine_relati_tier;

	INSERT INTO csrimp.map_chain_busine_relatio (old_business_relationship_id, new_business_relationship_id)
		 SELECT business_relationship_id, chain.business_relationship_id_seq.NEXTVAL
		   FROM csrimp.chain_business_relations;

	INSERT INTO csrimp.map_chain_bus_rel_period (old_business_rel_period_id, new_business_rel_period_id)
		 SELECT business_rel_period_id, chain.business_rel_period_id_seq.NEXTVAL
		   FROM csrimp.chain_busin_relat_period;

	INSERT INTO csrimp.map_chain_risk_level (old_risk_level_id, new_risk_level_id)
		 SELECT risk_level_id, chain.risk_level_id_seq.NEXTVAL
		   FROM csrimp.chain_risk_level;

	INSERT INTO csrimp.map_chain_reference (old_reference_id, new_reference_id)
		 SELECT reference_id, chain.reference_id_seq.NEXTVAL
		   FROM csrimp.chain_reference;

	INSERT INTO csrimp.map_chain_supp_rel_score (old_chain_supplie_rel_score_id, new_chain_supplie_rel_score_id)
		 SELECT supplier_relationship_score_id, chain.supplier_rel_score_id_seq.NEXTVAL
		   FROM csrimp.chain_suppl_relati_score;


	INSERT INTO csrimp.map_chem_cas_group (old_cas_group_id, new_cas_group_id)
		 SELECT cas_group_id, chem.cas_group_id_seq.NEXTVAL
		   FROM csrimp.chem_cas_group;

	INSERT INTO csrimp.map_chem_classification (old_classification_id, new_classification_id)
		 SELECT classification_id, chem.classification_id_seq.NEXTVAL
		   FROM csrimp.chem_classification;

	INSERT INTO csrimp.map_chem_manufacturer (old_manufacturer_id, new_manufacturer_id)
		 SELECT manufacturer_id, chem.manufacturer_id_seq.NEXTVAL
		   FROM csrimp.chem_manufacturer;

	INSERT INTO csrimp.map_chem_substance (old_substance_id, new_substance_id)
		 SELECT substance_id, chem.substance_id_seq.NEXTVAL
		   FROM csrimp.chem_substance;

	INSERT INTO csrimp.map_chem_usage (old_usage_id, new_usage_id)
		 SELECT usage_id, chem.usage_id_seq.NEXTVAL
		   FROM csrimp.chem_usage;

	INSERT INTO csrimp.map_chem_sub_rgn_pro_pro (old_subst_rgn_proc_process_id, new_subst_rgn_proc_process_id)
		 SELECT process_id, chem.subst_rgn_proc_process_id_seq.NEXTVAL
		   FROM csrimp.chem_subst_region_proces;

	INSERT INTO csrimp.map_chem_sub_pro_use_cha (old_subst_proc_use_change_id, new_subst_proc_use_change_id)
		 SELECT subst_proc_use_change_id, chem.subst_proc_use_change_id_seq.NEXTVAL
		   FROM csrimp.chem_subs_proc_use_chang;

	INSERT INTO csrimp.map_chem_su_pr_ca_de_chg (old_subst_proc_cas_dest_chg_id, new_subst_proc_cas_dest_chg_id)
		 SELECT subst_proc_cas_dest_change_id, chem.subst_proc_cas_dest_chg_id_seq.NEXTVAL
		   FROM csrimp.chem_sub_pro_cas_des_cha;

	INSERT INTO csrimp.map_chem_substance_file (old_substance_file_id, new_substance_file_id)
		 SELECT substance_file_id, chem.substance_file_id_seq.NEXTVAL
		   FROM csrimp.chem_substance_file;

	INSERT INTO csrimp.map_chem_subst_proce_use (old_substance_process_use_id, new_substance_process_use_id)
		 SELECT substance_process_use_id, chem.substance_process_use_id_seq.NEXTVAL
		   FROM csrimp.chem_substan_process_use;

	INSERT INTO csrimp.map_chem_sub_pro_use_fil (old_subst_proc_use_file_id, new_subst_proc_use_file_id)
		 SELECT substance_process_use_file_id, chem.subst_proc_use_file_id_seq.NEXTVAL
		   FROM csrimp.chem_subs_proce_use_file;

	INSERT INTO csrimp.map_chem_usage_audit_log (old_usage_audit_log_id, new_usage_audit_log_id)
		 SELECT usage_audit_log_id, chem.usage_audit_log_id_seq.NEXTVAL
		   FROM csrimp.chem_usage_audit_log;

	INSERT INTO csrimp.map_chem_sub_audit_log (old_sub_audit_log_id, new_sub_audit_log_id)
		 SELECT substance_audit_log_id, chem.sub_audit_log_id_seq.NEXTVAL
		   FROM csrimp.chem_substance_audit_log;

	INSERT INTO csrimp.map_aspen2_translated (old_translated_id, new_translated_id)
		SELECT translated_id, aspen2.translated_id_seq.NEXTVAL
		  FROM csrimp.aspen2_translated;

	INSERT INTO csrimp.map_flow_involvement_type (old_flow_involvement_type_id, new_flow_involvement_type_id)
		SELECT flow_involvement_type_id, CASE WHEN flow_involvement_type_id < 10000 THEN flow_involvement_type_id ELSE csr.flow_involvement_type_id_seq.NEXTVAL END
		  FROM csrimp.flow_involvement_type;

	INSERT INTO csrimp.map_flow_state_group (old_flow_state_group_id, new_flow_state_group_id)
		SELECT flow_state_group_id, csr.flow_state_group_id_seq.NEXTVAL
		  FROM csrimp.flow_state_group;

	INSERT INTO csrimp.map_aud_tp_flow_inv_tp (old_aud_tp_flow_inv_tp_id, new_aud_tp_flow_inv_tp_id)
		 SELECT audit_type_flow_inv_type_id, csr.audit_type_flw_inv_type_id_seq.NEXTVAL
		   FROM csrimp.audit_type_flow_inv_type;

	INSERT INTO csrimp.map_issue_supplier (old_issue_supplier_id, new_issue_supplier_id)
		 SELECT issue_supplier_id, csr.issue_supplier_id_seq.NEXTVAL
		   FROM csrimp.issue_supplier;

	INSERT INTO csrimp.map_issue_action (old_issue_action_id, new_issue_action_id)
		 SELECT issue_action_id, csr.issue_action_id_seq.NEXTVAL
		   FROM csrimp.issue_action;

	INSERT INTO csrimp.map_r_report_type (old_r_report_type_id, new_r_report_type_id)
		 SELECT r_report_type_id, csr.r_report_type_id_seq.NEXTVAL
		   FROM csrimp.r_report_type;

	INSERT INTO csrimp.map_r_report_file (old_r_report_file_id, new_r_report_file_id)
		 SELECT r_report_file_id, csr.r_report_file_id_seq.NEXTVAL
		   FROM csrimp.r_report_file;

	INSERT INTO csrimp.map_gresb_submission_log (old_gresb_submission_id, new_gresb_submission_id)
		 SELECT gsl.gresb_submission_id, csr.gresb_submission_seq.NEXTVAL
		   FROM csrimp.gresb_submission_log gsl;
	   --ORDER BY gsl.gresb_submission_id; -- preserve order

    -- Initiatives
	INSERT INTO csrimp.map_initiative_metric (old_initiative_metric_id, new_initiative_metric_id)
		 SELECT initiative_metric_id, csr.initiative_metric_id_seq.NEXTVAL
		   FROM csrimp.initiative_metric;

	INSERT INTO csrimp.map_user_msg (old_user_msg_id, new_user_msg_id)
		 SELECT user_msg_id, csr.user_msg_id_seq.NEXTVAL
		   FROM csrimp.user_msg;

	INSERT INTO csrimp.map_initia_period_status (old_initiativ_period_status_id, new_initiativ_period_status_id)
		 SELECT initiative_period_status_id, csr.initiativ_period_status_id_seq.NEXTVAL
		   FROM csrimp.initiative_period_status;

	INSERT INTO csrimp.map_initiative_comment (old_initiative_comment_id, new_initiative_comment_id)
		 SELECT initiative_comment_id, csr.initiative_comment_id_seq.NEXTVAL
		   FROM csrimp.initiative_comment;

	INSERT INTO csrimp.map_initiative_event (old_initiative_event_id, new_initiative_event_id)
		 SELECT initiative_event_id, csr.initiative_event_id_seq.NEXTVAL
		   FROM csrimp.initiative_event;

	INSERT INTO csrimp.map_initiative_group (old_initiative_group_id, new_initiative_group_id)
		 SELECT initiative_group_id, csr.initiative_group_id_seq.NEXTVAL
		   FROM csrimp.initiative_group;

	INSERT INTO csrimp.map_initiativ_user_group (old_initiative_user_group_id, new_initiative_user_group_id)
		 SELECT initiative_user_group_id, csr.initiative_user_group_id_seq.NEXTVAL
		   FROM csrimp.initiative_user_group;

	INSERT INTO csrimp.map_import_template (old_import_template_id, new_import_template_id)
		 SELECT import_template_id, csr.init_import_template_id_seq.NEXTVAL
		   FROM csrimp.initiati_import_template;

	INSERT INTO csrimp.map_issue_initiative (old_issue_initiative_id, new_issue_initiative_id)
		 SELECT issue_initiative_id, csr.issue_initiative_id_seq.NEXTVAL
		   FROM csrimp.issue_initiative;

	INSERT INTO csrimp.map_aggr_tag_group (old_aggr_tag_group_id, new_aggr_tag_group_id)
		 SELECT aggr_tag_group_id, csr.aggr_tag_group_id_seq.NEXTVAL
		   FROM csrimp.aggr_tag_group;

	INSERT INTO csrimp.map_initiative_header_element (old_init_header_element_id, new_init_header_element_id)
		 SELECT initiative_header_element_id, csr.init_header_element_id_seq.NEXTVAL
		   FROM csrimp.initiative_header_element;

	INSERT INTO csrimp.map_init_tab_element_layout (old_element_id, new_element_id)
		 SELECT element_id, csr.initiative_tab_element_id_seq.NEXTVAL
		   FROM csrimp.init_tab_element_layout;

	INSERT INTO csrimp.map_init_create_page_el_layout (old_element_id, new_element_id)
		 SELECT element_id, csr.init_create_page_el_id_seq.NEXTVAL
		   FROM csrimp.init_create_page_el_layout;

	INSERT INTO csrimp.map_issu_mete_missi_data (old_issue_meter_missin_data_id, new_issue_meter_missin_data_id)
		 SELECT issue_meter_missing_data_id, csr.issue_meter_missing_data_seq.NEXTVAL
		   FROM csrimp.issue_meter_missing_data;

	INSERT INTO csrimp.map_route_log (old_route_log_id, new_route_log_id)
		 SELECT route_log_id, csr.route_log_id_seq.NEXTVAL
		   FROM csrimp.route_log;

	INSERT INTO csrimp.map_sheet_change_req (old_sheet_change_req_id, new_sheet_change_req_id)
		 SELECT sheet_change_req_id, csr.sheet_change_req_id_seq.NEXTVAL
		   FROM csrimp.sheet_change_req;

	INSERT INTO csrimp.map_shee_chang_req_alert (old_sheet_change_req_alert_id, new_sheet_change_req_alert_id)
		 SELECT sheet_change_req_alert_id, csr.sheet_change_req_alert_id_seq.NEXTVAL
		   FROM csrimp.sheet_change_req_alert;

	INSERT INTO csrimp.map_user_msg_file (old_user_msg_file_id, new_user_msg_file_id)
		 SELECT user_msg_file_id, csr.user_msg_file_id_seq.NEXTVAL
		   FROM csrimp.user_msg_file;

	INSERT INTO csrimp.map_val_note (old_val_note_id, new_val_note_id)
		 SELECT val_note_id, csr.val_note_id_seq.NEXTVAL
		   FROM csrimp.val_note;

	FOR r IN (SELECT sc.table_name,
					 sc.column_name,
					 NVL(sc.sequence_owner, sc.owner) sequence_owner,
					 sc.sequence_name,
					 st.csrimp_table_name
				FROM csr.schema_column sc
				JOIN csr.schema_table st
				  ON st.owner = sc.owner
				 AND st.table_name = sc.table_name
			   WHERE sc.sequence_name IS NOT NULL
				 AND sc.enable_import != 0
				 AND sc.is_map_source != 0)
	LOOP
		EXECUTE IMMEDIATE
			'INSERT INTO csrimp.map_id (sequence_owner, sequence_name, old_id, new_id) '||
				'SELECT :sequence_owner,' ||
					   ':sequence_name,' ||
					   'old_id,' ||
					   '"' || r.sequence_owner || '"."' || r.sequence_name || '".NEXTVAL ' ||
				  'FROM (' ||
					  'SELECT DISTINCT "' || r.column_name || '" old_id ' ||
						'FROM csrimp."' || r.csrimp_table_name || '"' ||
					')' ||
				 'WHERE old_id NOT IN (' ||
						'SELECT old_id ' ||
						  'FROM csrimp.map_id ' ||
						 'WHERE sequence_owner = :sequence_owner ' ||
						   'AND sequence_name = :sequence_name' ||
					')' ||
				   'AND old_id IS NOT NULL'
				USING r.sequence_owner, r.sequence_name, r.sequence_owner, r.sequence_name;
	END LOOP;
END;

PROCEDURE GatherStats
AS
BEGIN
	dbms_stats.gather_schema_stats(
		ownname => NULL,
		granularity => 'AUTO',
		block_sample => FALSE,
		cascade => TRUE,
		degree => DBMS_STATS.DEFAULT_DEGREE,
		method_opt => 'FOR ALL COLUMNS SIZE 1',
		options => 'GATHER');

	cms.tab_pkg.gatherStats;

	FOR r IN (SELECT new_oracle_schema
				FROM csrimp.map_cms_schema
			   WHERE old_oracle_schema
			     NOT IN (SELECT oracle_schema
			     		   FROM cms.sys_schema)) LOOP
		EXECUTE IMMEDIATE 'begin '||cms.tab_pkg.q(r.new_oracle_schema)||'.'||'m$imp_pkg.gatherStats; end;';
	END LOOP;
END;

PROCEDURE CreateSecurableObjects
AS
	v_applications_sid				security_pkg.T_SID_ID;
	v_app_sid						security_pkg.T_SID_ID;
BEGIN
	v_applications_sid := securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), security_pkg.SID_ROOT, '//aspen/applications');

	-- insert SO classes that don't exist
	INSERT INTO security.securable_object_class (class_id, class_name, helper_pkg, helper_prog_id, parent_class_id)
		SELECT security.sid_id_seq.nextval, soc.class_name, soc.helper_pkg, soc.helper_prog_id, null
		  FROM csrimp.securable_object_class soc
		 WHERE soc.class_name NOT IN (SELECT class_name
		 								FROM security.securable_object_class);

	-- fix up parent class ids
	FOR r in (SELECT soc.class_id, oc.class_name
				FROM csrimp.securable_object_class oc, csrimp.securable_object_class ocp, security.securable_object_class soc
			   WHERE oc.class_name NOT IN (SELECT class_name
		 									 FROM security.securable_object_class)
				 AND oc.class_id = ocp.parent_class_id
				 AND ocp.class_name = soc.class_name) LOOP
		UPDATE security.securable_object_class
		   SET parent_class_id = r.class_id
		 WHERE class_name = r.class_name;
	END LOOP;

	-- permissions / permission mapping for classes we just added
	INSERT INTO security.permission_name (class_id, permission, permission_name)
		SELECT soc.class_id, pn.permission, pn.permission_name
		  FROM security.securable_object_class soc, csrimp.permission_name pn, csrimp.securable_object_class oc
		 WHERE pn.class_id = oc.class_id
		   AND oc.class_name = soc.class_name
		 MINUS
		SELECT class_id, permission, permission_name
		  FROM security.permission_name;

	INSERT INTO security.permission_mapping (parent_class_id, parent_permission, child_class_id, child_permission)
		SELECT socp.class_id, pm.parent_permission, socc.class_id, pm.child_permission
		  FROM security.securable_object_class socp, security.securable_object_class socc,
		  	   csrimp.permission_mapping pm, csrimp.securable_object_class occ,
		  	   csrimp.securable_object_class ocp
		 WHERE occ.class_name = socc.class_name
		   AND ocp.class_name = socp.class_name
		   AND pm.child_class_id = occ.class_id
		   AND pm.parent_class_id = ocp.class_id
		 MINUS
		SELECT parent_class_id, parent_permission, child_class_id, child_permission
		  FROM security.permission_mapping;

	-- attributes for new classes
	INSERT INTO security.attributes (attribute_id, class_id, name, flags, external_pkg)
		SELECT security.attribute_id_seq.nextval, soc.class_id, a.name, a.flags, a.external_pkg
		  FROM security.securable_object_class soc, csrimp.securable_object_class oc,
		  	   csrimp.attributes a
		 WHERE soc.class_name = oc.class_name
		   AND oc.class_id = a.class_id
		   AND (soc.class_id, a.name) NOT IN (
				SELECT class_id, name
				  FROM security.attributes);

	-- Create the application with a new name
	INSERT INTO security.securable_object (sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, link_sid_id, application_sid_id)
		SELECT /*+CARDINALITY(mso, 50000) CARDINALITY(ma, 200000) CARDINALITY(soc, 100)
				  CARDINALITY(oc, 100) CARDINALITY(ml, 50000) CARDINALITY(mo, 50000)
				  CARDINALITY(so, 50000)*/
			   mso.new_sid, v_applications_sid, ma.new_acl_id, soc.class_id, m_new_host,
			   so.flags, mo.new_sid, ml.new_sid, NULL
		  FROM csrimp.map_sid mso, csrimp.map_acl ma, security.securable_object_class soc,
		  	   csrimp.securable_object_class oc, csrimp.map_sid ml, csrimp.map_sid mo,
		  	   csrimp.securable_object so
		 WHERE so.sid_id = mso.old_sid
		   AND so.parent_sid_id IS NULL
		   AND so.dacl_id = ma.old_acl_id(+)
		   AND so.class_id = oc.class_id
		   AND oc.class_name = soc.class_name
		   AND so.owner = mo.old_sid(+)
		   AND so.link_sid_id = ml.old_sid(+);

	-- fetch the new app sid
	SELECT ms.new_sid
	  INTO v_app_sid
	  FROM csrimp.securable_object so, csrimp.map_sid ms
	 WHERE ms.old_sid = so.sid_id
	   AND so.parent_sid_id IS NULL;

	INSERT INTO security.application (application_sid_id, everyone_sid_id, language, culture, timezone)
		SELECT /*+CARDINALITY(msa, 50000) CARDINALITY(mse, 50000) CARDINALITY(a, 1)*/
			   msa.new_sid, mse.new_sid, language, culture, timezone
		  FROM csrimp.application a, csrimp.map_sid msa, csrimp.map_sid mse
		 WHERE a.application_sid_id = msa.old_sid
		   AND a.everyone_sid_id = mse.old_sid;

	-- now we have a row in application, set the application sid of the application object
	UPDATE security.securable_object
	   SET application_sid_id = v_app_sid
	 WHERE sid_id = v_app_sid;

	-- Rename any objects we are trying to import that have name clashes
	-- This is guaranteed to happen if you export/import from the same
	-- database where a superadmin user has saved a chart under their
	-- personal folders, for example.  The SO name doesn't really matter
	-- (it appears in the chart folder structure for example) so
	-- renaming it should work around this until a better solution for
	-- the fundamental issue (cross-site sharing of securable objects) is
	-- applied
	UPDATE csrimp.securable_object
	   SET name = SUBSTR(name, 1, 239) || ' (2)' -- utf8 uses up to 4 bytes per codepoint
	 WHERE sid_id IN (
			SELECT iso.sid_id
			  FROM (SELECT ms.old_sid root_sid, name, lvl
			  		  FROM (SELECT connect_by_root parent_sid_id root_sid, name, level lvl
			  		  		  FROM security.securable_object
			  		  		  	   START WITH parent_sid_id IN (
			  		  		  	   		SELECT new_sid
			  		  		  	   	 	  FROM csrimp.map_sid ms, csrimp.superadmin_folder sf
			  		  		  	   	 	 WHERE sf.sid_id = ms.old_sid)
			  		  		  	   CONNECT BY PRIOR sid_id = parent_sid_id) so,
						   csrimp.map_sid ms
					 WHERE so.root_sid = ms.new_sid) eso
			  JOIN (SELECT connect_by_root parent_sid_id root_sid, sid_id, name, level lvl
			  		  FROM csrimp.securable_object
			  		  	   START WITH parent_sid_id IN (
			  		  	   		SELECT sid_id
			  		  	   		  FROM csrimp.superadmin_folder)
						   CONNECT BY PRIOR sid_id = parent_sid_id) iso
				ON iso.root_sid = eso.root_sid
			   AND iso.lvl = eso.lvl
			   AND LOWER(iso.name) = LOWER(eso.name)
	);

	-- This is exactly the same as the above statement, but uses a GUID in case "2" fails
	-- We could just use this statement but "2" is nicer to look at
	UPDATE csrimp.securable_object
	   SET name = SUBSTR(name, 1, 123) || ' ' || SYS_GUID()  -- utf8 uses up to 4 bytes per codepoint
	 WHERE sid_id IN (
			SELECT iso.sid_id
			  FROM (SELECT ms.old_sid root_sid, name, lvl
			  		  FROM (SELECT connect_by_root parent_sid_id root_sid, name, level lvl
			  		  		  FROM security.securable_object
			  		  		  	   START WITH parent_sid_id IN (
			  		  		  	   		SELECT new_sid
			  		  		  	   	 	  FROM csrimp.map_sid ms, csrimp.superadmin_folder sf
			  		  		  	   	 	 WHERE sf.sid_id = ms.old_sid)
			  		  		  	   CONNECT BY PRIOR sid_id = parent_sid_id) so,
						   csrimp.map_sid ms
					 WHERE so.root_sid = ms.new_sid) eso
			  JOIN (SELECT connect_by_root parent_sid_id root_sid, sid_id, name, level lvl
			  		  FROM csrimp.securable_object
			  		  	   START WITH parent_sid_id IN (
			  		  	   		SELECT sid_id
			  		  	   		  FROM csrimp.superadmin_folder)
						   CONNECT BY PRIOR sid_id = parent_sid_id) iso
				ON iso.root_sid = eso.root_sid
			   AND iso.lvl = eso.lvl
			   AND LOWER(iso.name) = LOWER(eso.name)
	);

	-- Now we've got the application created, set the app sid
	security_pkg.SetApp(v_app_sid);

	INSERT INTO security.securable_object (sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, link_sid_id, application_sid_id)
		SELECT /*+CARDINALITY(mso, 150000) CARDINALITY(msp, 150000) CARDINALITY(ma, 2000000)
				  CARDINALITY(soc, 100) CARDINALITY(oc, 100) CARDINALITY(ml, 150000)
				  CARDINALITY(mo, 150000) CARDINALITY(mapp, 150000) CARDINALITY(so, 150000)
				  CARDINALITY(sor, 10) USE_HASH(msp) USE_HASH(ml) USE_HASH(mo) USE_HASH(mapp)
				  USE_HASH(ma) USE_HASH(soc) USE_HASH(oc) USE_HASH(sor)
				*/
			   mso.new_sid, msp.new_sid, ma.new_acl_id, soc.class_id, NVL(sor.name, so.name),
			   so.flags, mo.new_sid, ml.new_sid, mapp.new_sid
		  FROM csrimp.map_sid mso, csrimp.map_sid msp, csrimp.map_acl ma, security.securable_object_class soc,
		  	   csrimp.securable_object_class oc, csrimp.map_sid ml, csrimp.map_sid mo, csrimp.map_sid mapp,
		  	   csrimp.securable_object so, csrimp.so_rename sor
		 WHERE so.sid_id = mso.old_sid
		   AND so.parent_sid_id = msp.old_sid
		   AND so.dacl_id = ma.old_acl_id(+)
		   AND so.class_id = oc.class_id
		   AND oc.class_name = soc.class_name
		   AND so.owner = mo.old_sid(+)
		   AND so.link_sid_id = ml.old_sid(+)
		   AND so.application_sid_id = mapp.old_sid(+)
		   AND so.sid_id = sor.sid_id(+);

	INSERT INTO security.acl (acl_id, acl_index, ace_type, ace_flags, sid_id, permission_set)
		SELECT /*+CARDINALITY(ms, 50000) CARDINALITY(ma, 50000) CARDINALITY(a, 200000)
				  USE_HASH(ms) USE_HASH(ma)*/
			   ma.new_acl_id, a.acl_index, a.ace_type, a.ace_flags, ms.new_sid, a.permission_set
		  FROM csrimp.map_sid ms, csrimp.map_acl ma, csrimp.acl a
		 WHERE ma.old_acl_id = a.acl_id
		   AND a.sid_id = ms.old_sid;

	INSERT INTO security.securable_object_keyed_acl (sid_id, key_id, acl_id)
		SELECT /*+CARDINALITY(ms, 50000) CARDINALITY(ma, 50000)*/ ms.new_sid, soka.key_id, ma.new_acl_id
		  FROM csrimp.map_sid ms, csrimp.securable_object_keyed_acl soka, csrimp.map_acl ma
		 WHERE soka.sid_id = ms.old_sid
		   AND soka.acl_id = ma.old_acl_id;

	INSERT INTO security.account_policy (sid_id, max_logon_failures, expire_inactive, max_password_age, remember_previous_passwords,
		remember_previous_days, single_session)
		SELECT /*+CARDINALITY(ms, 50000)*/ms.new_sid, ap.max_logon_failures, ap.expire_inactive, ap.max_password_age, ap.remember_previous_passwords,
			   ap.remember_previous_days, ap.single_session
		  FROM csrimp.account_policy ap, csrimp.map_sid ms
		 WHERE ap.sid_id = ms.old_sid;

	INSERT INTO security.acc_policy_pwd_regexp (account_policy_sid, password_regexp_id)
		SELECT ms.new_sid, pr.password_regexp_id
		  FROM csrimp.acc_policy_pwd_regexp appr, security.password_regexp pr, csrimp.map_sid ms
		 WHERE appr.password_regexp_id = pr.password_regexp_id
		   AND appr.account_policy_sid = ms.old_sid;

	INSERT INTO security.home_page (app_sid, sid_id, url, created_by_host, priority)
		SELECT DISTINCT SYS_CONTEXT('SECURITY', 'APP'), msh.new_sid, hp.url, so.name, hp.priority
		  FROM csrimp.map_sid msh, csrimp.home_page hp, security.securable_object so
		 WHERE hp.sid_id = msh.old_sid
		   AND so.sid_id = SYS_CONTEXT('SECURITY','APP');

	INSERT INTO security.securable_object_attributes (sid_id, attribute_id, string_value, number_value,
		date_value, blob_value, isobject, clob_value)
		SELECT /*+CARDINALITY(ms, 50000)*/ms.new_sid, na.attribute_id, soa.string_value, soa.number_value,
			   soa.date_value, soa.blob_value, soa.isobject, soa.clob_value
		  FROM csrimp.securable_object_attributes soa, csrimp.map_sid ms,
		  	   csrimp.attributes oa, security.attributes na, csrimp.securable_object_class oc,
		  	   security.securable_object_class nc
		 WHERE soa.sid_id = ms.old_sid
		   AND soa.attribute_id = oa.attribute_id
		   AND oa.class_id = oc.class_id
		   AND oc.class_name = nc.class_name
		   AND nc.class_id = na.class_id
		   AND na.name = oa.name;

	INSERT INTO security.group_table (sid_id, group_type)
		SELECT /*+CARDINALITY(mg, 50000)*/mg.new_sid, gt.group_type
		  FROM csrimp.map_sid mg, csrimp.group_table gt
		 WHERE gt.sid_id = mg.old_sid;

	INSERT INTO security.group_members (group_sid_id, member_sid_id)
		SELECT /*+CARDINALITY(mg, 50000) CARDINALITY(mm, 50000)*/mg.new_sid, mm.new_sid
		  FROM csrimp.map_sid mg, csrimp.map_sid mm, csrimp.group_members gm
		 WHERE gm.group_sid_id = mg.old_sid
		   AND gm.member_sid_id = mm.old_sid;

	INSERT INTO security.menu (sid_id, description, action, pos, context)
		SELECT /*+CARDINALITY(mm, 50000)*/ mm.new_sid, m.description, m.action, m.pos, m.context
		  FROM csrimp.menu m, csrimp.map_sid mm
		 WHERE m.sid_id = mm.old_sid;


	INSERT INTO security.user_table (sid_id, login_password, login_password_salt, account_enabled,
		last_password_change, last_logon, last_but_one_logon, failed_logon_attempts, expiration_dtm,
		language, culture, timezone, java_login_password, java_auth_enabled, account_expiry_enabled, account_disabled_dtm)
		SELECT /*+CARDINALITY(ms, 50000)*/ ms.new_sid, ut.login_password, ut.login_password_salt, ut.account_enabled,
			   ut.last_password_change, ut.last_logon, ut.last_but_one_logon, ut.failed_logon_attempts,
			   ut.expiration_dtm, ut.language, ut.culture, ut.timezone, ut.java_login_password, ut.java_auth_enabled,
			   ut.account_expiry_enabled, ut.account_disabled_dtm
		  FROM csrimp.map_sid ms, csrimp.user_table ut
		 WHERE ms.old_sid = ut.sid_id;

	INSERT INTO security.user_certificates (sid_id, cert_hash, cert, website_name)
		SELECT /*+CARDINALITY(ms, 50000)*/ ms.new_sid, uc.cert_hash, uc.cert, uc.website_name
		  FROM csrimp.user_certificates uc, csrimp.map_sid ms
		 WHERE uc.sid_id = ms.old_sid;

	INSERT INTO security.user_password_history (sid_id, serial, login_password,
		login_password_salt, retired_dtm)
		SELECT /*+CARDINALITY(ms, 50000)*/ms.new_sid, uph.serial, uph.login_password, uph.login_password_salt,
			   uph.retired_dtm
		  FROM csrimp.user_password_history uph, csrimp.map_sid ms
		 WHERE ms.old_sid = uph.sid_id;

	INSERT INTO security.ip_rule (ip_rule_id)
		SELECT mir.new_ip_rule_id
		  FROM csrimp.map_ip_rule mir;

	INSERT INTO security.ip_rule_entry (ip_rule_id, ip_rule_index, ipv4_address, ipv4_bitmask, require_ssl, allow)
		SELECT mir.new_ip_rule_id, ire.ip_rule_index, ire.ipv4_address, ire.ipv4_bitmask, ire.require_ssl, ire.allow
		  FROM csrimp.map_ip_rule mir, csrimp.ip_rule_entry ire
		 WHERE mir.old_ip_rule_id = ire.ip_rule_id;

	INSERT INTO security.web_resource (web_root_sid_id, path, sid_id, ip_rule_id, rewrite_path)
		SELECT /*+CARDINALITY(mwr, 50000) CARDINALITY(ms, 50000)*/mwr.new_sid, wr.path, ms.new_sid, mi.new_ip_rule_id,
			   CASE WHEN wr.rewrite_path='/csr/site/quicksurvey/public/view.acds?sid='||ms.old_sid THEN '/csr/site/quicksurvey/public/view.acds?sid='||ms.new_sid
			   ELSE wr.rewrite_path END -- change re-write path for surveys
		  FROM csrimp.map_sid mwr, csrimp.web_resource wr, csrimp.map_sid ms, csrimp.map_ip_rule mi
		 WHERE wr.web_root_sid_id = mwr.old_sid
		   AND wr.sid_id = ms.old_sid
		   AND wr.ip_rule_id = mi.old_ip_rule_id(+);

	INSERT INTO security.website (website_name, server_group, web_root_sid_id, denied_page,
		act_timeout, cert_act_timeout, secure_only, http_only_cookies, xsrf_check_enabled,
		application_sid_id, proxy_secure, ip_rule_id)
		SELECT /*+CARDINALITY(mwr, 50000) CARDINALITY(ma, 50000)*/ m_new_host, ws.server_group, mwr.new_sid, ws.denied_page, ws.act_timeout,
			   ws.cert_act_timeout, ws.secure_only, ws.http_only_cookies, ws.xsrf_check_enabled,
			   ma.new_sid, ws.proxy_secure, mir.new_ip_rule_id
		  FROM csrimp.website ws, csrimp.map_sid mwr, csrimp.map_sid ma, csrimp.map_ip_rule mir
		 WHERE ws.web_root_sid_id = mwr.old_sid
		   AND ws.application_sid_id = ma.old_sid
		   AND ws.ip_rule_id = mir.old_ip_rule_id(+);

	-- slightly horrid code to fix up attributes that contain the host name
	UPDATE security.securable_object_attributes
	   SET string_value = REPLACE(string_value, m_old_host, m_new_host)
	 WHERE sid_id = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SetAppSid
AS
	v_app_sid						csr.customer.app_sid%TYPE;
BEGIN
	-- fetch the new app sid
	SELECT ms.new_sid
	  INTO v_app_sid
	  FROM csrimp.securable_object so, csrimp.map_sid ms
	 WHERE ms.old_sid = so.sid_id
	   AND so.parent_sid_id IS NULL;

	-- Now we've got the application created, set the app sid
	security_pkg.SetApp(v_app_sid);
END;

PROCEDURE CreateDynamicTableObjects
AS
	v_insert_list					VARCHAR2(32767);
	v_select_list					VARCHAR2(32767);
	v_join_list						VARCHAR2(32767);
	v_map_alias						VARCHAR2(32767);
	v_join_index					PLS_INTEGER := 0;

	v_map_table						VARCHAR2(30);
	v_old_id_col					VARCHAR2(30);
	v_new_id_col					VARCHAR2(30);

	v_table_cur						SYS_REFCURSOR;
	v_table							csr.schema_table%ROWTYPE;
BEGIN
	csr.schema_pkg.GetDynamicTablesForImport(v_table_cur);

	LOOP
		FETCH v_table_cur INTO v_table;
		EXIT WHEN v_table_cur%NOTFOUND;

		security.security_pkg.DebugMsg('Processing table: ' || v_table.owner || '.' || v_table.table_name);

		v_insert_list := '';
		v_select_list := '';
		v_join_list	:= '';
		v_join_index := 0;

		FOR col IN (SELECT atc.owner,
						   atc.column_name,
						   CASE WHEN sc.is_sid = 1 OR (sc.is_sid IS NULL AND
													   atc.column_name LIKE '%\_SID' ESCAPE '\') --'
								THEN 1 ELSE 0
						   END is_sid,
						   NVL(sc.sequence_owner, sc.owner) sequence_owner,
						   sc.sequence_name,
						   sc.map_table,
						   sc.map_old_id_col,
						   sc.map_new_id_col
					  FROM all_tab_columns atc
					  LEFT JOIN csr.schema_column sc
						ON atc.column_name = sc.column_name
					   AND atc.table_name = sc.table_name
					   AND atc.owner = sc.owner
					 WHERE atc.table_name = v_table.table_name
					   AND atc.owner = v_table.owner
					   AND NVL(sc.enable_import, 1) = 1
					   AND atc.column_name != 'APP_SID'
					 ORDER BY atc.column_id)
		LOOP
			v_select_list := v_select_list || CASE WHEN v_select_list IS NOT NULL THEN ',' END;
			v_insert_list :=
				v_insert_list || CASE WHEN v_insert_list IS NOT NULL THEN ',' END ||
				'"' || col.column_name || '"';

			IF col.sequence_name IS NOT NULL OR col.map_table IS NOT NULL OR col.is_sid = 1
			THEN
				v_map_alias := 'm' || v_join_index;
				v_join_index := v_join_index + 1;

				IF col.map_table IS NOT NULL THEN
					v_map_table := '"' || col.map_table || '"';
					v_old_id_col := '"' || col.map_old_id_col || '"';
					v_new_id_col := '"' || col.map_new_id_col || '"';
				ELSIF col.sequence_name IS NOT NULL THEN
					v_map_table := 'map_id';
					v_old_id_col := 'old_id';
					v_new_id_col := 'new_id';
				ELSE
					v_map_table := 'map_sid';
					v_old_id_col := 'old_sid';
					v_new_id_col := 'new_sid';
				END IF;

				v_select_list := v_select_list || v_map_alias || '.' || v_new_id_col;
				v_join_list := v_join_list ||
					' LEFT JOIN csrimp.' || v_map_table || ' ' || v_map_alias ||
					' ON t."' || col.column_name || '" = ' || v_map_alias || '.' || v_old_id_col;

				IF col.map_table IS NULL AND col.sequence_name IS NOT NULL THEN
					v_join_list := v_join_list ||
						' AND ' || v_map_alias || '.sequence_owner = ''' || col.sequence_owner || '''' ||
						' AND ' || v_map_alias || '.sequence_name = ''' || col.sequence_name || '''';
				END IF;
			ELSE
				v_select_list := v_select_list || 't."' || col.column_name || '"';
			END IF;
		END LOOP;

		EXECUTE IMMEDIATE
			'INSERT INTO "' || v_table.owner || '"."' || v_table.table_name || '" (' || v_insert_list || ') ' ||
			'SELECT ' || v_select_list || ' ' ||
			'FROM csrimp."' || v_table.csrimp_table_name || '" t' ||
			v_join_list;
	END LOOP;
END;

PROCEDURE CreateMail
AS
	v_system_mail_address			csrimp.customer.system_mail_address%TYPE;
	v_tracker_mail_address 			csrimp.customer.tracker_mail_address%TYPE;
	v_users_sid						security_pkg.T_SID_ID;
	v_registered_users_sid			security_pkg.T_SID_ID;
    v_user_mailbox_sid				security_pkg.T_SID_ID;
    v_dacl_id						security_pkg.T_ACL_ID;
BEGIN
	GetMailAccounts(m_new_host, v_system_mail_address, v_tracker_mail_address);

	INSERT INTO mail.mailbox (mailbox_sid, parent_sid, link_to_mailbox_sid, mailbox_name,
		last_message_uid, filter_duplicate_message_id)
		SELECT /*+CARDINALITY(ms, 50000) CARDINALITY(ml, 50000) CARDINALITY(mp, 50000)*/ ms.new_sid, mp.new_sid, ml.new_sid, NVL(sor.name, m.mailbox_name),
			   m.last_message_uid, m.filter_duplicate_message_id
		  FROM csrimp.mail_mailbox m, csrimp.map_sid ms, csrimp.map_sid mp,
		  	   csrimp.map_sid ml, csrimp.so_rename sor
		 WHERE m.mailbox_sid = ms.old_sid
		   AND m.parent_sid = mp.old_sid(+)
		   AND m.link_to_mailbox_sid = ml.old_sid(+)
		   AND m.mailbox_sid = sor.sid_id(+);

	INSERT INTO mail.account_alias (account_sid, email_address)
		SELECT /*+CARDINALITY(ms, 50000)*/ ms.new_sid, sor.name
		  FROM csrimp.mail_account ma, csrimp.map_sid ms, csrimp.so_rename sor
		 WHERE ma.account_sid = ms.old_sid
		   AND ma.account_sid = sor.sid_id;

	INSERT INTO mail.account (account_sid, email_address, root_mailbox_sid, inbox_sid, password,
		password_salt, apop_secret, description)
		SELECT /*+CARDINALITY(ms, 50000) CARDINALITY(mr, 50000) CARDINALITY(mi, 50000)*/ms.new_sid, sor.name, mr.new_sid, mi.new_sid, null password,
			   null password_salt, null apop_secret, replace(ma.description, m_old_host, m_new_host)
		  FROM csrimp.mail_account ma, csrimp.map_sid ms, csrimp.map_sid mr, csrimp.map_sid mi,
		  	   csrimp.so_rename sor
		 WHERE ma.account_sid = ms.old_sid
		   AND ma.account_sid = sor.sid_id
		   AND ma.root_mailbox_sid = mr.old_sid
		   AND ma.inbox_sid = mi.old_sid;

	INSERT INTO mail.message (message_id, subject, message_dtm, message_id_hdr,
		in_reply_to, priority, has_attachments)
		SELECT mm.new_message_id, m.subject, m.message_dtm, m.message_id_hdr,
			   m.in_reply_to, m.priority, m.has_attachments
		  FROM csrimp.mail_message m, csrimp.map_mail_message mm
		 WHERE m.message_id = mm.old_message_id
		   AND mm.is_new = 1;

	INSERT INTO mail.message_header (message_id, position, name, value)
		SELECT mm.new_message_id, mh.position, mh.name, mh.value
		  FROM csrimp.mail_message_header mh, csrimp.map_mail_message mm
		 WHERE mh.message_id = mm.old_message_id
		   AND mm.is_new = 1;

	INSERT INTO mail.message_address_field (message_id, field_id, position,
		address, name)
		SELECT mm.new_message_id, maf.field_id, maf.position, maf.address, maf.name
		  FROM csrimp.mail_message_address_field maf, csrimp.map_mail_message mm
		 WHERE maf.message_id = mm.old_message_id
		   AND mm.is_new = 1;

	INSERT INTO mail.mailbox_message (mailbox_sid, message_uid, message_id, flags,
		received_dtm, modseq)
		SELECT ms.new_sid, m.message_uid, mm.new_message_id, m.flags,
			   m.received_dtm, m.modseq
		  FROM csrimp.mail_mailbox_message m, csrimp.map_sid ms,
		  	   csrimp.map_mail_message mm
		 WHERE m.mailbox_sid = ms.old_sid
		   AND m.message_id = mm.old_message_id;

	-- under /mail/folders/foo@credit360.com/Users are a load of per user folders
	-- that have user sids as names -- these needs fixing (and the nasty hack
	-- should probably be removed!)
	v_users_sid := securableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), security_pkg.SID_ROOT,
		'/Mail/Folders/'||v_system_mail_address||'/Users');

	MERGE INTO security.securable_object so
	USING (SELECT so.sid_id, ms.new_sid
	   		 FROM csrimp.map_sid ms, security.securable_object so
	   		WHERE TO_CHAR(ms.old_sid) = so.name
	   		  AND so.parent_sid_id = v_users_sid) ms
	   ON (so.sid_id = ms.sid_id)
	 WHEN MATCHED THEN
	 	  UPDATE SET so.name = TO_CHAR(ms.new_sid);

	MERGE INTO mail.mailbox m
	USING (SELECT sid_id, name
	 		 FROM security.securable_object
	 		WHERE parent_sid_id = v_users_sid) so
	   ON (so.sid_id = m.mailbox_sid)
	 WHEN MATCHED THEN
	 	  UPDATE SET m.mailbox_name = so.name;

	v_registered_users_sid := getSIDFromPath('Groups/RegisteredUsers');

	-- if we had any existing super admins that weren't in the import they'll need
	-- mailboxes created for them in the new app
	FOR r IN (SELECT TO_CHAR(csr_user_sid) user_sid
				FROM csr.superadmin
			   MINUS
			  SELECT name
			    FROM security.securable_object
			   WHERE parent_sid_id = v_users_sid) LOOP

		mail.mail_pkg.createMailbox(v_users_sid, r.user_sid, v_user_mailbox_sid);
		v_dacl_id := acl_pkg.GetDACLIDForSID(v_user_mailbox_sid);
		IF v_dacl_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'The user mailbox with sid '||v_user_mailbox_sid||' and parent '||v_users_sid||' does not have a dacl id');
		END IF;
		acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_registered_users_sid, security_pkg.PERMISSION_ADD_CONTENTS);
		acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), v_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, r.user_sid, security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;
END;

PROCEDURE CreateSuperAdmins
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_superadmin_root_sid			security_pkg.T_SID_ID;
BEGIN
	v_superadmin_root_sid := securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security_pkg.SID_ROOT, '/csr/users');

	-- Map existing superadmins.  To account for existing zombie superadmins
	-- (those with rows missing from superadmin, but that exist under //csr/users)
	-- we map on securable_object rather than on the superadmin table.
	INSERT INTO csrimp.map_sid (old_sid, new_sid)
		SELECT os.csr_user_sid, so.sid_id
		  FROM csrimp.superadmin os, security.securable_object so
		 WHERE LOWER(os.user_name) = LOWER(so.name)
		   AND so.parent_sid_id = v_superadmin_root_sid;

	-- Create new ones -- disregard any that exist already (we can't just check the superadmin
	-- table because of the afore-mentioned zombies).
	FOR r IN (SELECT csr_user_sid, email, guid, full_name, user_name, friendly_name
			    FROM csrimp.superadmin
			   WHERE LOWER(user_name) NOT IN (
			   			SELECT LOWER(name)
			   			  FROM security.securable_object
			   			 WHERE parent_sid_id = v_superadmin_root_sid
			   		)) LOOP

		csr.csr_user_pkg.createSuperAdmin(
			in_act					=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_user_name			=> LOWER(r.user_name),
			in_password				=> NULL,
			in_full_name			=> r.full_name,
			in_friendly_name		=> r.friendly_name,
			in_email				=> r.email,
			out_user_sid			=> v_user_sid);

		INSERT INTO csrimp.map_sid (old_sid, new_sid)
		VALUES (r.csr_user_sid, v_user_sid);
	END LOOP;

	-- Add mappings for the superadmin's per user folders
	INSERT INTO csrimp.map_sid (old_sid, new_sid)
		SELECT sf.sid_id old_sid, so.sid_id new_sid
		  FROM csrimp.superadmin_folder sf, csrimp.map_sid ms,
			   security.securable_object so
		 WHERE ms.old_sid = sf.csr_user_sid
		   AND ms.new_sid = so.parent_sid_id
		   AND LOWER(so.name) = LOWER(sf.name);
END;

PROCEDURE CreateTranslations
AS
	v_to_application_sid	security_pkg.T_SID_ID;
	v_app_sid 				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_act_id 				security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_session_id			NUMBER := SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID');
BEGIN

	INSERT INTO aspen2.translation_application (application_sid, base_lang, static_translation_path)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), base_lang, static_translation_path
		  FROM csrimp.aspen2_translation_app;

	INSERT INTO aspen2.translation_set (application_sid, lang, revision, hidden)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), lang, revision, hidden
		  FROM csrimp.aspen2_translation_set
		 WHERE lang IN (SELECT lang FROM aspen2.lang);

	INSERT INTO aspen2.translation_set_include (application_sid, lang, pos, to_application_sid, to_lang)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), lang, pos, SYS_CONTEXT('SECURITY', 'APP'), to_lang
		  FROM csrimp.aspen2_translation_set_incl
		 WHERE to_application IS NULL
		   AND lang IN (SELECT lang FROM aspen2.lang);

	-- logoff to be able to get the cross site sids from the paths
	security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));

	FOR r IN (SELECT lang, pos, to_application, to_lang
				FROM csrimp.aspen2_translation_set_incl
			   WHERE csrimp_session_id = v_session_id
				 AND to_application IS NOT NULL
			)
	LOOP
		BEGIN
			v_to_application_sid := securableObject_pkg.GetSIDFromPath_(
				in_parent_sid_id => security_pkg.SID_ROOT, 
				in_path => r.to_application);
			INSERT INTO aspen2.translation_set_include (application_sid, lang, pos, to_application_sid, to_lang)
			VALUES (v_app_sid, r.lang, r.pos, v_to_application_sid, r.to_lang);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				-- just ignore includes from apps that don't exist
				NULL;
			WHEN OTHERS THEN
				RAISE_APPLICATION_ERROR(-20001, 'could not get sid from path '||r.to_application);
		END;
	END LOOP;

	-- log back on
	user_pkg.logonadmin();
	security.security_pkg.SetContext('CSRIMP_SESSION_ID', v_session_id);
	security.security_pkg.SetContext('APP', v_app_sid);

	INSERT INTO aspen2.translation (application_sid, original_hash, original)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), original_hash, original
		  FROM csrimp.aspen2_translation;

	INSERT INTO aspen2.translated (application_sid, lang, original_hash, translated, translated_id)
		SELECT SYS_CONTEXT('SECURITY', 'APP'), at.lang, at.original_hash, at.translated,
			   mt.new_translated_id
		  FROM csrimp.aspen2_translated at, csrimp.map_aspen2_translated mt
		 WHERE at.translated_id = mt.old_translated_id;
END;

PROCEDURE CreatePeriodSets
AS
BEGIN
	INSERT INTO csr.period_set (period_set_id, annual_periods, label)
		SELECT period_set_id, annual_periods, label
		  FROM csrimp.period_set;

	INSERT INTO csr.period (period_set_id, period_id, label, start_dtm, end_dtm)
		SELECT period_set_id, period_id, label, start_dtm, end_dtm
		  FROM csrimp.period;

	INSERT INTO csr.period_dates (period_set_id, period_id, year, start_dtm, end_dtm)
		SELECT period_set_id, period_id, year, start_dtm, end_dtm
		  FROM csrimp.period_dates;

	INSERT INTO csr.period_interval (period_set_id, period_interval_id, single_interval_label,
		multiple_interval_label, label, single_interval_no_year_label)
		SELECT period_set_id, period_interval_id, single_interval_label,
			   multiple_interval_label, label, single_interval_no_year_label
		  FROM csrimp.period_interval;

	INSERT INTO csr.period_interval_member (period_set_id, period_interval_id, start_period_id,
		end_period_id)
		SELECT period_set_id, period_interval_id, start_period_id, end_period_id
		  FROM csrimp.period_interval_member;
END;

PROCEDURE CreateReportingPeriods
AS
BEGIN
	INSERT INTO csr.reporting_period (reporting_period_sid, name, start_dtm, end_dtm)
		SELECT mrp.new_sid, rp.name, rp.start_dtm, rp.end_dtm
		  FROM csrimp.reporting_period rp, csrimp.map_sid mrp
		 WHERE rp.reporting_period_sid = mrp.old_sid;

	-- fix up customer.current_reporting_period_sid now the reporting period row exists
	UPDATE csr.customer
	   SET current_reporting_period_sid = (
			SELECT ms.new_sid
			  FROM csrimp.map_sid ms, csrimp.customer c
			 WHERE c.current_reporting_period_sid = ms.old_sid)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE CreateLookupTables
AS
BEGIN
	INSERT INTO csr.lookup_table (lookup_id, lookup_name)
		SELECT lookup_id, lookup_name
		  FROM csrimp.lookup_table;

	INSERT INTO csr.lookup_table_entry (lookup_id, start_dtm, val)
		SELECT lookup_id, start_dtm, val
		  FROM csrimp.lookup_table_entry;
END;

PROCEDURE CreateRagStatuses
AS
BEGIN
	INSERT INTO csr.rag_status (rag_status_id, colour, label, lookup_key)
		SELECT /*+CARDINALITY(it, 1000) CARDINALITY(mitrs, 1000)*/
		       mirs.new_rag_status_id, irs.colour, irs.label, irs.lookup_key
		  FROM csrimp.rag_status irs, csrimp.map_rag_status mirs
		 WHERE irs.rag_status_id = mirs.old_rag_status_id;
END;

PROCEDURE CreateCustomerFields
AS
	v_system_mail_address			csr.customer.system_mail_address%TYPE;
	v_tracker_mail_address			csr.customer.tracker_mail_address%TYPE;
BEGIN
	INSERT INTO aspen2.application (app_sid, menu_path, metadata_connection_string,
		commerce_store_path, admin_email, logon_url, referer_url, confirm_user_details,
		default_stylesheet, default_url, default_css, edit_css, logon_autocomplete,
		monitor_with_new_relic, default_script, cdn_server, ul_design_system_enabled,
		ga4_enabled, branding_service_enabled, display_cookie_policy, mega_menu_enabled, maxmind_enabled
	   )
		SELECT SYS_CONTEXT('SECURITY', 'APP'),
			REPLACE(a.menu_path, m_old_host, m_new_host),
			REPLACE(a.metadata_connection_string, m_old_host, m_new_host),
			REPLACE(a.commerce_store_path, m_old_host, m_new_host),
			REPLACE(a.admin_email, m_old_host, m_new_host),
			REPLACE(a.logon_url, m_old_host, m_new_host),
			REPLACE(a.referer_url, m_old_host, m_new_host),
			confirm_user_details,
			REPLACE(a.default_stylesheet, m_old_host, m_new_host),
			REPLACE(a.default_url, m_old_host, m_new_host),
			REPLACE(a.default_css, m_old_host, m_new_host),
			REPLACE(a.edit_css, m_old_host, m_new_host),
			logon_autocomplete,
			monitor_with_new_relic,
			REPLACE(a.default_script, m_old_host, m_new_host),
			a.cdn_server,
			a.ul_design_system_enabled,
			a.ga4_enabled,
			a.branding_service_enabled,
			a.display_cookie_policy,
			a.mega_menu_enabled,
			a.maxmind_enabled
		  FROM csrimp.aspen2_application a;

	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Inserted '||SQL%ROWCOUNT||' rows into aspen2.application -- something went wrong!');
	END IF;

	GetMailAccounts(m_new_host, v_system_mail_address, v_tracker_mail_address);

	INSERT INTO csr.customer (app_sid, name, host, system_mail_address, tracker_mail_address,
	   alert_mail_address, alert_mail_name, alert_batch_run_time,
	   trash_sid, aggregation_engine_version, contact_email, editing_url,
	   message, ind_info_xml_fields, region_info_xml_fields, user_info_xml_fields,
	   raise_reminders, account_policy_sid, status, raise_split_deleg_alerts,
	   current_reporting_period_sid, lock_start_dtm, lock_end_dtm,
	   region_root_sid, ind_root_sid, reporting_ind_root_sid,
	   cascade_reject, approver_response_window,
	   self_reg_group_sid, self_reg_needs_approval, self_reg_approver_sid,
	   allow_partial_submit, helper_assembly, approval_step_sheet_url,
	   use_tracker, use_user_sheets, allow_val_edit, fully_hide_sheets,
	   calc_sum_zero_fill, equality_epsilon, create_sheets_at_period_end, audit_calc_changes,
	   oracle_schema, ind_cms_table, target_line_col_from_gradient,
	   use_carbon_emission, helper_pkg, chain_invite_landing_preable,
	   chain_invite_landing_qstn, allow_deleg_plan, supplier_region_root_sid,
	   trucost_company_id, trucost_portlet_tab_id, fogbugz_ixproject, fogbugz_sarea,
	   propagate_deleg_values_down, enable_save_chart_warning,
	   issue_editor_url, allow_make_editable, alert_uri_format, unmerged_consistent,
	   unmerged_scenario_run_sid, ind_selections_enabled, check_tolerance_against_zero,
	   scenarios_enabled, calc_job_priority, copy_vals_to_new_sheets, use_var_expl_groups,
	   apply_factors_to_child_regions, merged_scenario_run_sid, bounce_tracking_enabled,
	   issue_escalation_enabled, incl_inactive_regions, check_divisibility, audit_helper_pkg,
	   start_month, chart_xsl, show_region_disposal_date, data_explorer_show_markers,
	   show_all_sheets_for_rep_prd, deleg_browser_show_rag, tgtdash_ignore_estimated,
	   tgtdash_hide_totals, tgtdash_show_chg_from_last_yr, tgtdash_show_last_year,
	   tgtdash_colour_text, tgtdash_show_target_first, tgtdash_show_flash, use_region_events,
	   metering_enabled, crc_metering_enabled, crc_metering_ind_core, crc_metering_auto_core,
	   iss_view_src_to_deepest_sheet, delegs_always_show_adv_opts, default_admin_css, max_dataview_history,
	   ntfy_days_before_user_inactive, data_explorer_show_ranking, data_explorer_show_trends, data_explorer_show_scatter,
	   data_explorer_show_radar, data_explorer_show_gauge, data_explorer_show_waterfall,
	   tolerance_checker_req_merged, multiple_audit_surveys, audits_on_users,
	   include_nulls_in_ta, allow_multiperiod_forms, rstrct_multiprd_frm_edit_to_yr, copy_forward_allow_na,
	   adj_factorset_startmonth, allow_custom_issue_types, allow_section_in_many_carts,
	   calc_job_notify_address, calc_job_notify_after_attempts, chemical_flow_sid, default_country,
	   est_job_notify_address, est_job_notify_after_attempts, failed_calc_job_retry_delay,
	   legacy_period_formatting, live_metering_show_gaps, lock_prevents_editing, max_concurrent_calc_jobs,
	   metering_gaps_from_acquisition, property_flow_sid, restrict_issue_visibility, scrag_queue,
	   status_from_parent_on_subdeleg, translation_checkbox, user_admin_helper_pkg, user_directory_type_id,
	   quick_survey_fixed_structure, remove_roles_on_account_expir, like_for_like_slots, show_aggregate_override,
	   allow_old_chart_engine, tear_off_deleg_header, show_map_on_audit_list, deleg_dropdown_threshold, user_picker_extra_fields,
	   forecasting_slots, divisibility_bug, rest_api_guest_access, question_library_enabled, calc_sum_to_dt_cust_yr_start,
	   calc_start_dtm, calc_end_dtm, show_additional_audit_info, lazy_load_role_membership, calc_future_window,
	   require_sa_login_reason, site_type, allow_cc_on_alerts, chart_algorithm_version,
	   marked_for_zap, zap_after_dtm, batch_jobs_disabled, calc_jobs_disabled, scheduled_tasks_disabled, alerts_disabled, prevent_logon,
	   mobile_branding_enabled, enable_java_auth, render_charts_as_svg, show_data_approve_confirm,
	   auto_anonymisation_enabled, inactive_days_before_anonymisation
	   )
		SELECT SYS_CONTEXT('SECURITY', 'APP'), m_new_host, m_new_host,
			   v_system_mail_address, v_tracker_mail_address,
			   c.alert_mail_address, c.alert_mail_name, c.alert_batch_run_time,
			   mtr.new_sid, c.aggregation_engine_version, c.contact_email, c.editing_url, c.message,
			   c.ind_info_xml_fields, c.region_info_xml_fields, c.user_info_xml_fields,
			   0,  /* we always have reminders turned OFF because otherwise we risk spamming users accidentally */
			   map.new_sid, c.status, c.raise_split_deleg_alerts,
			   null, /* current_reporting_period_sid: fixed in CreateReportingPeriods */
			   c.lock_start_dtm, c.lock_end_dtm,
			   null, /* region_root_sid: fixed in CreateRegions */
			   null, /* ind_root_sid: fixed in CreateIndicators */
			   null, /* reporting_ind_root_sid: fixed in CreateIndicators */
			   c.cascade_reject, c.approver_response_window,
			   msrg.new_sid, c.self_reg_needs_approval,
			   null, /* self_reg_approver_sid: fixed in CreateUsers */
			   c.allow_partial_submit, c.helper_assembly, c.approval_step_sheet_url,
			   c.use_tracker, c.use_user_sheets, c.allow_val_edit, c.fully_hide_sheets,
			   c.calc_sum_zero_fill, c.equality_epsilon, c.create_sheets_at_period_end, c.audit_calc_changes,
			   ms.new_oracle_schema, c.ind_cms_table, c.target_line_col_from_gradient,
			   c.use_carbon_emission,
			   CASE WHEN LOWER(c.helper_pkg) LIKE LOWER(c.oracle_schema)||'.%' THEN ms.new_oracle_schema||'.'||substr(c.helper_pkg,LENGTH(c.oracle_schema)+1)
			   ELSE c.helper_pkg END,
			   c.chain_invite_landing_preable,
			   c.chain_invite_landing_qstn, c.allow_deleg_plan,
			   null, /* supplier_region_root_sid: fixed in CreateRegions */
			   c.trucost_company_id,
			   null, /* trucost_portlet_tab_id: fixed in CreatePortlets */
			   c.fogbugz_ixproject, c.fogbugz_sarea,
			   c.propagate_deleg_values_down, c.enable_save_chart_warning,
			   c.issue_editor_url, c.allow_make_editable, c.alert_uri_format, c.unmerged_consistent,
			   null, /* unmerged_scenario_run_sid: fixed in CreateScenarios */
			   c.ind_selections_enabled, c.check_tolerance_against_zero,
			   c.scenarios_enabled, c.calc_job_priority, c.copy_vals_to_new_sheets, c.use_var_expl_groups,
			   c.apply_factors_to_child_regions,
			   null, /* merged_scenario_run_sid: fixed in CreateScenarios */
			   c.bounce_tracking_enabled, c.issue_escalation_enabled, c.incl_inactive_regions,
			   c.check_divisibility,
			   CASE WHEN LOWER(c.audit_helper_pkg) LIKE LOWER(c.oracle_schema)||'.%' THEN ms.new_oracle_schema||'.'||substr(c.audit_helper_pkg,LENGTH(c.oracle_schema)+1)
			   ELSE c.audit_helper_pkg END,
			   c.start_month, c.chart_xsl, c.show_region_disposal_date,
			   c.data_explorer_show_markers, c.show_all_sheets_for_rep_prd, c.deleg_browser_show_rag,
			   c.tgtdash_ignore_estimated, c.tgtdash_hide_totals, c.tgtdash_show_chg_from_last_yr,
			   c.tgtdash_show_last_year, c.tgtdash_colour_text, c.tgtdash_show_target_first,
			   c.tgtdash_show_flash, c.use_region_events, c.metering_enabled, c.crc_metering_enabled,
			   c.crc_metering_ind_core, c.crc_metering_auto_core, c.iss_view_src_to_deepest_sheet,
			   c.delegs_always_show_adv_opts, c.default_admin_css, c.max_dataview_history,
			   c.ntfy_days_before_user_inactive, c.data_explorer_show_ranking, c.data_explorer_show_trends,
			   c.data_explorer_show_scatter, c.data_explorer_show_radar, c.data_explorer_show_gauge, c.data_explorer_show_waterfall,
			   c.tolerance_checker_req_merged, c.multiple_audit_surveys, c.audits_on_users,
			   c.include_nulls_in_ta, c.allow_multiperiod_forms, c.rstrct_multiprd_frm_edit_to_yr, c.copy_forward_allow_na,
			   c.adj_factorset_startmonth, c.allow_custom_issue_types, c.allow_section_in_many_carts,
			   c.calc_job_notify_address, c.calc_job_notify_after_attempts,
			   null, /* chemical_flow_sid: fixed in CreateFlow */
			   c.default_country,
			   c.est_job_notify_address, c.est_job_notify_after_attempts, c.failed_calc_job_retry_delay,
			   c.legacy_period_formatting, c.live_metering_show_gaps, c.lock_prevents_editing, c.max_concurrent_calc_jobs,
			   c.metering_gaps_from_acquisition,
			   null, /* property_flow_sid: fixed in CreateFlow */
			   c.restrict_issue_visibility, c.scrag_queue,
			   c.status_from_parent_on_subdeleg, c.translation_checkbox,
			   CASE WHEN LOWER(c.user_admin_helper_pkg) LIKE LOWER(c.oracle_schema)||'.%' THEN ms.new_oracle_schema||'.'||substr(c.user_admin_helper_pkg,LENGTH(c.oracle_schema)+1)
			   ELSE c.user_admin_helper_pkg END,
			   c.user_directory_type_id, c.quick_survey_fixed_structure, c.remove_roles_on_account_expir, c.like_for_like_slots,
			   c.show_aggregate_override, c.allow_old_chart_engine,
			   c.tear_off_deleg_header, c.show_map_on_audit_list, c.deleg_dropdown_threshold,
			   c.user_picker_extra_fields, c.forecasting_slots, c.divisibility_bug, c.rest_api_guest_access,
			   c.question_library_enabled, c.calc_sum_to_dt_cust_yr_start,
			   c.calc_start_dtm, c.calc_end_dtm, c.show_additional_audit_info, c.lazy_load_role_membership, c.calc_future_window,
			   c.require_sa_login_reason, c.site_type, c.allow_cc_on_alerts, c.chart_algorithm_version,
			   c.marked_for_zap, c.zap_after_dtm, c.batch_jobs_disabled, c.calc_jobs_disabled, c.scheduled_tasks_disabled, c.alerts_disabled, c.prevent_logon,
			   c.mobile_branding_enabled, c.enable_java_auth, c.render_charts_as_svg, c.show_data_approve_confirm,
			   c.auto_anonymisation_enabled, c.inactive_days_before_anonymisation
		  FROM csrimp.customer c, csrimp.map_sid mtr, csrimp.map_sid map,
		  	   csrimp.map_sid msrg, csrimp.map_cms_schema ms
		 WHERE c.trash_sid = mtr.old_sid
		   AND c.account_policy_sid = map.old_sid
		   AND c.self_reg_group_sid = msrg.old_sid(+)
		   AND c.oracle_schema = ms.old_oracle_schema(+);

	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Inserted '||SQL%ROWCOUNT||' rows into customer -- something went wrong!');
	END IF;

	-- locks
	INSERT INTO csr.app_lock (lock_type)
	VALUES (csr.csr_data_pkg.LOCK_TYPE_CALC);
	INSERT INTO csr.app_lock (lock_type)
	VALUES (csr.csr_data_pkg.LOCK_TYPE_SHEET_CALC);

	-- a default gets poked in, so don't duplicate it
	INSERT INTO csr.customer_help_lang (
				help_lang_id,
				is_default
	   ) SELECT chl.help_lang_id,
				chl.is_default
		   FROM csrimp.customer_help_lang chl
		  MINUS
		 SELECT help_lang_id,
		        is_default
		   FROM csr.customer_help_lang;

	INSERT INTO csr.scragpp_audit_log (action, action_dtm, user_sid)
		 SELECT action, action_dtm, user_sid
		   FROM csrimp.scragpp_audit_log;

	INSERT INTO csr.scragpp_status (old_scrag, testcube_enabled, validation_approved_ref, scragpp_enabled)
		 SELECT old_scrag, testcube_enabled, validation_approved_ref, scragpp_enabled
		   FROM csrimp.scragpp_status;
END;

PROCEDURE CreateFileUploadOptions
AS
BEGIN
	INSERT INTO csr.customer_file_upload_type_opt (file_extension, is_allowed)
		SELECT file_extension, is_allowed
		  FROM csrimp.customer_file_upload_type_opt;

	INSERT INTO csr.customer_file_upload_mime_opt (mime_type, is_allowed)
		SELECT mime_type, is_allowed
		  FROM csrimp.customer_file_upload_mime_opt;
END;

PROCEDURE AddExistingSuperAdmins
AS
BEGIN
	-- add csr_user rows for superadmins that exist locally but are not in the import
	INSERT INTO csr.csr_user (csr_user_sid, user_name, full_name, friendly_name, email, guid, hidden, enable_aria, line_manager_sid)
		SELECT su.csr_user_sid, su.user_name, su.full_name, su.friendly_name, su.email, su.guid, 1, 0, NULL
		  FROM csr.superadmin su
		 WHERE su.csr_user_sid NOT IN (
				SELECT csr_user_sid
				  FROM csr.csr_user);

    -- backfill startpoints
    INSERT INTO csr.ind_start_point (user_sid, ind_sid)
        SELECT su.csr_user_sid, c.ind_root_sid
		  FROM csr.superadmin su, csr.customer c
		 WHERE su.csr_user_sid NOT IN (
		   		SELECT user_sid
		   		  FROM csr.ind_start_point)
		   AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP');

    INSERT INTO csr.region_start_point (user_sid, region_sid)
        SELECT su.csr_user_sid, c.region_root_sid
		  FROM csr.superadmin su, csr.customer c
		 WHERE su.csr_user_sid NOT IN (
		   		SELECT user_sid
		   		  FROM csr.region_start_point)
		   AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP');
			 
END;

PROCEDURE CreateIndSelectionGroups
AS
BEGIN
	INSERT INTO csr.ind_selection_group (master_ind_sid)
		SELECT mi.new_sid
		  FROM csrimp.ind_selection_group isg, csrimp.map_sid mi
		 WHERE isg.master_ind_sid = mi.old_sid;

	INSERT INTO csr.ind_selection_group_member (master_ind_sid, ind_sid, pos)
		SELECT mmi.new_sid, mi.new_sid, isgm.pos
		  FROM csrimp.ind_selection_group_member isgm,
		  	   csrimp.map_sid mmi, csrimp.map_sid mi
		 WHERE isgm.master_ind_sid = mmi.old_sid
		   AND isgm.ind_sid = mi.old_sid;

	INSERT INTO csr.ind_sel_group_member_desc (ind_sid, lang, description)
		SELECT mi.new_sid, isgmd.lang, isgmd.description
		  FROM csrimp.ind_sel_group_member_desc isgmd, csrimp.map_sid mi
		 WHERE isgmd.ind_sid = mi.old_sid
		   AND isgmd.lang IN (SELECT lang FROM aspen2.lang);
END;

PROCEDURE CreateTagGroups
AS
BEGIN
	INSERT INTO csr.tag_group (tag_group_id, multi_select, mandatory, lookup_key,
				applies_to_inds, applies_to_regions, applies_to_non_compliances,
				applies_to_suppliers, applies_to_initiatives, applies_to_chain, applies_to_chain_activities,
				applies_to_chain_product_types, applies_to_chain_products, applies_to_chain_product_supps,
				applies_to_quick_survey, applies_to_audits, applies_to_compliances, is_hierarchical)
		 SELECT mtg.new_tag_group_id, tg.multi_select, tg.mandatory, tg.lookup_key,
				tg.applies_to_inds,  tg.applies_to_regions, tg.applies_to_non_compliances,
				tg.applies_to_suppliers, tg.applies_to_initiatives, tg.applies_to_chain, tg.applies_to_chain_activities,
				tg.applies_to_chain_product_types, tg.applies_to_chain_products, tg.applies_to_chain_product_supps,
				tg.applies_to_quick_survey,  tg.applies_to_audits, tg.applies_to_compliances, tg.is_hierarchical
		   FROM csrimp.tag_group tg, csrimp.map_tag_group mtg
		  WHERE mtg.old_tag_group_id = tg.tag_group_id;

	INSERT INTO csr.tag_group_description (tag_group_id, lang, name, last_changed_dtm)
		SELECT mtg.new_tag_group_id, tgd.lang, tgd.name, tgd.last_changed_dtm
		  FROM csrimp.tag_group_description tgd, csrimp.map_tag_group mtg
		 WHERE mtg.old_tag_group_id = tgd.tag_group_id;

	INSERT INTO csr.tag (tag_id, lookup_key, exclude_from_dataview_grouping, parent_id)
		SELECT mt.new_tag_id, t.lookup_key, t.exclude_from_dataview_grouping, null
		  FROM csrimp.tag t, csrimp.map_tag mt
		 WHERE mt.old_tag_id = t.tag_id;

	FOR r IN (
		SELECT tag_id, parent_id
		  FROM csrimp.tag
		 WHERE parent_id IS NOT NULL
	)
	LOOP
		UPDATE csr.tag t
		   SET parent_id = (
				SELECT mt.new_tag_id
				  FROM csrimp.map_tag mt
				 WHERE mt.old_tag_id = r.parent_id
		)
		WHERE r.tag_id = t.tag_id;
	END LOOP;

	INSERT INTO csr.tag_description (tag_id, lang, tag, explanation, last_changed_dtm)
		SELECT mt.new_tag_id, td.lang, td.tag, td.explanation, td.last_changed_dtm
		  FROM csrimp.tag_description td, csrimp.map_tag mt
		 WHERE mt.old_tag_id = td.tag_id;

	INSERT INTO csr.tag_group_member (tag_group_id, tag_id, pos, active)
		SELECT mtg.new_tag_group_id, mt.new_tag_id, tgm.pos, tgm.active
		  FROM csrimp.tag_group_member tgm, csrimp.map_tag_group mtg,
		  	   csrimp.map_tag mt
		 WHERE tgm.tag_id = mt.old_tag_id
		   AND tgm.tag_group_id = mtg.old_tag_group_id;
END;

PROCEDURE CreateAccuracyTypes
AS
BEGIN
	INSERT INTO csr.accuracy_type (accuracy_type_id, label, q_or_c, max_score)
		SELECT mat.new_accuracy_type_id, at.label, at.q_or_c, at.max_score
		  FROM csrimp.accuracy_type at, csrimp.map_accuracy_type mat
		 WHERE at.accuracy_type_id = mat.old_accuracy_type_id;

	INSERT INTO csr.accuracy_type_option (accuracy_type_option_id, accuracy_type_id, label, accuracy_weighting)
		SELECT mato.new_accuracy_type_option_id, mat.new_accuracy_type_id, ato.label, ato.accuracy_weighting
		  FROM csrimp.accuracy_type_option ato, csrimp.map_accuracy_type mat,
		  	   csrimp.map_accuracy_type_option mato
		 WHERE ato.accuracy_type_id = mat.old_accuracy_type_id
		   AND ato.accuracy_type_option_id = mato.old_accuracy_type_option_id;
END;

PROCEDURE CreateCustomerAlertTypes
AS
BEGIN
	INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id, get_params_sp)
		SELECT mcat.new_customer_alert_type_id, std_alert_type_id, get_params_sp
		  FROM csrimp.customer_alert_type cat, csrimp.map_customer_alert_type mcat
		 WHERE cat.customer_alert_type_id = mcat.old_customer_alert_type_id;

	INSERT INTO customer_alert_type_param (customer_alert_type_id, field_name, description,
		help_text, repeats, display_pos)
		SELECT mcat.new_customer_alert_type_id, cat.field_name, cat.description, cat.help_text,
			   cat.repeats, cat.display_pos
		  FROM csrimp.customer_alert_type_param cat, csrimp.map_customer_alert_type mcat
		 WHERE cat.customer_alert_type_id = mcat.old_customer_alert_type_id;

	-- frame bodies
	INSERT INTO csr.alert_frame (alert_frame_id, name)
		SELECT maf.new_alert_frame_id, af.name
		  FROM csrimp.alert_frame af, csrimp.map_alert_frame maf
		 WHERE af.alert_frame_id = maf.old_alert_frame_id;

	INSERT INTO csr.alert_frame_body (alert_frame_id, lang, html)
		SELECT maf.new_alert_frame_id, afb.lang, afb.html
		  FROM csrimp.alert_frame_body afb, csrimp.map_alert_frame maf
		 WHERE afb.alert_frame_id = maf.old_alert_frame_id;

	-- templates
	INSERT INTO csr.alert_template (customer_alert_type_id, alert_frame_id, send_type,
		reply_to_name, reply_to_email, from_email, from_name)
		SELECT mcat.new_customer_alert_type_id, maf.new_alert_frame_id, at.send_type,
			   at.reply_to_name, at.reply_to_email, at.from_email, at.from_name
		  FROM csrimp.alert_template at, csrimp.map_customer_alert_type mcat,
		  	   csrimp.map_alert_frame maf
		 WHERE at.customer_alert_type_id = mcat.old_customer_alert_type_id
		   AND at.alert_frame_id = maf.old_alert_frame_id;

	-- template bodies
	INSERT INTO csr.alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT mcat.new_customer_alert_type_id, atb.lang, atb.subject, atb.body_html, atb.item_html
		  FROM csrimp.alert_template_body atb, csrimp.map_customer_alert_type mcat
		 WHERE atb.customer_alert_type_id = mcat.old_customer_alert_type_id
		   AND atb.lang IN (SELECT lang FROM aspen2.lang);
END;

PROCEDURE CreateMeasures
AS
BEGIN
	INSERT INTO csr.measure (measure_sid, name, description, scale, format_mask,
		regional_aggregation, custom_field, option_set_id, pct_ownership_applies,
		std_measure_conversion_id, factor, m, kg, s, a, k, mol, cd, divisibility, lookup_key)
		SELECT ms.new_sid, m.name, m.description, m.scale, m.format_mask,
			   m.regional_aggregation, m.custom_field, m.option_set_id, m.pct_ownership_applies,
			   m.std_measure_conversion_id, m.factor, m.m, m.kg, m.s, m.a, m.k, m.mol, m.cd,
			   m.divisibility, m.lookup_key
		  FROM csrimp.measure m, csrimp.map_sid ms
		 WHERE m.measure_sid = ms.old_sid;

	INSERT INTO csr.measure_conversion (measure_conversion_id, measure_sid, std_measure_conversion_id,
		description, a, b, c, lookup_key)
		SELECT mmc.new_measure_conversion_id, ms.new_sid, mc.std_measure_conversion_id,
			   mc.description, mc.a, mc.b, mc.c, mc.lookup_key
		  FROM csrimp.measure_conversion mc, csrimp.map_sid ms, csrimp.map_measure_conversion mmc
		 WHERE mc.measure_sid = ms.old_sid
		   AND mc.measure_conversion_id = mmc.old_measure_conversion_id;

	INSERT INTO csr.measure_conversion_period (measure_conversion_id, start_dtm, end_dtm, a, b, c)
		SELECT mmc.new_measure_conversion_id, mcp.start_dtm, mcp.end_dtm, mcp.a, mcp.b, mcp.c
		  FROM csrimp.measure_conversion_period mcp, csrimp.map_measure_conversion mmc
		 WHERE mcp.measure_conversion_id = mmc.old_measure_conversion_id;
END;

PROCEDURE FixCalcXml(
	in_node							IN	dbms_xmldom.domnode
)
AS
	v_node							dbms_xmldom.domnode := in_node;
	v_child							dbms_xmldom.domnode;
	v_sid 							varchar2(100);
	v_new_sid						csrimp.ind.ind_sid%TYPE;
	v_tag_id						varchar2(100);
	v_new_tag_id					csrimp.tag.tag_id%TYPE;
	v_sheet_id						varchar2(100);
	v_new_sheet_id					csrimp.model_sheet.sheet_id%TYPE;
	v_baseline_config_id			varchar2(100);
	v_new_baseline_config_id		csrimp.baseline_config.baseline_config_id%TYPE;
BEGIN
	WHILE NOT dbms_xmldom.isnull(v_node) LOOP
		IF dbms_xmldom.getnodetype(v_node) = dbms_xmldom.element_node THEN
			v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), 'sid');
			IF v_sid IS NOT NULL THEN
				BEGIN
					SELECT new_sid
					  INTO v_new_sid
					  FROM map_sid
					 WHERE old_sid = TO_NUMBER(v_sid);
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'The ind with sid '||v_sid||' was not found');
					WHEN OTHERS THEN
						RAISE_APPLICATION_ERROR(-20001, 'The ind with sid '||v_sid||' was not valid');
				END;
				--dbms_output.put_line('sid = '||v_sid||' -> '||v_new_sid);
				dbms_xmldom.setattribute(dbms_xmldom.makeelement(v_node), 'sid', v_new_sid);
			END IF;

			v_tag_id := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), 'tagId');
			IF v_tag_id IS NOT NULL THEN
				BEGIN
					SELECT new_tag_id
					  INTO v_new_tag_id
					  FROM map_tag
					 WHERE old_tag_id = TO_NUMBER(v_tag_id);
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'The tag with id '||v_tag_id||' was not found');
				END;
				--dbms_output.put_line('tag = '||v_tag_id||' -> '||v_new_tag_id);
				dbms_xmldom.setattribute(dbms_xmldom.makeelement(v_node), 'tagId', v_new_tag_id);
			END IF;

			v_sheet_id := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), 'sheet');
			IF v_sheet_id IS NOT NULL THEN
				BEGIN
					SELECT new_sheet_id
					  INTO v_new_sheet_id
					  FROM map_model_sheet
					 WHERE old_sheet_id = TO_NUMBER(v_sheet_id);
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'The model sheet with id '||v_sheet_id||' was not found');
				END;
				--dbms_output.put_line('sheet = '||v_sheet_id||' -> '||v_new_sheet_id);
				dbms_xmldom.setattribute(dbms_xmldom.makeelement(v_node), 'sheet', v_new_sheet_id);
			END IF;

			v_baseline_config_id := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), 'configId');
			IF v_baseline_config_id IS NOT NULL THEN
				BEGIN
					SELECT new_baseline_config_id
					  INTO v_new_baseline_config_id
					  FROM map_baseline_config
					 WHERE old_baseline_config_id = TO_NUMBER(v_baseline_config_id);
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'The baseline_config with id '||v_baseline_config_id||' was not found');
				END;
				--dbms_output.put_line('baseline_config = '||v_baseline_config_id||' -> '||v_new_baseline_config_id);
				dbms_xmldom.setattribute(dbms_xmldom.makeelement(v_node), 'configId', v_new_baseline_config_id);
			END IF;

			v_child := dbms_xmldom.getfirstchild(v_node);
			IF NOT dbms_xmldom.isnull(v_child) THEN
				FixCalcXml(v_child);
			END IF;
		END IF;
		v_node := dbms_xmldom.getnextsibling(v_node);
	END LOOP;
END;

PROCEDURE FixCalculations
AS
	v_doc							dbms_xmldom.domdocument;
	v_xml							sys.xmltype;
	e_missing_ind 					EXCEPTION;
	PRAGMA EXCEPTION_INIT(e_missing_ind, -20001);
BEGIN
    FOR r IN (SELECT mi.new_sid, i.calc_xml
    			FROM csrimp.ind i, csrimp.map_sid mi
    		   WHERE i.ind_sid = mi.old_sid
    		     AND i.calc_xml IS NOT NULL) LOOP
		v_doc := dbms_xmldom.newdomdocument(r.calc_xml);
		BEGIN
			--dbms_output.put_line('fixing '||r.ind_sid);
			FixCalcXml(dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(v_doc)));
			v_xml := dbms_xmldom.getxmltype(v_doc);
			UPDATE csr.ind
			   SET calc_xml = EXTRACT(v_xml, '/').getClobVal()
			 WHERE ind_sid = r.new_sid;
		EXCEPTION
			WHEN e_missing_ind THEN
				-- probably the indicator was in the trash
				-- this is a problem with the trash stuff (TO BE FIXED) (WHEN???)
				-- clear calc for now
				UPDATE csr.ind
				   SET calc_xml = NULL, ind_type = csr.csr_data_pkg.IND_TYPE_NORMAL
				 WHERE ind_sid = r.new_sid;
		END;
		dbms_xmldom.freedocument(v_doc);
	END LOOP;
END;

PROCEDURE FixFormExprs
AS
	v_doc							dbms_xmldom.domdocument;
	v_xml							sys.xmltype;
	e_missing_ind 					EXCEPTION;
	PRAGMA EXCEPTION_INIT(e_missing_ind, -20001);
BEGIN
    FOR r IN (SELECT mfe.new_form_expr_id, fe.expr
    			FROM csrimp.form_expr fe, csrimp.map_form_expr mfe
    		   WHERE fe.form_expr_id = mfe.old_form_expr_id) LOOP
		v_doc := dbms_xmldom.newdomdocument(r.expr);
		BEGIN
			--dbms_output.put_line('fixing '||r.ind_sid);
			FixCalcXml(dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(v_doc)));
			v_xml := dbms_xmldom.getxmltype(v_doc);
			UPDATE csr.form_expr
			   SET expr = v_xml
			 WHERE form_expr_id = r.new_form_expr_id;
		EXCEPTION
			WHEN e_missing_ind THEN
				-- probably the indicator was in the trash
				-- this is a problem with the trash stuff (TO BE FIXED) (WHEN???)
				-- clear for now
				DELETE FROM csr.deleg_ind_form_expr
				 WHERE form_expr_id = r.new_form_expr_id;
				DELETE FROM csr.form_expr
				 WHERE form_expr_id = r.new_form_expr_id;
		END;
		dbms_xmldom.freedocument(v_doc);
	END LOOP;
END;

PROCEDURE CreateIndicators
AS
BEGIN
	INSERT INTO csr.ind (ind_sid, parent_sid, name, ind_type, 
		tolerance_type, pct_upper_tolerance, pct_lower_tolerance,
		tolerance_number_of_periods, tolerance_number_of_standard_deviations_from_average,
		measure_sid, multiplier, scale, format_mask,
		last_modified_dtm, active, target_direction, pos, info_xml, start_month,
		divisibility, null_means_null, aggregate, period_set_id, period_interval_id,
		calc_start_dtm_adjustment, calc_end_dtm_adjustment,
		calc_fixed_start_dtm, calc_fixed_end_dtm, calc_output_round_dp,
		calc_xml, gri, lookup_key, owner_sid, ind_activity_type_id,
		core, roll_forward, factor_type_id, map_to_ind_sid, gas_measure_sid,
		gas_type_id, calc_description, normalize, do_temporal_aggregation,
		prop_down_region_tree_sid, is_system_managed)
		SELECT mi.new_sid, mp.new_sid, i.name, i.ind_type,
			   i.tolerance_type, i.pct_upper_tolerance, i.pct_lower_tolerance,
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   mm.new_sid, i.multiplier, i.scale, i.format_mask,
			   i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml, i.start_month,
			   i.divisibility, i.null_means_null, i.aggregate, i.period_set_id, i.period_interval_id,
			   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment,
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.calc_output_round_dp,
			   i.calc_xml, i.gri, i.lookup_key, mo.new_sid, i.ind_activity_type_id,
			   i.core, i.roll_forward, i.factor_type_id, mmi.new_sid, mgm.new_sid,
			   i.gas_type_id, i.calc_description, i.normalize, i.do_temporal_aggregation,
			   mpdr.new_sid, i.is_system_managed
	      FROM csrimp.ind i, csrimp.map_sid mi, csrimp.map_sid mp, csrimp.map_sid mm,
	      	   csrimp.map_sid mmi, csrimp.map_sid mgm, csrimp.map_sid mo, csrimp.map_sid mpdr
	     WHERE i.ind_sid = mi.old_sid
	       AND i.parent_sid = mp.old_sid
	       AND i.measure_sid = mm.old_sid(+)
	       AND i.owner_sid = mo.old_sid(+)
	       AND i.map_to_ind_sid = mmi.old_sid(+)
	       AND i.gas_measure_sid = mgm.old_sid(+)
	       AND i.prop_down_region_tree_sid = mpdr.old_sid(+);

    -- update calculations
    FixCalculations;

    INSERT INTO csr.calc_dependency (calc_ind_sid, ind_sid, dep_type)
    	SELECT mci.new_sid, mi.new_sid, cd.dep_type
    	  FROM csrimp.calc_dependency cd, csrimp.map_sid mci, csrimp.map_sid mi, csr.ind i
    	 WHERE cd.calc_ind_sid = mci.old_sid
    	   AND cd.ind_sid = mi.old_sid
    	   AND mci.new_sid = i.ind_sid
    	   -- skip any where the calc was cleared due to being invalid
    	   AND i.ind_type IN (csr.csr_data_pkg.IND_TYPE_CALC, csr.csr_data_pkg.IND_TYPE_STORED_CALC);

    -- flags
    INSERT INTO csr.ind_flag (ind_sid, flag, description, requires_note)
    	SELECT mi.new_sid, ifl.flag, ifl.description, ifl.requires_note
    	  FROM csrimp.map_sid mi, csrimp.ind_flag ifl
    	 WHERE mi.old_sid = ifl.ind_sid;

	-- descriptions
	INSERT INTO csr.ind_description (ind_sid, lang, description, last_changed_dtm)
		SELECT mi.new_sid, id.lang, id.description, id.last_changed_dtm
		  FROM csrimp.ind_description id, csrimp.map_sid mi
		 WHERE id.ind_sid = mi.old_sid
		   AND id.lang IN (SELECT lang FROM aspen2.lang);

	INSERT INTO csr.ind_validation_rule (ind_validation_rule_id, ind_sid, expr, message, position, type)
		SELECT csr.ind_validation_rule_id_seq.nextval, mi.new_sid, iivr.expr, iivr.message,
			   iivr.position, iivr.type
		  FROM csrimp.ind_validation_rule iivr, csrimp.map_sid mi
		 WHERE iivr.ind_sid = mi.old_sid;

	INSERT INTO csr.ind_tag (tag_id, ind_sid)
		SELECT mt.new_tag_id, mi.new_sid
		  FROM csrimp.ind_tag it, csrimp.map_sid mi, csrimp.map_tag mt
		 WHERE it.tag_id = mt.old_tag_id
		   AND it.ind_sid = mi.old_sid;

	-- fix up customer.ind_root_sid/reporting_ind_root_sid now the ind row(s) exist
	UPDATE csr.customer
	   SET ind_root_sid = (
			SELECT ms.new_sid
			  FROM csrimp.map_sid ms, csrimp.customer c
			 WHERE c.ind_root_sid = ms.old_sid),
		   reporting_ind_root_sid = (
			SELECT ms.new_sid
			  FROM csrimp.map_sid ms, csrimp.customer c
			 WHERE c.reporting_ind_root_sid = ms.old_sid)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO csr.calc_tag_dependency (calc_ind_sid, tag_id)
		SELECT mci.new_sid, mt.new_tag_id
		  FROM csrimp.calc_tag_dependency ctd, csrimp.map_sid mci,
		  	   csrimp.map_tag mt
		 WHERE ctd.calc_ind_sid = mci.old_sid
		   AND ctd.tag_id = mt.old_tag_id;

	INSERT INTO csr.calc_baseline_config_dependency (calc_ind_sid, baseline_config_id)
		SELECT mci.new_sid, mbc.new_baseline_config_id
		  FROM csrimp.calc_baseline_config_dependency ctd, csrimp.map_sid mci,
		  	   csrimp.map_baseline_config mbc
		 WHERE ctd.calc_ind_sid = mci.old_sid
		   AND ctd.baseline_config_id = mbc.old_baseline_config_id;

	INSERT INTO csr.aggregate_ind_group (aggregate_ind_group_id, helper_proc,
		helper_proc_args, name, js_include, label, run_daily, source_url, 
		run_for_current_month, lookup_key, data_bucket_sid, data_bucket_fetch_sp)
		SELECT mag.new_aggregate_ind_group_id, MapCustomerSchema(ag.helper_proc), ag.helper_proc_args,
			   MapCustomerSchema(ag.name), ag.js_include, MapCustomerSchema(ag.label), 
			   ag.run_daily, ag.source_url, ag.run_for_current_month,
			   ag.lookup_key,
			   maps.new_sid,
			   MapCustomerSchema(ag.data_bucket_fetch_sp)
		  FROM csrimp.aggregate_ind_group ag, csrimp.map_aggregate_ind_group mag, csrimp.map_sid maps
		 WHERE ag.aggregate_ind_group_id = mag.old_aggregate_ind_group_id
		   AND maps.new_sid = ag.data_bucket_sid;

	INSERT INTO csr.aggregate_ind_group (aggregate_ind_group_id, helper_proc,
		helper_proc_args, name, js_include, label, run_daily, source_url, 
		run_for_current_month, lookup_key, data_bucket_sid, data_bucket_fetch_sp)
		SELECT mag.new_aggregate_ind_group_id, MapCustomerSchema(ag.helper_proc), ag.helper_proc_args,
			   MapCustomerSchema(ag.name), ag.js_include, MapCustomerSchema(ag.label), 
			   ag.run_daily, ag.source_url, ag.run_for_current_month,
			   ag.lookup_key, 
			   NULL, 
			   NULL
		  FROM csrimp.aggregate_ind_group ag, csrimp.map_aggregate_ind_group mag
		 WHERE ag.aggregate_ind_group_id = mag.old_aggregate_ind_group_id
		   AND ag.data_bucket_sid IS NULL;

 	INSERT INTO csr.aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
		SELECT mag.new_aggregate_ind_group_id, mi.new_sid
		  FROM csrimp.aggregate_ind_group_member agm, csrimp.map_sid mi,
		  	   csrimp.map_aggregate_ind_group mag
		 WHERE agm.aggregate_ind_group_id = mag.old_aggregate_ind_group_id
		   AND agm.ind_sid = mi.old_sid;

	INSERT INTO csr.aggregate_ind_val_detail (
				aggregate_ind_group_id,
				description,
				dtm,
				ind_sid,
				link_url,
				period_end_dtm,
				period_start_dtm,
				region_sid,
				src_id
	   ) SELECT maig.new_aggregate_ind_group_id,
				aivd.description,
				aivd.dtm,
				ms.new_sid,
				aivd.link_url,
				aivd.period_end_dtm,
				aivd.period_start_dtm,
				ms1.new_sid,
				aivd.src_id
		   FROM csrimp.aggregate_ind_val_detail aivd,
				csrimp.map_aggregate_ind_group maig,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE aivd.aggregate_ind_group_id = maig.old_aggregate_ind_group_id
			AND aivd.ind_sid = ms.old_sid
			AND aivd.region_sid = ms1.old_sid;

	INSERT INTO csr.ind_window (
				ind_sid,
				period,
				comparison_offset,
				lower_bracket,
				upper_bracket
	   ) SELECT ms.new_sid,
				iw.period,
				iw.comparison_offset,
				iw.lower_bracket,
				iw.upper_bracket
		   FROM csrimp.ind_window iw,
				csrimp.map_sid ms
		  WHERE iw.ind_sid = ms.old_sid;
END;

PROCEDURE CreateRegions
AS
BEGIN
	INSERT INTO csr.customer_region_type (region_type)
		SELECT region_type
		  FROM csrimp.customer_region_type;

	INSERT INTO csr.region_type_tag_group (region_type, tag_group_id)
		 SELECT rttg.region_type, mtg.new_tag_group_id
		   FROM csrimp.region_type_tag_group rttg,
				csrimp.map_tag_group mtg
		  WHERE rttg.tag_group_id = mtg.old_tag_group_id;

	INSERT INTO csr.region (region_sid, link_to_region_sid, parent_sid, name, active,
	   pos, info_xml, flag, acquisition_dtm, disposal_dtm, region_type, lookup_key,
	   geo_country, geo_region, geo_city_id, geo_longitude, geo_latitude, geo_type,
	   map_entity, egrid_ref, egrid_ref_overridden, region_ref, last_modified_dtm)
		SELECT mr.new_sid, ml.new_sid, mp.new_sid, r.name, r.active,
			   r.pos, r.info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm,
			   r.region_type, r.lookup_key, r.geo_country, r.geo_region, r.geo_city_id,
			   r.geo_longitude, r.geo_latitude, r.geo_type, r.map_entity, r.egrid_ref,
			   r.egrid_ref_overridden, r.region_ref, r.last_modified_dtm
		  FROM csrimp.region r, csrimp.map_sid mr, csrimp.map_sid mp,
		  	   csrimp.map_sid ml
		 WHERE r.region_sid = mr.old_sid
		   AND r.parent_sid = mp.old_sid
		   AND r.link_to_region_sid = ml.old_sid(+);

	INSERT INTO csr.region_tag (tag_id, region_sid)
		SELECT mt.new_tag_id, mr.new_sid
		  FROM csrimp.map_tag mt, csrimp.region_tag rt, csrimp.map_sid mr
	     WHERE rt.region_sid = mr.old_sid
	       AND rt.tag_id = mt.old_tag_id;

	-- descriptions
	INSERT INTO csr.region_description (region_sid, lang, description, last_changed_dtm)
		SELECT mr.new_sid, rd.lang, rd.description, rd.last_changed_dtm
		  FROM csrimp.region_description rd, csrimp.map_sid mr
		 WHERE rd.region_sid = mr.old_sid
		   AND rd.lang IN (SELECT lang FROM aspen2.lang);

	-- now the region root exists, fix up customer.region_root_sid
	UPDATE csr.customer
	   SET region_root_sid = (
			SELECT ms.new_sid
			  FROM csrimp.map_sid ms, csrimp.customer c
			 WHERE c.region_root_sid = ms.old_sid),
		   supplier_region_root_sid = (
			SELECT ms.new_sid
			  FROM csrimp.map_sid ms, csrimp.customer c
			 WHERE c.supplier_region_root_sid = ms.old_sid)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE CreateRegionTrees
AS
BEGIN
	INSERT INTO csr.region_tree (region_tree_root_sid, is_primary, is_divisions, is_fund, last_recalc_dtm)
		SELECT mr.new_sid, rt.is_primary, rt.is_divisions, rt.is_fund, rt.last_recalc_dtm
		  FROM csrimp.region_tree rt, csrimp.map_sid mr
		 WHERE rt.region_tree_root_sid = mr.old_sid;

	CreateRegions;

	INSERT INTO csr.pct_ownership (region_sid, start_dtm, end_dtm, pct)
		SELECT mr.new_sid, pct.start_dtm, pct.end_dtm, pct.pct
		  FROM csrimp.map_sid mr, csrimp.pct_ownership pct
		 WHERE mr.old_sid = pct.region_sid;

	INSERT INTO csr.mgt_company_tree_sync_job (tree_root_sid)
		SELECT mr.new_sid
		  FROM csrimp.mgt_company_tree_sync_job mctsj
		  JOIN csrimp.map_sid mr ON mr.old_sid = mctsj.tree_root_sid;
END;

PROCEDURE CreateFactors
AS
BEGIN
	INSERT INTO csr.factor (factor_id, factor_type_id, gas_type_id, region_sid,
		geo_country, geo_region, egrid_ref, is_selected, start_dtm, end_dtm,
		value, note, std_measure_conversion_id, std_factor_id,
		custom_factor_id, original_factor_id, profile_id)
		 SELECT mf.new_factor_id, f.factor_type_id, f.gas_type_id, mr.new_sid,
		 		f.geo_country, f.geo_region, f.egrid_ref, f.is_selected, f.start_dtm, f.end_dtm,
		 		f.value, f.note, f.std_measure_conversion_id, f.std_factor_id,
				f.custom_factor_id, mof.new_factor_id, f.profile_id
		   FROM csrimp.factor f, csrimp.map_factor mf, csrimp.map_factor mof,
		   	    csrimp.map_sid mr
		  WHERE f.factor_id = mf.old_factor_id
		    AND f.region_sid = mr.old_sid(+)
		    AND f.original_factor_id = mof.old_factor_id(+);

	INSERT INTO csr.factor_history (factor_id, changed_dtm, user_sid, old_value, note)
		SELECT mf.new_factor_id, fh.changed_dtm, mu.new_sid, fh.old_value, fh.note
		  FROM csrimp.factor_history fh, csrimp.map_factor mf, csrimp.map_sid mu
		 WHERE fh.factor_id = mf.old_factor_id
		   AND fh.user_sid = mu.old_sid;
END;

PROCEDURE CreateAggregationPeriods
AS
BEGIN
	INSERT INTO csr.aggregation_period (aggregation_period_id, label, no_of_months)
		SELECT aggregation_period_id, label, no_of_months
		  FROM csrimp.aggregation_period;
END;

PROCEDURE CreateCustomerIndsRegions
AS
BEGIN
	CreateCustomerFields;
	CreateFileUploadOptions;
	CreateAggregationPeriods;
	CreateTranslations;
	CreatePeriodSets;
	CreateLookupTables;
	CreateReportingPeriods;
	CreateRagStatuses;
	CreateTagGroups;
	CreateAccuracyTypes;
	CreateCustomerAlertTypes;
	CreateMeasures;
	CreateRegionTrees;
	CreateBaselineConfigs;
	CreateIndicators;
END;

PROCEDURE CreateUsers
AS
	v_t_ignore_sids		aspen2.T_SPLIT_TABLE;
	v_new_ignore_sids	CLOB;
BEGIN
	INSERT INTO csr.csr_user (csr_user_sid, email, guid,
		full_name, user_name, friendly_name, info_xml, send_alerts, show_portal_help,
		donations_reports_filter_id, donations_browse_filter_id, hidden,
		phone_number, job_title, show_save_chart_warning, enable_aria, created_dtm,
		line_manager_sid, primary_region_sid, remove_roles_on_deactivation, user_ref,
		avatar, last_modified_dtm, last_logon_type_id, avatar_sha1,
		avatar_mime_type, avatar_last_modified_dtm, anonymised
		)
		SELECT mu.new_sid,
			   CASE WHEN m_obfuscate_email_addresses = 1 THEN
				   SUBSTR(REGEXP_REPLACE(cu.email, '(.*)\@(.*)', '\1'), 1, 256 - LENGTH('@credit360.com')) || '@credit360.com'
			   ELSE
				   cu.email
			   END,
			   cu.guid,
			   cu.full_name, cu.user_name, cu.friendly_name, cu.info_xml, cu.send_alerts, cu.show_portal_help,
			   cu.donations_reports_filter_id, cu.donations_browse_filter_id, cu.hidden,
			   cu.phone_number, cu.job_title, cu.show_save_chart_warning, cu.enable_aria, cu.created_dtm,
			   ml.new_sid, mp.new_sid, cu.remove_roles_on_deactivation, cu.user_ref,
			   cu.avatar, cu.last_modified_dtm, cu.last_logon_type_id, cu.avatar_sha1,
			   cu.avatar_mime_type, cu.avatar_last_modified_dtm, anonymised
		  FROM csrimp.csr_user cu, csrimp.map_sid mu, csrimp.map_sid ml, csrimp.map_sid mp
		 WHERE cu.csr_user_sid = mu.old_sid
		   AND cu.line_manager_sid = ml.old_sid(+)
		   AND cu.primary_region_sid = mp.old_sid(+);

	-- add all superadmins we didn't import for the new app
	INSERT INTO csr.csr_user (csr_user_sid, user_name, full_name, email, friendly_name, guid)
		SELECT s.csr_user_sid, s.user_name, s.full_name, s.email, s.friendly_name, s.guid
          FROM csr.superadmin s
         WHERE s.csr_user_sid NOT IN (
         		SELECT csr_user_sid
         		  FROM csr.csr_user
         		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'));

	-- add all imported start points
	INSERT INTO csr.ind_start_point (ind_sid, user_sid)
		SELECT mi.new_sid, mu.new_sid
		  FROM csrimp.map_sid mi, csrimp.map_sid mu, csrimp.ind_start_point isp
		 WHERE isp.user_sid = mu.old_sid
		   AND isp.ind_sid = mi.old_sid;

	INSERT INTO csr.region_start_point (region_sid, user_sid)
		SELECT mi.new_sid, mu.new_sid
		  FROM csrimp.map_sid mi, csrimp.map_sid mu, csrimp.region_start_point isp
		 WHERE isp.user_sid = mu.old_sid
		   AND isp.region_sid = mi.old_sid;

	-- fix customer fields that reference csr_user
	UPDATE csr.customer
	   SET self_reg_approver_sid = (
			SELECT ms.new_sid
			  FROM csrimp.map_sid ms, csrimp.customer c
			 WHERE c.self_reg_approver_sid = ms.old_sid)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO csr.user_measure_conversion (csr_user_sid, measure_sid, measure_conversion_id)
		SELECT mu.new_sid, mm.new_sid, mmc.new_measure_conversion_id
		  FROM csrimp.user_measure_conversion lumc, csrimp.map_sid mu,
		  	   csrimp.map_sid mm, csrimp.map_measure_conversion mmc
		 WHERE lumc.csr_user_sid = mu.old_sid
		   AND lumc.measure_sid = mm.old_sid
		   AND lumc.measure_conversion_id = mmc.old_measure_conversion_id(+);

	-- XXX: change guid?
	INSERT INTO csr.autocreate_user (guid, requested_dtm, user_name, approved_dtm,
		approved_by_user_sid, created_user_sid, activated_dtm, rejected_dtm,
		require_new_password, redirect_to_url)
		SELECT au.guid, au.requested_dtm, au.user_name, au.approved_dtm, mau.new_sid,
			   mcu.new_sid, au.activated_dtm, au.rejected_dtm,
			   au.require_new_password, au.redirect_to_url
		  FROM csrimp.autocreate_user au, csrimp.map_sid mau, csrimp.map_sid mcu
		 WHERE au.approved_by_user_sid = mau.old_sid(+)
		   AND au.created_user_sid = mcu.old_sid(+);

	INSERT INTO csr.region_owner (region_sid, user_sid)
		SELECT mr.new_sid, mu.new_sid
		  FROM csrimp.region_owner ro, csrimp.map_sid mr,
		  	   csrimp.map_sid mu
		 WHERE ro.region_sid = mr.old_sid
		   AND ro.user_sid = mu.old_sid;

	FOR r IN (
		SELECT mr.new_sid region_sid, srtc.sp_name, mrr.new_sid region_root_sid, srtc.tag_id, srtc.tag_group_ids,
				srtc.active_only, srtc.reduce_contention, srtc.apply_deleg_plans, srtc.ignore_sids, mu.new_sid user_sid, srtc.last_run_dtm
		  FROM csrimp.secondary_region_tree_ctrl srtc, csrimp.map_sid mr, csrimp.map_sid mu, csrimp.map_sid mrr
		 WHERE srtc.region_sid = mr.old_sid
		   AND srtc.user_sid = mu.old_sid
		   AND srtc.region_root_sid = mrr.old_sid(+)
	) LOOP		
		v_t_ignore_sids := aspen2.utils_pkg.SplitClob(r.ignore_sids, ',');
		
		SELECT LISTAGG(new_sid, ',') 
		 INTO v_new_ignore_sids
		 FROM TABLE(v_t_ignore_sids) t
		 JOIN csrimp.map_sid m ON t.item = m.old_sid;
		
		INSERT INTO csr.secondary_region_tree_ctrl
		(region_sid, sp_name, region_root_sid, tag_id, tag_group_ids, active_only, reduce_contention, apply_deleg_plans, ignore_sids, user_sid, last_run_dtm)
		VALUES
		(r.region_sid, r.sp_name, r.region_root_sid, r.tag_id, r.tag_group_ids, r.active_only, r.reduce_contention, r.apply_deleg_plans, v_new_ignore_sids, r.user_sid, r.last_run_dtm);
	END LOOP;

	INSERT INTO csr.secondary_region_tree_log
		(log_id, region_sid, user_sid, log_dtm, presync_tree, postsync_tree)
		SELECT srtl.log_id, mr.new_sid, mu.new_sid user_sid, srtl.log_dtm, srtl.presync_tree, srtl.postsync_tree
		  FROM csrimp.secondary_region_tree_log srtl, csrimp.map_sid mr, csrimp.map_sid mu
		 WHERE srtl.region_sid = mr.old_sid
		   AND srtl.user_sid = mu.old_sid;

	INSERT INTO csr.cookie_policy_consent (
		cookie_policy_consent_id,
		accepted,
		created_dtm,
		csr_user_sid
	   ) SELECT mcpc.new_cookie_policy_consent_id,
				cpc.accepted,
				cpc.created_dtm,
				ms.new_sid
		   FROM csrimp.cookie_policy_consent cpc,
				csrimp.map_cookie_policy_consen mcpc,
				csrimp.map_sid ms
		  WHERE cpc.cookie_policy_consent_id = mcpc.old_cookie_policy_consent_id
			AND cpc.csr_user_sid = ms.old_sid;
END;

PROCEDURE CreateRoles
AS
BEGIN
	INSERT INTO csr.role (role_sid, name, lookup_key, region_permission_set, is_metering, is_property_manager,
		is_delegation, is_supplier, is_hidden, is_system_managed)
		SELECT mr.new_sid, r.name, r.lookup_key, r.region_permission_set, r.is_metering, r.is_property_manager,
			   r.is_delegation, r.is_supplier, r.is_hidden, r.is_system_managed
		  FROM csrimp.role r, csrimp.map_sid mr
		 WHERE mr.old_sid = r.role_sid;

	INSERT INTO csr.region_role_member (user_sid, region_sid, role_sid, inherited_from_sid)
		SELECT /*+CARDINALITY(rrm, 1000000) CARDINALITY(mu, 10000) CARDINALITY(mreg, 10000)
				  CARDINALITY(mrol, 10000) CARDINALITY(minh, 10000)*/
			   mu.new_sid, mreg.new_sid, mrol.new_sid, minh.new_sid
		  FROM csrimp.region_role_member rrm, csrimp.map_sid mu, csrimp.map_sid mreg,
		  	   csrimp.map_sid mrol, csrimp.map_sid minh
		 WHERE rrm.user_sid = mu.old_sid
		   AND rrm.region_sid = mreg.old_sid
		   AND rrm.role_sid = mrol.old_sid
		   AND rrm.inherited_from_Sid = minh.old_sid;

    INSERT INTO csr.role_grant (role_sid, grant_role_sid)
        SELECT mr.new_sid, mg.new_sid
          FROM csrimp.role_grant rg, csrimp.map_sid mr, csrimp.map_sid mg
         WHERE rg.role_sid = mr.old_sid
           AND rg.grant_role_sid = mg.old_sid;
END;

PROCEDURE CreateFileUploads
AS
BEGIN
	-- note: this is ignoring file_upload.parent_sid because it's not always
	-- set to a sid that exists on live
	INSERT INTO csr.file_upload (file_upload_sid, filename, mime_type, parent_sid,
		data, sha1, last_modified_dtm)
		SELECT /*+CARDINALITY(so, 50000) CARDINALITY(fu, 1000) CARDINALITY(mfu, 50000)*/
			   mfu.new_sid, fu.filename, fu.mime_type, mso.new_sid,
			   fu.data, fu.sha1, fu.last_modified_dtm
		  FROM csrimp.file_upload fu, csrimp.map_sid mfu,
		  	   csrimp.securable_object so, csrimp.map_sid mso
		 WHERE fu.file_upload_sid = mfu.old_sid
		   AND fu.file_upload_sid = so.sid_id
		   AND so.parent_sid_id = mso.old_sid;
END;

PROCEDURE FixFormatXml(
	in_node							IN	dbms_xmldom.domnode
)
AS
	v_attribute						varchar2(100);
	v_node							dbms_xmldom.domnode := in_node;
	v_child							dbms_xmldom.domnode;
	v_id 							varchar2(100);
	v_new_id						csrimp.map_pending_ind.new_pending_ind_id%TYPE;
BEGIN
	WHILE NOT dbms_xmldom.isnull(v_node) LOOP
		IF dbms_xmldom.getnodetype(v_node) = dbms_xmldom.element_node THEN
			v_attribute := 'ind';
			v_id := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), v_attribute);
			IF v_id IS NULL THEN
				v_attribute := 'indId';
				v_id := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), v_attribute);
			END IF;
			IF v_id IS NOT NULL THEN
				BEGIN
					SELECT new_pending_ind_id
					  INTO v_new_id
					  FROM map_pending_ind
					 WHERE old_pending_ind_id = TO_NUMBER(v_id);
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001, 'The pending ind with id '||v_id||' was not found');
				END;
				--dbms_output.put_line('sid = '||v_sid||' -> '||v_new_sid);
				dbms_xmldom.setattribute(dbms_xmldom.makeelement(v_node), v_attribute, v_new_id);
			END IF;
			v_child := dbms_xmldom.getfirstchild(v_node);
			IF NOT dbms_xmldom.isnull(v_child) THEN
				FixFormatXml(v_child);
			END IF;
		END IF;
		v_node := dbms_xmldom.getnextsibling(v_node);
	END LOOP;
END;

PROCEDURE FixFormVersionXml(
	in_node   			IN dbms_xmldom.domnode
)
AS
	v_node							dbms_xmldom.domnode := in_node;
	v_child							dbms_xmldom.domnode;
	v_old_ref 						VARCHAR2(1000);
	v_new_ref 						VARCHAR2(1000);

BEGIN
	WHILE NOT dbms_xmldom.isnull(v_node) LOOP
		IF dbms_xmldom.getnodetype(v_node) = dbms_xmldom.element_node THEN
			IF dbms_xmldom.GETNODENAME(v_node) = 'table' THEN
				v_old_ref := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), 'name');
				IF v_old_ref IS NOT NULL THEN
					-- init
					v_new_ref := v_old_ref;

					-- check all user schemas
					FOR r IN (SELECT old_oracle_schema, new_oracle_schema FROM csrimp.map_cms_schema)
					LOOP
						-- replace uses extra qotes as in the xml from db so compare exact schema_name
						v_new_ref := REGEXP_REPLACE(v_new_ref, '"' || r.old_oracle_schema || '"', '"' || r.new_oracle_schema || '"',
							-- position (default)
							1,
							-- occurrence (first)
							1,
							-- case insensitive
							'i');
					END LOOP;

					IF v_old_ref != v_new_ref THEN
						dbms_xmldom.setattribute(dbms_xmldom.makeelement(v_node), 'name', v_new_ref);
					END IF;
				END IF;
			END IF;

			v_child := dbms_xmldom.getfirstchild(v_node);
			IF NOT dbms_xmldom.isnull(v_child) THEN
					FixFormVersionXml(v_child);
			END IF;
		END IF;
		v_node := dbms_xmldom.getnextsibling(v_node);
	END LOOP;
END;

PROCEDURE FixFormVersionTable
AS
	v_doc							dbms_xmldom.domdocument;
	v_xml							sys.xmltype;
BEGIN
	-- fix oracle_schema references in form_version table
	FOR s IN (
		SELECT form_sid, form_xml, form_version FROM cms.form_version WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		v_doc := dbms_xmldom.newdomdocument(s.form_xml);

		FixFormVersionXml(dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(v_doc)));

		v_xml := dbms_xmldom.getxmltype(v_doc);

		UPDATE cms.form_version
		   SET form_xml  = v_xml
		 WHERE form_sid = s.form_sid
		   AND form_version = s.form_version;

		dbms_xmldom.freedocument(v_doc);
	END LOOP;
END;

PROCEDURE ProcessPendingInds
AS
	v_doc							dbms_xmldom.domdocument;
	v_xml							sys.xmltype;
BEGIN
	INSERT INTO csr.pending_ind (pending_ind_id, pending_dataset_id, parent_ind_id, maps_to_ind_sid,
		link_to_ind_id, description, tolerance_type, pct_upper_tolerance, pct_lower_tolerance,
		val_mandatory, note_mandatory, file_upload_mandatory, measure_sid, pos, format_xml, element_type,
		read_only, dp, info_xml, default_val_number, default_val_string, lookup_key, aggregate,
		allow_file_upload)
		SELECT mpi.new_pending_ind_id, mpds.new_sid, mpp.new_pending_ind_id, mpmi.new_sid,
			   mpli.new_pending_ind_id, pi.description, pi.tolerance_type, pi.pct_upper_tolerance,
			   pi.pct_lower_tolerance, pi.val_mandatory, pi.note_mandatory, pi.file_upload_mandatory,
			   mm.new_sid, pi.pos, pi.format_xml, pi.element_type, pi.read_only, pi.dp, pi.info_xml,
			   pi.default_val_number, pi.default_val_string, pi.lookup_key, pi.aggregate,
			   pi.allow_file_upload
		  FROM csrimp.pending_ind pi,
		  	   csrimp.map_pending_ind mpi,
		  	   csrimp.map_sid mpds,
		  	   csrimp.map_pending_ind mpp,
		  	   csrimp.map_sid mpmi,
		  	   csrimp.map_pending_ind mpli,
		  	   csrimp.map_sid mm
		 WHERE pi.pending_ind_id = mpi.old_pending_ind_id
		   AND pi.pending_dataset_id = mpds.old_sid(+)
		   AND pi.parent_ind_id = mpp.old_pending_ind_id(+)
		   AND pi.maps_to_ind_sid = mpmi.old_sid(+)
		   AND pi.link_to_ind_id = mpli.old_pending_ind_id(+)
		   AND pi.measure_sid = mm.old_sid(+);

	-- fix up format xml now all the inds have been added
	FOR r IN (SELECT pi.pending_ind_id, pi.format_xml
				FROM csr.pending_ind pi, csrimp.map_pending_ind mpi
			   WHERE pi.pending_ind_id = mpi.new_pending_ind_id
			     AND NVL(dbms_lob.getlength(xmltype.getclobval(pi.format_xml)), 0) != 0) LOOP

		v_doc := dbms_xmldom.newdomdocument(r.format_xml);
		--dbms_output.put_line('fixing '||r.ind_sid);
		FixFormatXml(dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(v_doc)));
		v_xml := dbms_xmldom.getxmltype(v_doc);
		UPDATE csr.pending_ind
		   SET format_xml = v_xml
		 WHERE pending_ind_id = r.pending_ind_id;
		dbms_xmldom.freedocument(v_doc);
	END LOOP;

	INSERT INTO csr.pending_ind_accuracy_type (pending_ind_id, accuracy_type_id)
		SELECT mpi.new_pending_ind_id, mat.new_accuracy_type_id
		  FROM csrimp.pending_ind_accuracy_type piat, csrimp.map_accuracy_type mat,
		  	   csrimp.map_pending_ind mpi
		 WHERE piat.pending_ind_id = mpi.old_pending_ind_id
		   AND piat.accuracy_type_id = mat.old_accuracy_type_id;
END;

PROCEDURE ProcessPendingRegions
AS
BEGIN
	INSERT INTO csr.pending_region (pending_region_id, parent_region_id, pending_dataset_id,
		maps_to_region_sid, description, pos)
		SELECT mpr.new_pending_region_id, mpp.new_pending_region_id,
			   mpds.new_sid, mr.new_sid, pr.description, pr.pos
		  FROM csrimp.pending_region pr,
		  	   csrimp.map_pending_region mpr,
		  	   csrimp.map_pending_region mpp,
		  	   csrimp.map_sid mpds,
		  	   csrimp.map_sid mr
		 WHERE pr.pending_region_id = mpr.old_pending_region_id
		   AND pr.parent_region_id = mpp.old_pending_region_id(+)
		   AND pr.pending_dataset_id = mpds.old_sid
		   AND pr.maps_to_region_sid = mr.old_sid(+);
END;

PROCEDURE ProcessPendingPeriods
AS
BEGIN
	INSERT INTO csr.pending_period (pending_period_id, pending_dataset_id,
		start_dtm, end_dtm, label, default_due_dtm)
		SELECT mpp.new_pending_period_id, mpds.new_sid, pp.start_dtm,
			   pp.end_dtm, pp.label, pp.default_due_dtm
		  FROM csrimp.pending_period pp,
		  	   csrimp.map_pending_period mpp,
		  	   csrimp.map_sid mpds
		 WHERE pp.pending_period_id = mpp.old_pending_period_id
		   AND pp.pending_dataset_id = mpds.old_sid;
END;

PROCEDURE CreatePending
AS
BEGIN
	INSERT INTO csr.pending_dataset (pending_dataset_id, label, reporting_period_sid, helper_pkg)
		SELECT mpd.new_sid, pd.label, mrp.new_sid, MapCustomerSchema(pd.helper_pkg)
		  FROM csrimp.pending_dataset pd, csrimp.map_sid mpd, csrimp.map_sid mrp
		 WHERE pd.pending_dataset_id = mpd.old_sid
		   AND pd.reporting_period_sid = mrp.old_sid;

	ProcessPendingInds;
	ProcessPendingRegions;
	ProcessPendingPeriods;

	INSERT INTO csr.approval_step (approval_step_id, parent_step_id, pending_dataset_id,
		based_on_step_id, label, layout_type, max_sheet_value_count, working_day_offset_from_due)
		SELECT ma.new_sid, mp.new_sid, mpd.new_sid, mbs.new_sid, aps.label, aps.layout_type,
			   aps.max_sheet_value_count, aps.working_day_offset_from_due
		  FROM csrimp.approval_step aps, csrimp.map_sid ma, csrimp.map_sid mp, csrimp.map_sid mpd,
		  	   csrimp.map_sid mbs
		 WHERE aps.approval_step_id = ma.old_sid
		   AND aps.parent_step_id = mp.old_sid(+)
		   AND aps.pending_dataset_id = mpd.old_sid
		   AND aps.based_on_step_id = mbs.old_sid(+);

	INSERT INTO csr.approval_step_user (approval_step_id, user_sid, fallback_user_sid, read_only,
		is_lurker)
		SELECT maps.new_sid, mu.new_sid, mfu.new_sid, asu.read_only, asu.is_lurker
		  FROM csrimp.approval_step_user asu, csrimp.map_sid maps, csrimp.map_sid mu,
		  	   csrimp.map_sid mfu
		 WHERE asu.approval_step_id = maps.old_sid
		   AND asu.user_sid = mu.old_sid
		   AND asu.fallback_user_sid = mfu.old_sid(+);

	INSERT INTO csr.approval_step_ind (approval_step_id, pending_ind_id)
		SELECT maps.new_sid, mpi.new_pending_ind_id
		  FROM csrimp.approval_step_ind asi, csrimp.map_sid maps, csrimp.map_pending_ind mpi
		 WHERE mpi.old_pending_ind_id = asi.pending_ind_id
		   AND asi.approval_step_id = maps.old_sid;

	INSERT INTO csr.approval_step_region (approval_step_id, rolls_up_to_region_id, pending_region_id)
		SELECT maps.new_sid, mprr.new_pending_region_id, mpr.new_pending_region_id
		  FROM csrimp.approval_step_region asr, csrimp.map_sid maps,
		  	   csrimp.map_pending_region mprr, csrimp.map_pending_region mpr
		 WHERE asr.approval_step_id = maps.old_sid
		   AND mprr.old_pending_region_id = asr.rolls_up_to_region_id(+)
		   AND mpr.old_pending_region_id = asr.pending_region_id;

	INSERT INTO csr.approval_step_sheet (approval_step_id, sheet_key, label,
		pending_period_id, pending_ind_id, pending_region_id, submitted_value_count,
		submit_blocked, visible, due_dtm, reminder_dtm, approver_response_due_dtm)
		SELECT maps.new_approval_step_id, maps.new_sheet_key, aps.label,
			   mpp.new_pending_period_id, mpi.new_pending_ind_id, mpr.new_pending_region_id,
			   aps.submitted_value_count, aps.submit_blocked, aps.visible,
			   aps.due_dtm, aps.reminder_dtm, aps.approver_response_due_dtm
		  FROM csrimp.approval_step_sheet aps, csrimp.map_approval_step_sheet maps,
		  	   csrimp.map_pending_ind mpi, csrimp.map_pending_region mpr,
		  	   csrimp.map_pending_period mpp
		 WHERE aps.approval_step_id = maps.old_approval_step_id
		   AND aps.sheet_key = maps.old_sheet_key
		   AND aps.pending_ind_id = mpi.old_pending_ind_id(+)
		   AND aps.pending_region_id = mpr.old_pending_region_id(+)
		   AND aps.pending_period_id = mpp.old_pending_period_id(+);

	INSERT INTO csr.approval_step_sheet_log (approval_step_id, sheet_key, dtm,
		by_user_sid, up_or_down, note)
		SELECT maps.new_approval_step_id, maps.new_sheet_key, apsl.dtm,
			   mu.new_sid, apsl.up_or_down, apsl.note
		  FROM csrimp.approval_step_sheet_log apsl,
		  	   csrimp.map_approval_step_sheet maps,
		  	   csrimp.map_sid mu
		 WHERE apsl.approval_step_id = maps.old_approval_step_id
		   AND apsl.sheet_key = maps.old_sheet_key
		   AND apsl.by_user_sid = mu.old_sid;

	INSERT INTO csr.approval_step_role (approval_step_id, role_sid)
		SELECT maps.new_sid, mr.new_sid
		  FROM csrimp.approval_step_role asr,
		  	   csrimp.map_sid maps,
		  	   csrimp.map_sid mr
		 WHERE asr.approval_step_id = maps.old_sid
		   AND asr.role_sid = mr.old_Sid;

	-- do all the values (now we've done all the pending datasets)
	INSERT INTO csr.pending_val (pending_val_id, pending_ind_id, pending_region_id, pending_period_id,
		 approval_step_id, val_number, val_string, from_val_number, from_measure_conversion_id,
		 note, action, merged_state)
		SELECT mpv.new_pending_val_id, mpi.new_pending_ind_id, mpr.new_pending_region_id,
			   mpp.new_pending_period_id, maps.new_sid, pv.val_number, pv.val_string,
			   pv.from_val_number, mmc.new_measure_conversion_id, pv.note, pv.action, pv.merged_state
		  FROM csrimp.map_pending_val mpv, csrimp.pending_val pv, csrimp.map_sid maps,
		  	   csrimp.map_measure_conversion mmc, csrimp.map_pending_period mpp,
		  	   csrimp.map_pending_ind mpi, csrimp.map_pending_region mpr
	     WHERE pv.pending_val_id = mpv.old_pending_val_id
	       AND pv.approval_step_id = maps.old_sid(+)
	       AND pv.from_measure_conversion_id = mmc.new_measure_conversion_id(+)
	       AND pv.pending_ind_id = mpi.old_pending_ind_id
	       AND pv.pending_region_id = mpr.old_pending_region_id
	       AND pv.pending_period_id = mpp.old_pending_period_id;

	INSERT INTO csr.pending_val_log (pending_val_log_id, pending_val_id, set_dtm, set_by_user_sid, description,
								     param_1, param_2, param_3)
		SELECT csr.pending_val_log_id_seq.nextval, mpv.new_pending_val_id, pvl.set_dtm, mu.new_sid,
			   pvl.description, pvl.param_1, pvl.param_2, pvl.param_3
		  FROM csrimp.pending_val_log pvl, csrimp.map_pending_val mpv, csrimp.map_sid mu
		 WHERE pvl.pending_val_id = mpv.old_pending_val_id
		   AND pvl.set_by_user_sid = mu.old_sid;

	INSERT INTO csr.pending_val_variance (pending_val_id, compared_with_start_dtm, compared_with_end_dtm,
										  variance, explanation)
		SELECT mpv.new_pending_val_id, pvv.compared_with_start_dtm, pvv.compared_with_end_dtm,
			   pvv.variance, pvv.explanation
		  FROM csrimp.pending_val_variance pvv, csrimp.map_pending_val mpv
		 WHERE pvv.pending_val_id = mpv.old_pending_val_id;

	INSERT INTO csr.pending_val_accuracy_type_opt (pending_val_id, accuracy_type_option_id, pct)
		SELECT mpv.new_pending_val_id, mato.new_accuracy_type_option_id, pvato.pct
		  FROM csrimp.pending_val_accuracy_type_opt pvato,
		       csrimp.map_pending_val mpv,
		       csrimp.map_accuracy_type_option mato
		 WHERE pvato.pending_val_id = mpv.old_pending_val_id
		   AND pvato.accuracy_type_option_id = mato.old_accuracy_type_option_id;
END;

-- Fixes up the layout of a particular DELEGATION_LAYOUT table cell.
FUNCTION FixLayoutXmlCell(
	in_layout_xml				IN xmltype,
	in_old_sid					IN csrimp.map_sid.old_sid%TYPE,
	in_attribute_name			IN varchar2
)
RETURN xmltype
AS
	v_element_path				varchar2(512);
	v_result_xml				xmltype;
BEGIN
	v_element_path := '//td[@' || in_attribute_name || '="' || in_old_sid || '"]/@' || in_attribute_name;

	SELECT UPDATEXML(in_layout_xml, v_element_path, new_sid)
	  INTO v_result_xml
	  FROM csrimp.map_sid
	 WHERE old_sid = in_old_sid;

	RETURN v_result_xml;
END;

-- Fixes up the SID references in a DELEGATION_LAYOUT.
PROCEDURE FixLayoutXml(
	in_layout_id					IN security_pkg.T_SID_ID
)
AS
	v_layout_xml					xmltype;
	v_element_path					varchar(255);
BEGIN
	-- Retreive the layout xml
	SELECT layout_xhtml
	  INTO v_layout_xml
	  FROM csr.delegation_layout
	 WHERE layout_id = in_layout_id;

	-- Loop over each <td> or <th> that have indicator or region attributes, extracting the
	-- SIDs that are not $expressions.
	FOR rec IN (
		SELECT ind_sid, region_sid
		  FROM XMLTABLE(
			  '//td[@indicator or @region] | //th[@indicator or @region]'
			   PASSING v_layout_xml
			   COLUMNS
				   ind_sid number PATH '@indicator[not(starts-with(., "$"))]',
				   region_sid number PATH '@region[not(starts-with(., "$"))]'
		  ) sids
	)
	LOOP
		-- Replace the attributes values with the remapped SID
		IF rec.ind_sid IS NOT NULL THEN
			v_layout_xml := FixLayoutXmlCell(v_layout_xml, rec.ind_sid, 'indicator');
		END IF;

		IF rec.region_sid IS NOT NULL THEN
			v_layout_xml := FixLayoutXmlCell(v_layout_xml, rec.region_sid, 'region');
		END IF;
	END LOOP;

	-- Write back the updated XML
	UPDATE csr.delegation_layout
	   SET layout_xhtml = v_layout_xml
	 WHERE layout_id = in_layout_id;
END;

PROCEDURE FixSectionXml(
	in_delegation_sid				IN	csr.delegation.delegation_sid%TYPE,
	in_node							IN	dbms_xmldom.domnode
)
AS
	v_attribute						varchar2(100);
	v_node							dbms_xmldom.domnode := in_node;
	v_old_node						dbms_xmldom.domnode;
	v_next_node						dbms_xmldom.domnode;
	v_child							dbms_xmldom.domnode;
	v_sid 							varchar2(100);
	v_new_sid						csrimp.map_sid.new_sid%TYPE;
	v_key							csr.delegation_ind.section_key%TYPE;
BEGIN
	WHILE NOT dbms_xmldom.isnull(v_node) LOOP
		v_next_node := dbms_xmldom.getnextsibling(v_node);
		IF dbms_xmldom.getnodetype(v_node) = dbms_xmldom.element_node THEN
			IF dbms_xmldom.getnodename(v_node) = 'ind' THEN
				v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), 'sid');
				IF v_sid IS NOT NULL THEN
					BEGIN
						SELECT new_sid
						  INTO v_new_sid
						  FROM csrimp.map_sid
						 WHERE old_sid = TO_NUMBER(v_sid);
						dbms_xmldom.setattribute(dbms_xmldom.makeelement(v_node), 'sid', v_new_sid);

						v_key := dbms_xmldom.getattribute(dbms_xmldom.makeelement(dbms_xmldom.getparentnode(v_node)), 'key');

						UPDATE csr.delegation_ind
			 			   SET section_key = v_key
				    	 WHERE delegation_sid = in_delegation_sid
				    	   AND ind_sid = v_new_sid;

					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							-- can't find sid, so delete node
							v_old_node := dbms_xmldom.removechild(dbms_xmldom.getparentnode(v_node), v_node);
					END;
				END IF;
			END IF;
			v_child := dbms_xmldom.getfirstchild(v_node);
			IF NOT dbms_xmldom.isnull(v_child) THEN
				FixSectionXml(in_delegation_sid, v_child);
			END IF;
		END IF;
		v_node := v_next_node;
	END LOOP;
END;

PROCEDURE FixSectionXml(
	in_delegation_sid					IN	csr.delegation.delegation_sid%TYPE,
	in_section_xml						IN	csr.delegation.section_xml%TYPE
)
AS
	v_section_doc					dbms_xmldom.domdocument;
	v_section_xml					csr.delegation.section_xml%TYPE;
BEGIN
	IF NVL(LENGTH(in_section_xml), 0) = 0 THEN
		RETURN;
	END IF;
	v_section_doc := dbms_xmldom.newdomdocument(in_section_xml);
	FixSectionXml(in_delegation_sid, dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(v_section_doc)));

	dbms_lob.createTemporary(v_section_xml, TRUE, dbms_lob.call);
	dbms_xmldom.writetoclob(dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(v_section_doc)), v_section_xml);

	UPDATE csr.delegation
	   SET section_xml = v_section_xml
 	 WHERE delegation_sid = in_delegation_sid;

	dbms_xmldom.freedocument(v_section_doc);
END;

PROCEDURE CreateVarExpls
AS
BEGIN
	INSERT INTO csr.var_expl_group (var_expl_group_id, label)
		SELECT mvg.new_var_expl_group_id, vg.label
		  FROM csrimp.var_expl_group vg, csrimp.map_var_expl_group mvg
		 WHERE vg.var_expl_group_id = mvg.old_var_expl_group_id;

	INSERT INTO csr.var_expl (var_expl_id, var_expl_group_id, label, requires_note, pos, hidden)
		SELECT mve.new_var_expl_id, mvg.new_var_expl_group_id, ve.label, ve.requires_note, ve.pos, ve.hidden
		  FROM csrimp.var_expl ve, csrimp.map_var_expl_group mvg, csrimp.map_var_expl mve
		 WHERE ve.var_expl_id = mve.old_var_expl_id
		   AND ve.var_expl_group_id = mvg.old_var_expl_group_id;
END;

PROCEDURE CreateDelegations
AS
BEGIN
	INSERT INTO csr.delegation_date_schedule(delegation_date_schedule_id, start_dtm, end_dtm)
		SELECT mdds.new_deleg_date_schedule_id, dds.start_dtm, dds.end_dtm
		  FROM csrimp.delegation_date_schedule dds, csrimp.map_deleg_date_schedule mdds
		 WHERE dds.delegation_date_schedule_id = mdds.old_deleg_date_schedule_id;

	INSERT INTO csr.sheet_date_schedule (delegation_date_schedule_id, start_dtm, creation_dtm, submission_dtm, reminder_dtm)
		SELECT mdds.new_deleg_date_schedule_id, sds.start_dtm, sds.creation_dtm, sds.submission_dtm, sds.reminder_dtm
		  FROM csrimp.sheet_date_schedule sds, csrimp.map_deleg_date_schedule mdds
		 WHERE sds.delegation_date_schedule_id = mdds.old_deleg_date_schedule_id;

	-- delegation layouts
	INSERT INTO csr.delegation_layout (layout_id, layout_xhtml, name, valid)
		SELECT mlay.new_delegation_layout_id, dl.layout_xhtml, 'test', dl.valid
		  FROM csrimp.delegation_layout dl, csrimp.map_delegation_layout mlay
		 WHERE dl.layout_id = mlay.old_delegation_layout_id;

	FOR r IN (SELECT mlay.new_delegation_layout_id layout_id
		        FROM csrimp.delegation_layout dl, csrimp.map_delegation_layout mlay
		       WHERE dl.layout_id = mlay.old_delegation_layout_id)
	LOOP
		FixLayoutXml(r.layout_id);
	END LOOP;

	INSERT INTO csr.delegation (delegation_sid, parent_sid, name, master_delegation_sid, created_by_sid, schedule_xml,
		note, period_set_id, period_interval_id, group_by, allocate_users_to, start_dtm, end_dtm, reminder_offset,
		is_note_mandatory, section_xml, editing_url, fully_delegated, grid_xml, is_flag_mandatory, show_aggregate,
		hide_sheet_period, delegation_date_schedule_id, submission_offset, layout_id, tag_visibility_matrix_group_id,
		allow_multi_period)
		SELECT mdel.new_sid, mpar.new_sid, d.name, mmas.new_sid, mcrea.new_sid, d.schedule_xml,
			   d.note, d.period_set_id, d.period_interval_id, d.group_by, d.allocate_users_to, d.start_dtm, d.end_dtm,
			   d.reminder_offset, d.is_note_mandatory, d.section_xml, d.editing_url, d.fully_delegated, d.grid_xml,
			   d.is_flag_mandatory, d.show_aggregate, d.hide_sheet_period,
			   mdds.new_deleg_date_schedule_id, d.submission_offset, mlay.new_delegation_layout_id,
			   mtg.new_tag_group_id, d.allow_multi_period
		  FROM csrimp.delegation d, csrimp.map_sid mdel, csrimp.map_sid mpar, csrimp.map_sid mmas,
		  	   csrimp.map_sid mcrea, csrimp.map_deleg_date_schedule mdds, csrimp.map_delegation_layout mlay,
			   csrimp.map_tag_group mtg
		 WHERE d.delegation_sid = mdel.old_sid
		   AND d.parent_sid = mpar.old_sid(+)
		   AND d.master_delegation_sid = mmas.old_sid(+)
		   AND d.created_by_sid = mcrea.old_sid
		   AND d.delegation_date_schedule_id = mdds.old_deleg_date_schedule_id(+)
		   AND d.layout_id = mlay.old_delegation_layout_id(+)
		   AND d.tag_visibility_matrix_group_id = mtg.old_tag_group_id(+);

	INSERT INTO csr.delegation_description (delegation_sid, lang, description, last_changed_dtm)
		SELECT mdel.new_sid, dd.lang, dd.description, dd.last_changed_dtm
		  FROM csrimp.delegation_description dd, csrimp.map_sid mdel
		 WHERE dd.delegation_sid = mdel.old_sid;

    INSERT INTO csr.delegation_policy (delegation_sid, submit_confirmation_text)
        SELECT mdel.new_sid, dp.submit_confirmation_text
          FROM csrimp.delegation_policy dp
          JOIN csrimp.map_sid mdel ON mdel.old_sid = dp.delegation_sid;

	-- fetch indicator info
	INSERT INTO csr.delegation_ind
        (delegation_sid, ind_sid, mandatory, pos, section_key, var_expl_group_id, visibility, css_class, meta_role, allowed_na)
		SELECT mdel.new_sid, mi.new_sid, di.mandatory, di.pos, di.section_key, mvg.new_var_expl_group_id, di.visibility,
               di.css_class, di.meta_role, di.allowed_na
		  FROM csrimp.map_sid mi, csrimp.delegation_ind di, csrimp.map_var_expl_group mvg, csrimp.map_sid mdel
	     WHERE di.ind_sid = mi.old_sid
	       AND di.delegation_sid = mdel.old_sid
		   AND di.var_expl_group_id = mvg.old_var_expl_group_id(+);

	INSERT INTO csr.delegation_ind_description (delegation_sid, ind_sid, lang, description)
		SELECT mdel.new_sid, mind.new_sid, did.lang, did.description
		  FROM csrimp.map_sid mdel, csrimp.map_sid mind, csrimp.delegation_ind_description did
	     WHERE did.ind_sid = mind.old_sid
		   AND did.delegation_sid = mdel.old_sid;

	FOR r in (SELECT mdel.new_sid delegation_sid, d.section_xml
				FROM csrimp.delegation d, csrimp.map_sid mdel
			   WHERE mdel.old_sid = d.delegation_sid) LOOP
		-- now parse Xml in section Xml
		FixSectionXml(r.delegation_sid, r.section_xml);
	END LOOP;

	-- fetch region info
	INSERT INTO csr.delegation_region (delegation_sid, region_sid, pos, mandatory, aggregate_to_region_sid, visibility,
			allowed_na, hide_after_dtm, hide_inclusive)
		SELECT mdel.new_sid, mreg.new_sid, dr.pos, dr.mandatory, magg.new_sid, dr.visibility,
		       dr.allowed_na, dr.hide_after_dtm, dr.hide_inclusive
		  FROM csrimp.delegation_region dr, csrimp.map_sid mdel, csrimp.map_sid mreg, csrimp.map_sid magg
		 WHERE dr.region_sid = mreg.old_sid
		   AND dr.aggregate_to_region_sid = magg.old_sid
		   AND dr.delegation_sid = mdel.old_sid;

	INSERT INTO csr.delegation_region_description (delegation_sid, region_sid, lang, description)
		SELECT mdel.new_sid, mreg.new_sid, drd.lang, drd.description
		  FROM csrimp.delegation_region_description drd, csrimp.map_sid mreg, csrimp.map_sid mdel
		 WHERE drd.region_sid = mreg.old_sid
		   AND drd.delegation_sid = mdel.old_sid
		   AND drd.lang IN (SELECT lang FROM aspen2.lang);

	-- TODO: needs to update the schema in the aggregation_xml where it's wired in
	INSERT INTO csr.delegation_grid (ind_sid, name, path, form_sid, helper_pkg, aggregation_xml, variance_validation_sp)
		SELECT mind.new_sid, dg.name, dg.path, mf.new_sid, dg.helper_pkg, dg.aggregation_xml, dg.variance_validation_sp
		  FROM csrimp.delegation_grid dg
		  JOIN csrimp.map_sid mind ON dg.ind_sid = mind.old_sid
	 LEFT JOIN csrimp.map_sid mf ON dg.form_sid = mf.old_sid;

	INSERT INTO csr.delegation_grid_aggregate_ind (ind_sid, aggregate_to_ind_sid)
		SELECT mind.new_sid, magg.new_sid
		  FROM csrimp.delegation_grid_aggregate_ind dgai, csrimp.map_sid mind, csrimp.map_sid magg
		 WHERE dgai.ind_sid = mind.old_sid
		   AND dgai.aggregate_to_ind_sid = magg.old_sid;

	INSERT INTO csr.delegation_user (delegation_sid, user_sid, deleg_permission_set, inherited_from_sid)
		SELECT mdel.new_sid, mu.new_sid, du.deleg_permission_set, minh.new_sid
		  FROM csrimp.delegation_user du, csrimp.map_sid mdel, csrimp.map_sid mu, csrimp.map_sid minh
		 WHERE du.delegation_sid = mdel.old_sid
		   AND du.user_sid = mu.old_sid
		   AND du.inherited_from_sid = minh.old_sid;

	INSERT INTO csr.delegation_role (delegation_sid, role_sid, is_read_only, inherited_from_sid, deleg_permission_set)
		SELECT mdel.new_sid, mrol.new_sid, dr.is_read_only, minh.new_sid, dr.deleg_permission_set
		  FROM csrimp.delegation_role dr, csrimp.map_sid mdel, csrimp.map_sid mrol, csrimp.map_sid minh
		 WHERE dr.delegation_sid = mdel.old_sid
		   AND dr.role_sid = mrol.old_sid
		   AND dr.inherited_from_sid = minh.old_sid;

	-- sort out the conditions -- these are all at top level so no need to put this into createsubdelegations
	INSERT INTO csr.delegation_ind_tag_list (delegation_sid, tag)
		SELECT md.new_sid, ditl.tag
		  FROM csrimp.delegation_ind_tag_list ditl, csrimp.map_sid md
		 WHERE ditl.delegation_sid = md.old_sid;

	INSERT INTO csr.delegation_ind_tag (delegation_sid, ind_sid, tag)
		SELECT md.new_sid, mi.new_sid, tag
		  FROM csrimp.delegation_ind_tag dit, csrimp.map_sid md, csrimp.map_sid mi
		 WHERE dit.delegation_sid = md.old_sid
		   AND dit.ind_sid = mi.old_sid;

	INSERT INTO csr.delegation_ind_cond (delegation_sid, ind_sid, delegation_ind_cond_id, expr)
		SELECT /*+CARDINALITY(dic, 50000) CARDINALITY(mdic, 50000)*/
			   md.new_sid, mi.new_sid, mdic.new_delegation_ind_cond_id, expr
		  FROM csrimp.delegation_ind_cond dic, csrimp.map_delegation_ind_cond mdic,
		  	   csrimp.map_sid md, csrimp.map_sid mi
		 WHERE dic.delegation_sid = md.old_sid
		   AND dic.ind_sid = mi.old_sid
		   AND dic.delegation_ind_cond_id = mdic.old_delegation_ind_cond_id;

	INSERT INTO csr.delegation_ind_cond_action (delegation_sid, ind_sid, delegation_ind_cond_id, action, tag)
		SELECT /*+CARDINALITY(dica, 50000) CARDINALITY(mdica, 50000)*/
			   md.new_sid, mi.new_sid, mdica.new_delegation_ind_cond_id, dica.action, dica.tag
		  FROM csrimp.delegation_ind_cond_action dica, csrimp.map_sid md, csrimp.map_sid mi,
		  	   csrimp.map_delegation_ind_cond mdica
		 WHERE dica.delegation_ind_cond_id = mdica.old_delegation_ind_cond_id
		   AND dica.delegation_sid = md.old_sid
		   AND dica.ind_sid = mi.old_sid;

	-- import form_expr and groups
	INSERT INTO csr.form_expr (form_expr_id, delegation_sid, description, expr)
		SELECT /*+CARDINALITY(fe, 50000) CARDINALITY(mfe, 50000)*/
			   mfe.new_form_expr_id, md.new_sid, fe.description, fe.expr
		  FROM csrimp.form_expr fe, csrimp.map_sid md, csrimp.map_form_expr mfe
		 WHERE fe.form_expr_id = mfe.old_form_expr_id
		   AND fe.delegation_sid = md.old_sid;

	INSERT INTO csr.deleg_ind_form_expr (delegation_sid, ind_sid, form_expr_id)
		SELECT /*+CARDINALITY(dife, 50000) CARDINALITY(mfe, 50000)*/
			   md.new_sid, mi.new_sid, mfe.new_form_expr_id
		  FROM csrimp.deleg_ind_form_expr dife, csrimp.map_sid md, csrimp.map_sid mi,
		  	   csrimp.map_form_expr mfe
		 WHERE dife.form_expr_id = mfe.old_form_expr_id
		   AND dife.delegation_sid = md.old_sid
		   AND dife.ind_sid = mi.old_sid;

	INSERT INTO csr.deleg_ind_group (deleg_ind_group_id, delegation_sid, title, start_collapsed)
		SELECT /*+CARDINALITY(dig, 50000) CARDINALITY(mdig, 50000)*/
			   mdig.new_deleg_ind_group_id, md.new_sid, dig.title, dig.start_collapsed
		  FROM csrimp.deleg_ind_group dig, csrimp.map_sid md, csrimp.map_deleg_ind_group mdig
		 WHERE dig.deleg_ind_group_id = mdig.old_deleg_ind_group_id
		   AND dig.delegation_sid = md.old_sid;

	INSERT INTO csr.deleg_ind_group_member (delegation_sid, ind_sid, deleg_ind_group_id)
		SELECT /*+CARDINALITY(didig, 50000) CARDINALITY(mdig, 50000)*/
			   md.new_sid, mi.new_sid, mdig.new_deleg_ind_group_id
		  FROM csrimp.deleg_ind_group_member didig, csrimp.map_deleg_ind_group mdig,
		  	   csrimp.map_sid md, csrimp.map_sid mi
		 WHERE didig.deleg_ind_group_id = mdig.old_deleg_ind_group_id
		   AND didig.delegation_sid = md.old_sid
		   AND didig.ind_sid = mi.old_sid;

	INSERT INTO csr.deleg_grid_variance (id, root_delegation_sid, region_sid, start_dtm, end_dtm,
		grid_ind_sid, variance, explanation, active, label, curr_value, prev_value)
		SELECT id, mrd.new_sid, mr.new_sid, start_dtm, end_dtm, mgi.new_sid, variance,
			   explanation, active, label, curr_value, prev_value
		  FROM csrimp.deleg_grid_variance dgv, csrimp.map_sid mrd, csrimp.map_sid mr,
		  	   csrimp.map_sid mgi
		 WHERE dgv.root_delegation_sid = mrd.old_sid
		   AND dgv.region_sid = mr.old_sid
		   AND dgv.grid_ind_sid = mgi.old_sid;

	FixFormExprs;

	-- fix up delegation plans
	INSERT INTO csr.master_deleg (delegation_sid)
		SELECT mdel.new_sid
		  FROM csrimp.master_deleg md, csrimp.map_sid mdel
		 WHERE md.delegation_sid = mdel.old_sid;

	INSERT INTO csr.deleg_plan (deleg_plan_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id,
		reminder_offset, schedule_xml, name_template, active, notes, dynamic, last_applied_dtm, last_applied_dynamic)
		SELECT mdp.new_sid, dp.name, dp.start_dtm, dp.end_dtm, dp.period_set_id, dp.period_interval_id,
			   dp.reminder_offset, dp.schedule_xml, dp.name_template, dp.active, dp.notes, dp.dynamic, dp.last_applied_dtm, dp.last_applied_dynamic
		  FROM csrimp.map_sid mdp, csrimp.deleg_plan dp
		 WHERE dp.deleg_plan_sid = mdp.old_sid;

	INSERT INTO csr.deleg_plan_role (deleg_plan_sid, role_sid, pos)
		SELECT mdp.new_sid, mg.new_sid, dpr.pos
		  FROM csrimp.deleg_plan_role dpr, csrimp.map_sid mdp, csrimp.map_sid mg
		 WHERE dpr.role_sid = mg.old_sid
		   AND dpr.deleg_plan_sid = mdp.old_sid;

	INSERT INTO csr.deleg_plan_region (deleg_plan_sid, region_sid)
		SELECT mdp.new_sid, mr.new_sid
		  FROM csrimp.deleg_plan_region dpr, csrimp.map_sid mr, csrimp.map_sid mdp
		 WHERE dpr.region_sid = mr.old_sid
		   AND dpr.deleg_plan_Sid = mdp.old_sid;

	-- now insert all the mappings
	INSERT INTO csr.deleg_plan_col_deleg (deleg_plan_col_deleg_id, delegation_sid)
		SELECT mdpcd.new_deleg_plan_col_deleg_id, md.new_sid
		  FROM csrimp.deleg_plan_col_deleg dpcd, csrimp.map_deleg_plan_col_deleg mdpcd,
		  	   csrimp.map_sid md
		 WHERE dpcd.deleg_plan_col_deleg_id = mdpcd.old_deleg_plan_col_deleg_id
		   AND dpcd.delegation_sid = md.old_sid;

	INSERT INTO csr.deleg_plan_col (deleg_plan_sid, deleg_plan_col_id, is_hidden, deleg_plan_col_deleg_id, qs_campaign_sid)
		SELECT /*+CARDINALITY(dpc, 50000) CARDINALITY(mdpc, 50000) CARDINALITY(mdpcd, 50000)*/
			   md.new_sid, mdpc.new_deleg_plan_col_id, dpc.is_hidden, mdpcd.new_deleg_plan_col_deleg_id, mqs.new_sid
		  FROM csrimp.map_sid md, csrimp.deleg_plan_col dpc, csrimp.map_deleg_plan_col mdpc,
		       csrimp.map_deleg_plan_col_deleg mdpcd, csrimp.map_sid mqs
		 WHERE dpc.deleg_plan_col_id = mdpc.old_deleg_plan_col_id
		   AND dpc.deleg_plan_col_deleg_id = mdpcd.old_deleg_plan_col_deleg_id
		   AND dpc.qs_campaign_sid = mqs.old_sid(+)
		   AND dpc.deleg_plan_sid = md.old_sid(+);

   	INSERT INTO csr.deleg_plan_col_survey (deleg_plan_col_survey_id, survey_sid)
		SELECT mdp.new_deleg_plan_col_survey_id, ms.new_sid
		  FROM csrimp.deleg_plan_col_survey dpc, csrimp.map_deleg_plan_col_survey mdp,
		  	   csrimp.map_sid ms
		 WHERE dpc.deleg_plan_col_survey_id = mdp.old_deleg_plan_col_survey_id
		   AND dpc.survey_sid = ms.old_sid;

	INSERT INTO campaigns.campaign_region (campaign_sid, region_sid, has_manual_amends, pending_deletion, region_selection, tag_id)
		SELECT mqs.new_sid, mr.new_sid, cr.has_manual_amends,
			   cr.pending_deletion, cr.region_selection, mt.new_tag_id
		  FROM csrimp.campaign_region cr, csrimp.map_sid mr, csrimp.map_tag mt,
			   csrimp.deleg_plan_col dpc, csrimp.map_sid mqs
		 WHERE cr.region_sid = mr.old_sid
		   AND dpc.qs_campaign_sid = mqs.old_sid
		   AND cr.tag_id = mt.old_tag_id(+);
		   
	INSERT INTO csr.deleg_plan_deleg_region (deleg_plan_col_deleg_id, region_sid, pending_deletion,
		region_selection, region_collation, tag_id, region_type)
		SELECT mdpcd.new_deleg_plan_col_deleg_id, mr.new_sid, dpdr.pending_deletion,
			   dpdr.region_selection, dpdr.region_collation, mt.new_tag_id, dpdr.region_type
		  FROM csrimp.deleg_plan_deleg_region dpdr, csrimp.map_deleg_plan_col_deleg mdpcd,
		  	   csrimp.map_sid mr, csrimp.map_tag mt
		 WHERE dpdr.deleg_plan_col_deleg_id = mdpcd.old_deleg_plan_col_deleg_id
		   AND dpdr.tag_id = mt.old_tag_id(+)
		   AND dpdr.region_sid = mr.old_sid;

	INSERT INTO csr.deleg_plan_deleg_region_deleg (deleg_plan_col_deleg_id, region_sid, applied_to_region_sid, maps_to_root_deleg_sid, has_manual_amends)
		SELECT /*+ALL_ROWS CARDINALITY(dpdrd, 1000) CARDINALITY(mr, 10000) CARDINALITY(mdpcd, 1000) CARDINALITY(mar, 10000) CARDINALITY(md, 10000)*/
			   mdpcd.new_deleg_plan_col_deleg_id, mr.new_sid, mar.new_sid, md.new_sid, dpdrd.has_manual_amends
		  FROM csrimp.deleg_plan_deleg_region_deleg dpdrd, csrimp.map_deleg_plan_col_deleg mdpcd,
		  	   csrimp.map_sid mr, csrimp.map_sid mar, csrimp.map_sid md
		 WHERE dpdrd.deleg_plan_col_deleg_id = mdpcd.old_deleg_plan_col_deleg_id
		   AND dpdrd.region_sid = mr.old_sid
		   AND dpdrd.applied_to_region_sid = mar.old_sid
		   AND dpdrd.maps_to_root_deleg_sid = md.old_sid;

	INSERT INTO csr.deleg_plan_date_schedule (deleg_plan_sid, role_sid, deleg_plan_col_id, schedule_xml, reminder_offset, delegation_date_schedule_id)
		SELECT mdp.new_sid, mg.new_sid, mdpc.new_deleg_plan_col_id, dpds.schedule_xml, dpds.reminder_offset, mdds.new_deleg_date_schedule_id
		  FROM csrimp.deleg_plan_date_schedule dpds, csrimp.map_sid mdp, csrimp.map_sid mg, csrimp.map_deleg_plan_col mdpc, csrimp.map_deleg_date_schedule mdds
		 WHERE dpds.deleg_plan_sid = mdp.old_sid
		   AND dpds.role_sid = mg.old_sid(+)
		   AND dpds.deleg_plan_col_id = mdpc.old_deleg_plan_col_id(+)
		   AND dpds.delegation_date_schedule_id = mdds.old_deleg_date_schedule_id(+);

	INSERT INTO csr.deleg_meta_role_ind_selection (delegation_sid, ind_sid,
		lang, description)
		SELECT md.new_sid, mi.new_sid, dmr.lang, dmr.description
		  FROM csrimp.deleg_meta_role_ind_selection dmr, csrimp.map_sid md,
		  	   csrimp.map_sid mi
		 WHERE dmr.delegation_sid = md.old_sid
		   AND dmr.ind_sid = mi.old_sid;

	INSERT INTO csr.delegation_comment (delegation_sid, start_dtm, end_dtm, postit_id)
		SELECT md.new_sid, dc.start_dtm, dc.end_dtm, mp.new_postit_id
		  FROM csrimp.delegation_comment dc, csrimp.map_sid md, csrimp.map_postit mp
		 WHERE dc.delegation_sid = md.old_sid
		   AND dc.postit_id = mp.old_postit_id;

	INSERT INTO csr.delegation_plugin (ind_sid, name, js_class_type, js_include,
		helper_pkg)
		SELECT mi.new_sid, dp.name, dp.js_class_type, dp.js_include, dp.helper_pkg
		  FROM csrimp.delegation_plugin dp, csrimp.map_sid mi
		 WHERE dp.ind_sid = mi.old_sid;

	INSERT INTO csr.delegation_tag (delegation_sid, tag_id)
		SELECT md.new_sid, mt.new_tag_id
		  FROM csrimp.delegation_tag dt, csrimp.map_sid md, csrimp.map_tag mt
		 WHERE dt.delegation_sid = md.old_sid
		   AND dt.tag_id = mt.old_tag_id;

	INSERT INTO csr.user_cover (user_cover_id, user_giving_cover_sid,
		user_being_covered_sid, start_dtm, end_dtm, cover_terminated,
		alert_sent_dtm)
		SELECT /*+ALL_ROWS CARDINALITY(uc, 1000) CARDINALITY(muc, 1000) CARDINALITY(mugc, 10000) CARDINALITY(mubc, 10000)*/
			   muc.new_user_cover_id, mugc.new_sid, mubc.new_sid,
			   uc.start_dtm, uc.end_dtm, uc.cover_terminated,
			   uc.alert_sent_dtm
		  FROM csrimp.user_cover uc, csrimp.map_user_cover muc,
		  	   csrimp.map_sid mugc, csrimp.map_sid mubc
		 WHERE uc.user_cover_id = muc.old_user_cover_id
		   AND uc.user_giving_cover_sid = mugc.old_sid
		   AND uc.user_being_covered_Sid = mubc.old_sid;

	INSERT INTO csr.delegation_user_cover (user_cover_id, user_giving_cover_sid,
		user_being_covered_sid, delegation_sid)
		SELECT /*+ALL_ROWS CARDINALITY(duc, 1000) CARDINALITY(muc, 1000) CARDINALITY(mugc, 10000) CARDINALITY(mubc, 10000) CARDINALITY(md, 10000)*/
			   muc.new_user_cover_id, mugc.new_sid, mubc.new_sid, md.new_sid
		  FROM csrimp.delegation_user_cover duc, csrimp.map_user_cover muc,
		       csrimp.map_sid mugc, csrimp.map_sid mubc, csrimp.map_sid md
		 WHERE duc.user_cover_id = muc.old_user_cover_id
		   AND duc.user_giving_cover_sid = mugc.old_sid
		   AND duc.user_being_covered_sid = mubc.old_sid
		   AND duc.delegation_sid = md.old_sid;

	INSERT INTO csr.group_user_cover (user_cover_id, user_giving_cover_sid,
		user_being_covered_sid, group_sid)
		SELECT /*+ALL_ROWS CARDINALITY(guc, 1000) CARDINALITY(muc, 1000) CARDINALITY(mugc, 10000) CARDINALITY(mubc, 10000) CARDINALITY(mg, 10000)*/
			   muc.new_user_cover_id, mugc.new_sid, mubc.new_sid, mg.new_sid
		  FROM csrimp.group_user_cover guc, csrimp.map_user_cover muc,
		       csrimp.map_sid mugc, csrimp.map_sid mubc, csrimp.map_sid mg
		 WHERE guc.user_cover_id = muc.old_user_cover_id
		   AND guc.user_giving_cover_sid = mugc.old_sid
		   AND guc.user_being_covered_sid = mubc.old_sid
		   AND guc.group_sid = mg.old_sid;

	INSERT INTO csr.role_user_cover (user_cover_id, user_giving_cover_sid,
		user_being_covered_sid, role_sid, region_sid)
		SELECT /*+ALL_ROWS CARDINALITY(ruc, 1000) CARDINALITY(muc, 1000) CARDINALITY(mugc, 10000) CARDINALITY(mubc, 10000) CARDINALITY(mr, 10000)*/
			   muc.new_user_cover_id, mugc.new_sid, mubc.new_sid, mr.new_sid, mreg.new_sid
		  FROM csrimp.role_user_cover ruc, csrimp.map_user_cover muc,
		       csrimp.map_sid mugc, csrimp.map_sid mubc, csrimp.map_sid mr,
		       csrimp.map_sid mreg
		 WHERE ruc.user_cover_id = muc.old_user_cover_id
		   AND ruc.user_giving_cover_sid = mugc.old_sid
		   AND ruc.user_being_covered_sid = mubc.old_sid
		   AND ruc.role_sid = mr.old_sid
		   AND ruc.region_sid = mreg.old_sid;

	-- issue_user_cover is with CreateIssues

	INSERT INTO csr.chain_tpl_delegation (
				tpl_delegation_sid
	   ) SELECT ms.new_sid
		   FROM csrimp.chain_tpl_delegation ctd,
				csrimp.map_sid ms
		  WHERE ctd.tpl_delegation_sid = ms.old_sid;
END;

PROCEDURE CreateSheets
AS
BEGIN
	INSERT INTO csr.sheet (sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm, reminder_dtm, is_visible,
			automatic_approval_dtm, percent_complete, is_read_only, is_copied_forward, automatic_approval_status)
		SELECT ms.new_sheet_id, md.new_sid, s.start_dtm, s.end_dtm, s.submission_dtm, s.reminder_dtm, s.is_visible,
		       s.automatic_approval_dtm, s.percent_complete, s.is_read_only, s.is_copied_forward, s.automatic_approval_status
		  FROM csrimp.sheet s, csrimp.map_sheet ms, csrimp.map_sid md
		 WHERE md.old_sid = s.delegation_sid
		   AND s.sheet_id = ms.old_sheet_id;

	INSERT INTO csr.sheet_history (sheet_history_id, sheet_id, from_user_sid, to_delegation_sid, action_dtm, note, sheet_action_id, is_system_note)
		SELECT msh.new_sheet_history_id, ms.new_sheet_id, mu.new_sid, md.new_sid, sh.action_dtm, sh.note, sh.sheet_action_id, sh.is_system_note
		  FROM csrimp.map_sheet_history msh, csrimp.map_sheet ms, csrimp.map_sid mu, csrimp.map_sid md, csrimp.sheet_history sh
		 WHERE msh.old_sheet_history_id = sh.sheet_history_id
		   AND sh.sheet_id = ms.old_sheet_id
		   AND sh.from_user_sid = mu.old_sid
		   AND sh.to_delegation_sid = md.old_sid;

	MERGE INTO csr.sheet s
	USING (SELECT s.sheet_id, msh.new_sheet_history_id
		  	 FROM csr.sheet s, csrimp.map_sheet_history msh, csrimp.map_sheet ms, csrimp.sheet os
		 	WHERE ms.new_sheet_id = s.sheet_id
		   	  AND ms.old_sheet_id = os.sheet_id
		   	  AND os.last_sheet_history_id = msh.old_sheet_history_id) sh
	   ON (s.sheet_id = sh.sheet_id)
	 WHEN MATCHED THEN
	 	  UPDATE SET s.last_sheet_history_id = sh.new_sheet_history_id;

	INSERT INTO csr.sheet_alert (sheet_id, user_sid, reminder_sent_dtm, overdue_sent_dtm)
		SELECT ms.new_sheet_id, mu.new_sid, sa.reminder_sent_dtm, sa.overdue_sent_dtm
		  FROM csrimp.map_sheet ms, csrimp.map_sid mu, csrimp.sheet_alert sa
		 WHERE ms.old_sheet_id = sa.sheet_id
		   AND mu.old_sid = sa.user_sid;

	INSERT INTO csr.sheet_value (sheet_value_id, sheet_id, ind_sid, region_sid, val_number, set_by_user_sid,
							     set_dtm, note, entry_measure_conversion_id, entry_val_number, is_inherited,
							     status, alert, flag, var_expl_note, is_na)
		SELECT msv.new_sheet_value_id, ms.new_sheet_id, mi.new_sid, mr.new_sid, sv.val_number, mu.new_sid,
			   sv.set_dtm, sv.note, mmc.new_measure_conversion_id, sv.entry_val_number, sv.is_inherited,
			   sv.status, sv.alert, sv.flag, sv.var_expl_note, sv.is_na
		  FROM csrimp.map_sheet_value msv, csrimp.map_sheet ms, csrimp.sheet_value sv, csrimp.map_sid mi,
		  	   csrimp.map_sid mr, csrimp.map_sid mu, csrimp.map_measure_conversion mmc
		 WHERE msv.old_sheet_value_id = sv.sheet_value_id
		   AND sv.sheet_id = ms.old_sheet_id
		   AND sv.ind_sid = mi.old_sid
		   AND sv.region_sid = mr.old_sid
		   AND sv.set_by_user_sid = mu.old_sid
		   AND sv.entry_measure_conversion_id = mmc.old_measure_conversion_id(+);

	INSERT INTO csr.sheet_value_change (sheet_value_change_id, sheet_value_id, ind_sid, region_sid, val_number,
										reason, changed_by_sid, changed_dtm, entry_measure_conversion_id,
										entry_val_number, note, flag)

		SELECT msvc.new_sheet_value_change_id, msv.new_sheet_value_id, mi.new_sid, mr.new_sid,
			   svc.val_number, svc.reason, mu.new_sid, svc.changed_dtm, mmc.new_measure_conversion_id,
			   svc.entry_val_number, svc.note, svc.flag
		  FROM csrimp.map_sheet_value_change msvc, csr.sheet_value sv, csrimp.map_sheet_value msv, csrimp.sheet_value_change svc,
		  	   csrimp.map_sid mi, csrimp.map_sid mr, csrimp.map_sid mu, csrimp.map_measure_conversion mmc
		 WHERE msvc.old_sheet_value_change_id = svc.sheet_value_change_id
		   AND svc.sheet_value_id = msv.old_sheet_value_id
		   AND sv.sheet_value_id = msv.new_sheet_value_id -- hack around the fact that data goes missing: we really want to import trashed stuff too
		   AND svc.ind_sid = mi.old_sid
		   AND svc.region_sid = mr.old_sid
		   AND svc.changed_by_sid = mu.old_sid
		   AND svc.entry_measure_conversion_id = mmc.old_measure_conversion_id(+);

	MERGE INTO csr.sheet_value sv
	USING (SELECT msv.new_sheet_value_id, msvc.new_sheet_value_change_id
		  	 FROM csrimp.map_sheet_value_change msvc,
			   	  csrimp.sheet_value osv, csrimp.map_sheet_value msv
		 	WHERE msv.csrimp_session_id = osv.csrimp_session_id
		   	  AND msv.old_sheet_value_id = osv.sheet_value_id
		   	  AND msvc.csrimp_session_id = osv.csrimp_session_id
		   	  AND msvc.old_sheet_value_change_id = osv.last_sheet_value_change_id) svc
	   ON (sv.sheet_value_id = svc.new_sheet_value_id)
	 WHEN MATCHED THEN
	 	  UPDATE SET sv.last_sheet_value_change_id = svc.new_sheet_value_change_id;

	INSERT INTO csr.sheet_value_file (sheet_value_id, file_upload_sid)
		SELECT msv.new_sheet_value_id, ms.new_sid
		  FROM csrimp.sheet_value_file svf, csrimp.map_sheet_value msv, csrimp.map_sid ms
		 WHERE svf.sheet_value_id = msv.old_sheet_value_id
		   AND svf.file_upload_sid = ms.old_sid;
	
	
	INSERT INTO csr.sheet_inherited_value (sheet_value_id, inherited_value_id)
		SELECT msv1.new_sheet_value_id, msv2.new_sheet_value_id
		  FROM csrimp.sheet_inherited_value siv, csrimp.map_sheet_value msv1, csrimp.map_sheet_value msv2
		 WHERE siv.sheet_value_id = msv1.old_sheet_value_id
		   AND siv.inherited_value_id = msv2.old_sheet_value_id;

	INSERT INTO csr.sheet_value_accuracy (sheet_value_id, accuracy_type_option_id, pct)
		SELECT msv.new_sheet_value_id, mato.new_accuracy_type_option_id, sva.pct
		  FROM csrimp.map_sheet_value msv, csrimp.map_accuracy_type_option mato,
		  	   csrimp.sheet_value_accuracy sva
		 WHERE msv.old_sheet_value_id = sva.sheet_value_id
		   AND sva.accuracy_type_option_id = mato.old_accuracy_type_option_id;

	INSERT INTO csr.sheet_value_var_expl (sheet_value_id, var_expl_id)
		SELECT msv.new_sheet_value_id, mve.new_var_expl_id
		  FROM csrimp.map_sheet_value msv, csrimp.map_var_expl mve,
		  	   csrimp.sheet_value_var_expl svve
		 WHERE msv.old_sheet_value_id = svve.sheet_value_id
		   AND svve.var_expl_id = mve.old_var_expl_id;

	INSERT INTO csr.sheet_value_file_hidden_cache (sheet_value_id, file_upload_sid)
		SELECT msv.new_sheet_value_id, mfu.new_sid
		  FROM csrimp.map_sheet_value msv, csrimp.sheet_value_file_hidden_cache svfhc,
				csrimp.map_sid mfu
		 WHERE msv.old_sheet_value_id = svfhc.sheet_value_id
		   AND svfhc.file_upload_sid = mfu.old_sid;

	INSERT INTO csr.sheet_value_hidden_cache (sheet_value_id, val_number, note, entry_measure_conversion_id, entry_val_number)
		SELECT msv.new_sheet_value_id, svhc.val_number, svhc.note, mmc.new_measure_conversion_id, svhc.entry_val_number
		  FROM csrimp.map_sheet_value msv, csrimp.sheet_value_hidden_cache svhc,
			   csrimp.map_measure_conversion mmc
		 WHERE msv.old_sheet_value_id = svhc.sheet_value_id
		   AND svhc.entry_measure_conversion_id = mmc.old_measure_conversion_id(+);

	INSERT INTO csr.sheet_change_req (
				sheet_change_req_id,
				active_sheet_id,
				is_approved,
				processed_by_sid,
				processed_dtm,
				processed_note,
				raised_by_sid,
				raised_dtm,
				raised_note,
				req_to_change_sheet_id
	   ) SELECT mscr.new_sheet_change_req_id,
				ms.new_sheet_id,
				scr.is_approved,
				ms1.new_sid,
				scr.processed_dtm,
				scr.processed_note,
				ms2.new_sid,
				scr.raised_dtm,
				scr.raised_note,
				ms3.new_sheet_id
		   FROM csrimp.sheet_change_req scr,
				csrimp.map_sheet_change_req mscr,
				csrimp.map_sheet ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_sheet ms3
		  WHERE scr.sheet_change_req_id = mscr.old_sheet_change_req_id
			AND scr.active_sheet_id = ms.old_sheet_id
			AND scr.processed_by_sid = ms1.old_sid(+)
			AND scr.raised_by_sid = ms2.old_sid
			AND scr.req_to_change_sheet_id = ms3.old_sheet_id;

	INSERT INTO csr.sheet_change_req_alert (
				sheet_change_req_alert_id,
				action_type,
				notify_user_sid,
				raised_by_user_sid,
				sheet_change_req_id
	   ) SELECT mscra.new_sheet_change_req_alert_id,
				scra.action_type,
				ms.new_sid,
				ms1.new_sid,
				mscr.new_sheet_change_req_id
		   FROM csrimp.sheet_change_req_alert scra,
				csrimp.map_shee_chang_req_alert mscra,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sheet_change_req mscr
		  WHERE scra.sheet_change_req_alert_id = mscra.old_sheet_change_req_alert_id
			AND scra.notify_user_sid = ms.old_sid
			AND scra.raised_by_user_sid = ms1.old_sid
			AND scra.sheet_change_req_id = mscr.old_sheet_change_req_id;

	INSERT INTO csr.sheet_value_change_file (
				sheet_value_change_id,
				file_upload_sid
	   ) SELECT msvc.new_sheet_value_change_id,
				ms.new_sid
		   FROM csrimp.sheet_value_change_file svcf,
				csrimp.map_sheet_value_change msvc,
				csrimp.map_sid ms
		  WHERE svcf.sheet_value_change_id = msvc.old_sheet_value_change_id
			AND svcf.file_upload_sid = ms.old_sid;
END;

PROCEDURE CreateForms
AS
BEGIN
	INSERT INTO csr.form (form_sid, parent_sid, name, note, start_dtm, end_dtm,
		group_by, period_set_id, period_interval_id, allocate_users_to, tab_direction)
		SELECT mf.new_sid, mfp.new_sid, f.name, f.note, f.start_dtm, f.end_dtm,
			   f.group_by, f.period_set_id, f.period_interval_id,
			   f.allocate_users_to, f.tab_direction
		  FROM csrimp.form f, csrimp.map_sid mf, csrimp.map_sid mfp
		 WHERE f.form_sid = mf.old_sid
		   AND f.parent_sid = mfp.old_sid;

	INSERT INTO csr.form_region_member (form_sid, region_sid, description, pos)
		SELECT mf.new_sid, mreg.new_sid, frm.description, frm.pos
		  FROM form_region_member frm, csrimp.map_sid mf, csrimp.map_sid mreg
		 WHERE frm.form_sid = mf.old_sid
		   AND frm.region_sid = mreg.old_sid;

	INSERT INTO csr.form_ind_member (form_sid, ind_sid, description, pos, format_mask,
		scale, measure_description, show_total, multiplier_ind_sid, measure_conversion_id)
		SELECT mf.new_sid, mind.new_sid, fim.description, fim.pos, fim.format_mask,
			   fim.scale, fim.measure_description, fim.show_total, mmi.new_sid,
			   mmc.new_measure_conversion_id
		  FROM form_ind_member fim, csrimp.map_sid mf, csrimp.map_sid mind,
		  	   csrimp.map_sid mmi, csrimp.map_measure_conversion mmc
		 WHERE fim.form_sid = mf.old_sid
		   AND fim.ind_sid = mind.old_sid
		   AND fim.multiplier_ind_sid = mmi.old_sid(+)
		   AND fim.measure_conversion_id = mmc.old_measure_conversion_id(+);

	INSERT INTO csr.form_allocation (form_allocation_id, form_sid, note)
		SELECT mfa.new_form_allocation_id, mf.new_sid, fa.note
		  FROM csrimp.form_allocation fa, csrimp.map_sid mf,
		  	   csrimp.map_form_allocation mfa
		 WHERE fa.form_allocation_id = mfa.old_form_allocation_id
		   AND fa.form_sid = mf.old_sid;

	INSERT INTO csr.form_allocation_item (form_allocation_id, item_sid)
		SELECT mfa.new_form_allocation_id, mi.new_sid
		  FROM csrimp.form_allocation_item fai, csrimp.map_form_allocation mfa, csrimp.map_sid mi
		 WHERE fai.form_allocation_id = mfa.old_form_allocation_id
		   AND fai.item_sid = mi.old_sid;

	INSERT INTO csr.form_allocation_user (form_allocation_id, user_sid, read_only)
		SELECT mfa.new_form_allocation_id, mu.new_sid, fau.read_only
		  FROM csrimp.form_allocation_user fau, csrimp.map_form_allocation mfa, csrimp.map_sid mu
		 WHERE fau.form_allocation_id = mfa.old_form_allocation_id
		   AND fau.user_sid = mu.old_sid;

	INSERT INTO csr.form_comment (form_sid, z_key, form_comment, last_updated_by_sid, last_updated_dtm, form_allocation_id)
		SELECT /*+ALL_ROWS CARDINALITY(fc, 1000) CARDINALITY(mfa, 5000) CARDINALITY(mf, 50000)
			      CARDINALITY(mu, 50000)*/
			   mf.new_sid, fc.z_key, fc.form_comment, mu.new_sid, fc.last_updated_dtm, mfa.new_form_allocation_id
		  FROM csrimp.form_comment fc, csrimp.map_form_allocation mfa, csrimp.map_sid mf,
		  	   csrimp.map_sid mu
		 WHERE fc.form_sid = mf.old_sid
		   AND fc.last_updated_by_sid = mu.old_sid
		   AND fc.form_allocation_id = mfa.old_form_allocation_id;
END;

PROCEDURE CreateImgCharts
AS
	v_key				VARCHAR2(255);
	v_sid				security.security_pkg.T_SID_ID;
BEGIN
	INSERT INTO csr.img_chart (img_chart_sid, parent_sid, label, mime_type, data, sha1, last_modified_dtm)
		SELECT ms.new_sid, mp.new_sid, ic.label, ic.mime_type, ic.data, ic.sha1, ic.last_modified_dtm
		  FROM csrimp.img_chart ic, csrimp.map_sid ms, csrimp.map_sid mp
		 WHERE ic.img_chart_sid = ms.old_sid
		   AND ic.parent_sid = mp.old_sid;

	INSERT INTO csr.img_chart_ind (img_chart_sid, ind_sid, description, measure_conversion_id, x, y, background_color, border_color, font_size)
		SELECT ms.new_sid, mi.new_sid, ici.description, mmc.new_measure_conversion_id, ici.x, ici.y, ici.background_color, ici.border_color, ici.font_size
		  FROM csrimp.img_chart_ind ici, csrimp.map_sid ms, csrimp.map_sid mi, csrimp.map_measure_conversion mmc
		 WHERE ici.img_chart_sid = ms.old_sid
		   AND ici.ind_sid = mi.old_sid
		   AND ici.measure_conversion_id = mmc.old_measure_conversion_id(+);

	INSERT INTO csr.img_chart_region (
				img_chart_sid,
				region_sid,
				background_color,
				border_color,
				description,
				x,
				y
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				icr.background_color,
				icr.border_color,
				icr.description,
				icr.x,
				icr.y
		   FROM csrimp.img_chart_region icr,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE icr.img_chart_sid = ms.old_sid
			AND icr.region_sid = ms1.old_sid;
END;

-- fixes the foul workbook styling XML
PROCEDURE FixDataViewXml(
	in_node							IN	dbms_xmldom.domnode
)
AS
	v_node							dbms_xmldom.domnode := in_node;
	v_child							dbms_xmldom.domnode;
	v_sid 							varchar2(100);
	v_new_sid						security_pkg.T_SID_ID;
	type t_attribs is table of varchar2(30);
	v_list							t_attribs;
BEGIN
	v_list := t_attribs('sid', 'dataview_ind_sid'); -- lovely - it duplicates ids. Thanks Mr Ringrose!
	WHILE NOT dbms_xmldom.isnull(v_node) LOOP
		IF dbms_xmldom.getnodetype(v_node) = dbms_xmldom.element_node THEN
			FOR i IN 1 .. v_list.COUNT LOOP
				v_sid := dbms_xmldom.getattribute(dbms_xmldom.makeelement(v_node), v_list(i));
				IF NVL(v_sid, 0) NOT IN (0, -1) THEN
					BEGIN
						SELECT new_sid
						  INTO v_new_sid
						  FROM csrimp.map_sid
						 WHERE old_sid = TO_NUMBER(v_sid);
						dbms_xmldom.setattribute(dbms_xmldom.makeelement(v_node), v_list(i), v_new_sid);
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							-- quietly ignore for now
							null;
					END;
					--dbms_output.put_line('sid = '||v_sid||' -> '||v_new_sid);
				END IF;
			END LOOP;
			v_child := dbms_xmldom.getfirstchild(v_node);
			IF NOT dbms_xmldom.isnull(v_child) THEN
				FixDataViewXml(v_child);
			END IF;
		END IF;
		v_node := dbms_xmldom.getnextsibling(v_node);
	END LOOP;
END;

PROCEDURE CreateDataViews
AS
	v_doc							dbms_xmldom.domdocument;
	v_doc_node						dbms_xmldom.domnode;
	v_chart_config_xml				CLOB;
BEGIN
	INSERT INTO csr.dataview (dataview_sid, parent_sid, name, start_dtm, end_dtm, group_by,
		period_set_id, period_interval_id, chart_config_xml, chart_style_xml, pos, description,
		dataview_type_id, show_calc_trace, show_variance, show_abs_variance, show_variance_explanations,
		sort_by_most_recent, treat_null_as_zero, include_parent_region_names, last_updated_dtm, last_updated_sid,
		rank_limit_left, rank_limit_left_type, rank_ind_sid, rank_filter_type,
		rank_limit_right, rank_limit_right_type, rank_reverse, region_grouping_tag_group,
		suppress_unmerged_data_message, version_num, anonymous_region_names, include_notes_in_table,
		show_region_events, aggregation_period_id, highlight_changed_since, highlight_changed_since_dtm,
		show_layer_variance_pct, show_layer_variance_abs, show_layer_variance_pct_base, show_layer_variance_abs_base, show_layer_variance_start)
		SELECT mdv.new_sid, mp.new_sid, dv.name, dv.start_dtm, dv.end_dtm, dv.group_by,
			   dv.period_set_id, period_interval_id, dv.chart_config_xml, dv.chart_style_xml,
			   dv.pos, dv.description, dv.dataview_type_id,
			   dv.show_calc_trace, dv.show_variance, dv.show_abs_variance, dv.show_variance_explanations, dv.sort_by_most_recent,
			   dv.treat_null_as_zero, dv.include_parent_region_names, dv.last_updated_dtm, mu.new_sid,
			   dv.rank_limit_left, dv.rank_limit_left_type,
			   mi.new_sid, dv.rank_filter_type,
			   dv.rank_limit_right, dv.rank_limit_right_type, dv.rank_reverse, mtg.new_tag_group_id,
			   dv.suppress_unmerged_data_message,
			   dv.version_num, dv.anonymous_region_names, dv.include_notes_in_table,
			   dv.show_region_events, dv.aggregation_period_id, dv.highlight_changed_since, dv.highlight_changed_since_dtm,
			   dv.show_layer_variance_pct, dv.show_layer_variance_abs, dv.show_layer_variance_pct_base, dv.show_layer_variance_abs_base, dv.show_layer_variance_start
		  FROM csrimp.dataview dv, csrimp.map_sid mdv, csrimp.map_sid mp,
		  	   csrimp.map_sid mu, csrimp.map_sid mi, csrimp.map_tag_group mtg
		 WHERE dv.dataview_sid = mdv.old_sid
		   AND dv.parent_sid = mp.old_sid
		   AND dv.last_updated_sid = mu.old_sid(+)
		   AND dv.rank_ind_sid = mi.old_sid(+)
		   AND dv.region_grouping_tag_group = mtg.old_tag_group_id(+);

	FOR r IN (SELECT dv.dataview_sid, dv.chart_config_xml
			    FROM csr.dataview dv
			   WHERE dataview_type_id = csr.csr_data_pkg.DATAVIEW_WORKBOOK
			     AND NVL(dbms_lob.getlength(dv.chart_config_xml), 0) > 0) LOOP

		-- fix up foul xml
		v_doc := dbms_xmldom.newdomdocument(r.chart_config_xml);
		BEGIN
			v_doc_node := dbms_xmldom.makenode(dbms_xmldom.getdocumentelement(v_doc));
			FixDataViewXml(v_doc_node);

			dbms_lob.createTemporary(v_chart_config_xml, TRUE, dbms_lob.call);
			dbms_xmldom.writetoclob(v_doc_node, v_chart_config_xml);
			dbms_xmldom.freedocument(v_doc);

			UPDATE csr.dataview
			   SET chart_config_xml = v_chart_config_xml
			 WHERE dataview_sid = r.dataview_sid;
		EXCEPTION
			WHEN OTHERS THEN
				dbms_xmldom.freedocument(v_doc);
				v_chart_config_xml := null;
				RAISE;
		END;

	END LOOP;

	INSERT INTO csr.dataview_ind_member (dataview_sid, ind_sid, normalization_ind_sid,
			 					         calculation_type_id, pos, format_mask,
		 							     measure_conversion_id)
		SELECT mdv.new_sid, mi1.new_sid ind_sid, mi2.new_sid new_normalization_ind_sid,
			   dvim.calculation_type_id, dvim.pos, dvim.format_mask,
			   mmc.new_measure_conversion_id
		  FROM csrimp.dataview_ind_member dvim, csrimp.map_sid mi1, csrimp.map_sid mi2,
			   csrimp.map_measure_conversion mmc, csrimp.map_sid mdv
	     WHERE mdv.old_sid = dvim.dataview_sid
	       AND dvim.ind_sid = mi1.old_sid
	       AND dvim.normalization_ind_sid = mi2.old_sid(+)
	       AND dvim.measure_conversion_id = mmc.old_measure_conversion_id(+);

	INSERT INTO csr.dataview_ind_description (dataview_sid, pos, lang, description)
		SELECT mdv.new_sid, did.pos, did.lang, did.description
		  FROM csrimp.dataview_ind_description did, csrimp.map_sid mdv
	     WHERE mdv.old_sid = did.dataview_sid;

	INSERT INTO csr.dataview_region_member (dataview_sid, region_sid, pos, tab_level)
		SELECT mdv.new_sid, mr.new_sid, dvrm.pos, dvrm.tab_level
		  FROM csrimp.dataview_region_member dvrm, csrimp.map_sid mr,
		  	   csrimp.map_sid mdv
		 WHERE mdv.old_sid = dvrm.dataview_sid
		   AND dvrm.region_sid = mr.old_sid;

	INSERT INTO csr.dataview_region_description (dataview_sid, region_sid, lang, description)
		SELECT mdv.new_sid, mr.new_sid, drd.lang, drd.description
		  FROM csrimp.dataview_region_description drd, csrimp.map_sid mr,
		  	   csrimp.map_sid mdv
	     WHERE mdv.old_sid = drd.dataview_sid
	       AND drd.region_sid = mr.old_sid;

	INSERT INTO csr.excel_export_options (dataview_sid, ind_show_sid, ind_show_info,
		ind_show_tags, ind_show_gas_factor, region_show_sid, region_show_inactive,
		region_show_info, region_show_tags, region_show_type, region_show_ref,
		region_show_acquisition_dtm, region_show_disposal_dtm, region_show_roles,
		region_show_egrid, region_show_geo_country, meter_show_ref, meter_show_location,
		meter_show_source_type, meter_show_note, meter_show_crc, meter_show_ind,
		meter_show_measure, meter_show_cost_ind, meter_show_cost_measure,
		meter_show_days_ind, meter_show_supplier, meter_show_contract, scenario_pos)
		SELECT ms.new_sid, eeo.ind_show_sid, eeo.ind_show_info, eeo.ind_show_tags,
			   eeo.ind_show_gas_factor, eeo.region_show_sid, eeo.region_show_inactive,
			   eeo.region_show_info, eeo.region_show_tags, eeo.region_show_type,
			   eeo.region_show_ref, eeo.region_show_acquisition_dtm,
			   eeo.region_show_disposal_dtm, eeo.region_show_roles,
			   eeo.region_show_egrid, eeo.region_show_geo_country,
			   eeo.meter_show_ref, eeo.meter_show_location, eeo.meter_show_source_type,
			   eeo.meter_show_note, eeo.meter_show_crc, eeo.meter_show_ind,
			   eeo.meter_show_measure, eeo.meter_show_cost_ind, eeo.meter_show_cost_measure,
			   eeo.meter_show_days_ind, eeo.meter_show_supplier, eeo.meter_show_contract,
			   eeo.scenario_pos
		  FROM csrimp.excel_export_options eeo, csrimp.map_sid ms
		 WHERE eeo.dataview_sid = ms.old_sid;

	INSERT INTO csr.excel_export_options_tag_group (dataview_sid, applies_to, tag_group_id)
		SELECT ms.new_sid, eeotg.applies_to, mtg.new_tag_group_id
		  FROM csrimp.excel_export_options_tag_group eeotg, csrimp.map_sid ms, csrimp.map_tag_group mtg
		 WHERE mtg.old_tag_group_id = eeotg.tag_group_id
		   AND eeotg.dataview_sid = ms.old_sid;

	INSERT INTO csr.dataview_scenario_run (dataview_sid, scenario_run_type, scenario_run_sid)
		SELECT mdv.new_sid, dsr.scenario_run_type, nvl(msr.new_sid, dsr.scenario_run_sid)
		  FROM csrimp.dataview_scenario_run dsr, csrimp.map_sid mdv,
		  	   csrimp.map_sid msr
		 WHERE dsr.dataview_sid = mdv.old_sid
		   AND dsr.scenario_run_sid = msr.old_sid(+);

	INSERT INTO csr.dataview_zone (pos, name, dataview_sid, description,
		start_val_ind_sid, start_val_region_sid, start_val_start_dtm, start_val_end_dtm,
		end_val_ind_sid, end_val_region_sid, end_val_start_dtm, end_val_end_dtm,
		style_xml, is_target, type, target_direction)
		SELECT dvz.pos, dvz.name, mdv.new_sid, dvz.description,
			   msvi.new_sid, msvr.new_sid, dvz.start_val_start_dtm, dvz.start_val_end_dtm,
			   mevi.new_sid, mevr.new_sid, dvz.end_val_start_dtm, dvz.end_val_end_dtm,
			   dvz.style_xml, dvz.is_target, dvz.type, dvz.target_direction
		  FROM csrimp.dataview_zone dvz, csrimp.map_sid mdv, csrimp.map_sid msvi,
		  	   csrimp.map_sid msvr, csrimp.map_sid mevi, csrimp.map_sid mevr
		 WHERE dvz.dataview_sid = mdv.old_sid(+)
		   AND dvz.start_val_ind_sid = msvi.old_sid
		   AND dvz.start_val_region_sid = msvr.old_sid
		   AND dvz.end_val_ind_sid = mevi.old_sid(+)
		   AND dvz.end_val_region_sid = mevr.old_sid(+);

    INSERT INTO csr.dataview_history
              (name, start_dtm, end_dtm, group_by, chart_config_xml, chart_style_xml, pos, description,
               dataview_type_id, show_calc_trace, show_variance, show_abs_variance, show_variance_explanations,
               sort_by_most_recent, treat_null_as_zero, include_parent_region_names,
			   last_updated_dtm, last_updated_sid, rank_filter_type,
               rank_limit_left, rank_ind_sid, rank_limit_right, rank_limit_left_type, rank_limit_right_type,
               rank_reverse, region_grouping_tag_group, anonymous_region_names, include_notes_in_table,
               show_region_events, suppress_unmerged_data_message, period_set_id, period_interval_id,
               version_num, aggregation_period_id, highlight_changed_since, highlight_changed_since_dtm,
			   show_layer_variance_pct, show_layer_variance_abs, show_layer_variance_pct_base, show_layer_variance_abs_base, show_layer_variance_start,
			   dataview_sid)
        SELECT dh.name, dh.start_dtm, dh.end_dtm, dh.group_by, dh.chart_config_xml, dh.chart_style_xml, dh.pos, dh.description,
               dh.dataview_type_id, dh.show_calc_trace, dh.show_variance, dh.show_abs_variance, dh.show_variance_explanations,
               dh.sort_by_most_recent, dh.treat_null_as_zero, dh.include_parent_region_names,
			   dh.last_updated_dtm, mcu.new_sid, dh.rank_filter_type,
               dh.rank_limit_left, dh.rank_ind_sid, dh.rank_limit_right, dh.rank_limit_left_type, dh.rank_limit_right_type,
               dh.rank_reverse, dh.region_grouping_tag_group, dh.anonymous_region_names, dh.include_notes_in_table,
               dh.show_region_events, dh.suppress_unmerged_data_message, dh.period_set_id, dh.period_interval_id,
               dh.version_num, dh.aggregation_period_id, dh.highlight_changed_since, dh.highlight_changed_since_dtm,
			   dh.show_layer_variance_pct, dh.show_layer_variance_abs, dh.show_layer_variance_pct_base, dh.show_layer_variance_abs_base, dh.show_layer_variance_start,
			   mdv.new_sid
          FROM csrimp.dataview_history dh
          JOIN csrimp.map_sid mdv ON mdv.old_sid = dh.dataview_sid
		  JOIN csrimp.map_sid mcu ON mcu.old_sid = dh.last_updated_sid;

   INSERT INTO csr.dataview_arbitrary_period
              (start_dtm, end_dtm, dataview_sid)
        SELECT dap.start_dtm, dap.end_dtm, mdv.new_sid
          FROM csrimp.dataview_arbitrary_period dap
          JOIN csrimp.map_sid mdv ON mdv.old_sid = dap.dataview_sid;

   INSERT INTO csr.dataview_arbitrary_period_hist
              (start_dtm, end_dtm, version_num, dataview_sid)
        SELECT daph.start_dtm, daph.end_dtm, daph.version_num, mdv.new_sid
          FROM csrimp.dataview_arbitrary_period_hist daph
          JOIN csrimp.map_sid mdv ON mdv.old_sid = daph.dataview_sid;

   INSERT INTO csr.dataview_trend
              (pos, name, title, dataview_sid, ind_sid, region_sid, months, rounding_method, rounding_digits)
        SELECT pos, dt.name, dt.title, mdv.new_sid, mi.new_sid, mr.new_sid, dt.months, dt.rounding_method, dt.rounding_digits
          FROM csrimp.dataview_trend dt
          JOIN csrimp.map_sid mdv ON mdv.old_sid = dt.dataview_sid
          JOIN csrimp.map_sid mi ON mdv.old_sid = dt.ind_sid
          JOIN csrimp.map_sid mr ON mdv.old_sid = dt.region_sid;
END;

PROCEDURE CreateImports
AS
BEGIN
	INSERT INTO csr.imp_session (imp_session_sid, parent_sid, name, owner_sid,
		uploaded_dtm, file_path, parse_started_dtm, parsed_dtm, merged_dtm,
		result_code, message, unmerged_dtm)
		SELECT mi.new_sid, mp.new_sid, i.name, mo.new_sid, i.uploaded_dtm,
			   i.file_path, i.parse_started_dtm, i.parsed_dtm, i.merged_dtm,
			   i.result_code, i.message, i.unmerged_dtm
		  FROM csrimp.imp_session i, csrimp.map_sid mi, csrimp.map_sid mp,
		  	   csrimp.map_sid mo
		 WHERE i.imp_session_sid = mi.old_sid
		   AND i.parent_sid = mp.old_sid
		   AND i.owner_sid = mo.old_sid;

	-- import indicators
	INSERT INTO csr.imp_ind (imp_ind_id, description, maps_to_ind_sid, ignore)
		SELECT mii.new_imp_ind_id, ii.description, mi.new_sid, ii.ignore
		  FROM csrimp.map_imp_ind mii, csrimp.imp_ind ii, csrimp.map_sid mi
		 WHERE mii.old_imp_ind_id = ii.imp_ind_id
		   AND ii.maps_to_ind_sid = mi.old_sid(+);

  	-- import regions
	INSERT INTO csr.imp_region (imp_region_id, description, maps_to_region_sid, ignore)
		SELECT mir.new_imp_region_id, ir.description, mr.new_sid, ir.ignore
		  FROM csrimp.map_imp_region mir, csrimp.imp_region ir, csrimp.map_sid mr
		 WHERE mir.old_imp_region_id = ir.imp_region_id
		   AND ir.maps_to_region_sid = mr.old_sid(+);

	-- import measures
	INSERT INTO csr.imp_measure (imp_measure_id, description, maps_to_measure_conversion_id, maps_to_measure_sid, imp_ind_id)
		SELECT mim.new_imp_measure_id, im.description, mmc.new_measure_conversion_id, mm.new_sid, mii.new_imp_ind_id
		  FROM csrimp.map_imp_measure mim, csrimp.imp_measure im, csrimp.map_measure_conversion mmc, csrimp.map_sid mm,
		  	   csrimp.map_imp_ind mii
		 WHERE mim.old_imp_measure_id = im.imp_measure_id
		   AND im.imp_ind_id = mii.old_imp_ind_id
		   AND im.maps_to_measure_conversion_id = mmc.old_measure_conversion_id(+)
		   AND im.maps_to_measure_sid = mm.old_sid(+);

	-- import values
	INSERT INTO csr.imp_val (imp_val_id, imp_ind_id, imp_region_id, imp_measure_id, unknown, start_dtm, end_dtm,
							 val, file_sid, a, b, c, imp_session_sid, set_val_id, note, set_region_metric_val_id)
		SELECT miv.new_imp_val_id, mii.new_imp_ind_id, mir.new_imp_region_id, mim.new_imp_measure_id,
			   iv.unknown, iv.start_dtm, iv.end_dtm, iv.val, mfu.new_sid, iv.a, iv.b, iv.c,
			   mis.new_sid, mv.new_val_id, iv.note, msrm.new_val_id
		  FROM csrimp.imp_val iv, csrimp.map_imp_val miv, csrimp.map_imp_ind mii, csrimp.map_imp_region mir,
		  	   csrimp.map_imp_measure mim, csrimp.map_sid mfu, csrimp.map_sid mis, csrimp.map_val mv, csrimp.map_val msrm
		 WHERE miv.old_imp_val_id = iv.imp_val_id
		   AND iv.imp_ind_id = mii.old_imp_ind_id
		   AND iv.imp_region_id = mir.old_imp_region_id
		   AND iv.imp_measure_id = mim.old_imp_measure_id(+)
		   AND iv.file_sid = mfu.old_sid(+)
		   AND iv.imp_session_sid = mis.old_sid
		   AND iv.set_val_id = mv.old_val_id(+)
		   AND iv.set_region_metric_val_id = msrm.old_val_id(+);

	-- import conflicts
	INSERT INTO csr.imp_conflict (imp_conflict_id, imp_session_sid, resolved_by_user_sid, start_dtm, end_dtm, region_sid, ind_sid)
		SELECT mic.new_imp_conflict_id, mis.new_sid, mu.new_sid, ic.start_dtm, ic.end_dtm,
			   mr.new_sid, mi.new_sid
		  FROM csrimp.map_imp_conflict mic, csrimp.imp_conflict ic, csrimp.map_sid mis, csrimp.map_sid mu,
		  	   csrimp.map_sid mr, csrimp.map_sid mi
		 WHERE mic.old_imp_conflict_id = ic.imp_conflict_id
		   AND ic.imp_session_sid = mis.old_sid
		   AND ic.resolved_by_user_sid = mu.old_sid(+)
		   AND ic.region_sid = mr.old_sid
		   AND ic.ind_sid = mi.old_sid;

	INSERT INTO csr.imp_conflict_val (imp_conflict_id, imp_val_id, accept)
		SELECT mic.new_imp_conflict_id, miv.new_imp_val_id, icv.accept
		  FROM csrimp.map_imp_conflict mic, csrimp.map_imp_val miv, csrimp.imp_conflict_val icv
		 WHERE mic.old_imp_conflict_id = icv.imp_conflict_id
		   AND miv.old_imp_val_id = icv.imp_val_id;

	INSERT INTO csr.imp_vocab (csr_user_sid, imp_tag_type_id, phrase, frequency)
		SELECT mu.new_sid, imp_tag_type_id, phrase, frequency
		  FROM csrimp.imp_vocab iv, csrimp.map_sid mu
		 WHERE iv.csr_user_sid = mu.old_sid;
END;

PROCEDURE CreateVals
AS
BEGIN
	INSERT INTO csr.val (val_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number,
						 error_code, alert, source_type_id, source_id, flags,
						 entry_measure_conversion_id, entry_val_number, note, changed_dtm,
						 changed_by_sid)
		SELECT /*+INDEX(v, PK_VAL) INDEX(mv, PK_MAP_VAL) INDEX(mi PK_MAP_SID) INDEX(mr PK_MAP_SID)
				  INDEX(mu PK_MAP_SID) INDEX(mmc PK_MAP_MEASURE_CONVERSION) INDEX(msv PK_MAP_SHEET_VALUE) INDEX(miv PK_MAP_IMP_VAL)
				  CARDINALITY(v, 5000000) CARDINALITY(mv, 1000000) CARDINALITY(mi, 50000) CARDINALITY(mr, 50000)
				  CARDINALITY(mu, 50000) CARDINALITY(mmc, 100) CARDINALITY(msv, 1000000) CARDINALITY(miv, 1000000)*/
			   mv.new_val_id, mi.new_sid, mr.new_sid, v.period_start_dtm,
			   v.period_end_dtm, v.val_number, v.error_code, v.alert, v.source_type_id,
			   CASE WHEN v.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_IMPORT -- map source values in imports (invalid values go to null)
			        THEN miv.new_imp_val_id
			        WHEN v.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_DELEGATION -- map source values in delegations (invalid values go to null)
			        THEN msv.new_sheet_value_id
			    	ELSE v.source_id
			   END,
			   v.flags, mmc.new_measure_conversion_id, v.entry_val_number, v.note, v.changed_dtm,
			   mu.new_sid
		  FROM csrimp.val v
		  JOIN csrimp.map_val mv ON v.val_id = mv.old_val_id
		  JOIN csrimp.map_sid mi ON v.ind_sid = mi.old_sid
		  JOIN csrimp.map_sid mr ON v.region_sid = mr.old_sid
		  JOIN csrimp.map_sid mu ON v.changed_by_sid = mu.old_sid
		  LEFT JOIN csrimp.map_measure_conversion mmc ON v.entry_measure_conversion_id = mmc.old_measure_conversion_id
		  LEFT JOIN csrimp.map_sheet_value msv ON v.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_DELEGATION AND v.source_id = msv.old_sheet_value_id
		  LEFT JOIN csrimp.map_imp_val miv ON v.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_IMPORT AND v.source_id = miv.old_imp_val_id;

	INSERT INTO csr.val_change (val_change_id, ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number,
								source_type_id, source_id, entry_measure_conversion_id, entry_val_number,
								note, changed_by_sid, changed_dtm, reason)
		SELECT /*+INDEX(vc, PK_VAL_CHANGE) INDEX(mi PK_MAP_SID) INDEX(mr PK_MAP_SID)
				  INDEX(mu PK_MAP_SID) INDEX(mmc PK_MAP_MEASURE_CONVERSION) INDEX(msv PK_MAP_SHEET_VALUE) INDEX(miv PK_MAP_IMP_VAL)
				  CARDINALITY(vc, 5000000) CARDINALITY(mi, 50000) CARDINALITY(mr, 50000)
				  CARDINALITY(mu, 50000) CARDINALITY(mmc, 100) CARDINALITY(msv, 1000000) CARDINALITY(miv, 1000000)*/
			   csr.val_change_id_seq.NEXTVAL, mi.new_sid, mr.new_sid, vc.period_start_dtm,
			   vc.period_end_dtm, vc.val_number, vc.source_type_id,
			   CASE WHEN vc.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_IMPORT -- map source values in imports (invalid values go to null)
			        THEN miv.new_imp_val_id
			        WHEN vc.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_DELEGATION -- map source values in delegations (invalid values go to null)
			        THEN msv.new_sheet_value_id
			    	ELSE vc.source_id
			   END,
 			   mmc.new_measure_conversion_id, vc.entry_val_number, vc.note,
			   mu.new_sid, vc.changed_dtm, vc.reason
		  FROM csrimp.val_change vc
		  JOIN csrimp.map_sid mi ON vc.ind_sid = mi.old_sid
		  JOIN csrimp.map_sid mr ON vc.region_sid = mr.old_sid
		  JOIN csrimp.map_sid mu ON vc.changed_by_sid = mu.old_sid
	 LEFT JOIN csrimp.map_measure_conversion mmc ON vc.entry_measure_conversion_id = mmc.old_measure_conversion_id
	 LEFT JOIN csrimp.map_sheet_value msv ON vc.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_DELEGATION AND vc.source_id = msv.old_sheet_value_id
	 LEFT JOIN csrimp.map_imp_val miv ON vc.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_IMPORT AND vc.source_id = miv.old_imp_val_id;

	INSERT INTO csr.val_file (
				val_id,
				file_upload_sid
	   ) SELECT mv.new_val_id,
				ms.new_sid
		   FROM csrimp.val_file vf,
				csrimp.map_val mv,
				csrimp.map_sid ms
		  WHERE vf.val_id = mv.old_val_id
			AND vf.file_upload_sid = ms.old_sid;

	INSERT INTO csr.val_note (
				val_note_id,
				entered_by_sid,
				entered_dtm,
				ind_sid,
				note,
				period_end_dtm,
				period_start_dtm,
				region_sid
	   ) SELECT mvn.new_val_note_id,
				ms.new_sid,
				vn.entered_dtm,
				ms1.new_sid,
				vn.note,
				vn.period_end_dtm,
				vn.period_start_dtm,
				ms2.new_sid
		   FROM csrimp.val_note vn,
				csrimp.map_val_note mvn,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2
		  WHERE vn.val_note_id = mvn.old_val_note_id
			AND vn.entered_by_sid = ms.old_sid
			AND vn.ind_sid = ms1.old_sid
			AND vn.region_sid = ms2.old_sid;
END;

PROCEDURE CreateSections
AS
BEGIN
	INSERT INTO csr.section_status (section_status_sid, description, colour, pos, icon_path)
		SELECT ms.new_sid, ss.description, ss.colour, ss.pos, ss.icon_path
		  FROM csrimp.section_status ss, csrimp.map_sid ms
		 WHERE ss.section_status_sid = ms.old_sid;

	INSERT INTO csr.section_flow (flow_sid, split_question_flow_state_id, dflt_ret_aft_inc_usr_submit)
		SELECT m.new_sid, mfs.new_flow_state_id, sf.dflt_ret_aft_inc_usr_submit
		  FROM csrimp.section_flow sf, csrimp.map_sid m, csrimp.map_flow_state mfs
		 WHERE sf.flow_sid = m.old_sid
		   AND sf.split_question_flow_state_id = mfs.old_flow_state_id(+);

	INSERT INTO csr.section_module (module_root_sid, label, show_summary_tab,
		default_status_sid, flow_sid, region_sid, active, start_dtm, show_flow_summary_tab, reminder_offset,
		previous_module_sid, library_sid, end_dtm, show_fact_icon)
		SELECT msm.new_sid, sm.label, sm.show_summary_tab, mds.new_sid, mf.new_sid, mr.new_sid,
		       sm.active, sm.start_dtm, sm.show_flow_summary_tab, sm.reminder_offset,
			   mpm.new_sid, ml.new_sid, sm.end_dtm, sm.show_fact_icon
		  FROM csrimp.section_module sm, csrimp.map_sid msm, csrimp.map_sid mds,
		  	   csrimp.map_sid mf, csrimp.map_sid mr,
			   csrimp.map_sid mpm, csrimp.map_sid ml
		 WHERE sm.module_root_sid = msm.old_sid
		   AND sm.default_status_sid = mds.old_sid
		   AND sm.flow_sid = mf.old_sid(+)
		   AND sm.region_sid = mr.old_sid(+)
		   AND sm.previous_module_sid = mpm.old_sid(+)
		   AND sm.library_sid = ml.old_sid(+);

	INSERT INTO csr.attachment (attachment_id, filename, mime_type, data, embed,
		dataview_sid, last_updated_from_dataview, view_as_table, indicator_sid,
		doc_id, url)
		SELECT ma.new_attachment_id, a.filename, a.mime_type, a.data, a.embed,
			   mdv.new_sid, a.last_updated_from_dataview, a.view_as_table,
			   mi.new_sid, md.new_doc_id, a.url
		  FROM csrimp.attachment a, csrimp.map_attachment ma, csrimp.map_sid mdv,
		       csrimp.map_sid mi, csrimp.map_doc md
		 WHERE a.attachment_id = ma.old_attachment_id
		   AND a.dataview_sid = mdv.old_sid(+)
		   AND a.indicator_sid = mi.old_sid(+)
		   AND a.doc_id = md.old_doc_id(+);

	INSERT INTO csr.section_routed_flow_state (flow_sid, flow_state_id, reject_fs_transition_id)
		SELECT mf.new_sid, mfs.new_flow_state_id, mfst.new_flow_state_transition_id
		  FROM csrimp.section_routed_flow_state  srfs, csrimp.map_sid mf, csrimp.map_flow_state mfs, csrimp.map_flow_state_transition mfst
		 WHERE srfs.flow_sid = mf.old_sid
		   AND srfs.flow_state_id = mfs.old_flow_state_id
		   AND srfs.reject_fs_transition_id = mfst.old_flow_state_transition_id(+);

	INSERT INTO csr.section (section_sid, parent_sid, checked_out_to_sid,
		checked_out_dtm, checked_out_version_number, visible_version_number,
		section_position, active, module_root_sid, title_only, ref, plugin,
		plugin_config, section_status_sid, further_info_url, help_text, flow_item_id,
		current_route_step_id, is_split, disable_general_attachments, previous_section_sid)
		SELECT ms.new_sid, mps.new_sid, mco.new_sid, s.checked_out_dtm,
			   null, null, -- has a constraint to section version
			   s.section_position, s.active, mrs.new_sid, s.title_only,
			   s.ref, s.plugin, s.plugin_config, mss.new_sid,
			   s.further_info_url, s.help_text, mfi.new_flow_item_id,
			   null, -- has a constraint on route_step --mrst.new_route_step_id,
			   s.is_split, s.disable_general_attachments, mprev.new_sid
		  FROM csrimp.section s, csrimp.map_sid ms, csrimp.map_sid mps,
		  	   csrimp.map_sid mco, csrimp.map_sid mrs, csrimp.map_sid mss, csrimp.map_flow_item mfi, csrimp.map_sid mprev
		 WHERE s.section_sid = ms.old_sid
		   AND s.parent_sid = mps.old_sid(+)
		   AND s.checked_out_to_sid = mco.old_sid(+)
		   AND s.module_root_sid = mrs.old_sid
		   AND s.section_status_sid = mss.old_sid
		   AND s.flow_item_id = mfi.old_flow_item_id(+)
		   AND s.previous_section_sid = mprev.old_sid(+);

	INSERT INTO csr.section_version (section_sid, version_number, title,
		body, changed_by_sid, changed_dtm, reason_for_change, approved_by_sid,
		approved_dtm)
		SELECT ms.new_sid, sv.version_number, sv.title, sv.body, mc.new_sid,
			   sv.changed_dtm, sv.reason_for_change, ma.new_sid, sv.approved_dtm
		  FROM csrimp.section_version sv, csrimp.map_sid ms, csrimp.map_sid mc,
		  	   csrimp.map_sid ma
		 WHERE sv.section_sid = ms.old_sid
		   AND sv.changed_by_sid = mc.old_sid(+)
		   AND sv.approved_by_sid = ma.old_sid(+);

	-- fix up columns in section we couldn't import without the rows in section_version existing
	UPDATE csr.section s
	   SET (s.checked_out_version_number, s.visible_version_number) =
	   		(SELECT si.checked_out_version_number, si.visible_version_number
	   		   FROM csrimp.section si, csrimp.map_sid ms
	   		  WHERE si.section_sid = ms.old_sid
	   		    AND ms.new_sid = s.section_sid);

	INSERT INTO csr.route (route_id, section_sid, flow_state_id, flow_sid, due_dtm, completed_dtm)
	   SELECT mr.new_route_id, ms.new_sid, mfs.new_flow_state_id, mf.new_sid, r.due_dtm, r.completed_dtm
	     FROM csrimp.route r, csrimp.map_route mr, csrimp.map_sid ms, csrimp.map_flow_state mfs, csrimp.map_sid mf
	    WHERE r.route_id = mr.old_route_id
	      AND r.section_sid = ms.old_sid
	      AND r.flow_state_id = mfs.old_flow_state_id
	      AND r.flow_sid = mf.old_sid;

	INSERT INTO csr.route_step (route_step_id, route_id, work_days_offset, step_due_dtm, pos)
	   SELECT mrs.new_route_step_id, mr.new_route_id, rs.work_days_offset, rs.step_due_dtm, rs.pos
	     FROM csrimp.map_route_step mrs, csrimp.map_route mr, csrimp.route_step rs
	    WHERE rs.route_id = mr.old_route_id
	      AND rs.route_step_id = mrs.old_route_step_id;

	INSERT INTO csr.route_step_user (route_step_id, csr_user_sid, reminder_sent_dtm, overdue_sent_dtm, declined_sent_dtm)
	   SELECT mrs.new_route_step_id, mu.new_sid, rsu.reminder_sent_dtm, rsu.overdue_sent_dtm, rsu.declined_sent_dtm
	     FROM csrimp.route_step_user rsu, csrimp.map_route_step mrs, csrimp.map_sid mu
	    WHERE rsu.route_step_id = mrs.old_route_step_id
	      AND rsu.csr_user_sid = mu.old_sid;

	-- fix the current step
	UPDATE csr.section s
	   SET (s.current_route_step_id) =
			(SELECT mrs.new_route_step_id
			   FROM csrimp.section si, csrimp.map_route_step mrs, csrimp.map_sid ms
			  WHERE si.current_route_step_id = mrs.old_route_step_id
			    AND si.section_sid = ms.old_sid
			    AND ms.new_sid = s.section_sid);

	INSERT INTO csr.attachment_history (section_sid, version_number, attachment_id, attach_name, pg_num, attach_comment)
		SELECT /*+CARDINALITY(ah, 1000) CARDINALITY(ma, 1000)*/
			   ms.new_sid, version_number, ma.new_attachment_id, attach_name, pg_num, attach_comment
		  FROM csrimp.attachment_history ah, csrimp.map_sid ms,
		  	   csrimp.map_attachment ma
		 WHERE ah.section_sid = ms.old_sid
		   AND ah.attachment_id = ma.old_attachment_id;

	INSERT INTO csr.section_comment (section_comment_id, section_sid, in_reply_to_id,
		comment_text, entered_by_sid, entered_dtm, is_closed)
		SELECT /*+CARDINALITY(msc, 1000) CARDINALITY(sc, 1000) CARDINALITY(msr, 1000)*/
			   msc.new_section_comment_id, ms.new_sid, msr.new_section_comment_id,
			   comment_text, meu.new_sid, sc.entered_dtm, sc.is_closed
		  FROM csrimp.section_comment sc, csrimp.map_sid ms, csrimp.map_section_comment msc,
		  	   csrimp.map_section_comment msr, csrimp.map_sid meu
		 WHERE sc.section_comment_id = msc.old_section_comment_id
		   AND sc.section_sid = ms.old_sid(+)
		   AND sc.in_reply_to_id = msr.old_section_comment_id(+)
		   AND sc.entered_by_sid = meu.old_sid;

	INSERT INTO csr.section_trans_comment (section_trans_comment_id, section_sid, entered_by_sid, entered_dtm, comment_text)
		SELECT /*+CARDINALITY(mstc, 1000) CARDINALITY(stc, 1000)*/
			   mstc.new_section_t_comment_id, ms.new_sid, meu.new_sid, stc.entered_dtm, stc.comment_text
		  FROM csrimp.section_trans_comment stc, csrimp.map_section_trans_comment mstc, csrimp.map_sid ms, csrimp.map_sid meu
		 WHERE stc.section_trans_comment_id = mstc.old_section_t_comment_id
		   AND stc.section_sid = ms.old_sid(+)
		   AND stc.entered_by_sid = meu.old_sid;

	INSERT INTO csr.section_cart_folder (section_cart_folder_id, parent_id, name, is_visible, is_root)
	   SELECT mscf0.new_section_cart_folder_id, mscf1.new_section_cart_folder_id, scf.name, scf.is_visible, scf.is_root
	     FROM csrimp.section_cart_folder scf, csrimp.map_section_cart_folder mscf0, csrimp.map_section_cart_folder mscf1
	    WHERE scf.section_cart_folder_id = mscf0.old_section_cart_folder_id
		  AND scf.parent_id = mscf1.old_section_cart_folder_id (+);

	INSERT INTO csr.section_cart (section_cart_id, name, section_cart_folder_id)
	   SELECT msc.new_section_cart_id, sc.name, mscf.new_section_cart_folder_id
	     FROM csrimp.section_cart sc, csrimp.map_section_cart msc, csrimp.map_section_cart_folder mscf
	    WHERE sc.section_cart_id = msc.old_section_cart_id
		  AND sc.section_cart_folder_id = mscf.old_section_cart_folder_id;

	INSERT INTO csr.section_cart_member (section_cart_id, section_sid)
	   SELECT msc.new_section_cart_id, ms.new_sid
	     FROM csrimp.section_cart_member scm, csrimp.map_section_cart msc, map_sid ms
	    WHERE scm.section_cart_id = msc.old_section_cart_id
	      AND scm.section_sid = ms.old_sid;

	INSERT INTO csr.section_tag (parent_id, section_tag_id, tag, active)
	   SELECT pmst.new_section_tag_id, mst.new_section_tag_id, st.tag, st.active
	     FROM csrimp.section_tag st, csrimp.map_section_tag pmst, csrimp.map_section_tag mst
	    WHERE st.section_tag_id = mst.old_section_tag_id
	      AND st.parent_id = pmst.old_section_tag_id(+)
	    ORDER BY section_tag_id;

	INSERT INTO csr.section_tag_member (section_tag_id, section_sid)
	   SELECT mst.new_section_tag_id, ms.new_sid
	     FROM csrimp.section_tag_member stm, csrimp.map_section_tag mst, csrimp.map_sid ms
	    WHERE stm.section_tag_id = mst.old_section_tag_id
	      AND stm.section_sid = ms.old_sid;

	INSERT INTO csr.section_alert (section_alert_id, customer_alert_type_id, section_sid,
		raised_dtm, from_user_sid, notify_user_sid, flow_state_id, route_step_id, sent_dtm, cancelled_dtm)
		SELECT /*+CARDINALITY(sa, 1000) CARDINALITY(msa, 1000) CARDINALITY(ms, 1000) CARDINALITY(mcat, 1000) CARDINALITY(fu, 1000) CARDINALITY(nu, 1000)  CARDINALITY(mfs, 1000)  CARDINALITY(mrs, 1000)*/
			   msa.new_section_alert_id, mcat.new_customer_alert_type_id, ms.new_sid, sa.raised_dtm, fu.new_sid, nu.new_sid, mfs.new_flow_state_id, mrs.new_route_step_id, sa.sent_dtm, sa.cancelled_dtm
		  FROM csrimp.section_alert sa, csrimp.map_section_alert msa, csrimp.map_sid ms, csrimp.map_customer_alert_type mcat, csrimp.map_sid fu, csrimp.map_sid nu, csrimp.map_flow_state mfs, csrimp.map_route_step mrs
		  WHERE sa.section_alert_id = msa.old_section_alert_id
		    AND sa.section_sid = ms.old_sid
		    AND sa.customer_alert_type_id = mcat.old_customer_alert_type_id
		    AND sa.from_user_sid = fu.old_sid
		    AND sa.notify_user_sid = nu.old_sid
		    AND sa.flow_state_id = mfs.old_flow_state_id
		    AND sa.route_step_id = mrs.old_route_step_id;

	INSERT INTO csr.section_transition (section_transition_sid, from_section_status_sid, to_section_status_sid)
		SELECT mt.new_sid, mfs.new_sid, mts.new_sid
		  FROM csrimp.section_transition st, csrimp.map_sid mt, csrimp.map_sid mfs, csrimp.map_sid mts
		 WHERE st.section_transition_sid = mt.old_sid
		   AND st.from_section_status_sid = mfs.old_sid
		   AND st.to_section_status_sid = mts.old_sid;

	INSERT INTO csr.route_log (
				route_log_id,
				csr_user_sid,
				description,
				log_date,
				param_1,
				param_2,
				param_3,
				route_id,
				route_step_id,
				summary
	   ) SELECT mrl.new_route_log_id,
				ms.new_sid,
				rl.description,
				rl.log_date,
				rl.param_1,
				rl.param_2,
				rl.param_3,
				mr.new_route_id,
				mrs.new_route_step_id,
				rl.summary
		   FROM csrimp.route_log rl,
				csrimp.map_route_log mrl,
				csrimp.map_sid ms,
				csrimp.map_route mr,
				csrimp.map_route_step mrs
		  WHERE rl.route_log_id = mrl.old_route_log_id
			AND rl.csr_user_sid = ms.old_sid
			AND rl.route_id = mr.old_route_id
			AND rl.route_step_id = mrs.old_route_step_id;

	INSERT INTO csr.route_step_vote (
				route_step_id,
				user_sid,
				dest_flow_state_id,
				dest_route_step_id,
				is_return,
				vote_direction,
				vote_dtm
	   ) SELECT mrs.new_route_step_id,
				ms.new_sid,
				mfs.new_flow_state_id,
				mrs1.new_route_step_id,
				rsv.is_return,
				rsv.vote_direction,
				rsv.vote_dtm
		   FROM csrimp.route_step_vote rsv,
				csrimp.map_route_step mrs,
				csrimp.map_sid ms,
				csrimp.map_flow_state mfs,
				csrimp.map_route_step mrs1
		  WHERE rsv.route_step_id = mrs.old_route_step_id
			AND rsv.user_sid = ms.old_sid
			AND rsv.dest_flow_state_id = mfs.old_flow_state_id(+)
			AND rsv.dest_route_step_id = mrs1.old_route_step_id(+);
END;

PROCEDURE CreateFlow
AS
BEGIN
	INSERT INTO csr.customer_flow_alert_class (flow_alert_class)
	    SELECT flow_alert_class
		  FROM csrimp.customer_flow_alert_class;

	INSERT INTO csr.flow (flow_sid, label, default_state_id, helper_pkg, owner_can_create, aggregate_ind_group_id, flow_alert_class)
		SELECT ms.new_sid, f.label, NULL, f.helper_pkg, f.owner_can_create, maig.new_aggregate_ind_group_id, f.flow_alert_class
		  FROM csrimp.flow f, map_sid ms, map_aggregate_ind_group maig
		 WHERE ms.old_sid = f.flow_sid
		   AND f.aggregate_ind_group_id = maig.old_aggregate_ind_group_id(+);

	INSERT INTO csr.flow_state (flow_state_id, flow_sid, label, lookup_key, attributes_xml,
		is_deleted, state_colour, pos, is_final, is_editable_by_owner, ind_sid, move_from_flow_state_id,
		flow_state_nature_id, time_spent_ind_sid, survey_editable)
		SELECT mfs.new_flow_state_id, mf.new_sid, fs.label, fs.lookup_key, fs.attributes_xml,
			   fs.is_deleted, fs.state_colour, fs.pos, fs.is_final, fs.is_editable_by_owner,
			   mi.new_sid, mmtfs.new_flow_state_id, fs.flow_state_nature_id, mt.new_sid, fs.survey_editable
		  FROM csrimp.flow_state fs
		  JOIN csrimp.map_flow_state mfs ON fs.flow_state_id = mfs.old_flow_state_id
		  JOIN csrimp.map_sid mf ON fs.flow_sid = mf.old_sid
	 LEFT JOIN csrimp.map_sid mi ON fs.ind_sid = mi.old_sid
	 LEFT JOIN csrimp.map_flow_state mmtfs ON fs.move_from_flow_state_id = mmtfs.old_flow_state_id
	 LEFT JOIN csrimp.map_sid mt ON fs.ind_sid = mt.old_sid;

	UPDATE csr.flow f
	   SET f.default_state_id = (
			SELECT mfs.new_flow_state_id
			  FROM csrimp.map_flow_state mfs, csrimp.flow fo, csrimp.map_sid mf
			 WHERE f.flow_sid = mf.new_sid
			   AND mf.old_sid = fo.flow_sid
			   AND fo.default_state_id = mfs.old_flow_state_id);

	UPDATE csr.customer c
	   SET c.property_flow_sid = (
			SELECT ms.new_sid
			  FROM csrimp.customer cc, map_sid ms
			 WHERE cc.property_flow_sid = ms.old_sid(+) );

	UPDATE csr.customer c
	   SET c.chemical_flow_sid = (
			SELECT ms.new_sid
			  FROM csrimp.customer cc, map_sid ms
			 WHERE cc.chemical_flow_sid = ms.old_sid(+) );

	INSERT INTO csr.flow_involvement_type (flow_involvement_type_id, product_area, label, css_class, lookup_key)
		SELECT mfit.new_flow_involvement_type_id, fit.product_area, fit.label, fit.css_class, fit.lookup_key
		  FROM csrimp.flow_involvement_type fit
		  JOIN csrimp.map_flow_involvement_type mfit ON mfit.old_flow_involvement_type_id = fit.flow_involvement_type_id;

	INSERT INTO csr.flow_state_group (flow_state_group_id, label, lookup_key, count_ind_sid)
		SELECT mfsg.new_flow_state_group_id, fsg.label, fsg.lookup_key, mi.new_sid
		  FROM csrimp.flow_state_group fsg
		  JOIN csrimp.map_flow_state_group mfsg ON mfsg.old_flow_state_group_id = fsg.flow_state_group_id
		  LEFT JOIN csrimp.ind i ON i.ind_sid = fsg.count_ind_sid
		  LEFT JOIN csrimp.map_sid mi ON i.ind_sid = mi.old_sid;

	INSERT INTO csr.customer_flow_capability (
				flow_capability_id,
				default_permission_set,
				description,
				flow_alert_class,
				lookup_key,
				perm_type,
				is_system_managed
	   ) SELECT mcfc.new_customer_flow_cap_id,
				cfc.default_permission_set,
				cfc.description,
				cfc.flow_alert_class,
				cfc.lookup_key,
				cfc.perm_type,
				cfc.is_system_managed
		   FROM csrimp.customer_flow_capability cfc,
				csrimp.map_customer_flow_cap mcfc
		  WHERE cfc.flow_capability_id = mcfc.old_customer_flow_cap_id;

	INSERT INTO csr.flow_state_group_member (flow_state_id, flow_state_group_id, before_report_date, after_report_date)
		SELECT mfs.new_flow_state_id, mfsg.new_flow_state_group_id, fsgm.before_report_date, fsgm.after_report_date
		  FROM csrimp.flow_state_group_member fsgm
		  JOIN csrimp.map_flow_state mfs ON fsgm.flow_state_id = mfs.old_flow_state_id
		  JOIN csrimp.map_flow_state_group mfsg ON mfsg.old_flow_state_group_id = fsgm.flow_state_group_id;

	INSERT INTO csr.flow_inv_type_alert_class (flow_involvement_type_id, flow_alert_class)
		SELECT mfit.new_flow_involvement_type_id, fitac.flow_alert_class
		  FROM csrimp.flow_inv_type_alert_class fitac
		  JOIN csrimp.map_flow_involvement_type mfit ON mfit.old_flow_involvement_type_id = fitac.flow_involvement_type_id;

	INSERT INTO csr.flow_state_survey_tag (flow_state_id, tag_id)
		SELECT mfs.new_flow_state_id, mt.new_tag_id
		  FROM flow_state_survey_tag fsst
		  JOIN map_flow_state mfs ON fsst.flow_state_id = mfs.old_flow_state_id
		  JOIN map_tag mt ON fsst.tag_id = mt.old_tag_id;
END;

PROCEDURE CreateFlowItems
AS
BEGIN
	INSERT INTO csr.flow_item (flow_item_id, flow_sid, current_state_id, survey_response_id,
		dashboard_instance_id)
		SELECT /*+CARDINALITY(fi, 50000) CARDINALITY(mfi, 50000) CARDINALITY(ms, 50000)
				  CARDINALITY(mfs, 50000) CARDINALITY(msr, 1000), CARDINALITY(mdi, 1000)*/
			   mfi.new_flow_item_id, ms.new_sid, mfs.new_flow_state_id,
			   /*msr.new_survey_response_id*/ null, -- response id done when we import survey responses
			   /*mdi.new_dashboard_instance_id*/ null -- dashboard set when dashboards are craeted
		  FROM csrimp.flow_item fi, csrimp.map_flow_item mfi, csrimp.map_sid ms,
		  	   csrimp.map_flow_state mfs
		  	   -- csrimp.map_qs_survey_response msr,
		  	   -- csrimp.map_dashboard_instance mdi
		 WHERE fi.flow_item_id = mfi.old_flow_item_id
		   AND fi.flow_sid = ms.old_sid
		   AND fi.current_state_id = mfs.old_flow_state_id;
		   --AND fi.survey_response_id = msr.old_survey_response_id(+)
		   --AND fi.dashboard_instance_id = mdi.old_dashboard_instance_id(+);

	UPDATE /*+CARDINALITY(fi, 50000)*/ csr.flow_item nfi
	   SET nfi.last_flow_state_log_id = (
			SELECT /*+CARDINALITY(mfsl, 50000) CARDINALITY(ofi, 50000) CARDINALITY(mfi, 50000)*/
				   mfsl.new_flow_state_log_id
			  FROM csrimp.map_flow_state_log mfsl, csrimp.flow_item ofi, csrimp.map_flow_item mfi
			 WHERE mfi.new_flow_item_id = nfi.flow_item_id
			   AND mfi.old_flow_item_id = ofi.flow_item_id
			   AND ofi.last_flow_state_log_id = mfsl.old_flow_state_log_id);

	INSERT INTO csr.flow_item_region(flow_item_id, region_sid)
	 SELECT mfi.new_flow_item_id, mrs.new_sid
	   FROM csrimp.flow_item_region fir, csrimp.map_flow_item mfi, csrimp.map_sid mrs
		WHERE fir.flow_item_id = mfi.old_flow_item_id
		  AND fir.region_sid = mrs.old_sid(+);

	INSERT INTO csr.flow_item_involvement (flow_involvement_type_id, flow_item_id, user_sid)
		SELECT mfit.new_flow_involvement_type_id, mfi.new_flow_item_id, ms.new_sid
		  FROM csrimp.flow_item_involvement fii
		  JOIN csrimp.map_flow_item mfi ON mfi.old_flow_item_id = fii.flow_item_id
		  JOIN csrimp.map_sid ms ON ms.old_sid = fii.user_sid
		  JOIN csrimp.map_flow_involvement_type mfit ON mfit.old_flow_involvement_type_id = fii.flow_involvement_type_id;

	INSERT INTO csr.flow_involvement_cover (user_cover_id, user_giving_cover_sid,
		user_being_covered_sid, flow_item_id, flow_involvement_type_id)
		SELECT muc.new_user_cover_id, mugc.new_sid, mubc.new_sid, mfi.new_flow_item_id,
			   mfit.new_flow_involvement_type_id
		  FROM csrimp.flow_involvement_cover fic
		  JOIN csrimp.map_user_cover muc ON muc.old_user_cover_id = fic.user_cover_id
		  JOIN csrimp.map_sid mugc ON fic.user_giving_cover_sid = mugc.old_sid
		  JOIN csrimp.map_sid mubc ON fic.user_being_covered_sid = mubc.old_sid
		  JOIN csrimp.map_flow_item mfi ON mfi.old_flow_item_id = fic.flow_item_id
		  JOIN csrimp.map_flow_involvement_type mfit ON mfit.old_flow_involvement_type_id = fic.flow_involvement_type_id;

	INSERT INTO csr.flow_state_log (flow_state_log_id, flow_item_id, flow_state_id, set_by_user_sid,
		set_dtm, comment_text)
		SELECT /*+CARDINALITY(fsl, 50000) CARDINALITY(mfsl, 50000) CARDINALITY(mfi, 50000)
				  CARDINALITY(mfs, 50000) CARDINALITY(mu, 50000)*/
			   mfsl.new_flow_state_log_id, mfi.new_flow_item_id, mfs.new_flow_state_id, mu.new_sid,
			   fsl.set_dtm, fsl.comment_text
		  FROM csrimp.flow_state_log fsl, csrimp.map_flow_state_log mfsl,
		  	   csrimp.map_flow_item mfi, csrimp.map_flow_state mfs, csrimp.map_sid mu
		 WHERE fsl.flow_state_log_id = mfsl.old_flow_state_log_id
		   AND fsl.flow_item_id = mfi.old_flow_item_id
		   AND fsl.flow_state_id = mfs.old_flow_state_id
		   AND fsl.set_by_user_sid = mu.old_sid;

	INSERT INTO csr.flow_state_log_file (flow_state_log_file_id, flow_state_log_id, filename,
		mime_type, data, sha1, uploaded_dtm)
		SELECT /*+CARDINALITY(fslf, 50000) CARDINALITY(mfsl, 50000)*/
			   csr.flow_state_log_file_id_seq.nextval, mfsl.new_flow_state_log_id,
			   fslf.filename, fslf.mime_type, fslf.data, fslf.sha1, fslf.uploaded_dtm
		  FROM csrimp.flow_state_log_file fslf, csrimp.map_flow_state_log mfsl
		 WHERE fslf.flow_state_log_id = mfsl.old_flow_state_log_id;

	INSERT INTO csr.flow_state_role (flow_state_id, role_sid, is_editable, group_sid)
		SELECT /*+CARDINALITY(fsr, 50000) CARDINALITY(mfs, 50000) CARDINALITY(mr, 50000)*/
			   mfs.new_flow_state_id, mr.new_sid, fsr.is_editable, mg.new_sid
		  FROM csrimp.flow_state_role fsr, csrimp.map_flow_state mfs,
		  	   csrimp.map_sid mr, csrimp.map_sid mg
		 WHERE fsr.flow_state_id = mfs.old_flow_state_id
		   AND fsr.role_sid = mr.old_sid(+)
		   AND fsr.group_sid = mg.old_sid(+);

	INSERT INTO csr.flow_state_cms_col (flow_state_id, column_sid, is_editable)
		SELECT /*+CARDINALITY(fsr, 50000) CARDINALITY(mfs, 50000) CARDINALITY(mr, 50000)*/
			   mfs.new_flow_state_id, mc.new_column_id, fsc.is_editable
		  FROM csrimp.flow_state_cms_col fsc, csrimp.map_flow_state mfs,
		  	   csrimp.map_cms_tab_column mc
		 WHERE fsc.flow_state_id = mfs.old_flow_state_id
		   AND fsc.column_sid = mc.old_column_id;

	INSERT INTO csr.flow_state_involvement (flow_state_id, flow_involvement_type_id)
		SELECT /*+CARDINALITY(fsi, 50000) CARDINALITY(mfs, 50000)*/
			   mfs.new_flow_state_id, mfit.new_flow_involvement_type_id
		  FROM csrimp.flow_state_involvement fsi
		  JOIN csrimp.map_flow_state mfs ON fsi.flow_state_id = mfs.old_flow_state_id
		  JOIN csrimp.map_flow_involvement_type mfit ON mfit.old_flow_involvement_type_id = fsi.flow_involvement_type_id;

	INSERT INTO csr.flow_state_role_capability (flow_state_rl_cap_id, flow_state_id,
		flow_capability_id, role_sid, flow_involvement_type_id, permission_set, group_sid)
		SELECT /*+CARDINALITY(fsrc, 50000) CARDINALITY(mfs, 50000) */
			   mfsrc.new_flow_state_rl_cap_id, mfs.new_flow_state_id,
			   fsrc.flow_capability_id, mr.new_sid, mfit.new_flow_involvement_type_id,
			   fsrc.permission_set, mg.new_sid
		  FROM csrimp.flow_state_role_capability fsrc, csrimp.map_flow_state mfs,
			   csrimp.map_sid mr, csrimp.map_flow_state_rl_cap mfsrc,
			   csr.flow_capability fc, csrimp.map_flow_involvement_type mfit, csrimp.map_sid mg
		 WHERE fsrc.flow_state_id = mfs.old_flow_state_id
		   AND fsrc.role_sid = mr.old_sid(+)
		   AND fsrc.group_sid = mg.old_sid(+)
		   AND fsrc.flow_capability_id = fc.flow_capability_id
		   AND fsrc.flow_state_rl_cap_id = mfsrc.old_flow_state_rl_cap_id
		   AND fsrc.flow_involvement_type_id = mfit.old_flow_involvement_type_id(+);

	INSERT INTO csr.flow_state_role_capability (flow_state_rl_cap_id, flow_state_id,
		flow_capability_id, role_sid, flow_involvement_type_id, permission_set, group_sid)
		SELECT /*+CARDINALITY(fsrc, 50000) CARDINALITY(mfs, 50000) */
			   mfsrc.new_flow_state_rl_cap_id, mfs.new_flow_state_id,
			   mcfc.new_customer_flow_cap_id, mr.new_sid, mfit.new_flow_involvement_type_id,
			   fsrc.permission_set, mg.new_sid
		  FROM csrimp.flow_state_role_capability fsrc, csrimp.map_flow_state mfs,
			   csrimp.map_sid mr, csrimp.map_flow_state_rl_cap mfsrc,
			   csrimp.map_customer_flow_cap mcfc, csrimp.map_flow_involvement_type mfit, csrimp.map_sid mg
		 WHERE fsrc.flow_state_id = mfs.old_flow_state_id
		   AND fsrc.role_sid = mr.old_sid(+)
		   AND fsrc.group_sid = mg.old_sid(+)
		   AND fsrc.flow_capability_id = mcfc.old_customer_flow_cap_id
		   AND fsrc.flow_state_rl_cap_id = mfsrc.old_flow_state_rl_cap_id
		   AND fsrc.flow_involvement_type_id = mfit.old_flow_involvement_type_id(+);

	INSERT INTO csr.flow_state_trans_helper (flow_sid, helper_sp, label)
		SELECT /*+CARDINALITY(fsth, 1000) CARDINALITY(mf, 50000)*/
			   mf.new_sid, MapCustomerSchema(fsth.helper_sp), fsth.label
		  FROM csrimp.flow_state_trans_helper fsth, csrimp.map_sid mf
		 WHERE fsth.flow_sid = mf.old_sid;

	INSERT INTO csr.flow_state_transition (flow_state_transition_id, from_state_id, to_state_id,
		flow_sid, verb, ask_for_comment, pos, attributes_xml, helper_sp, lookup_key, mandatory_fields_message,
		hours_before_auto_tran, button_icon_path, owner_can_set, group_sid_can_set, auto_schedule_xml, auto_trans_type, last_run_dtm, enforce_validation)
		SELECT /*+CARDINALITY(fst, 50000) CARDINALITY(mfst, 50000) CARDINALITY(mfsf, 50000)
			      CARDINALITY(mfst, 50000) CARDINALITY(mf, 50000)*/
			   mfst.new_flow_state_transition_id, mfsf.new_flow_state_id, mfst.new_flow_state_id, mf.new_sid,
			   fst.verb, fst.ask_for_comment, fst.pos, fst.attributes_xml, MapCustomerSchema(fst.helper_sp), fst.lookup_key,
			   fst.mandatory_fields_message, fst.hours_before_auto_tran, fst.button_icon_path, fst.owner_can_set,
			   mgcs.new_sid, fst.auto_schedule_xml, fst.auto_trans_type, fst.last_run_dtm, fst.enforce_validation
		  FROM csrimp.flow_state_transition fst, csrimp.map_flow_state_transition mfst,
		  	   csrimp.map_flow_state mfsf, csrimp.map_flow_state mfst, csrimp.map_sid mf,
			   csrimp.map_sid mgcs
		 WHERE fst.flow_state_transition_id = mfst.old_flow_state_transition_id
		   AND fst.from_state_id = mfsf.old_flow_state_id
		   AND fst.to_state_id = mfst.old_flow_state_id
		   AND fst.flow_sid = mf.old_sid
		   AND fst.group_sid_can_set = mgcs.old_sid(+);

	INSERT INTO csr.flow_state_transition_role (flow_state_transition_id, from_state_id, role_sid, group_sid)
		SELECT /*+CARDINALITY(fstr, 50000), CARDINALITY(mfst, 50000) CARDINALITY(mfs, 50000)
			      CARDINALITY(mr, 50000)*/
			   mfst.new_flow_state_transition_id, mfs.new_flow_state_id, mr.new_sid, mg.new_sid
		  FROM csrimp.flow_state_transition_role fstr, csrimp.map_flow_state_transition mfst,
		  	   csrimp.map_flow_state mfs, csrimp.map_sid mr, csrimp.map_sid mg
		 WHERE fstr.flow_state_transition_id = mfst.old_flow_state_transition_id
		   AND fstr.from_state_id = mfs.old_flow_state_id
		   AND fstr.role_sid = mr.old_sid(+)
		   AND fstr.group_sid = mg.old_sid(+);

	INSERT INTO csr.flow_state_transition_cms_col (flow_state_transition_id, from_state_id, column_sid)
		SELECT /*+CARDINALITY(fstr, 50000), CARDINALITY(mfst, 50000) CARDINALITY(mfs, 50000)
			      CARDINALITY(mr, 50000)*/
			   mfst.new_flow_state_transition_id, mfs.new_flow_state_id, mc.new_column_id
		  FROM csrimp.flow_state_transition_cms_col fstc, csrimp.map_flow_state_transition mfst,
		  	   csrimp.map_flow_state mfs, csrimp.map_cms_tab_column mc
		 WHERE fstc.flow_state_transition_id = mfst.old_flow_state_transition_id
		   AND fstc.from_state_id = mfs.old_flow_state_id
		   AND fstc.column_sid = mc.old_column_id;

	INSERT INTO csr.flow_state_transition_inv (flow_state_transition_id, from_state_id, flow_involvement_type_id)
		SELECT /*+CARDINALITY(fsti, 50000), CARDINALITY(mfst, 50000) CARDINALITY(mfs, 50000)*/
			   mfst.new_flow_state_transition_id, mfs.new_flow_state_id, mfit.new_flow_involvement_type_id
		  FROM csrimp.flow_state_transition_inv fsti, csrimp.map_flow_state_transition mfst,
		  	   csrimp.map_flow_state mfs, csrimp.map_flow_involvement_type mfit
		 WHERE fsti.flow_state_transition_id = mfst.old_flow_state_transition_id
		   AND fsti.from_state_id = mfs.old_flow_state_id
		   AND fsti.flow_involvement_type_id = mfit.old_flow_involvement_type_id;

	INSERT INTO csr.flow_alert_type (customer_alert_type_id, flow_sid, label, deleted, lookup_key)
		SELECT /*+CARDINALITY(fat, 1000) CARDINALITY(mcat, 1000) CARDINALITY(mf, 50000)*/
			   mcat.new_customer_alert_type_id, mf.new_sid, fat.label, fat.deleted, fat.lookup_key
		  FROM csrimp.flow_alert_type fat, csrimp.map_customer_alert_type mcat,
		  	   csrimp.map_sid mf
		 WHERE fat.customer_alert_type_id = mcat.old_customer_alert_type_id
		   AND fat.flow_sid = mf.old_sid;
END;

PROCEDURE CreateCms
AS
BEGIN
	INSERT INTO cms.app_schema (oracle_schema)
		SELECT /*+CARDINALITY(cas, 10) CARDINALITY(mr, 10)*/
			   ms.new_oracle_schema
		  FROM csrimp.cms_app_schema cas, csrimp.map_cms_schema ms
		 WHERE cas.oracle_schema = ms.old_oracle_schema;

	INSERT INTO cms.app_schema_table (oracle_schema, oracle_table)
		SELECT /*+CARDINALITY(ast, 10) CARDINALITY(ms, 10)*/
			   ms.new_oracle_schema, ast.oracle_table
		  FROM csrimp.cms_app_schema_table ast, csrimp.map_cms_schema ms
		 WHERE ast.oracle_schema = ms.old_oracle_schema;

	INSERT INTO cms.oracle_tab (oracle_schema, oracle_table)
		SELECT DISTINCT ms.new_oracle_schema, t.oracle_table
		  FROM csrimp.cms_tab t, csrimp.map_sid mt, csrimp.map_cms_schema ms
		 WHERE t.tab_sid = mt.old_sid
		   AND t.oracle_schema = ms.old_oracle_schema
		 MINUS
		SELECT oracle_schema, oracle_table
		  FROM cms.oracle_tab;

	INSERT INTO cms.tab (tab_sid, oracle_schema, oracle_table, description, format_sql,
		pk_cons_id, managed, auto_registered, cms_editor, issues, flow_sid, policy_function, policy_view,
		is_view, helper_pkg, show_in_company_filter, parent_tab_sid, show_in_property_filter,
		securable_fk_cons_id, is_basedata, enum_translation_tab_sid, show_in_product_filter,
		storage_location, managed_version)
		SELECT /*+CARDINALITY(t, 100) CARDINALITY(mt, 50000) CARDINALITY(ms, 10)
				  CARDINALITY(mf, 50000)*/
			   mt.new_sid, ms.new_oracle_schema, t.oracle_table,
			   t.description, t.format_sql, null /* pk_cons_id */, t.managed, t.auto_registered,
			   t.cms_editor, t.issues, mf.new_sid, t.policy_function, t.policy_view, t.is_view, t.helper_pkg, t.show_in_company_filter,
			   mt2.new_sid, show_in_property_filter, null /* securable_fk_cons_id */, is_basedata,
			   mt3.new_sid, t.show_in_product_filter,  t.storage_location, t.managed_version
		  FROM csrimp.cms_tab t, csrimp.map_sid mt, csrimp.map_cms_schema ms, csrimp.map_sid mf,
			   csrimp.map_sid mt2, csrimp.map_sid mt3
		 WHERE t.tab_sid = mt.old_sid
		   AND t.oracle_schema = ms.old_oracle_schema
		   AND t.flow_sid = mf.old_sid(+)
		   AND t.parent_tab_sid = mt2.old_sid (+)
		   AND t.enum_translation_tab_sid = mt3.old_sid(+);

	INSERT INTO cms.tab_column (column_sid, tab_sid, oracle_column, description, pos, col_type,
		master_column_sid, enumerated_desc_field, enumerated_pos_field, enumerated_hidden_field,
		enumerated_colour_field, enumerated_extra_fields, help, check_msg, calc_xml, data_type,
		data_length, data_precision, data_scale, nullable, char_length, value_placeholder,
		helper_pkg, tree_desc_field, tree_id_field, tree_parent_id_field, full_text_index_name,
		incl_in_active_user_filter, owner_permission, enumerated_colpos_field, coverable,
		default_length, data_default, measure_sid, measure_conv_column_sid,
		measure_conv_date_column_sid, auto_sequence, show_in_filter, include_in_search,
		show_in_breakdown, form_selection_desc_field, form_selection_pos_field,
		form_selection_form_field, form_selection_hidden_field, restricted_by_policy, format_mask)
		SELECT /*+CARDINALITY(tc, 50000) CARDINALITY(mtc, 50000) CARDINALITY(mt, 50000)
				  CARDINALITY(mtcm, 50000)*/
			   mtc.new_column_id, mt.new_sid, tc.oracle_column, tc.description, tc.pos, tc.col_type,
			   mtcm.new_column_id, tc.enumerated_desc_field, tc.enumerated_pos_field,
			   tc.enumerated_hidden_field, tc.enumerated_colour_field, tc.enumerated_extra_fields,
			   tc.help, tc.check_msg, tc.calc_xml, tc.data_type, tc.data_length, tc.data_precision,
			   tc.data_scale, tc.nullable, tc.char_length, tc.value_placeholder, tc.helper_pkg,
			   tc.tree_desc_field, tc.tree_id_field, tc.tree_parent_id_field, tc.full_text_index_name,
			   tc.incl_in_active_user_filter, tc.owner_permission, tc.enumerated_colpos_field,
			   tc.coverable, tc.default_length, tc.data_default, mm.new_sid, mmcc.new_column_id,
			   mmcdc.new_column_id, tc.auto_sequence, tc.show_in_filter, tc.include_in_search,
			   tc.show_in_breakdown, tc.form_selection_desc_field, tc.form_selection_pos_field,
			   tc.form_selection_form_field, tc.form_selection_hidden_field, tc.restricted_by_policy,
			   tc.format_mask
		  FROM csrimp.cms_tab_column tc, csrimp.map_cms_tab_column mtc, csrimp.map_sid mt,
		  	   csrimp.map_cms_tab_column mtcm, csrimp.map_sid mm,
			   csrimp.map_cms_tab_column mmcc, csrimp.map_cms_tab_column mmcdc
		 WHERE tc.column_sid = mtc.old_column_id
		   AND tc.tab_sid = mt.old_sid
		   AND tc.master_column_sid = mtcm.old_column_id(+)
		   AND tc.measure_sid = mm.old_sid(+)
		   AND tc.measure_conv_column_sid = mmcc.old_column_id(+)
		   AND tc.measure_conv_date_column_sid = mmcdc.old_column_id(+);

	-- fix helper procedures to point at any remapped cms schemas
	UPDATE cms.tab
	   SET policy_function = MapCustomerSchema(policy_function),
	       helper_pkg = MapCustomerSchema(helper_pkg)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	UPDATE cms.tab_column
	   SET helper_pkg = MapCustomerSchema(helper_pkg)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO cms.tab_column_measure (column_sid, measure_sid)
		SELECT mtc.new_column_id, mm.new_sid
		  FROM csrimp.cms_tab_column_measure tcm, csrimp.map_cms_tab_column mtc, csrimp.map_sid mm
		 WHERE tcm.column_sid = mtc.old_column_id
		   AND tcm.measure_sid = mm.old_sid;

	INSERT INTO cms.tab_column_role_permission (column_sid, role_sid, permission, policy_function)
		SELECT /*+CARDINALITY(tcrp, 50000) CARDINALITY(mtc, 50000) CARDINALITY(mr, 50000)*/
			   mtc.new_column_id, mr.new_sid, permission, tcrp.policy_function
		  FROM csrimp.cms_tab_column_role_permission tcrp, csrimp.map_cms_tab_column mtc,
		  	   csrimp.map_sid mr
		 WHERE tcrp.column_sid = mtc.old_column_id
		   AND tcrp.role_sid = mr.old_sid;

	INSERT INTO cms.flow_tab_column_cons (column_sid, flow_state_id, nullable)
		SELECT /*+CARDINALITY(ftcc, 1000) CARDINALITY(mtc, 1000), CARDINALITY(mfs, 1000)*/
			   mtc.new_column_id, mfs.new_flow_state_id, ftcc.nullable
		  FROM csrimp.cms_flow_tab_column_cons ftcc, csrimp.map_cms_tab_column mtc,
		  	   csrimp.map_flow_state mfs
		 WHERE ftcc.column_sid = mtc.old_column_id
		   AND ftcc.flow_state_id = mfs.old_flow_state_id;

	INSERT INTO cms.uk_cons (uk_cons_id, tab_sid, constraint_owner, constraint_name)
		SELECT /*+CARDINALITY(uc, 2000) CARDINALITY(muc, 2000) CARDINALITY(mt, 50000)*/
			   muc.new_uk_cons_id, mt.new_sid, uc.constraint_owner, uc.constraint_name
		  FROM csrimp.cms_uk_cons uc, csrimp.map_cms_uk_cons muc, csrimp.map_sid mt
		 WHERE uc.uk_cons_id = muc.old_uk_cons_id
		   AND uc.tab_sid = mt.old_sid;

	INSERT INTO cms.uk_cons_col (uk_cons_id, column_sid, pos)
		SELECT /*+CARDINALITY(ucc, 1000) CARDINALITY(muc, 1000) CARDINALITY(mtc, 2000)*/
			   muc.new_uk_cons_id, mtc.new_column_id, ucc.pos
		  FROM csrimp.cms_uk_cons_col ucc, csrimp.map_cms_uk_cons muc, csrimp.map_cms_tab_column mtc
		 WHERE ucc.uk_cons_id = muc.old_uk_cons_id
		   AND ucc.column_sid = mtc.old_column_id;

	UPDATE /*+CARDINALITY(t, 50000)*/ cms.tab t
	   SET t.pk_cons_id = (
	   		SELECT /*+ CARDINALITY(muc, 1000) CARDINALITY(ot, 1000) CARDINALITY(ms, 50000)*/
	   			   muc.new_uk_cons_id
	   		  FROM csrimp.map_cms_uk_cons muc, csrimp.cms_tab ot, csrimp.map_sid ms
	   		 WHERE ms.new_sid = t.tab_sid
	   		   AND ms.old_sid = ot.tab_sid
	   		   AND ot.pk_cons_id = muc.old_uk_cons_id);

	INSERT INTO cms.fk_cons (fk_cons_id, tab_sid, r_cons_id, delete_rule, constraint_owner, constraint_name)
		SELECT /*+CARDINALITY(fc, 2000) CARDINALITY(mfc, 2000) CARDINALITY(mt, 50000)
				  CARDINALITY(muc, 2000)*/
			   mfc.new_fk_cons_id, mt.new_sid, muc.new_uk_cons_id, fc.delete_rule, fc.constraint_owner, fc.constraint_name
		  FROM csrimp.cms_fk_cons fc, csrimp.map_cms_fk_cons mfc, csrimp.map_sid mt,
		  	   csrimp.map_cms_uk_cons muc
		 WHERE fc.fk_cons_id = mfc.old_fk_cons_id
		   AND fc.tab_sid = mt.old_sid
		   AND fc.r_cons_id = muc.old_uk_cons_id;

	INSERT INTO cms.fk_cons_col (fk_cons_id, column_sid, pos)
		SELECT /*+CARDINALITY(fcc, 2000) CARDINALITY(mfc, 2000) CARDINALITY(mtc, 1000)*/
			   mfc.new_fk_cons_id, mtc.new_column_id, fcc.pos
		  FROM csrimp.cms_fk_cons_col fcc, csrimp.map_cms_fk_cons mfc, csrimp.map_cms_tab_column mtc
		 WHERE fcc.fk_cons_id = mfc.old_fk_cons_id
		   AND fcc.column_sid = mtc.old_column_id;

	UPDATE /*+CARDINALITY(t, 50000)*/ cms.tab t
	   SET t.securable_fk_cons_id = (
	   		SELECT /*+ CARDINALITY(mfc, 1000) CARDINALITY(ot, 1000) CARDINALITY(ms, 50000)*/
	   			   mfc.new_fk_cons_id
	   		  FROM csrimp.map_cms_fk_cons mfc, csrimp.cms_tab ot, csrimp.map_sid ms
	   		 WHERE ms.new_sid = t.tab_sid
	   		   AND ms.old_sid = ot.tab_sid
	   		   AND ot.securable_fk_cons_id = mfc.old_fk_cons_id);

	INSERT INTO cms.ck_cons (ck_cons_id, tab_sid, search_condition, constraint_owner, constraint_name)
		SELECT /*+CARDINALITY(cc, 2000) CARDINALITY(mcc, 2000) CARDINALITY(mt, 50000)*/
			   mcc.new_ck_cons_id, mt.new_sid, cc.search_condition, cc.constraint_owner, cc.constraint_name
		  FROM csrimp.cms_ck_cons cc, csrimp.map_cms_ck_cons mcc, csrimp.map_sid mt
		 WHERE cc.ck_cons_id = mcc.old_ck_cons_id
		   AND cc.tab_sid = mt.old_sid;

	INSERT INTO cms.ck_cons_col (ck_cons_id, column_sid)
		SELECT /*+CARDINALITY(ccc, 2000) CARDINALITY(mcc, 2000) CARDINALITY(mtc, 2000)*/
			   mcc.new_ck_cons_id, mtc.new_column_id
		  FROM csrimp.cms_ck_cons_col ccc, csrimp.map_cms_ck_cons mcc, csrimp.map_cms_tab_column mtc
		 WHERE ccc.ck_cons_id = mcc.old_ck_cons_id
		   AND ccc.column_sid = mtc.old_column_id;

	-- TODO: xml needs rewriting (form/filter)
	INSERT INTO cms.form (form_sid, description, parent_tab_sid, lookup_key, current_version,
			              is_report_builder, short_path, use_quick_chart, draft_form_xml, draft_file_name)
		SELECT /*+CARDINALITY(f, 1000) CARDINALITY(mf, 50000) CARDINALITY(mpt, 50000)*/
			   mf.new_sid, f.description, mpt.new_sid, f.lookup_key, f.current_version,
			   f.is_report_builder, f.short_path, f.use_quick_chart, f.draft_form_xml, f.draft_file_name
		  FROM csrimp.cms_form f, csrimp.map_sid mf, csrimp.map_sid mpt
		 WHERE f.form_sid = mf.old_sid
		   AND f.parent_tab_sid = mpt.old_sid(+);

	INSERT INTO cms.form_version (form_sid, form_version, file_name, form_xml, published_dtm,
			                      published_by_sid, version_comment)
		SELECT /*+CARDINALITY(fv, 1000) CARDINALITY(mf, 50000) CARDINALITY(mu, 50000)*/
			   mf.new_sid, fv.form_version, fv.file_name, fv.form_xml, fv.published_dtm,
			   mu.new_sid, fv.version_comment
		  FROM csrimp.cms_form_version fv, csrimp.map_sid mf, csrimp.map_sid mu
		 WHERE fv.form_sid = mf.old_sid
		   AND fv.published_by_sid = mu.old_sid;

	INSERT INTO cms.filter (filter_sid, tab_sid, name, created_by_user_sid, filter_xml, parent_sid)
		SELECT /*+CARDINALITY(f, 50000) CARDINALITY(mf, 50000) CARDINALITY(mt, 50000)
				  CARDINALITY(mu, 50000)*/
			   mf.new_sid, mt.new_sid, f.name, mu.new_sid, f.filter_xml, mp.new_sid
		  FROM csrimp.cms_filter f, csrimp.map_sid mf, csrimp.map_sid mt, csrimp.map_sid mu, csrimp.map_sid mp
		 WHERE f.filter_sid = mf.old_sid
		   AND f.tab_sid = mt.old_sid
		   AND f.created_by_user_sid = mu.old_sid(+)
		   AND f.parent_sid = mp.old_sid;

	INSERT INTO cms.display_template (display_template_id, tab_sid, template_url, priority, name, description)
		SELECT /*+CARDINALITY(dt, 1000) CARDINALITY(mdt, 1000) CARDINALITY(mt, 50000)*/
			   mdt.new_display_template_id, mt.new_sid, dt.template_url, dt.priority, dt.name, dt.description
		  FROM csrimp.cms_display_template dt, csrimp.map_cms_display_template mdt, csrimp.map_sid mt
		 WHERE dt.display_template_id = mdt.old_display_template_id
		   AND dt.tab_sid = mt.old_sid(+);

	INSERT INTO cms.doc_template (doc_template_id, name, lookup_key, lang)
		SELECT /*+CARDINALITY(dt, 1000) CARDINALITY(mdt, 1000) CARDINALITY(mt, 50000)*/
			   mdt.new_doc_template_id, dt.name, dt.lookup_key, dt.lang
		  FROM csrimp.cms_doc_template dt, csrimp.map_cms_doc_template mdt
		 WHERE dt.doc_template_id = mdt.old_doc_template_id;

	INSERT INTO cms.doc_template_file (doc_template_file_id, file_name, file_mime, file_data, uploaded_dtm)
		SELECT /*+CARDINALITY(dt, 1000) CARDINALITY(mdt, 1000) CARDINALITY(mt, 50000)*/
			   mdtf.new_doc_template_file_id, dt.file_name, dt.file_mime, dt.file_data, dt.uploaded_dtm
		  FROM csrimp.cms_doc_template_file dt, csrimp.map_cms_doc_template_file mdtf
		 WHERE dt.doc_template_file_id = mdtf.old_doc_template_file_id;

	INSERT INTO cms.doc_template_version (doc_template_id, version, comments, doc_template_file_id, log_dtm, user_sid, published_dtm, active)
		SELECT /*+CARDINALITY(dt, 1000) CARDINALITY(mdt, 1000) CARDINALITY(mt, 50000)*/
			   mdt.new_doc_template_id, dv.version, dv.comments, mdtf.new_doc_template_file_id, dv.log_dtm, dv.user_sid, dv.published_dtm, dv.active
		  FROM csrimp.cms_doc_template_version dv
		  JOIN csrimp.map_cms_doc_template mdt ON dv.doc_template_id = mdt.old_doc_template_id
		  JOIN csrimp.map_cms_doc_template_file mdtf ON dv.doc_template_file_id = mdtf.old_doc_template_file_id;

	-- XXX: we need to map item_id for the cms editor (although normal CMS tables don't care
	-- about this as they don't share ids)
	INSERT INTO cms.web_publication (web_publication_id, display_template_id, item_id)
		SELECT /*+CARDINALITY(wp, 1000) CARDINALITY(mdt, 1000)*/
			   cms.web_publication_id_seq.nextval, mdt.new_display_template_id, wp.item_id
		  FROM csrimp.cms_web_publication wp, csrimp.map_cms_display_template mdt
		 WHERE wp.display_template_id = mdt.old_display_template_id;

	INSERT INTO cms.link_track (item_id, context_id, column_sid, path, query_string)
		SELECT /*+CARDINALITY(lt, 1000) CARDINALITY(mt, 1000)*/
			   lt.item_id, lt.context_id, mtc.new_column_id, lt.path, lt.query_string
		  FROM csrimp.cms_link_track lt, csrimp.map_cms_tab_column mtc
		 WHERE lt.column_sid = mtc.old_column_id;

	INSERT INTO cms.image (image_id, mime_type, sha1, filename, description, data,
		modified_dtm, width, height, recycled)
		SELECT /*+CARDINALITY(i, 1000) CARDINALITY(mi, 1000)*/
			   mi.new_image_id, i.mime_type, i.sha1, i.filename, i.description, i.data,
			   i.modified_dtm, i.width, i.height, i.recycled
		  FROM csrimp.cms_image i, csrimp.map_cms_image mi
		 WHERE i.image_id = mi.old_image_id;

	INSERT INTO cms.tag (tag_id, tag, parent_tag_id)
		SELECT /*+CARDINALITY(t, 1000) CARDINALITY(mt, 1000) CARDINALITY(mtp, 1000)*/
			   mt.new_tag_id, t.tag, mtp.new_tag_id
		  FROM csrimp.cms_tag t, csrimp.map_cms_tag mt, csrimp.map_cms_tag mtp
		 WHERE t.tag_id = mt.old_tag_id
		   AND t.parent_tag_id = mtp.old_tag_id(+);

	INSERT INTO cms.image_tag (parent_tag_id, image_id)
		SELECT /*+CARDINALITY(it, 1000) CARDINALITY(mt, 1000) CARDINALITY(mi, 1000)*/
			   mt.new_tag_id, mi.new_image_id
		  FROM csrimp.cms_image_tag it, csrimp.map_cms_tag mt, csrimp.map_cms_image mi
		 WHERE it.parent_tag_id = mt.old_tag_id
		   AND it.image_id = mi.old_image_id;

	UPDATE /*CARDINALITY(so, 50000)*/ security.securable_object so
	   SET so.name = (SELECT /*CARDINALITY(t, 1000)*/
	   						 cms.tab_pkg.q(t.oracle_schema)||'.'||cms.tab_pkg.q(t.oracle_table)
	   					FROM cms.tab t
	   				   WHERE t.tab_sid = so.sid_id)
	 WHERE so.sid_id IN (SELECT /*CARDINALITY(ct, 1000) CARDINALITY(ms, 10)*/
								ct.tab_sid
	 					   FROM cms.tab ct, csrimp.map_cms_schema ms
	 					  WHERE ct.oracle_schema = ms.new_oracle_schema);

	-- what's the point of this? just for debug?
	INSERT INTO cms_tab_alert_type (tab_sid, has_repeats, customer_alert_type_id,
		filter_xml)
		SELECT /*+CARDINALITY(ctat, 1000) CARDINALITY(mt, 50000) CARDINALITY(mcat, 1000)*/
			   mt.new_sid, ctat.has_repeats, mcat.new_customer_alert_type_id, ctat.filter_xml
		  FROM csrimp.cms_tab_alert_type ctat, csrimp.map_sid mt,
		  	   csrimp.map_customer_alert_type mcat
		 WHERE ctat.tab_sid = mt.old_sid
		   AND ctat.customer_alert_type_id = mcat.old_customer_alert_type_id;

	-- this was in createflow but has to be done post CMS
	INSERT INTO csr.cms_alert_type (tab_sid, customer_alert_type_id, description, lookup_key, include_in_alert_setup, deleted, is_batched)
		SELECT mt.new_sid, mcat.new_customer_alert_type_id, cat.description, cat.lookup_key, cat.include_in_alert_setup, cat.deleted, cat.is_batched
		  FROM csrimp.cms_alert_type cat, csrimp.map_sid mt,
		  	   csrimp.map_customer_alert_type mcat
		 WHERE cat.tab_sid = mt.old_sid
		   AND cat.customer_alert_type_id = mcat.old_customer_alert_type_id;

	INSERT INTO csr.cms_alert_helper (helper_sp, tab_sid, description)
		SELECT MapCustomerSchema(cah.helper_sp), mt.new_sid, cah.description
		  FROM csrimp.cms_alert_helper cah, csrimp.map_sid mt
		 WHERE cah.tab_sid = mt.old_sid;


	-- XXX: we need to map item_id's
	INSERT INTO cms.tab_column_link (tab_column_link_id, column_sid_1, item_id_1, column_sid_2, item_id_2)
		SELECT /*+CARDINALITY(tcl, 1000) CARDINALITY(mtcl, 1000) CARDINALITY(mtc1, 1000) CARDINALITY(mtc2, 1000)*/
			   mtcl.new_column_link_id, mtc1.new_column_id, tcl.item_id_1, mtc2.new_column_id, tcl.item_id_2
		  FROM csrimp.cms_tab_column_link tcl, csrimp.map_cms_tab_column_link mtcl, csrimp.map_cms_tab_column mtc1,
		       csrimp.map_cms_tab_column mtc2
		 WHERE tcl.tab_column_link_id = mtcl.old_column_link_id
		   AND tcl.column_sid_1 = mtc1.old_column_id
		   AND tcl.column_sid_2 = mtc2.old_column_id;

	INSERT INTO cms.tab_column_link_type (column_sid, link_column_sid, label, base_link_url)
		SELECT /*+CARDINALITY(tclt, 1000) CARDINALITY(mtc1, 1000) CARDINALITY(mtc2, 1000)*/
			   mtc1.new_column_id, mtc2.new_column_id, tclt.label, tclt.base_link_url
		  FROM csrimp.cms_tab_column_link_type tclt, csrimp.map_cms_tab_column mtc1, csrimp.map_cms_tab_column mtc2
		 WHERE tclt.column_sid = mtc1.old_column_id
		   AND tclt.link_column_sid = mtc2.old_column_id;

	INSERT INTO cms.tab_aggregate_ind (tab_aggregate_ind_id, tab_sid, column_sid, ind_sid)
		SELECT /*+CARDINALITY(mt, 50000) CARDINALITY(mt2, 50000) CARDINALITY(mtc, 1000)  CARDINALITY(ctai, 1000)*/
		       cms.tab_aggregate_ind_id_seq.nextval, mt.new_sid, mtc.new_column_id, mt2.new_sid
		  FROM csrimp.map_sid mt, csrimp.map_sid mt2, csrimp.map_cms_tab_column mtc,
		       csrimp.cms_tab_aggregate_ind ctai
		 WHERE ctai.tab_sid = mt.old_sid
		   AND ctai.column_sid = mtc.old_column_id(+)
		   AND ctai.ind_sid = mt2.old_sid;

	INSERT INTO cms.tab_issue_aggregate_ind (tab_sid, raised_ind_sid, rejected_ind_sid, closed_on_time_ind_sid,
		       closed_late_ind_sid, closed_late_u30_ind_sid, closed_late_u60_ind_sid,
			   closed_late_u90_ind_sid, closed_late_o90_ind_sid, closed_ind_sid, open_ind_sid, closed_td_ind_sid,
			   rejected_td_ind_sid, open_od_ind_sid, open_nod_ind_sid, open_od_u30_ind_sid, open_od_u60_ind_sid,
			   open_od_u90_ind_sid, open_od_o90_ind_sid)
		SELECT /*+CARDINALITY(mt, 50000) CARDINALITY(mt2, 50000) CARDINALITY(mt3, 50000) CARDINALITY(mt4, 50000)
		          CARDINALITY(mt5, 50000) CARDINALITY(mt6, 50000) CARDINALITY(mt7, 50000) CARDINALITY(mt8, 50000)
		          CARDINALITY(mt9, 50000) CARDINALITY(mt10, 50000) CARDINALITY(mt11, 50000) CARDINALITY(mt12, 50000)
		          CARDINALITY(mt13, 50000) CARDINALITY(mt14, 50000) CARDINALITY(mt15, 50000) CARDINALITY(mt16, 50000)
				  CARDINALITY(mt17, 50000) CARDINALITY(mt18, 50000) CARDINALITY(mt19, 50000) CARDINALITY(ctiai, 1000)*/
		       mt.new_sid, mt2.new_sid, mt3.new_sid, mt4.new_sid, mt5.new_sid,
			   mt6.new_sid, mt7.new_sid, mt8.new_sid, mt9.new_sid,
			   mt10.new_sid, mt11.new_sid, mt12.new_sid, mt13.new_sid,
			   mt14.new_sid, mt15.new_sid, mt16.new_sid, mt17.new_sid,
			   mt18.new_sid, mt19.new_sid
		  FROM csrimp.map_sid mt, csrimp.map_sid mt2, csrimp.map_sid mt3,
		       csrimp.map_sid mt4, csrimp.map_sid mt5, csrimp.map_sid mt6,
		       csrimp.map_sid mt7, csrimp.map_sid mt8, csrimp.map_sid mt9,
		       csrimp.map_sid mt10, csrimp.map_sid mt11, csrimp.map_sid mt12,
		       csrimp.map_sid mt13, csrimp.map_sid mt14, csrimp.map_sid mt15,
		       csrimp.map_sid mt16, csrimp.map_sid mt17, csrimp.map_sid mt18,
		       csrimp.map_sid mt19,
			   csrimp.cms_tab_issue_aggregate_ind ctiai
		 WHERE ctiai.tab_sid = mt.old_sid
		   AND ctiai.raised_ind_sid = mt2.old_sid
		   AND ctiai.rejected_ind_sid = mt3.old_sid
		   AND ctiai.closed_on_time_ind_sid = mt4.old_sid
		   AND ctiai.closed_late_ind_sid = mt5.old_sid
		   AND ctiai.closed_late_u30_ind_sid = mt6.old_sid
		   AND ctiai.closed_late_u60_ind_sid = mt7.old_sid
		   AND ctiai.closed_late_u90_ind_sid = mt8.old_sid
		   AND ctiai.closed_late_o90_ind_sid = mt9.old_sid
		   AND ctiai.closed_ind_sid = mt10.old_sid
		   AND ctiai.open_ind_sid = mt11.old_sid
		   AND ctiai.closed_td_ind_sid = mt12.old_sid
		   AND ctiai.rejected_td_ind_sid = mt13.old_sid
		   AND ctiai.open_od_ind_sid = mt14.old_sid
		   AND ctiai.open_nod_ind_sid = mt15.old_sid
		   AND ctiai.open_od_u30_ind_sid = mt16.old_sid
		   AND ctiai.open_od_u60_ind_sid = mt17.old_sid
		   AND ctiai.open_od_u90_ind_sid = mt18.old_sid
		   AND ctiai.open_od_o90_ind_sid = mt19.old_sid;


	INSERT INTO cms.data_helper (lookup_key, helper_procedure)
		 SELECT lookup_key, MapCustomerSchema(helper_procedure)
		   FROM csrimp.cms_data_helper;

	INSERT INTO cms.enum_group_tab (tab_sid, label, replace_existing_filters)
		 SELECT ms.new_sid, egt.label, egt.replace_existing_filters
		   FROM cms_enum_group_tab egt
		   JOIN map_sid ms ON egt.tab_sid = ms.old_sid;

	INSERT INTO cms.enum_group (tab_sid, enum_group_id, group_label)
		 SELECT ms.new_sid, meg.new_enum_group_id, eg.group_label
		   FROM cms_enum_group eg
		   JOIN map_sid ms ON eg.tab_sid = ms.old_sid
		   JOIN map_cms_enum_group meg ON eg.enum_group_id = meg.old_enum_group_id;

	INSERT INTO cms.enum_group_member (enum_group_id, enum_group_member_id)
		 SELECT meg.new_enum_group_id, egm.enum_group_member_id
		   FROM cms_enum_group_member egm
		   JOIN map_cms_enum_group meg ON egm.enum_group_id = meg.old_enum_group_id;

	-- call sp to update schema references in cms.form_version.form_xml
	FixFormVersionTable();
END;

PROCEDURE CreateFlowAlerts
AS
BEGIN
	INSERT INTO csr.flow_alert_helper (flow_alert_helper, label)
		SELECT fah.flow_alert_helper, fah.label
		  FROM csrimp.flow_alert_helper fah;

	INSERT INTO csr.flow_transition_alert (flow_transition_alert_id, flow_state_transition_id,
		customer_alert_type_id, description, deleted, helper_sp, to_initiator, flow_alert_helper, can_be_edited_before_sending)
		SELECT /*+CARDINALITY(fsta, 1000) CARDINALITY(mfst, 50000) CARDINALITY(mfsta, 1000)
			      CARDINALITY(mcat, 1000)*/
			   mfsta.new_flow_transition_alert_id, mfst.new_flow_state_transition_id,
			   mcat.new_customer_alert_type_id, fsta.description, fsta.deleted,
			   MapCustomerSchema(fsta.helper_sp), fsta.to_initiator, fsta.flow_alert_helper,
			   fsta.can_be_edited_before_sending
		  FROM csrimp.flow_transition_alert fsta, csrimp.map_flow_state_transition mfst,
		  	   csrimp.map_flow_transition_alert mfsta, csrimp.map_customer_alert_type mcat
		 WHERE fsta.flow_transition_alert_id = mfsta.old_flow_transition_alert_id
		   AND fsta.flow_state_transition_id = mfst.old_flow_state_transition_id
		   AND fsta.customer_alert_type_id = mcat.old_customer_alert_type_id;

	INSERT INTO csr.flow_item_generated_alert (flow_item_generated_alert_id, flow_item_id, flow_state_log_id,
		flow_transition_alert_id, processed_dtm, created_dtm, from_user_sid, to_user_sid, to_column_sid,
		subject_override, body_override)
		SELECT /*+CARDINALITY(fia, 50000) CARDINALITY(mfi, 50000) CARDINALITY(mfsl, 50000)
			      CARDINALITY(mfsta, 50000)*/
			   csr.flow_item_gen_alert_id_seq.nextval, mfi.new_flow_item_id, mfsl.new_flow_state_log_id,
			   mfsta.new_flow_transition_alert_id, figa.processed_dtm, figa.created_dtm, mfu.new_sid, mtu.new_sid, mtc.new_column_id,
			   subject_override, body_override
		  FROM csrimp.flow_item_generated_alert figa, csrimp.map_flow_item mfi, csrimp.map_flow_state_log mfsl,
		  	   csrimp.map_flow_transition_alert mfsta, csrimp.map_sid mfu, csrimp.map_sid mtu, csrimp.map_cms_tab_column mtc
		 WHERE figa.flow_item_id = mfi.old_flow_item_id
		   AND figa.flow_state_log_id = mfsl.old_flow_state_log_id
		   AND figa.flow_transition_alert_id = mfsta.old_flow_transition_alert_id
		   AND figa.from_user_sid = mfu.old_sid
		   AND figa.to_user_sid = mtu.old_sid(+)
		   AND figa.to_column_sid = mtc.old_column_id(+);

	INSERT INTO csr.flow_transition_alert_cms_col (flow_transition_alert_id, column_sid)
		SELECT /*+CARDINALITY(ftar, 10000) CARDINALITY(mr, 50000) CARDINALITY(mfsta, 50000)*/
			   mfsta.new_flow_transition_alert_id, mr.new_sid
		  FROM csrimp.flow_transition_alert_cms_col ftacc, csrimp.map_sid mr,
			   csrimp.map_flow_transition_alert mfsta
		 WHERE ftacc.flow_transition_alert_id = mfsta.old_flow_transition_alert_id
		   AND ftacc.column_sid = mr.old_sid;

	INSERT INTO csr.flow_transition_alert_inv (flow_transition_alert_id, flow_involvement_type_id)
		SELECT /*+CARDINALITY(ftai, 10000) CARDINALITY(mfsta, 50000)*/
			   mfsta.new_flow_transition_alert_id, mfit.new_flow_involvement_type_id
		  FROM csrimp.flow_transition_alert_inv ftai,
		  	   csrimp.map_flow_transition_alert mfsta,
			   csrimp.map_flow_involvement_type mfit
		 WHERE ftai.flow_transition_alert_id = mfsta.old_flow_transition_alert_id
		   AND ftai.flow_involvement_type_id = mfit.old_flow_involvement_type_id;

	INSERT INTO csr.flow_transition_alert_role (flow_transition_alert_id, role_sid, group_sid)
		SELECT /*+CARDINALITY(ftar, 10000) CARDINALITY(mr, 50000) CARDINALITY(mfsta, 50000)*/
			   mfsta.new_flow_transition_alert_id, mr.new_sid, mg.new_sid
		  FROM csrimp.flow_transition_alert_role ftar, csrimp.map_sid mr, csrimp.map_sid mg,
		  	   csrimp.map_flow_transition_alert mfsta
		 WHERE ftar.flow_transition_alert_id = mfsta.old_flow_transition_alert_id
		   AND ftar.role_sid = mr.old_sid(+)
		   AND ftar.group_sid = mg.old_sid(+);

	INSERT INTO csr.flow_transition_alert_cc_role (flow_transition_alert_id, role_sid, group_sid)
		SELECT /*+CARDINALITY(ftar, 10000) CARDINALITY(mr, 50000) CARDINALITY(mfsta, 50000)*/
			   mfsta.new_flow_transition_alert_id, mr.new_sid, mg.new_sid
		  FROM csrimp.flow_transition_alert_cc_role ftar, csrimp.map_sid mr, csrimp.map_sid mg,
		  	   csrimp.map_flow_transition_alert mfsta
		 WHERE ftar.flow_transition_alert_id = mfsta.old_flow_transition_alert_id
		   AND ftar.role_sid = mr.old_sid(+)
		   AND ftar.group_sid = mg.old_sid(+);

	INSERT INTO csr.flow_transition_alert_user (flow_transition_alert_id, user_sid)
		SELECT /*+CARDINALITY(ftar, 10000) CARDINALITY(mr, 50000) CARDINALITY(mfsta, 50000)*/
			   mfsta.new_flow_transition_alert_id, mr.new_sid
		  FROM csrimp.flow_transition_alert_user ftau, csrimp.map_sid mr,
			   csrimp.map_flow_transition_alert mfsta
		 WHERE ftau.flow_transition_alert_id = mfsta.old_flow_transition_alert_id
		   AND ftau.user_sid = mr.old_sid;

	INSERT INTO csr.flow_transition_alert_cc_user (flow_transition_alert_id, user_sid)
		SELECT /*+CARDINALITY(ftar, 10000) CARDINALITY(mr, 50000) CARDINALITY(mfsta, 50000)*/
			   mfsta.new_flow_transition_alert_id, mr.new_sid
		  FROM csrimp.flow_transition_alert_cc_user ftau, csrimp.map_sid mr,
			   csrimp.map_flow_transition_alert mfsta
		 WHERE ftau.flow_transition_alert_id = mfsta.old_flow_transition_alert_id
		   AND ftau.user_sid = mr.old_sid;
END;

PROCEDURE ImportCmsData
AS
BEGIN
	FOR r IN (SELECT new_oracle_schema
				FROM csrimp.map_cms_schema
			   WHERE old_oracle_schema
			     NOT IN (SELECT oracle_schema
			     		   FROM cms.sys_schema)) LOOP
		EXECUTE IMMEDIATE 'begin '||cms.tab_pkg.q(r.new_oracle_schema)||'.'||'m$imp_pkg.import; end;';
	END LOOP;
END;

PROCEDURE CreateDoclib
AS
BEGIN
	INSERT INTO csr.doc (doc_id)
		SELECT md.new_doc_id
		  FROM csrimp.doc d, csrimp.map_doc md
		 WHERE d.doc_id = md.old_doc_id;

	INSERT INTO csr.doc_data (doc_data_id, data, sha1, mime_type)
		SELECT mdd.new_doc_data_id, dd.data, dd.sha1, dd.mime_type
		  FROM doc_data dd, map_doc_data mdd
		 WHERE dd.doc_data_id = mdd.old_doc_data_id;

	INSERT INTO csr.doc_folder (doc_folder_sid, description,
		lifespan_is_override, lifespan, approver_is_override, approver_sid,
		is_system_managed)
		SELECT mdf.new_sid, 
			   CASE WHEN df.description is NULL THEN EMPTY_CLOB() ELSE df.description END description,
			   df.lifespan_is_override, df.lifespan,
			   df.approver_is_override, ma.new_sid, df.is_system_managed
		  FROM csrimp.doc_folder df, csrimp.map_sid mdf, csrimp.map_sid ma
		 WHERE df.doc_folder_sid = mdf.old_sid
		   AND df.approver_sid = ma.old_sid(+);

	INSERT INTO csr.doc_library (doc_library_sid, documents_sid, trash_folder_sid)
		SELECT mdl.new_sid, md.new_sid, mt.new_sid
		  FROM csrimp.doc_library dl, csrimp.map_sid mdl,
		  	   csrimp.map_sid md, csrimp.map_sid mt
		 WHERE dl.doc_library_sid = mdl.old_sid
		   AND dl.documents_sid = md.old_sid
		   AND dl.trash_folder_sid = mt.old_sid;

	INSERT INTO csr.doc_type (doc_type_id, doc_library_sid, name)
		SELECT mdt.new_doc_type_id, mdl.new_sid, dt.name
		  FROM csrimp.doc_type dt
		  JOIN csrimp.map_doc_type mdt ON dt.doc_type_id = mdt.old_doc_type_id
		  JOIN csrimp.map_sid mdl ON dt.doc_library_sid = mdl.old_sid;

	INSERT INTO csr.doc_version (doc_id, version, filename, description,
		change_description, changed_by_sid, changed_dtm, doc_data_id, doc_type_id)
		SELECT md.new_doc_id, dv.version, dv.filename, dv.description,
			   dv.change_description, mcby.new_sid, dv.changed_dtm,
			   mdd.new_doc_data_id, mdt.new_doc_type_id
		  FROM csrimp.doc_version dv, csrimp.map_doc md, csrimp.map_doc_data mdd,
			   csrimp.map_sid mcby, csrimp.map_doc_type mdt
		 WHERE dv.doc_id = md.old_doc_id
		   AND dv.changed_by_sid = mcby.old_sid
		   AND dv.doc_data_id = mdd.old_doc_data_id
		   AND dv.doc_type_id = mdt.old_doc_type_id(+);

	INSERT INTO csr.doc_folder_subscription (doc_folder_sid, notify_sid)
		SELECT mdf.new_sid, mn.new_sid
		  FROM csrimp.doc_folder_subscription dfs, csrimp.map_sid mdf,
		  	   csrimp.map_sid mn
		 WHERE dfs.doc_folder_sid = mdf.old_sid
		   AND dfs.notify_sid = mn.old_sid;

	INSERT INTO csr.doc_current (doc_id, version, parent_sid, locked_by_sid,
		pending_version)
		SELECT md.new_doc_id, dc.version, mp.new_sid, mlby.new_sid, dc.pending_version
		  FROM csrimp.doc_current dc, csrimp.map_doc md, csrimp.map_sid mp,
		  	   csrimp.map_sid mlby
		 WHERE dc.doc_id = md.old_doc_id
		   AND dc.parent_sid = mp.old_sid
		   AND dc.locked_by_sid = mlby.old_sid(+);

	INSERT INTO csr.doc_download (doc_id, version, downloaded_dtm, downloaded_by_sid)
		SELECT md.new_doc_id, dd.version, dd.downloaded_dtm, mdby.new_sid
		  FROM csrimp.doc_download dd, csrimp.map_doc md, csrimp.map_sid mdby
		 WHERE dd.doc_id = md.old_doc_id
		   AND dd.downloaded_by_sid = mdby.old_sid;

	INSERT INTO csr.doc_notification (doc_notification_id, doc_id, version, notify_sid,
		sent_dtm, reason)
		SELECT csr.doc_notification_id_seq.nextval, md.new_doc_id, dn.version,
			   mn.new_sid, dn.sent_dtm, dn.reason
		  FROM csrimp.doc_notification dn, csrimp.map_doc md, csrimp.map_sid mn
		 WHERE dn.doc_id = md.old_doc_id
		   AND dn.notify_sid = mn.old_sid;

	INSERT INTO csr.doc_subscription (doc_id, notify_sid)
		SELECT md.new_doc_id, mn.new_sid
		  FROM csrimp.doc_subscription ds, csrimp.map_doc md, csrimp.map_sid mn
		 WHERE ds.doc_id = md.old_doc_id
		   AND ds.notify_sid = mn.old_sid;

	INSERT INTO csr.doc_folder_name_translation (doc_folder_sid, lang, translated, parent_sid)
		SELECT mdf.new_sid, dfnt.lang, dfnt.translated, mdfp.new_sid
		  FROM csrimp.doc_folder_name_translation dfnt, csrimp.map_sid mdf, map_sid mdfp
		 WHERE dfnt.doc_folder_sid = mdf.old_sid
		   AND dfnt.parent_sid = mdfp.old_sid;
END;

PROCEDURE CreateMeters
AS
BEGIN
	INSERT INTO csr.metering_options (analytics_months, analytics_current_month, meter_page_url,
			metering_helper_pkg, show_inherited_roles, period_set_id, period_interval_id, show_invoice_reminder,
			invoice_reminder, supplier_data_mandatory, region_date_clipping, fwd_estimate_meters,
			reference_mandatory, realtime_metering_enabled, prevent_manual_future_readings,
			proc_use_service, proc_api_base_uri, proc_local_path, proc_kick_timeout,
			raw_feed_data_jobs_enabled)
		SELECT analytics_months, analytics_current_month, meter_page_url, metering_helper_pkg,
			show_inherited_roles, period_set_id, period_interval_id, show_invoice_reminder,
			invoice_reminder, supplier_data_mandatory, region_date_clipping, fwd_estimate_meters,
			reference_mandatory, realtime_metering_enabled, prevent_manual_future_readings,
			proc_use_service, proc_api_base_uri, proc_local_path, proc_kick_timeout,
			raw_feed_data_jobs_enabled
		  FROM csrimp.metering_options;

	-- this looks like a bit of an odd design -- meter_source_type_id appears to be
	-- basedata (inserted as 1,2,3) when metering is enabled, yet it has an app_sid
	-- -- suggests a missing join table
	INSERT INTO csr.meter_source_type (meter_source_type_id, name, description,
	   arbitrary_period, add_invoice_data, show_in_meter_list,
	   is_calculated_sub_meter, descending, allow_reset,
	   allow_null_start_dtm)
	   SELECT /*+CARDINALITY(meter_source_type, 10)*/
			  meter_source_type_id, name, description,
			  arbitrary_period, add_invoice_data, show_in_meter_list,
			  is_calculated_sub_meter, descending, allow_reset,
			  allow_null_start_dtm
		 FROM csrimp.meter_source_type st;

	INSERT INTO csr.meter_type (meter_type_id, label, group_key, days_ind_sid, costdays_ind_sid, req_approval, flow_sid)
		SELECT mmi.new_meter_type_id, mi.label, mi.group_key, mdays.new_sid, mcostdays.new_sid, req_approval, mfs.new_sid
		  FROM csrimp.meter_type mi
		  JOIN csrimp.map_meter_type mmi ON mi.meter_type_id = mmi.old_meter_type_id
		  LEFT JOIN csrimp.map_sid mdays ON mi.days_ind_sid = mdays.old_sid
		  LEFT JOIN csrimp.map_sid mcostdays ON mi.costdays_ind_sid = mcostdays.old_sid
		  LEFT JOIN csrimp.map_sid mfs ON mi.flow_sid = mfs.old_sid;

	INSERT INTO csr.meter_input (meter_input_id, label, lookup_key, is_consumption_based, patch_helper, gap_finder, is_virtual, value_helper)
		SELECT mmi.new_meter_input_id, mi.label, mi.lookup_key, mi.is_consumption_based, mi.patch_helper, mi.gap_finder, mi.is_virtual, mi.value_helper
		  FROM csrimp.meter_input mi
		  JOIN csrimp.map_meter_input mmi ON mi.meter_input_id = mmi.old_meter_input_id;

	INSERT INTO csr.meter_data_priority(priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch)
		SELECT priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch
		FROM csrimp.meter_data_priority;

	INSERT INTO csr.meter_input_aggregator (meter_input_id, aggregator, aggr_proc, is_mandatory)
		SELECT mmi.new_meter_input_id, mia.aggregator, mia.aggr_proc, mia.is_mandatory
		  FROM csrimp.meter_input_aggregator mia
		  JOIN csrimp.map_meter_input mmi ON mia.meter_input_id = mmi.old_meter_input_id;

	INSERT INTO csr.meter_aggregate_type (meter_aggregate_type_id, meter_input_id, aggregator,
				analytic_function, description, accumulative)
		SELECT matmap.new_meter_aggregate_type_id, mmi.new_meter_input_id, mat.aggregator,
		       mat.analytic_function, mat.description, mat.accumulative
		  FROM csrimp.meter_aggregate_type mat, csrimp.map_meter_aggregate_type matmap, csrimp.map_meter_input mmi
		 WHERE mat.meter_aggregate_type_id = matmap.old_meter_aggregate_type_id
		   AND mat.meter_input_id = mmi.old_meter_input_id;

	INSERT INTO csr.meter_type_input (meter_type_id, meter_input_id, aggregator, ind_sid, measure_sid)
		SELECT mmt.new_meter_type_id, mmi.new_meter_input_id, mi.aggregator, indmap.new_sid, measuremap.new_sid
		  FROM csrimp.meter_type_input mi
		  JOIN csrimp.map_meter_type mmt ON mi.meter_type_id = mmt.old_meter_type_id
		  JOIN csrimp.map_meter_input mmi ON mi.meter_input_id = mmi.old_meter_input_id
		  LEFT JOIN csrimp.map_sid indmap ON mi.ind_sid = indmap.old_sid
		  LEFT JOIN csrimp.map_sid measuremap ON mi.measure_sid = measuremap.old_sid;

	INSERT INTO csr.all_meter (region_sid, meter_type_id, meter_source_type_id,
			   days_measure_conversion_id, costdays_measure_conversion_id, manual_data_entry,
			   approved_by_sid, reference, note, crc_meter, active, export_live_data_after_dtm,
			   approved_dtm, is_core, urjanet_meter_id, metering_version, lower_threshold_percentage, upper_threshold_percentage)
		SELECT /*+CARDINALITY(am, 50000)
				  CARDINALITY(rgn, 50000)
				  CARDINALITY(mcdays, 100)
				  CARDINALITY(mccostdays, 100)
				  CARDINALITY(mcdemand, 100)
				*/
			   rgn.new_sid, mmi.new_meter_type_id, am.meter_source_type_id,
			   mcdays.new_measure_conversion_id, mccostdays.new_measure_conversion_id, manual_data_entry,
			   apprby.new_sid, am.reference, am.note, am.crc_meter, am.active, am.export_live_data_after_dtm,
			   am.approved_dtm, am.is_core, am.urjanet_meter_id, am.metering_version,
			   am.lower_threshold_percentage, am.upper_threshold_percentage
		  FROM csrimp.all_meter am
		  JOIN csrimp.map_sid rgn ON am.region_sid = rgn.old_sid
		  JOIN map_meter_type mmi ON am.meter_type_id = mmi.old_meter_type_id
		  LEFT JOIN csrimp.map_measure_conversion mcdays ON am.days_measure_conversion_id = mcdays.old_measure_conversion_id
		  LEFT JOIN csrimp.map_measure_conversion mccostdays ON  am.costdays_measure_conversion_id = mccostdays.old_measure_conversion_id
		  LEFT JOIN csrimp.map_sid apprby ON am.approved_by_sid = apprby.old_sid;

	INSERT INTO csr.linked_meter (region_sid, linked_meter_sid, pos)
		SELECT /*+CARDINALITY(lm, 1000)*/
			mr.new_sid, lmr.new_Sid, lm.pos
		  FROM csrimp.linked_meter lm, csrimp.map_sid mr, csrimp.map_sid lmr
		 WHERE lm.region_sid = mr.old_sid
		   AND lm.linked_meter_sid = lmr.old_sid;

	INSERT INTO csr.meter_input_aggr_ind (region_sid, meter_input_id, aggregator, meter_type_id, measure_sid, measure_conversion_id)
		SELECT mr.new_sid, mmi.new_meter_input_id, ai.aggregator, mmi.new_meter_type_id, mm.new_sid, mmc.new_measure_conversion_id
		  FROM csrimp.meter_input_aggr_ind ai
		  JOIN csrimp.map_sid mr ON ai.region_sid = mr.old_sid
		  JOIN csrimp.map_meter_type mmi ON ai.meter_type_id = mmi.old_meter_type_id
		  JOIN csrimp.map_meter_input mmi ON mmi.old_meter_input_id = ai.meter_input_id
		  LEFT JOIN csrimp.map_sid mm ON ai.measure_sid = mm.old_sid
		  LEFT JOIN csrimp.map_measure_conversion mmc ON ai.measure_conversion_id = mmc.old_measure_conversion_id;

	INSERT INTO csr.event (event_id, label, raised_by_user_sid, raised_dtm, event_text, raised_for_region_sid, event_dtm)
		SELECT /*+CARDINALITY(e, 1000) CARDINALITY(me, 1000) rCARDINALITY(mru, 50000)
				  CARDINALITY(mr, CARDINALITY) */
			   me.new_event_id, e.label, mru.new_sid, e.raised_dtm, e.event_text, mr.new_sid, e.event_dtm
		  FROM csrimp.event e, csrimp.map_event me, csrimp.map_sid mru, csrimp.map_sid mr
		 WHERE e.event_id = me.old_event_id
		   AND e.raised_by_user_sid = mru.old_sid
		   AND e.raised_for_region_sid = mr.old_sid;

	INSERT INTO csr.region_event (region_sid, event_id)
		SELECT /*+CARDINALITY(re, 1000) CARDINALITY(mr, 50000) CARDINALITY(me, 1000)*/
			   mr.new_sid, me.new_event_id
		  FROM csrimp.region_event re, csrimp.map_sid mr, csrimp.map_event me
		 WHERE re.region_sid = mr.old_sid
		   AND re.event_id = me.old_event_id;

	INSERT INTO csr.meter_bucket (meter_bucket_id, duration, description, is_hours, is_minutes,
		is_weeks, week_start_day, is_months, start_month, is_export_period,
		period_set_id, period_interval_id, high_resolution_only, core_working_hours)
		SELECT /*+CARDINALITY(ldd, 100) CARDINALITY(mldd, 100)*/
			   mldd.new_meter_bucket_id, ldd.duration, ldd.description, ldd.is_hours, ldd.is_minutes,
			   ldd.is_weeks, ldd.week_start_day, ldd.is_months, ldd.start_month, ldd.is_export_period,
			   ldd.period_set_id, ldd.period_interval_id, ldd.high_resolution_only, ldd.core_working_hours
		  FROM csrimp.meter_bucket ldd, csrimp.map_meter_bucket mldd
		 WHERE ldd.meter_bucket_id = mldd.old_meter_bucket_id;

	INSERT INTO csr.meter_alarm_statistic (statistic_id, meter_input_id, aggregator, meter_bucket_id, name, is_average, is_sum, comp_proc, all_meters, not_before_dtm, core_working_hours, pos)
		SELECT /*+CARDINALITY(mas, 100) CARDINALITY(mmas, 100)*/
			   mmas.new_statistic_id, mmi.new_meter_input_id, mas.aggregator, mmb.new_meter_bucket_id, mas.name, mas.is_average, mas.is_sum, mas.comp_proc,
			   mas.all_meters, mas.not_before_dtm, core_working_hours, pos
		  FROM csrimp.meter_alarm_statistic mas, csrimp.map_meter_alarm_statistic mmas, csrimp.map_meter_bucket mmb, csrimp.map_meter_input mmi
		 WHERE mas.statistic_id = mmas.old_statistic_id
		   AND mas.meter_bucket_id = mmb.old_meter_bucket_id
		   AND mas.meter_input_id = mmi.old_meter_input_id;

	INSERT INTO csr.meter_alarm_comparison (comparison_id, name, show_pct, op_code)
		SELECT /*+CARDINALITY(mac, 100) CARDINALITY(mmac, 100)*/
			   mmac.new_comparison_id, mac.name, mac.show_pct, mac.op_code
		  FROM csrimp.meter_alarm_comparison mac, csrimp.map_meter_alarm_comparison mmac
		 WHERE mac.comparison_id = mmac.old_comparison_id;

	INSERT INTO csr.meter_alarm_issue_period (issue_period_id, name, test_function)
		SELECT /*+CARDINALITY(mac, 100) CARDINALITY(mmac, 100)*/
			   mp.new_issue_period_id, p.name, p.test_function
		  FROM csrimp.meter_alarm_issue_period p, csrimp.map_meter_alarm_issue_period mp
		 WHERE p.issue_period_id = mp.old_issue_period_id;

	INSERT INTO csr.meter_alarm_test_time (test_time_id, name, test_function)
		SELECT /*+CARDINALITY(matt, 100) CARDINALITY(mmatt, 100)*/
			   mmatt.new_test_time_id, matt.name, matt.test_function
		  FROM csrimp.meter_alarm_test_time matt, csrimp.map_meter_alarm_test_time mmatt
		 WHERE matt.test_time_id = mmatt.old_test_time_id;

	INSERT INTO csr.meter_alarm (meter_alarm_id, inheritable, enabled, name, test_time_id,
		look_at_statistic_id, compare_statistic_id, comparison_id,
		comparison_val, issue_period_id, issue_trigger_count)
		SELECT /*+CARDINALITY(ma, 100) CARDINALITY(mma, 100) CARDINALITY(mls, 100)
				  CARDINALITY(mcs, 100) CARDINALITY(mc, 100) CARDINALITY(mp, 100)
				  CARDINALITY(mmatt, 100)
			    */
			   mma.new_meter_alarm_id, ma.inheritable, ma.enabled, ma.name, mmatt.new_test_time_id,
			   mls.new_statistic_id, mcs.new_statistic_id, mc.new_comparison_id,
			   ma.comparison_val, mp.new_issue_period_id, ma.issue_trigger_count
		  FROM csrimp.meter_alarm ma, csrimp.map_meter_alarm mma,
		  	   csrimp.map_meter_alarm_statistic mls, csrimp.map_meter_alarm_statistic mcs,
		  	   csrimp.map_meter_alarm_comparison mc, csrimp.map_meter_alarm_issue_period mp,
		  	   csrimp.map_meter_alarm_test_time mmatt
		 WHERE ma.meter_alarm_id = mma.old_meter_alarm_id
		   AND ma.look_at_statistic_id = mls.old_statistic_id
		   AND ma.compare_statistic_id = mcs.old_statistic_id
		   AND ma.comparison_id = mc.old_comparison_id
		   AND ma.issue_period_id = mp.old_issue_period_id
		   AND ma.test_time_id = mmatt.old_test_time_id;

	INSERT INTO csr.region_meter_alarm (region_sid, inherited_from_sid,
		meter_alarm_id, ignore, ignore_children)
		SELECT /*+CARDINALITY(rma, 10000) CARDINALITY(mr, 50000) CARDINALITY(mi, 50000)
				  CARDINALITY(mma, 100)*/
			   mr.new_sid, mi.new_sid,
			   mma.new_meter_alarm_id, rma.ignore, rma.ignore_children
		  FROM csrimp.region_meter_alarm rma, csrimp.map_sid mr,
		  	   csrimp.map_sid mi, csrimp.map_meter_alarm mma
		 WHERE rma.region_sid = mr.old_sid
		   AND rma.inherited_from_sid = mi.old_sid
		   AND rma.meter_alarm_id = mma.old_meter_alarm_id;

	INSERT INTO csr.meter_alarm_event (region_sid, meter_alarm_id, meter_alarm_event_id, event_dtm)
		SELECT /*+CARDINALITY(mae, 50000) CARDINALITY(mr, 50000) CARDINALITY(mma, 100)*/
			   mr.new_sid, mma.new_meter_alarm_id, csr.meter_alarm_event_id_seq.nextval, mae.event_dtm
		  FROM csrimp.meter_alarm_event mae, csrimp.map_sid mr, csrimp.map_meter_alarm mma
		 WHERE mae.region_sid = mr.old_sid
		   AND mae.meter_alarm_id = mma.old_meter_alarm_id;

	INSERT INTO csr.meter_meter_alarm_statistic (region_sid, statistic_id, not_before_dtm, last_comp_dtm)
		SELECT /*+CARDINALITY(ms, 10000) CARDINALITY(mr, 50000) CARDINALITY(mms, 100)*/
			   mr.new_sid, mms.new_statistic_id, ms.not_before_dtm, ms.last_comp_dtm
		  FROM csrimp.meter_meter_alarm_statistic ms, csrimp.map_sid mr,
		  	   csrimp.map_meter_alarm_statistic mms
		 WHERE ms.region_sid = mr.old_sid
		   AND ms.statistic_id = mms.old_statistic_id;

	INSERT INTO csr.meter_alarm_statistic_period (region_sid, statistic_id, statistic_dtm, val, average_count)
		SELECT /*+CARDINALITY(masp, 500000) CARDINALITY(mr, 50000) CARDINALITY(mmas, 100)*/
			   mr.new_sid, mmas.new_statistic_id, statistic_dtm, masp.val, masp.average_count
		  FROM csrimp.meter_alarm_statistic_period masp, csrimp.map_sid mr,
		  	   csrimp.map_meter_alarm_statistic mmas
		 WHERE masp.region_sid = mr.old_sid
		   AND masp.statistic_id = mmas.old_statistic_id;

	INSERT INTO csr.meter_alarm_stat_run (meter_alarm_id, region_sid, statistic_id, statistic_dtm)
		SELECT /*+CARDINALITY(masp, 500) CARDINALITY(mma, 1000) CARDINALITY(mr, 50000)
				  CARDINALITY(mmas, 100)*/
			   mma.new_meter_alarm_id, mr.new_sid, mmas.new_statistic_id, masr.statistic_dtm
		  FROM csrimp.meter_alarm_stat_run masr, csrimp.map_meter_alarm mma,
		  	   csrimp.map_sid mr, csrimp.map_meter_alarm_statistic mmas
		 WHERE masr.meter_alarm_id = mma.old_meter_alarm_id
		   AND masr.region_sid = mr.old_sid
		   AND masr.statistic_id = mmas.old_statistic_id;

	INSERT INTO csr.meter_alarm_statistic_job (region_sid, statistic_id, start_dtm, end_dtm, job_created_dtm)
		SELECT /*+CARDINALITY(masj, 1000) CARDINALITY(mr, 50000) CARDINALITY(mmas, 100)*/
			   mr.new_sid, mmas.new_statistic_id, masj.start_dtm, masj.end_dtm, masj.job_created_dtm
		  FROM csrimp.meter_alarm_statistic_job masj, csrimp.map_sid mr,
		  	   csrimp.map_meter_alarm_statistic mmas
		 WHERE masj.region_sid = mr.old_sid
		   AND masj.statistic_id = mmas.old_statistic_id;

	INSERT INTO csr.core_working_hours (core_working_hours_id, start_time, end_time)
		SELECT m.new_core_working_hours_id, c.start_time, c.end_time
		  FROM csrimp.core_working_hours c
		  JOIN csrimp.map_core_working_hours m ON m.old_core_working_hours_id = c.core_working_hours_id;

	INSERT INTO csr.core_working_hours_day (core_working_hours_id, day)
		SELECT m.new_core_working_hours_id, c.day
		  FROM csrimp.core_working_hours_day c
		  JOIN csrimp.map_core_working_hours m ON m.old_core_working_hours_id = c.core_working_hours_id;

	INSERT INTO csr.core_working_hours_region (region_sid, core_working_hours_id)
		SELECT mr.new_sid, mc.new_core_working_hours_id
		  FROM csrimp.core_working_hours_region c
		  JOIN csrimp.map_sid mr ON mr.old_sid = c.region_sid
		  JOIN csrimp.map_core_working_hours mc ON mc.old_core_working_hours_id = c.core_working_hours_id;

	INSERT INTO csr.meter_document (meter_document_id, mime_type, file_name, data)
		SELECT /*+CARDINALITY(md, 10000) CARDINALITY(mmd, 10000)*/
			   mmd.new_meter_document_id, md.mime_type, md.file_name, md.data
		  FROM csrimp.meter_document md, csrimp.map_meter_document mmd
		 WHERE md.meter_document_id = mmd.old_meter_document_id;

	INSERT INTO csr.meter_element_layout (meter_element_layout_id, pos, ind_sid, tag_group_id)
		 SELECT csr.meter_element_layout_id_seq.NEXTVAL, mel.pos, mi.new_sid, mtg.new_tag_group_id
		   FROM csrimp.meter_element_layout mel
		   LEFT JOIN csrimp.map_sid mi ON mel.ind_sid = mi.old_sid
		   LEFT JOIN csrimp.map_tag_group mtg ON mel.tag_group_id = mtg.old_tag_group_id;

	INSERT INTO csr.meter_raw_data_source (raw_data_source_id, label,
			parser_type, helper_pkg,
			export_system_values, export_after_dtm, default_issue_user_sid,
			orphan_count, matched_count, create_meters,
			automated_import_class_sid,
			holding_region_sid,
			meter_date_format, process_body, proc_use_remote_service)
		SELECT /*+CARDINALITY(rds, 100) CARDINALITY(mrds, 100) CARDINALITY(miu, 50000)*/
			   mrds.new_raw_data_source_id, rds.label,
			   rds.parser_type, rds.helper_pkg,
			   rds.export_system_values, rds.export_after_dtm, miu.new_sid,
			   rds.orphan_count, rds.matched_count, rds.create_meters,
			   NULL, -- automated_import_class_sid is never exported, set it to null
			   hrsid.new_sid, -- holding_region_sid
			   rds.meter_date_format, rds.process_body, rds.proc_use_remote_service
		  FROM csrimp.meter_raw_data_source rds
		  JOIN csrimp.map_meter_raw_data_source mrds ON mrds.old_raw_data_source_id = rds.raw_data_source_id
		  LEFT JOIN csrimp.map_sid miu ON miu.old_sid = rds.default_issue_user_sid
		  LEFT JOIN csrimp.map_sid hrsid ON hrsid.old_sid = rds.holding_region_sid;

	INSERT INTO csr.meter_xml_option (raw_data_source_id, data_type, xslt)
		SELECT /*+CARDINALITY(mxo, 100) CARDINALITY(mrds, 100)*/
			   mrds.new_raw_data_source_id, mxo.data_type, mxo.xslt
		  FROM csrimp.meter_xml_option mxo, csrimp.map_meter_raw_data_source mrds
		 WHERE mxo.raw_data_source_id = mrds.old_raw_data_source_id;

	INSERT INTO csr.meter_excel_option (raw_data_source_id, worksheet_index, row_index, csv_delimiter)
		SELECT /*+CARDINALITY(meo, 100) CARDINALITY(mrds, 100)*/
			   mrds.new_raw_data_source_id, meo.worksheet_index, meo.row_index, meo.csv_delimiter
		  FROM csrimp.meter_excel_option meo, csrimp.map_meter_raw_data_source mrds
		 WHERE meo.raw_data_source_id = mrds.old_raw_data_source_id;

	INSERT INTO csr.meter_excel_mapping (raw_data_source_id, field_name, column_name, column_index)
		SELECT /*+CARDINALITY(mem, 100) CARDINALITY(mrds, 100)*/
			   mrds.new_raw_data_source_id, mem.field_name, mem.column_name, mem.column_index
		  FROM csrimp.meter_excel_mapping mem, csrimp.map_meter_raw_data_source mrds
		 WHERE mem.raw_data_source_id = mrds.old_raw_data_source_id;

	INSERT INTO csr.meter_list_cache (region_sid, last_reading_dtm, entered_dtm,
		val_number, avg_consumption, cost_number, read_by_sid, realtime_last_period,
		realtime_consumption, demand_number, reading_count, first_reading_dtm)
		SELECT /*+CARDINALITY(mlc, 100000) CARDINALITY(mr, 50000) CARDINALITY(mu, 50000)*/
			   mr.new_sid, mlc.last_reading_dtm, mlc.entered_dtm,
			   mlc.val_number, mlc.avg_consumption, mlc.cost_number,
			   mu.new_sid, mlc.realtime_last_period, mlc.realtime_consumption,
			   mlc.demand_number, mlc.reading_count, mlc.first_reading_dtm
		  FROM csrimp.meter_list_cache mlc, csrimp.map_sid mr, csrimp.map_sid mu
		 WHERE mlc.region_sid = mr.old_sid
		   AND mlc.read_by_sid = mu.old_sid(+);

	INSERT INTO csr.meter_raw_data (meter_raw_data_id, raw_data_source_id, received_dtm, start_dtm,
		end_dtm, mime_type, encoding_name, message_uid, data, status_id, orphan_count, matched_count,
		original_mime_type, original_file_name, original_data, automated_import_instance_id, file_name)
		SELECT /*+CARDINALITY(rd, 500000) CARDINALITY(mrds, 100) CARDINALITY(mrd, 500000)*/
			   mrd.new_meter_raw_data_id, mrds.new_raw_data_source_id, rd.received_dtm, rd.start_dtm,
			   rd.end_dtm, rd.mime_type, rd.encoding_name, rd.message_uid, rd.data, rd.status_id, rd.orphan_count, rd.matched_count,
			   original_mime_type, original_file_name, original_data, NULL automated_import_instance_id, /* can't exp/imp automated import stuff atm? */
			   file_name
		  FROM csrimp.meter_raw_data rd, csrimp.map_meter_raw_data_source mrds, csrimp.map_meter_raw_data mrd
		 WHERE rd.raw_data_source_id = mrds.old_raw_data_source_id
		   AND rd.meter_raw_data_id = mrd.old_meter_raw_data_id;

	INSERT INTO csr.meter_live_data (region_sid, meter_bucket_id, meter_input_id, aggregator, priority, start_dtm,
		meter_raw_data_id, end_dtm, modified_dtm, consumption, meter_data_id)
		SELECT /*+CARDINALITY(rd, 500000) CARDINALITY(mrds, 100) CARDINALITY(mrd, 500000)*/
			   mr.new_sid, mldd.new_meter_bucket_id, mmi.new_meter_input_id, mld.aggregator, mld.priority, mld.start_dtm,
			   mrd.new_meter_raw_data_id, mld.end_dtm, mld.modified_dtm, mld.consumption, mdid.new_meter_data_id
		  FROM csrimp.meter_live_data mld, csrimp.map_meter_bucket mldd,
		  	   csrimp.map_sid mr, csrimp.map_meter_raw_data mrd,
			   csrimp.map_meter_input mmi, csrimp.map_meter_data_id mdid
		 WHERE mld.region_sid = mr.old_sid
		   AND mld.meter_bucket_id = mldd.old_meter_bucket_id
		   AND mld.meter_raw_data_id = mrd.old_meter_raw_data_id(+)
		   AND mld.meter_input_id = mmi.old_meter_input_id
		   AND mld.meter_data_id = mdid.old_meter_data_id(+);

	INSERT INTO csr.meter_orphan_data (serial_id, meter_input_id, priority, start_dtm, end_dtm, meter_raw_data_id,
		consumption, uom, note, related_location_1, related_location_2, region_sid, has_overlap, error_type_id, statement_id)
		SELECT /*+CARDINALITY(md, 1000000) CARDINALITY(mrd, 500000)*/
			   md.serial_id, mmi.new_meter_input_id, md.priority, md.start_dtm, md.end_dtm, mrd.new_meter_raw_data_id,
			   md.consumption, md.uom, md.note, md.related_location_1, md.related_location_2, mrm.new_sid, md.has_overlap, md.error_type_id, md.statement_id
		  FROM csrimp.meter_orphan_data md, csrimp.map_meter_raw_data mrd, csrimp.map_meter_input mmi, csrimp.map_sid mrm
		 WHERE md.meter_raw_data_id = mrd.old_meter_raw_data_id
		   AND md.meter_input_id = mmi.old_meter_input_id
		   AND md.region_sid = mrm.old_sid;

	 INSERT INTO csr.duff_meter_region (urjanet_meter_id, meter_name, meter_number, region_ref,
		    service_type, meter_raw_data_id,
		    meter_raw_data_error_id, region_sid, issue_id, message, error_type_id)
	 	SELECT urjanet_meter_id, meter_name, meter_number, region_ref,
		    service_type, mrdm.new_meter_raw_data_id,
		    meter_raw_data_error_id, rsm.new_sid, im.new_issue_id, message, error_type_id
		  FROM csrimp.duff_meter_region dmr
		  LEFT JOIN csrimp.map_meter_raw_data mrdm ON mrdm.old_meter_raw_data_id = dmr.meter_raw_data_id
		  LEFT JOIN csrimp.map_sid rsm ON rsm.old_sid = dmr.region_sid
		  LEFT JOIN csrimp.map_issue im ON im.old_issue_id = dmr.issue_id;

	INSERT INTO csr.meter_raw_data_error (meter_raw_data_id, error_id, message, raised_dtm, data_dtm)
		SELECT /*+CARDINALITY(me, 500000) CARDINALITY(mrd, 500000)*/
			   mrd.new_meter_raw_data_id, me.error_id, me.message, me.raised_dtm, me.data_dtm
		  FROM csrimp.meter_raw_data_error me, csrimp.map_meter_raw_data mrd
		 WHERE me.meter_raw_data_id = mrd.old_meter_raw_data_id;

	INSERT INTO csr.meter_header_element (meter_header_element_id, pos, col, ind_sid, tag_group_id, meter_header_core_element_id)
		 SELECT mmhe.new_meter_header_element_id, mhe.pos, mhe.col, mis.new_sid, mtg.new_tag_group_id, mhe.meter_header_core_element_id
		   FROM csrimp.meter_header_element mhe
		   JOIN csrimp.map_meter_header_element mmhe ON mhe.meter_header_element_id = mmhe.old_meter_header_element_id
		   LEFT JOIN csrimp.map_sid mis ON mhe.ind_sid = mis.old_sid
		   LEFT JOIN csrimp.map_tag_group mtg ON mhe.tag_group_id = mtg.old_tag_group_id;

	INSERT INTO csr.meter_photo (meter_photo_id, region_sid, filename, mime_type, data)
		 SELECT mmp.new_meter_photo_id, mrs.new_sid, mp.filename, mp.mime_type, mp.data
		   FROM csrimp.meter_photo mp
		   JOIN csrimp.map_meter_photo mmp ON mp.meter_photo_id = mmp.old_meter_photo_id
		   JOIN csrimp.map_sid mrs ON mp.region_sid = mrs.old_sid;

	INSERT INTO csr.meter_tab (plugin_id, plugin_type_id, pos, tab_label)
		 SELECT mp.new_plugin_id, mt.plugin_type_id, mt.pos, mt.tab_label
		   FROM csrimp.meter_tab mt
		   JOIN csrimp.map_plugin mp ON mt.plugin_id = mp.old_plugin_id;

	INSERT INTO csr.meter_tab_group (plugin_id, group_sid, role_sid)
		 SELECT mp.new_plugin_id, mgs.new_sid, mrs.new_sid
		   FROM csrimp.meter_tab_group mtg
		   JOIN csrimp.map_plugin mp ON mtg.plugin_id = mp.old_plugin_id
		   LEFT JOIN csrimp.map_sid mgs ON mtg.group_sid = mgs.old_sid
		   LEFT JOIN csrimp.map_sid mrs ON mtg.role_sid = mrs.old_sid;

	INSERT INTO csr.utility_supplier (utility_supplier_id, supplier_name, contact_details)
		SELECT /*+CARDINALITY(us, 100) CARDINALITY(mus, 100)*/
			   mus.new_utility_supplier_id, us.supplier_name, us.contact_details
		  FROM csrimp.utility_supplier us, csrimp.map_utility_supplier mus
		 WHERE us.utility_supplier_id = mus.old_utility_supplier_id;

	INSERT INTO csr.utility_contract (utility_contract_id, utility_supplier_id, account_ref, from_dtm,
		to_dtm, alert_when_due, file_data, file_mime_type, file_name, created_by_sid)
		SELECT /*+CARDINALITY(uc, 100) CARDINALITY(muc, 100)
				  CARDINALITY(mus, 100) CARDINALITY(mu, 50000)*/
			   muc.new_utility_contract_id, mus.new_utility_supplier_id, uc.account_ref, uc.from_dtm,
			   uc.to_dtm, uc.alert_when_due, uc.file_data, uc.file_mime_type, uc.file_name, mu.new_sid
		  FROM csrimp.utility_contract uc, csrimp.map_utility_contract muc,
		  	   csrimp.map_utility_supplier mus, csrimp.map_sid mu
		 WHERE uc.utility_contract_id = muc.old_utility_contract_id
		   AND uc.utility_supplier_id = mus.old_utility_supplier_id
		   AND uc.created_by_sid = mu.old_sid(+);

	INSERT INTO csr.utility_invoice (utility_invoice_id, utility_contract_id, reference, invoice_dtm,
		cost_value, cost_measure_sid, cost_conv_id, consumption,
		consumption_conv_id, file_data, file_mime_type, file_name,
		verified_by_sid, consumption_measure_sid)
		SELECT /*+CARDINALITY(ui_invoice, 10000) CARDINALITY(mui, 10000) CARDINALITY(muc, 100)
				  CARDINALITY(mcostmeas, 50000) CARDINALITY(mcostconv, 100) CARDINALITY(mconsconv, 100)
				  CARDINALITY(mverified, 50000) CARDINALITY(mconsmeas, 50000)*/
			   mui.new_utility_invoice_id, muc.new_utility_contract_id, ui.reference, ui.invoice_dtm,
			   ui.cost_value, mcostmeas.new_sid, mcostconv.new_measure_conversion_id, ui.consumption,
			   mconsconv.new_measure_conversion_id, ui.file_data, ui.file_mime_type, ui.file_name,
			   mverified.new_sid, mconsmeas.new_sid
		  FROM csrimp.utility_invoice ui, csrimp.map_utility_invoice mui,
		  	   csrimp.map_utility_contract muc, csrimp.map_sid mcostmeas,
		  	   csrimp.map_measure_conversion mcostconv, csrimp.map_measure_conversion mconsconv,
		  	   csrimp.map_sid mverified, csrimp.map_sid mconsmeas
		 WHERE ui.utility_invoice_id = mui.old_utility_invoice_id
		   AND ui.utility_contract_id = muc.old_utility_contract_id
		   AND ui.cost_measure_sid = mcostmeas.old_sid(+)
		   AND ui.cost_conv_id = mcostconv.old_measure_conversion_id(+)
		   AND ui.consumption_conv_id = mconsconv.old_measure_conversion_id(+)
		   AND ui.verified_by_sid = mverified.old_sid(+)
		   AND ui.consumption_measure_sid = mconsmeas.old_sid(+);

	INSERT INTO csr.meter_patch_data (region_sid, meter_input_id, priority, start_dtm, end_dtm, consumption, updated_dtm)
		SELECT mr.new_sid, mmi.new_meter_input_id, mpd.priority, mpd.start_dtm, mpd.end_dtm, mpd.consumption, mpd.updated_dtm
		  FROM csrimp.meter_patch_data mpd, csrimp.map_sid mr, csrimp.map_meter_input mmi
		 WHERE mr.old_sid = mpd.region_sid
		   AND mmi.old_meter_input_id = mpd.meter_input_id;

	INSERT INTO csr.meter_patch_job (region_sid, meter_input_id, start_dtm, end_dtm, created_dtm)
		SELECT mr.new_sid, mmi.new_meter_input_id, mpj.start_dtm, mpj.end_dtm, mpj.created_dtm
		  FROM csrimp.meter_patch_job mpj, csrimp.map_sid mr, csrimp.map_meter_input mmi
		 WHERE mr.old_sid = mpj.region_sid
		   AND mmi.old_meter_input_id = mpj.meter_input_id;

	-- TODO: where is the batch job ID map table?
	/*
	INSERT INTO csr.meter_patch_batch_job (batch_job_id, region_sid, is_remove, created_dtm)
		SELECT batch_job_id, region_sid, is_remove, created_dtm
		  FROM csrimp.meter_patch_batch_job;

	INSERT INTO csr.meter_patch_batch_data (batch_job_id, meter_input_id, priority, start_dtm, end_dtm, period_type, consumption)
		SELECT batch_job_id, mmi.new_meter_input_id, priority, start_dtm, end_dtm, period_type, consumption
		  FROM csrimp.meter_patch_batch_data, csrimp.map_meter_input mmi
		 WHERE mmi.old_meter_input_id = meter_input_id;
	*/

	INSERT INTO csr.meter_data_coverage_ind (meter_input_id, priority, ind_sid)
		SELECT mmi.new_meter_input_id, mdci.priority, mi.new_sid
		  FROM csrimp.meter_data_coverage_ind mdci, csrimp.map_sid mi, csrimp.map_meter_input mmi
		 WHERE mi.old_sid = mdci.ind_sid
		   AND mmi.old_meter_input_id = mdci.meter_input_id;

	INSERT INTO csr.meter_reading (region_sid, meter_reading_id, start_dtm, end_dtm, val_number, entered_by_user_sid,
		entered_dtm, note, reference, cost, meter_document_id, created_invoice_id, meter_source_type_id,
		req_approval, replaces_reading_id, approved_dtm, approved_by_sid, active, is_delete, flow_item_id, baseline_val,
		demand, pm_reading_id, is_estimate)
		SELECT mreg.new_sid, mmr.new_meter_reading_id, mr.start_dtm, mr.end_dtm, mr.val_number, mu.new_sid,
			   mr.entered_dtm, mr.note, mr.reference, mr.cost, md.new_meter_document_id, mui.new_utility_invoice_id, mr.meter_source_type_id,
			   mr.req_approval, mrmr.new_meter_reading_id, mr.approved_dtm, mapu.new_sid, mr.active, mr.is_delete, mfi.new_flow_item_id, mr.baseline_val,
			   mr.demand, mr.pm_reading_id, mr.is_estimate
		  FROM csrimp.meter_reading mr, csrimp.map_meter_reading mmr, csrimp.map_sid mreg,
		  	   csrimp.map_meter_document md, csrimp.map_sid mu, csrimp.map_utility_invoice mui,
		  	   csrimp.map_meter_reading mrmr, csrimp.map_sid mapu, csrimp.map_flow_item mfi
		 WHERE mr.region_sid = mreg.old_sid
		   AND mr.meter_reading_id = mmr.old_meter_reading_id
		   AND mr.entered_by_user_sid = mu.old_sid
		   AND mr.meter_document_id = md.old_meter_document_id(+)
		   AND mr.created_invoice_id = mui.old_utility_invoice_id(+)
		   AND mr.replaces_reading_id = mrmr.old_meter_reading_id(+)
		   AND mr.approved_by_sid = mapu.old_sid(+)
		   AND mr.flow_item_id = mfi.old_flow_item_id(+);

	INSERT INTO csr.meter_source_data (region_sid, meter_input_id, priority, start_dtm, end_dtm, meter_raw_data_id, raw_uom, raw_consumption, consumption, note, statement_id)
		SELECT /*+CARDINALITY(msd, 100000) CARDINALITY(mrd, 100000)*/
			mr.new_sid, mmi.new_meter_input_id, msd.priority, msd.start_dtm, msd.end_dtm, mrd.new_meter_raw_data_id, msd.raw_uom, msd.raw_consumption, msd.consumption, msd.note, msd.statement_id
		  FROM csrimp.meter_source_data msd, csrimp.map_sid mr, csrimp.map_meter_raw_data mrd, csrimp.map_meter_input mmi
		 WHERE msd.region_sid = mr.old_sid
		   AND msd.meter_raw_data_id = mrd.old_meter_raw_data_id(+)
		   AND msd.meter_input_id = mmi.old_meter_input_id;

	INSERT INTO csr.meter_reading_data (region_sid, meter_input_id, priority, reading_dtm, meter_raw_data_id, raw_uom, raw_val, val, note)
		SELECT /*+CARDINALITY(msd, 100000) CARDINALITY(mrd, 100000)*/
			mr.new_sid, mmi.new_meter_input_id, msd.priority, msd.reading_dtm, mrd.new_meter_raw_data_id, msd.raw_uom, msd.raw_val, msd.val, msd.note
		  FROM csrimp.meter_reading_data msd, csrimp.map_sid mr, csrimp.map_meter_raw_data mrd, csrimp.map_meter_input mmi
		 WHERE msd.region_sid = mr.old_sid
		   AND msd.meter_raw_data_id = mrd.old_meter_raw_data_id(+)
		   AND msd.meter_input_id = mmi.old_meter_input_id;

	INSERT INTO csr.meter_utility_contract (region_sid, utility_contract_id, active)
		SELECT mr.new_sid, muc.new_utility_contract_id, uc.active
		  FROM csrimp.meter_utility_contract uc, csrimp.map_sid mr,
		  	   csrimp.map_utility_contract muc
		 WHERE uc.region_sid = mr.old_sid
		   AND uc.utility_contract_id = muc.old_utility_contract_id;

	INSERT INTO csr.region_proc_doc (region_sid, doc_id, inherited)
		SELECT mr.new_sid, md.new_doc_id, rpd.inherited
		  FROM csrimp.region_proc_doc rpd, csrimp.map_sid mr, csrimp.map_doc md
		 WHERE rpd.region_sid = mr.old_sid
		   AND rpd.doc_id = md.old_doc_id;

	INSERT INTO csr.region_proc_file (region_sid, meter_document_id, inherited)
		SELECT mr.new_sid, md.new_meter_document_id, rpf.inherited
		  FROM csrimp.region_proc_file rpf, csrimp.map_sid mr,
		  	   csrimp.map_meter_document md
		 WHERE rpf.region_sid = mr.old_sid
		   AND rpf.meter_document_id = md.old_meter_document_id;

	-- Meter raw_data_log_id doesn't really need mapping, it will be distinct within the app which is fine
	INSERT INTO csr.meter_raw_data_log (meter_raw_data_id, log_id, user_sid, log_text, log_dtm, mime_type, file_name, data)
		SELECT  mrd.new_meter_raw_data_id, log_id, us.new_sid, log_text, log_dtm, mime_type, file_name, data
		  FROM csrimp.meter_raw_data_log l
		  JOIN csrimp.map_sid us ON us.old_sid = l.user_sid
		  JOIN csrimp.map_meter_raw_data mrd ON mrd.old_meter_raw_data_id = l.meter_raw_data_id;

	INSERT INTO csr.meter_data_source_hi_res_input (raw_data_source_id, meter_input_id)
		SELECT mrs.new_raw_data_source_id, mi.new_meter_input_id
		  FROM csrimp.meter_data_source_hi_res_input mdshri
		  JOIN csrimp.map_meter_raw_data_source mrs ON mdshri.raw_data_source_id = mrs.old_raw_data_source_id
		  JOIN csrimp.map_meter_input mi ON mdshri.meter_input_id = mi.old_meter_input_id;

	INSERT INTO csr.issue_meter (issue_meter_id, region_sid, issue_dtm)
		SELECT /*+CARDINALITY(im, 10000) CARDINALITY(mim, 10000)*/
			   mim.new_issue_meter_id, mr.new_sid, im.issue_dtm
		  FROM csrimp.issue_meter im, csrimp.map_issue_meter mim,
		  	   csrimp.map_sid mr
		 WHERE im.issue_meter_id = mim.old_issue_meter_id
		   AND im.region_sid = mr.old_sid;

	INSERT INTO csr.issue_meter_alarm (issue_meter_alarm_id, region_sid, meter_alarm_id, issue_dtm)
		SELECT /*+CARDINALITY(ima, 10000) CARDINALITY(mima, 10000) CARDINALITY(mma, 10000)*/
			   mima.new_issue_meter_alarm_id, mr.new_sid, mma.new_meter_alarm_id, ima.issue_dtm
		  FROM csrimp.issue_meter_alarm ima, csrimp.map_issue_meter_alarm mima,
		  	   csrimp.map_sid mr, csrimp.map_meter_alarm mma
		 WHERE ima.issue_meter_alarm_id = mima.old_issue_meter_alarm_id
		   AND ima.region_sid = mr.old_sid
		   AND ima.meter_alarm_id = mma.old_meter_alarm_id;

	INSERT INTO csr.issue_meter_data_source (issue_meter_data_source_id, raw_data_source_id)
		SELECT /*+CARDINALITY(imds, 10000) CARDINALITY(mimds, 10000) CARDINALITY(mrds, 10000)*/
			   mimds.new_issue_meter_data_source_id, mrds.new_raw_data_source_id
		  FROM csrimp.issue_meter_data_source imds, csrimp.map_issue_meter_data_source mimds,
		  	   csrimp.map_meter_raw_data_source mrds
		 WHERE imds.issue_meter_data_source_id = mimds.old_issue_meter_data_source_id
		   AND imds.raw_data_source_id = mrds.old_raw_data_source_id;

	INSERT INTO csr.issue_meter_raw_data (issue_meter_raw_data_id, meter_raw_data_id, region_sid)
		SELECT /*+CARDINALITY(imr, 10000) CARDINALITY(mimr, 10000) CARDINALITY(mrd, 10000)*/
			   mimr.new_issue_meter_raw_data_id, mrd.new_meter_raw_data_id, mr.new_sid
		  FROM csrimp.issue_meter_raw_data imr, csrimp.map_issue_meter_raw_data mimr,
		  	   csrimp.map_meter_raw_data mrd, csrimp.map_sid mr
		 WHERE imr.issue_meter_raw_data_id = mimr.old_issue_meter_raw_data_id
		   AND imr.meter_raw_data_id = mrd.old_meter_raw_data_id
		   AND imr.region_sid = mr.old_sid(+);

	INSERT INTO csr.issue_meter_missing_data (
				issue_meter_missing_data_id,
				end_dtm,
				region_sid,
				start_dtm
	   ) SELECT mimmd.new_issue_meter_missin_data_id,
				immd.end_dtm,
				ms.new_sid,
				immd.start_dtm
		   FROM csrimp.issue_meter_missing_data immd,
				csrimp.map_issu_mete_missi_data mimmd,
				csrimp.map_sid ms
		  WHERE immd.issue_meter_missing_data_id = mimmd.old_issue_meter_missin_data_id
			AND immd.region_sid = ms.old_sid;
END;

PROCEDURE CreateIncidentTypes
AS
BEGIN
	INSERT INTO csr.incident_type (tab_sid, group_key, label, plural, base_css_class, pos, list_url,
						edit_url, new_case_url, mobile_form_path, mobile_form_sid, description)
		SELECT mts.new_sid, it.group_key, it.label, it.plural, it.base_css_class, it.pos, it.list_url,
			   it.edit_url, it.new_case_url, it.mobile_form_path, mfs.new_sid, it.description
		  FROM incident_type it
		  JOIN map_sid mts ON it.tab_sid = mts.old_sid
		  LEFT JOIN map_sid mfs ON it.mobile_form_sid = mfs.old_sid;
END;

PROCEDURE CreateIssues
AS
BEGIN
	INSERT INTO	csr.issue_pending_val (issue_pending_val_id, pending_region_id, pending_ind_id, pending_period_id)
		SELECT /*+CARDINALITY(ipv, 10000) CARDINALITY(mipv, 10000) CARDINALITY(mpi, 10000)
			     CARDINALITY(mpr, 10000) CARDINALITY(mpp, 10000)*/
			   mipv.new_issue_pending_val_id, mpr.new_pending_region_id, mpi.new_pending_ind_id, mpp.new_pending_period_id
		  FROM csrimp.issue_pending_val ipv, csrimp.map_issue_pending_val mipv,
		  	   csrimp.map_pending_region mpr, csrimp.map_pending_ind mpi,
		  	   csrimp.map_pending_period mpp
		 WHERE ipv.issue_pending_val_id = mipv.old_issue_pending_val_id
		   AND ipv.pending_region_id = mpr.old_pending_region_id
		   AND ipv.pending_ind_id = mpi.old_pending_ind_id
		   AND ipv.pending_period_id = mpp.old_pending_period_id;

	INSERT INTO csr.issue_sheet_value (issue_sheet_value_id, ind_sid, region_sid, start_dtm, end_dtm)
		SELECT /*+CARDINALITY(isv, 10000) CARDINALITY(misv, 10000)*/
			   misv.new_issue_sheet_value_id, mi.new_sid, mr.new_sid, isv.start_dtm, isv.end_dtm
		  FROM csrimp.issue_sheet_value isv, csrimp.map_sid mi, csrimp.map_sid mr,
		  	   csrimp.map_issue_sheet_value misv
		 WHERE isv.issue_sheet_value_id = misv.old_issue_sheet_value_id
		   AND isv.ind_sid = mi.old_sid
		   AND isv.region_sid = mr.old_sid;

	INSERT INTO csr.issue_priority (issue_priority_id, description, due_date_offset)
		SELECT /*+CARDINALITY(ip, 1000) CARDINALITY(mip, 1000)*/
			   mip.new_issue_priority_id, ip.description, ip.due_date_offset
		  FROM csrimp.issue_priority ip, csrimp.map_issue_priority mip
		 WHERE ip.issue_priority_id = mip.old_issue_priority_id;

	-- This is another odd table: it looks like issue_type_id ought to be in a separate table
	-- and this should be customer_issue_type.  Oh well.
	INSERT INTO csr.issue_type (issue_type_id, label, default_region_sid, default_issue_priority_id,
		alert_mail_address, alert_mail_name, require_priority, require_due_dtm_comment, allow_children, auto_close_after_resolve_days, create_raw,
		region_link_type, default_assign_to_user_sid, default_assign_to_role_sid, alert_pending_due_days, alert_overdue_days, position, deleted, can_set_public,
		email_involved_roles, email_involved_users, allow_pending_assignment, restrict_users_to_region, deletable_by_owner, deletable_by_administrator,
		involve_min_users_in_issue, show_forecast_dtm, require_var_expl, enable_reject_action, helper_pkg, public_by_default, owner_can_be_changed, 
		deletable_by_raiser, send_alert_on_issue_raised, internal_issue_ref_helper_func, internal_issue_ref_prefix, lookup_key, show_one_issue_popup,
		allow_owner_resolve_and_close, applies_to_audit, get_assignables_sp, is_region_editable, enable_manual_comp_date, comment_is_optional,
		due_date_is_mandatory, allow_critical, allow_urgent_alert, region_is_mandatory)
		SELECT /*+CARDINALITY(it, 1000) CARDINALITY(mip, 1000)*/
			   issue_type_id, it.label, mr.new_sid, mip.new_issue_priority_id,
			   it.alert_mail_address, it.alert_mail_name, it.require_priority, it.require_due_dtm_comment, it.allow_children, it.auto_close_after_resolve_days,
			   it.create_raw, it.region_link_type, msusr.new_sid default_assign_to_user_sid, msrole.new_sid default_assign_to_role_sid, it.alert_pending_due_days,
			   it.alert_overdue_days, position, deleted, it.can_set_public, it.email_involved_roles, it.email_involved_users, it.allow_pending_assignment,
			   it.restrict_users_to_region, it.deletable_by_owner, it.deletable_by_administrator, it.involve_min_users_in_issue, it.show_forecast_dtm,
			   it.require_var_expl, it.enable_reject_action, it.helper_pkg, it.public_by_default, it.owner_can_be_changed, it.deletable_by_raiser,
			   it.send_alert_on_issue_raised, it.internal_issue_ref_helper_func, it.internal_issue_ref_prefix, it.lookup_key, it.show_one_issue_popup,
			   it.allow_owner_resolve_and_close, it.applies_to_audit, it.get_assignables_sp, it.is_region_editable, it.enable_manual_comp_date,
			   it.comment_is_optional, it.due_date_is_mandatory, it.allow_critical, it.allow_urgent_alert, it.region_is_mandatory
		  FROM csrimp.issue_type it, csrimp.map_sid mr, csrimp.map_issue_priority mip, csrimp.map_sid msusr, csrimp.map_sid msrole
		 WHERE it.default_region_sid = mr.old_sid(+)
		   AND it.default_issue_priority_id = mip.new_issue_priority_id(+)
		   AND it.default_assign_to_user_sid = msusr.old_sid(+)
		   AND it.default_assign_to_role_sid = msrole.old_sid(+);

	-- No mapping tables as all ids are fixed
	INSERT INTO csr.issue_due_source (issue_due_source_id, issue_type_id, source_description, fetch_proc)
		SELECT issue_due_source_id, issue_type_id, source_description, fetch_proc
		  FROM csrimp.issue_due_source;

	INSERT INTO csr.issue_type_aggregate_ind_grp (issue_type_id, aggregate_ind_group_id)
		SELECT /*+CARDINALITY(it, 1000) CARDINALITY(mag, 1000)*/
		       it.issue_type_id, mag.new_aggregate_ind_group_id
		  FROM csrimp.issue_type_aggregate_ind_grp it, csrimp.map_aggregate_ind_group mag
		 WHERE it.aggregate_ind_group_id = mag.old_aggregate_ind_group_id;

	INSERT INTO csr.issue_type_rag_status (issue_type_id, rag_status_id, pos)
		SELECT /*+CARDINALITY(it, 1000) CARDINALITY(mitrs, 1000)*/
		       itrs.issue_type_id, mirs.new_rag_status_id, itrs.pos
		  FROM csrimp.issue_type_rag_status itrs, csrimp.map_rag_status mirs
		 WHERE itrs.rag_status_id = mirs.old_rag_status_id;

	INSERT INTO csr.correspondent (correspondent_id, full_name, email, phone, guid, more_info_1)
		SELECT /*+CARDINALITY(mc, 1000) CARDINALITY(c, 1000)*/
			   mc.new_correspondent_id, c.full_name, c.email, c.phone, c.guid, c.more_info_1
		  FROM csrimp.correspondent c, csrimp.map_correspondent mc
		 WHERE c.correspondent_id = mc.old_correspondent_id;

	INSERT INTO csr.issue_survey_answer (issue_survey_answer_id, survey_response_id, question_id, question_version, survey_sid, survey_version)
		SELECT /*+CARDINALITY(misa, 10000) CARDINALITY(msr, 10000) CARDINALITY(mq, 1000) CARDINALITY(isa, 10000)*/
			   misa.new_issue_survey_answer_id, msr.new_survey_response_id, mq.new_question_id, isa.question_version, ms.new_sid, isa.survey_version
		  FROM csrimp.issue_survey_answer isa, csrimp.map_qs_survey_response msr,
		  	   csrimp.map_issue_survey_answer misa, csrimp.map_qs_question mq, csrimp.map_sid ms
		 WHERE isa.issue_survey_answer_id = misa.old_issue_survey_answer_id
		   AND isa.survey_response_id = msr.old_survey_response_id
		   AND isa.survey_sid = ms.old_sid
		   AND isa.question_id = mq.old_question_id;

	INSERT INTO csr.issue_non_compliance (issue_non_compliance_id, non_compliance_id)
		SELECT /*+CARDINALITY(inc, 10000) CARDINALITY(minc, 10000) CARDINALITY(mnc, 10000)*/
			   minc.new_issue_non_compliance_id, mnc.new_non_compliance_id
		  FROM csrimp.issue_non_compliance inc, csrimp.map_issue_non_compliance minc,
		  	   csrimp.map_non_compliance mnc
		 WHERE inc.issue_non_compliance_id = minc.old_issue_non_compliance_id
		   AND inc.non_compliance_id = mnc.old_non_compliance_id;

	INSERT INTO csr.issue_action (issue_action_id, task_sid)
		SELECT mia.new_issue_action_id, ms.new_sid
		  FROM csrimp.issue_action isa, csrimp.map_issue_action mia,
		  	   csrimp.map_sid ms
		 WHERE isa.issue_action_id = mia.old_issue_action_id
		   AND isa.task_sid = ms.old_sid(+);

	INSERT INTO csr.issue_compliance_region(issue_compliance_region_id, flow_item_id)
		/*+CARDINALITY(icr, 10000) CARDINALITY(micr, 10000) CARDINALITY(mfi, 100000)*/
		SELECT micr.new_issue_compliance_region_id, mfi.new_flow_item_id
		  FROM issue_compliance_region icr
		  JOIN map_issue_compliance_region micr ON icr.issue_compliance_region_id  = micr.old_issue_compliance_region_id
		  JOIN map_flow_item mfi ON icr.flow_item_id = mfi.old_flow_item_id;


	-- XXX: do we need to change the GUID?
	INSERT INTO csr.issue (first_priority_set_dtm, issue_id, label, last_label,
	           description, last_description, source_label,
			   correspondent_id, correspondent_notified, raised_by_user_sid,
			   raised_dtm, owner_user_sid, owner_role_sid, resolved_by_user_sid,
			   resolved_dtm, closed_by_user_sid, closed_dtm, assigned_to_user_sid,
			   assigned_to_role_sid, region_sid, rejected_dtm, rejected_by_user_sid,
			   due_dtm, last_due_dtm, guid, issue_pending_val_id, issue_sheet_value_id,
			   issue_survey_answer_id, issue_type_id, issue_non_compliance_id,
			   issue_action_id, issue_meter_id, issue_meter_alarm_id,
			   issue_meter_raw_data_id, issue_priority_id, last_issue_priority_id,
			   issue_meter_data_source_id, issue_compliance_region_id,
			   --issue_supplier_id,
			   is_visible, source_url,
			   deleted, parent_id, is_public, issue_escalated, allow_auto_close, is_pending_assignment,
			   first_issue_log_id, last_issue_log_id, region_2_sid, forecast_dtm, last_forecast_dtm,
			   rag_status_id, last_rag_status_id, var_expl, issue_ref, last_region_sid, manual_completion_dtm,
			   manual_comp_dtm_set_dtm, issue_due_source_id, issue_due_offset_days, issue_due_offset_months,
			   issue_due_offset_years, permit_id, is_critical, notified_overdue, copied_from_id)
		SELECT /*+CARDINALITY(i, 10000) CARDINALITY(mi, 10000) CARDINALITY(mipv, 10000)
		 	      CARDINALITY(misv, 10000) CARDINALITY(mpi, 10000) CARDINALITY(m_iprio, 1000)
		 	      CARDINALITY(m_liprio, 1000) CARDINALITY(m_imeter, 10000) CARDINALITY(m_imeter_alarm, 10000)
		 	      CARDINALITY(m_imeter_rd, 10000) CARDINALITY(m_imeter_ds, 10000) CARDINALITY(m_icr, 10000) CARDINALITY(m_corr, 10000)
		 	      CARDINALITY(misa, 10000) CARDINALITY(minc, 10000) CARDINALITY(fil, 10000) CARDINALITY(lil, 10000) */
			   i.first_priority_set_dtm, mi.new_issue_id, i.label, i.last_label,
			   i.description, i.last_description, i.source_label,
			   m_corr.new_correspondent_id, i.correspondent_notified, m_raised.new_sid,
			   i.raised_dtm, m_owner_user.new_sid, m_owner_role.new_sid, m_resolved.new_sid,
			   i.resolved_dtm, m_closed.new_sid, i.closed_dtm, m_assigned_user.new_sid,
			   m_assigned_role.new_sid, m_region.new_sid, i.rejected_dtm, m_rejected.new_sid,
			   i.due_dtm, i.last_due_dtm, i.guid, mipv.new_issue_pending_val_id, misv.new_issue_sheet_value_id,
			   misa.new_issue_survey_answer_id,
			   i.issue_type_id,
			   minc.new_issue_non_compliance_id,
			   mia.new_issue_action_id,
			   m_imeter.new_issue_meter_id, m_imeter_alarm.new_issue_meter_alarm_id,
			   m_imeter_rd.new_issue_meter_raw_data_id,
			   m_iprio.new_issue_priority_id, m_liprio.new_issue_priority_id,
			   m_imeter_ds.new_issue_meter_data_source_id, m_icr.new_issue_compliance_region_id,
			   --mis.new_issue_supplier_id,
			   i.is_visible, i.source_url,
			   i.deleted, mpi.new_issue_id, i.is_public, i.issue_escalated, allow_auto_close, i.is_pending_assignment,
			   fil.new_issue_log_id, lil.new_issue_log_id, m_region_2.new_sid, i.forecast_dtm, i.last_forecast_dtm,
			   m_rs.new_rag_status_id, m_lrs.new_rag_status_id, var_expl, i.issue_ref, m_last_region.new_sid, i.manual_completion_dtm,
			   i.manual_comp_dtm_set_dtm, i.issue_due_source_id, i.issue_due_offset_days,
			   i.issue_due_offset_months, i.issue_due_offset_years, mcp.new_compliance_permit_id, i.is_critical,
			   i.notified_overdue, mci.new_issue_id
		  FROM csrimp.issue i,
		  	   csrimp.map_issue mi,
		  	   csrimp.map_sid m_owner_user,
		  	   csrimp.map_sid m_owner_role,
		  	   csrimp.map_sid m_resolved,
		  	   csrimp.map_sid m_closed,
		  	   csrimp.map_sid m_assigned_user,
		  	   csrimp.map_sid m_assigned_role,
		  	   csrimp.map_sid m_region,
		  	   csrimp.map_sid m_rejected,
		  	   csrimp.map_sid m_raised,
		  	   csrimp.map_issue_pending_val mipv,
		  	   csrimp.map_issue_sheet_value misv,
		  	   csrimp.map_issue mpi,
		  	   csrimp.map_issue_priority m_iprio,
		  	   csrimp.map_issue_priority m_liprio,
		  	   csrimp.map_issue_meter m_imeter,
		  	   csrimp.map_issue_meter_alarm m_imeter_alarm,
		  	   csrimp.map_issue_meter_raw_data m_imeter_rd,
		  	   csrimp.map_issue_meter_data_source m_imeter_ds,
			   csrimp.map_issue_compliance_region m_icr,
		  	   csrimp.map_correspondent m_corr,
		  	   csrimp.map_issue_survey_answer misa,
		  	   csrimp.map_issue_non_compliance minc,
			   csrimp.map_issue_log fil,
			   csrimp.map_issue_log lil,
			   csrimp.map_sid m_region_2,
			   csrimp.map_rag_status m_rs,
			   csrimp.map_rag_status m_lrs,
			   csrimp.map_issue_action mia,
			   csrimp.map_sid m_last_region,
			   csrimp.map_compliance_permit mcp,
			   csrimp.map_issue mci
			   --csrimp.map_issue_supplier mis
		 WHERE i.issue_id = mi.old_issue_id
		   AND i.correspondent_id = m_corr.old_correspondent_id(+)
		   AND i.raised_by_user_sid = m_raised.old_sid
		   AND i.owner_user_sid = m_owner_user.old_sid(+)
		   AND i.owner_role_sid = m_owner_role.old_sid(+)
		   AND i.resolved_by_user_sid = m_resolved.old_sid(+)
		   AND i.closed_by_user_sid = m_closed.old_sid(+)
		   AND i.region_sid = m_region.old_sid(+)
		   AND i.assigned_to_user_sid = m_assigned_user.old_sid(+)
		   AND i.assigned_to_role_sid = m_assigned_role.old_sid(+)
		   AND i.rejected_by_user_sid = m_rejected.old_sid(+)
		   AND i.issue_pending_val_id = mipv.old_issue_pending_val_id(+)
		   AND i.issue_sheet_value_id = misv.old_issue_sheet_value_id(+)
		   AND i.parent_id = mpi.old_issue_id(+)
		   AND i.issue_priority_id = m_iprio.old_issue_priority_id(+)
		   AND i.last_issue_priority_id = m_liprio.old_issue_priority_id(+)
		   AND i.issue_meter_id = m_imeter.old_issue_meter_id(+)
		   AND i.issue_meter_alarm_id = m_imeter_alarm.old_issue_meter_alarm_id(+)
		   AND i.issue_meter_raw_data_id = m_imeter_rd.old_issue_meter_raw_data_id(+)
		   AND i.issue_meter_data_source_id = m_imeter_ds.old_issue_meter_data_source_id(+)
		   AND i.issue_compliance_region_id = m_icr.old_issue_compliance_region_id(+)
		   AND i.issue_survey_answer_id = misa.old_issue_survey_answer_id(+)
		   AND i.issue_non_compliance_id = minc.old_issue_non_compliance_id(+)
		   AND i.first_issue_log_id = fil.old_issue_log_id(+)
		   AND i.last_issue_log_id = lil.old_issue_log_id(+)
		   AND i.region_2_sid = m_region_2.old_sid(+)
		   AND i.rag_status_id = m_rs.old_rag_status_id(+)
		   AND i.last_rag_status_id = m_lrs.old_rag_status_id(+)
		   AND i.issue_action_id = mia.old_issue_action_id(+)
		   AND i.last_region_sid = m_last_region.old_sid(+)
		   AND i.permit_id = mcp.old_compliance_permit_id(+)
		   AND i.copied_from_id = mci.old_issue_id(+);
		   --AND i.issue_supplier_id = mis.old_issue_supplier_id(+);

	INSERT INTO csr.issue_log (issue_log_id, issue_id, message, logged_dtm,
		is_system_generated, logged_by_user_sid, logged_by_correspondent_id,
		param_1, param_2, param_3)
		SELECT /*+CARDINALITY(il, 10000) CARDINALITY(mi, 10000) CARDINALITY(mi, 10000)
			      CARDINALITY(mc, 10000)*/
			   mil.new_issue_log_id, mi.new_issue_id, il.message, il.logged_dtm,
			   il.is_system_generated, mu.new_sid, mc.new_correspondent_id,
			   il.param_1, il.param_2, il.param_3
		  FROM csrimp.issue_log il, csrimp.map_issue_log mil, csrimp.map_issue mi,
		  	   csrimp.map_sid mu, csrimp.map_correspondent mc
		 WHERE il.issue_log_id = mil.old_issue_log_id
		   AND il.issue_id = mi.old_issue_id(+)
		   AND il.logged_by_user_sid = mu.old_sid(+)
		   AND il.logged_by_correspondent_id = mc.old_correspondent_id(+);

	INSERT INTO csr.issue_log_file (issue_log_file_id, issue_log_id, filename,
			   mime_type, data, sha1, uploaded_dtm, archive_file_id, archive_file_size)
		SELECT /*+CARDINALITY(ilf, 10000) CARDINALITY(mil, 10000)*/
			   csr.issue_log_file_id_seq.nextval, mil.new_issue_log_id, ilf.filename,
			   ilf.mime_type, ilf.data, ilf.sha1, ilf.uploaded_dtm, ilf.archive_file_id, ilf.archive_file_size
		  FROM csrimp.issue_log_file ilf, csrimp.map_issue_log mil
		 WHERE ilf.issue_log_id = mil.old_issue_log_id;

	INSERT INTO csr.issue_log_read (issue_log_id, read_dtm, csr_user_sid)
		SELECT /*+CARDINALITY(ilr, 10000) CARDINALITY(mil, 10000) CARDINALITY(mu, 50000)*/
			   mil.new_issue_log_id, ilr.read_dtm, mu.new_sid
		  FROM csrimp.issue_log_read ilr, csrimp.map_issue_log mil,
		  	   csrimp.map_sid mu
		 WHERE ilr.issue_log_id = mil.old_issue_log_id
		   AND ilr.csr_user_sid = mu.old_sid;

	INSERT INTO csr.issue_action_log (issue_action_log_id, issue_action_type_id, issue_id, issue_log_id,
		logged_by_user_sid, logged_by_correspondent_id, logged_dtm,
		assigned_to_role_sid, assigned_to_user_sid, re_user_sid, re_role_sid,
		old_label, new_label, old_due_dtm, new_due_dtm, old_priority_id,
		new_priority_id, old_description, new_description, old_forecast_dtm,
		new_forecast_dtm, owner_user_sid, old_region_sid, new_region_sid,
		new_manual_comp_dtm_set_dtm, new_manual_comp_dtm, involved_user_sid, involved_user_sid_removed,
		is_public)
		SELECT /*+CARDINALITY(ial, 10000) CARDINALITY(mi, 10000) CARDINALITY(mil, 10000)
				  CARDINALITY(mipc, 1000) CARDINALITY(mipn, 1000)
		        */
			   csr.issue_action_log_id_seq.nextval, ial.issue_action_type_id, mi.new_issue_id,
			   mil.new_issue_log_id, mlu.new_sid, mc.new_correspondent_id, ial.logged_dtm,
			   mar.new_sid, mau.new_sid, mreu.new_sid, mrer.new_sid,
			   ial.old_label, ial.new_label, ial.old_due_dtm, ial.new_due_dtm,
			   mipo.new_issue_priority_id, mipn.new_issue_priority_id,
			   ial.old_description, ial.new_description,
			   ial.old_forecast_dtm, ial.new_forecast_dtm, mou.new_sid, mor.new_sid, mnr.new_sid,
			   ial.new_manual_comp_dtm_set_dtm, ial.new_manual_comp_dtm, miu.new_sid, miur.new_sid,
			   ial.is_public			   
		  FROM csrimp.issue_action_log ial, csrimp.map_issue mi, csrimp.map_issue_log mil,
		  	   csrimp.map_sid mlu, csrimp.map_correspondent mc, csrimp.map_sid mar,
		  	   csrimp.map_sid mau, csrimp.map_sid mreu, csrimp.map_sid mrer,
		  	   csrimp.map_issue_priority mipo, csrimp.map_issue_priority mipn,
		  	   csrimp.map_sid mou, csrimp.map_sid mor, csrimp.map_sid mnr, csrimp.map_sid miu, csrimp.map_sid miur
		 WHERE ial.issue_id = mi.old_issue_id(+)
		   AND ial.issue_log_id = mil.old_issue_log_id(+)
		   AND ial.logged_by_user_sid = mlu.old_sid(+)
		   AND ial.logged_by_correspondent_id = mc.old_correspondent_id(+)
		   AND ial.assigned_to_role_sid = mar.old_sid(+)
		   AND ial.assigned_to_user_sid = mau.old_sid(+)
		   AND ial.re_user_sid = mreu.old_sid(+)
		   AND ial.re_role_sid = mrer.old_sid(+)
		   AND ial.old_priority_id = mipo.old_issue_priority_id(+)
		   AND ial.new_priority_id = mipn.old_issue_priority_id(+)
		   AND ial.owner_user_sid = mou.old_sid(+)
		   AND ial.old_region_sid = mor.old_sid(+)
		   AND ial.new_region_sid = mnr.old_sid(+)
		   AND ial.involved_user_sid = miu.old_sid(+)
		   AND ial.involved_user_sid_removed = miur.old_sid(+);

	INSERT INTO csr.issue_custom_field (issue_custom_field_id, issue_type_id, field_type, label, is_mandatory, pos, field_reference_name, restrict_to_group_sid)
		SELECT /*+CARDINALITY(micf, 1000) CARDINALITY(icf, 1000)*/
			   micf.new_issue_custom_field_id, icf.issue_type_id, icf.field_type, icf.label, icf.is_mandatory, icf.pos, icf.field_reference_name, micfg.new_sid
		  FROM csrimp.issue_custom_field icf, csrimp.map_issue_custom_field micf, csrimp.map_sid micfg
		 WHERE icf.issue_custom_field_id = micf.old_issue_custom_field_id
		   AND icf.restrict_to_group_sid = micfg.old_sid(+);

	-- another oddity -- presumably these are manually set up so the opt_id doesn't need mapping
	INSERT INTO csr.issue_custom_field_option (issue_custom_field_id, issue_custom_field_opt_id, label)
		SELECT /*+CARDINALITY(micf, 1000) CARDINALITY(icfo, 10000)*/
			   micf.new_issue_custom_field_id, icfo.issue_custom_field_opt_id, icfo.label
		  FROM csrimp.issue_custom_field_option icfo, csrimp.map_issue_custom_field micf
		 WHERE icfo.issue_custom_field_id = micf.old_issue_custom_field_id;

	INSERT INTO csr.issue_custom_field_opt_sel (issue_id, issue_custom_field_id, issue_custom_field_opt_id)
		SELECT /*+CARDINALITY(icfos, 1000) CARDINALITY(mi, 10000) CARDINALITY(micf, 1000)*/
			   mi.new_issue_id, micf.new_issue_custom_field_id, icfos.issue_custom_field_opt_id
		  FROM csrimp.issue_custom_field_opt_sel icfos, csrimp.map_issue mi,
		  	   csrimp.map_issue_custom_field micf
		 WHERE icfos.issue_id = mi.old_issue_id
		   AND icfos.issue_custom_field_id = micf.old_issue_custom_field_id;

	INSERT INTO csr.issue_custom_field_str_val (issue_id, issue_custom_field_id, string_value)
		SELECT /*+CARDINALITY(icfsv, 1000) CARDINALITY(mi, 10000) CARDINALITY(micf, 1000)*/
			   mi.new_issue_id, micf.new_issue_custom_field_id, icfsv.string_value
		  FROM csrimp.issue_custom_field_str_val icfsv, csrimp.map_issue mi,
		  	   csrimp.map_issue_custom_field micf
		 WHERE icfsv.issue_id = mi.old_issue_id
		   AND icfsv.issue_custom_field_id = micf.old_issue_custom_field_id;

	INSERT INTO csr.issue_custom_field_date_val (issue_id, issue_custom_field_id, date_value)
		SELECT /*+CARDINALITY(icfsv, 1000) CARDINALITY(mi, 10000) CARDINALITY(micf, 1000)*/
			   mi.new_issue_id, micf.new_issue_custom_field_id, icfdv.date_value
		  FROM csrimp.issue_custom_field_date_val icfdv, csrimp.map_issue mi,
		  	   csrimp.map_issue_custom_field micf
		 WHERE icfdv.issue_id = mi.old_issue_id
		   AND icfdv.issue_custom_field_id = micf.old_issue_custom_field_id;

	INSERT INTO csr.issue_scheduled_task (issue_scheduled_task_id, label, schedule_xml, period_xml,
			   last_created, raised_by_user_sid, assign_to_user_sid, next_run_dtm, create_critical,
			   due_dtm_relative, due_dtm_relative_unit, scheduled_on_due_date, issue_type_id,
			   copied_from_id, region_sid)
		SELECT /*+CARDINALITY(ist, 1000) CARDINALITY(mist, 1000) CARDINALITY(mru, 10000) CARDINALITY(mau, 10000) CARDINALITY(mcist, 1000) CARDINALITY(mr, 10000)*/
			   mist.new_issue_scheduled_task_id, ist.label, ist.schedule_xml, ist.period_xml,
			   ist.last_created, mru.new_sid, mau.new_sid, ist.next_run_dtm, ist.create_critical,
			   due_dtm_relative, due_dtm_relative_unit, ist.scheduled_on_due_date, ist.issue_type_id,
			   mcist.new_issue_scheduled_task_id, mr.new_sid
		  FROM issue_scheduled_task ist
		  JOIN map_issue_scheduled_task mist ON mist.old_issue_scheduled_task_id  = ist.issue_scheduled_task_id
		  JOIN map_sid mru ON mru.old_sid = ist.raised_by_user_sid
		  JOIN map_sid mau ON mau.old_sid = ist.assign_to_user_sid
	 LEFT JOIN map_issue_scheduled_task mcist ON mcist.old_issue_scheduled_task_id = ist.copied_from_id
	 LEFT JOIN map_sid mr ON mr.old_sid = ist.region_sid;

	INSERT INTO csr.issue_user_cover (user_cover_id, user_giving_cover_sid,
		user_being_covered_sid, issue_id)
		SELECT /*+ALL_ROWS CARDINALITY(iuc, 1000) CARDINALITY(muc, 1000) CARDINALITY(mugc, 10000) CARDINALITY(mubc, 10000) CARDINALITY(mi, 10000)*/
			   muc.new_user_cover_id, mugc.new_sid, mubc.new_sid, mi.new_issue_id
		  FROM csrimp.issue_user_cover iuc, csrimp.map_user_cover muc,
		       csrimp.map_sid mugc, csrimp.map_sid mubc, csrimp.map_issue mi
		 WHERE iuc.user_cover_id = muc.old_user_cover_id
		   AND iuc.user_giving_cover_sid = mugc.old_sid
		   AND iuc.user_being_covered_sid = mubc.old_sid
		   AND iuc.issue_id = mi.old_issue_id;

	INSERT INTO csr.issue_alert (
				issue_id,
				csr_user_sid,
				overdue_sent_dtm,
				reminder_sent_dtm
	   ) SELECT mi.new_issue_id,
				ms.new_sid,
				ia.overdue_sent_dtm,
				ia.reminder_sent_dtm
		   FROM csrimp.issue_alert ia,
				csrimp.map_issue mi,
				csrimp.map_sid ms
		  WHERE ia.issue_id = mi.old_issue_id
			AND ia.csr_user_sid = ms.old_sid;

	INSERT INTO csr.comp_item_region_sched_issue (flow_item_id, issue_scheduled_task_id)
		SELECT mfi.new_flow_item_id, mist.new_issue_scheduled_task_id
		  FROM comp_item_region_sched_issue cirsi
		  JOIN map_flow_item mfi ON cirsi.flow_item_id = mfi.old_flow_item_id
		  JOIN map_issue_scheduled_task mist ON cirsi.issue_scheduled_task_id = mist.old_issue_scheduled_task_id;

	INSERT INTO csr.issue_template (
				issue_template_id,
				assign_to_user_sid,
				description,
				due_dtm,
				due_dtm_relative,
				due_dtm_relative_unit,
				issue_type_id,
				is_critical,
				is_urgent,
				label
	   ) SELECT mit.new_issue_template_id,
				ms.new_sid,
				it.description,
				it.due_dtm,
				it.due_dtm_relative,
				it.due_dtm_relative_unit,
				it.issue_type_id,
				it.is_critical,
				it.is_urgent,
				it.label
		   FROM csrimp.issue_template it,
				csrimp.map_issue_template mit,
				csrimp.map_sid ms
		  WHERE it.issue_template_id = mit.old_issue_template_id
			AND it.assign_to_user_sid = ms.old_sid(+);

	INSERT INTO csr.issue_template_custom_field (
				issue_template_id,
				issue_custom_field_id,
				date_value,
				string_value
	)
		SELECT mit.new_issue_template_id,
			   micf.new_issue_custom_field_id,
			   itcf.date_value,
			   itcf.string_value
		  FROM csrimp.issue_template_custom_field itcf,
			   csrimp.map_issue_template mit,
			   csrimp.map_issue_custom_field micf
		 WHERE itcf.issue_template_id = mit.old_issue_template_id
		   AND itcf.issue_custom_field_id = micf.old_issue_custom_field_id;


	INSERT INTO csr.issue_template_cust_field_opt (
				issue_template_id,
				issue_custom_field_id,
				issue_custom_field_opt_id
	)
		SELECT mit.new_issue_template_id,
			   micf.new_issue_custom_field_id,
			   itcfo.issue_custom_field_opt_id
		  FROM csrimp.issue_template_cust_field_opt itcfo,
			   csrimp.map_issue_template mit,
			   csrimp.map_issue_custom_field micf
		 WHERE itcfo.issue_template_id = mit.old_issue_template_id
		   AND itcfo.issue_custom_field_id = micf.old_issue_custom_field_id;
END;

-- JSON with ids in into a database table.  Hideous.
PROCEDURE FixTabPortletStates
AS
	v_pos							INTEGER;
	v_sid_pos						INTEGER;
	v_temp_sid_pos					INTEGER;
	v_result 						CLOB;
	TYPE t_variants IS TABLE OF VARCHAR2(100);
	v_variants 						t_variants;
	v_variant_length				INTEGER;
	v_sid	 						VARCHAR2(128);
	v_sid_length 					INTEGER;
	v_new_sid 						VARCHAR2(128);
	v_len 							INTEGER;
	v_in							CLOB;
BEGIN
	v_variants := t_variants(
		'sid:', 'sid":', 'Sid:', 'Sid":',
		'sid:"', 'sid":"', 'Sid:"', 'Sid":"',
		'uniqueId:', 'uniqueId":',
		'uniqueId:"', 'uniqueId":"'
	);
	FOR r IN (SELECT tab_portlet_id, state
				FROM csr.tab_portlet) LOOP
		--dbms_output.put_line('in:  '||r.state);
		v_in := r.state;
		v_pos := 1;
		dbms_lob.createTemporary(v_result, TRUE, dbms_lob.call);
		LOOP
			v_sid_pos := 0;
			FOR v_i IN 1 .. v_variants.COUNT LOOP
				v_temp_sid_pos := dbms_lob.instr(v_in, v_variants(v_i), v_pos);
				IF v_temp_sid_pos != 0 AND (
					v_sid_pos = 0 OR v_temp_sid_pos < v_sid_pos OR
					(v_temp_sid_pos = v_sid_pos AND LENGTH(v_variants(v_i)) > v_variant_length)
				) THEN
					v_sid_pos := v_temp_sid_pos;
					v_variant_length := LENGTH(v_variants(v_i));
				END IF;
			END LOOP;
			--dbms_output.put_line('sid pos = '||v_sid_pos||' var len = '||v_variant_length);
			EXIT WHEN v_sid_pos = 0;
			dbms_lob.copy(v_result, v_in, v_sid_pos + v_variant_length - v_pos, 1 + dbms_lob.getLength(v_result), v_pos);
			v_pos := v_sid_pos + v_variant_length;

			v_sid_length := 32;
			dbms_lob.read(v_in, v_sid_length, v_pos, v_sid);
			--dbms_output.put_line('sid = '||v_sid);

			v_temp_sid_pos := 1;
			LOOP
				--dbms_output.put_line( 'c = '||SUBSTR(v_sid, v_temp_sid_pos, 1));
				EXIT WHEN v_temp_sid_pos > LENGTH(v_sid) OR NOT REGEXP_LIKE(SUBSTR(v_sid, v_temp_sid_pos, 1), '^[0-9 \t]$');
				v_temp_sid_pos := v_temp_sid_pos + 1;
			END LOOP;
			IF v_temp_sid_pos > 1 THEN
				BEGIN
					--dbms_output.put_line('remap: '||SUBSTR(v_sid, 1, v_temp_sid_pos - 1));
					SELECT TO_CHAR(new_sid)
					  INTO v_new_sid
					  FROM csrimp.map_sid
					 WHERE old_sid = TO_NUMBER(SUBSTR(v_sid, 1, v_temp_sid_pos - 1));

					v_pos := v_pos + v_temp_sid_pos - 1;
					dbms_lob.write(v_result, LENGTH(v_new_sid), 1 + dbms_lob.getLength(v_result), v_new_sid);
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						-- Since there's no RI then just ignore missing sids
						NULL;
				END;
			END IF;
		END LOOP;
		v_len := dbms_lob.getLength(v_in);
		IF v_pos <= v_len THEN
			--dbms_output.put_line('pos = '||v_pos||', len = '||v_len||', rlen='||dbms_lob.getLength(v_result)||' r so far '||v_result);
			dbms_lob.copy(v_result, v_in, v_len - v_pos + 1, 1 + dbms_lob.getLength(v_result), v_pos);
		END IF;
		--dbms_output.put_line('out: '||v_result);
		UPDATE csr.tab_portlet
		   SET state = v_result
		 WHERE tab_portlet_id = r.tab_portlet_id;
	END LOOP;
END;

PROCEDURE CreatePortlets
AS
BEGIN
	INSERT INTO csr.customer_portlet (customer_portlet_sid, portlet_id,
		default_state, portal_group)
		SELECT mcp.new_sid, cp.portlet_id, cp.default_state, cp.portal_group
		  FROM csrimp.customer_portlet cp, csrimp.map_sid mcp
		 WHERE cp.customer_portlet_sid = mcp.old_sid;

	INSERT INTO csr.tab (tab_id, layout, name, is_shared, portal_group, override_pos, is_hideable)
		SELECT mt.new_tab_id, t.layout, t.name, t.is_shared, t.portal_group, t.override_pos, t.is_hideable
		  FROM csrimp.tab t, csrimp.map_tab mt
		 WHERE t.tab_id = mt.old_tab_id;

	INSERT INTO csr.tab_group (tab_id, group_sid, pos)
		SELECT mt.new_tab_id, mg.new_sid, tg.pos
		  FROM csrimp.tab_group tg, csrimp.map_tab mt,
		       csrimp.map_sid mg
		 WHERE tg.tab_id = mt.old_tab_id
		   AND tg.group_sid = mg.old_sid;

	INSERT INTO csr.tab_portlet (tab_portlet_id, tab_id, column_num, pos,
		state, customer_portlet_sid, added_by_user_sid, added_dtm)
		SELECT mtp.new_tab_portlet_id, mt.new_tab_id, tp.column_num,
			   tp.pos, tp.state, ms.new_sid, mu.new_sid, tp.added_dtm
		  FROM csrimp.tab_portlet tp, csrimp.map_tab_portlet mtp,
		  	   csrimp.map_tab mt, csrimp.map_sid ms, csrimp.map_sid mu
		 WHERE tp.tab_portlet_id = mtp.old_tab_portlet_id
		   AND tp.tab_id = mt.old_tab_id
		   AND tp.customer_portlet_sid = ms.old_sid
		   AND tp.added_by_user_sid = mu.old_sid(+);

	-- now the portlet exists, fix up customer.trucost_portlet_tab_id
	UPDATE csr.customer
	   SET trucost_portlet_tab_id = (
			SELECT mtp.new_tab_portlet_id
			  FROM csrimp.map_tab_portlet mtp, csrimp.customer c
			 WHERE c.trucost_portlet_tab_id = mtp.old_tab_portlet_id)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	FixTabPortletStates;

	-- deal with another dodgy cross-app shared table
	INSERT INTO csr.rss_cache (rss_url, last_updated, xml, last_error, error_count)
		SELECT rss_url, last_updated, xml, last_error, error_count
		  FROM csrimp.rss_cache
		 WHERE rss_url NOT IN (
		 		SELECT rss_url
		 		  FROM csr.rss_cache);

	INSERT INTO csr.tab_portlet_rss_feed (tab_portlet_id, rss_url)
		SELECT mtp.new_tab_portlet_id, tprf.rss_url
		  FROM csrimp.tab_portlet_rss_feed tprf, csrimp.map_tab_portlet mtp
		 WHERE tprf.tab_portlet_id = mtp.old_tab_portlet_id;

	INSERT INTO csr.tab_portlet_user_region (tab_portlet_id, csr_user_sid, region_sid)
		SELECT /*+CARDINALITY(mtp, 1000) CARDINALITY(tpur, 1000)*/
			   mtp.new_tab_portlet_id, mu.new_sid, mr.new_sid
		  FROM csrimp.tab_portlet_user_region tpur, csrimp.map_tab_portlet mtp,
		  	   csrimp.map_sid mu, csrimp.map_sid mr
		 WHERE tpur.tab_portlet_id = mtp.old_tab_portlet_id
		   AND tpur.csr_user_sid = mu.old_sid
		   AND tpur.region_sid = mr.old_sid;

	INSERT INTO csr.tab_user (tab_id, user_sid, pos, is_owner, is_hidden)
		SELECT mt.new_tab_id, mu.new_sid, tu.pos, tu.is_owner, tu.is_hidden
		  FROM csrimp.tab_user tu, csrimp.map_tab mt, csrimp.map_sid mu
		 WHERE tu.tab_id = mt.old_tab_id
		   AND tu.user_sid = mu.old_sid;

	-- yet another half shared table.  sigh.
	INSERT INTO csr.user_setting
		SELECT category, setting, description, data_type
		  FROM csrimp.user_setting
		 WHERE (category, setting) NOT IN (
		 		SELECT category, setting
		 		  FROM csr.user_setting);

	INSERT INTO csr.user_setting_entry (csr_user_sid, category, setting, tab_portlet_id, value)
		SELECT mu.new_sid, us.category, us.setting, mtp.new_tab_portlet_id, value
		  FROM csrimp.user_setting_entry us, csrimp.map_sid mu,
		  	   csrimp.map_tab_portlet mtp
		 WHERE us.csr_user_sid = mu.old_sid
		   AND us.tab_portlet_id = mtp.old_tab_portlet_id;

	INSERT INTO csr.hide_portlet (portlet_id)
		 SELECT portlet_id
		   FROM csrimp.hide_portlet;

	INSERT INTO csrimp.map_image_upload_portlet (old_image_upload_portlet_id, new_image_upload_portlet_id)
		 SELECT img_id, csr.image_upload_portlet_seq.NEXTVAL
		   FROM csrimp.image_upload_portlet;

	INSERT INTO csr.image_upload_portlet (
				file_name, image, img_id, mime_type
	   ) SELECT iup.file_name, iup.image, miup.new_image_upload_portlet_id, iup.mime_type
		   FROM csrimp.image_upload_portlet iup,
				csrimp.map_image_upload_portlet miup
		  WHERE iup.img_id = miup.old_image_upload_portlet_id;

	INSERT INTO csr.tab_description (tab_id, lang, description, last_changed_dtm)
		SELECT mt.new_tab_id, td.lang, td.description, td.last_changed_dtm
		  FROM csrimp.tab_description td, csrimp.map_tab mt
		 WHERE td.tab_id = mt.old_tab_id;
END;

PROCEDURE CreatePortalDashboards
AS
BEGIN
	INSERT INTO csr.portal_dashboard (portal_sid, portal_group, menu_sid, message)
		SELECT mp.new_sid, pd.portal_group, mm.new_sid, pd.message
		  FROM csrimp.map_sid mp, csrimp.map_sid mm, csrimp.portal_dashboard pd
		 WHERE pd.portal_sid = mp.old_sid
		   AND pd.menu_sid = mm.old_sid(+);

	FOR r IN (SELECT portal_sid, menu_sid FROM csr.portal_dashboard WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND menu_sid IS NOT NULL)
	LOOP
		UPDATE security.menu
		   SET action = substr(action, 0, instr(action, 'portalSid=') - 1) || 'portalSid=' || r.portal_sid
		 WHERE sid_id = r.menu_sid;
	END LOOP;
END;

PROCEDURE CreateApprovalDashboards
AS
BEGIN
	INSERT INTO	csr.approval_dashboard (approval_dashboard_sid, label, flow_sid,
		tpl_report_sid, is_multi_region,start_dtm, end_dtm,active_period_scenario_run_sid,
		signed_off_scenario_run_sid, instance_creation_schedule, period_set_id, period_interval_id,
		publish_doc_folder_sid, source_scenario_run_sid
		)
		SELECT mad.new_sid, ad.label, mf.new_sid, mtpl.new_sid,
			   ad.is_multi_region, ad.start_dtm, ad.end_dtm, apsrs.new_sid, sosrs.new_sid,
			   ad.instance_creation_schedule, ad.period_set_id, ad.period_interval_id, pdfs.new_sid, srs.new_sid
		  FROM csrimp.approval_dashboard ad, csrimp.map_sid mad,
		  	   csrimp.map_sid mf, csrimp.map_sid mtpl, csrimp.map_sid apsrs, csrimp.map_sid sosrs, csrimp.map_sid pdfs,
		       csrimp.map_sid srs
		 WHERE ad.approval_dashboard_sid = mad.old_sid
		   AND ad.flow_sid = mf.old_sid(+)
		   AND ad.tpl_report_sid = mtpl.old_sid(+)
		   AND ad.active_period_scenario_run_sid = apsrs.old_sid(+)
		   AND ad.signed_off_scenario_run_sid = sosrs.old_sid(+)
		   AND ad.publish_doc_folder_sid = pdfs.old_sid(+)
		   AND ad.source_scenario_run_sid = srs.old_sid(+);

	INSERT INTO csr.approval_dashboard_alert_type (approval_dashboard_sid,
		customer_alert_type_id, flow_sid)
		SELECT mad.new_sid, mcat.new_customer_alert_type_id, mf.new_sid
		  FROM csrimp.approval_dashboard_alert_type adat, csrimp.map_sid mad,
		  	   csrimp.map_customer_alert_type mcat, csrimp.map_sid mf
		 WHERE adat.approval_dashboard_sid = mad.old_sid
		   AND adat.customer_alert_type_id = mcat.old_customer_alert_type_id
		   AND adat.flow_sid = mf.old_sid;

	INSERT INTO csr.tpl_report_tag_approval_note (tpl_report_tag_app_note_id, tab_portlet_id, approval_dashboard_sid)
		SELECT mtrtan.new_tpl_rep_tag_appr_note_id, mtp.new_tab_portlet_id, ad.new_sid
		  FROM csrimp.tpl_report_tag_approval_note trtan, map_tpl_rep_tag_appr_note mtrtan, csrimp.map_tab_portlet mtp, csrimp.map_sid ad
		 WHERE trtan.tpl_report_tag_app_note_id = mtrtan.old_tpl_rep_tag_appr_note_id
		   AND trtan.tab_portlet_id = mtp.old_tab_portlet_id
		   AND trtan.approval_dashboard_sid = ad.old_sid;

	INSERT INTO csr.tpl_report_tag_approval_matrix (tpl_report_tag_app_matrix_id, approval_dashboard_sid)
		SELECT mtrtam.new_tpl_rep_tag_appr_matr_id, ad.new_sid
		  FROM csrimp.tpl_report_tag_approval_matrix trtam, map_tpl_report_tag_appr_matr mtrtam, csrimp.map_sid ad
		 WHERE trtam.tpl_report_tag_app_matrix_id = mtrtam.old_tpl_rep_tag_appr_matr_id
		   AND trtam.approval_dashboard_sid = ad.old_sid;
END;

PROCEDURE CreateApprovalDashInstances
AS
BEGIN
	INSERT INTO csr.approval_dashboard_region (approval_dashboard_sid, region_sid)
		SELECT mad.new_sid, mr.new_sid
		  FROM csrimp.approval_dashboard_region adr, csrimp.map_sid mad,
		  	   csrimp.map_sid mr
		 WHERE adr.approval_dashboard_sid = mad.old_sid
		   AND adr.region_sid = mr.old_sid;

	INSERT INTO csr.approval_dashboard_instance (dashboard_instance_id,
		approval_dashboard_sid, region_sid, start_dtm, end_dtm, tpl_report_sid, last_refreshed_dtm, is_locked, is_signed_off)
		SELECT madi.new_dashboard_instance_id, mad.new_sid, mr.new_sid,
			   adi.start_dtm, adi.end_dtm, mtpl.new_sid, adi.last_refreshed_dtm, adi.is_locked, adi.is_signed_off
		  FROM csrimp.approval_dashboard_instance adi,
		  	   csrimp.map_dashboard_instance madi, csrimp.map_sid mad,
		  	   csrimp.map_sid mr, csrimp.map_sid mtpl
		 WHERE adi.dashboard_instance_id = madi.old_dashboard_instance_id
		   AND adi.approval_dashboard_sid = mad.old_sid
		   AND adi.region_sid = mr.old_sid
		   AND adi.tpl_report_sid = mtpl.old_sid(+);

	-- Update flow_item (ideally we should move the RI the other way around)
	UPDATE csr.flow_item fi
	   SET fi.dashboard_instance_id = (
		SELECT mdi.new_dashboard_instance_id
		  FROM csrimp.flow_item ofi
		  JOIN csrimp.map_dashboard_instance mdi ON mdi.old_dashboard_instance_id = ofi.dashboard_instance_id
		  JOIN csrimp.map_flow_item mfi ON ofi.flow_item_id = mfi.old_flow_item_id
		 WHERE mfi.new_flow_item_id = fi.flow_item_id
		);

	INSERT INTO csr.approval_dashboard_tab (approval_dashboard_sid, tab_id, pos)
		SELECT mad.new_sid, mt.new_tab_id, adt.pos
		  FROM csrimp.approval_dashboard_tab adt, csrimp.map_sid mad, csrimp.map_tab mt
		 WHERE adt.approval_dashboard_sid = mad.old_sid
		   AND adt.tab_id = mt.old_tab_id;

	INSERT INTO csr.approval_dashboard_tpl_tag (dashboard_instance_id, tpl_report_sid,
		tag, note)
		SELECT madi.new_dashboard_instance_id, mtpl.new_sid, adtt.tag, adtt.note
		  FROM csrimp.approval_dashboard_tpl_tag adtt, csrimp.map_sid mtpl,
		  	   csrimp.map_dashboard_instance madi
		 WHERE adtt.dashboard_instance_id = madi.old_dashboard_instance_id
		   AND adtt.tpl_report_sid = mtpl.old_sid;

	INSERT INTO csr.approval_dashboard_ind (approval_dashboard_sid, ind_sid, deactivated_dtm, allow_estimated_data, pos, is_hidden)
		SELECT madi.new_sid, mi.new_sid, adi.deactivated_dtm, adi.allow_estimated_data, adi.pos, adi.is_hidden
		  FROM csrimp.approval_dashboard_ind adi, csrimp.map_sid madi, csrimp.map_sid mi
		 WHERE adi.approval_dashboard_sid = madi.old_sid
		   AND adi.ind_sid = mi.old_sid;

	INSERT INTO csr.approval_dashboard_val (approval_dashboard_val_id,  approval_dashboard_sid, dashboard_instance_id,
		ind_sid, start_dtm, end_dtm, val_number, ytd_val_number, note, note_added_by_sid, note_added_dtm, is_estimated_data)
		SELECT madv.new_approval_dashboard_val_id, ad.new_sid, madi.new_dashboard_instance_id, mi.new_sid, adv.start_dtm,
			   adv.end_dtm, adv.val_number, adv.ytd_val_number, adv.note, cu.new_sid, adv.note_added_dtm, adv.is_estimated_data
		  FROM csrimp.approval_dashboard_val adv, csrimp.map_appr_dash_val madv, csrimp.map_sid ad, csrimp.map_dashboard_instance madi,
		       csrimp.map_sid mi, csrimp.map_sid cu
		 WHERE adv.approval_dashboard_val_id = madv.old_approval_dashboard_val_id
		   AND adv.approval_dashboard_sid = ad.old_sid
		   AND adv.dashboard_instance_id = madi.old_dashboard_instance_id
		   AND adv.ind_sid = mi.old_sid
		   AND adv.note_added_by_sid = cu.old_sid(+);

	INSERT INTO csr.approval_note_portlet_note (version, tab_portlet_id, approval_dashboard_sid, dashboard_instance_id,
		region_sid, note, added_dtm, added_by_sid)
		SELECT anpn.version, mtp.new_tab_portlet_id, ad.new_sid, mdi.new_dashboard_instance_id, mr.new_sid, note, added_dtm, cu.new_sid
		  FROM approval_note_portlet_note anpn, csrimp.map_tab_portlet mtp, csrimp.map_sid ad, csrimp.map_dashboard_instance mdi,
			   csrimp.map_sid mr, csrimp.map_sid cu
		 WHERE anpn.tab_portlet_id = mtp.old_tab_portlet_id
		   AND anpn.approval_dashboard_sid = ad.old_sid
		   AND anpn.dashboard_instance_id = mdi.old_dashboard_instance_id
		   AND anpn.region_sid = mr.old_sid
		   AND anpn.added_by_sid = cu.old_sid;
	-- TODO:
	-- csr.aggregate_ind_val_detail
	-- csr.approval_dashboard_val_src (problem with ID not constrained column)
END;

PROCEDURE CreateTemplatedReports
AS
BEGIN
	INSERT INTO csr.tpl_img (key, path, image, filename, mime_type)
		SELECT key, path, image, filename, mime_type
		  FROM csrimp.tpl_img;

	-- XXX: id seems manually assigned?
	INSERT INTO csr.tpl_rep_cust_tag_type (tpl_rep_cust_tag_type_id, cs_class,
		js_include, js_class, helper_pkg, description)
		SELECT tpl_rep_cust_tag_type_id, cs_class, js_include, js_class,
			   helper_pkg, description
		  FROM csrimp.tpl_rep_cust_tag_type;

	INSERT INTO csr.tpl_report (tpl_report_sid, parent_sid, name, description, word_doc, filename,
		thumb_img, period_set_id, period_interval_id)
		SELECT mtr.new_sid, mtrp.new_sid, tr.name, tr.description, tr.word_doc, tr.filename,
			   tr.thumb_img, tr.period_set_id, tr.period_interval_id
		  FROM csrimp.tpl_report tr, csrimp.map_sid mtr, csrimp.map_sid mtrp
		 WHERE tr.tpl_report_sid = mtr.old_sid
		   AND tr.parent_sid = mtrp.old_sid;

	INSERT INTO csr.tpl_report_tag_dataview (tpl_report_tag_dataview_id, dataview_sid,
		month_offset, month_duration, hide_if_empty, split_table_by_columns,
		saved_filter_sid, filter_result_mode, aggregate_type_id, approval_dashboard_sid, ind_tag, period_set_id, period_interval_id)
		SELECT mtdv.new_tpl_report_tag_dv_id, mdv.new_sid,
			trt.month_offset, trt.month_duration, trt.hide_if_empty, trt.split_table_by_columns,
			msfs.new_sid, trt.filter_result_mode, trt.aggregate_type_id, ad.new_sid, mt.new_tag_id, trt.period_set_id, trt.period_interval_id
		  FROM csrimp.tpl_report_tag_dataview trt, csrimp.map_tpl_report_tag_dv mtdv,
		  	   csrimp.map_sid mdv, csrimp.map_sid msfs, csrimp.map_sid ad, csrimp.map_tag mt
		 WHERE trt.tpl_report_tag_dataview_id = mtdv.old_tpl_report_tag_dv_id
		   AND trt.dataview_sid = mdv.old_sid
		   AND trt.saved_filter_sid = msfs.old_sid(+)
		   AND trt.approval_dashboard_sid = ad.old_sid(+)
		   AND trt.ind_tag = mt.old_tag_id(+);

	INSERT INTO csr.tpl_report_tag_dv_region (tpl_report_tag_dataview_id, dataview_sid, region_sid,
		tpl_region_type_id)
		SELECT mtdv.new_tpl_report_tag_dv_id, mdv.new_sid, mr.new_sid, rtdv.tpl_region_type_id
		  FROM csrimp.tpl_report_tag_dv_region rtdv, csrimp.map_tpl_report_tag_dv mtdv,
		  	   csrimp.map_sid mdv, csrimp.map_sid mr
		 WHERE rtdv.tpl_report_tag_dataview_id = mtdv.old_tpl_report_tag_dv_id
		   AND rtdv.dataview_sid = mdv.old_sid
		   AND rtdv.region_sid = mr.old_sid;

	INSERT INTO csr.tpl_report_tag_eval (tpl_report_tag_eval_id, if_true, if_false,
		all_must_be_true, month_offset, period_set_id, period_interval_id)
		SELECT mtrt.new_tpl_report_tag_eval_id, trt.if_true, trt.if_false,
			   trt.all_must_be_true, trt.month_offset, trt.period_set_id, trt.period_interval_id
		  FROM csrimp.tpl_report_tag_eval trt, csrimp.map_tpl_report_tag_eval mtrt
		 WHERE trt.tpl_report_tag_eval_id = mtrt.old_tpl_report_tag_eval_id;

	INSERT INTO csr.tpl_report_tag_eval_cond (tpl_report_tag_eval_id, left_ind_sid,
		operator, right_value, right_ind_sid)
		SELECT mtrt.new_tpl_report_tag_eval_id, mli.new_sid, trt.operator, trt.right_value,
			   mri.new_sid
		  FROM csrimp.tpl_report_tag_eval_cond trt, csrimp.map_tpl_report_tag_eval mtrt,
		  	   csrimp.map_sid mli, csrimp.map_sid mri
		 WHERE trt.tpl_report_tag_eval_id = mtrt.old_tpl_report_tag_eval_id
		   AND trt.left_ind_sid = mli.old_sid
		   AND trt.right_ind_sid = mri.old_sid(+);

	INSERT INTO csr.tpl_report_tag_ind (tpl_report_tag_ind_id, ind_sid, month_offset,
        measure_conversion_id, format_mask, period_set_id, period_interval_id, show_full_path)
		SELECT mtrt.new_tpl_report_tag_ind_id, mi.new_sid, trt.month_offset,
               mmc.new_measure_conversion_id, trt.format_mask, trt.period_set_id, trt.period_interval_id, trt.show_full_path
		  FROM csrimp.tpl_report_tag_ind trt, csrimp.map_tpl_report_tag_ind mtrt,
		  	   csrimp.map_sid mi, csrimp.map_measure_conversion mmc
		 WHERE trt.tpl_report_tag_ind_id = mtrt.old_tpl_report_tag_ind_id
		   AND trt.measure_conversion_id = mmc.old_measure_conversion_id(+)
		   AND trt.ind_sid = mi.old_sid;

	INSERT INTO csr.tpl_report_tag_logging_form (tpl_report_tag_logging_form_id, tab_sid,
		month_offset, month_duration, region_column_name, tpl_region_type_id, date_column_name,
		form_sid, filter_sid, saved_filter_sid)
		SELECT mtrt.new_tpl_report_tag_log_frm_id, mt.new_sid, trt.month_offset,
			   trt.month_duration, trt.region_column_name, trt.tpl_region_type_id,
			   trt.date_column_name, mfrm.new_sid, mfil.new_sid, msf.new_sid
		  FROM csrimp.tpl_report_tag_logging_form trt, csrimp.map_tpl_report_tag_log_frm mtrt,
		  	   csrimp.map_sid mt, csrimp.map_sid mfrm, csrimp.map_sid mfil, csrimp.map_sid msf
		 WHERE trt.tpl_report_tag_logging_form_id = mtrt.old_tpl_report_tag_log_frm_id
		   AND trt.tab_sid = mt.old_sid
		   AND trt.form_sid = mfrm.old_sid(+)
		   AND trt.filter_sid = mfil.old_sid(+)
		   AND trt.saved_filter_sid = msf.old_sid(+);

	INSERT INTO csr.tpl_report_tag_qchart (tpl_report_tag_qchart_id,
		month_offset, month_duration, hide_if_empty, split_table_by_columns,
		saved_filter_sid, period_set_id, period_interval_id)
		SELECT mtqc.new_tpl_report_tag_qc_id, trt.month_offset, trt.month_duration,
		    trt.hide_if_empty, trt.split_table_by_columns,
			msfs.new_sid, trt.period_set_id, trt.period_interval_id
		  FROM csrimp.tpl_report_tag_qchart trt
		  JOIN csrimp.map_tpl_report_tag_qc mtqc ON trt.tpl_report_tag_qchart_id = mtqc.old_tpl_report_tag_qc_id
		  JOIN csrimp.map_sid msfs ON trt.saved_filter_sid = msfs.old_sid;

	INSERT INTO csr.tpl_report_non_compl (tpl_report_non_compl_id, month_offset,
		month_duration, tpl_region_type_id, tag_id)
		SELECT mtrt.new_tpl_report_non_compl_id, trt.month_offset,
			   trt.month_duration, trt.tpl_region_type_id, mt.new_tag_id
		  FROM csrimp.tpl_report_non_compl trt
		  JOIN csrimp.map_tpl_report_non_compl mtrt ON trt.tpl_report_non_compl_id = mtrt.old_tpl_report_non_compl_id
		  LEFT JOIN csrimp.map_tag mt ON trt.tag_id = mt.old_tag_id;

	INSERT INTO csr.tpl_report_tag_text (tpl_report_tag_text_id, label)
		SELECT mtrt.new_tpl_report_tag_text_id, trt.label
		  FROM csrimp.tpl_report_tag_text trt, csrimp.map_tpl_report_tag_text mtrt
		 WHERE trt.tpl_report_tag_text_id = mtrt.old_tpl_report_tag_text_id;

	INSERT INTO csr.tpl_report_tag_reg_data (tpl_report_tag_reg_data_id, tpl_report_reg_data_type_id)
		SELECT mtrtrd.new_tpl_report_tag_reg_data_id, trt.tpl_report_reg_data_type_id
		  FROM csrimp.tpl_report_tag_reg_data trt, csrimp.map_tpl_report_tag_reg_data mtrtrd
		 WHERE trt.tpl_report_tag_reg_data_id = mtrtrd.old_tpl_report_tag_reg_data_id;

	INSERT INTO csr.tpl_report_tag (tpl_report_sid, tag, tag_type, tpl_report_tag_ind_id,
		tpl_report_tag_eval_id, tpl_report_tag_dataview_id, tpl_report_tag_logging_form_id,
		tpl_rep_cust_tag_type_id, tpl_report_tag_text_id, tpl_report_non_compl_id,
		tpl_report_tag_app_note_id, tpl_report_tag_app_matrix_id, tpl_report_tag_reg_data_id,
		tpl_report_tag_qc_id)

		SELECT mtrt.new_sid, trt.tag, trt.tag_type, mti.new_tpl_report_tag_ind_id,
			   mte.new_tpl_report_tag_eval_id, mdv.new_tpl_report_tag_dv_id,
			   mlf.new_tpl_report_tag_log_frm_id, trt.tpl_rep_cust_tag_type_id,
			   mtx.new_tpl_report_tag_text_id, mnc.new_tpl_report_non_compl_id,
			   mtrtan.new_tpl_rep_tag_appr_note_id, mtrtam.new_tpl_rep_tag_appr_matr_id,
			   mtrtrd.new_tpl_report_tag_reg_data_id, mtrtqc.new_tpl_report_tag_qc_id

		  FROM csrimp.tpl_report_tag trt, csrimp.map_sid mtrt, csrimp.map_tpl_report_tag_ind mti,
			   csrimp.map_tpl_report_tag_eval mte, csrimp.map_tpl_report_tag_dv mdv,
			   csrimp.map_tpl_report_tag_log_frm mlf, csrimp.map_tpl_report_tag_text mtx,
			   csrimp.map_tpl_report_non_compl mnc,
			   csrimp.map_tpl_rep_tag_appr_note mtrtan,
			   csrimp.map_tpl_report_tag_appr_matr mtrtam,
			   csrimp.map_tpl_report_tag_reg_data mtrtrd,
			   csrimp.map_tpl_report_tag_qc mtrtqc
		 WHERE trt.tpl_report_sid = mtrt.old_sid
		   AND trt.tpl_report_tag_ind_id = mti.old_tpl_report_tag_ind_id(+)
		   AND trt.tpl_report_tag_eval_id = mte.old_tpl_report_tag_eval_id(+)
		   AND trt.tpl_report_tag_dataview_id = mdv.old_tpl_report_tag_dv_id(+)
		   AND ( trt.tpl_report_tag_dataview_id IS NULL
			  OR mdv.old_tpl_report_tag_dv_id IS NOT NULL )
		   AND trt.tpl_report_tag_logging_form_id = mlf.old_tpl_report_tag_log_frm_id(+)
		   AND trt.tpl_report_tag_text_id = mtx.old_tpl_report_tag_text_id(+)
		   AND trt.tpl_report_non_compl_id = mnc.old_tpl_report_non_compl_id(+)
		   AND trt.tpl_report_tag_app_note_id = mtrtan.old_tpl_rep_tag_appr_note_id(+)
		   AND trt.tpl_report_tag_app_matrix_id = mtrtam.old_tpl_rep_tag_appr_matr_id(+)
		   AND trt.tpl_report_tag_reg_data_id = mtrtrd.old_tpl_report_tag_reg_data_id(+)
		   AND trt.tpl_report_tag_qc_id = mtrtqc.old_tpl_report_tag_qc_id(+);
		   
		INSERT INTO csr.tpl_report_variant (master_template_sid, language_code, word_doc, filename, mime_type)
		SELECT ms.new_sid, trv.language_code, trv.word_doc, trv.filename, trv.mime_type
		  FROM csrimp.tpl_report_variant trv, csrimp.map_sid ms
		 WHERE trv.master_template_sid = ms.old_sid;
		 
		INSERT INTO csr.tpl_report_variant_tag (tpl_report_sid, language_code, tag)
		SELECT ms.new_sid, trvt.language_code, trvt.tag
		  FROM csrimp.tpl_report_variant_tag trvt, csrimp.map_sid ms
		 WHERE trvt.tpl_report_sid = ms.old_sid;

END;

PROCEDURE CreateDashboards
AS
BEGIN
	INSERT INTO csr.dashboard (dashboard_sid, name, note)
		SELECT md.new_sid, d.name, d.note
		  FROM csrimp.dashboard d, csrimp.map_sid md
		 WHERE d.dashboard_sid = md.old_sid;

	INSERT INTO csr.dashboard_item (dashboard_item_id, dashboard_sid, parent_sid, period,
		comparison_type, ind_sid, region_sid, name, pos, dataview_sid)
		SELECT mdi.new_dashboard_item_id, md.new_sid, mp.new_sid, di.period, di.comparison_type,
			   mi.new_sid, mr.new_sid, di.name, di.pos, mdv.new_sid
		  FROM dashboard_item di, csrimp.map_dashboard_item mdi, csrimp.map_sid md,
		  	   csrimp.map_sid mp, csrimp.map_sid mi, csrimp.map_sid mr,
		  	   csrimp.map_sid mdv
		 WHERE di.dashboard_item_id = mdi.old_dashboard_item_id
		   AND di.dashboard_sid = md.old_sid
		   AND di.parent_sid = mp.old_sid
		   AND di.ind_sid = mi.old_sid
		   AND di.region_sid = mr.old_sid
		   AND di.dataview_sid = mdv.old_sid;
END;

PROCEDURE CreateModels
AS
BEGIN
	INSERT INTO csr.model (model_sid, revision, name, description, excel_doc,
		file_name, thumb_img, created_dtm, temp_only_boo, load_state,
		scenario_run_type, scenario_run_sid, lookup_key)
		SELECT /*+CARDINALITY(m, 1000) CARDINALITY(ms, 50000) CARDINALITY(msr, 50000)*/
			   ms.new_sid, m.revision, m.name, m.description, m.excel_doc,
			   m.file_name, m.thumb_img, m.created_dtm, m.temp_only_boo,
			   m.load_state, m.scenario_run_type, NVL(msr.new_sid, m.scenario_run_sid), lookup_key
		  FROM csrimp.model m, csrimp.map_sid ms, csrimp.map_sid msr
		 WHERE m.model_sid = ms.old_sid
		   AND m.scenario_run_sid = msr.old_sid(+);

	INSERT INTO csr.model_sheet (model_sid, sheet_name, user_editable_boo,
		sheet_index, display_charts_boo, chart_count, sheet_id, structure)
		SELECT /*+CARDINALITY(ms, 1000) CARDINALITY(mms, 1000)*/
			   msid.new_sid, ms.sheet_name, ms.user_editable_boo, ms.sheet_index,
			   ms.display_charts_boo, ms.chart_count, mms.new_sheet_id, ms.structure
		  FROM csrimp.model_sheet ms, csrimp.map_sid msid,
		  	   csrimp.map_model_sheet mms
		 WHERE ms.model_sid = msid.old_sid
		   AND ms.sheet_id = mms.old_sheet_id;

	INSERT INTO csr.model_instance (model_instance_sid, base_model_sid, start_dtm,
		end_dtm, owner_sid, created_dtm, excel_doc, description, run_state)
		SELECT /*+CARDINALITY(mi, 1000)*/
			   mis.new_sid, mib.new_sid, mi.start_dtm, mi.end_dtm, mio.new_sid,
			   mi.created_dtm, mi.excel_doc, mi.description, mi.run_state
		  FROM csrimp.model_instance mi, csrimp.map_sid mis, csrimp.map_sid mib,
		  	   csrimp.map_sid mio
		 WHERE mi.model_instance_sid = mis.old_sid
		   AND mi.base_model_sid = mib.old_sid
		   AND mi.owner_sid = mio.old_sid;

	INSERT INTO csr.model_map (model_sid, sheet_id, cell_name, model_map_type_id,
		map_to_indicator_sid, cell_comment, is_temp, region_type_offset, region_offset_tag_id,
		period_year_offset, period_offset)
		SELECT /*+CARDINALITY(mm, 1000) CARDINALITY(mms, 1000)*/
			   ms.new_sid, mms.new_sheet_id, mm.cell_name, mm.model_map_type_id, mi.new_sid,
			   mm.cell_comment, mm.is_temp, mm.region_type_offset,
			   mt.new_tag_id, mm.period_year_offset, mm.period_offset
		  FROM csrimp.model_map mm, csrimp.map_sid ms,
		  	   csrimp.map_sid mi, csrimp.map_tag mt, csrimp.map_model_sheet mms
		 WHERE mm.model_sid = ms.old_sid
		   AND mm.map_to_indicator_sid = mi.old_sid(+)
		   AND mm.region_offset_tag_id = mt.old_tag_id(+)
		   AND mm.sheet_id = mms.old_sheet_id;

	INSERT INTO csr.model_instance_map (model_instance_sid, base_model_sid,
		sheet_id, cell_name, source_cell_name, cell_value, map_to_indicator_sid,
		map_to_region_sid, period_year_offset, period_offset)
		SELECT /*+CARDINALITY(mis, 1000) CARDINALITY(mms, 1000) CARDINALITY(mim, 1000)*/
			   mis.new_sid, mib.new_sid, mms.new_sheet_id, mim.cell_name,
			   mim.source_cell_name, mim.cell_value, mti.new_sid,
			   mtr.new_sid, mim.period_year_offset, mim.period_offset
		  FROM csrimp.model_instance_map mim, csrimp.map_sid mis,
		  	   csrimp.map_sid mib, csrimp.map_sid mti,
		  	   csrimp.map_sid mtr, csrimp.map_model_sheet mms
		 WHERE mim.model_instance_sid = mis.old_sid
		   AND mim.base_model_sid = mib.old_sid
		   AND mim.map_to_indicator_sid = mti.old_sid(+)
		   AND mim.map_to_region_sid = mtr.old_sid(+)
		   AND mim.sheet_id = mms.old_sheet_id;

	INSERT INTO csr.model_instance_region (model_instance_sid, base_model_sid,
		region_sid, pos)
		SELECT /*+CARDINALITY(mir, 1000)*/
			   mis.new_sid, mib.new_sid, mr.new_sid, mir.pos
		  FROM csrimp.model_instance_region mir, csrimp.map_sid mis,
		  	   csrimp.map_sid mib, csrimp.map_sid mr
		 WHERE mir.model_instance_sid = mis.old_sid
		   AND mir.base_model_sid = mib.old_sid
		   AND mir.region_sid = mr.old_sid;

	INSERT INTO csr.model_instance_sheet (model_instance_sid, base_model_sid,
		sheet_id, structure)
		SELECT /*+CARDINALITY(mi, 1000) CARDINALITY(mms, 1000)*/
			   mis.new_sid, mib.new_sid, mms.new_sheet_id, mi.structure
		  FROM csrimp.model_instance_sheet mi, csrimp.map_sid mis,
		  	   csrimp.map_sid mib, csrimp.map_model_sheet mms
		 WHERE mi.model_instance_sid = mis.old_sid
		   AND mi.base_model_sid = mib.old_sid
		   AND mi.sheet_id = mms.old_sheet_id;

	INSERT INTO csr.model_instance_chart (model_instance_sid, base_model_sid,
		sheet_id, chart_index, top, left, width, height, source_data)
		SELECT /*+CARDINALITY(mic, 1000) CARDINALITY(mms, 1000)*/
			   mis.new_sid, mib.new_sid, mms.new_sheet_id, mic.chart_index,
			   mic.top, mic.left, mic.width, mic.height, mic.source_data
		  FROM csrimp.model_instance_chart mic, csrimp.map_sid mis,
			   csrimp.map_sid mib, csrimp.map_model_sheet mms
		 WHERE mic.model_instance_sid = mis.old_sid
		   AND mic.base_model_sid = mib.old_sid
		   AND mic.sheet_id = mms.old_sheet_id;

	INSERT INTO csr.model_range (model_sid, range_id, sheet_id)
		SELECT /*+CARDINALITY(mr, 1000) CARDINALITY(mmr, 1000) CARDINALITY(mms, 1000)*/
			   ms.new_sid, mmr.new_range_id, mms.new_sheet_id
		  FROM csrimp.model_range mr, csrimp.map_model_range mmr,
		  	   csrimp.map_sid ms, csrimp.map_model_sheet mms
		 WHERE mr.model_sid = ms.old_sid
		   AND mr.range_id = mmr.old_range_id
		   AND mr.sheet_id = mms.old_sheet_id;

	INSERT INTO csr.model_range_cell (model_sid, range_id, cell_name)
		SELECT /*+CARDINALITY(mrc, 1000) CARDINALITY(mmr, 1000)*/
			   ms.new_sid, mmr.new_range_id, mrc.cell_name
		  FROM csrimp.model_range_cell mrc, csrimp.map_sid ms,
		  	   csrimp.map_model_range mmr
		 WHERE mrc.model_sid = ms.old_sid
		   AND mrc.range_id = mmr.old_range_id;

	INSERT INTO csr.model_region_range (model_sid, range_id, region_repeat_id)
		SELECT /*+CARDINALITY(mrr, 1000) CARDINALITY(mmr, 1000)*/
			   ms.new_sid, mmr.new_range_id, region_repeat_id
		  FROM csrimp.model_region_range mrr, csrimp.map_sid ms,
		  	   csrimp.map_model_range mmr
		 WHERE mrr.model_sid = ms.old_sid
		   AND mrr.range_id = mmr.old_range_id;

	INSERT INTO csr.model_validation (model_sid, cell_name, display_seq,
		validation_text, sheet_id)
		SELECT /*+CARDINALITY(mv, 1000) CARDINALITY(mms, 1000)*/
			   ms.new_sid, mv.cell_name, mv.display_seq, mv.validation_text,
			   mms.new_sheet_id
		  FROM csrimp.model_validation mv, csrimp.map_sid ms,
		  	   csrimp.map_model_sheet mms
		 WHERE mv.model_sid = ms.old_sid
		   AND mv.sheet_id = mms.old_sheet_id;
END;

PROCEDURE CreatePostIts
AS
BEGIN
	-- Sometimes postits are secured by a sid that no longer exists.  This is because
	-- they don't have any RI on the secured_via_sid column.
	INSERT INTO csr.postit (postit_id, label, message, created_dtm,
		created_by_sid, secured_via_sid)
		SELECT mp.new_postit_id, p.label, p.message, p.created_dtm,
			   mcby.new_sid, NVL(msby.new_sid, 3) -- builtin/admin
		  FROM csrimp.postit p, csrimp.map_postit mp, csrimp.map_sid mcby,
		  	   csrimp.map_sid msby
		 WHERE p.postit_id = mp.old_postit_id
		   AND p.created_by_sid = mcby.old_sid
		   AND p.secured_via_sid = msby.old_sid(+);

	INSERT INTO csr.postit_file (postit_file_id, postit_id, filename,
		mime_type, data, sha1, uploaded_dtm)
		SELECT csr.postit_file_id_seq.nextval, mp.new_postit_id, pf.filename,
			   pf.mime_type, pf.data, pf.sha1, pf.uploaded_dtm
		  FROM csrimp.postit_file pf, csrimp.map_postit mp
		 WHERE pf.postit_id = mp.old_postit_id;
END;

PROCEDURE CreateAudits
AS
BEGIN
	INSERT INTO csr.internal_audit_type_group (internal_audit_type_group_id,
				label, lookup_key, internal_audit_ref_prefix,
				applies_to_regions, applies_to_users, use_user_primary_region,
				audit_singular_label, audit_plural_label,
				auditee_user_label, auditor_user_label, auditor_name_label,
				audits_menu_sid, new_audit_menu_sid, non_compliances_menu_sid,
				block_css_class, applies_to_permits)
		SELECT miatg.new_inter_audit_type_group_id,
			   iatg.label, iatg.lookup_key, iatg.internal_audit_ref_prefix,
			   iatg.applies_to_regions, iatg.applies_to_users, iatg.use_user_primary_region,
			   iatg.audit_singular_label, iatg.audit_plural_label,
			   iatg.auditee_user_label, iatg.auditor_user_label, iatg.auditor_name_label,
			   mams.new_sid, mnams.new_sid, mncms.new_sid,
			   iatg.block_css_class, iatg.applies_to_permits
		  FROM csrimp.internal_audit_type_group iatg
		  JOIN csrimp.map_internal_audit_type_group miatg ON iatg.internal_audit_type_group_id = miatg.old_inter_audit_type_group_id
		  LEFT JOIN csrimp.map_sid mams ON mams.old_sid = iatg.audits_menu_sid
		  LEFT JOIN csrimp.map_sid mnams ON mnams.old_sid = iatg.new_audit_menu_sid
		  LEFT JOIN csrimp.map_sid mncms ON mncms.old_sid = iatg.non_compliances_menu_sid;

	INSERT INTO csr.internal_audit_type (
				internal_audit_type_id,
				label,
				every_n_months,
				auditor_role_sid,
				audit_contact_role_sid,
				default_survey_sid,
				lookup_key,
				default_auditor_org,
				override_issue_dtm,
				assign_issues_to_role,
				auditor_can_take_ownership,
				flow_sid,
				internal_audit_type_source_id,
				summary_survey_sid,
				send_auditor_expiry_alerts,
				validity_months,
				tab_sid,
				form_path,
				form_sid,
				internal_audit_ref_helper_func,
				nc_audit_child_region,
				internal_audit_type_group_id,
				nc_score_type_id,
				show_primary_survey_in_header,
				primary_survey_active,
				primary_survey_label,
				primary_survey_mandatory,
				primary_survey_fixed,
				primary_survey_group_key,
				add_nc_per_question,
				audit_coord_role_or_group_sid,
				use_legacy_closed_definition,
				involve_auditor_in_issues
	   ) SELECT miat.new_internal_audit_type_id,
				iat.label,
				iat.every_n_months,
				mars.new_sid,
				macrs.new_sid,
				mdss.new_sid,
				iat.lookup_key,
				iat.default_auditor_org,
				iat.override_issue_dtm,
				iat.assign_issues_to_role,
				iat.auditor_can_take_ownership,
				mfs.new_sid,
				iat.internal_audit_type_source_id, mss.new_sid,
				send_auditor_expiry_alerts,
				iat.validity_months,
				mts.new_sid,
				iat.form_path,
				mf.new_sid,
				iat.internal_audit_ref_helper_func,
				nc_audit_child_region,
				miatg.new_inter_audit_type_group_id,
				mst.new_score_type_id,
				iat.show_primary_survey_in_header,
				iat.primary_survey_active,
				iat.primary_survey_label,
				iat.primary_survey_mandatory,
				iat.primary_survey_fixed,
				iat.primary_survey_group_key,
				iat.add_nc_per_question,
				macors.new_sid,
				iat.use_legacy_closed_definition,
				iat.involve_auditor_in_issues
		   FROM csrimp.internal_audit_type iat
		   JOIN csrimp.map_internal_audit_type miat ON iat.internal_audit_type_id = miat.old_internal_audit_type_id
	  LEFT JOIN	csrimp.map_sid mars ON iat.auditor_role_sid = mars.old_sid
	  LEFT JOIN csrimp.map_sid mdss ON iat.default_survey_sid = mdss.old_sid
	  LEFT JOIN csrimp.map_sid macrs ON iat.audit_contact_role_sid = macrs.old_sid
	  LEFT JOIN csrimp.map_sid mfs ON iat.flow_sid = mfs.old_sid
	  LEFT JOIN csrimp.map_sid mss ON iat.summary_survey_sid = mss.old_sid
	  LEFT JOIN csrimp.map_sid mts ON iat.tab_sid = mts.old_sid
	  LEFT JOIN csrimp.map_internal_audit_type_group miatg ON iat.internal_audit_type_group_id = miatg.old_inter_audit_type_group_id
	  LEFT JOIN csrimp.map_score_type mst ON iat.nc_score_type_id = mst.old_score_type_id
	  LEFT JOIN csrimp.map_sid macors ON iat.audit_coord_role_or_group_sid = macors.old_sid
	  LEFT JOIN csrimp.map_sid mf ON iat.form_sid = mf.old_sid;

	INSERT INTO csr.ia_type_report_group (
				ia_type_report_group_id,
				label
	   ) SELECT miatrg.new_ia_type_report_group_id,
				iatrg.label
		   FROM csrimp.ia_type_report_group iatrg
		   JOIN csrimp.map_ia_type_report_group miatrg ON iatrg.ia_type_report_group_id = miatrg.old_ia_type_report_group_id;

	INSERT INTO csr.internal_audit_type_report (
				internal_audit_type_report_id,
				internal_audit_type_id,
				report_filename,
				word_doc,
				label,
				ia_type_report_group_id,
				use_merge_field_guid,
				guid_expiration_days
	   ) SELECT miatr.new_internal_audit_type_rep_id,
		 		miat.new_internal_audit_type_id,
		 		iatr.report_filename,
		 		iatr.word_doc,
		 		iatr.label,
		 		miatrg.new_ia_type_report_group_id,
				iatr.use_merge_field_guid,
				iatr.guid_expiration_days
		   FROM csrimp.internal_audit_type_report iatr
		   JOIN csrimp.map_internal_audit_type_report miatr ON iatr.internal_audit_type_report_id = miatr.old_internal_audit_type_rep_id
		   JOIN csrimp.map_internal_audit_type miat ON iatr.internal_audit_type_id = miat.old_internal_audit_type_id
		   LEFT JOIN csrimp.map_ia_type_report_group miatrg ON iatr.ia_type_report_group_id = miatrg.old_ia_type_report_group_id;

	INSERT INTO csr.internal_audit_type_carry_fwd (from_internal_audit_type_id, to_internal_audit_type_id)
		 SELECT mfiat.new_internal_audit_type_id, mtiat.new_internal_audit_type_id
		   FROM csrimp.internal_audit_type_carry_fwd iatcf,
				csrimp.map_internal_audit_type mfiat,
				csrimp.map_internal_audit_type mtiat
		  WHERE iatcf.from_internal_audit_type_id = mfiat.old_internal_audit_type_id
		    AND iatcf.to_internal_audit_type_id = mtiat.old_internal_audit_type_id;

	INSERT INTO csr.internal_audit_type_tag_group(internal_audit_type_id, tag_group_id)
	SELECT miat.new_internal_audit_type_id, mtg.new_tag_group_id
	  FROM csrimp.internal_audit_type_tag_group iattg
	  JOIN csrimp.map_internal_audit_type miat ON miat.old_internal_audit_type_id = iattg.internal_audit_type_id
	  JOIN csrimp.map_tag_group mtg ON mtg.old_tag_group_id = iattg.tag_group_id;

	UPDATE csr.quick_survey qs
	   SET auditing_audit_type_id = (
		SELECT miat.new_internal_audit_type_id
		  FROM csrimp.quick_survey oqs
		  JOIN csrimp.map_sid mqs ON oqs.survey_sid = mqs.old_sid
	 LEFT JOIN csrimp.map_internal_audit_type miat ON miat.old_internal_audit_type_id = oqs.auditing_audit_type_id
		 WHERE qs.survey_sid = mqs.new_sid
	);

	INSERT INTO csr.flow_state_audit_ind (ind_sid, flow_state_id, flow_state_audit_ind_type_id, internal_audit_type_id)
		SELECT i.new_sid, mfs.new_flow_state_id, fsai.flow_state_audit_ind_type_id, miat.new_internal_audit_type_id
		  FROM csrimp.flow_state_audit_ind fsai
		  JOIN csrimp.map_sid i ON fsai.ind_sid = i.old_sid
		  JOIN csrimp.map_flow_state mfs ON fsai.flow_state_id = mfs.old_flow_state_id
		  JOIN csrimp.map_internal_audit_type miat ON miat.old_internal_audit_type_id = fsai.internal_audit_type_id;

	INSERT INTO csr.audit_closure_type (audit_closure_type_id, label, icon_image,
		   icon_image_filename, icon_image_mime_type, icon_image_sha1, is_failure, lookup_key)
		SELECT mact.new_audit_closure_type_id, act.label, act.icon_image,
			   act.icon_image_filename, act.icon_image_mime_type, act.icon_image_sha1,
			   act.is_failure, act.lookup_key
		  FROM csrimp.audit_closure_type act
		  JOIN csrimp.map_audit_closure_type mact ON act.audit_closure_type_id = mact.old_audit_closure_type_id;

	INSERT INTO csr.audit_type_closure_type (internal_audit_type_id, audit_closure_type_id,
		   re_audit_due_after, re_audit_due_after_type, reminder_offset_days, reportable_for_months,
		   ind_sid, manual_expiry_date)
		SELECT miat.new_internal_audit_type_id, mact.new_audit_closure_type_id,
			   act.re_audit_due_after, act.re_audit_due_after_type, act.reminder_offset_days, act.reportable_for_months,
			   ms.new_sid, manual_expiry_date
		  FROM csrimp.audit_type_closure_type act
		  JOIN csrimp.map_audit_closure_type mact ON act.audit_closure_type_id = mact.old_audit_closure_type_id
		  JOIN csrimp.map_internal_audit_type miat ON act.internal_audit_type_id = miat.old_internal_audit_type_id
		  LEFT JOIN csrimp.map_sid ms ON act.ind_sid = ms.old_sid;

	INSERT INTO csr.audit_type_expiry_alert_role (internal_audit_type_id, role_sid)
		SELECT miat.new_internal_audit_type_id, mrs.new_sid
		  FROM csrimp.audit_type_expiry_alert_role atrar
		  JOIN csrimp.map_internal_audit_type miat ON atrar.internal_audit_type_id = miat.old_internal_audit_type_id
		  JOIN csrimp.map_sid mrs ON atrar.role_sid = mrs.old_sid;

	INSERT INTO csr.internal_audit (internal_audit_sid, internal_audit_type_id, survey_sid,
		region_sid, auditee_user_sid, label, audit_dtm, created_by_user_sid, created_dtm, auditor_user_sid,
		notes, audit_contact_user_sid, survey_response_id, auditor_name, deleted,
		auditor_organisation, audit_closure_type_id, flow_item_id, summary_response_id,
		expired, internal_audit_ref, nc_score,
		comparison_response_id, ovw_validity_dtm, nc_score_thrsh_id,
		ovw_nc_score_thrsh_id, ovw_nc_score_thrsh_dtm, ovw_nc_score_thrsh_usr_sid, permit_id,
		external_audit_ref, external_parent_ref, external_url)
		SELECT mau.new_sid, miat.new_internal_audit_type_id, ms.new_sid, mr.new_sid, mu.new_sid,
			   ia.label, ia.audit_dtm, mcby.new_sid, ia.created_dtm, mausr.new_sid,
			   ia.notes, macu.new_sid, mresp.new_survey_response_id, ia.auditor_name, ia.deleted,
			   ia.auditor_organisation, mact.new_audit_closure_type_id, mfi.new_flow_item_id,
			   msrp.new_survey_response_id, ia.expired, ia.internal_audit_ref, ia.nc_score,
			   mscrp.new_survey_response_id, ia.ovw_validity_dtm, mncst.new_score_threshold_id,
			   moncst.new_score_threshold_id, ia.ovw_nc_score_thrsh_dtm, moncu.new_sid, mcp.new_compliance_permit_id,
			   ia.external_audit_ref, ia.external_parent_ref, ia.external_url
	  	  FROM csrimp.internal_audit ia, csrimp.map_internal_audit_type miat,
	  	  	   csrimp.map_sid mau, csrimp.map_sid ms, csrimp.map_sid mr,
	  	  	   csrimp.map_sid mcby, csrimp.map_sid mausr, csrimp.map_sid mu,
	  	  	   csrimp.map_sid macu, csrimp.map_qs_survey_response mresp,
	  	  	   csrimp.map_audit_closure_type mact, csrimp.map_flow_item mfi,
			   csrimp.map_qs_survey_response msrp, csrimp.map_qs_survey_response mscrp,
			   csrimp.map_score_threshold mncst,
			   csrimp.map_score_threshold moncst,csrimp.map_sid moncu,
			   csrimp.map_compliance_permit mcp
	  	 WHERE ia.internal_audit_sid = mau.old_sid
	  	   AND ia.internal_audit_type_id = miat.old_internal_audit_type_id
	  	   AND ia.survey_sid = ms.old_sid(+)
	  	   AND ia.region_sid = mr.old_sid(+)
		   AND ia.auditee_user_sid = mu.old_sid(+)
		   AND ia.created_by_user_sid = mcby.old_sid
		   AND ia.auditor_user_sid = mausr.old_sid
		   AND ia.audit_contact_user_sid = macu.old_sid(+)
		   AND ia.survey_response_id = mresp.old_survey_response_id(+)
		   AND ia.audit_closure_type_id = mact.old_audit_closure_type_id(+)
		   AND ia.flow_item_id = mfi.old_flow_item_id(+)
		   AND ia.summary_response_id = msrp.old_survey_response_id(+)
		   AND ia.comparison_response_id = mscrp.old_survey_response_id(+)
		   AND ia.nc_score_thrsh_id = mncst.old_score_threshold_id(+)
		   AND ia.ovw_nc_score_thrsh_id = moncst.old_score_threshold_id(+)
		   AND ia.ovw_nc_score_thrsh_usr_sid = moncu.old_sid(+)
		   AND ia.permit_id = mcp.old_compliance_permit_id(+);

	INSERT INTO csr.internal_audit_tag(internal_audit_sid, tag_id)
	SELECT mau.new_sid, mt.new_tag_id
	  FROM csrimp.internal_audit_tag iat
	  JOIN csrimp.map_sid mau ON mau.old_sid = iat.internal_audit_sid
	  JOIN csrimp.map_tag mt ON mt.old_tag_id = iat.tag_id;

	INSERT INTO csr.audit_user_cover (user_cover_id, user_giving_cover_sid,
		user_being_covered_sid, internal_audit_sid)
		SELECT /*+ALL_ROWS CARDINALITY(auc, 1000) CARDINALITY(muc, 1000) CARDINALITY(mugc, 10000) CARDINALITY(mubc, 10000) CARDINALITY(mia, 10000)*/
			   muc.new_user_cover_id, mugc.new_sid, mubc.new_sid, mia.new_sid
		  FROM csrimp.audit_user_cover auc, csrimp.map_user_cover muc,
		       csrimp.map_sid mugc, csrimp.map_sid mubc, csrimp.map_sid mia
		 WHERE auc.user_cover_id = muc.old_user_cover_id
		   AND auc.user_giving_cover_sid = mugc.old_sid
		   AND auc.user_being_covered_sid = mubc.old_sid
		   AND auc.internal_audit_sid = mia.old_sid;

   INSERT INTO csr.internal_audit_file_data(internal_audit_file_data_id,
	           filename, mime_type, data, sha1, uploaded_dtm)
		SELECT miafd.new_int_audit_file_data_id, iafd.filename,
		       iafd.mime_type, iafd.data, iafd.sha1, iafd.uploaded_dtm
		  FROM csrimp.internal_audit_file_data iafd,
			   csrimp.map_internal_audit_file_data miafd
		 WHERE iafd.internal_audit_file_data_id = miafd.old_int_audit_file_data_id;

	INSERT INTO csr.internal_audit_file (internal_audit_sid, internal_audit_file_data_id)
		SELECT ma.new_sid, miafd.new_int_audit_file_data_id
		  FROM csrimp.internal_audit_file iaf, csrimp.map_sid ma,
			   csrimp.map_internal_audit_file_data miafd
		 WHERE iaf.internal_audit_sid = ma.old_sid
		   AND iaf.internal_audit_file_data_id = miafd.old_int_audit_file_data_id;

	INSERT INTO csr.internal_audit_postit (internal_audit_sid, postit_id)
		SELECT ma.new_sid, mp.new_postit_id
		  FROM csrimp.internal_audit_postit iap, csrimp.map_sid ma,
			   csrimp.map_postit mp
		 WHERE iap.internal_audit_sid = ma.old_sid
		   AND iap.postit_id = mp.old_postit_id;

	INSERT INTO csr.region_internal_audit (internal_audit_type_id, region_sid, next_audit_dtm)
		SELECT miat.new_internal_audit_type_id, mr.new_sid, ria.next_audit_dtm
		  FROM csrimp.region_internal_audit ria, csrimp.map_internal_audit_type miat,
		  	   csrimp.map_sid mr
		 WHERE ria.internal_audit_type_id = miat.old_internal_audit_type_id
		   AND ria.region_sid = mr.old_sid;

	INSERT INTO csr.non_comp_default_issue (non_comp_default_issue_id, non_comp_default_id, label, description,
											due_dtm_relative, due_dtm_relative_unit)
		SELECT mncdi.new_non_comp_default_issue_id, mncd.new_non_comp_default_id, ncdi.label, ncdi.description,
			   ncdi.due_dtm_relative, ncdi.due_dtm_relative_unit
		  FROM csrimp.non_comp_default_issue ncdi
		  JOIN csrimp.map_non_comp_default_issue mncdi ON ncdi.non_comp_default_issue_id = mncdi.old_non_comp_default_issue_id
		  JOIN csrimp.map_non_comp_default mncd ON ncdi.non_comp_default_id = mncd.old_non_comp_default_id;

	INSERT INTO csr.audit_type_non_comp_default (internal_audit_type_id, non_comp_default_id)
		SELECT miat.new_internal_audit_type_id, mncd.new_non_comp_default_id
		  FROM csrimp.audit_type_non_comp_default atncd
		  JOIN csrimp.map_internal_audit_type miat ON atncd.internal_audit_type_id = miat.old_internal_audit_type_id
		  JOIN csrimp.map_non_comp_default mncd ON atncd.non_comp_default_id = mncd.old_non_comp_default_id;

	INSERT INTO csr.non_comp_default_tag (non_comp_default_id, tag_id)
		SELECT mncd.new_non_comp_default_id, mt.new_tag_id
		  FROM csrimp.non_comp_default_tag ncdt
		  JOIN csrimp.map_non_comp_default mncd ON ncdt.non_comp_default_id = mncd.old_non_comp_default_id
		  JOIN csrimp.map_tag mt ON ncdt.tag_id = mt.old_tag_id;

	INSERT INTO csr.non_comp_type_audit_type (internal_audit_type_id, non_compliance_type_id)
		SELECT miat.new_internal_audit_type_id, mnct.new_non_compliance_type_id
		  FROM csrimp.non_comp_type_audit_type nctat
		  JOIN map_internal_audit_type miat ON nctat.internal_audit_type_id = miat.old_internal_audit_type_id
		  JOIN map_non_compliance_type mnct ON nctat.non_compliance_type_id = mnct.old_non_compliance_type_id;

	INSERT INTO csr.non_comp_type_rpt_audit_type (
				non_compliance_type_id,
				internal_audit_type_id
	   ) SELECT mnct.new_non_compliance_type_id,
				miat.new_internal_audit_type_id
		   FROM csrimp.non_comp_type_rpt_audit_type nctrat,
				csrimp.map_non_compliance_type mnct,
				csrimp.map_internal_audit_type miat
		  WHERE nctrat.non_compliance_type_id = mnct.old_non_compliance_type_id
			AND nctrat.internal_audit_type_id = miat.old_internal_audit_type_id;
	
	INSERT INTO csr.non_compliance_type_flow_cap (
				non_compliance_type_id,
				flow_capability_id,
				base_flow_capability_id
	   ) SELECT mnct.new_non_compliance_type_id,
				mcfc.new_customer_flow_cap_id,
				ntcfp.base_flow_capability_id
		   FROM csrimp.non_compliance_type_flow_cap ntcfp,
				csrimp.map_non_compliance_type mnct,
				csrimp.map_customer_flow_cap mcfc
		  WHERE ntcfp.non_compliance_type_id = mnct.old_non_compliance_type_id
			AND ntcfp.flow_capability_id = mcfc.old_customer_flow_cap_id;
	
	INSERT INTO csr.non_compliance (non_compliance_id, created_in_audit_sid, from_non_comp_default_id,
		label, detail, created_dtm, created_by_user_sid, non_compliance_type_id, is_closed,
		override_score, question_id, question_version, question_draft, question_option_id, non_compliance_ref, root_cause,
		region_sid)
		SELECT mnc.new_non_compliance_id, mias.new_sid, mncd.new_non_comp_default_id,
			   nc.label, nc.detail, nc.created_dtm, mcby.new_sid, mnct.new_non_compliance_type_id, nc.is_closed,
			   nc.override_score, mq.new_question_id, nc.question_version, nc.question_draft, mqo.new_question_option_id, nc.non_compliance_ref,
			   nc.root_cause, ms.new_sid
		  FROM csrimp.non_compliance nc, csrimp.map_non_compliance mnc,
		  	   csrimp.map_sid mias, csrimp.map_sid mcby, csrimp.map_non_comp_default mncd,
			   csrimp.map_non_compliance_type mnct, csrimp.map_qs_question mq, csrimp.map_qs_question_option mqo,
			   csrimp.map_sid ms
		 WHERE nc.non_compliance_id = mnc.old_non_compliance_id
		   AND nc.created_in_audit_sid = mias.old_sid
		   AND nc.created_by_user_sid = mcby.old_sid
		   AND nc.from_non_comp_default_id = mncd.old_non_comp_default_id(+)
		   AND nc.non_compliance_type_id = mnct.old_non_compliance_type_id(+)
		   AND nc.question_id = mq.old_question_id(+)
		   AND nc.question_option_id = mqo.old_question_option_id(+)
		   AND nc.region_sid = ms.old_sid(+);

	INSERT INTO csr.non_compliance_file (non_compliance_file_id, non_compliance_id, filename, mime_type, data, sha1, uploaded_dtm)
		SELECT mncf.new_non_compliance_file_id, mnc.new_non_compliance_id, filename, ncf.mime_type, ncf.data, ncf.sha1, uploaded_dtm
		  FROM csrimp.non_compliance_file ncf, csrimp.map_non_compliance_file mncf, csrimp.map_non_compliance mnc
		 WHERE ncf.non_compliance_file_id = mncf.old_non_compliance_file_id
		   AND ncf.non_compliance_id = mnc.old_non_compliance_id;

	INSERT INTO csr.non_compliance_tag (tag_id, non_compliance_id)
		SELECT mt.new_tag_id, mnc.new_non_compliance_id
		  FROM csrimp.non_compliance_tag nct, csrimp.map_tag mt,
		  	   csrimp.map_non_compliance mnc
		 WHERE nct.tag_id = mt.old_tag_id
		   AND nct.non_compliance_id = mnc.old_non_compliance_id;

	INSERT INTO csr.audit_non_compliance (audit_non_compliance_id, internal_audit_sid, non_compliance_id, repeat_of_audit_nc_id,
		attached_to_primary_survey, internal_audit_type_survey_id)
		SELECT manc.new_audit_non_compliance_id, mias.new_sid, mnc.new_non_compliance_id, mranc.new_audit_non_compliance_id,
			   anc.attached_to_primary_survey, miats.new_ia_type_survey_id
		  FROM csrimp.audit_non_compliance anc
		  JOIN csrimp.map_audit_non_compliance manc ON anc.audit_non_compliance_id = manc.old_audit_non_compliance_id
		  JOIN csrimp.map_non_compliance mnc ON anc.non_compliance_id = mnc.old_non_compliance_id
		  JOIN csrimp.map_sid mias ON anc.internal_audit_sid = mias.old_sid
	 LEFT JOIN csrimp.map_audit_non_compliance mranc ON anc.repeat_of_audit_nc_id = mranc.old_audit_non_compliance_id
	 LEFT JOIN csrimp.map_ia_type_survey miats ON anc.internal_audit_type_survey_id = miats.old_ia_type_survey_id;

	INSERT INTO csr.audit_alert (internal_audit_sid, csr_user_sid, reminder_sent_dtm, overdue_sent_dtm)
		SELECT mias.new_sid, mus.new_sid, aa.reminder_sent_dtm, aa.overdue_sent_dtm
		  FROM csrimp.audit_alert aa
		  JOIN csrimp.map_sid mias ON aa.internal_audit_sid = mias.old_sid
		  JOIN csrimp.map_sid mus ON aa.csr_user_sid = mus.old_sid;

	INSERT INTO csr.audit_type_tab (internal_audit_type_id, plugin_type_id, plugin_id, pos, tab_label, flow_capability_id)
		SELECT miat.new_internal_audit_type_id, att.plugin_type_id, mp.new_plugin_id, att.pos, att.tab_label,
			   mcfc.new_customer_flow_cap_id
		  FROM csrimp.audit_type_tab att
		  JOIN csrimp.map_internal_audit_type miat ON att.internal_audit_type_id = miat.old_internal_audit_type_id
		  JOIN csrimp.map_plugin mp ON att.plugin_id = mp.old_plugin_id
	 LEFT JOIN csrimp.map_customer_flow_cap mcfc ON att.flow_capability_id = mcfc.old_customer_flow_cap_id;

	INSERT INTO csr.audit_type_header (internal_audit_type_id, plugin_type_id, plugin_id, pos)
		SELECT miat.new_internal_audit_type_id, ath.plugin_type_id, mp.new_plugin_id, ath.pos
		  FROM csrimp.audit_type_header ath
		  JOIN csrimp.map_internal_audit_type miat ON ath.internal_audit_type_id = miat.old_internal_audit_type_id
		  JOIN csrimp.map_plugin mp ON ath.plugin_id = mp.old_plugin_id;

	INSERT INTO csr.audit_type_flow_inv_type (
				audit_type_flow_inv_type_id,
				flow_involvement_type_id,
				internal_audit_type_id,
				min_users,
				max_users,
				users_role_or_group_sid
	   ) SELECT matfit.new_aud_tp_flow_inv_tp_id,
				mfit.new_flow_involvement_type_id,
				miat.new_internal_audit_type_id,
				atfit.min_users,
				atfit.max_users,
				ms.new_sid
		   FROM csrimp.audit_type_flow_inv_type atfit
		   JOIN csrimp.map_aud_tp_flow_inv_tp matfit ON matfit.old_aud_tp_flow_inv_tp_id = atfit.audit_type_flow_inv_type_id
		   JOIN csrimp.map_flow_involvement_type mfit ON mfit.old_flow_involvement_type_id = atfit.flow_involvement_type_id
		   JOIN csrimp.map_internal_audit_type miat ON miat.old_internal_audit_type_id = atfit.internal_audit_type_id
	  LEFT JOIN csrimp.map_sid ms ON ms.old_sid = atfit.users_role_or_group_sid;

	INSERT INTO csr.ia_type_survey_group (
				ia_type_survey_group_id,
				survey_capability_id,
				change_survey_capability_id,
				label,
				lookup_key
	   ) SELECT mitsg.new_ia_type_survey_group_id,
				mcfc1.new_customer_flow_cap_id,
				mcfc2.new_customer_flow_cap_id,
				itsg.label,
				itsg.lookup_key
		   FROM csrimp.ia_type_survey_group itsg,
				csrimp.map_ia_type_survey_group mitsg,
				csrimp.map_customer_flow_cap mcfc1,
				csrimp.map_customer_flow_cap mcfc2
		  WHERE itsg.ia_type_survey_group_id = mitsg.old_ia_type_survey_group_id
			AND itsg.survey_capability_id = mcfc1.old_customer_flow_cap_id
			AND itsg.change_survey_capability_id = mcfc2.old_customer_flow_cap_id;

	INSERT INTO csr.internal_audit_type_survey (
				internal_audit_type_survey_id,
				active,
				default_survey_sid,
				ia_type_survey_group_id,
				internal_audit_type_id,
				label,
				mandatory,
				survey_group_key,
				survey_fixed
	   ) SELECT miats.new_ia_type_survey_id,
				iats.active,
				ms.new_sid,
				mitsg.new_ia_type_survey_group_id,
				miat.new_internal_audit_type_id,
				iats.label,
				iats.mandatory,
				iats.survey_group_key,
				iats.survey_fixed
		   FROM csrimp.internal_audit_type_survey iats,
				csrimp.map_ia_type_survey miats,
				csrimp.map_sid ms,
				csrimp.map_ia_type_survey_group mitsg,
				csrimp.map_internal_audit_type miat
		  WHERE iats.internal_audit_type_survey_id = miats.old_ia_type_survey_id
			AND iats.default_survey_sid = ms.old_sid(+)
			AND iats.ia_type_survey_group_id = mitsg.old_ia_type_survey_group_id(+)
			AND iats.internal_audit_type_id = miat.old_internal_audit_type_id;

	INSERT INTO csr.internal_audit_survey (
				internal_audit_sid,
				internal_audit_type_survey_id,
				survey_response_id,
				survey_sid
	   ) SELECT ms.new_sid,
				miats.new_ia_type_survey_id,
				mqsr.new_survey_response_id,
				ms1.new_sid
		   FROM csrimp.internal_audit_survey ias,
				csrimp.map_sid ms,
				csrimp.map_ia_type_survey miats,
				csrimp.map_qs_survey_response mqsr,
				csrimp.map_sid ms1
		  WHERE ias.internal_audit_sid = ms.old_sid
			AND ias.internal_audit_type_survey_id = miats.old_ia_type_survey_id
			AND ias.survey_response_id = mqsr.old_survey_response_id(+)
			AND ias.survey_sid = ms1.old_sid;

	INSERT INTO csr.internal_audit_score (
				internal_audit_sid,
				score_type_id,
				score,
				score_threshold_id
	   ) SELECT ms.new_sid,
				mst.new_score_type_id,
				ias.score,
				mst1.new_score_threshold_id
		   FROM csrimp.internal_audit_score ias,
				csrimp.map_sid ms,
				csrimp.map_score_type mst,
				csrimp.map_score_threshold mst1
		  WHERE ias.internal_audit_sid = ms.old_sid
			AND ias.score_type_id = mst.old_score_type_id
			AND ias.score_threshold_id = mst1.old_score_threshold_id(+);

	INSERT INTO csr.internal_audit_locked_tag (
				internal_audit_sid,
				tag_group_id,
				tag_id
	   ) SELECT ma.new_sid,
				mtg.new_tag_group_id,
				mt.new_tag_id
		   FROM csrimp.internal_audit_locked_tag ialt, csrimp.map_tag_group mtg, csrimp.map_sid ma, csrimp.map_tag mt
		  WHERE mtg.old_tag_group_id = ialt.tag_group_id
			AND ma.old_sid = ialt.internal_audit_sid
			AND mt.old_tag_id = ialt.tag_id;

	INSERT INTO csr.score_type_audit_type (score_type_id, internal_audit_type_id)
		 SELECT mst.new_score_type_id, miat.new_internal_audit_type_id
		   FROM csrimp.score_type_audit_type stat
		   JOIN csrimp.map_score_type mst on stat.score_type_id = mst.old_score_type_id
		   JOIN csrimp.map_internal_audit_type miat ON stat.internal_audit_type_id = miat.old_internal_audit_type_id;

	INSERT INTO csr.internal_audit_listener_last_update (tenant_id, external_parent_ref, external_ref, last_update, correlation_id)
		 SELECT llu.tenant_id, llu.external_parent_ref, llu.external_ref, llu.last_update, llu.correlation_id
		   FROM csrimp.internal_audit_listener_last_update llu;
END;

PROCEDURE FixQuickSurveyXml(
	in_survey_sid					IN	csrimp.quick_survey.survey_sid%TYPE,
	in_xml							IN	csrimp.quick_survey_version.question_xml%TYPE,
	out_clob						OUT	CLOB
)
AS
	v_doc							dbms_xmldom.DOMDocument;
	v_nl							dbms_xmldom.DOMNodeList;
	v_n								dbms_xmldom.DOMNode;
	v_id							NUMBER(10);
	v_new_id						NUMBER(10);
	v_old_id						NUMBER(10);
	v_old_ids						VARCHAR2(4000);
	v_new_ids						VARCHAR2(4000);
BEGIN
	v_doc := dbms_xmldom.newDomDocument(in_xml);

	v_nl := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc),'//question|//pageBreak|//question/checkbox|//section|//question/radioRow');
	FOR idx IN 0 .. dbms_xmldom.getLength(v_nl) - 1 LOOP
		v_n := dbms_xmldom.item(v_nl, idx);
		v_old_id := dbms_xmldom.getAttribute(dbms_xmldom.makeElement(v_n), 'id');

		BEGIN
			SELECT new_question_id
			  INTO v_new_id
			  FROM csrimp.map_qs_question
			 WHERE old_question_id = v_old_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				security_pkg.debugmsg('csrimp session '||SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')||
					' old question id '||v_old_id||' not found -- setting to null');
				v_new_id := NULL;
		END;

		dbms_xmldom.setAttribute(dbms_xmldom.makeElement(v_n), 'id', v_new_id);
	END LOOP;

	v_nl := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc),'//question/option|//question/columnHeader');
	FOR idx IN 0 .. dbms_xmldom.getLength(v_nl) - 1 LOOP
		v_n := dbms_xmldom.item(v_nl, idx);
		v_old_id := dbms_xmldom.getAttribute(dbms_xmldom.makeElement(v_n), 'id');

		BEGIN
			SELECT new_question_option_id
			  INTO v_new_id
			  FROM csrimp.map_qs_question_option
			 WHERE old_question_option_id = v_old_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				security_pkg.debugmsg('csrimp session '||SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')||
					' old question option id '||v_old_id||' not found -- setting to null');
				v_new_id := NULL;
		END;

		dbms_xmldom.setAttribute(dbms_xmldom.makeElement(v_n), 'id', v_new_id);
	END LOOP;

	v_nl := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc),'//scoreOverride');
	FOR idx IN 0 .. dbms_xmldom.getLength(v_nl) - 1 LOOP
		v_n := dbms_xmldom.item(v_nl, idx);
		v_old_id := dbms_xmldom.getAttribute(dbms_xmldom.makeElement(v_n), 'columnId');

		BEGIN
			SELECT new_question_option_id
			  INTO v_new_id
			  FROM csrimp.map_qs_question_option
			 WHERE old_question_option_id = v_old_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				security_pkg.debugmsg('csrimp session '||SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')||
					' old question option id '||v_old_id||' not found -- setting to null');
				v_new_id := NULL;
		END;

		dbms_xmldom.setAttribute(dbms_xmldom.makeElement(v_n), 'columnId', v_new_id);
	END LOOP;

	v_nl := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc),'//@pickerRegionRootSid');
	FOR idx IN 0 .. dbms_xmldom.getLength(v_nl) - 1 LOOP
		v_n := dbms_xmldom.item(v_nl, idx);
		v_old_id := dbms_xmldom.getNodeValue(v_n);

		BEGIN
			SELECT new_sid
			  INTO v_new_id
			  FROM csrimp.map_sid
			 WHERE old_sid = v_old_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				security_pkg.debugmsg('csrimp session '||SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')||
					' old picker root sid '||v_old_id||' not found -- setting to null');
				v_new_id := NULL;
		END;

		dbms_xmldom.setNodeValue(v_n, v_new_id);
	END LOOP;

	-- non compliance types
	v_nl := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc),'//@ncTypeId');
	FOR idx IN 0 .. dbms_xmldom.getLength(v_nl) - 1 LOOP
		v_n := dbms_xmldom.item(v_nl, idx);
		v_old_id := dbms_xmldom.getNodeValue(v_n);

		BEGIN
			SELECT new_non_compliance_type_id
			  INTO v_new_id
			  FROM csrimp.map_non_compliance_type
			 WHERE old_non_compliance_type_id = v_old_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				security_pkg.debugmsg('csrimp session '||SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')||
					' old ncTypeId '||v_old_id||' not found -- setting to null');
				v_new_id := NULL;
		END;

		dbms_xmldom.setNodeValue(v_n, v_new_id);
	END LOOP;

	-- default non compliances
	v_nl := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc),'//@ncId');
	FOR idx IN 0 .. dbms_xmldom.getLength(v_nl) - 1 LOOP
		v_n := dbms_xmldom.item(v_nl, idx);
		v_old_id := dbms_xmldom.getNodeValue(v_n);

		BEGIN
			SELECT new_non_comp_default_id
			  INTO v_new_id
			  FROM csrimp.map_non_comp_default
			 WHERE old_non_comp_default_id = v_old_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				security_pkg.debugmsg('csrimp session '||SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')||
					' old ncId '||v_old_id||' not found -- setting to null');
				v_new_id := NULL;
		END;

		dbms_xmldom.setNodeValue(v_n, v_new_id);
	END LOOP;

	-- tagGroupId
	v_nl := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc),'//@tagGroupId');
	FOR idx IN 0 .. dbms_xmldom.getLength(v_nl) - 1 LOOP
		v_n := dbms_xmldom.item(v_nl, idx);
		v_old_id := dbms_xmldom.getNodeValue(v_n);

		BEGIN
			SELECT new_tag_group_id
			  INTO v_new_id
			  FROM csrimp.map_tag_group
			 WHERE old_tag_group_id = v_old_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				security_pkg.debugmsg('csrimp session '||SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')||
					' old tagGroupId '||v_old_id||' not found -- setting to null');
				v_new_id := NULL;
		END;

		dbms_xmldom.setNodeValue(v_n, v_new_id);
	END LOOP;

	-- tag ids (1) <tag id="old_id"...
	v_nl := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc),'//tag');
	FOR idx IN 0 .. dbms_xmldom.getLength(v_nl) - 1 LOOP
		v_n := dbms_xmldom.item(v_nl, idx);
		v_old_id := dbms_xmldom.getAttribute(dbms_xmldom.makeElement(v_n), 'id');

		BEGIN
			SELECT new_tag_id
			  INTO v_new_id
			  FROM csrimp.map_tag
			 WHERE old_tag_id = v_old_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				security_pkg.debugmsg('csrimp session '||SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID')||
					' old tag id '||v_old_id||' not found -- setting to null');
				v_new_id := NULL;
		END;

		dbms_xmldom.setAttribute(dbms_xmldom.makeElement(v_n), 'id', v_new_id);
	END LOOP;

	-- tag ids (2) -- <option ncTagIds="old_id,old_id,old_id"...
	v_nl := dbms_xslprocessor.selectNodes(dbms_xmldom.makeNode(v_doc),'//@ncTagIds');
	FOR idx IN 0 .. dbms_xmldom.getLength(v_nl) - 1 LOOP
		v_n := dbms_xmldom.item(v_nl, idx);
		v_old_ids := dbms_xmldom.getNodeValue(v_n);

		SELECT csr.stragg(mt.new_tag_id)
		  INTO v_new_ids
		  FROM csrimp.map_tag mt
		  JOIN TABLE(csr.utils_pkg.splitstring(v_old_ids,',')) ids
			ON mt.old_tag_id = ids.item;

		dbms_xmldom.setNodeValue(v_n, v_new_ids);
	END LOOP;

	-- write back
	DBMS_LOB.CreateTemporary(out_clob, TRUE);
	dbms_xmldom.writeToClob(v_doc, out_clob);

	-- Free any resources associated with the document now it
	-- is no longer needed.
	dbms_xmldom.freeDocument(v_doc);

EXCEPTION
	WHEN OTHERS THEN
		dbms_xmldom.freeDocument(v_doc);
		RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
END;

PROCEDURE FixQuickSurveyResponse(
	in_survey_sid					IN	csrimp.quick_survey_response.survey_sid%TYPE,
	in_survey_response_id			IN	csrimp.quick_survey_response.survey_response_id%TYPE,
	in_xml							IN	csrimp.quick_survey_response.question_xml_override%TYPE
)
AS
	v_clob							CLOB;
BEGIN
	FixQuickSurveyXml(in_survey_sid, in_xml, v_clob);

	UPDATE csr.quick_survey_response
	   SET question_xml_override = v_clob
	 WHERE survey_response_id = in_survey_response_id;

	DBMS_LOB.FreeTemporary(v_clob);
END;

PROCEDURE FixQuickSurvey(
	in_survey_sid					IN	csrimp.quick_survey.survey_sid%TYPE,
	in_survey_version				IN	csrimp.quick_survey_version.survey_version%TYPE,
	in_xml							IN	csrimp.quick_survey_version.question_xml%TYPE
)
AS
	v_clob							CLOB;
BEGIN
	FixQuickSurveyXml(in_survey_sid, in_xml, v_clob);

	UPDATE csr.quick_survey_version
	   SET question_xml = v_clob
	 WHERE survey_sid = in_survey_sid
	   AND survey_version = in_survey_version;

	DBMS_LOB.FreeTemporary(v_clob);
END;

PROCEDURE CreateQuestionLibrary
AS
BEGIN
	INSERT INTO csr.question (question_id, question_type, custom_question_type_id, lookup_key,
				maps_to_ind_sid, measure_sid, latest_question_version, latest_question_draft)
		SELECT mq.new_question_id, q.question_type, mct.new_custom_question_type_id, q.lookup_key,
			   mi.new_sid, mm.new_sid, q.latest_question_version, q.latest_question_draft
		  FROM csrimp.question q, csrimp.map_qs_question mq,
		  	   csrimp.map_sid mi, csrimp.map_sid mm,
		  	   csrimp.map_qs_custom_question_type mct
		 WHERE q.question_id = mq.old_question_id
		   AND q.maps_to_ind_sid = mi.old_sid(+)
		   AND q.measure_sid = mm.old_sid(+)
		   AND q.custom_question_type_id = mct.old_custom_question_type_id(+);

	INSERT INTO csr.question_version (question_id, question_version, question_draft, parent_id, parent_version, parent_draft,
		pos, label, score, max_score, upload_score, weight, dont_normalise_score, has_score_expression, has_max_score_expr,
		remember_answer, count_question, action, question_xml)
		SELECT mq.new_question_id, q.question_version, q.question_draft, mpq.new_question_id, q.parent_version, q.parent_draft,
			   q.pos, q.label, q.score, q.max_score, q.upload_score, q.weight, q.dont_normalise_score, q.has_score_expression, q.has_max_score_expr,
			   q.remember_answer, q.count_question, q.action, q.question_xml
		  FROM csrimp.question_version q, csrimp.map_qs_question mq,
		  	   csrimp.map_qs_question mpq
		 WHERE q.question_id = mq.old_question_id
		   AND q.parent_id = mpq.old_question_id(+);

	INSERT INTO csr.question_option (question_option_id, question_id, question_version, question_draft,
		pos, label, color, lookup_key, maps_to_ind_sid, option_action, score,
		non_compliance_popup, non_comp_default_id, non_compliance_type_id,
		non_compliance_label, non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, question_option_xml)
		SELECT mqo.new_question_option_id, mq.new_question_id, qo.question_version, qo.question_draft,
			   qo.pos, qo.label, qo.color, qo.lookup_key, mi.new_sid, qo.option_action, qo.score,
			   qo.non_compliance_popup, mncd.new_non_comp_default_id, mnct.new_non_compliance_type_id,
			   qo.non_compliance_label, qo.non_compliance_detail, qo.non_comp_root_cause,
			   qo.non_comp_suggested_action, qo.question_option_xml
		  FROM csrimp.question_option qo, csrimp.map_qs_question_option mqo,
			   csrimp.map_qs_question mq, csrimp.map_sid mi, csrimp.map_non_compliance_type mnct,
		  	   csrimp.map_non_comp_default mncd
		 WHERE qo.question_option_id = mqo.old_question_option_id
		   AND qo.question_id = mq.old_question_id
		   AND qo.maps_to_ind_sid = mi.old_sid(+)
		   AND qo.non_comp_default_id = mncd.old_non_comp_default_id(+)
		   AND qo.non_compliance_type_id = mnct.old_non_compliance_type_id(+);

	INSERT INTO csr.question_option_nc_tag (question_id, question_option_id, question_version, question_draft, tag_id)
		SELECT mq.new_question_id, mqo.new_question_option_id, qot.question_version, qot.question_draft, mt.new_tag_id
		  FROM csrimp.question_option_nc_tag qot, csrimp.map_qs_question_option mqo,
			   csrimp.map_qs_question mq, csrimp.map_tag mt
		 WHERE qot.question_option_id = mqo.old_question_option_id
		   AND qot.question_id = mq.old_question_id
		   AND qot.tag_id = mt.old_tag_id;

	INSERT INTO csr.question_tag (question_id, question_version, tag_id, question_draft, show_in_survey)
		SELECT mq.new_question_id, qsqt.question_version, mt.new_tag_id, qsqt.question_draft, qsqt.show_in_survey
		  FROM csrimp.question_tag qsqt, csrimp.map_qs_question mq,
		       csrimp.map_tag mt
		 WHERE qsqt.question_id = mq.old_question_id
		   AND qsqt.tag_id = mt.old_tag_id;
END;

PROCEDURE CreateQuickSurvey
AS
BEGIN
	INSERT INTO csr.score_type (score_type_id, label, pos, hidden, allow_manual_set,
		lookup_key, applies_to_supplier, reportable_months, measure_sid, supplier_score_ind_sid,
		format_mask, ask_for_comment, applies_to_surveys, applies_to_non_compliances,
		min_score, max_score, start_score, normalise_to_max_score, applies_to_regions,
		applies_to_audits, applies_to_supp_rels, applies_to_permits, show_expired_scores)
		SELECT mt.new_score_type_id, t.label, t.pos, t.hidden, t.allow_manual_set,
			   t.lookup_key, t.applies_to_supplier, t.reportable_months, mms.new_sid,
			   mssis.new_sid, t.format_mask, t.ask_for_comment,
			   t.applies_to_surveys, t.applies_to_non_compliances,
			   t.min_score, t.max_score, t.start_score, t.normalise_to_max_score,
			   t.applies_to_regions, t.applies_to_audits, t.applies_to_supp_rels, t.applies_to_permits,
			   t.show_expired_scores
		  FROM csrimp.score_type t
		  JOIN csrimp.map_score_type mt on t.score_type_id = mt.old_score_type_id
		  LEFT JOIN csrimp.map_sid mms on t.measure_sid = mms.old_sid
		  LEFT JOIN csrimp.map_sid mssis on t.supplier_score_ind_sid = mssis.old_sid;

	-- moved from CMS because it's dependent on csr.score_type
	INSERT INTO cms.cms_aggregate_type (cms_aggregate_type_id, tab_sid, first_arg_column_sid,
		   second_arg_column_sid, operation, description, analytic_function, score_type_id,
		   format_mask, normalize_by_aggregate_type_id)
	SELECT mat.new_cms_aggregate_type_id, mt.new_sid, mc1.new_column_id,
		   mc2.new_column_id, operation, description, analytic_function, mst.new_score_type_id,
		   cat.format_mask, matn.new_cms_aggregate_type_id
	  FROM csrimp.cms_aggregate_type cat
	  JOIN csrimp.map_cms_aggregate_type mat ON cat.cms_aggregate_type_id = mat.old_cms_aggregate_type_id
	  JOIN csrimp.map_sid mt ON cat.tab_sid = mt.old_sid
	  JOIN csrimp.map_cms_tab_column mc1 ON cat.first_arg_column_sid = mc1.old_column_id
	  LEFT JOIN csrimp.map_cms_tab_column mc2 ON cat.second_arg_column_sid = mc2.old_column_id
	  LEFT JOIN csrimp.map_score_type mst ON cat.score_type_id = mst.old_score_type_id
	  LEFT JOIN csrimp.map_cms_aggregate_type matn ON cat.normalize_by_aggregate_type_id = matn.old_cms_aggregate_type_id;

	INSERT INTO csr.quick_survey_type (quick_survey_type_id, description, cs_class,
			helper_pkg, enable_question_count, show_answer_set_dtm, other_text_req_for_score, 
			tearoff_toolbar, capture_geo_location, enable_response_import)
		SELECT mqst.new_quick_survey_type_id, qst.description, qst.cs_class,
			   qst.helper_pkg, qst.enable_question_count, qst.show_answer_set_dtm,
			   qst.other_text_req_for_score, qst.tearoff_toolbar, qst.capture_geo_location,
			   qst.enable_response_import			   
		  FROM csrimp.quick_survey_type qst, csrimp.map_qs_type mqst
		 WHERE qst.quick_survey_type_id = mqst.old_quick_survey_type_id;

	INSERT INTO csr.quick_survey (survey_sid, created_dtm, audience, aggregate_ind_group_id,
			   quick_survey_type_id, root_ind_sid, submission_validity_months, 
			   score_type_id, last_modified_dtm, group_key,
			   from_question_library, lookup_key)
		SELECT mqs.new_sid, qs.created_dtm, qs.audience, maig.new_aggregate_ind_group_id,
			   mqst.new_quick_survey_type_id, mi.new_sid, submission_validity_months,
			   mt.new_score_type_id, qs.last_modified_dtm, qs.group_key, 
			   qs.from_question_library, qs.lookup_key
		  FROM csrimp.quick_survey qs, csrimp.map_sid mqs,
		  	   csrimp.map_aggregate_ind_group maig, csrimp.map_sid mi,
		  	   csrimp.map_qs_type mqst, csrimp.map_score_type mt
		 WHERE qs.survey_sid = mqs.old_sid
		   AND qs.aggregate_ind_group_id = maig.old_aggregate_ind_group_id(+)
		   AND qs.quick_survey_type_id = mqst.old_quick_survey_type_id(+)
		   AND qs.root_ind_sid = mi.old_sid(+)
		   AND qs.score_type_id = mt.old_score_type_id(+);

	UPDATE csr.question q
	   SET owned_by_survey_sid = (
		SELECT mss.new_sid
		  FROM csrimp.question oq
		  JOIN csrimp.map_qs_question mq ON oq.question_id = mq.old_question_id
		  LEFT JOIN csrimp.map_sid mss ON oq.owned_by_survey_sid = mss.old_sid
		 WHERE q.question_id = mq.new_question_id
		);

	INSERT INTO csr.quick_survey_version (survey_sid, survey_version, question_xml, label,
		start_dtm, end_dtm, published_dtm, published_by_sid)
		SELECT mqs0.new_sid, qsv.survey_version, qsv.question_xml, qsv.label, qsv.start_dtm,
			   qsv.end_dtm, qsv.published_dtm, mqs1.new_sid
		  FROM csrimp.quick_survey_version qsv, csrimp.map_sid mqs0, csrimp.map_sid mqs1
		 WHERE qsv.survey_sid = mqs0.old_sid
		   AND qsv.published_by_sid = mqs1.old_sid(+);

	UPDATE csr.quick_survey qs
	   SET current_version = (
		SELECT current_version
		  FROM csrimp.quick_survey oqs
		  JOIN csrimp.map_sid mqs ON oqs.survey_sid = mqs.old_sid
		 WHERE qs.survey_sid = mqs.new_sid
	);

	INSERT INTO csr.quick_survey_lang (survey_sid, lang)
		SELECT ms.new_sid, qsl.lang
		  FROM csrimp.quick_survey_lang qsl, csrimp.map_sid ms
		 WHERE qsl.survey_sid = ms.old_sid;

	INSERT INTO campaigns.campaign(campaign_sid, name, table_sid, filter_sid,
		survey_sid, frame_id, subject, body, send_after_dtm, status, sent_dtm,
		period_start_dtm, period_end_dtm, audience_type, flow_sid, inc_regions_with_no_users,
		skip_overlapping_regions, carry_forward_answers, send_to_column_sid, region_column_sid,
		created_by_sid, filter_xml, response_column_sid, tag_lookup_key_column_sid,
		is_system_generated, customer_alert_type_id, campaign_end_dtm,
		send_alert, dynamic, resend)
		SELECT mqc.new_sid, qc.name, mt.new_sid, mf.new_sid, ms.new_sid, mframe.new_alert_frame_id,
			   subject, body, send_after_dtm, status, sent_dtm, period_start_dtm,
			   period_end_dtm, audience_type, mflow.new_sid, inc_regions_with_no_users,
			   skip_overlapping_regions, carry_forward_answers, mstc.new_column_id,
			   mrc.new_column_id, mcb.new_sid, qc.filter_xml, mrcs.new_column_id,
			   mlukcs.new_column_id, qc.is_system_generated, mcat.new_customer_alert_type_id,
			   qc.campaign_end_dtm, qc.send_alert, qc.dynamic, qc.resend
		  FROM csrimp.campaign qc, csrimp.map_sid mqc, csrimp.map_sid mt,
		  	   csrimp.map_sid mf, csrimp.map_sid ms, csrimp.map_alert_frame maf,
		  	   csrimp.map_sid mflow, csrimp.map_alert_frame mframe,
		  	   csrimp.map_cms_tab_column mstc, csrimp.map_cms_tab_column mrc,
		  	   csrimp.map_sid mcb, csrimp.map_cms_tab_column mrcs,
		  	   csrimp.map_cms_tab_column mlukcs, csrimp.map_customer_alert_type mcat
		 WHERE qc.campaign_sid = mqc.old_sid
		   AND qc.table_sid = mt.old_sid(+)
		   AND qc.filter_sid = mf.old_sid(+)
		   AND qc.survey_sid = ms.old_sid
		   AND qc.frame_id = maf.old_alert_frame_id(+)
		   AND qc.flow_sid = mflow.old_sid(+)
		   AND qc.frame_id = mframe.old_alert_frame_id(+)
		   AND qc.send_to_column_sid = mstc.old_column_id(+)
		   AND qc.region_column_sid = mrc.old_column_id(+)
		   AND qc.created_by_sid = mcb.old_sid(+)
		   AND qc.response_column_sid = mrcs.old_column_id(+)
		   AND qc.tag_lookup_key_column_sid = mlukcs.old_column_id(+)
		   AND qc.customer_alert_type_id = mcat.old_customer_alert_type_id(+);

		   
	INSERT INTO campaigns.campaign_region_response (campaign_sid, response_id, region_sid, surveys_version, flow_item_id)
		SELECT mc.new_sid, mqsr.new_survey_response_id, mr.new_sid, crr.surveys_version, mfi.new_flow_item_id
		  FROM csrimp.campaign_region_response crr, csrimp.map_sid mr, csrimp.map_sid mc, csrimp.map_qs_survey_response mqsr, csrimp.map_flow_item mfi
		 WHERE crr.campaign_sid = mc.old_sid
		   AND crr.response_id = mqsr.old_survey_response_id
		   AND crr.response_id = mfi.old_flow_item_id(+)
		   AND crr.region_sid = mr.old_sid;

	-- TODO: keep guid or generate a new one?
	INSERT INTO csr.quick_survey_response (survey_response_id, survey_sid, user_sid, user_name,
		created_dtm, guid, qs_campaign_sid, last_submission_id, survey_version,
		question_xml_override, hidden)
		SELECT mqsr.new_survey_response_id, mqs.new_sid, qsr.user_name, mu.new_sid,
			   qsr.created_dtm, qsr.guid, mqc.new_sid,
			   null, /* last_submission_id: fixed up after inserting submissions */
			   qsr.survey_version, qsr.question_xml_override, hidden
		  FROM csrimp.quick_survey_response qsr, csrimp.map_qs_survey_response mqsr,
		  	   csrimp.map_sid mqs, csrimp.map_sid mu,
		  	   csrimp.map_sid mqc
		 WHERE qsr.survey_response_id = mqsr.old_survey_response_id
		   AND qsr.survey_sid = mqs.old_sid
		   AND qsr.user_sid = mu.old_sid(+)
		   AND qsr.qs_campaign_sid = mqc.old_sid(+);

	-- Update flow_item (ideally we should move the RI the other way around)
	UPDATE csr.flow_item fi
	   SET survey_response_id = (
		SELECT new_survey_response_id
		  FROM csrimp.flow_item ofi
		  JOIN csrimp.map_qs_survey_response m ON m.old_survey_response_id = ofi.survey_response_id
		  JOIN csrimp.map_flow_item mfi ON ofi.flow_item_id = mfi.old_flow_item_id
		 WHERE mfi.new_flow_item_id = fi.flow_item_id
		);

	INSERT INTO csr.qs_response_postit (survey_response_id, postit_id)
		SELECT mqsr.new_survey_response_id, mp.new_postit_id
		  FROM csrimp.qs_response_postit qsrp, csrimp.map_qs_survey_response mqsr,
		  	   csrimp.map_postit mp
		 WHERE qsrp.survey_response_id = mqsr.old_survey_response_id
		   AND qsrp.postit_id = mp.old_postit_id;

	INSERT INTO csr.qs_custom_question_type (custom_question_type_id, description, js_include,
		js_class, cs_class)
		SELECT mcq.new_custom_question_type_id, cq.description, cq.js_include,
			   cq.js_class, cq.cs_class
		  FROM csrimp.qs_custom_question_type cq, csrimp.map_qs_custom_question_type mcq
		 WHERE cq.custom_question_type_id = mcq.old_custom_question_type_id;

	INSERT INTO csr.quick_survey_question (question_id, question_version, parent_id, parent_version, survey_sid,
		pos, label, is_visible, question_type, score, lookup_key, maps_to_ind_sid,
		measure_sid, max_score, upload_score, custom_question_type_id, weight,
		dont_normalise_score, has_score_expression, has_max_score_expr, survey_version,
		remember_answer, count_question, action, question_draft)
		SELECT mq.new_question_id, q.question_version, mpq.new_question_id, q.parent_version, ms.new_sid, q.pos, q.label,
			   q.is_visible, q.question_type, q.score, q.lookup_key, mi.new_sid,
			   mm.new_sid, q.max_score, q.upload_score,
			   mct.new_custom_question_type_id, q.weight, q.dont_normalise_score,
			   q.has_score_expression, q.has_max_score_expr, q.survey_version, q.remember_answer,
			   q.count_question, q.action, q.question_draft
		  FROM csrimp.quick_survey_question q, csrimp.map_qs_question mq,
		  	   csrimp.map_qs_question mpq, csrimp.map_sid ms,
		  	   csrimp.map_sid mi, csrimp.map_sid mm,
		  	   csrimp.map_qs_custom_question_type mct
		 WHERE q.question_id = mq.old_question_id
		   AND q.parent_id = mpq.old_question_id(+)
		   AND q.survey_sid = ms.old_sid
		   AND q.maps_to_ind_sid = mi.old_sid(+)
		   AND q.measure_sid = mm.old_sid(+)
		   AND q.custom_question_type_id = mct.old_custom_question_type_id(+);

	INSERT INTO csr.non_compliance_type (non_compliance_type_id, label, lookup_key, position, colour_when_open,
										colour_when_closed, can_have_actions, closure_behaviour_id,
										score, repeat_score, inter_non_comp_ref_helper_func, inter_non_comp_ref_prefix,
										root_cause_enabled, suggested_action_enabled,
									    match_repeats_by_carry_fwd, match_repeats_by_default_ncs, match_repeats_by_surveys,
									    find_repeats_in_unit, find_repeats_in_qty, carry_fwd_repeat_type,
										is_default_survey_finding)
		 SELECT mnct.new_non_compliance_type_id, nct.label, nct.lookup_key, nct.position, nct.colour_when_open,
		        nct.colour_when_closed, nct.can_have_actions, nct.closure_behaviour_id,
				nct.score, nct.repeat_score, nct.inter_non_comp_ref_helper_func, nct.inter_non_comp_ref_prefix,
				nct.root_cause_enabled, nct.suggested_action_enabled,
			    nct.match_repeats_by_carry_fwd, nct.match_repeats_by_default_ncs, nct.match_repeats_by_surveys,
			    nct.find_repeats_in_unit, nct.find_repeats_in_qty, nct.carry_fwd_repeat_type,
				nct.is_default_survey_finding
		   FROM csrimp.non_compliance_type nct
		   JOIN map_non_compliance_type mnct ON nct.non_compliance_type_id = mnct.old_non_compliance_type_id;

	INSERT INTO csr.non_compliance_type_tag_group (non_compliance_type_id, tag_group_id)
		 SELECT mnct.new_non_compliance_type_id, mtg.new_tag_group_id
		   FROM csrimp.non_compliance_type_tag_group nct
		   JOIN map_non_compliance_type mnct ON nct.non_compliance_type_id = mnct.old_non_compliance_type_id
		   JOIN csrimp.map_tag_group mtg ON mtg.old_tag_group_id = nct.tag_group_id;

	INSERT INTO csr.non_comp_default_folder (non_comp_default_folder_id, label, parent_folder_id)
		SELECT mncdf.new_non_comp_default_folder_id, ncdf.label, mpncdf.new_non_comp_default_folder_id
		  FROM csrimp.non_comp_default_folder ncdf
		  JOIN csrimp.map_non_comp_default_folder mncdf ON ncdf.non_comp_default_folder_id = mncdf.old_non_comp_default_folder_id
		  LEFT JOIN csrimp.map_non_comp_default_folder mpncdf ON ncdf.parent_folder_id = mpncdf.old_non_comp_default_folder_id;

	INSERT INTO csr.non_comp_default (non_comp_default_id, label, detail, non_compliance_type_id, root_cause,
		suggested_action, unique_reference, non_comp_default_folder_id)
		SELECT mncd.new_non_comp_default_id, ncd.label, ncd.detail, mnct.new_non_compliance_type_id,
			   ncd.root_Cause, ncd.suggested_action, ncd.unique_reference, mncdf.new_non_comp_default_folder_id
		  FROM csrimp.non_comp_default ncd
		  JOIN csrimp.map_non_comp_default mncd ON ncd.non_comp_default_id = mncd.old_non_comp_default_id
		  LEFT JOIN csrimp.map_non_compliance_type mnct ON ncd.non_compliance_type_id = mnct.old_non_compliance_type_id
		  LEFT JOIN csrimp.map_non_comp_default_folder mncdf ON ncd.non_comp_default_folder_id = mncdf.old_non_comp_default_folder_id;

	INSERT INTO csr.qs_question_option (question_option_id, question_id, question_version,
		pos, label, is_visible, score, color, lookup_key, maps_to_ind_sid, option_action,
		survey_sid, survey_version, non_compliance_popup, non_comp_default_id, non_compliance_type_id,
		non_compliance_label, non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, question_draft)
		SELECT mqo.new_question_option_id, mq.new_question_id, qo.question_version,
			   qo.pos, qo.label, qo.is_visible, qo.score, qo.color, qo.lookup_key,
			   mi.new_sid, qo.option_action, ms.new_sid, qo.survey_version, qo.non_compliance_popup,
			   mncd.new_non_comp_default_id, mnct.new_non_compliance_type_id,
			   qo.non_compliance_label, qo.non_compliance_detail, qo.non_comp_root_cause,
			   qo.non_comp_suggested_action, qo.question_draft
		  FROM csrimp.qs_question_option qo, csrimp.map_qs_question_option mqo,
			   csrimp.map_qs_question mq, csrimp.map_sid mi, csrimp.map_non_compliance_type mnct,
		  	   csrimp.map_non_comp_default mncd, csrimp.map_sid ms
		 WHERE qo.question_option_id = mqo.old_question_option_id
		   AND qo.question_id = mq.old_question_id
		   AND qo.maps_to_ind_sid = mi.old_sid(+)
		   AND qo.survey_sid = ms.old_sid
		   AND qo.non_comp_default_id = mncd.old_non_comp_default_id(+)
		   AND qo.non_compliance_type_id = mnct.old_non_compliance_type_id(+);

	INSERT INTO csr.qs_question_option_nc_tag (question_id, question_option_id, question_version,
			survey_sid, survey_version, tag_id)
		SELECT mq.new_question_id, mqo.new_question_option_id, qot.question_version,
			ms.new_sid, qot.survey_version, mt.new_tag_id
		  FROM csrimp.qs_question_option_nc_tag qot, csrimp.map_qs_question_option mqo,
			   csrimp.map_qs_question mq, csrimp.map_tag mt, csrimp.map_sid ms
		 WHERE qot.question_option_id = mqo.old_question_option_id
		   AND qot.survey_sid = ms.old_sid
		   AND qot.question_id = mq.old_question_id
		   AND qot.tag_id = mt.old_tag_id;

	INSERT INTO csr.quick_survey_question_tag (question_id, question_version, tag_id, survey_sid, survey_version)
		SELECT mq.new_question_id, qsqt.question_version, mt.new_tag_id, ms.new_sid, qsqt.survey_version
		  FROM csrimp.quick_survey_question_tag qsqt, csrimp.map_qs_question mq,
		       csrimp.map_tag mt, csrimp.map_sid ms
		 WHERE qsqt.question_id = mq.old_question_id
		   AND qsqt.survey_sid = ms.old_sid
		   AND qsqt.tag_id = mt.old_tag_id;

	INSERT INTO csr.score_threshold (score_threshold_id, max_value, description,
		text_colour, background_colour, bar_colour, icon_image, icon_image_filename,
		icon_image_mime_type, icon_image_sha1, dashboard_image, dashboard_filename,
		dashboard_mime_type, dashboard_sha1, measure_list_index, score_type_id,
		supplier_score_ind_sid, lookup_key)
		SELECT mst.new_score_threshold_id, st.max_value, st.description, st.text_colour,
			   st.background_colour, st.bar_colour, st.icon_image, st.icon_image_filename,
			   st.icon_image_mime_type, st.icon_image_sha1, st.dashboard_image,
			   st.dashboard_filename, st.dashboard_mime_type, st.dashboard_sha1,
			   st.measure_list_index, mt.new_score_type_id, ms.new_sid, st.lookup_key
		  FROM csrimp.score_threshold st, csrimp.map_score_threshold mst,
			   csrimp.map_score_type mt, csrimp.map_sid ms
		 WHERE st.score_threshold_id = mst.old_score_threshold_id
		   AND st.score_type_id = mt.old_score_type_id
		   AND st.supplier_score_ind_sid = ms.old_sid(+);

	INSERT INTO csr.quick_survey_submission (survey_response_id, submission_id,
		submitted_dtm, submitted_by_user_sid, overall_score, overall_max_score,
		score_threshold_id, survey_version,
		geo_latitude, geo_longitude, geo_altitude,
		geo_h_accuracy, geo_v_accuracy)
		SELECT mqsr.new_survey_response_id, ms.new_submission_id, qss.submitted_dtm,
			   msu.new_sid, qss.overall_score, qss.overall_max_score,
			   msc.new_score_threshold_id, qss.survey_version,
			   qss.geo_latitude, qss.geo_longitude, qss.geo_altitude,
			   qss.geo_h_accuracy, qss.geo_v_accuracy
		  FROM csrimp.quick_survey_submission qss, csrimp.map_qs_survey_response mqsr,
		  	   csrimp.map_sid msu, csrimp.map_score_threshold msc,
		  	   csrimp.map_qs_submission ms
		 WHERE qss.survey_response_id = mqsr.old_survey_response_id
		   AND qss.submission_id = ms.old_submission_id
		   AND qss.submitted_by_user_sid = msu.old_sid(+)
		   AND qss.score_threshold_id = msc.old_score_threshold_id(+);

	UPDATE csr.quick_survey_response qsr
	   SET qsr.last_submission_id = (
	   		SELECT mqss.new_submission_id
	   		  FROM csrimp.map_qs_survey_response mqsr,
	   		  	   csrimp.quick_survey_response oqsr,
	   		  	   csrimp.map_qs_submission mqss
	   		 WHERE qsr.survey_response_id = mqsr.new_survey_response_id
	   		   AND mqsr.old_survey_response_id = oqsr.survey_response_id
	   		   AND oqsr.last_submission_id = mqss.old_submission_id);

	INSERT INTO csr.quick_survey_answer (survey_response_id, question_id, question_version, answer,
		note, score, question_option_id, val_number, measure_conversion_id,
		measure_sid, region_sid, html_display, max_score, version_stamp, submission_id,
		weight_override, survey_sid, survey_version, log_item)
		SELECT mqsr.new_survey_response_id, mq.new_question_id, qsa.question_version, qsa.answer, qsa.note,
			   qsa.score, mqo.new_question_option_id, qsa.val_number,
			   mmc.new_measure_conversion_id, mm.new_sid, mr.new_sid,
			   qsa.html_display, qsa.max_score, qsa.version_stamp,
			   ms.new_submission_id, qsa.weight_override, mss.new_sid, qsa.survey_version, qsa.log_item
		  FROM csrimp.quick_survey_answer qsa, csrimp.map_qs_survey_response mqsr,
		  	   csrimp.map_qs_question mq, csrimp.map_qs_question_option mqo,
		  	   csrimp.map_measure_conversion mmc, csrimp.map_sid mm,
		  	   csrimp.map_sid mr, csrimp.map_qs_submission ms, csrimp.map_sid mss
		 WHERE qsa.survey_response_id = mqsr.old_survey_response_id
		   AND qsa.question_id = mq.old_question_id
		   AND qsa.survey_sid = mss.old_sid
		   AND qsa.question_option_id = mqo.old_question_option_id(+)
		   AND qsa.measure_conversion_id = mmc.old_measure_conversion_id(+)
		   AND qsa.measure_sid = mm.old_sid(+)
		   AND qsa.region_sid = mr.old_sid(+)
		   AND qsa.submission_id = ms.old_submission_id;

	INSERT INTO csr.qs_response_file (survey_response_id, filename, mime_type, data, sha1, uploaded_dtm)
		SELECT mqsr.new_survey_response_id, qrf.filename, qrf.mime_type, qrf.data, qrf.sha1, qrf.uploaded_dtm
		  FROM csrimp.qs_response_file qrf, csrimp.map_qs_survey_response mqsr
		 WHERE qrf.survey_response_id = mqsr.old_survey_response_id;

	INSERT INTO csr.qs_answer_file (qs_answer_file_id, survey_response_id, question_id, question_version,
		filename, mime_type, sha1, caption, survey_sid, survey_version)
		SELECT mqaf.new_qs_answer_file_id, mqsr.new_survey_response_id, mq.new_question_id, qaf.question_version,
			   qaf.filename, qaf.mime_type, qaf.sha1,
			   qaf.caption, ms.new_sid, qaf.survey_version
		  FROM csrimp.qs_answer_file qaf, csrimp.map_qs_answer_file mqaf,
		  	   csrimp.map_qs_survey_response mqsr, csrimp.map_qs_question mq, csrimp.map_sid ms
		 WHERE qaf.qs_answer_file_id = mqaf.old_qs_answer_file_id
		   AND qaf.survey_response_id = mqsr.old_survey_response_id
		   AND qaf.survey_sid = ms.old_sid
		   AND qaf.question_id = mq.old_question_id;

	INSERT INTO csr.qs_submission_file (qs_answer_file_id, survey_response_id, submission_id,
		survey_version)
		SELECT mqaf.new_qs_answer_file_id, msr.new_survey_response_id, msub.new_submission_id,
			   qsf.survey_version
		  FROM csrimp.qs_submission_file qsf, csrimp.map_qs_answer_file mqaf,
		  	   csrimp.map_qs_survey_response msr, csrimp.map_qs_submission msub
		 WHERE qsf.qs_answer_file_id = mqaf.old_qs_answer_file_id
		   AND qsf.survey_response_id = msr.old_survey_response_id
		   AND qsf.submission_id = msub.old_submission_id;

	INSERT INTO csr.qs_answer_log (qs_answer_log_id, survey_response_id, question_id, question_version, version_stamp,
		set_dtm, set_by_user_sid, submission_id, log_item)
		SELECT csr.qs_answer_log_id_seq.nextval, mqsr.new_survey_response_id,
			   mq.new_question_id, qal.question_version, qal.version_stamp, qal.set_dtm, mu.new_sid,
			   msub.new_submission_id, qal.log_item
		  FROM csrimp.qs_answer_log qal, csrimp.map_qs_survey_response mqsr,
		 	   csrimp.map_qs_question mq, csrimp.map_sid mu,
		 	   csrimp.map_qs_submission msub
		 WHERE qal.survey_response_id = mqsr.old_survey_response_id
		   AND qal.question_id = mq.old_question_id
		   AND qal.set_by_user_sid = mu.old_sid
		   AND qal.submission_id = msub.old_submission_id;

	INSERT INTO csr.quick_survey_expr (survey_sid, expr_id, expr, survey_version, question_id, question_version, question_option_id)
		SELECT ms.new_sid, mqse.new_expr_id, qse.expr, qse.survey_version, mq.new_question_id, qse.question_version, mqo.new_question_option_id
		  FROM csrimp.quick_survey_expr qse
		  JOIN csrimp.map_sid ms ON qse.survey_sid = ms.old_sid
		  JOIN csrimp.map_qs_expr mqse ON qse.expr_id = mqse.old_expr_id
		  LEFT JOIN csrimp.map_qs_question mq ON qse.question_id = mq.old_question_id
		  LEFT JOIN csrimp.map_qs_question_option mqo ON qse.question_option_id = mqo.old_question_option_id;

	INSERT INTO csr.term_cond_doc (company_type_id, doc_id)
		SELECT company_type_id, doc_id
		  FROM csrimp.term_cond_doc;

	INSERT INTO csr.term_cond_doc_log (user_sid, company_type_id, doc_id, doc_version, accepted_dtm)
		SELECT user_sid, company_type_id, doc_id, doc_version, accepted_dtm
		  FROM csrimp.term_cond_doc_log;

	INSERT INTO csr.quick_survey_css (class_name, description, type, position)
		SELECT qsc.class_name, qsc.description, qsc.type, qsc.position
		  FROM csrimp.quick_survey_css qsc;

	INSERT INTO csr.quick_survey_score_threshold (survey_sid, score_threshold_id, maps_to_ind_sid)
		SELECT sms.new_sid, mst.new_score_threshold_id, ims.new_sid
		  FROM csrimp.quick_survey_score_threshold qsst, csrimp.map_score_threshold mst,
		  csrimp.map_sid sms, csrimp.map_sid ims
		 WHERE qsst.score_threshold_id = mst.old_score_threshold_id and qsst.csrimp_session_id = mst.csrimp_session_id and
		 qsst.survey_sid = sms.old_sid and qsst.csrimp_session_id = sms.csrimp_session_id and
		 qsst.maps_to_ind_sid = ims.old_sid and qsst.csrimp_session_id = ims.csrimp_session_id;

	FOR r IN (SELECT survey_sid, survey_Version, question_xml
			    FROM csr.quick_survey_version
			   WHERE question_xml IS NOT NULL) LOOP
		FixQuickSurvey(r.survey_sid, r.survey_version, r.question_xml);
	END LOOP;

	FOR r IN (SELECT survey_sid, survey_Version, question_xml_override, survey_response_id
			    FROM csr.quick_survey_response
			   WHERE question_xml_override IS NOT NULL) LOOP
		FixQuickSurveyResponse(r.survey_sid, r.survey_response_id, r.question_xml_override);
	END LOOP;
END;

PROCEDURE CreateQuickSurveyExprActions
AS
BEGIN
	INSERT INTO csr.qs_expr_msg_action (qs_expr_msg_action_id, msg, css_class)
		SELECT mq.new_qs_expr_msg_action_id, q.msg, q.css_class
		  FROM csrimp.qs_expr_msg_action q, csrimp.map_qs_expr_msg_action mq
		 WHERE q.qs_expr_msg_action_id = mq.old_qs_expr_msg_action_id;

	INSERT INTO csr.qs_expr_non_compl_action (qs_expr_non_compl_action_id, assign_to_role_sid,
		due_dtm_abs, due_dtm_relative, due_dtm_relative_unit, title, detail, send_email_on_creation,
		non_comp_default_id, non_compliance_type_id)
		SELECT mq.new_qs_expr_nc_action_id, mr.new_sid, q.due_dtm_abs,
			   q.due_dtm_relative, q.due_dtm_relative_unit, q.title, q.detail,
			   q.send_email_on_creation, mncd.new_non_comp_default_id,
			   mnct.new_non_compliance_type_id
		  FROM csrimp.qs_expr_non_compl_action q, csrimp.map_qs_expr_nc_action mq,
		  	   csrimp.map_sid mr, csrimp.map_non_comp_default mncd,
			   csrimp.map_non_compliance_type mnct
		 WHERE q.qs_expr_non_compl_action_id = mq.old_qs_expr_nc_action_id
		   AND q.assign_to_role_sid = mr.old_sid(+)
		   AND q.non_comp_default_id = mncd.old_non_comp_default_id(+)
		   AND q.non_compliance_type_id = mnct.old_non_compliance_type_id(+);

	INSERT INTO csr.non_compliance_expr_action (non_compliance_id, qs_expr_non_compl_action_id, survey_response_id)
		SELECT mnc.new_non_compliance_id, mncea.new_qs_expr_nc_action_id, mqsr.new_survey_response_id
		  FROM csrimp.non_compliance_expr_action ncea, csrimp.map_qs_expr_nc_action mncea,
		   	   csrimp.map_qs_survey_response mqsr, csrimp.map_non_compliance mnc
		 WHERE ncea.non_compliance_id = mnc.old_non_compliance_id
		   AND ncea.qs_expr_non_compl_action_id = mncea.old_qs_expr_nc_action_id
		   AND ncea.survey_response_id = mqsr.old_survey_response_id;

	INSERT INTO csr.quick_survey_expr_action (quick_survey_expr_action_id, action_type,
		survey_sid, expr_id, qs_expr_non_compl_action_id, qs_expr_msg_action_id,
		show_question_id, mandatory_question_id, show_page_id, survey_version, show_question_version, mandatory_question_version, show_page_version, issue_template_id)
    	SELECT csr.qs_expr_action_id_seq.nextval, q.action_type, ms.new_sid, mq.new_expr_id,
			   mqnc.new_qs_expr_nc_action_id, mqe.new_qs_expr_msg_action_id,
			   mqq.new_question_id, mqq2.new_question_id, mqq3.new_question_id, q.survey_version, q.show_question_version, q.mandatory_question_version, q.show_page_version,
			   mit.new_issue_template_id
		  FROM csrimp.quick_survey_expr_action q, csrimp.map_sid ms, csrimp.map_qs_expr mq,
		  	   csrimp.map_qs_expr_nc_action mqnc, csrimp.map_qs_expr_msg_action mqe,
		  	   csrimp.map_qs_question mqq, csrimp.map_qs_question mqq2, csrimp.map_qs_question mqq3,
			   csrimp.map_issue_template mit
		 WHERE q.survey_sid = ms.old_sid
		   AND q.expr_id = mq.old_expr_id(+)
		   AND q.qs_expr_non_compl_action_id = mqnc.old_qs_expr_nc_action_id(+)
		   AND q.qs_expr_msg_action_id = mqe.old_qs_expr_msg_action_id(+)
		   AND q.show_question_id = mqq.old_question_id(+)
		   AND q.mandatory_question_id = mqq2.old_question_id(+)
		   AND q.show_page_id = mqq3.old_question_id(+)
		   AND q.issue_template_id = mit.old_issue_template_id(+);

	INSERT INTO csr.qs_expr_nc_action_involve_role (qs_expr_non_compl_action_id, involve_role_sid)
		SELECT mnca.new_qs_expr_nc_action_id, mr.new_sid
		  FROM csrimp.qs_expr_nc_action_involve_role q, csrimp.map_qs_expr_nc_action mnca,
		  	   csrimp.map_sid mr
		 WHERE q.qs_expr_non_compl_action_id = mnca.old_qs_expr_nc_action_id
		   AND q.involve_role_sid = mr.old_sid;

	INSERT INTO csr.region_survey_response (survey_sid, survey_response_id, region_sid,
		period_start_dtm, period_end_dtm)
		SELECT ms.new_sid, msr.new_survey_response_id, mr.new_sid, rsr.period_start_dtm,
			   rsr.period_end_dtm
		  FROM csrimp.region_survey_response rsr, csrimp.map_sid ms,
		  	   csrimp.map_qs_survey_response msr, csrimp.map_sid mr
		 WHERE rsr.survey_sid = ms.old_sid
		   AND rsr.survey_response_id = msr.old_survey_response_id
		   AND rsr.region_sid = mr.old_sid;

END;

PROCEDURE CreateQuickSurveyFilters
AS
BEGIN
	INSERT INTO csr.qs_filter_condition (filter_id, qs_filter_condition_id,
		question_id, question_version, comparator, compare_to_str_val, compare_to_num_val,
		compare_to_option_id, survey_version, survey_sid, pos, qs_campaign_sid)
		SELECT mf.new_filter_id, csr.qs_filter_condition_id_seq.NEXTVAL, mq.new_question_id, fc.question_version,
			   fc.comparator, fc.compare_to_str_val, fc.compare_to_num_val,
			   mqo.new_question_option_id, fc.survey_version, mss.new_sid, fc.pos, mcs.new_sid
		  FROM csrimp.qs_filter_condition fc
		  JOIN csrimp.map_chain_filter mf ON fc.filter_id = mf.old_filter_id
		  JOIN csrimp.map_qs_question mq ON fc.question_id = mq.old_question_id
		  LEFT JOIN csrimp.map_qs_question_option mqo ON fc.compare_to_option_id = mqo.old_question_option_id
		  JOIN csrimp.map_sid mss ON fc.survey_sid = mss.old_sid
		  LEFT JOIN csrimp.map_sid mcs ON fc.qs_campaign_sid = mcs.old_sid;

	INSERT INTO csr.qs_filter_condition_general (filter_id, qs_filter_condition_general_id, survey_sid,
		qs_filter_cond_gen_type_id, comparator, compare_to_str_val, compare_to_num_val, pos, qs_campaign_sid)
		SELECT mf.new_filter_id, csr.qs_filter_condition_gen_id_seq.NEXTVAL, mss.new_sid, qs_filter_cond_gen_type_id,
			   comparator, compare_to_str_val, compare_to_num_val, pos, ms.new_sid
		  FROM csrimp.qs_filter_condition_general qfcg
		  JOIN csrimp.map_sid mss ON qfcg.survey_sid = mss.old_sid
		  JOIN csrimp.map_chain_filter mf ON qfcg.filter_id = mf.old_filter_id
		  LEFT JOIN csrimp.map_sid ms ON qfcg.qs_campaign_sid = ms.old_sid;
END;

PROCEDURE CreateRegionSets
AS
BEGIN
	INSERT INTO csr.region_set (region_set_id, owner_sid, name, disposal_dtm)
		SELECT mr.new_region_set_id, mo.new_sid, rs.name, rs.disposal_dtm
		  FROM csrimp.region_set rs, csrimp.map_region_set mr,
		  	   csrimp.map_sid mo
		 WHERE rs.region_set_id = mr.old_region_set_id
		   AND rs.owner_sid = mo.old_sid(+);

	INSERT INTO csr.region_set_region (region_set_id, region_sid, pos)
		SELECT mrsr.new_region_set_id, mr.new_sid, rsr.pos
		  FROM csrimp.region_set_region rsr, csrimp.map_region_set mrsr,
		  	   csrimp.map_sid mr
		 WHERE rsr.region_set_id = mrsr.old_region_set_id
		   AND rsr.region_sid = mr.old_sid;
END;

PROCEDURE CreateIndSets
AS
BEGIN
	INSERT INTO csr.ind_set (
				ind_set_id,
				disposal_dtm,
				name,
				owner_sid
	   ) SELECT mis.new_ind_set_id,
				iset.disposal_dtm,
				iset.name,
				ms.new_sid
		   FROM csrimp.ind_set iset,
				csrimp.map_ind_set mis,
				csrimp.map_sid ms
		  WHERE iset.ind_set_id = mis.old_ind_set_id
			AND iset.owner_sid = ms.old_sid(+);

	INSERT INTO csr.ind_set_ind (
				ind_set_id,
				ind_sid,
				pos
	   ) SELECT mis.new_ind_set_id,
				ms.new_sid,
				isi.pos
		   FROM csrimp.ind_set_ind isi,
				csrimp.map_ind_set mis,
				csrimp.map_sid ms
		  WHERE isi.ind_set_id = mis.old_ind_set_id
			AND isi.ind_sid = ms.old_sid;
END;

PROCEDURE CreateScenarios
AS
BEGIN
	INSERT INTO csr.scenario (scenario_sid, description, start_dtm, end_dtm, period_set_id,
		period_interval_id, equality_epsilon, file_based, auto_update_run_sid, recalc_trigger_type,
		data_source, data_source_sp, data_source_sp_args, data_source_run_sid, created_by_user_sid,
		created_dtm, include_all_inds, dont_run_aggregate_indicators)
		SELECT ms.new_sid, s.description, s.start_dtm, s.end_dtm, s.period_set_id, s.period_interval_id,
			   s.equality_epsilon, s.file_based,
			   null /* auto_update_run_sid - set after scenario_run */,
			   s.recalc_trigger_type, s.data_source, s.data_source_sp, s.data_source_sp_args,
			   null /* data_source_run_sid -- set after scenario run */,
			   mu.new_sid, s.created_dtm, s.include_all_inds, s.dont_run_aggregate_indicators
		  FROM csrimp.scenario s
		  JOIN csrimp.map_sid ms ON s.scenario_sid = ms.old_sid
		  JOIN csrimp.map_sid mu ON s.created_by_user_sid = mu.old_sid;

	-- fix helper procedures to point at any remapped cms schemas
	UPDATE csr.scenario
	   SET data_source_sp = MapCustomerSchema(data_source_sp)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO csr.scenario_email_sub (scenario_sid, csr_user_sid)
		SELECT ms.new_sid, mu.new_sid
		  FROM csrimp.scenario_email_sub ses
		  JOIN csrimp.map_sid ms ON ses.scenario_sid = ms.old_sid
		  JOIN csrimp.map_sid mu ON ses.csr_user_sid = mu.old_sid;

	INSERT INTO csr.scenario_ind (scenario_sid, ind_sid)
		SELECT ms.new_sid, mi.new_sid
		  FROM csrimp.scenario_ind si, csrimp.map_sid ms,
		  	   csrimp.map_sid mi
		 WHERE si.scenario_sid = ms.old_sid
		   AND si.ind_sid = mi.old_sid;

	INSERT INTO csr.scenario_region (scenario_sid, region_sid)
		SELECT ms.new_sid, mr.new_sid
		  FROM csrimp.scenario_region sr, csrimp.map_sid ms,
		  	   csrimp.map_sid mr
		 WHERE sr.scenario_sid = ms.old_sid
		   AND sr.region_sid = mr.old_sid;

	INSERT INTO csr.scenario_options (show_chart, show_bau_option, bau_default)
		SELECT show_chart, show_bau_option, bau_default
		  FROM csrimp.scenario_options;

	INSERT INTO csr.scenario_rule (scenario_sid, rule_id, description,
		rule_type, amount, measure_conversion_id, start_dtm, end_dtm)
		SELECT ms.new_sid, sr.rule_id, sr.description, sr.rule_type, sr.amount,
			   mmc.new_measure_conversion_id, sr.start_dtm, sr.end_dtm
		  FROM csrimp.scenario_rule sr, csrimp.map_sid ms, csrimp.map_measure_conversion mmc
		 WHERE sr.scenario_sid = ms.old_sid
		   AND sr.measure_conversion_id = mmc.old_measure_conversion_id(+);

	INSERT INTO csr.scenario_rule_ind (scenario_sid, rule_id, ind_sid)
		SELECT ms.new_sid, sri.rule_id, mi.new_sid
		  FROM csrimp.scenario_rule_ind sri, csrimp.map_sid ms,
		  	   csrimp.map_sid mi
		 WHERE sri.scenario_sid = ms.old_sid
		   AND sri.ind_sid = mi.old_sid;

	INSERT INTO csr.scenario_rule_like_contig_ind (scenario_sid, rule_id, ind_sid)
		SELECT ms.new_sid, sri.rule_id, mi.new_sid
		  FROM csrimp.scenario_rule_like_contig_ind sri, csrimp.map_sid ms,
		  	   csrimp.map_sid mi
		 WHERE sri.scenario_sid = ms.old_sid
		   AND sri.ind_sid = mi.old_sid;

	INSERT INTO csr.forecasting_rule (scenario_sid, rule_id, ind_sid, region_sid, start_dtm,
		end_dtm, rule_type, rule_val)
		SELECT ms.new_sid, fr.rule_id, mi.new_sid, mr.new_sid, fr.start_dtm, fr.end_dtm,
			   fr.rule_type, fr.rule_val
		  FROM csrimp.forecasting_rule fr
		  JOIN csrimp.map_sid ms ON fr.scenario_sid = ms.old_sid
		  JOIN csrimp.map_sid mi ON fr.ind_sid = mi.old_sid
		  JOIN csrimp.map_sid mr ON fr.region_sid = mr.old_sid;

	INSERT INTO csr.scenario_rule_region (scenario_sid, rule_id, region_sid)
		SELECT ms.new_sid, srr.rule_id, mr.new_sid
		  FROM csrimp.scenario_rule_region srr, csrimp.map_sid ms,
		  	   csrimp.map_sid mr
		 WHERE srr.scenario_sid = ms.old_sid
		   AND srr.region_sid = mr.old_sid;

	INSERT INTO csr.scenario_run_version (scenario_run_sid, version)
		 SELECT ms.new_sid, srv.version
		   FROM csrimp.scenario_run_version srv
		   JOIN csrimp.map_sid ms
		     ON ms.old_sid = srv.scenario_run_sid;

	INSERT INTO csr.scenario_run_version_file (scenario_run_sid, version, file_path, sha1)
		 SELECT ms.new_sid, srvf.version, srvf.file_path, srvf.sha1
		   FROM csrimp.scenario_run_version_file srvf
		   JOIN csrimp.map_sid ms
		     ON ms.old_sid = srvf.scenario_run_sid;

	INSERT INTO csr.scenario_run (scenario_run_sid, scenario_sid, run_dtm, description,
		on_completion_sp, version, last_run_by_user_sid)
		SELECT msr.new_sid, ms.new_sid, sr.run_dtm, sr.description, sr.on_completion_sp,
			   sr.version, mu.new_sid
		  FROM csrimp.scenario_run sr, csrimp.map_sid msr, csrimp.map_sid ms,
		  	   csrimp.map_sid mu
		 WHERE sr.scenario_run_sid = msr.old_sid
		   AND sr.scenario_sid = ms.old_sid
		   AND sr.last_run_by_user_sid = mu.old_sid;

	MERGE INTO csr.scenario s
	USING (SELECT ms.new_sid scenario_sid, msr.new_sid run_sid
			 FROM csrimp.map_sid ms, csrimp.scenario os,
			  	  csrimp.map_sid msr
			WHERE ms.old_sid = os.scenario_sid
			  AND os.auto_update_run_sid = msr.old_sid) ms
	   ON (s.scenario_sid = ms.scenario_sid)
	 WHEN MATCHED THEN
		  UPDATE SET s.auto_update_run_sid = ms.run_sid;

	MERGE INTO csr.scenario s
	USING (SELECT ms.new_sid scenario_sid, msr.new_sid run_sid
			 FROM csrimp.map_sid ms, csrimp.scenario os,
			  	  csrimp.map_sid msr
			WHERE ms.old_sid = os.scenario_sid
			  AND os.data_source_run_sid = msr.old_sid) ms
	   ON (s.scenario_sid = ms.scenario_sid)
	 WHEN MATCHED THEN
		  UPDATE SET s.data_source_run_sid = ms.run_sid;

	INSERT INTO csr.scenario_run_val (scenario_run_sid, ind_sid, region_sid, period_start_dtm,
		period_end_dtm, val_number, error_code, source_type_id, source_id)
		SELECT msr.new_sid scenario_run_sid, mi.new_sid ind_sid, mr.new_sid region_sid, srv.period_start_dtm, srv.period_end_dtm,
			   srv.val_number, srv.error_code, srv.source_type_id,
			   CASE WHEN srv.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_IMPORT -- map source values in imports (invalid values go to null)
			        THEN miv.new_imp_val_id
			        WHEN srv.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_DELEGATION -- map source values in delegations (invalid values go to null)
			        THEN msv.new_sheet_value_id
			    	ELSE srv.source_id
			   END source_id
		  FROM csrimp.scenario_run_val srv
		  JOIN csrimp.map_sid msr ON srv.scenario_run_sid = msr.old_sid
		  JOIN csrimp.map_sid mi ON srv.ind_sid = mi.old_sid
		  JOIN csrimp.map_sid mr ON srv.region_sid = mr.old_sid
	 LEFT JOIN csrimp.map_sheet_value msv ON srv.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_DELEGATION AND srv.source_id = msv.old_sheet_value_id
	 LEFT JOIN csrimp.map_imp_val miv ON srv.source_type_id = csr.csr_data_pkg.SOURCE_TYPE_IMPORT AND srv.source_id = miv.old_imp_val_id;

	-- fix up customer.(un)merged_scenario_run_sid now that the row(s) exist
	UPDATE csr.customer c
	   SET c.unmerged_scenario_run_sid = (
	   		SELECT musr.new_sid
	   		  FROM csrimp.customer oc,
	   		  	   csrimp.map_sid musr
	   		 WHERE oc.unmerged_scenario_run_sid = musr.old_sid),
	   	   c.merged_scenario_run_sid = (
	   		SELECT musr.new_sid
	   		  FROM csrimp.customer oc,
	   		  	   csrimp.map_sid musr
	   		 WHERE oc.merged_scenario_run_sid = musr.old_sid);
END;

PROCEDURE CreateTargetDashboards
AS
BEGIN
	INSERT INTO csr.target_dashboard (target_dashboard_sid, start_dtm, end_dtm, period_set_id,
		period_interval_id, name, parent_sid, use_root_region_sid)
		SELECT mtd.new_sid, td.start_dtm, td.end_dtm, td.period_set_id, td.period_interval_id,
			   td.name, mtp.new_sid, td.use_root_region_sid
		  FROM csrimp.target_dashboard td, csrimp.map_sid mtd, csrimp.map_sid mtp
		 WHERE td.target_dashboard_sid = mtd.old_sid
		   AND td.parent_sid = mtp.old_sid;

	INSERT INTO csr.target_dashboard_ind_member (target_dashboard_sid, target_ind_sid, ind_sid, pos)
		SELECT mtd.new_sid, mti.new_sid, mi.new_sid, tdi.pos
		  FROM csrimp.target_dashboard_ind_member tdi, csrimp.map_sid mtd,
			   csrimp.map_sid mti, csrimp.map_sid mi
		 WHERE tdi.target_dashboard_sid = mtd.old_sid
		   AND tdi.target_ind_sid = mti.old_sid(+)
		   AND tdi.ind_sid = mi.old_sid;

	INSERT INTO csr.target_dashboard_reg_member (target_dashboard_sid, region_sid, pos)
		SELECT mtd.new_sid, mr.new_sid, tdr.pos
		  FROM csrimp.target_dashboard_reg_member tdr, csrimp.map_sid mtd,
			   csrimp.map_sid mr
		 WHERE tdr.target_dashboard_sid = mtd.old_sid
		   AND tdr.region_sid = mr.old_sid;

	INSERT INTO csr.target_dashboard_value (target_dashboard_sid, ind_sid, region_sid, val_number)
		SELECT mtd.new_sid, mi.new_sid, mr.new_sid, tdv.val_number
		  FROM csrimp.target_dashboard_value tdv, csrimp.map_sid mtd, csrimp.map_sid mi,
		  	   csrimp.map_sid mr
		 WHERE tdv.target_dashboard_sid = mtd.old_sid
		   AND tdv.ind_sid = mi.old_sid
		   AND tdv.region_sid = mr.old_sid;
END;

PROCEDURE CreateAuditLog
AS
BEGIN
	-- XXX: not sure what to do with sub_object_id -- need to figure out where it's used
	INSERT INTO csr.audit_log (audit_date, audit_type_id, object_sid, user_sid,
		description, param_1, param_2, param_3, sub_object_id, remote_addr)
		SELECT /*+ALL_ROWS CARDINALITY(al, 1000000) CARDINALITY(mo, 50000) CARDINALITY(mu, 50000)*/
			   al.audit_date, al.audit_type_id, mo.new_sid, mu.new_sid, al.description,
			   al.param_1, al.param_2, al.param_3, al.sub_object_id, al.remote_addr
		  FROM csrimp.audit_log al, csrimp.map_sid mo, csrimp.map_sid mu
		 WHERE al.object_sid = mo.old_sid(+)
		   AND al.user_sid = mu.old_sid;
	
	-- This is here rather than with the other aggregate ind stuff because it needs the
	-- users to have been created. It creates the ind, etc, first presumably so that the 
	-- start points can be set when the users then get created.
	INSERT INTO csr.aggregate_ind_group_audit_log
		(aggregate_ind_group_id, change_dtm, change_description, changed_by_user_sid)
		SELECT mag.new_aggregate_ind_group_id, log.change_dtm, log.change_description, ms.new_sid
		  FROM csrimp.aggregate_ind_group_audit_log log, csrimp.map_aggregate_ind_group mag, csrimp.map_sid ms
		 WHERE log.aggregate_ind_group_id = mag.old_aggregate_ind_group_id
		   AND log.changed_by_user_sid = ms.old_sid;
END;

PROCEDURE CreateTrash
AS
BEGIN
	INSERT INTO csr.trash (trash_sid, trash_can_sid, trashed_by_sid, trashed_dtm,
		previous_parent_sid, description, so_name)
		SELECT mt.new_sid, mtc.new_sid, mtu.new_sid, t.trashed_dtm, mpp.new_sid,
			   t.description, t.so_name
		  FROM csrimp.trash t, csrimp.map_sid mt, csrimp.map_sid mtc,
		  	   csrimp.map_sid mtu, csrimp.map_sid mpp
		 WHERE t.trash_sid = mt.old_sid
		   AND t.trash_can_sid = mtc.old_sid
		   AND t.trashed_by_sid = mtu.old_sid(+)
		   AND t.previous_parent_sid = mpp.old_sid;
END;

PROCEDURE CreateTemplates
AS
BEGIN
	INSERT INTO csr.template (template_type_id, data, mime_type, uploaded_dtm, uploaded_by_sid)
		SELECT t.template_type_id, t.data, t.mime_type, t.uploaded_dtm, mu.new_sid
		  FROM csrimp.template t, csrimp.map_sid mu
		 WHERE t.uploaded_by_sid = mu.old_sid;
END;

PROCEDURE CreateExportFeeds
AS
BEGIN
	INSERT INTO csr.export_feed (export_feed_sid, name, protocol, url, interval,
		start_dtm, end_dtm, last_success_attempt_dtm, last_attempt_dtm, secure_creds)
		SELECT mef.new_sid, ef.name, ef.protocol, ef.url, ef.interval,
			   ef.start_dtm, ef.end_dtm, ef.last_success_attempt_dtm, ef.last_attempt_dtm, ef.secure_creds
		  FROM csrimp.export_feed ef
		  JOIN csrimp.map_sid mef ON ef.export_feed_sid = mef.old_sid;

	INSERT INTO csr.export_feed_cms_form (export_feed_sid, form_sid, filename_mask, format, incremental)
		SELECT mef.new_sid, mcf.new_sid, ef.filename_mask, ef.format, ef.incremental
		  FROM csrimp.export_feed_cms_form ef
		  JOIN csrimp.map_sid mef ON ef.export_feed_sid = mef.old_sid
		  JOIN csrimp.map_sid mcf ON ef.form_sid = mcf.old_sid;

	INSERT INTO csr.export_feed_dataview (export_feed_sid, dataview_sid, filename_mask, format, assembly_name)
		SELECT mef.new_sid, mcf.new_sid, ef.filename_mask, ef.format, ef.assembly_name
		  FROM csrimp.export_feed_dataview ef
		  JOIN csrimp.map_sid mef ON ef.export_feed_sid = mef.old_sid
		  JOIN csrimp.map_sid mcf ON ef.dataview_sid = mcf.old_sid;

	INSERT INTO csr.export_feed_stored_proc (export_feed_sid, sp_name, sp_params, filename_mask, format)
		SELECT mef.new_sid, ef.sp_name, ef.sp_params, ef.filename_mask, ef.format
		  FROM csrimp.export_feed_stored_proc ef
		  JOIN csrimp.map_sid mef ON ef.export_feed_sid = mef.old_sid;
END;

PROCEDURE CreateAlertBounceTrack
AS
BEGIN
	INSERT INTO csr.alert (alert_id, to_user_sid, to_email_address, sent_dtm, subject, message)
		SELECT ma.new_alert_id, mu.new_sid, a.to_email_address, a.sent_dtm, a.subject, a.message
		  FROM csrimp.alert a, csrimp.map_alert ma, csrimp.map_sid mu
		 WHERE a.alert_id = ma.old_alert_id
		   AND a.to_user_sid = mu.old_sid(+);

	INSERT INTO csr.alert_bounce (alert_bounce_id, alert_id, received_dtm, message)
		SELECT csr.alert_bounce_id_seq.nextval, ma.new_alert_id, ab.received_dtm, ab.message
		  FROM csrimp.alert_bounce ab, csrimp.map_alert ma
		 WHERE ab.alert_id = ma.old_alert_id;
END;

PROCEDURE CreateRegionMetrics
AS
BEGIN
	INSERT INTO csr.region_metric (ind_sid, measure_sid, is_mandatory, show_measure)
		 SELECT mi.new_sid, mm.new_sid, is_mandatory, show_measure
		   FROM csrimp.region_metric rm,
				csrimp.map_sid mi,
				csrimp.map_sid mm
		  WHERE rm.ind_sid = mi.old_sid
		    AND rm.measure_sid = mm.old_sid;

	INSERT INTO csr.region_type_metric(region_type, ind_sid)
		 SELECT rtm.region_type, mi.new_sid
		   FROM csrimp.region_type_metric rtm,
				csrimp.map_sid mi
		  WHERE rtm.ind_sid = mi.old_sid;

	INSERT INTO csr.region_metric_val (region_metric_val_id, region_sid, ind_sid, val,
									   effective_dtm, entered_by_sid, entered_dtm, note,
									   measure_sid, source_type_id, entry_measure_conversion_id, entry_val)
		SELECT mrmv.new_region_metric_val_id, mr.new_sid, mi.new_sid, rmv.val,
			   rmv.effective_dtm, mu.new_sid, rmv.entered_dtm, rmv.note,
			   mm.new_sid, rmv.source_type_id, mmc.new_measure_conversion_id, rmv.entry_val
		  FROM csrimp.region_metric_val rmv
			   JOIN csrimp.map_region_metric_val mrmv ON rmv.region_metric_val_id = mrmv.old_region_metric_val_id
			   JOIN csrimp.map_sid mr ON rmv.region_sid = mr.old_sid
			   JOIN csrimp.map_sid mi ON rmv.ind_sid = mi.old_sid
			   JOIN csrimp.map_sid mu ON rmv.entered_by_sid = mu.old_sid
			   JOIN csrimp.map_sid mm ON rmv.measure_sid = mm.old_sid
		  LEFT JOIN csrimp.map_measure_conversion mmc ON rmv.entry_measure_conversion_id = mmc.old_measure_conversion_id;
END;

PROCEDURE CreatePropertyOptions
AS
BEGIN
	INSERT INTO csr.geo_map (geo_map_sid, label, region_selection_type_id, include_inactive_regions,
							 start_dtm, end_dtm, interval, tag_id)
		SELECT gms.new_sid, gm.label, gm.region_selection_type_id, gm.include_inactive_regions, gm.start_dtm,
			   gm.end_dtm, gm.interval, mt.new_tag_id
		  FROM csrimp.geo_map gm
		  LEFT JOIN csrimp.map_sid gms ON gm.geo_map_sid = gms.old_sid
		  LEFT JOIN csrimp.map_tag mt ON gm.tag_id = mt.old_tag_id;

	INSERT INTO csr.geo_map_region (geo_map_sid, region_sid)
		SELECT mgm.new_sid, mr.new_sid
		  FROM csrimp.geo_map_region gmr
		  JOIN csrimp.map_sid mgm ON gmr.geo_map_sid = mgm.old_sid
		  JOIN csrimp.map_sid mr ON gmr.region_sid = mr.old_sid;

		  INSERT INTO csr.customer_geo_map_tab_type (
				geo_map_tab_type_id
	   ) SELECT cgmtt.geo_map_tab_type_id
		   FROM csrimp.customer_geo_map_tab_type cgmtt;

	INSERT INTO csr.property_options (property_helper_pkg, properties_geo_map_sid,
									  enable_multi_fund_ownership, gresb_service_config,
									  auto_assign_manager, show_inherited_roles)
		 SELECT po.property_helper_pkg, gms.new_sid, po.enable_multi_fund_ownership,
				po.gresb_service_config, po.auto_assign_manager, show_inherited_roles
		   FROM csrimp.property_options po
		   LEFT JOIN csrimp.map_sid gms ON po.properties_geo_map_sid = gms.old_sid;

	INSERT INTO csr.property_element_layout (element_name, pos, ind_sid, tag_group_id)
		 SELECT pel.element_name, pel.pos, ms.new_sid, mtg.new_tag_group_id
		   FROM csrimp.property_element_layout pel
		   LEFT JOIN csrimp.map_sid ms ON pel.ind_sid = ms.old_sid
		   LEFT JOIN csrimp.map_tag_group mtg ON pel.tag_group_id = mtg.old_tag_group_id;

	INSERT INTO csr.property_character_layout (element_name, pos, col, ind_sid, tag_group_id)
		 SELECT pcl.element_name, pcl.pos, pcl.col, ms.new_sid, mtg.new_tag_group_id
		   FROM csrimp.property_character_layout pcl
		   LEFT JOIN csrimp.map_sid ms ON pcl.ind_sid = ms.old_sid
		   LEFT JOIN csrimp.map_tag_group mtg ON pcl.tag_group_id = mtg.old_tag_group_id;

	INSERT INTO csr.property_address_options (element_name, mandatory)
		 SELECT element_name, mandatory
		   FROM csrimp.property_address_options;

	INSERT INTO csr.property_tab (plugin_id, plugin_type_id, pos, tab_label)
		 SELECT mp.new_plugin_id, pt.plugin_type_id, pt.pos, pt.tab_label
		   FROM csrimp.property_tab pt, csrimp.map_plugin mp
		  WHERE pt.plugin_id = mp.old_plugin_id;

	INSERT INTO csr.property_tab_group (plugin_id, group_sid, role_sid)
		 SELECT mp.new_plugin_id, mg.new_sid, mr.new_sid
		   FROM csrimp.property_tab_group ptg, csrimp.map_sid mg,
				csrimp.map_sid mr, csrimp.map_plugin mp
		  WHERE ptg.plugin_id = mp.old_plugin_id
			AND ptg.group_sid = mg.old_sid(+)
		    AND ptg.role_sid = mr.old_sid(+);
END;

PROCEDURE CreateProperties
AS
BEGIN
	INSERT INTO csr.mgmt_company (mgmt_company_id, name, company_sid)
		 SELECT mmc.new_mgmt_company_id, mc.name, ms.new_sid
		   FROM csrimp.mgmt_company mc,
				csrimp.map_mgmt_company mmc,
				csrimp.map_sid ms
		  WHERE mc.mgmt_company_id = mmc.old_mgmt_company_id
			AND mc.company_sid = ms.old_sid(+);

	INSERT INTO csr.mgmt_company_contact (mgmt_company_contact_id, mgmt_company_id, name, email, phone)
		 SELECT mmcc.new_mgmt_company_contact_id, mmc.new_mgmt_company_id,
			    mcc.name, mcc.email, mcc.phone
		   FROM csrimp.mgmt_company_contact mcc,
			    csrimp.map_mgmt_company_contact mmcc,
			    csrimp.map_mgmt_company mmc
		  WHERE mcc.mgmt_company_contact_id = mmcc.old_mgmt_company_contact_id
		    AND mcc.mgmt_company_id = mmc.old_mgmt_company_id;

	INSERT INTO csr.fund_type (fund_type_id, label)
		 SELECT mft.new_fund_type_id, ft.label
		   FROM csrimp.fund_type ft, csrimp.map_fund_type mft
		  WHERE ft.fund_type_id = mft.old_fund_type_id;

	INSERT INTO csr.fund (fund_id, fund_type_id, company_sid,
			    name, year_of_inception, default_mgmt_company_id,
			    mgr_contact_name, mgr_contact_email, mgr_contact_phone, region_sid)
		 SELECT mf.new_fund_id, mft.new_fund_type_id, ms.new_sid,
				f.name, f.year_of_inception, mmc.new_mgmt_company_id,
			    f.mgr_contact_name, f.mgr_contact_email, f.mgr_contact_phone,
				mr.new_sid
		   FROM csrimp.fund f
		   JOIN csrimp.map_fund mf ON f.fund_id = mf.old_fund_id
		   LEFT JOIN csrimp.map_fund_type mft ON f.fund_Type_id = mft.old_fund_type_id
		   LEFT JOIN csrimp.map_mgmt_company mmc ON f.default_mgmt_company_id = mmc.old_mgmt_company_id
		   LEFT JOIN csrimp.map_sid ms ON f.company_sid = ms.old_sid
		   LEFT JOIN csrimp.map_sid mr ON f.region_sid = mr.old_sid;

	INSERT INTO csr.fund_form_plugin (plugin_id, pos, xml_path, key_name)
		 SELECT mp.new_plugin_id, ffp.pos, ffp.xml_path, ffp.key_name
		   FROM csrimp.fund_form_plugin ffp, csrimp.map_plugin mp
		  WHERE ffp.plugin_id = mp.old_plugin_id;

	INSERT INTO csr.mgmt_company_fund_contact (mgmt_company_contact_id, mgmt_company_id, fund_id)
		 SELECT mmcc.new_mgmt_company_contact_id, mmc.new_mgmt_company_id, mf.new_fund_id
		   FROM csrimp.mgmt_company_fund_contact mcfc,
			    csrimp.map_mgmt_company_contact mmcc,
			    csrimp.map_mgmt_company mmc,
		        csrimp.map_fund mf
		  WHERE mcfc.fund_id = mf.old_fund_id
		    AND mcfc.mgmt_company_contact_id = mmcc.old_mgmt_company_contact_id
		    AND mcfc.mgmt_company_id = mmc.old_mgmt_company_id;

	INSERT INTO csr.tenant (tenant_id, name)
		 SELECT mt.new_tenant_id, t.name
		   FROM csrimp.tenant t, csrimp.map_tenant mt
		  WHERE t.tenant_id = mt.old_tenant_id;

	INSERT INTO csr.lease_type (lease_type_id)
		 SELECT mlt.new_lease_type_id
		   FROM csrimp.lease_type lt, csrimp.map_lease_type mlt
		  WHERE lt.lease_type_id = mlt.old_lease_type_id;

	INSERT INTO csr.lease (lease_id, tenant_id, start_dtm, end_dtm, next_break_dtm,
						   current_rent, normalised_rent, currency_code, next_rent_review)
		 SELECT ml.new_lease_id, mt.new_tenant_id,
			    l.start_dtm, l.end_dtm, l.next_break_dtm,
			    l.current_rent, l.normalised_rent, l.currency_code, l.next_rent_review
		   FROM csrimp.lease l,
			    csrimp.map_lease ml,
			    csrimp.map_tenant mt
		  WHERE l.lease_id = ml.old_lease_id
		    AND l.tenant_id = mt.old_tenant_id;

	INSERT INTO csr.lease_postit (lease_id, postit_id)
		 SELECT ml.new_lease_id, mp.new_postit_id
		   FROM csrimp.lease_postit lp,
			    csrimp.map_lease ml,
			    csrimp.map_postit mp
		  WHERE lp.lease_id = ml.old_lease_id
		    AND lp.postit_id = mp.old_postit_id;

	INSERT INTO csr.property_type (property_type_id, label, lookup_key, gresb_property_type_id)
		 SELECT mpt.new_property_type_id, pt.label, pt.lookup_key, pt.gresb_property_type_id
		   FROM csrimp.property_type pt, csrimp.map_property_type mpt
		  WHERE pt.property_type_id = mpt.old_property_type_id;

	INSERT INTO csr.property_sub_type (property_sub_type_id, property_type_id, label, gresb_property_type_id, gresb_property_sub_type_id)
		 SELECT mpst.new_sub_property_type_id, mpt.new_property_type_id, pst.label, pst.gresb_property_type_id, pst.gresb_property_sub_type_id
		   FROM csrimp.property_sub_type pst,
			    csrimp.map_sub_property_type mpst,
			    csrimp.map_property_type mpt
		  WHERE pst.property_sub_type_id = mpst.old_sub_property_type_id
		    AND pst.property_type_id = mpt.old_property_type_id;

	INSERT INTO csr.space_type (space_type_id, label, is_tenantable)
		 SELECT mst.new_space_type_id, st.label, st.is_tenantable
		   FROM csrimp.space_type st, csrimp.map_space_type mst
		  WHERE st.space_type_id = mst.old_space_type_id;

	INSERT INTO csr.space_type_region_metric (space_type_id, ind_sid, region_type)
		 SELECT mst.new_space_type_id, mi.new_sid, strm.region_type
		   FROM csrimp.space_type_region_metric strm,
			    csrimp.map_space_type mst,
			    csrimp.map_sid mi
		  WHERE strm.space_type_id = mst.old_space_type_id
		    AND strm.ind_sid = mi.old_sid;

	INSERT INTO csr.property_type_space_type (
				property_type_id,
				space_type_id,
				is_hidden
	   ) SELECT mpt.new_property_type_id,
				mst.new_space_type_id,
				ptst.is_hidden
		   FROM csrimp.property_type_space_type ptst,
				csrimp.map_property_type mpt,
				csrimp.map_space_type mst
		  WHERE ptst.property_type_id = mpt.old_property_type_id
			AND ptst.space_type_id = mst.old_space_type_id;

	INSERT INTO csr.all_property(region_sid, property_type_id, property_sub_type_id, company_sid,
						     mgmt_company_id, mgmt_company_other, mgmt_company_contact_id,
						     current_lease_id, pm_building_id,
						     street_addr_1, city, state, postcode, flow_item_id, street_addr_2)
		 SELECT mr.new_sid, mpt.new_property_type_id, mpst.new_sub_property_type_id, ms.new_sid,
				mmc.new_mgmt_company_id, p.mgmt_company_other, mmcc.new_mgmt_company_contact_id,
				ml.new_lease_id, p.pm_building_id,
				p.street_addr_1, p.city, p.state, p.postcode, mfi.new_flow_item_id, p.street_addr_2
		   FROM csrimp.property p,
				csrimp.map_sid mr,
			    csrimp.map_property_type mpt,
			    csrimp.map_sub_property_type mpst,
			    csrimp.map_mgmt_company mmc,
			    csrimp.map_mgmt_company_contact mmcc,
		        csrimp.map_lease ml,
				csrimp.map_flow_item mfi,
				csrimp.map_sid ms
		  WHERE p.region_sid = mr.old_sid
			AND p.property_type_id = mpt.old_property_type_id
		    AND p.property_sub_type_id = mpst.old_sub_property_type_id(+)
		    AND p.mgmt_company_id = mmc.old_mgmt_company_id(+)
		    AND p.mgmt_company_contact_id = mmcc.old_mgmt_company_contact_id(+)
			AND p.current_lease_id = ml.new_lease_id(+)
			AND p.flow_item_id = mfi.old_flow_item_id(+)
			AND p.company_sid = ms.old_sid(+);

	INSERT INTO csr.all_space (region_sid, space_type_id, property_region_sid, property_type_id, current_lease_id)
		 SELECT mr.new_sid, mst.new_space_type_id, mpr.new_sid, mpt.new_property_type_id, ml.new_lease_id
		   FROM csrimp.space s,
				csrimp.map_sid mr,
				csrimp.map_space_type mst,
				csrimp.map_sid mpr,
				csrimp.map_property_type mpt,
				csrimp.map_lease ml
		  WHERE s.region_sid = mr.old_sid
		    AND s.space_type_id = mst.old_space_type_id
			AND s.property_region_sid = mpr.old_sid
			AND s.property_type_id = mpt.old_property_type_id
			AND s.current_lease_id = ml.old_lease_id(+);

	INSERT INTO csr.lease_property (lease_id, property_region_sid)
		 SELECT ml.new_lease_id, mr.new_sid
		   FROM csrimp.lease_property lp,
				csrimp.map_lease ml,
				csrimp.map_sid mr
		  WHERE lp.lease_id = ml.old_lease_id
		    AND lp.property_region_sid = mr.old_sid;

	INSERT INTO csr.lease_space (lease_id, space_region_sid)
		 SELECT ml.new_lease_id, mr.new_sid
		   FROM csrimp.lease_space ls,
				csrimp.map_lease ml,
				csrimp.map_sid mr
		  WHERE ls.lease_id = ml.old_lease_id
		    AND ls.space_region_sid = mr.old_sid;

	INSERT INTO csr.property_photo (property_photo_id, property_region_sid, space_region_sid,
									filename, mime_type, data)
		 SELECT mpp.new_property_photo_id, mpr.new_sid, msr.new_sid,
			    pp.filename, pp.mime_type, pp.data
		   FROM csrimp.property_photo pp,
			    csrimp.map_property_photo mpp,
			    csrimp.map_sid mpr,
			    csrimp.map_sid msr
		  WHERE pp.property_photo_id = mpp.old_property_photo_id
		    AND pp.property_region_sid = mpr.old_sid
		    AND pp.space_region_sid(+) = msr.old_sid;

	INSERT INTO csr.gresb_indicator_mapping (gresb_indicator_id, ind_sid, measure_conversion_id, not_applicable)
	     SELECT gim.gresb_indicator_id, mi.new_sid, mmc.new_measure_conversion_id, gim.not_applicable
		   FROM csrimp.gresb_indicator_mapping gim,
		   		csrimp.map_sid mi,
				csrimp.map_measure_conversion mmc
		  WHERE gim.ind_sid = mi.old_sid
			AND gim.measure_conversion_id = mmc.old_measure_conversion_id(+);

	INSERT INTO csr.gresb_submission_log
			(gresb_submission_id, gresb_response_id, gresb_entity_id, gresb_asset_id, submission_type, submission_date, request_data, response_data)
		 SELECT mgsl.new_gresb_submission_id, gsl.gresb_response_id, gsl.gresb_entity_id, gsl.gresb_asset_id, gsl.submission_type, gsl.submission_date, gsl.request_data, gsl.response_data
		   FROM csrimp.gresb_submission_log gsl
		   JOIN csrimp.map_gresb_submission_log mgsl
			 ON mgsl.old_gresb_submission_id = gsl.gresb_submission_id;

	INSERT INTO csr.property_fund (region_sid, fund_id, container_sid)
		 SELECT mr.new_sid, mf.new_fund_id, mc.new_sid
		   FROM csrimp.property_fund pf
		   JOIN map_sid mr ON mr.old_sid = pf.region_sid
		   JOIN map_fund mf ON mf.old_fund_id = pf.fund_id
		   LEFT JOIN map_sid mc ON mc.old_sid = pf.container_sid;

	INSERT INTO csr.property_fund_ownership (region_sid, fund_id, start_dtm, ownership)
		 SELECT mr.new_sid, mf.new_fund_id, pfo.start_dtm, pfo.ownership
		   FROM csrimp.property_fund_ownership pfo
		   JOIN map_sid mr ON mr.old_sid = pfo.region_sid
		   JOIN map_fund mf ON mf.old_fund_id = pfo.fund_id;

	INSERT INTO csr.region_score_log (region_score_log_id, region_sid, score_type_id, score_threshold_id, score, set_dtm,
				changed_by_user_sid, comment_text)
		 SELECT mrs.new_region_score_log_id, mr.new_sid, mst.new_score_type_id, mstr.new_score_threshold_id, rsl.score,
		        rsl.set_dtm, mu.new_sid, rsl.comment_text
		   FROM csrimp.region_score_log rsl
		   JOIN csrimp.map_region_score_log mrs ON rsl.region_score_log_id = mrs.old_region_score_log_id
		   JOIN csrimp.map_sid mr ON rsl.region_sid = mr.old_sid
		   JOIN csrimp.map_score_type mst ON rsl.score_type_id = mst.old_score_type_id
		   LEFT JOIN csrimp.map_score_threshold mstr ON rsl.score_threshold_id = mstr.old_score_threshold_id
		   LEFT JOIN csrimp.map_sid mu ON rsl.changed_by_user_sid = mu.old_sid;

	INSERT INTO csr.region_score (region_sid, score_type_id, last_region_score_log_id)
		 SELECT mr.new_sid, mst.new_score_type_id, mrs.new_region_score_log_id
		   FROM csrimp.region_score rs
		   JOIN csrimp.map_region_score_log mrs ON rs.last_region_score_log_id = mrs.old_region_score_log_id
		   JOIN csrimp.map_sid mr ON rs.region_sid = mr.old_sid
		   JOIN csrimp.map_score_type mst ON rs.score_type_id = mst.old_score_type_id;

	INSERT INTO csr.property_mandatory_roles (role_sid)
		SELECT mr.new_sid
		  FROM csrimp.property_mandatory_roles pmr
		  JOIN csrimp.map_sid mr ON pmr.role_sid = mr.old_sid;

	-- Add property to document folders
	UPDATE csr.doc_folder df
	   SET property_sid = (
			SELECT mp.new_sid
			  FROM csrimp.doc_folder idf
			  JOIN csrimp.map_sid mdf ON idf.doc_folder_sid = mdf.old_sid
			  JOIN csrimp.map_sid mp ON idf.property_sid = mp.old_sid
			 WHERE df.doc_folder_sid = mdf.new_sid
		)
	 WHERE df.doc_folder_sid IN (
		SELECT mdf.new_sid
		  FROM csrimp.doc_folder idf
		  JOIN csrimp.map_sid mdf ON idf.doc_folder_sid = mdf.old_sid
	 );

	INSERT INTO csr.prop_type_prop_tab (plugin_id, property_type_id)
		 SELECT mpi.new_plugin_id, mpt.new_property_type_id
		   FROM csrimp.prop_type_prop_tab ptpt
		   JOIN csrimp.map_property_type mpt ON ptpt.property_type_id = mpt.old_property_type_id
		   LEFT JOIN csrimp.map_plugin mpi ON ptpt.plugin_id = mpi.old_plugin_id;

	INSERT INTO csr.property_gresb (region_sid, asset_id)
		 SELECT mr.new_sid, pg.asset_id
		   FROM csrimp.property_gresb pg
		   JOIN map_sid mr ON mr.old_sid = pg.region_sid;
END;

PROCEDURE CreatePropertiesDashboards
AS
BEGIN
	INSERT INTO csr.benchmark_dashboard(benchmark_dashboard_sid, name, start_dtm, end_dtm, lookup_key, period_set_id, period_interval_id)
		 SELECT ms.new_sid, tbl.name, tbl.start_dtm, tbl.end_dtm, tbl.lookup_key, tbl.period_set_id, tbl.period_interval_id
		   FROM csrimp.benchmark_dashboard tbl
		   JOIN csrimp.map_sid  ms ON tbl.benchmark_dashboard_sid = ms.old_sid;

	INSERT INTO csr.benchmark_dashboard_char(benchmark_dashboard_sid, benchmark_dashboard_char_id, pos, ind_sid, tag_group_id)
		 SELECT ms.new_sid, mtbl.new_benchmark_das_char_id, tbl.pos, msi.new_sid, mtg.new_tag_group_id
		   FROM csrimp.benchmark_dashboard_char tbl
		   JOIN csrimp.map_sid  ms ON tbl.benchmark_dashboard_sid = ms.old_sid
		   JOIN csrimp.map_benchmark_dashboard_char mtbl ON tbl.benchmark_dashboard_char_id = mtbl.old_benchmark_das_char_id
	  LEFT JOIN csrimp.map_sid msi ON tbl.ind_sid = ms.old_sid
	  LEFT JOIN csrimp.map_tag_group mtg ON tbl.tag_group_id = mtg.old_tag_group_id;

	INSERT INTO csr.benchmark_dashboard_ind(benchmark_dashboard_sid, ind_sid, display_name, scenario_run_sid, floor_area_ind_sid, pos)
		 SELECT ms.new_sid, msi.new_sid, tbl.display_name, mss.new_sid, msf.new_sid, tbl.pos
		   FROM csrimp.benchmark_dashboard_ind tbl
		   JOIN csrimp.map_sid  ms ON tbl.benchmark_dashboard_sid = ms.old_sid
		   JOIN csrimp.map_sid msi ON tbl.ind_sid = ms.old_sid
	  LEFT JOIN csrimp.map_sid mss ON tbl.scenario_run_sid = ms.old_sid
		   JOIN csrimp.map_sid msf ON tbl.floor_area_ind_sid = ms.old_sid;

	INSERT INTO csr.benchmark_dashboard_plugin(benchmark_dashboard_sid, plugin_id)
		 SELECT ms.new_sid, mp.new_plugin_id
		   FROM csrimp.benchmark_dashboard_plugin tbl
		   JOIN csrimp.map_sid ms ON tbl.benchmark_dashboard_sid = ms.old_sid
		   JOIN csrimp.map_plugin mp ON tbl.plugin_id = mp.old_plugin_id;

	INSERT INTO csr.metric_dashboard(metric_dashboard_sid, name, start_dtm, end_dtm, lookup_key, period_set_id, period_interval_id)
		 SELECT ms.new_sid, tbl.name, tbl.start_dtm, tbl.end_dtm, tbl.lookup_key, tbl.period_set_id, tbl.period_interval_id
		   FROM csrimp.metric_dashboard tbl
		   JOIN csrimp.map_sid ms ON tbl.metric_dashboard_sid = ms.old_sid;

	INSERT INTO csr.metric_dashboard_ind(metric_dashboard_sid, ind_sid, pos, block_title, block_css_class, inten_view_scenario_run_sid, inten_view_floor_area_ind_sid, absol_view_scenario_run_sid)
		 SELECT ms.new_sid, msi.new_sid, tbl.pos, tbl.block_title, tbl.block_css_class, msis.new_sid, msfi.new_sid, msas.new_sid
		   FROM csrimp.metric_dashboard_ind tbl
		   JOIN csrimp.map_sid   ms ON tbl.metric_dashboard_sid = ms.old_sid
		   JOIN csrimp.map_sid  msi ON tbl.ind_sid = ms.old_sid
		   JOIN csrimp.map_sid msis ON tbl.inten_view_scenario_run_sid = ms.old_sid
	  LEFT JOIN csrimp.map_sid msfi ON tbl.inten_view_floor_area_ind_sid = ms.old_sid
		   JOIN csrimp.map_sid msas ON tbl.absol_view_scenario_run_sid = ms.old_sid;

	INSERT INTO csr.metric_dashboard_plugin(metric_dashboard_sid, plugin_id)
		 SELECT ms.new_sid, mp.new_plugin_id
		   FROM csrimp.metric_dashboard_plugin tbl
		   JOIN csrimp.map_sid ms ON tbl.metric_dashboard_sid = ms.old_sid
		   JOIN csrimp.map_plugin mp ON tbl.plugin_id = mp.old_plugin_id;
END;

PROCEDURE CreateCurrencies
AS
BEGIN
	INSERT INTO csr.currency(currency_code)
		 SELECT currency_code
		   FROM csrimp.currency;
END;

PROCEDURE CreatePlugins
AS
	v_plugin_id				plugin.plugin_id%TYPE;
BEGIN
	FOR p IN (
		SELECT app_sid, plugin_id, plugin_type_id, description,
			   cs_class, js_class, js_include, details, preview_image_path,
			   mts.new_sid tab_sid, form_path, mf.new_sid form_sid, group_key, control_lookup_keys,
			   result_mode, mps.new_sid portal_sid,
			   use_reporting_period, r_script_path, allow_multiple
		   FROM csrimp.plugin pl
		   LEFT JOIN csrimp.map_sid mts ON pl.tab_sid = mts.old_sid
		   LEFT JOIN csrimp.map_sid mps ON pl.portal_sid = mps.old_sid
		   LEFT JOIN csrimp.map_sid mf on pl.form_sid = mf.old_sid
		  WHERE pl.saved_filter_sid IS NULL AND pl.pre_filter_sid IS NULL
	) LOOP
		IF p.app_sid IS NULL THEN
			BEGIN
			SELECT plugin_id
			  INTO v_plugin_id
			  FROM csr.plugin
			 WHERE app_sid IS NULL
			   AND UPPER(js_class) = UPPER(p.js_class)
			   AND (UPPER(cs_class) = UPPER(p.cs_class) OR cs_class = 'Credit360.Plugins.PluginDto');
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Unable to map the plugin with id='||p.plugin_id||
						', description='||p.description||', js_class='||p.js_class||', cs_class='||p.cs_class||
						' -- check for missing base data');
			END;
		ELSE
			INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description,
									cs_class, js_class, js_include, details, preview_image_path,
									tab_sid, form_path, form_sid, group_key, control_lookup_keys,
									result_mode, use_reporting_period, portal_sid, r_script_path, allow_multiple)
				 VALUES (SYS_CONTEXT('SECURITY', 'APP'), csr.plugin_id_seq.NEXTVAL, p.plugin_type_id, p.description,
						 p.cs_class, p.js_class, p.js_include, p.details, p.preview_image_path,
						 p.tab_sid, p.form_path, p.form_sid, p.group_key, p.control_lookup_keys,
						p.result_mode, p.use_reporting_period, p.portal_sid, p.r_script_path, p.allow_multiple)
			  RETURNING plugin_id INTO v_plugin_id;
		END IF;

			INSERT INTO csrimp.map_plugin (old_plugin_id, new_plugin_id)
						VALUES (p.plugin_id, v_plugin_id);
	END LOOP;

	INSERT INTO csr.plugin_indicator(plugin_indicator_id,
									 plugin_id,
									 lookup_key,
									 label,
									 pos)
		 SELECT csr.plugin_ind_id_seq.NEXTVAL,
				mp.new_plugin_id,
				pli.lookup_key,
				pli.label,
				pli.pos
		   FROM csrimp.plugin_indicator pli
		   JOIN csrimp.map_plugin mp ON mp.old_plugin_id = pli.plugin_id;
END;

PROCEDURE CreateSuppliers
AS
BEGIN
	-- insert into csr.supplier done in the chain stuff
	INSERT INTO csr.supplier_score_log (
				supplier_score_id,
				score,
				score_threshold_id,
				set_dtm,
				supplier_sid,
				score_type_id,
				changed_by_user_sid,
				comment_text,
				valid_until_dtm,
				score_source_type,
				score_source_id
	   ) SELECT mss.new_supplier_score_id,
				ss.score,
				mst.new_score_threshold_id,
				ss.set_dtm,
				ms.new_sid,
				msty.new_score_type_id,
				ms1.new_sid,
				ss.comment_text,
				ss.valid_until_dtm,
				ss.score_source_type,
				CASE
					WHEN ss.score_source_type = csr.csr_data_pkg.SCORE_SOURCE_TYPE_QS THEN mqss.new_submission_id
					WHEN ss.score_source_type = csr.csr_data_pkg.SCORE_SOURCE_TYPE_AUDIT THEN ms2.new_sid
					WHEN ss.score_source_type = csr.csr_data_pkg.SCORE_SOURCE_TYPE_SCORE_CALC THEN ms2.new_sid
					ELSE NULL
				END score_source_id
		   FROM csrimp.supplier_score_log ss,
				csrimp.map_supplier_score mss,
				csrimp.map_score_threshold mst,
				csrimp.map_sid ms,
				csrimp.map_score_type msty,
				csrimp.map_sid ms1,
				csrimp.map_qs_submission mqss,
				csrimp.map_sid ms2
		  WHERE ss.supplier_score_id = mss.old_supplier_score_id
			AND ss.score_threshold_id = mst.old_score_threshold_id(+)
			AND ss.supplier_sid = ms.old_sid
			AND ss.score_type_id = msty.old_score_type_id
			AND ss.changed_by_user_sid = ms1.old_sid(+)
			AND ss.score_source_id = mqss.old_submission_id(+)
			AND ss.score_source_id = ms2.old_sid(+);


	INSERT INTO csr.current_supplier_score (score_type_id, company_sid, last_supplier_score_id)
		SELECT mt.new_score_type_id, ms.new_sid, mss.new_supplier_score_id
		  FROM csrimp.current_supplier_score css
		  JOIN csrimp.map_supplier_score mss ON css.last_supplier_score_id = mss.old_supplier_score_id
		  JOIN csrimp.map_sid ms ON css.company_sid = ms.old_sid
		  JOIN csrimp.map_score_type mt ON css.score_type_id = mt.old_score_type_id;

	INSERT INTO csr.supplier_survey_response (survey_sid, survey_response_id, supplier_sid,
		component_id)
		SELECT ms.new_sid, msr.new_survey_response_id, msup.new_sid, mcc.new_component_id
		  FROM csrimp.supplier_survey_response ssr, csrimp.map_sid ms,
		  	   csrimp.map_qs_survey_response msr, csrimp.map_sid msup,
			   csrimp.map_chain_component mcc
		 WHERE ssr.survey_sid = ms.old_sid
		   AND ssr.survey_response_id = msr.old_survey_response_id
		   AND ssr.component_id = mcc.old_component_id
		   AND ssr.supplier_sid = msup.old_sid;

	INSERT INTO csr.issue_supplier (issue_supplier_id, company_sid, qs_expr_non_compl_action_id)
		SELECT mis.new_issue_supplier_id, ms.new_sid, mqs.new_qs_expr_nc_action_id
		  FROM csrimp.issue_supplier iss, csrimp.map_issue_supplier mis,
		  	   csrimp.map_sid ms, csrimp.map_qs_expr_nc_action mqs
		 WHERE iss.issue_supplier_id = mis.old_issue_supplier_id
		   AND iss.company_sid = ms.old_sid(+)
		   AND iss.qs_expr_non_compl_action_id = mqs.old_qs_expr_nc_action_id(+);

    FOR c IN (
		SELECT mi.new_issue_id issue_id, mis.new_issue_supplier_id issue_supplier_id
		  FROM csrimp.issue i,
		  	   csrimp.map_issue mi,
			   csrimp.map_issue_supplier mis
		 WHERE i.issue_id = mi.old_issue_id
		   AND i.issue_supplier_id = mis.old_issue_supplier_id(+)
	) LOOP
		BEGIN
		   UPDATE csr.issue
		      SET issue_supplier_id = c.issue_supplier_id
		    WHERE issue_id = c.issue_id;
		END;
	END LOOP;

	INSERT INTO csr.supplier_delegation (
				supplier_sid,
				tpl_delegation_sid,
				delegation_sid
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				ms2.new_sid
		   FROM csrimp.supplier_delegation sd,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2
		  WHERE sd.supplier_sid = ms.old_sid
			AND sd.tpl_delegation_sid = ms1.old_sid
			AND sd.delegation_sid = ms2.old_sid(+);
END;

PROCEDURE CreateBasicChain
AS
	v_capability_id				chain_capability.capability_id%TYPE;
	v_group_capability_id		chain_group_capability.group_capability_id%TYPE;
	v_new_capability_id			chain_capability.capability_id%TYPE;
	v_signature					chain_company.signature%TYPE;
BEGIN
    FOR c IN (
		SELECT capability_id,
			   capability_name,
			   capability_type_id,
			   is_supplier,
			   perm_type,
			   supplier_on_purchaser
		  FROM csrimp.chain_capability
	) LOOP
		BEGIN
			INSERT INTO chain.capability (capability_id, capability_name, capability_type_id,
										  is_supplier, perm_type, supplier_on_purchaser)
				VALUES (chain.capability_id_seq.NEXTVAL, c.capability_name, c.capability_type_id,
										  c.is_supplier, c.perm_type, c.supplier_on_purchaser)
			  RETURNING capability_id INTO v_capability_id;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
			  SELECT capability_id
			    INTO v_capability_id
				FROM chain.capability
			   WHERE capability_type_id = c.capability_type_id
				 AND capability_name = c.capability_name;
		END;

		BEGIN
			INSERT INTO csrimp.map_chain_capability (old_capability_id, new_capability_id)
		VALUES (c.capability_id, v_capability_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	INSERT INTO chain.capability_flow_capability (
				flow_capability_id,
				capability_id
	   ) SELECT mcfc.new_customer_flow_cap_id,
				mcc.new_capability_id
		   FROM csrimp.chain_capability_flow_cap ccfc,
				csrimp.map_customer_flow_cap mcfc,
				csrimp.map_chain_capability mcc
		  WHERE ccfc.flow_capability_id = mcfc.old_customer_flow_cap_id
			AND ccfc.capability_id = mcc.old_capability_id;

	INSERT INTO chain.customer_options (
				activity_mail_account_sid,
				add_csr_user_to_top_comp,
				admin_has_dev_access,
				allow_add_existing_contacts,
				allow_cc_on_invite,
				allow_company_self_reg,
				allow_new_user_request,
				chain_is_visible_to_top,
				company_user_create_alert,
				countries_helper_sp,
				default_qnr_invitation_wiz,
				default_receive_sched_alerts,
				default_share_qnr_with_on_bhlf,
				default_url,
				enable_qnnaire_reminder_alerts,
				enable_user_visibility_options,
				flow_helper_class_path,
				invitation_expiration_days,
				invitation_expiration_rem_days,
				invitation_expiration_rem,
				invite_from_name_addendum,
				inv_mgr_norm_user_full_access,
				landing_url,
				last_generate_alert_dtm,
				link_host,
				login_page_message,
				newsflash_summary_sp,
				override_manage_co_path,
				override_send_qi_path,
				product_url,
				product_url_read_only,
				purchased_comp_auto_map,
				questionnaire_filter_class,
				registration_terms_url,
				registration_terms_version,
				reinvite_supplier,
				req_qnnaire_invitation_landing,
				restrict_change_email_domains,
				scheduled_alert_intvl_minutes,
				sched_alerts_enabled,
				send_change_email_alert,
				show_all_components,
				show_invitation_preview,
				site_name,
				supplier_filter_export_url,
				support_email,
				task_manager_helper_type,
				top_company_sid,
				use_company_type_css_class,
				use_company_type_user_groups,
				use_type_capabilities,
				country_risk_enabled,
				filter_cache_timeout,
				show_map_on_supplier_list,
				force_login_as_company,
				show_extra_details_in_graph,
				enable_dedupe_onboarding,
				create_one_flow_item_for_comp,
				show_audit_coordinator,
				allow_duplicate_emails,
				prevent_relationship_loops,
				company_geotag_enabled
	   ) SELECT
				cco.activity_mail_account_sid,
				cco.add_csr_user_to_top_comp,
				cco.admin_has_dev_access,
				cco.allow_add_existing_contacts,
				cco.allow_cc_on_invite,
				cco.allow_company_self_reg,
				cco.allow_new_user_request,
				cco.chain_is_visible_to_top,
				cco.company_user_create_alert,
				MapCustomerSchema(cco.countries_helper_sp),
				cco.default_qnr_invitation_wiz,
				cco.default_receive_sched_alerts,
				cco.default_share_qnr_with_on_bhlf,
				cco.default_url,
				cco.enable_qnnaire_reminder_alerts,
				cco.enable_user_visibility_options,
				cco.flow_helper_class_path,
				cco.invitation_expiration_days,
				cco.invitation_expiration_rem_days,
				cco.invitation_expiration_rem,
				cco.invite_from_name_addendum,
				cco.inv_mgr_norm_user_full_access,
				cco.landing_url,
				cco.last_generate_alert_dtm,
				cco.link_host,
				cco.login_page_message,
				cco.newsflash_summary_sp,
				cco.override_manage_co_path,
				cco.override_send_qi_path,
				cco.product_url,
				cco.product_url_read_only,
				cco.purchased_comp_auto_map,
				cco.questionnaire_filter_class,
				cco.registration_terms_url,
				cco.registration_terms_version,
				cco.reinvite_supplier,
				cco.req_qnnaire_invitation_landing,
				cco.restrict_change_email_domains,
				cco.scheduled_alert_intvl_minutes,
				cco.sched_alerts_enabled,
				cco.send_change_email_alert,
				cco.show_all_components,
				cco.show_invitation_preview,
				cco.site_name,
				cco.supplier_filter_export_url,
				cco.support_email,
				cco.task_manager_helper_type,
				ms.new_sid,
				cco.use_company_type_css_class,
				cco.use_company_type_user_groups,
				cco.use_type_capabilities,
				cco.country_risk_enabled,
				cco.filter_cache_timeout,
				cco.show_map_on_supplier_list,
				cco.force_login_as_company,
				cco.show_extra_details_in_graph,
				cco.enable_dedupe_onboarding,
				cco.create_one_flow_item_for_comp,
				cco.show_audit_coordinator,
				cco.prevent_relationship_loops,
				cco.allow_duplicate_emails,
				cco.company_geotag_enabled
		   FROM csrimp.chain_customer_options cco,
				csrimp.map_sid ms
		  WHERE cco.top_company_sid = ms.old_sid(+);

	INSERT INTO chain.company_type (company_type_id, allow_lower_case, css_class, is_default,
				is_top_company, lookup_key, plural, position, singular, user_group_sid,
				user_role_sid, use_user_role, default_region_type, region_root_sid, default_region_layout,
				create_subsids_under_parent, create_doc_library_folder
	   ) SELECT mcct.new_company_type_id, cct.allow_lower_case, cct.css_class, cct.is_default,
				cct.is_top_company, cct.lookup_key, cct.plural, cct.position, cct.singular,
				ms.new_sid, ms1.new_sid, cct.use_user_role, cct.default_region_type, mrrs.new_sid,
				cct.default_region_layout, cct.create_subsids_under_parent, cct.create_doc_library_folder
		   FROM csrimp.chain_company_type cct,
				csrimp.map_chain_company_type mcct,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid mrrs
		  WHERE cct.company_type_id = mcct.old_company_type_id
			AND cct.user_group_sid = ms.old_sid(+)
			AND cct.user_role_sid = ms1.old_sid(+)
			AND cct.region_root_sid = mrrs.old_sid(+);

	INSERT INTO chain.sector (
			sector_id,
			active,
			description,
			is_other,
			parent_sector_id
   ) SELECT cs.sector_id,
			cs.active,
			cs.description,
			cs.is_other,
			cs.parent_sector_id
	   FROM csrimp.chain_sector cs;

	INSERT INTO chain.company (
				company_sid,
				activated_dtm,
				active,
				address_1,
				address_2,
				address_3,
				address_4,
				allow_stub_registration,
				approve_stub_registration,
				can_see_all_companies,
				company_type_id,
				country_code,
				created_dtm,
				deleted,
				details_confirmed,
				fax,
				mapping_approval_required,
				name,
				phone,
				postcode,
				sector_id,
				state,
				stub_registration_guid,
				supp_rel_code_label,
				supp_rel_code_label_mand,
				city,
				user_level_messaging,
				website,
				parent_sid,
				country_is_hidden,
				deactivated_dtm,
				email,
				requested_by_company_sid,
				requested_by_user_sid,
				pending,
				signature
	   ) SELECT ms.new_sid,
				cc.activated_dtm,
				cc.active,
				cc.address_1,
				cc.address_2,
				cc.address_3,
				cc.address_4,
				cc.allow_stub_registration,
				cc.approve_stub_registration,
				cc.can_see_all_companies,
				mcct.new_company_type_id,
				cc.country_code,
				cc.created_dtm,
				cc.deleted,
				cc.details_confirmed,
				cc.fax,
				cc.mapping_approval_required,
				cc.name,
				cc.phone,
				cc.postcode,
				cc.sector_id,
				cc.state,
				cc.stub_registration_guid,
				cc.supp_rel_code_label,
				cc.supp_rel_code_label_mand,
				cc.city,
				cc.user_level_messaging,
				cc.website,
				mpc.new_sid,
				cc.country_is_hidden,
				cc.deactivated_dtm,
				cc.email,
				rbc.new_sid,
				rbu.new_sid,
				cc.pending,
				cc.signature
		   FROM csrimp.chain_company cc,
				csrimp.map_sid ms,
				csrimp.map_chain_company_type mcct,
				csrimp.map_sid mpc,
				csrimp.map_sid rbc,
				csrimp.map_sid rbu
		  WHERE cc.company_sid = ms.old_sid
			AND cc.company_type_id = mcct.old_company_type_id
			AND cc.parent_sid = mpc.old_sid(+)
			AND cc.requested_by_company_sid = rbc.old_sid(+)
			AND cc.requested_by_user_sid = rbu.old_sid(+);

	-- fix signatures/ SO names
	FOR r IN (
		SELECT c.company_sid, c.name, c.country_code, c.company_type_id, c.city, c.state, c.sector_id, c.parent_sid,
			ct.default_region_layout, c.deleted
		  FROM chain.company c
		  JOIN chain.company_type ct ON c.company_type_id = ct.company_type_id
		 WHERE c.app_sid = security.security_pkg.getapp
	) 
	LOOP
		IF r.deleted = 0 THEN
			UPDATE security.securable_object
			   SET name = chain.helper_pkg.GenerateSOName(r.name, r.company_sid)
			 WHERE sid_id = r.company_sid;
		END IF;

		v_signature := chain.helper_pkg.GenerateCompanySignature(
			in_company_name		=> r.name, 
			in_country			=> r.country_code,
			in_company_type_id	=> r.company_type_id,
			in_city				=> r.city,
			in_state			=> r.state,
			in_sector_id		=> r.sector_id,
			in_layout			=> NVL(r.default_region_layout, '{COUNTRY}/{SECTOR}'),
			in_parent_sid		=> r.parent_sid
		);

		BEGIN
			UPDATE chain.company
			   SET signature = v_signature
			 WHERE company_sid = r.company_sid;
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE chain.company
		   		   SET signature = v_signature || '|sid:' || r.company_sid
		 		 WHERE company_sid = r.company_sid;
		END;
	END LOOP;

	--group_capability is a little bit tricky:
	--first match rows...
	INSERT INTO csrimp.map_chain_group_capabili (old_group_capability_id, new_group_capability_id)
		 SELECT cgc.group_capability_id, gp.group_capability_id
		   FROM csrimp.chain_group_capability cgc
           JOIN csrimp.map_chain_capability mcc on mcc.old_capability_id = cgc.capability_id
           JOIN chain.group_capability gp ON gp.capability_id = mcc.new_capability_id AND gp.company_group_type_id = cgc.company_group_type_id AND gp.permission_set = cgc.permission_set;

	--...then copy non existing rows
	FOR c IN (
		--selecting rows which could not be matched with an existing row hence they must be copied.
		SELECT  group_capability_id,
				company_group_type_id,
				capability_id,
				permission_set
		  FROM  csrimp.chain_group_capability
		  WHERE group_capability_id not in (
			SELECT old_group_capability_id
			  FROM csrimp.map_chain_group_capabili
			  )
	) LOOP
		SELECT mcc.new_capability_id
		  INTO v_new_capability_id
		  FROM csrimp.map_chain_capability mcc
		 WHERE mcc.old_capability_id = c.capability_id;

		BEGIN
			INSERT INTO chain.group_capability (group_capability_id, company_group_type_id, capability_id, permission_set)
				VALUES(chain.group_capability_id_seq.NEXTVAL, c.company_group_type_id, v_new_capability_id, c.permission_set)
			  RETURNING group_capability_id INTO v_group_capability_id;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;		--it should never get here because of how csrimp.map_chain_group_capabili was filled.
		END;

		BEGIN
			INSERT INTO csrimp.map_chain_group_capabili (old_group_capability_id, new_group_capability_id)
			VALUES (c.group_capability_id, v_group_capability_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	INSERT INTO chain.applied_company_capability (
				company_sid,
				group_capability_id,
				permission_set
	   ) SELECT ms.new_sid,
				mcgc.new_group_capability_id,
				cacc.permission_set
		   FROM csrimp.chain_appli_compa_capabi cacc,
				csrimp.map_sid ms,
				csrimp.map_chain_group_capabili mcgc
		  WHERE cacc.company_sid = ms.old_sid
			AND cacc.group_capability_id = mcgc.old_group_capability_id;

	INSERT INTO chain.chain_user (
				user_sid,
				default_company_sid,
				default_css_path,
				default_home_page,
				default_stylesheet,
				deleted,
				details_confirmed,
				merged_to_user_sid,
				next_scheduled_alert_dtm,
				receive_scheduled_alerts,
				registration_status_id,
				scheduled_alert_time,
				tmp_is_chain_user,
				visibility_id
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				ccu.default_css_path,
				ccu.default_home_page,
				ccu.default_stylesheet,
				ccu.deleted,
				ccu.details_confirmed,
				ms2.new_sid,
				ccu.next_scheduled_alert_dtm,
				ccu.receive_scheduled_alerts,
				ccu.registration_status_id,
				ccu.scheduled_alert_time,
				ccu.tmp_is_chain_user,
				ccu.visibility_id
		   FROM csrimp.chain_chain_user ccu,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2
		  WHERE ccu.user_sid = ms.old_sid
			AND ccu.default_company_sid = ms1.old_sid(+)
			AND ccu.merged_to_user_sid = ms2.old_sid(+);

	INSERT INTO chain.company_group (
				company_sid,
				company_group_type_id,
				group_sid
	   ) SELECT ms.new_sid,
				ccg.company_group_type_id,
				ms1.new_sid
		   FROM csrimp.chain_company_group ccg,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE ccg.company_sid = ms.old_sid
			AND ccg.group_sid = ms1.old_sid(+);

	INSERT INTO chain.company_type_relationship (
				primary_company_type_id,
				secondary_company_type_id,
				use_user_roles,
				hidden,
				flow_sid,
				follower_role_sid,
				can_be_primary
	   ) SELECT mcct.new_company_type_id,
				mcct1.new_company_type_id,
				cctr.use_user_roles,
				cctr.hidden,
				ms.new_sid,
				mrs.new_sid,
				cctr.can_be_primary
		   FROM csrimp.chain_compan_type_relati cctr,
				csrimp.map_chain_company_type mcct,
				csrimp.map_chain_company_type mcct1,
				csrimp.map_sid ms,
				csrimp.map_sid mrs
		  WHERE cctr.primary_company_type_id = mcct.old_company_type_id
			AND cctr.secondary_company_type_id = mcct1.old_company_type_id
			AND cctr.flow_sid = ms.old_sid(+)
			AND cctr.follower_role_sid = mrs.old_sid(+);

	INSERT INTO chain.tertiary_relationships (
				primary_company_type_id,
				secondary_company_type_id,
				tertiary_company_type_id
	   ) SELECT mcct.new_company_type_id,
				mcct1.new_company_type_id,
				mcct2.new_company_type_id
		   FROM csrimp.chain_tertiary_relations ctr,
				csrimp.map_chain_company_type mcct,
				csrimp.map_chain_company_type mcct1,
				csrimp.map_chain_company_type mcct2
		  WHERE ctr.primary_company_type_id = mcct.old_company_type_id
			AND ctr.secondary_company_type_id = mcct1.old_company_type_id
			AND ctr.tertiary_company_type_id = mcct2.old_company_type_id;

	INSERT INTO chain.company_type_role(
				company_type_role_id,
				company_type_id,
				role_sid,
				mandatory,
				cascade_to_supplier,
				pos
		) SELECT mcctr.new_company_type_role_id,
				 mcct.new_company_type_id,
				 ms.new_sid,
				 cctr.mandatory,
				 cctr.cascade_to_supplier,
				 cctr.pos
			FROM csrimp.chain_company_type_role cctr
			JOIN csrimp.map_chain_company_type_role mcctr ON cctr.company_type_role_id = mcctr.old_company_type_role_id
			JOIN csrimp.map_chain_company_type mcct ON cctr.company_type_id = mcct.old_company_type_id
			JOIN csrimp.map_sid ms ON cctr.role_sid = ms.old_sid;

	INSERT INTO chain.company_type_capability (
				capability_id,
				permission_set,
				primary_company_group_type_id,
				primary_company_type_id,
				secondary_company_type_id,
				tertiary_company_type_id,
				primary_company_type_role_sid
	   ) SELECT mcc.new_capability_id,
				cctc.permission_set,
				cctc.primary_company_group_type_id,
				mcct.new_company_type_id,
				mcct1.new_company_type_id,
				mcct2.new_company_type_id,
				ms.new_sid
		   FROM csrimp.chain_compan_type_capabi cctc,
				csrimp.map_chain_capability mcc,
				csrimp.map_chain_company_type mcct,
				csrimp.map_chain_company_type mcct1,
				csrimp.map_chain_company_type mcct2,
				csrimp.map_sid ms
		  WHERE cctc.capability_id = mcc.old_capability_id
		    AND cctc.primary_company_type_id = mcct.old_company_type_id
			AND cctc.secondary_company_type_id = mcct1.old_company_type_id(+)
			AND cctc.tertiary_company_type_id = mcct2.old_company_type_id(+)
			AND cctc.primary_company_type_role_sid = ms.old_sid(+);

	INSERT INTO chain.group_capability_override (
				group_capability_id,
				hide_group_capability,
				permission_set_override
	   ) SELECT mcgc.new_group_capability_id,
				cgco.hide_group_capability,
				cgco.permission_set_override
		   FROM csrimp.chain_group_capab_overri cgco,
				csrimp.map_chain_group_capabili mcgc
		  WHERE cgco.group_capability_id = mcgc.old_group_capability_id;

	INSERT INTO chain.implementation (
				execute_order,
				link_pkg,
				name
	   ) SELECT ci.execute_order,
				ci.link_pkg,
				ci.name
		   FROM csrimp.chain_implementation ci;

	INSERT INTO chain.supplier_relationship(
				purchaser_company_sid,
				supplier_company_sid,
				active,
				deleted,
				virtually_active_until_dtm,
				virtually_active_key,
				supp_rel_code,
				is_primary
		) SELECT
				ms0.new_sid,
				ms1.new_sid,
				csr.active,
				csr.deleted,
				csr.virtually_active_until_dtm,
				csr.virtually_active_key,
				csr.supp_rel_code,
				csr.is_primary
			FROM csrimp.chain_supplier_relationship csr
			JOIN csrimp.map_sid ms0 ON csr.purchaser_company_sid = ms0.old_sid
			JOIN csrimp.map_sid ms1 ON csr.supplier_company_sid = ms1.old_sid;
	
	INSERT INTO chain.supplier_relationship_source (
				purchaser_company_sid,
				supplier_company_sid,
				source_type,
				object_id
		) SELECT
				ms0.new_sid,
				ms1.new_sid,
				csrs.source_type,
				mcbr.new_business_relationship_id
			FROM csrimp.chain_supp_rel_source csrs
			JOIN csrimp.map_sid ms0 ON csrs.purchaser_company_sid = ms0.old_sid
			JOIN csrimp.map_sid ms1 ON csrs.supplier_company_sid = ms1.old_sid
			LEFT JOIN csrimp.map_chain_busine_relatio mcbr ON mcbr.old_business_relationship_id = csrs.object_id;

	INSERT INTO chain.supplier_relationship_score (
				supplier_relationship_score_id,
				purchaser_company_sid,
				supplier_company_sid,
				score_threshold_id,
				set_dtm,
				score,
				score_type_id,
				changed_by_user_sid,
				comment_text,
				valid_until_dtm,
				score_source_type,
				score_source_id,
				is_override
	   ) SELECT mcsrs.new_chain_supplie_rel_score_id,
				ms.new_sid,
				ms1.new_sid,
				csrs.score_threshold_id,
				csrs.set_dtm,
				csrs.score,
				csrs.score_type_id,
				ms2.new_sid,
				csrs.comment_text,
				csrs.valid_until_dtm,
				csrs.score_source_type,
				NVL(ms3.new_sid, csrs.score_source_id),
				csrs.is_override
		   FROM csrimp.chain_suppl_relati_score csrs,
				csrimp.map_chain_supp_rel_score mcsrs,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_sid ms3
		  WHERE csrs.supplier_relationship_score_id = mcsrs.old_chain_supplie_rel_score_id
			AND csrs.purchaser_company_sid = ms.old_sid
			AND csrs.supplier_company_sid = ms1.old_sid
			AND NVL(csrs.changed_by_user_sid, -1) = ms2.old_sid(+)
			AND NVL(csrs.score_source_id, -1) = ms3.old_sid(+);

	INSERT INTO chain.supplier_follower(
			purchaser_company_sid,
			supplier_company_sid,
			user_sid,
			is_primary
	)SELECT
		ms0.new_sid,
		ms1.new_sid,
		ms2.new_sid,
		csf.is_primary
	   FROM csrimp.chain_supplier_follower csf
	   JOIN csrimp.map_sid ms0 ON csf.purchaser_company_sid = ms0.old_sid
	   JOIN csrimp.map_sid ms1 ON csf.supplier_company_sid = ms1.old_sid
	   JOIN csrimp.map_sid ms2 ON csf.user_sid = ms2.old_sid;

	INSERT INTO chain.risk_level(
			risk_level_id,
			label,
			lookup_key
	)SELECT
		mcrl.new_risk_level_id,
		crl.label,
		crl.lookup_key
	   FROM csrimp.chain_risk_level crl
	   JOIN csrimp.map_chain_risk_level mcrl ON crl.risk_level_id = mcrl.old_risk_level_id;

	INSERT INTO chain.country_risk_level(
			risk_level_id,
			country,
			start_dtm
	)SELECT
		mcrl.new_risk_level_id,
		ccrl.country,
		ccrl.start_dtm
	   FROM csrimp.chain_country_risk_level ccrl
	   JOIN csrimp.map_chain_risk_level mcrl ON ccrl.risk_level_id = mcrl.old_risk_level_id;

	-- stick company_sid into supplier
	INSERT INTO csr.supplier (
				company_sid,
				logo_file_sid,
				region_sid,
				default_region_mount_sid
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				ms2.new_sid,
				ms3.new_sid
		   FROM csrimp.supplier s,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_sid ms3
		  WHERE s.company_sid = ms.old_sid
			AND s.logo_file_sid = ms1.old_sid(+)
			AND s.region_sid = ms2.old_sid(+)
			AND s.default_region_mount_sid = ms3.old_sid(+);

    -- fix up audit company
    FOR r IN (
        SELECT mau.new_sid internal_audit_sid, macs.new_sid auditor_company_sid
          FROM csrimp.internal_audit ia
          JOIN csrimp.map_sid macs ON ia.auditor_company_sid = macs.old_sid
          JOIN csrimp.map_sid mau ON ia.internal_audit_sid = mau.old_sid
    )
    LOOP
        UPDATE csr.internal_audit
           SET auditor_company_sid = r.auditor_company_sid
         WHERE internal_audit_sid = r.internal_audit_sid;
    END LOOP;

	-- fix up issue_involvement
	INSERT INTO csr.issue_involvement (issue_id, is_an_owner, user_sid, role_sid, company_sid)
		SELECT /*+CARDINALITY(ii, 10000) CARDINALITY(mi, 10000)*/
			   mi.new_issue_id, ii.is_an_owner, mu.new_sid, mr.new_sid, mc.new_sid
		  FROM csrimp.issue_involvement ii, csrimp.map_issue mi, csrimp.map_sid mu, csrimp.map_sid mr,
			   csrimp.map_sid mc
		 WHERE ii.issue_id = mi.old_issue_id
		   AND ii.user_sid = mu.old_sid(+)
		   AND ii.role_sid = mr.old_sid(+)
		   AND ii.company_sid = mc.old_sid(+);

	-- fix up doc library folders
    FOR r IN (
        SELECT mdfs.new_sid doc_folder_sid, mcs.new_sid company_sid
          FROM csrimp.doc_folder df
          JOIN csrimp.map_sid mdfs ON df.doc_folder_sid = mdfs.old_sid
          JOIN csrimp.map_sid mcs ON df.company_sid = mcs.old_sid
    )
    LOOP
        UPDATE csr.doc_folder
           SET company_sid = r.company_sid
         WHERE doc_folder_sid = r.doc_folder_sid;
    END LOOP;

	INSERT INTO chain.company_type_score_calc (
				company_type_id,
				score_type_id,
				calc_type,
				operator_type,
				supplier_score_type_id,
				active_suppliers_only
	   ) SELECT mcct.new_company_type_id,
				mst.new_score_type_id,
				cctsc.calc_type,
				cctsc.operator_type,
				mst1.new_score_type_id,
				cctsc.active_suppliers_only
		   FROM csrimp.chain_com_type_scor_calc cctsc,
				csrimp.map_chain_company_type mcct,
				csrimp.map_score_type mst,
				csrimp.map_score_type mst1
		  WHERE cctsc.company_type_id = mcct.old_company_type_id
			AND cctsc.score_type_id = mst.old_score_type_id
			AND cctsc.supplier_score_type_id = mst1.old_score_type_id(+);

	INSERT INTO chain.comp_type_score_calc_comp_type (
				company_type_id,
				score_type_id,
				supplier_company_type_id
	   ) SELECT mcct.new_company_type_id,
				mst.new_score_type_id,
				mcct1.new_company_type_id
		   FROM csrimp.chain_co_ty_sc_cal_co_ty cctscct,
				csrimp.map_chain_company_type mcct,
				csrimp.map_score_type mst,
				csrimp.map_chain_company_type mcct1
		  WHERE cctscct.company_type_id = mcct.old_company_type_id
			AND cctscct.score_type_id = mst.old_score_type_id
			AND cctscct.supplier_company_type_id = mcct1.old_company_type_id;

	INSERT INTO chain.supplier_involvement_type (
				flow_involvement_type_id,
				user_company_type_id,
				page_company_type_id,
				purchaser_type,
				restrict_to_role_sid
	   ) SELECT mfit.new_flow_involvement_type_id, muct.new_company_type_id, mpct.new_company_type_id,
				csit.purchaser_type, mr.new_sid
		   FROM csrimp.chain_supplier_inv_type csit
		   JOIN csrimp.map_flow_involvement_type mfit ON mfit.old_flow_involvement_type_id = csit.flow_involvement_type_id
		   LEFT JOIN csrimp.map_chain_company_type muct ON muct.old_company_type_id = csit.user_company_type_id
		   LEFT JOIN csrimp.map_chain_company_type mpct ON mpct.old_company_type_id = csit.page_company_type_id
		   LEFT JOIN csrimp.map_sid mr ON mr.old_sid = csit.restrict_to_role_sid;
END;

PROCEDURE CreateChainActivities
AS
BEGIN
	INSERT INTO chain.project (
				project_id,
				name
	   ) SELECT mcp.new_project_id,
				cp.name
		   FROM csrimp.chain_project cp,
				csrimp.map_chain_project mcp
		  WHERE cp.project_id = mcp.old_project_id;

	INSERT INTO chain.activity_type (
				activity_type_id,
				css_class,
				due_dtm_relative,
				due_dtm_relative_unit,
				has_location,
				has_target_user,
				helper_pkg,
				label,
				lookup_key,
				user_can_create,
				title_template,
				can_share
	   ) SELECT mcat.new_activity_type_id,
				cat.css_class,
				cat.due_dtm_relative,
				cat.due_dtm_relative_unit,
				cat.has_location,
				cat.has_target_user,
				cat.helper_pkg,
				cat.label,
				cat.lookup_key,
				cat.user_can_create,
				cat.title_template,
				cat.can_share
		   FROM csrimp.chain_activity_type cat,
				csrimp.map_chain_activity_type mcat
		  WHERE cat.activity_type_id = mcat.old_activity_type_id;

	INSERT INTO chain.outcome_type (
				outcome_type_id,
				is_deferred,
				is_failure,
				is_success,
				label,
				lookup_key,
				require_reason
	   ) SELECT mcot.new_outcome_type_id,
				cot.is_deferred,
				cot.is_failure,
				cot.is_success,
				cot.label,
				cot.lookup_key,
				cot.require_reason
		   FROM csrimp.chain_outcome_type cot,
				csrimp.map_chain_outcome_type mcot
		  WHERE cot.outcome_type_id = mcot.old_outcome_type_id;

	INSERT INTO chain.activity_outcome_type (
				activity_type_id,
				outcome_type_id
	   ) SELECT mcat.new_activity_type_id,
				mcot.new_outcome_type_id
		   FROM csrimp.chain_activi_outcom_type caot,
				csrimp.map_chain_activity_type mcat,
				csrimp.map_chain_outcome_type mcot
		  WHERE caot.activity_type_id = mcat.old_activity_type_id
			AND caot.outcome_type_id = mcot.old_outcome_type_id;

	INSERT INTO chain.activity (
				activity_id,
				description,
				activity_dtm,
				activity_type_id,
				assigned_to_user_sid,
				assigned_to_role_sid,
				created_by_activity_id,
				created_by_company_sid,
				created_by_sid,
				created_dtm,
				location,
				location_type,
				original_activity_dtm,
				outcome_reason,
				outcome_type_id,
				target_company_sid,
				target_user_sid,
				target_role_sid,
				share_with_target,
				project_id
	   ) SELECT mca.new_activity_id,
				ca.description,
				ca.activity_dtm,
				mcat.new_activity_type_id,
				ms.new_sid,
				ms0.new_sid,
				mca1.new_activity_id,
				ms1.new_sid,
				ms2.new_sid,
				ca.created_dtm,
				ca.location,
				ca.location_type,
				ca.original_activity_dtm,
				ca.outcome_reason,
				mcot.new_outcome_type_id,
				ms3.new_sid,
				ms4.new_sid,
				ms5.new_sid,
				ca.share_with_target,
				mcp.new_project_id
		   FROM csrimp.chain_activity ca,
				csrimp.map_chain_activity mca,
				csrimp.map_chain_activity_type mcat,
				csrimp.map_sid ms,
				csrimp.map_sid ms0,
				csrimp.map_chain_activity mca1,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_chain_outcome_type mcot,
				csrimp.map_sid ms3,
				csrimp.map_sid ms4,
				csrimp.map_sid ms5,
				csrimp.map_chain_project mcp
		  WHERE ca.activity_id = mca.old_activity_id
			AND ca.activity_type_id = mcat.old_activity_type_id
			AND ca.assigned_to_user_sid = ms.old_sid(+)
			AND ca.assigned_to_role_sid = ms0.old_sid(+)
			AND ca.created_by_activity_id = mca1.old_activity_id(+)
			AND ca.created_by_company_sid = ms1.old_sid
			AND ca.created_by_sid = ms2.old_sid
			AND ca.outcome_type_id = mcot.old_outcome_type_id(+)
			AND ca.target_company_sid = ms3.old_sid
			AND ca.target_user_sid = ms4.old_sid(+)
			AND ca.target_role_sid = ms5.old_sid(+)
			AND ca.project_id = mcp.old_project_id(+);

	INSERT INTO chain.activity_log (
				activity_log_id,
				activity_id,
				is_system_generated,
				is_visible_to_supplier,
				logged_by_user_sid,
				logged_dtm,
				message,
				reply_to_activity_log_id,
				param_1,
				param_2,
				param_3,
				correspondent_name,
				is_from_email
	   ) SELECT mcal.new_activity_log_id,
				mca.new_activity_id,
				cal.is_system_generated,
				cal.is_visible_to_supplier,
				ms.new_sid,
				cal.logged_dtm,
				cal.message,
				mrcal.new_activity_log_id,
				cal.param_1,
				cal.param_2,
				cal.param_3,
				cal.correspondent_name,
				cal.is_from_email
		   FROM csrimp.chain_activity_log cal,
				csrimp.map_chain_activity_log mcal,
				csrimp.map_chain_activity_log mrcal,
				csrimp.map_chain_activity mca,
				csrimp.map_sid ms
		  WHERE cal.activity_log_id = mcal.old_activity_log_id
			AND cal.activity_id = mca.old_activity_id
			AND cal.logged_by_user_sid = ms.old_sid
			AND cal.reply_to_activity_log_id = mrcal.old_activity_log_id(+);

	INSERT INTO chain.activity_log_file (
				activity_log_file_id,
				activity_log_id,
				data,
				filename,
				mime_type,
				sha1,
				uploaded_dtm
	   ) SELECT mcalf.new_activity_log_file_id,
				mcal.new_activity_log_id,
				calf.data,
				calf.filename,
				calf.mime_type,
				calf.sha1,
				calf.uploaded_dtm
		   FROM csrimp.chain_activity_log_file calf,
				csrimp.map_chain_activ_log_file mcalf,
				csrimp.map_chain_activity_log mcal
		  WHERE calf.activity_log_file_id = mcalf.old_activity_log_file_id
			AND calf.activity_log_id = mcal.old_activity_log_id;

	INSERT INTO chain.activity_type_tag_group (
				activity_type_id,
				tag_group_id
	   ) SELECT mcat.new_activity_type_id,
				mtg.new_tag_group_id
		   FROM csrimp.chain_acti_type_tag_grou cattg,
				csrimp.map_chain_activity_type mcat,
				csrimp.map_tag_group mtg
		  WHERE cattg.activity_type_id = mcat.old_activity_type_id
			AND cattg.tag_group_id = mtg.old_tag_group_id;

	INSERT INTO chain.activity_involvement (
				activity_id,
				user_sid,
				role_sid,
				added_by_sid,
				added_dtm
	   ) SELECT mca.new_activity_id,
				ms.new_sid,
				ms0.new_sid,
				ms1.new_sid,
				cau.added_dtm
		   FROM csrimp.chain_activity_involvement cau,
				csrimp.map_chain_activity mca,
				csrimp.map_sid ms,
				csrimp.map_sid ms0,
				csrimp.map_sid ms1
		  WHERE cau.activity_id = mca.old_activity_id
			AND cau.user_sid = ms.old_sid(+)
			AND cau.role_sid = ms0.old_sid(+)
			AND cau.added_by_sid = ms1.old_sid;

	INSERT INTO chain.activity_tag (
				activity_id,
				tag_id,
				activity_type_id,
				tag_group_id
	   ) SELECT mca.new_activity_id,
				mt.new_tag_id,
				mcat.new_activity_type_id,
				mtg.new_tag_group_id
		   FROM csrimp.chain_activity_tag cat,
				csrimp.map_chain_activity mca,
				csrimp.map_tag mt,
				csrimp.map_chain_activity_type mcat,
				csrimp.map_tag_group mtg
		  WHERE cat.activity_id = mca.old_activity_id
			AND cat.tag_id = mt.old_tag_id
			AND cat.activity_type_id = mcat.old_activity_type_id
			AND cat.tag_group_id = mtg.old_tag_group_id;

	INSERT INTO chain.activity_type_action (
				activity_type_action_id,
				activity_type_id,
				allow_user_interaction,
				generate_activity_type_id,
				default_description,
				default_assigned_to_role_sid,
				default_target_role_sid,
			    default_act_date_relative,
			    default_act_date_relative_unit,
			    default_share_with_target,
				default_location,
				default_location_type,
				copy_tags,
				copy_assigned_to,
				copy_target
	   ) SELECT mcata.new_activity_type_action_id,
				mcat.new_activity_type_id,
				cata.allow_user_interaction,
				mcat1.new_activity_type_id,
				cata.default_description,
				msar.new_sid,
				mstr.new_sid,
			    cata.default_act_date_relative,
			    cata.default_act_date_relative_unit,
			    cata.default_share_with_target,
				cata.default_location,
				cata.default_location_type,
				cata.copy_tags,
				cata.copy_assigned_to,
				cata.copy_target
		   FROM csrimp.chain_activi_type_action cata,
				csrimp.map_chain_acti_type_acti mcata,
				csrimp.map_chain_activity_type mcat,
				csrimp.map_chain_activity_type mcat1,
				csrimp.map_sid msar,
				csrimp.map_sid mstr
		  WHERE cata.activity_type_action_id = mcata.old_activity_type_action_id
			AND cata.activity_type_id = mcat.old_activity_type_id
			AND cata.generate_activity_type_id = mcat1.old_activity_type_id
			AND cata.default_assigned_to_role_sid = msar.old_sid(+)
			AND cata.default_target_role_sid = mstr.old_sid(+);

	INSERT INTO chain.activity_outcome_type_action (
				activity_outcome_typ_action_id,
				activity_type_id,
				allow_user_interaction,
				generate_activity_type_id,
				outcome_type_id,
				default_description,
				default_assigned_to_role_sid,
				default_target_role_sid,
			    default_act_date_relative,
			    default_act_date_relative_unit,
			    default_share_with_target,
				default_location,
				default_location_type,
				copy_tags,
				copy_assigned_to,
				copy_target
	   ) SELECT mcaota.new_activity_outcm_typ_actn_id,
				mcat.new_activity_type_id,
				caota.allow_user_interaction,
				mcat1.new_activity_type_id,
				caota.outcome_type_id,
				caota.default_description,
				msar.new_sid,
				mstr.new_sid,
			    caota.default_act_date_relative,
			    caota.default_act_date_relative_unit,
			    caota.default_share_with_target,
				caota.default_location,
				caota.default_location_type,
				caota.copy_tags,
				caota.copy_assigned_to,
				caota.copy_target
		   FROM csrimp.chain_act_outc_type_act caota,
				csrimp.map_chain_ac_out_typ_ac mcaota,
				csrimp.map_chain_activity_type mcat,
				csrimp.map_chain_activity_type mcat1,
				csrimp.map_sid msar,
				csrimp.map_sid mstr
		  WHERE caota.activity_outcome_typ_action_id = mcaota.old_activity_outcm_typ_actn_id
			AND caota.activity_type_id = mcat.old_activity_type_id
			AND caota.generate_activity_type_id = mcat1.old_activity_type_id
			AND caota.default_assigned_to_role_sid = msar.old_sid(+)
			AND caota.default_target_role_sid = mstr.old_sid(+);

	INSERT INTO chain.activity_type_alert (
				activity_type_id,
				customer_alert_type_id,
				allow_manual_editing,
				label,
				use_supplier_company,
				send_to_target,
				send_to_assignee
	   ) SELECT mcat.new_activity_type_id,
				mcat1.new_customer_alert_type_id,
				cata.allow_manual_editing,
				cata.label,
				cata.use_supplier_company,
				cata.send_to_target,
				cata.send_to_assignee
		   FROM csrimp.chain_activit_type_alert cata,
				csrimp.map_chain_activity_type mcat,
				csrimp.map_customer_alert_type mcat1
		  WHERE cata.activity_type_id = mcat.old_activity_type_id
			AND cata.customer_alert_type_id = mcat1.old_customer_alert_type_id;

	INSERT INTO chain.activity_type_alert_role (
				activity_type_id,
				customer_alert_type_id,
				role_sid
	   ) SELECT mcat.new_activity_type_id,
				mcat1.new_customer_alert_type_id,
				ms.new_sid
		   FROM csrimp.chain_act_type_aler_role catar,
				csrimp.map_chain_activity_type mcat,
				csrimp.map_customer_alert_type mcat1,
				csrimp.map_sid ms
		  WHERE catar.activity_type_id = mcat.old_activity_type_id
			AND catar.customer_alert_type_id = mcat1.old_customer_alert_type_id
			AND catar.role_sid = ms.old_sid;

	INSERT INTO chain.activity_type_default_user (
				activity_type_id,
				user_sid
	   ) SELECT mcat.new_activity_type_id,
				ms.new_sid
		   FROM csrimp.chain_act_type_defa_user catdu,
				csrimp.map_chain_activity_type mcat,
				csrimp.map_sid ms
		  WHERE catdu.activity_type_id = mcat.old_activity_type_id
			AND catdu.user_sid = ms.old_sid;
END;

PROCEDURE CreateChainCards
AS
BEGIN
	INSERT INTO chain.card_group_card (
		card_group_id,
		card_id,
		position,
		required_permission_set,
		required_capability_id,
		invert_capability_check,
		force_terminate
	) SELECT
		ccgc.card_group_id,
		mcc.new_card_id,
		ccgc.position,
		ccgc.required_permission_set,
		mcap.new_capability_id,
		ccgc.invert_capability_check,
		ccgc.force_terminate
		FROM csrimp.chain_card_group_card ccgc
		JOIN csrimp.map_chain_card mcc ON mcc.old_card_id = ccgc.card_id
		LEFT JOIN csrimp.map_chain_capability mcap ON mcap.old_capability_id = ccgc.required_capability_id;

	FOR c IN (
		SELECT card_id,
			   action
		  FROM csrimp.chain_card_progre_action
	) LOOP
			BEGIN
				INSERT INTO chain.card_progression_action (card_id, action)
					SELECT mcc.new_card_id, c.action
					  FROM csrimp.map_chain_card mcc
					 WHERE mcc.old_card_id = c.card_id;
			EXCEPTION
				WHEN OTHERS THEN
					null;  --do nothing, the row was already there
			END;
	END LOOP;

	INSERT INTO chain.card_group_progression(
		card_group_id,
		from_card_id,
		from_card_action,
		to_card_id
	)SELECT
		ccgp.card_group_id,
		mcc.new_card_id,
		ccgp.from_card_action,
		mcc2.new_card_id
	   FROM csrimp.chain_card_group_progression ccgp
	   JOIN csrimp.map_chain_card mcc ON mcc.old_card_id = ccgp.from_card_id
	   JOIN csrimp.map_chain_card mcc2 ON mcc2.old_card_id = ccgp.to_card_id;

	INSERT INTO chain.card_init_param(
		card_id,
		param_type_id,
		key,
		value,
		card_group_id
	)SELECT
		mcc.new_card_id,
		param_type_id,
		key,
		value,
		card_group_id
	   FROM csrimp.chain_card_init_param ccip
	   JOIN csrimp.map_chain_card mcc ON mcc.old_card_id = ccip.card_id;
END;

PROCEDURE CreateChainProductTypes
AS
BEGIN
	INSERT INTO chain.product_type(product_type_id, parent_product_type_id, label, lookup_key)
	SELECT mpt.new_product_type_id, mppt.new_product_type_id, pt.label, pt.lookup_key
	   FROM csrimp.chain_product_type pt
	   JOIN csrimp.map_chain_product_type mpt ON mpt.old_product_type_id = pt.product_type_id
  LEFT JOIN csrimp.map_chain_product_type mppt ON mppt.old_product_type_id = pt.parent_product_type_id
 START WITH product_type_id IN (SELECT product_type_id FROM csrimp.chain_product_type where parent_product_type_id IS NULL)
 CONNECT BY PRIOR product_type_id = parent_product_type_id;

	INSERT INTO chain.product_type_tr(product_type_id, lang, description, last_changed_dtm_description)
	SELECT mpt.new_product_type_id, cptt.lang, cptt.description, cptt.last_changed_dtm_description
	   FROM csrimp.chain_product_type_tr cptt
	   JOIN csrimp.map_chain_product_type mpt ON mpt.old_product_type_id = cptt.product_type_id;

	INSERT INTO chain.company_product_type(company_sid, product_type_id)
	SELECT mc.new_sid, mpt.new_product_type_id
	   FROM csrimp.chain_company_product_type cpt
	   JOIN csrimp.map_sid mc ON mc.old_sid = cpt.company_sid
	   JOIN csrimp.map_chain_product_type mpt ON mpt.old_product_type_id = cpt.product_type_id;

	INSERT INTO chain.product_type_tag(product_type_id, tag_id)
	SELECT mpt.new_product_type_id, mt.new_tag_id
	   FROM csrimp.chain_product_type_tag ptt
	   JOIN csrimp.map_chain_product_type mpt ON mpt.old_product_type_id = ptt.product_type_id
	   JOIN csrimp.map_tag mt ON mt.old_tag_id = ptt.tag_id;
END;

PROCEDURE GetMapInd(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ms.old_sid old_ind_sid, ms.new_sid new_ind_sid
		  FROM csrimp.map_sid ms, csrimp.ind i
		 WHERE i.ind_sid = ms.old_sid;
END;

PROCEDURE GetMapRegion(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ms.old_sid old_region_sid, ms.new_sid new_region_sid
		  FROM csrimp.map_sid ms, csrimp.region r
		 WHERE r.region_sid = ms.old_sid;
END;

PROCEDURE GetMapUser(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ms.old_sid old_user_sid, ms.new_sid new_user_sid
		  FROM csrimp.map_sid ms, csrimp.csr_user cu
		 WHERE cu.csr_user_sid = ms.old_sid;
END;

PROCEDURE GetMapPendingInd(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT old_pending_ind_id, new_pending_ind_id
		  FROM map_pending_ind;
END;

PROCEDURE GetMapPendingRegion(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT old_pending_region_id, new_pending_region_id
		  FROM map_pending_region;
END;

PROCEDURE GetMapPendingPeriod(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT old_pending_period_id, new_pending_period_id
		  FROM map_pending_period;
END;

PROCEDURE GetMapApprovalStep(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ms.old_sid old_approval_step_id, ms.new_sid new_approval_step_id
		  FROM csrimp.map_sid ms, csrimp.approval_step ass
		 WHERE ass.approval_step_id = ms.old_sid;
END;

PROCEDURE CreateChainMiscellaneous
AS
BEGIN
	INSERT INTO chain.amount_unit (
				amount_unit_id,
				conversion_to_base,
				description,
				unit_type
	   ) SELECT cau.amount_unit_id,
				cau.conversion_to_base,
				cau.description,
				cau.unit_type
		   FROM csrimp.chain_amount_unit cau;

	INSERT INTO chain.chain_user_email_address_log (
				email,
				last_modified_dtm,
				modified_by_sid,
				user_sid
	   ) SELECT ccueal.email,
				ccueal.last_modified_dtm,
				ms.new_sid,
				ms1.new_sid
		   FROM csrimp.chain_ch_use_ema_add_log ccueal,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE ccueal.modified_by_sid = ms.old_sid
			AND ccueal.user_sid = ms1.old_sid;

	INSERT INTO chain.default_product_code_type (
				code_label1,
				code_label2,
				code_label3
	   ) SELECT cdpct.code_label1,
				cdpct.code_label2,
				cdpct.code_label3
		   FROM csrimp.chain_def_prod_code_type cdpct;

	INSERT INTO chain.default_supp_rel_code_label (
				label,
				mandatory
	   ) SELECT cdsrcl.label,
				cdsrcl.mandatory
		   FROM csrimp.chain_de_sup_rel_cod_lab cdsrcl;

	INSERT INTO chain.email_stub (
				company_sid,
				lower_stub,
				stub
	   ) SELECT ms.new_sid,
				ces.lower_stub,
				ces.stub
		   FROM csrimp.chain_email_stub ces,
				csrimp.map_sid ms
		  WHERE ces.company_sid = ms.old_sid;

	INSERT INTO chain.ucd_logon (
				ucd_act_id,
				previous_act_id,
				previous_company_sid,
				previous_user_sid
	   ) SELECT cul.ucd_act_id,
				cul.previous_act_id,
				ms.new_sid,
				ms1.new_sid
		   FROM csrimp.chain_ucd_logon cul,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE cul.previous_company_sid = ms.old_sid(+)
			AND cul.previous_user_sid = ms1.old_sid;

	INSERT INTO chain.url_overrides (
				host,
				key,
				site_name,
				support_email
	   ) SELECT cuo.host,
				cuo.key,
				cuo.site_name,
				cuo.support_email
		   FROM csrimp.chain_url_overrides cuo;

	INSERT INTO chain.certification_type (
		certification_type_id,
		label,
		lookup_key,
		product_requirement_type_id
	) SELECT mcc.new_cert_type_id,
			 cc.label,
			 cc.lookup_key,
			 cc.product_requirement_type_id
		FROM csrimp.chain_certification_type cc
		JOIN csrimp.map_chain_cert_type mcc ON cc.certification_type_id = mcc.old_cert_type_id;

	INSERT INTO chain.cert_type_audit_type (
		certification_type_id,
		internal_audit_type_id
	) SELECT mcc.new_cert_type_id,
			 iat.new_internal_audit_type_id
		FROM csrimp.chain_cert_type_audit_type ccat
		JOIN csrimp.map_chain_cert_type mcc ON ccat.certification_type_id = mcc.old_cert_type_id
		JOIN csrimp.map_internal_audit_type iat ON ccat.internal_audit_type_id = iat.old_internal_audit_type_id;

END;

PROCEDURE CreateChainAudits
AS
BEGIN
	INSERT INTO chain.audit_request (
				audit_request_id,
				auditee_company_sid,
				auditor_company_sid,
				audit_sid,
				notes,
				proposed_dtm,
				requested_at_dtm,
				requested_by_company_sid,
				requested_by_user_sid
	   ) SELECT mcar.new_audit_request_id,
				ms.new_sid,
				ms1.new_sid,
				ms2.new_sid,
				car.notes,
				car.proposed_dtm,
				car.requested_at_dtm,
				ms3.new_sid,
				ms4.new_sid
		   FROM csrimp.chain_audit_request car,
				csrimp.map_chain_audit_request mcar,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_sid ms3,
				csrimp.map_sid ms4
		  WHERE car.audit_request_id = mcar.old_audit_request_id
			AND car.auditee_company_sid = ms.old_sid
			AND car.auditor_company_sid = ms1.old_sid
			AND car.audit_sid = ms2.old_sid(+)
			AND car.requested_by_company_sid = ms3.old_sid
			AND car.requested_by_user_sid = ms4.old_sid;

	INSERT INTO chain.audit_request_alert (
				audit_request_id,
				user_sid,
				sent_dtm
	   ) SELECT mcar.new_audit_request_id,
				ms.new_sid,
				cara.sent_dtm
		   FROM csrimp.chain_audit_reques_alert cara,
				csrimp.map_chain_audit_request mcar,
				csrimp.map_sid ms
		  WHERE cara.audit_request_id = mcar.old_audit_request_id
			AND cara.user_sid = ms.old_sid;

	INSERT INTO chain.supplier_audit (
				audit_sid,
				auditor_company_sid,
				created_by_company_sid,
				supplier_company_sid
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				ms2.new_sid,
				ms3.new_sid
		   FROM csrimp.chain_supplier_audit csa,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_sid ms3
		  WHERE csa.audit_sid = ms.old_sid
			AND csa.auditor_company_sid = ms1.old_sid
			AND csa.created_by_company_sid = ms2.old_sid
			AND csa.supplier_company_sid = ms3.old_sid;
END;

PROCEDURE CreateChainBusinessUnits
AS
BEGIN
	INSERT INTO chain.business_unit (
				business_unit_id,
				active,
				description,
				parent_business_unit_id
	   ) SELECT cbu.business_unit_id,
				cbu.active,
				cbu.description,
				cbu.parent_business_unit_id
		   FROM csrimp.chain_business_unit cbu;

	INSERT INTO chain.business_unit_member (
				business_unit_id,
				user_sid,
				is_primary_bu
	   ) SELECT cbum.business_unit_id,
				ms.new_sid,
				cbum.is_primary_bu
		   FROM csrimp.chain_busine_unit_member cbum,
				csrimp.map_sid ms
		  WHERE cbum.user_sid = ms.old_sid;

	INSERT INTO chain.business_unit_supplier (
				business_unit_id,
				supplier_company_sid,
				is_primary_bu
	   ) SELECT cbus.business_unit_id,
				ms.new_sid,
				cbus.is_primary_bu
		   FROM csrimp.chain_busine_unit_suppli cbus,
				csrimp.map_sid ms
		  WHERE cbus.supplier_company_sid = ms.old_sid;
END;

PROCEDURE CreateChainCompanies
AS
BEGIN
	INSERT INTO chain.company_cc_email (
				company_sid,
				lower_email,
				email
	   ) SELECT ms.new_sid,
				ccce.lower_email,
				ccce.email
		   FROM csrimp.chain_company_cc_email ccce,
				csrimp.map_sid ms
		  WHERE ccce.company_sid = ms.old_sid;

	INSERT INTO chain.company_header (company_header_id, page_company_type_id, plugin_id, plugin_type_id,
				pos, user_company_type_id, viewing_own_company, page_company_col_sid, user_company_col_sid)
		 SELECT mcch.new_company_header_id, mcct.new_company_type_id, mp.new_plugin_id, cch.plugin_type_id,
				cch.pos, mcct1.new_company_type_id, cch.viewing_own_company, mptc.new_column_id, mutc.new_column_id
		   FROM csrimp.chain_company_header cch,
				csrimp.map_chain_company_header mcch,
				csrimp.map_chain_company_type mcct,
				csrimp.map_plugin mp,
				csrimp.map_chain_company_type mcct1,
				csrimp.map_cms_tab_column mptc,
				csrimp.map_cms_tab_column mutc
		  WHERE cch.company_header_id = mcch.old_company_header_id
			AND cch.page_company_type_id = mcct.old_company_type_id
			AND cch.plugin_id = mp.old_plugin_id
			AND cch.user_company_type_id = mcct1.old_company_type_id
			AND cch.page_company_col_sid = mptc.old_column_id(+)
			AND cch.user_company_col_sid = mutc.old_column_id(+);

	INSERT INTO chain.company_metric_type (
				company_metric_type_id,
				class,
				description,
				max_value
	   ) SELECT ccmt.company_metric_type_id,
				ccmt.class,
				ccmt.description,
				ccmt.max_value
		   FROM csrimp.chain_compan_metric_type ccmt;

	INSERT INTO chain.company_metric (
				company_metric_type_id,
				company_sid,
				metric_value,
				normalised_value
	   ) SELECT ccm.company_metric_type_id,
				ms.new_sid,
				ccm.metric_value,
				ccm.normalised_value
		   FROM csrimp.chain_company_metric ccm,
				csrimp.map_sid ms
		  WHERE ccm.company_sid = ms.old_sid;

	INSERT INTO chain.reference (
				reference_id,
				lookup_key,
				depricated_reference_number,
				label,
				mandatory,
				reference_filter_type_id,
				reference_location_id,
				reference_uniqueness_id,
				reference_validation_id,
				show_in_filter
	   ) SELECT
				mcr.new_reference_id,
				cr.lookup_key,
				cr.depricated_reference_number,
				cr.label,
				cr.mandatory,
				cr.reference_filter_type_id,
				cr.reference_location_id,
				cr.reference_uniqueness_id,
				cr.reference_validation_id,
				show_in_filter
		   FROM csrimp.chain_reference cr,
				csrimp.map_chain_reference mcr
		  WHERE cr.reference_id = mcr.old_reference_id;

	INSERT INTO chain.reference_company_type (
				reference_id, company_type_id
	   ) SELECT mcr.new_reference_id, mcct.new_company_type_id
		   FROM csrimp.chain_reference_company_type crct
		   JOIN csrimp.map_chain_company_type mcct ON crct.company_type_id = mcct.old_company_type_id
		   JOIN csrimp.map_chain_reference mcr ON crct.reference_id = mcr.old_reference_id;

	INSERT INTO chain.reference_capability (
				reference_id,
				primary_company_type_id,
				primary_company_group_type_id,
				primary_company_type_role_sid,
				secondary_company_type_id,
				permission_set
	   ) SELECT mcr.new_reference_id, 
				mpct.new_company_type_id,
				crc.primary_company_group_type_id,
				ms.new_sid,
				msct.new_company_type_id,
				permission_set
		   FROM csrimp.chain_reference_capability crc
		   JOIN csrimp.map_chain_reference mcr ON crc.reference_id = mcr.old_reference_id
		   JOIN csrimp.map_chain_company_type mpct ON crc.primary_company_type_id = mpct.old_company_type_id
		   LEFT JOIN csrimp.map_sid ms ON crc.primary_company_type_role_sid = ms.old_sid
		   LEFT JOIN csrimp.map_chain_company_type msct ON crc.secondary_company_type_id = msct.old_company_type_id;

	INSERT INTO chain.company_reference (
				company_reference_id,
				reference_id,
				company_sid,
				value
	   ) SELECT chain.company_reference_id_seq.nextval,
				mcr.new_reference_id,
				ms.new_sid,
				ccr.value
		   FROM csrimp.chain_company_reference ccr,
				csrimp.map_sid ms,
				csrimp.map_chain_reference mcr
		  WHERE ccr.company_sid = ms.old_sid
			AND ccr.reference_id = mcr.old_reference_id;

	INSERT INTO chain.company_tag_group (
				company_sid,
				tag_group_id,
				applies_to_component,
				applies_to_purchase
	   ) SELECT ms.new_sid,
				mtg.new_tag_group_id,
				cctg.applies_to_component,
				cctg.applies_to_purchase
		   FROM csrimp.chain_company_tag_group cctg,
				csrimp.map_sid ms,
				csrimp.map_tag_group mtg
		  WHERE cctg.company_sid = ms.old_sid
			AND cctg.tag_group_id = mtg.old_tag_group_id;
	INSERT INTO chain.company_type_tag_group (
				company_type_id,
				tag_group_id
	   ) SELECT mcct.new_company_type_id,
				mtg.new_tag_group_id
		   FROM csrimp.chain_company_type_tag_group ccttg,
				csrimp.map_chain_company_type mcct,
				csrimp.map_tag_group mtg
		  WHERE ccttg.company_type_id = mcct.old_company_type_id
			AND ccttg.tag_group_id = mtg.old_tag_group_id;

	INSERT INTO chain.alt_company_name (
				alt_company_name_id,
				company_sid,
				name
	   ) SELECT mcacn.new_alt_company_name_id,
				ms.new_sid,
				cacn.name
		   FROM csrimp.map_chain_alt_company_name mcacn,
				csrimp.map_sid ms,
				csrimp.chain_alt_company_name cacn
		  WHERE cacn.company_sid = ms.old_sid
			AND cacn.alt_company_name_id = mcacn.old_alt_company_name_id;

	INSERT INTO chain.company_request_action (
				company_sid,
				matched_company_sid,
				action,
				is_processed,
				batch_job_id,
				error_message,
				error_detail
	   ) SELECT msc.new_sid,
				msm.new_sid,
				ccra.action,
				ccra.is_processed,
				NULL,
				ccra.error_message,
				ccra.error_detail
		   FROM csrimp.chain_company_request_action ccra,
				csrimp.map_sid msc,
				csrimp.map_sid msm
		  WHERE ccra.company_sid = msc.old_sid
			AND ccra.matched_company_sid = msm.old_sid(+);
END;

PROCEDURE CreateChainCompanyTabs
AS
BEGIN
	INSERT INTO chain.company_tab (company_tab_id, label, page_company_type_id, plugin_id,
				plugin_type_id, pos, user_company_type_id, viewing_own_company,
				options, page_company_col_sid, user_company_col_sid, flow_capability_id,
				business_relationship_type_id, supplier_restriction)
		 SELECT mcct.new_company_tab_id, cct.label, mcct1.new_company_type_id, mp.new_plugin_id,
				cct.plugin_type_id, cct.pos, mcct2.new_company_type_id, cct.viewing_own_company,
				options, mctc.new_column_id, mctc1.new_column_id, mcfc.new_customer_flow_cap_id,
				mcbrt.new_business_rel_type_id, cct.supplier_restriction
		   FROM csrimp.chain_company_tab cct,
				csrimp.map_chain_company_tab mcct,
				csrimp.map_chain_company_type mcct1,
				csrimp.map_plugin mp,
				csrimp.map_chain_company_type mcct2,
				csrimp.map_cms_tab_column mctc,
				csrimp.map_cms_tab_column mctc1,
				csrimp.map_customer_flow_cap mcfc,
				csrimp.map_chain_busin_rel_type mcbrt
		  WHERE cct.company_tab_id = mcct.old_company_tab_id
			AND cct.page_company_type_id = mcct1.old_company_type_id
			AND cct.plugin_id = mp.old_plugin_id
			AND cct.user_company_type_id = mcct2.old_company_type_id
			AND cct.page_company_col_sid = mctc.old_column_id(+)
			AND cct.user_company_col_sid = mctc1.old_column_id(+)
			AND cct.flow_capability_id = mcfc.old_customer_flow_cap_id(+)
			AND cct.business_relationship_type_id = mcbrt.old_business_rel_type_id(+);

	INSERT INTO chain.company_tab_related_co_type (company_tab_id, company_type_id)
		 SELECT mcctab.new_company_tab_id, mcctype.new_company_type_id
		   FROM csrimp.chain_co_tab_related_co_type cctrct
		   JOIN csrimp.map_chain_company_tab mcctab ON cctrct.company_tab_id = mcctab.old_company_tab_id
		   JOIN csrimp.map_chain_company_type mcctype ON cctrct.company_type_id = mcctype.old_company_type_id;

	INSERT INTO chain.company_tab_company_type_role (comp_tab_comp_type_role_id, company_tab_id, company_group_type_id, company_type_role_id)
		 SELECT mcctctr.new_comp_tab_comp_type_role_id, mcctab.new_company_tab_id, cctctr.company_group_type_id, mcctr.new_company_type_role_id
		   FROM csrimp.chain_comp_tab_comp_type_role cctctr
		   JOIN csrimp.map_chain_cmp_tab_cmp_typ_role mcctctr ON cctctr.comp_tab_comp_type_role_id = mcctctr.old_comp_tab_comp_type_role_id
		   JOIN csrimp.map_chain_company_tab mcctab ON cctctr.company_tab_id = mcctab.old_company_tab_id
		   JOIN csrimp.map_chain_company_type_role mcctr ON cctctr.company_type_role_id = mcctr.old_company_type_role_id
		  WHERE cctctr.company_group_type_id IS NULL
		  UNION
		 SELECT mcctctr.new_comp_tab_comp_type_role_id, mcctab.new_company_tab_id, cctctr.company_group_type_id, NULL
		   FROM csrimp.chain_comp_tab_comp_type_role cctctr
		   JOIN csrimp.map_chain_cmp_tab_cmp_typ_role mcctctr ON cctctr.comp_tab_comp_type_role_id = mcctctr.old_comp_tab_comp_type_role_id
		   JOIN csrimp.map_chain_company_tab mcctab ON cctctr.company_tab_id = mcctab.old_company_tab_id
		  WHERE cctctr.company_group_type_id IS NOT NULL
			AND cctctr.company_type_role_id IS NULL;
END;

PROCEDURE CreateChainProductTabs
AS
BEGIN
	INSERT INTO chain.product_header (
				product_header_id,
				plugin_id,
				plugin_type_id,
				pos,
				product_col_sid,
				product_company_type_id,
				user_company_col_sid,
				user_company_type_id,
				viewing_as_supplier,
				viewing_own_product
	   ) SELECT mcph.new_product_header_id,
				mp.new_plugin_id,
				cph.plugin_type_id,
				cph.pos,
				ms.new_sid,
				mcct.new_company_type_id,
				ms1.new_sid,
				mcct1.new_company_type_id,
				cph.viewing_as_supplier,
				cph.viewing_own_product
		   FROM csrimp.chain_product_header cph,
				csrimp.map_chain_product_header mcph,
				csrimp.map_plugin mp,
				csrimp.map_sid ms,
				csrimp.map_chain_company_type mcct,
				csrimp.map_sid ms1,
				csrimp.map_chain_company_type mcct1
		  WHERE cph.product_header_id = mcph.old_product_header_id
			AND cph.plugin_id = mp.old_plugin_id
			AND cph.product_col_sid = ms.old_sid(+)
			AND cph.product_company_type_id = mcct.old_company_type_id
			AND cph.user_company_col_sid = ms1.old_sid(+)
			AND cph.user_company_type_id = mcct1.old_company_type_id;

	INSERT INTO chain.product_header_product_type (
				product_header_id,
				product_type_id
	   ) SELECT mcph.new_product_header_id,
				mcpt.new_product_type_id
		   FROM csrimp.chain_pro_head_pro_type cphpt,
				csrimp.map_chain_product_header mcph,
				csrimp.map_chain_product_type mcpt
		  WHERE cphpt.product_header_id = mcph.old_product_header_id
			AND cphpt.product_type_id = mcpt.old_product_type_id;

	INSERT INTO chain.product_tab (
				product_tab_id,
				label,
				plugin_id,
				plugin_type_id,
				pos,
				product_col_sid,
				product_company_type_id,
				user_company_col_sid,
				user_company_type_id,
				viewing_as_supplier,
				viewing_own_product
	   ) SELECT mcpt.new_product_tab_id,
				cpt.label,
				mp.new_plugin_id,
				cpt.plugin_type_id,
				cpt.pos,
				ms.new_sid,
				mcct.new_company_type_id,
				ms1.new_sid,
				mcct1.new_company_type_id,
				cpt.viewing_as_supplier,
				cpt.viewing_own_product
		   FROM csrimp.chain_product_tab cpt,
				csrimp.map_chain_product_tab mcpt,
				csrimp.map_plugin mp,
				csrimp.map_sid ms,
				csrimp.map_chain_company_type mcct,
				csrimp.map_sid ms1,
				csrimp.map_chain_company_type mcct1
		  WHERE cpt.product_tab_id = mcpt.old_product_tab_id
			AND cpt.plugin_id = mp.old_plugin_id
			AND cpt.product_col_sid = ms.old_sid(+)
			AND cpt.product_company_type_id = mcct.old_company_type_id
			AND cpt.user_company_col_sid = ms1.old_sid(+)
			AND cpt.user_company_type_id = mcct1.old_company_type_id;

	INSERT INTO chain.product_tab_product_type (
				product_tab_id,
				product_type_id
	   ) SELECT mcpt.new_product_tab_id,
				mcpt1.new_product_type_id
		   FROM csrimp.chain_prod_tab_prod_type cptpt,
				csrimp.map_chain_product_tab mcpt,
				csrimp.map_chain_product_type mcpt1
		  WHERE cptpt.product_tab_id = mcpt.old_product_tab_id
			AND cptpt.product_type_id = mcpt1.old_product_type_id;

	INSERT INTO chain.product_supplier_tab (
				product_supplier_tab_id,
				label,
				plugin_id,
				plugin_type_id,
				pos,
				product_company_type_id,
				user_company_type_id,
				viewing_as_supplier,
				viewing_own_product
	   ) SELECT mcpst.new_product_supplier_tab_id,
				cpst.label,
				mp.new_plugin_id,
				cpst.plugin_type_id,
				cpst.pos,
				mcct.new_company_type_id,
				mcct1.new_company_type_id,
				cpst.viewing_as_supplier,
				cpst.viewing_own_product
		   FROM csrimp.chain_produc_supplie_tab cpst,
				csrimp.map_chain_product_supplier_tab mcpst,
				csrimp.map_plugin mp,
				csrimp.map_chain_company_type mcct,
				csrimp.map_chain_company_type mcct1
		  WHERE cpst.product_supplier_tab_id = mcpst.old_product_supplier_tab_id
			AND cpst.plugin_id = mp.old_plugin_id
			AND cpst.product_company_type_id = mcct.old_company_type_id
			AND cpst.user_company_type_id = mcct1.old_company_type_id;

	INSERT INTO chain.prod_supp_tab_product_type (
				product_supplier_tab_id,
				product_type_id
	   ) SELECT mcpst.new_product_supplier_tab_id,
				mcpt.new_product_type_id
		   FROM csrimp.chain_pr_sup_tab_pr_typ cpstpt,
				csrimp.map_chain_product_supplier_tab mcpst,
				csrimp.map_chain_product_type mcpt
		  WHERE cpstpt.product_supplier_tab_id = mcpst.old_product_supplier_tab_id
			AND cpstpt.product_type_id = mcpt.old_product_type_id;
END;

PROCEDURE CreateChainFilesAndFilters
AS
	v_plugin_id				plugin.plugin_id%TYPE;
BEGIN
	INSERT INTO chain.compound_filter (
				compound_filter_id,
				act_id,
				card_group_id,
				created_by_user_sid,
				created_dtm,
				operator_type
	   ) SELECT mccf.new_compound_filter_id,
				ccf.act_id,
				ccf.card_group_id,
				ms.new_sid,
				ccf.created_dtm,
				ccf.operator_type
		   FROM csrimp.chain_compound_filter ccf,
				csrimp.map_chain_compoun_filter mccf,
				csrimp.map_sid ms
		  WHERE ccf.compound_filter_id = mccf.old_compound_filter_id
			AND ccf.created_by_user_sid = ms.old_sid;

	INSERT INTO chain.file_upload (
				file_upload_sid,
				company_sid,
				data,
				download_permission_id,
				filename,
				lang,
				last_modified_by_sid,
				last_modified_dtm,
				mime_type,
				sha1
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				cfu.data,
				cfu.download_permission_id,
				cfu.filename,
				cfu.lang,
				ms2.new_sid,
				cfu.last_modified_dtm,
				cfu.mime_type,
				cfu.sha1
		   FROM csrimp.chain_file_upload cfu
	  LEFT JOIN	csrimp.map_sid ms on cfu.file_upload_sid = ms.old_sid
	  LEFT JOIN	csrimp.map_sid ms1 on cfu.company_sid = ms1.old_sid
      LEFT JOIN csrimp.map_sid ms2 on ms2.old_sid = cfu.LAST_MODIFIED_BY_SID
		  WHERE cfu.file_upload_sid = ms.old_sid
			AND cfu.company_sid = ms1.old_sid;

	INSERT INTO chain.file_group (
				file_group_id,
				company_sid,
				default_file_group_file_id,
				description,
				download_permission_id,
				file_group_model_id,
				guid,
				title
	   ) SELECT mcfg.new_file_group_id,
				ms.new_sid,
				mcfgf.new_file_group_file_id,
				cfg.description,
				cfg.download_permission_id,
				cfg.file_group_model_id,
				cfg.guid,
				cfg.title
		   FROM csrimp.chain_file_group cfg,
				csrimp.map_chain_file_group mcfg,
				csrimp.map_sid ms,
				csrimp.map_chain_file_grou_file mcfgf
		  WHERE cfg.file_group_id = mcfg.old_file_group_id
			AND cfg.company_sid = ms.old_sid(+)
			AND cfg.default_file_group_file_id = mcfgf.old_file_group_file_id(+);

	INSERT INTO chain.file_group_file (
				file_group_file_id,
				file_group_id,
				file_upload_sid
	   ) SELECT mcfgf.new_file_group_file_id,
				mcfg.new_file_group_id,
				ms.new_sid
		   FROM csrimp.chain_file_group_file cfgf,
				csrimp.map_chain_file_grou_file mcfgf,
				csrimp.map_chain_file_group mcfg,
				csrimp.map_sid ms
		  WHERE cfgf.file_group_file_id = mcfgf.old_file_group_file_id
			AND cfgf.file_group_id = mcfg.old_file_group_id
			AND cfgf.file_upload_sid = ms.old_sid;

	INSERT INTO chain.worksheet_file_upload (
				worksheet_id,
				file_upload_sid
	   ) SELECT mw.new_worksheet_id,
				ms.new_sid
		   FROM csrimp.chain_worksh_file_upload cwfu,
				csrimp.map_sid ms,
				csrimp.map_worksheet mw
		  WHERE cwfu.file_upload_sid = ms.old_sid
		    AND cwfu.worksheet_id = mw.old_worksheet_id;

	INSERT INTO chain.filter (
				filter_id,
				compound_filter_id,
				filter_type_id,
				operator_type
	   ) SELECT mcf.new_filter_id,
				mccf.new_compound_filter_id,
				mcft.new_filter_type_id,
				cf.operator_type
		   FROM csrimp.chain_filter cf,
				csrimp.map_chain_filter mcf,
				csrimp.map_chain_compoun_filter mccf,
				csrimp.map_chain_filter_type mcft
		  WHERE cf.filter_id = mcf.old_filter_id
			AND cf.compound_filter_id = mccf.old_compound_filter_id
			AND cf.filter_type_id = mcft.old_filter_type_id;

	INSERT INTO chain.filter_field (filter_field_id, comparator, filter_id,
				name, group_by_index, show_all, top_n, bottom_n, show_other,
				column_sid, period_set_id, period_interval_id
	   ) SELECT mcff.new_filter_field_id, cff.comparator, mcf.new_filter_id,
				CASE
					WHEN mcs.new_column_id IS NULL THEN cff.name
					WHEN cff.name LIKE 'BooleanField.%' THEN 'BooleanField.'||mcs.new_column_id
					WHEN cff.name LIKE 'ChildCmsFilter.%' THEN 'ChildCmsFilter.'||mcs.new_column_id
					WHEN cff.name LIKE 'CompanyCmsFilter.%' THEN 'CompanyCmsFilter.'||mcs.new_column_id
					WHEN cff.name LIKE 'ProductCmsFilter.%' THEN 'ProductCmsFilter.'||mcs.new_column_id
					WHEN cff.name LIKE 'DateField.%' THEN 'DateField.'||mcs.new_column_id
					WHEN cff.name LIKE 'EnumField.%' THEN 'EnumField.'||mcs.new_column_id
					WHEN cff.name LIKE 'NumberField.%' THEN 'NumberField.'||mcs.new_column_id
					WHEN cff.name LIKE 'PropertyCmsFilter.%' THEN 'PropertyCmsFilter.'||mcs.new_column_id
					WHEN cff.name LIKE 'RegionField.%' THEN 'RegionField.'||mcs.new_column_id
					WHEN cff.name LIKE 'SearchEnumField.%' THEN 'SearchEnumField.'||mcs.new_column_id
					WHEN cff.name LIKE 'TextField.%' THEN 'TextField.'||mcs.new_column_id
					WHEN cff.name LIKE 'UserField.%' THEN 'UserField.'||mcs.new_column_id
					ELSE cff.name
				END,
				cff.group_by_index, cff.show_all, cff.top_n,
				cff.bottom_n, cff.show_other, mcs.new_column_id, cff.period_set_id,
				cff.period_interval_id
		   FROM csrimp.chain_filter_field cff,
				csrimp.map_chain_filter_field mcff,
				csrimp.map_chain_filter mcf,
				csrimp.map_cms_tab_column mcs,
				chain.filter f
		  WHERE cff.filter_field_id = mcff.old_filter_field_id
			AND cff.filter_id = mcf.old_filter_id
			AND mcf.new_filter_id = f.filter_id
			AND cff.column_sid = mcs.old_column_id(+);

	INSERT INTO chain.saved_filter (
				saved_filter_sid, card_group_id, compound_filter_id, name, parent_sid,
				group_by_compound_filter_id, search_text, group_key, region_column_id,
				date_column_id, cms_region_column_sid, cms_date_column_sid,
				cms_id_column_sid, list_page_url, company_sid, exclude_from_reports, dual_axis, ranking_mode,
				order_direction, results_per_page, map_colour_by, map_cluster_bias, colour_range_id, colour_by, order_by, hide_empty)
		SELECT ms.new_sid, csf.card_group_id, mccf.new_compound_filter_id, csf.name,
				ms1.new_sid, mgbccf.new_compound_filter_id, csf.search_text, csf.group_key,
				csf.region_column_id, csf.date_column_id, mcrs.new_column_id, mcds.new_column_id,
				mcis.new_column_id, csf.list_page_url, msc.new_sid, csf.exclude_from_reports, csf.dual_axis,
				csf.ranking_mode, csf.order_direction, csf.results_per_page, csf.map_colour_by, csf.map_cluster_bias, csf.colour_range_id,
				-- Use the correct mapping based on the colour_by prefix
				CASE
					WHEN csf.colour_by LIKE('ind.%') THEN 'ind.' || cb_sid_map.new_sid
					WHEN csf.colour_by LIKE('metric.%') THEN 'metric.' || cb_sid_map.new_sid
					WHEN csf.colour_by LIKE('scoreTypeScore.%') THEN 'scoreTypeScore.' || cb_score_map.new_score_type_id
					ELSE csf.colour_by
				END colour_by,
				CASE
					WHEN csf.order_by_name LIKE '%cms.%' THEN csf.order_by_name || mtc.new_column_id
					WHEN csf.order_by_name LIKE '%regionTagGroup.%' THEN csf.order_by_name || mtg.new_tag_group_id
					WHEN csf.order_by_name LIKE '%tagGroup.%' THEN csf.order_by_name || mtg.new_tag_group_id
					WHEN csf.order_by_name LIKE '%score.%' THEN csf.order_by_name || mst.new_score_type_id
					WHEN csf.order_by_name LIKE '%customField.%' THEN csf.order_by_name || micf.new_issue_custom_field_id
					WHEN csf.order_by_name LIKE '%metric.%' THEN csf.order_by_name || mcs.new_sid
					WHEN csf.order_by_name LIKE '%role.%' THEN csf.order_by_name || mcs.new_sid
					WHEN csf.order_by_name LIKE '%userGroup.%' THEN csf.order_by_name || mcs.new_sid
					WHEN csf.order_by_name LIKE '%ind.%' THEN csf.order_by_name || mcs.new_sid
					ELSE csf.order_by_name
				END order_by,
				csf.hide_empty
		  FROM (
				-- Need to map number suffix from colour_by column to an id coloum so we can join that to the correct map table
				SELECT saved_filter_sid, compound_filter_id, card_group_id, parent_sid, name, group_by_compound_filter_id,
					search_text, group_key, region_column_id, date_column_id, cms_region_column_sid, cms_date_column_sid,
					cms_id_column_sid, list_page_url, exclude_from_reports, company_sid, dual_axis, ranking_mode,
					colour_range_id, colour_by, order_direction, results_per_page, map_colour_by, map_cluster_bias,
					REGEXP_SUBSTR(order_by, '[^\.]+\.?', 1, 1) order_by_name, -- order_by_name up to the first '.'
					REPLACE(REGEXP_SUBSTR(order_by, '\.\d+', 1, 1), '.', '') order_by_number,
					-- Note: Oracle regex doesn't support look-back (?<=x)
					CASE
						WHEN colour_by LIKE('ind.%') THEN REPLACE(REGEXP_SUBSTR(colour_by, '\.\d+', 1, 1), '.', '')
						WHEN colour_by LIKE('metric.%') THEN REPLACE(REGEXP_SUBSTR(colour_by, '\.\d+', 1, 1), '.', '')
						ELSE NULL
					END colour_by_sid,
					CASE
						WHEN colour_by LIKE('scoreTypeScore.%') THEN REPLACE(REGEXP_SUBSTR(colour_by, '\.\d+', 1, 1), '.', '')
						ELSE NULL
					END colour_by_score_type_id,
					hide_empty

				  FROM csrimp.chain_saved_filter
				) csf
		  JOIN map_sid ms ON csf.saved_filter_sid = ms.old_sid
		  JOIN map_chain_compoun_filter mccf ON csf.compound_filter_id = mccf.old_compound_filter_id
		  JOIN map_sid ms1 ON csf.parent_sid = ms1.old_sid
		  LEFT JOIN map_chain_compoun_filter mgbccf ON csf.group_by_compound_filter_id = mgbccf.old_compound_filter_id
		  LEFT JOIN map_cms_tab_column mcrs ON csf.cms_region_column_sid = mcrs.old_column_id
		  LEFT JOIN map_cms_tab_column mcds ON csf.cms_date_column_sid = mcds.old_column_id
		  LEFT JOIN map_cms_tab_column mcis ON csf.cms_id_column_sid = mcis.old_column_id
		  LEFT JOIN map_sid msc ON csf.company_sid = msc.old_sid
		  LEFT JOIN map_sid cb_sid_map ON csf.colour_by_sid = cb_sid_map.old_sid
		  LEFT JOIN map_score_type cb_score_map ON csf.colour_by_score_type_id = cb_score_map.old_score_type_id
		  LEFT JOIN map_sid mcs ON csf.order_by_number = mcs.old_sid
		  LEFT JOIN map_tag_group mtg ON csf.order_by_number = mtg.old_tag_group_id
		  LEFT JOIN map_score_type mst ON csf.order_by_number = mst.old_score_type_id
		  LEFT JOIN map_cms_tab_column mtc ON csf.order_by_number = mtc.old_column_id
		  LEFT JOIN map_issue_custom_field micf ON csf.order_by_number = micf.old_issue_custom_field_id;

	INSERT INTO chain.filter_value (
				filter_value_id, description, end_dtm_value, filter_field_id, max_num_val, min_num_val,
				num_value, region_sid, start_dtm_value, str_value, user_sid, compound_filter_id_value,
				saved_filter_sid_value, pos, period_set_id, period_interval_id, start_period_id, filter_type,
				null_filter, colour
	   ) SELECT mcfv.new_filter_value_id, cfv.description, cfv.end_dtm_value, mcff.new_filter_field_id,
				cfv.max_num_val, cfv.min_num_val, cfv.num_value, ms.new_sid, cfv.start_dtm_value,
				cfv.str_value, ms1.new_sid, mcf.new_compound_filter_id, msf.new_sid, cfv.pos, cfv.period_set_id,
				cfv.period_interval_id, cfv.start_period_id, cfv.filter_type, cfv.null_filter, cfv.colour
		   FROM csrimp.chain_filter_value cfv,
				csrimp.map_chain_filter_value mcfv,
				csrimp.map_chain_filter_field mcff,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_chain_compoun_filter mcf,
				csrimp.map_sid msf,
				chain.filter_field ff
		  WHERE cfv.filter_value_id = mcfv.old_filter_value_id
			AND cfv.filter_field_id = mcff.old_filter_field_id
			AND mcff.new_filter_field_id = ff.filter_field_id
			AND cfv.region_sid = ms.old_sid(+)
			AND cfv.user_sid = ms1.old_sid(+)
			AND cfv.compound_filter_id_value = mcf.old_compound_filter_id(+)
			AND cfv.saved_filter_sid_value = msf.old_sid(+);

	INSERT INTO chain.filter_page_column (card_group_id, label, pos, width, fixed_width,
				hidden, group_sid, include_in_export, session_prefix, group_key, column_name)
	SELECT fpc.card_group_id, fpc.label, fpc.pos,
		   fpc.width, fpc.fixed_width, fpc.hidden, ms.new_sid, fpc.include_in_export,
		   fpc.session_prefix, fpc.group_key,
		   CASE
				WHEN fpc.column_name LIKE '%cms.%' THEN fpc.column_name || mtc.new_column_id
				WHEN fpc.column_name LIKE '%regionTagGroup.%' THEN fpc.column_name || mtg.new_tag_group_id
				WHEN fpc.column_name LIKE '%tagGroup.%' THEN fpc.column_name || mtg.new_tag_group_id
				WHEN fpc.column_name LIKE '%score.%' THEN fpc.column_name || mst.new_score_type_id
				WHEN fpc.column_name LIKE '%customField.%' THEN fpc.column_name || micf.new_issue_custom_field_id
				WHEN fpc.column_name LIKE '%metric.%' THEN fpc.column_name || mcs.new_sid
				WHEN fpc.column_name LIKE '%role.%' THEN fpc.column_name || mcs.new_sid
				WHEN fpc.column_name LIKE '%userGroup.%' THEN fpc.column_name || mcs.new_sid
				WHEN fpc.column_name LIKE '%ind.%' THEN fpc.column_name || mcs.new_sid
				WHEN fpc.column_name LIKE '%groupSurvey%' THEN fpc.column_name || mitsg.new_ia_type_survey_group_id
				WHEN fpc.column_name LIKE '%inv.%' THEN fpc.column_name || mfit.new_flow_involvement_type_id
				WHEN fpc.column_name LIKE '%certification.%' THEN REPLACE (fpc.cert_column_name, '..', '.' || mcct.new_cert_type_id || '.')
				WHEN fpc.column_name LIKE '%ref.%' THEN fpc.column_name || mcr.new_reference_id
				ELSE fpc.column_name
			END column_name
		  FROM (
			SELECT card_group_id, label, pos, width, fixed_width, hidden, group_sid,
			       include_in_export, session_prefix, group_key,
			       TRANSLATE(column_name, 'a0123456789', 'a') cert_column_name,
			       REGEXP_SUBSTR(column_name, '[^\.]+\.?', 1, 1) column_name, -- column_name up to the first '.'
			       REPLACE(REGEXP_SUBSTR(column_name, '\.\d+', 1, 1), '.', '') column_number
			  FROM chain_filter_page_column fpc
			 ) fpc
		  LEFT JOIN map_sid ms ON fpc.group_sid = ms.old_sid
		  LEFT JOIN map_sid mcs ON fpc.column_number = mcs.old_sid
		  LEFT JOIN map_tag_group mtg ON fpc.column_number = mtg.old_tag_group_id
		  LEFT JOIN map_score_type mst ON fpc.column_number = mst.old_score_type_id
		  LEFT JOIN map_cms_tab_column mtc ON fpc.column_number = mtc.old_column_id
		  LEFT JOIN map_issue_custom_field micf ON fpc.column_number = micf.old_issue_custom_field_id
		  LEFT JOIN map_ia_type_survey_group mitsg ON fpc.column_number = mitsg.old_ia_type_survey_group_id
		  LEFT JOIN map_flow_involvement_type mfit ON fpc.column_number = mfit.old_flow_involvement_type_id
		  LEFT JOIN map_chain_cert_type mcct ON fpc.column_number = mcct.old_cert_type_id
		  LEFT JOIN map_chain_reference mcr ON fpc.column_number = mcr.old_reference_id;

	INSERT INTO chain.filter_item_config (card_group_id, card_id, item_name, label, pos,
		   group_sid, include_in_filter, include_in_breakdown, include_in_advanced, session_prefix,
		   path)
	SELECT fic.card_group_id, mc.new_card_id, fic.item_name, fic.label, fic.pos,
		   ms.new_sid, fic.include_in_filter, fic.include_in_breakdown, fic.include_in_advanced,
		   fic.session_prefix, fic.path
	  FROM csrimp.chain_filter_item_config fic
	  LEFT JOIN csrimp.map_sid ms ON fic.group_sid = ms.old_sid
	  LEFT JOIN csrimp.map_chain_card mc ON fic.card_id = mc.old_card_id;

	INSERT INTO chain.filter_page_ind (filter_page_ind_id, card_group_id, ind_sid,
				period_set_id, period_interval_id, start_dtm, end_dtm, previous_n_intervals,
				include_in_list, include_in_filter, include_in_aggregates, include_in_breakdown,
				show_measure_in_description, show_interval_in_description, description_override
	   ) SELECT mfpi.new_filter_page_ind_id, fpi.card_group_id, ms.new_sid,
				fpi.period_set_id, fpi.period_interval_id, fpi.start_dtm, fpi.end_dtm, fpi.previous_n_intervals,
				fpi.include_in_list, fpi.include_in_filter, fpi.include_in_aggregates, fpi.include_in_breakdown,
				fpi.show_measure_in_description, fpi.show_interval_in_description, fpi.description_override
		   FROM csrimp.chain_filter_page_ind fpi
		   JOIN csrimp.map_chain_filter_page_ind mfpi ON fpi.filter_page_ind_id = mfpi.old_filter_page_ind_id
		   JOIN csrimp.map_sid ms ON fpi.ind_sid = ms.old_sid;

	INSERT INTO chain.filter_page_ind_interval (filter_page_ind_interval_id, filter_page_ind_id,
				start_dtm, current_interval_offset
	   ) SELECT mfpii.new_filter_page_ind_intrvl_id, mfpi.new_filter_page_ind_id, fpii.start_dtm,
				fpii.current_interval_offset
		   FROM csrimp.chain_filter_page_ind_interval fpii
		   JOIN csrimp.map_chain_fltr_page_ind_intrvl mfpii ON fpii.filter_page_ind_interval_id = mfpii.old_filter_page_ind_intrvl_id
		   JOIN csrimp.map_chain_filter_page_ind mfpi ON fpii.filter_page_ind_id = mfpi.old_filter_page_ind_id;

	INSERT INTO chain.filter_page_cms_table (filter_page_cms_table_id, card_group_id, column_sid)
	SELECT mfpct.new_filter_page_cms_table_id, fpct.card_group_id, mtc.new_column_id
	  FROM csrimp.chain_filter_page_cms_table fpct
	  JOIN csrimp.map_chain_filter_page_cms_tab mfpct ON fpct.filter_page_cms_table_id = mfpct.old_filter_page_cms_table_id
	  JOIN csrimp.map_cms_tab_column mtc ON fpct.column_sid = mtc.old_column_id;

	INSERT INTO chain.aggregate_type_config (aggregate_type_id, label, pos,
		   group_sid, enabled, session_prefix, path, card_group_id)
	SELECT CASE WHEN atc.aggregate_type_id < 10000 THEN atc.aggregate_type_id ELSE mcat.new_customer_aggregate_type_id END,
		   atc.label, atc.pos, ms.new_sid, atc.enabled, atc.session_prefix, atc.path, atc.card_group_id
	  FROM csrimp.chain_aggregate_type_config atc
	  LEFT JOIN csrimp.map_sid ms ON atc.group_sid = ms.old_sid
	  LEFT JOIN csrimp.map_chain_custom_agg_type mcat ON atc.aggregate_type_id = mcat.old_customer_aggregate_type_id
	 WHERE atc.aggregate_type_id < 10000 OR mcat.new_customer_aggregate_type_id IS NOT NULL;

	INSERT INTO csr.score_type_agg_type (score_type_agg_type_id, analytic_function, score_type_id,
		   applies_to_nc_score, applies_to_primary_audit_survy, ia_type_survey_group_id, applies_to_audits)
	SELECT mstat.new_score_type_agg_type_id, analytic_function, mst.new_score_type_id,
		   applies_to_nc_score, applies_to_primary_audit_survy, mg.new_ia_type_survey_group_id, applies_to_audits
	  FROM score_type_agg_type stat
	  JOIN map_score_type_agg_type mstat ON stat.score_type_agg_type_id = mstat.old_score_type_agg_type_id
	  JOIN map_score_type mst ON stat.score_type_id = mst.old_score_type_id
	  LEFT JOIN map_ia_type_survey_group mg ON stat.ia_type_survey_group_id = mg.old_ia_type_survey_group_id;

	INSERT INTO chain.customer_grid_extension (grid_extension_id, enabled)
	SELECT grid_extension_id, enabled
	  FROM csrimp.chain_customer_grid_ext;

	INSERT INTO chain.customer_filter_item (
				customer_filter_item_id,
				can_breakdown,
				card_group_id,
				item_name,
				label,
				session_prefix
	   ) SELECT mccfi.new_chain_cust_filter_item_id,
				ccfi.can_breakdown,
				ccfi.card_group_id,
				ccfi.item_name,
				ccfi.label,
				ccfi.session_prefix
		   FROM csrimp.chain_custom_filter_item ccfi,
				csrimp.map_chain_cust_filt_item mccfi
		  WHERE ccfi.customer_filter_item_id = mccfi.old_chain_cust_filter_item_id;

	INSERT INTO chain.cust_filt_item_agg_type (
				cust_filt_item_agg_type_id,
				analytic_function,
				customer_filter_item_id
	   ) SELECT mccfiat.new_chain_cu_fi_ite_agg_typ_id,
				ccfiat.analytic_function,
				mccfi.new_chain_cust_filter_item_id
		   FROM csrimp.chain_cu_fil_ite_agg_typ ccfiat,
				csrimp.map_chain_cu_fi_it_ag_ty mccfiat,
				csrimp.map_chain_cust_filt_item mccfi
		  WHERE ccfiat.cust_filt_item_agg_type_id = mccfiat.old_chain_cu_fi_ite_agg_typ_id
			AND ccfiat.customer_filter_item_id = mccfi.old_chain_cust_filter_item_id;

	INSERT INTO chain.customer_aggregate_type (card_group_id, customer_aggregate_type_id, cms_aggregate_type_id,
				initiative_metric_id, ind_sid, filter_page_ind_interval_id, meter_aggregate_type_id,
				score_type_agg_type_id, cust_filt_item_agg_type_id
	   ) SELECT cuat.card_group_id, mccat.new_customer_aggregate_type_id, mcat.new_cms_aggregate_type_id,
				mim.new_initiative_metric_id, ms.new_sid, mfpii.new_filter_page_ind_intrvl_id, matid.new_meter_aggregate_type_id,
				mstat.new_score_type_agg_type_id, mccfiat.new_chain_cu_fi_ite_agg_typ_id
		   FROM chain_customer_aggregate_type cuat
		   LEFT JOIN map_chain_custom_agg_type mccat ON cuat.customer_aggregate_type_id = mccat.old_customer_aggregate_type_id
		   LEFT JOIN map_cms_aggregate_type mcat ON cuat.cms_aggregate_type_id = mcat.old_cms_aggregate_type_id
		   LEFT JOIN map_sid ms ON cuat.ind_sid = ms.old_sid
		   LEFT JOIN map_chain_fltr_page_ind_intrvl mfpii ON cuat.filter_page_ind_interval_id = mfpii.old_filter_page_ind_intrvl_id
		   LEFT JOIN map_meter_aggregate_type matid ON matid.old_meter_aggregate_type_id = cuat.meter_aggregate_type_id
		   LEFT JOIN map_score_type_agg_type mstat ON cuat.score_type_agg_type_id = mstat.old_score_type_agg_type_id
		   LEFT JOIN map_initiative_metric mim ON cuat.initiative_metric_id = mim.old_initiative_metric_id
		   LEFT JOIN map_chain_cu_fi_it_ag_ty mccfiat ON cuat.cust_filt_item_agg_type_id = mccfiat.old_chain_cu_fi_ite_agg_typ_id;

	INSERT INTO chain.filtersupplierreportlinks (
				label,
				report_url,
				position
	   ) SELECT cf.label,
				cf.report_url,
				position
		   FROM csrimp.chain_filtersupplierrepo cf;

	INSERT INTO chain.saved_filter_aggregation_type (
				saved_filter_sid, pos, aggregation_type, customer_aggregate_type_id
	   ) SELECT ms.new_sid, csfat.pos, csfat.aggregation_type, mcat.new_customer_aggregate_type_id
		   FROM csrimp.chain_saved_filter_agg_type csfat
		   JOIN csrimp.map_sid ms ON csfat.saved_filter_sid = ms.old_sid
		   LEFT JOIN csrimp.map_chain_custom_agg_type mcat ON csfat.customer_aggregate_type_id = mcat.old_customer_aggregate_type_id;

	INSERT INTO chain.saved_filter_column (saved_filter_sid, pos, width, label, column_name)
		SELECT ms.new_sid, csfc.pos, csfc.width, csfc.label,
			CASE
				WHEN csfc.column_name LIKE '%cms.%' THEN csfc.column_name || mtc.new_column_id
				WHEN csfc.column_name LIKE '%regionTagGroup.%' THEN csfc.column_name || mtg.new_tag_group_id
				WHEN csfc.column_name LIKE '%tagGroup.%' THEN csfc.column_name || mtg.new_tag_group_id
				WHEN csfc.column_name LIKE '%score.%' THEN csfc.column_name || mst.new_score_type_id
				WHEN csfc.column_name LIKE '%customField.%' THEN csfc.column_name || micf.new_issue_custom_field_id
				WHEN csfc.column_name LIKE '%metric.%' THEN csfc.column_name || mcs.new_sid
				WHEN csfc.column_name LIKE '%role.%' THEN csfc.column_name || mcs.new_sid
				WHEN csfc.column_name LIKE '%userGroup.%' THEN csfc.column_name || mcs.new_sid
				WHEN csfc.column_name LIKE '%ind.%' THEN csfc.column_name || mcs.new_sid
				WHEN csfc.column_name LIKE '%groupSurvey%' THEN csfc.column_name || mitsg.new_ia_type_survey_group_id
				WHEN csfc.column_name LIKE '%radioQuestion.%' THEN csfc.column_name || mq.new_question_id
				ELSE csfc.column_name
			END column_name
		  FROM (
			SELECT saved_filter_sid, pos, width, label,
			       REGEXP_SUBSTR(column_name, '[^\.]+\.?', 1, 1) column_name, -- column_name up to the first '.'
			       REPLACE(REGEXP_SUBSTR(column_name, '\.\d+', 1, 1), '.', '') column_number
			  FROM csrimp.chain_saved_filter_column csfc
			 ) csfc
		  JOIN csrimp.map_sid ms ON csfc.saved_filter_sid = ms.old_sid
		  LEFT JOIN csrimp.map_sid mcs ON csfc.column_number = mcs.old_sid
		  LEFT JOIN csrimp.map_tag_group mtg ON csfc.column_number = mtg.old_tag_group_id
		  LEFT JOIN csrimp.map_score_type mst ON csfc.column_number = mst.old_score_type_id
		  LEFT JOIN csrimp.map_cms_tab_column mtc ON csfc.column_number = mtc.old_column_id
		  LEFT JOIN csrimp.map_issue_custom_field micf ON csfc.column_number = micf.old_issue_custom_field_id
		  LEFT JOIN csrimp.map_ia_type_survey_group mitsg ON csfc.column_number = mitsg.old_ia_type_survey_group_id
		  LEFT JOIN csrimp.map_qs_question mq ON csfc.column_number = mq.old_question_id;

	INSERT INTO chain.saved_filter_region (saved_filter_sid, region_sid)
	     SELECT msf.new_sid, mr.new_sid
		   FROM csrimp.chain_saved_filter_region csfr
		   JOIN csrimp.map_sid msf ON csfr.saved_filter_sid = msf.old_sid
		   JOIN csrimp.map_sid mr ON csfr.region_sid = mr.old_sid;

	FOR p IN (
		SELECT plugin_id, plugin_type_id, description,
			   cs_class, js_class, js_include, details, preview_image_path,
			   mts.new_sid tab_sid, form_path, mf.new_sid form_sid, group_key, control_lookup_keys,
			   msfs.new_sid saved_filter_sid, result_mode, mps.new_sid portal_sid,
			   use_reporting_period, r_script_path, mpfs.new_sid pre_filter_sid
		   FROM csrimp.plugin pl
		   LEFT JOIN csrimp.map_sid mts ON pl.tab_sid = mts.old_sid
		   LEFT JOIN csrimp.map_sid msfs ON pl.saved_filter_sid = msfs.old_sid
		   LEFT JOIN csrimp.map_sid mpfs ON pl.pre_filter_sid = mpfs.old_sid
		   LEFT JOIN csrimp.map_sid mps ON pl.portal_sid = mps.old_sid
		   LEFT JOIN csrimp.map_sid mf on pl.form_sid = mf.old_sid
		  WHERE pl.saved_filter_sid IS NOT NULL OR pl.pre_filter_sid IS NOT NULL
	) LOOP
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description,
								cs_class, js_class, js_include, details, preview_image_path,
								tab_sid, form_path, form_sid, group_key, control_lookup_keys,
								result_mode, use_reporting_period, portal_sid, r_script_path,
								saved_filter_sid, pre_filter_sid)
			 VALUES (SYS_CONTEXT('SECURITY', 'APP'), csr.plugin_id_seq.NEXTVAL, p.plugin_type_id, p.description,
					p.cs_class, p.js_class, p.js_include, p.details, p.preview_image_path,
					p.tab_sid, p.form_path, p.form_sid, p.group_key, p.control_lookup_keys,
					p.result_mode, p.use_reporting_period, p.portal_sid, p.r_script_path,
					p.saved_filter_sid, p.pre_filter_sid)
		  RETURNING plugin_id INTO v_plugin_id;

		INSERT INTO csrimp.map_plugin (old_plugin_id, new_plugin_id)
					VALUES (p.plugin_id, v_plugin_id);
	END LOOP;

	INSERT INTO chain.flow_filter (
				flow_sid,
				saved_filter_sid
	   ) SELECT ms.new_sid,
				ms1.new_sid
		   FROM csrimp.chain_flow_filter cff,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE cff.flow_sid = ms.old_sid
			AND cff.saved_filter_sid = ms1.old_sid;

	INSERT INTO chain.saved_filter_alert (
				saved_filter_sid, users_can_subscribe, customer_alert_type_id,
				description, every_n_minutes,
				schedule_xml, next_fire_time, last_fire_time,
				alerts_sent_on_last_run
	   ) SELECT msf.new_sid, sfa.users_can_subscribe, mcat.new_customer_alert_type_id,
				sfa.description, sfa.every_n_minutes,
				sfa.schedule_xml, sfa.next_fire_time, sfa.last_fire_time,
				sfa.alerts_sent_on_last_run
		   FROM chain_saved_filter_alert sfa
		   JOIN map_sid msf ON sfa.saved_filter_sid = msf.old_sid
		   JOIN map_customer_alert_type mcat ON sfa.customer_alert_type_id = mcat.old_customer_alert_type_id;

	-- Mark all users as not having their initial set. This is easier than trying to map
	-- object_ids of chain.saved_filter_sent_alert and copes with cases where new filter
	-- types are added. On first run we'll prime each user, so one day's worth of updates will be lost.
	-- This should be acceptable for a copy
	INSERT INTO chain.saved_filter_alert_subscriptn (
				saved_filter_sid, user_sid, region_sid, has_had_initial_set, error_message
	   ) SELECT msf.new_sid, mu.new_sid, mr.new_sid, 0, sfas.error_message
		   FROM chain_saved_fltr_alrt_sbscrptn sfas
		   JOIN map_sid msf ON sfas.saved_filter_sid = msf.old_sid
		   JOIN map_sid mu ON sfas.user_sid = mu.old_sid
		   JOIN map_sid mr ON sfas.region_sid = mr.old_sid;

	INSERT INTO chain.customer_filter_column (
				customer_filter_column_id,
				card_group_id,
				column_name,
				fixed_width,
				label,
				session_prefix,
				sortable,
				width
	   ) SELECT mccfc.new_chain_cust_filter_colum_id,
				ccfc.card_group_id,
				ccfc.column_name,
				ccfc.fixed_width,
				ccfc.label,
				ccfc.session_prefix,
				ccfc.sortable,
				ccfc.width
		   FROM csrimp.chain_cust_filter_column ccfc,
				csrimp.map_chain_cust_filt_col mccfc
		  WHERE ccfc.customer_filter_column_id = mccfc.old_chain_cust_filter_colum_id;


END;

PROCEDURE CreateChainComponents
AS
BEGIN
	INSERT INTO chain.component_type (
				component_type_id
	   ) SELECT cct.component_type_id
		   FROM csrimp.chain_component_type cct;

	INSERT INTO chain.component_type_containment (
				container_component_type_id,
				child_component_type_id,
				allow_add_existing,
				allow_add_new
	   ) SELECT cctc.container_component_type_id,
				cctc.child_component_type_id,
				cctc.allow_add_existing,
				cctc.allow_add_new
		   FROM csrimp.chain_compon_type_contai cctc;

	INSERT INTO chain.component (
				component_id,
				amount_child_per_parent,
				amount_unit_id,
				company_sid,
				component_code,
				component_notes,
				component_type_id,
				created_by_sid,
				created_dtm,
				deleted,
				description,
				parent_component_id,
				parent_component_type_id,
				position
	   ) SELECT mcc.new_component_id,
				cc.amount_child_per_parent,
				cc.amount_unit_id,
				ms.new_sid,
				cc.component_code,
				cc.component_notes,
				cc.component_type_id,
				ms1.new_sid,
				cc.created_dtm,
				cc.deleted,
				cc.description,
				mcc1.new_component_id,
				cc.parent_component_type_id,
				cc.position
		   FROM csrimp.chain_component cc,
				csrimp.map_chain_component mcc,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_chain_component mcc1
		  WHERE cc.component_id = mcc.old_component_id
			AND cc.company_sid = ms.old_sid
			AND cc.created_by_sid = ms1.old_sid
			AND cc.parent_component_id = mcc1.old_component_id(+);

	INSERT INTO chain.component_document (
				component_id,
				file_upload_sid,
				key
	   ) SELECT mcc.new_component_id,
				ms.new_sid,
				ccd.key
		   FROM csrimp.chain_component_document ccd,
				csrimp.map_chain_component mcc,
				csrimp.map_sid ms
		  WHERE ccd.component_id = mcc.old_component_id
			AND ccd.file_upload_sid = ms.old_sid;

	INSERT INTO chain.component_source (
				card_group_id,
				card_text,
				component_type_id,
				description_xml,
				position,
				progression_action
	   ) SELECT ccs.card_group_id,
				ccs.card_text,
				ccs.component_type_id,
				ccs.description_xml,
				ccs.position,
				ccs.progression_action
		   FROM csrimp.chain_component_source ccs;

	INSERT INTO chain.component_tag (
				tag_id,
				component_id
	   ) SELECT mt.new_tag_id,
				mcc.new_component_id
		   FROM csrimp.chain_component_tag cct,
				csrimp.map_tag mt,
				csrimp.map_chain_component mcc
		  WHERE cct.tag_id = mt.old_tag_id
			AND cct.component_id = mcc.old_component_id;
END;

PROCEDURE CreateChainInvitations
AS
BEGIN
	INSERT INTO chain.invitation (
				invitation_id,
				accepted_dtm,
				accepted_reg_terms_vers,
				batch_job_id,
				cancelled_by_user_sid,
				cancelled_dtm,
				expiration_dtm,
				expiration_grace,
				from_company_sid,
				from_user_sid,
				guid,
				invitation_status_id,
				invitation_type_id,
				lang,
				on_behalf_of_company_sid,
				reinvitation_of_invitation_id,
				sent_dtm,
				to_company_sid,
				to_user_sid
	   ) SELECT mci.new_invitation_id,
				ci.accepted_dtm,
				ci.accepted_reg_terms_vers,
				null,
				ms.new_sid,
				ci.cancelled_dtm,
				ci.expiration_dtm,
				ci.expiration_grace,
				ms1.new_sid,
				ms2.new_sid,
				ci.guid,
				ci.invitation_status_id,
				ci.invitation_type_id,
				ci.lang,
				ms3.new_sid,
				mci1.new_invitation_id,
				ci.sent_dtm,
				ms4.new_sid,
				ms5.new_sid
		   FROM csrimp.chain_invitation ci,
				csrimp.map_chain_invitation mci,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_sid ms3,
				csrimp.map_chain_invitation mci1,
				csrimp.map_sid ms4,
				csrimp.map_sid ms5
		  WHERE ci.invitation_id = mci.old_invitation_id
			AND ci.cancelled_by_user_sid = ms.old_sid(+)
			AND ci.from_company_sid = ms1.old_sid(+)
			AND ci.from_user_sid = ms2.old_sid(+)
			AND ci.on_behalf_of_company_sid = ms3.old_sid(+)
			AND ci.reinvitation_of_invitation_id = mci1.old_invitation_id(+)
			AND ci.to_company_sid = ms4.old_sid
			AND ci.to_user_sid = ms5.old_sid;

	INSERT INTO chain.invitation_user_tpl (
				user_sid,
				lang,
				footer,
				header
	   ) SELECT ms.new_sid,
				ciut.lang,
				ciut.footer,
				ciut.header
		   FROM csrimp.chain_invitatio_user_tpl ciut,
				csrimp.map_sid ms
		  WHERE ciut.user_sid = ms.old_sid;

	INSERT INTO chain.questionnaire_group (
				group_name,
				description
	   ) SELECT cqg.group_name,
				cqg.description
		   FROM csrimp.chain_questionnair_group cqg;

	INSERT INTO chain.questionnaire_type (
				questionnaire_type_id,
				view_url,
				edit_url,
				owner_can_review,
				class,
				name,
				db_class,
				group_name,
				position,
				active,
				requires_review,
				reminder_offset_days,
				enable_reminder_alert,
				enable_overdue_alert,
				security_scheme_id,
				can_be_overdue,
				default_overdue_days,
				procurer_can_review,
				expire_after_months,
				auto_resend_on_expiry,
				is_resendable,
				enable_status_log,
				enable_transition_alert
	   ) SELECT mcqt.new_questionnaire_type_id,
				REPLACE(cqt.view_url, cqt.questionnaire_type_id, mcqt.new_questionnaire_type_id),
				REPLACE(cqt.edit_url, cqt.questionnaire_type_id, mcqt.new_questionnaire_type_id),
				cqt.owner_can_review,
				REPLACE(cqt.class, cqt.questionnaire_type_id, mcqt.new_questionnaire_type_id),
				cqt.name,
				cqt.db_class,
				cqt.group_name,
				cqt.position,
				cqt.active,
				cqt.requires_review,
				cqt.reminder_offset_days,
				cqt.enable_reminder_alert,
				cqt.enable_overdue_alert,
				cqt.security_scheme_id,
				cqt.can_be_overdue,
				cqt.default_overdue_days,
				cqt.procurer_can_review,
				cqt.expire_after_months,
				cqt.auto_resend_on_expiry,
				cqt.is_resendable,
				cqt.enable_status_log,
				cqt.enable_transition_alert
		   FROM csrimp.chain_questionnaire_type cqt,
				csrimp.map_chain_questionn_type mcqt
		  WHERE cqt.questionnaire_type_id = mcqt.old_questionnaire_type_id;

	-- fix helper procedures to point at any remapped cms schemas
	UPDATE chain.questionnaire_type
	   SET db_class = MapCustomerSchema(db_class)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO chain.flow_questionnaire_type (
				flow_sid,
				questionnaire_type_id
	   ) SELECT ms.new_sid,
				mcqt.new_questionnaire_type_id
		   FROM csrimp.chain_flow_question_type cfqt,
				csrimp.map_sid ms,
				csrimp.map_chain_questionn_type mcqt
		  WHERE cfqt.flow_sid = ms.old_sid
			AND cfqt.questionnaire_type_id = mcqt.old_questionnaire_type_id;

	INSERT INTO chain.invitation_qnr_type (
				invitation_id,
				questionnaire_type_id,
				added_by_user_sid,
				requested_due_dtm
	   ) SELECT mci.new_invitation_id,
				mcqt.new_questionnaire_type_id,
				ms.new_sid,
				ciqt.requested_due_dtm
		   FROM csrimp.chain_invitatio_qnr_type ciqt,
				csrimp.map_chain_invitation mci,
				csrimp.map_chain_questionn_type mcqt,
				csrimp.map_sid ms
		  WHERE ciqt.invitation_id = mci.old_invitation_id
			AND ciqt.questionnaire_type_id = mcqt.old_questionnaire_type_id
			AND ciqt.added_by_user_sid = ms.old_sid;

	INSERT INTO chain.invitation_qnr_type_component (
				invitation_id,
				questionnaire_type_id,
				component_id
	   ) SELECT mci.new_invitation_id,
				mcqt.new_questionnaire_type_id,
				mcc.new_component_id
		   FROM csrimp.chain_invi_qnr_type_comp ciqtc,
				csrimp.map_chain_invitation mci,
				csrimp.map_chain_questionn_type mcqt,
				csrimp.map_chain_component mcc
		  WHERE ciqtc.invitation_id = mci.old_invitation_id
			AND ciqtc.questionnaire_type_id = mcqt.old_questionnaire_type_id
			AND ciqtc.component_id = mcc.old_component_id;

	INSERT INTO chain.message (
				message_id,
				action_id,
				completed_by_user_sid,
				completed_dtm,
				due_dtm,
				event_id,
				message_definition_id,
				re_audit_request_id,
				re_company_sid,
				re_component_id,
				re_invitation_id,
				re_questionnaire_type_id,
				re_secondary_company_sid,
				re_user_sid
	   ) SELECT mcm.new_message_id,
				cm.action_id,
				ms.new_sid,
				cm.completed_dtm,
				cm.due_dtm,
				cm.event_id,
				mcmd.new_message_definition_id,
				mcar.new_audit_request_id,
				ms1.new_sid,
				mcc.new_component_id,
				mci.new_invitation_id,
				mcqt.new_questionnaire_type_id,
				ms2.new_sid,
				ms3.new_sid
		   FROM csrimp.chain_message cm,
				csrimp.map_chain_message mcm,
				csrimp.map_sid ms,
				csrimp.map_chain_messag_definit mcmd,
				csrimp.map_chain_audit_request mcar,
				csrimp.map_sid ms1,
				csrimp.map_chain_component mcc,
				csrimp.map_chain_invitation mci,
				csrimp.map_chain_questionn_type mcqt,
				csrimp.map_sid ms2,
				csrimp.map_sid ms3
		  WHERE cm.message_id = mcm.old_message_id
			AND cm.completed_by_user_sid = ms.old_sid(+)
			AND cm.message_definition_id = mcmd.old_message_definition_id
			AND cm.re_audit_request_id = mcar.old_audit_request_id(+)
			AND cm.re_company_sid = ms1.old_sid(+)
			AND cm.re_component_id = mcc.old_component_id(+)
			AND cm.re_invitation_id = mci.old_invitation_id(+)
			AND cm.re_questionnaire_type_id = mcqt.old_questionnaire_type_id(+)
			AND cm.re_secondary_company_sid = ms2.old_sid(+)
			AND cm.re_user_sid = ms3.old_sid(+);
END;

PROCEDURE CreateChainAlerts
AS
BEGIN
	INSERT INTO chain.alert_entry (
				alert_entry_id,
				alert_entry_type_id,
				company_sid,
				message_id,
				occurred_dtm,
				owner_scheduled_alert_id,
				priority,
				template_name,
				user_sid
	   ) SELECT mcae.new_alert_entry_id,
				cae.alert_entry_type_id,
				ms.new_sid,
				mcm.new_message_id,
				cae.occurred_dtm,
				mcsa.new_scheduled_alert_id,
				cae.priority,
				cae.template_name,
				ms1.new_sid
		   FROM csrimp.chain_alert_entry cae,
				csrimp.map_chain_alert_entry mcae,
				csrimp.map_sid ms,
				csrimp.map_chain_message mcm,
				csrimp.map_chain_schedule_alert mcsa,
				csrimp.map_sid ms1
		  WHERE cae.alert_entry_id = mcae.old_alert_entry_id
			AND cae.company_sid = ms.old_sid(+)
			AND cae.message_id = mcm.old_message_id(+)
			AND cae.owner_scheduled_alert_id = mcsa.old_scheduled_alert_id(+)
			AND cae.user_sid = ms1.old_sid;

	INSERT INTO chain.alert_entry_param (
				alert_entry_id,
				name,
				value
	   ) SELECT mcae.new_alert_entry_id,
				caep.name,
				caep.value
		   FROM csrimp.chain_alert_entry_param caep,
				csrimp.map_chain_alert_entry mcae
		  WHERE caep.alert_entry_id = mcae.old_alert_entry_id;

	INSERT INTO chain.alert_partial_template (
				alert_type_id,
				partial_template_type_id,
				lang,
				partial_html
	   ) SELECT capt.alert_type_id,
				capt.partial_template_type_id,
				capt.lang,
				capt.partial_html
		   FROM csrimp.chain_alert_parti_templa capt;

	INSERT INTO chain.alert_partial_template_param (
				alert_type_id,
				partial_template_type_id,
				field_name
	   ) SELECT captp.alert_type_id,
				captp.partial_template_type_id,
				captp.field_name
		   FROM csrimp.chain_ale_part_temp_para captp;

	INSERT INTO chain.user_alert_entry_type (
				alert_entry_type_id,
				user_sid,
				enabled,
				schedule_xml
	   ) SELECT cuaet.alert_entry_type_id,
				ms.new_sid,
				cuaet.enabled,
				cuaet.schedule_xml
		   FROM csrimp.chain_use_aler_entr_type cuaet,
				csrimp.map_sid ms
		  WHERE cuaet.user_sid = ms.old_sid;

	INSERT INTO chain.review_alert (
				review_alert_id,
				from_company_sid,
				from_user_sid,
				sent_dtm,
				to_company_sid,
				to_user_sid
	   ) SELECT cra.review_alert_id,
				ms.new_sid,
				ms1.new_sid,
				cra.sent_dtm,
				ms2.new_sid,
				ms3.new_sid
		   FROM csrimp.chain_review_alert cra,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_sid ms3
		  WHERE cra.from_company_sid = ms.old_sid
			AND cra.from_user_sid = ms1.old_sid
			AND cra.to_company_sid = ms2.old_sid
			AND cra.to_user_sid = ms3.old_sid;

	INSERT INTO chain.scheduled_alert (
				scheduled_alert_id,
				user_sid,
				alert_entry_type_id,
				sent_dtm
	   ) SELECT mcsa.new_scheduled_alert_id,
				ms.new_sid,
				csa.alert_entry_type_id,
				csa.sent_dtm
		   FROM csrimp.chain_scheduled_alert csa,
				csrimp.map_chain_schedule_alert mcsa,
				csrimp.map_sid ms
		  WHERE csa.scheduled_alert_id = mcsa.old_scheduled_alert_id
			AND csa.user_sid = ms.old_sid;

	INSERT INTO chain.customer_alert_entry_template (
				alert_entry_type_id,
				template_name,
				template
	   ) SELECT ccaet.alert_entry_type_id,
				ccaet.template_name,
				ccaet.template
		   FROM csrimp.chain_cus_aler_entr_temp ccaet;

	INSERT INTO chain.customer_alert_entry_type (
				alert_entry_type_id,
				company_section_template,
				enabled,
				force_disable,
				generator_sp,
				important_section_template,
				schedule_xml,
				user_section_template
	   ) SELECT ccaet.alert_entry_type_id,
				ccaet.company_section_template,
				ccaet.enabled,
				ccaet.force_disable,
				ccaet.generator_sp,
				ccaet.important_section_template,
				ccaet.schedule_xml,
				ccaet.user_section_template
		   FROM csrimp.chain_cus_aler_entr_type ccaet;

	INSERT INTO chain.product_company_alert (
				alert_id,
				company_product_id,
				purchaser_company_sid,
				supplier_company_sid,
				user_sid,
				sent_dtm
	   ) SELECT ccpa.alert_id,
				ccpa.company_product_id,
				ms1.new_sid,
				ms2.new_sid,
				ms3.new_sid,
				ccpa.sent_dtm
		   FROM csrimp.chain_product_company_alert ccpa,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_sid ms3
		  WHERE ccpa.purchaser_company_sid = ms1.old_sid
			AND ccpa.supplier_company_sid = ms2.old_sid
			AND ccpa.user_sid = ms3.old_sid;
END;

PROCEDURE CreateChainMessages
AS
BEGIN
		INSERT INTO chain.message_definition (
					message_definition_id,
					completed_template,
					completion_type_id,
					css_class,
					helper_pkg,
					message_priority_id,
					message_template
		   ) SELECT mcmd.new_message_definition_id,
					cmd.completed_template,
					cmd.completion_type_id,
					cmd.css_class,
					cmd.helper_pkg,
					cmd.message_priority_id,
					cmd.message_template
			   FROM csrimp.chain_message_definition cmd,
					csrimp.map_chain_messag_definit mcmd
			  WHERE cmd.message_definition_id = mcmd.old_message_definition_id;

		INSERT INTO chain.message_param (
					message_definition_id,
					param_name,
					css_class,
					href,
				value
	   ) SELECT mcmd.new_message_definition_id,
				cmp.param_name,
				cmp.css_class,
				cmp.href,
				cmp.value
		   FROM csrimp.chain_message_param cmp,
				csrimp.map_chain_messag_definit mcmd
		  WHERE cmp.message_definition_id = mcmd.old_message_definition_id;

	INSERT INTO chain.recipient (
				recipient_id,
				to_company_sid,
				to_user_sid
	   ) SELECT mcr.new_recipient_id,
				ms.new_sid,
				ms1.new_sid
		   FROM csrimp.chain_recipient cr,
				csrimp.map_chain_recipient mcr,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE cr.recipient_id = mcr.old_recipient_id
			AND cr.to_company_sid = ms.old_sid(+)
			AND cr.to_user_sid = ms1.old_sid(+);

	INSERT INTO chain.message_recipient (
				message_id,
				recipient_id
	   ) SELECT mcm.new_message_id,
				mcr.new_recipient_id
		   FROM csrimp.chain_message_recipient cmr,
				csrimp.map_chain_message mcm,
				csrimp.map_chain_recipient mcr
		  WHERE cmr.message_id = mcm.old_message_id
			AND cmr.recipient_id = mcr.old_recipient_id;

	INSERT INTO chain.message_refresh_log (
				message_id,
				refresh_index,
				refresh_dtm,
				refresh_user_sid
	   ) SELECT mcm.new_message_id,
				cmrl.refresh_index,
				cmrl.refresh_dtm,
				ms.new_sid
		   FROM csrimp.chain_messag_refresh_log cmrl,
				csrimp.map_chain_message mcm,
				csrimp.map_sid ms
		  WHERE cmrl.message_id = mcm.old_message_id
			AND cmrl.refresh_user_sid = ms.old_sid;

	INSERT INTO chain.newsflash (
				newsflash_id,
				content,
				created_dtm,
				expired_dtm,
				released_dtm
	   ) SELECT mcn.new_newsflash_id,
				cn.content,
				cn.created_dtm,
				cn.expired_dtm,
				cn.released_dtm
		   FROM csrimp.chain_newsflash cn,
				csrimp.map_chain_newsflash mcn
		  WHERE cn.newsflash_id = mcn.old_newsflash_id;

	INSERT INTO chain.newsflash_company (
				newsflash_id,
				company_sid,
				for_suppliers,
				for_users
	   ) SELECT mcn.new_newsflash_id,
				ms.new_sid,
				cnc.for_suppliers,
				cnc.for_users
		   FROM csrimp.chain_newsflash_company cnc,
				csrimp.map_chain_newsflash mcn,
				csrimp.map_sid ms
		  WHERE cnc.newsflash_id = mcn.old_newsflash_id
			AND cnc.company_sid = ms.old_sid;

	INSERT INTO chain.newsflash_user_settings (
				newsflash_id,
				user_sid,
				hidden
	   ) SELECT mcn.new_newsflash_id,
				ms.new_sid,
				cnus.hidden
		   FROM csrimp.chain_newsfl_user_settin cnus,
				csrimp.map_chain_newsflash mcn,
				csrimp.map_sid ms
		  WHERE cnus.newsflash_id = mcn.old_newsflash_id
			AND cnus.user_sid = ms.old_sid;
END;

PROCEDURE CreateChainProducts
AS
BEGIN
	INSERT INTO chain.product (
				product_id
	   ) SELECT mcp.new_product_id
		   FROM csrimp.chain_product cp,
				csrimp.map_chain_product mcp
		  WHERE cp.product_id = mcp.old_product_id;

	INSERT INTO chain.product_code_type (
				company_sid,
				code2_mandatory,
				code3_mandatory,
				code_label1,
				code_label2,
				code_label3,
				mapping_approval_required
	   ) SELECT ms.new_sid,
				cpct.code2_mandatory,
				cpct.code3_mandatory,
				cpct.code_label1,
				cpct.code_label2,
				cpct.code_label3,
				cpct.mapping_approval_required
		   FROM csrimp.chain_product_code_type cpct,
				csrimp.map_sid ms
		  WHERE cpct.company_sid = ms.old_sid;

	INSERT INTO chain.product_metric_type (
				product_metric_type_id,
				class,
				description,
				max_score
	   ) SELECT cpmt.product_metric_type_id,
				cpmt.class,
				cpmt.description,
				cpmt.max_score
		   FROM csrimp.chain_produc_metric_type cpmt;

	INSERT INTO chain.product_revision (
				product_id,
				revision_num,
				active,
				code2,
				code3,
				last_published_by_user_sid,
				last_published_dtm,
				need_review,
				notes,
				previous_end_dtm,
				previous_rev_number,
				supplier_root_component_id,
				published,
				revision_created_by_sid,
				revision_end_dtm,
				revision_start_dtm,
				validated_root_component_id,
				validation_status_id
	   ) SELECT mcp.new_product_id,
				cpr.revision_num,
				cpr.active,
				cpr.code2,
				cpr.code3,
				ms.new_sid,
				cpr.last_published_dtm,
				cpr.need_review,
				cpr.notes,
				cpr.previous_end_dtm,
				cpr.previous_rev_number,
				mcc.new_component_id,
				cpr.published,
				ms1.new_sid,
				cpr.revision_end_dtm,
				cpr.revision_start_dtm,
				mcc1.new_component_id,
				cpr.validation_status_id
		   FROM csrimp.chain_product_revision cpr,
				csrimp.map_chain_product mcp,
				csrimp.map_sid ms,
				csrimp.map_chain_component mcc,
				csrimp.map_sid ms1,
				csrimp.map_chain_component mcc1
		  WHERE cpr.product_id = mcp.old_product_id
			AND cpr.last_published_by_user_sid = ms.old_sid(+)
			AND cpr.supplier_root_component_id = mcc.old_component_id
			AND cpr.revision_created_by_sid = ms1.old_sid
			AND cpr.validated_root_component_id = mcc1.old_component_id(+);

   INSERT INTO chain.uninvited_supplier (
				company_sid,
				uninvited_supplier_sid,
				country_code,
				created_as_company_sid,
				name,
				supp_rel_code
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				cus.country_code,
				ms2.new_sid,
				cus.name,
				cus.supp_rel_code
		   FROM csrimp.chain_uninvited_supplier cus,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2
		  WHERE cus.company_sid = ms.old_sid
			AND cus.uninvited_supplier_sid = ms1.old_sid
			AND cus.created_as_company_sid = ms2.old_sid(+);

	INSERT INTO chain.purchase_channel (
				company_sid,
				purchase_channel_id,
				description,
				region_sid
	   ) SELECT ms.new_sid,
				cpc.purchase_channel_id,
				cpc.description,
				ms1.new_sid
		   FROM csrimp.chain_purchase_channel cpc,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE cpc.company_sid = ms.old_sid
			AND cpc.region_sid = ms1.old_sid(+);

	INSERT INTO chain.purchased_component (
				component_id,
				acceptance_status_id,
				company_sid,
				component_supplier_type_id,
				component_type_id,
				mapped_by_user_sid,
				mapped_dtm,
				previous_purch_component_id,
				purchases_locked,
				supplier_company_sid,
				supplier_product_id,
				uninvited_supplier_sid
	   ) SELECT mcc.new_component_id,
				cpc.acceptance_status_id,
				ms.new_sid,
				cpc.component_supplier_type_id,
				cpc.component_type_id,
				ms1.new_sid,
				cpc.mapped_dtm,
				mcc1.new_component_id,
				cpc.purchases_locked,
				ms2.new_sid,
				mcp.new_product_id,
				ms3.new_sid
		   FROM csrimp.chain_purchase_component cpc,
				csrimp.map_chain_component mcc,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_chain_component mcc1,
				csrimp.map_sid ms2,
				csrimp.map_chain_product mcp,
				csrimp.map_sid ms3
		  WHERE cpc.component_id = mcc.old_component_id
			AND cpc.company_sid = ms.old_sid
			AND cpc.mapped_by_user_sid = ms1.old_sid(+)
			AND cpc.previous_purch_component_id = mcc1.old_component_id(+)
			AND cpc.supplier_company_sid = ms2.old_sid(+)
			AND cpc.supplier_product_id = mcp.old_product_id(+)
			AND cpc.uninvited_supplier_sid = ms3.old_sid(+);

	INSERT INTO chain.purchase (
				purchase_id,
				amount,
				amount_unit_id,
				end_date,
				invoice_number,
				note,
				component_id,
				purchaser_company_sid,
				purchase_channel_id,
				purchase_order,
				start_date
	   ) SELECT mcp.new_purchase_id,
				cp.amount,
				cp.amount_unit_id,
				cp.end_date,
				cp.invoice_number,
				cp.note,
				mcc.new_component_id,
				ms.new_sid,
				cp.purchase_channel_id,
				cp.purchase_order,
				cp.start_date
		   FROM csrimp.chain_purchase cp,
				csrimp.map_chain_purchase mcp,
				csrimp.map_chain_component mcc,
				csrimp.map_sid ms
		  WHERE cp.purchase_id = mcp.old_purchase_id
			AND cp.component_id = mcc.old_component_id
			AND cp.purchaser_company_sid = ms.old_sid;

	INSERT INTO chain.purchase_tag (
				tag_id,
				purchase_id
	   ) SELECT mt.new_tag_id,
				mcp.new_purchase_id
		   FROM csrimp.chain_purchase_tag cpt,
				csrimp.map_tag mt,
				csrimp.map_chain_purchase mcp
		  WHERE cpt.tag_id = mt.old_tag_id
			AND cpt.purchase_id = mcp.old_purchase_id;

	INSERT INTO chain.purchaser_follower (
				purchaser_company_sid,
				supplier_company_sid,
				user_sid
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				ms2.new_sid
		   FROM csrimp.chain_purchaser_follower cpf,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2
		  WHERE cpf.purchaser_company_sid = ms.old_sid
			AND cpf.supplier_company_sid = ms1.old_sid
			AND cpf.user_sid = ms2.old_sid;

	INSERT INTO chain.validated_purchased_component (
				component_id,
				mapped_purchased_component_id
	   ) SELECT mcc.new_component_id,
				mcc1.new_component_id
		   FROM csrimp.chain_valid_purch_compon cvpc,
				csrimp.map_chain_component mcc,
				csrimp.map_chain_component mcc1
		  WHERE cvpc.component_id = mcc.old_component_id
			AND cvpc.mapped_purchased_component_id = mcc1.old_component_id(+);

	INSERT INTO chain.product_metric (
				ind_sid,
				applies_to_product,
				applies_to_prod_supplier,
				product_metric_icon_id,
				is_mandatory,
				show_measure
	   ) SELECT ms.new_sid ind_sid,
	   			cpm.applies_to_product,
				cpm.applies_to_prod_supplier,
				product_metric_icon_id,
				is_mandatory,
				show_measure
		   FROM csrimp.chain_product_metric cpm
		   JOIN csrimp.map_sid ms ON ms.old_sid = cpm.ind_sid;

	INSERT INTO chain.product_metric_product_type (
				ind_sid,
				product_type_id
	   ) SELECT ms.new_sid,
	   			mcpt.new_product_type_id
		   FROM csrimp.chain_prd_mtrc_prd_type cpmpt
		   JOIN csrimp.map_sid ms ON ms.old_sid = cpmpt.ind_sid
		   JOIN csrimp.map_chain_product_type mcpt ON cpmpt.product_type_id = mcpt.old_product_type_id;

END;

PROCEDURE CreateChainQuestionnaires
AS
BEGIN
	INSERT INTO chain.qnr_action_security_mask (
				questionnaire_type_id,
				company_function_id,
				questionnaire_action_id,
				action_security_type_id
	   ) SELECT mcqt.new_questionnaire_type_id,
				cqasm.company_function_id,
				cqasm.questionnaire_action_id,
				cqasm.action_security_type_id
		   FROM csrimp.chain_qnr_acti_secu_mask cqasm,
				csrimp.map_chain_questionn_type mcqt
		  WHERE cqasm.questionnaire_type_id = mcqt.old_questionnaire_type_id;

	INSERT INTO chain.questionnaire (
				questionnaire_id,
				company_sid,
				component_id,
				created_dtm,
				description,
				questionnaire_type_id,
				rejected
	   ) SELECT mcq.new_questionnaire_id,
				ms.new_sid,
				mcc.new_component_id,
				cq.created_dtm,
				cq.description,
				mcqt.new_questionnaire_type_id,
				cq.rejected
		   FROM csrimp.chain_questionnaire cq,
				csrimp.map_chain_questionnaire mcq,
				csrimp.map_sid ms,
				csrimp.map_chain_component mcc,
				csrimp.map_chain_questionn_type mcqt
		  WHERE cq.questionnaire_id = mcq.old_questionnaire_id
			AND cq.company_sid = ms.old_sid
			AND cq.component_id = mcc.old_component_id(+)
			AND cq.questionnaire_type_id = mcqt.old_questionnaire_type_id(+);

	INSERT INTO chain.questionnaire_share (
				questionnaire_share_id,
				due_by_dtm,
				expiry_dtm,
				expiry_sent_dtm,
				overdue_events_sent,
				overdue_sent_dtm,
				qnr_owner_company_sid,
				questionnaire_id,
				reminder_sent_dtm,
				share_with_company_sid
	   ) SELECT mcqs.new_questionnaire_share_id,
				cqs.due_by_dtm,
				cqs.expiry_dtm,
				cqs.expiry_sent_dtm,
				cqs.overdue_events_sent,
				cqs.overdue_sent_dtm,
				ms.new_sid,
				mcq.new_questionnaire_id,
				cqs.reminder_sent_dtm,
				ms1.new_sid
		   FROM csrimp.chain_questionnair_share cqs,
				csrimp.map_chain_question_share mcqs,
				csrimp.map_sid ms,
				csrimp.map_chain_questionnaire mcq,
				csrimp.map_sid ms1
		  WHERE cqs.questionnaire_share_id = mcqs.old_questionnaire_share_id
			AND cqs.qnr_owner_company_sid = ms.old_sid
			AND cqs.questionnaire_id = mcq.old_questionnaire_id
			AND cqs.share_with_company_sid = ms1.old_sid;

	INSERT INTO chain.qnr_share_log_entry (
				questionnaire_share_id,
				share_log_entry_index,
				company_sid,
				entry_dtm,
				share_status_id,
				user_notes,
				user_sid
	   ) SELECT mcqs.new_questionnaire_share_id,
				cqsle.share_log_entry_index,
				ms.new_sid,
				cqsle.entry_dtm,
				cqsle.share_status_id,
				cqsle.user_notes,
				ms1.new_sid
		   FROM csrimp.chain_qnr_shar_log_entry cqsle,
				csrimp.map_chain_question_share mcqs,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE cqsle.questionnaire_share_id = mcqs.old_questionnaire_share_id
			AND cqsle.company_sid = ms.old_sid
			AND cqsle.user_sid = ms1.old_sid;

	INSERT INTO chain.qnr_status_log_entry (
				questionnaire_id,
				status_log_entry_index,
				entry_dtm,
				questionnaire_status_id,
				user_notes,
				user_sid
	   ) SELECT mcq.new_questionnaire_id,
				cqsle.status_log_entry_index,
				cqsle.entry_dtm,
				cqsle.questionnaire_status_id,
				cqsle.user_notes,
				ms.new_sid
		   FROM csrimp.chain_qnr_stat_log_entry cqsle,
				csrimp.map_chain_questionnaire mcq,
				csrimp.map_sid ms
		  WHERE cqsle.questionnaire_id = mcq.old_questionnaire_id
			AND cqsle.user_sid = ms.old_sid;

	INSERT INTO chain.questionnaire_expiry_alert (
				questionnaire_share_id,
				user_sid
	   ) SELECT mcqs.new_questionnaire_share_id,
				ms.new_sid
		   FROM csrimp.chain_quest_expiry_alert cqea,
				csrimp.map_chain_question_share mcqs,
				csrimp.map_sid ms
		  WHERE cqea.questionnaire_share_id = mcqs.old_questionnaire_share_id
			AND cqea.user_sid = ms.old_sid;

	INSERT INTO chain.questionnaire_invitation (
				questionnaire_id,
				invitation_id,
				added_dtm
	   ) SELECT mcq.new_questionnaire_id,
				mci.new_invitation_id,
				cqi.added_dtm
		   FROM csrimp.chain_question_invitatio cqi,
				csrimp.map_chain_questionnaire mcq,
				csrimp.map_chain_invitation mci
		  WHERE cqi.questionnaire_id = mcq.old_questionnaire_id
			AND cqi.invitation_id = mci.old_invitation_id;

	INSERT INTO chain.questionnaire_metric_type (
				questionnaire_metric_type_id,
				description,
				max_value,
				questionnaire_type_id
	   ) SELECT cqmt.questionnaire_metric_type_id,
				cqmt.description,
				cqmt.max_value,
				mcqt.new_questionnaire_type_id
		   FROM csrimp.chain_questi_metric_type cqmt,
				csrimp.map_chain_questionn_type mcqt
		  WHERE cqmt.questionnaire_type_id = mcqt.old_questionnaire_type_id;

	INSERT INTO chain.questionnaire_metric (
				questionnaire_id,
				questionnaire_metric_type_id,
				metric_value,
				normalised_value
	   ) SELECT mcq.new_questionnaire_id,
				cqm.questionnaire_metric_type_id,
				cqm.metric_value,
				cqm.normalised_value
		   FROM csrimp.chain_questionnai_metric cqm,
				csrimp.map_chain_questionnaire mcq
		  WHERE cqm.questionnaire_id = mcq.old_questionnaire_id;

	INSERT INTO chain.questionnaire_user (
				questionnaire_id,
				user_sid,
				company_function_id,
				company_sid,
				added_dtm
	   ) SELECT mcq.new_questionnaire_id,
				ms.new_sid,
				cqu.company_function_id,
				ms1.new_sid,
				cqu.added_dtm
		   FROM csrimp.chain_questionnaire_user cqu,
				csrimp.map_chain_questionnaire mcq,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE cqu.questionnaire_id = mcq.old_questionnaire_id
			AND cqu.user_sid = ms.old_sid
			AND cqu.company_sid = ms1.old_sid;

	INSERT INTO chain.questionnaire_user_action (
				questionnaire_id,
				user_sid,
				company_function_id,
				questionnaire_action_id,
				company_sid
	   ) SELECT mcq.new_questionnaire_id,
				ms.new_sid,
				cqua.company_function_id,
				cqua.questionnaire_action_id,
				ms1.new_sid
		   FROM csrimp.chain_questi_user_action cqua,
				csrimp.map_chain_questionnaire mcq,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE cqua.questionnaire_id = mcq.old_questionnaire_id
			AND cqua.user_sid = ms.old_sid
			AND cqua.company_sid = ms1.old_sid;

	INSERT INTO chain.qnnaire_share_alert_log (
				questionnaire_share_id,
				alert_sent_dtm,
				std_alert_type_id,
				user_sid
	   ) SELECT mcqs.new_questionnaire_share_id,
				cqsal.alert_sent_dtm,
				cqsal.std_alert_type_id,
				ms.new_sid
		   FROM csrimp.chain_qnna_shar_aler_log cqsal,
				csrimp.map_chain_question_share mcqs,
				csrimp.map_sid ms
		  WHERE cqsal.questionnaire_share_id = mcqs.old_questionnaire_share_id
			AND cqsal.user_sid = ms.old_sid;
END;

PROCEDURE CreateChainTasks
AS
BEGIN
	INSERT INTO chain.task_scheme (
				task_scheme_id,
				db_class,
				description
	   ) SELECT cts.task_scheme_id,
				cts.db_class,
				cts.description
		   FROM csrimp.chain_task_scheme cts;

	INSERT INTO chain.task_type (
				task_type_id,
				card_id,
				db_class,
				default_task_status_id,
				description,
				due_date_editable,
				due_in_days,
				mandatory,
				name,
				parent_task_type_id,
				position,
				review_every_n_days,
				task_scheme_id
	   ) SELECT mctt.new_task_type_id,
				mcc.new_card_id,
				ctt.db_class,
				ctt.default_task_status_id,
				ctt.description,
				ctt.due_date_editable,
				ctt.due_in_days,
				ctt.mandatory,
				ctt.name,
				mctt1.new_task_type_id,
				ctt.position,
				ctt.review_every_n_days,
				ctt.task_scheme_id
		   FROM csrimp.chain_task_type ctt,
				csrimp.map_chain_task_type mctt,
				csrimp.map_chain_card mcc,
				csrimp.map_chain_task_type mctt1
		  WHERE ctt.task_type_id = mctt.old_task_type_id
			AND ctt.card_id = mcc.old_card_id(+)
			AND ctt.parent_task_type_id = mctt1.old_task_type_id(+);

	INSERT INTO chain.task (
				task_id,
				change_group_id,
				due_date,
				last_task_status_id,
				last_updated_by_sid,
				last_updated_dtm,
				next_review_date,
				owner_company_sid,
				skipped,
				supplier_company_sid,
				task_status_id,
				task_type_id
	   ) SELECT mct.new_task_id,
				ct.change_group_id,
				ct.due_date,
				ct.last_task_status_id,
				ms.new_sid,
				ct.last_updated_dtm,
				ct.next_review_date,
				ms1.new_sid,
				ct.skipped,
				ms2.new_sid,
				ct.task_status_id,
				mctt.new_task_type_id
		   FROM csrimp.chain_task ct,
				csrimp.map_chain_task mct,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_chain_task_type mctt
		  WHERE ct.task_id = mct.old_task_id
			AND ct.last_updated_by_sid = ms.old_sid(+)
			AND ct.owner_company_sid = ms1.old_sid
			AND ct.supplier_company_sid = ms2.old_sid
			AND ct.task_type_id = mctt.old_task_type_id;

	INSERT INTO chain.task_action_trigger (
				on_task_action_id,
				position,
				task_type_id,
				trigger_task_action_id,
				trigger_task_name
	   ) SELECT ctat.on_task_action_id,
				ctat.position,
				mctt.new_task_type_id,
				ctat.trigger_task_action_id,
				ctat.trigger_task_name
		   FROM csrimp.chain_task_action_trigge ctat,
				csrimp.map_chain_task_type mctt
		  WHERE ctat.task_type_id = mctt.old_task_type_id;

	INSERT INTO chain.task_entry (
				task_entry_id,
				last_modified_by_sid,
				last_modified_dtm,
				name,
				task_entry_type_id,
				task_id
	   ) SELECT mcte.new_task_entry_id,
				ms.new_sid,
				cte.last_modified_dtm,
				cte.name,
				cte.task_entry_type_id,
				cte.task_id
		   FROM csrimp.chain_task_entry cte,
				csrimp.map_chain_task_entry mcte,
				csrimp.map_sid ms
		  WHERE cte.task_entry_id = mcte.old_task_entry_id
			AND cte.last_modified_by_sid = ms.old_sid;

	INSERT INTO chain.task_entry_date (
				task_entry_id,
				dtm
	   ) SELECT mcte.new_task_entry_id,
				cted.dtm
		   FROM csrimp.chain_task_entry_date cted,
				csrimp.map_chain_task_entry mcte
		  WHERE cted.task_entry_id = mcte.old_task_entry_id;

	INSERT INTO chain.task_entry_file (
				task_entry_id,
				file_upload_sid
	   ) SELECT mcte.new_task_entry_id,
				ms.new_sid
		   FROM csrimp.chain_task_entry_file ctef,
				csrimp.map_chain_task_entry mcte,
				csrimp.map_sid ms
		  WHERE ctef.task_entry_id = mcte.old_task_entry_id
			AND ctef.file_upload_sid = ms.old_sid;

	INSERT INTO chain.task_entry_note (
				task_entry_id,
				text
	   ) SELECT mcte.new_task_entry_id,
				cten.text
		   FROM csrimp.chain_task_entry_note cten,
				csrimp.map_chain_task_entry mcte
		  WHERE cten.task_entry_id = mcte.old_task_entry_id;

	INSERT INTO chain.task_invitation_qnr_type (
				task_id,
				invitation_id,
				questionnaire_type_id
	   ) SELECT mct.new_task_id,
				mci.new_invitation_id,
				mcqt.new_questionnaire_type_id
		   FROM csrimp.chain_task_invi_qnr_type ctiqt,
				csrimp.map_chain_task mct,
				csrimp.map_chain_invitation mci,
				csrimp.map_chain_questionn_type mcqt
		  WHERE ctiqt.task_id = mct.old_task_id
			AND ctiqt.invitation_id = mci.old_invitation_id
			AND ctiqt.questionnaire_type_id = mcqt.old_questionnaire_type_id;
END;

PROCEDURE CreateChainUserMessageLog
AS
BEGIN
	INSERT INTO chain.user_message_log (
				user_sid,
				message_id,
				viewed_dtm
	   ) SELECT ms.new_sid,
				mcm.new_message_id,
				cuml.viewed_dtm
		   FROM csrimp.chain_user_message_log cuml,
				csrimp.map_sid ms,
				csrimp.map_chain_message mcm
		  WHERE cuml.user_sid = ms.old_sid
			AND cuml.message_id = mcm.old_message_id;
END;

PROCEDURE CreateChainBusinessRelnships
AS
BEGIN
	INSERT INTO chain.business_relationship_type (
				business_relationship_type_id,
				label,
				form_path,
				tab_sid,
				column_sid,
				lookup_key
	   ) SELECT mcbrt.new_business_rel_type_id,
				cbrt.label,
				cbrt.form_path,
				ms1.new_sid,
				ms2.new_sid,
				cbrt.lookup_key
		   FROM csrimp.chain_busine_relati_type cbrt,
				csrimp.map_chain_busin_rel_type mcbrt,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2
		  WHERE cbrt.business_relationship_type_id = mcbrt.old_business_rel_type_id
		    AND cbrt.tab_sid = ms1.old_sid(+)
			AND cbrt.column_sid = ms2.old_sid(+);

	INSERT INTO chain.business_relationship_tier (
				business_relationship_type_id,
				business_relationship_tier_id,
				tier,
				direct_from_previous_tier,
				create_supplier_relationship,
				create_new_company,
				label,
				lookup_key,
				allow_multiple_companies,
				create_sup_rels_w_lower_tiers
	   ) SELECT mcbrt.new_business_rel_type_id,
				mcbrt1.new_business_rel_tier_id,
				cbrt.tier,
				cbrt.direct_from_previous_tier,
				cbrt.create_supplier_relationship,
				cbrt.create_new_company,
				cbrt.label,
				cbrt.lookup_key,
				cbrt.allow_multiple_companies,
				cbrt.create_sup_rels_w_lower_tiers
		   FROM csrimp.chain_busine_relati_tier cbrt,
				csrimp.map_chain_busin_rel_type mcbrt,
				csrimp.map_chain_busin_rel_tier mcbrt1
		  WHERE cbrt.business_relationship_type_id = mcbrt.old_business_rel_type_id
			AND cbrt.business_relationship_tier_id = mcbrt1.old_business_rel_tier_id;

	INSERT INTO chain.business_rel_tier_company_type (
				business_relationship_tier_id,
				company_type_id
	   ) SELECT mcbrt.new_business_rel_tier_id,
				mcct.new_company_type_id
		   FROM csrimp.chain_bu_rel_tie_com_typ cbrtct,
				csrimp.map_chain_busin_rel_tier mcbrt,
				csrimp.map_chain_company_type mcct
		  WHERE cbrtct.business_relationship_tier_id = mcbrt.old_business_rel_tier_id
			AND cbrtct.company_type_id = mcct.old_company_type_id;

	INSERT INTO chain.business_relationship (
				business_relationship_id,
				business_relationship_type_id
	   ) SELECT mcbr.new_business_relationship_id,
				mcbrt.new_business_rel_type_id
		   FROM csrimp.chain_business_relations cbr,
				csrimp.map_chain_busine_relatio mcbr,
				csrimp.map_chain_busin_rel_type mcbrt
		  WHERE cbr.business_relationship_type_id = mcbrt.old_business_rel_type_id
			AND cbr.business_relationship_id = mcbr.old_business_relationship_id;

	INSERT INTO chain.business_relationship_period (
				business_relationship_id,
				business_rel_period_id,
				start_dtm,
				end_dtm
	   ) SELECT mcbr.new_business_relationship_id,
				mcbrp.new_business_rel_period_id,
				cbrp.start_dtm,
				cbrp.end_dtm
		   FROM csrimp.chain_busin_relat_period cbrp,
				csrimp.map_chain_busine_relatio mcbr,
				csrimp.map_chain_bus_rel_period mcbrp
		  WHERE cbrp.business_rel_period_id = mcbrp.old_business_rel_period_id
			AND cbrp.business_relationship_id = mcbr.old_business_relationship_id;

	INSERT INTO chain.business_relationship_company (
				business_relationship_id,
				business_relationship_tier_id,
				pos,
				company_sid
	   ) SELECT mcbr.new_business_relationship_id,
				mcbrt.new_business_rel_tier_id,
				cbrc.pos,
				ms.new_sid
		   FROM csrimp.chain_busin_relat_compan cbrc,
				csrimp.map_chain_busine_relatio mcbr,
				csrimp.map_chain_busin_rel_tier mcbrt,
				csrimp.map_sid ms
		  WHERE cbrc.business_relationship_id = mcbr.old_business_relationship_id
			AND cbrc.business_relationship_tier_id = mcbrt.old_business_rel_tier_id
			AND cbrc.company_sid = ms.old_sid;

	FOR r IN (
		SELECT br.business_relationship_id, br.business_relationship_type_id || ':' || listagg(brc.company_sid, ',') WITHIN GROUP (order by brt.tier) signature
		  FROM chain.business_relationship br
		  JOIN chain.business_relationship_company brc ON brc.business_relationship_id = br.business_relationship_id AND brc.app_sid = br.app_sid
		  JOIN chain.business_relationship_tier brt ON brt.business_relationship_tier_id = brc.business_relationship_tier_id AND brt.app_sid = brc.app_sid
		 GROUP BY br.business_relationship_id, br.business_relationship_type_id
	) LOOP
		UPDATE chain.business_relationship
		   SET signature = r.signature
		 WHERE business_relationship_id = r.business_relationship_id;
	END LOOP;
END;

PROCEDURE SetDedupeData
AS
BEGIN

	INSERT INTO chain.import_source (
				import_source_id,
				dedupe_no_match_action_id,
				name,
				position,
				lookup_key,
				is_owned_by_system,
				override_company_active
	   ) SELECT mcis.new_import_source_id,
				cis.dedupe_no_match_action_id,
				cis.name,
				cis.position,
				cis.lookup_key,
				cis.is_owned_by_system,
				cis.override_company_active
		   FROM csrimp.chain_import_source cis,
				csrimp.map_chain_import_source mcis
		  WHERE cis.import_source_id = mcis.old_import_source_id;

	INSERT INTO chain.import_source_lock (
				import_source_id,
				is_locked
	   ) SELECT mcis.new_import_source_id,
				0
		   FROM csrimp.chain_import_source cis,
				csrimp.map_chain_import_source mcis
		  WHERE cis.import_source_id = mcis.old_import_source_id
		    AND cis.is_owned_by_system = 0;

	INSERT INTO chain.dedupe_staging_link (
				dedupe_staging_link_id,
				description,
				destination_tab_sid,
				import_source_id,
				parent_staging_link_id,
				position,
				staging_batch_num_col_sid,
				staging_id_col_sid,
				staging_source_lookup_col_sid,
				staging_tab_sid,
				is_owned_by_system
	   ) SELECT mcdsl.new_chain_dedup_stagin_link_id,
				cdsl.description,
				ms.new_sid,
				mcis.new_import_source_id,
				mcdsl2.new_chain_dedup_stagin_link_id,
				cdsl.position,
				mctc1.new_column_id,
				mctc2.new_column_id,
				mctc3.new_column_id,
				ms3.new_sid,
				cdsl.is_owned_by_system
		   FROM csrimp.chain_dedupe_stagin_link cdsl,
				csrimp.map_chain_dedu_stag_link mcdsl,
				csrimp.map_chain_dedu_stag_link mcdsl2,
				csrimp.map_chain_import_source mcis,
				csrimp.map_sid ms,
				csrimp.map_cms_tab_column mctc1,
				csrimp.map_cms_tab_column mctc2,
				csrimp.map_cms_tab_column mctc3,
				csrimp.map_sid ms3
		  WHERE cdsl.dedupe_staging_link_id = mcdsl.old_chain_dedup_stagin_link_id
			AND cdsl.parent_staging_link_id = mcdsl2.old_chain_dedup_stagin_link_id(+)
			AND cdsl.destination_tab_sid = ms.old_sid(+)
			AND cdsl.staging_batch_num_col_sid = mctc1.old_column_id(+)
			AND cdsl.staging_id_col_sid = mctc2.old_column_id(+)
			AND cdsl.staging_source_lookup_col_sid = mctc3.old_column_id(+)
			AND cdsl.staging_tab_sid = ms3.old_sid(+)
			AND cdsl.import_source_id = mcis.old_import_source_id;

	INSERT INTO chain.dedupe_mapping (
				dedupe_mapping_id,
				dedupe_staging_link_id,
				col_sid,
				dedupe_field_id,
				reference_id,
				tag_group_id,
				tab_sid,
				destination_tab_sid,
				destination_col_sid,
				role_sid,
				is_owned_by_system,
				allow_create_alt_company_name,
				fill_nulls_under_ui_source
	   ) SELECT mcdm.new_dedupe_mapping_id,
				mcdsl.new_chain_dedup_stagin_link_id,
				mctc.new_column_id,
				cdm.dedupe_field_id,
				mcr.new_reference_id,
				mtg.new_tag_group_id,
				ms1.new_sid,
				ms2.new_sid,
				mctc_dest.new_column_id,
				ms3.new_sid,
				cdm.is_owned_by_system,
				cdm.allow_create_alt_company_name,
				cdm.fill_nulls_under_ui_source
		   FROM csrimp.chain_dedupe_mapping cdm,
				csrimp.map_chain_dedu_stag_link mcdsl,
				csrimp.map_chain_dedupe_mapping mcdm,
				csrimp.map_cms_tab_column mctc,
				csrimp.map_sid ms1,
				csrimp.map_chain_reference mcr,
				csrimp.map_tag_group mtg,
				csrimp.map_sid ms2,
				csrimp.map_cms_tab_column mctc_dest,
				csrimp.map_sid ms3
		  WHERE cdm.dedupe_mapping_id = mcdm.old_dedupe_mapping_id
			AND cdm.dedupe_staging_link_id = mcdsl.old_chain_dedup_stagin_link_id
			AND cdm.col_sid = mctc.old_column_id(+)
			AND cdm.tab_sid = ms1.old_sid(+)
			AND cdm.reference_id = mcr.old_reference_id(+)
			AND cdm.tag_group_id = mtg.old_tag_group_id(+)
			AND cdm.destination_tab_sid = ms2.old_sid(+)
			AND cdm.role_sid = ms3.old_sid(+)
			AND cdm.destination_col_sid = mctc_dest.old_column_id(+);

	INSERT INTO chain.dedupe_rule_set (
				dedupe_rule_set_id,
				description,
				dedupe_staging_link_id,
				dedupe_match_type_id,
				position
	   ) SELECT mcdrs.new_dedupe_rule_set_id,
				cdrs.description,
				mcdsl.new_chain_dedup_stagin_link_id,
				cdrs.dedupe_match_type_id,
				cdrs.position
		   FROM csrimp.chain_dedupe_rule_set cdrs,
				csrimp.map_chain_dedupe_rule_set mcdrs,
				csrimp.map_chain_dedu_stag_link mcdsl
		  WHERE cdrs.dedupe_rule_set_id = mcdrs.old_dedupe_rule_set_id
		    AND cdrs.dedupe_staging_link_id = mcdsl.old_chain_dedup_stagin_link_id(+);

	INSERT INTO chain.dedupe_rule(
				dedupe_rule_id,
				dedupe_rule_set_id,
				dedupe_mapping_id,
				position,
				dedupe_rule_type_id,
				match_threshold
	   ) SELECT mcdr.new_dedupe_rule_id,
				mcdrs.new_dedupe_rule_set_id,
				mcdm.new_dedupe_mapping_id,
				cdr.position,
				cdr.dedupe_rule_type_id,
				cdr.match_threshold
		   FROM csrimp.chain_dedupe_rule cdr,
				csrimp.map_chain_dedupe_rule_set mcdrs,
				csrimp.map_chain_dedupe_mapping mcdm,
				csrimp.map_chain_dedupe_rule mcdr
		  WHERE cdr.dedupe_mapping_id = mcdm.old_dedupe_mapping_id
			AND cdr.dedupe_rule_set_id = mcdrs.old_dedupe_rule_set_id
		    AND cdr.dedupe_rule_id = mcdr.old_dedupe_rule_id;

	INSERT INTO chain.dedupe_processed_record (
				dedupe_processed_record_id,
				dedupe_staging_link_id,
				batch_num,
				cms_record_id,
				parent_processed_record_id,
				reference,
				dedupe_action_type_id,
				iteration_num,
				matched_by_user_sid,
				matched_dtm,
				matched_to_company_sid,
				processed_dtm,
				created_company_sid,
				data_merged,
				imported_user_sid,
				merge_status_id,
				dedupe_action
	   ) SELECT mcdpr.new_dedupe_processed_record_id,
				mcdsl.new_chain_dedup_stagin_link_id,
				cdpr.batch_num,
				cdpr.cms_record_id,
				mcdpr2.new_dedupe_processed_record_id,
				cdpr.reference,
				cdpr.dedupe_action_type_id,
				cdpr.iteration_num,
				ms.new_sid,
				cdpr.matched_dtm,
				ms1.new_sid,
				cdpr.processed_dtm,
				ms2.new_sid,
				cdpr.data_merged,
				ms3.new_sid,
			    NULL,
				cdpr.dedupe_action
		   FROM csrimp.chain_dedup_proce_record cdpr,
				csrimp.map_chain_dedu_proc_reco mcdpr,
				csrimp.map_chain_dedu_proc_reco mcdpr2,
				csrimp.map_chain_dedu_stag_link mcdsl,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_sid ms3
		  WHERE cdpr.dedupe_processed_record_id = mcdpr.old_dedupe_processed_record_id
			AND cdpr.dedupe_staging_link_id = mcdsl.old_chain_dedup_stagin_link_id(+)
			AND cdpr.matched_by_user_sid = ms.old_sid(+)
			AND cdpr.matched_to_company_sid = ms1.old_sid(+)
			AND cdpr.created_company_sid = ms2.old_sid(+)
			AND cdpr.parent_processed_record_id = mcdpr2.old_dedupe_processed_record_id(+)
			AND cdpr.imported_user_sid = ms3.old_sid(+);

	INSERT INTO chain.dedupe_match (
				dedupe_match_id,
				dedupe_processed_record_id,
				dedupe_rule_set_id,
				matched_to_company_sid
	   ) SELECT mcdm.new_dedupe_match_id,
				mcdpr.new_dedupe_processed_record_id,
				mcdr.new_dedupe_rule_set_id,
				ms.new_sid
		   FROM csrimp.chain_dedupe_match cdm,
				csrimp.map_chain_dedupe_match mcdm,
				csrimp.map_chain_dedu_proc_reco mcdpr,
				csrimp.map_chain_dedupe_rule_set mcdr,
				csrimp.map_sid ms
		  WHERE cdm.dedupe_match_id = mcdm.old_dedupe_match_id
		    AND cdm.dedupe_processed_record_id = mcdpr.old_dedupe_processed_record_id
			AND cdm.dedupe_rule_set_id = mcdr.old_dedupe_rule_set_id
			AND cdm.matched_to_company_sid = ms.old_sid;

	INSERT INTO chain.dedupe_merge_log (
				dedupe_merge_log_id,
				dedupe_field_id,
				dedupe_processed_record_id,
				new_val,
				old_val,
				reference_id,
				tag_group_id,
				destination_tab_sid,
				destination_col_sid,
				error_message,
				current_desc_val,
				new_raw_val,
				new_translated_val,
				role_sid,
				alt_comp_name_downgrade
	   ) SELECT mcdml.new_dedupe_merge_log_id,
				cdml.dedupe_field_id,
				mcdpr.new_dedupe_processed_record_id,
				cdml.new_val,
				cdml.old_val,
				mcr.new_reference_id,
				mtg.new_tag_group_id,
				ms1.new_sid,
				mctc.new_column_id,
				cdml.error_message,
				cdml.current_desc_val,
				cdml.new_raw_val,
				cdml.new_translated_val,
				ms2.new_sid,
				cdml.alt_comp_name_downgrade
		   FROM csrimp.chain_dedupe_merge_log cdml,
				csrimp.map_chain_dedu_merge_log mcdml,
				csrimp.map_chain_dedu_proc_reco mcdpr,
				csrimp.map_chain_reference mcr,
				csrimp.map_tag_group mtg,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_cms_tab_column mctc
		  WHERE cdml.dedupe_merge_log_id = mcdml.old_dedupe_merge_log_id
		    AND cdml.dedupe_processed_record_id = mcdpr.old_dedupe_processed_record_id
			AND cdml.reference_id = mcr.old_reference_id(+)
			AND cdml.tag_group_id = mtg.old_tag_group_id(+)
		    AND cdml.destination_tab_sid = ms1.old_sid(+)
			AND cdml.destination_col_sid = mctc.old_column_id(+)
			AND cdml.role_sid = ms2.old_sid(+);

	INSERT INTO chain.dedupe_preproc_comp (
				company_sid,
				address,
				city,
				name,
				postcode,
				state,
				website,
				phone,
				email_domain,
				updated_dtm
	   ) SELECT ms.new_sid,
				cdpc.address,
				cdpc.city,
				cdpc.name,
				cdpc.postcode,
				cdpc.state,
				cdpc.website,
				cdpc.phone,
				cdpc.email_domain,
				cdpc.updated_dtm
		   FROM csrimp.chain_dedupe_prepro_comp cdpc,
				csrimp.map_sid ms
		  WHERE cdpc.company_sid = ms.old_sid;

	INSERT INTO csrimp.map_chain_dedu_prep_rule (old_chain_dedup_prepro_rule_id, new_chain_dedup_prepro_rule_id)
		 SELECT dedupe_preproc_rule_id, chain.dedupe_preproc_rule_id_seq.NEXTVAL
		   FROM csrimp.chain_dedupe_prepro_rule;

	INSERT INTO chain.dedupe_preproc_rule (
				dedupe_preproc_rule_id,
				pattern,
				replacement,
				run_order
	   ) SELECT mcdpr.new_chain_dedup_prepro_rule_id,
				cdpr.pattern,
				cdpr.replacement,
				cdpr.run_order
		   FROM csrimp.chain_dedupe_prepro_rule cdpr,
				csrimp.map_chain_dedu_prep_rule mcdpr
		  WHERE cdpr.dedupe_preproc_rule_id = mcdpr.old_chain_dedup_prepro_rule_id;

	INSERT INTO chain.dedupe_pp_field_cntry (
				country_code,
				dedupe_field_id,
				dedupe_preproc_rule_id
	   ) SELECT cdpfc.country_code,
				cdpfc.dedupe_field_id,
				mcdpr.new_chain_dedup_prepro_rule_id
		   FROM csrimp.chain_dedu_pp_fiel_cntry cdpfc,
				csrimp.map_chain_dedu_prep_rule mcdpr
		  WHERE cdpfc.dedupe_preproc_rule_id = mcdpr.old_chain_dedup_prepro_rule_id;

	INSERT INTO chain.dedupe_sub (
				dedupe_sub_id,
				pattern,
				substitution,
				proc_pattern,
				proc_substitution,
				updated_dtm
	   ) SELECT mcds.new_chain_dedupe_sub_id,
				cds.pattern,
				cds.substitution,
				cds.proc_pattern,
				cds.proc_substitution,
				cds.updated_dtm
		   FROM csrimp.chain_dedupe_sub cds,
				csrimp.map_chain_dedupe_sub mcds
		  WHERE cds.dedupe_sub_id = mcds.old_chain_dedupe_sub_id;

	INSERT INTO chain.dedupe_pp_alt_comp_name (
				alt_company_name_id,
				company_sid,
				name
	   ) SELECT mcacn.new_alt_company_name_id,
				ms.new_sid,
				cdpacn.name
		   FROM csrimp.chain_dedupe_pp_alt_comp_name cdpacn,
				csrimp.map_sid ms,
				csrimp.map_chain_alt_company_name mcacn
		  WHERE cdpacn.company_sid = ms.old_sid
			AND cdpacn.alt_company_name_id = mcacn.old_alt_company_name_id;

	INSERT INTO chain.pend_company_suggested_match (
				pending_company_sid,
				matched_company_sid,
				dedupe_rule_set_id
	   ) SELECT pcs.new_sid,
				mcs.new_sid,
				mcdr.new_dedupe_rule_set_id
		   FROM csrimp.chain_pend_cmpny_suggstd_match cpcsm,
				csrimp.map_chain_dedupe_rule_set mcdr,
				csrimp.map_sid pcs,
				csrimp.map_sid mcs
		  WHERE cpcsm.pending_company_sid = pcs.old_sid
		    AND cpcsm.matched_company_sid = mcs.old_sid
			AND cpcsm.dedupe_rule_set_id = mcdr.old_dedupe_rule_set_id(+);

	INSERT INTO chain.pending_company_tag (
				pending_company_sid,
				tag_id
	   ) SELECT pcs.new_sid,
				mt.new_tag_id
		   FROM csrimp.chain_pending_company_tag cpct,
				csrimp.map_tag mt,
				csrimp.map_sid pcs
		  WHERE cpct.pending_company_sid = pcs.old_sid
			AND cpct.tag_id = mt.old_tag_id(+);

	INSERT INTO chain.dd_customer_blcklst_email (
				email_domain
	   ) SELECT email_domain
		   FROM csrimp.chain_dd_cust_blcklst_email;

END;

PROCEDURE CreateHigg
AS
BEGIN
	INSERT INTO chain.higg (
		ftp_folder,
		ftp_profile_label
	)
	SELECT ftp_folder, ftp_profile_label
	  FROM csrimp.chain_higg;

	INSERT INTO chain.higg_config (
		higg_config_id,
		company_type_id,
		audit_type_id,
		survey_sid,
		closure_type_id,
		audit_coordinator_sid,
		aggregate_ind_group_id,
		copy_score_on_survey_submit
	)
	SELECT mhg.new_higg_config_id,
		mcct.new_company_type_id,
		iat.new_internal_audit_type_id,
		qs.new_sid,
		atct.new_audit_closure_type_id,
		cu.new_sid,
		maig.new_aggregate_ind_group_id,
		hc.copy_score_on_survey_submit
	  FROM csrimp.higg_config hc
	  JOIN csrimp.map_higg_config mhg ON mhg.old_higg_config_id = hc.higg_config_id
	  LEFT JOIN csrimp.map_chain_company_type mcct ON hc.company_type_id = mcct.old_company_type_id
	  JOIN csrimp.map_internal_audit_type iat ON hc.audit_type_id = iat.old_internal_audit_type_id
	  JOIN csrimp.map_sid qs ON hc.survey_sid = qs.old_sid
	  LEFT JOIN csrimp.map_audit_closure_type atct ON hc.closure_type_id = atct.old_audit_closure_type_id
	  JOIN csrimp.map_sid cu ON hc.audit_coordinator_sid = cu.old_sid
	  LEFT JOIN csrimp.map_aggregate_ind_group maig ON maig.old_aggregate_ind_group_id = hc.aggregate_ind_group_id;

	INSERT INTO chain.higg_module_tag_group (
		higg_module_id,
		tag_group_id
	)
	SELECT hm.higg_module_id,
		   mtg.new_tag_group_id
	  FROM csrimp.higg_module_tag_group hm
	  JOIN csrimp.map_tag_group mtg ON mtg.old_tag_group_id = hm.tag_group_id;

	INSERT INTO chain.higg_config_module (
		higg_config_id,
		higg_module_id,
		score_type_id
	)
	SELECT mhg.new_higg_config_id,
	       hcm.higg_module_id,
		   mst.new_score_type_id
	  FROM csrimp.higg_config_module hcm
	  JOIN csrimp.map_higg_config mhg ON mhg.old_higg_config_id = hcm.higg_config_id
	  JOIN csrimp.map_score_type mst ON mst.old_score_type_id = hcm.score_type_id;

	INSERT INTO chain.higg_question_survey (
		higg_question_id,
		survey_sid,
		qs_question_id,
		qs_question_version,
		survey_version
	)
	SELECT hqs.higg_question_id,
		mqs.new_sid,
		mqq.new_question_id,
		hqs.qs_question_version,
		hqs.survey_version
	  FROM csrimp.higg_question_survey hqs
	  JOIN csrimp.map_qs_question mqq ON mqq.old_question_id = hqs.qs_question_id
	  JOIN csrimp.map_sid mqs ON mqs.old_sid = hqs.survey_sid;

	INSERT INTO chain.higg_question_option_survey (
		higg_question_id,
		higg_question_option_id,
		survey_sid,
		qs_question_id,
		qs_question_version,
		qs_question_option_id,
		survey_version
	)
	SELECT hqos.higg_question_id,
		hqos.higg_question_option_id,
		mqs.new_sid,
		mqq.new_question_id,
		mqqo.new_question_option_id,
		hqos.qs_question_version,
		hqos.survey_version
	  FROM csrimp.higg_question_option_survey hqos
	  JOIN csrimp.map_sid mqs ON mqs.old_sid = hqos.survey_sid
	  JOIN csrimp.map_qs_question mqq ON mqq.old_question_id = hqos.qs_question_id
	  JOIN csrimp.map_qs_question_option mqqo ON mqqo.old_question_option_id = hqos.qs_question_option_id;

	INSERT INTO chain.higg_profile (
		higg_profile_id,
		response_year
	)
	SELECT hp.higg_profile_id,
	       hp.response_year
	  FROM csrimp.higg_profile hp;

	INSERT INTO chain.higg_response (
		higg_response_id,
		higg_module_id,
		higg_account_id,
		higg_profile_id,
		response_year,
		module_name,
		posted,
		verification_status,
		verification_document_url,
		is_benchmarked,
		response_score,
		last_updated_dtm
	)
	SELECT higg_response_id,
		higg_module_id,
		higg_account_id,
		higg_profile_id,
		response_year,
		module_name,
		posted,
		verification_status,
		verification_document_url,
		is_benchmarked,
		response_score,
		last_updated_dtm
	  FROM csrimp.higg_response;

	INSERT INTO chain.higg_section_score (
		higg_response_id,
		higg_section_id,
		score
	)
	SELECT higg_response_id,
		higg_section_id,
		score
	  FROM csrimp.higg_section_score;

	INSERT INTO chain.higg_sub_section_score (
		higg_response_id,
		higg_section_id,
		higg_sub_section_id,
		score
	)
	SELECT higg_response_id,
		higg_section_id,
		higg_sub_section_id,
		score
	  FROM csrimp.higg_sub_section_score;

	INSERT INTO chain.higg_question_response (
		higg_response_id,
		higg_question_id,
		score,
		answer,
		option_id
	)
	SELECT higg_response_id,
		higg_question_id,
		score,
		answer,
		option_id
	  FROM csrimp.higg_question_response;

	INSERT INTO chain.higg_config_profile (
		higg_config_id,
		higg_profile_id,
		response_year,
		internal_audit_sid
	)
	SELECT mhc.new_higg_config_id,
		hcp.higg_profile_id,
		hcp.response_year,
		ms.new_sid
	  FROM csrimp.higg_config_profile hcp
	  JOIN csrimp.map_higg_config mhc ON mhc.old_higg_config_id = hcp.higg_config_id
	  JOIN csrimp.map_sid ms ON ms.old_sid = hcp.internal_audit_sid;

	INSERT INTO chain.higg_question_opt_conversion (
		higg_question_id,
		higg_question_option_id,
		measure_conversion_id
	)
	SELECT hqoc.higg_question_id,
		hqoc.higg_question_option_id,
		mmc.new_measure_conversion_id
	  FROM csrimp.higg_question_opt_conversion hqoc
	  JOIN csrimp.map_measure_conversion mmc ON mmc.old_measure_conversion_id = hqoc.measure_conversion_id;
END;

PROCEDURE CreateWorksheets
AS
BEGIN
	INSERT INTO csrimp.map_worksheet (old_worksheet_id, new_worksheet_id)
		 SELECT worksheet_id, csr.worksheet_id_seq.NEXTVAL
		   FROM csrimp.worksheet;

	INSERT INTO csr.worksheet (
				worksheet_id,
				header_row_index,
				lower_sheet_name,
				sheet_name,
				worksheet_type_id
	   ) SELECT mw.new_worksheet_id,
				w.header_row_index,
				w.lower_sheet_name,
				w.sheet_name,
				w.worksheet_type_id
		   FROM csrimp.worksheet w,
				csrimp.map_worksheet mw
		  WHERE w.worksheet_id = mw.old_worksheet_id;

	INSERT INTO csr.worksheet_column (
				worksheet_id,
				column_type_id,
				column_index
	   ) SELECT mw.new_worksheet_id,
				wc.column_type_id,
				wc.column_index
		   FROM csrimp.worksheet_column wc,
				csrimp.map_worksheet mw
		  WHERE wc.worksheet_id = mw.old_worksheet_id;

	INSERT INTO csrimp.map_value_map (old_value_map_id, new_value_map_id)
		 SELECT value_map_id, csr.value_map_id_seq.NEXTVAL
		   FROM csrimp.worksheet_value_map;

	INSERT INTO csr.worksheet_column_value_map (
				worksheet_id,
				column_type_id,
				value_mapper_id,
				value_map_id
	   ) SELECT mw.new_worksheet_id,
				wcvm.column_type_id,
				wcvm.value_mapper_id,
				mvm.new_value_map_id
		   FROM csrimp.worksheet_column_value_map wcvm,
				csrimp.map_worksheet mw,
				csrimp.map_value_map mvm
		  WHERE wcvm.worksheet_id = mw.old_worksheet_id
			AND wcvm.value_map_id = mvm.old_value_map_id;

	INSERT INTO csr.worksheet_row (
				worksheet_id,
				row_number,
				ignore
	   ) SELECT mw.new_worksheet_id,
				wr.row_number,
				wr.ignore
		   FROM csrimp.worksheet_row wr,
				csrimp.map_worksheet mw
		  WHERE wr.worksheet_id = mw.old_worksheet_id;

	INSERT INTO csr.worksheet_value_map (
				value_mapper_id,
				value_map_id
	   ) SELECT wvm.value_mapper_id,
				mvm.new_value_map_id
		   FROM csrimp.worksheet_value_map wvm,
				csrimp.map_value_map mvm
		  WHERE wvm.value_map_id = mvm.old_value_map_id;

	INSERT INTO csr.worksheet_value_map_value (
				value_map_id,
				column_type_id,
				value_mapper_id,
				value
	   ) SELECT mvm.new_value_map_id,
				wvmv.column_type_id,
				wvmv.value_mapper_id,
				wvmv.value
		   FROM csrimp.worksheet_value_map_value wvmv,
				csrimp.map_value_map mvm
		  WHERE wvmv.value_map_id = mvm.old_value_map_id;
END;

PROCEDURE CreateChem
AS
BEGIN

	INSERT INTO chem.chem_options (
				chem_helper_pkg
	   ) SELECT cco.chem_helper_pkg
		   FROM csrimp.chem_chem_options cco;

	INSERT INTO chem.cas (
				cas_code,
			    name,
			    unconfirmed,
			    is_voc,
			    category
	   ) SELECT cc.cas_code,
			    cc.name,
			    cc.unconfirmed,
			    cc.is_voc,
			    cc.category
		   FROM csrimp.chem_cas cc;

	INSERT INTO chem.cas_group (
				cas_group_id,
				label,
				lookup_key,
				parent_group_id
	   ) SELECT mccg.new_cas_group_id,
				ccg.label,
				ccg.lookup_key,
				ccg.parent_group_id
		   FROM csrimp.chem_cas_group ccg,
				csrimp.map_chem_cas_group mccg
		  WHERE ccg.cas_group_id = mccg.old_cas_group_id;

	INSERT INTO chem.cas_group_member (
				cas_group_id,
				cas_code
	   ) SELECT mccg.new_cas_group_id,
				ccgm.cas_code
		   FROM csrimp.chem_cas_group_member ccgm,
				csrimp.map_chem_cas_group mccg
		  WHERE ccgm.cas_group_id = mccg.old_cas_group_id;

	INSERT INTO chem.cas_restricted (
				cas_code,
				root_region_sid,
				clp_table_3_1,
				clp_table_3_2,
				end_dtm,
				remarks,
				source,
				start_dtm
	   ) SELECT ccr.cas_code,
				ms.new_sid,
				ccr.clp_table_3_1,
				ccr.clp_table_3_2,
				ccr.end_dtm,
				ccr.remarks,
				ccr.source,
				ccr.start_dtm
		   FROM csrimp.chem_cas_restricted ccr,
				csrimp.map_sid ms
		  WHERE ccr.root_region_sid = ms.old_sid;

	INSERT INTO chem.classification (
				classification_id,
				description
	   ) SELECT mcc.new_classification_id,
				cc.description
		   FROM csrimp.chem_classification cc,
				csrimp.map_chem_classification mcc
		  WHERE cc.classification_id = mcc.old_classification_id;

	INSERT INTO chem.manufacturer (
				manufacturer_id,
				code,
				name
	   ) SELECT mcm.new_manufacturer_id,
				cm.code,
				cm.name
		   FROM csrimp.chem_manufacturer cm,
				csrimp.map_chem_manufacturer mcm
		  WHERE cm.manufacturer_id = mcm.old_manufacturer_id;

	INSERT INTO chem.substance (
				substance_id,
				classification_id,
				description,
				is_central,
				manufacturer_id,
				ref,
				region_sid
	   ) SELECT mcs.new_substance_id,
				mcc.new_classification_id,
				cs.description,
				cs.is_central,
				mcm.new_manufacturer_id,
				cs.ref,
				ms.new_sid
		   FROM csrimp.chem_substance cs,
				csrimp.map_chem_substance mcs,
				csrimp.map_chem_classification mcc,
				csrimp.map_chem_manufacturer mcm,
				csrimp.map_sid ms
		  WHERE cs.substance_id = mcs.old_substance_id
			AND cs.classification_id = mcc.old_classification_id
			AND cs.manufacturer_id = mcm.old_manufacturer_id
			AND cs.region_sid = ms.old_sid(+);

	INSERT INTO chem.substance_cas (
				substance_id,
				cas_code,
				pct_composition
	   ) SELECT mcs.new_substance_id,
				csc.cas_code,
				csc.pct_composition
		   FROM csrimp.chem_substance_cas csc,
				csrimp.map_chem_substance mcs
		  WHERE csc.substance_id = mcs.old_substance_id;

	INSERT INTO chem.usage (
				usage_id,
				description
	   ) SELECT mcu.new_usage_id,
				cu.description
		   FROM csrimp.chem_usage cu,
				csrimp.map_chem_usage mcu
		  WHERE cu.usage_id = mcu.old_usage_id;

	INSERT INTO chem.substance_region (
				substance_id,
				region_sid,
				first_used_dtm,
				flow_item_id,
				local_ref,
				waiver_status_id
	   ) SELECT mcs.new_substance_id,
				ms.new_sid,
				csr.first_used_dtm,
				mfi.new_flow_item_id,
				csr.local_ref,
				csr.waiver_status_id
		   FROM csrimp.chem_substance_region csr,
				csrimp.map_chem_substance mcs,
				csrimp.map_sid ms,
				csrimp.map_flow_item mfi
		  WHERE csr.substance_id = mcs.old_substance_id
			AND csr.region_sid = ms.old_sid
			AND csr.flow_item_id = mfi.old_flow_item_id(+);

	INSERT INTO chem.substance_region_process (
				substance_id,
				region_sid,
				process_id,
				active,
				first_used_dtm,
				label,
				usage_id
	   ) SELECT mcs.new_substance_id,
				ms.new_sid,
				mcsrpp.new_subst_rgn_proc_process_id,
				csrp.active,
				csrp.first_used_dtm,
				csrp.label,
				mcu.new_usage_id
		   FROM csrimp.chem_subst_region_proces csrp,
				csrimp.map_chem_substance mcs,
				csrimp.map_sid ms,
				csrimp.map_chem_sub_rgn_pro_pro mcsrpp,
				csrimp.map_chem_usage mcu
		  WHERE csrp.substance_id = mcs.old_substance_id
			AND csrp.region_sid = ms.old_sid
			AND csrp.process_id = mcsrpp.old_subst_rgn_proc_process_id
			AND csrp.usage_id = mcu.old_usage_id;

	INSERT INTO chem.process_cas_default (
				substance_id,
				region_sid,
				process_id,
				cas_code,
				remaining_dest,
				remaining_pct,
				to_air_pct,
				to_product_pct,
				to_waste_pct,
				to_water_pct
	   ) SELECT mcs.new_substance_id,
				ms.new_sid,
				mcsrpp.new_subst_rgn_proc_process_id,
				cpcd.cas_code,
				cpcd.remaining_dest,
				cpcd.remaining_pct,
				cpcd.to_air_pct,
				cpcd.to_product_pct,
				cpcd.to_waste_pct,
				cpcd.to_water_pct
		   FROM csrimp.chem_process_cas_default cpcd,
				csrimp.map_chem_substance mcs,
				csrimp.map_sid ms,
				csrimp.map_chem_sub_rgn_pro_pro mcsrpp
		  WHERE cpcd.substance_id = mcs.old_substance_id
			AND cpcd.region_sid = ms.old_sid
			AND cpcd.process_id = mcsrpp.old_subst_rgn_proc_process_id;

	INSERT INTO chem.substance_process_use_change (
				subst_proc_use_change_id,
				changed_by,
				changed_dtm,
				end_dtm,
				entry_mass_value,
				entry_std_measure_conv_id,
				mass_value,
				note,
				process_id,
				region_sid,
				retired_dtm,
				root_delegation_sid,
				start_dtm,
				substance_id
	   ) SELECT mcspuc.new_subst_proc_use_change_id,
				cspuc.changed_by,
				cspuc.changed_dtm,
				cspuc.end_dtm,
				cspuc.entry_mass_value,
				cspuc.entry_std_measure_conv_id,
				cspuc.mass_value,
				cspuc.note,
				mcsrpp.new_subst_rgn_proc_process_id,
				ms.new_sid,
				cspuc.retired_dtm,
				ms1.new_sid,
				cspuc.start_dtm,
				mcs.new_substance_id
		   FROM csrimp.chem_subs_proc_use_chang cspuc,
				csrimp.map_chem_sub_pro_use_cha mcspuc,
				csrimp.map_chem_sub_rgn_pro_pro mcsrpp,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_chem_substance mcs
		  WHERE cspuc.subst_proc_use_change_id = mcspuc.old_subst_proc_use_change_id
			AND cspuc.process_id = mcsrpp.old_subst_rgn_proc_process_id
			AND cspuc.region_sid = ms.old_sid
			AND cspuc.root_delegation_sid = ms1.old_sid(+)
			AND cspuc.substance_id = mcs.old_substance_id;

	INSERT INTO chem.subst_process_cas_dest_change (
				subst_proc_cas_dest_change_id,
				cas_code,
				changed_by,
				changed_dtm,
				remaining_dest,
				remaining_pct,
				retired_dtm,
				subst_proc_use_change_id,
				to_air_pct,
				to_product_pct,
				to_waste_pct,
				to_water_pct
	   ) SELECT mcspcdc.new_subst_proc_cas_dest_chg_id,
				cspcdc.cas_code,
				cspcdc.changed_by,
				cspcdc.changed_dtm,
				cspcdc.remaining_dest,
				cspcdc.remaining_pct,
				cspcdc.retired_dtm,
				mcspuc.new_subst_proc_use_change_id,
				cspcdc.to_air_pct,
				cspcdc.to_product_pct,
				cspcdc.to_waste_pct,
				cspcdc.to_water_pct
		   FROM csrimp.chem_sub_pro_cas_des_cha cspcdc,
				csrimp.map_chem_su_pr_ca_de_chg mcspcdc,
				csrimp.map_chem_sub_pro_use_cha mcspuc
		  WHERE cspcdc.subst_proc_cas_dest_change_id = mcspcdc.old_subst_proc_cas_dest_chg_id
			AND cspcdc.subst_proc_use_change_id = mcspuc.old_subst_proc_use_change_id(+);

	INSERT INTO chem.substance_audit_log (
				substance_audit_log_id,
				substance_id,
				changed_by,
				changed_dtm,
				description,
				param_1,
				param_2
	   ) SELECT mcsal.new_sub_audit_log_id,
				mcs.new_substance_id,
				csal.changed_by,
				csal.changed_dtm,
				csal.description,
				csal.param_1,
				csal.param_2
		   FROM csrimp.chem_substance_audit_log csal,
				csrimp.map_chem_sub_audit_log mcsal,
				csrimp.map_chem_substance mcs
		  WHERE csal.substance_audit_log_id = mcsal.old_sub_audit_log_id
			AND csal.substance_id = mcs.old_substance_id;

	INSERT INTO chem.substance_file (
				substance_file_id,
				data,
				filename,
				mime_type,
				substance_id,
				uploaded_dtm,
				uploaded_user_sid,
				url
	   ) SELECT mcsf.new_substance_file_id,
				csf.data,
				csf.filename,
				csf.mime_type,
				mcs.new_substance_id,
				csf.uploaded_dtm,
				ms.new_sid,
				csf.url
		   FROM csrimp.chem_substance_file csf,
				csrimp.map_chem_substance_file mcsf,
				csrimp.map_chem_substance mcs,
				csrimp.map_sid ms
		  WHERE csf.substance_file_id = mcsf.old_substance_file_id
			AND csf.substance_id = mcs.old_substance_id
			AND csf.uploaded_user_sid = ms.old_sid(+);


	-- remove the records where the unvalidated root delegation sid is no longer a delegation.
	DELETE FROM chem_subs_proce_use_file
	 WHERE substance_process_use_id IN (
		SELECT substance_process_use_id 
		  FROM chem_substan_process_use cspu
		  LEFT JOIN  map_sid msd ON msd.old_sid = cspu.root_delegation_sid
		 WHERE msd.old_sid IS NULL
	);

	DELETE FROM chem_subs_proce_cas_dest 
	 WHERE substance_process_use_id IN (
		SELECT substance_process_use_id 
		  FROM chem_substan_process_use cspu
		  LEFT JOIN map_sid msd ON msd.old_sid = cspu.root_delegation_sid
		 WHERE msd.old_sid IS NULL
        )
	  AND substance_id IN (
		SELECT substance_id
		  FROM chem_substan_process_use cspu
		  LEFT JOIN map_sid msd ON msd.old_sid = cspu.root_delegation_sid
		 WHERE msd.old_sid IS NULL
	);

	DELETE FROM csrimp.chem_substan_process_use 
	 WHERE root_delegation_sid IN (
		SELECT DISTINCT root_delegation_sid
		  FROM chem_substan_process_use cspu
		  LEFT JOIN map_sid msd ON msd.old_sid = cspu.root_delegation_sid
		 WHERE msd.old_sid IS NULL
	);
	--end remove


	INSERT INTO chem.substance_process_use (
				substance_process_use_id,
				changed_since_prev_period,
				end_dtm,
				entry_mass_value,
				entry_std_measure_conv_id,
				mass_value,
				note,
				process_id,
				region_sid,
				root_delegation_sid,
				start_dtm,
				substance_id
	   ) SELECT mcspu.new_substance_process_use_id,
				cspu.changed_since_prev_period,
				cspu.end_dtm,
				cspu.entry_mass_value,
				cspu.entry_std_measure_conv_id,
				cspu.mass_value,
				cspu.note,
				mcsrpp.new_subst_rgn_proc_process_id,
				ms.new_sid,
				ms1.new_sid,
				cspu.start_dtm,
				mcs.new_substance_id
		   FROM csrimp.chem_substan_process_use cspu,
				csrimp.map_chem_subst_proce_use mcspu,
				csrimp.map_chem_sub_rgn_pro_pro mcsrpp,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_chem_substance mcs
		  WHERE cspu.substance_process_use_id = mcspu.old_substance_process_use_id
			AND cspu.process_id = mcsrpp.old_subst_rgn_proc_process_id
			AND cspu.region_sid = ms.old_sid
			AND cspu.root_delegation_sid = ms1.old_sid
			AND cspu.substance_id = mcs.old_substance_id;

	INSERT INTO chem.substance_process_cas_dest (
				substance_process_use_id,
				cas_code,
				remaining_dest,
				remaining_pct,
				substance_id,
				to_air_pct,
				to_product_pct,
				to_waste_pct,
				to_water_pct
	   ) SELECT mcspu.new_substance_process_use_id,
				cspcd.cas_code,
				cspcd.remaining_dest,
				cspcd.remaining_pct,
				mcs.new_substance_id,
				cspcd.to_air_pct,
				cspcd.to_product_pct,
				cspcd.to_waste_pct,
				cspcd.to_water_pct
		   FROM csrimp.chem_subs_proce_cas_dest cspcd,
				csrimp.map_chem_subst_proce_use mcspu,
				csrimp.map_chem_substance mcs
		  WHERE cspcd.substance_process_use_id = mcspu.old_substance_process_use_id
			AND cspcd.substance_id = mcs.old_substance_id;

	INSERT INTO chem.substance_process_use_file (
				substance_process_use_file_id,
				data,
				filename,
				mime_type,
				substance_process_use_id,
				uploaded_dtm,
				uploaded_user_sid
	   ) SELECT mcspuf.new_subst_proc_use_file_id,
				cspuf.data,
				cspuf.filename,
				cspuf.mime_type,
				mcspu.new_substance_process_use_id,
				cspuf.uploaded_dtm,
				ms.new_sid
		   FROM csrimp.chem_subs_proce_use_file cspuf,
				csrimp.map_chem_sub_pro_use_fil mcspuf,
				csrimp.map_chem_subst_proce_use mcspu,
				csrimp.map_sid ms
		  WHERE cspuf.substance_process_use_file_id = mcspuf.old_subst_proc_use_file_id
			AND cspuf.substance_process_use_id = mcspu.old_substance_process_use_id
			AND cspuf.uploaded_user_sid = ms.old_sid(+);

	INSERT INTO chem.usage_audit_log (
				usage_audit_log_id,
				substance_id,
				changed_by,
				changed_dtm,
				description,
				end_dtm,
				param_1,
				param_2,
				region_sid,
				root_delegation_sid,
				start_dtm
	   ) SELECT mcual.new_usage_audit_log_id,
				mcs.new_substance_id,
				cual.changed_by,
				cual.changed_dtm,
				cual.description,
				cual.end_dtm,
				cual.param_1,
				cual.param_2,
				ms.new_sid,
				ms1.new_sid,
				cual.start_dtm
		   FROM csrimp.chem_usage_audit_log cual,
				csrimp.map_chem_usage_audit_log mcual,
				csrimp.map_chem_substance mcs,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE cual.usage_audit_log_id = mcual.old_usage_audit_log_id
			AND cual.substance_id = mcs.old_substance_id
			AND cual.region_sid = ms.old_sid(+)
			AND cual.root_delegation_sid = ms1.old_sid(+);
END;

PROCEDURE CreateRReports
AS
BEGIN

	INSERT INTO csr.r_report_type (
				r_report_type_id,
				label,
				plugin_id,
				plugin_type_id
	   ) SELECT mrrt.new_r_report_type_id,
				rrt.label,
				mp.new_plugin_id,
				rrt.plugin_type_id
		   FROM csrimp.r_report_type rrt,
				csrimp.map_r_report_type mrrt,
				csrimp.map_plugin mp
		  WHERE rrt.r_report_type_id = mrrt.old_r_report_type_id
			AND rrt.plugin_id = mp.old_plugin_id;

	INSERT INTO csr.r_report (
				r_report_sid,
				js_data,
				prepared_dtm,
				requested_by_user_sid,
				r_report_type_id
	   ) SELECT ms.new_sid,
				rr.js_data,
				rr.prepared_dtm,
				ms1.new_sid,
				mrrt.new_r_report_type_id
		   FROM csrimp.r_report rr,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_r_report_type mrrt
		  WHERE rr.r_report_sid = ms.old_sid
			AND rr.requested_by_user_sid = ms1.old_sid
			AND rr.r_report_type_id = mrrt.old_r_report_type_id;

	INSERT INTO csr.r_report_file (
				r_report_file_id,
				data,
				filename,
				mime_type,
				r_report_sid,
				show_as_download,
				show_as_tab,
				title
	   ) SELECT mrrf.new_r_report_file_id,
				rrf.data,
				rrf.filename,
				rrf.mime_type,
				ms.new_sid,
				rrf.show_as_download,
				rrf.show_as_tab,
				rrf.title
		   FROM csrimp.r_report_file rrf,
				csrimp.map_r_report_file mrrf,
				csrimp.map_sid ms
		  WHERE rrf.r_report_file_id = mrrf.old_r_report_file_id
			AND rrf.r_report_sid = ms.old_sid;

END;

PROCEDURE CreateScheduledStoredProcs
AS
BEGIN
	-- This table has an annoying circular constraint (last_ssp_log_id). So we'll set it to null here and update after the child
	-- row has been inserted below...
	INSERT INTO csr.scheduled_stored_proc (ssp_id, sp, args, description, intrval, frequency, next_run_dtm, schedule_run_dtm,
		one_off, one_off_user, one_off_date, last_ssp_log_id, enabled)
		 SELECT ssp_id, sp, args, description, intrval, frequency, next_run_dtm, schedule_run_dtm,
			one_off, one_off_user, one_off_date, NULL, enabled
		   FROM csrimp.scheduled_stored_proc;

	INSERT INTO csr.scheduled_stored_proc_log (ssp_log_id, ssp_id, run_dtm, result_code, result_msg, result_ex, one_off, one_off_user, one_off_date)
	     SELECT ssp_log_id, ssp_id, run_dtm, result_code, result_msg, result_ex, one_off, one_off_user, one_off_date
		   FROM csrimp.scheduled_stored_proc_log;

	-- Update last_ssp_log_id in parent table where necessary...
	-- These IDs map straight over. No mapping tables needed (PK is app_sid + ssp_id)
	UPDATE csr.scheduled_stored_proc ssp
	   SET last_ssp_log_id = (
			SELECT last_ssp_log_id
			  FROM csrimp.scheduled_stored_proc imp_ssp
			 WHERE ssp.ssp_id = imp_ssp.ssp_id
	   )
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE CreateLikeForLike
AS
BEGIN
	INSERT INTO	csr.like_for_like_slot
			  (like_for_like_sid, name, ind_sid, region_sid, include_inactive_regions, period_start_dtm, period_end_dtm, period_set_id, period_interval_id, rule_type,
			   scenario_run_sid, created_by_user_sid, created_dtm, last_refresh_user_sid, last_refresh_dtm)
		SELECT l4l_map.new_sid, lfls.name, ind_map.new_sid, region_map.new_sid, lfls.include_inactive_regions, lfls.period_start_dtm, lfls.period_end_dtm, lfls.period_set_id, lfls.period_interval_id, lfls.rule_type,
			   scenario_map.new_sid, user_map.new_sid, lfls.created_dtm, user_map2.new_sid, lfls.last_refresh_dtm
		  FROM csrimp.like_for_like_slot lfls, csrimp.map_sid l4l_map, csrimp.map_sid ind_map, csrimp.map_sid scenario_map, csrimp.map_sid region_map, csrimp.map_sid user_map, csrimp.map_sid user_map2
		 WHERE lfls.like_for_like_sid = l4l_map.old_sid
		   AND lfls.ind_sid = ind_map.old_sid(+)
		   AND lfls.scenario_run_sid = scenario_map.old_sid(+)
		   AND lfls.region_sid = region_map.old_sid(+)
		   AND lfls.created_by_user_sid = user_map.old_sid(+)
		   AND lfls.last_refresh_user_sid = user_map2.old_sid(+);

	INSERT INTO csr.like_for_like_email_sub
			(like_for_like_sid, csr_user_sid)
		SELECT l4l_map.new_sid, user_map.new_sid
		  FROM csrimp.like_for_like_email_sub lfles, csrimp.map_sid l4l_map, csrimp.map_sid user_map
		 WHERE lfles.like_for_like_sid = l4l_map.old_sid
		   AND lfles.csr_user_sid = user_map.old_sid(+);

	-- Purposely not copying/mapping batch jobs or excluded regions.
END;

PROCEDURE CreateDegreeDays
AS
BEGIN
	INSERT INTO csr.degreeday_settings
		(account_name, download_enabled, earliest_fetch_dtm, average_years, heating_base_temp_ind_sid,
		 cooling_base_temp_ind_sid, heating_degree_days_ind_sid, cooling_degree_days_ind_sid,
		 heating_average_ind_sid, cooling_average_ind_sid, last_sync_dtm)
	SELECT ds.account_name, ds.download_enabled, ds.earliest_fetch_dtm, ds.average_years, hbm.new_sid,
		   cbm.new_sid, hvm.new_sid, cvm.new_sid, ham.new_sid, cam.new_sid, ds.last_sync_dtm
	  FROM csrimp.degreeday_settings ds
	  LEFT JOIN csrimp.map_sid hbm ON ds.heating_base_temp_ind_sid = hbm.old_sid
	  LEFT JOIN csrimp.map_sid cbm ON ds.cooling_base_temp_ind_sid = cbm.old_sid
	  LEFT JOIN csrimp.map_sid hvm ON ds.heating_degree_days_ind_sid = hvm.old_sid
	  LEFT JOIN csrimp.map_sid cvm ON ds.cooling_degree_days_ind_sid = cvm.old_sid
	  LEFT JOIN csrimp.map_sid ham ON ds.heating_average_ind_sid = ham.old_sid
	  LEFT JOIN csrimp.map_sid cam ON ds.cooling_average_ind_sid = cam.old_sid;

	INSERT INTO csr.degreeday_region (region_sid, station_id, station_description, station_update_dtm)
	SELECT rm.new_sid, dr.station_id, dr.station_description, dr.station_update_dtm
	  FROM csrimp.degreeday_region dr
	  JOIN csrimp.map_sid rm ON rm.old_sid = dr.region_sid;
END;

PROCEDURE CreateInitiatives
AS
BEGIN
	INSERT INTO csr.initiative_metric (
				initiative_metric_id,
				divisibility,
				is_during,
				is_external,
				is_rampable,
				is_running,
				is_saving,
				label,
				lookup_key,
				measure_sid,
				one_off_period,
				per_period_duration
	   ) SELECT mim.new_initiative_metric_id,
				im.divisibility,
				im.is_during,
				im.is_external,
				im.is_rampable,
				im.is_running,
				im.is_saving,
				im.label,
				im.lookup_key,
				ms.new_sid,
				im.one_off_period,
				im.per_period_duration
		   FROM csrimp.initiative_metric im,
				csrimp.map_initiative_metric mim,
				csrimp.map_sid ms
		  WHERE im.initiative_metric_id = mim.old_initiative_metric_id
			AND im.measure_sid = ms.old_sid;

	INSERT INTO csr.initiative_project (
				project_sid,
				abbreviation,
				category_level,
				end_dtm,
				fields_xml,
				flow_sid,
				helper_pkg,
				icon,
				live_flow_state_id,
				name,
				period_fields_xml,
				pos,
				pos_group,
				start_dtm,
				tab_sid
	   ) SELECT ms.new_sid,
				ip.abbreviation,
				ip.category_level,
				ip.end_dtm,
				ip.fields_xml,
				ms1.new_sid,
				ip.helper_pkg,
				ip.icon,
				mfs.new_flow_state_id,
				ip.name,
				ip.period_fields_xml,
				ip.pos,
				ip.pos_group,
				ip.start_dtm,
				ms2.new_sid
		   FROM csrimp.initiative_project ip,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_flow_state mfs,
				csrimp.map_sid ms2
		  WHERE ip.project_sid = ms.old_sid
			AND ip.flow_sid = ms1.old_sid
			AND ip.live_flow_state_id = mfs.old_flow_state_id
			AND ip.tab_sid = ms2.old_sid(+);

	INSERT INTO csr.initiative_project_rag_status (
				project_sid,
				rag_status_id,
				pos
	   ) SELECT ms.new_sid,
				mrs.new_rag_status_id,
				iprs.pos
		   FROM csrimp.initia_projec_rag_status iprs,
				csrimp.map_sid ms,
				csrimp.map_rag_status mrs
		  WHERE iprs.project_sid = ms.old_sid
			AND iprs.rag_status_id = mrs.old_rag_status_id;

	INSERT INTO csr.customer_init_saving_type (
				saving_type_id,
				is_during,
				is_running
	   ) SELECT cist.saving_type_id,
				cist.is_during,
				cist.is_running
		   FROM csrimp.customer_init_saving_type cist;

	INSERT INTO csr.initiative_metric_group (
				project_sid,
				pos_group,
				info_text,
				is_group_mandatory,
				label
	   ) SELECT ms.new_sid,
				img.pos_group,
				img.info_text,
				img.is_group_mandatory,
				img.label
		   FROM csrimp.initiative_metric_group img,
				csrimp.map_sid ms
		  WHERE img.project_sid = ms.old_sid;

	INSERT INTO csr.project_initiative_metric (
				project_sid,
				initiative_metric_id,
				default_value,
				display_context,
				flow_sid,
				info_text,
				input_dp,
				pos,
				pos_group,
				update_per_period
	   ) SELECT ms.new_sid,
				mim.new_initiative_metric_id,
				pim.default_value,
				pim.display_context,
				ms1.new_sid,
				pim.info_text,
				pim.input_dp,
				pim.pos,
				pim.pos_group,
				pim.update_per_period
		   FROM csrimp.project_initiative_metric pim,
				csrimp.map_sid ms,
				csrimp.map_initiative_metric mim,
				csrimp.map_sid ms1
		  WHERE pim.project_sid = ms.old_sid
			AND pim.initiative_metric_id = mim.old_initiative_metric_id
			AND pim.flow_sid = ms1.old_sid;

	INSERT INTO csr.initiative_metric_assoc (
				project_sid,
				proposed_metric_id,
				measured_metric_id
	   ) SELECT ms.new_sid,
				mim.new_initiative_metric_id,
				mim1.new_initiative_metric_id
		   FROM csrimp.initiative_metric_assoc ima,
				csrimp.map_sid ms,
				csrimp.map_initiative_metric mim,
				csrimp.map_initiative_metric mim1
		  WHERE ima.project_sid = ms.old_sid
			AND ima.proposed_metric_id = mim.old_initiative_metric_id
			AND ima.measured_metric_id = mim1.old_initiative_metric_id;

	INSERT INTO csr.project_init_metric_flow_state (
				initiative_metric_id,
				flow_state_id,
				project_sid,
				flow_sid,
				mandatory,
				visible
	   ) SELECT mim.new_initiative_metric_id,
				mfs.new_flow_state_id,
				ms.new_sid,
				ms1.new_sid,
				pimfs.mandatory,
				pimfs.visible
		   FROM csrimp.project_init_metric_flow_state pimfs,
				csrimp.map_initiative_metric mim,
				csrimp.map_flow_state mfs,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE pimfs.initiative_metric_id = mim.old_initiative_metric_id
			AND pimfs.flow_state_id = mfs.old_flow_state_id
			AND pimfs.project_sid = ms.old_sid
			AND pimfs.flow_sid = ms1.old_sid;

	INSERT INTO csr.aggr_tag_group (
				aggr_tag_group_id,
				count_ind_sid,
				label,
				lookup_key
	   ) SELECT matg.new_aggr_tag_group_id,
				ms.new_sid,
				atg.label,
				atg.lookup_key
		   FROM csrimp.aggr_tag_group atg,
				csrimp.map_aggr_tag_group matg,
				csrimp.map_sid ms
		  WHERE atg.aggr_tag_group_id = matg.old_aggr_tag_group_id
			AND atg.count_ind_sid = ms.old_sid(+);

	INSERT INTO csr.aggr_tag_group_member (
				aggr_tag_group_id,
				tag_id
	   ) SELECT matg.new_aggr_tag_group_id,
				mt.new_tag_id
		   FROM csrimp.aggr_tag_group_member atgm,
				csrimp.map_aggr_tag_group matg,
				csrimp.map_tag mt
		  WHERE atgm.aggr_tag_group_id = matg.old_aggr_tag_group_id
			AND atgm.tag_id = mt.old_tag_id;

	INSERT INTO csr.initiative_metric_tag_ind (
				initiative_metric_id,
				aggr_tag_group_id,
				ind_sid,
				measure_sid
	   ) SELECT mim.new_initiative_metric_id,
				matg.new_aggr_tag_group_id,
				ms.new_sid,
				ms1.new_sid
		   FROM csrimp.initiativ_metric_tag_ind imti,
				csrimp.map_initiative_metric mim,
				csrimp.map_aggr_tag_group matg,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE imti.initiative_metric_id = mim.old_initiative_metric_id
			AND imti.aggr_tag_group_id = matg.old_aggr_tag_group_id
			AND imti.ind_sid = ms.old_sid
			AND imti.measure_sid = ms1.old_sid;

	INSERT INTO csr.initiative_metric_state_ind (
				initiative_metric_id,
				flow_state_group_id,
				ind_sid,
				measure_sid,
				net_period
	   ) SELECT mim.new_initiative_metric_id,
				mfsg.new_flow_state_group_id,
				ms.new_sid,
				ms1.new_sid,
				imsi.net_period
		   FROM csrimp.initiat_metric_state_ind imsi,
				csrimp.map_initiative_metric mim,
				csrimp.map_flow_state_group mfsg,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE imsi.initiative_metric_id = mim.old_initiative_metric_id
			AND imsi.flow_state_group_id = mfsg.old_flow_state_group_id
			AND imsi.ind_sid = ms.old_sid
			AND imsi.measure_sid = ms1.old_sid;

	INSERT INTO csr.initiatives_options (
				auto_complete_date,
				current_report_date,
				gantt_period_colour,
				initiatives_host,
				initiative_name_gen_proc,
				initiative_new_days,
				initiative_reminder_alerts,
				metrics_end_year,
				metrics_start_year,
				my_initiatives_options,
				update_ref_on_amend
	   ) SELECT io.auto_complete_date,
				io.current_report_date,
				io.gantt_period_colour,
				io.initiatives_host,
				io.initiative_name_gen_proc,
				io.initiative_new_days,
				io.initiative_reminder_alerts,
				io.metrics_end_year,
				io.metrics_start_year,
				io.my_initiatives_options,
				io.update_ref_on_amend
		   FROM csrimp.initiatives_options io;

	INSERT INTO csr.user_msg (
				user_msg_id,
				msg_dtm,
				msg_text,
				reply_to_msg_id,
				user_sid
	   ) SELECT mum.new_user_msg_id,
				um.msg_dtm,
				um.msg_text,
				mum1.new_user_msg_id,
				ms.new_sid
		   FROM csrimp.user_msg um,
				csrimp.map_user_msg mum,
				csrimp.map_user_msg mum1,
				csrimp.map_sid ms
		  WHERE um.user_msg_id = mum.old_user_msg_id
			AND um.reply_to_msg_id = mum1.old_user_msg_id(+)
			AND um.user_sid = ms.old_sid;

	INSERT INTO csr.user_msg_file (
				user_msg_file_id,
				data,
				filename,
				mime_type,
				sha1,
				user_msg_id
	   ) SELECT mumf.new_user_msg_file_id,
				umf.data,
				umf.filename,
				umf.mime_type,
				umf.sha1,
				mum.new_user_msg_id
		   FROM csrimp.user_msg_file umf,
				csrimp.map_user_msg_file mumf,
				csrimp.map_user_msg mum
		  WHERE umf.user_msg_file_id = mumf.old_user_msg_file_id
			AND umf.user_msg_id = mum.old_user_msg_id;

	INSERT INTO csr.initiative_period_status (
				initiative_period_status_id,
				colour,
				label,
				means_pct_complete
	   ) SELECT mips.new_initiativ_period_status_id,
				ips.colour,
				ips.label,
				ips.means_pct_complete
		   FROM csrimp.initiative_period_status ips,
				csrimp.map_initia_period_status mips
		  WHERE ips.initiative_period_status_id = mips.old_initiativ_period_status_id;

	INSERT INTO csr.project_initiative_period_stat (
				project_sid,
				initiative_period_status_id
	   ) SELECT ms.new_sid,
				mips.new_initiativ_period_status_id
		   FROM csrimp.project_initiative_period_stat pips,
				csrimp.map_sid ms,
				csrimp.map_initia_period_status mips
		  WHERE pips.project_sid = ms.old_sid
			AND pips.initiative_period_status_id = mips.old_initiativ_period_status_id;

	INSERT INTO csr.default_initiative_user_state (
				flow_state_id,
				flow_sid,
				is_editable,
				generate_alerts
	   ) SELECT mfs.new_flow_state_id,
				ms.new_sid,
				dius.is_editable,
				dius.generate_alerts
		   FROM csrimp.default_initiative_user_state dius,
				csrimp.map_sid ms,
                csrimp.map_flow_state mfs
		  WHERE dius.flow_sid = ms.old_sid(+)
			AND dius.flow_state_id = mfs.old_flow_state_id;

	INSERT INTO csr.aggr_region (
				region_sid,
				aggr_region_sid
	   ) SELECT ms.new_sid,
				ms1.new_sid
		   FROM csrimp.aggr_region ar,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE ar.region_sid = ms.old_sid
			AND ar.aggr_region_sid = ms1.old_sid;

	INSERT INTO csr.project_doc_folder (
				project_sid,
				name,
				info_text,
				label
	   ) SELECT ms.new_sid,
				pdf.name,
				pdf.info_text,
				pdf.label
		   FROM csrimp.project_doc_folder pdf,
				csrimp.map_sid ms
		  WHERE pdf.project_sid = ms.old_sid;

	INSERT INTO csr.project_tag_group (
				project_sid,
				tag_group_id,
				default_tag_id,
				pos
	   ) SELECT ms.new_sid,
				mtg.new_tag_group_id,
				mt.new_tag_id,
				ptg.pos
		   FROM csrimp.project_tag_group ptg,
				csrimp.map_sid ms,
				csrimp.map_tag_group mtg,
				csrimp.map_tag mt
		  WHERE ptg.project_sid = ms.old_sid
			AND ptg.tag_group_id = mtg.old_tag_group_id
			AND ptg.default_tag_id = mt.old_tag_id;

	INSERT INTO csr.project_tag_filter (
				project_sid,
				tag_group_id,
				tag_id
	   ) SELECT ms.new_sid,
				mtg.new_tag_group_id,
				mt.new_tag_id
		   FROM csrimp.project_tag_filter ptf,
				csrimp.map_sid ms,
				csrimp.map_tag_group mtg,
				csrimp.map_tag mt
		  WHERE ptf.project_sid = ms.old_sid
			AND ptf.tag_group_id = mtg.old_tag_group_id
			AND ptf.tag_id = mt.old_tag_id;

	INSERT INTO csr.initiative (
				initiative_sid,
				created_by_sid,
				created_dtm,
				doc_library_sid,
				fields_xml,
				flow_item_id,
				flow_sid,
				internal_ref,
				is_ramped,
				name,
				parent_sid,
				period_duration,
				project_end_dtm,
				project_sid,
				project_start_dtm,
				rag_status_id,
				running_end_dtm,
				running_start_dtm,
				saving_type_id
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				i.created_dtm,
				ms2.new_sid,
				i.fields_xml,
				mfi.new_flow_item_id,
				ms3.new_sid,
				i.internal_ref,
				i.is_ramped,
				i.name,
				ms4.new_sid,
				i.period_duration,
				i.project_end_dtm,
				ms5.new_sid,
				i.project_start_dtm,
				mrs.new_rag_status_id,
				i.running_end_dtm,
				i.running_start_dtm,
				i.saving_type_id
		   FROM csrimp.initiative i,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_flow_item mfi,
				csrimp.map_sid ms3,
				csrimp.map_sid ms4,
				csrimp.map_sid ms5,
				csrimp.map_rag_status mrs
		  WHERE i.initiative_sid = ms.old_sid
			AND i.created_by_sid = ms1.old_sid
			AND i.doc_library_sid = ms2.old_sid(+)
			AND i.flow_item_id = mfi.old_flow_item_id
			AND i.flow_sid = ms3.old_sid
			AND i.parent_sid = ms4.old_sid(+)
			AND i.project_sid = ms5.old_sid
			AND i.rag_status_id = mrs.old_rag_status_id(+);

	INSERT INTO csr.initiative_comment (
				initiative_comment_id,
				comment_text,
				initiative_sid,
				posted_dtm,
				user_sid
	   ) SELECT mic.new_initiative_comment_id,
				ic.comment_text,
				ms.new_sid,
				ic.posted_dtm,
				ms1.new_sid
		   FROM csrimp.initiative_comment ic,
				csrimp.map_initiative_comment mic,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE ic.initiative_comment_id = mic.old_initiative_comment_id
			AND ic.initiative_sid = ms.old_sid(+)
			AND ic.user_sid = ms1.old_sid;

	INSERT INTO csr.initiative_event (
				initiative_event_id,
				created_by_sid,
				created_dtm,
				description,
				end_dtm,
				initiative_sid,
				location,
				start_dtm
	   ) SELECT mie.new_initiative_event_id,
				ms.new_sid,
				ie.created_dtm,
				ie.description,
				ie.end_dtm,
				ms1.new_sid,
				ie.location,
				ie.start_dtm
		   FROM csrimp.initiative_event ie,
				csrimp.map_initiative_event mie,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE ie.initiative_event_id = mie.old_initiative_event_id
			AND ie.created_by_sid = ms.old_sid
			AND ie.initiative_sid = ms1.old_sid;

	INSERT INTO csr.initiative_group (
				initiative_group_id,
				is_public,
				name
	   ) SELECT mig.new_initiative_group_id,
				ig.is_public,
				ig.name
		   FROM csrimp.initiative_group ig,
				csrimp.map_initiative_group mig
		  WHERE ig.initiative_group_id = mig.old_initiative_group_id;

	INSERT INTO csr.initiative_group_member (
				initiative_group_id,
				initiative_sid
	   ) SELECT mig.new_initiative_group_id,
				ms.new_sid
		   FROM csrimp.initiative_group_member igm,
				csrimp.map_initiative_group mig,
				csrimp.map_sid ms
		  WHERE igm.initiative_group_id = mig.old_initiative_group_id
			AND igm.initiative_sid = ms.old_sid;

	INSERT INTO csr.initiative_group_user (
				initiative_group_id,
				user_sid,
				can_edit
	   ) SELECT mig.new_initiative_group_id,
				ms.new_sid,
				igu.can_edit
		   FROM csrimp.initiative_group_user igu,
				csrimp.map_initiative_group mig,
				csrimp.map_sid ms
		  WHERE igu.initiative_group_id = mig.old_initiative_group_id
			AND igu.user_sid = ms.old_sid;

	INSERT INTO csr.initiative_import_map_mru (
				csr_user_sid,
				from_name,
				to_name,
				pos
	   ) SELECT ms.new_sid,
				iimm.from_name,
				iimm.to_name,
				iimm.pos
		   FROM csrimp.initiative_import_map_mru iimm,
				csrimp.map_sid ms
		  WHERE iimm.csr_user_sid = ms.old_sid;

	INSERT INTO csr.initiative_import_template (
				import_template_id,
				heading_row_idx,
				is_default,
				name,
				project_sid,
				workbook,
				worksheet_name
	   ) SELECT mit.new_import_template_id,
				iit.heading_row_idx,
				iit.is_default,
				iit.name,
				ms.new_sid,
				iit.workbook,
				iit.worksheet_name
		   FROM csrimp.initiati_import_template iit,
				csrimp.map_import_template mit,
				csrimp.map_sid ms
		  WHERE iit.import_template_id = mit.old_import_template_id
			AND iit.project_sid = ms.old_sid(+);

	INSERT INTO csr.initiative_import_template_map (
				import_template_id,
				to_name,
				from_idx,
				from_name
	   ) SELECT mit.new_import_template_id,
				iitm.to_name,
				iitm.from_idx,
				iitm.from_name
		   FROM csrimp.initia_import_templa_map iitm,
				csrimp.map_import_template mit
		  WHERE iitm.import_template_id = mit.old_import_template_id;

	INSERT INTO csr.initiative_metric_val (
				initiative_metric_id,
				initiative_sid,
				entry_measure_conversion_id,
				entry_val,
				measure_sid,
				project_sid,
				val
	   ) SELECT mim.new_initiative_metric_id,
				ms.new_sid,
				mmc.new_measure_conversion_id,
				imv.entry_val,
				ms1.new_sid,
				ms2.new_sid,
				imv.val
		   FROM csrimp.initiative_metric_val imv,
				csrimp.map_initiative_metric mim,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
                csrimp.map_measure_conversion mmc
		  WHERE imv.initiative_metric_id = mim.old_initiative_metric_id
			AND imv.initiative_sid = ms.old_sid
			AND imv.measure_sid = ms1.old_sid(+)
			AND imv.project_sid = ms2.old_sid
	        AND imv.entry_measure_conversion_id = mmc.old_measure_conversion_id(+);

	INSERT INTO csr.initiative_period (
				initiative_sid,
				region_sid,
				start_dtm,
				approved_by_sid,
				approved_dtm,
				end_dtm,
				entered_by_sid,
				entered_dtm,
				fields_xml,
				initiative_period_status_id,
				needs_aggregation,
				project_sid,
				public_comment_approved_by_sid,
				public_comment_approved_dtm,
				set_flow_state_id
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				ip.start_dtm,
				ms2.new_sid,
				ip.approved_dtm,
				ip.end_dtm,
				ms3.new_sid,
				ip.entered_dtm,
				ip.fields_xml,
				mips.new_initiativ_period_status_id,
				ip.needs_aggregation,
				ms4.new_sid,
				ms5.new_sid,
				ip.public_comment_approved_dtm,
				mfs.new_flow_state_id
		   FROM csrimp.initiative_period ip,
				csrimp.map_sid ms,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2,
				csrimp.map_sid ms3,
				csrimp.map_initia_period_status mips,
				csrimp.map_sid ms4,
				csrimp.map_sid ms5,
				csrimp.map_flow_state mfs
		  WHERE ip.initiative_sid = ms.old_sid
			AND ip.region_sid = ms1.old_sid
			AND ip.approved_by_sid = ms2.old_sid(+)
			AND ip.entered_by_sid = ms3.old_sid
			AND ip.initiative_period_status_id = mips.old_initiativ_period_status_id
			AND ip.project_sid = ms4.old_sid
			AND ip.public_comment_approved_by_sid = ms5.old_sid(+)
			AND ip.set_flow_state_id = mfs.old_flow_state_id(+);

	INSERT INTO csr.initiative_project_tab (
				project_sid,
				plugin_id,
				plugin_type_id,
				pos,
				tab_label
	   ) SELECT ms.new_sid,
				mp.new_plugin_id,
				ipt.plugin_type_id,
				ipt.pos,
				ipt.tab_label
		   FROM csrimp.initiative_project_tab ipt,
				csrimp.map_sid ms,
				csrimp.map_plugin mp
		  WHERE ipt.project_sid = ms.old_sid
			AND ipt.plugin_id = mp.old_plugin_id;

	INSERT INTO csr.initiative_project_tab_group (
				project_sid,
				plugin_id,
				group_sid,
				is_read_only
	   ) SELECT ms.new_sid,
				mp.new_plugin_id,
				ms1.new_sid,
				iptg.is_read_only
		   FROM csrimp.initia_project_tab_group iptg,
				csrimp.map_sid ms,
				csrimp.map_plugin mp,
				csrimp.map_sid ms1
		  WHERE iptg.project_sid = ms.old_sid
			AND iptg.plugin_id = mp.old_plugin_id
			AND iptg.group_sid = ms1.old_sid;

	INSERT INTO csr.initiative_project_team (
				email,
				initiative_sid,
				name
	   ) SELECT ipt.email,
				ms.new_sid,
				ipt.name
		   FROM csrimp.initiative_project_team ipt,
				csrimp.map_sid ms
		  WHERE ipt.initiative_sid = ms.old_sid;

	INSERT INTO csr.initiative_region (
				initiative_sid,
				region_sid,
				use_for_calc
	   ) SELECT ms.new_sid,
				ms1.new_sid,
				ir.use_for_calc
		   FROM csrimp.initiative_region ir,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE ir.initiative_sid = ms.old_sid
			AND ir.region_sid = ms1.old_sid;

	INSERT INTO csr.initiative_sponsor (
				email,
				initiative_sid,
				name
	   ) SELECT isp.email,
				ms.new_sid,
				isp.name
		   FROM csrimp.initiative_sponsor isp,
				csrimp.map_sid ms
		  WHERE isp.initiative_sid = ms.old_sid;

	INSERT INTO csr.initiative_tag (
				initiative_sid,
				tag_id
	   ) SELECT ms.new_sid,
				mt.new_tag_id
		   FROM csrimp.initiative_tag it,
				csrimp.map_sid ms,
				csrimp.map_tag mt
		  WHERE it.initiative_sid = ms.old_sid
			AND it.tag_id = mt.old_tag_id;

	INSERT INTO csr.initiative_user_group (
				initiative_user_group_id,
				label,
				lookup_key,
				synch_issues
	   ) SELECT miug.new_initiative_user_group_id,
				iug.label,
				iug.lookup_key,
				iug.synch_issues
		   FROM csrimp.initiative_user_group iug,
				csrimp.map_initiativ_user_group miug
		  WHERE iug.initiative_user_group_id = miug.old_initiative_user_group_id;

	INSERT INTO csr.initiative_project_user_group (
				initiative_user_group_id,
				project_sid
	   ) SELECT miug.new_initiative_user_group_id,
				ms.new_sid
		   FROM csrimp.initia_projec_user_group ipug,
				csrimp.map_initiativ_user_group miug,
				csrimp.map_sid ms
		  WHERE ipug.initiative_user_group_id = miug.old_initiative_user_group_id
			AND ipug.project_sid = ms.old_sid;

	INSERT INTO csr.initiative_user (
				initiative_sid,
				initiative_user_group_id,
				user_sid,
				project_sid
	   ) SELECT ms.new_sid,
				miug.new_initiative_user_group_id,
				ms1.new_sid,
				ms2.new_sid
		   FROM csrimp.initiative_user iu,
				csrimp.map_sid ms,
				csrimp.map_initiativ_user_group miug,
				csrimp.map_sid ms1,
				csrimp.map_sid ms2
		  WHERE iu.initiative_sid = ms.old_sid
			AND iu.initiative_user_group_id = miug.old_initiative_user_group_id
			AND iu.user_sid = ms1.old_sid
			AND iu.project_sid = ms2.old_sid;

	INSERT INTO csr.initiative_user_msg (
				initiative_sid,
				user_msg_id
	   ) SELECT ms.new_sid,
				mum.new_user_msg_id
		   FROM csrimp.initiative_user_msg ium,
				csrimp.map_sid ms,
				csrimp.map_user_msg mum
		  WHERE ium.initiative_sid = ms.old_sid
			AND ium.user_msg_id = mum.old_user_msg_id;

	INSERT INTO csr.initiative_group_flow_state (
				initiative_user_group_id,
				flow_state_id,
				flow_sid,
				generate_alerts,
				is_editable,
				project_sid
	   ) SELECT miug.new_initiative_user_group_id,
				mfs.new_flow_state_id,
				ms.new_sid,
				igfs.generate_alerts,
				igfs.is_editable,
				ms1.new_sid
		   FROM csrimp.initiat_group_flow_state igfs,
				csrimp.map_initiativ_user_group miug,
				csrimp.map_flow_state mfs,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE igfs.initiative_user_group_id = miug.old_initiative_user_group_id
			AND igfs.flow_state_id = mfs.old_flow_state_id
			AND igfs.flow_sid = ms.old_sid
			AND igfs.project_sid = ms1.old_sid;

	INSERT INTO csr.issue_initiative (
				issue_initiative_id,
				initiative_sid
	   ) SELECT mii.new_issue_initiative_id,
				ms.new_sid
		   FROM csrimp.issue_initiative ii,
				csrimp.map_issue_initiative mii,
				csrimp.map_sid ms
		  WHERE ii.issue_initiative_id = mii.old_issue_initiative_id
			AND ii.initiative_sid = ms.old_sid;

	INSERT INTO csr.init_tab_element_layout (element_id, plugin_id, tag_group_id, xml_field_id, pos)
	     SELECT mit.new_element_id, mp.new_plugin_id, mt.new_tag_group_id, it.xml_field_id, it.pos
		   FROM init_tab_element_layout it
		   JOIN map_init_tab_element_layout mit ON it.element_id = mit.old_element_id
		   JOIN map_plugin mp ON it.plugin_id = mp.old_plugin_id
		   LEFT JOIN map_tag_group mt ON it.tag_group_id = mt.old_tag_group_id;

	INSERT INTO csr.init_create_page_el_layout (element_id, section_id, tag_group_id, xml_field_id, pos)
	     SELECT mic.new_element_id, ic.section_id, mt.new_tag_group_id, ic.xml_field_id, ic.pos
		   FROM init_create_page_el_layout ic
		   JOIN map_init_create_page_el_layout mic ON ic.element_id = mic.old_element_id
		   LEFT JOIN map_tag_group mt ON ic.tag_group_id = mt.old_tag_group_id;

	INSERT INTO csr.initiative_header_element (initiative_header_element_id, pos, col, initiative_metric_id, tag_group_id, init_header_core_element_id)
	     SELECT mih.new_init_header_element_id, ih.pos, ih.col, mim.new_initiative_metric_id, mt.new_tag_group_id, ih.init_header_core_element_id
		   FROM initiative_header_element ih
		   JOIN map_initiative_header_element mih ON ih.initiative_header_element_id = mih.old_init_header_element_id
		   LEFT JOIN map_initiative_metric mim ON ih.initiative_metric_id = mim.old_initiative_metric_id
		   LEFT JOIN map_tag_group mt ON ih.tag_group_id = mt.old_tag_group_id;
END;

PROCEDURE CreateCustomFactors
AS
BEGIN
	INSERT INTO csr.custom_factor_set
		(custom_factor_set_id, name, created_by_sid, created_dtm, factor_set_group_id, info_note)
	SELECT cfs.custom_factor_set_id, cfs.name, mu.new_sid, cfs.created_dtm, cfs.factor_set_group_id, cfs.info_note
	  FROM csrimp.custom_factor_set cfs
	  LEFT JOIN csrimp.map_sid mu ON cfs.created_by_sid = mu.old_sid;

	INSERT INTO csr.custom_factor
		(custom_factor_id, custom_factor_set_id, factor_type_id, gas_type_id,
		geo_country, geo_region, egrid_ref, region_sid, std_measure_conversion_id,
		start_dtm, end_dtm, value, note)
	SELECT cf.custom_factor_id, cf.custom_factor_set_id, cf.factor_type_id, cf.gas_type_id,
		cf.geo_country, cf.geo_region, cf.egrid_ref, mr.new_sid, cf.std_measure_conversion_id,
		cf.start_dtm, cf.end_dtm, cf.value, cf.note
	  FROM csrimp.custom_factor cf
	  LEFT JOIN csrimp.map_sid mr ON cf.region_sid = mr.old_sid
	 WHERE cf.custom_factor_set_id IN (SELECT custom_factor_set_id FROM csr.custom_factor_set);

	INSERT INTO csr.custom_factor_history (custom_factor_history_id, factor_cat_id, factor_type_id,
		factor_set_id, geo_country, geo_region, egrid_ref, region_sid, gas_type_id, start_dtm,
		end_dtm, field_name, old_val, new_val, message, audit_date, user_sid)
	SELECT csr.custom_factor_history_seq.nextval, cfh.factor_cat_id, cfh.factor_type_id, cfh.factor_set_id,
		cfh.geo_country, cfh.geo_region, cfh.egrid_ref, mr.new_sid, cfh.gas_type_id, cfh.start_dtm,
		cfh.end_dtm, cfh.field_name, cfh.old_val, cfh.new_val, cfh.message, cfh.audit_date, mu.new_sid
	  FROM csrimp.custom_factor_history cfh
	  LEFT JOIN csrimp.map_sid mu ON cfh.user_sid = mu.old_sid
	  LEFT JOIN csrimp.map_sid mr ON cfh.region_sid = mr.old_sid;
END;

PROCEDURE CreateEmissionFactorProfiles
AS
BEGIN
	INSERT INTO csr.emission_factor_profile
		(profile_id, name, start_dtm, end_dtm, applied)
	SELECT efp.profile_id, efp.name, efp.start_dtm, efp.end_dtm, efp.applied
	  FROM csrimp.emission_factor_profile efp;

	INSERT INTO csr.emission_factor_profile_factor
		(profile_id, factor_type_id, std_factor_set_id, custom_factor_set_id,
		 region_sid, geo_country, geo_region, egrid_ref)
	SELECT efpf.profile_id, efpf.factor_type_id, efpf.std_factor_set_id, efpf.custom_factor_set_id,
		   mr.new_sid, efpf.geo_country, efpf.geo_region, efpf.egrid_ref
	  FROM csrimp.emission_factor_profile_factor efpf
	  LEFT JOIN csrimp.map_sid mr ON efpf.region_sid = mr.old_sid;

	INSERT INTO csr.std_factor_set_active
		(std_factor_set_id)
	SELECT sfsa.std_factor_set_id
	  FROM csrimp.std_factor_set_active sfsa;

END;

PROCEDURE CreateCompliance
AS
BEGIN
	INSERT INTO csr.compliance_options (
			   quick_survey_type_id, rollout_delay, requirement_flow_sid, regulation_flow_sid, permit_flow_sid, application_flow_sid, condition_flow_sid, rollout_option, score_type_id, auto_involve_managers, permit_doc_lib_sid, permit_score_type_id)
		SELECT mqt.new_quick_survey_type_id, co.rollout_delay, mrqw.new_sid, mrf.new_sid, mpf.new_sid, maf.new_sid, mcf.new_sid, co.rollout_option, mst.new_score_type_id, co.auto_involve_managers, msdl.new_sid, mst2.new_score_type_id
		  FROM csrimp.compliance_options co
		  JOIN csrimp.map_qs_type mqt ON co.quick_survey_type_id = mqt.old_quick_survey_type_id
		  LEFT JOIN csrimp.map_sid mrqw ON co.requirement_flow_sid = mrqw.old_sid
		  LEFT JOIN csrimp.map_sid mrf ON co.regulation_flow_sid = mrf.old_sid
		  LEFT JOIN csrimp.map_sid mpf ON co.permit_flow_sid = mpf.old_sid
		  LEFT JOIN csrimp.map_sid maf ON co.application_flow_sid = maf.old_sid
		  LEFT JOIN csrimp.map_sid mcf ON co.condition_flow_sid = mcf.old_sid
		  LEFT JOIN csrimp.map_score_type mst ON co.score_type_id = mst.old_score_type_id
		  LEFT JOIN csrimp.map_score_type mst2 ON co.permit_score_type_id = mst2.old_score_type_id
		  LEFT JOIN csrimp.map_qs_type mqst ON co.quick_survey_type_id = mqst.old_quick_survey_type_id
		  LEFT JOIN csrimp.map_sid msdl ON co.permit_doc_lib_sid = msdl.old_sid;

	INSERT INTO csr.compliance_language (
			   lang_id, added_dtm, active)
		SELECT cl.lang_id, cl.added_dtm, cl.active
		  FROM csrimp.compliance_language cl;

	INSERT INTO csr.compliance_item (
			   compliance_item_id, title, summary, details, source, reference_code, user_comment,
			   citation, external_link, created_dtm, updated_dtm, compliance_item_status_id,
			   major_version, minor_version, lookup_key, compliance_item_type)
		SELECT mci.new_compliance_item_id, ci.title, ci.summary, ci.details, ci.source,
			   ci.reference_code, ci.user_comment, ci.citation, ci.external_link, ci.created_dtm,
			   ci.updated_dtm, ci.compliance_item_status_id, ci.major_version, ci.minor_version,
			   ci.lookup_key, ci.compliance_item_type
		  FROM csrimp.compliance_item ci
		  JOIN csrimp.map_compliance_item mci ON ci.compliance_item_id = mci.old_compliance_item_id;

	INSERT INTO csr.compliance_item_version_log (
				compliance_item_version_log_id, compliance_item_id, change_type, major_version, minor_version, description, change_dtm, is_major_change, lang_id)
		SELECT mcih.new_comp_item_version_log_id, mci.new_compliance_item_id, cih.change_type, cih.major_version,
				cih.minor_version, cih.description, cih.change_dtm, cih.is_major_change, cih.lang_id
		  FROM csrimp.compliance_item_version_log cih
		  LEFT JOIN csrimp.map_compliance_item mci ON cih.compliance_item_id = mci.old_compliance_item_id
		  LEFT JOIN csrimp.map_comp_item_version_log mcih ON cih.compliance_item_version_log_id = mcih.old_comp_item_version_log_id;

	INSERT INTO csr.compliance_item_desc_hist (
				compliance_item_desc_hist_id, compliance_item_id, lang_id, major_version, minor_version, title, summary, summary_clob, details, citation, description, change_dtm)
		SELECT mcidh.new_comp_item_desc_hist_id, mci.new_compliance_item_id, cidh.lang_id, 
				cidh.major_version, cidh.minor_version, cidh.title, cidh.summary, cidh.summary_clob, cidh.details, cidh.citation, cidh.description, cidh.change_dtm
		  FROM csrimp.compliance_item_desc_hist cidh
		  LEFT JOIN csrimp.map_compliance_item mci ON cidh.compliance_item_id = mci.old_compliance_item_id
		  LEFT JOIN csrimp.map_compliance_item_desc_hist mcidh ON cidh.compliance_item_desc_hist_id = mcidh.old_comp_item_desc_hist_id;

	INSERT INTO csr.compliance_audit_log (compliance_audit_log_id, compliance_item_id, date_time, responsible_user, 
				user_lang_id, sys_lang_id, lang_id, title, summary, details, citation) 
		SELECT mcal.new_compliance_audit_log_id, mci.new_compliance_item_id, cal.date_time, mru.new_sid, cal.user_lang_id, 
			   cal.sys_lang_id, cal.lang_id, cal.title, cal.summary, cal.details, cal.citation
		  FROM csrimp.compliance_audit_log cal
		  LEFT JOIN csrimp.map_compliance_audit_log mcal ON cal.compliance_audit_log_id = mcal.old_compliance_audit_log_id
		  LEFT JOIN csrimp.map_compliance_item mci ON cal.compliance_item_id = mci.old_compliance_item_id
		  LEFT JOIN csrimp.map_sid mru ON cal.responsible_user = mru.old_sid;

	INSERT INTO csr.compliance_item_tag (compliance_item_id, tag_id)
		SELECT mci.new_compliance_item_id, mt.new_tag_id
		  FROM csrimp.compliance_item_tag cit
		  JOIN csrimp.map_compliance_item mci ON cit.compliance_item_id = mci.old_compliance_item_id
		  JOIN csrimp.map_tag mt ON cit.tag_id = mt.old_tag_id;

	INSERT INTO csr.compliance_requirement (compliance_item_id)
		SELECT mci.new_compliance_item_id
		  FROM csrimp.compliance_requirement cr
		  JOIN csrimp.map_compliance_item mci ON cr.compliance_item_id = mci.old_compliance_item_id;

	INSERT INTO csr.compliance_regulation (compliance_item_id, adoption_dtm, external_id, is_policy)
		SELECT mci.new_compliance_item_id, cr.adoption_dtm, cr.external_id, cr.is_policy
		  FROM csrimp.compliance_regulation cr
		  JOIN csrimp.map_compliance_item mci ON cr.compliance_item_id = mci.old_compliance_item_id;

	INSERT INTO csr.compliance_req_reg (requirement_id, regulation_id)
		SELECT mreq.new_compliance_item_id, mreg.new_compliance_item_id
		  FROM csrimp.compliance_req_reg crr
		  JOIN csrimp.map_compliance_item mreq ON crr.requirement_id = mreq.old_compliance_item_id
		  JOIN csrimp.map_compliance_item mreg ON crr.regulation_id = mreg.old_compliance_item_id;

	INSERT INTO csr.compliance_item_region (compliance_item_id, region_sid, flow_item_id, out_of_scope)
		SELECT mci.new_compliance_item_id, mr.new_sid, mfi.new_flow_item_id, cir.out_of_scope
		  FROM csrimp.compliance_item_region cir
		  JOIN csrimp.map_compliance_item mci ON cir.compliance_item_id = mci.old_compliance_item_id
		  JOIN csrimp.map_sid mr ON cir.region_sid = mr.old_sid
		  LEFT JOIN csrimp.map_flow_item mfi ON cir.flow_item_id = mfi.old_flow_item_id;

	INSERT INTO csr.flow_item_audit_log (
	            flow_item_audit_log_id, flow_item_id, log_dtm, user_sid, description, comment_text)
		SELECT mfial.new_flow_item_audit_log_id, mfi.new_flow_item_id, fial.log_dtm, ms.new_sid, fial.description, fial.comment_text
		  FROM flow_item_audit_log fial
		  JOIN map_flow_item_audit_log mfial ON fial.flow_item_audit_log_id = mfial.new_flow_item_audit_log_id
		  JOIN map_flow_item mfi ON fial.flow_item_id = mfi.old_flow_item_id
		  JOIN map_sid ms ON fial.user_sid = ms.old_sid;

	INSERT INTO csr.compliance_region_tag (tag_id, region_sid)
		SELECT mt.new_tag_id, mr.new_sid
		  FROM csrimp.compliance_region_tag crt
		  JOIN csrimp.map_tag mt ON crt.tag_id = mt.old_tag_id
		  JOIN csrimp.map_sid mr ON crt.region_sid = mr.old_sid;

	INSERT INTO csr.compliance_root_regions (region_sid, region_type, rollout_level)
		SELECT mr.new_sid, crr.region_type, crr.rollout_level
		  FROM csrimp.compliance_root_regions crr
		  JOIN csrimp.map_sid mr ON crr.region_sid = mr.old_sid;

	INSERT INTO csr.enhesa_options (client_id, username, password, last_success, last_run, next_run, last_message, manual_run, packages_imported,
		packages_total, items_imported, items_total, links_created, links_total)
	SELECT client_id, username, password, last_success, last_run, next_run, last_message, manual_run, packages_imported, packages_total,
			items_imported, items_total, links_created, links_total
	  FROM csrimp.enhesa_options;

	INSERT INTO csr.enhesa_error_log (error_log_id, error_dtm, error_message, stack_trace)
	SELECT meel.new_error_log_id, eel.error_dtm, eel.error_message, eel.stack_trace
	  FROM csrimp.enhesa_error_log eel
	  JOIN csrimp.map_enhesa_error_log meel ON eel.error_log_id = meel.old_error_log_id;
	
	INSERT INTO csr.compliance_permit_type (
				permit_type_id,
				description,
				pos
	   ) SELECT mcpt.new_compliance_permit_type_id,
				cpt.description,
				cpt.pos
		   FROM csrimp.compliance_permit_type cpt,
				csrimp.map_complian_permit_type mcpt
		  WHERE cpt.permit_type_id = mcpt.old_compliance_permit_type_id;

	INSERT INTO csr.compliance_condition_type (
				condition_type_id,
				description,
				pos
	   ) SELECT mcct.new_complian_condition_type_id,
				cct.description,
				cct.pos
		   FROM csrimp.compliance_condition_type cct,
				csrimp.map_complia_conditi_type mcct
		  WHERE cct.condition_type_id = mcct.old_complian_condition_type_id;

	INSERT INTO csr.compliance_permit_sub_type (
				permit_type_id,
				permit_sub_type_id,
				description,
				pos
	  )  SELECT	mcpt.new_compliance_permit_type_id,
				mcpst.new_complia_permit_sub_type_id,
				cpst.description,
				cpst.pos
		   FROM csrimp.compliance_permit_sub_type cpst
		   JOIN csrimp.map_complian_permit_type mcpt
			 ON mcpt.old_compliance_permit_type_id = cpst.permit_type_id
		   JOIN csrimp.map_compl_permi_sub_type mcpst
			 ON mcpst.old_complia_permit_sub_type_id = cpst.permit_sub_type_id
			AND mcpst.old_compliance_permit_type_id = cpst.permit_type_id;

	INSERT INTO csr.compliance_condition_sub_type (
				condition_type_id,
				condition_sub_type_id,
				description,
				pos
	   ) SELECT mcct.new_complian_condition_type_id,
				mccst.new_comp_condition_sub_type_id,
				ccst.description,
				ccst.pos
		   FROM csrimp.compliance_condition_sub_type ccst
		   JOIN csrimp.map_complia_conditi_type mcct
		     ON mcct.old_complian_condition_type_id = ccst.condition_type_id
		   JOIN csrimp.map_complia_condition_sub_type mccst
			 ON mccst.old_comp_condition_sub_type_id = ccst.condition_sub_type_id
			AND mccst.old_complian_condition_type_id = ccst.condition_type_id;

	INSERT INTO csr.compliance_activity_type (
				activity_type_id,
				description,
				pos
	   ) SELECT mcat.new_complianc_activity_type_id,
				cat.description,
				cat.pos
		   FROM csrimp.compliance_activity_type cat,
				csrimp.map_complia_activit_type mcat
		  WHERE cat.activity_type_id = mcat.old_complianc_activity_type_id;

	INSERT INTO csr.compliance_activity_sub_type (activity_type_id, activity_sub_type_id, description, pos)
		SELECT mcat.new_complianc_activity_type_id, mast.new_compl_activity_sub_type_id, cat.description, cat.pos
		  FROM csrimp.compliance_activity_sub_type cat
		  JOIN csrimp.map_complia_activit_type mcat ON cat.activity_type_id = mcat.old_complianc_activity_type_id
		  JOIN csrimp.map_compl_activity_sub_type mast ON cat.activity_sub_type_id = mast.old_compl_activity_sub_type_id
		   AND cat.activity_type_id = mast.old_complianc_activity_type_id;

	INSERT INTO csr.compliance_application_type (
				application_type_id,
				description,
				pos
	   ) SELECT mcat.new_complianc_applicatio_tp_id,
				cat.description,
				cat.pos
		   FROM csrimp.compliance_application_type cat,
				csrimp.map_complian_applicat_tp mcat
		  WHERE cat.application_type_id = mcat.old_complianc_applicatio_tp_id;

	INSERT INTO csr.compliance_item_rollout (
				compliance_item_rollout_id,
				compliance_item_id,
				country,
				country_group,
				region,
				region_group,
				rollout_dtm,
				rollout_pending,
				federal_requirement_code,
				is_federal_req,
				source_region,
				source_country,
				suppress_rollout
	   ) SELECT mcir.new_compliance_item_rollout_id,
				mci.new_compliance_item_id,
				cir.country,
				cir.country_group,
				cir.region,
				cir.region_group,
				cir.rollout_dtm,
				cir.rollout_pending,
				cir.federal_requirement_code,
				cir.is_federal_req,
				cir.source_region,
				cir.source_country,
				cir.suppress_rollout
		   FROM csrimp.compliance_item_rollout cir,
				csrimp.map_compliance_item_rollout mcir,
				csrimp.map_compliance_item mci
		  WHERE cir.compliance_item_rollout_id = mcir.old_compliance_item_rollout_id
		    AND cir.compliance_item_id = mci.old_compliance_item_id;

	INSERT INTO csr.compliance_permit (
				compliance_permit_id,
				activity_end_dtm,
				activity_start_dtm,
				activity_type_id,
				flow_item_id,
				permit_end_dtm,
				permit_reference,
				site_commissioning_required,
				site_commissioning_dtm,
				permit_start_dtm,
				permit_sub_type_id,
				permit_type_id,
				region_sid,
				title,
				date_created,
				date_updated,
				created_by,
				activity_details
	   ) SELECT mcp.new_compliance_permit_id,
				cp.activity_end_dtm,
				cp.activity_start_dtm,
				mpat.new_complianc_activity_type_id,
				mfi.new_flow_item_id,
				cp.permit_end_dtm,
				cp.permit_reference,
				cp.site_commissioning_required,
				cp.site_commissioning_dtm,
				cp.permit_start_dtm,
				mpst.new_complia_permit_sub_type_id,
				mpt.new_compliance_permit_type_id,
				ms.new_sid,
				cp.title,
				cp.date_created,
				cp.date_updated,
				ms2.new_sid,
				cp.activity_details
		   FROM csrimp.compliance_permit cp
		   JOIN csrimp.map_compliance_permit mcp ON cp.compliance_permit_id = mcp.old_compliance_permit_id
		   JOIN csrimp.map_sid ms ON cp.region_sid = ms.old_sid
		   JOIN csrimp.map_flow_item mfi ON cp.flow_item_id = mfi.old_flow_item_id
		   LEFT JOIN csrimp.map_sid ms2 ON cp.created_by = ms2.old_sid
		   JOIN map_complian_permit_type mpt ON cp.permit_type_id = mpt.old_compliance_permit_type_id
		   LEFT JOIN map_compl_permi_sub_type mpst ON cp.permit_sub_type_id = mpst.old_complia_permit_sub_type_id AND mpst.old_compliance_permit_type_id = cp.permit_type_id
		   JOIN map_complia_activit_type mpat ON cp.activity_type_id = mpat.old_complianc_activity_type_id;

	INSERT INTO csr.compliance_permit_history (prev_permit_id, next_permit_id)
		SELECT mp.new_compliance_permit_id, mn.new_compliance_permit_id
		  FROM csrimp.compliance_permit_history cph
		  JOIN csrimp.map_compliance_permit mp ON cph.prev_permit_id = mp.old_compliance_permit_id
		  JOIN csrimp.map_compliance_permit mn ON cph.next_permit_id = mn.old_compliance_permit_id;

	INSERT INTO csr.compliance_permit_application (
				permit_application_id,
				application_reference,
				application_type_id,
				determined_dtm,
				duly_made_dtm,
				notes,
				permit_id,
				flow_item_id,
				submission_dtm,
				title,
				compl_permit_app_status_id
	   ) SELECT mcpa.new_compliance_permit_appl_id,
				cpa.application_reference,
				mcat.new_complianc_applicatio_tp_id,
				cpa.determined_dtm,
				cpa.duly_made_dtm,
				cpa.notes,
				mcp.new_compliance_permit_id,
				mfi.new_flow_item_id,
				cpa.submission_dtm,
				cpa.title,
				cpa.compl_permit_app_status_id
		   FROM csrimp.compliance_permit_application cpa
		   JOIN csrimp.map_complian_permit_appl mcpa
		     ON cpa.permit_application_id = mcpa.old_compliance_permit_appl_id
		   JOIN csrimp.map_complian_applicat_tp mcat
		     ON mcat.old_complianc_applicatio_tp_id = cpa.application_type_id
		   JOIN csrimp.map_compliance_permit mcp
		     ON mcp.old_compliance_permit_id = cpa.permit_id
		   JOIN csrimp.map_flow_item mfi
			 ON mfi.old_flow_item_id = cpa.flow_item_id;

	INSERT INTO csr.compl_permit_application_pause (
				application_pause_id,
				permit_application_id,
				paused_dtm,
				resumed_dtm
	   ) SELECT csr.application_pause_id_seq.NEXTVAL,
				mcpa.new_compliance_permit_appl_id,
				cpap.paused_dtm,
				cpap.resumed_dtm
		   FROM csrimp.compl_permit_application_pause cpap
		   JOIN csrimp.map_complian_permit_appl mcpa
		     ON cpap.permit_application_id = mcpa.old_compliance_permit_appl_id;

	INSERT INTO csr.compliance_permit_condition (
				compliance_item_id,
				compliance_permit_id,
				condition_sub_type_id,
				condition_type_id,
				copied_from_id
	   ) SELECT mci.new_compliance_item_id,
				mcp.new_compliance_permit_id,
				mccst.new_comp_condition_sub_type_id,
				mcct.new_complian_condition_type_id,
				mcci.new_compliance_item_id
		   FROM csrimp.compliance_permit_condition cpc
		   JOIN csrimp.map_compliance_item mci
		     ON mci.old_compliance_item_id = cpc.compliance_item_id
		   JOIN csrimp.map_compliance_permit mcp
		     ON mcp.old_compliance_permit_id = cpc.compliance_permit_id
		   LEFT JOIN csrimp.map_complia_condition_sub_type mccst
		     ON mccst.old_comp_condition_sub_type_id = cpc.condition_sub_type_id
		    AND mccst.old_complian_condition_type_id = cpc.condition_type_id
		   JOIN csrimp.map_complia_conditi_type mcct
		     ON mcct.old_complian_condition_type_id = cpc.condition_type_id
		   LEFT JOIN csrimp.map_compliance_item mcci
		     ON mcci.old_compliance_item_id = cpc.copied_from_id;

	INSERT INTO csr.compliance_permit_tab(
				plugin_id,
				plugin_type_id,
				pos,
				tab_label
       ) SELECT mp.new_plugin_id,
				plugin_type_id,
				cpt.pos,
				cpt.tab_label
		   FROM csrimp.compliance_permit_tab cpt
		   JOIN csrimp.map_plugin mp ON cpt.plugin_id = mp.old_plugin_id;

	INSERT INTO csr.compliance_permit_tab_group (
				plugin_id,
				group_sid,
				role_sid
       ) SELECT mp.new_plugin_id,
				mg.new_sid,
				mr.new_sid
		   FROM csrimp.compliance_permit_tab_group cptg
		   JOIN csrimp.map_plugin mp ON cptg.plugin_id = mp.old_plugin_id
		   LEFT JOIN csrimp.map_sid mg ON cptg.group_sid = mg.old_sid
		   LEFT JOIN csrimp.map_sid mr ON cptg.role_sid = mr.new_sid;

	INSERT INTO csr.compliance_rollout_regions (compliance_item_id,region_sid)
		SELECT ci.new_compliance_item_id, mr.new_sid
		  FROM csrimp.compliance_rollout_regions crrs
		  JOIN csrimp.map_sid mr ON crrs.region_sid = mr.old_sid
		  JOIN csrimp.map_compliance_item ci on crrs.compliance_item_id = ci.old_compliance_item_id;

	INSERT INTO csr.compliance_item_description (compliance_item_id, lang_id, major_version, minor_version, title, summary, details, citation)
		 SELECT mci.new_compliance_item_id, civ.lang_id, civ.major_version, civ.minor_version, civ.title, civ.summary, civ.details, civ.citation
		   FROM csrimp.compliance_item_description civ
		   JOIN csrimp.map_compliance_item mci
		     ON mci.old_compliance_item_id = civ.compliance_item_id;

	INSERT INTO csr.compliance_permit_header(
				plugin_id,
				plugin_type_id,
				pos
       ) SELECT mp.new_plugin_id,
				plugin_type_id,
				cpt.pos
		   FROM csrimp.compliance_permit_header cpt
		   JOIN csrimp.map_plugin mp ON cpt.plugin_id = mp.old_plugin_id;

		   INSERT INTO csr.compliance_permit_header_group (
				plugin_id,
				group_sid,
				role_sid
       ) SELECT mp.new_plugin_id,
				mg.new_sid,
				mr.new_sid
		   FROM csrimp.compliance_permit_header_group cptg
		   JOIN csrimp.map_plugin mp ON cptg.plugin_id = mp.old_plugin_id
		   LEFT JOIN csrimp.map_sid mg ON cptg.group_sid = mg.old_sid
		   LEFT JOIN csrimp.map_sid mr ON cptg.role_sid = mr.new_sid;

	INSERT INTO csr.compliance_permit_score (
				compliance_permit_score_id,
				compliance_permit_id,
				score_threshold_id,
				score_type_id,
				score,
				comment_text,
				set_dtm,
				changed_by_user_sid,
				valid_until_dtm,
				score_source_type,
				score_source_id,
				is_override
       ) SELECT mcps.new_compliance_permit_score_id, mcp.new_compliance_permit_id, mst.new_score_threshold_id, msty.new_score_type_id,
			cps.score, cps.comment_text, cps.set_dtm, mcu.new_sid, cps.valid_until_dtm, cps.score_source_type,
			CASE
				WHEN cps.score_source_type = csr.csr_data_pkg.SCORE_SOURCE_TYPE_QS THEN mqss.new_submission_id
				WHEN cps.score_source_type = csr.csr_data_pkg.SCORE_SOURCE_TYPE_AUDIT THEN ms.new_sid
				WHEN cps.score_source_type = csr.csr_data_pkg.SCORE_SOURCE_TYPE_SCORE_CALC THEN ms.new_sid
				ELSE NULL
			END,
			cps.is_override
		   FROM csrimp.compliance_permit_score cps
		   JOIN csrimp.map_compliance_permit mcp ON cps.compliance_permit_id = mcp.old_compliance_permit_id
		   JOIN csrimp.map_compliance_permit_score mcps ON cps.compliance_permit_score_id = mcps.old_compliance_permit_score_id
		   LEFT JOIN csrimp.map_sid mcu ON cps.changed_by_user_sid = mcu.old_sid
		   LEFT JOIN csrimp.map_score_threshold mst ON cps.score_threshold_id = mst.old_score_threshold_id
		   LEFT JOIN csrimp.map_score_type msty ON cps.score_type_id = msty.old_score_type_id
		   LEFT JOIN csrimp.map_qs_submission mqss ON cps.score_source_id = mqss.old_submission_id
		   LEFT JOIN csrimp.map_sid ms ON cps.score_source_id = ms.old_sid;

	-- Add permit item to document folders
	UPDATE csr.doc_folder df
	   SET permit_item_id = (
			SELECT mcp.new_compliance_permit_id
			  FROM csrimp.doc_folder idf
			  JOIN csrimp.map_sid mdf ON idf.doc_folder_sid = mdf.old_sid
			  JOIN csrimp.map_compliance_permit mcp ON idf.permit_item_id = mcp.old_compliance_permit_id
			 WHERE df.doc_folder_sid = mdf.new_sid
		)
	 WHERE df.doc_folder_sid IN (
		SELECT mdf.new_sid
		  FROM csrimp.doc_folder idf
		  JOIN csrimp.map_sid mdf ON idf.doc_folder_sid = mdf.old_sid
	 );
END;

PROCEDURE CreateCalendar
AS
BEGIN
	INSERT INTO csr.calendar (
				calendar_sid,
				applies_to_initiatives,
				applies_to_teamrooms,
				description,
				is_global,
				js_class_type,
				js_include,
				plugin_id
	   ) SELECT ms.new_sid,
				c.applies_to_initiatives,
				c.applies_to_teamrooms,
				c.description,
				c.is_global,
				c.js_class_type,
				c.js_include,
				mp.new_plugin_id
		   FROM csrimp.map_sid ms,
				csrimp.calendar c
		   JOIN csrimp.map_plugin mp
		     ON mp.old_plugin_id = c.plugin_id
		  WHERE c.calendar_sid = ms.old_sid;

	INSERT INTO csrimp.map_calendar_event (old_calendar_event_id, new_calendar_event_id)
		 SELECT calendar_event_id, csr.calendar_event_id_seq.NEXTVAL
		   FROM csrimp.calendar_event;

	INSERT INTO csr.calendar_event (
				calendar_event_id,
				created_by_sid,
				created_dtm,
				description,
				end_dtm,
				location,
				region_sid,
				start_dtm
	   ) SELECT mce.new_calendar_event_id,
				ms.new_sid,
				ce.created_dtm,
				ce.description,
				ce.end_dtm,
				ce.location,
				ms1.new_sid,
				ce.start_dtm
		   FROM csrimp.calendar_event ce,
				csrimp.map_calendar_event mce,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE ce.calendar_event_id = mce.old_calendar_event_id
			AND ce.created_by_sid = ms.old_sid
			AND ce.region_sid = ms1.old_sid(+);

	INSERT INTO csr.calendar_event_invite (
				calendar_event_id,
				user_sid,
				accepted_dtm,
				attended,
				declined_dtm,
				invited_by_sid,
				invited_dtm
	   ) SELECT mce.new_calendar_event_id,
				ms.new_sid,
				cei.accepted_dtm,
				cei.attended,
				cei.declined_dtm,
				ms1.new_sid,
				cei.invited_dtm
		   FROM csrimp.calendar_event_invite cei,
				csrimp.map_calendar_event mce,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE cei.calendar_event_id = mce.old_calendar_event_id
			AND cei.user_sid = ms.old_sid
			AND cei.invited_by_sid = ms1.old_sid;

	INSERT INTO csr.calendar_event_owner (
				calendar_event_id,
				user_sid,
				added_by_sid,
				added_dtm
	   ) SELECT mce.new_calendar_event_id,
				ms.new_sid,
				ms1.new_sid,
				ceo.added_dtm
		   FROM csrimp.calendar_event_owner ceo,
				csrimp.map_calendar_event mce,
				csrimp.map_sid ms,
				csrimp.map_sid ms1
		  WHERE ceo.calendar_event_id = mce.old_calendar_event_id
			AND ceo.user_sid = ms.old_sid
			AND ceo.added_by_sid = ms1.old_sid;
END;

PROCEDURE CreateClientUtilScripts
AS
BEGIN
	INSERT INTO csrimp.map_client_util_script (old_client_util_script_id, new_client_util_script_id)
		 SELECT client_util_script_id, csr.client_util_script_id_seq.NEXTVAL
		   FROM csrimp.client_util_script;

	INSERT INTO csr.client_util_script (
				client_util_script_id,
				description,
				util_script_name,
				util_script_sp,
				wiki_article
	   ) SELECT mcus.new_client_util_script_id,
				cus.description,
				cus.util_script_name,
				MapCustomerSchema(cus.util_script_sp),
				cus.wiki_article
		   FROM csrimp.client_util_script cus,
				csrimp.map_client_util_script mcus
		  WHERE cus.client_util_script_id = mcus.old_client_util_script_id;

	INSERT INTO csr.client_util_script_param (
				client_util_script_id,
				pos,
				param_hidden,
				param_hint,
				param_name,
				param_value
	   ) SELECT mcus.new_client_util_script_id,
				cusp.pos,
				cusp.param_hidden,
				cusp.param_hint,
				cusp.param_name,
				cusp.param_value
		   FROM csrimp.client_util_script_param cusp,
				csrimp.map_client_util_script mcus
		  WHERE cusp.client_util_script_id = mcus.old_client_util_script_id;

	INSERT INTO csr.util_script_run_log (
				client_util_script_id,
				csr_user_sid,
				params,
				run_dtm,
				util_script_id
	   ) SELECT mcus.new_client_util_script_id,
				ms.new_sid,
				usrl.params,
				usrl.run_dtm,
				usrl.util_script_id
		   FROM csrimp.util_script_run_log usrl,
				csrimp.map_client_util_script mcus,
				csrimp.map_sid ms
		  WHERE usrl.client_util_script_id = mcus.old_client_util_script_id(+)
			AND usrl.csr_user_sid = ms.old_sid;
END;

PROCEDURE CreateIntegrationApiTables
AS
BEGIN
	INSERT INTO csr.intapi_company_user_group (group_sid_id)
	SELECT mg.new_sid 
	FROM csrimp.intapi_company_user_group cug
	LEFT JOIN csrimp.map_sid mg ON cug.group_sid_id = mg.old_sid;
END;

PROCEDURE CreateOshaMappings
AS
BEGIN
	INSERT INTO csr.osha_mapping (osha_map_field_id, ind_sid, cms_col_sid, region_data_map_id)
	SELECT omp.osha_map_field_id, mpa.new_sid, mpb.new_sid, omp.region_data_map_id
	  FROM csrimp.osha_mapping omp
	  LEFT JOIN csrimp.map_sid mpa ON omp.ind_sid = mpa.old_sid
	  LEFT JOIN csrimp.map_sid mpb ON omp.cms_col_sid = mpb.old_sid;
END;

PROCEDURE CreateSysTranslationsAuditLogs
AS
BEGIN
	INSERT INTO csr.sys_translations_audit_log (sys_translations_audit_log_id, audit_date, translated_id, user_sid, description)
	SELECT mstal.new_sys_trans_audit_log_id, tal.audit_date, tal.translated_id, tal.user_sid, tal.description
	  FROM csrimp.sys_translations_audit_log tal
	  LEFT JOIN csrimp.map_sys_trans_audit_log mstal ON tal.sys_translations_audit_log_id = mstal.old_sys_trans_audit_log_id;

	INSERT INTO csr.sys_translations_audit_data (sys_translations_audit_log_id, audit_date, is_delete, original, translation, old_translation)
	SELECT mstal.new_sys_trans_audit_log_id, tad.audit_date, tad.is_delete, tad.original, tad.translation, tad.old_translation
	  FROM csrimp.sys_translations_audit_data tad
	  LEFT JOIN csrimp.map_sys_trans_audit_log mstal ON tad.sys_translations_audit_log_id = mstal.old_sys_trans_audit_log_id;
END;

PROCEDURE CreateDataBuckets
AS
BEGIN
	INSERT INTO csr.data_bucket (data_bucket_sid, description, enabled, active_instance_id)
		SELECT mdb.new_sid, db.description, db.enabled, null
		  FROM csrimp.map_sid mdb, csrimp.data_bucket db
		 WHERE db.data_bucket_sid = mdb.old_sid;
END;

PROCEDURE CreateIntegrationQuestionAnswer
AS
BEGIN
	INSERT INTO csr.integration_question_answer (parent_ref, questionnaire_name, question_ref, internal_audit_sid,
			   section_name, section_code, section_score, subsection_name,
			   subsection_code, question_text, rating, conclusion, answer,
			   data_points, last_updated, id)
		SELECT iqa.parent_ref, iqa.questionnaire_name, iqa.question_ref, mdb.new_sid,
			   iqa.section_name, iqa.section_code, iqa.section_score, iqa.subsection_name,
			   iqa.subsection_code, iqa.question_text, iqa.rating, iqa.conclusion, iqa.answer,
			   iqa.data_points, iqa.last_updated, iqa.id
		  FROM csrimp.integration_question_answer iqa
		  LEFT JOIN csrimp.map_sid mdb on mdb.old_sid = iqa.internal_audit_sid;
END;

PROCEDURE CreateRegionCertificates
AS
BEGIN
	INSERT INTO csr.region_certificate (region_certificate_id, region_sid, certification_id, certification_level_id, certificate_number,
			   floor_area, issued_dtm, expiry_dtm, external_certificate_id, deleted, note, submit_to_gresb)
		SELECT csr.region_certificate_id_seq.NEXTVAL, mr.new_sid, rc.certification_id, rc.certification_level_id, rc.certificate_number,
				rc.floor_area, rc.issued_dtm, rc.expiry_dtm, rc.external_certificate_id, rc.deleted, rc.note, rc.submit_to_gresb
		  FROM csrimp.region_certificate rc
		  JOIN csrimp.map_sid mr ON rc.region_sid = mr.old_sid;
END;

PROCEDURE CreateRegionEnergyRatings
AS
BEGIN
	INSERT INTO csr.region_energy_rating (region_energy_rating_id, region_sid, energy_rating_id,
			   floor_area, issued_dtm, expiry_dtm, note, submit_to_gresb)
		SELECT rer.region_energy_rating_id, mr.new_sid, rer.energy_rating_id, rer.floor_area, rer.issued_dtm, rer.expiry_dtm, rer.note, rer.submit_to_gresb
		  FROM csrimp.region_energy_rating rer
		  JOIN csrimp.map_sid mr ON rer.region_sid = mr.old_sid;
END;

PROCEDURE CreateModuleHistory
AS
BEGIN
	INSERT INTO csr.module_history (module_id, enabled_dtm, last_enabled_dtm, disabled_dtm)
		SELECT mh.module_id, mh.enabled_dtm, mh.last_enabled_dtm, mh.disabled_dtm
		  FROM csrimp.module_history mh;
END;

PROCEDURE CreateBaselineConfigs
AS
BEGIN
	INSERT INTO csr.baseline_config (baseline_config_id, baseline_name, baseline_lookup_key)
		SELECT mbc.new_baseline_config_id, bc.baseline_name, bc.baseline_lookup_key
		  FROM csrimp.baseline_config bc, csrimp.map_baseline_config mbc
		 WHERE mbc.old_baseline_config_id = bc.baseline_config_id;

	INSERT INTO csr.baseline_config_period (baseline_config_period_id, baseline_config_id, baseline_period_dtm, baseline_cover_period_start_dtm, baseline_cover_period_end_dtm)
		SELECT mbcp.new_baseline_config_period_id, mbc.new_baseline_config_id, baseline_period_dtm, baseline_cover_period_start_dtm, baseline_cover_period_end_dtm
		  FROM csrimp.baseline_config_period bcp, csrimp.map_baseline_config mbc, csrimp.map_baseline_config_period mbcp
		 WHERE mbc.old_baseline_config_id = bcp.baseline_config_id
		   AND mbcp.old_baseline_config_period_id = bcp.baseline_config_period_id;
END;

END imp_pkg;
/
