CREATE OR REPLACE PACKAGE BODY CSR.schema_Pkg AS

-- This package is only used by csrexp and so contains no security
m_known_sos						security.T_VARCHAR2_TABLE;
m_known_sids					security.T_SID_TABLE;
m_sids							security.T_SID_TABLE;
m_ind_sids						security.T_SID_TABLE;
m_region_sids					security.T_SID_TABLE;
m_user_sids						security.T_SID_TABLE;
m_form_sids						security.T_SID_TABLE;
m_dataview_sids					security.T_SID_TABLE;
m_deleg_sids					security.T_SID_TABLE;
m_system_account_sid			security_pkg.T_SID_ID;
m_system_root_sid				security_pkg.T_SID_ID;
m_tracker_account_sid			security_pkg.T_SID_ID;
m_tracker_root_sid				security_pkg.T_SID_ID;
-- if this is zero, we try and skip inds/regions in the trash
-- (often with disastrous consequences)
m_export_everything				NUMBER DEFAULT 1;

PROCEDURE InitExport(
	in_export_everything			IN	NUMBER
)
AS
BEGIN
	m_export_everything := in_export_everything;
END;

PROCEDURE GetSuperAdmins(
	out_cur							OUT	SYS_REFCURSOR,
	out_folders_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		-- Superadmins
		SELECT csr_user_sid, email, guid, full_name, user_name,
			   friendly_name
		  FROM superadmin
		 UNION ALL
		-- Zombie superadmins: somebody has gone around deleting rows from superadmin,
		-- but leaving the /csr/users/account object.  These zombie superadmins
		-- may have created objects, so we need to export them.
		-- Instead of being created as zombies, they will be reinstated to a normal
		-- logon disabled superadmin status on import.
		SELECT so.sid_id, 'nobody@credit360.com', security.user_pkg.GenerateACT, so.name,
			   so.name, so.name
		  FROM security.securable_object so, security.user_table ut
		 WHERE so.parent_sid_id = securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security_pkg.SID_ROOT, '/csr/users')
		   AND ut.sid_id = so.sid_id
		   AND so.sid_id NOT IN (
		   		SELECT csr_user_sid
		   		  FROM superadmin);

	OPEN out_folders_cur FOR
		SELECT parent_sid_id csr_user_sid, sid_id, name
		  FROM security.securable_object
		 WHERE parent_sid_id IN (
				SELECT sid_id
				  FROM security.securable_object
				 WHERE parent_sid_id = securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security_pkg.SID_ROOT, '/csr/users'))
		   AND LOWER(name) IN ('charts', 'workspace', 'filters', 'cms filters', 'pivot tables');
END;

PROCEDURE GetSecuritySchema(
	out_soc_cur						OUT SYS_REFCURSOR,
	out_att_cur						OUT SYS_REFCURSOR,
	out_pm_cur						OUT SYS_REFCURSOR,
	out_pn_cur						OUT SYS_REFCURSOR
)
AS
	v_class_ids						security.T_SID_TABLE;
	v_superadmin_sos				security.T_SID_TABLE;
	v_trash_sid						customer.trash_sid%TYPE;
	type t_paths is table of varchar2(4000);
	v_paths 						t_paths;
BEGIN
	-- no security, only used by csrexp
	v_paths := t_paths(
		'/aspen',
		'/aspen/applications',
		'/csr',
		'/csr/help',
		'/csr/users',
		'/csr/superadmins',
		'/mail',
		'/mail/accounts',
		'/mail/folders'
	);
	m_known_sos := security.T_VARCHAR2_TABLE();
	FOR i IN v_paths.FIRST .. v_paths.LAST LOOP
		m_known_sos.extend(1);
		m_known_sos(m_known_sos.count) := security.T_VARCHAR2_ROW(i, v_paths(i));
	END LOOP;

	SELECT trash_sid
	  INTO v_trash_sid
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- mailboxes and folders we want to export
	SELECT asys.account_sid, asys.root_mailbox_sid,
		   atrac.account_sid, atrac.root_mailbox_sid
	  INTO m_system_account_sid, m_system_root_sid,
	       m_tracker_account_sid, m_tracker_root_sid
	  FROM mail.account asys, mail.account atrac, customer c
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND LOWER(c.system_mail_address) = LOWER(asys.email_address)
	   AND LOWER(c.tracker_mail_address) = LOWER(atrac.email_address);

	-- get objects that live under the per user folders for superadmins that belong
	-- to the application.  these really either need a better place to live, or better
	-- yet, shared nothing in security
	SELECT sid_id
	  BULK COLLECT INTO v_superadmin_sos
	  FROM security.securable_object
		   START WITH application_sid_id = SYS_CONTEXT('SECURITY', 'APP') AND parent_sid_id IN (
				SELECT sid_id
				  FROM security.securable_object
				 WHERE parent_sid_id IN (
						SELECT sid_id
						  FROM security.securable_object
						 WHERE parent_sid_id = securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security_pkg.SID_ROOT, '/csr/users'))
			   	   AND LOWER(name) IN ('charts', 'workspace', 'filters', 'cms filters', 'pivot tables'))
		   CONNECT BY PRIOR application_sid_id = application_sid_id AND PRIOR sid_id = parent_sid_id;

	IF m_export_everything = 1 THEN
		SELECT sid_id
		  BULK COLLECT INTO m_sids
		  FROM security.securable_object
		  	   START WITH sid_id IN (
		  	   		SYS_CONTEXT('SECURITY', 'APP'),
		  	   		m_system_account_sid,
		  	   		m_system_root_sid,
		  	   		m_tracker_account_sid,
		  	   		m_tracker_root_sid) OR sid_id IN (
		  	   		SELECT column_value
		  	   		  FROM TABLE(v_superadmin_sos))
		  	   CONNECT BY PRIOR sid_id = parent_sid_id;
	ELSE
		-- filter out regions/inds in the trash, but export everything else in there
		WITH trash AS (
			SELECT sid_id
			  FROM security.securable_object
			 	   START WITH sid_id = v_trash_sid
			 	   CONNECT BY PRIOR sid_id = parent_sid_id
		)
		SELECT sid_id
		  BULK COLLECT INTO m_sids
		  FROM security.securable_object
		 WHERE sid_id NOT IN (
		 		SELECT t.sid_id
		 		  FROM ind i, trash t
		 		 WHERE i.ind_sid = t.sid_id
		 		 UNION ALL
		 		SELECT t.sid_id
		 		  FROM region r, trash t
		 		 WHERE r.region_sid = t.sid_id)
		  	   START WITH sid_id IN (
		  	   		SYS_CONTEXT('SECURITY', 'APP'),
		  	   		m_system_account_sid,
		  	   		m_system_root_sid,
		  	   		m_tracker_account_sid,
		  	   		m_tracker_root_sid) OR sid_id IN (
		  	   		SELECT column_value
		  	   		  FROM TABLE(v_superadmin_sos))
		  	   CONNECT BY PRIOR sid_id = parent_sid_id;
	END IF;

	SELECT sid_id
	  BULK COLLECT INTO m_known_sids
	  FROM (SELECT securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security_pkg.SID_ROOT, value) sid_id
	  	 	  FROM TABLE(m_known_sos));

	SELECT DISTINCT class_id
	  BULK COLLECT INTO v_class_ids
	  FROM security.securable_object
	 WHERE sid_id IN (
	 		SELECT column_value
	 		  FROM TABLE(m_sids));

	OPEN out_soc_cur FOR
		SELECT class_id, class_name, helper_pkg, helper_prog_id, parent_class_id
		  FROM security.securable_object_class
		 WHERE class_id IN (
		 		SELECT column_value
		 		  FROM TABLE(v_class_ids));

	OPEN out_att_cur FOR
		SELECT attribute_id, class_id, name, flags, external_pkg
		  FROM security.attributes
		 WHERE class_id IN (
		 		SELECT column_value
		 		  FROM TABLE(v_class_ids));

	OPEN out_pm_cur FOR
		SELECT parent_class_id, parent_permission, child_class_id, child_permission
		  FROM security.permission_mapping
		 WHERE parent_class_id IN (
		 		SELECT column_value
		 		  FROM TABLE(v_class_ids))
		   AND child_class_id IN (
		 		SELECT column_value
		 		  FROM TABLE(v_class_ids));

	OPEN out_pn_cur FOR
		SELECT class_id, permission, permission_name
		  FROM security.permission_name
		 WHERE class_id IN (
		 		SELECT column_value
		 		  FROM TABLE(v_class_ids));
END;

PROCEDURE GetSecurableObjects(
	out_so_cur						OUT SYS_REFCURSOR,
	out_soa_cur						OUT SYS_REFCURSOR,
	out_soka_cur					OUT SYS_REFCURSOR,
	out_acl_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security, only used by csrexp
	OPEN out_so_cur FOR
		SELECT sid_id,
			   -- return null for //aspen/applications -- we aren't exporting that
			   CASE
			       WHEN sid_id = SYS_CONTEXT('SECURITY', 'APP') THEN NULL
			       ELSE parent_sid_id
			   END parent_sid_id,
			   dacl_id, class_id, name, flags, owner, link_sid_id, application_sid_id
		  FROM security.securable_object
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));

	OPEN out_soa_cur FOR
		SELECT sid_id, attribute_id, string_value, number_value, date_value, blob_value, isobject, clob_value
		  FROM security.securable_object_attributes
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));

	OPEN out_soka_cur FOR
		SELECT sid_id, key_id, acl_id
		  FROM security.securable_object_keyed_acl
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));

	OPEN out_acl_cur FOR
		SELECT acl_id, acl_index, ace_type, ace_flags, sid_id, permission_set
		  FROM security.acl
		 WHERE acl_id IN (
		 		SELECT so.dacl_id
		 		  FROM security.securable_object so, TABLE(m_sids) s
		 		 WHERE so.sid_id = s.column_value);
END;

PROCEDURE GetSecurityAccountPolicies(
	out_pol_cur						OUT SYS_REFCURSOR,
	out_pol_pwdre_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security, only used by csrexp
	OPEN out_pol_cur FOR
		SELECT sid_id, max_logon_failures, expire_inactive, max_password_age,
			   remember_previous_passwords, remember_previous_days, single_session
		  FROM security.account_policy
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));

	OPEN out_pol_pwdre_cur FOR
		SELECT account_policy_sid, password_regexp_id
		  FROM security.acc_policy_pwd_regexp
		 WHERE account_policy_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));
END;

PROCEDURE GetSecurityGroups(
	out_group_cur					OUT	SYS_REFCURSOR,
	out_group_member_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security, only used by csrexp
	OPEN out_group_cur FOR
		SELECT sid_id, group_type
		  FROM security.group_table
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));

	OPEN out_group_member_cur FOR
		SELECT group_sid_id, member_sid_id
		  FROM security.group_members
		 WHERE group_sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));
END;

PROCEDURE GetSecurityUsers(
	out_user_cur					OUT	SYS_REFCURSOR,
	out_user_pass_hist_cur			OUT	SYS_REFCURSOR,
	out_user_cert_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security, only used by csrexp
	OPEN out_user_cur FOR
		SELECT sid_id, login_password, login_password_salt, account_enabled,
			   last_password_change, last_logon, last_but_one_logon, failed_logon_attempts,
			   expiration_dtm, language, culture, timezone, java_login_password, java_auth_enabled,
			   account_expiry_enabled, account_disabled_dtm
		  FROM security.user_table
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));

	OPEN out_user_pass_hist_cur FOR
		SELECT sid_id, serial, login_password, login_password_salt, retired_dtm
		  FROM security.user_password_history
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));

	OPEN out_user_cert_cur FOR
		SELECT sid_id, cert_hash, cert, website_name
		  FROM security.user_certificates
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));
END;

PROCEDURE GetSecurityWebInfo(
	out_app_cur						OUT SYS_REFCURSOR,
	out_website_cur					OUT	SYS_REFCURSOR,
	out_web_resource_cur			OUT	SYS_REFCURSOR,
	out_ip_rule_cur					OUT	SYS_REFCURSOR,
	out_ip_rule_entry_cur			OUT	SYS_REFCURSOR,
	out_home_page_cur				OUT SYS_REFCURSOR,
	out_menu_cur					OUT	SYS_REFCURSOR
)
AS
	v_ip_rule_ids					security.T_SID_TABLE;
BEGIN
	-- no security, only used by csrexp
	OPEN out_app_cur FOR
		SELECT application_sid_id, everyone_sid_id, language, culture, timezone
		  FROM security.application
		 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_website_cur FOR
		SELECT website_name, server_group, web_root_sid_id, denied_page, act_timeout,
			   cert_act_timeout, secure_only, http_only_cookies, xsrf_check_enabled,
			   application_sid_id, proxy_secure, ip_rule_id
		  FROM security.website
		 WHERE LOWER(website_name) = (
		 		SELECT LOWER(host)
		 		  FROM customer
		 		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'));

	OPEN out_web_resource_cur FOR
		SELECT web_root_sid_id, path, sid_id, ip_rule_id, rewrite_path
		  FROM security.web_resource
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));

	SELECT ip_rule_id
	  BULK COLLECT INTO v_ip_rule_ids
	  FROM (SELECT ip_rule_id
			  FROM security.website
			 WHERE LOWER(website_name) = (
			 		SELECT LOWER(host)
			 		  FROM customer
			 		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'))
			 UNION
			SELECT ip_rule_id
			  FROM security.web_resource
			 WHERE sid_id IN (
			 		SELECT column_value
			 		  FROM TABLE(m_sids)));

	OPEN out_ip_rule_cur FOR
		SELECT DISTINCT ip_rule_id
		  FROM security.web_resource
		 WHERE ip_rule_id IN (
		 		SELECT column_value
		 		  FROM TABLE(v_ip_rule_ids));

	OPEN out_ip_rule_entry_cur FOR
		SELECT ip_rule_id, ip_rule_index, ipv4_address, ipv4_bitmask, require_ssl, allow
		  FROM security.ip_rule_entry
		 WHERE ip_rule_id IN (
		 		SELECT column_value
		 		  FROM TABLE(v_ip_rule_ids));

	OPEN out_home_page_cur FOR
		SELECT sid_id, url, created_by_host, priority
		  FROM security.home_page
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));

	OPEN out_menu_cur FOR
		SELECT sid_id, description, action, pos, context
		  FROM security.menu
		 WHERE sid_id IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));
END;

PROCEDURE GetKnownSOs(
	out_so_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security, only used by csrexp
	IF m_known_sos IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetSecuritySchema first');
	END IF;

	OPEN out_so_cur FOR
		SELECT securableObject_pkg.getSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), security_pkg.SID_ROOT, value) sid_id,
			   value path
		  FROM TABLE(m_known_sos);
END;

PROCEDURE GetMailAccounts(
	out_account_cur					OUT	SYS_REFCURSOR,
	out_mailbox_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_account_cur FOR
		SELECT account_sid, email_address, root_mailbox_sid, inbox_sid,
			   password, password_salt, apop_secret, description
		  FROM mail.account
		 WHERE account_sid IN (m_system_account_sid, m_tracker_account_sid);

	OPEN out_mailbox_cur FOR
		SELECT mailbox_sid, parent_sid, link_to_mailbox_sid, mailbox_name,
			   last_message_uid, filter_duplicate_message_id
		  FROM mail.mailbox
		 	   START WITH mailbox_sid IN (m_system_root_sid, m_tracker_root_sid)
		 	   CONNECT BY PRIOR mailbox_sid = parent_sid;
END;

PROCEDURE GetMailMessages(
	out_mailbox_message_cur			OUT	SYS_REFCURSOR,
	out_message_cur					OUT	SYS_REFCURSOR,
	out_message_header_cur			OUT	SYS_REFCURSOR,
	out_message_address_field_cur	OUT	SYS_REFCURSOR,
	out_alert_cur					OUT	SYS_REFCURSOR,
	out_alert_bounce_cur			OUT	SYS_REFCURSOR
)
AS
	m_mailbox_sids					security.T_SID_TABLE;
BEGIN
	OPEN out_mailbox_message_cur FOR
		SELECT mailbox_sid, message_uid, message_id, flags, received_dtm, modseq
		  FROM mail.mailbox_message
		 WHERE mailbox_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids));

	OPEN out_message_cur FOR
		SELECT m.message_id, m.subject, m.message_dtm, m.message_id_hdr, m.in_reply_to,
			   m.priority, m.has_attachments, m.body, m.sha512
		  FROM mail.message m
		 WHERE m.message_id IN (
			SELECT message_id
			  FROM mail.mailbox_message
			 WHERE mailbox_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids)
		 	)
		 );

	OPEN out_message_header_cur FOR
		SELECT mh.message_id, mh.position, mh.name, mh.value
		  FROM mail.message_header mh
		 WHERE mh.message_id IN (
			SELECT message_id
			  FROM mail.mailbox_message
			 WHERE mailbox_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids)
		 	)
		 );

	OPEN out_message_address_field_cur FOR
		SELECT maf.message_id, maf.field_id, maf.position, maf.address, maf.name
		  FROM mail.message_address_field maf
		 WHERE maf.message_id IN (
			SELECT message_id
			  FROM mail.mailbox_message
			 WHERE mailbox_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_sids)
		 	)
		 );

	OPEN out_alert_cur FOR
		SELECT alert_id, to_user_sid, to_email_address, sent_dtm, subject, message
		  FROM alert;

	OPEN out_alert_bounce_cur FOR
		SELECT alert_bounce_id, alert_id, received_dtm, message
		  FROM alert_bounce;
END;

PROCEDURE GetCustomerFields(
	out_aspen2_app_cur				OUT	SYS_REFCURSOR,
    out_customer_cur				OUT	SYS_REFCURSOR,
    out_template_cur				OUT	SYS_REFCURSOR,
    out_trash_cur					OUT	SYS_REFCURSOR,
	out_customer_help_lang_cur		OUT SYS_REFCURSOR,
	out_scragpp_audit_log_cur		OUT SYS_REFCURSOR,
	out_scragpp_status_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_aspen2_app_cur FOR
		SELECT menu_path, metadata_connection_string, commerce_store_path, admin_email,
			   logon_url, referer_url, confirm_user_details, default_stylesheet, default_url,
			   default_css, edit_css, logon_autocomplete, monitor_with_new_relic, default_script, cdn_server,
			   branding_service_enabled, ul_design_system_enabled, ga4_enabled,
			   display_cookie_policy, mega_menu_enabled, maxmind_enabled
		  FROM aspen2.application
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_customer_cur FOR
		SELECT name, host, system_mail_address, tracker_mail_address,
			   alert_mail_address, alert_mail_name, alert_batch_run_time,
			   trash_sid, aggregation_engine_version, contact_email, editing_url, message,
			   ind_info_xml_fields, region_info_xml_fields, user_info_xml_fields,
			   raise_reminders, account_policy_sid, status, raise_split_deleg_alerts,
			   current_reporting_period_sid, lock_start_dtm, lock_end_dtm,
			   region_root_sid, ind_root_sid, reporting_ind_root_sid,
			   cascade_reject, approver_response_window,
			   self_reg_group_sid, self_reg_needs_approval, self_reg_approver_sid,
			   allow_partial_submit, helper_assembly, approval_step_sheet_url,
			   use_tracker, use_user_sheets, allow_val_edit, fully_hide_sheets,
			   calc_sum_zero_fill, equality_epsilon, create_sheets_at_period_end,
			   audit_calc_changes, oracle_schema, ind_cms_table, target_line_col_from_gradient,
			   use_carbon_emission, helper_pkg, chain_invite_landing_preable,
			   chain_invite_landing_qstn, allow_deleg_plan, supplier_region_root_sid,
			   trucost_company_id, trucost_portlet_tab_id, fogbugz_ixproject, fogbugz_sarea,
			   propagate_deleg_values_down, enable_save_chart_warning,
			   issue_editor_url, allow_make_editable, alert_uri_format, unmerged_consistent,
			   unmerged_scenario_run_sid, ind_selections_enabled, check_tolerance_against_zero,
			   scenarios_enabled, calc_job_priority, copy_vals_to_new_sheets, use_var_expl_groups,
			   merged_scenario_run_sid, bounce_tracking_enabled, issue_escalation_enabled,
			   check_divisibility, property_flow_sid, audit_helper_pkg, start_month, chart_xsl,
			   show_region_disposal_date, data_explorer_show_markers, show_all_sheets_for_rep_prd,
			   deleg_browser_show_rag, tgtdash_ignore_estimated, tgtdash_hide_totals,
			   tgtdash_show_chg_from_last_yr, tgtdash_show_last_year, tgtdash_colour_text,
			   tgtdash_show_target_first, tgtdash_show_flash, use_region_events, metering_enabled,
			   crc_metering_enabled, crc_metering_ind_core, crc_metering_auto_core,
			   iss_view_src_to_deepest_sheet, delegs_always_show_adv_opts, default_admin_css, max_dataview_history,
			   ntfy_days_before_user_inactive, data_explorer_show_ranking, data_explorer_show_trends, data_explorer_show_scatter,
			   data_explorer_show_radar, data_explorer_show_gauge, data_explorer_show_waterfall, multiple_audit_surveys,
			   include_nulls_in_ta, allow_multiperiod_forms, rstrct_multiprd_frm_edit_to_yr,
			   copy_forward_allow_na, audits_on_users, adj_factorset_startmonth, allow_custom_issue_types, allow_section_in_many_carts,
			   apply_factors_to_child_regions, calc_job_notify_address, calc_job_notify_after_attempts, chemical_flow_sid, default_country,
			   est_job_notify_address, est_job_notify_after_attempts, failed_calc_job_retry_delay, incl_inactive_regions,
			   legacy_period_formatting, live_metering_show_gaps, lock_prevents_editing, max_concurrent_calc_jobs,
			   metering_gaps_from_acquisition, restrict_issue_visibility, scrag_queue, status_from_parent_on_subdeleg,
			   tolerance_checker_req_merged, translation_checkbox, user_admin_helper_pkg, user_directory_type_id,
			   quick_survey_fixed_structure, remove_roles_on_account_expir, like_for_like_slots, show_aggregate_override,
			   allow_old_chart_engine, tear_off_deleg_header, show_map_on_audit_list, deleg_dropdown_threshold,
			   user_picker_extra_fields, forecasting_slots, divisibility_bug, rest_api_guest_access, question_library_enabled, calc_sum_to_dt_cust_yr_start,
			   calc_start_dtm, calc_end_dtm, show_additional_audit_info, lazy_load_role_membership, calc_future_window,
			   require_sa_login_reason, site_type, allow_cc_on_alerts, chart_algorithm_version, marked_for_zap, zap_after_dtm,
			   batch_jobs_disabled, calc_jobs_disabled, scheduled_tasks_disabled, alerts_disabled, prevent_logon,
			   mobile_branding_enabled, enable_java_auth, render_charts_as_svg, show_data_approve_confirm,
			   AUTO_ANONYMISATION_ENABLED, INACTIVE_DAYS_BEFORE_ANONYMISATION
		  FROM customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_template_cur FOR
		SELECT template_type_id, data, mime_type, uploaded_dtm, uploaded_by_sid
		  FROM template;

	OPEN out_trash_cur FOR
		SELECT trash_sid, trash_can_sid, trashed_by_sid, trashed_dtm, previous_parent_sid,
			   description, so_name
		  FROM trash
		 WHERE m_export_everything = 1;

	OPEN out_customer_help_lang_cur FOR
		SELECT help_lang_id,
			   is_default
		  FROM customer_help_lang;

	OPEN out_scragpp_audit_log_cur FOR
		SELECT action, action_dtm, user_sid
		  FROM scragpp_audit_log;

	OPEN out_scragpp_status_cur FOR
		SELECT old_scrag, testcube_enabled, validation_approved_ref, scragpp_enabled
		  FROM scragpp_status;

END;

PROCEDURE GetPeriodSets(
	out_period_set_cur				OUT	SYS_REFCURSOR,
	out_period_cur					OUT	SYS_REFCURSOR,
	out_period_dates_cur			OUT	SYS_REFCURSOR,
	out_period_interval_cur			OUT	SYS_REFCURSOR,
	out_period_interval_mem_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_period_set_cur FOR
		SELECT period_set_id, annual_periods, label
		  FROM period_set
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_period_cur FOR
		SELECT period_set_id, period_id, label, start_dtm, end_dtm
		  FROM period
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_period_dates_cur FOR
		SELECT period_set_id, period_id, year, start_dtm, end_dtm
		  FROM period_dates
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_period_interval_cur FOR
		SELECT period_set_id, period_interval_id, single_interval_label,
			   multiple_interval_label, label, single_interval_no_year_label
		  FROM period_interval
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_period_interval_mem_cur FOR
		SELECT period_set_id, period_interval_id, start_period_id, end_period_id
		  FROM period_interval_member
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetLookupTables(
	out_lookup_table_cur			OUT SYS_REFCURSOR,
	out_lookup_table_entry_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_lookup_table_cur FOR
		SELECT lookup_id, lookup_name
		  FROM lookup_table
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_lookup_table_entry_cur FOR
		SELECT lookup_id, start_dtm, val
		  FROM lookup_table_entry
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetReportingPeriods(
    out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT DISTINCT reporting_period_sid, name, start_dtm, end_dtm
          FROM reporting_period
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetRagStatuses(
    out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
		SELECT rag_status_id, colour, label, lookup_key
		  FROM rag_status
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAccuracyTypes(
    out_accuracy_type_cur			OUT	SYS_REFCURSOR,
    out_accuracy_type_opt_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_accuracy_type_cur FOR
        SELECT accuracy_type_id, label, q_or_c, max_score
          FROM accuracy_type
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

    OPEN out_accuracy_type_opt_cur FOR
		SELECT accuracy_type_option_id, ato.accuracy_type_id, ato.label, accuracy_weighting
		  FROM accuracy_type_option ato, accuracy_type aty
		 WHERE ato.accuracy_type_id = aty.accuracy_type_Id
		   AND aty.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetTranslations(
	out_app_cur						OUT	SYS_REFCURSOR,
	out_set_cur						OUT	SYS_REFCURSOR,
	out_set_incl_cur				OUT	SYS_REFCURSOR,
	out_translation_cur				OUT	SYS_REFCURSOR,
	out_translated_cur				OUT	SYS_REFCURSOR
)
AS
	v_app_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_current_host		VARCHAR2(2000);
BEGIN
	SELECT host
	  INTO v_current_host
	  FROM csr.customer
	 WHERE app_sid = v_app_sid;

	security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
	user_pkg.logonadmin();

	OPEN out_app_cur FOR
		SELECT base_lang, static_translation_path
		  FROM aspen2.translation_application
		 WHERE application_sid = v_app_sid;

	OPEN out_set_cur FOR
		SELECT lang, revision, hidden
		  FROM aspen2.translation_set
		 WHERE application_sid = v_app_sid;


	-- build map of cross site apps
	DELETE FROM translation_set_include_path
	 WHERE application_sid_id = v_app_sid;

	INSERT INTO translation_set_include_path (application_sid_id, app_path_sid_id, app_path)
		SELECT DISTINCT v_app_sid application_sid_id, to_application_sid app_path_sid_id, securableObject_pkg.GetPathFromSid_(to_application_sid) app_path
		  FROM aspen2.translation_set_include
		 WHERE application_sid = v_app_sid
		   AND to_application_sid != v_app_sid;


	OPEN out_set_incl_cur FOR
		SELECT lang, pos,
			   CASE
			   	WHEN to_application_sid = application_sid THEN NULL
			   	ELSE (SELECT app_path from translation_set_include_path WHERE application_sid_id = v_app_sid AND app_path_sid_id = to_application_sid)
			   END to_application, to_lang
		  FROM aspen2.translation_set_include
		 WHERE application_sid = v_app_sid;

	OPEN out_translation_cur FOR
		SELECT original_hash, original
		  FROM aspen2.translation
		 WHERE application_sid = v_app_sid;

	OPEN out_translated_cur FOR
		SELECT lang, original_hash, translated, translated_id
		  FROM aspen2.translated
		 WHERE application_sid = v_app_sid;

	user_pkg.logonadmin(v_current_host);
END;

PROCEDURE GetCustomerAlertTypes(
	out_cat_cur						OUT	SYS_REFCURSOR,
	out_cat_param_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cat_cur FOR
		SELECT customer_alert_type_id, std_alert_type_id
		  FROM customer_alert_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_cat_param_cur FOR
		SELECT customer_alert_type_id, field_name, description,
			   help_text, repeats, display_pos
		  FROM customer_alert_type_param;
END;

PROCEDURE GetAlerts(
	out_alert_frame_cur				OUT	SYS_REFCURSOR,
	out_alert_frame_body_cur		OUT	SYS_REFCURSOR,
	out_alert_tpl_cur				OUT	SYS_REFCURSOR,
	out_alert_tpl_body_cur			OUT	SYS_REFCURSOR,
	out_cms_tab_alert_type_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_alert_frame_cur FOR
		SELECT alert_frame_id, name
		  FROM alert_frame
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_alert_frame_body_cur FOR
		SELECT alert_frame_id, lang, html
		  FROM alert_frame_body
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_alert_tpl_cur FOR
		SELECT customer_alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email, from_email, from_name
		  FROM alert_template
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_alert_tpl_body_cur FOR
		SELECT customer_alert_type_id, lang, subject, body_html, item_html
		  FROM alert_template_body
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_cms_tab_alert_type_cur FOR
		SELECT tab_sid, has_repeats, customer_alert_type_id, filter_xml
		  FROM cms_tab_alert_type;
END;

PROCEDURE GetRoles(
	out_cur							OUT	SYS_REFCURSOR,
	out_grants						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT role_sid, name, lookup_Key, region_permission_set, is_metering, is_property_manager,
			is_delegation, is_supplier, is_hidden, is_system_managed
		  FROM role
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_grants FOR
		SELECT role_sid, grant_role_sid
		  FROM role_grant
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetTags(
	out_tag_cur						OUT	SYS_REFCURSOR,
	out_tag_description_cur			OUT	SYS_REFCURSOR,
	out_tag_group_cur				OUT	SYS_REFCURSOR,
	out_tag_group_description_cur	OUT	SYS_REFCURSOR,
	out_tag_group_member_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_tag_cur FOR
		SELECT t.tag_id, t.lookup_key, t.exclude_from_dataview_grouping, parent_id
		  FROM tag t
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_tag_description_cur FOR
		SELECT td.tag_id, td.lang, td.tag, td.explanation, td.last_changed_dtm
		  FROM tag_description td
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_tag_group_cur FOR
		SELECT tag_group_id, multi_select, mandatory, applies_to_inds, applies_to_regions,
			   applies_to_non_compliances, applies_to_suppliers, applies_to_initiatives, applies_to_chain,
			   applies_to_chain_activities, applies_to_chain_product_types, applies_to_quick_survey,
			   applies_to_audits, applies_to_compliances, lookup_key,
			   applies_to_chain_products, applies_to_chain_product_supps, is_hierarchical
		  FROM tag_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_tag_group_description_cur FOR
		SELECT tgd.tag_group_id, tgd.lang, tgd.name, tgd.last_changed_dtm
		  FROM tag_group_description tgd
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_tag_group_member_cur FOR
		SELECT tgm.tag_group_id, tgm.tag_id, tgm.pos, tgm.active
		  FROM tag_group_member tgm
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetMeasures(
	out_measure_cur					OUT	SYS_REFCURSOR,
	out_measure_conv_cur			OUT	SYS_REFCURSOR,
	out_measure_conv_period_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_measure_cur FOR
		SELECT measure_sid, name, description, scale, format_mask, regional_aggregation, custom_field,
			   option_set_id, pct_ownership_applies, std_measure_conversion_id, factor,
			   m, kg, s, a, k, mol, cd, divisibility, lookup_key
		  FROM measure;

	OPEN out_measure_conv_cur FOR
		SELECT mc.measure_conversion_id, mc.measure_sid, mc.description, mc.a, mc.b, mc.c, mc.lookup_key
		  FROM measure_conversion mc, measure m
		 WHERE mc.measure_sid = m.measure_sid;

	OPEN out_measure_conv_period_cur FOR
		SELECT mcp.measure_conversion_id, mcp.start_dtm, mcp.end_dtm, mcp.a, mcp.b, mcp.c
 		  FROM measure_conversion_period mcp, measure_conversion mc, measure m
 		 WHERE mcp.measure_conversioN_id = mc.measure_conversion_id
  		   AND mc.measure_sid = m.measure_sid
  		   AND m.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

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
)
AS
BEGIN
	-- store all our indicator sids for use in other queries
	IF m_export_everything = 1 THEN
		SELECT ind_sid
	      BULK COLLECT INTO m_ind_sids
		  FROM ind;
	ELSE
		SELECT ind_sid
		       BULK COLLECT INTO m_ind_sids
		  FROM ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND parent_sid = app_sid
		 	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid;
	END IF;

	OPEN out_ind_cur FOR
		SELECT i.ind_sid, i.parent_sid, i.name, i.ind_type, 
			   i.tolerance_type, i.pct_upper_tolerance, i.pct_lower_tolerance,
			   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
			   i.measure_sid, i.multiplier, i.scale, i.format_mask,
			   i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml.extract('/').getStringVal() info_xml,
			   i.start_month, NVL(i.divisibility, m.divisibility) divisibility, i.null_means_null,
			   i.aggregate, i.period_set_id, i.period_interval_id,
			   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment,
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm,
			   i.calc_xml, i.gri, i.lookup_key, i.owner_sid, i.ind_activity_type_id,
			   i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid, i.gas_measure_sid,
			   i.gas_type_id, i.calc_description, i.normalize, i.do_temporal_aggregation,
			   i.prop_down_region_tree_sid, i.is_system_managed, i.calc_output_round_dp
		  FROM ind i
		  JOIN TABLE(m_ind_sids) pi ON i.ind_sid = pi.column_value
		  LEFT JOIN measure m ON i.measure_sid = m.measure_sid
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_ind_description_cur FOR
		SELECT id.ind_sid, id.lang, id.description, id.last_changed_dtm
		  FROM ind_description id, TABLE(m_ind_sids) pi
		 WHERE id.ind_sid = pi.column_value;

	OPEN out_ind_flag_cur FOR
		SELECT ind_sid, flag, description, requires_note
		  FROM ind_flag;

	OPEN out_calc_dependency_cur FOR
		SELECT calc_ind_sid, ind_sid, dep_type
		  FROM calc_dependency;

	OPEN out_ind_tag_cur FOR
   		SELECT it.tag_id, it.ind_sid
		  FROM ind_tag it, tag t, tag_group_member tgm, tag_group tg, TABLE(m_ind_sids) i
		 WHERE it.tag_id = t.tag_id
		   AND t.tag_id = tgm.tag_id
		   AND tgm.tag_group_id = tg.tag_group_id
		   AND it.ind_sid = i.column_value
		   AND tg.app_sid = SYS_CONTEXT('SECURITY', 'APP');

    OPEN out_ind_accuracy_cur FOR
        SELECT ind_sid, accuracy_type_id
          FROM ind_accuracy_type
         WHERE ind_sid IN (
            SELECT column_value
              FROM TABLE(m_ind_sids));

	OPEN out_validation_rule_cur FOR
		SELECT ind_validation_rule_id, ind_sid, expr, message, position, type
		  FROM ind_validation_rule, TABLE(m_ind_sids) i
		 WHERE ind_sid = i.column_value;

	OPEN out_calc_tag_dep_cur FOR
		SELECT calc_ind_sid, tag_id
		  FROM calc_tag_dependency;

	OPEN out_aggr_ind_group_cur FOR
		SELECT aggregate_ind_group_id, helper_proc, helper_proc_args, name, js_include,
			   run_daily, label, source_url, run_for_current_month, lookup_key, data_bucket_sid, data_bucket_fetch_sp
		  FROM aggregate_ind_group;

	OPEN out_aggr_ind_group_member_cur FOR
		SELECT aggregate_ind_group_id, ind_sid
		  FROM aggregate_ind_group_member;

	OPEN out_aggr_ind_group_log_cur FOR
		SELECT aggregate_ind_group_id, change_dtm, change_description, changed_by_user_sid
		  FROM aggregate_ind_group_audit_log;

	OPEN out_aivd_cur FOR
		SELECT aggregate_ind_group_id,
			   description,
			   dtm,
			   ind_sid,
			   link_url,
			   period_end_dtm,
			   period_start_dtm,
			   region_sid,
			   src_id
		  FROM aggregate_ind_val_detail;

	OPEN out_ind_window_cur FOR
		SELECT ind_sid,
			   period,
			   comparison_offset,
			   lower_bracket,
			   upper_bracket
		  FROM ind_window;

	OPEN out_calc_baseline_dep_cur FOR
		SELECT calc_ind_sid, baseline_config_id
		  FROM calc_baseline_config_dependency;
END;

PROCEDURE GetIndSelections(
	out_ind_sel_group_cur			OUT	SYS_REFCURSOR,
	out_ind_sel_group_mem_cur		OUT	SYS_REFCURSOR,
	out_ind_sel_grp_mem_dsc_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_ind_sel_group_cur FOR
		SELECT master_ind_sid
		  FROM ind_selection_group
		 WHERE master_ind_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_ind_sids));

	OPEN out_ind_sel_group_mem_cur FOR
		SELECT master_ind_sid, ind_sid, pos
		  FROM ind_selection_group_member
		 WHERE master_ind_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_ind_sids))
		    OR ind_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_ind_sids));

	OPEN out_ind_sel_grp_mem_dsc_cur FOR
		SELECT ind_sid, lang, description
		  FROM ind_sel_group_member_desc
		 WHERE ind_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_ind_sids));
END;

PROCEDURE GetFactors(
	out_factor_cur					OUT	SYS_REFCURSOR,
	out_factor_history_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_factor_cur FOR
		 SELECT factor_id, factor_type_id, gas_type_id, region_sid, geo_country, geo_region, egrid_ref,
				is_selected, start_dtm, end_dtm, value, note, std_measure_conversion_id, std_factor_id,
				original_factor_id, custom_factor_id, profile_id, is_virtual
		   FROM factor
		  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_factor_history_cur FOR
		SELECT factor_id, changed_dtm, user_sid, old_value, note
		  FROM factor_history;
END;

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
)
AS
BEGIN
	OPEN out_model_cur FOR
		SELECT model_sid, revision, name, description, excel_doc,
			   file_name, thumb_img, created_dtm, temp_only_boo,
			   load_state, scenario_run_type, scenario_run_sid, lookup_key
		  FROM model;

	OPEN out_model_instance_cur FOR
		SELECT model_instance_sid, base_model_sid, start_dtm, end_dtm, owner_sid,
			   created_dtm, excel_doc, description, run_state
		  FROM model_instance;

	OPEN out_model_instance_chart_cur FOR
		SELECT model_instance_sid, base_model_sid, sheet_id, chart_index,
			   top, left, width, height, source_data
		  FROM model_instance_chart;

	OPEN out_model_instance_map_cur FOR
		SELECT model_instance_sid, base_model_sid, sheet_id, cell_name,
			   source_cell_name, cell_value, map_to_indicator_sid,
			   map_to_region_sid, period_year_offset, period_offset
		  FROM model_instance_map;

	OPEN out_model_instance_region_cur FOR
		SELECT model_instance_sid, base_model_sid, region_sid, pos
		  FROM model_instance_region;

	OPEN out_model_instance_sheet_cur FOR
		SELECT model_instance_sid, base_model_sid, sheet_id, structure
		  FROM model_instance_sheet;

	OPEN out_model_map_cur FOR
		SELECT model_sid, sheet_id, model_map_type_id, map_to_indicator_sid,
			   cell_comment, cell_name, is_temp, region_type_offset,
			   region_offset_tag_id, period_year_offset, period_offset
		  FROM model_map;

	OPEN out_model_range_cur FOR
		SELECT model_sid, range_id, sheet_id
		  FROM model_range;

	OPEN out_model_range_cell_cur FOR
		SELECT model_sid, range_id, cell_name
		  FROM model_range_cell;

	OPEN out_region_range_cur FOR
		SELECT model_sid, range_id, region_repeat_id
		  FROM model_region_range;

	OPEN out_model_sheet_cur FOR
		SELECT model_sid, sheet_name, user_editable_boo, sheet_index,
			   display_charts_boo, chart_count, sheet_id, structure
		  FROM model_sheet;

	OPEN out_model_validation_cur FOR
		SELECT model_sid, cell_name, display_seq, validation_text, sheet_id
		  FROM model_validation;
END;

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
)
AS
	v_dp_region_sid		security_pkg.T_SID_ID;
BEGIN
	OPEN out_region_tree_cur FOR
		SELECT region_tree_root_sid, is_primary, is_divisions, is_fund, last_recalc_dtm
		  FROM region_tree
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_region_type_cur FOR
		SELECT region_type
		  FROM customer_region_type;

	OPEN out_region_type_tag_cur FOR
		SELECT region_type, tag_group_id
		  FROM region_type_tag_group;

	-- make sure we always include the weird DelegPlansRegion
	v_dp_region_sid	:= security.securableobject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'),
		SYS_CONTEXT('SECURITY', 'APP'), 'DelegationPlans/DelegPlansRegion');

	IF m_export_everything = 1 THEN
		SELECT region_sid
		  BULK COLLECT INTO m_region_sids
		  FROM region;
	ELSE
		SELECT region_sid
		  BULK COLLECT INTO m_region_sids
		  FROM (SELECT region_sid
				  FROM region
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   START WITH parent_sid = app_sid
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
				 UNION ALL
				SELECT v_dp_region_sid FROM DUAL);
	END IF;

	OPEN out_region_cur FOR
		SELECT r.region_sid, r.link_to_region_sid, r.parent_sid, r.name, r.active,
			   r.pos, r.info_xml.extract('/').getStringVal() info_xml, r.flag, r.acquisition_dtm, r.disposal_dtm,
			   r.region_type, r.lookup_key, r.geo_country, r.geo_region, r.geo_city_id,
			   r.geo_longitude, r.geo_latitude, r.geo_type, r.map_entity, r.egrid_ref,
			   r.egrid_ref_overridden, r.region_ref, r.last_modified_dtm
		  FROM region r, TABLE(m_region_sids) x
		 WHERE r.region_sid = x.column_value;

	OPEN out_region_description_cur FOR
		SELECT rd.region_sid, rd.lang, rd.description, rd.last_changed_dtm
		  FROM region_description rd, TABLE(m_region_sids) x
		 WHERE rd.region_sid = x.column_value;

	OPEN out_region_tag_cur FOR
		SELECT rt.tag_id, rt.region_sid
		  FROM region_tag rt, tag t, tag_group_member tgm, tag_group tg, TABLE(m_region_sids) r
		 WHERE rt.tag_id = t.tag_id
		   AND t.tag_id = tgm.tag_id
		   AND tgm.tag_group_id = tg.tag_group_id
		   AND rt.region_sid = r.column_value
		   AND tg.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_pct_ownership_cur FOR
		SELECT po.region_sid, po.start_dtm, po.end_dtm, po.pct
		  FROM pct_ownership po, TABLE(m_region_sids) r
		 WHERE po.region_sid = r.column_value;

	OPEN out_region_owner_cur FOR
		SELECT region_sid, user_sid
		  FROM region_owner;

	OPEN out_mgt_tree_sync_job_cur FOR
		SELECT tree_root_sid
		  FROM mgt_company_tree_sync_job;
END;

PROCEDURE GetRegionEventsAndDocs(
	out_event_cur					OUT	SYS_REFCURSOR,
	out_region_event_cur			OUT	SYS_REFCURSOR,
	out_region_proc_doc_cur			OUT	SYS_REFCURSOR,
	out_region_proc_file_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_event_cur FOR
		SELECT event_id, label, raised_by_user_sid, raised_dtm, event_text,
			   raised_for_region_sid, event_dtm
		  FROM event
		 WHERE raised_for_region_sid IN (
				SELECT column_value
				  FROM TABLE(m_region_sids));

	OPEN out_region_event_cur FOR
		SELECT region_sid, event_id
		  FROM region_event;

	OPEN out_region_proc_doc_cur FOR
		SELECT region_sid, doc_id, inherited
		  FROM region_proc_doc;

	OPEN out_region_proc_file_cur FOR
		SELECT region_sid, meter_document_id, inherited
		  FROM region_proc_file;
END;

PROCEDURE GetRegionSets(
	out_region_set_cur				OUT	SYS_REFCURSOR,
	out_region_set_region_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_region_set_cur FOR
		SELECT region_set_id, owner_sid, name, disposal_dtm
		  FROM region_set;

	OPEN out_region_set_region_cur FOR
		SELECT region_set_id, region_sid, pos
		  FROM region_set_region;
END;

PROCEDURE GetIndSets(
	out_ind_set_cur					OUT SYS_REFCURSOR,
	out_ind_set_ind_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_ind_set_cur FOR
		SELECT ind_set_id,
			   disposal_dtm,
			   name,
			   owner_sid
		  FROM ind_set;

	OPEN out_ind_set_ind_cur FOR
		SELECT ind_set_id,
			   ind_sid,
			   pos
		  FROM ind_set_ind;
END;

PROCEDURE GetUsers(
	out_csr_user_cur				OUT	SYS_REFCURSOR,
	out_user_measure_conv_cur		OUT	SYS_REFCURSOR,
	out_autocreate_user_cur			OUT	SYS_REFCURSOR,
	out_cookie_pol_consent_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	SELECT csr_user_sid
	  BULK COLLECT INTO m_user_sids
	  FROM csr_user
     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_csr_user_cur FOR
		SELECT cu.csr_user_sid, cu.email, cu.guid,
			   cu.full_name, cu.user_name, cu.friendly_name, cu.info_xml,
			   cu.send_alerts, cu.show_portal_help,
			   cu.donations_reports_filter_id, cu.donations_browse_filter_id,
			   cu.hidden, cu.phone_number, cu.job_title,
			   cu.show_save_chart_warning, cu.enable_aria, cu.created_dtm,
			   cu.line_manager_sid, cu.primary_region_sid,
			   remove_roles_on_deactivation, user_ref,
			   avatar, last_modified_dtm, last_logon_type_id, avatar_sha1,
			   avatar_mime_type, avatar_last_modified_dtm, anonymised
		  FROM csr_user cu
		 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_user_measure_conv_cur FOR
		SELECT csr_user_sid, measure_sid, measure_conversion_id
		  FROM user_measure_conversion;

	OPEN out_autocreate_user_cur FOR
		SELECT guid, requested_dtm, user_name, approved_dtm, approved_by_user_sid,
			   created_user_sid, activated_dtm, rejected_dtm,
			   require_new_password, redirect_to_url
		  FROM autocreate_user;

	OPEN out_cookie_pol_consent_cur	FOR
		SELECT cookie_policy_consent_id, csr_user_sid, created_dtm, accepted
		  FROM cookie_policy_consent;
END;

PROCEDURE GetStartPoints(
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF m_user_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetUsers first');
	END IF;

	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;

	IF m_region_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetRegions first');
	END IF;

	OPEN out_ind_cur FOR
		SELECT isp.ind_sid, isp.user_sid
		  FROM TABLE(m_ind_sids) i, TABLE(m_user_sids) cu, ind_start_point isp
		 WHERE isp.ind_sid = i.column_value
		   AND isp.user_sid = cu.column_value;

	OPEN out_region_cur FOR
		SELECT rsp.region_sid, rsp.user_sid
		  FROM TABLE(m_region_sids) i, TABLE(m_user_sids) cu, region_start_point rsp
		 WHERE rsp.region_sid = i.column_value
		   AND rsp.user_sid = cu.column_value;
END;

PROCEDURE GetRegionRoleMembers(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT region_sid, role_sid, user_sid, inherited_from_sid
		  FROM region_role_member rrm, TABLE(m_region_sids) r
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rrm.region_sid = r.column_value;
END;

PROCEDURE GetPending(
	out_dataset_cur					OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_period_cur					OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_ind_accuracy_type_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF m_region_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetRegions first');
	END IF;
	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;

    OPEN out_dataset_cur FOR
        SELECT pending_dataset_id, label, reporting_period_sid
          FROM pending_dataset
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_region_cur FOR
       SELECT pr.pending_region_id, pr.parent_region_id, pr.pending_dataset_id,
 			  CASE WHEN r.column_value IS NULL THEN NULL ELSE pr.maps_to_region_sid END maps_to_region_sid,
			  pr.description, pr.pos
         FROM pending_region pr, TABLE(m_region_sids) r
        WHERE pr.maps_to_region_sid = r.column_value(+);

	OPEN out_period_cur FOR
        SELECT pending_period_id, pending_dataset_id, start_dtm, end_dtm, label, default_due_dtm
          FROM pending_period
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

    OPEN out_ind_cur FOR
		SELECT pi.pending_ind_id, pi.pending_dataset_id,
			   CASE WHEN i.column_value IS NULL THEN NULL ELSE pi.maps_to_ind_sid END maps_to_ind_sid,
			   pi.description, pi.val_mandatory, pi.note_mandatory, pi.file_upload_mandatory,
			   pi.measure_sid, pi.parent_ind_id, pi.pos, pi.element_type, pi.tolerance_type,
			   pi.pct_upper_tolerance, pi.pct_lower_tolerance, pi.format_xml, pi.link_to_ind_id, pi.read_only,
			   pi.info_xml, pi.dp, pi.default_val_number, pi.default_val_string, pi.lookup_key,
			   pi.allow_file_upload, pi.aggregate
          FROM pending_ind pi, TABLE(m_ind_sids) i
         WHERE pi.maps_to_ind_sid = i.column_value(+);

    OPEN out_ind_accuracy_type_cur FOR
        SELECT pending_ind_id, accuracy_type_id
          FROM pending_ind_accuracy_type
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE PickAllDelegations
AS
BEGIN
	IF m_export_everything = 1 THEN
		SELECT delegation_sid
		  BULK COLLECT INTO m_deleg_sids
		  FROM delegation;
	ELSE
		SELECT delegation_sid
		  BULK COLLECT INTO m_deleg_sids
		  FROM delegation
			   START WITH parent_sid = SYS_CONTEXT('SECURITY', 'APP')
			   CONNECT BY PRIOR delegation_sid = parent_sid;
	END IF;
END;

PROCEDURE PickPlanDelegations
AS
BEGIN
	SELECT delegation_sid
	  BULK COLLECT INTO m_deleg_sids
	  FROM master_deleg;
END;

PROCEDURE GetPostits(
	out_postit_cur					OUT	SYS_REFCURSOR,
	out_postit_file_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_postit_cur FOR
		SELECT postit_id, label, message, created_dtm, created_by_sid, secured_via_sid
		  FROM postit;

	OPEN out_postit_file_cur FOR
		SELECT postit_file_id, postit_id, filename, mime_type, data,
			   sha1, uploaded_dtm
		  FROM postit_file pf;
END;

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
	out_sheet_date_schedule_cur		OUT	SYS_REFCURSOR,
	out_delegation_layout_cur		OUT SYS_REFCURSOR,
    out_delegation_policy_cur       OUT SYS_REFCURSOR
)
AS
BEGIN
	IF m_deleg_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call PickPlanDelegations or PickAllDelegations first');
	END IF;
	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;
	IF m_region_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetRegions first');
	END IF;
	IF m_user_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetUsers first');
	END IF;

	OPEN out_deleg_cur FOR
		SELECT delegation_sid, parent_sid, name, master_delegation_sid,
			   created_by_sid, schedule_xml, note, period_set_id, period_interval_id,
			   group_by, allocate_users_to, start_dtm, end_dtm, reminder_offset,
			   is_note_mandatory, section_xml, editing_url, fully_delegated,
			   grid_xml, is_flag_mandatory, show_aggregate, hide_sheet_period,
			   delegation_date_schedule_id, submission_offset, layout_id,
			   tag_visibility_matrix_group_id, allow_multi_period
		  FROM delegation
 		 WHERE delegation_sid IN (
			SELECT column_value FROM TABLE(m_deleg_sids)
		 );

	OPEN out_deleg_desc_cur FOR
       	SELECT dd.delegation_sid, dd.lang, dd.description, dd.last_changed_dtm
	 	  FROM delegation_description dd, TABLE(m_deleg_sids) d
         WHERE dd.delegation_sid = d.column_value;

	OPEN out_ind_cur FOR
       	SELECT di.delegation_sid, di.ind_sid, di.mandatory, di.pos, di.section_key, di.visibility, di.var_expl_group_id, di.css_class, di.meta_role, di.allowed_na
	 	  FROM delegation_ind di, TABLE(m_ind_sids) i, TABLE(m_deleg_sids) d
         WHERE di.ind_sid = i.column_value
           AND di.delegation_sid = d.column_value;

	OPEN out_ind_desc_cur FOR
       	SELECT did.delegation_sid, did.ind_sid, did.lang, did.description
	 	  FROM delegation_ind_description did, TABLE(m_ind_sids) i, TABLE(m_deleg_sids) d
         WHERE did.ind_sid = i.column_value
           AND did.delegation_sid = d.column_value;

	OPEN out_region_cur FOR
       	SELECT dr.delegation_sid, dr.region_sid, dr.mandatory, dr.pos, dr.aggregate_to_region_sid,
       		   dr.visibility, dr.allowed_na, dr.hide_after_dtm, dr.hide_inclusive
	 	  FROM delegation_region dr, TABLE(m_region_sids) r, TABLE(m_region_sids) rag, TABLE(m_deleg_sids) d
         WHERE dr.region_sid = r.column_value
           AND dr.aggregate_to_region_sid = rag.column_value
           AND dr.delegation_sid = d.column_value;

	OPEN out_region_desc_cur FOR
       	SELECT drd.delegation_sid, drd.region_sid, drd.lang, drd.description
	 	  FROM delegation_region_description drd, TABLE(m_region_sids) r, TABLE(m_deleg_sids) d
         WHERE drd.region_sid = r.column_value
           AND drd.delegation_sid = d.column_value;

	OPEN out_user_cur FOR
	 	 SELECT delegation_sid, user_sid, inherited_from_sid, deleg_permission_set
	 	   FROM delegation_user, TABLE(m_user_sids) cu, TABLE(m_deleg_sids) d
          WHERE user_sid = cu.column_value
          	AND delegation_sid = d.column_value;

	OPEN out_deleg_plugin_cur FOR
		SELECT ind_sid, name, js_class_type, js_include, helper_pkg
		  FROM delegation_plugin;

	OPEN out_deleg_meta_role_is_cur FOR
		SELECT delegation_sid, ind_sid, lang, description
		  FROM deleg_meta_role_ind_selection
		 WHERE delegation_sid IN (
			SELECT column_value FROM TABLE(m_deleg_sids)
		);

	OPEN out_deleg_comment_cur FOR
		SELECT delegation_sid, start_dtm, end_dtm, postit_id
		  FROM delegation_comment
		 WHERE delegation_sid IN (
			SELECT column_value FROM TABLE(m_deleg_sids)
		);

	OPEN out_deleg_tag_cur FOR
		SELECT delegation_sid, tag_id
		  FROM delegation_tag
		 WHERE delegation_sid IN (
			SELECT column_value FROM TABLE(m_deleg_sids)
		);

	OPEN out_user_cover_cur FOR
		SELECT user_cover_id, user_giving_cover_sid, user_being_covered_sid,
			   start_dtm, end_dtm, cover_terminated, alert_sent_dtm
		  FROM user_cover;

	OPEN out_deleg_user_cover_cur FOR
		SELECT user_cover_id, user_giving_cover_sid, user_being_covered_sid,
			   delegation_sid
		  FROM delegation_user_cover
		 WHERE delegation_sid IN (
			SELECT column_value FROM TABLE(m_deleg_sids)
		);

	OPEN out_audit_user_cover_cur FOR
		SELECT user_cover_id, user_giving_cover_sid, user_being_covered_sid,
			   internal_audit_sid
		  FROM audit_user_cover;

	OPEN out_issue_user_cover_cur FOR
		SELECT user_cover_id, user_giving_cover_sid, user_being_covered_sid,
			   issue_id
		  FROM issue_user_cover;

	OPEN out_role_user_cover_cur FOR
		SELECT user_cover_id, user_giving_cover_sid, user_being_covered_sid,
			   role_sid, region_sid
		  FROM role_user_cover;

	OPEN out_group_user_cover_cur FOR
		SELECT user_cover_id, user_giving_cover_sid, user_being_covered_sid,
			   group_sid
		  FROM group_user_cover;

	OPEN out_flow_inv_cover_cur FOR
		SELECT user_cover_id, user_giving_cover_sid, user_being_covered_sid,
			   flow_item_id, flow_involvement_type_id
		  FROM flow_involvement_cover;

	OPEN out_deleg_date_schedule_cur FOR
		SELECT delegation_date_schedule_id, start_dtm, end_dtm
		  FROM delegation_date_schedule;

	OPEN out_sheet_date_schedule_cur FOR
		SELECT delegation_date_schedule_id, start_dtm, creation_dtm, submission_dtm, reminder_dtm
		  FROM sheet_date_schedule;

	OPEN out_delegation_layout_cur FOR
		SELECT layout_id, layout_xhtml, name, valid
		  FROM delegation_layout;

    OPEN out_delegation_policy_cur FOR
        SELECT delegation_sid, submit_confirmation_text
          FROM delegation_policy
		 WHERE delegation_sid IN (
			SELECT column_value FROM TABLE(m_deleg_sids)
		);
END;

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
)
AS
BEGIN
	IF m_deleg_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call PickPlanDelegations or PickAllDelegations first');
	END IF;

	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;

	OPEN out_role_cur FOR
		SELECT delegation_sid, role_sid, is_read_only, deleg_permission_set, inherited_from_sid
		  FROM delegation_role, TABLE(m_deleg_sids) d
		 WHERE delegation_sid = d.column_value;

	OPEN out_grid_cur FOR
		SELECT path, form_sid, ind_sid, helper_pkg, name, aggregation_xml, variance_validation_sp
		  FROM delegation_grid, TABLE(m_ind_sids) d
		 WHERE ind_sid = d.column_value;

	OPEN out_deleg_grid_var_cur FOR
		SELECT id, root_delegation_sid, region_sid, start_dtm, end_dtm, grid_ind_sid,
			   variance, explanation, active, label, curr_value, prev_value
		  FROM deleg_grid_variance;

	OPEN out_ind_tag_cur FOR
		SELECT delegation_sid, ind_sid, tag
		  FROM delegation_ind_tag, TABLE(m_deleg_sids) d, TABLE(m_ind_sids) i
		 WHERE delegation_sid = d.column_value
		   AND ind_sid = i.column_value;

	OPEN out_ind_tag_list_cur FOR
		SELECT delegation_sid, tag
		  FROM delegation_ind_tag_list, TABLE(m_deleg_sids) d
		 WHERE delegation_sid = d.column_value;

	OPEN out_ind_cond_cur FOR
		SELECT delegation_sid, ind_sid, delegation_ind_cond_id, expr
		  FROM delegation_ind_cond, TABLE(m_deleg_sids) d, TABLE(m_ind_sids) i
		 WHERE delegation_sid = d.column_value
		   AND ind_sid = i.column_value;

	OPEN out_ind_cond_action_cur FOR
		SELECT delegation_sid, ind_sid, delegation_ind_cond_id, action, tag
		  FROM delegation_ind_cond_action, TABLE(m_deleg_sids) d, TABLE(m_ind_sids) i
		 WHERE delegation_sid = d.column_value
		   AND ind_sid = i.column_value;

	OPEN out_form_expr FOR
		SELECT fe.form_expr_id, fe.delegation_sid, fe.description, fe.expr.extract('/').getStringVal() expr
		  FROM form_expr fe, TABLE(m_deleg_sids) d
		 WHERE delegation_sid = d.column_value;

	OPEN out_deleg_ind_form_expr FOR
		SELECT delegation_sid, ind_sid, form_expr_id
		  FROM deleg_ind_form_expr,  TABLE(m_deleg_sids) d, TABLE(m_ind_sids) i
		 WHERE delegation_sid = d.column_value
		   AND ind_sid = i.column_value;

	OPEN out_deleg_ind_group FOR
		SELECT deleg_ind_group_id, delegation_sid, title, start_collapsed
		  FROM deleg_ind_group, TABLE(m_deleg_sids) d
		 WHERE delegation_sid = d.column_value;

	OPEN out_deleg_ind_group_member FOR
		SELECT delegation_sid, ind_sid, deleg_ind_group_id
		  FROM deleg_ind_group_member, TABLE(m_deleg_sids) d, TABLE(m_ind_sids) i
		 WHERE delegation_sid = d.column_value
		   AND ind_sid = i.column_value;

	OPEN out_var_expl_groups FOR
		SELECT var_expl_group_id, label
		  FROM var_expl_group;

	OPEN out_var_expl FOR
		SELECT var_expl_id, var_expl_group_id, label, requires_note, pos, hidden
		  FROM var_expl;

	OPEN out_dlg_pln_survey_reg_cur FOR
		SELECT campaign_sid, region_sid, has_manual_amends,
			   pending_deletion, region_selection, tag_id
		  FROM campaigns.campaign_region;
		  
	OPEN out_campaign_region_response FOR
		SELECT campaign_sid, response_id, region_sid, surveys_version, flow_item_id
		  FROM campaigns.campaign_region_response;
END;

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
)
AS
BEGIN
	IF m_region_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetRegions first');
	END IF;

	IF m_deleg_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call PickPlanDelegations or PickAllDelegations first');
	END IF;

	OPEN out_role FOR
		SELECT deleg_plan_sid, role_sid, pos
		  FROM deleg_plan_role;

	OPEN out_region FOR
		SELECT deleg_plan_sid, region_sid
		  FROM deleg_plan_region, TABLE(m_region_sids) r
		 WHERE region_sid = r.column_value;

	OPEN out_plan FOR
		SELECT deleg_plan_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id,
			   reminder_offset, schedule_xml, name_template, active, notes, dynamic, last_applied_dtm, last_applied_dynamic
		  FROM deleg_plan;

	OPEN out_col FOR
		SELECT deleg_plan_sid, deleg_plan_col_id, is_hidden, deleg_plan_col_deleg_id
		  FROM deleg_plan_col;

	OPEN out_col_deleg FOR
		SELECT deleg_plan_col_deleg_Id, delegation_sid
		  FROM deleg_plan_col_deleg;

	OPEN out_deleg_region FOR
		SELECT deleg_plan_col_deleg_id, region_sid, pending_deletion, region_selection, region_collation, tag_id, region_type
		  FROM deleg_plan_deleg_region, TABLE(m_region_sids) r
		 WHERE region_sid = r.column_value;

	OPEN out_deleg_region_deleg FOR
		SELECT deleg_plan_col_deleg_id, region_sid, applied_to_region_sid, maps_to_root_deleg_sid, has_manual_amends
		  FROM deleg_plan_deleg_region_deleg, TABLE(m_region_sids) r, TABLE(m_region_sids) ar, TABLE(m_deleg_sids) d
		 WHERE region_sid = r.column_value
		   AND applied_to_region_sid = ar.column_value
		   AND maps_to_root_deleg_sid = d.column_value;

	OPEN out_master_deleg FOR
		SELECT md.delegation_sid
		  FROM master_deleg md, TABLE(m_deleg_sids) d
		 WHERE md.delegation_sid = d.column_value;

	OPEN out_date_schedule FOR
		SELECT deleg_plan_sid, role_sid, deleg_plan_col_id, schedule_xml, reminder_offset, delegation_date_schedule_id
		  FROM deleg_plan_date_schedule;
END;

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
)
AS
BEGIN
	IF m_user_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetUsers first');
	END IF;
	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;
	IF m_region_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetRegions first');
	END IF;

	OPEN out_sheet_cur FOR
		SELECT sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm, reminder_dtm, last_sheet_history_id, is_visible,
		       automatic_approval_dtm, percent_complete, is_read_only, is_copied_forward, automatic_approval_status
		  FROM sheet, TABLE(m_deleg_sids) d
		 WHERE delegation_sid = d.column_value;

	OPEN out_sheet_history_cur FOR
		SELECT sheet_history_id, sheet_id, from_user_sid, to_delegation_sid, action_dtm, note, sheet_action_id, is_system_note
		  FROM sheet_history
		 WHERE sheet_id IN (SELECT sheet_id
		   					  FROM sheet, TABLE(m_deleg_sids) d
							 WHERE delegation_sid = d.column_value);

	OPEN out_sheet_alert_cur FOR
		SELECT sheet_id, user_sid, reminder_sent_dtm, overdue_sent_dtm
		  FROM sheet_alert
		 WHERE sheet_id IN (SELECT sheet_id
							   FROM sheet, TABLE(m_deleg_sids) d
							  WHERE delegation_sid = d.column_value);

	OPEN out_sheet_value_cur FOR
	    SELECT sv.sheet_value_id, sv.sheet_id, sv.ind_sid, sv.region_sid, sv.val_number, sv.set_by_user_sid,
	    	   sv.set_dtm, sv.note, sv.entry_measure_conversion_id, sv.entry_val_number, sv.is_inherited,
	    	   sv.status, sv.last_sheet_value_change_id, sv.alert, sv.flag, sv.var_expl_note, sv.is_na
		  FROM sheet_value sv
		  JOIN sheet s ON sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id
		  JOIN TABLE(m_ind_sids) i ON i.column_value = sv.ind_sid
		  JOIN TABLE(m_region_sids) r ON r.column_value = sv.region_sid
		  JOIN TABLE(m_deleg_sids) d ON d.column_value = s.delegation_sid;

	OPEN out_sheet_inherited_value_cur FOR
		WITH sheet_values AS (
		    SELECT /*+MATERIALIZE CARDINALITY(i, 50000) CARDINALITY(r, 50000) CARDINALITY(d, 50000)*/ sv.sheet_value_id
			  FROM sheet_value sv
			  JOIN sheet s ON sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id
			  JOIN TABLE(m_ind_sids) i ON i.column_value = sv.ind_sid
			  JOIN TABLE(m_region_sids) r ON r.column_value = sv.region_sid
			  JOIN TABLE(m_deleg_sids) d ON d.column_value = s.delegation_sid
		)
	    SELECT siv.sheet_value_id, siv.inherited_value_id
		  FROM sheet_inherited_value siv, sheet_values sv1, sheet_values sv2
         WHERE siv.sheet_value_id = sv1.sheet_value_id
           AND siv.inherited_value_id = sv2.sheet_value_id;

	OPEN out_sheet_value_accuracy_cur FOR
	    SELECT sva.sheet_value_id, sva.accuracy_type_option_id, sva.pct
		  FROM sheet_value_accuracy sva, sheet_value sv, TABLE(m_ind_sids) i, TABLE(m_region_sids) r,
		  	   TABLE(m_deleg_sids) d, sheet s
         WHERE sv.app_sid = sva.app_sid
           AND sv.sheet_value_id = sva.sheet_value_id
           AND sv.ind_sid = i.column_value
           AND sv.region_sid = r.column_value
           AND sv.sheet_id = s.sheet_id
           AND s.delegation_sid = d.column_value;

	OPEN out_sheet_value_var_expl_cur FOR
	    SELECT svve.sheet_value_id, svve.var_expl_id
		  FROM sheet_value_var_expl svve, sheet_value sv, TABLE(m_ind_sids) i, TABLE(m_region_sids) r,
		  	   TABLE(m_deleg_sids) d, sheet s
         WHERE sv.app_sid = svve.app_sid
           AND sv.sheet_value_id = svve.sheet_value_id
           AND sv.ind_sid = i.column_value
           AND sv.region_sid = r.column_value
           AND sv.sheet_id = s.sheet_id
           AND s.delegation_sid = d.column_value;

	OPEN out_sheet_value_file_cur FOR
	    SELECT svf.sheet_value_id, svf.file_upload_sid
		  FROM sheet_value_file svf, sheet_value sv, TABLE(m_ind_sids) i, TABLE(m_region_sids) r,
		  	   TABLE(m_deleg_sids) d, sheet s
         WHERE sv.app_sid = svf.app_sid
           AND sv.sheet_value_id = svf.sheet_value_id
           AND sv.ind_sid = i.column_value
           AND sv.region_sid = r.column_value
           AND sv.sheet_id = s.sheet_id
           AND s.delegation_sid = d.column_value;
	
	OPEN out_svfhc_cur FOR
	    SELECT svfhc.sheet_value_id, svfhc.file_upload_sid
		  FROM sheet_value_file_hidden_cache svfhc, sheet_value sv, TABLE(m_ind_sids) i, TABLE(m_region_sids) r,
		  	   TABLE(m_deleg_sids) d, sheet s
         WHERE sv.app_sid = svfhc.app_sid
           AND sv.sheet_value_id = svfhc.sheet_value_id
           AND sv.ind_sid = i.column_value
           AND sv.region_sid = r.column_value
           AND sv.sheet_id = s.sheet_id
           AND s.delegation_sid = d.column_value;
	
	OPEN out_sheet_value_hidden_cac_cur FOR
		SELECT svhc.sheet_value_id, svhc.val_number, svhc.note, svhc.entry_measure_conversion_id, svhc.entry_val_number
		  FROM sheet_value_hidden_cache svhc, sheet_value sv, TABLE(m_ind_sids) i, TABLE(m_region_sids) r,
			   TABLE(m_deleg_sids) d, sheet s
		 WHERE sv.app_sid = svhc.app_sid
		   AND sv.sheet_value_id = svhc.sheet_value_id
		   AND sv.ind_sid = i.column_value
		   AND sv.region_sid = r.column_value
		   AND sv.sheet_id = s.sheet_id
		   AND s.delegation_sid = d.column_value;

	OPEN out_sheet_change_req_cur FOR
		SELECT sheet_change_req_id,
			   active_sheet_id,
			   is_approved,
			   processed_by_sid,
			   processed_dtm,
			   processed_note,
			   raised_by_sid,
			   raised_dtm,
			   raised_note,
			   req_to_change_sheet_id
		  FROM sheet_change_req;

	OPEN out_sheet_change_req_alert_cur FOR
		SELECT sheet_change_req_alert_id,
			   action_type,
			   notify_user_sid,
			   raised_by_user_sid,
			   sheet_change_req_id
		  FROM sheet_change_req_alert;

	OPEN out_sheet_value_change_fil_cur FOR
		SELECT sheet_value_change_id,
			   file_upload_sid
		  FROM sheet_value_change_file;
END;

PROCEDURE GetSheetValueChanges(
	out_sheet_value_change_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;
	IF m_region_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetRegions first');
	END IF;

	OPEN out_sheet_value_change_cur FOR
	    SELECT svc.sheet_value_change_id, svc.sheet_value_id, svc.ind_sid, svc.region_sid, svc.val_number, svc.reason,
	    	   svc.changed_by_sid, svc.changed_dtm, svc.entry_measure_conversion_id, svc.entry_val_number,
	    	   svc.note, svc.flag
		  FROM sheet_value_change svc, sheet_value sv, TABLE(m_ind_sids) i, TABLE(m_region_sids) r,
		  	   TABLE(m_deleg_sids) d, sheet s
         WHERE sv.app_sid = svc.app_sid
           AND sv.sheet_value_id = svc.sheet_value_id
           AND sv.ind_sid = i.column_value
           AND sv.region_sid = r.column_value
           AND sv.sheet_id = s.sheet_id
           AND s.delegation_sid = d.column_value;
END;

PROCEDURE GetForms(
	out_form_cur					OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_allocation_cur				OUT	SYS_REFCURSOR,
	out_allocation_user_cur			OUT	SYS_REFCURSOR,
	out_allocation_item_cur			OUT	SYS_REFCURSOR,
	out_comment_cur					OUT	SYS_REFCURSOR
)
AS
	v_trash_root_sid security_pkg.T_SID_ID;
BEGIN
	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;
	IF m_region_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetRegions first');
	END IF;
	IF m_user_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetUsers first');
	END IF;

	SELECT trash_sid
	  INTO v_trash_root_sid
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF m_export_everything = 1 THEN
		SELECT form_sid
		  BULK COLLECT INTO m_form_sids
		  FROM form;
	ELSE
		SELECT form_sid
		  BULK COLLECT INTO m_form_sids
		  FROM form
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND parent_sid != v_trash_root_sid;
	END IF;

	OPEN out_form_cur FOR
		SELECT form_sid, parent_sid, name, note, start_dtm, end_dtm, group_by, period_set_id,
			   period_interval_id, allocate_users_to, tab_direction
		  FROM form f, TABLE(m_form_sids) tf
		 WHERE tf.column_value = f.form_sid;

	OPEN out_ind_cur FOR
		 SELECT fim.form_sid, fim.ind_sid, fim.description, fim.pos, fim.scale, fim.format_mask, fim.measure_description,
		 		fim.show_total, fim.multiplier_ind_sid, fim.measure_conversion_id
		   FROM form_ind_member fim, TABLE(m_ind_sids) i, TABLE(m_form_sids) rr
		  WHERE	fim.ind_sid = i.column_value
			AND fim.form_sid = rr.column_value;

	OPEN out_region_cur FOR
		 SELECT frm.form_sid, frm.region_sid, frm.description, frm.pos
		   FROM form_region_member frm, TABLE(m_region_sids) r, TABLE(m_form_sids) rr
		  WHERE	frm.region_sid = r.column_value
			AND frm.form_sid = rr.column_value;

	OPEN out_allocation_cur FOR
		SELECT fa.form_allocation_id, fa.form_sid, fa.note
		  FROM form_allocation fa, TABLE(m_form_sids) f
		 WHERE fa.form_sid = f.column_value;

	OPEN out_allocation_user_cur FOR
		SELECT fau.form_allocation_id, fau.user_sid, fau.read_only
		  FROM form_allocation_user fau, form_allocation fa, TABLE(m_form_sids) f, TABLE(m_user_sids) cu
		 WHERE fau.form_allocation_id = fa.form_allocation_id
		   AND fa.form_sid = f.column_value
		   AND fau.user_sid = cu.column_value;

	OPEN out_allocation_item_cur FOR
		SELECT fai.form_allocation_id, NVL(r.column_value, i.column_value) item_sid
		  FROM form_allocation_item fai, form_allocation fa,
		  	   TABLE(m_form_sids) f, TABLE(m_ind_sids) i, TABLE(m_region_sids) r
		 WHERE fai.form_allocation_id = fa.form_allocation_id
		   AND fa.form_sid = f.column_value
		   AND fai.item_sid = i.column_value(+)
		   AND fai.item_sid = r.column_value(+)
		   AND (i.column_value IS NOT NULL OR r.column_value IS NOT NULL);

	OPEN out_comment_cur FOR
		SELECT fc.form_sid, fc.z_key, fc.form_allocation_id, fc.form_comment, fc.last_updated_by_sid, fc.last_updated_dtm
		  FROM form_comment fc, TABLE(m_form_sids) f, TABLE(m_user_sids) cu
		 WHERE fc.form_sid = f.column_value
		   AND fc.last_updated_by_sid = cu.column_value;
END;

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
)
AS
BEGIN
	OPEN out_scenario_cur FOR
		SELECT scenario_sid, description, start_dtm, period_set_id, period_interval_id,
			   equality_epsilon, file_based, auto_update_run_sid, recalc_trigger_type,
			   data_source, data_source_sp, data_source_sp_args, data_source_run_sid,
			   created_by_user_sid, created_dtm, include_all_inds, dont_run_aggregate_indicators
		  FROM scenario;

	OPEN out_scenario_ind_cur FOR
		SELECT scenario_sid, ind_sid
		  FROM scenario_ind;

	OPEN out_scenario_region_cur FOR
		SELECT scenario_sid, region_sid
		  FROM scenario_region;

	OPEN out_scn_opt_cur FOR
		SELECT show_chart, show_bau_option, bau_default
		  FROM scenario_options;

	OPEN out_scn_sub_cur FOR
		SELECT scenario_sid, csr_user_sid
		  FROM scenario_email_sub;

	OPEN out_scn_rule_cur FOR
		SELECT scenario_sid, rule_id, description, rule_type, amount,
			   measure_conversion_id, start_dtm, end_dtm
		  FROM scenario_rule;

	OPEN out_scn_rule_ind_cur FOR
		SELECT scenario_sid, rule_id, ind_sid
		  FROM scenario_rule_ind;

	OPEN out_scn_rle_like_cntg_ind_cur FOR
		SELECT scenario_sid, rule_id, ind_sid
		  FROM scenario_rule_like_contig_ind;

	OPEN out_scn_forecast_rule_cur FOR
		SELECT scenario_sid, rule_id, ind_sid, region_sid, start_dtm, end_dtm, rule_type, rule_val
		  FROM forecasting_rule
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_scn_rule_region_cur FOR
		SELECT scenario_sid, rule_id, region_sid
		  FROM scenario_rule_region;

	OPEN out_scn_run_vers_cur FOR
		SELECT scenario_run_sid, version
		  FROM scenario_run_version;

	OPEN out_scn_run_vers_file_cur FOR
		SELECT scenario_run_sid, version, file_path, sha1
		  FROM scenario_run_version_file;

	OPEN out_scn_run_cur FOR
		SELECT scenario_run_sid, scenario_sid, run_dtm, description, on_completion_sp, version, last_run_by_user_sid
		  FROM scenario_run;

	OPEN out_scn_run_val_cur FOR
		SELECT scenario_run_sid, ind_sid, region_sid, period_start_dtm, period_end_dtm,
			   val_number, error_code, source_type_id, source_id
		  FROM scenario_run_val;
END;

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
)
AS
	v_dataview_root_sid security_pkg.T_SID_ID;
BEGIN
	-- figure out dataview root sid
	v_dataview_root_sid := securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'APP'), 'dataviews');

	IF m_region_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetRegions first');
	END IF;
	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;

	SELECT dataview_sid
  	  BULK COLLECT INTO m_dataview_sids
	  FROM dataview
	 WHERE parent_sid IN (SELECT column_value
	  						FROM TABLE(m_sids))
		OR dataview_sid IN (SELECT column_value
							  FROM TABLE(m_sids));

	OPEN out_dv_cur FOR
		SELECT dataview_sid, parent_sid, name, start_dtm, end_dtm, group_by, period_set_id,
			   period_interval_id, chart_config_xml, chart_style_xml,
 			   pos, description, dataview_type_id,
 			   show_calc_trace, show_variance, show_abs_variance, show_variance_explanations, sort_by_most_recent,
			   treat_null_as_zero, include_parent_region_names,
 			   last_updated_dtm, last_updated_sid, rank_limit_left, rank_limit_left_type,
			   rank_ind_sid, rank_filter_type, rank_limit_right, rank_limit_right_type,
			   rank_reverse, region_grouping_tag_group, version_num, anonymous_region_names, include_notes_in_table,
			   show_region_events, suppress_unmerged_data_message, aggregation_period_id, highlight_changed_since, highlight_changed_since_dtm,
			   show_layer_variance_pct, show_layer_variance_abs, show_layer_variance_pct_base, show_layer_variance_abs_base, show_layer_variance_start,
			   region_selection
   		  FROM dataview
  	     WHERE dataview_sid IN (SELECT column_value
  	     						  FROM TABLE(m_dataview_sids));

	OPEN out_ind_cur FOR
		 SELECT dim.dataview_sid, dim.ind_sid, dim.pos, dim.format_mask,
		 	    dim.measure_conversion_id, dim.normalization_ind_sid,
		 	    dim.calculation_type_id, dim.show_as_rank
		   FROM dataview_ind_member dim, TABLE(m_ind_sids) i, TABLE(m_dataview_sids) rr
		  WHERE	dim.ind_sid = i.column_value
			AND dim.dataview_sid = rr.column_value;

	OPEN out_ind_description_cur FOR
		SELECT did.dataview_sid, did.pos, did.lang, did.description
		  FROM dataview_ind_member dim, dataview_ind_description did, TABLE(m_ind_sids) i, TABLE(m_dataview_sids) rr
		 WHERE dim.ind_sid = i.column_value
		   AND dim.dataview_sid = rr.column_value
		   AND dim.app_sid = did.app_sid
		   AND dim.dataview_sid = did.dataview_sid
		   AND dim.pos = did.pos;

	OPEN out_region_cur FOR
		 SELECT drm.dataview_sid, drm.region_sid, drm.pos
		   FROM dataview_region_member drm, TABLE(m_region_sids) r, TABLE(m_dataview_sids) rr
		  WHERE	drm.region_sid = r.column_value
			AND drm.dataview_sid = rr.column_value;

	OPEN out_region_description_cur FOR
		SELECT drd.dataview_sid, drd.region_sid, drd.lang, drd.description
		  FROM dataview_region_member drm, dataview_region_description drd, TABLE(m_region_sids) r, TABLE(m_dataview_sids) rr
		 WHERE drm.region_sid = r.column_value
		   AND drm.dataview_sid = rr.column_value
		   AND drm.app_sid = drd.app_sid
		   AND drm.dataview_sid = drd.dataview_sid
		   AND drm.region_sid = drd.region_sid;

	OPEN out_excel_export_opts_cur FOR
		SELECT dataview_sid, ind_show_sid, ind_show_info, ind_show_tags,
			   ind_show_gas_factor, region_show_sid, region_show_inactive,
			   region_show_info, region_show_tags, region_show_type,
			   region_show_ref, region_show_acquisition_dtm,
			   region_show_disposal_dtm, region_show_roles,
			   region_show_egrid, region_show_geo_country,
			   meter_show_ref, meter_show_location, meter_show_source_type,
			   meter_show_note, meter_show_crc, meter_show_ind,
			   meter_show_measure, meter_show_cost_ind, meter_show_cost_measure,
			   meter_show_days_ind, meter_show_supplier, meter_show_contract,
			   scenario_pos
		  FROM excel_export_options eeo, TABLE(m_dataview_sids) dvs
		 WHERE eeo.dataview_sid = dvs.column_value;

	OPEN out_dataview_scenario_run_cur FOR
		SELECT dataview_sid, scenario_run_type, scenario_run_sid
		  FROM dataview_scenario_run dsr, TABLE(m_dataview_sids) dvs
		 WHERE dsr.dataview_sid = dvs.column_value;

	OPEN out_dataview_zone_cur FOR
		SELECT pos, name, dataview_sid, start_val_ind_sid, description,
			   start_val_region_sid, start_val_start_dtm, start_val_end_dtm,
			   end_val_ind_sid, end_val_region_sid, end_val_start_dtm,
			   end_val_end_dtm, style_xml, is_target, type, target_direction
		  FROM dataview_zone dvz, TABLE(m_dataview_sids) dvs
		 WHERE dvz.dataview_sid = dvs.column_value;

	OPEN out_dataview_trend_cur FOR
		SELECT dt.pos, dt.name, dt.title, dt.dataview_sid, dt.ind_sid, dt.region_sid,
			   dt.months, dt.rounding_method, dt.rounding_digits
		  FROM dataview_trend dt, TABLE(m_dataview_sids) dvs
		 WHERE dt.dataview_sid = dvs.column_value;

    OPEN out_dataview_history_cur FOR
        SELECT dataview_sid, version_num, name, start_dtm, end_dtm, group_by, chart_config_xml, chart_style_xml, pos,
               description, dataview_type_id, show_calc_trace, show_variance, show_abs_variance, show_variance_explanations,
               sort_by_most_recent, treat_null_as_zero, include_parent_region_names, last_updated_dtm, last_updated_sid, rank_filter_type,
               rank_limit_left, rank_ind_sid, rank_limit_right, rank_limit_left_type, rank_limit_right_type,
               rank_reverse, region_grouping_tag_group, anonymous_region_names, include_notes_in_table,
               show_region_events, suppress_unmerged_data_message, period_set_id, period_interval_id,
			   aggregation_period_id, highlight_changed_since, highlight_changed_since_dtm,
			   show_layer_variance_pct, show_layer_variance_abs, show_layer_variance_pct_base, show_layer_variance_abs_base, show_layer_variance_start
          FROM dataview_history;

    OPEN out_dataview_arb_per_cur FOR
        SELECT dataview_sid, start_dtm, end_dtm
          FROM dataview_arbitrary_period;

    OPEN out_dataview_arb_per_hist_cur FOR
        SELECT dataview_sid, version_num, start_dtm, end_dtm
          FROM dataview_arbitrary_period_hist;
END;

PROCEDURE GetImgCharts(
	out_chart						OUT	SYS_REFCURSOR,
	out_ind							OUT	SYS_REFCURSOR,
	out_img_chart_region_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;

	OPEN out_chart FOR
		SELECT img_chart_sid, parent_sid, label, mime_type, data, sha1, last_modified_dtm, scenario_run_sid, scenario_run_type
		  FROM img_chart;

	OPEN out_ind FOR
		SELECT img_chart_sid, ind_sid, description, measure_conversion_id, x, y, background_color, border_color, font_size
		  FROM img_chart_ind, TABLE(m_ind_sids) i
		 WHERE ind_sid = i.column_value;

	OPEN out_img_chart_region_cur FOR
		SELECT img_chart_sid,
			   region_sid,
			   background_color,
			   border_color,
			   description,
			   x,
			   y
		  FROM img_chart_region;
END;

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
	out_tpl_rep_tag_qc_cur			OUT SYS_REFCURSOR,
	out_tpl_rep_variant_cur			OUT SYS_REFCURSOR,
	out_tpl_rep_variant_tag_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_tpl_img_cur FOR
		SELECT key, path, image, filename, mime_type
		  FROM tpl_img;

	OPEN out_tpl_rep_cust_tt_cur FOR
		SELECT tpl_rep_cust_tag_type_id, cs_class, js_include, js_class,
			   helper_pkg, description
		  FROM tpl_rep_cust_tag_type;

	OPEN out_tpl_report_cur FOR
		SELECT tpl_report_sid, parent_sid, name, description, word_doc, filename, thumb_img,
			   period_set_id, period_interval_id
		  FROM tpl_report;

	OPEN out_tpl_report_tag_dv_cur FOR
		SELECT tpl_report_tag_dataview_id, dataview_sid, month_offset, month_duration,
		       saved_filter_sid, filter_result_mode, aggregate_type_id, period_set_id, period_interval_id, approval_dashboard_sid, ind_tag,
		       hide_if_empty, split_table_by_columns
		  FROM tpl_report_tag_dataview trtd, TABLE(m_dataview_sids) ds
  	     WHERE trtd.dataview_sid = ds.column_value;

	OPEN out_rep_tag_dv_reg_cur FOR
		SELECT tpl_report_tag_dataview_id, dataview_sid, region_sid, tpl_region_type_id, filter_by_tag
		  FROM tpl_report_tag_dv_region trtdr, TABLE(m_dataview_sids) ds
  	     WHERE trtdr.dataview_sid = ds.column_value;
	
	OPEN old_tpl_rep_tag_eval_cur FOR
		SELECT tpl_report_tag_eval_id, if_true, if_false, all_must_be_true, month_offset, period_set_id, period_interval_id
		  FROM tpl_report_tag_eval;

	OPEN out_tpl_rep_tag_eval_cond_cur FOR
		SELECT tpl_report_tag_eval_id, left_ind_sid, operator, right_value, right_ind_sid
		  FROM tpl_report_tag_eval_cond;

	OPEN out_tpl_rep_tag_ind_cur FOR
		SELECT tpl_report_tag_ind_id, ind_sid, month_offset, measure_conversion_id, format_mask, period_set_id, period_interval_id, show_full_path
		  FROM tpl_report_tag_ind;

	OPEN out_tpl_rep_tag_log_frm_cur FOR
		SELECT tpl_report_tag_logging_form_id, tab_sid, month_offset, month_duration,
			   region_column_name, tpl_region_type_id, date_column_name, form_sid,
			   filter_sid, saved_filter_sid
		  FROM tpl_report_tag_logging_form;

	OPEN out_tpl_rep_tag_text_cur FOR
		SELECT tpl_report_tag_text_id, label
		  FROM tpl_report_tag_text;

	OPEN out_tpl_rep_tag_qc_cur FOR
		SELECT tpl_report_tag_qchart_id, month_offset, month_duration, period_set_id, period_interval_id, hide_if_empty,
			   split_table_by_columns, saved_filter_sid
		  FROM tpl_report_tag_qchart;

	OPEN out_tpl_rep_non_compl_cur FOR
		SELECT tpl_report_non_compl_id, month_offset, month_duration, tpl_region_type_id, tag_id
		  FROM tpl_report_non_compl;

	OPEN out_tpl_rep_tag_cur FOR
		SELECT tpl_report_sid, tag, tag_type, tpl_report_tag_ind_id, tpl_report_tag_eval_id,
			   tpl_report_tag_dataview_id, tpl_report_tag_logging_form_id,
			   tpl_rep_cust_tag_type_id, tpl_report_tag_text_id, tpl_report_non_compl_id,
			   tpl_report_tag_app_note_id, tpl_report_tag_app_matrix_id, tpl_report_tag_reg_data_id, tpl_report_tag_qc_id
		  FROM tpl_report_tag;

	OPEN out_tpl_rep_tag_appr_nt_cur FOR
		SELECT tpl_report_tag_app_note_id, tab_portlet_id, approval_dashboard_sid
		  FROM tpl_report_tag_approval_note;

	OPEN out_tpl_rep_tag_appr_mx_cur FOR
		SELECT tpl_report_tag_app_matrix_id, approval_dashboard_sid
		  FROM tpl_report_tag_approval_matrix;

	OPEN out_tpl_rep_tag_reg_data_cur FOR
		SELECT tpl_report_tag_reg_data_id, tpl_report_reg_data_type_id
		  FROM tpl_report_tag_reg_data;
		  
	OPEN out_tpl_rep_variant_cur FOR
		SELECT master_template_sid, language_code, word_doc, filename, mime_type
		  FROM tpl_report_variant;
		  
	OPEN out_tpl_rep_variant_tag_cur FOR 
		SELECT tpl_report_sid, language_code, tag
		  FROM tpl_report_variant_tag;
END;

PROCEDURE GetTargetDashboards(
	out_target_dash_cur				OUT	SYS_REFCURSOR,
	out_tgt_dash_ind_member_cur		OUT	SYS_REFCURSOR,
	out_tgt_dash_reg_member_cur		OUT	SYS_REFCURSOR,
	out_tgt_dash_val_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_target_dash_cur FOR
		SELECT target_dashboard_sid, start_dtm, end_dtm, period_set_id, period_interval_id,
			   name, parent_sid,
			   use_root_region_sid
		  FROM target_dashboard;

	OPEN out_tgt_dash_ind_member_cur FOR
		SELECT target_dashboard_sid, target_ind_sid, ind_sid, pos
		  FROM target_dashboard_ind_member;

	OPEN out_tgt_dash_reg_member_cur FOR
		SELECT target_dashboard_sid, region_sid, pos
		  FROM target_dashboard_reg_member;

	OPEN out_tgt_dash_val_cur FOR
		SELECT target_dashboard_sid, ind_sid, region_sid, val_number
		  FROM target_dashboard_value;
END;

PROCEDURE GetMetricDashboards(
	out_metric_dash_cur				OUT	SYS_REFCURSOR,
	out_metric_dash_ind_cur			OUT	SYS_REFCURSOR,
	out_metric_dash_plugin_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_metric_dash_cur FOR
		SELECT metric_dashboard_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id
		  FROM metric_dashboard;

	OPEN out_metric_dash_ind_cur FOR
		SELECT metric_dashboard_sid, ind_sid, pos, block_title, block_css_class, inten_view_scenario_run_sid, inten_view_floor_area_ind_sid, absol_view_scenario_run_sid
 	      FROM metric_dashboard_ind;

	OPEN out_metric_dash_plugin_cur FOR
		SELECT metric_dashboard_sid, plugin_id
		  FROM metric_dashboard_plugin;
END;

PROCEDURE GetBenchmarkingDashboards(
	out_benchmark_dash_cur				OUT	SYS_REFCURSOR,
	out_benchmark_dash_ind_cur			OUT	SYS_REFCURSOR,
	out_benchmark_dash_plugin_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_benchmark_dash_cur FOR
		SELECT benchmark_dashboard_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id
		  FROM benchmark_dashboard;

	OPEN out_benchmark_dash_ind_cur FOR
		SELECT benchmark_dashboard_sid, ind_sid, pos, display_name, scenario_run_sid, floor_area_ind_sid
 	      FROM benchmark_dashboard_ind;

	OPEN out_benchmark_dash_plugin_cur FOR
		SELECT benchmark_dashboard_sid, plugin_id
		  FROM benchmark_dashboard_plugin;
END;

PROCEDURE GetApprovalDashboards(
	out_approval_dashboard_cur		OUT	SYS_REFCURSOR,
	out_appr_dash_alert_type_cur	OUT	SYS_REFCURSOR,
	out_appr_dash_inst_cur			OUT	SYS_REFCURSOR,
	out_appr_dash_region_cur		OUT	SYS_REFCURSOR,
	out_appr_dash_tab_cur			OUT	SYS_REFCURSOR,
	out_appr_dash_tpl_tag_cur		OUT	SYS_REFCURSOR,
	out_appr_dash_val_cur			OUT SYS_REFCURSOR,
	out_appr_dash_ind_cur			OUT SYS_REFCURSOR,
	out_appr_dash_val_src_cur		OUT SYS_REFCURSOR,
	out_appr_dash_batch_job_cur		OUT SYS_REFCURSOR,
	out_appr_note_portlet_note_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_approval_dashboard_cur FOR
		SELECT approval_dashboard_sid, label, flow_sid, tpl_report_sid,
			   is_multi_region, start_dtm, end_dtm,	active_period_scenario_run_sid,	signed_off_scenario_run_sid,
			   instance_creation_schedule, period_set_id, period_interval_id, publish_doc_folder_sid, source_scenario_run_sid
		  FROM approval_dashboard;

	OPEN out_appr_dash_alert_type_cur FOR
		SELECT approval_dashboard_sid, customer_alert_type_id, flow_sid
		  FROM approval_dashboard_alert_type;

	OPEN out_appr_dash_inst_cur FOR
		SELECT dashboard_instance_id, approval_dashboard_sid, region_sid,
			   start_dtm, end_dtm, tpl_report_sid, last_refreshed_dtm, is_locked, is_signed_off
		  FROM approval_dashboard_instance
		 WHERE 1 = 0; -- we don't support clonning approval dashboard instances data

	OPEN out_appr_dash_region_cur FOR
		SELECT approval_dashboard_sid, region_sid
		  FROM approval_dashboard_region;

	OPEN out_appr_dash_tab_cur FOR
		SELECT approval_dashboard_sid, tab_id, pos
		  FROM approval_dashboard_tab;

	OPEN out_appr_dash_tpl_tag_cur FOR
		SELECT dashboard_instance_id, tpl_report_sid, tag, note
		  FROM approval_dashboard_tpl_tag;

	OPEN out_appr_dash_val_cur FOR
		SELECT approval_dashboard_val_id, approval_dashboard_sid, dashboard_instance_id, ind_sid, start_dtm,end_dtm,val_number,ytd_val_number,
			   note, note_added_by_sid, note_added_dtm, is_estimated_data
    	  FROM approval_dashboard_val
		 WHERE 1 = 0; -- we don't support clonning approval dashboard instances data

	OPEN out_appr_dash_ind_cur FOR
		SELECT approval_dashboard_sid, ind_sid, deactivated_dtm, allow_estimated_data, pos, is_hidden
    	  FROM approval_dashboard_ind;

	OPEN out_appr_dash_val_src_cur FOR
		SELECT approval_dashboard_val_id, id, description
    	  FROM approval_dashboard_val_src
		 WHERE 1 = 0; -- we don't support clonning approval dashboard instances data

	OPEN out_appr_dash_batch_job_cur FOR
		SELECT dashboard_instance_id, batch_job_id
    	  FROM batch_job_approval_dash_vals
		 WHERE 1 = 0; -- we don't support clonning approval dashboard instances data

	OPEN out_appr_note_portlet_note_cur FOR
		SELECT version, tab_portlet_id,approval_dashboard_sid,dashboard_instance_id, region_sid, note, added_dtm, added_by_sid
    	  FROM approval_note_portlet_note
		 WHERE 1 = 0; -- we don't support clonning approval dashboard instances data
END;

PROCEDURE GetDashboards(
	out_dashboard_cur				OUT	SYS_REFCURSOR,
	out_dashboard_item_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_dashboard_cur FOR
		SELECT dashboard_sid, name, note
		  FROM dashboard;

	OPEN out_dashboard_item_cur FOR
		SELECT dashboard_item_id, dashboard_sid, parent_sid, period, comparison_type,
			   ind_sid, region_sid, name, pos, dataview_sid
		  FROM dashboard_item;
END;

PROCEDURE GetVals(
	in_include_calc_values			IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF m_region_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetRegions first');
	END IF;

	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;

	IF m_user_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetUsers first');
	END IF;
	-- cu.app_sid IS NULL - this is for // system users
	OPEN out_cur FOR
		SELECT v.val_id, v.ind_sid, v.region_sid, v.period_start_dtm, v.period_end_dtm, v.val_number,
			   v.error_code, v.alert, v.flags, v.source_type_id, v.source_id,
			   v.entry_measure_conversion_id, v.entry_val_number, v.note,
 			   NVL(cu.column_value, 3) changed_by_sid, v.changed_dtm
 	 	  FROM val v, TABLE(m_user_sids) cu, TABLE(m_ind_sids) i, TABLE(m_region_sids) r
		 WHERE v.changed_by_sid = cu.column_value(+)
		   AND v.ind_sid = i.column_value
		   AND v.region_sid = r.column_value
		   AND v.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (in_include_calc_values = 1
				OR v.source_type_id NOT IN (csr_data_pkg.SOURCE_TYPE_AGGREGATOR, csr_data_pkg.SOURCE_TYPE_STORED_CALC));
END;

PROCEDURE GetValChanges(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF m_region_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetRegions first');
	END IF;

	IF m_ind_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetIndicators first');
	END IF;

	IF m_user_sids IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must call GetUsers first');
	END IF;
	-- cu.app_sid IS NULL - this is for // system users
	OPEN out_cur FOR
		SELECT vc.val_change_id, vc.ind_sid, vc.region_sid, vc.period_start_dtm, vc.period_end_dtm, vc.val_number,
			   vc.source_type_id, vc.source_id, vc.entry_measure_conversion_id, vc.entry_val_number,
			   vc.note, NVL(cu.column_value, 3) changed_by_sid, vc.changed_dtm, vc.reason
 	 	  FROM val_change vc, TABLE(m_user_sids) cu, TABLE(m_ind_sids) i, TABLE(m_region_sids) r
		 WHERE vc.changed_by_sid = cu.column_value(+)
		   AND vc.ind_sid = i.column_value
		   AND vc.region_sid = r.column_value
		   AND vc.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetValMetadata(
	out_val_file_cur OUT SYS_REFCURSOR,
	out_val_note_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_val_file_cur FOR
		SELECT val_id,
			   file_upload_sid
		  FROM val_file;

	OPEN out_val_note_cur FOR
		SELECT val_note_id,
			   entered_by_sid,
			   entered_dtm,
			   ind_sid,
			   note,
			   period_end_dtm,
			   period_start_dtm,
			   region_sid
		  FROM val_note;
END;

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
)
AS
	v_dataview_root_sid security_pkg.T_SID_ID;
BEGIN
	OPEN out_section_status_cur FOR
		SELECT section_status_sid, description, colour, pos, icon_path
		  FROM section_status;

	OPEN out_section_module_cur FOR
		SELECT module_root_sid, label, show_summary_tab, default_status_sid, flow_sid, region_sid, active,
			   start_dtm, show_flow_summary_tab, reminder_offset, previous_module_sid, library_sid, end_dtm,
			   show_fact_icon
		  FROM section_module;

	OPEN out_section_cur FOR
		SELECT section_sid, parent_sid, checked_out_to_sid, checked_out_dtm, checked_out_version_number,
			   visible_version_number, section_position, active, module_root_sid, title_only, ref,
			   plugin, plugin_config, section_status_sid, further_info_url, help_text, flow_item_id,
			   current_route_step_id, is_split, disable_general_attachments, previous_section_sid
		  FROM section;

	OPEN out_section_version_cur FOR
		SELECT section_sid, version_number, title, body, changed_by_sid, changed_dtm, reason_for_change,
			   approved_by_sid, approved_dtm
		  FROM section_version;

	OPEN out_attachment_cur FOR
		SELECT attachment_id, filename, mime_type, data, ds.column_value dataview_sid,
			   last_updated_from_dataview, view_as_table, indicator_sid, embed, doc_id, url
		  FROM attachment a, TABLE(m_dataview_sids) ds
  	     WHERE a.dataview_sid = ds.column_value(+);

	OPEN out_attachment_history_cur FOR
		SELECT section_sid, version_number, attachment_id, attach_name, pg_num, attach_comment
		  FROM attachment_history;

	OPEN out_section_comment_cur FOR
		SELECT section_comment_id, section_sid, in_reply_to_id, comment_text,
			   entered_by_sid, entered_dtm, is_closed
		  FROM section_comment;

	OPEN out_section_trans_comment_cur FOR
		SELECT section_trans_comment_id, section_sid, entered_by_sid, entered_dtm, comment_text
		  FROM section_trans_comment;

	OPEN out_route_cur FOR
		SELECT route_id, section_sid, flow_state_id, flow_sid, due_dtm, completed_dtm
		  FROM route;

	OPEN out_route_step_cur FOR
		SELECT ROUTE_STEP_ID, ROUTE_ID, WORK_DAYS_OFFSET, STEP_DUE_DTM, POS
		  FROM route_step;

	OPEN out_route_step_user_cur FOR
		SELECT route_step_id, csr_user_sid, reminder_sent_dtm, overdue_sent_dtm, declined_sent_dtm
		  FROM route_step_user;

	OPEN out_section_cart_folder_cur FOR
		SELECT SECTION_CART_FOLDER_ID, PARENT_ID, NAME, IS_VISIBLE, IS_ROOT
		  FROM section_cart_folder;

	OPEN out_section_cart_cur FOR
		SELECT SECTION_CART_ID, NAME, SECTION_CART_FOLDER_ID
		  FROM section_cart;

	OPEN out_section_cart_member_cur FOR
		SELECT section_cart_id, SECTION_SID
		  FROM section_cart_member;

	OPEN out_section_route_fs_cur FOR
		SELECT flow_sid, flow_state_id, reject_fs_transition_id
		  FROM section_routed_flow_state;

	OPEN out_section_flow_cur FOR
		SELECT flow_sid, split_question_flow_state_id, dflt_ret_aft_inc_usr_submit
		  FROM section_flow;

	OPEN out_section_tag_cur FOR
		SELECT parent_id, section_tag_id, tag, active
		  FROM section_tag;

	OPEN out_section_tag_member_cur	FOR
		SELECT section_tag_id, section_sid
		  FROM section_tag_member;

	OPEN out_section_alert FOR
		SELECT section_alert_id, customer_alert_type_id, section_sid, raised_dtm, from_user_sid, notify_user_sid, flow_state_id, route_step_id, sent_dtm, cancelled_dtm
		  FROM section_alert;

	OPEN out_section_transition_cur FOR
		SELECT section_transition_sid, from_section_status_sid, to_section_status_sid
		  FROM section_transition;

	OPEN out_route_log_cur FOR
		SELECT route_log_id,
			   csr_user_sid,
			   description,
			   log_date,
			   param_1,
			   param_2,
			   param_3,
			   route_id,
			   route_step_id,
			   summary
		  FROM route_log;

	OPEN out_route_step_vote_cur FOR
		SELECT route_step_id,
			   user_sid,
			   dest_flow_state_id,
			   dest_route_step_id,
			   is_return,
			   vote_direction,
			   vote_dtm
		  FROM route_step_vote;
END;

PROCEDURE GetFileUploads(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security, only used by csrexp
	OPEN out_cur FOR
		SELECT fu.file_upload_sid, fu.filename, fu.mime_type, fu.parent_sid, fu.data,
			   fu.sha1, fu.last_modified_dtm
		  FROM file_upload fu, TABLE(m_sids) s
		 WHERE s.column_value = fu.file_upload_sid;
END;

PROCEDURE GetImports(
	out_imp_session_cur				OUT	SYS_REFCURSOR,
	out_imp_ind_cur					OUT	SYS_REFCURSOR,
	out_imp_region_cur				OUT	SYS_REFCURSOR,
	out_imp_measure_cur				OUT	SYS_REFCURSOR,
	out_imp_val_cur					OUT	SYS_REFCURSOR,
	out_imp_conflict_cur			OUT	SYS_REFCURSOR,
	out_imp_conflict_val_cur		OUT	SYS_REFCURSOR,
	out_imp_vocab_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_imp_session_cur FOR
		SELECT imp_session_sid, parent_sid, name, owner_sid, uploaded_dtm, file_path,
			   parse_started_dtm, parsed_dtm, merged_dtm, result_code, message, unmerged_dtm
		  FROM imp_session;

	OPEN out_imp_ind_cur FOR
		SELECT imp_ind_id, description, maps_to_ind_sid, ignore
		  FROM imp_ind;

	OPEN out_imp_region_cur FOR
		SELECT imp_region_id, description, maps_to_region_sid, ignore
		  FROM imp_region;

	OPEN out_imp_measure_cur FOR
		SELECT imp_measure_id, description, maps_to_measure_conversion_id, maps_to_measure_sid, imp_ind_id
		  FROM imp_measure;

	OPEN out_imp_val_cur FOR
		SELECT imp_val_id, imp_ind_id, imp_region_id, imp_measure_id, unknown, start_dtm, end_dtm,
			   val, file_sid, a, b, c, imp_session_sid, set_val_id, note, set_region_metric_val_id
		  FROM imp_val;

	OPEN out_imp_conflict_cur FOR
		SELECT imp_conflict_id, imp_session_sid, resolved_by_user_sid, start_dtm, end_dtm, region_sid, ind_sid
		  FROM imp_conflict;

	OPEN out_imp_conflict_val_cur FOR
		SELECT imp_conflict_id, imp_val_id, accept
		  FROM imp_conflict_val;

	OPEN out_imp_vocab_cur FOR
		SELECT csr_user_sid, imp_tag_type_id, phrase, frequency
		  FROM imp_vocab;
END;

PROCEDURE GetFlowCmsAlertData(
	out_alert_type_cur				OUT	SYS_REFCURSOR,
	out_alert_helper_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_alert_type_cur FOR
		SELECT tab_sid, customer_alert_type_id, description, lookup_key, include_in_alert_setup, deleted, is_batched
		  FROM cms_alert_type;

	OPEN out_alert_helper_cur FOR
		SELECT helper_sp, tab_sid, description
		  FROM cms_alert_helper;
END;

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
)
AS
BEGIN
	OPEN out_flow_cur FOR
		SELECT flow_sid, label, default_state_id, helper_pkg, owner_can_create,
			   aggregate_ind_group_id, flow_alert_class
		  FROM flow;

	OPEN out_flow_item_cur FOR
		SELECT flow_item_id, flow_sid, current_state_id, survey_response_id,
			   dashboard_instance_id, last_flow_state_transition_id, last_flow_state_log_id
		  FROM flow_item;

	OPEN out_flow_item_region_cur FOR
		SELECT flow_item_id, region_sid
		  FROM flow_item_region;

	OPEN out_flow_state_cur FOR
		SELECT flow_state_id, flow_sid, label, lookup_key, attributes_xml, is_deleted,
			   state_colour, pos, is_final, is_editable_by_owner, ind_sid, move_from_flow_state_id,
			   flow_state_nature_id, time_spent_ind_sid, survey_editable
		  FROM flow_state;

	OPEN out_flow_state_log_cur FOR
		SELECT flow_state_log_id, flow_item_id, flow_state_id, set_by_user_sid, set_dtm, comment_text
		  FROM flow_state_log;

	OPEN out_flow_state_log_file_cur FOR
		SELECT flow_state_log_file_id, flow_state_log_id, filename, mime_type, data, sha1, uploaded_dtm
		  FROM flow_state_log_file;

	OPEN out_flow_state_role_cur FOR
		SELECT flow_state_id, role_sid, is_editable, group_sid
		  FROM flow_state_role;

	OPEN out_flow_state_cms_col_cur FOR
		SELECT flow_state_id, column_sid, is_editable
		  FROM flow_state_cms_col;

	OPEN out_flow_state_inv_cur FOR
		SELECT flow_state_id, flow_involvement_type_id
		  FROM flow_state_involvement;

	OPEN out_flow_state_inv_cap_cur FOR
		SELECT flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid,
			   flow_involvement_type_id, permission_set, group_sid
		  FROM flow_state_role_capability;

	OPEN out_flow_state_trans_cur FOR
		SELECT flow_state_transition_id, from_state_id, to_state_id, flow_sid, verb,
			   ask_for_comment, pos, attributes_xml, helper_sp, lookup_key,
			   mandatory_fields_message, hours_before_auto_tran, button_icon_path, owner_can_set,
			   group_sid_can_set, auto_schedule_xml, auto_trans_type, last_run_dtm, enforce_validation
		  FROM flow_state_transition;

	OPEN out_flow_state_trans_role_cur FOR
		SELECT flow_state_transition_id, from_state_id, role_sid, group_sid
		  FROM flow_state_transition_role;

	OPEN out_flow_state_trans_col_cur FOR
		SELECT flow_state_transition_id, from_state_id, column_sid
		  FROM flow_state_transition_cms_col;

	OPEN out_flow_state_trans_inv_cur FOR
		SELECT flow_state_transition_id, from_state_id, flow_involvement_type_id
		  FROM flow_state_transition_inv;

	OPEN out_flow_state_trans_help_cur FOR
		SELECT flow_sid, helper_sp, label
		  FROM flow_state_trans_helper;

	OPEN out_flow_alert_type_cur FOR
		SELECT customer_alert_type_id, flow_sid, label, deleted, lookup_key
		  FROM flow_alert_type;

	OPEN out_flow_alert_helper_cur FOR
		SELECT flow_alert_helper, label
		  FROM flow_alert_helper;

	OPEN out_flow_item_gen_alert_cur FOR
		SELECT flow_transition_alert_id, from_user_sid, to_user_sid, to_column_sid, flow_item_generated_alert_id,
			flow_item_id, processed_dtm, flow_state_log_id, created_dtm, subject_override, body_override
		  FROM flow_item_generated_alert;

	OPEN out_flow_trans_alert_cur FOR
		SELECT flow_transition_alert_id, flow_state_transition_id,
			   customer_alert_type_id, description, deleted, helper_sp,
			   to_initiator, flow_alert_helper, can_be_edited_before_sending
		  FROM flow_transition_alert;

	OPEN out_flow_trans_alert_role_cur FOR
		SELECT flow_transition_alert_id, role_sid, group_sid
		  FROM flow_transition_alert_role;

	OPEN out_flow_trans_alrt_cc_rl_cur FOR
		SELECT flow_transition_alert_id, role_sid, group_sid
		  FROM flow_transition_alert_cc_role;

	OPEN out_flow_trans_alert_user_cur FOR
		SELECT flow_transition_alert_id, user_sid
		  FROM flow_transition_alert_user;

	OPEN out_flow_trans_alrt_cc_usr_cur FOR
		SELECT flow_transition_alert_id, user_sid
		  FROM flow_transition_alert_cc_user;

	OPEN out_flow_trns_alrt_cms_usr_cur FOR
		SELECT flow_transition_alert_id, column_sid, alert_manager_flag
		  FROM flow_transition_alert_cms_col;

	OPEN out_flow_trans_alert_inv_cur FOR
		SELECT flow_transition_alert_id, flow_involvement_type_id
		  FROM flow_transition_alert_inv;

	OPEN out_flow_cust_alert_class_cur FOR
		SELECT flow_alert_class
		  FROM customer_flow_alert_class;

	OPEN out_flow_involvement_type_cur FOR
		SELECT flow_involvement_type_id, product_area, label, css_class, lookup_key
		  FROM flow_involvement_type;

	OPEN out_flow_item_involvement_cur FOR
		SELECT flow_involvement_type_id, flow_item_id, user_sid
		  FROM flow_item_involvement;

	OPEN out_cust_flow_capability_cur FOR
		SELECT flow_capability_id,
			   default_permission_set,
			   description,
			   flow_alert_class,
			   lookup_key,
			   perm_type,
			   is_system_managed
		  FROM customer_flow_capability;

	OPEN out_flow_state_group_cur FOR
		SELECT flow_state_group_id,
			   label,
			   lookup_key,
			   count_ind_sid
		  FROM flow_state_group;

	OPEN out_flow_state_group_membr_cur FOR
		SELECT flow_state_group_id,
			   flow_state_id,
			   before_report_date,
			   after_report_date
		  FROM flow_state_group_member;

	OPEN out_flow_inv_type_alt_cls_cur FOR
		SELECT flow_involvement_type_id, flow_alert_class
		  FROM flow_inv_type_alert_class;

	OPEN out_flow_state_survey_tag_cur FOR
		SELECT flow_state_id, tag_id
		  FROM flow_state_survey_tag;
END;

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
)
AS
BEGIN
	OPEN out_meter_source_type_cur FOR
	   SELECT meter_source_type_id, name, description, arbitrary_period,
	   		  add_invoice_data, show_in_meter_list,
	   		  is_calculated_sub_meter, descending, allow_reset, 
	   		  allow_null_start_dtm
		 FROM meter_source_type;

	OPEN out_all_meter_cur FOR
		SELECT region_sid, meter_type_id, meter_source_type_id,
			   days_measure_conversion_id, costdays_measure_conversion_id,
			   approved_by_sid, reference, note, crc_meter, active, export_live_data_after_dtm, approved_dtm, is_core, urjanet_meter_id,
			   metering_version, lower_threshold_percentage, upper_threshold_percentage, manual_data_entry
		  FROM all_meter
		 WHERE region_sid IN (
				SELECT column_value
		 		  FROM TABLE(m_region_sids));

	OPEN out_meter_document_cur FOR
		SELECT meter_document_id, mime_type, file_name, data
		  FROM meter_document;

	OPEN out_meter_type_cur FOR
		SELECT meter_type_id, label, group_key,
			   days_ind_sid, costdays_ind_sid, req_approval, flow_sid
		  FROM meter_type;


	OPEN out_utility_supplier_cur FOR
		SELECT utility_supplier_id, supplier_name, contact_details
		  FROM utility_supplier;

	OPEN out_utility_contract_cur FOR
		SELECT utility_contract_id, utility_supplier_id, account_ref, from_dtm,
			   to_dtm, alert_when_due, file_data, file_mime_type, file_name,
			   created_by_sid
		  FROM utility_contract;

	OPEN out_utility_invoice_cur FOR
		SELECT utility_invoice_id, utility_contract_id, reference, invoice_dtm,
			   cost_value, cost_measure_sid, cost_conv_id, consumption,
			   consumption_conv_id, file_data, file_mime_type, file_name,
			   verified_by_sid, consumption_measure_sid
		  FROM utility_invoice;

	OPEN out_meter_reading_cur FOR
		SELECT region_sid, meter_reading_id, start_dtm, end_dtm, val_number, entered_by_user_sid,
			   entered_dtm, note, reference, cost, meter_document_id, created_invoice_id, meter_source_type_id,
			   req_approval, replaces_reading_id, approved_dtm, approved_by_sid, active, is_delete, flow_item_id, baseline_val,
			   demand, pm_reading_id, is_estimate
		  FROM meter_reading;

	OPEN out_meter_util_contract_cur FOR
		SELECT region_sid, utility_contract_id, active
		  FROM meter_utility_contract;

	OPEN out_meter_input_cur FOR
		SELECT meter_input_id, label, lookup_key, is_consumption_based, patch_helper, gap_finder, is_virtual, value_helper
		  FROM meter_input;

	OPEN out_meter_data_priority_cur FOR
		SELECT priority, label, lookup_key, is_input, is_output, is_patch, is_auto_patch
		  FROM meter_data_priority;

	OPEN out_meter_input_aggregator_cur FOR
		SELECT meter_input_id, aggregator, aggr_proc, is_mandatory
		  FROM meter_input_aggregator;

	OPEN out_meter_input_aggr_ind_cur FOR
		SELECT region_sid, meter_input_id, aggregator, meter_type_id, measure_sid, measure_conversion_id
		  FROM meter_input_aggr_ind;

	OPEN out_meter_patch_data_cur FOR
		SELECT region_sid, meter_input_id, priority, start_dtm, end_dtm, consumption, updated_dtm
		  FROM meter_patch_data;

	OPEN out_meter_patch_job_cur FOR
		SELECT region_sid, meter_input_id, start_dtm, end_dtm, created_dtm
		  FROM meter_patch_job;

	OPEN out_meter_patch_batch_job_cur FOR
		SELECT batch_job_id, region_sid, is_remove, created_dtm
		  FROM meter_patch_batch_job;

	OPEN out_meter_patch_batch_data_cur FOR
		SELECT batch_job_id, meter_input_id, priority, start_dtm, end_dtm, period_type, consumption
		  FROM meter_patch_batch_data;

	OPEN out_meter_data_covg_ind_cur FOR
		SELECT meter_input_id, priority, ind_sid
		  FROM meter_data_coverage_ind;

	OPEN out_meter_aggregate_type_cur FOR
		SELECT meter_aggregate_type_id, meter_input_id, aggregator, analytic_function, description,
		       accumulative
		  FROM meter_aggregate_type;

	OPEN out_metering_options_cur FOR
		SELECT analytics_months, analytics_current_month, meter_page_url, metering_helper_pkg,
			   show_inherited_roles, period_set_id, period_interval_id, show_invoice_reminder,
			   invoice_reminder, supplier_data_mandatory, region_date_clipping, fwd_estimate_meters,
			   reference_mandatory, realtime_metering_enabled, prevent_manual_future_readings,
			   proc_use_service, proc_api_base_uri, proc_local_path, proc_kick_timeout,
			   raw_feed_data_jobs_enabled
		  FROM metering_options;

	OPEN out_meter_element_layout_cur FOR
		SELECT meter_element_layout_id, pos, ind_sid, tag_group_id
		  FROM meter_element_layout;

	OPEN out_meter_type_input_cur FOR
		SELECT meter_type_id, meter_input_id, aggregator, ind_sid, measure_sid
		  FROM meter_type_input;

	OPEN out_meter_tab_cur FOR
		SELECT plugin_id, plugin_type_id, pos, tab_label
		  FROM meter_tab;

	OPEN out_meter_tab_group_cur FOR
		SELECT plugin_id, group_sid, role_sid
		  FROM meter_tab_group;

	OPEN out_meter_header_element_cur FOR
		SELECT meter_header_element_id, pos, col, ind_sid, tag_group_id, meter_header_core_element_id
		  FROM meter_header_element;

	OPEN out_meter_photo_cur FOR
		SELECT meter_photo_id, region_sid, filename, mime_type, data
		  FROM meter_photo;

	OPEN out_meter_data_src_hi_inp_cur FOR
		SELECT raw_data_source_id, meter_input_id
		  FROM meter_data_source_hi_res_input;
END;


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
)
AS
BEGIN
	OPEN out_meter_alarm_statistic_cur FOR
		SELECT statistic_id, meter_input_id, aggregator, meter_bucket_id, name, is_average, is_sum, comp_proc, all_meters, not_before_dtm, core_working_hours, pos
		  FROM meter_alarm_statistic;

	OPEN out_meter_alarm_compar_cur FOR
		SELECT comparison_id, name, show_pct, op_code
		  FROM meter_alarm_comparison;

	OPEN out_meter_alrm_iss_period_cur FOR
		SELECT issue_period_id, name, test_function
		  FROM meter_alarm_issue_period;

	OPEN out_meter_alarm_test_time_cur FOR
		SELECT test_time_id, name, test_function
		  FROM meter_alarm_test_time;

	OPEN out_meter_alarm_cur FOR
		SELECT meter_alarm_id, inheritable, enabled, name, test_time_id,
			   look_at_statistic_id, compare_statistic_id, comparison_id,
			   comparison_val, issue_period_id, issue_trigger_count
		  FROM meter_alarm;

	OPEN out_meter_alarm_event_cur FOR
		SELECT region_sid, meter_alarm_id, meter_alarm_event_id, event_dtm
		  FROM meter_alarm_event;

	OPEN out_meter_alarm_stat_run_cur FOR
		SELECT meter_alarm_id, region_sid, statistic_id, statistic_dtm
		  FROM meter_alarm_stat_run;

	OPEN out_meter_alarm_stat_job_cur FOR
		SELECT region_sid, statistic_id, start_dtm, end_dtm, job_created_dtm
		  FROM meter_alarm_statistic_job;

	OPEN out_meter_alarm_stat_period FOR
		SELECT region_sid, statistic_id, statistic_dtm, val, average_count
		  FROM meter_alarm_statistic_period;

	OPEN out_meter_meter_alrm_stat_cur FOR
		SELECT region_sid, statistic_id, not_before_dtm, last_comp_dtm
		  FROM meter_meter_alarm_statistic;

	OPEN out_region_meter_alarm_cur FOR
		SELECT region_sid, inherited_from_sid,
			   meter_alarm_id, ignore, ignore_children
		  FROM region_meter_alarm;

	OPEN out_core_working_hours_cur FOR
		SELECT core_working_hours_id, start_time, end_time
		  FROM core_working_hours;

	OPEN out_core_working_hours_day_cur FOR
		SELECT core_working_hours_id, day
		  FROM core_working_hours_day;

	OPEN out_core_working_hours_rgn_cur FOR 
		SELECT region_sid, core_working_hours_id
		  FROM core_working_hours_region;
END;

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
)
AS
BEGIN
	OPEN out_meter_raw_data_source_cur FOR
		SELECT raw_data_source_id, parser_type, helper_pkg,
			   export_system_values, export_after_dtm, default_issue_user_sid,
			   orphan_count, matched_count, create_meters, automated_import_class_sid,
			   holding_region_sid, meter_date_format, process_body, label, proc_use_remote_service
	 	  FROM meter_raw_data_source;

	OPEN out_meter_xml_option FOR
		SELECT raw_data_source_id, data_type, xslt
		  FROM meter_xml_option;

	OPEN out_meter_excel_mapping_cur FOR
		SELECT raw_data_source_id, field_name, column_name, column_index
		  FROM meter_excel_mapping;

	OPEN out_meter_excel_option_cur FOR
		SELECT raw_data_source_id, worksheet_index, row_index, csv_delimiter
		  FROM meter_excel_option;

	OPEN out_meter_list_cache_cur FOR
		SELECT region_sid, last_reading_dtm, entered_dtm,
			   val_number, avg_consumption, cost_number, read_by_sid, realtime_last_period,
			   realtime_consumption, demand_number, reading_count, first_reading_dtm
		  FROM meter_list_cache;

	OPEN out_meter_bucket_cur FOR
		SELECT meter_bucket_id, duration, description, is_hours, is_weeks, is_minutes,
			   week_start_day, is_months, start_month, is_export_period,
			   period_set_id, period_interval_id, high_resolution_only,
			   core_working_hours
		  FROM meter_bucket;

	OPEN out_meter_raw_data_cur FOR
		SELECT meter_raw_data_id, raw_data_source_id, received_dtm, start_dtm,
			   end_dtm, mime_type, encoding_name, message_uid, data, status_id, orphan_count, matched_count,
			   original_mime_type, original_file_name, original_data, automated_import_instance_id, file_name
		  FROM meter_raw_data;

	OPEN out_meter_live_data_cur FOR
		SELECT region_sid, meter_bucket_id, meter_input_id, aggregator, priority, start_dtm,
			   meter_raw_data_id, end_dtm, modified_dtm, consumption, meter_data_id
		  FROM meter_live_data;

	OPEN out_meter_orphan_data_cur FOR
		SELECT serial_id, meter_input_id, priority, start_dtm, end_dtm, meter_raw_data_id, consumption,
			   uom, related_location_1, related_location_2, region_sid, has_overlap, error_type_id, statement_id
		  FROM meter_orphan_data;

	OPEN out_meter_raw_data_error_cur FOR
		SELECT meter_raw_data_id, error_id, message, raised_dtm, data_dtm
		  FROM meter_raw_data_error;

	OPEN out_meter_source_data_cur FOR
		SELECT region_sid, meter_input_id, priority, start_dtm, end_dtm, meter_raw_data_id, raw_uom, raw_consumption, consumption, statement_id
		  FROM meter_source_data;

	OPEN out_meter_reading_data_cur FOR
		SELECT region_sid, meter_input_id, priority, reading_dtm, meter_raw_data_id, raw_uom, raw_val, val
		  FROM meter_reading_data;

	OPEN out_meter_raw_data_log_cur FOR
		SELECT meter_raw_data_id, log_id, user_sid, log_text, log_dtm, mime_type, file_name, data
		  FROM meter_raw_data_log;

	OPEN out_duff_meter_region_cur FOR
		SELECT urjanet_meter_id, meter_name, meter_number, region_ref, service_type, meter_raw_data_id,
			meter_raw_data_error_id, region_sid, issue_id, message, error_type_id, created_dtm, updated_dtm
		  FROM duff_meter_region;
END;

PROCEDURE GetIncidentTypes(
	out_incident_types				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_incident_types FOR
		SELECT tab_sid, group_key, label, plural, base_css_class, pos, list_url,
			   edit_url, new_case_url, mobile_form_path, mobile_form_sid, description
		  FROM incident_type;
END;

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
)
AS
BEGIN
	OPEN out_issue_cur FOR
		SELECT first_priority_set_dtm, issue_id, label, last_label, source_label,
			   correspondent_id, correspondent_notified, raised_by_user_sid,
			   raised_dtm, owner_user_sid, owner_role_sid, resolved_by_user_sid,
			   resolved_dtm, closed_by_user_sid, closed_dtm, assigned_to_user_sid,
			   assigned_to_role_sid, region_sid, rejected_dtm, rejected_by_user_sid,
			   due_dtm, last_due_dtm, guid, issue_pending_val_id, issue_sheet_value_id,
			   issue_survey_answer_id, issue_type_id, issue_non_compliance_id,
			   issue_action_id, issue_meter_id, issue_meter_alarm_id,
			   issue_meter_raw_data_id, issue_priority_id, last_issue_priority_id,
			   issue_meter_data_source_id, issue_supplier_id, is_visible, source_url,
			   deleted, parent_id, is_public, issue_escalated, allow_auto_close,
			   first_issue_log_id, last_issue_log_id, description, last_description,
			   region_2_sid, forecast_dtm, last_forecast_dtm, rag_status_id,
			   last_rag_status_id, var_expl, issue_ref, is_pending_assignment, last_region_sid,
			   manual_completion_dtm, manual_comp_dtm_set_dtm, issue_compliance_region_id,
			   issue_due_source_id, issue_due_offset_days, issue_due_offset_months, 
			   issue_due_offset_years, permit_id, is_critical, notified_overdue, copied_from_id
		  FROM issue;

	OPEN out_correspondent_cur FOR
		SELECT correspondent_id, full_name, email, phone, guid, more_info_1
		  FROM correspondent;

	OPEN out_issue_pending_val_cur FOR
		SELECT issue_pending_val_id, pending_region_id, pending_ind_id, pending_period_id
		  FROM issue_pending_val;

	OPEN out_issue_sheet_value_cur FOR
		SELECT issue_sheet_value_id, ind_sid, region_sid, start_dtm, end_dtm
		  FROM issue_sheet_value
		 WHERE ind_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_ind_sids))
		   AND region_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_region_sids));

	OPEN out_issue_priority_cur FOR
		SELECT issue_priority_id, description, due_date_offset
		  FROM issue_priority;

	OPEN out_issue_type_cur FOR
		SELECT issue_type_id, label, default_region_sid, default_issue_priority_id,
			   alert_mail_address, alert_mail_name, require_priority, allow_children,
			   create_raw, auto_close_after_resolve_days, default_assign_to_user_sid, default_assign_to_role_sid,
			   alert_pending_due_days, alert_overdue_days, position, deleted, can_set_public, email_involved_roles,
			   email_involved_users, allow_pending_assignment, restrict_users_to_region, deletable_by_owner,
			   deletable_by_administrator, involve_min_users_in_issue, show_forecast_dtm, require_var_expl, enable_reject_action,
			   helper_pkg, public_by_default, owner_can_be_changed, deletable_by_raiser, send_alert_on_issue_raised,
			   internal_issue_ref_helper_func, internal_issue_ref_prefix, lookup_key, show_one_issue_popup, allow_owner_resolve_and_close,
			   applies_to_audit, get_assignables_sp, region_link_type, require_due_dtm_comment, is_region_editable, enable_manual_comp_date,
			   comment_is_optional, due_date_is_mandatory, allow_critical, allow_urgent_alert, region_is_mandatory
		  FROM issue_type;

	OPEN out_issue_type_agg_ind_grp FOR
		SELECT issue_type_id, aggregate_ind_group_id
		  FROM issue_type_aggregate_ind_grp;

	OPEN out_issue_type_rag_status FOR
		SELECT issue_type_id, rag_status_id, pos
		  FROM issue_type_rag_status;

	OPEN out_issue_user_cur FOR
		SELECT issue_id, is_an_owner, user_sid, role_sid, company_sid
		  FROM issue_involvement;

	OPEN out_issue_scheduled_task_cur FOR
		SELECT issue_scheduled_task_id, label, schedule_xml, period_xml,
			   last_created, raised_by_user_sid, assign_to_user_sid,
			   next_run_dtm, due_dtm_relative, due_dtm_relative_unit,
			   scheduled_on_due_date, issue_type_id, create_critical,
			   copied_from_id, region_sid
		  FROM issue_scheduled_task;

	OPEN out_issue_survey_ans_cur FOR
		SELECT issue_survey_answer_id, survey_response_id, question_id,
			   survey_sid, survey_version, question_version
		  FROM issue_survey_answer;

	OPEN out_issue_nc_cur FOR
		SELECT issue_non_compliance_id, non_compliance_id
		  FROM issue_non_compliance;

	OPEN out_issue_action_cur FOR
		SELECT issue_action_id, task_sid
		  FROM issue_action;

	OPEN out_issue_alert_cur FOR
		SELECT issue_id,
			   csr_user_sid,
			   overdue_sent_dtm,
			   reminder_sent_dtm
		  FROM issue_alert;

	OPEN out_issue_cmp_reg_cur FOR
		SELECT issue_compliance_region_id, flow_item_id
		  FROM issue_compliance_region;

	OPEN out_issue_due_source FOR
		SELECT issue_due_source_id, issue_type_id, source_description, fetch_proc
		  FROM issue_due_source;

	OPEN out_issue_template_cur FOR
		SELECT issue_template_id,
			   assign_to_user_sid,
			   description,
			   due_dtm,
			   due_dtm_relative,
			   due_dtm_relative_unit,
			   issue_type_id,
			   is_critical,
			   is_urgent,
			   label
		  FROM issue_template;

	OPEN out_itcf_cur FOR
		SELECT issue_template_id,
			   issue_custom_field_id,
			   date_value,
			   string_value
		  FROM issue_template_custom_field;

	OPEN out_itcfo_cur FOR
		SELECT issue_template_id,
			   issue_custom_field_id,
			   issue_custom_field_opt_id
		  FROM issue_template_cust_field_opt;
END;

PROCEDURE GetMeterIssues(
	out_issue_meter_cur				OUT	SYS_REFCURSOR,
	out_issue_meter_alarm_cur		OUT	SYS_REFCURSOR,
	out_issue_meter_data_src_cur	OUT	SYS_REFCURSOR,
	out_issue_meter_raw_data_cur	OUT	SYS_REFCURSOR,
	out_immd_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_issue_meter_cur FOR
		SELECT issue_meter_id, region_sid, issue_dtm
		  FROM issue_meter
		 WHERE region_sid IN (
		 		SELECT column_value
		 		  FROM TABLE(m_region_sids));

	OPEN out_issue_meter_alarm_cur FOR
		SELECT issue_meter_alarm_id, region_sid, meter_alarm_id, issue_dtm
		  FROM issue_meter_alarm;

	OPEN out_issue_meter_data_src_cur FOR
		SELECT issue_meter_data_source_id, raw_data_source_id
		  FROM issue_meter_data_source;

	OPEN out_issue_meter_raw_data_cur FOR
		SELECT issue_meter_raw_data_id, meter_raw_data_id, region_sid
		  FROM issue_meter_raw_data;

	OPEN out_immd_cur FOR
		SELECT issue_meter_missing_data_id,
			   end_dtm,
			   region_sid,
			   start_dtm
		  FROM issue_meter_missing_data;
END;

PROCEDURE GetIssueLogs(
	out_issue_action_log_cur		OUT	SYS_REFCURSOR,
	out_issue_log_cur				OUT	SYS_REFCURSOR,
	out_issue_log_file_cur			OUT	SYS_REFCURSOR,
	out_issue_log_read_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_issue_action_log_cur FOR
		SELECT issue_action_log_id, issue_action_type_id, issue_id, issue_log_id,
			   logged_by_user_sid, logged_by_correspondent_id, logged_dtm,
			   assigned_to_role_sid, assigned_to_user_sid, re_user_sid, re_role_sid,
			   old_label, new_label, old_due_dtm, new_due_dtm, old_priority_id,
			   new_priority_id, old_description, new_description, old_forecast_dtm,
			   new_forecast_dtm, owner_user_sid, old_region_sid, new_region_sid,
			   new_manual_comp_dtm_set_dtm, new_manual_comp_dtm, involved_user_sid, 
			   involved_user_sid_removed, is_public
		  FROM issue_action_log;

	OPEN out_issue_log_cur FOR
		SELECT issue_log_id, issue_id, message, logged_dtm, is_system_generated,
			   logged_by_user_sid, logged_by_correspondent_id,
			   param_1, param_2, param_3
		  FROM issue_log;

	OPEN out_issue_log_file_cur FOR
		SELECT issue_log_file_id, issue_log_id, filename, mime_type,
			   data, sha1, uploaded_dtm
		  FROM issue_log_file;

	OPEN out_issue_log_read_cur FOR
		SELECT issue_log_id, read_dtm, csr_user_sid
		  FROM issue_log_read;
END;

PROCEDURE GetIssueLogsFiltered(
	in_issue_log_file_filter		IN	NUMBER,
	in_issue_log_file_data			IN  NUMBER,
	out_issue_action_log_cur		OUT	SYS_REFCURSOR,
	out_issue_log_cur				OUT	SYS_REFCURSOR,
	out_issue_log_file_cur			OUT	SYS_REFCURSOR,
	out_issue_log_read_cur			OUT	SYS_REFCURSOR
)
AS
	v_filter_date	DATE;
	v_empty_blob	BLOB;
BEGIN
	-- Update archive file id and size only if empty and file is archived
	IF in_issue_log_file_data = 0
	THEN
		DBMS_LOB.CreateTemporary(v_empty_blob, TRUE);

		MERGE INTO issue_log_file ilf
		USING (SELECT ilft.issue_log_file_id logfileid,
					  ilt.issue_log_id logid,
					  dbms_lob.getlength(ilft.data) filesize,
					  ilt.issue_id || '_' || ilft.issue_log_file_id || '.' 
					  || SUBSTR(ilft.filename,(INSTR(ilft.filename,'.',-1,1)+1), length(ilft.filename)) newfilename
				 FROM issue_log_file ilft
				 JOIN issue_log ilt 
				   ON ilft.issue_log_id = ilt.issue_log_id
				WHERE ilft.archive_file_id IS null) 
		   ON ( ilf.issue_log_file_id = logfileid AND ilf.issue_log_id = logid )
		 WHEN MATCHED THEN UPDATE
			SET ilf.archive_file_size = filesize,
				ilf.archive_file_id = newfilename;
	END IF;

	OPEN out_issue_action_log_cur FOR
		SELECT issue_action_log_id, issue_action_type_id, issue_id, issue_log_id,
			   logged_by_user_sid, logged_by_correspondent_id, logged_dtm,
			   assigned_to_role_sid, assigned_to_user_sid, re_user_sid, re_role_sid,
			   old_label, new_label, old_due_dtm, new_due_dtm, old_priority_id,
			   new_priority_id, old_description, new_description, old_forecast_dtm,
			   new_forecast_dtm, owner_user_sid, old_region_sid, new_region_sid,
			   new_manual_comp_dtm_set_dtm, new_manual_comp_dtm, involved_user_sid, 
			   involved_user_sid_removed, is_public
		  FROM issue_action_log;

	OPEN out_issue_log_cur FOR
		SELECT issue_log_id, issue_id, message, logged_dtm, is_system_generated,
			logged_by_user_sid, logged_by_correspondent_id,
			param_1, param_2, param_3
		FROM issue_log;

	IF in_issue_log_file_filter = 0
	THEN
		OPEN out_issue_log_file_cur FOR
			-- return empty cursor
			SELECT issue_log_file_id, issue_log_id, filename, mime_type,
				data,
				sha1,
				uploaded_dtm,
				archive_file_id,
				archive_file_size
			FROM issue_log_file
			WHERE issue_log_file_id IS NULL;
	END IF;
	IF in_issue_log_file_filter = 1
	THEN
		OPEN out_issue_log_file_cur FOR
			SELECT issue_log_file_id, issue_log_id, filename, mime_type,
				CASE
					WHEN in_issue_log_file_data = 0 THEN v_empty_blob
					ELSE data
				END AS data,
				CASE
					WHEN in_issue_log_file_data = 0 THEN null
					ELSE sha1
				END AS sha1,
				uploaded_dtm,
				archive_file_id,
				archive_file_size
			FROM issue_log_file;
	END IF;
	IF in_issue_log_file_filter > 1
	THEN
		SELECT TO_DATE(in_issue_log_file_filter, 'yyyymmdd') 
		  INTO v_filter_date
		  FROM DUAL;

		OPEN out_issue_log_file_cur FOR
			SELECT issue_log_file_id, issue_log_id, filename, mime_type,
				CASE
					WHEN in_issue_log_file_data = 0 THEN v_empty_blob
					ELSE data
				END AS data,
				CASE
					WHEN in_issue_log_file_data = 0 THEN null
					ELSE sha1
				END AS sha1,
				uploaded_dtm,
				archive_file_id,
				archive_file_size
			FROM issue_log_file
			WHERE uploaded_dtm >= v_filter_date;
	END IF;

	OPEN out_issue_log_read_cur FOR
		SELECT issue_log_id, read_dtm, csr_user_sid
		  FROM issue_log_read;
END;

PROCEDURE GetIssueCustomFields(
	out_custom_field_id_cur			OUT	SYS_REFCURSOR,
	out_issue_custom_fld_opt_cur	OUT	SYS_REFCURSOR,
	out_iss_cust_fld_opt_sel_cur	OUT	SYS_REFCURSOR,
	out_iss_cust_fld_str_val_cur	OUT	SYS_REFCURSOR,
	out_iss_cust_fld_date_val_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_custom_field_id_cur FOR
		SELECT issue_custom_field_id, issue_type_id, field_type, label, is_mandatory, pos, field_reference_name, restrict_to_group_sid
		  FROM issue_custom_field
		 WHERE field_type IN ('T', 'O', 'M', 'D');

	OPEN out_issue_custom_fld_opt_cur FOR
		SELECT issue_custom_field_id, issue_custom_field_opt_id, label
		  FROM issue_custom_field_option;

	OPEN out_iss_cust_fld_opt_sel_cur FOR
		SELECT issue_id, issue_custom_field_id, issue_custom_field_opt_id
		  FROM issue_custom_field_opt_sel;

	OPEN out_iss_cust_fld_str_val_cur FOR
		SELECT issue_id, issue_custom_field_id, string_value
		  FROM issue_custom_field_str_val;

	OPEN out_iss_cust_fld_date_val_cur FOR
		SELECT issue_id, issue_custom_field_id, date_value
		  FROM issue_custom_field_date_val;
END;

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
)
AS
BEGIN
	OPEN out_customer_portlet_cur FOR
		SELECT customer_portlet_sid, portlet_id, default_state, portal_group
		  FROM customer_portlet;

	OPEN out_tab_cur FOR
		SELECT tab_id, layout, name, is_shared, portal_group, override_pos, is_hideable
		  FROM tab;

	OPEN out_tab_group_cur FOR
		SELECT tab_id, group_sid, pos
		  FROM tab_group;

	OPEN out_tab_portlet_cur FOR
		SELECT tab_portlet_id, tab_id, column_num, pos, state, customer_portlet_sid,
		       added_by_user_sid, added_dtm
		  FROM tab_portlet;

	OPEN out_rss_cache_cur FOR
		SELECT rc.rss_url, rc.last_updated, rc.xml, rc.last_error, rc.error_count
		  FROM rss_cache rc
		 WHERE rc.rss_url IN (
			SELECT tprf.rss_url
			  FROM tab_portlet_rss_feed tprf
		 );

	OPEN out_tab_portlet_rss_feed_cur FOR
		SELECT tab_portlet_id, rss_url
		  FROM tab_portlet_rss_feed;

	OPEN out_tab_portlet_user_reg_cur FOR
		SELECT tab_portlet_id, csr_user_sid, region_sid
		  FROM tab_portlet_user_region;

	OPEN out_tab_user_cur FOR
		SELECT tab_id, user_sid, pos, is_owner, is_hidden
		  FROM tab_user;

	-- yet another half shared table.  sigh.
	OPEN out_user_setting_cur FOR
		SELECT us.category, us.setting, us.description, us.data_type
		  FROM user_setting us, customer_portlet cp, portlet p
		 WHERE cp.portlet_id = p.portlet_id
		   AND UPPER(p.type) = UPPER(us.category);

	OPEN out_user_setting_entry_cur FOR
		SELECT csr_user_sid, category, setting, tab_portlet_id, value
		  FROM user_setting_entry;

	OPEN out_hide_portlet_cur FOR
		SELECT portlet_id
		  FROM hide_portlet
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_image_upload_portlet_cur FOR
		SELECT file_name, image, img_id, mime_type
		  FROM image_upload_portlet;

	OPEN out_tab_description_cur FOR
		SELECT tab_id, lang, description, last_changed_dtm
		  FROM tab_description;
END;

PROCEDURE GetPortalDashboards(
	out_dashboard_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_dashboard_cur FOR
		SELECT portal_sid, portal_group, menu_sid, message
		  FROM portal_dashboard;
END;

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
)
AS
BEGIN
	OPEN out_doc_cur FOR
		SELECT doc_id
		  FROM doc;

	OPEN out_doc_data_cur FOR
		SELECT doc_data_id, data, sha1, mime_type
		  FROM doc_data;

	OPEN out_doc_version_cur FOR
		SELECT doc_id, version, filename, description, change_description,
			   changed_by_sid, changed_dtm, doc_data_id, doc_type_id
		  FROM doc_version;

	OPEN out_doc_current_cur FOR
		SELECT doc_id, version, parent_sid, locked_by_sid, pending_version
		  FROM doc_current;

	OPEN out_doc_download_cur FOR
		SELECT doc_id, version, downloaded_dtm, downloaded_by_sid
		  FROM doc_download;

	OPEN out_doc_folder_cur FOR
		SELECT doc_folder_sid, description, lifespan_is_override, lifespan,
			   approver_is_override, approver_sid, company_sid, property_sid, is_system_managed,
			   permit_item_id
		  FROM doc_folder;

	OPEN out_doc_folder_sub_cur FOR
		SELECT doc_folder_sid, notify_sid
		  FROM doc_folder_subscription;

	OPEN out_doc_library_cur FOR
		SELECT doc_library_sid, documents_sid, trash_folder_sid
		  FROM doc_library;

	OPEN out_doc_notification_cur FOR
		SELECT doc_notification_id, doc_id, version, notify_sid, sent_dtm, reason
		  FROM doc_notification;

	OPEN out_doc_subscription_cur FOR
		SELECT doc_id, notify_sid
		  FROM doc_subscription;

	OPEN out_doc_types_cur FOR
		SELECT doc_type_id, doc_library_sid, name
		  FROM doc_type;

	OPEN out_doc_folder_name_tr_cur FOR
		SELECT doc_folder_sid, lang, translated, parent_sid
		  FROM doc_folder_name_translation;
END;

PROCEDURE GetQuestionLibrary(
	out_question_cur						OUT	SYS_REFCURSOR,
	out_quest_ver_cur						OUT	SYS_REFCURSOR,
	out_quest_opt_cur						OUT	SYS_REFCURSOR,
	out_q_opt_nc_t_cur						OUT	SYS_REFCURSOR,
	out_quest_tag_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_question_cur FOR
		SELECT question_id, owned_by_survey_sid, question_type,
			   custom_question_type_id, lookup_key, maps_to_ind_sid,
			   measure_sid, latest_question_version, latest_question_draft
		  FROM question;

	OPEN out_quest_ver_cur FOR
		SELECT question_id, question_version, question_draft, parent_id, parent_version,
			   parent_draft, pos, label, score, max_score, upload_score, weight, 
			   dont_normalise_score, has_score_expression, has_max_score_expr,
			   remember_answer, count_question, action, question_xml
		  FROM question_version;

	OPEN out_quest_opt_cur FOR
		SELECT question_option_id, question_id, question_version, question_draft, pos,
			   label, score, color, lookup_key, maps_to_ind_sid, option_action, non_compliance_popup,
			   non_comp_default_id, non_compliance_type_id, non_compliance_label, non_compliance_detail,
			   non_comp_root_cause, non_comp_suggested_action, question_option_xml
		  FROM question_option;

	OPEN out_q_opt_nc_t_cur FOR
		SELECT question_id, question_option_id, question_version, question_draft, tag_id
		  FROM question_option_nc_tag;

	OPEN out_quest_tag_cur FOR
		SELECT question_id, question_version, tag_id, question_draft, show_in_survey
		  FROM question_tag;
END;

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
)
AS
BEGIN
	OPEN out_qs_cur FOR
		SELECT survey_sid, created_dtm, audience, aggregate_ind_group_id,
			   quick_survey_type_id, root_ind_sid, submission_validity_months,
			   score_type_id, last_modified_dtm, current_version, group_key,
			   auditing_audit_type_id, from_question_library, lookup_key
		  FROM quick_survey;

	OPEN out_qs_ver_cur FOR
		SELECT survey_sid, survey_version, question_xml, label, start_dtm, end_dtm,
			   published_dtm, published_by_sid
		  FROM quick_survey_version;

	campaigns.campaign_pkg.GetAllCampaigns(out_qs_campaign_cur);

	OPEN out_qs_type_cur FOR
		SELECT quick_survey_type_id, description, cs_class, helper_pkg,
			   enable_question_count, show_answer_set_dtm, other_text_req_for_score, 
			   tearoff_toolbar, capture_geo_location
		  FROM quick_survey_type;


	OPEN out_qs_filter_cond_gen_cur FOR
		SELECT filter_id, qs_filter_condition_general_id, survey_sid, qs_filter_cond_gen_type_id,
			   comparator, compare_to_str_val, compare_to_num_val, qs_campaign_sid, pos
		  FROM qs_filter_condition_general;

	OPEN out_qs_lang_cur FOR
		SELECT survey_sid, lang
		  FROM quick_survey_lang;

	OPEN out_qs_cust_quest_cur FOR
		SELECT custom_question_type_id, description, js_include, js_class, cs_class
		  FROM qs_custom_question_type;

	OPEN out_qs_question_cur FOR
		SELECT question_id, question_version, parent_id, parent_version, survey_sid, pos, label, is_visible,
			   question_type, score, lookup_key, maps_to_ind_sid, measure_sid,
			   max_score, upload_score, custom_question_type_id, weight,
			   dont_normalise_score, has_score_expression, has_max_score_expr,
			   survey_version, remember_answer, count_question, action, question_draft
		  FROM quick_survey_question;

	OPEN out_qs_question_opt_cur FOR
		SELECT question_option_id, question_id, question_version, parent_option_id, pos, label,
			   is_visible, score, color, lookup_key, maps_to_ind_sid, option_action,
			   survey_sid, survey_version, non_compliance_popup, non_comp_default_id,
			   non_compliance_type_id, non_compliance_label, non_compliance_detail,
			   non_comp_root_cause, non_comp_suggested_action, question_draft
		  FROM qs_question_option;

	OPEN out_qs_question_opt_tag_cur FOR
		SELECT question_option_id, question_id, question_version, survey_sid, survey_version, tag_id
		  FROM qs_question_option_nc_tag;

	OPEN out_qs_question_tag_cur FOR
		SELECT question_id, question_version, tag_id, survey_sid, survey_version
		  FROM quick_survey_question_tag;

	OPEN out_qs_css_cur FOR
		SELECT class_name, description, type, position
		  FROM quick_survey_css;

	OPEN out_score_type_cur FOR
		SELECT score_type_id, label, pos, hidden, allow_manual_set, lookup_key,
			   applies_to_supplier, reportable_months, measure_sid,
			   supplier_score_ind_sid, format_mask, ask_for_comment,
			   applies_to_surveys, applies_to_non_compliances,
			   min_score, max_score, start_score, normalise_to_max_score,
			   applies_to_regions, applies_to_audits, applies_to_supp_rels, applies_to_permits, show_expired_scores
		  FROM score_type;

	OPEN out_score_threshold_cur FOR
		SELECT score_threshold_id, max_value, description, text_colour, background_colour,
			   bar_colour, icon_image, icon_image_filename, icon_image_mime_type, icon_image_sha1,
			   dashboard_image, dashboard_filename, dashboard_mime_type, dashboard_sha1,
			   measure_list_index, score_type_id, supplier_score_ind_sid, lookup_key
		  FROM score_threshold;

	OPEN out_qs_score_threshold_cur FOR
		SELECT survey_sid, score_threshold_id, maps_to_ind_sid
		  FROM quick_survey_score_threshold;

	OPEN out_score_type_agg_type_cur FOR
		SELECT score_type_agg_type_id, analytic_function, score_type_id, applies_to_nc_score,
			   applies_to_primary_audit_survy, ia_type_survey_group_id, applies_to_audits
		  FROM score_type_agg_type;

	OPEN out_score_type_audit_type_cur FOR
		SELECT score_type_id, internal_audit_type_id
		  FROM score_type_audit_type;
END;

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
)
AS
BEGIN
	OPEN out_qs_response_cur FOR
		SELECT survey_response_id, survey_sid, user_sid, user_name, created_dtm,
			   guid, qs_campaign_sid, last_submission_id, survey_version,
			   question_xml_override, hidden
		  FROM quick_survey_response;

	OPEN out_qs_resp_postit_cur FOR
		SELECT survey_response_id, postit_id
		  FROM qs_response_postit;

	OPEN out_qs_submission_cur FOR
		SELECT survey_response_id, submission_id, submitted_dtm, submitted_by_user_sid,
			   overall_score, overall_max_score, score_threshold_id, survey_version,
			   geo_latitude, geo_longitude, geo_altitude, geo_h_accuracy, geo_v_accuracy
		  FROM quick_survey_submission;

	OPEN out_qs_answer_cur FOR
		SELECT survey_response_id, question_id, question_version, answer, note, score,
			   question_option_id, val_number, measure_conversion_id,
			   measure_sid, region_sid, html_display, max_score, version_stamp,
			   submission_id, weight_override, survey_sid, survey_version, log_item
		  FROM quick_survey_answer;

	OPEN out_qs_response_file_cur FOR
		SELECT survey_response_id, filename, mime_type, data, sha1, uploaded_dtm
		  FROM qs_response_file;

	OPEN out_qs_answer_file_cur FOR
		SELECT qs_answer_file_id, survey_response_id, question_id, question_version, filename,
			   mime_type, sha1, caption, survey_sid, survey_version
		  FROM qs_answer_file;

	OPEN out_qs_submission_file_cur FOR
		SELECT qs_answer_file_id, survey_response_id, submission_id, survey_version
		  FROM qs_submission_file;

	OPEN out_qs_answer_log_cur FOR
		SELECT qs_answer_log_id, survey_response_id, question_id, question_version, version_stamp, set_dtm, set_by_user_sid,
			   log_item, submission_id
		  FROM qs_answer_log;

	OPEN out_reg_survey_resp_cur FOR
		SELECT survey_sid, survey_response_id, region_sid, period_start_dtm, period_end_dtm
		  FROM region_survey_response;
END;

PROCEDURE GetQuickSurveyExpr(
	out_qs_expr_cur					OUT	SYS_REFCURSOR,
	out_qs_expr_msg_action_cur		OUT	SYS_REFCURSOR,
	out_qs_expr_nc_action_cur		OUT	SYS_REFCURSOR,
	out_qs_expr_action_cur			OUT	SYS_REFCURSOR,
	out_qs_filter_condition_cur		OUT	SYS_REFCURSOR,
	out_qs_expr_nc_act_role_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_qs_expr_cur FOR
		SELECT survey_sid, expr_id, expr, survey_version, question_id, question_version, question_option_id
		  FROM quick_survey_expr;

	OPEN out_qs_expr_msg_action_cur FOR
		SELECT qs_expr_msg_action_id, msg, css_class
		  FROM qs_expr_msg_action;

	OPEN out_qs_expr_nc_action_cur FOR
		SELECT qs_expr_non_compl_action_id, assign_to_role_sid, due_dtm_abs,
			   due_dtm_relative, due_dtm_relative_unit, title, detail,
			   send_email_on_creation, non_comp_default_id, non_compliance_type_id
		  FROM qs_expr_non_compl_action;

	OPEN out_qs_expr_action_cur FOR
		SELECT quick_survey_expr_action_id, action_type, survey_sid, expr_id,
			   qs_expr_non_compl_action_id, qs_expr_msg_action_id,
			   show_question_id, show_question_version, survey_version,
			   mandatory_question_id, mandatory_question_version,
			   show_page_id, show_page_version,
			   issue_template_id
		  FROM quick_survey_expr_action;

	OPEN out_qs_filter_condition_cur FOR
		SELECT filter_id, qs_filter_condition_id, question_id, question_version,
			   comparator, compare_to_str_val, compare_to_num_val,
			   compare_to_option_id, survey_version, qs_campaign_sid,
			   pos, survey_sid
		  FROM qs_filter_condition;

	OPEN out_qs_expr_nc_act_role_cur FOR
		SELECT qs_expr_non_compl_action_id, involve_role_sid
		  FROM qs_expr_nc_action_involve_role;
END;

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
)
AS
BEGIN
	OPEN out_nc_cur FOR
		SELECT non_compliance_id, created_in_audit_sid, from_non_comp_default_id, label, detail,
			   created_dtm, created_by_user_sid, non_compliance_type_id, is_closed, override_score,
			   root_cause, region_sid, suggested_action, question_id, question_version,
			   non_compliance_ref, question_option_id
		  FROM non_compliance;

	OPEN out_nc_ea_cur FOR
		SELECT non_compliance_id, qs_expr_non_compl_action_id, survey_response_id
		  FROM non_compliance_expr_action;

	OPEN out_nc_file_upload_cur FOR
		SELECT non_compliance_file_id, non_compliance_id, filename, mime_type, data, sha1, uploaded_dtm
		  FROM non_compliance_file;

	OPEN out_nc_tag_cur FOR
		SELECT tag_id, non_compliance_id
		  FROM non_compliance_tag;

	OPEN out_aud_nc_cur FOR
		SELECT internal_audit_sid, non_compliance_id, audit_non_compliance_id, repeat_of_audit_nc_id,
			   attached_to_primary_survey, internal_audit_type_survey_id
		  FROM audit_non_compliance;

	OPEN out_nc_type_cur FOR
		SELECT non_compliance_type_id, label, lookup_key, position, colour_when_open,
		       colour_when_closed, can_have_actions, closure_behaviour_id,
			   score, repeat_score, root_cause_enabled, suggested_action_enabled,
			   inter_non_comp_ref_helper_func, inter_non_comp_ref_prefix,
			   match_repeats_by_carry_fwd, match_repeats_by_default_ncs, match_repeats_by_surveys,
			   find_repeats_in_unit, find_repeats_in_qty, carry_fwd_repeat_type,
			   is_default_survey_finding
		  FROM non_compliance_type;

	OPEN out_nc_type_tag_group_cur FOR
		SELECT non_compliance_type_id, tag_group_id
		  FROM non_compliance_type_tag_group;

	OPEN out_nc_type_audit_type_cur FOR
		SELECT internal_audit_type_id, non_compliance_type_id
		  FROM non_comp_type_audit_type;

	OPEN out_nc_type_rpt_audit_type_cur FOR
		SELECT internal_audit_type_id, non_compliance_type_id
		  FROM non_comp_type_rpt_audit_type;
		  
	OPEN out_nc_type_flow_cap FOR	  
		SELECT non_compliance_type_id, flow_capability_id, base_flow_capability_id
		  FROM non_compliance_type_flow_cap;
END;

PROCEDURE GetNonComplianceDefaults(
	non_comp_default_cur			OUT SYS_REFCURSOR,
	non_comp_default_issue_cur		OUT SYS_REFCURSOR,
	audit_type_non_comp_def_cur		OUT SYS_REFCURSOR,
	non_comp_def_folder_cur			OUT SYS_REFCURSOR,
	non_comp_def_tag_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN non_comp_default_cur FOR
		SELECT non_comp_default_id, label, detail, non_compliance_type_id, root_cause,
			   suggested_action, non_comp_default_folder_id, unique_reference
		  FROM non_comp_default;

	OPEN non_comp_default_issue_cur FOR
		SELECT non_comp_default_issue_id, non_comp_default_id, label, description,
			   due_dtm_relative, due_dtm_relative_unit
		  FROM non_comp_default_issue;

	OPEN audit_type_non_comp_def_cur FOR
		SELECT internal_audit_type_id, non_comp_default_id
		  FROM audit_type_non_comp_default;

	OPEN non_comp_def_folder_cur FOR
		SELECT non_comp_default_folder_id, parent_folder_id, label
		  FROM non_comp_default_folder;

	OPEN non_comp_def_tag_cur FOR
		SELECT non_comp_default_id, tag_id
		  FROM non_comp_default_tag;
END;

PROCEDURE GetInternalAudit(
	out_internal_audit_type_cur		OUT	SYS_REFCURSOR,
	out_ia_type_carry_fwd_cur		OUT	SYS_REFCURSOR,
	out_ia_type_tag_group_cur		OUT	SYS_REFCURSOR,
	out_audit_closure_type_cur		OUT	SYS_REFCURSOR,
	out_audit_type_cl_type_cur		OUT	SYS_REFCURSOR,
	out_ia_cur						OUT	SYS_REFCURSOR,
	out_ia_tag_cur					OUT	SYS_REFCURSOR,
	out_ia_postit_cur				OUT	SYS_REFCURSOR,
	out_region_ia_cur				OUT	SYS_REFCURSOR,
	out_audit_alert_cur				OUT	SYS_REFCURSOR,
	out_int_audit_file_data_cur		OUT	SYS_REFCURSOR,
	out_audit_type_alert_role_cur	OUT	SYS_REFCURSOR,
	out_audit_type_tab_cur			OUT	SYS_REFCURSOR,
	out_audit_type_header_cur		OUT	SYS_REFCURSOR,
	out_internal_audit_file_cur		OUT	SYS_REFCURSOR,
	out_audit_type_group_cur		OUT	SYS_REFCURSOR,
	out_flow_state_audit_ind_cur	OUT	SYS_REFCURSOR,
	out_adt_tp_flow_inv_tp_cur		OUT	SYS_REFCURSOR,
	out_ia_type_survey_group_cur	OUT	SYS_REFCURSOR,
	out_ia_type_survey_cur			OUT	SYS_REFCURSOR,
	out_internal_audit_survey_cur	OUT	SYS_REFCURSOR,
	out_internal_audit_type_re_cur	OUT	SYS_REFCURSOR,
	out_ia_type_report_group_cur 	OUT SYS_REFCURSOR,
	out_internal_audit_score_cur	OUT SYS_REFCURSOR,
	out_ia_locked_tag_cur			OUT SYS_REFCURSOR,
	out_ia_listener_last_update		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_internal_audit_type_cur FOR
		SELECT internal_audit_type_id, label, every_n_months, auditor_role_sid,
			   audit_contact_role_sid, default_survey_sid,
			   lookup_key, default_auditor_org, override_issue_dtm,
			   assign_issues_to_role, auditor_can_take_ownership, flow_sid,
			   internal_audit_type_source_id, summary_survey_sid, send_auditor_expiry_alerts,
			   tab_sid, form_path, form_sid, internal_audit_type_group_id, internal_audit_ref_helper_func,
			   nc_score_type_id, show_primary_survey_in_header, primary_survey_active,
			   primary_survey_label, primary_survey_mandatory, primary_survey_fixed,
			   primary_survey_group_key, add_nc_per_question, active, validity_months,
			   nc_audit_child_region, audit_coord_role_or_group_sid,
			   use_legacy_closed_definition, involve_auditor_in_issues
		  FROM internal_audit_type;

	OPEN out_ia_type_carry_fwd_cur FOR
		SELECT from_internal_audit_type_id, to_internal_audit_type_id
		  FROM internal_audit_type_carry_fwd;

	OPEN out_ia_type_tag_group_cur FOR
		SELECT internal_audit_type_id, tag_group_id
		  FROM internal_audit_type_tag_group;

	OPEN out_audit_closure_type_cur FOR
		SELECT act.audit_closure_type_id, act.label, act.icon_image, act.icon_image_filename,
			   act.icon_image_mime_type, act.icon_image_sha1, act.is_failure, act.lookup_key
		  FROM audit_closure_type act;

	OPEN out_audit_type_cl_type_cur FOR
		SELECT atct.internal_audit_type_id, atct.audit_closure_type_id, atct.re_audit_due_after,
			   atct.re_audit_due_after_type, atct.reminder_offset_days, atct.reportable_for_months,
			   atct.ind_sid, atct.manual_expiry_date
		  FROM audit_type_closure_type atct;

	OPEN out_ia_cur FOR
		SELECT internal_audit_sid, internal_audit_type_id, survey_sid, region_sid,
			   label, audit_dtm, created_by_user_sid, created_dtm, auditor_user_sid,
			   notes, audit_contact_user_sid, survey_response_id, auditor_name,
			   auditor_organisation, audit_closure_type_id, flow_item_id, summary_response_id,
			   deleted, expired, internal_audit_ref, nc_score, comparison_response_id,
			   auditor_company_sid, ovw_validity_dtm, nc_score_thrsh_id, ovw_nc_score_thrsh_id,
			   ovw_nc_score_thrsh_dtm, ovw_nc_score_thrsh_usr_sid, auditee_user_sid, permit_id,
			   external_audit_ref, external_parent_ref, external_url
	  	  FROM internal_audit;

	OPEN out_ia_tag_cur FOR
		SELECT internal_audit_sid, tag_id
		  FROM internal_audit_tag;

	OPEN out_ia_postit_cur FOR
		SELECT internal_audit_sid, postit_id
		  FROM internal_audit_postit;

	OPEN out_region_ia_cur FOR
		SELECT internal_audit_type_id, region_sid, next_audit_dtm
		  FROM region_internal_audit;

	OPEN out_audit_alert_cur FOR
		SELECT internal_audit_sid, csr_user_sid, reminder_sent_dtm, overdue_sent_dtm
		  FROM audit_alert;

	OPEN out_int_audit_file_data_cur FOR
		SELECT internal_audit_file_data_id, filename, mime_type, data,
		       sha1, uploaded_dtm
		  FROM internal_audit_file_data;

	OPEN out_audit_type_alert_role_cur FOR
		SELECT internal_audit_type_id, role_sid
		  FROM audit_type_expiry_alert_role;

	OPEN out_audit_type_tab_cur FOR
		SELECT internal_audit_type_id, plugin_type_id, plugin_id, pos, tab_label, flow_capability_id
		  FROM audit_type_tab;

	OPEN out_audit_type_header_cur FOR
		SELECT internal_audit_type_id, plugin_type_id, plugin_id, pos
		  FROM audit_type_header;

	OPEN out_internal_audit_file_cur FOR
		SELECT internal_audit_sid, internal_audit_file_data_id
		  FROM internal_audit_file;

	OPEN out_audit_type_group_cur FOR
		SELECT internal_audit_type_group_id, label, lookup_key,
			   internal_audit_ref_prefix, auditor_name_label, issue_type_id,
			   applies_to_regions, applies_to_users, use_user_primary_region,
			   audit_singular_label, audit_plural_label, auditee_user_label, auditor_user_label,
			   audits_menu_sid, new_audit_menu_sid, non_compliances_menu_sid,
			   block_css_class, applies_to_permits
		  FROM internal_audit_type_group;

	OPEN out_flow_state_audit_ind_cur FOR
		SELECT ind_sid, flow_state_id, flow_state_audit_ind_type_id, internal_audit_type_id
		  FROM flow_state_audit_ind;

	OPEN out_adt_tp_flow_inv_tp_cur FOR
		SELECT audit_type_flow_inv_type_id, flow_involvement_type_id, internal_audit_type_id,
			   min_users, max_users, users_role_or_group_sid
		  FROM audit_type_flow_inv_type;

	OPEN out_ia_type_survey_group_cur FOR
		SELECT ia_type_survey_group_id,
			   survey_capability_id,
			   change_survey_capability_id,
			   label,
			   lookup_key
		  FROM ia_type_survey_group;

	OPEN out_ia_type_survey_cur FOR
		SELECT internal_audit_type_survey_id,
			   active,
			   default_survey_sid,
			   ia_type_survey_group_id,
			   internal_audit_type_id,
			   label,
			   mandatory,
			   survey_fixed,
			   survey_group_key
		  FROM internal_audit_type_survey;

	OPEN out_internal_audit_survey_cur FOR
		SELECT internal_audit_sid,
			   internal_audit_type_survey_id,
			   survey_response_id,
			   survey_sid
		  FROM internal_audit_survey;

	OPEN out_internal_audit_type_re_cur FOR
		SELECT internal_audit_type_report_id,
			   internal_audit_type_id,
			   word_doc,
			   report_filename,
			   label,
			   ia_type_report_group_id,
			   use_merge_field_guid,
			   guid_expiration_days
		  FROM csr.internal_audit_type_report;

	OPEN out_ia_type_report_group_cur FOR
		SELECT ia_type_report_group_id,
			   label
		  FROM csr.ia_type_report_group;

	OPEN out_internal_audit_score_cur FOR
		SELECT internal_audit_sid,
			   score_type_id,
			   score,
			   score_threshold_id
		  FROM internal_audit_score;

	OPEN out_ia_locked_tag_cur FOR
		SELECT internal_audit_sid,
			   tag_group_id,
			   tag_id
		  FROM csr.internal_audit_locked_tag;

	OPEN out_ia_listener_last_update FOR
		SELECT tenant_id,
			   external_parent_ref,
			   external_ref,
			   last_update,
			   correlation_id
		  FROM csr.internal_audit_listener_last_update;

END;

PROCEDURE GetRegionMetrics(
	out_region_type_metric_cur		OUT	SYS_REFCURSOR,
	out_region_metric_cur			OUT	SYS_REFCURSOR,
	out_region_metric_val_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_region_type_metric_cur FOR
		SELECT region_type, ind_sid
		  FROM region_type_metric;

	OPEN out_region_metric_cur FOR
		SELECT measure_sid, ind_sid, is_mandatory, show_measure
		  FROM region_metric;

	OPEN out_region_metric_val_cur FOR
		SELECT ind_sid, region_sid, effective_dtm, entered_by_sid, entered_dtm, val, note, region_metric_val_id,
			   measure_sid, source_type_id, entry_measure_conversion_id, entry_val
		  FROM region_metric_val;
END;

PROCEDURE GetFunds(
	out_mgmt_companies_cur			OUT SYS_REFCURSOR,
	out_mgmt_co_contact_cur			OUT SYS_REFCURSOR,
	out_fund_type_cur				OUT	SYS_REFCURSOR,
	out_funds_cur					OUT	SYS_REFCURSOR,
	out_fund_form_plugin_cur		OUT	SYS_REFCURSOR,
	out_mgmt_co_fund_contact_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_mgmt_companies_cur FOR
		SELECT mgmt_company_id, name, company_sid
		  FROM mgmt_company;

	OPEN out_mgmt_co_contact_cur FOR
		SELECT mgmt_company_contact_id,
			   name, email, phone, mgmt_company_id
		  FROM mgmt_company_contact;

	OPEN out_fund_type_cur FOR
		SELECT fund_type_id, label
		  FROM fund_type;

	OPEN out_funds_cur FOR
		SELECT fund_id, company_sid, name, year_of_inception,
			   fund_type_id, default_mgmt_company_id,
			   mgr_contact_name, mgr_contact_email, mgr_contact_phone,
			   region_sid
		  FROM fund;

	OPEN out_fund_form_plugin_cur FOR
		SELECT plugin_id, pos, xml_path, key_name
		  FROM fund_form_plugin;

	OPEN out_mgmt_co_fund_contact_cur FOR
		SELECT fund_id, mgmt_company_contact_id, mgmt_company_id
		  FROM mgmt_company_fund_contact;
END;

PROCEDURE GetPropertyOptions(
	out_property_options_cur		OUT	SYS_REFCURSOR,
	out_property_el_layout_cur		OUT	SYS_REFCURSOR,
	out_property_addr_options_cur	OUT	SYS_REFCURSOR,
	out_property_tabs_cur			OUT SYS_REFCURSOR,
	out_prop_type_prop_tab_cur		OUT SYS_REFCURSOR,
	out_property_tab_groups_cur		OUT SYS_REFCURSOR,
	out_property_char_layout_cur	OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_property_options_cur FOR
		SELECT property_helper_pkg, properties_geo_map_sid, enable_multi_fund_ownership,
			  gresb_service_config, auto_assign_manager, show_inherited_roles
		  FROM property_options;

	OPEN out_property_el_layout_cur FOR
		SELECT element_name, pos, ind_sid, tag_group_id
		  FROM property_element_layout;

	OPEN out_property_addr_options_cur FOR
		SELECT element_name, mandatory
		  FROM property_address_options;

	OPEN out_property_tabs_cur FOR
		SELECT plugin_id, plugin_type_id, pos, tab_label
		  FROM property_tab;

	OPEN out_prop_type_prop_tab_cur FOR
		SELECT plugin_id, property_type_id
		  FROM prop_type_prop_tab;

	OPEN out_property_tab_groups_cur FOR
		SELECT plugin_id, group_sid, role_sid
		  FROM property_tab_group;

	OPEN out_property_char_layout_cur FOR
		SELECT element_name, pos, col, ind_sid, tag_group_id
		  FROM property_character_layout;
END;

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
)
AS
BEGIN
	OPEN out_property_type_cur FOR
		SELECT property_type_id, label, lookup_key, gresb_property_type_id
		  FROM property_type;

	OPEN out_property_sub_type_cur FOR
		SELECT property_sub_type_id, property_type_id, label, gresb_property_type_id, gresb_property_sub_type_id
		  FROM property_sub_type;

	OPEN out_space_type_cur FOR
		SELECT space_type_id, label, is_tenantable
		  FROM space_type;

	OPEN out_space_type_rgn_metric_cur FOR
		SELECT space_type_id, ind_sid, region_type
		  FROM space_type_region_metric;

	OPEN out_prop_type_space_type_cur FOR
		SELECT property_type_id,
			   space_type_id,
			   is_hidden
		  FROM property_type_space_type;

	OPEN out_properties_cur FOR
		SELECT region_sid, street_addr_1, city, state, postcode,
			   flow_item_id, street_addr_2, property_type_id,
			   company_sid, property_sub_type_id
			   mgmt_company_id, mgmt_company_other, pm_building_id,
			   current_lease_id, mgmt_company_contact_id
		  FROM all_property;

	OPEN out_space_cur FOR
		SELECT region_sid, space_type_id,
			   property_region_sid, property_type_id, current_lease_id
		  FROM space;

	OPEN out_photos_cur FOR
		SELECT property_photo_id, property_region_sid, space_region_sid,
			   filename, mime_type, data
		  FROM property_photo;

	OPEN out_property_funds FOR
		SELECT region_sid, fund_id, container_sid
		  FROM property_fund;

	OPEN out_reg_score_log_cur FOR
		SELECT region_score_log_id, region_sid, score_type_id, score_threshold_id, score, set_dtm, changed_by_user_sid, comment_text
		  FROM region_score_log;

	OPEN out_reg_score_cur FOR
		SELECT score_type_id, region_sid, last_region_score_log_id
		  FROM region_score;

	OPEN out_property_mandatory_roles FOR
		SELECT role_sid
		  FROM property_mandatory_roles;

	OPEN out_property_fund_ownership FOR
		SELECT region_sid, fund_id, start_dtm, ownership
		  FROM property_fund_ownership;
END;

PROCEDURE GetPropertiesDashboards(
	out_benchmark_dashb_cur			OUT	SYS_REFCURSOR,
	out_benchmark_dashb_char_cur	OUT	SYS_REFCURSOR,
	out_benchmark_dashb_ind_cur		OUT	SYS_REFCURSOR,
	out_benchmark_dashb_plugin_cur	OUT	SYS_REFCURSOR,
	out_metric_dashb_cur			OUT	SYS_REFCURSOR,
	out_metric_dashb_ind_cur		OUT	SYS_REFCURSOR,
	out_metric_dashb_plugin_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_benchmark_dashb_cur FOR
		SELECT benchmark_dashboard_sid, name, start_dtm, end_dtm, lookup_key, period_set_id, period_interval_id
		  FROM benchmark_dashboard;
	OPEN out_benchmark_dashb_char_cur FOR
		SELECT benchmark_dashboard_sid, benchmark_dashboard_char_id, pos, ind_sid, tag_group_id
		  FROM benchmark_dashboard_char;
	OPEN out_benchmark_dashb_ind_cur FOR
		SELECT benchmark_dashboard_sid, ind_sid, display_name, scenario_run_sid, floor_area_ind_sid, pos
		  FROM benchmark_dashboard_ind;
	OPEN out_benchmark_dashb_plugin_cur FOR
		SELECT benchmark_dashboard_sid, plugin_id
		  FROM benchmark_dashboard_plugin;
	OPEN out_metric_dashb_cur FOR
		SELECT metric_dashboard_sid, name, start_dtm, end_dtm, lookup_key, period_set_id, period_interval_id
		  FROM metric_dashboard;
	OPEN out_metric_dashb_ind_cur FOR
		SELECT metric_dashboard_sid, ind_sid, pos, block_title, block_css_class, inten_view_scenario_run_sid, inten_view_floor_area_ind_sid, absol_view_scenario_run_sid
		  FROM metric_dashboard_ind;
	OPEN out_metric_dashb_plugin_cur FOR
		SELECT metric_dashboard_sid, plugin_id
		  FROM metric_dashboard_plugin;
END;

PROCEDURE GetGresbConfig(
	out_gresb_indicator_map_cur		OUT	SYS_REFCURSOR,
	out_gresb_submission_log_cur	OUT	SYS_REFCURSOR,
	out_property_gresb_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_gresb_indicator_map_cur FOR
		SELECT gresb_indicator_id, ind_sid, measure_conversion_id, not_applicable
		  FROM gresb_indicator_mapping
		  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_gresb_submission_log_cur FOR
		SELECT gresb_submission_id, gresb_response_id, gresb_entity_id, gresb_asset_id, submission_type, submission_date, request_data, response_data
		  FROM gresb_submission_log
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_property_gresb_cur FOR
		SELECT region_sid, asset_id
		  FROM property_gresb
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetCurrencies(
	out_currencies_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_currencies_cur FOR
		SELECT currency_code
		  FROM currency;
END;

PROCEDURE GetLeases(
	out_tenant_cur					OUT SYS_REFCURSOR,
	out_lease_type_cur				OUT SYS_REFCURSOR,
	out_lease_cur					OUT SYS_REFCURSOR,
	out_lease_postit_cur			OUT SYS_REFCURSOR,
	out_lease_property_cur			OUT SYS_REFCURSOR,
	out_lease_space_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_tenant_cur FOR
		SELECT tenant_id, name
		  FROM tenant;

	OPEN out_lease_type_cur FOR
		SELECT lease_type_id
		  FROM lease_type;

	OPEN out_lease_cur FOR
		SELECT lease_id, start_dtm, end_dtm, next_break_dtm,
			   current_rent, normalised_rent, next_rent_review,
			   tenant_id, currency_code
		  FROM lease;

	OPEN out_lease_postit_cur FOR
		SELECT lease_id, postit_id
		  FROM lease_postit;

	OPEN out_lease_property_cur FOR
		SELECT lease_id, property_region_sid
		  FROM lease_property;

	OPEN out_lease_space_cur FOR
		SELECT lease_id, space_region_sid
		  FROM lease_space;
END;

PROCEDURE GetAuditLog(
	out_audit_log_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_audit_log_cur FOR
		SELECT audit_date, audit_type_id, object_sid, user_sid, description, param_1,
			   param_2, param_3, sub_object_id, remote_addr
		  FROM audit_log;
END;

PROCEDURE GetSysTranslationsAudit(
	out_sys_trans_audit_log_cur				OUT	SYS_REFCURSOR,
	out_sys_trans_audit_data_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_sys_trans_audit_log_cur FOR
		SELECT sys_translations_audit_log_id, audit_date, app_sid, translated_id, user_sid, description
		  FROM sys_translations_audit_log;
	OPEN out_sys_trans_audit_data_cur FOR
		SELECT sys_translations_audit_log_id, audit_date, app_sid, is_delete, original, translation, old_translation
		  FROM sys_translations_audit_data;
END;

PROCEDURE GetExportFeed(
	out_export_feed_cur				OUT	SYS_REFCURSOR,
	out_ef_cms_form_cur				OUT	SYS_REFCURSOR,
	out_ef_dataview_cur				OUT	SYS_REFCURSOR,
	out_ef_stored_proc_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_export_feed_cur FOR
		SELECT export_feed_sid, name, protocol, url, interval,
			   start_dtm, end_dtm, last_success_attempt_dtm, last_attempt_dtm, secure_creds
		  FROM export_feed;

	OPEN out_ef_cms_form_cur FOR
		SELECT export_feed_sid, form_sid, filename_mask, format, incremental
		  FROM export_feed_cms_form;

	OPEN out_ef_dataview_cur FOR
		SELECT export_feed_sid, dataview_sid, filename_mask, format, assembly_name
		  FROM export_feed_dataview efd, TABLE(m_dataview_sids) ds
  	     WHERE efd.dataview_sid = ds.column_value;

	OPEN out_ef_stored_proc_cur FOR
		SELECT export_feed_sid, sp_name, sp_params, filename_mask, format
		  FROM export_feed_stored_proc;
END;

PROCEDURE GetPlugins(
	out_plugin_cur					OUT SYS_REFCURSOR,
	out_plugin_ind_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_plugin_cur FOR
		SELECT plugin_id, cs_class, description, js_class, js_include, plugin_type_id,
		       app_sid, details, preview_image_path, tab_sid, form_path, group_key,
			   control_lookup_keys, saved_filter_sid, result_mode, portal_sid,
			   use_reporting_period, r_script_path, form_sid, pre_filter_sid
		  FROM plugin;

	OPEN out_plugin_ind_cur FOR
		SELECT plugin_indicator_id, plugin_id, lookup_key, label, pos
		  FROM plugin_indicator
         WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetSuppliers(
	out_supplier_score_log_cur 		OUT SYS_REFCURSOR,
	out_supplier_score_cur 			OUT SYS_REFCURSOR,
	out_supplier_cur 				OUT SYS_REFCURSOR,
	out_sup_survey_resp_cur			OUT SYS_REFCURSOR,
	out_issue_supplier_cur			OUT	SYS_REFCURSOR,
	out_supplier_delegation_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_supplier_score_log_cur FOR
		SELECT supplier_score_id,
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
		  FROM supplier_score_log;

	OPEN out_supplier_score_cur  FOR
		SELECT score_type_id, company_sid, last_supplier_score_id
		  FROM current_supplier_score;

	OPEN out_supplier_cur FOR
		SELECT company_sid,
			   logo_file_sid,
			   recipient_sid,
			   region_sid,
			   default_region_mount_sid
		  FROM supplier;

	OPEN out_sup_survey_resp_cur FOR
		SELECT supplier_sid, survey_sid, survey_response_id, component_id
		  FROM supplier_survey_response;

	OPEN out_issue_supplier_cur FOR
		SELECT issue_supplier_id, company_sid, qs_expr_non_compl_action_id
		  FROM issue_supplier;

	OPEN out_supplier_delegation_cur FOR
		SELECT supplier_sid,
			   tpl_delegation_sid,
			   delegation_sid
		  FROM supplier_delegation;
END;

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
)
AS
BEGIN
	OPEN out_chain_capability_cur FOR
		SELECT capability_id,
			   capability_name,
			   capability_type_id,
			   is_supplier,
			   perm_type,
			   supplier_on_purchaser
		  FROM chain.capability;

	OPEN out_chain_capability_flow_cur FOR
		SELECT flow_capability_id,
			   capability_id
		  FROM chain.capability_flow_capability;

	OPEN out_chain_customer_options_cur FOR
		SELECT activity_mail_account_sid,
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
			   invitation_expiration_rem_days,
			   invitation_expiration_rem,
			   country_risk_enabled,
			   filter_cache_timeout,
			   show_map_on_supplier_list,
			   force_login_as_company,
			   show_extra_details_in_graph,
			   enable_dedupe_onboarding,
			   create_one_flow_item_for_comp,
			   show_audit_coordinator,
			   prevent_relationship_loops,
			   allow_duplicate_emails,
			   company_geotag_enabled
		  FROM chain.customer_options;

	OPEN out_chain_company_type_cur FOR
		SELECT company_type_id, allow_lower_case, css_class, is_default, is_top_company, lookup_key,
			   plural, position, singular, user_group_sid, user_role_sid, use_user_role, default_region_type,
			   region_root_sid, default_region_layout, create_subsids_under_parent, create_doc_library_folder
		  FROM chain.company_type;

	OPEN out_chain_company_cur FOR
		SELECT company_sid,
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
			   email,
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
			   requested_by_company_sid,
			   requested_by_user_sid,
			   pending,
			   signature
		  FROM chain.company;

	OPEN out_cacc_cur FOR
		SELECT company_sid,
			   group_capability_id,
			   permission_set
		  FROM chain.applied_company_capability;

	OPEN out_chain_chain_user_cur FOR
		SELECT user_sid,
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
		  FROM chain.chain_user;

	OPEN out_chain_company_group_cur FOR
		SELECT company_sid,
			   company_group_type_id,
			   group_sid
		  FROM chain.company_group;

	OPEN out_cctr_cur FOR
		SELECT primary_company_type_id,
			   secondary_company_type_id,
			   use_user_roles,
			   hidden,
			   flow_sid,
			   follower_role_sid,
			   can_be_primary
		  FROM chain.company_type_relationship;

	OPEN out_cctc_cur FOR
		SELECT capability_id,
			   permission_set,
			   primary_company_group_type_id,
			   primary_company_type_id,
			   secondary_company_type_id,
			   tertiary_company_type_id,
			   primary_company_type_role_sid
		  FROM chain.company_type_capability;

	OPEN out_cgco_cur FOR
		SELECT group_capability_id,
			   hide_group_capability,
			   permission_set_override
		  FROM chain.group_capability_override;

	OPEN out_chain_implementation_cur FOR
		SELECT execute_order,
			   link_pkg,
			   name
		  FROM chain.implementation;

	OPEN out_chain_sector_cur FOR
		SELECT sector_id,
			   active,
			   description,
			   is_other,
			   parent_sector_id
		  FROM chain.sector;

	OPEN out_ctr_cur FOR
		SELECT primary_company_type_id,
			   secondary_company_type_id,
			   tertiary_company_type_id
		  FROM chain.tertiary_relationships;

	OPEN out_chain_ct_role_cur FOR
		SELECT company_type_role_id,
			   company_type_id,
			   role_sid,
			   mandatory,
			   cascade_to_supplier,
			   pos
		  FROM chain.company_type_role;

	OPEN out_chain_suppl_relat_cur FOR
		SELECT purchaser_company_sid,
			   supplier_company_sid,
			   active,
			   deleted,
			   virtually_active_until_dtm,
			   virtually_active_key,
			   supp_rel_code,
			   flow_item_id,
			   is_primary
		  FROM chain.supplier_relationship;
	
	OPEN out_chain_supp_rel_src_cur FOR
		SELECT purchaser_company_sid,
			   supplier_company_sid,
			   source_type,
			   object_id
		  FROM chain.supplier_relationship_source;
	
	OPEN out_csrs_cur FOR
		SELECT purchaser_company_sid,
			   supplier_company_sid,
			   score_threshold_id,
			   set_dtm,
			   score,
			   score_type_id,
			   changed_by_user_sid,
			   valid_until_dtm,
			   score_source_type,
			   score_source_id
		  FROM chain.supplier_relationship_score;
		 
	OPEN out_chain_suppl_follower_cur FOR
		SELECT purchaser_company_sid,
			   supplier_company_sid,
			   user_sid,
			   is_primary
		  FROM chain.supplier_follower;

	OPEN out_chain_risk_level_cur FOR
		SELECT risk_level_id,
			   label,
			   lookup_key
		  FROM chain.risk_level;

	OPEN out_chain_country_risk_lvl_cur FOR
		SELECT country,
			   risk_level_id,
			   start_dtm
		  FROM chain.country_risk_level;

	OPEN out_chain_tpl_delegation_cur FOR
		SELECT tpl_delegation_sid
		  FROM chain_tpl_delegation;

	OPEN out_cctsc_cur FOR
		SELECT company_type_id,
			   score_type_id,
			   calc_type,
			   operator_type,
			   supplier_score_type_id,
			   active_suppliers_only
		  FROM chain.company_type_score_calc;

	OPEN out_cctscct_cur FOR
		SELECT company_type_id,
			   score_type_id,
			   supplier_company_type_id
		  FROM chain.comp_type_score_calc_comp_type;
	
	OPEN out_supplier_involvement_type FOR
		SELECT flow_involvement_type_id,
			user_company_type_id,
			page_company_type_id,
			purchaser_type,
			restrict_to_role_sid
		FROM chain.supplier_involvement_type;
END;

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
)
AS
BEGIN

	OPEN out_chain_project_cur FOR
		SELECT project_id,
			   name
		  FROM chain.project;

	OPEN out_chain_activity_type_cur FOR
		SELECT activity_type_id,
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
		  FROM chain.activity_type;

	OPEN out_chain_outcome_type_cur FOR
		SELECT outcome_type_id,
			   is_deferred,
			   is_failure,
			   is_success,
			   label,
			   lookup_key,
			   require_reason
		  FROM chain.outcome_type;

	OPEN out_caot_cur FOR
		SELECT activity_type_id,
			   outcome_type_id
		  FROM chain.activity_outcome_type;

	OPEN out_chain_activity_cur FOR
		SELECT activity_id,
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
		  FROM chain.activity;

	OPEN out_chain_activity_log_cur FOR
		SELECT activity_log_id,
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
		  FROM chain.activity_log;

	OPEN out_chain_act_log_file_cur FOR
		SELECT activity_log_file_id,
			   activity_log_id,
			   data,
			   filename,
			   mime_type,
			   sha1,
			   uploaded_dtm
		  FROM chain.activity_log_file;

	OPEN out_cattg_cur FOR
		SELECT activity_type_id,
			   tag_group_id
		  FROM chain.activity_type_tag_group;

	OPEN out_chain_activity_invl_cur FOR
		SELECT activity_id,
			   user_sid,
			   role_sid,
			   added_by_sid,
			   added_dtm
		  FROM chain.activity_involvement;

	OPEN out_chain_activity_tag_cur FOR
		SELECT activity_id,
			   tag_id,
			   activity_type_id,
			   tag_group_id
		  FROM chain.activity_tag;

	OPEN out_cata_cur FOR
		SELECT activity_type_action_id,
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
		  FROM chain.activity_type_action;

	OPEN out_chain_act_out_type_act_cur FOR
		SELECT activity_outcome_typ_action_id,
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
		  FROM chain.activity_outcome_type_action;

	OPEN out_cata1_cur FOR
		SELECT activity_type_id,
			   customer_alert_type_id,
			   allow_manual_editing,
			   label,
			   use_supplier_company,
			   send_to_target,
			   send_to_assignee
		  FROM chain.activity_type_alert;

	OPEN out_catar_cur FOR
		SELECT activity_type_id,
			   customer_alert_type_id,
			   role_sid
		  FROM chain.activity_type_alert_role;

	OPEN out_catdu_cur FOR
		SELECT activity_type_id,
			   user_sid
		  FROM chain.activity_type_default_user;
END;

PROCEDURE GetChainCards(
	out_chain_card_cur OUT SYS_REFCURSOR,
	out_chain_card_group_card_cur OUT SYS_REFCURSOR,
	out_chain_card_group_progr_cur OUT SYS_REFCURSOR,
	out_chain_card_init_param_cur OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_chain_card_cur FOR
		SELECT card_id,
			description,
			class_type,
			js_class_type,
			js_include,
			css_include
		  FROM chain.card;

	OPEN out_chain_card_group_card_cur FOR
		SELECT card_group_id,
			card_id,
			position,
			required_permission_set,
			required_capability_id,
			invert_capability_check,
			force_terminate
		  FROM chain.card_group_card;

	OPEN out_chain_card_group_progr_cur FOR
		SELECT card_group_id,
			from_card_id,
			from_card_action,
			to_card_id
		  FROM chain.card_group_progression;

	OPEN out_chain_card_init_param_cur FOR
		SELECT card_id,
			param_type_id,
			key,
			value,
			card_group_id
		  FROM chain.card_init_param;
END;

PROCEDURE GetChainProducts(
	out_chain_product_type_cur 			OUT SYS_REFCURSOR,
	out_chain_product_type_tr_cur 		OUT SYS_REFCURSOR,
	out_chain_comp_prod_type_cur 		OUT SYS_REFCURSOR,
	out_chain_product_type_tag_cur 		OUT SYS_REFCURSOR,
	out_chain_product_metric_cur		OUT SYS_REFCURSOR,
	out_chain_prd_mtrc_prd_typ_cur		OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_chain_product_type_cur FOR
		SELECT product_type_id, parent_product_type_id, label, lookup_key
		  FROM chain.product_type;

	OPEN out_chain_product_type_tr_cur FOR
		SELECT product_type_id, lang, description, last_changed_dtm_description
		  FROM chain.product_type_tr;

	OPEN out_chain_comp_prod_type_cur FOR
		SELECT company_sid, product_type_id
		  FROM chain.company_product_type;

	OPEN out_chain_product_type_tag_cur FOR
		SELECT product_type_id, tag_id
		  FROM chain.product_type_tag;

	OPEN out_chain_product_metric_cur FOR
		SELECT ind_sid, applies_to_product, applies_to_prod_supplier, product_metric_icon_id, is_mandatory, show_measure 
		  FROM chain.product_metric;

	OPEN out_chain_prd_mtrc_prd_typ_cur FOR
		SELECT ind_sid, product_type_id
		  FROM chain.product_metric_product_type;
END;

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
)
AS
BEGIN
	OPEN out_chain_amount_unit_cur FOR
		SELECT amount_unit_id,
			   conversion_to_base,
			   description,
			   unit_type
		  FROM chain.amount_unit;

	OPEN out_ccueal_cur FOR
		SELECT email,
			   last_modified_dtm,
			   modified_by_sid,
			   user_sid
		  FROM chain.chain_user_email_address_log;

	OPEN out_cdpct_cur FOR
		SELECT code_label1,
			   code_label2,
			   code_label3
		  FROM chain.default_product_code_type;

	OPEN out_cdsrcl_cur FOR
		SELECT label,
			   mandatory
		  FROM chain.default_supp_rel_code_label;

	OPEN out_chain_email_stub_cur FOR
		SELECT company_sid,
			   lower_stub,
			   stub
		  FROM chain.email_stub;

	OPEN out_chain_ucd_logon_cur FOR
		SELECT ucd_act_id,
			   previous_act_id,
			   previous_company_sid,
			   previous_user_sid
		  FROM chain.ucd_logon;

	OPEN out_chain_url_overrides_cur FOR
		SELECT host,
			   key,
			   site_name,
			   support_email
		  FROM chain.url_overrides;

	OPEN out_chain_certification_cur FOR
		SELECT certification_type_id,
			   label,
			   lookup_key,
			   product_requirement_type_id
		  FROM chain.certification_type;

	OPEN out_chain_cert_aud_type_cur FOR
		SELECT certification_type_id,
			   internal_audit_type_id
		  FROM chain.cert_type_audit_type;
END;

PROCEDURE GetChainAudits (
	out_chain_audit_request_cur OUT SYS_REFCURSOR,
	out_cara_cur OUT SYS_REFCURSOR,
	out_chain_supplier_audit_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_chain_audit_request_cur FOR
		SELECT audit_request_id,
			   auditee_company_sid,
			   auditor_company_sid,
			   audit_sid,
			   notes,
			   proposed_dtm,
			   requested_at_dtm,
			   requested_by_company_sid,
			   requested_by_user_sid
		  FROM chain.audit_request;

	OPEN out_cara_cur FOR
		SELECT audit_request_id,
			   user_sid,
			   sent_dtm
		  FROM chain.audit_request_alert;

	OPEN out_chain_supplier_audit_cur FOR
		SELECT audit_sid,
			   auditor_company_sid,
			   created_by_company_sid,
			   supplier_company_sid
		  FROM chain.supplier_audit;

END;

PROCEDURE GetChainBusinessUnits (
	out_chain_business_unit_cur OUT SYS_REFCURSOR,
	out_cbum_cur OUT SYS_REFCURSOR,
	out_cbus_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_chain_business_unit_cur FOR
		SELECT business_unit_id,
			   active,
			   description,
			   parent_business_unit_id
		  FROM chain.business_unit;

	OPEN out_cbum_cur FOR
		SELECT business_unit_id,
			   user_sid,
			   is_primary_bu
		  FROM chain.business_unit_member;

	OPEN out_cbus_cur FOR
		SELECT business_unit_id,
			   supplier_company_sid,
			   is_primary_bu
		  FROM chain.business_unit_supplier;

END;

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
)
AS
BEGIN
	OPEN out_chain_company_cc_email_cur FOR
		SELECT company_sid,
			   lower_email,
			   email
		  FROM chain.company_cc_email;

	OPEN out_chain_company_header_cur FOR
		SELECT company_header_id, page_company_type_id, plugin_id,
			   plugin_type_id, pos, user_company_type_id, viewing_own_company,
			   page_company_col_sid, user_company_col_sid
		  FROM chain.company_header;

	OPEN out_ccmt_cur FOR
		SELECT company_metric_type_id,
			   class,
			   description,
			   max_value
		  FROM chain.company_metric_type;

	OPEN out_chain_company_metric_cur FOR
		SELECT company_metric_type_id,
			   company_sid,
			   metric_value,
			   normalised_value
		  FROM chain.company_metric;

	OPEN out_chain_reference_cur FOR
		SELECT reference_id,
			   lookup_key,
			   depricated_reference_number,
			   label,
			   mandatory,
			   reference_filter_type_id,
			   reference_location_id,
			   reference_uniqueness_id,
			   show_in_filter,
			   reference_validation_id
		  FROM chain.reference;

	OPEN out_chain_reference_ct_cur FOR
		SELECT reference_id, company_type_id
		  FROM chain.reference_company_type;

	OPEN out_chain_reference_cap_cur FOR
		SELECT reference_id,
			   primary_company_type_id,
			   primary_company_group_type_id,
			   primary_company_type_role_sid,
			   secondary_company_type_id,
			   permission_set
		  FROM chain.reference_capability;

	OPEN out_chain_company_reference_c FOR
		SELECT company_reference_id,
			   company_sid,
			   value,
			   reference_id
		  FROM chain.company_reference;

	OPEN out_chain_company_tab_cur FOR
		SELECT company_tab_id, label, page_company_type_id, plugin_id, plugin_type_id,
			   pos, user_company_type_id, viewing_own_company, options, page_company_col_sid, user_company_col_sid,
			   flow_capability_id, business_relationship_type_id, default_saved_filter_sid, supplier_restriction
		  FROM chain.company_tab;

	OPEN out_chain_co_tab_rel_co_tye_c FOR
		SELECT company_tab_id, company_type_id
		  FROM chain.company_tab_related_co_type;

	OPEN out_chain_co_tab_co_type_rl_c FOR
		SELECT comp_tab_comp_type_role_id, company_tab_id, company_group_type_id, company_type_role_id
		  FROM chain.company_tab_company_type_role;

	OPEN out_chain_company_tag_group_c FOR
		SELECT company_sid,
			   tag_group_id,
			   applies_to_component,
			   applies_to_purchase
		  FROM chain.company_tag_group;

	OPEN out_chain_comp_type_tag_group FOR
		SELECT company_type_id, tag_group_id
		  FROM chain.company_type_tag_group;

	OPEN out_chain_product_header_cur FOR
		SELECT product_header_id,
			   plugin_id,
			   plugin_type_id,
			   pos,
			   product_col_sid,
			   product_company_type_id,
			   user_company_col_sid,
			   user_company_type_id,
			   viewing_as_supplier,
			   viewing_own_product
		  FROM chain.product_header;

	OPEN out_chain_pro_hd_pro_type_cur FOR
		SELECT product_header_id,
			   product_type_id
		  FROM chain.product_header_product_type;

	OPEN out_chain_product_tab_cur FOR
		SELECT product_tab_id,
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
		  FROM chain.product_tab;

	OPEN out_cptpt_cur FOR
		SELECT product_tab_id,
			   product_type_id
		  FROM chain.product_tab_product_type;

	OPEN out_cpst_cur FOR
		SELECT product_supplier_tab_id,
			   label,
			   plugin_id,
			   plugin_type_id,
			   pos,
			   product_company_type_id,
			   user_company_type_id,
			   viewing_as_supplier,
			   viewing_own_product
		  FROM chain.product_supplier_tab;

	OPEN out_chain_pr_sp_tb_pr_typ_cur FOR
		SELECT product_supplier_tab_id,
			   product_type_id
		  FROM chain.prod_supp_tab_product_type;

	OPEN out_chain_alt_company_name_cur FOR
		SELECT alt_company_name_id,
			   company_sid,
			   name
		  FROM chain.alt_company_name;

	OPEN out_chain_company_request_cur FOR
		SELECT company_sid,
			   matched_company_sid,
			   action,
			   is_processed,
			   batch_job_id,
			   error_message,
			   error_detail
		  FROM chain.company_request_action;
END;

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
)
AS
BEGIN
	OPEN out_chain_compound_filter_cur FOR
		SELECT compound_filter_id,
			   act_id,
			   card_group_id,
			   created_by_user_sid,
			   created_dtm,
			   operator_type
		  FROM chain.compound_filter
		 WHERE read_only_saved_filter_sid IS NULL;

	OPEN out_chain_file_upload_cur FOR
		SELECT file_upload_sid,
			   company_sid,
			   data,
			   download_permission_id,
			   filename,
			   lang,
			   last_modified_by_sid,
			   last_modified_dtm,
			   mime_type,
			   sha1
		  FROM chain.file_upload;

	OPEN out_chain_file_group_cur FOR
		SELECT file_group_id,
			   company_sid,
			   default_file_group_file_id,
			   description,
			   download_permission_id,
			   file_group_model_id,
			   guid,
			   title
		  FROM chain.file_group;

	OPEN out_chain_file_group_file_cur FOR
		SELECT file_group_file_id,
			   file_group_id,
			   file_upload_sid
		  FROM chain.file_group_file;

	OPEN out_cwfu_cur FOR
		SELECT worksheet_id,
			   file_upload_sid
		  FROM chain.worksheet_file_upload;

	OPEN out_chain_filter_cur FOR
		SELECT filter_id,
			   compound_filter_id,
			   filter_type_id,
			   operator_type
		  FROM chain.filter;

	OPEN out_chain_filter_field_cur FOR
		SELECT filter_field_id, comparator, filter_id,
			   name, group_by_index, show_all, top_n, bottom_n, show_other,
			   period_set_id, period_interval_id, column_sid
		  FROM chain.filter_field;

	OPEN out_chain_filter_value_cur FOR
		SELECT filter_value_id, description, end_dtm_value, filter_field_id, max_num_val,
			   min_num_val, num_value, region_sid, start_dtm_value, str_value, user_sid,
			   compound_filter_id_value, saved_filter_sid_value, pos, period_set_id,
			   period_interval_id, start_period_id, filter_type, null_filter, colour
		  FROM chain.filter_value;

	OPEN out_cf_cur FOR
		SELECT label,
			   report_url,
			   position
		  FROM chain.filtersupplierreportlinks;

	OPEN out_chain_saved_filter_cur FOR
		SELECT saved_filter_sid, card_group_id, compound_filter_id, name, parent_sid,
			   group_by_compound_filter_id, search_text, group_key, region_column_id,
			   date_column_id, cms_region_column_sid, cms_date_column_sid, cms_id_column_sid,
			   list_page_url, company_sid, exclude_from_reports, dual_axis, ranking_mode,
			   colour_by, colour_range_id, order_by, order_direction, results_per_page, map_colour_by, map_cluster_bias, hide_empty
		  FROM chain.saved_filter;

	OPEN out_chain_saved_fil_agg_t_cur FOR
		SELECT saved_filter_sid, pos, aggregation_type, customer_aggregate_type_id
		  FROM chain.saved_filter_aggregation_type;
	
	OPEN out_chain_saved_fil_col_cur FOR
		SELECT saved_filter_sid, column_name, pos, width, label
		  FROM chain.saved_filter_column;

	OPEN out_chain_flow_filter_cur FOR
		SELECT flow_sid,
			   saved_filter_sid
		  FROM chain.flow_filter;

	OPEN out_chain_svd_fil_alert_cur FOR
		SELECT saved_filter_sid, users_can_subscribe, customer_alert_type_id,
			   description, every_n_minutes,
			   schedule_xml, next_fire_time, last_fire_time,
			   alerts_sent_on_last_run
		  FROM chain.saved_filter_alert;

	OPEN out_chain_svd_fl_alrt_sub_cur FOR
		SELECT saved_filter_sid,
			   user_sid,
			   region_sid,
			   error_message
		  FROM chain.saved_filter_alert_subscriptn;

	-- We don't need chain.saved_filter_sent_alert, we assume all users haven't
	-- had their initial set sent to avoid mapping object_id;

	OPEN out_chain_fltr_itm_config_cur FOR
		SELECT card_group_id, card_id, item_name, label, pos, group_sid,
			   include_in_filter, include_in_breakdown, include_in_advanced,
			   session_prefix, path
		  FROM chain.filter_item_config
		 WHERE session_prefix IS NULL;

	OPEN out_chain_filter_page_cols_cur FOR
		SELECT card_group_id,
			   column_name,
			   label,
			   pos,
		       width,
		       fixed_width,
		       hidden,
		       group_sid,
		       include_in_export,
			   session_prefix,
			   group_key
		  FROM chain.filter_page_column
		 WHERE session_prefix IS NULL;

	OPEN out_chain_filter_page_inds_cur FOR
		SELECT filter_page_ind_id, card_group_id, ind_sid,
		       period_set_id, period_interval_id, start_dtm, end_dtm, previous_n_intervals,
		       include_in_list, include_in_filter, include_in_aggregates, include_in_breakdown,
		       show_measure_in_description, show_interval_in_description, description_override
		  FROM chain.filter_page_ind;

	OPEN out_chain_fltr_pg_ind_itvl_cur FOR
		SELECT filter_page_ind_interval_id, filter_page_ind_id,
		       start_dtm, current_interval_offset
		  FROM chain.filter_page_ind_interval;

	OPEN out_chain_custom_agg_type_cur FOR
		SELECT card_group_id, customer_aggregate_type_id, cms_aggregate_type_id, initiative_metric_id,
		       ind_sid, filter_page_ind_interval_id, meter_aggregate_type_id, score_type_agg_type_id, cust_filt_item_agg_type_id
		  FROM chain.customer_aggregate_type;

	OPEN out_chain_agg_type_config_cur FOR
		SELECT card_group_id, aggregate_type_id, label, pos, enabled, group_sid, session_prefix, path
		  FROM chain.aggregate_type_config
		 WHERE session_prefix IS NULL;

	OPEN out_chain_svd_fltr_region_cur FOR
		SELECT saved_filter_sid, region_sid
		  FROM chain.saved_filter_region;

	OPEN out_chain_filter_page_cms_tab FOR
		SELECT filter_page_cms_table_id, card_group_id, column_sid
		  FROM chain.filter_page_cms_table;

	OPEN out_chain_customer_grid_ext FOR
		SELECT grid_extension_id, enabled
		  FROM chain.customer_grid_extension;

	OPEN out_ccfc_cur FOR
		SELECT customer_filter_column_id,
			   card_group_id,
			   column_name,
			   fixed_width,
			   label,
			   session_prefix,
			   sortable,
			   width
		  FROM chain.customer_filter_column;

	OPEN out_ccfi_cur FOR
		SELECT customer_filter_item_id,
			   can_breakdown,
			   card_group_id,
			   item_name,
			   label,
			   session_prefix
		  FROM chain.customer_filter_item;

	OPEN out_ccfiat_cur FOR
		SELECT cust_filt_item_agg_type_id,
			   analytic_function,
			   customer_filter_item_id
		  FROM chain.cust_filt_item_agg_type;
END;

PROCEDURE GetChainComponents (
	out_chain_component_type_cur OUT SYS_REFCURSOR,
	out_cctc_cur OUT SYS_REFCURSOR,
	out_chain_component_cur OUT SYS_REFCURSOR,
	out_ccd_cur OUT SYS_REFCURSOR,
	out_chain_component_source_cur OUT SYS_REFCURSOR,
	out_chain_component_tag_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_chain_component_type_cur FOR
		SELECT component_type_id
		  FROM chain.component_type;

	OPEN out_cctc_cur FOR
		SELECT container_component_type_id,
			   child_component_type_id,
			   allow_add_existing,
			   allow_add_new
		  FROM chain.component_type_containment;

	OPEN out_chain_component_cur FOR
		SELECT component_id,
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
		  FROM chain.component;

	OPEN out_ccd_cur FOR
		SELECT component_id,
			   file_upload_sid,
			   key
		  FROM chain.component_document;

	OPEN out_chain_component_source_cur FOR
		SELECT card_group_id,
			   card_text,
			   component_type_id,
			   description_xml,
			   position,
			   progression_action
		  FROM chain.component_source;

	OPEN out_chain_component_tag_cur FOR
		SELECT tag_id,
			   component_id
		  FROM chain.component_tag;

END;

PROCEDURE GetChainInvitations (
	out_chain_invitation_cur OUT SYS_REFCURSOR,
	out_ciut_cur OUT SYS_REFCURSOR,
	out_cqg_cur OUT SYS_REFCURSOR,
	out_cqt_cur OUT SYS_REFCURSOR,
	out_cfqt_cur OUT SYS_REFCURSOR,
	out_ciqt_cur OUT SYS_REFCURSOR,
	out_ciqtc_cur OUT SYS_REFCURSOR,
	out_chain_message_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_chain_invitation_cur FOR
		SELECT invitation_id,
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
		  FROM chain.invitation;

	OPEN out_ciut_cur FOR
		SELECT user_sid,
			   lang,
			   footer,
			   header
		  FROM chain.invitation_user_tpl;

	OPEN out_cqg_cur FOR
		SELECT group_name,
			   description
		  FROM chain.questionnaire_group;

	OPEN out_cqt_cur FOR
		SELECT questionnaire_type_id,
			   active,
			   auto_resend_on_expiry,
			   can_be_overdue,
			   class,
			   db_class,
			   default_overdue_days,
			   edit_url,
			   enable_overdue_alert,
			   enable_reminder_alert,
			   expire_after_months,
			   group_name,
			   is_resendable,
			   name,
			   owner_can_review,
			   position,
			   procurer_can_review,
			   reminder_offset_days,
			   requires_review,
			   security_scheme_id,
			   view_url,
			   enable_status_log,
			   enable_transition_alert
		  FROM chain.questionnaire_type;

	OPEN out_cfqt_cur FOR
		SELECT flow_sid,
			   questionnaire_type_id
		  FROM chain.flow_questionnaire_type;

	OPEN out_ciqt_cur FOR
		SELECT invitation_id,
			   questionnaire_type_id,
			   added_by_user_sid,
			   requested_due_dtm
		  FROM chain.invitation_qnr_type;

	OPEN out_ciqtc_cur FOR
		SELECT invitation_id,
			   questionnaire_type_id,
			   component_id
		  FROM chain.invitation_qnr_type_component;

	OPEN out_chain_message_cur FOR
		SELECT message_id,
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
		  FROM chain.message;

END;

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
)
AS
BEGIN
	OPEN out_chain_alert_entry_cur FOR
		SELECT alert_entry_id,
			   alert_entry_type_id,
			   company_sid,
			   message_id,
			   occurred_dtm,
			   owner_scheduled_alert_id,
			   priority,
			   template_name,
			   user_sid
		  FROM chain.alert_entry;

	OPEN out_chain_alert_entry_param_c FOR
		SELECT alert_entry_id,
			   name,
			   value
		  FROM chain.alert_entry_param;

	OPEN out_capt_cur FOR
		SELECT alert_type_id,
			   partial_template_type_id,
			   lang,
			   partial_html
		  FROM chain.alert_partial_template;

	OPEN out_captp_cur FOR
		SELECT alert_type_id,
			   partial_template_type_id,
			   field_name
		  FROM chain.alert_partial_template_param;

	OPEN out_cuaet_cur FOR
		SELECT alert_entry_type_id,
			   user_sid,
			   enabled,
			   schedule_xml
		  FROM chain.user_alert_entry_type;

	OPEN out_chain_review_alert_cur FOR
		SELECT review_alert_id,
			   from_company_sid,
			   from_user_sid,
			   sent_dtm,
			   to_company_sid,
			   to_user_sid
		  FROM chain.review_alert;

	OPEN out_chain_scheduled_alert_cur FOR
		SELECT scheduled_alert_id,
			   user_sid,
			   alert_entry_type_id,
			   sent_dtm
		  FROM chain.scheduled_alert;

	OPEN out_ccaet_cur FOR
		SELECT alert_entry_type_id,
			   template_name,
			   template
		  FROM chain.customer_alert_entry_template;

	OPEN out_ccaet1_cur FOR
		SELECT alert_entry_type_id,
			   company_section_template,
			   enabled,
			   force_disable,
			   generator_sp,
			   important_section_template,
			   schedule_xml,
			   user_section_template
		  FROM chain.customer_alert_entry_type;

	OPEN out_ch_prod_comp_alerts_cur FOR
		SELECT alert_id,
			   company_product_id,
			   purchaser_company_sid,
			   supplier_company_sid,
			   user_sid,
			   sent_dtm
		  FROM chain.product_company_alert;

END;

PROCEDURE GetChainMessages (
	out_cmd_cur OUT SYS_REFCURSOR,
	out_chain_message_param_cur OUT SYS_REFCURSOR,
	out_chain_recipient_cur OUT SYS_REFCURSOR,
	out_chain_message_recipient_c OUT SYS_REFCURSOR,
	out_cmrl_cur OUT SYS_REFCURSOR,
	out_chain_newsflash_cur OUT SYS_REFCURSOR,
	out_chain_newsflash_company_c OUT SYS_REFCURSOR,
	out_cnus_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cmd_cur FOR
		SELECT message_definition_id,
			   completed_template,
			   completion_type_id,
			   css_class,
			   helper_pkg,
			   message_priority_id,
			   message_template
		  FROM chain.message_definition;

	OPEN out_chain_message_param_cur FOR
		SELECT message_definition_id,
			   param_name,
			   css_class,
			   href,
			   value
		  FROM chain.message_param;

	OPEN out_chain_recipient_cur FOR
		SELECT recipient_id,
			   to_company_sid,
			   to_user_sid
		  FROM chain.recipient;

	OPEN out_chain_message_recipient_c FOR
		SELECT message_id,
			   recipient_id
		  FROM chain.message_recipient;

	OPEN out_cmrl_cur FOR
		SELECT message_id,
			   refresh_index,
			   refresh_dtm,
			   refresh_user_sid
		  FROM chain.message_refresh_log;

	OPEN out_chain_newsflash_cur FOR
		SELECT newsflash_id,
			   content,
			   created_dtm,
			   expired_dtm,
			   released_dtm
		  FROM chain.newsflash;

	OPEN out_chain_newsflash_company_c FOR
		SELECT newsflash_id,
			   company_sid,
			   for_suppliers,
			   for_users
		  FROM chain.newsflash_company;

	OPEN out_cnus_cur FOR
		SELECT newsflash_id,
			   user_sid,
			   hidden
		  FROM chain.newsflash_user_settings;

END;

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
)
AS
BEGIN
	OPEN out_chain_product_cur FOR
		SELECT product_id
		  FROM chain.product;


	OPEN out_chain_product_code_type_c FOR
		SELECT company_sid,
			   code2_mandatory,
			   code3_mandatory,
			   code_label1,
			   code_label2,
			   code_label3,
			   mapping_approval_required
		  FROM chain.product_code_type;

	OPEN out_cpmt_cur FOR
		SELECT product_metric_type_id,
			   class,
			   description,
			   max_score
		  FROM chain.product_metric_type;

	OPEN out_chain_product_revision_cur FOR
		SELECT product_id,
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
		  FROM chain.product_revision;

	OPEN out_cus_cur FOR
		SELECT company_sid,
			   uninvited_supplier_sid,
			   country_code,
			   created_as_company_sid,
			   name,
			   supp_rel_code
		  FROM chain.uninvited_supplier;

	OPEN out_chain_purchase_channel_cur FOR
		SELECT company_sid,
			   purchase_channel_id,
			   description,
			   region_sid
		  FROM chain.purchase_channel;

	OPEN out_cpc_cur FOR
		SELECT component_id,
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
		  FROM chain.purchased_component;

	OPEN out_chain_purchase_cur FOR
		SELECT purchase_id,
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
		  FROM chain.purchase;

	OPEN out_chain_purchase_tag_cur FOR
		SELECT tag_id,
			   purchase_id
		  FROM chain.purchase_tag;

	OPEN out_cpf_cur FOR
		SELECT purchaser_company_sid,
			   supplier_company_sid,
			   user_sid
		  FROM chain.purchaser_follower;

	OPEN out_cvpc_cur FOR
		SELECT component_id,
			   mapped_purchased_component_id
		  FROM chain.validated_purchased_component;

END;

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
)
AS
BEGIN
	OPEN out_cqsal_cur FOR
		SELECT questionnaire_share_id,
			   alert_sent_dtm,
			   std_alert_type_id,
			   user_sid
		  FROM chain.qnnaire_share_alert_log;

	OPEN out_cqasm_cur FOR
		SELECT questionnaire_type_id,
			   company_function_id,
			   questionnaire_action_id,
			   action_security_type_id
		  FROM chain.qnr_action_security_mask;

	OPEN out_chain_questionnaire_cur FOR
		SELECT questionnaire_id,
			   company_sid,
			   component_id,
			   created_dtm,
			   description,
			   questionnaire_type_id,
			   rejected
		  FROM chain.questionnaire;

	OPEN out_cqsle_cur FOR
		SELECT questionnaire_share_id,
			   share_log_entry_index,
			   company_sid,
			   entry_dtm,
			   share_status_id,
			   user_notes,
			   user_sid
		  FROM chain.qnr_share_log_entry;

	OPEN out_cqsle1_cur FOR
		SELECT questionnaire_id,
			   status_log_entry_index,
			   entry_dtm,
			   questionnaire_status_id,
			   user_notes,
			   user_sid
		  FROM chain.qnr_status_log_entry;

	OPEN out_cqea_cur FOR
		SELECT questionnaire_share_id,
			   user_sid
		  FROM chain.questionnaire_expiry_alert;

	OPEN out_cqi_cur FOR
		SELECT questionnaire_id,
			   invitation_id,
			   added_dtm
		  FROM chain.questionnaire_invitation;

	OPEN out_cqmt_cur FOR
		SELECT questionnaire_metric_type_id,
			   description,
			   max_value,
			   questionnaire_type_id
		  FROM chain.questionnaire_metric_type;

	OPEN out_cqm_cur FOR
		SELECT questionnaire_id,
			   questionnaire_metric_type_id,
			   metric_value,
			   normalised_value
		  FROM chain.questionnaire_metric;

	OPEN out_cqs_cur FOR
		SELECT questionnaire_share_id,
			   due_by_dtm,
			   expiry_dtm,
			   expiry_sent_dtm,
			   overdue_events_sent,
			   overdue_sent_dtm,
			   qnr_owner_company_sid,
			   questionnaire_id,
			   reminder_sent_dtm,
			   share_with_company_sid
		  FROM chain.questionnaire_share;

	OPEN out_cqu_cur FOR
		SELECT questionnaire_id,
			   user_sid,
			   company_function_id,
			   company_sid,
			   added_dtm
		  FROM chain.questionnaire_user;

	OPEN out_cqua_cur FOR
		SELECT questionnaire_id,
			   user_sid,
			   company_function_id,
			   questionnaire_action_id,
			   company_sid
		  FROM chain.questionnaire_user_action;

END;

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
)
AS
BEGIN
	OPEN out_chain_task_cur FOR
		SELECT task_id,
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
		  FROM chain.task;

	OPEN out_ctat_cur FOR
		SELECT on_task_action_id,
			   position,
			   task_type_id,
			   trigger_task_action_id,
			   trigger_task_name
		  FROM chain.task_action_trigger;

	OPEN out_chain_task_entry_cur FOR
		SELECT task_entry_id,
			   last_modified_by_sid,
			   last_modified_dtm,
			   name,
			   task_entry_type_id,
			   task_id
		  FROM chain.task_entry;

	OPEN out_chain_task_entry_date_cur FOR
		SELECT task_entry_id,
			   dtm
		  FROM chain.task_entry_date;

	OPEN out_chain_task_entry_file_cur FOR
		SELECT task_entry_id,
			   file_upload_sid
		  FROM chain.task_entry_file;

	OPEN out_chain_task_entry_note_cur FOR
		SELECT task_entry_id,
			   text
		  FROM chain.task_entry_note;

	OPEN out_chain_task_scheme_cur FOR
		SELECT task_scheme_id,
			   db_class,
			   description
		  FROM chain.task_scheme;

	OPEN out_chain_task_type_cur FOR
		SELECT task_type_id,
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
		  FROM chain.task_type;

	OPEN out_ctiqt_cur FOR
		SELECT task_id,
			   invitation_id,
			   questionnaire_type_id
		  FROM chain.task_invitation_qnr_type;

END;

PROCEDURE GetChainUserMessageLog (
	out_chain_user_message_log_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_chain_user_message_log_cur FOR
		SELECT user_sid,
			   message_id,
			   viewed_dtm
		  FROM chain.user_message_log;

END;

PROCEDURE GetChainBusinessRelationships (
	out_cbrt_cur OUT SYS_REFCURSOR,
	out_cbrt1_cur OUT SYS_REFCURSOR,
	out_cbrtct_cur OUT SYS_REFCURSOR,
	out_cbr_cur OUT SYS_REFCURSOR,
	out_cbrc_cur OUT SYS_REFCURSOR,
	out_cbrp_cur OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cbrt_cur FOR
		SELECT business_relationship_type_id,
			   label,
			   form_path,
			   tab_sid,
			   column_sid,
			   lookup_key
		  FROM chain.business_relationship_type;

	OPEN out_cbrt1_cur FOR
		SELECT business_relationship_type_id,
			   business_relationship_tier_id,
			   tier,
			   direct_from_previous_tier,
			   label,
			   create_supplier_relationship,
			   create_new_company,
			   lookup_key,
			   allow_multiple_companies,
			   create_sup_rels_w_lower_tiers
		  FROM chain.business_relationship_tier;

	OPEN out_cbrtct_cur FOR
		SELECT business_relationship_tier_id,
			   company_type_id
		  FROM chain.business_rel_tier_company_type;

	OPEN out_cbr_cur FOR
		SELECT business_relationship_id,
			   business_relationship_type_id
		  FROM chain.business_relationship;

	OPEN out_cbrc_cur FOR
		SELECT business_relationship_id,
			   business_relationship_tier_id,
			   company_sid,
			   pos
		  FROM chain.business_relationship_company;

	OPEN out_cbrp_cur FOR
		SELECT business_relationship_id,
			   business_rel_period_id,
			   start_dtm,
			   end_dtm
		  FROM chain.business_relationship_period;
END;


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
)
AS
BEGIN

	OPEN out_chain_import_source_cur FOR
		SELECT import_source_id,
			   dedupe_no_match_action_id,
			   name,
			   position,
			   lookup_key,
			   is_owned_by_system,
			   override_company_active
		  FROM chain.import_source;

	OPEN out_chain_dedupe_mapping_cur FOR
		SELECT dedupe_mapping_id,
			   col_sid,
			   dedupe_field_id,
			   reference_id,
			   tag_group_id,
			   role_sid,
			   tab_sid,
			   destination_tab_sid,
			   destination_col_sid,
			   dedupe_staging_link_id,
			   allow_create_alt_company_name,
			   is_owned_by_system,
			   fill_nulls_under_ui_source
		  FROM chain.dedupe_mapping;

	OPEN out_chain_dedupe_rule_set_cur FOR
		SELECT dedupe_rule_set_id,
			   position,
			   dedupe_staging_link_id,
			   dedupe_match_type_id,
			   description
		  FROM chain.dedupe_rule_set;

	OPEN out_chain_dedupe_rule_cur FOR
		SELECT dedupe_rule_id,
			   dedupe_rule_set_id,
			   dedupe_mapping_id,
			   position,
			   dedupe_rule_type_id,
			   match_threshold
		  FROM chain.dedupe_rule;

	OPEN out_cdpr_cur FOR
		SELECT dedupe_processed_record_id,
			   reference,
			   dedupe_action_type_id,
			   iteration_num,
		 	   matched_by_user_sid,
			   matched_dtm,
			   matched_to_company_sid,
			   processed_dtm,
			   created_company_sid,
			   data_merged,
			   dedupe_staging_link_id,
			   batch_num,
			   cms_record_id,
			   parent_processed_record_id,
			   imported_user_sid,
			   merge_status_id
		  FROM chain.dedupe_processed_record;

	OPEN out_chain_dedupe_match_cur FOR
		SELECT dedupe_match_id,
			   dedupe_processed_record_id,
			   dedupe_rule_set_id,
			   matched_to_company_sid
		  FROM chain.dedupe_match;

	OPEN out_chain_dedupe_merge_log_cur FOR
		SELECT dedupe_merge_log_id,
			   dedupe_field_id,
			   dedupe_processed_record_id,
			   new_val,
			   old_val,
			   reference_id,
			   tag_group_id,
			   role_sid,
			   destination_tab_sid,
			   destination_col_sid,
			   error_message,
			   current_desc_val,
			   new_raw_val,
			   new_translated_val,
			   alt_comp_name_downgrade
		  FROM chain.dedupe_merge_log;

	OPEN out_cdsl_cur FOR
		SELECT dedupe_staging_link_id,
			   description,
			   destination_tab_sid,
			   import_source_id,
			   parent_staging_link_id,
			   position,
			   staging_batch_num_col_sid,
			   staging_id_col_sid,
			   staging_tab_sid,
			   staging_source_lookup_col_sid,
			   is_owned_by_system
		  FROM chain.dedupe_staging_link;

	OPEN out_cdpc_cur FOR
		SELECT company_sid,
			   address,
			   city,
			   name,
			   postcode,
			   state,
			   updated_dtm,
			   website,
			   phone,
			   email_domain
		  FROM chain.dedupe_preproc_comp;

	OPEN out_cdpru_cur FOR
		SELECT dedupe_preproc_rule_id,
			   pattern,
			   replacement,
			   run_order
		  FROM chain.dedupe_preproc_rule;

	OPEN out_cdpfc_cur FOR
		SELECT country_code,
			   dedupe_field_id,
			   dedupe_preproc_rule_id
		  FROM chain.dedupe_pp_field_cntry;

	OPEN out_chain_dedupe_sub_cur FOR
		SELECT dedupe_sub_id,
			   pattern,
			   substitution,
			   proc_pattern,
			   proc_substitution,
			   updated_dtm
		  FROM chain.dedupe_sub;

	OPEN out_cdpacn_cur FOR
		SELECT alt_company_name_id,
			   company_sid,
			   name
		  FROM chain.dedupe_pp_alt_comp_name;

	OPEN out_pnd_cmpny_sggstd_match_cur FOR
		SELECT pending_company_sid,
			   matched_company_sid,
			   dedupe_rule_set_id
		  FROM chain.pend_company_suggested_match;

	OPEN out_pending_company_tag_cur FOR
		SELECT pending_company_sid,
			   tag_id
		  FROM chain.pending_company_tag;

	OPEN out_blcklst_email_domain FOR
		SELECT email_domain
		  FROM chain.dd_customer_blcklst_email;

END;

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
)
AS
BEGIN
	OPEN out_chain_higg FOR
		SELECT ftp_folder,
			   ftp_profile_label
		  FROM chain.higg;

	OPEN out_higg_config FOR
		SELECT higg_config_id,
			   company_type_id,
			   audit_type_id,
			   survey_sid,
			   closure_type_id,
			   audit_coordinator_sid,
			   aggregate_ind_group_id,
			   copy_score_on_survey_submit
		  FROM chain.higg_config;

	OPEN out_higg_module_tag_group FOR
		SELECT higg_module_id,
			tag_group_id
		  FROM chain.higg_module_tag_group;

	OPEN out_higg_config_module FOR
		SELECT higg_config_id,
			higg_module_id,
			score_type_id
		  FROM chain.higg_config_module;

	OPEN out_higg_question_survey FOR
		SELECT higg_question_id, survey_sid, qs_question_id, qs_question_version, survey_version
		FROM chain.higg_question_survey;

	OPEN out_higg_question_op_survey FOR
		SELECT higg_question_id, higg_question_option_id, survey_sid, qs_question_id, 
			   qs_question_version, qs_question_option_id, survey_version
		FROM chain.higg_question_option_survey;

	OPEN out_higg_response FOR
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
		  FROM chain.higg_response;

	OPEN out_higg_section_score FOR
		SELECT higg_response_id,
			higg_section_id,
			score
		  FROM chain.higg_section_score;

	OPEN out_higg_sub_section_score FOR
		SELECT higg_response_id,
			higg_section_id,
			higg_sub_section_id,
			score
		  FROM chain.higg_sub_section_score;

	OPEN out_higg_question_response FOR
			SELECT higg_response_id,
			higg_question_id,
			score,
			answer,
			option_id
		  FROM chain.higg_question_response;

	OPEN out_higg_profile FOR
		SELECT higg_profile_id,
			response_year
		  FROM chain.higg_profile;

	OPEN out_higg_config_profile FOR
		SELECT higg_config_id,
			higg_profile_id,
			response_year,
			internal_audit_sid
		  FROM chain.higg_config_profile;

	OPEN out_higg_question_opt_conv FOR
		SELECT higg_question_id,
			higg_question_option_id,
			measure_conversion_id
		  FROM chain.higg_question_opt_conversion;
END;

PROCEDURE GetWorksheet (
	out_worksheet_cur OUT SYS_REFCURSOR,
	out_worksheet_column_cur OUT SYS_REFCURSOR,
	out_wcvm_cur OUT SYS_REFCURSOR,
	out_worksheet_row_cur OUT SYS_REFCURSOR,
	out_worksheet_value_map_cur OUT SYS_REFCURSOR,
	out_wvmv_cur OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_worksheet_cur FOR
		SELECT worksheet_id,
			   header_row_index,
			   lower_sheet_name,
			   sheet_name,
			   worksheet_type_id
		  FROM worksheet;

	OPEN out_worksheet_column_cur FOR
		SELECT worksheet_id,
			   column_type_id,
			   column_index
		  FROM worksheet_column;

	OPEN out_wcvm_cur FOR
		SELECT worksheet_id,
			   column_type_id,
			   value_mapper_id,
			   value_map_id
		  FROM worksheet_column_value_map;

	OPEN out_worksheet_row_cur FOR
		SELECT worksheet_id,
			   row_number,
			   ignore
		  FROM worksheet_row;

	OPEN out_worksheet_value_map_cur FOR
		SELECT value_mapper_id,
			   value_map_id
		  FROM worksheet_value_map;

	OPEN out_wvmv_cur FOR
		SELECT value_map_id,
			   column_type_id,
			   value_mapper_id,
			   value
		  FROM worksheet_value_map_value;

END;

PROCEDURE GetMessageDefinitions (
	out_cdmd_cur OUT SYS_REFCURSOR,
	out_cmdl_cur OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cdmd_cur FOR
		SELECT message_definition_id,
			   addressing_type_id,
			   completed_template,
			   completion_type_id,
			   css_class,
			   helper_pkg,
			   message_priority_id,
			   message_template,
			   repeat_type_id
		  FROM chain.default_message_definition;

	OPEN out_cmdl_cur FOR
		SELECT message_definition_id,
			   primary_lookup_id,
			   secondary_lookup_id
		  FROM chain.message_definition_lookup;
END;

PROCEDURE GetFilterType (
	out_chain_filter_type_cur OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_chain_filter_type_cur FOR
		SELECT filter_type_id,
			   card_id,
			   description,
			   helper_pkg
		  FROM chain.filter_type;

END;

PROCEDURE GetGroupCapability (
	out_chain_group_capability_cur OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_chain_group_capability_cur FOR
		SELECT group_capability_id,
			   capability_id,
			   company_group_type_id,
			   permission_set
		  FROM chain.group_capability;

END;

PROCEDURE GetCardProgressionAction (
	out_ccpa_cur OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_ccpa_cur FOR
		SELECT card_id,
			   action
		  FROM chain.card_progression_action;

END;

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
)
AS
BEGIN
	OPEN out_chem_chem_options_cur FOR
		SELECT chem_helper_pkg
		  FROM chem.chem_options;

	OPEN out_chem_cas_cur FOR
		SELECT cas_code,
			   name,
			   unconfirmed,
			   is_voc,
			   category
		  FROM chem.cas;

	OPEN out_chem_cas_group_cur FOR
		SELECT cas_group_id,
			   label,
			   lookup_key,
			   parent_group_id
		  FROM chem.cas_group;

	OPEN out_chem_cas_group_member_cur FOR
		SELECT cas_group_id,
			   cas_code
		  FROM chem.cas_group_member;

	OPEN out_chem_cas_restricted_cur FOR
		SELECT cas_code,
			   root_region_sid,
			   clp_table_3_1,
			   clp_table_3_2,
			   end_dtm,
			   remarks,
			   source,
			   start_dtm
		  FROM chem.cas_restricted;

	OPEN out_chem_classification_cur FOR
		SELECT classification_id,
			   description
		  FROM chem.classification;

	OPEN out_chem_manufacturer_cur FOR
		SELECT manufacturer_id,
			   code,
			   name
		  FROM chem.manufacturer;

	OPEN out_chem_substance_cur FOR
		SELECT substance_id,
			   classification_id,
			   description,
			   is_central,
			   manufacturer_id,
			   ref,
			   region_sid
		  FROM chem.substance;

	OPEN out_chem_substance_cas_cur FOR
		SELECT substance_id,
			   cas_code,
			   pct_composition
		  FROM chem.substance_cas;

	OPEN out_chem_usage_cur FOR
		SELECT usage_id,
			   description
		  FROM chem.usage;

	OPEN out_chem_substance_region_cur FOR
		SELECT substance_id,
			   region_sid,
			   first_used_dtm,
			   flow_item_id,
			   local_ref,
			   waiver_status_id
		  FROM chem.substance_region;

	OPEN out_csrp_cur FOR
		SELECT substance_id,
			   region_sid,
			   process_id,
			   active,
			   first_used_dtm,
			   label,
			   usage_id
		  FROM chem.substance_region_process;

	OPEN out_cpcd_cur FOR
		SELECT substance_id,
			   region_sid,
			   process_id,
			   cas_code,
			   remaining_dest,
			   remaining_pct,
			   to_air_pct,
			   to_product_pct,
			   to_waste_pct,
			   to_water_pct
		  FROM chem.process_cas_default;

	OPEN out_cspuc_cur FOR
		SELECT subst_proc_use_change_id,
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
		  FROM chem.substance_process_use_change;

	OPEN out_cspcdc_cur FOR
		SELECT subst_proc_cas_dest_change_id,
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
		  FROM chem.subst_process_cas_dest_change;

	OPEN out_csal_cur FOR
		SELECT substance_audit_log_id,
			   substance_id,
			   changed_by,
			   changed_dtm,
			   description,
			   param_1,
			   param_2
		  FROM chem.substance_audit_log;

	OPEN out_chem_substance_file_cur FOR
		SELECT substance_file_id,
			   data,
			   filename,
			   mime_type,
			   substance_id,
			   uploaded_dtm,
			   uploaded_user_sid,
			   url
		  FROM chem.substance_file;

	OPEN out_cspu_cur FOR
		SELECT substance_process_use_id,
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
		  FROM chem.substance_process_use;

	OPEN out_cspcd_cur FOR
		SELECT substance_process_use_id,
			   cas_code,
			   remaining_dest,
			   remaining_pct,
			   substance_id,
			   to_air_pct,
			   to_product_pct,
			   to_waste_pct,
			   to_water_pct
		  FROM chem.substance_process_cas_dest;

	OPEN out_cspuf_cur FOR
		SELECT substance_process_use_file_id,
			   data,
			   filename,
			   mime_type,
			   substance_process_use_id,
			   uploaded_dtm,
			   uploaded_user_sid
		  FROM chem.substance_process_use_file;

	OPEN out_chem_usage_audit_log_cur FOR
		SELECT usage_audit_log_id,
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
		  FROM chem.usage_audit_log;

END;

PROCEDURE GetScheduledStoredProcs (
	out_ssp_cur OUT SYS_REFCURSOR,
	out_sspl_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_ssp_cur FOR
		SELECT ssp_id, sp, args, description, intrval, frequency, next_run_dtm, schedule_run_dtm, one_off,
			one_off_user, one_off_date, last_ssp_log_id, enabled
		  FROM scheduled_stored_proc;
	
	OPEN out_sspl_cur FOR
		SELECT ssp_log_id, ssp_id, run_dtm, result_code, result_msg, result_ex, one_off, one_off_user,  one_off_date
		  FROM scheduled_stored_proc_log;
END;

PROCEDURE GetFileUploadTypeOptions(
	out_futo_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_futo_cur FOR
		SELECT file_extension, is_allowed
		  FROM customer_file_upload_type_opt
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetFileUploadMimeOptions(
	out_fumo_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_fumo_cur FOR
		SELECT mime_type, is_allowed
		  FROM customer_file_upload_mime_opt
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetFileUploadOptions(
	out_file_type_cur		OUT	SYS_REFCURSOR,
	out_mime_type_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetFileUploadTypeOptions(out_file_type_cur);
	GetFileUploadMimeOptions(out_mime_type_cur);
END;

PROCEDURE GetRReports (
	out_r_report_type_cur	OUT SYS_REFCURSOR,
	out_r_report_cur		OUT SYS_REFCURSOR,
	out_r_report_file_cur	OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_r_report_type_cur FOR
		SELECT r_report_type_id,
			   label,
			   plugin_id,
			   plugin_type_id
		  FROM r_report_type;

	OPEN out_r_report_cur FOR
		SELECT r_report_sid,
			   js_data,
			   prepared_dtm,
			   requested_by_user_sid,
			   r_report_type_id
		  FROM r_report;

	OPEN out_r_report_file_cur FOR
		SELECT r_report_file_id,
			   data,
			   filename,
			   mime_type,
			   r_report_sid,
			   show_as_download,
			   show_as_tab,
			   title
		  FROM r_report_file;
END;

PROCEDURE GetLikeForLike(
	out_slot_cur					OUT SYS_REFCURSOR,
	out_email_sub_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_slot_cur FOR
		SELECT like_for_like_sid, name, ind_sid, region_sid, include_inactive_regions, period_start_dtm, period_end_dtm, period_set_id, period_interval_id, rule_type,
			   scenario_run_sid, created_by_user_sid, created_dtm, last_refresh_user_sid, last_refresh_dtm
		  FROM like_for_like_slot
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_email_sub_cur FOR
		SELECT like_for_like_sid, csr_user_sid
		  FROM like_for_like_email_sub
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetAggregationPeriods(
	out_aggregation_period_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_aggregation_period_cur FOR
		SELECT aggregation_period_id, label, no_of_months
		  FROM aggregation_period
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetGeoMaps(
	out_geo_map						OUT SYS_REFCURSOR,
	out_geo_map_region				OUT SYS_REFCURSOR,
	out_cgmtt_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_geo_map FOR
		SELECT geo_map_sid, label, region_selection_type_id, tag_id, include_inactive_regions, start_dtm,
			   end_dtm, interval
		  FROM geo_map
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_geo_map_region FOR
		SELECT geo_map_sid, region_sid
		  FROM geo_map_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_cgmtt_cur FOR
		SELECT geo_map_tab_type_id
		  FROM customer_geo_map_tab_type;
END;

PROCEDURE GetDegreeDays(
	out_settings					OUT SYS_REFCURSOR,
	out_regions						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_settings FOR
		SELECT account_name, download_enabled, earliest_fetch_dtm, average_years, heating_base_temp_ind_sid,
			   cooling_base_temp_ind_sid, heating_degree_days_ind_sid, cooling_degree_days_ind_sid,
			   heating_average_ind_sid, cooling_average_ind_sid, last_sync_dtm
		  FROM degreeday_settings
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_regions FOR
		SELECT region_sid, station_id, station_description, station_update_dtm
		  FROM degreeday_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

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
)
AS
BEGIN

	OPEN out_initiative_cur FOR
		SELECT initiative_sid,
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
		  FROM initiative;

	OPEN out_initiative_metric_cur FOR
		SELECT initiative_metric_id,
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
		  FROM initiative_metric;

	OPEN out_initiative_project_cur FOR
		SELECT project_sid,
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
		  FROM initiative_project;

	OPEN out_iprs_cur FOR
		SELECT project_sid,
			   rag_status_id,
			   pos
		  FROM initiative_project_rag_status;

	OPEN out_cist_cur FOR
		SELECT saving_type_id,
			   is_during,
			   is_running
		  FROM customer_init_saving_type;

	OPEN out_initiative_metri_group_cur FOR
		SELECT project_sid,
			   pos_group,
			   info_text,
			   is_group_mandatory,
			   label
		  FROM initiative_metric_group;

	OPEN out_pim_cur FOR
		SELECT project_sid,
			   initiative_metric_id,
			   default_value,
			   display_context,
			   flow_sid,
			   info_text,
			   input_dp,
			   pos,
			   pos_group,
			   update_per_period
		  FROM project_initiative_metric;

	OPEN out_initiative_metri_assoc_cur FOR
		SELECT project_sid,
			   proposed_metric_id,
			   measured_metric_id
		  FROM initiative_metric_assoc;

	OPEN out_pimfs_cur FOR
		SELECT initiative_metric_id,
			   flow_state_id,
			   project_sid,
			   flow_sid,
			   mandatory,
			   visible
		  FROM project_init_metric_flow_state;

	OPEN out_imsi_cur FOR
		SELECT initiative_metric_id,
			   flow_state_group_id,
			   ind_sid,
			   measure_sid,
			   net_period
		  FROM initiative_metric_state_ind;

	OPEN out_aggr_tag_group_cur FOR
		SELECT aggr_tag_group_id,
			   count_ind_sid,
			   label,
			   lookup_key
		  FROM aggr_tag_group;

	OPEN out_imti_cur FOR
		SELECT initiative_metric_id,
			   aggr_tag_group_id,
			   ind_sid,
			   measure_sid
		  FROM initiative_metric_tag_ind;

	OPEN out_aggr_tag_group_member_cur FOR
		SELECT aggr_tag_group_id,
			   tag_id
		  FROM aggr_tag_group_member;

	OPEN out_initiative_comment_cur FOR
		SELECT initiative_comment_id,
			   comment_text,
			   initiative_sid,
			   posted_dtm,
			   user_sid
		  FROM initiative_comment;

	OPEN out_initiative_event_cur FOR
		SELECT initiative_event_id,
			   created_by_sid,
			   created_dtm,
			   description,
			   end_dtm,
			   initiative_sid,
			   location,
			   start_dtm
		  FROM initiative_event;

	OPEN out_initiative_group_cur FOR
		SELECT initiative_group_id,
			   is_public,
			   name
		  FROM initiative_group;

	OPEN out_igfs_cur FOR
		SELECT initiative_user_group_id,
			   flow_state_id,
			   flow_sid,
			   generate_alerts,
			   is_editable,
			   project_sid
		  FROM initiative_group_flow_state;

	OPEN out_initiative_group_mem_cur FOR
		SELECT initiative_group_id,
			   initiative_sid
		  FROM initiative_group_member;

	OPEN out_initiative_group_user_cur FOR
		SELECT initiative_group_id,
			   user_sid,
			   can_edit
		  FROM initiative_group_user;

	OPEN out_iimm_cur FOR
		SELECT csr_user_sid,
			   from_name,
			   to_name,
			   pos
		  FROM initiative_import_map_mru;

	OPEN out_iit_cur FOR
		SELECT import_template_id,
			   heading_row_idx,
			   is_default,
			   name,
			   project_sid,
			   workbook,
			   worksheet_name
		  FROM initiative_import_template;

	OPEN out_iitm_cur FOR
		SELECT import_template_id,
			   to_name,
			   from_idx,
			   from_name
		  FROM initiative_import_template_map;

	OPEN out_initiative_metric_val_cur FOR
		SELECT initiative_metric_id,
			   initiative_sid,
			   entry_measure_conversion_id,
			   entry_val,
			   measure_sid,
			   project_sid,
			   val
		  FROM initiative_metric_val;

	OPEN out_ips_cur FOR
		SELECT initiative_period_status_id,
			   colour,
			   label,
			   means_pct_complete
		  FROM initiative_period_status;

	OPEN out_initiative_period_cur FOR
		SELECT initiative_sid,
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
		  FROM initiative_period;

	OPEN out_initiative_project_tab_cur FOR
		SELECT project_sid,
			   plugin_id,
			   plugin_type_id,
			   pos,
			   tab_label
		  FROM initiative_project_tab;

	OPEN out_iptg_cur FOR
		SELECT project_sid,
			   plugin_id,
			   group_sid,
			   is_read_only
		  FROM initiative_project_tab_group;

	OPEN out_initiative_proj_team_cur FOR
		SELECT email,
			   initiative_sid,
			   name
		  FROM initiative_project_team;

	OPEN out_initiative_region_cur FOR
		SELECT initiative_sid,
			   region_sid,
			   use_for_calc
		  FROM initiative_region;

	OPEN out_initiative_sponsor_cur FOR
		SELECT email,
			   initiative_sid,
			   name
		  FROM initiative_sponsor;

	OPEN out_initiative_tag_cur FOR
		SELECT initiative_sid,
			   tag_id
		  FROM initiative_tag;

	OPEN out_initiative_user_group_cur FOR
		SELECT initiative_user_group_id,
			   label,
			   lookup_key,
			   synch_issues
		  FROM initiative_user_group;

	OPEN out_ipug_cur FOR
		SELECT initiative_user_group_id,
			   project_sid
		  FROM initiative_project_user_group;

	OPEN out_initiative_user_cur FOR
		SELECT initiative_sid,
			   initiative_user_group_id,
			   user_sid,
			   project_sid
		  FROM initiative_user;

	OPEN out_initiative_user_msg_cur FOR
		SELECT initiative_sid,
			   user_msg_id
		  FROM initiative_user_msg;

	OPEN out_initiatives_options_cur FOR
		SELECT auto_complete_date,
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
		  FROM initiatives_options;

	OPEN out_user_msg_cur FOR
		SELECT user_msg_id,
			   msg_dtm,
			   msg_text,
			   reply_to_msg_id,
			   user_sid
		  FROM user_msg;

	OPEN out_user_msg_file_cur FOR
		SELECT user_msg_file_id,
			   data,
			   filename,
			   mime_type,
			   sha1,
			   user_msg_id
		  FROM user_msg_file;

	OPEN out_pips_cur FOR
		SELECT project_sid,
			   initiative_period_status_id
		  FROM project_initiative_period_stat;

	OPEN out_dius_cur FOR
		SELECT flow_state_id,
		       flow_sid,
		       is_editable,
		       generate_alerts
		  FROM default_initiative_user_state;

	OPEN out_issue_initiative_cur FOR
		SELECT issue_initiative_id,
			   initiative_sid
		  FROM issue_initiative;

	OPEN out_aggr_region_cur FOR
		SELECT region_sid,
			   aggr_region_sid
		  FROM aggr_region;

	OPEN out_project_doc_folder_cur FOR
		SELECT project_sid,
			   name,
			   info_text,
			   label
		  FROM project_doc_folder;

	OPEN out_project_tag_group_cur FOR
		SELECT project_sid,
			   tag_group_id,
			   default_tag_id,
			   pos
		  FROM project_tag_group;

	OPEN out_project_tag_filter_cur FOR
		SELECT project_sid,
			   tag_group_id,
			   tag_id
		  FROM project_tag_filter;

	OPEN out_init_header_element_cur FOR
		SELECT initiative_header_element_id, pos, col, initiative_metric_id, tag_group_id,
		       init_header_core_element_id
		  FROM initiative_header_element;

	OPEN out_init_tab_element_layout FOR
		SELECT element_id, plugin_id, tag_group_id,	xml_field_id, pos
		  FROM init_tab_element_layout;

	OPEN out_init_create_el_layout_cur FOR
		SELECT element_id, tag_group_id, xml_field_id, section_id, pos
		  FROM init_create_page_el_layout;
END;

PROCEDURE GetCustomFactors(
	out_custom_factor_set			OUT SYS_REFCURSOR,
	out_custom_factor				OUT SYS_REFCURSOR,
	out_custom_factor_history		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_custom_factor_set FOR
		SELECT custom_factor_set_id, name, created_by_sid, created_dtm, factor_set_group_id, info_note
		  FROM custom_factor_set
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_custom_factor FOR
		SELECT custom_factor_id, custom_factor_set_id, factor_type_id, gas_type_id,
			geo_country, geo_region, egrid_ref, region_sid, std_measure_conversion_id,
			start_dtm, end_dtm, value, note
		  FROM custom_factor
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_custom_factor_history FOR
		SELECT custom_factor_history_id, factor_cat_id, factor_type_id, factor_set_id,
			geo_country, geo_region, egrid_ref, region_sid, gas_type_id, start_dtm,
			end_dtm, field_name, old_val, new_val, message, audit_date, user_sid
		  FROM custom_factor_history
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetEmissionFactorProfiles(
	out_emission_factor_profile		OUT SYS_REFCURSOR,
	out_emission_fctr_profile_fctr	OUT SYS_REFCURSOR,
	out_std_factor_set_active		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_emission_factor_profile FOR
		SELECT profile_id, name, start_dtm, end_dtm, applied
		  FROM emission_factor_profile
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_emission_fctr_profile_fctr FOR
		SELECT profile_id, factor_type_id, std_factor_set_id, custom_factor_set_id,
			   region_sid, geo_country, geo_region, egrid_ref
		  FROM emission_factor_profile_factor
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_std_factor_set_active FOR
		SELECT std_factor_set_id
		  FROM std_factor_set_active
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

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
)
AS
BEGIN
	OPEN out_options FOR
		SELECT quick_survey_type_id, rollout_delay, requirement_flow_sid, regulation_flow_sid,
			   permit_flow_sid, application_flow_sid, condition_flow_sid, rollout_option, score_type_id,
			   auto_involve_managers, permit_doc_lib_sid, permit_score_type_id
		  FROM compliance_options;

	OPEN out_compliance_languages for
		SELECT lang_id, added_dtm, active
		  FROM compliance_language;

	OPEN out_compliance_item_version_log FOR
		SELECT compliance_item_version_log_id, compliance_item_id, change_type, major_version, minor_version,
			   description, change_dtm, is_major_change, lang_id
		  FROM compliance_item_version_log;

	OPEN out_compliance_audit_log FOR
		SELECT compliance_audit_log_id, compliance_item_id, date_time, responsible_user, user_lang_id,
		       sys_lang_id, lang_id, title, summary, details, citation
		  FROM compliance_audit_log;

	OPEN out_compliance_item_regions FOR
		SELECT compliance_item_id, region_sid, flow_item_id, out_of_scope
		  FROM compliance_item_region;

	OPEN out_compliance_reg_req FOR
		SELECT requirement_id, regulation_id
		  FROM compliance_req_reg;

	OPEN out_compliance_regulations FOR
		SELECT compliance_item_id, adoption_dtm, external_id, is_policy
		  FROM compliance_regulation;

	OPEN out_compliance_requirement FOR
		SELECT compliance_item_id
		  FROM compliance_requirement;

	OPEN out_compliance_item_tag FOR
		SELECT compliance_item_id, tag_id
		  FROM compliance_item_tag;

	OPEN out_compliance_item FOR
		SELECT compliance_item_id, title, summary, details, source, reference_code, user_comment, 
			   citation, external_link, created_dtm, updated_dtm, compliance_item_status_id, 
			   major_version, minor_version, lookup_key, compliance_item_type
		  FROM compliance_item;

	OPEN out_compliance_item_desc FOR
		SELECT compliance_item_id, lang_id, major_version, minor_version, title, summary, details, citation
		  FROM compliance_item_description;

	OPEN out_compliance_item_desc_hist FOR
		SELECT compliance_item_desc_hist_id, compliance_item_id, lang_id, major_version, minor_version, title, summary, summary_clob, details, citation, description, change_dtm
		  FROM compliance_item_desc_hist;

	OPEN out_compliance_region_tag FOR
		SELECT tag_id, region_sid
		  FROM compliance_region_tag;

	OPEN out_compliance_root_regions FOR
		SELECT region_sid, region_type, rollout_level
		  FROM compliance_root_regions;

	OPEN out_enhesa_options FOR
		SELECT client_id, username, password, last_success, last_run, last_message, next_run, manual_run,
			packages_imported, packages_total, items_imported, items_total, links_created, links_total
		  FROM enhesa_options;

	OPEN out_enhesa_error_log FOR
		SELECT error_log_id, error_dtm, error_message, stack_trace
		  FROM enhesa_error_log;

	OPEN out_compliance_item_sched_iss_cur FOR
		SELECT flow_item_id, issue_scheduled_task_id
		  FROM comp_item_region_sched_issue;

	OPEN out_flow_item_audit_log FOR
		SELECT flow_item_audit_log_id, flow_item_id, log_dtm, user_sid, description, comment_text, param_1, param_2, param_3
		  FROM flow_item_audit_log;

	OPEN out_compliance_pmt_sub_type FOR
		SELECT permit_type_id, permit_sub_type_id, description, pos
		  FROM compliance_permit_sub_type;

	OPEN out_compliance_permit_type FOR
		SELECT permit_type_id, description, pos
		  FROM compliance_permit_type;

	OPEN out_compliance_cond_sub_type FOR
		SELECT condition_type_id, condition_sub_type_id, description, pos
		  FROM compliance_condition_sub_type;

	OPEN out_compliance_cond_type FOR
		SELECT condition_type_id, description, pos
		  FROM compliance_condition_type;

	OPEN out_compliance_activity_type FOR
		SELECT activity_type_id, description, pos
		  FROM compliance_activity_type;

	OPEN out_compliance_act_sub_type FOR
		SELECT activity_type_id, activity_sub_type_id, description, pos
		  FROM compliance_activity_sub_type;

	OPEN out_compliance_appl_type FOR
		SELECT application_type_id, description, pos
		  FROM compliance_application_type;

	OPEN out_compliance_permit_app FOR
		SELECT permit_application_id,
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
		  FROM compliance_permit_application;
	
	OPEN out_compliance_permit_app_pause FOR
		SELECT application_pause_id,	
			   permit_application_id,	
			   paused_dtm,				
			   resumed_dtm	
		  FROM compl_permit_application_pause;
	
	OPEN out_compliance_permit FOR
		SELECT compliance_permit_id,
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
			   activity_details
		  FROM compliance_permit;

	OPEN out_compliance_item_rollout FOR
		SELECT compliance_item_rollout_id,
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
			   source_country
		  FROM compliance_item_rollout;

	OPEN out_compliance_permit_cond FOR
		SELECT compliance_item_id,
			   compliance_permit_id,
			   condition_sub_type_id,
			   condition_type_id,
			   copied_from_id
		  FROM compliance_permit_condition;

	OPEN out_compliance_permit_tab FOR
		SELECT plugin_id, 
			   plugin_type_id,
			   pos,
			   tab_label     
		  FROM compliance_permit_tab;

	OPEN out_compliance_permit_tab_group FOR
		SELECT plugin_id,
		       group_sid,
			   role_sid	
		  FROM compliance_permit_tab_group;

	OPEN out_compliance_permit_hdr FOR
		SELECT plugin_id, 
			   plugin_type_id,
			   pos     
		  FROM compliance_permit_header;

	OPEN out_compliance_permit_hdr_group FOR
		SELECT plugin_id,
		       group_sid,
			   role_sid	
		  FROM compliance_permit_header_group;
		  
	OPEN out_compliance_permit_history FOR
		SELECT prev_permit_id,
			   next_permit_id
		  FROM compliance_permit_history;

	OPEN out_compliance_rollout_regions FOR
		SELECT compliance_item_id,region_sid
		  FROM compliance_rollout_regions;

	OPEN out_compliance_permit_score FOR
		SELECT app_sid, compliance_permit_score_id, compliance_permit_id, 
			score_threshold_id, score_type_id, score, comment_text, set_dtm,
			changed_by_user_sid, valid_until_dtm, score_source_type, score_source_id, is_override
		  FROM compliance_permit_score;
END;

PROCEDURE GetCalendars(
	out_calendar_cur				OUT SYS_REFCURSOR,
	out_calendar_event_cur			OUT SYS_REFCURSOR,
	out_calendar_event_invite_cur	OUT SYS_REFCURSOR,
	out_calendar_event_owner_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_calendar_cur FOR
		SELECT calendar_sid,
			   applies_to_initiatives,
			   applies_to_teamrooms,
			   description,
			   is_global,
			   js_class_type,
			   js_include,
			   plugin_id
		  FROM calendar;

	OPEN out_calendar_event_cur FOR
		SELECT calendar_event_id,
			   created_by_sid,
			   created_dtm,
			   description,
			   end_dtm,
			   location,
			   region_sid,
			   start_dtm
		  FROM calendar_event;

	OPEN out_calendar_event_invite_cur FOR
		SELECT calendar_event_id,
			   user_sid,
			   accepted_dtm,
			   attended,
			   declined_dtm,
			   invited_by_sid,
			   invited_dtm
		  FROM calendar_event_invite;

	OPEN out_calendar_event_owner_cur FOR
		SELECT calendar_event_id,
			   user_sid,
			   added_by_sid,
			   added_dtm
		  FROM calendar_event_owner;
END;

PROCEDURE GetClientUtilScripts(
	out_client_util_script_cur		OUT SYS_REFCURSOR,
	out_cusp_cur					OUT SYS_REFCURSOR,
	out_util_script_run_log_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_client_util_script_cur FOR
		SELECT client_util_script_id,
			   description,
			   util_script_name,
			   util_script_sp,
			   wiki_article
		  FROM client_util_script;

	OPEN out_cusp_cur FOR
		SELECT client_util_script_id,
			   pos,
			   param_hidden,
			   param_hint,
			   param_name,
			   param_value
		  FROM client_util_script_param;

	OPEN out_util_script_run_log_cur FOR
		SELECT client_util_script_id,
			   csr_user_sid,
			   params,
			   run_dtm,
			   util_script_id
		  FROM util_script_run_log;
END;

PROCEDURE GetTextToTranslate(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 'SELECT DESCRIPTION FROM DASHBOARD_ITEM_COMPARISON_TYPE' query, description
		  FROM dashboard_item_comparison_type
		 UNION ALL
		SELECT 'SELECT DESCRIPTION FROM SHEET_ACTION', description
		  FROM sheet_action 
		 UNION ALL
		SELECT 'SELECT DOWNSTREAM_DESCRIPTION FROM SHEET_ACTION', description
		  FROM sheet_action
		 UNION ALL
		SELECT 'SELECT LABEL FROM AUDIT_TYPE', label
		  FROM audit_type
		 UNION ALL
		SELECT 'SELECT DESCRIPTION FROM STD_ALERT_TYPE', description
		  FROM std_alert_type
		 UNION ALL
		SELECT 'SELECT SEND_TRIGGER FROM STD_ALERT_TYPE', send_trigger
		  FROM std_alert_type
		 UNION ALL
		SELECT 'SELECT SENT_FROM FROM STD_ALERT_TYPE', sent_from
		  FROM std_alert_type
		 UNION ALL
		SELECT 'SELECT DESCRIPTION FROM SOURCE_TYPE', description
		  FROM source_type
		 UNION ALL
		SELECT 'SELECT LABEL FROM SOURCE_TYPE_ERROR_CODE', label
		  FROM source_type_error_code
		 UNION ALL
		SELECT 'SELECT DESCRIPTION FROM TEMPLATE_TYPE', description
		  FROM template_type
		 UNION ALL
		SELECT 'SELECT NAME FROM PORTLET', name
		  FROM portlet
		 UNION ALL
		SELECT 'SELECT DESCRIPTION FROM STD_ALERT_TYPE_PARAM', description
		  FROM std_alert_type_param
		 UNION ALL
		SELECT 'SELECT HELP_TEXT FROM STD_ALERT_TYPE_PARAM', help_text
		  FROM std_alert_type_param;
END;

PROCEDURE GetDynamicTables(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_modules						security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	GetDynamicTables(v_modules, out_cur);
END;

PROCEDURE GetDynamicTables(
	in_modules						IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_include_all					NUMBER(1);
	v_modules						security.T_VARCHAR2_TABLE;
BEGIN
	v_modules := security_pkg.Varchar2ArrayToTable(in_modules);
	v_include_all := CASE WHEN v_modules.COUNT = 0 THEN 1 ELSE 0 END;

	OPEN out_cur FOR
		SELECT owner, table_name, enable_export, enable_import, csrimp_table_name, module_name
		  FROM schema_table
		 WHERE v_include_all = 1 
			OR LOWER(module_name) IN (SELECT LOWER(value) FROM TABLE(v_modules));
END;

PROCEDURE GetDynamicTableData(
	in_owner						IN	VARCHAR2,
	in_table_name					IN	VARCHAR2,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_sql							VARCHAR2(32767);
BEGIN
	SELECT 'SELECT ' || LISTAGG('"' || atc.column_name || '"', ',') WITHIN GROUP (ORDER BY atc.column_id) || 
		    ' FROM "' || in_owner || '"."' || in_table_name || '"'
	  INTO v_sql
	  FROM all_tab_columns atc
	  JOIN schema_table st ON atc.table_name = st.table_name
	  LEFT JOIN schema_column sc 
		ON sc.table_name = atc.table_name 
	   AND sc.column_name = atc.column_name
	 WHERE atc.owner = in_owner
	   AND st.table_name = in_table_name
	   AND atc.column_name != 'APP_SID'
	   AND NVL(sc.enable_export, 1) != 0;

	OPEN out_cur FOR v_sql;
END;

-- Calculates the correct order for importing into schema tables, given their referential 
-- constraints. This is linear over the total number of reachable constraints as each node is 
-- visited only once.
-- See [https://en.wikipedia.org/wiki/Topological_sorting#Depth-first_search]
FUNCTION GetDynamicTablesForImport RETURN security.T_VARCHAR2_TABLE
AS
	TYPE StringList					IS TABLE OF VARCHAR2(61); 
	TYPE Node						IS RECORD(edges StringList);
	TYPE NodeLookup					IS TABLE OF Node INDEX BY VARCHAR2(61);
	TYPE FlagTable					IS TABLE OF BOOLEAN INDEX BY VARCHAR2(61);

	v_edge_cache					NodeLookup;
	v_visiting						FlagTable;
	v_visited						FlagTable;
	v_unsorted						FlagTable;
	v_sorted						security.T_VARCHAR2_TABLE := security.T_VARCHAR2_TABLE();

	PROCEDURE VisitNode(in_table_name VARCHAR2) AS
		v_node						Node;
	BEGIN
		IF v_visiting.EXISTS(in_table_name) THEN
			IF v_unsorted.EXISTS(in_table_name) THEN
				IF in_table_name != 'CSR.COMPLIANCE_ENHESA_MAP' THEN
					RAISE_APPLICATION_ERROR(-20001, 'Referential dependency cycle in schema_tables for table '||in_table_name);
				END IF;
				RETURN;
			ELSE
				-- Cycles in core tables can be ignored
				RETURN;
			END IF;
		END IF;

		IF v_visited.EXISTS(in_table_name) THEN
			RETURN;
		END IF;

		IF NOT v_edge_cache.EXISTS(in_table_name) THEN
			DECLARE 
				v_index		PLS_INTEGER		:= INSTR(in_table_name, '.');
				v_owner		VARCHAR2(30)	:= SUBSTR(in_table_name, 1, v_index - 1); 
				v_table		VARCHAR2(30)	:= SUBSTR(in_table_name, v_index + 1);
			BEGIN
				SELECT pk.owner || '.' || pk.table_name 
				  BULK COLLECT INTO v_node.edges
				  FROM all_constraints fk
				  JOIN all_constraints pk 
					ON fk.r_owner = pk.owner 
				   AND fk.r_constraint_name = pk.constraint_name
				 WHERE fk.constraint_type = 'R'
				   AND fk.owner = v_owner 
				   AND fk.table_name = v_table;
			END;

			v_edge_cache(in_table_name) := v_node;
		ELSE 
			v_node := v_edge_cache(in_table_name);
		END IF;

		v_visiting(in_table_name) := TRUE;

		FOR i IN 1 .. v_node.edges.COUNT LOOP
			VisitNode(v_node.edges(i));
		END LOOP;

		v_visiting.DELETE(in_table_name);
		v_visited(in_table_name) := TRUE;

		IF v_unsorted.EXISTS(in_table_name) THEN 
			v_unsorted.DELETE(in_table_name);
			v_sorted.EXTEND(1);
			v_sorted(v_sorted.COUNT) := security.T_VARCHAR2_ROW(v_sorted.COUNT, in_table_name);
		END IF;
	END;
BEGIN
	FOR r IN (SELECT owner, table_name 
				FROM schema_table 
			   WHERE enable_import = 1)
	LOOP
		v_unsorted(r.owner || '.' || r.table_name) := TRUE;
	END LOOP;

	WHILE v_unsorted.COUNT > 0 LOOP
		VisitNode(v_unsorted.FIRST);
	END LOOP;

	RETURN v_sorted;
END;

PROCEDURE GetDynamicTablesForImport(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT s.owner, s.table_name, st.enable_export, st.enable_import, st.csrimp_table_name, module_name
		  FROM schema_table st
		  JOIN (SELECT pos, 
					   SUBSTR(value, 1, INSTR(value, '.') - 1) owner, 
					   SUBSTR(value, INSTR(value, '.') + 1) table_name 
				FROM TABLE(GetDynamicTablesForImport())) s 
			ON s.owner = st.owner 
		   AND s.table_name = st.table_name
		 WHERE enable_import = 1
		 ORDER BY s.pos;
END;

PROCEDURE GetIntApiCompanyUserGroups(
	out_company_user_groups			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_company_user_groups FOR
		SELECT group_sid_id
		  FROM intapi_company_user_group;
END;

PROCEDURE GetSecondaryRegionTreeCtrl(
	out_secondary_region_tree_ctrl	OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_secondary_region_tree_ctrl FOR
		SELECT region_sid, sp_name, region_root_sid, tag_id, tag_group_ids, active_only, reduce_contention, apply_deleg_plans, ignore_sids, user_sid, last_run_dtm
		  FROM secondary_region_tree_ctrl;
END;

PROCEDURE GetSecondaryRegionTreeLog(
	out_secondary_region_tree_log	OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_secondary_region_tree_log FOR
		SELECT log_id, region_sid, user_sid, log_dtm, presync_tree, postsync_tree
		  FROM secondary_region_tree_log;
END;

PROCEDURE GetOshaMappings (
	out_osha_mappings 				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_osha_mappings FOR
		SELECT osha_map_field_id, ind_sid, cms_col_sid, region_data_map_id
		  FROM osha_mapping;
END;

PROCEDURE GetDataBuckets (
	out_data_buckets 			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_data_buckets FOR
		SELECT data_bucket_sid, description, enabled, active_instance_id
		  FROM data_bucket;

END;

PROCEDURE GetCredentialManagement(
	out_credential_management	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_credential_management FOR
		SELECT credential_id, label, auth_type_id, auth_scope_id, created_dtm, updated_dtm, login_hint
		  FROM credential_management
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetIntegrationQuestionAnswer(
	out_integration_question_answer	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_integration_question_answer FOR
		SELECT parent_ref, questionnaire_name, question_ref, internal_audit_sid, section_name, section_code, section_score,
			   subsection_name, subsection_code, question_text, rating, conclusion, answer, data_points,
			   last_updated, id
		  FROM integration_question_answer
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetRegionCertificates(
	out_region_certificates	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_region_certificates FOR
		SELECT region_certificate_id, region_sid, certification_id, certification_level_id, certificate_number,
				floor_area, issued_dtm, expiry_dtm, external_certificate_id, deleted, note, submit_to_gresb
		  FROM region_certificate
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetRegionEnergyRatings(
	out_region_energy_ratings	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_region_energy_ratings FOR
		SELECT region_energy_rating_id, region_sid, energy_rating_id, floor_area, issued_dtm, expiry_dtm, note, submit_to_gresb
		  FROM region_energy_rating
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetModuleHistory(
	out_module_history	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_module_history FOR
		SELECT module_id, enabled_dtm, last_enabled_dtm, disabled_dtm
		  FROM module_history
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetExcelExportOptionsTagGroup(
	out_cur_ee_options_tg	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur_ee_options_tg FOR
		SELECT dataview_sid, applies_to, tag_group_id
		  FROM excel_export_options_tag_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetBaselineConfig(
	out_cur_baseline_config	OUT SYS_REFCURSOR,
	out_cur_baseline_config_period	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur_baseline_config FOR
		SELECT baseline_config_id,baseline_name,baseline_lookup_key
		  FROM baseline_config
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_cur_baseline_config_period FOR
		SELECT baseline_config_period_id,baseline_config_id,baseline_period_dtm,baseline_cover_period_start_dtm,baseline_cover_period_end_dtm
		  FROM baseline_config_period
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

END;
/
